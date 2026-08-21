// دالة حافة: إرسال إشعار Push لعميل (كل أجهزته) عبر FCM (أندرويد) و APNs (آيفون).
// تُستدعى من الخلفية فقط (لوحة الإدارة/الخادم) بترويسة أمان — ليست للعميل.
// خاملة وآمنة: إن لم تُضبط مفاتيح FCM/APNs تُرجع sent=0 دون خطأ.
//
// المصادقة على الاستدعاء: ترويسة x-push-secret == PUSH_TRIGGER_SECRET،
// أو x-admin-pin == ADMIN_PIN. إن لم يُضبط أي منهما → تُرفض كل الاستدعاءات.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const PUSH_TRIGGER_SECRET = Deno.env.get('PUSH_TRIGGER_SECRET') ?? ''
const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''

// FCM HTTP v1: يحتاج JSON حساب الخدمة من Firebase.
const FCM_SERVICE_ACCOUNT_JSON = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON') ?? ''

// APNs (اختياري، للآيفون): مفتاح p8 + معرّفاته.
const APNS_KEY = Deno.env.get('APNS_KEY') ?? '' // محتوى ملف .p8
const APNS_KEY_ID = Deno.env.get('APNS_KEY_ID') ?? ''
const APNS_TEAM_ID = Deno.env.get('APNS_TEAM_ID') ?? ''
const APNS_BUNDLE_ID = Deno.env.get('APNS_BUNDLE_ID') ?? ''
const APNS_TOPIC = 'com.otlobli.app'

type DeliveryResult = {
  provider: 'apns' | 'fcm'
  ok: boolean
  invalid: boolean
  retryable: boolean
  status: number
  reason: string
  requestId: string
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-push-secret, x-admin-pin',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })
}

// ── أدوات تشفير (JWT) ──────────────────────────────────────────────────────
function b64url(bytes: Uint8Array): string {
  let bin = ''
  bytes.forEach((b) => (bin += String.fromCharCode(b)))
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}
function b64urlStr(s: string): string {
  return b64url(new TextEncoder().encode(s))
}
function pemToDer(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/g, '')
    .replace(/-----END [^-]+-----/g, '')
    .replace(/\s+/g, '')
  const bin = atob(body)
  const der = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) der[i] = bin.charCodeAt(i)
  return der
}

// ── FCM HTTP v1 ────────────────────────────────────────────────────────────
let fcmTokenCache: { token: string; exp: number } | null = null

async function getFcmAccessToken(): Promise<{ token: string; projectId: string } | null> {
  if (!FCM_SERVICE_ACCOUNT_JSON) return null
  let sa: { client_email: string; private_key: string; project_id: string }
  try {
    sa = JSON.parse(FCM_SERVICE_ACCOUNT_JSON)
  } catch {
    console.error('FCM service account JSON invalid')
    return null
  }
  const now = Math.floor(Date.now() / 1000)
  if (fcmTokenCache && fcmTokenCache.exp > now + 60) {
    return { token: fcmTokenCache.token, projectId: sa.project_id }
  }

  const header = { alg: 'RS256', typ: 'JWT' }
  const claim = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }
  const unsigned = `${b64urlStr(JSON.stringify(header))}.${b64urlStr(JSON.stringify(claim))}`
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const sig = new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned)))
  const jwt = `${unsigned}.${b64url(sig)}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  if (!res.ok) {
    console.error('FCM token exchange failed', res.status, await res.text())
    return null
  }
  const data = (await res.json()) as { access_token: string; expires_in: number }
  fcmTokenCache = { token: data.access_token, exp: now + (data.expires_in ?? 3600) }
  return { token: data.access_token, projectId: sa.project_id }
}

async function sendFcm(
  token: string,
  title: string,
  bodyText: string,
  data: Record<string, string>,
): Promise<DeliveryResult> {
  const auth = await getFcmAccessToken()
  if (!auth) return { provider: 'fcm', ok: false, invalid: false, retryable: false, status: 0, reason: 'not_configured', requestId: '' }
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${auth.projectId}/messages:send`, {
    method: 'POST',
    headers: { authorization: `Bearer ${auth.token}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body: bodyText },
        data,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channel_id: 'otlobli_general',
          },
        },
      },
    }),
  })
  if (res.ok) return { provider: 'fcm', ok: true, invalid: false, retryable: false, status: res.status, reason: '', requestId: '' }
  const errText = await res.text()
  // رموز خطأ FCM التي تعني أن الرمز لم يعد صالحاً.
  const invalid = /UNREGISTERED|INVALID_ARGUMENT|NOT_FOUND/i.test(errText)
  console.error('FCM send failed', { status: res.status, reason: invalid ? 'invalid_token' : 'provider_error' })
  return {
    provider: 'fcm', ok: false, invalid, retryable: res.status === 429 || res.status >= 500,
    status: res.status, reason: invalid ? 'invalid_token' : 'provider_error', requestId: '',
  }
}

// ── APNs (token-based, p8) ─────────────────────────────────────────────────
let apnsJwtCache: { token: string; iat: number } | null = null

async function getApnsJwt(): Promise<string | null> {
  if (!APNS_KEY || !APNS_KEY_ID || !APNS_TEAM_ID) return null
  const now = Math.floor(Date.now() / 1000)
  if (apnsJwtCache && now - apnsJwtCache.iat < 1500) return apnsJwtCache.token
  const header = { alg: 'ES256', kid: APNS_KEY_ID }
  const claim = { iss: APNS_TEAM_ID, iat: now }
  const unsigned = `${b64urlStr(JSON.stringify(header))}.${b64urlStr(JSON.stringify(claim))}`
  try {
    const key = await crypto.subtle.importKey(
      'pkcs8',
      pemToDer(APNS_KEY),
      { name: 'ECDSA', namedCurve: 'P-256' },
      false,
      ['sign'],
    )
    const sig = new Uint8Array(
      await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, new TextEncoder().encode(unsigned)),
    )
    const jwt = `${unsigned}.${b64url(sig)}`
    apnsJwtCache = { token: jwt, iat: now }
    return jwt
  } catch (e) {
    console.error('APNs JWT sign failed', (e as Error).message)
    return null
  }
}

async function sendApns(
  token: string,
  title: string,
  bodyText: string,
  data: Record<string, string>,
  production: boolean,
): Promise<DeliveryResult> {
  const jwt = await getApnsJwt()
  if (!jwt || APNS_BUNDLE_ID !== APNS_TOPIC) {
    return { provider: 'apns', ok: false, invalid: false, retryable: false, status: 0, reason: 'not_configured', requestId: '' }
  }
  const host = production ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com'
  const expiration = String(Math.floor(Date.now() / 1000) + 3600)
  const retryStatuses = new Set([429, 500, 503])
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const res = await fetch(`${host}/3/device/${token}`, {
        method: 'POST',
        headers: {
          authorization: `bearer ${jwt}`,
          'apns-topic': APNS_TOPIC,
          'apns-push-type': 'alert',
          'apns-priority': '10',
          'apns-expiration': expiration,
        },
        body: JSON.stringify({
          aps: { alert: { title, body: bodyText }, sound: 'default', badge: 1 },
          ...data,
        }),
      })
      const requestId = res.headers.get('apns-id') ?? ''
      if (res.status === 200) {
        return { provider: 'apns', ok: true, invalid: false, retryable: false, status: 200, reason: '', requestId }
      }
      let reason = 'provider_error'
      try {
        const payload = await res.json() as { reason?: unknown }
        if (typeof payload.reason === 'string' && /^[A-Za-z0-9_-]{1,64}$/.test(payload.reason)) reason = payload.reason
      } catch {
        // APNs normally returns JSON; keep a sanitized generic reason otherwise.
      }
      const invalid = res.status === 410 ||
        (res.status === 400 && ['BadDeviceToken', 'DeviceTokenNotForTopic', 'Unregistered'].includes(reason))
      const retryable = retryStatuses.has(res.status)
      if (retryable && attempt < 2) {
        const retryAfter = Number(res.headers.get('retry-after') ?? '')
        const waitMs = Number.isFinite(retryAfter) && retryAfter > 0
          ? Math.min(2000, retryAfter * 1000)
          : [250, 750][attempt]
        await new Promise((resolve) => setTimeout(resolve, waitMs))
        continue
      }
      console.error('APNs send failed', { status: res.status, reason, requestId, attempt: attempt + 1 })
      return { provider: 'apns', ok: false, invalid, retryable, status: res.status, reason, requestId }
    } catch {
      if (attempt < 2) {
        await new Promise((resolve) => setTimeout(resolve, [250, 750][attempt]))
        continue
      }
      return { provider: 'apns', ok: false, invalid: false, retryable: true, status: 0, reason: 'network_error', requestId: '' }
    }
  }
  return { provider: 'apns', ok: false, invalid: false, retryable: true, status: 0, reason: 'retry_exhausted', requestId: '' }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405, headers: corsHeaders })

  // المصادقة على الاستدعاء (خلفي فقط).
  const secret = (req.headers.get('x-push-secret') ?? '').trim()
  const pin = (req.headers.get('x-admin-pin') ?? '').trim()
  const secretOk = PUSH_TRIGGER_SECRET !== '' && secret === PUSH_TRIGGER_SECRET
  const pinOk = ADMIN_PIN !== '' && pin === ADMIN_PIN
  if (!secretOk && !pinOk) return json({ error: 'unauthorized' }, 401)

  let body: {
    customerId?: string
    phone?: string
    installationId?: string
    broadcast?: boolean
    dryRun?: boolean
    title?: string
    body?: string
    data?: Record<string, string>
  }
  try {
    body = (await req.json()) as typeof body
  } catch {
    return json({ error: 'invalid_body' }, 400)
  }

  const title = (body.title ?? '').trim()
  const bodyText = (body.body ?? '').trim()
  if (!title && !bodyText) return json({ error: 'empty_message' }, 400)
  const rawData = body.data ?? {}
  const version = String(rawData.version ?? '1')
  const type = String(rawData.type ?? '').trim()
  const route = String(rawData.route ?? '').trim()
  const entityId = String(rawData.entityId ?? '').trim()
  const allowedTypes = new Set(['order_update', 'payment_update', 'product_issue', 'wallet_update', 'group_order_update', 'system'])
  const allowedRoutes = new Set(['', 'notifications', 'orders', 'orders/details', 'wallet', 'payment-methods'])
  if (version !== '1' || !allowedTypes.has(type) || !allowedRoutes.has(route) || entityId.length > 128) {
    return json({ error: 'invalid_payload' }, 400)
  }
  if (route === 'orders/details' && !entityId) return json({ error: 'missing_entity_id' }, 400)
  const data: Record<string, string> = { version, type, route }
  if (entityId) data.entityId = entityId

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // جلب الأجهزة المفعّلة: لعميل محدّد، أو لرقم، أو للكل (broadcast).
  let query = supabase
    .from('device_tokens')
    .select('token, platform, environment')
    .eq('enabled', true)
    .eq('notifications_enabled', true)
    .is('invalidated_at', null)
  if (body.customerId) query = query.eq('customer_id', body.customerId)
  else if (body.phone) query = query.eq('phone', body.phone.replace(/[^0-9]/g, ''))
  else if (body.installationId) query = query.eq('installation_id', body.installationId)
  else if (body.broadcast === true) query = query.limit(5000) // إرسال جماعي لكل الأجهزة
  else return json({ error: 'missing_target' }, 400)

  const { data: rows, error } = await query
  if (error) return json({ error: error.message }, 500)
  const devices = (rows ?? []) as { token: string; platform: string; environment?: string }[]
  if (devices.length === 0) return json({ sent: 0, reason: 'no_devices' })
  if (body.dryRun === true) return json({ dryRun: true, eligible: devices.length, payload: data })

  // إن لم تُضبط أي بوابة إرسال، اخرج بهدوء (خامل وآمن).
  const fcmReady = !!FCM_SERVICE_ACCOUNT_JSON
  const apnsReady = !!(APNS_KEY && APNS_KEY_ID && APNS_TEAM_ID && APNS_BUNDLE_ID === APNS_TOPIC)
  if (!fcmReady && !apnsReady) return json({ sent: 0, reason: 'not_configured' })

  let sent = 0
  const toDisable: string[] = []
  const delivery = {
    apns: { sent: 0, invalid: 0, retryable: 0, failed: 0 },
    fcm: { sent: 0, invalid: 0, retryable: 0, failed: 0 },
  }
  for (const d of devices) {
    let result: DeliveryResult = {
      provider: d.platform === 'ios' ? 'apns' : 'fcm', ok: false, invalid: false,
      retryable: false, status: 0, reason: 'provider_not_configured', requestId: '',
    }
    if (d.platform === 'ios' && apnsReady) {
      result = await sendApns(d.token, title, bodyText, data, d.environment !== 'development')
    }
    else if (fcmReady) result = await sendFcm(d.token, title, bodyText, data)
    const summary = delivery[result.provider]
    if (result.ok) { sent++; summary.sent++ }
    else if (result.invalid) { toDisable.push(d.token); summary.invalid++ }
    else if (result.retryable) summary.retryable++
    else summary.failed++
  }

  // تعطيل الرموز غير الصالحة.
  for (const t of toDisable) {
    await supabase.rpc('disable_device_token', { p_token: t })
  }

  return json({ sent, total: devices.length, disabled: toDisable.length, delivery })
})
