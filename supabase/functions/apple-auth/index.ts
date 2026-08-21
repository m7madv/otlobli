import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5.9.6'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const ALLOWED_AUDS = (Deno.env.get('APPLE_CLIENT_IDS') ?? 'com.otlobli.app')
  .split(',').map((value) => value.trim()).filter(Boolean)
const APPLE_JWKS = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'))
const APPLE_SIGN_IN_KEY = Deno.env.get('APPLE_SIGN_IN_KEY') ?? ''
const APPLE_SIGN_IN_KEY_ID = Deno.env.get('APPLE_SIGN_IN_KEY_ID') ?? ''
const APPLE_TEAM_ID = Deno.env.get('APPLE_TEAM_ID') ?? ''
const APPLE_CLIENT_ID = Deno.env.get('APPLE_CLIENT_ID') ?? 'com.otlobli.app'
const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'content-type': 'application/json' } })
}

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(input))
  return Array.from(new Uint8Array(digest)).map((byte) => byte.toString(16).padStart(2, '0')).join('')
}

function randomToken(): string {
  const bytes = new Uint8Array(32)
  crypto.getRandomValues(bytes)
  let binary = ''
  bytes.forEach((byte) => { binary += String.fromCharCode(byte) })
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function base64Url(bytes: Uint8Array): string {
  let binary = ''
  bytes.forEach((byte) => { binary += String.fromCharCode(byte) })
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function base64UrlText(value: string): string {
  return base64Url(new TextEncoder().encode(value))
}

function pemToDer(pem: string): Uint8Array {
  const content = pem.replace(/-----BEGIN [^-]+-----/g, '').replace(/-----END [^-]+-----/g, '').replace(/\s+/g, '')
  const binary = atob(content)
  return Uint8Array.from(binary, (char) => char.charCodeAt(0))
}

async function appleClientSecret(): Promise<string | null> {
  if (!APPLE_SIGN_IN_KEY || !APPLE_SIGN_IN_KEY_ID || !APPLE_TEAM_ID || !APPLE_CLIENT_ID) return null
  const now = Math.floor(Date.now() / 1000)
  const header = { alg: 'ES256', kid: APPLE_SIGN_IN_KEY_ID }
  const claims = { iss: APPLE_TEAM_ID, iat: now, exp: now + 300, aud: 'https://appleid.apple.com', sub: APPLE_CLIENT_ID }
  const unsigned = `${base64UrlText(JSON.stringify(header))}.${base64UrlText(JSON.stringify(claims))}`
  const key = await crypto.subtle.importKey('pkcs8', pemToDer(APPLE_SIGN_IN_KEY), { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign'])
  const signature = new Uint8Array(await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, new TextEncoder().encode(unsigned)))
  return `${unsigned}.${base64Url(signature)}`
}

async function exchangeAuthorizationCode(code: string): Promise<string | null> {
  if (!code || code.length > 4096) return null
  try {
    const clientSecret = await appleClientSecret()
    if (!clientSecret) return null
    const response = await fetch('https://appleid.apple.com/auth/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: APPLE_CLIENT_ID,
        client_secret: clientSecret,
        code,
        grant_type: 'authorization_code',
      }),
      signal: AbortSignal.timeout(10000),
    })
    if (!response.ok) return null
    const payload = await response.json() as { refresh_token?: string }
    return payload.refresh_token?.trim() || null
  } catch {
    return null
  }
}

type AppleClaims = {
  sub: string
  email?: string
  email_verified?: string | boolean
  nonce?: string
  exp?: number
}

async function verifyAppleIdToken(idToken: string, rawNonce: string): Promise<AppleClaims | null> {
  if (!idToken || !rawNonce || idToken.length > 20000 || rawNonce.length > 256) return null
  try {
    const nonce = await sha256Hex(rawNonce)
    const result = await jwtVerify(idToken, APPLE_JWKS, {
      issuer: 'https://appleid.apple.com',
      audience: ALLOWED_AUDS,
      clockTolerance: 5,
    })
    const claims = result.payload as unknown as AppleClaims
    if (!claims.sub || claims.nonce !== nonce || !claims.exp || claims.exp * 1000 <= Date.now()) return null
    return claims
  } catch {
    return null
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405, headers: corsHeaders })
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY || ALLOWED_AUDS.length === 0 ||
      !APPLE_SIGN_IN_KEY || !APPLE_SIGN_IN_KEY_ID || !APPLE_TEAM_ID) {
    return json({ error: 'apple_auth_not_configured' }, 503)
  }

  let body: {
    idToken?: string
    rawNonce?: string
    authorizationCode?: string
    action?: string
    sessionToken?: string
    phone?: string
    name?: string
    governorate?: string
    qadmousBranch?: string
    city?: string
    details?: string
  }
  try { body = await req.json() as typeof body }
  catch { return json({ error: 'invalid_body' }, 400) }

  const idToken = (body.idToken ?? '').trim()
  const claims = await verifyAppleIdToken(idToken, (body.rawNonce ?? '').trim())
  if (!claims) return json({ error: 'invalid_apple_token' }, 401)
  const emailVerified = claims.email_verified === true || claims.email_verified === 'true'
  const displayName = (body.name ?? '').trim()
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
  const authorizationCode = (body.authorizationCode ?? '').trim()
  if (body.action !== 'register' && !authorizationCode) return json({ error: 'missing_authorization_code' }, 400)
  const exchangedRefreshToken = authorizationCode ? await exchangeAuthorizationCode(authorizationCode) : null
  if (authorizationCode && !exchangedRefreshToken) return json({ error: 'apple_token_exchange_failed' }, 401)

  const saveAuthorization = async (customerId: string | null) => {
    if (exchangedRefreshToken) {
      return await supabase.from('apple_authorizations').upsert({
        provider_user_id: claims.sub,
        customer_id: customerId,
        refresh_token: exchangedRefreshToken,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'provider_user_id' })
    }
    return await supabase.from('apple_authorizations')
      .update({ customer_id: customerId, updated_at: new Date().toISOString() })
      .eq('provider_user_id', claims.sub)
  }

  if (body.action === 'link') {
    if (!(body.sessionToken ?? '').trim()) return json({ error: 'missing_session' }, 401)
    const { data, error } = await supabase.rpc('link_customer_identity', {
      p_session_token: body.sessionToken,
      p_provider: 'apple',
      p_provider_user_id: claims.sub,
      p_email: claims.email ?? null,
      p_email_verified: emailVerified,
      p_display_name: displayName || null,
    })
    if (error) {
      const message = /another account/i.test(error.message) ? 'حساب Apple هذا مرتبط بحساب آخر.' : error.message
      return json({ error: 'link_failed', message }, 409)
    }
    const linkedCustomer = (data ?? {}) as { customer_id?: string }
    const savedAuthorization = await saveAuthorization(linkedCustomer.customer_id ?? null)
    if (savedAuthorization.error) return json({ error: 'apple_authorization_store_failed' }, 500)
    return json({ ok: true, linked: true })
  }

  if (body.action === 'register') {
    const { data: pendingAuthorization } = await supabase.from('apple_authorizations')
      .select('provider_user_id').eq('provider_user_id', claims.sub).maybeSingle()
    if (!pendingAuthorization) {
      return json({ error: 'apple_authorization_expired', message: 'أعد تسجيل الدخول عبر Apple.' }, 401)
    }
    const rawSession = randomToken()
    const tokenHash = await sha256Hex(rawSession)
    const expiresAt = new Date(Date.now() + SESSION_TTL_MS).toISOString()
    const { data, error } = await supabase.rpc('register_external_customer', {
      p_provider: 'apple',
      p_provider_user_id: claims.sub,
      p_email: claims.email ?? null,
      p_email_verified: emailVerified,
      p_display_name: displayName || null,
      p_phone: body.phone ?? '',
      p_name: displayName,
      p_governorate: body.governorate ?? 'دمشق',
      p_qadmous_branch: body.qadmousBranch ?? '',
      p_city: body.city ?? '',
      p_details: body.details ?? '',
      p_token_hash: tokenHash,
      p_expires_at: expiresAt,
    })
    if (error) {
      if (/delivery phone already belongs/i.test(error.message)) {
        return json({ error: 'phone_account_exists', message: 'هذا الرقم مرتبط بحساب موجود. ادخل أولاً ثم اربط Apple من حسابك.' }, 409)
      }
      if (/verified email already belongs/i.test(error.message)) {
        return json({ error: 'verified_email_account_exists', message: 'هذا البريد مرتبط بحساب موجود. ادخل بطريقتك الحالية ثم اربط Apple.' }, 409)
      }
      return json({ error: 'registration_failed', message: error.message }, 400)
    }
    const registered = (data ?? {}) as { customerId?: string; phone?: string; name?: string }
    const savedAuthorization = await saveAuthorization(registered.customerId ?? null)
    if (savedAuthorization.error) return json({ error: 'apple_authorization_store_failed' }, 500)
    return json({
      mode: 'registered', sessionToken: rawSession,
      phone: registered.phone ?? body.phone ?? '', name: registered.name ?? displayName,
      apple: { sub: claims.sub, email: claims.email ?? '', name: displayName, emailVerified },
    })
  }

  const { data: found, error: findError } = await supabase.rpc('find_identity_customer', {
    p_provider: 'apple', p_provider_user_id: claims.sub,
  })
  if (findError) return json({ error: 'identity_lookup_failed' }, 500)
  if (found && (found as { customer_id?: string }).customer_id) {
    const customerId = (found as { customer_id: string }).customer_id
    const { data: blockRow } = await supabase.from('customers').select('blocked').eq('id', customerId).maybeSingle()
    if ((blockRow as { blocked?: boolean } | null)?.blocked === true) {
      return json({ error: 'account_blocked', message: 'تم إيقاف حسابك. للاستفسار تواصل مع الدعم.' }, 403)
    }
    const rawSession = randomToken()
    const tokenHash = await sha256Hex(rawSession)
    const expiresAt = new Date(Date.now() + SESSION_TTL_MS).toISOString()
    const { error: sessionError } = await supabase.rpc('create_customer_session_for_customer', {
      p_customer_id: customerId, p_token_hash: tokenHash, p_expires_at: expiresAt,
    })
    if (sessionError) return json({ error: 'session_creation_failed' }, 500)
    await supabase.rpc('touch_identity_login', { p_provider: 'apple', p_provider_user_id: claims.sub })
    const savedAuthorization = await saveAuthorization(customerId)
    if (savedAuthorization.error) return json({ error: 'apple_authorization_store_failed' }, 500)
    return json({
      mode: 'existing', sessionToken: rawSession,
      phone: (found as { phone?: string }).phone ?? '', name: (found as { name?: string }).name ?? '',
      apple: { sub: claims.sub, email: claims.email ?? '', name: displayName, emailVerified },
    })
  }
  const savedAuthorization = await saveAuthorization(null)
  if (savedAuthorization.error) return json({ error: 'apple_authorization_store_failed' }, 500)
  return json({ mode: 'new', apple: { sub: claims.sub, email: claims.email ?? '', name: displayName, emailVerified } })
})
