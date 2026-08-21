import { Capacitor } from '@capacitor/core'
import { cleanEnvValue } from '../config'
import { initializeSocialLogin, SocialLogin } from './socialLoginNative'

const SUPABASE_URL = cleanEnvValue(import.meta.env.VITE_SUPABASE_URL)
const SUPABASE_ANON_KEY = cleanEnvValue(import.meta.env.VITE_SUPABASE_ANON_KEY)
const NATIVE_PLATFORM = Capacitor.getPlatform()

export const isAppleAuthEnabled = NATIVE_PLATFORM === 'ios' && !!SUPABASE_URL && !!SUPABASE_ANON_KEY
const FN_URL = `${SUPABASE_URL}/functions/v1/apple-auth`

export type AppleProfile = { sub: string; email: string; name: string; emailVerified: boolean }
export type AppleSignInResult =
  | { mode: 'existing'; sessionToken: string; phone: string; name: string; apple: AppleProfile }
  | { mode: 'new'; apple: AppleProfile; idToken: string; rawNonce: string }

export type AppleRegistrationProfile = {
  phone: string
  name: string
  governorate: string
  qadmousBranch?: string
  city?: string
  details?: string
}

function base64Url(bytes: Uint8Array): string {
  let binary = ''
  for (const byte of bytes) binary += String.fromCharCode(byte)
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

async function noncePair(): Promise<{ raw: string; hashed: string }> {
  const bytes = new Uint8Array(32)
  crypto.getRandomValues(bytes)
  const raw = base64Url(bytes)
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(raw)))
  const hashed = Array.from(digest).map((value) => value.toString(16).padStart(2, '0')).join('')
  return { raw, hashed }
}

async function callFn(body: Record<string, unknown>): Promise<Record<string, unknown>> {
  const response = await fetch(FN_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      apikey: SUPABASE_ANON_KEY,
      authorization: `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify(body),
  })
  const data = await response.json().catch(() => ({})) as Record<string, unknown>
  if (!response.ok) throw new Error(String(data.message ?? data.error ?? 'تعذر تسجيل الدخول عبر Apple.'))
  return data
}

async function getAppleCredential(): Promise<{ idToken: string; rawNonce: string; authorizationCode: string; name: string }> {
  if (!isAppleAuthEnabled) throw new Error('تسجيل الدخول عبر Apple غير متاح على هذا الجهاز.')
  await initializeSocialLogin()
  const nonce = await noncePair()
  const response = await SocialLogin.login({
    provider: 'apple',
    options: { scopes: ['email', 'name'], nonce: nonce.hashed },
  })
  const idToken = response.result.idToken?.trim()
  const authorizationCode = response.result.authorizationCode?.trim()
  if (!idToken) throw new Error('تعذر الحصول على رمز Apple.')
  if (!authorizationCode) throw new Error('تعذر إكمال تفويض Apple الآمن.')
  const name = [response.result.profile.givenName, response.result.profile.familyName]
    .filter(Boolean).join(' ').trim()
  return { idToken, rawNonce: nonce.raw, authorizationCode, name }
}

export async function signInWithApple(): Promise<AppleSignInResult> {
  const credential = await getAppleCredential()
  const data = await callFn(credential)
  const apple = (data.apple ?? {}) as AppleProfile
  if (data.mode === 'existing' && typeof data.sessionToken === 'string') {
    return {
      mode: 'existing',
      sessionToken: data.sessionToken,
      phone: String(data.phone ?? ''),
      name: String(data.name ?? ''),
      apple,
    }
  }
  return { mode: 'new', apple: { ...apple, name: apple.name || credential.name }, idToken: credential.idToken, rawNonce: credential.rawNonce }
}

export async function linkAppleAccount(sessionToken: string): Promise<void> {
  const credential = await getAppleCredential()
  await callFn({ ...credential, action: 'link', sessionToken })
}

export async function registerAppleAccount(
  idToken: string,
  rawNonce: string,
  profile: AppleRegistrationProfile,
): Promise<{ sessionToken: string; phone: string; name: string; apple: AppleProfile }> {
  const data = await callFn({ idToken, rawNonce, action: 'register', ...profile })
  if (data.mode !== 'registered' || typeof data.sessionToken !== 'string') {
    throw new Error('تعذر إنشاء الحساب عبر Apple.')
  }
  return {
    sessionToken: data.sessionToken,
    phone: String(data.phone ?? profile.phone),
    name: String(data.name ?? profile.name),
    apple: (data.apple ?? {}) as AppleProfile,
  }
}
