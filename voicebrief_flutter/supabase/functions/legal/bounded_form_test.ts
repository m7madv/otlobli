import { BoundedBodyError, boundedFormData } from "./bounded_form.ts";

function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

Deno.test("bounded form parses a normal urlencoded request", async () => {
  const request = new Request("https://example.test/support", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: "email=a%40example.com&message=%D9%85%D8%B1%D8%AD%D8%A8%D8%A7",
  });
  const form = await boundedFormData(request, 1_024);
  assert(form.get("email") === "a@example.com", "email was not parsed");
  assert(form.get("message") === "مرحبا", "Arabic form value was not parsed");
});

Deno.test("bounded form rejects streamed bytes beyond the real limit", async () => {
  const request = new Request("https://example.test/support", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new ReadableStream({
      start(controller) {
        controller.enqueue(new TextEncoder().encode("message="));
        controller.enqueue(new Uint8Array(2_000));
        controller.close();
      },
    }),
  });
  try {
    await boundedFormData(request, 1_024);
    throw new Error("expected oversized body rejection");
  } catch (error) {
    assert(
      error instanceof BoundedBodyError && error.status === 413,
      "oversized body did not return 413",
    );
  }
});

Deno.test("bounded form rejects unsupported content types", async () => {
  const request = new Request("https://example.test/support", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: "{}",
  });
  try {
    await boundedFormData(request, 1_024);
    throw new Error("expected unsupported body rejection");
  } catch (error) {
    assert(
      error instanceof BoundedBodyError && error.status === 415,
      "unsupported body did not return 415",
    );
  }
});
