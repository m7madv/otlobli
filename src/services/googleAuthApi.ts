// تسجيل الدخول عبر جوجل (واجهة العميل).
// خامل تماماً حتى: (1) يُضبط VITE_GOOGLE_AUTH_ENABLED=true و VITE_GOOGLE_WEB_CLIENT_ID،
// (2) يعمل داخل تطبيق أصلي مع إضافة @capgo/capacitor-social-login.
// الاستيراد ديناميكي محروس بـ @vite-ignore حتى يمرّ بناء الويب بأمان.
import { cleanEnvValue } from '../config'

const SUPABASE_URL = cleanEnvValue(import.meta.env.VITE_SUPABASE_URL)
const SUPABASE_ANON_KEY = cleanEnvValue(import.meta.env.VITE_SUPABASE_ANON_KEY)
const WEB_CLIENT_ID = cleanEnvValue(import.meta.env.VITE_GOOGLE_WEB_CLIENT_ID)
const ENABLED_FLAG = cleanEnvValue(import.meta.env.VITE_GOOGLE_AUTH_ENABLED) === 'true'

// جاهزية الميزة: العلم مفعّل + معرّف عميل الويب موجود + Supabase مضبوط.
export const isGoogleAuthEnabled = ENABLED_FLAG && !!WEB_CLIENT_ID && !!SUPABASE_URL && !!SUPABASE_ANON_KEY

const FN_URL = `${SUPABASE_URL}/functions/v1/google-auth`

export type GoogleProfile = { sub: string; email: string; name: string; emailVerified: boolean }

export type GoogleSignInResult =
  | { mode: 'existing'; sessionToken: string; phone: string; name: string; google: GoogleProfile; idToken: string }
  | { mode: 'new'; needsPhoneLink: true; google: GoogleProfile; idToken: string }

let pluginInitialized = false

// يحصل على idToken من إضافة جوجل الأصلية (يُهيّئها مرة واحدة).
async function getGoogleIdToken(): Promise<string> {
  // اسم الحزمة في متغيّر حتى لا يحاول Vite حلّها وقت البناء.
  const pkg = '@capgo/capacitor-social-login'
  const mod = (await import(/* @vite-ignore */ pkg)) as {
    SocialLogin: {
      initialize: (opts: { google?: { webClientId?: string } }) => Promise<void>
      login: (opts: { provider: 'google'; options: { scopes?: string[] } }) => Promise<{
        result?: { idToken?: string }
      }>
    }
  }
  const SocialLogin = mod.SocialLogin
  if (!pluginInitialized) {
    await SocialLogin.initialize({ google: { webClientId: WEB_CLIENT_ID } })
    pluginInitialized = true
  }
  const res = await SocialLogin.login({ provider: 'google', options: { scopes: ['email', 'profile'] } })
  const idToken = res?.result?.idToken
  if (!idToken) throw new Error('تعذّر الحصول على رمز جوجل.')
  return idToken
}

async function callFn(body: Record<string, unknown>): Promise<Record<string, unknown>> {
  const res = await fetch(FN_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      apikey: SUPABASE_ANON_KEY,
      authorization: `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify(body),
  })
  const data = (await res.json().catch(() => null)) as Record<string, unknown> | null
  if (!res.ok) {
    const msg = (data?.message as string) || (data?.error as string) || 'تعذّر تسجيل الدخول عبر جوجل.'
    throw new Error(msg)
  }
  return data ?? {}
}

// يبدأ تسجيل الدخول عبر جوجل ويرجع إمّا جلسة جاهزة أو طلب توثيق هاتف.
export async function signInWithGoogle(): Promise<GoogleSignInResult> {
  if (!isGoogleAuthEnabled) throw new Error('تسجيل الدخول عبر جوجل غير مفعّل.')
  const idToken = await getGoogleIdToken()
  const data = await callFn({ idToken })
  const google = (data.google ?? {}) as GoogleProfile
  if (data.mode === 'existing' && typeof data.sessionToken === 'string') {
    return {
      mode: 'existing',
      sessionToken: data.sessionToken,
      phone: (data.phone as string) ?? '',
      name: (data.name as string) ?? '',
      google,
      idToken,
    }
  }
  return { mode: 'new', needsPhoneLink: true, google, idToken }
}

// يربط هوية جوجل بحساب مصادَق عليه بجلسة هاتف (بعد OTP، أو من الإعدادات).
export async function linkGoogleToSession(idToken: string, sessionToken: string): Promise<void> {
  if (!idToken || !sessionToken) return
  await callFn({ idToken, sessionToken, action: 'link' })
}
