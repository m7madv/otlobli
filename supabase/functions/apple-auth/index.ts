import { createClient, type SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5.9.6'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const DEFAULT_APPLE_CLIENT_ID = 'com.otlobli.app'
const ALLOWED_AUDS = Array.from(new Set(
  (Deno.env.get('APPLE_CLIENT_IDS') ?? Deno.env.get('APPLE_CLIENT_ID') ?? DEFAULT_APPLE_CLIENT_ID)
    .split(',').map((value) => value.trim()).filter(Boolean),
))
const ALLOWED_AUD_SET = new Set(ALLOWED_AUDS)
const APPLE_JWKS = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'))
const APPLE_SIGN_IN_KEY = Deno.env.get('APPLE_SIGN_IN_KEY') ?? ''
const APPLE_SIGN_IN_KEY_ID = Deno.env.get('APPLE_SIGN_IN_KEY_ID') ?? ''
const APPLE_TEAM_ID = Deno.env.get('APPLE_TEAM_ID') ?? ''
const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000
const PENDING_AUTHORIZATION_TTL_MS = 15 * 60 * 1000

function readRedirectUris(): { valid: boolean; values: Record<string, string> } {
  const raw = (Deno.env.get('APPLE_REDIRECT_URIS_JSON') ?? '').trim()
  if (!raw) return { valid: true, values: {} }
  try {
    const parsed = JSON.parse(raw) as unknown
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return { valid: false, values: {} }
    const values: Record<string, string> = {}
    for (const [clientId, rawUri] of Object.entries(parsed)) {
      if (!ALLOWED_AUD_SET.has(clientId) || typeof rawUri !== 'string') return { valid: false, values: {} }
      const uri = rawUri.trim()
      const url = new URL(uri)
      if (url.protocol !== 'https:' || url.username || url.password || url.hash || uri.length > 2048) {
        return { valid: false, values: {} }
      }
      values[clientId] = uri
    }
    return { valid: true, values }
  } catch {
    return { valid: false, values: {} }
  }
}

const APPLE_REDIRECT_URIS = readRedirectUris()

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

function pemToDer(pem: string): ArrayBuffer {
  const content = pem.replace(/-----BEGIN [^-]+-----/g, '').replace(/-----END [^-]+-----/g, '').replace(/\s+/g, '')
  const binary = atob(content)
  const bytes = new Uint8Array(binary.length)
  for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index)
  return bytes.buffer
}

async function appleClientSecret(clientId: string): Promise<string | null> {
  if (!APPLE_SIGN_IN_KEY || !APPLE_SIGN_IN_KEY_ID || !APPLE_TEAM_ID || !ALLOWED_AUD_SET.has(clientId)) return null
  try {
    const now = Math.floor(Date.now() / 1000)
    const header = { alg: 'ES256', kid: APPLE_SIGN_IN_KEY_ID }
    const claims = { iss: APPLE_TEAM_ID, iat: now, exp: now + 300, aud: 'https://appleid.apple.com', sub: clientId }
    const unsigned = `${base64UrlText(JSON.stringify(header))}.${base64UrlText(JSON.stringify(claims))}`
    const key = await crypto.subtle.importKey('pkcs8', pemToDer(APPLE_SIGN_IN_KEY), { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign'])
    const signature = new Uint8Array(await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, new TextEncoder().encode(unsigned)))
    return `${unsigned}.${base64Url(signature)}`
  } catch {
    return null
  }
}

type AppleTokenExchange = { idToken: string; refreshToken: string }

async function exchangeAuthorizationCode(
  code: string,
  clientId: string,
  redirectUri?: string,
): Promise<AppleTokenExchange | null> {
  if (!code || code.length > 4096) return null
  try {
    const clientSecret = await appleClientSecret(clientId)
    if (!clientSecret) return null
    const parameters: Record<string, string> = {
      client_id: clientId,
      client_secret: clientSecret,
      code,
      grant_type: 'authorization_code',
    }
    if (redirectUri) parameters.redirect_uri = redirectUri
    const response = await fetch('https://appleid.apple.com/auth/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams(parameters),
      signal: AbortSignal.timeout(10000),
    })
    if (!response.ok) return null
    const payload = await response.json() as { id_token?: string; refresh_token?: string }
    const idToken = payload.id_token?.trim() ?? ''
    const refreshToken = payload.refresh_token?.trim() ?? ''
    return idToken && refreshToken ? { idToken, refreshToken } : null
  } catch {
    return null
  }
}

async function revokeAppleRefreshToken(refreshToken: string, clientId: string): Promise<boolean> {
  if (!refreshToken || refreshToken.length > 4096 || !ALLOWED_AUD_SET.has(clientId)) return false
  try {
    const clientSecret = await appleClientSecret(clientId)
    if (!clientSecret) return false
    const response = await fetch('https://appleid.apple.com/auth/revoke', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        token: refreshToken,
        token_type_hint: 'refresh_token',
      }),
      signal: AbortSignal.timeout(10000),
    })
    if (response.ok) return true
    if (response.status === 400) {
      const payload = await response.json().catch(() => ({})) as { error?: string }
      return payload.error === 'invalid_grant' || payload.error === 'invalid_token'
    }
    return false
  } catch {
    return false
  }
}

async function cleanupExpiredPendingAuthorizations(supabase: SupabaseClient): Promise<void> {
  const now = new Date().toISOString()
  const { data } = await supabase.from('apple_authorizations')
    .select('provider_user_id,client_id,refresh_token,pending_expires_at,updated_at')
    .is('customer_id', null)
    .lt('pending_expires_at', now)
    .limit(10)
  await Promise.all((data ?? []).map(async (authorization) => {
    const providerUserId = String(authorization.provider_user_id ?? '')
    const clientId = String(authorization.client_id ?? '')
    const refreshToken = String(authorization.refresh_token ?? '')
    const pendingExpiresAt = String(authorization.pending_expires_at ?? '')
    const previousUpdatedAt = String(authorization.updated_at ?? '')
    if (!providerUserId || !clientId || !refreshToken || !pendingExpiresAt || !previousUpdatedAt) return

    // Claim the exact expired row before contacting Apple. A concurrent sign-in
    // or account link changes updated_at/token/expiry, so this stale cleanup can
    // neither revoke nor delete the replacement authorization.
    const claimedAt = new Date().toISOString()
    const { data: claimedAuthorization } = await supabase.from('apple_authorizations')
      .update({ updated_at: claimedAt })
      .eq('provider_user_id', providerUserId)
      .eq('client_id', clientId)
      .eq('pending_expires_at', pendingExpiresAt)
      .eq('updated_at', previousUpdatedAt)
      .is('customer_id', null)
      .lt('pending_expires_at', now)
      .select('provider_user_id')
      .maybeSingle()
    if (!claimedAuthorization) return

    const revoked = await revokeAppleRefreshToken(refreshToken, clientId)
    if (revoked) {
      await supabase.from('apple_authorizations').delete()
        .eq('provider_user_id', providerUserId)
        .eq('client_id', clientId)
        .eq('pending_expires_at', pendingExpiresAt)
        .eq('updated_at', claimedAt)
        .is('customer_id', null)
    }
  }))
}

type AppleClaims = {
  sub: string
  aud?: string | string[]
  email?: string
  email_verified?: string | boolean
  nonce?: string
  exp?: number
}

type VerifiedAppleToken = { claims: AppleClaims; clientId: string }

async function verifyAppleIdToken(
  idToken: string,
  rawNonce: string,
  expectedClientId?: string,
): Promise<VerifiedAppleToken | null> {
  if (!idToken || !rawNonce || idToken.length > 20000 || rawNonce.length > 256) return null
  if (expectedClientId && !ALLOWED_AUD_SET.has(expectedClientId)) return null
  try {
    const nonce = await sha256Hex(rawNonce)
    const result = await jwtVerify(idToken, APPLE_JWKS, {
      issuer: 'https://appleid.apple.com',
      audience: expectedClientId ?? ALLOWED_AUDS,
      clockTolerance: 5,
    })
    const claims = result.payload as unknown as AppleClaims
    const clientId = typeof claims.aud === 'string'
      ? claims.aud
      : Array.isArray(claims.aud) && claims.aud.length === 1 ? claims.aud[0] : ''
    if (!ALLOWED_AUD_SET.has(clientId) || (expectedClientId && clientId !== expectedClientId)) return null
    if (!claims.sub || claims.nonce !== nonce || !claims.exp || claims.exp * 1000 <= Date.now()) return null
    return { claims, clientId }
  } catch {
    return null
  }
}

function redirectUriForExchange(
  clientId: string,
  requestedRedirectUri: string,
  requireConfiguredRedirect: boolean,
): { valid: boolean; value?: string } {
  if (requestedRedirectUri.length > 2048) return { valid: false }
  const configuredRedirectUri = APPLE_REDIRECT_URIS.values[clientId]
  if (!configuredRedirectUri) {
    return !requireConfiguredRedirect && !requestedRedirectUri ? { valid: true } : { valid: false }
  }
  return requestedRedirectUri === configuredRedirectUri
    ? { valid: true, value: configuredRedirectUri }
    : { valid: false }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405, headers: corsHeaders })
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY || ALLOWED_AUDS.length === 0 ||
      !APPLE_SIGN_IN_KEY || !APPLE_SIGN_IN_KEY_ID || !APPLE_TEAM_ID || !APPLE_REDIRECT_URIS.valid) {
    return json({ error: 'apple_auth_not_configured' }, 503)
  }

  let body: {
    idToken?: string
    rawNonce?: string
    authorizationCode?: string
    clientId?: string
    redirectUrl?: string
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
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // Apple client IDs and HTTPS return URLs are public OAuth configuration.
  // This narrow endpoint lets release CI prove the exact embedded client is
  // accepted without exposing the allowlist, signing key, or any token.
  if (body.action === 'configuration-check') {
    const clientId = (body.clientId ?? '').trim()
    const redirectUrl = (body.redirectUrl ?? '').trim()
    if (!clientId || clientId.length > 255) return json({ error: 'invalid_apple_client' }, 400)
    const redirect = redirectUriForExchange(clientId, redirectUrl, false)
    const signingReady = ALLOWED_AUD_SET.has(clientId) && redirect.valid
      ? !!(await appleClientSecret(clientId))
      : false
    const { data: schemaStatus, error: schemaError } = await supabase.rpc('auth_schema_readiness')
    const schema = (schemaStatus ?? {}) as { ready?: boolean; version?: string }
    return json({
      configured: signingReady && !schemaError && schema.ready === true && schema.version === 'auth-v86.212-1',
    })
  }

  let idToken = (body.idToken ?? '').trim()
  const rawNonce = (body.rawNonce ?? '').trim()
  const requestedClientId = (body.clientId ?? '').trim()
  const requestedRedirectUri = (body.redirectUrl ?? '').trim()
  const authorizationCode = (body.authorizationCode ?? '').trim()
  if (requestedClientId.length > 255) return json({ error: 'invalid_apple_client' }, 401)
  if (!rawNonce || rawNonce.length > 256) return json({ error: 'invalid_apple_token' }, 401)
  if (body.action !== 'register' && body.action !== 'cancel-registration' && !authorizationCode) {
    return json({ error: 'missing_authorization_code' }, 400)
  }

  let verifiedToken: VerifiedAppleToken | null = null
  let exchangedRefreshToken = ''
  if (idToken) {
    verifiedToken = await verifyAppleIdToken(idToken, rawNonce)
    if (!verifiedToken) return json({ error: 'invalid_apple_token' }, 401)
    if (requestedClientId && requestedClientId !== verifiedToken.clientId) {
      return json({ error: 'invalid_apple_client' }, 401)
    }
    if (authorizationCode) {
      const redirectUri = redirectUriForExchange(verifiedToken.clientId, requestedRedirectUri, false)
      if (!redirectUri.valid) return json({ error: 'invalid_apple_redirect' }, 400)
      const exchange = await exchangeAuthorizationCode(authorizationCode, verifiedToken.clientId, redirectUri.value)
      if (!exchange) return json({ error: 'apple_token_exchange_failed' }, 401)
      const exchangedToken = await verifyAppleIdToken(exchange.idToken, rawNonce, verifiedToken.clientId)
      if (!exchangedToken || exchangedToken.claims.sub !== verifiedToken.claims.sub) {
        return json({ error: 'apple_token_exchange_failed' }, 401)
      }
      verifiedToken = exchangedToken
      idToken = exchange.idToken
      exchangedRefreshToken = exchange.refreshToken
    } else if (requestedRedirectUri) {
      const redirectUri = redirectUriForExchange(verifiedToken.clientId, requestedRedirectUri, false)
      if (!redirectUri.valid) return json({ error: 'invalid_apple_redirect' }, 400)
    }
  } else {
    if (!authorizationCode || !requestedClientId || !ALLOWED_AUD_SET.has(requestedClientId)) {
      return json({ error: authorizationCode ? 'invalid_apple_client' : 'invalid_apple_token' }, 401)
    }
    const redirectUri = redirectUriForExchange(requestedClientId, requestedRedirectUri, true)
    if (!redirectUri.valid) return json({ error: 'invalid_apple_redirect' }, 400)
    const exchange = await exchangeAuthorizationCode(authorizationCode, requestedClientId, redirectUri.value)
    if (!exchange) return json({ error: 'apple_token_exchange_failed' }, 401)
    verifiedToken = await verifyAppleIdToken(exchange.idToken, rawNonce, requestedClientId)
    if (!verifiedToken) return json({ error: 'apple_token_exchange_failed' }, 401)
    idToken = exchange.idToken
    exchangedRefreshToken = exchange.refreshToken
  }

  if (!verifiedToken) return json({ error: 'invalid_apple_token' }, 401)
  const claims = verifiedToken.claims
  const appleClientId = verifiedToken.clientId
  const emailVerified = claims.email_verified === true || claims.email_verified === 'true'
  const displayName = (body.name ?? '').trim()
  await cleanupExpiredPendingAuthorizations(supabase).catch(() => undefined)

  if (body.action === 'cancel-registration') {
    const { data: pendingAuthorization } = await supabase.from('apple_authorizations')
      .select('refresh_token,pending_expires_at,updated_at')
      .eq('provider_user_id', claims.sub)
      .eq('client_id', appleClientId)
      .is('customer_id', null)
      .maybeSingle()
    if (pendingAuthorization?.refresh_token) {
      const refreshToken = String(pendingAuthorization.refresh_token)
      const pendingExpiresAt = String(pendingAuthorization.pending_expires_at ?? '')
      const previousUpdatedAt = String(pendingAuthorization.updated_at ?? '')
      if (!pendingExpiresAt || !previousUpdatedAt) {
        return json({ error: 'apple_authorization_cleanup_failed' }, 500)
      }
      const claimedAt = new Date().toISOString()
      const { data: claimedAuthorization, error: claimError } = await supabase.from('apple_authorizations')
        .update({ updated_at: claimedAt })
        .eq('provider_user_id', claims.sub)
        .eq('client_id', appleClientId)
        .eq('pending_expires_at', pendingExpiresAt)
        .eq('updated_at', previousUpdatedAt)
        .is('customer_id', null)
        .select('provider_user_id')
        .maybeSingle()
      if (claimError) return json({ error: 'apple_authorization_cleanup_failed' }, 500)
      // A newer sign-in replaced this pending row; do not cancel that newer flow.
      if (!claimedAuthorization) return json({ ok: true })

      const revoked = await revokeAppleRefreshToken(refreshToken, appleClientId)
      if (!revoked) return json({ error: 'apple_revocation_failed' }, 503)

      const { error: deletePendingError } = await supabase.from('apple_authorizations').delete()
        .eq('provider_user_id', claims.sub)
        .eq('client_id', appleClientId)
        .eq('pending_expires_at', pendingExpiresAt)
        .eq('updated_at', claimedAt)
        .is('customer_id', null)
      if (deletePendingError) return json({ error: 'apple_authorization_cleanup_failed' }, 500)
      return json({ ok: true })
    }
    return json({ ok: true })
  }

  const saveAuthorization = async (customerId: string | null) => {
    const pendingExpiresAt = customerId
      ? null
      : new Date(Date.now() + PENDING_AUTHORIZATION_TTL_MS).toISOString()
    if (exchangedRefreshToken) {
      return await supabase.from('apple_authorizations').upsert({
        provider_user_id: claims.sub,
        customer_id: customerId,
        refresh_token: exchangedRefreshToken,
        client_id: appleClientId,
        pending_expires_at: pendingExpiresAt,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'provider_user_id,client_id' })
    }
    return await supabase.from('apple_authorizations')
      .update({ customer_id: customerId, pending_expires_at: pendingExpiresAt, updated_at: new Date().toISOString() })
      .eq('provider_user_id', claims.sub)
      .eq('client_id', appleClientId)
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
      .select('provider_user_id')
      .eq('provider_user_id', claims.sub)
      .eq('client_id', appleClientId)
      .is('customer_id', null)
      .gt('pending_expires_at', new Date().toISOString())
      .maybeSingle()
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
  return json({
    mode: 'new',
    idToken,
    clientId: appleClientId,
    apple: { sub: claims.sub, email: claims.email ?? '', name: displayName, emailVerified },
  })
})
