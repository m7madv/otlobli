import {
  fetchRevenueCatSubscriptionSnapshot,
  monthlyQuotaWindows,
  needsRevenueCatCustomerSnapshot,
  parseRevenueCatSubscriptionSnapshot,
  quotaWindowLimitForProduct,
  resolveRevenueCatTransferDestination,
  RevenueCatCustomerError,
  revenueCatEventMode,
  type RevenueCatSubscriptionSnapshot,
  revenueCatTransferIds,
  shouldCarrySubscriptionUsage,
  shouldRetryRevenueCatTransfer,
} from "./core.ts";

function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("monthly subscription receives one 300-minute quota window", () => {
  const windows = monthlyQuotaWindows(
    Date.parse("2026-09-02T10:15:00.000Z"),
    Date.parse("2026-10-02T10:15:00.000Z"),
    1,
  );

  assert(windows.length === 1, "expected one monthly window");
  assert(windows[0].quotaMinutes === 300, "expected 300 minutes");
});

Deno.test("annual subscription receives twelve independent monthly quotas", () => {
  const windows = monthlyQuotaWindows(
    Date.parse("2026-09-02T10:15:00.000Z"),
    Date.parse("2027-09-02T10:15:00.000Z"),
    12,
  );

  assert(windows.length === 12, "expected twelve monthly windows");
  assert(
    windows.every((window) => window.quotaMinutes === 300),
    "every annual month must receive 300 minutes",
  );
  assert(
    windows[0].endsAt === windows[1].startsAt,
    "quota windows must be contiguous",
  );
});

Deno.test("month-end anchoring does not drift after February", () => {
  const windows = monthlyQuotaWindows(
    Date.parse("2028-01-31T08:00:00.000Z"),
    Date.parse("2028-04-30T08:00:00.000Z"),
    12,
  );

  assert(
    windows[0].endsAt === "2028-02-29T08:00:00.000Z",
    "leap-year February should clamp to the 29th",
  );
  assert(
    windows[1].endsAt === "2028-03-31T08:00:00.000Z",
    "March should return to the original purchase day",
  );
});

Deno.test("grace access extends the final quota without adding a refill", () => {
  const windows = monthlyQuotaWindows(
    Date.parse("2026-09-02T10:15:00.000Z"),
    Date.parse("2026-10-02T10:15:00.000Z"),
    1,
    Date.parse("2026-10-16T10:15:00.000Z"),
  );

  assert(windows.length === 1, "grace must not create another quota window");
  assert(
    windows[0].endsAt === "2026-10-16T10:15:00.000Z",
    "the existing quota should remain usable through grace",
  );
});

Deno.test("annual grace keeps exactly twelve monthly quotas", () => {
  const windows = monthlyQuotaWindows(
    Date.parse("2026-09-02T10:15:00.000Z"),
    Date.parse("2027-09-02T10:15:00.000Z"),
    12,
    Date.parse("2027-09-16T10:15:00.000Z"),
  );

  assert(windows.length === 12, "annual grace must not add month thirteen");
  assert(
    windows[11].endsAt === "2027-09-16T10:15:00.000Z",
    "only the twelfth window should extend through grace",
  );
});

Deno.test("quota-window limits outside the supported bound are rejected", () => {
  let rejected = false;
  try {
    monthlyQuotaWindows(
      Date.parse("2026-01-01T00:00:00.000Z"),
      Date.parse("2029-01-01T00:00:00.000Z"),
      25,
    );
  } catch (error) {
    rejected = error instanceof RangeError;
  }
  assert(rejected, "more than 24 quota windows must fail closed");
});

Deno.test("a sub-day monthly extension does not create a refill", () => {
  const accessEnd = Date.parse("2026-10-02T22:15:00.000Z");
  const windows = monthlyQuotaWindows(
    Date.parse("2026-09-02T10:15:00.000Z"),
    Date.parse("2026-10-02T10:15:00.000Z"),
    quotaWindowLimitForProduct("voicebrief_pro_monthly"),
    accessEnd,
  );

  assert(windows.length === 1, "a short extension must reuse month one");
  assert(
    Date.parse(windows[0].endsAt) === accessEnd,
    "the original quota must remain available through the extension",
  );
});

Deno.test("an annual extension cannot create month thirteen", () => {
  const accessEnd = Date.parse("2027-09-03T10:15:00.000Z");
  const windows = monthlyQuotaWindows(
    Date.parse("2026-09-02T10:15:00.000Z"),
    Date.parse("2027-09-02T10:15:00.000Z"),
    quotaWindowLimitForProduct("voicebrief_pro_annual:annual"),
    accessEnd,
  );

  assert(windows.length === 12, "annual access must stop at twelve quotas");
  assert(
    Date.parse(windows[11].endsAt) === accessEnd,
    "month twelve must absorb the extension",
  );
});

Deno.test("only subscription-state events are allowed to mutate access", () => {
  assert(
    revenueCatEventMode("INITIAL_PURCHASE") === "subscription_state",
    "purchase should update subscription state",
  );
  assert(
    revenueCatEventMode("TRANSFER") === "transfer",
    "transfer needs its dedicated path",
  );
  assert(
    revenueCatEventMode("TEMPORARY_ENTITLEMENT_GRANT") ===
      "temporary_grant",
    "temporary grant needs a server snapshot",
  );
  assert(
    revenueCatEventMode("BILLING_ISSUE") === "subscription_state",
    "billing issues need a fresh customer snapshot",
  );
  for (
    const ignored of [
      "TEST",
      "EXPERIMENT_ENROLLMENT",
      "PRICE_INCREASE_CONSENT_REQUIRED",
      "PRICE_INCREASE_CONSENT_APPROVED",
      "SUBSCRIBER_ALIAS",
      "VIRTUAL_CURRENCY_TRANSACTION",
      "PURCHASE_REDEEMED",
      "INVOICE_ISSUANCE",
    ]
  ) {
    assert(
      revenueCatEventMode(ignored) === "ignore",
      `${ignored} must not downgrade a subscriber`,
    );
  }
});

Deno.test("every mutating webhook mode fetches a customer snapshot", () => {
  for (
    const eventType of [
      "INITIAL_PURCHASE",
      "RENEWAL",
      "CANCELLATION",
      "UNCANCELLATION",
      "BILLING_ISSUE",
      "SUBSCRIPTION_PAUSED",
      "EXPIRATION",
      "PRODUCT_CHANGE",
      "SUBSCRIPTION_EXTENDED",
      "REFUND_REVERSED",
      "TRANSFER",
      "TEMPORARY_ENTITLEMENT_GRANT",
    ]
  ) {
    assert(
      needsRevenueCatCustomerSnapshot(revenueCatEventMode(eventType)),
      `${eventType} must reconcile against RevenueCat Customer Info`,
    );
  }
  assert(
    !needsRevenueCatCustomerSnapshot(revenueCatEventMode("TEST")),
    "non-subscription events must not trigger customer reconciliation",
  );
});

Deno.test("product-change companion carries usage but renewal does not", () => {
  assert(
    shouldCarrySubscriptionUsage({
      eventType: "RENEWAL",
      previousEventType: "PRODUCT_CHANGE",
      previousProductId: "voicebrief_pro_monthly",
      productId: "voicebrief_pro_annual:annual",
      generationChanged: true,
      overlapsPreviousAccess: true,
    }),
    "Apple companion renewal must retain usage",
  );
  assert(
    shouldCarrySubscriptionUsage({
      eventType: "INITIAL_PURCHASE",
      previousEventType: "RENEWAL",
      previousProductId: "voicebrief_pro_monthly",
      productId: "voicebrief_pro_annual:annual",
      generationChanged: true,
      overlapsPreviousAccess: true,
    }),
    "Google companion purchase must retain usage",
  );
  assert(
    !shouldCarrySubscriptionUsage({
      eventType: "SUBSCRIPTION_SYNC",
      previousEventType: "RENEWAL",
      previousProductId: "voicebrief_pro_monthly",
      productId: "voicebrief_pro_monthly",
      generationChanged: true,
      overlapsPreviousAccess: true,
    }),
    "lost-webhook reconciliation must keep a genuine renewal quota fresh",
  );
  assert(
    shouldCarrySubscriptionUsage({
      eventType: "SUBSCRIPTION_SYNC",
      previousEventType: "RENEWAL",
      previousProductId: "voicebrief_pro_monthly",
      productId: "voicebrief_pro_annual:annual",
      generationChanged: true,
      overlapsPreviousAccess: true,
    }),
    "lost product-change webhooks must not refill the overlapping quota",
  );
  assert(
    !shouldCarrySubscriptionUsage({
      eventType: "PRODUCT_CHANGE",
      previousEventType: "RENEWAL",
      previousProductId: "voicebrief_pro_monthly",
      productId: "voicebrief_pro_annual:annual",
      generationChanged: true,
      overlapsPreviousAccess: false,
    }),
    "a deferred product change must not consume a future cycle",
  );
});

Deno.test("customer snapshot resolves transferred Google Pro period", () => {
  const snapshot = parseRevenueCatSubscriptionSnapshot(
    {
      subscriber: {
        entitlements: {
          pro: {
            product_identifier: "voicebrief_pro_annual:annual",
            purchase_date: "2026-09-02T10:00:00.000Z",
            expires_date: "2027-09-02T10:00:00.000Z",
            grace_period_expires_date: null,
          },
        },
        subscriptions: {
          "voicebrief_pro_annual:annual": {
            purchase_date: "2026-09-02T10:00:00.000Z",
            expires_date: "2027-09-02T10:00:00.000Z",
            store: "play_store",
          },
        },
      },
    },
    {
      nowMs: Date.parse("2026-09-03T00:00:00.000Z"),
      eventTimestampMs: Date.parse("2026-09-03T00:00:00.000Z"),
      fallbackStore: "PLAY_STORE",
    },
  );

  assert(snapshot.isPro, "transferred Pro entitlement should be active");
  assert(
    snapshot.productId === "voicebrief_pro_annual:annual",
    "Google base-plan product should be preserved",
  );
  assert(snapshot.store === "play_store", "subscription store should win");
  assert(
    snapshot.accessEndMs === snapshot.periodEndMs,
    "ordinary access should end with the store period",
  );
});

Deno.test("fresh production snapshot wins over a stale sandbox expiration", () => {
  const snapshot = parseRevenueCatSubscriptionSnapshot(
    {
      subscriber: {
        entitlements: {
          pro: {
            product_identifier: "voicebrief_pro_monthly",
            purchase_date: "2026-09-01T00:00:00.000Z",
            expires_date: "2026-10-01T00:00:00.000Z",
          },
        },
        subscriptions: {
          voicebrief_pro_monthly: {
            purchase_date: "2026-09-01T00:00:00.000Z",
            expires_date: "2026-10-01T00:00:00.000Z",
            store: "app_store",
            is_sandbox: false,
          },
        },
      },
    },
    {
      nowMs: Date.parse("2026-09-10T00:00:00.000Z"),
      eventTimestampMs: Date.parse("2026-09-09T00:00:00.000Z"),
      fallbackStore: "PROMOTIONAL",
    },
  );

  assert(
    snapshot.isPro && snapshot.store === "app_store",
    "the reconciled production entitlement must not be downgraded by event fields",
  );
});

Deno.test("customer snapshot separates billing quota from grace access", () => {
  const snapshot = parseRevenueCatSubscriptionSnapshot(
    {
      subscriber: {
        entitlements: {
          pro: {
            product_identifier: "voicebrief_pro_monthly",
            purchase_date: "2026-09-02T10:00:00.000Z",
            expires_date: "2026-10-02T10:00:00.000Z",
            grace_period_expires_date: "2026-10-16T10:00:00.000Z",
          },
        },
        subscriptions: {
          voicebrief_pro_monthly: {
            purchase_date: "2026-09-02T10:00:00.000Z",
            expires_date: "2026-10-02T10:00:00.000Z",
            grace_period_expires_date: "2026-10-16T10:00:00.000Z",
            store: "app_store",
          },
        },
      },
    },
    {
      nowMs: Date.parse("2026-10-05T00:00:00.000Z"),
      eventTimestampMs: Date.parse("2026-10-02T10:00:00.000Z"),
    },
  );

  assert(snapshot.isPro, "grace-period customer should remain Pro");
  assert(
    snapshot.periodEndMs === Date.parse("2026-10-02T10:00:00.000Z"),
    "quota boundary must remain the paid period end",
  );
  assert(
    snapshot.accessEndMs === Date.parse("2026-10-16T10:00:00.000Z"),
    "access should include the grace extension",
  );
});

Deno.test("transfer event accepts RevenueCat shape without app_user_id", () => {
  const ids = revenueCatTransferIds({
    transferred_from: [
      "$RCAnonymousID:source",
      "00005A1C-6091-4F81-BE77-F0A83A271AB6",
    ],
    transferred_to: [
      "4BEDB450-8EF2-11E9-B475-0800200C9A66",
      "$RCAnonymousID:destination",
    ],
  });

  assert(
    ids.destinationUserIds[0] ===
      "4bedb450-8ef2-11e9-b475-0800200c9a66",
    "destination UUID should be normalized",
  );
  assert(ids.sourceUserIds.length === 1, "source UUID should be retained");
  assert(
    ids.sourceRevenueCatIds.length === 2 &&
      ids.sourceRevenueCatIds[0] === "$RCAnonymousID:source",
    "anonymous source alias must be retained for RevenueCat reconciliation",
  );
});

Deno.test("transfer resolves exactly one stored profile among aliases", () => {
  const first = "4bedb450-8ef2-11e9-b475-0800200c9a66";
  const second = "957d8890-db8c-4fd4-a388-ee52bef47b5d";
  const ids = revenueCatTransferIds({
    transferred_from: [],
    transferred_to: [first, second, "$RCAnonymousID:destination"],
  });
  assert(ids.destinationUserIds.length === 2, "UUID aliases were discarded");
  assert(
    resolveRevenueCatTransferDestination(ids.destinationUserIds, [second]) ===
      second,
    "the only matching VoiceBrief profile was not selected",
  );
});

Deno.test("transfer destination resolution fails closed on zero or two profiles", () => {
  const candidates = [
    "4bedb450-8ef2-11e9-b475-0800200c9a66",
    "957d8890-db8c-4fd4-a388-ee52bef47b5d",
  ];
  for (const profiles of [[], candidates]) {
    let rejected = false;
    try {
      resolveRevenueCatTransferDestination(candidates, profiles);
    } catch (error) {
      rejected = error instanceof RevenueCatCustomerError;
    }
    assert(rejected, "ambiguous/missing destination did not fail closed");
  }
});

Deno.test("transfer never silently discards an unsafe source identifier", () => {
  let rejected = false;
  try {
    revenueCatTransferIds({
      transferred_from: ["x".repeat(101)],
      transferred_to: ["4bedb450-8ef2-11e9-b475-0800200c9a66"],
    });
  } catch (error) {
    rejected = error instanceof RevenueCatCustomerError;
  }
  assert(rejected, "unsafe source alias was silently skipped");
});

Deno.test("restore transfer waits while the source receipt is still Pro", () => {
  const freeDestination: RevenueCatSubscriptionSnapshot = {
    isPro: false,
    productId: "",
    store: "app_store",
    periodStartMs: 1,
    periodEndMs: 1,
    accessEndMs: 1,
  };
  const activeSource: RevenueCatSubscriptionSnapshot = {
    isPro: true,
    productId: "voicebrief_pro_monthly",
    store: "app_store",
    periodStartMs: 1,
    periodEndMs: 2,
    accessEndMs: 2,
  };

  assert(
    shouldRetryRevenueCatTransfer(freeDestination, [activeSource]),
    "a lost/lagging destination transfer must be retried",
  );
  assert(
    !shouldRetryRevenueCatTransfer(freeDestination, [
      { ...freeDestination },
    ]),
    "an actually expired transfer may settle as Free",
  );
});

Deno.test("anonymous transfer source remains eligible for the Pro retry", () => {
  const ids = revenueCatTransferIds({
    transferred_from: ["$RCAnonymousID:still-active-source"],
    transferred_to: ["4bedb450-8ef2-11e9-b475-0800200c9a66"],
  });
  const freeDestination: RevenueCatSubscriptionSnapshot = {
    isPro: false,
    productId: "",
    store: "app_store",
    periodStartMs: 1,
    periodEndMs: 1,
    accessEndMs: 1,
  };
  assert(ids.sourceUserIds.length === 0, "anonymous ID reached the UUID RPC");
  assert(
    ids.sourceRevenueCatIds[0] === "$RCAnonymousID:still-active-source",
    "anonymous RevenueCat lookup ID was discarded",
  );
  assert(
    shouldRetryRevenueCatTransfer(freeDestination, [
      { ...freeDestination, isPro: true, productId: "voicebrief_pro_monthly" },
    ]),
    "active anonymous source did not keep the transfer retryable",
  );
});

Deno.test("temporary grant can use sparse customer entitlement fields", () => {
  const snapshot = parseRevenueCatSubscriptionSnapshot(
    {
      subscriber: {
        entitlements: {
          pro: {
            expires_date: "2026-09-03T09:00:00.000Z",
          },
        },
        subscriptions: {},
      },
    },
    {
      nowMs: Date.parse("2026-09-02T10:00:00.000Z"),
      eventTimestampMs: Date.parse("2026-09-02T09:00:00.000Z"),
      fallbackStore: "APP_STORE",
    },
  );

  assert(snapshot.isPro, "temporary entitlement should be active");
  assert(
    snapshot.productId === "revenuecat_temporary_entitlement",
    "sparse grant should use a non-store synthetic product",
  );
  assert(
    snapshot.periodEndMs - snapshot.periodStartMs === 24 * 60 * 60 * 1000,
    "temporary quota should follow the server-reported expiration",
  );
});

Deno.test("expired customer snapshot is Free", () => {
  const eventTimestampMs = Date.parse("2026-09-02T10:00:00.000Z");
  const snapshot = parseRevenueCatSubscriptionSnapshot(
    {
      subscriber: {
        entitlements: {
          pro: {
            product_identifier: "voicebrief_pro_monthly",
            purchase_date: "2026-07-01T00:00:00.000Z",
            expires_date: "2026-08-01T00:00:00.000Z",
          },
        },
      },
    },
    { nowMs: eventTimestampMs, eventTimestampMs },
  );

  assert(!snapshot.isPro, "expired entitlement must not grant Pro");
  assert(
    snapshot.periodStartMs === snapshot.periodEndMs,
    "Free snapshots must not create a quota period",
  );
});

Deno.test("server customer lookup uses encoded ID and secret authorization", async () => {
  let requestedUrl = "";
  let authorization = "";
  let redirect = "";
  let signalPresent = false;
  const snapshot = await fetchRevenueCatSubscriptionSnapshot(
    "user/with space",
    "private-key",
    {
      nowMs: Date.parse("2026-09-02T10:00:00.000Z"),
      eventTimestampMs: Date.parse("2026-09-02T09:00:00.000Z"),
      fetcher: (input, init) => {
        requestedUrl = input.toString();
        authorization = new Headers(init?.headers).get("authorization") ?? "";
        redirect = init?.redirect ?? "";
        signalPresent = init?.signal instanceof AbortSignal;
        return Promise.resolve(
          new Response(JSON.stringify({ subscriber: { entitlements: {} } }), {
            status: 200,
            headers: { "content-type": "application/json" },
          }),
        );
      },
    },
  );

  assert(
    requestedUrl.endsWith("/user%2Fwith%20space"),
    "App User ID must be URL encoded",
  );
  assert(
    authorization === "Bearer private-key",
    "secret authorization is missing",
  );
  assert(redirect === "error", "redirects must fail closed");
  assert(signalPresent, "customer lookup must carry a timeout signal");
  assert(!snapshot.isPro, "empty customer must remain Free");
});

Deno.test("customer lookup fails closed without a server secret", async () => {
  let rejected = false;
  try {
    await fetchRevenueCatSubscriptionSnapshot("user-id", "", {
      nowMs: 1,
      eventTimestampMs: 1,
      fetcher: () => {
        throw new Error("fetch should not run");
      },
    });
  } catch (error) {
    rejected = error instanceof RevenueCatCustomerError;
  }
  assert(rejected, "missing RevenueCat secret must fail closed");
});

Deno.test("customer lookup rejects a newly created empty customer", async () => {
  let rejected = false;
  try {
    await fetchRevenueCatSubscriptionSnapshot("missing-user", "private-key", {
      nowMs: 1,
      eventTimestampMs: 1,
      fetcher: () =>
        Promise.resolve(
          new Response(
            JSON.stringify({ subscriber: { entitlements: {} } }),
            { status: 201 },
          ),
        ),
    });
  } catch (error) {
    rejected = error instanceof RevenueCatCustomerError;
  }
  assert(
    rejected,
    "GET-created customer must retry instead of revoking access",
  );
});

Deno.test("transfer source lookup may classify a missing customer as Free", async () => {
  const snapshot = await fetchRevenueCatSubscriptionSnapshot(
    "expired-transfer-source",
    "private-key",
    {
      nowMs: 2,
      eventTimestampMs: 1,
      allowCreatedCustomer: true,
      fetcher: () =>
        Promise.resolve(
          new Response(
            JSON.stringify({ subscriber: { entitlements: {} } }),
            { status: 201 },
          ),
        ),
    },
  );

  assert(!snapshot.isPro, "a missing source must be treated as expired");
});

Deno.test("customer lookup timeout covers a stalled response body", async () => {
  let rejected = false;
  try {
    await fetchRevenueCatSubscriptionSnapshot("stalled-user", "private-key", {
      nowMs: 1,
      eventTimestampMs: 1,
      timeoutMs: 5,
      fetcher: (_input, init) => {
        const signal = init?.signal;
        return Promise.resolve(
          new Response(
            new ReadableStream({
              start(controller) {
                signal?.addEventListener("abort", () => {
                  controller.error(new DOMException("Timed out", "AbortError"));
                });
              },
            }),
            { status: 200 },
          ),
        );
      },
    });
  } catch (error) {
    rejected = error instanceof RevenueCatCustomerError;
  }
  assert(rejected, "stalled response bodies must fail within the timeout");
});
