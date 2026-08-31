import { createClient } from "@supabase/supabase-js";
import {
  acknowledgeGoogleSubscription,
  type VerifiedEntitlement,
  verifyApplePurchase,
  verifyGooglePurchase,
} from "../verify-store-purchase/index.ts";

export type RefreshRow = {
  id?: unknown;
  storeId?: unknown;
  userId?: unknown;
  platform?: unknown;
  originalTransactionId?: unknown;
  purchaseToken?: unknown;
};

export const REFRESH_CLAIM_LIMIT = 100;
export const REFRESH_CONCURRENCY_LIMIT = 10;

type RefreshRpcResult = { error: unknown; data?: unknown };
export type RefreshRpc = (
  name: string,
  params: Record<string, unknown>,
) => Promise<RefreshRpcResult>;

export type RefreshVerifiers = {
  apple: typeof verifyApplePurchase;
  google: typeof verifyGooglePurchase;
  acknowledgeGoogle?: typeof acknowledgeGoogleSubscription;
};

const defaultVerifiers: RefreshVerifiers = {
  apple: verifyApplePurchase,
  google: verifyGooglePurchase,
  acknowledgeGoogle: acknowledgeGoogleSubscription,
};

export function buildRefreshVerificationBody(row: RefreshRow) {
  const storeId = String(row.storeId ?? "");
  const platform = String(row.platform ?? "");
  const originalTransactionId = String(row.originalTransactionId ?? "");
  if (platform === "app_store") {
    return {
      platform: "app_store" as const,
      body: {
        storeId,
        platform: "app_store" as const,
        purchaseId: originalTransactionId,
        verificationSource: "app_store",
      },
    };
  }
  if (platform === "google_play") {
    return {
      platform: "google_play" as const,
      body: {
        storeId,
        platform: "google_play" as const,
        verificationData: String(row.purchaseToken ?? ""),
        verificationSource: "google_play",
        knownOriginalTransactionId: originalTransactionId,
      },
    };
  }
  throw new Error("REFRESH_PLATFORM_INVALID");
}

export function buildRefreshApplyRequest(
  row: RefreshRow,
  entitlement: VerifiedEntitlement,
) {
  const isGoogle = entitlement.platform === "google_play";
  const rawPurchaseToken = isGoogle
    ? String(row.purchaseToken ?? "").trim()
    : null;
  const purchaseTokenHash = isGoogle
    ? entitlement.purchaseTokenHash?.trim() ?? null
    : null;
  const linkedPurchaseTokenHash = isGoogle
    ? entitlement.linkedPurchaseTokenHash?.trim() || null
    : null;

  if (
    isGoogle &&
    (
      rawPurchaseToken == null ||
      rawPurchaseToken.length < 20 ||
      purchaseTokenHash == null ||
      !/^[0-9a-f]{64}$/.test(purchaseTokenHash) ||
      (linkedPurchaseTokenHash != null &&
        !/^[0-9a-f]{64}$/.test(linkedPurchaseTokenHash))
    )
  ) {
    throw new Error("REFRESH_GOOGLE_LINEAGE_INVALID");
  }

  return {
    name: "apply_verified_store_entitlement_with_receipt" as const,
    params: {
      target_store_id: String(row.storeId ?? ""),
      target_user_id: String(row.userId ?? ""),
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
      raw_purchase_token: rawPurchaseToken,
      purchase_token_hash: purchaseTokenHash,
      linked_purchase_token_hash: linkedPurchaseTokenHash,
      expected_current_purchase_token_hash: purchaseTokenHash,
    },
  };
}

export async function mapWithConcurrency<T, R>(
  values: readonly T[],
  requestedLimit: number,
  mapper: (value: T, index: number) => Promise<R>,
): Promise<R[]> {
  if (values.length === 0) return [];
  const limit = Math.max(
    1,
    Math.min(
      Math.floor(requestedLimit),
      REFRESH_CONCURRENCY_LIMIT,
      values.length,
    ),
  );
  const results = new Array<R>(values.length);
  let nextIndex = 0;

  await Promise.all(
    Array.from({ length: limit }, async () => {
      while (true) {
        const index = nextIndex++;
        if (index >= values.length) return;
        results[index] = await mapper(values[index], index);
      }
    }),
  );
  return results;
}

export async function refreshEntitlementRow(
  row: RefreshRow,
  rpc: RefreshRpc,
  verifiers: RefreshVerifiers = defaultVerifiers,
) {
  const id = String(row.id ?? "");
  const userId = String(row.userId ?? "");
  let succeeded = false;
  try {
    let entitlement: VerifiedEntitlement;
    const verification = buildRefreshVerificationBody(row);
    if (verification.platform === "app_store") {
      entitlement = await verifiers.apple(verification.body, userId);
    } else {
      entitlement = await verifiers.google(verification.body, userId, {
        resolveOutOfAppLineage: async (expiredPurchaseToken) => {
          const { data, error } = await rpc(
            "resolve_google_purchase_token_binding",
            { raw_purchase_token: expiredPurchaseToken },
          );
          if (error || data == null || typeof data !== "object") return false;
          const binding = data as Record<string, unknown>;
          return binding.store_id === String(row.storeId ?? "") &&
            binding.user_id === userId;
        },
      });
    }
    if (entitlement.platform !== verification.platform) {
      throw new Error("REFRESH_PLATFORM_MISMATCH");
    }

    const apply = buildRefreshApplyRequest(row, entitlement);
    const { error: applyError } = await rpc(apply.name, apply.params);
    if (applyError) throw new Error("REFRESH_APPLY_FAILED");
    if (
      entitlement.platform === "google_play" &&
      entitlement.googleAcknowledgementPending === true
    ) {
      const acknowledge = verifiers.acknowledgeGoogle;
      if (!acknowledge) throw new Error("REFRESH_ACKNOWLEDGER_MISSING");
      await acknowledge(
        String(row.purchaseToken ?? ""),
        entitlement.productId,
        userId,
        String(row.storeId ?? ""),
        entitlement.googleOutOfApp === true,
      );
    }
    succeeded = true;
    return true;
  } catch (refreshError) {
    console.error(
      "refresh-store-entitlements",
      refreshError instanceof Error ? refreshError.message : "REFRESH_FAILED",
    );
    return false;
  } finally {
    try {
      const { error: releaseError } = await rpc(
        "release_store_entitlement_refresh",
        {
          target_entitlement_id: id,
          refresh_succeeded: succeeded,
        },
      );
      if (releaseError) {
        console.error("refresh-store-entitlements", "REFRESH_RELEASE_FAILED");
      }
    } catch {
      console.error("refresh-store-entitlements", "REFRESH_RELEASE_FAILED");
    }
  }
}

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
    { requested_limit: REFRESH_CLAIM_LIMIT },
  );
  if (error) return json(500, { error: "REFRESH_QUEUE_UNAVAILABLE" });
  const rows = Array.isArray(data) ? data as RefreshRow[] : [];

  const rpc: RefreshRpc = async (name, params) => {
    const { data: rpcData, error: rpcError } = await admin.rpc(name, params);
    return { data: rpcData, error: rpcError };
  };
  const results = await mapWithConcurrency(
    rows,
    REFRESH_CONCURRENCY_LIMIT,
    (row) => refreshEntitlementRow(row, rpc),
  );

  return json(200, {
    processed: rows.length,
    refreshed: results.filter(Boolean).length,
    failed: results.filter((value) => !value).length,
  });
}

if (import.meta.main) Deno.serve(handle);
