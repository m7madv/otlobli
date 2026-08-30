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

type PublicClaimRow = {
  id: string;
  claim_number: number;
  status: string;
  issue: string;
  customer_notes: string;
  decision_reason: string;
  resolution: string;
  created_at: string;
  updated_at: string;
};

type PublicClaimSubmission = {
  requestId: string;
  storeId: string;
  claimNumber: number;
  status: string;
  duplicate: boolean;
};

const allowedClaimCategories = new Set([
  "malfunction",
  "battery",
  "software",
  "physical_damage",
  "missing_parts",
  "other",
]);
const allowedAttachmentTypes = new Map([
  ["image/jpeg", "jpg"],
  ["image/png", "png"],
  ["image/webp", "webp"],
  ["application/pdf", "pdf"],
]);
const maxAttachmentBytes = 5 * 1024 * 1024;

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
    signature.buffer.slice(
      signature.byteOffset,
      signature.byteOffset + signature.byteLength,
    ) as ArrayBuffer,
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

function claimStatus(value: string) {
  return {
    new: { label: "تم الاستلام", className: "neutral" },
    needs_review: { label: "قيد المراجعة", className: "neutral" },
    approved: { label: "مقبولة", className: "active" },
    in_progress: { label: "قيد المعالجة", className: "neutral" },
    waiting_for_customer: { label: "بانتظار ردك", className: "soon" },
    ready_for_pickup: { label: "جاهزة للاستلام", className: "active" },
    completed: { label: "مكتملة", className: "active" },
    rejected: { label: "مرفوضة", className: "expired" },
    cancelled: { label: "ملغاة", className: "neutral" },
  }[value] ?? { label: "قيد المتابعة", className: "neutral" };
}

function resolutionLabel(value: string) {
  return {
    repair: "إصلاح",
    replacement: "استبدال",
    refund: "استرداد",
    external_service: "مركز خدمة خارجي",
    rejected: "رفض المطالبة",
  }[value] ?? "";
}

function dateTimeLabel(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("ar-QA", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
    timeZone: "Asia/Qatar",
  }).format(date);
}

function claimCategoryOptions() {
  return [
    ["malfunction", "عطل في التشغيل"],
    ["battery", "البطارية أو الطاقة"],
    ["software", "البرمجيات"],
    ["physical_damage", "ضرر مادي"],
    ["missing_parts", "قطعة أو ملحق مفقود"],
    ["other", "أخرى"],
  ].map(([value, label]) => `<option value="${value}">${label}</option>`).join(
    "",
  );
}

export function renderWarranty(
  warranty: WarrantyRow,
  store: { name: string; city: string | null; phone: string | null },
  claims: PublicClaimRow[],
  token: string,
  submittedClaimNumber: string | null,
  attachmentWarning: boolean,
) {
  const status = warrantyStatus(warranty.expiry_date);
  const canSubmitClaim = status.className !== "expired";
  const claimsHtml = claims.length === 0
    ? `<p class="empty">لا توجد مطالبة مسجلة على هذا الضمان.</p>`
    : claims.map((claim) => {
      const state = claimStatus(claim.status);
      const resolution = resolutionLabel(claim.resolution);
      return `<article class="claim">
        <div class="claim-title"><strong dir="ltr">CLM-${
        String(claim.claim_number).padStart(6, "0")
      }</strong><span class="status ${state.className}">${state.label}</span></div>
        <p>${escapeHtml(claim.issue)}</p>
        ${
        claim.customer_notes
          ? `<p class="customer-note">${escapeHtml(claim.customer_notes)}</p>`
          : ""
      }
        ${
        resolution
          ? `<p class="meta">القرار: ${escapeHtml(resolution)}</p>`
          : ""
      }
        ${
        claim.decision_reason
          ? `<p class="meta">سبب القرار: ${
            escapeHtml(claim.decision_reason)
          }</p>`
          : ""
      }
        <p class="meta">آخر تحديث: ${
        escapeHtml(dateTimeLabel(claim.updated_at))
      }</p>
      </article>`;
    }).join("");
  const submittedNotice = submittedClaimNumber
    ? `<div class="success" role="status"><strong>تم تسجيل المطالبة.</strong><span>رقمها <bdi dir="ltr">CLM-${
      escapeHtml(submittedClaimNumber.padStart(6, "0"))
    }</bdi>. احتفظ بهذا الرابط لمتابعتها.${
      attachmentWarning
        ? " لم تُرفع الملفات؛ يمكنك إرسالها مباشرةً إلى المتجر."
        : ""
    }</span></div>`
    : "";
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
        .neutral { background:#edf1f0; color:#33413d; }
        dl { margin:0; display:grid; grid-template-columns:minmax(110px,.72fr) minmax(0,1.6fr); gap:0; }
        dt,dd { margin:0; padding:12px 0; border-bottom:1px solid #e6ecea; }
        dt { color:#64736f; font-weight:650; }
        dd { font-weight:700; overflow-wrap:anywhere; }
        .notice { margin-top:18px; padding:15px; border-radius:15px; background:#eef7f4; color:#31564c; }
        .success { display:grid; gap:3px; margin-bottom:16px; padding:15px; border-radius:15px; background:#dff5ec; color:#075f45; }
        .section { margin-top:18px; padding:22px; background:#fff; border:1px solid #d9e1df; border-radius:22px; }
        .section-head { display:flex; align-items:start; justify-content:space-between; gap:12px; margin-bottom:14px; }
        .section-head p { margin-top:3px; }
        .claims { display:grid; gap:10px; }
        .claim { padding:15px; border:1px solid #e0e7e5; border-radius:16px; }
        .claim-title { display:flex; align-items:center; justify-content:space-between; gap:10px; margin-bottom:8px; }
        .claim .status { margin:0; font-size:.84rem; }
        .meta { margin-top:7px; color:#5f6e6a; font-size:.9rem; }
        .customer-note { margin-top:9px; padding:10px 12px; border-radius:12px; background:#eef7f4; }
        .empty { padding:14px; border-radius:14px; background:#f4f7f6; color:#5f6e6a; }
        form { display:grid; gap:14px; }
        label { display:grid; gap:6px; font-weight:700; }
        input,select,textarea,button { width:100%; min-height:48px; font:inherit; }
        input,select,textarea { padding:12px 14px; color:inherit; background:transparent; border:1px solid #aebbb7; border-radius:14px; }
        textarea { min-height:112px; resize:vertical; }
        input:focus,select:focus,textarea:focus { outline:3px solid rgba(8,127,91,.22); border-color:#087f5b; }
        .files { font-weight:600; }
        .hint { color:#5f6e6a; font-size:.88rem; font-weight:500; }
        .consent { display:flex; align-items:flex-start; gap:9px; font-weight:600; }
        .consent input { width:22px; min-height:22px; margin-top:2px; accent-color:#087f5b; }
        button { border:0; border-radius:999px; background:#087f5b; color:#fff; font-weight:800; cursor:pointer; }
        button:focus-visible { outline:3px solid rgba(8,127,91,.3); outline-offset:3px; }
        .website { position:absolute; inset-inline-start:-10000px; width:1px; height:1px; overflow:hidden; }
        footer { margin-top:18px; text-align:center; color:#6b7774; font-size:.88rem; }
        @media (max-width:420px) { dl { grid-template-columns:1fr; } dt { padding-bottom:2px; border:0; } dd { padding-top:2px; } }
        @media (prefers-color-scheme:dark) {
          body { background:#0c1110; color:#f0f5f3; }
          .card { background:#151b19; border-color:#303a37; box-shadow:none; }
          .muted,dt,footer { color:#aab7b3; }
          dt,dd { border-color:#303a37; }
          .notice { background:#1d302a; color:#c5e8dd; }
          .section { background:#151b19; border-color:#303a37; }
          .claim,input,select,textarea { border-color:#46534f; }
          .empty { background:#1b2421; color:#aab7b3; }
          .neutral { background:#303a37; color:#e2e9e7; }
          .meta,.hint { color:#aab7b3; }
          .customer-note { background:#1d302a; }
        }
      </style>
    </head>
    <body>
      <main>
        <header><div class="mark" aria-hidden="true">✓</div><div><h1>بطاقة ضمان موثّقة</h1><p class="muted">صادرة عبر ضمانك</p></div></header>
        ${submittedNotice}
        <article class="card">
          <div class="card-head"><h2>${escapeHtml(store.name)}</h2><p>${
    escapeHtml(store.city || "قطر")
  }</p></div>
          <div class="body">
            <span class="status ${status.className}">${status.label}</span>
            <dl>
              <dt>رقم الضمان</dt><dd dir="ltr">${
    escapeHtml(warranty.warranty_number)
  }</dd>
              <dt>المنتج</dt><dd>${escapeHtml(warranty.product_name)}</dd>
              <dt>العميل</dt><dd>${
    escapeHtml(maskName(warranty.customer_name))
  }</dd>
              <dt>الهاتف</dt><dd dir="ltr">${
    escapeHtml(maskTail(warranty.customer_phone))
  }</dd>
              <dt>الرقم التسلسلي</dt><dd dir="ltr">${
    escapeHtml(maskTail(warranty.serial_number))
  }</dd>
              <dt>تاريخ الشراء</dt><dd>${
    escapeHtml(dateLabel(warranty.purchase_date))
  }</dd>
              <dt>صالح حتى</dt><dd>${
    escapeHtml(dateLabel(warranty.expiry_date))
  }</dd>
            </dl>
            <p class="notice">احتفظ بهذا الرابط للتحقق من الضمان وتسجيل المطالبة ومتابعتها.${
    store.phone
      ? ` ويمكنك التواصل مع المتجر على <span dir="ltr">${
        escapeHtml(store.phone)
      }</span>.`
      : ""
  }</p>
          </div>
        </article>
        <section class="section" aria-labelledby="claims-title">
          <div class="section-head"><div><h2 id="claims-title">مطالبات هذا الضمان</h2><p class="muted">الحالة المعروضة هي آخر تحديث شاركه المتجر.</p></div></div>
          <div class="claims">${claimsHtml}</div>
        </section>
        <section class="section" aria-labelledby="new-claim-title">
          <div class="section-head"><div><h2 id="new-claim-title">تسجيل مطالبة جديدة</h2><p class="muted">صف المشكلة بوضوح، ويمكنك إضافة 3 صور أو ملفات PDF كحد أقصى.</p></div></div>
          ${
    canSubmitClaim
      ? `<form method="post" action="?token=${
        encodeURIComponent(token)
      }" enctype="multipart/form-data">
            <input type="hidden" name="submissionId" value="${crypto.randomUUID()}">
            <label class="website" aria-hidden="true">اترك هذا الحقل فارغاً<input name="website" tabindex="-1" autocomplete="off"></label>
            <label>نوع المشكلة<select name="category" required>${claimCategoryOptions()}</select></label>
            <label>ما المشكلة؟<textarea name="issue" minlength="3" maxlength="2000" required placeholder="مثال: الجهاز لا يعمل بعد التشغيل"></textarea></label>
            <label>معلومة إضافية للمتجر<textarea name="customerNotes" maxlength="2000" placeholder="اختياري: متى بدأ العطل أو ماذا جربت؟"></textarea></label>
            <label class="files">صور أو إثبات شراء<input type="file" name="attachments" multiple accept="image/jpeg,image/png,image/webp,application/pdf"><span class="hint">حتى 5 MB للملف، وبحد أقصى 3 ملفات. لا ترفع مستند هوية.</span></label>
            <label class="consent"><input type="checkbox" name="consent" value="yes" required><span>أوافق على إرسال هذه البيانات إلى المتجر لمعالجة المطالبة.</span></label>
            <button type="submit">إرسال المطالبة</button>
          </form>`
      : `<p class="empty">انتهت مدة هذا الضمان، لذلك لا يمكن تسجيل مطالبة جديدة من الرابط. تواصل مع المتجر إذا كنت تحتاج إلى مساعدة خارج الضمان.</p>`
  }
        </section>
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
  const { data: userData, error: userError } = await memberClient.auth
    .getUser();
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

function portalMessage(
  status: number,
  title: string,
  message: string,
  backUrl?: string,
) {
  const link = backUrl
    ? `<a href="${escapeHtml(backUrl)}">العودة إلى بطاقة الضمان</a>`
    : "";
  return new Response(
    `<!doctype html>
  <html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>${
      escapeHtml(title)
    } | ضمانك</title><style>
  :root{color-scheme:light dark;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}*{box-sizing:border-box}body{margin:0;display:grid;min-height:100vh;place-items:center;padding:20px;background:#f4f7f6;color:#17211f}.box{width:min(520px,100%);padding:26px;border:1px solid #d9e1df;border-radius:22px;background:#fff}h1{margin:0 0 8px;font-size:1.55rem}p{margin:0;line-height:1.7;color:#53635f}a{display:grid;place-items:center;min-height:48px;margin-top:18px;border-radius:999px;background:#087f5b;color:white;text-decoration:none;font-weight:800}@media(prefers-color-scheme:dark){body{background:#0c1110;color:#f0f5f3}.box{background:#151b19;border-color:#303a37}p{color:#aab7b3}}
  </style></head><body><main class="box"><h1>${escapeHtml(title)}</h1><p>${
      escapeHtml(message)
    }</p>${link}</main></body></html>`,
    {
      status,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": "private, no-store, max-age=0",
        "content-security-policy":
          "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
        "referrer-policy": "no-referrer",
        "x-content-type-options": "nosniff",
        "x-frame-options": "DENY",
      },
    },
  );
}

function textField(form: FormData, name: string) {
  const value = form.get(name);
  return typeof value === "string" ? value.trim() : "";
}

function safeOriginalName(value: string) {
  const normalized = value.trim().replace(/[<>:"/\\|?*\u0000-\u001F]/g, "_");
  return (normalized || "attachment").slice(0, 180);
}

async function submitPublicClaim(request: Request) {
  const url = new URL(request.url);
  const token = url.searchParams.get("token")?.trim();
  if (!token) {
    return portalMessage(
      400,
      "الرابط غير مكتمل",
      "افتح رابط الضمان الأصلي ثم حاول مجدداً.",
    );
  }
  const payload = await verifyToken(token);
  if (!payload) {
    return portalMessage(
      404,
      "انتهت صلاحية الرابط",
      "اطلب من المتجر مشاركة بطاقة ضمان جديدة.",
    );
  }

  const contentLength = Number(request.headers.get("content-length") || "0");
  if (Number.isFinite(contentLength) && contentLength > 16 * 1024 * 1024) {
    return portalMessage(
      413,
      "الملفات كبيرة",
      "اختر حتى 3 ملفات، وبحجم 5 MB لكل ملف.",
      url.toString(),
    );
  }

  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return portalMessage(
      400,
      "تعذّر قراءة الطلب",
      "أعد اختيار الملفات ثم حاول مجدداً.",
      url.toString(),
    );
  }
  if (textField(form, "website")) {
    return portalMessage(
      400,
      "تعذّر إرسال الطلب",
      "أعد فتح بطاقة الضمان وحاول مجدداً.",
      url.toString(),
    );
  }
  if (textField(form, "consent") !== "yes") {
    return portalMessage(
      400,
      "الموافقة مطلوبة",
      "وافق على إرسال البيانات إلى المتجر لمعالجة المطالبة.",
      url.toString(),
    );
  }

  const issue = textField(form, "issue");
  const customerNotes = textField(form, "customerNotes");
  const category = textField(form, "category");
  const submissionId = textField(form, "submissionId");
  if (issue.length < 3 || issue.length > 2000) {
    return portalMessage(
      400,
      "صف المشكلة بوضوح",
      "يجب أن يكون الوصف بين 3 و2000 حرف.",
      url.toString(),
    );
  }
  if (customerNotes.length > 2000 || !allowedClaimCategories.has(category)) {
    return portalMessage(
      400,
      "بيانات المطالبة غير صحيحة",
      "راجع نوع المشكلة والمعلومة الإضافية.",
      url.toString(),
    );
  }
  if (
    !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(submissionId)
  ) {
    return portalMessage(
      400,
      "تعذّر تأكيد الطلب",
      "حدّث الصفحة ثم أرسل المطالبة من جديد.",
      url.toString(),
    );
  }

  const files = form.getAll("attachments").filter((value): value is File =>
    value instanceof File && value.size > 0
  );
  if (files.length > 3) {
    return portalMessage(
      400,
      "ملفات كثيرة",
      "اختر 3 ملفات كحد أقصى.",
      url.toString(),
    );
  }
  for (const file of files) {
    if (
      file.size > maxAttachmentBytes || !allowedAttachmentTypes.has(file.type)
    ) {
      return portalMessage(
        400,
        "ملف غير مدعوم",
        "المسموح JPG وPNG وWebP وPDF حتى 5 MB للملف.",
        url.toString(),
      );
    }
  }

  const admin = createClient(
    requiredEnv("SUPABASE_URL"),
    requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
  const { data, error } = await admin.rpc("submit_public_warranty_claim", {
    target_warranty_id: payload.warrantyId,
    submission_id: submissionId,
    claim_issue: issue,
    claim_category: category,
    claim_customer_notes: customerNotes,
  });
  if (error || !data) {
    const code = error?.message || "";
    if (code.includes("CLAIM_RATE_LIMITED")) {
      return portalMessage(
        429,
        "طلبات كثيرة",
        "وصل هذا الضمان إلى حد الإرسال اليومي. حاول غداً أو تواصل مع المتجر.",
        url.toString(),
      );
    }
    if (code.includes("WARRANTY_EXPIRED")) {
      return portalMessage(
        409,
        "انتهت مدة الضمان",
        "لا يمكن تسجيل مطالبة جديدة بعد انتهاء الضمان. تواصل مع المتجر للمساعدة خارج الضمان.",
        url.toString(),
      );
    }
    console.error("warranty-card submit", code);
    return portalMessage(
      500,
      "تعذّر تسجيل المطالبة",
      "لم تُحفظ المطالبة. حاول مرة أخرى بعد قليل.",
      url.toString(),
    );
  }

  const submission = data as PublicClaimSubmission;
  let attachmentWarning = false;
  if (!submission.duplicate && files.length > 0) {
    const uploadedPaths: string[] = [];
    const attachmentRows: Record<string, unknown>[] = [];
    for (const file of files) {
      const extension = allowedAttachmentTypes.get(file.type)!;
      const path =
        `${submission.storeId}/${submission.requestId}/${crypto.randomUUID()}.${extension}`;
      const { error: uploadError } = await admin.storage
        .from("claim-attachments")
        .upload(path, file, { contentType: file.type, upsert: false });
      if (uploadError) {
        attachmentWarning = true;
        break;
      }
      uploadedPaths.push(path);
      attachmentRows.push({
        request_id: submission.requestId,
        store_id: submission.storeId,
        storage_path: path,
        original_name: safeOriginalName(file.name),
        mime_type: file.type,
        size_bytes: file.size,
        uploaded_by_type: "customer",
        created_by: null,
      });
    }
    if (!attachmentWarning && attachmentRows.length > 0) {
      const { error: metadataError } = await admin
        .from("maintenance_request_attachments")
        .insert(attachmentRows);
      attachmentWarning = Boolean(metadataError);
    }
    if (attachmentWarning && uploadedPaths.length > 0) {
      await admin.storage.from("claim-attachments").remove(uploadedPaths);
    }
  }

  const redirect = new URL(request.url);
  redirect.search = "";
  redirect.searchParams.set("token", token);
  redirect.searchParams.set("submitted", String(submission.claimNumber));
  if (attachmentWarning) redirect.searchParams.set("attachmentWarning", "1");
  return new Response(null, {
    status: 303,
    headers: {
      location: redirect.toString(),
      "cache-control": "no-store",
      "referrer-policy": "no-referrer",
      "x-content-type-options": "nosniff",
    },
  });
}

async function viewWarranty(request: Request) {
  const url = new URL(request.url);
  const token = url.searchParams.get("token")?.trim();
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

  const { data: claims, error: claimsError } = await admin
    .from("maintenance_requests")
    .select(
      "id,claim_number,status,issue,customer_notes,decision_reason,resolution,created_at,updated_at",
    )
    .eq("warranty_id", warranty.id)
    .order("created_at", { ascending: false })
    .limit(20)
    .returns<PublicClaimRow[]>();
  if (claimsError) return json(500, { error: "CLAIMS_UNAVAILABLE" });

  return new Response(
    renderWarranty(
      warranty,
      store,
      claims ?? [],
      token,
      url.searchParams.get("submitted")?.trim() || null,
      url.searchParams.get("attachmentWarning") === "1",
    ),
    {
      status: 200,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": "private, no-store, max-age=0",
        "content-security-policy":
          "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'",
        "permissions-policy": "camera=(), microphone=(), geolocation=()",
        "referrer-policy": "no-referrer",
        "x-content-type-options": "nosniff",
        "x-frame-options": "DENY",
      },
    },
  );
}

if (import.meta.main) {
  Deno.serve(async (request) => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    try {
      if (request.method === "POST") {
        return new URL(request.url).searchParams.has("token")
          ? await submitPublicClaim(request)
          : await issueLink(request);
      }
      if (request.method === "GET") return await viewWarranty(request);
      return json(405, { error: "METHOD_NOT_ALLOWED" });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error("warranty-card", message);
      return json(500, { error: "WARRANTY_CARD_UNAVAILABLE" });
    }
  });
}
