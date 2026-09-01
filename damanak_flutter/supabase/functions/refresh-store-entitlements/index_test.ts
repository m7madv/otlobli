import type { VerifiedEntitlement } from "../verify-store-purchase/index.ts";
import {
  buildRefreshApplyRequest,
  buildRefreshVerificationBody,
  handle,
  mapWithConcurrency,
  REFRESH_CLAIM_LIMIT,
  REFRESH_CONCURRENCY_LIMIT,
  refreshEntitlementRow,
} from "./index.ts";

Deno.test("scheduled entitlement refresh rejects an invalid secret", async () => {
  Deno.env.set("ENTITLEMENT_REFRESH_SECRET", "expected-secret");
  const response = await handle(
    new Request("https://example.test", {
      method: "POST",
      headers: { authorization: "Bearer wrong-secret" },
    }),
  );
  if (response.status !== 401) {
    throw new Error("refresh endpoint must reject an invalid scheduler secret");
  }
});

Deno.test("Google refresh preserves the current entitlement lineage", () => {
  const verification = buildRefreshVerificationBody({
    storeId: "store-id",
    platform: "google_play",
    originalTransactionId: "token_existing-lineage",
    purchaseToken: "raw-provider-purchase-token",
  });
  if (
    verification.platform !== "google_play" ||
    verification.body.knownOriginalTransactionId !==
      "token_existing-lineage" ||
    verification.body.verificationData !== "raw-provider-purchase-token"
  ) {
    throw new Error("refresh must not create a second Google lineage");
  }
});

Deno.test("Apple refresh uses the bound original transaction", () => {
  const verification = buildRefreshVerificationBody({
    storeId: "store-id",
    platform: "app_store",
    originalTransactionId: "2000000123456789",
  });
  if (
    verification.platform !== "app_store" ||
    verification.body.purchaseId !== "2000000123456789"
  ) {
    throw new Error("Apple refresh must use the current receipt binding");
  }
});

Deno.test("refresh rejects an unknown queue platform before provider I/O", () => {
  let rejected = false;
  try {
    buildRefreshVerificationBody({ platform: "manual" });
  } catch {
    rejected = true;
  }
  if (!rejected) throw new Error("unknown refresh platforms must be rejected");
});

Deno.test("refresh claims a large batch but limits provider concurrency", async () => {
  if (REFRESH_CLAIM_LIMIT !== 100 || REFRESH_CONCURRENCY_LIMIT !== 10) {
    throw new Error(
      "refresh batch and concurrency limits changed unexpectedly",
    );
  }

  let active = 0;
  let maximumActive = 0;
  const values = Array.from({ length: 37 }, (_, index) => index);
  const results = await mapWithConcurrency(
    values,
    REFRESH_CLAIM_LIMIT,
    async (value) => {
      active += 1;
      maximumActive = Math.max(maximumActive, active);
      await new Promise((resolve) => setTimeout(resolve, 1));
      active -= 1;
      return value * 2;
    },
  );

  if (maximumActive > 10 || maximumActive !== 10) {
    throw new Error(`expected exactly 10 workers, saw ${maximumActive}`);
  }
  if (results.some((value, index) => value !== index * 2)) {
    throw new Error("bounded refresh processing must preserve result order");
  }
});

Deno.test("Google refresh uses the receipt-aware RPC and stale-row hash", () => {
  const tokenHash = "a".repeat(64);
  const linkedTokenHash = "b".repeat(64);
  const request = buildRefreshApplyRequest(
    {
      storeId: "11111111-1111-4111-8111-111111111111",
      userId: "22222222-2222-4222-8222-222222222222",
      purchaseToken: "raw-google-purchase-token-current",
    },
    {
      platform: "google_play",
      productId: "com.damanak.subscription.growth",
      basePlanId: "monthly",
      transactionId: `order_${"c".repeat(64)}`,
      originalTransactionId: `token_${tokenHash}`,
      status: "active",
      environment: "production",
      periodStart: "2026-08-01T00:00:00.000Z",
      periodEnd: "2026-09-01T00:00:00.000Z",
      autoRenews: true,
      purchaseTokenHash: tokenHash,
      linkedPurchaseTokenHash: linkedTokenHash,
    },
  );

  if (request.name !== "apply_verified_store_entitlement_with_receipt") {
    throw new Error("refresh must always use the receipt-aware apply RPC");
  }
  const params = request.params;
  if (
    params.raw_purchase_token !== "raw-google-purchase-token-current" ||
    params.purchase_token_hash !== tokenHash ||
    params.linked_purchase_token_hash !== linkedTokenHash ||
    params.expected_current_purchase_token_hash !== tokenHash
  ) {
    throw new Error("Google refresh did not preserve the stale-row guard");
  }
});

Deno.test("Apple refresh sends null receipt-lineage fields", () => {
  const request = buildRefreshApplyRequest(
    {
      storeId: "11111111-1111-4111-8111-111111111111",
      userId: "22222222-2222-4222-8222-222222222222",
      purchaseToken: "must-not-leak-to-apple",
    },
    {
      platform: "app_store",
      productId: "com.damanak.subscription.growth.monthly",
      basePlanId: "",
      transactionId: "2000000123456790",
      originalTransactionId: "2000000123456789",
      status: "active",
      environment: "sandbox",
      periodStart: "2026-08-01T00:00:00.000Z",
      periodEnd: "2026-09-01T00:00:00.000Z",
      autoRenews: true,
      purchaseTokenHash: "a".repeat(64),
      linkedPurchaseTokenHash: "b".repeat(64),
    },
  );
  const params = request.params;
  if (
    request.name !== "apply_verified_store_entitlement_with_receipt" ||
    params.raw_purchase_token !== null ||
    params.purchase_token_hash !== null ||
    params.linked_purchase_token_hash !== null ||
    params.expected_current_purchase_token_hash !== null
  ) {
    throw new Error("Apple refresh must not send Google receipt lineage");
  }
});

Deno.test("Apple Sandbox terminal refresh uses the reducing RPC", () => {
  const request = buildRefreshApplyRequest(
    {
      storeId: "11111111-1111-4111-8111-111111111111",
      userId: "22222222-2222-4222-8222-222222222222",
      purchaseToken: "must-not-leak-to-apple",
    },
    {
      platform: "app_store",
      productId: "com.damanak.subscription.growth.monthly",
      basePlanId: "",
      transactionId: "2000000123456791",
      originalTransactionId: "2000000123456789",
      status: "canceled",
      environment: "sandbox",
      periodStart: "2026-08-01T00:00:00.000Z",
      periodEnd: "2026-09-01T00:00:00.000Z",
      autoRenews: false,
    },
  );

  if (
    request.name !== "apply_verified_sandbox_terminal_entitlement" ||
    request.params.billing_platform !== "app_store" ||
    request.params.entitlement_status !== "canceled" ||
    request.params.external_original_transaction_id !== "2000000123456789"
  ) {
    throw new Error("Apple Sandbox terminal state could be reactivated");
  }
});

Deno.test("Google Sandbox past-due refresh keeps the receipt-aware RPC", () => {
  const purchaseToken = "google-sandbox-current-token";
  const tokenHash = "c".repeat(64);
  const request = buildRefreshApplyRequest(
    {
      storeId: "11111111-1111-4111-8111-111111111111",
      userId: "22222222-2222-4222-8222-222222222222",
      purchaseToken,
    },
    {
      platform: "google_play",
      productId: "com.damanak.subscription.growth",
      basePlanId: "monthly",
      transactionId: "google-sandbox-current-token",
      originalTransactionId: "google-sandbox-current-token",
      status: "past_due",
      environment: "sandbox",
      periodStart: "2026-08-01T00:00:00.000Z",
      periodEnd: "2026-09-01T00:00:00.000Z",
      autoRenews: true,
      purchaseTokenHash: tokenHash,
      linkedPurchaseTokenHash: null,
    },
  );

  if (
    request.name !== "apply_verified_store_entitlement_with_receipt" ||
    request.params.billing_platform !== "google_play" ||
    request.params.raw_purchase_token !== purchaseToken ||
    request.params.purchase_token_hash !== tokenHash
  ) {
    throw new Error("Google Sandbox past-due refresh used Apple terminal flow");
  }
});

Deno.test("refresh releases every claimed row after applying it", async () => {
  const calls: Array<{ name: string; params: Record<string, unknown> }> = [];
  const entitlement: VerifiedEntitlement = {
    platform: "app_store",
    productId: "com.damanak.subscription.starter.monthly",
    basePlanId: "",
    transactionId: "2000000123456790",
    originalTransactionId: "2000000123456789",
    status: "active",
    environment: "production",
    periodStart: "2026-08-01T00:00:00.000Z",
    periodEnd: "2026-09-01T00:00:00.000Z",
    autoRenews: true,
  };
  const refreshed = await refreshEntitlementRow(
    {
      id: "33333333-3333-4333-8333-333333333333",
      storeId: "11111111-1111-4111-8111-111111111111",
      userId: "22222222-2222-4222-8222-222222222222",
      platform: "app_store",
      originalTransactionId: entitlement.originalTransactionId,
    },
    async (name, params) => {
      calls.push({ name, params });
      return { error: null };
    },
    {
      apple: async () => entitlement,
      google: async () => entitlement,
    },
  );

  if (!refreshed || calls.length !== 2) {
    throw new Error("refresh must apply once and release once");
  }
  if (
    calls[0].name !== "apply_verified_store_entitlement_with_receipt" ||
    calls[1].name !== "release_store_entitlement_refresh" ||
    calls[1].params.refresh_succeeded !== true
  ) {
    throw new Error("refresh did not release the claimed entitlement");
  }
});

Deno.test("Google refresh resolves an incomplete out-of-app lineage by receipt", async () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const userId = "22222222-2222-4222-8222-222222222222";
  const tokenHash = "a".repeat(64);
  let resolverAccepted = false;
  const refreshed = await refreshEntitlementRow(
    {
      id: "33333333-3333-4333-8333-333333333333",
      storeId,
      userId,
      platform: "google_play",
      originalTransactionId: `token_${tokenHash}`,
      purchaseToken: "current-provider-token-with-safe-length",
    },
    async (name) => {
      if (name === "resolve_google_purchase_token_binding") {
        return {
          error: null,
          data: { store_id: storeId, user_id: userId },
        };
      }
      return { error: null };
    },
    {
      apple: async () => {
        throw new Error("unexpected Apple verifier");
      },
      google: async (_body, _user, options) => {
        resolverAccepted = await options!.resolveOutOfAppLineage!(
          "expired-provider-token-with-safe-length",
        );
        return {
          platform: "google_play",
          productId: "com.damanak.subscription.growth",
          basePlanId: "monthly",
          transactionId: `order_${"b".repeat(64)}`,
          originalTransactionId: `token_${tokenHash}`,
          status: "active",
          environment: "production",
          periodStart: "2026-08-01T00:00:00.000Z",
          periodEnd: "2026-09-01T00:00:00.000Z",
          autoRenews: true,
          purchaseTokenHash: tokenHash,
        };
      },
    },
  );

  if (!refreshed || !resolverAccepted) {
    throw new Error("refresh did not trust the exact stored token lineage");
  }
});

Deno.test("Google refresh acknowledges a pending current token after apply", async () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const userId = "22222222-2222-4222-8222-222222222222";
  const tokenHash = "a".repeat(64);
  let acknowledged = false;
  const refreshed = await refreshEntitlementRow(
    {
      id: "33333333-3333-4333-8333-333333333333",
      storeId,
      userId,
      platform: "google_play",
      originalTransactionId: `token_${tokenHash}`,
      purchaseToken: "current-provider-token-with-safe-length",
    },
    async () => ({ error: null }),
    {
      apple: async () => {
        throw new Error("unexpected Apple verifier");
      },
      google: async () => ({
        platform: "google_play",
        productId: "com.damanak.subscription.growth",
        basePlanId: "monthly",
        transactionId: `order_${"b".repeat(64)}`,
        originalTransactionId: `token_${tokenHash}`,
        status: "active",
        environment: "production",
        periodStart: "2026-08-01T00:00:00.000Z",
        periodEnd: "2026-09-01T00:00:00.000Z",
        autoRenews: true,
        purchaseTokenHash: tokenHash,
        googleAcknowledgementPending: true,
      }),
      acknowledgeGoogle: async (token, productId, accountId, profileId) => {
        acknowledged = token === "current-provider-token-with-safe-length" &&
          productId === "com.damanak.subscription.growth" &&
          accountId === userId &&
          profileId === storeId;
      },
    },
  );

  if (!refreshed || !acknowledged) {
    throw new Error("pending Google purchase was not acknowledged safely");
  }
});
