import { createClient } from "@supabase/supabase-js";

type WarrantyToken = {
  version: 1;
  warrantyId: string;
  expiresAt: number;
};

type WarrantyRow = {
  id: string;
  warranty_number: string;
  store_id: string;
  customer_name: string;
  customer_phone: string;
  product_name: string;
  serial_number: string | null;
  purchase_date: string;
  expiry_date: string;
  created_at: string;
  voided_at?: string | null;
};

const encoder = new TextEncoder();
const decoder = new TextDecoder();
const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "GET, POST, OPTIONS",
};

function requiredEnv(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`MISSING_SECRET_${name}`);
  return value;
}

function base64UrlEncode(value: Uint8Array) {
  let binary = "";
  for (const byte of value) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function base64UrlDecode(value: string) {
  const padded = value.replaceAll("-", "+").replaceAll("_", "/") +
    "=".repeat((4 - value.length % 4) % 4);
  const binary = atob(padded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

async function signingKey() {
  return await crypto.subtle.importKey(
    "raw",
    encoder.encode(requiredEnv("WARRANTY_LINK_SECRET")),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

async function createToken(payload: WarrantyToken) {
  const encodedPayload = base64UrlEncode(
    encoder.encode(JSON.stringify(payload)),
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    await signingKey(),
    encoder.encode(encodedPayload),
  );
  return `${encodedPayload}.${base64UrlEncode(new Uint8Array(signature))}`;
}

async function verifyToken(value: string): Promise<WarrantyToken | null> {
  const [encodedPayload, encodedSignature, extra] = value.split(".");
  if (!encodedPayload || !encodedSignature || extra) return null;
  let signature: Uint8Array;
  let payload: WarrantyToken;
  try {
    signature = base64UrlDecode(encodedSignature);
    payload = JSON.parse(
      decoder.decode(base64UrlDecode(encodedPayload)),
    ) as WarrantyToken;
  } catch {
    return null;
  }
  if (
    payload.version !== 1 ||
    typeof payload.warrantyId !== "string" ||
    !Number.isFinite(payload.expiresAt) ||
    payload.expiresAt <= Math.floor(Date.now() / 1000)
  ) return null;
  const valid = await crypto.subtle.verify(
    "HMAC",
    await signingKey(),
    signature,
    encoder.encode(encodedPayload),
  );
  return valid ? payload : null;
}

function json(status: number, body: Record<string, unknown>) {
  return Response.json(body, {
    status,
    headers: {
      ...corsHeaders,
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
  });
}

function escapeHtml(value: unknown) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function maskName(value: string) {
  const first = value.trim().split(/\s+/)[0] || "عميل";
  return `${first} ${"•".repeat(3)}`;
}

function maskTail(value: string | null, visible = 4) {
  const normalized = (value ?? "").trim();
  if (!normalized) return "غير مسجل";
  const tail = normalized.slice(-visible);
  return `${"•".repeat(Math.max(4, normalized.length - tail.length))}${tail}`;
}

function dateLabel(value: string) {
  const date = new Date(`${value}T00:00:00Z`);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("ar-QA", {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  }).format(date);
}

function warrantyStatus(expiryDate: string) {
  const expiry = new Date(`${expiryDate}T23:59:59Z`).getTime();
  const remainingDays = Math.ceil((expiry - Date.now()) / 86_400_000);
  if (remainingDays < 0) return { label: "منتهي", className: "expired" };
  if (remainingDays <= 30) {
    return { label: "قارب على الانتهاء", className: "soon" };
  }
  return { label: "ساري", className: "active" };
}

function renderWarranty(
  warranty: WarrantyRow,
  store: { name: string; city: string | null; phone: string | null },
) {
  const status = warrantyStatus(warranty.expiry_date);
  return `<!doctype html>
  <html lang="ar" dir="rtl">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <meta name="robots" content="noindex,nofollow,noarchive">
      <title>ضمان ${escapeHtml(warranty.warranty_number)} | ضمانك</title>
      <style>
        :root { color-scheme: light dark; font-family: -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; }
        * { box-sizing: border-box; }
        body { margin: 0; background: #f4f7f6; color: #17211f; line-height: 1.65; }
        main { width: min(680px,calc(100% - 28px)); margin: 28px auto; }
        header { display:flex; align-items:center; gap:12px; margin-bottom:18px; }
        .mark { display:grid; place-items:center; width:48px; height:48px; border-radius:15px; background:#087f5b; color:white; font-size:24px; }
        h1,h2,p { margin:0; }
        h1 { font-size:clamp(1.45rem,5vw,2rem); }
        .muted { color:#5f6e6a; }
        .card { background:#fff; border:1px solid #d9e1df; border-radius:22px; overflow:hidden; box-shadow:0 16px 44px rgba(15,45,36,.07); }
        .card-head { padding:22px; background:#087f5b; color:#fff; }
        .card-head p { opacity:.8; }
        .body { padding:22px; }
        .status { display:inline-flex; align-items:center; min-height:34px; padding:5px 12px; border-radius:999px; font-weight:750; margin-bottom:18px; }
        .active { background:#dff5ec; color:#075f45; }
        .soon { background:#fff1c7; color:#745500; }
        .expired { background:#fde6e4; color:#8c2922; }
        dl { margin:0; display:grid; grid-template-columns:minmax(110px,.72fr) minmax(0,1.6fr); gap:0; }
        dt,dd { margin:0; padding:12px 0; border-bottom:1px solid #e6ecea; }
        dt { color:#64736f; font-weight:650; }
        dd { font-weight:700; overflow-wrap:anywhere; }
        .notice { margin-top:18px; padding:15px; border-radius:15px; background:#eef7f4; color:#31564c; }
        footer { margin-top:18px; text-align:center; color:#6b7774; font-size:.88rem; }
        @media (max-width:420px) { dl { grid-template-columns:1fr; } dt { padding-bottom:2px; border:0; } dd { padding-top:2px; } }
        @media (prefers-color-scheme:dark) {
          body { background:#0c1110; color:#f0f5f3; }
          .card { background:#151b19; border-color:#303a37; box-shadow:none; }
          .muted,dt,footer { color:#aab7b3; }
          dt,dd { border-color:#303a37; }
          .notice { background:#1d302a; color:#c5e8dd; }
        }
      </style>
    </head>
    <body>
      <main>
        <header><div class="mark" aria-hidden="true">✓</div><div><h1>بطاقة ضمان موثّقة</h1><p class="muted">صادرة عبر ضمانك</p></div></header>
        <article class="card">
          <div class="card-head"><h2>${escapeHtml(store.name)}</h2><p>${escapeHtml(store.city || "قطر")}</p></div>
          <div class="body">
            <span class="status ${status.className}">${status.label}</span>
            <dl>
              <dt>رقم الضمان</dt><dd dir="ltr">${escapeHtml(warranty.warranty_number)}</dd>
              <dt>المنتج</dt><dd>${escapeHtml(warranty.product_name)}</dd>
              <dt>العميل</dt><dd>${escapeHtml(maskName(warranty.customer_name))}</dd>
              <dt>الهاتف</dt><dd dir="ltr">${escapeHtml(maskTail(warranty.customer_phone))}</dd>
              <dt>الرقم التسلسلي</dt><dd dir="ltr">${escapeHtml(maskTail(warranty.serial_number))}</dd>
              <dt>تاريخ الشراء</dt><dd>${escapeHtml(dateLabel(warranty.purchase_date))}</dd>
              <dt>صالح حتى</dt><dd>${escapeHtml(dateLabel(warranty.expiry_date))}</dd>
            </dl>
            <p class="notice">هذه الصفحة للتحقق من سجل الضمان لدى المتجر. للاستفسار أو طلب الصيانة تواصل مع المتجر${store.phone ? ` على <span dir="ltr">${escapeHtml(store.phone)}</span>` : ""}.</p>
          </div>
        </article>
        <footer>لا تعرض هذه الصفحة الاسم الكامل أو رقم الهاتف أو الرقم التسلسلي لحماية الخصوصية.</footer>
      </main>
    </body>
  </html>`;
}

async function issueLink(request: Request) {
  const authorization = request.headers.get("authorization")?.trim();
  if (!authorization) return json(401, { error: "AUTH_REQUIRED" });
  let body: { warrantyId?: string };
  try {
    body = await request.json();
  } catch {
    return json(400, { error: "INVALID_JSON" });
  }
  const warrantyId = body.warrantyId?.trim();
  if (!warrantyId) return json(400, { error: "WARRANTY_REQUIRED" });

  const supabaseUrl = requiredEnv("SUPABASE_URL");
  const memberClient = createClient(
    supabaseUrl,
    requiredEnv("SUPABASE_ANON_KEY"),
    { global: { headers: { Authorization: authorization } } },
  );
  const { data: userData, error: userError } = await memberClient.auth.getUser();
  if (userError || !userData.user) {
    return json(401, { error: "AUTH_INVALID" });
  }
  const { data, error } = await memberClient
    .from("warranties")
    .select("id, expiry_date")
    .eq("id", warrantyId)
    .is("voided_at", null)
    .maybeSingle();
  if (error || !data) return json(404, { error: "WARRANTY_NOT_FOUND" });

  const nowSeconds = Math.floor(Date.now() / 1000);
  const expirySeconds = Math.floor(
    new Date(`${data.expiry_date}T23:59:59Z`).getTime() / 1000,
  );
  const expiresAt = Math.max(
    nowSeconds + 365 * 86_400,
    expirySeconds + 2 * 365 * 86_400,
  );
  const token = await createToken({ version: 1, warrantyId, expiresAt });
  const url = new URL(request.url);
  url.search = "";
  url.searchParams.set("token", token);
  return json(200, {
    url: url.toString(),
    expiresAt: new Date(expiresAt * 1000).toISOString(),
  });
}

async function viewWarranty(request: Request) {
  const token = new URL(request.url).searchParams.get("token")?.trim();
  if (!token) return json(400, { error: "TOKEN_REQUIRED" });
  const payload = await verifyToken(token);
  if (!payload) return json(404, { error: "LINK_INVALID_OR_EXPIRED" });

  const admin = createClient(
    requiredEnv("SUPABASE_URL"),
    requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
  const { data: warranty, error } = await admin
    .from("warranties")
    .select(
      "id,warranty_number,store_id,customer_name,customer_phone,product_name,serial_number,purchase_date,expiry_date,created_at,voided_at",
    )
    .eq("id", payload.warrantyId)
    .is("voided_at", null)
    .maybeSingle<WarrantyRow>();
  if (error || !warranty) return json(404, { error: "WARRANTY_NOT_FOUND" });
  const { data: store, error: storeError } = await admin
    .from("stores")
    .select("name,city,phone")
    .eq("id", warranty.store_id)
    .maybeSingle();
  if (storeError || !store) return json(404, { error: "STORE_NOT_FOUND" });

  return new Response(renderWarranty(warranty, store), {
    status: 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "private, no-store, max-age=0",
      "content-security-policy":
        "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
      "permissions-policy": "camera=(), microphone=(), geolocation=()",
      "referrer-policy": "no-referrer",
      "x-content-type-options": "nosniff",
      "x-frame-options": "DENY",
    },
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    if (request.method === "POST") return await issueLink(request);
    if (request.method === "GET") return await viewWarranty(request);
    return json(405, { error: "METHOD_NOT_ALLOWED" });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("warranty-card", message);
    return json(500, { error: "WARRANTY_CARD_UNAVAILABLE" });
  }
});
