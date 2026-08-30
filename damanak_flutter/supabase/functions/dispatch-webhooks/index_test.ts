import { isPublicHttps } from "./index.ts";

function assertEquals(actual: unknown, expected: unknown, message?: string) {
  if (actual !== expected) {
    throw new Error(message || `Expected ${expected}, received ${actual}`);
  }
}

Deno.test("webhook endpoints reject local networks and embedded credentials", () => {
  for (const value of [
    "http://example.com/hook",
    "https://localhost/hook",
    "https://api.internal/hook",
    "https://127.0.0.1/hook",
    "https://10.0.0.8/hook",
    "https://100.64.1.1/hook",
    "https://172.31.1.2/hook",
    "https://192.168.1.2/hook",
    "https://[::1]/hook",
    "https://user:pass@example.com/hook",
  ]) {
    assertEquals(isPublicHttps(value), false, value);
  }
});

Deno.test("webhook endpoints accept a public HTTPS URL", () => {
  assertEquals(isPublicHttps("https://hooks.example.com/damanak"), true);
});
