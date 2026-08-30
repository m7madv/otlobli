import { boundedJson, BoundedJsonError } from "./bounded_json.ts";

function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

Deno.test("boundedJson accepts a small JSON body without content-length", async () => {
  const value = await boundedJson(
    new Request("https://voicebrief.test", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ jobId: "job" }),
    }),
    64,
  );
  assert(
    JSON.stringify(value) === JSON.stringify({ jobId: "job" }),
    "small JSON body was not parsed",
  );
});

Deno.test("boundedJson rejects a streamed body larger than the limit", async () => {
  const stream = new ReadableStream<Uint8Array>({
    start(controller) {
      controller.enqueue(new TextEncoder().encode('{"value":"'));
      controller.enqueue(new Uint8Array(80).fill(97));
      controller.enqueue(new TextEncoder().encode('"}'));
      controller.close();
    },
  });
  const request = new Request("https://voicebrief.test", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: stream,
  });
  try {
    await boundedJson(request, 32);
    throw new Error("expected oversized body rejection");
  } catch (error) {
    assert(
      error instanceof BoundedJsonError && error.status === 413,
      "oversized body did not return 413",
    );
  }
});

Deno.test("boundedJson rejects unsupported content types", async () => {
  const request = new Request("https://voicebrief.test", {
    method: "POST",
    headers: { "content-type": "text/plain" },
    body: "{}",
  });
  try {
    await boundedJson(request, 32);
    throw new Error("expected unsupported body rejection");
  } catch (error) {
    assert(
      error instanceof BoundedJsonError && error.status === 415,
      "unsupported body did not return 415",
    );
  }
});
