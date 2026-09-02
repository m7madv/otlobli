import { createClient } from "@supabase/supabase-js";
import { boundedJson, BoundedJsonError } from "../_shared/bounded_json.ts";
import { constantTimeEqual, jsonResponse } from "../_shared/http.ts";
import {
  fetchRevenueCatSubscriptionSnapshot,
  needsRevenueCatCustomerSnapshot,
  resolveRevenueCatTransferDestination,
  RevenueCatCustomerError,
  revenueCatEventMode,
  type RevenueCatSubscriptionSnapshot,
  revenueCatTransferIds,
  shouldRetryRevenueCatTransfer,
} from "./core.ts";

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const MAX_WEBHOOK_BODY_BYTES = 262_144;
const ACTIVE_SNAPSHOT_EVENT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "SUBSCRIPTION_EXTENDED",
  "REFUND_REVERSED",
  "TEMPORARY_ENTITLEMENT_GRANT",
]);

function timestamp(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) && value >= 0
    ? value
    : null;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }
  const expected = Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ?? "";
  const provided = request.headers.get("authorization") ?? "";
  if (!expected || !constantTimeEqual(provided, `Bearer ${expected}`)) {
    return jsonResponse(401, { error: "invalid_webhook_authorization" });
  }
  let payload: Record<string, unknown>;
  try {
    const parsed = await boundedJson(request, MAX_WEBHOOK_BODY_BYTES);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return jsonResponse(400, { error: "invalid_json" });
    }
    payload = parsed as Record<string, unknown>;
  } catch (error) {
    if (error instanceof BoundedJsonError) {
      return jsonResponse(error.status, {
        error: error.status === 413
          ? "request_too_large"
          : error.status === 415
          ? "unsupported_media_type"
          : "invalid_json",
      });
    }
    return jsonResponse(400, { error: "invalid_json" });
  }

  const event = payload.event as Record<string, unknown> | undefined;
  const eventId = event?.id;
  const eventType = event?.type;
  if (
    typeof eventId !== "string" || eventId.length === 0 ||
    typeof eventType !== "string" || eventType.length === 0
  ) {
    return jsonResponse(400, { error: "invalid_event" });
  }
  const mode = revenueCatEventMode(eventType);
  const eventTimestampMs = timestamp(event?.event_timestamp_ms) ?? Date.now();
  const store = typeof event?.store === "string" ? event.store : "unknown";

  let appUserId: string | null = null;
  let destinationUserIds: string[] = [];
  let sourceUserIds: string[] = [];
  let sourceRevenueCatIds: string[] = [];
  if (mode === "transfer") {
    try {
      const ids = revenueCatTransferIds(event);
      destinationUserIds = ids.destinationUserIds;
      sourceUserIds = ids.sourceUserIds;
      sourceRevenueCatIds = ids.sourceRevenueCatIds;
    } catch (_error) {
      return jsonResponse(400, { error: "invalid_transfer_event" });
    }
  } else {
    const rawAppUserId = event?.app_user_id;
    if (typeof rawAppUserId === "string" && UUID_PATTERN.test(rawAppUserId)) {
      appUserId = rawAppUserId.toLowerCase();
    } else if (mode !== "ignore") {
      return jsonResponse(400, { error: "invalid_event" });
    }
  }

  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !serviceRoleKey) {
    return jsonResponse(503, { error: "service_not_configured" });
  }
  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const canonicalEventId = eventId.slice(0, 200);
  const { data: existingAudit, error: existingAuditError } = await serviceClient
    .from("revenuecat_webhook_events")
    .select("app_user_id, handling_status")
    .eq("event_id", canonicalEventId)
    .maybeSingle();
  if (existingAuditError) {
    return jsonResponse(500, { error: "webhook_processing_failed" });
  }
  if (existingAudit) {
    return jsonResponse(200, {
      received: true,
      duplicate: true,
      ignored: existingAudit.handling_status.startsWith("ignored_"),
      anonymized: existingAudit.handling_status === "anonymized_deleted_user",
    });
  }

  if (mode === "ignore") {
    const { data, error } = await serviceClient.rpc(
      "record_ignored_revenuecat_event",
      {
        p_event_id: eventId,
        p_event_type: eventType,
        p_user_id: appUserId,
      },
    );
    if (error) {
      return jsonResponse(500, { error: "webhook_processing_failed" });
    }
    return jsonResponse(200, {
      received: true,
      duplicate: data === false,
      ignored: true,
      anonymized: false,
    });
  }

  let profile: { user_id: string } | null = null;
  if (mode === "transfer") {
    const { data: destinationProfiles, error: profileError } =
      await serviceClient
        .from("profiles")
        .select("user_id")
        .in("user_id", destinationUserIds);
    if (profileError) {
      return jsonResponse(500, { error: "webhook_processing_failed" });
    }
    try {
      appUserId = resolveRevenueCatTransferDestination(
        destinationUserIds,
        (destinationProfiles ?? []).map((item) => item.user_id),
      );
      profile = { user_id: appUserId };
    } catch (error) {
      if (
        error instanceof RevenueCatCustomerError &&
        error.message === "transfer_destination_profile_missing"
      ) {
        return jsonResponse(503, { error: "profile_not_ready" });
      }
      return jsonResponse(400, { error: "invalid_transfer_event" });
    }
  } else {
    const { data, error: profileError } = await serviceClient
      .from("profiles")
      .select("user_id")
      .eq("user_id", appUserId!)
      .maybeSingle();
    if (profileError) {
      return jsonResponse(500, { error: "webhook_processing_failed" });
    }
    profile = data;
  }

  let snapshot: RevenueCatSubscriptionSnapshot = {
    isPro: false,
    productId: "",
    store,
    periodStartMs: eventTimestampMs,
    periodEndMs: eventTimestampMs,
    accessEndMs: eventTimestampMs,
  };
  if (profile != null && needsRevenueCatCustomerSnapshot(mode)) {
    const revenueCatSecretApiKey = Deno.env.get("REVENUECAT_SECRET_API_KEY") ??
      "";
    try {
      snapshot = await fetchRevenueCatSubscriptionSnapshot(
        appUserId!,
        revenueCatSecretApiKey,
        {
          nowMs: Date.now(),
          eventTimestampMs,
          fallbackStore: store,
        },
      );
    } catch (error) {
      console.error(
        JSON.stringify({
          event: "revenuecat_customer_sync_failed",
          type: eventType,
          reason: error instanceof RevenueCatCustomerError
            ? error.message
            : "unexpected_error",
        }),
      );
      return jsonResponse(503, { error: "subscription_sync_unavailable" });
    }
    if (mode === "transfer" && !snapshot.isPro) {
      let sourceSnapshots: RevenueCatSubscriptionSnapshot[];
      try {
        sourceSnapshots = await Promise.all(
          sourceRevenueCatIds
            .filter((sourceUserId) => sourceUserId.toLowerCase() !== appUserId)
            .map((sourceUserId) =>
              fetchRevenueCatSubscriptionSnapshot(
                sourceUserId,
                revenueCatSecretApiKey,
                {
                  nowMs: Date.now(),
                  eventTimestampMs,
                  fallbackStore: store,
                  allowCreatedCustomer: true,
                },
              )
            ),
        );
      } catch (error) {
        console.error(
          JSON.stringify({
            event: "revenuecat_transfer_source_sync_failed",
            reason: error instanceof RevenueCatCustomerError
              ? error.message
              : "unexpected_error",
          }),
        );
        return jsonResponse(503, { error: "subscription_sync_unavailable" });
      }
      if (shouldRetryRevenueCatTransfer(snapshot, sourceSnapshots)) {
        return jsonResponse(503, { error: "subscription_sync_pending" });
      }
    }
    if (!snapshot.isPro && ACTIVE_SNAPSHOT_EVENT_TYPES.has(eventType)) {
      return jsonResponse(503, { error: "subscription_sync_pending" });
    }
  }

  const rpc = mode === "transfer"
    ? serviceClient.rpc("apply_revenuecat_transfer", {
      p_event_id: eventId,
      p_event_type: eventType,
      p_source_user_ids: sourceUserIds,
      p_destination_user_id: appUserId!,
      p_is_pro: snapshot.isPro,
      p_product_id: snapshot.productId,
      p_store: snapshot.store,
      p_event_at: new Date(eventTimestampMs).toISOString(),
      p_period_start: new Date(snapshot.periodStartMs).toISOString(),
      p_period_end: new Date(snapshot.periodEndMs).toISOString(),
      p_access_end: new Date(snapshot.accessEndMs).toISOString(),
    })
    : serviceClient.rpc("apply_revenuecat_event", {
      p_event_id: eventId,
      p_event_type: eventType,
      p_user_id: appUserId!,
      p_is_pro: snapshot.isPro,
      p_product_id: snapshot.productId,
      p_store: snapshot.store,
      p_event_at: new Date(eventTimestampMs).toISOString(),
      p_period_start: new Date(snapshot.periodStartMs).toISOString(),
      p_period_end: new Date(snapshot.periodEndMs).toISOString(),
      p_access_end: new Date(snapshot.accessEndMs).toISOString(),
    });
  const { data, error } = await rpc;
  if (error) return jsonResponse(500, { error: "webhook_processing_failed" });

  const { data: auditEvent, error: auditError } = await serviceClient
    .from("revenuecat_webhook_events")
    .select("app_user_id, handling_status")
    .eq("event_id", canonicalEventId)
    .maybeSingle();
  if (auditError || !auditEvent) {
    return jsonResponse(500, { error: "webhook_processing_failed" });
  }
  const ignored = auditEvent.handling_status.startsWith("ignored_");
  const anonymized = auditEvent.handling_status === "anonymized_deleted_user";
  if (profile == null || ignored || anonymized) {
    console.info(
      JSON.stringify({
        event: "revenuecat_event_anonymized",
        reason: ignored
          ? "missing_profile"
          : anonymized
          ? "deleted_profile"
          : "missing_profile",
      }),
    );
  }
  return jsonResponse(200, {
    received: true,
    duplicate: data === false,
    ignored,
    anonymized,
  });
});
