import { handle } from "./index.ts";

Deno.test("scheduled entitlement refresh rejects an invalid secret", async () => {
  Deno.env.set("ENTITLEMENT_REFRESH_SECRET", "expected-secret");
  const response = await handle(
    new Request("https://example.test", {
      method: "POST",
      headers: { authorization: "Bearer wrong-secret" },
    }),
  );
  if (response.status !== 401) {
    throw new Error("refresh endpoint must reject an invalid scheduler secret");
  }
});
