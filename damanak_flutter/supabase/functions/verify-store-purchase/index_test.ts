import {
  appleEnvironmentOrder,
  decodeAppleClientTransaction,
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
