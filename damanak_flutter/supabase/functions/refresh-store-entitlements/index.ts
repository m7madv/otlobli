import { createClient } from "@supabase/supabase-js";
import {
  type VerifiedEntitlement,
  verifyApplePurchase,
  verifyGooglePurchase,
} from "../verify-store-purchase/index.ts";

type RefreshRow = {
  id?: unknown;
  storeId?: unknown;
  userId?: unknown;
  platform?: unknown;
  originalTransactionId?: unknown;
  purchaseToken?: unknown;
};

function env(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`MISSING_SECRET_${name}`);
  return value;
}

function json(status: number, body: Record<string, unknown>) {
  return Response.json(body, {
    status,
    headers: {
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
  });
}

export async function handle(request: Request) {
  if (request.method !== "POST") {
    return json(405, { error: "METHOD_INVALID" });
  }
  if (
    request.headers.get("authorization") !==
      `Bearer ${env("ENTITLEMENT_REFRESH_SECRET")}`
  ) {
    return json(401, { error: "AUTH_INVALID" });
  }

  const admin = createClient(
    env("SUPABASE_URL"),
    env("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
  const { data, error } = await admin.rpc(
    "claim_store_entitlement_refreshes",
    { requested_limit: 10 },
  );
  if (error) return json(500, { error: "REFRESH_QUEUE_UNAVAILABLE" });
  const rows = Array.isArray(data) ? data as RefreshRow[] : [];

  const results = await Promise.all(rows.map(async (row) => {
    const id = String(row.id ?? "");
    const storeId = String(row.storeId ?? "");
    const userId = String(row.userId ?? "");
    const platform = String(row.platform ?? "");
    let succeeded = false;
    try {
      let entitlement: VerifiedEntitlement;
      if (platform === "app_store") {
        entitlement = await verifyApplePurchase({
          storeId,
          platform: "app_store",
          purchaseId: String(row.originalTransactionId ?? ""),
          verificationSource: "app_store",
        }, userId);
      } else if (platform === "google_play") {
        entitlement = await verifyGooglePurchase({
          storeId,
          platform: "google_play",
          verificationData: String(row.purchaseToken ?? ""),
          verificationSource: "google_play",
        }, userId);
      } else {
        throw new Error("REFRESH_PLATFORM_INVALID");
      }

      const { error: applyError } = await admin.rpc(
        "apply_verified_store_entitlement",
        {
          target_store_id: storeId,
          target_user_id: userId,
          billing_platform: entitlement.platform,
          billed_product_id: entitlement.productId,
          billed_base_plan_id: entitlement.basePlanId,
          external_transaction_id: entitlement.transactionId,
          external_original_transaction_id: entitlement.originalTransactionId,
          entitlement_status: entitlement.status,
          store_environment: entitlement.environment,
          entitlement_period_start: entitlement.periodStart,
          entitlement_period_end: entitlement.periodEnd,
          entitlement_auto_renews: entitlement.autoRenews,
        },
      );
      if (applyError) throw new Error("REFRESH_APPLY_FAILED");
      succeeded = true;
      return true;
    } catch (refreshError) {
      console.error(
        "refresh-store-entitlements",
        refreshError instanceof Error ? refreshError.message : "REFRESH_FAILED",
      );
      return false;
    } finally {
      if (/^[0-9a-f-]{36}$/i.test(id)) {
        await admin.rpc("release_store_entitlement_refresh", {
          target_entitlement_id: id,
          refresh_succeeded: succeeded,
        });
      }
    }
  }));

  return json(200, {
    processed: rows.length,
    refreshed: results.filter(Boolean).length,
    failed: results.filter((value) => !value).length,
  });
}

if (import.meta.main) Deno.serve(handle);
