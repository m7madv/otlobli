import {
  isFreshTimestamp,
  isRetryableUnmatchedTimestamp,
  notificationTextFromPayload,
  parseIncomingPayment,
  parseListenerPayload,
  sha256Hex,
  verifyHmacSignature,
} from "./core.ts";

function assert(
  condition: unknown,
  message = "assertion failed",
): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals(actual: unknown, expected: unknown): void {
  const actualJson = JSON.stringify(actual);
  const expectedJson = JSON.stringify(expected);
  if (actualJson !== expectedJson) {
    throw new Error(`expected ${expectedJson}, received ${actualJson}`);
  }
}

Deno.test("HMAC verification matches the Android listener byte protocol", async () => {
  const secret = "0123456789abcdef0123456789abcdef";
  const deviceId = "3f5f2b63-759f-4d5f-a33b-3ba9ac784710";
  const eventId = "0123456789abcdef".repeat(4);
  const timestamp = 1783764000123;
  const body = new TextEncoder().encode(
    '{"packageName":"com.shmacash.shamcash","notificationText":"Payment received USD 17.25"}',
  );
  const signature =
    "v1=9409034b2f41a5f30457c632d450c0746d3d62824c5634aa4f2013a32a1d6ba1";

  assert(
    await verifyHmacSignature(
      secret,
      deviceId,
      eventId,
      timestamp,
      body,
      signature,
    ),
  );
  assert(
    !await verifyHmacSignature(
      secret,
      deviceId,
      eventId,
      timestamp,
      new Uint8Array([...body, 32]),
      signature,
    ),
  );
  assert(
    !await verifyHmacSignature(
      `${secret}x`,
      deviceId,
      eventId,
      timestamp,
      body,
      signature,
    ),
  );
});

Deno.test("timestamp replay window rejects stale and future signatures", () => {
  const now = 1783764000000;
  assert(isFreshTimestamp(now - 299_999, now));
  assert(isFreshTimestamp(now + 299_999, now));
  assert(!isFreshTimestamp(now - 300_001, now));
  assert(!isFreshTimestamp(now + 300_001, now));
});

Deno.test("unmatched reconciliation is retryable only for a short recent window", () => {
  const now = Date.parse("2026-07-11T10:00:00.000Z");
  assertEquals(
    isRetryableUnmatchedTimestamp("2026-07-11T09:59:00.000Z", now),
    true,
  );
  assertEquals(
    isRetryableUnmatchedTimestamp("2026-07-11T09:57:00.000Z", now),
    false,
  );
  assertEquals(
    isRetryableUnmatchedTimestamp("not-a-date", now),
    false,
  );
});

Deno.test("body digest is stable for duplicate event binding", async () => {
  assertEquals(
    await sha256Hex(new TextEncoder().encode("abc")),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  );
});

Deno.test("listener payload parsing keeps the signed identity and canonical notification text", () => {
  const payload = parseListenerPayload({
    packageName: "com.shmacash.shamcash",
    title: "شام كاش",
    body: "تم استلام 25 USD",
    bigText: "",
    notificationText: "  تم\nاستلام   25 USD  ",
    sentAt: 1783764000000,
    eventId: "a".repeat(64),
    deviceId: "3f5f2b63-759f-4d5f-a33b-3ba9ac784710",
  });
  assert(payload);
  assertEquals(notificationTextFromPayload(payload), "تم استلام 25 USD");
  assertEquals(payload.sentAt, 1783764000000);
});

Deno.test("parses Arabic incoming USD payment with Arabic digits", () => {
  assertEquals(parseIncomingPayment("تم استلام ٢٥٫٥٠ دولار إلى حسابك"), {
    ok: true,
    amount: 25.5,
    currency: "USD",
    notificationText: "تم استلام ٢٥٫٥٠ دولار إلى حسابك",
  });
});

Deno.test("parses incoming SYP payment with Arabic thousands separator", () => {
  assertEquals(parseIncomingPayment("حوالة واردة بقيمة ١٢٥٬٠٠٠ ل.س"), {
    ok: true,
    amount: 125000,
    currency: "SYP",
    notificationText: "حوالة واردة بقيمة ١٢٥٬٠٠٠ ل.س",
  });
});

Deno.test("parses English incoming USD payment and localized grouping", () => {
  assertEquals(parseIncomingPayment("Payment received: USD 1,234.50"), {
    ok: true,
    amount: 1234.5,
    currency: "USD",
    notificationText: "Payment received: USD 1,234.50",
  });
});

Deno.test("rejects outgoing payments even when amount and incoming-like words coexist", () => {
  const result = parseIncomingPayment("تم إرسال حوالة، تم خصم 25 USD من حسابك");
  assertEquals(result.ok, false);
  assert(!result.ok);
  assertEquals(result.reason, "outgoing_payment");
});

Deno.test("rejects balance-only and OTP notifications", () => {
  const balance = parseIncomingPayment("رصيدك الحالي 500 USD");
  assert(!balance.ok);
  assertEquals(balance.reason, "not_incoming_payment");

  const otp = parseIncomingPayment("رمز التحقق OTP هو 123456");
  assert(!otp.ok);
  assertEquals(otp.reason, "otp_notification");
});

Deno.test("rejects incoming notifications without an explicit currency", () => {
  const result = parseIncomingPayment("تم استلام مبلغ 25000 إلى حسابك");
  assert(!result.ok);
  assertEquals(result.reason, "currency_missing");
});

Deno.test("rejects ambiguous currency or multiple distinct payment amounts", () => {
  const currencies = parseIncomingPayment(
    "تم استلام 25 USD، ما يعادل 325000 ل.س",
  );
  assert(!currencies.ok);
  assertEquals(currencies.reason, "currency_ambiguous");

  const amounts = parseIncomingPayment(
    "تم استلام 25 USD، القيمة السابقة 20 USD",
  );
  assert(!amounts.ok);
  assertEquals(amounts.reason, "amount_ambiguous");
});

Deno.test("rejects fractional SYP but accepts a zero decimal suffix", () => {
  const fractional = parseIncomingPayment("تم استلام 125000.50 SYP");
  assert(!fractional.ok);
  assertEquals(fractional.reason, "amount_missing");

  assertEquals(parseIncomingPayment("تم استلام 125000.00 SYP"), {
    ok: true,
    amount: 125000,
    currency: "SYP",
    notificationText: "تم استلام 125000.00 SYP",
  });
});
