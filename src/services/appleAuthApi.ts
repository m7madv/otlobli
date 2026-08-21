import { Capacitor } from '@capacitor/core'
import { cleanEnvValue } from '../config'
import {
  APPLE_ANDROID_CLIENT_ID,
  APPLE_ANDROID_REDIRECT_URL,
  initializeSocialLogin,
  isAndroidAppleConfigured,
  SocialLogin,
} from './socialLoginNative'

const SUPABASE_URL = cleanEnvValue(import.meta.env.VITE_SUPABASE_URL)
const SUPABASE_ANON_KEY = cleanEnvValue(import.meta.env.VITE_SUPABASE_ANON_KEY)
const NATIVE_PLATFORM = Capacitor.getPlatform()
const IOS_APPLE_CLIENT_ID = 'com.otlobli.app'

export const isAppleAuthEnabled = (
  NATIVE_PLATFORM === 'ios'
  || (NATIVE_PLATFORM === 'android' && isAndroidAppleConfigured)
) && !!SUPABASE_URL && !!SUPABASE_ANON_KEY
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

type AppleCredential = {
  idToken?: string
  rawNonce: string
  authorizationCode: string
  name: string
  clientId: string
  redirectUrl?: string
}

function currentAppleClient(): { clientId: string; redirectUrl?: string } {
  if (NATIVE_PLATFORM === 'android') {
    return {
      clientId: APPLE_ANDROID_CLIENT_ID,
      redirectUrl: APPLE_ANDROID_REDIRECT_URL,
    }
  }
  return { clientId: IOS_APPLE_CLIENT_ID }
}

async function getAppleCredential(): Promise<AppleCredential> {
  if (!isAppleAuthEnabled) throw new Error('تسجيل الدخول عبر Apple غير متاح على هذا الجهاز.')
  await initializeSocialLogin()
  const nonce = await noncePair()
  const response = await SocialLogin.login({
    provider: 'apple',
    options: { scopes: ['email', 'name'], nonce: nonce.hashed },
  })
  if (response.provider !== 'apple') throw new Error('تعذر إكمال تسجيل الدخول عبر Apple.')
  const idToken = response.result.idToken?.trim() || undefined
  const authorizationCode = response.result.authorizationCode?.trim()
  if (!authorizationCode) throw new Error('تعذر إكمال تفويض Apple الآمن.')
  // Native iOS returns both values. Android deliberately returns code-only so
  // the backend—not the APK or callback URL—owns Apple's token exchange.
  if (NATIVE_PLATFORM === 'ios' && !idToken) throw new Error('تعذر الحصول على رمز Apple.')
  const name = [response.result.profile.givenName, response.result.profile.familyName]
    .filter(Boolean).join(' ').trim()
  return {
    ...(idToken ? { idToken } : {}),
    rawNonce: nonce.raw,
    authorizationCode,
    name,
    ...currentAppleClient(),
  }
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
  const verifiedIdToken = typeof data.idToken === 'string' && data.idToken.trim()
    ? data.idToken.trim()
    : credential.idToken
  if (!verifiedIdToken) throw new Error('تعذر التحقق من هوية Apple.')
  return {
    mode: 'new',
    apple: { ...apple, name: apple.name || credential.name },
    idToken: verifiedIdToken,
    rawNonce: credential.rawNonce,
  }
}

export async function linkAppleAccount(sessionToken: string): Promise<void> {
  const credential = await getAppleCredential()
  await callFn({ ...credential, action: 'link', sessionToken })
}

export async function cancelAppleRegistration(idToken: string, rawNonce: string): Promise<void> {
  await callFn({
    idToken,
    rawNonce,
    ...currentAppleClient(),
    action: 'cancel-registration',
  })
}

export async function registerAppleAccount(
  idToken: string,
  rawNonce: string,
  profile: AppleRegistrationProfile,
): Promise<{ sessionToken: string; phone: string; name: string; apple: AppleProfile }> {
  const data = await callFn({ idToken, rawNonce, ...currentAppleClient(), action: 'register', ...profile })
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
