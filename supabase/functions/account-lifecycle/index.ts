import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const APPLE_SIGN_IN_KEY = Deno.env.get('APPLE_SIGN_IN_KEY') ?? ''
const APPLE_SIGN_IN_KEY_ID = Deno.env.get('APPLE_SIGN_IN_KEY_ID') ?? ''
const APPLE_TEAM_ID = Deno.env.get('APPLE_TEAM_ID') ?? ''
const APPLE_CLIENT_ID = Deno.env.get('APPLE_CLIENT_ID') ?? 'com.otlobli.app'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, 'content-type': 'application/json' } })
}

function base64Url(bytes: Uint8Array): string {
  let binary = ''
  bytes.forEach((byte) => { binary += String.fromCharCode(byte) })
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function pemToDer(pem: string): Uint8Array {
  const content = pem.replace(/-----BEGIN [^-]+-----/g, '').replace(/-----END [^-]+-----/g, '').replace(/\s+/g, '')
  const binary = atob(content)
  return Uint8Array.from(binary, (char) => char.charCodeAt(0))
}

async function appleClientSecret(): Promise<string | null> {
  if (!APPLE_SIGN_IN_KEY || !APPLE_SIGN_IN_KEY_ID || !APPLE_TEAM_ID || !APPLE_CLIENT_ID) return null
  const now = Math.floor(Date.now() / 1000)
  const encode = (value: unknown) => base64Url(new TextEncoder().encode(JSON.stringify(value)))
  const unsigned = `${encode({ alg: 'ES256', kid: APPLE_SIGN_IN_KEY_ID })}.${encode({
    iss: APPLE_TEAM_ID, iat: now, exp: now + 300, aud: 'https://appleid.apple.com', sub: APPLE_CLIENT_ID,
  })}`
  const key = await crypto.subtle.importKey('pkcs8', pemToDer(APPLE_SIGN_IN_KEY), { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign'])
  const signature = new Uint8Array(await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, new TextEncoder().encode(unsigned)))
  return `${unsigned}.${base64Url(signature)}`
}

async function revokeAppleAuthorization(refreshToken: string): Promise<boolean> {
  try {
    const clientSecret = await appleClientSecret()
    if (!clientSecret) return false
    const response = await fetch('https://appleid.apple.com/auth/revoke', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: APPLE_CLIENT_ID,
        client_secret: clientSecret,
        token: refreshToken,
        token_type_hint: 'refresh_token',
      }),
      signal: AbortSignal.timeout(10000),
    })
    return response.ok
  } catch {
    return false
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405, headers: corsHeaders })
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return json({ error: 'account_lifecycle_not_configured' }, 503)

  let body: { action?: string; sessionToken?: string }
  try { body = await req.json() as typeof body }
  catch { return json({ error: 'invalid_body' }, 400) }
  if (body.action !== 'delete') return json({ error: 'invalid_action' }, 400)
  const sessionToken = (body.sessionToken ?? '').trim()
  if (!sessionToken) return json({ error: 'missing_session' }, 401)

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
  const { data: customerId, error: sessionError } = await supabase.rpc('get_customer_id_for_session', {
    p_session_token: sessionToken,
  })
  if (sessionError || !customerId) return json({ error: 'invalid_session' }, 401)

  const { data: appleAuthorizations, error: appleLookupError } = await supabase
    .from('apple_authorizations').select('refresh_token').eq('customer_id', customerId)
  if (appleLookupError) return json({ error: 'account_lookup_failed' }, 500)
  for (const authorization of appleAuthorizations ?? []) {
    const revoked = await revokeAppleAuthorization(String(authorization.refresh_token))
    if (!revoked) return json({ error: 'apple_revocation_failed', message: 'تعذر إلغاء تفويض Apple الآن. حاول مجدداً.' }, 503)
  }

  const { data, error } = await supabase.rpc('delete_customer_account', { p_session_token: sessionToken })
  if (error || !(data as { deleted?: boolean } | null)?.deleted) return json({ error: 'account_delete_failed' }, 500)
  return json({ deleted: true, appleRevoked: (appleAuthorizations?.length ?? 0) > 0 })
})
