import { createClient } from "@supabase/supabase-js";

function env(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`MISSING_SECRET_${name}`);
  return value;
}

function json(status: number, body: Record<string, unknown>) {
  return Response.json(body, {
    status,
    headers: {
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
  });
}

function parseIpv4(value: string) {
  const parts = value.split(".");
  if (parts.length !== 4 || parts.some((part) => !/^\d{1,3}$/.test(part))) {
    return null;
  }
  const octets = parts.map(Number);
  if (octets.some((part) => part < 0 || part > 255)) return null;
  return octets;
}

function parseIpv6(value: string) {
  let host = value.replace(/^\[|\]$/g, "").toLowerCase();
  if (!host || host.includes("%") || host.split("::").length > 2) return null;

  if (host.includes(".")) {
    const separator = host.lastIndexOf(":");
    const ipv4 = parseIpv4(host.slice(separator + 1));
    if (separator < 0 || !ipv4) return null;
    host = `${host.slice(0, separator)}:${
      ((ipv4[0] << 8) | ipv4[1]).toString(16)
    }:${((ipv4[2] << 8) | ipv4[3]).toString(16)}`;
  }

  const compressed = host.includes("::");
  const [leftText, rightText = ""] = host.split("::");
  const left = leftText ? leftText.split(":") : [];
  const right = rightText ? rightText.split(":") : [];
  const missing = 8 - left.length - right.length;
  if ((!compressed && missing !== 0) || (compressed && missing < 1)) {
    return null;
  }

  const groups = [...left, ...Array(missing).fill("0"), ...right];
  if (
    groups.length !== 8 ||
    groups.some((part) => !/^[0-9a-f]{1,4}$/.test(part))
  ) return null;

  return groups.reduce(
    (result, part) => (result << 16n) | BigInt(`0x${part}`),
    0n,
  );
}

function ipv6InCidr(address: bigint, base: bigint, prefix: bigint) {
  return address >> (128n - prefix) === base >> (128n - prefix);
}

export function isBlockedAddress(value: string) {
  const host = value.replace(/^\[|\]$/g, "").toLowerCase();
  const ipv4 = parseIpv4(host);
  if (ipv4) {
    const [a, b, c] = ipv4;
    return a === 0 || a === 10 || a === 127 ||
      (a === 100 && b >= 64 && b <= 127) ||
      (a === 169 && b === 254) ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 0 && c === 0) ||
      (a === 192 && b === 0 && c === 2) ||
      (a === 192 && b === 88 && c === 99) ||
      (a === 192 && b === 168) ||
      (a === 198 && (b === 18 || b === 19)) ||
      (a === 198 && b === 51 && c === 100) ||
      (a === 203 && b === 0 && c === 113) ||
      a >= 224;
  }

  const ipv6 = parseIpv6(host);
  if (ipv6 === null) return false;
  return !ipv6InCidr(ipv6, 0x20000000000000000000000000000000n, 3n) || // Outside IANA global unicast space.
    ipv6InCidr(ipv6, 0n, 8n) || // Unspecified, loopback, mapped and translation ranges.
    ipv6InCidr(ipv6, 0x1000000000000000000000000000000n, 64n) || // 100::/64 discard-only.
    ipv6InCidr(ipv6, 0x20010000000000000000000000000000n, 23n) || // IETF assignments; block conservatively, including unassigned children.
    ipv6InCidr(ipv6, 0x20010000000000000000000000000000n, 32n) || // Teredo.
    ipv6InCidr(ipv6, 0x20010002000000000000000000000000n, 48n) || // Benchmarking.
    ipv6InCidr(ipv6, 0x20010010000000000000000000000000n, 28n) || // ORCHID.
    ipv6InCidr(ipv6, 0x20010020000000000000000000000000n, 28n) || // ORCHIDv2.
    ipv6InCidr(ipv6, 0x20010db8000000000000000000000000n, 32n) || // Documentation.
    ipv6InCidr(ipv6, 0x20020000000000000000000000000000n, 16n) || // 6to4.
    ipv6InCidr(ipv6, 0x3fff0000000000000000000000000000n, 20n) || // Documentation.
    ipv6InCidr(ipv6, 0x5f000000000000000000000000000000n, 16n) || // Segment-routing SIDs.
    ipv6InCidr(ipv6, 0xfc000000000000000000000000000000n, 7n) || // Unique-local.
    ipv6InCidr(ipv6, 0xfe800000000000000000000000000000n, 10n) || // Link-local.
    ipv6InCidr(ipv6, 0xfec0000000000000000000000000000n, 10n) || // Deprecated site-local.
    ipv6InCidr(ipv6, 0xff000000000000000000000000000000n, 8n); // Multicast.
}

export function isPublicHttps(value: string) {
  try {
    const url = new URL(value);
    const host = url.hostname.toLowerCase().replace(/\.$/, "");
    const localSuffixes = [
      "localhost",
      "local",
      "internal",
      "home.arpa",
      "lan",
      "home",
      "corp",
      "test",
      "example",
      "invalid",
    ];
    if (
      url.protocol !== "https:" || (url.port && url.port !== "443") ||
      url.username || url.password ||
      localSuffixes.some((suffix) =>
        host === suffix || host.endsWith(`.${suffix}`)
      ) || isBlockedAddress(host)
    ) {
      return false;
    }
    return true;
  } catch {
    return false;
  }
}

export type DnsRecordType = "A" | "AAAA";
export type DnsResolver = (
  hostname: string,
  recordType: DnsRecordType,
  signal: AbortSignal,
) => Promise<string[]>;

const defaultDnsResolver: DnsResolver = async (
  hostname,
  recordType,
  signal,
) => {
  try {
    return await Deno.resolveDns(hostname, recordType, { signal }) as string[];
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) return [];
    throw error;
  }
};

async function withTimeout<T>(
  operation: (signal: AbortSignal) => Promise<T>,
  timeoutMs: number,
) {
  const controller = new AbortController();
  let timedOut = false;
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      operation(controller.signal),
      new Promise<T>((_, reject) => {
        timer = setTimeout(
          () => {
            timedOut = true;
            controller.abort();
            reject(new Error("WEBHOOK_DNS_TIMEOUT"));
          },
          timeoutMs,
        );
      }),
    ]);
  } catch (error) {
    if (timedOut) throw new Error("WEBHOOK_DNS_TIMEOUT");
    throw error;
  } finally {
    if (timer !== undefined) clearTimeout(timer);
  }
}

/**
 * Resolves both A and AAAA records and fails closed before delivery. This
 * screening materially reduces SSRF exposure, but fetch() performs its own DNS
 * lookup. DNS rebinding remains a TOCTOU risk until the runtime supports socket
 * IP pinning or delivery is routed through a trusted egress proxy.
 */
export async function resolvePublicWebhookTarget(
  value: string,
  resolver: DnsResolver = defaultDnsResolver,
  timeoutMs = 2_500,
) {
  if (!isPublicHttps(value)) throw new Error("WEBHOOK_ENDPOINT_BLOCKED");
  const url = new URL(value);
  const hostname = url.hostname.replace(/^\[|\]$/g, "").replace(/\.$/, "");

  if (parseIpv4(hostname) || parseIpv6(hostname) !== null) return url;

  let records: string[];
  try {
    const [ipv4, ipv6] = await Promise.all([
      withTimeout((signal) => resolver(hostname, "A", signal), timeoutMs),
      withTimeout((signal) => resolver(hostname, "AAAA", signal), timeoutMs),
    ]);
    records = [...ipv4, ...ipv6];
  } catch (error) {
    if (error instanceof Error && error.message === "WEBHOOK_DNS_TIMEOUT") {
      throw error;
    }
    throw new Error("WEBHOOK_DNS_UNAVAILABLE");
  }

  if (records.length === 0) throw new Error("WEBHOOK_DNS_NO_PUBLIC_ADDRESS");
  for (const address of records) {
    if (
      (!parseIpv4(address) && parseIpv6(address) === null) ||
      isBlockedAddress(address)
    ) throw new Error("WEBHOOK_ENDPOINT_BLOCKED");
  }
  return url;
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
    if (request.method !== "POST") {
      return json(405, { error: "METHOD_INVALID" });
    }
    if (
      request.headers.get("authorization") !==
        `Bearer ${env("WEBHOOK_DISPATCH_SECRET")}`
    ) {
      return json(401, { error: "AUTH_INVALID" });
    }
    const admin = createClient(
      env("SUPABASE_URL"),
      env("SUPABASE_SERVICE_ROLE_KEY"),
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );
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
        if (!row.is_active) {
          throw new Error("WEBHOOK_ENDPOINT_BLOCKED");
        }
        const body = JSON.stringify(row.payload);
        const timestamp = Math.floor(Date.now() / 1000).toString();
        const digest = await signature(row.signing_secret, timestamp, body);
        const target = await resolvePublicWebhookTarget(endpoint);
        const result = await fetch(target, {
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
        const delayMinutes = [1, 5, 30, 120, 360, 720, 1440][attempt - 1] ||
          1440;
        await admin.from("webhook_deliveries").update({
          status: terminal ? "failed" : "pending",
          attempts: attempt,
          next_attempt_at: new Date(Date.now() + delayMinutes * 60_000)
            .toISOString(),
          locked_at: null,
          last_error: (deliveryError instanceof Error
            ? deliveryError.message
            : "DELIVERY_FAILED").slice(0, 300),
        }).eq("id", row.id);
        retried++;
      }
    }
    return json(200, {
      processed: deliveries?.length ?? 0,
      delivered,
      retried,
    });
  });
}
