import {
  appleAccountBindingKind,
  appleEntitlementPeriodEnd,
  appleEnvironmentOrder,
  assertAppleStoreBinding,
  assertGooglePurchaseIdentity,
  assertGoogleSubscriptionStateIsVerifiable,
  classifyVerificationFailure,
  decodeAppleClientTransaction,
  expectedCurrentPurchaseTokenHash,
  googleAccessToken,
  googleAcknowledgementRequired,
  googleAutoRenews,
  googleEntitlementStatus,
  googleLinkedPurchaseToken,
  isAllowedStoreProduct,
  parseBoundedJsonBody,
  RequestBodyTooLargeError,
  selectGoogleLineItem,
  setGoogleAccessTokenTestHook,
} from "./index.ts";

function unsignedJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    btoa(JSON.stringify(value))
      .replaceAll("+", "-")
      .replaceAll("/", "_")
      .replaceAll("=", "");
  return `${encode({ alg: "none" })}.${encode(payload)}.client-routing-only`;
}

Deno.test("TestFlight StoreKit payload routes to sandbox before production", () => {
  const transaction = decodeAppleClientTransaction({
    verificationData: unsignedJwt({
      environment: "Sandbox",
      transactionId: "2000000123456789",
    }),
  });
  if (transaction?.transactionId !== "2000000123456789") {
    throw new Error("transaction ID was not recovered from StoreKit JWS");
  }
  const order = appleEnvironmentOrder(transaction.environment);
  if (order[0].name !== "sandbox" || order[1].name !== "production") {
    throw new Error("TestFlight must use the sandbox endpoint first");
  }
});

Deno.test("unknown Apple environment retains production-first fallback", () => {
  const order = appleEnvironmentOrder(null);
  if (order[0].name !== "production" || order[1].name !== "sandbox") {
    throw new Error("unknown transactions must retain Apple's fallback order");
  }
});

Deno.test("Apple account token distinguishes store-bound Build 24 from legacy", () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const userId = "22222222-2222-4222-8222-222222222222";
  if (
    appleAccountBindingKind(storeId, storeId, userId) !== "store" ||
    appleAccountBindingKind(storeId.toUpperCase(), storeId, userId) !==
      "store" ||
    appleAccountBindingKind(userId, storeId, userId) !== "legacy_user" ||
    appleAccountBindingKind(
        "33333333-3333-4333-8333-333333333333",
        storeId,
        userId,
      ) !== "unresolved"
  ) {
    throw new Error("Apple appAccountToken binding was classified unsafely");
  }
});

Deno.test("Apple store binding rejects ambiguous legacy receipts", () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const userId = "22222222-2222-4222-8222-222222222222";
  assertAppleStoreBinding(storeId, storeId, userId, [], false);
  assertAppleStoreBinding(userId, storeId, userId, [], true);
  assertAppleStoreBinding(
    "33333333-3333-4333-8333-333333333333",
    storeId,
    userId,
    [storeId],
    false,
  );

  for (
    const attempt of [
      () => assertAppleStoreBinding(userId, storeId, userId, [], false),
      () =>
        assertAppleStoreBinding(
          "33333333-3333-4333-8333-333333333333",
          storeId,
          userId,
          ["44444444-4444-4444-8444-444444444444"],
          true,
        ),
    ]
  ) {
    let rejected = false;
    try {
      attempt();
    } catch {
      rejected = true;
    }
    if (!rejected) throw new Error("ambiguous Apple receipt was accepted");
  }
});

Deno.test("store product allow-list rejects prefix lookalikes", () => {
  if (
    !isAllowedStoreProduct(
      "app_store",
      "com.damanak.subscription.growth.yearly",
    ) ||
    isAllowedStoreProduct(
      "app_store",
      "com.damanak.subscription.growth.yearly.attacker",
    ) ||
    !isAllowedStoreProduct(
      "google_play",
      "com.damanak.subscription.scale",
      "monthly",
    ) ||
    isAllowedStoreProduct(
      "google_play",
      "com.damanak.subscription.scale",
      "weekly",
    )
  ) {
    throw new Error("store identifiers must match the exact catalog");
  }
});

Deno.test("Google deferred replacement keeps the currently entitled item", () => {
  const selected = selectGoogleLineItem({
    lineItems: [
      {
        productId: "com.damanak.subscription.starter",
        expiryTime: "2026-09-15T00:00:00Z",
        offerDetails: { basePlanId: "monthly" },
        deferredItemReplacement: {
          productId: "com.damanak.subscription.growth",
        },
      },
      {
        productId: "com.damanak.subscription.growth",
        expiryTime: "2026-10-15T00:00:00Z",
        offerDetails: { basePlanId: "monthly" },
      },
    ],
  }, Date.parse("2026-08-31T00:00:00Z"));
  if (selected?.productId !== "com.damanak.subscription.starter") {
    throw new Error("a deferred product must not be granted early");
  }
});

Deno.test("Google deferred replacement remains renewable", () => {
  if (
    !googleAutoRenews({
      autoRenewingPlan: { autoRenewEnabled: false },
      deferredItemReplacement: {
        productId: "com.damanak.subscription.growth",
      },
    }) ||
    googleAutoRenews({
      autoRenewingPlan: { autoRenewEnabled: false },
    })
  ) {
    throw new Error("a scheduled replacement must keep auto-renewal visible");
  }
});

Deno.test("Google line selection avoids a farther scheduled period", () => {
  const selected = selectGoogleLineItem({
    lineItems: [
      {
        productId: "com.damanak.subscription.growth",
        expiryTime: "2026-10-15T00:00:00Z",
        offerDetails: { basePlanId: "yearly" },
      },
      {
        productId: "com.damanak.subscription.starter",
        expiryTime: "2026-09-15T00:00:00Z",
        offerDetails: { basePlanId: "monthly" },
      },
    ],
  }, Date.parse("2026-08-31T00:00:00Z"));
  if (selected?.productId !== "com.damanak.subscription.starter") {
    throw new Error("the nearest live period must win conservatively");
  }
});

Deno.test("Apple grace uses the signed grace deadline", () => {
  const periodEnd = appleEntitlementPeriodEnd(
    "grace",
    { expiresDate: Date.parse("2026-08-30T00:00:00Z") },
    { gracePeriodExpiresDate: Date.parse("2026-09-07T00:00:00Z") },
  );
  if (periodEnd !== "2026-09-07T00:00:00.000Z") {
    throw new Error("grace must not be truncated to the expired transaction");
  }
});

Deno.test("Google terminal and recovery states stay conservative", () => {
  const future = "2026-09-30T00:00:00.000Z";
  const now = Date.parse("2026-08-31T00:00:00Z");
  if (
    googleEntitlementStatus(
        "SUBSCRIPTION_STATE_CANCELED",
        future,
        now,
      ) !== "active" ||
    googleEntitlementStatus(
        "SUBSCRIPTION_STATE_EXPIRED",
        future,
        now,
      ) !== "expired" ||
    googleEntitlementStatus(
        "SUBSCRIPTION_STATE_ON_HOLD",
        future,
        now,
      ) !== "past_due"
  ) {
    throw new Error("Google subscription states were normalized incorrectly");
  }
});

Deno.test("Google linked token accepts only a plausible provider token", () => {
  const token = "linked-provider-token-1234567890";
  if (
    googleLinkedPurchaseToken({ linkedPurchaseToken: `  ${token}  ` }) !==
      token ||
    googleLinkedPurchaseToken({ linkedPurchaseToken: "short" }) !== null
  ) {
    throw new Error("linked purchase tokens must be normalized safely");
  }
});

Deno.test("verification failures expose only stable public categories", () => {
  const cases = [
    ["APPLE_ACCOUNT_MISMATCH", 422, "PURCHASE_NOT_VALID"],
    ["GOOGLE_LINKED_PURCHASE_UNRESOLVED", 409, "PURCHASE_CONFLICT"],
    ["SANDBOX_REVIEW_WINDOW_CLOSED", 403, "SANDBOX_NOT_AVAILABLE"],
    ["GOOGLE_AUTH_503", 503, "PURCHASE_PROVIDER_UNAVAILABLE"],
    ["unexpected database detail", 500, "PURCHASE_VERIFICATION_UNAVAILABLE"],
  ] as const;
  for (const [message, status, code] of cases) {
    const failure = classifyVerificationFailure(message);
    if (failure.status !== status || failure.code !== code) {
      throw new Error(`unexpected public failure for ${message}`);
    }
  }
});

Deno.test("Google pending states fail closed with stable public errors", () => {
  const cases = [
    [
      "SUBSCRIPTION_STATE_PENDING",
      "GOOGLE_SUBSCRIPTION_PENDING",
      "STORE_PURCHASE_PENDING",
      true,
    ],
    [
      "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED",
      "GOOGLE_SUBSCRIPTION_PENDING_PURCHASE_CANCELED",
      "STORE_PURCHASE_PENDING_CANCELED",
      false,
    ],
  ] as const;

  for (const [state, internalCode, publicCode, retryable] of cases) {
    let message = "";
    try {
      assertGoogleSubscriptionStateIsVerifiable(state);
    } catch (error) {
      message = error instanceof Error ? error.message : String(error);
    }
    if (message !== internalCode) {
      throw new Error(`pending state did not fail closed: ${state}`);
    }
    const failure = classifyVerificationFailure(message);
    if (
      failure.status !== 409 ||
      failure.code !== publicCode ||
      failure.retryable !== retryable
    ) {
      throw new Error(`pending state was not classified stably: ${state}`);
    }
  }
});

Deno.test("unknown Google subscription states fail closed without expiry mutation", () => {
  let message = "";
  try {
    assertGoogleSubscriptionStateIsVerifiable(
      "SUBSCRIPTION_STATE_FUTURE_PROVIDER_VALUE",
    );
  } catch (error) {
    message = error instanceof Error ? error.message : String(error);
  }
  if (message !== "GOOGLE_SUBSCRIPTION_STATE_UNSUPPORTED") {
    throw new Error("an unknown Google state was not rejected");
  }
  const failure = classifyVerificationFailure(message);
  if (
    failure.status !== 503 ||
    failure.code !== "PURCHASE_VERIFICATION_UNAVAILABLE" ||
    !failure.retryable
  ) {
    throw new Error("an unknown Google state was not classified safely");
  }
});

Deno.test("stale and superseded Google receipts expose safe public outcomes", () => {
  const stale = classifyVerificationFailure("STORE_RECEIPT_STALE");
  const superseded = classifyVerificationFailure(
    "GOOGLE_PURCHASE_TOKEN_SUPERSEDED",
  );
  if (
    stale.status !== 409 ||
    stale.code !== "PURCHASE_VERIFICATION_UNAVAILABLE" ||
    !stale.retryable ||
    superseded.status !== 409 ||
    superseded.code !== "PURCHASE_CONFLICT" ||
    superseded.retryable
  ) {
    throw new Error("receipt freshness outcomes were not classified safely");
  }
});

Deno.test("Google purchase identity binds both account and store exactly", () => {
  const body = { storeId: "11111111-1111-4111-8111-111111111111" };
  const userId = "22222222-2222-4222-8222-222222222222";
  assertGooglePurchaseIdentity(
    {
      externalAccountIdentifiers: {
        obfuscatedExternalAccountId: userId,
        obfuscatedExternalProfileId: body.storeId,
      },
    },
    body,
    userId,
  );

  for (
    const identifiers of [
      {
        obfuscatedExternalAccountId: "33333333-3333-4333-8333-333333333333",
        obfuscatedExternalProfileId: body.storeId,
      },
      {
        obfuscatedExternalAccountId: userId,
        obfuscatedExternalProfileId: "44444444-4444-4444-8444-444444444444",
      },
      { obfuscatedExternalAccountId: userId },
    ]
  ) {
    let rejected = false;
    try {
      assertGooglePurchaseIdentity(
        { externalAccountIdentifiers: identifiers },
        body,
        userId,
      );
    } catch {
      rejected = true;
    }
    if (!rejected) {
      throw new Error("a direct purchase escaped exact account/store binding");
    }
  }
});

Deno.test("Google refresh alone tolerates a missing legacy profile id", () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const userId = "22222222-2222-4222-8222-222222222222";
  assertGooglePurchaseIdentity({
    externalAccountIdentifiers: {
      obfuscatedExternalAccountId: userId,
    },
  }, {
    storeId,
    knownOriginalTransactionId: `token_${"a".repeat(64)}`,
  }, userId);
});

Deno.test("Google Build 23 profile compatibility is explicit and account-bound", () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const userId = "22222222-2222-4222-8222-222222222222";
  assertGooglePurchaseIdentity(
    {
      externalAccountIdentifiers: {
        obfuscatedExternalAccountId: userId,
      },
    },
    { storeId },
    userId,
    { allowMissingDirectProfile: true },
  );

  let rejected = false;
  try {
    assertGooglePurchaseIdentity(
      {
        externalAccountIdentifiers: {
          obfuscatedExternalAccountId: "33333333-3333-4333-8333-333333333333",
        },
      },
      { storeId },
      userId,
      { allowMissingDirectProfile: true },
    );
  } catch {
    rejected = true;
  }
  if (!rejected) {
    throw new Error("legacy profile compatibility ignored account binding");
  }
});

Deno.test("Google out-of-app purchase reuses only matched expired lineage", () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const userId = "22222222-2222-4222-8222-222222222222";
  const expiredPurchaseToken = "expired-provider-token-1234567890";
  const purchase = {
    outOfAppPurchaseContext: {
      expiredExternalAccountIdentifiers: {
        obfuscatedExternalAccountId: userId,
        obfuscatedExternalProfileId: storeId,
      },
      expiredPurchaseToken,
    },
  };
  assertGooglePurchaseIdentity(purchase, { storeId }, userId);
  if (googleLinkedPurchaseToken(purchase) !== expiredPurchaseToken) {
    throw new Error("expired purchase token was not linked to the new lineage");
  }

  let rejected = false;
  try {
    assertGooglePurchaseIdentity(
      {
        outOfAppPurchaseContext: {
          expiredExternalAccountIdentifiers: {
            obfuscatedExternalAccountId: userId,
            obfuscatedExternalProfileId: "33333333-3333-4333-8333-333333333333",
          },
          expiredPurchaseToken,
        },
      },
      { storeId },
      userId,
    );
  } catch {
    rejected = true;
  }
  if (!rejected) {
    throw new Error("out-of-app lineage escaped the expired store binding");
  }
});

Deno.test("Google out-of-app lineage rejects missing or conflicting expired tokens", () => {
  for (
    const purchase of [
      {
        outOfAppPurchaseContext: {
          expiredExternalAccountIdentifiers: {},
        },
      },
      {
        linkedPurchaseToken: "linked-provider-token-1234567890",
        outOfAppPurchaseContext: {
          expiredPurchaseToken: "different-expired-token-1234567890",
        },
      },
    ]
  ) {
    let rejected = false;
    try {
      googleLinkedPurchaseToken(purchase);
    } catch {
      rejected = true;
    }
    if (!rejected) {
      throw new Error("invalid out-of-app lineage was silently accepted");
    }
  }
});

Deno.test("Google out-of-app missing identifiers require trusted token lineage", () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const userId = "22222222-2222-4222-8222-222222222222";
  const purchase = {
    outOfAppPurchaseContext: {
      expiredPurchaseToken: "expired-provider-token-1234567890",
    },
  };
  let rejected = false;
  try {
    assertGooglePurchaseIdentity(purchase, { storeId }, userId);
  } catch {
    rejected = true;
  }
  if (!rejected) {
    throw new Error("unbound out-of-app purchase bypassed lineage lookup");
  }
  assertGooglePurchaseIdentity(purchase, { storeId }, userId, {
    trustedOutOfAppLineage: true,
  });
});

Deno.test("Google acknowledgement state is fail-closed", () => {
  if (
    !googleAcknowledgementRequired("ACKNOWLEDGEMENT_STATE_PENDING") ||
    googleAcknowledgementRequired("ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED")
  ) {
    throw new Error("Google acknowledgement state was reversed");
  }
  let rejected = false;
  try {
    googleAcknowledgementRequired("ACKNOWLEDGEMENT_STATE_FUTURE");
  } catch {
    rejected = true;
  }
  if (!rejected) {
    throw new Error("unknown Google acknowledgement state did not fail closed");
  }
});

Deno.test("purchase JSON limit counts streamed bytes without Content-Length", async () => {
  const valid = await parseBoundedJsonBody<{ storeId: string }>(
    new Request("https://example.test/verify", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ storeId: "store-1" }),
    }),
    128,
  );
  if (valid.storeId !== "store-1") {
    throw new Error("bounded JSON parsing changed a valid payload");
  }

  const oversizedRequest = new Request("https://example.test/verify", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(new Uint8Array(65 * 1024));
        controller.close();
      },
    }),
  });
  let rejected = false;
  try {
    await parseBoundedJsonBody(oversizedRequest);
  } catch (error) {
    rejected = error instanceof RequestBodyTooLargeError;
  }
  if (!rejected) {
    throw new Error("streamed JSON exceeded 64 KiB without being rejected");
  }
});

Deno.test("purchase JSON limit rejects an oversized advertised body", async () => {
  const request = new Request("https://example.test/verify", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "content-length": String(65 * 1024),
    },
    body: "{}",
  });
  let rejected = false;
  try {
    await parseBoundedJsonBody(request);
  } catch (error) {
    rejected = error instanceof RequestBodyTooLargeError;
  }
  if (!rejected) {
    throw new Error("oversized Content-Length was not rejected before parsing");
  }
});

Deno.test("Google OAuth token cache is single-flight and expires safely", async () => {
  let calls = 0;
  let nowMs = Date.parse("2026-08-31T00:00:00Z");
  setGoogleAccessTokenTestHook({
    now: () => nowMs,
    fetchToken: async () => {
      calls += 1;
      await Promise.resolve();
      return {
        accessToken: `access-token-${calls}`,
        expiresInSeconds: 120,
      };
    },
  });
  try {
    const tokens = await Promise.all([
      googleAccessToken(),
      googleAccessToken(),
      googleAccessToken(),
    ]);
    if (calls !== 1 || tokens.some((token) => token !== "access-token-1")) {
      throw new Error(
        "concurrent verifications did not share one OAuth request",
      );
    }

    nowMs += 108_000;
    const refreshed = await googleAccessToken();
    if (Number(calls) !== 2 || refreshed !== "access-token-2") {
      throw new Error("expired OAuth cache entry was not refreshed");
    }
  } finally {
    setGoogleAccessTokenTestHook(null);
  }
});

Deno.test("only a Google refresh sends the expected current token hash", () => {
  const hash = "a".repeat(64);
  const entitlement = {
    platform: "google_play" as const,
    productId: "com.damanak.subscription.growth",
    basePlanId: "monthly",
    transactionId: `order_${"b".repeat(64)}`,
    originalTransactionId: `token_${hash}`,
    status: "active" as const,
    environment: "production" as const,
    periodStart: "2026-08-01T00:00:00.000Z",
    periodEnd: "2026-09-01T00:00:00.000Z",
    autoRenews: true,
    purchaseTokenHash: hash,
  };
  if (
    expectedCurrentPurchaseTokenHash(false, entitlement) !== null ||
    expectedCurrentPurchaseTokenHash(true, entitlement) !== hash
  ) {
    throw new Error("direct and refresh RPC lineage guards were conflated");
  }
});
