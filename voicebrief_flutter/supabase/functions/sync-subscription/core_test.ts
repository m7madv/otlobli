import { BoundedJsonError } from "../_shared/bounded_json.ts";
import type { RevenueCatSubscriptionSnapshot } from "../revenuecat-webhook/core.ts";
import {
  executeClaimedSubscriptionSync,
  fetchRevenueCatSubscriptionSyncLookup,
  MAX_SUBSCRIPTION_SYNC_BODY_BYTES,
  normalizeStoredSubscriptionState,
  type StoredSubscriptionState,
  SUBSCRIPTION_SYNC_EVENT_ID_PREFIX,
  subscriptionSyncEventId,
  subscriptionSyncEventType,
  subscriptionSyncRequestBody,
  subscriptionSyncRpcArguments,
} from "./core.ts";

const userId = "11111111-1111-4111-8111-111111111111";
const monthlyProduct = "voicebrief_pro_monthly";

function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function activeSnapshot(
  overrides: Partial<RevenueCatSubscriptionSnapshot> = {},
): RevenueCatSubscriptionSnapshot {
  return {
    isPro: true,
    productId: monthlyProduct,
    store: "APP_STORE",
    periodStartMs: Date.parse("2026-09-01T00:00:00.000Z"),
    periodEndMs: Date.parse("2026-10-01T00:00:00.000Z"),
    accessEndMs: Date.parse("2026-10-01T00:00:00.000Z"),
    ...overrides,
  };
}

function storedPro(
  overrides: Partial<StoredSubscriptionState> = {},
): StoredSubscriptionState {
  return {
    entitlement: "pro",
    productId: monthlyProduct,
    quotaGenerationKey: "old-generation",
    revenueCatEventId: "real-webhook-event",
    expiresAt: "2026-10-01T00:00:00.000Z",
    ...overrides,
  };
}

Deno.test("active recovery uses the paid-cycle sync event", () => {
  assert(
    subscriptionSyncEventType(activeSnapshot()) === "SUBSCRIPTION_SYNC",
    "active snapshot did not use the sync cycle event",
  );
});

Deno.test("inactive recovery uses an expiration event", () => {
  assert(
    subscriptionSyncEventType({
      ...activeSnapshot(),
      isPro: false,
      productId: "",
    }) === "EXPIRATION",
    "inactive snapshot must revoke stale access",
  );
});

Deno.test("sync request accepts only one boolean expectedPro hint", async () => {
  for (const expectedPro of [true, false]) {
    const body = await subscriptionSyncRequestBody(
      new Request("https://voicebrief.test", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ expectedPro }),
      }),
    );
    assert(body.expectedPro === expectedPro, "expectedPro changed");
  }

  for (
    const invalid of [
      {},
      { expectedPro: "true" },
      { expectedPro: true, operation: "load" },
      { expectedPro: true, operation: "purchase", userId },
      [true],
    ]
  ) {
    try {
      await subscriptionSyncRequestBody(
        new Request("https://voicebrief.test", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify(invalid),
        }),
      );
      throw new Error("expected invalid body rejection");
    } catch (error) {
      assert(
        error instanceof BoundedJsonError && error.status === 400,
        "invalid sync body was accepted",
      );
    }
  }
});

Deno.test("sync request enforces its byte limit", async () => {
  try {
    await subscriptionSyncRequestBody(
      new Request("https://voicebrief.test", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          expectedPro: true,
          operation: "purchase",
          padding: "x".repeat(MAX_SUBSCRIPTION_SYNC_BODY_BYTES),
        }),
      }),
    );
    throw new Error("expected oversized body rejection");
  } catch (error) {
    assert(
      error instanceof BoundedJsonError && error.status === 413,
      "oversized sync body did not return 413",
    );
  }
});

Deno.test("rate limit claim runs before fetch and prevents every later call", async () => {
  const calls: string[] = [];
  const result = await executeClaimedSubscriptionSync({
    expectedPro: false,
    claim: () => {
      calls.push("claim");
      return Promise.resolve(false);
    },
    fetchSnapshot: () => {
      calls.push("revenuecat");
      return Promise.resolve({
        snapshot: activeSnapshot(),
        createdCustomer: false,
      });
    },
    hasCurrentProGeneration: () => {
      calls.push("generation");
      return Promise.resolve(true);
    },
    applySnapshot: () => {
      calls.push("apply");
      return Promise.resolve(true);
    },
  });
  assert(result.kind === "rate_limited", "rate limit was ignored");
  assert(
    JSON.stringify(calls) === JSON.stringify(["claim"]),
    `unexpected limited calls: ${calls.join(",")}`,
  );
});

Deno.test("stale Free never mutates when the client still expects Pro", async () => {
  let applied = false;
  const result = await executeClaimedSubscriptionSync({
    expectedPro: true,
    claim: () => Promise.resolve(true),
    fetchSnapshot: () =>
      Promise.resolve({
        snapshot: { ...activeSnapshot(), isPro: false, productId: "" },
        createdCustomer: false,
      }),
    hasCurrentProGeneration: () => Promise.resolve(false),
    applySnapshot: () => {
      applied = true;
      return Promise.resolve(true);
    },
  });
  assert(result.kind === "pending", "stale Free was not retried");
  assert(!applied, "stale Free reached apply_revenuecat_event");
});

Deno.test("authoritative Free applies when expectedPro is false", async () => {
  const calls: string[] = [];
  const result = await executeClaimedSubscriptionSync({
    expectedPro: false,
    claim: () => {
      calls.push("claim");
      return Promise.resolve(true);
    },
    fetchSnapshot: () => {
      calls.push("revenuecat");
      return Promise.resolve({
        snapshot: { ...activeSnapshot(), isPro: false, productId: "" },
        createdCustomer: false,
      });
    },
    hasCurrentProGeneration: () => Promise.resolve(true),
    applySnapshot: (snapshot) => {
      calls.push("apply");
      assert(!snapshot.isPro, "Free snapshot was changed to Pro");
      return Promise.resolve(true);
    },
  });
  assert(result.kind === "synced", "authoritative Free was not applied");
  assert(
    JSON.stringify(calls) === JSON.stringify([
      "claim",
      "revenuecat",
      "apply",
    ]),
    `unexpected sync order: ${calls.join(",")}`,
  );
});

Deno.test("RevenueCat 201 is pending and cannot revoke local Pro", async () => {
  let applied = false;
  const result = await executeClaimedSubscriptionSync({
    expectedPro: false,
    claim: () => Promise.resolve(true),
    fetchSnapshot: () =>
      Promise.resolve({
        snapshot: { ...activeSnapshot(), isPro: false, productId: "" },
        createdCustomer: true,
      }),
    hasCurrentProGeneration: () => Promise.resolve(false),
    applySnapshot: () => {
      applied = true;
      return Promise.resolve(true);
    },
  });
  assert(result.kind === "pending", "created customer was treated as Free");
  assert(!applied, "RevenueCat 201 reached apply_revenuecat_event");
});

Deno.test("Pro sync waits for signed webhook when no current generation exists", async () => {
  let applied = false;
  const result = await executeClaimedSubscriptionSync({
    expectedPro: true,
    claim: () => Promise.resolve(true),
    fetchSnapshot: () =>
      Promise.resolve({ snapshot: activeSnapshot(), createdCustomer: false }),
    hasCurrentProGeneration: () => Promise.resolve(false),
    applySnapshot: () => {
      applied = true;
      return Promise.resolve(true);
    },
  });
  assert(result.kind === "pending", "new destination received fresh quota");
  assert(!applied, "restore without transferred usage mutated state");
});

Deno.test("matching current Pro generation needs no entitlement mutation", async () => {
  let applied = false;
  const result = await executeClaimedSubscriptionSync({
    expectedPro: true,
    claim: () => Promise.resolve(true),
    fetchSnapshot: () =>
      Promise.resolve({ snapshot: activeSnapshot(), createdCustomer: false }),
    hasCurrentProGeneration: () => Promise.resolve(true),
    applySnapshot: () => {
      applied = true;
      return Promise.resolve(true);
    },
  });
  assert(result.kind === "synced", "current generation was not accepted");
  assert(!applied, "client sync rewrote an already reconciled entitlement");
});

Deno.test("RevenueCat lookup preserves a 201 created-customer signal", async () => {
  let authorization = "";
  const lookup = await fetchRevenueCatSubscriptionSyncLookup(
    userId,
    "private-key",
    {
      nowMs: Date.parse("2026-09-02T00:00:00.000Z"),
      eventTimestampMs: Date.parse("2026-09-02T00:00:00.000Z"),
      fetcher: (_input, init) => {
        authorization = new Headers(init?.headers).get("authorization") ?? "";
        return Promise.resolve(Response.json(
          { subscriber: { entitlements: {}, subscriptions: {} } },
          { status: 201 },
        ));
      },
    },
  );
  assert(lookup.createdCustomer, "RevenueCat 201 signal was lost");
  assert(!lookup.snapshot.isPro, "empty customer became Pro");
  assert(
    authorization === "Bearer private-key",
    "private RevenueCat authorization is missing",
  );
});

Deno.test("matching active snapshot uses one canonical event ID", async () => {
  const snapshot = activeSnapshot();
  const firstId = await subscriptionSyncEventId(
    userId,
    snapshot,
    storedPro({ revenueCatEventId: "webhook-a" }),
  );
  const retryId = await subscriptionSyncEventId(
    userId,
    snapshot,
    storedPro({ revenueCatEventId: "webhook-b" }),
  );
  assert(firstId === retryId, "matching period produced two canonical IDs");
  assert(
    firstId.startsWith(SUBSCRIPTION_SYNC_EVENT_ID_PREFIX),
    "sync event namespace is missing",
  );
});

Deno.test("same active period repairs a later Free transition", async () => {
  const snapshot = activeSnapshot();
  const canonicalId = await subscriptionSyncEventId(
    userId,
    snapshot,
    storedPro(),
  );
  const recoveryId = await subscriptionSyncEventId(userId, snapshot, {
    entitlement: "free",
    productId: "",
    quotaGenerationKey: null,
    revenueCatEventId: "later-expiration",
    expiresAt: null,
  });
  const stableId = await subscriptionSyncEventId(
    userId,
    snapshot,
    storedPro({ revenueCatEventId: recoveryId }),
  );
  assert(recoveryId !== canonicalId, "consumed canonical ID blocked recovery");
  assert(stableId === canonicalId, "repaired active state did not converge");
});

Deno.test("new store period receives a distinct idempotency key", async () => {
  const firstId = await subscriptionSyncEventId(
    userId,
    activeSnapshot(),
    storedPro(),
  );
  const renewedId = await subscriptionSyncEventId(
    userId,
    activeSnapshot({
      periodStartMs: Date.parse("2026-10-01T00:00:00.000Z"),
      periodEndMs: Date.parse("2026-11-01T00:00:00.000Z"),
      accessEndMs: Date.parse("2026-11-01T00:00:00.000Z"),
    }),
    storedPro(),
  );
  assert(firstId !== renewedId, "renewal reused the previous store period ID");
});

Deno.test("inactive sync converges without blocking a later generation", async () => {
  const inactive = {
    ...activeSnapshot(),
    isPro: false,
    productId: "",
  };
  const firstId = await subscriptionSyncEventId(
    userId,
    inactive,
    storedPro({ quotaGenerationKey: "generation-a" }),
  );
  const retryId = await subscriptionSyncEventId(userId, inactive, {
    entitlement: "free",
    productId: "",
    quotaGenerationKey: null,
    revenueCatEventId: firstId,
    expiresAt: null,
  });
  const laterGenerationId = await subscriptionSyncEventId(
    userId,
    inactive,
    storedPro({ quotaGenerationKey: "generation-b" }),
  );
  assert(firstId === retryId, "inactive retry did not reuse the applied event");
  assert(
    firstId !== laterGenerationId,
    "later subscription generation could not expire independently",
  );
});

Deno.test("a second Free transition after restoring period A gets a new ID", async () => {
  const inactive = { ...activeSnapshot(), isPro: false, productId: "" };
  const firstFreeId = await subscriptionSyncEventId(
    userId,
    inactive,
    storedPro({ revenueCatEventId: "active-a" }),
  );
  const restoredAId = await subscriptionSyncEventId(userId, activeSnapshot(), {
    entitlement: "free",
    productId: "",
    quotaGenerationKey: null,
    revenueCatEventId: firstFreeId,
    expiresAt: null,
  });
  const secondFreeId = await subscriptionSyncEventId(
    userId,
    inactive,
    storedPro({ revenueCatEventId: restoredAId }),
  );
  const stableFreeId = await subscriptionSyncEventId(userId, inactive, {
    entitlement: "free",
    productId: "",
    quotaGenerationKey: null,
    revenueCatEventId: secondFreeId,
    expiresAt: null,
  });
  assert(firstFreeId !== secondFreeId, "second Free transition was duplicate");
  assert(secondFreeId === stableFreeId, "Free transition did not converge");
});

Deno.test("RPC arguments preserve authoritative subscription boundaries", () => {
  const snapshot = activeSnapshot();
  const args = subscriptionSyncRpcArguments({
    eventId: "voicebrief-sync-v1-test",
    eventType: "SUBSCRIPTION_SYNC",
    userId,
    eventAtMs: Date.parse("2026-09-02T12:34:56.000Z"),
    snapshot,
  });
  assert(args.p_event_type === "SUBSCRIPTION_SYNC", "event type changed");
  assert(args.p_user_id === userId, "authenticated user changed");
  assert(args.p_is_pro, "active entitlement changed");
  assert(
    args.p_period_start === "2026-09-01T00:00:00.000Z",
    "period start changed",
  );
  assert(
    args.p_period_end === "2026-10-01T00:00:00.000Z",
    "period end changed",
  );
  assert(
    args.p_access_end === "2026-10-01T00:00:00.000Z",
    "access end changed",
  );
});

Deno.test("stored state normalization rejects untrusted field shapes", () => {
  const state = normalizeStoredSubscriptionState({
    entitlement: "pro",
    product_id: monthlyProduct,
    quota_generation_key: 12,
    revenuecat_event_id: ["not", "a", "string"],
    expires_at: "2026-10-01T00:00:00.000Z",
  });
  assert(state?.entitlement === "pro", "entitlement was not normalized");
  assert(state?.quotaGenerationKey === null, "invalid generation was trusted");
  assert(state?.revenueCatEventId === null, "invalid event ID was trusted");
  assert(normalizeStoredSubscriptionState([]) === null, "array was trusted");
});
