import { createClient } from "@supabase/supabase-js";
import { BoundedJsonError } from "../_shared/bounded_json.ts";
import { bearerToken, jsonResponse } from "../_shared/http.ts";
import { RevenueCatCustomerError } from "../revenuecat-webhook/core.ts";
import {
  executeClaimedSubscriptionSync,
  fetchRevenueCatSubscriptionSyncLookup,
  normalizeStoredSubscriptionState,
  subscriptionSyncEventId,
  subscriptionSyncEventType,
  subscriptionSyncRequestBody,
  subscriptionSyncRpcArguments,
} from "./core.ts";

type SubscriptionSyncOperationErrorCode =
  | "rate_limit_failed"
  | "database_failed";

class SubscriptionSyncOperationError extends Error {
  constructor(public readonly code: SubscriptionSyncOperationErrorCode) {
    super(code);
    this.name = "SubscriptionSyncOperationError";
  }
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  const token = bearerToken(request);
  if (!token) return jsonResponse(401, { error: "authentication_required" });

  let body;
  try {
    body = await subscriptionSyncRequestBody(request);
  } catch (error) {
    if (error instanceof BoundedJsonError) {
      return jsonResponse(error.status, {
        error: error.status === 413
          ? "request_too_large"
          : error.status === 415
          ? "unsupported_media_type"
          : "invalid_request",
      });
    }
    return jsonResponse(400, { error: "invalid_request" });
  }

  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const revenueCatSecret = Deno.env.get("REVENUECAT_SECRET_API_KEY") ?? "";
  if (!url || !anonKey || !serviceRoleKey || !revenueCatSecret) {
    return jsonResponse(503, { error: "service_not_configured" });
  }

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser(
    token,
  );
  if (userError || !userData.user) {
    return jsonResponse(401, { error: "authentication_required" });
  }

  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const userId = userData.user.id;
  const { data: profile, error: profileError } = await serviceClient
    .from("profiles")
    .select("user_id")
    .eq("user_id", userId)
    .maybeSingle();
  if (profileError) {
    return jsonResponse(500, { error: "subscription_sync_failed" });
  }
  if (!profile) {
    return jsonResponse(409, { error: "profile_not_ready" });
  }

  const observedAtMs = Date.now();
  let result;
  try {
    result = await executeClaimedSubscriptionSync({
      expectedPro: body.expectedPro,
      claim: async () => {
        const { data, error } = await serviceClient.rpc(
          "claim_voicebrief_subscription_sync",
          { p_user_id: userId },
        );
        if (error || typeof data !== "boolean") {
          throw new SubscriptionSyncOperationError("rate_limit_failed");
        }
        return data;
      },
      fetchSnapshot: async () => {
        return await fetchRevenueCatSubscriptionSyncLookup(
          userId,
          revenueCatSecret,
          {
            nowMs: observedAtMs,
            eventTimestampMs: observedAtMs,
          },
        );
      },
      hasCurrentProGeneration: async (snapshot) => {
        const { data: generationKey, error: generationError } =
          await serviceClient.rpc("voicebrief_subscription_generation_key", {
            p_product_id: snapshot.productId,
            p_period_start: new Date(snapshot.periodStartMs).toISOString(),
          });
        if (
          generationError || typeof generationKey !== "string" ||
          generationKey.length === 0
        ) {
          throw new SubscriptionSyncOperationError("database_failed");
        }
        const { data: currentState, error: currentStateError } =
          await serviceClient
            .from("subscription_state")
            .select(
              "entitlement, product_id, quota_generation_key, expires_at",
            )
            .eq("user_id", userId)
            .maybeSingle();
        if (currentStateError) {
          throw new SubscriptionSyncOperationError("database_failed");
        }
        if (
          currentState?.entitlement !== "pro" ||
          currentState.product_id !== snapshot.productId ||
          currentState.quota_generation_key !== generationKey ||
          typeof currentState.expires_at !== "string" ||
          Date.parse(currentState.expires_at) !== snapshot.accessEndMs
        ) {
          return false;
        }
        const { data: matchingPeriod, error: periodError } = await serviceClient
          .from("usage_periods")
          .select("id")
          .eq("user_id", userId)
          .eq("plan", "pro")
          .eq("subscription_generation_key", generationKey)
          .limit(1)
          .maybeSingle();
        if (periodError) {
          throw new SubscriptionSyncOperationError("database_failed");
        }
        return matchingPeriod != null;
      },
      applySnapshot: async (snapshot) => {
        // Read after the RevenueCat request so classification and the
        // idempotency key use the newest local state available before the RPC.
        const { data: rawState, error: stateError } = await serviceClient
          .from("subscription_state")
          .select(
            "entitlement, product_id, quota_generation_key, revenuecat_event_id, expires_at",
          )
          .eq("user_id", userId)
          .maybeSingle();
        if (stateError) {
          throw new SubscriptionSyncOperationError("database_failed");
        }
        const previousState = normalizeStoredSubscriptionState(rawState);
        const eventType = subscriptionSyncEventType(snapshot);
        const eventId = await subscriptionSyncEventId(
          userId,
          snapshot,
          previousState,
        );
        const rpcArguments = subscriptionSyncRpcArguments({
          eventId,
          eventType,
          userId,
          eventAtMs: observedAtMs,
          snapshot,
        });
        const { data: applied, error: applyError } = await serviceClient.rpc(
          "apply_revenuecat_event",
          rpcArguments,
        );
        if (applyError || typeof applied !== "boolean") {
          throw new SubscriptionSyncOperationError("database_failed");
        }
        return applied;
      },
    });
  } catch (error) {
    if (error instanceof SubscriptionSyncOperationError) {
      console.error(
        JSON.stringify({
          event: "subscription_sync_failed",
          stage: error.code === "rate_limit_failed" ? "rate_limit" : "database",
        }),
      );
      return jsonResponse(500, { error: "subscription_sync_failed" });
    }
    if (error instanceof RevenueCatCustomerError) {
      console.error(
        JSON.stringify({
          event: "subscription_sync_failed",
          stage: "revenuecat",
          reason: error.message,
        }),
      );
      return jsonResponse(503, { error: "subscription_sync_unavailable" });
    }
    console.error(
      JSON.stringify({
        event: "subscription_sync_failed",
        stage: "unexpected",
      }),
    );
    return jsonResponse(500, { error: "subscription_sync_failed" });
  }

  if (result.kind === "rate_limited") {
    return jsonResponse(429, { error: "subscription_sync_rate_limited" });
  }
  if (result.kind === "pending") {
    return jsonResponse(503, { error: "subscription_sync_pending" });
  }

  return jsonResponse(200, {
    synced: true,
    duplicate: !result.applied,
    entitlement: result.snapshot.isPro ? "pro" : "free",
    expiresAt: result.snapshot.isPro
      ? new Date(result.snapshot.accessEndMs).toISOString()
      : null,
  });
});
