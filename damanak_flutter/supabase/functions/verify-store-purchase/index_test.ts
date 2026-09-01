import {
  VerificationException,
  VerificationStatus,
} from "@apple/app-store-server-library";
import {
  appleAccountBindingKind,
  appleAccountTokenUpdateRequest,
  appleEntitlementPeriodEnd,
  appleEnvironmentOrder,
  applyThenMaybeScheduleAppleAccountTokenUpdate,
  assertAppleOrphanRecoveryEligible,
  assertAppleRecoveryProofForBinding,
  assertAppleRecoveryTransactionProof,
  assertAppleStoreBinding,
  assertGoogleOrphanRecoveryEligible,
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
  googleOrphanRecoveryBinding,
  isAllowedStoreProduct,
  isAppleSandboxTerminalEntitlement,
  parseBoundedJsonBody,
  RequestBodyTooLargeError,
  resolveTrustedGoogleOutOfAppLineage,
  scheduleBestEffortPostCommitTask,
  selectGoogleLineItem,
  setGoogleAccessTokenTestHook,
  storeEntitlementRefreshIsAllowed,
  storeRefreshSnapshotCanBeReused,
  storeRefreshSnapshotIsFresh,
  verifyAppleRecoveryTransactionWithFallback,
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

Deno.test("recent server refresh snapshot bypasses another provider call", () => {
  const now = Date.parse("2026-09-01T12:00:00.000Z");
  if (
    !storeRefreshSnapshotIsFresh("2026-09-01T11:58:30.000Z", now) ||
    storeRefreshSnapshotIsFresh("2026-09-01T11:57:59.000Z", now) ||
    storeRefreshSnapshotIsFresh("2026-09-01T12:00:31.000Z", now) ||
    storeRefreshSnapshotIsFresh("invalid", now)
  ) {
    throw new Error("refresh snapshot freshness boundary is unsafe");
  }
});

Deno.test("refresh cache requires a still-unexpired direct store period", () => {
  const now = Date.parse("2026-09-01T12:00:00.000Z");
  const fresh = "2026-09-01T11:59:00.000Z";
  if (
    !storeRefreshSnapshotCanBeReused({
      status: "active",
      current_period_end: "2026-09-01T12:05:00.000Z",
      last_store_verified_at: fresh,
    }, now) ||
    storeRefreshSnapshotCanBeReused({
      status: "active",
      current_period_end: "2026-09-01T12:00:00.000Z",
      last_store_verified_at: fresh,
    }, now) ||
    storeRefreshSnapshotCanBeReused({
      status: "canceled",
      current_period_end: "2026-09-01T12:05:00.000Z",
      last_store_verified_at: fresh,
    }, now) ||
    storeRefreshSnapshotCanBeReused({
      status: "active",
      current_period_end: "invalid",
      last_store_verified_at: fresh,
    }, now)
  ) {
    throw new Error("expired or unusable store snapshot was cached");
  }
});

Deno.test("revoked tombstones never trigger an automatic provider refresh", () => {
  const now = Date.parse("2026-09-01T12:00:00.000Z");
  if (
    storeEntitlementRefreshIsAllowed({
      status: "revoked",
      period_end: "2030-01-01T00:00:00.000Z",
      auto_renews: true,
    }, now) ||
    storeEntitlementRefreshIsAllowed({
      status: "expired",
      period_end: "2030-01-01T00:00:00.000Z",
      auto_renews: true,
    }, now) ||
    !storeEntitlementRefreshIsAllowed({
      status: "active",
      period_end: "2026-09-01T12:05:00.000Z",
      auto_renews: false,
    }, now) ||
    !storeEntitlementRefreshIsAllowed({
      status: "past_due",
      environment: "production",
      period_end: "2026-08-01T00:00:00.000Z",
      auto_renews: true,
    }, now) ||
    storeEntitlementRefreshIsAllowed({
      platform: "app_store",
      status: "past_due",
      environment: "sandbox",
      period_end: "2030-01-01T00:00:00.000Z",
      auto_renews: true,
    }, now) ||
    !storeEntitlementRefreshIsAllowed({
      platform: "google_play",
      status: "past_due",
      environment: "sandbox",
      period_end: "2030-01-01T00:00:00.000Z",
      auto_renews: true,
    }, now)
  ) {
    throw new Error("terminal entitlement refresh policy is unsafe");
  }
});

Deno.test("terminal reducing path is exclusive to Apple Sandbox", () => {
  if (
    !isAppleSandboxTerminalEntitlement({
      platform: "app_store",
      environment: "sandbox",
      status: "canceled",
    }) ||
    isAppleSandboxTerminalEntitlement({
      platform: "google_play",
      environment: "sandbox",
      status: "canceled",
    }) ||
    isAppleSandboxTerminalEntitlement({
      platform: "app_store",
      environment: "production",
      status: "canceled",
    }) ||
    isAppleSandboxTerminalEntitlement({
      platform: "app_store",
      environment: "sandbox",
      status: "active",
    })
  ) {
    throw new Error("Sandbox terminal routing escaped Apple-only scope");
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

Deno.test("Apple orphan recovery accepts a verified device JWS with extra fields", async () => {
  const oldStoreId = "33333333-3333-4333-8333-333333333333";
  const serverPayload = {
    bundleId: "com.damanak.damanak",
    transactionId: "2000000123456790",
    originalTransactionId: "2000000123456789",
    productId: "com.damanak.subscription.scale.yearly",
    environment: "Sandbox",
    appAccountToken: oldStoreId,
  };
  const serverSignedTransaction = unsignedJwt(serverPayload);
  const deviceSignedTransaction = unsignedJwt({
    ...serverPayload,
    deviceVerification: "device-specific-digest",
    deviceVerificationNonce: "55555555-5555-4555-8555-555555555555",
  });
  if (deviceSignedTransaction === serverSignedTransaction) {
    throw new Error("device and server fixtures must be different JWS values");
  }
  const entitlement = {
    transactionId: serverPayload.transactionId,
    originalTransactionId: serverPayload.originalTransactionId,
    productId: serverPayload.productId,
    environment: "sandbox" as const,
    appleAccountToken: oldStoreId,
  };
  let verifierCalls = 0;
  await assertAppleRecoveryTransactionProof(
    deviceSignedTransaction,
    entitlement,
    (candidate, environment) => {
      verifierCalls += 1;
      if (
        candidate !== deviceSignedTransaction || environment !== "sandbox"
      ) {
        throw new Error("unexpected Apple verifier input");
      }
      const decoded = decodeAppleClientTransaction({
        verificationData: candidate,
      });
      if (decoded == null) throw new Error("fixture decode failed");
      return Promise.resolve(decoded);
    },
  );
  if (verifierCalls !== 1) {
    throw new Error("Apple recovery did not require the signature verifier");
  }
});

Deno.test("Apple proof verifier is lazy for an existing binding", async () => {
  const entitlement = {
    transactionId: "2000000123456790",
    originalTransactionId: "2000000123456789",
    productId: "com.damanak.subscription.scale.yearly",
    environment: "sandbox" as const,
    appleAccountToken: "33333333-3333-4333-8333-333333333333",
  };
  const calls: string[] = [];
  const unavailableVerifier = () => {
    calls.push("verify");
    return Promise.reject(
      new Error("APPLE_CERTIFICATE_VERIFICATION_UNAVAILABLE"),
    );
  };
  await assertAppleRecoveryProofForBinding(
    false,
    "bound-receipt-does-not-need-orphan-proof",
    entitlement,
    unavailableVerifier,
  );
  if (calls.length !== 0) {
    throw new Error("an existing Apple binding invoked orphan verification");
  }

  let orphanRejected = false;
  try {
    await assertAppleRecoveryProofForBinding(
      true,
      "orphan-receipt-must-be-verified",
      entitlement,
      unavailableVerifier,
    );
  } catch {
    orphanRejected = true;
  }
  if (!orphanRejected || Number(calls.length) !== 1) {
    throw new Error("an Apple orphan bypassed fail-closed verification");
  }
});

Deno.test("Apple orphan recovery rejects forged or mismatched device JWS", async () => {
  const oldStoreId = "33333333-3333-4333-8333-333333333333";
  const payload = {
    bundleId: "com.damanak.damanak",
    transactionId: "2000000123456790",
    originalTransactionId: "2000000123456789",
    productId: "com.damanak.subscription.scale.yearly",
    environment: "Sandbox",
    appAccountToken: oldStoreId,
  };
  const entitlement = {
    transactionId: payload.transactionId,
    originalTransactionId: payload.originalTransactionId,
    productId: payload.productId,
    environment: "sandbox" as const,
    appleAccountToken: oldStoreId,
  };
  const mismatchedJws = unsignedJwt({
    ...payload,
    transactionId: "2000000123456791",
  });
  const mismatched = decodeAppleClientTransaction({
    verificationData: mismatchedJws,
  });
  if (mismatched == null) throw new Error("fixture decode failed");

  let defaultVerifierFailure = "";
  try {
    await assertAppleRecoveryTransactionProof(
      unsignedJwt(payload),
      entitlement,
    );
  } catch (error) {
    defaultVerifierFailure = error instanceof Error ? error.message : "";
  }
  if (defaultVerifierFailure !== "APPLE_RECOVERY_PROOF_INVALID") {
    throw new Error(
      "Apple official verifier or pinned roots did not initialize",
    );
  }

  for (
    const attempt of [
      () =>
        assertAppleRecoveryTransactionProof(
          mismatchedJws,
          entitlement,
          () => Promise.resolve(mismatched),
        ),
      () =>
        assertAppleRecoveryTransactionProof(
          unsignedJwt(payload),
          entitlement,
          () => Promise.reject(new Error("signature rejected")),
        ),
      () => assertAppleRecoveryTransactionProof("", entitlement),
    ]
  ) {
    let rejected = false;
    try {
      await attempt();
    } catch {
      rejected = true;
    }
    if (!rejected) {
      throw new Error("an untrusted Apple device JWS was accepted");
    }
  }

  for (
    const providerFailure of [
      "APPLE_CERTIFICATE_VERIFICATION_RETRYABLE",
      "APPLE_CERTIFICATE_VERIFICATION_UNAVAILABLE",
    ]
  ) {
    let preserved = false;
    try {
      await assertAppleRecoveryTransactionProof(
        unsignedJwt(payload),
        entitlement,
        () => Promise.reject(new Error(providerFailure)),
      );
    } catch (error) {
      preserved = error instanceof Error && error.message === providerFailure;
    }
    if (!preserved) {
      throw new Error("Apple provider failure lost its retryable category");
    }
  }
});

Deno.test("Apple recovery uses the online verifier when it succeeds", async () => {
  const calls: boolean[] = [];
  const verified = { bundleId: "com.damanak.damanak" };
  const result = await verifyAppleRecoveryTransactionWithFallback(
    unsignedJwt({
      bundleId: "com.damanak.damanak",
      environment: "Sandbox",
    }),
    "sandbox",
    (_candidate, _environment, enableOnlineChecks) => {
      calls.push(enableOnlineChecks);
      return Promise.resolve(verified);
    },
  );
  if (result !== verified || calls.join(",") !== "true") {
    throw new Error("Apple recovery bypassed a successful online verifier");
  }
});

Deno.test("Apple recovery retries online-check failures at the signed date", async () => {
  const signedTransaction = unsignedJwt({
    bundleId: "com.damanak.damanak",
    environment: "Sandbox",
    signedDate: Date.now(),
  });
  const retryableFailures: unknown[] = [
    new VerificationException(VerificationStatus.VERIFICATION_FAILURE),
    new VerificationException(
      VerificationStatus.RETRYABLE_VERIFICATION_FAILURE,
    ),
    new VerificationException(VerificationStatus.INVALID_CERTIFICATE),
    new Error("APPLE_CERTIFICATE_VERIFICATION_RETRYABLE"),
  ];
  const originalWarn = console.warn;
  console.warn = () => {};
  try {
    for (const onlineFailure of retryableFailures) {
      const calls: boolean[] = [];
      const verified = { bundleId: "com.damanak.damanak" };
      const result = await verifyAppleRecoveryTransactionWithFallback(
        signedTransaction,
        "sandbox",
        (_candidate, _environment, enableOnlineChecks) => {
          calls.push(enableOnlineChecks);
          return enableOnlineChecks
            ? Promise.reject(onlineFailure)
            : Promise.resolve(verified);
        },
      );
      if (result !== verified || calls.join(",") !== "true,false") {
        throw new Error("Apple signed-date fallback did not run exactly once");
      }
    }
  } finally {
    console.warn = originalWarn;
  }
});

Deno.test("Apple recovery never falls back for identity or chain-shape failures", async () => {
  const signedTransaction = unsignedJwt({
    bundleId: "com.damanak.damanak",
    environment: "Sandbox",
  });
  for (
    const status of [
      VerificationStatus.INVALID_APP_IDENTIFIER,
      VerificationStatus.INVALID_ENVIRONMENT,
      VerificationStatus.INVALID_CHAIN_LENGTH,
      VerificationStatus.FAILURE,
    ]
  ) {
    const calls: boolean[] = [];
    let message = "";
    try {
      await verifyAppleRecoveryTransactionWithFallback(
        signedTransaction,
        "sandbox",
        (_candidate, _environment, enableOnlineChecks) => {
          calls.push(enableOnlineChecks);
          return Promise.reject(new VerificationException(status));
        },
      );
    } catch (error) {
      message = error instanceof Error ? error.message : "";
    }
    if (
      message !== "APPLE_RECOVERY_PROOF_INVALID" ||
      calls.join(",") !== "true"
    ) {
      throw new Error("Apple identity or chain-shape failure reached fallback");
    }
  }

  const calls: boolean[] = [];
  let message = "";
  try {
    await verifyAppleRecoveryTransactionWithFallback(
      signedTransaction,
      "sandbox",
      (_candidate, _environment, enableOnlineChecks) => {
        calls.push(enableOnlineChecks);
        return Promise.reject(new Error("unexpected verifier crash"));
      },
    );
  } catch (error) {
    message = error instanceof Error ? error.message : "";
  }
  if (
    message !== "APPLE_CERTIFICATE_VERIFICATION_UNAVAILABLE" ||
    calls.join(",") !== "true"
  ) {
    throw new Error("unexpected verifier errors were retried or misclassified");
  }
});

Deno.test("Apple signed-date fallback fails closed and logs no purchase secrets", async () => {
  const secretToken = "33333333-3333-4333-8333-333333333333";
  const secretTransaction = "2000000123456789";
  const secretCertificate = "sensitive-certificate-material";
  const encode = (value: Record<string, unknown>) =>
    btoa(JSON.stringify(value))
      .replaceAll("+", "-")
      .replaceAll("/", "_")
      .replaceAll("=", "");
  const signedTransaction = `${
    encode({ alg: "ES256", x5c: [secretCertificate, "two", "three"] })
  }.${
    encode({
      bundleId: "com.damanak.damanak",
      environment: "Sandbox",
      signedDate: Date.now(),
      transactionId: secretTransaction,
      appAccountToken: secretToken,
    })
  }.sensitive-signature-material`;
  const warnings: string[] = [];
  const originalWarn = console.warn;
  console.warn = (...args: unknown[]) => warnings.push(JSON.stringify(args));
  let message = "";
  try {
    await verifyAppleRecoveryTransactionWithFallback(
      signedTransaction,
      "sandbox",
      (_candidate, _environment, enableOnlineChecks) =>
        Promise.reject(
          new VerificationException(
            enableOnlineChecks
              ? VerificationStatus.INVALID_CERTIFICATE
              : VerificationStatus.VERIFICATION_FAILURE,
          ),
        ),
    );
  } catch (error) {
    message = error instanceof Error ? error.message : "";
  } finally {
    console.warn = originalWarn;
  }
  const telemetry = warnings.join("\n");
  if (message !== "APPLE_RECOVERY_PROOF_INVALID" || warnings.length !== 2) {
    throw new Error("a rejected signed-date proof did not fail closed");
  }
  for (
    const secret of [
      secretToken,
      secretTransaction,
      secretCertificate,
      signedTransaction,
      "sensitive-signature-material",
    ]
  ) {
    if (telemetry.includes(secret)) {
      throw new Error("Apple fallback telemetry exposed purchase material");
    }
  }
});

Deno.test("Apple orphan recovery is explicit, single-store, and deletion-only", () => {
  const currentStoreId = "11111111-1111-4111-8111-111111111111";
  const currentUserId = "22222222-2222-4222-8222-222222222222";
  const oldToken = "33333333-3333-4333-8333-333333333333";
  const allowed = {
    recoveryRequested: true,
    appAccountToken: oldToken,
    currentStoreId,
    currentUserId,
    ownedStoreIds: [currentStoreId],
    existingBindingStoreIds: [],
    targetHasStoreEntitlement: false,
    oldTokenStoreExists: false,
    oldTokenUserExists: false,
  };
  assertAppleOrphanRecoveryEligible(allowed);
  assertAppleOrphanRecoveryEligible({
    ...allowed,
    currentStoreId: currentStoreId.toUpperCase(),
  });

  for (
    const denied of [
      { ...allowed, recoveryRequested: false },
      { ...allowed, existingBindingStoreIds: [oldToken] },
      { ...allowed, targetHasStoreEntitlement: true },
      { ...allowed, oldTokenStoreExists: true },
      { ...allowed, oldTokenUserExists: true },
      { ...allowed, ownedStoreIds: [currentStoreId, oldToken] },
    ]
  ) {
    let rejected = false;
    try {
      assertAppleOrphanRecoveryEligible(denied);
    } catch {
      rejected = true;
    }
    if (!rejected) throw new Error("an unsafe Apple orphan claim was accepted");
  }
});

Deno.test("Apple account-token update targets the verified environment", () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const sandbox = appleAccountTokenUpdateRequest(
    "2000000123456789",
    "sandbox",
    storeId,
  );
  const production = appleAccountTokenUpdateRequest(
    "1000000123456789",
    "production",
    storeId,
  );
  if (
    !sandbox.url.startsWith("https://api.storekit-sandbox.apple.com/") ||
    !production.url.startsWith("https://api.storekit.apple.com/") ||
    sandbox.body.appAccountToken !== storeId
  ) {
    throw new Error("Apple account-token update was routed incorrectly");
  }
});

Deno.test("Apple token update is scheduled only after apply without blocking", async () => {
  const failedOrder: string[] = [];
  let failed = false;
  try {
    await applyThenMaybeScheduleAppleAccountTokenUpdate(
      () => {
        failedOrder.push("apply");
        throw new Error("apply failed");
      },
      () => {
        failedOrder.push("update");
        return Promise.resolve();
      },
      () => {
        failedOrder.push("schedule");
        return true;
      },
    );
  } catch {
    failed = true;
  }
  if (!failed || failedOrder.join(",") !== "apply") {
    throw new Error("Apple token update ran despite a failed atomic apply");
  }

  const successOrder: string[] = [];
  const updateGate = Promise.withResolvers<void>();
  let scheduledTask: Promise<void> | null = null;
  const scheduled = await applyThenMaybeScheduleAppleAccountTokenUpdate(
    () => {
      successOrder.push("apply");
      return Promise.resolve();
    },
    () => {
      successOrder.push("update");
      return updateGate.promise;
    },
    (task) => {
      successOrder.push("schedule");
      scheduledTask = task();
      return true;
    },
  );
  if (
    !scheduled ||
    scheduledTask == null ||
    successOrder.join(",") !== "apply,schedule,update"
  ) {
    throw new Error("Apple token update was not scheduled after apply");
  }
  updateGate.resolve();
  await scheduledTask;
});

Deno.test("a failed post-commit acknowledgement remains background-only", async () => {
  const errors: string[] = [];
  const acknowledgement = Promise.withResolvers<void>();
  let scheduledTask: Promise<void> | null = null;
  const scheduled = scheduleBestEffortPostCommitTask(
    () => acknowledgement.promise,
    (error) => errors.push(error instanceof Error ? error.message : "unknown"),
    (task) => {
      scheduledTask = task();
      return true;
    },
  );
  if (!scheduled || scheduledTask == null || errors.length !== 0) {
    throw new Error("post-commit acknowledgement blocked the success path");
  }
  acknowledgement.reject(new Error("GOOGLE_ACKNOWLEDGE_503"));
  await scheduledTask;
  if (errors.join(",") !== "GOOGLE_ACKNOWLEDGE_503") {
    throw new Error("post-commit acknowledgement failure escaped its guard");
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
    [
      "APPLE_RECOVERY_PROOF_MISMATCH",
      422,
      "PURCHASE_RECOVERY_PROOF_INVALID",
    ],
    [
      "APPLE_CERTIFICATE_VERIFICATION_RETRYABLE",
      503,
      "PURCHASE_PROVIDER_UNAVAILABLE",
    ],
    [
      "APPLE_CERTIFICATE_VERIFICATION_UNAVAILABLE",
      503,
      "PURCHASE_PROVIDER_UNAVAILABLE",
    ],
    [
      "STORE_PURCHASE_RECOVERY_NOT_ALLOWED",
      409,
      "PURCHASE_RECOVERY_NOT_ALLOWED",
    ],
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

Deno.test("Google orphan recovery accepts direct Build 23 account binding", () => {
  const currentStoreId = "11111111-1111-4111-8111-111111111111";
  const currentUserId = "22222222-2222-4222-8222-222222222222";
  const oldAccountId = "33333333-3333-4333-8333-333333333333";
  const oldStoreId = "44444444-4444-4444-8444-444444444444";
  const purchase = {
    externalAccountIdentifiers: {
      obfuscatedExternalAccountId: oldAccountId,
      obfuscatedExternalProfileId: oldStoreId,
    },
  };
  const binding = googleOrphanRecoveryBinding(
    purchase,
    { storeId: currentStoreId },
    currentUserId,
  );
  if (
    binding.oldAccountId !== oldAccountId ||
    binding.oldStoreId !== oldStoreId
  ) {
    throw new Error("Google deleted binding was not preserved exactly");
  }
  const legacyBinding = googleOrphanRecoveryBinding(
    {
      externalAccountIdentifiers: {
        obfuscatedExternalAccountId: oldAccountId,
      },
    },
    { storeId: currentStoreId },
    currentUserId,
  );
  if (
    legacyBinding.oldAccountId !== oldAccountId ||
    legacyBinding.oldStoreId !== null
  ) {
    throw new Error("Google Build 23 account-only binding was not accepted");
  }

  const linkedPurchaseToken = "linked-provider-token-1234567890";
  const linkedBinding = googleOrphanRecoveryBinding(
    { ...purchase, linkedPurchaseToken },
    { storeId: currentStoreId },
    currentUserId,
  );
  if (linkedBinding.linkedPurchaseToken !== linkedPurchaseToken) {
    throw new Error("Google replacement lineage was not preserved");
  }

  const expiredPurchaseToken = "expired-provider-token-1234567890";
  const outOfAppBinding = googleOrphanRecoveryBinding(
    {
      outOfAppPurchaseContext: {
        expiredPurchaseToken,
        expiredExternalAccountIdentifiers: {
          obfuscatedExternalAccountId: oldAccountId,
        },
      },
    },
    { storeId: currentStoreId },
    currentUserId,
  );
  if (
    outOfAppBinding.oldAccountId !== oldAccountId ||
    outOfAppBinding.oldStoreId !== null ||
    outOfAppBinding.linkedPurchaseToken !== expiredPurchaseToken
  ) {
    throw new Error("Google out-of-app Build 23 lineage was not accepted");
  }

  for (
    const denied of [
      {
        externalAccountIdentifiers: {
          obfuscatedExternalAccountId: currentUserId,
          obfuscatedExternalProfileId: oldStoreId,
        },
      },
      {
        externalAccountIdentifiers: {},
      },
      {
        ...purchase,
        linkedPurchaseToken,
        outOfAppPurchaseContext: {
          expiredPurchaseToken: "different-expired-token-1234567890",
          expiredExternalAccountIdentifiers:
            purchase.externalAccountIdentifiers,
        },
      },
    ]
  ) {
    let rejected = false;
    try {
      googleOrphanRecoveryBinding(
        denied,
        { storeId: currentStoreId },
        currentUserId,
      );
    } catch {
      rejected = true;
    }
    if (!rejected) throw new Error("unsafe Google orphan proof was accepted");
  }
});

Deno.test("Google orphan claim fails if either old identity is still live", () => {
  const currentStoreId = "11111111-1111-4111-8111-111111111111";
  const currentUserId = "22222222-2222-4222-8222-222222222222";
  const allowed = {
    recoveryRequested: true,
    oldAccountId: "33333333-3333-4333-8333-333333333333",
    oldStoreId: "44444444-4444-4444-8444-444444444444",
    currentStoreId,
    currentUserId,
    ownedStoreIds: [currentStoreId],
    existingBindingStoreIds: [],
    targetHasStoreEntitlement: false,
    oldStoreExists: false,
    oldUserExists: false,
    oldAccountOwnsStore: false,
  };
  assertGoogleOrphanRecoveryEligible(allowed);
  assertGoogleOrphanRecoveryEligible({ ...allowed, oldStoreId: null });

  for (
    const denied of [
      { ...allowed, recoveryRequested: false },
      { ...allowed, existingBindingStoreIds: [allowed.oldStoreId] },
      { ...allowed, targetHasStoreEntitlement: true },
      { ...allowed, oldStoreExists: true },
      { ...allowed, oldUserExists: true },
      { ...allowed, oldStoreId: null, oldAccountOwnsStore: true },
      { ...allowed, ownedStoreIds: [currentStoreId, allowed.oldStoreId] },
    ]
  ) {
    let rejected = false;
    try {
      assertGoogleOrphanRecoveryEligible(denied);
    } catch {
      rejected = true;
    }
    if (!rejected) throw new Error("unsafe Google orphan claim was accepted");
  }
});

Deno.test("Google identity bypass is reserved for a server-bound refresh", () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const currentUserId = "22222222-2222-4222-8222-222222222222";
  const staleProviderBinding = {
    externalAccountIdentifiers: {
      obfuscatedExternalAccountId: "33333333-3333-4333-8333-333333333333",
      obfuscatedExternalProfileId: "44444444-4444-4444-8444-444444444444",
    },
  };
  let rejected = false;
  try {
    assertGooglePurchaseIdentity(
      staleProviderBinding,
      { storeId },
      currentUserId,
    );
  } catch {
    rejected = true;
  }
  if (!rejected) throw new Error("untrusted Google mismatch was accepted");
  assertGooglePurchaseIdentity(
    staleProviderBinding,
    { storeId },
    currentUserId,
    { trustedServerBinding: true },
  );
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

Deno.test("Google bound predecessor overrides only stale expired identifiers", async () => {
  const storeId = "11111111-1111-4111-8111-111111111111";
  const userId = "22222222-2222-4222-8222-222222222222";
  const oldStoreId = "33333333-3333-4333-8333-333333333333";
  const oldUserId = "44444444-4444-4444-8444-444444444444";
  const expiredPurchaseToken = "expired-provider-token-1234567890";
  const purchase = {
    externalAccountIdentifiers: {
      obfuscatedExternalAccountId: userId,
      obfuscatedExternalProfileId: storeId,
    },
    outOfAppPurchaseContext: {
      expiredPurchaseToken,
      expiredExternalAccountIdentifiers: {
        obfuscatedExternalAccountId: oldUserId,
        obfuscatedExternalProfileId: oldStoreId,
      },
    },
  };
  const resolvedTokens: string[] = [];
  const trusted = await resolveTrustedGoogleOutOfAppLineage(
    purchase,
    (token) => {
      resolvedTokens.push(token);
      return Promise.resolve(true);
    },
  );
  if (
    !trusted || resolvedTokens.length !== 1 ||
    resolvedTokens[0] !== expiredPurchaseToken
  ) {
    throw new Error("server-bound predecessor lineage was not resolved");
  }
  assertGooglePurchaseIdentity(purchase, { storeId }, userId, {
    trustedOutOfAppLineage: trusted,
  });

  let rejected = false;
  try {
    assertGooglePurchaseIdentity(
      {
        ...purchase,
        externalAccountIdentifiers: {
          obfuscatedExternalAccountId: oldUserId,
          obfuscatedExternalProfileId: oldStoreId,
        },
      },
      { storeId },
      userId,
      { trustedOutOfAppLineage: true },
    );
  } catch {
    rejected = true;
  }
  if (!rejected) {
    throw new Error("trusted predecessor bypassed mismatched current identity");
  }
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
