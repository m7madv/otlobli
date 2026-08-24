import { createClient } from "@supabase/supabase-js";
import { constantTimeEqual, jsonResponse } from "../_shared/http.ts";

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }
  const expected = Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ?? "";
  const provided = request.headers.get("authorization") ?? "";
  if (!expected || !constantTimeEqual(provided, `Bearer ${expected}`)) {
    return jsonResponse(401, { error: "invalid_webhook_authorization" });
  }
  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (contentLength > 262_144) {
    return jsonResponse(413, { error: "request_too_large" });
  }

  let payload: Record<string, unknown>;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse(400, { error: "invalid_json" });
  }
  const event = payload.event as Record<string, unknown> | undefined;
  const eventId = event?.id;
  const eventType = event?.type;
  const appUserId = event?.app_user_id;
  if (
    typeof eventId !== "string" || typeof eventType !== "string" ||
    typeof appUserId !== "string" || !UUID_PATTERN.test(appUserId)
  ) {
    return jsonResponse(400, { error: "invalid_event" });
  }

  const entitlementIds = Array.isArray(event?.entitlement_ids)
    ? event.entitlement_ids.filter((value): value is string =>
      typeof value === "string"
    )
    : [];
  const expirationMs = typeof event?.expiration_at_ms === "number"
    ? event.expiration_at_ms
    : 0;
  const purchasedMs = typeof event?.purchased_at_ms === "number"
    ? event.purchased_at_ms
    : Date.now();
  const eventTimestampMs = typeof event?.event_timestamp_ms === "number"
    ? event.event_timestamp_ms
    : Date.now();
  const isPro = entitlementIds.includes("pro") && expirationMs > Date.now();
  const productId = typeof event?.product_id === "string"
    ? event.product_id
    : "";
  const store = typeof event?.store === "string" ? event.store : "unknown";

  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !serviceRoleKey) {
    return jsonResponse(503, { error: "service_not_configured" });
  }
  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data, error } = await serviceClient.rpc("apply_revenuecat_event", {
    p_event_id: eventId,
    p_event_type: eventType,
    p_user_id: appUserId,
    p_is_pro: isPro,
    p_product_id: productId,
    p_store: store,
    p_event_at: new Date(eventTimestampMs).toISOString(),
    p_period_start: new Date(purchasedMs).toISOString(),
    p_period_end: new Date(expirationMs || purchasedMs).toISOString(),
  });
  if (error) return jsonResponse(500, { error: "webhook_processing_failed" });
  return jsonResponse(200, { received: true, duplicate: data === false });
});
