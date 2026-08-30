import {
  type DnsResolver,
  isBlockedAddress,
  isPublicHttps,
  resolvePublicWebhookTarget,
} from "./index.ts";

function assertEquals(actual: unknown, expected: unknown, message?: string) {
  if (actual !== expected) {
    throw new Error(message || `Expected ${expected}, received ${actual}`);
  }
}

async function assertRejects(
  operation: () => Promise<unknown>,
  expectedMessage: string,
) {
  try {
    await operation();
  } catch (error) {
    assertEquals(
      error instanceof Error ? error.message : String(error),
      expectedMessage,
    );
    return;
  }
  throw new Error(`Expected rejection: ${expectedMessage}`);
}

Deno.test("webhook endpoints reject local networks and embedded credentials", () => {
  for (
    const value of [
      "http://example.com/hook",
      "https://localhost/hook",
      "https://localhost./hook",
      "https://api.internal/hook",
      "https://api.internal./hook",
      "https://api.corp/hook",
      "https://hooks.example/hook",
      "https://127.0.0.1/hook",
      "https://2130706433/hook",
      "https://0x7f000001/hook",
      "https://10.0.0.8/hook",
      "https://100.64.1.1/hook",
      "https://172.31.1.2/hook",
      "https://192.168.1.2/hook",
      "https://[::1]/hook",
      "https://user:pass@example.com/hook",
      "https://example.com:8443/hook",
    ]
  ) {
    assertEquals(isPublicHttps(value), false, value);
  }
});

Deno.test("webhook endpoints accept a public HTTPS URL", () => {
  assertEquals(isPublicHttps("https://hooks.example.com/damanak"), true);
  assertEquals(isPublicHttps("https://hooks.example.com:443/damanak"), true);
});

Deno.test("reserved IPv4 and IPv6 address ranges are blocked", () => {
  for (
    const address of [
      "192.0.2.10",
      "198.51.100.4",
      "203.0.113.5",
      "240.0.0.1",
      "::ffff:10.0.0.1",
      "100::1",
      "2001:5::1",
      "2001:db8::1",
      "3fff::1",
      "4000::1",
      "fc00::1",
      "fe80::1",
    ]
  ) assertEquals(isBlockedAddress(address), true, address);

  assertEquals(isBlockedAddress("93.184.216.34"), false);
  assertEquals(isBlockedAddress("2606:2800:220:1:248:1893:25c8:1946"), false);
});

Deno.test("DNS validation resolves A and AAAA and accepts only public answers", async () => {
  const queries: string[] = [];
  const resolver: DnsResolver = async (hostname, recordType) => {
    queries.push(`${hostname}:${recordType}`);
    return recordType === "A" ? ["93.184.216.34"] : [];
  };
  const target = await resolvePublicWebhookTarget(
    "https://hooks.example.com/damanak",
    resolver,
  );
  assertEquals(target.hostname, "hooks.example.com");
  assertEquals(
    queries.sort().join(","),
    "hooks.example.com:A,hooks.example.com:AAAA",
  );
});

Deno.test("DNS validation rejects mixed public and private answers", async () => {
  const resolver: DnsResolver = async (_hostname, recordType) =>
    recordType === "A" ? ["93.184.216.34"] : ["fd00::1"];
  await assertRejects(
    () => resolvePublicWebhookTarget("https://hooks.example.com", resolver),
    "WEBHOOK_ENDPOINT_BLOCKED",
  );
});

Deno.test("DNS validation rejects invalid or empty answers", async () => {
  await assertRejects(
    () =>
      resolvePublicWebhookTarget("https://hooks.example.com", async () => []),
    "WEBHOOK_DNS_NO_PUBLIC_ADDRESS",
  );
  await assertRejects(
    () =>
      resolvePublicWebhookTarget(
        "https://hooks.example.com",
        async () => ["not-an-address"],
      ),
    "WEBHOOK_ENDPOINT_BLOCKED",
  );
});

Deno.test("DNS validation fails closed on resolver error or timeout", async () => {
  await assertRejects(
    () =>
      resolvePublicWebhookTarget(
        "https://hooks.example.com",
        async () => {
          throw new Error("resolver failed");
        },
      ),
    "WEBHOOK_DNS_UNAVAILABLE",
  );
  let aborted = false;
  await assertRejects(
    () =>
      resolvePublicWebhookTarget(
        "https://hooks.example.com",
        (_hostname, _recordType, signal) =>
          new Promise((_, reject) => {
            signal.addEventListener("abort", () => {
              aborted = true;
              reject(new DOMException("aborted", "AbortError"));
            });
          }),
        5,
      ),
    "WEBHOOK_DNS_TIMEOUT",
  );
  assertEquals(aborted, true);
});

Deno.test("public IP literals do not require a second DNS lookup", async () => {
  let called = false;
  const target = await resolvePublicWebhookTarget(
    "https://93.184.216.34:443/damanak",
    async () => {
      called = true;
      return [];
    },
  );
  assertEquals(target.hostname, "93.184.216.34");
  assertEquals(called, false);
});
