// دالة حافة: تسجيل الدخول/الربط عبر جوجل.
// حساب العميل هو المرتكز، وبيانات الاستلام منفصلة عن وسائل تسجيل الدخول:
//  - هوية جوجل المربوطة → نصدر جلسة فورية.
//  - هوية جوجل الجديدة → ينشئ التطبيق الحساب مع رقم استلام غير موثّق.
//  - توثيق رقم الاستلام لاحقاً عبر OTP يجعله وسيلة دخول اختيارية.
//
// أمان: لا تعمل الدالة إطلاقاً ما لم تُضبط GOOGLE_CLIENT_IDS (تفشل مغلقة).
// التحقق من التوقيع/الصلاحية يتم عبر خدمة جوجل tokeninfo (موقّعة من جوجل).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
// معرّفات عملاء OAuth المسموح بها (Web/Android/iOS)، مفصولة بفواصل.
const ALLOWED_AUDS = (Deno.env.get('GOOGLE_CLIENT_IDS') ?? '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean)

const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000 // 30 يوماً

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })
}

async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

function randomToken(): string {
  const bytes = new Uint8Array(32)
  crypto.getRandomValues(bytes)
  // base64url
  let bin = ''
  bytes.forEach((b) => (bin += String.fromCharCode(b)))
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

type GoogleClaims = {
  sub: string
  email?: string
  email_verified?: string | boolean
  name?: string
  aud?: string
  iss?: string
  exp?: string | number
}

// يتحقق من رمز هوية جوجل ويعيد الادعاءات، أو null إن كان غير صالح.
async function verifyGoogleIdToken(idToken: string): Promise<GoogleClaims | null> {
  if (!idToken || idToken.length < 20) return null
  try {
    const res = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`,
      { signal: AbortSignal.timeout(8000) },
    )
    if (!res.ok) return null
    const claims = (await res.json()) as GoogleClaims
    // المُصدِر يجب أن يكون جوجل.
    const iss = claims.iss ?? ''
    if (iss !== 'accounts.google.com' && iss !== 'https://accounts.google.com') return null
    // الجمهور يجب أن يطابق أحد معرّفات عملائنا.
    if (!claims.aud || !ALLOWED_AUDS.includes(claims.aud)) return null
    // انتهاء الصلاحية.
    const exp = Number(claims.exp ?? 0)
    if (!exp || exp * 1000 <= Date.now()) return null
    if (!claims.sub) return null
    return claims
  } catch {
    return null
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405, headers: corsHeaders })
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return json({ error: 'google_auth_not_configured' }, 503)

  let body: {
    idToken?: string
    action?: string
    clientId?: string
    sessionToken?: string
    phone?: string
    name?: string
    governorate?: string
    qadmousBranch?: string
    city?: string
    details?: string
  }
  try {
    body = (await req.json()) as typeof body
  } catch {
    return json({ error: 'invalid_body' }, 400)
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // الجلسة الحالية هي إثبات الهوية هنا، لذلك لا نطلب رمز جوجل لقراءة الحالة.
  if (body.action === 'status') {
    const sessionToken = (body.sessionToken ?? '').trim()
    if (!sessionToken) return json({ error: 'missing_session' }, 401)
    const { data, error } = await supabase.rpc('get_customer_auth_methods', {
      p_session_token: sessionToken,
    })
    if (error) {
      const code = /invalid customer session/i.test(error.message) ? 'invalid_session' : error.message
      return json({ error: code }, 401)
    }
    return json(data ?? {})
  }

  // All Google-token operations fail closed until allowed audiences exist.
  // Reading the current account's linked methods needs only its valid Otlobli
  // session and remains available for Apple/phone-only configurations.
  if (ALLOWED_AUDS.length === 0) {
    return json({ error: 'google_auth_not_configured' }, 503)
  }

  // OAuth client IDs are public configuration. This narrow check lets release
  // CI prove that the exact iOS client embedded in the IPA is also accepted by
  // the backend, without revealing the rest of the allowlist or any secret.
  if (body.action === 'configuration-check') {
    const clientId = (body.clientId ?? '').trim()
    if (!clientId || clientId.length > 255) return json({ error: 'invalid_google_client' }, 400)
    const { data: schemaStatus, error: schemaError } = await supabase.rpc('auth_schema_readiness')
    const schema = (schemaStatus ?? {}) as { ready?: boolean; version?: string }
    return json({
      configured: ALLOWED_AUDS.includes(clientId) && !schemaError &&
        schema.ready === true && schema.version === 'auth-v86.212-1',
    })
  }

  const idToken = (body.idToken ?? '').trim()
  const claims = await verifyGoogleIdToken(idToken)
  if (!claims) return json({ error: 'invalid_google_token' }, 401)

  const emailVerified = claims.email_verified === true || claims.email_verified === 'true'

  // ── مسار الربط: مستخدم مصادَق عليه (بجلسة هاتف) يربط جوجل بحسابه ──────────
  if (body.action === 'link') {
    const sessionToken = (body.sessionToken ?? '').trim()
    if (!sessionToken) return json({ error: 'missing_session' }, 401)
    const { error } = await supabase.rpc('link_customer_identity', {
      p_session_token: sessionToken,
      p_provider: 'google',
      p_provider_user_id: claims.sub,
      p_email: claims.email ?? null,
      p_email_verified: emailVerified,
      p_display_name: claims.name ?? null,
    })
    if (error) {
      const msg = /another account/i.test(error.message)
        ? 'حساب جوجل هذا مرتبط بحساب آخر.'
        : error.message
      return json({ ok: false, error: msg }, 409)
    }
    return json({ ok: true, linked: true })
  }

  // ── إنشاء حساب Google جديد مع بيانات الاستلام، من دون ربط الرقم للدخول ──
  if (body.action === 'register') {
    const rawToken = randomToken()
    const tokenHash = await sha256Hex(rawToken)
    const expiresAt = new Date(Date.now() + SESSION_TTL_MS).toISOString()
    const { data, error } = await supabase.rpc('register_external_customer', {
      p_provider: 'google',
      p_provider_user_id: claims.sub,
      p_email: claims.email ?? null,
      p_email_verified: emailVerified,
      p_display_name: claims.name ?? null,
      p_phone: body.phone ?? '',
      p_name: body.name ?? claims.name ?? '',
      p_governorate: body.governorate ?? 'دمشق',
      p_qadmous_branch: body.qadmousBranch ?? '',
      p_city: body.city ?? '',
      p_details: body.details ?? '',
      p_token_hash: tokenHash,
      p_expires_at: expiresAt,
    })
    if (error) {
      if (/delivery phone already belongs/i.test(error.message)) {
        return json({
          error: 'phone_account_exists',
          message: 'هذا الرقم مرتبط بحساب موجود. ادخل بالرقم أولاً، ثم اربط Google من «حسابي».',
        }, 409)
      }
      if (/provider identity already registered/i.test(error.message)) {
        return json({
          error: 'google_account_exists',
          message: 'حساب Google هذا مسجّل بالفعل. أعد تسجيل الدخول.',
        }, 409)
      }
      if (/verified email already belongs/i.test(error.message)) {
        return json({
          error: 'verified_email_account_exists',
          message: 'هذا البريد مرتبط بحساب موجود. ادخل بطريقتك الحالية ثم اربط Google.',
        }, 409)
      }
      return json({ error: error.message }, 400)
    }

    const registered = (data ?? {}) as { phone?: string; name?: string }
    return json({
      mode: 'registered',
      sessionToken: rawToken,
      phone: registered.phone ?? body.phone ?? '',
      name: registered.name ?? body.name ?? claims.name ?? '',
      google: { sub: claims.sub, email: claims.email ?? '', name: claims.name ?? '', emailVerified },
    })
  }

  // ── مسار الدخول: هل هوية جوجل مربوطة بعميل؟ ─────────────────────────────
  const { data: found, error: findError } = await supabase.rpc('find_identity_customer', {
    p_provider: 'google',
    p_provider_user_id: claims.sub,
  })
  if (findError) return json({ error: findError.message }, 500)

  if (found && (found as { customer_id?: string }).customer_id) {
    const customerId = (found as { customer_id: string }).customer_id
    const phone = (found as { phone?: string }).phone ?? ''
    const name = (found as { name?: string }).name ?? ''

    // منع دخول المحظور.
    const { data: blockRow } = await supabase
      .from('customers')
      .select('blocked')
      .eq('id', customerId)
      .maybeSingle()
    if ((blockRow as { blocked?: boolean } | null)?.blocked === true) {
      return json({ error: 'account_blocked', message: 'تم إيقاف حسابك. للاستفسار تواصل مع الدعم.' }, 403)
    }

    // إصدار جلسة لهذا العميل.
    const rawToken = randomToken()
    const tokenHash = await sha256Hex(rawToken)
    const expiresAt = new Date(Date.now() + SESSION_TTL_MS).toISOString()
    const { error: sessErr } = await supabase.rpc('create_customer_session_for_customer', {
      p_customer_id: customerId,
      p_token_hash: tokenHash,
      p_expires_at: expiresAt,
    })
    if (sessErr) return json({ error: sessErr.message }, 500)

    await supabase.rpc('touch_identity_login', {
      p_provider: 'google',
      p_provider_user_id: claims.sub,
    })

    return json({
      mode: 'existing',
      sessionToken: rawToken,
      phone,
      name,
      google: { sub: claims.sub, email: claims.email ?? '', name: claims.name ?? '', emailVerified },
    })
  }

  // ── هوية جديدة: بيانات استلام فقط؛ لا OTP ولا ربط رقم تلقائي ─────────────
  return json({
    mode: 'new',
    google: { sub: claims.sub, email: claims.email ?? '', name: claims.name ?? '', emailVerified },
  })
})
