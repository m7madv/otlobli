import { createClient } from "@supabase/supabase-js";

function env(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`MISSING_SECRET_${name}`);
  return value;
}

function json(status: number, body: Record<string, unknown>) {
  return Response.json(body, {
    status,
    headers: { "cache-control": "no-store", "x-content-type-options": "nosniff" },
  });
}

function isBlockedAddress(value: string) {
  const host = value.replace(/^\[|\]$/g, "").toLowerCase();
  const mapped = host.match(/^::ffff:(\d+\.\d+\.\d+\.\d+)$/)?.[1];
  if (mapped) return isBlockedAddress(mapped);
  if (host.includes(":")) {
    return host === "::" || host === "::1" || host.startsWith("fc") ||
      host.startsWith("fd") || /^fe[89ab]/.test(host) || host.startsWith("ff");
  }
  const parts = host.split(".").map(Number);
  if (parts.length !== 4 || parts.some((part) => !Number.isInteger(part) || part < 0 || part > 255)) {
    return false;
  }
  const [a, b] = parts;
  return a === 0 || a === 10 || a === 127 ||
    (a === 100 && b >= 64 && b <= 127) ||
    (a === 169 && b === 254) ||
    (a === 172 && b >= 16 && b <= 31) ||
    (a === 192 && (b === 0 || b === 168)) ||
    (a === 198 && (b === 18 || b === 19)) || a >= 224;
}

export function isPublicHttps(value: string) {
  try {
    const url = new URL(value);
    const host = url.hostname.toLowerCase();
    if (url.protocol !== "https:" || url.username || url.password ||
      host === "localhost" || host.endsWith(".localhost") ||
      host.endsWith(".local") || host.endsWith(".internal") ||
      host.endsWith(".home.arpa") || isBlockedAddress(host)) {
      return false;
    }
    return true;
  } catch {
    return false;
  }
}

async function signature(secret: string, timestamp: string, body: string) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signed = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(`${timestamp}.${body}`),
  );
  return Array.from(new Uint8Array(signed))
    .map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

if (import.meta.main) {
  Deno.serve(async (request) => {
    if (request.method !== "POST") return json(405, { error: "METHOD_INVALID" });
    if (request.headers.get("authorization") !== `Bearer ${env("WEBHOOK_DISPATCH_SECRET")}`) {
      return json(401, { error: "AUTH_INVALID" });
    }
    const admin = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await admin.rpc("claim_webhook_deliveries", {
      requested_limit: 25,
    });
    if (error) return json(500, { error: "QUEUE_UNAVAILABLE" });
    const deliveries = Array.isArray(data) ? data : [];
    let delivered = 0;
    let retried = 0;
    for (const row of deliveries ?? []) {
      const endpoint = row.endpoint_url || "";
      const attempt = Number(row.attempts || 0) + 1;
      try {
        if (!row.is_active || !isPublicHttps(endpoint)) {
          throw new Error("WEBHOOK_ENDPOINT_BLOCKED");
        }
        const body = JSON.stringify(row.payload);
        const timestamp = Math.floor(Date.now() / 1000).toString();
        const digest = await signature(row.signing_secret, timestamp, body);
        const result = await fetch(endpoint, {
          method: "POST",
          redirect: "error",
          signal: AbortSignal.timeout(10_000),
          headers: {
            "content-type": "application/json",
            "user-agent": "Damanak-Webhook/1.0",
            "x-damanak-event": row.event_name,
            "x-damanak-delivery": row.id,
            "x-damanak-timestamp": timestamp,
            "x-damanak-signature": `v1=${digest}`,
          },
          body,
        });
        if (result.status < 200 || result.status >= 300) {
          throw new Error(`HTTP_${result.status}`);
        }
        await admin.from("webhook_deliveries").update({
          status: "delivered",
          attempts: attempt,
          response_status: result.status,
          delivered_at: new Date().toISOString(),
          last_error: null,
          locked_at: null,
        }).eq("id", row.id);
        delivered++;
      } catch (deliveryError) {
        const terminal = attempt >= 8;
        const delayMinutes = [1, 5, 30, 120, 360, 720, 1440][attempt - 1] || 1440;
        await admin.from("webhook_deliveries").update({
          status: terminal ? "failed" : "pending",
          attempts: attempt,
          next_attempt_at: new Date(Date.now() + delayMinutes * 60_000).toISOString(),
          locked_at: null,
          last_error: (deliveryError instanceof Error
            ? deliveryError.message
            : "DELIVERY_FAILED").slice(0, 300),
        }).eq("id", row.id);
        retried++;
      }
    }
    return json(200, { processed: deliveries?.length ?? 0, delivered, retried });
  });
}
