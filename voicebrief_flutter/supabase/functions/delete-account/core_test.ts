import {
  deleteAccountWithRevenueCatFirst,
  deleteRevenueCatSubscriber,
  type RevenueCatDeleteFetcher,
  RevenueCatSubscriberDeletionError,
} from "./core.ts";

const userId = "11111111-1111-4111-8111-111111111111";

function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

async function expectDeletionError(
  action: () => Promise<unknown>,
  code: string,
  status: number | null = null,
) {
  try {
    await action();
  } catch (error) {
    assert(
      error instanceof RevenueCatSubscriberDeletionError,
      "unexpected error type",
    );
    assert(error.code === code, `expected ${code}, received ${error.code}`);
    assert(
      error.status === status,
      `expected status ${status}, received ${error.status}`,
    );
    return;
  }
  throw new Error(`expected ${code}`);
}

Deno.test("RevenueCat subscriber deletion uses the private v1 endpoint", async () => {
  let requestedUrl = "";
  let requestedInit: RequestInit | undefined;
  const fetcher: RevenueCatDeleteFetcher = (input, init) => {
    requestedUrl = input.toString();
    requestedInit = init;
    return Promise.resolve(new Response(null, { status: 200 }));
  };

  await deleteRevenueCatSubscriber(userId, "rc-secret", fetcher);

  assert(
    requestedUrl ===
      `https://api.revenuecat.com/v1/subscribers/${userId}`,
    "unexpected RevenueCat URL",
  );
  assert(requestedInit?.method === "DELETE", "unexpected HTTP method");
  const headers = new Headers(requestedInit?.headers);
  assert(
    headers.get("authorization") === "Bearer rc-secret",
    "missing RevenueCat authorization",
  );
  assert(requestedInit?.redirect === "error", "redirects must fail closed");
});

Deno.test("RevenueCat 404 is an idempotent deletion success", async () => {
  await deleteRevenueCatSubscriber(
    userId,
    "rc-secret",
    () => Promise.resolve(new Response(null, { status: 404 })),
  );
});

Deno.test("RevenueCat rejection prevents local deletion from continuing", async () => {
  await expectDeletionError(
    () =>
      deleteRevenueCatSubscriber(
        userId,
        "rc-secret",
        () => Promise.resolve(new Response(null, { status: 401 })),
      ),
    "revenuecat_delete_failed",
    401,
  );
});

Deno.test("RevenueCat transport failures are sanitized", async () => {
  await expectDeletionError(
    () =>
      deleteRevenueCatSubscriber(
        userId,
        "rc-secret",
        () => Promise.reject(new Error("response contained a secret")),
      ),
    "revenuecat_unavailable",
  );
});

Deno.test("RevenueCat deletion fails closed without a secret", async () => {
  let called = false;
  await expectDeletionError(
    () =>
      deleteRevenueCatSubscriber(userId, "", () => {
        called = true;
        return Promise.resolve(new Response(null, { status: 200 }));
      }),
    "revenuecat_not_configured",
  );
  assert(!called, "RevenueCat was called without a configured secret");
});

Deno.test("Supabase deletion never starts when RevenueCat fails", async () => {
  let supabaseDeletionStarted = false;
  await expectDeletionError(
    () =>
      deleteAccountWithRevenueCatFirst(
        () =>
          deleteRevenueCatSubscriber(
            userId,
            "rc-secret",
            () => Promise.resolve(new Response(null, { status: 500 })),
          ),
        () => {
          supabaseDeletionStarted = true;
          return Promise.resolve();
        },
      ),
    "revenuecat_delete_failed",
    500,
  );
  assert(
    !supabaseDeletionStarted,
    "Supabase deletion started after RevenueCat rejected the request",
  );
});

Deno.test("Supabase deletion starts only after RevenueCat succeeds", async () => {
  const calls: string[] = [];
  await deleteAccountWithRevenueCatFirst(
    () => {
      calls.push("revenuecat");
      return Promise.resolve();
    },
    () => {
      calls.push("supabase");
      return Promise.resolve();
    },
  );
  assert(
    JSON.stringify(calls) === JSON.stringify(["revenuecat", "supabase"]),
    `unexpected deletion order: ${calls.join(",")}`,
  );
});
