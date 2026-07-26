// تسجيل الدخول عبر جوجل (واجهة العميل).
// خامل تماماً حتى: (1) يُضبط VITE_GOOGLE_AUTH_ENABLED=true و VITE_GOOGLE_WEB_CLIENT_ID،
// (2) يعمل داخل تطبيق أصلي مع إضافة @capgo/capacitor-social-login.
// تُضمَّن الإضافة في حزمة Vite حتى لا يحاول WebView حل اسم حزمة bare specifier وقت التشغيل.
import { SocialLogin } from '@capgo/capacitor-social-login'
import { Capacitor } from '@capacitor/core'
import { cleanEnvValue } from '../config'

const SUPABASE_URL = cleanEnvValue(import.meta.env.VITE_SUPABASE_URL)
const SUPABASE_ANON_KEY = cleanEnvValue(import.meta.env.VITE_SUPABASE_ANON_KEY)
const DEFAULT_WEB_CLIENT_ID = '677396296147-o5q0rt5qk2rq0rqh714kuki7gabkdmcu.apps.googleusercontent.com'
const WEB_CLIENT_ID = cleanEnvValue(import.meta.env.VITE_GOOGLE_WEB_CLIENT_ID) || DEFAULT_WEB_CLIENT_ID
const IOS_CLIENT_ID = cleanEnvValue(import.meta.env.VITE_GOOGLE_IOS_CLIENT_ID)
const ENABLED_FLAG = cleanEnvValue(import.meta.env.VITE_GOOGLE_AUTH_ENABLED) !== 'false'
const NATIVE_PLATFORM = Capacitor.getPlatform()

// جاهزية الميزة: العلم مفعّل + معرّف عميل الويب موجود + Supabase مضبوط.
// iOS additionally requires its bundle-bound OAuth client. Hiding the action
// when that credential is absent is safer than showing a button that can only
// fail with "No provider was initialized".
export const isGoogleAuthEnabled =
  ENABLED_FLAG &&
  !!WEB_CLIENT_ID &&
  !!SUPABASE_URL &&
  !!SUPABASE_ANON_KEY &&
  (NATIVE_PLATFORM !== 'ios' || !!IOS_CLIENT_ID)

const FN_URL = `${SUPABASE_URL}/functions/v1/google-auth`

export type GoogleProfile = { sub: string; email: string; name: string; emailVerified: boolean }

export type GoogleSignInResult =
  | { mode: 'existing'; sessionToken: string; phone: string; name: string; google: GoogleProfile; idToken: string }
  | { mode: 'new'; google: GoogleProfile; idToken: string }

export type GoogleRegistrationProfile = {
  phone: string
  name: string
  governorate: string
  qadmousBranch?: string
  city?: string
  details?: string
}

export type AccountAuthMethods = {
  deliveryPhone: string
  phoneLinked: boolean
  phoneVerifiedAt: string | null
  googleLinked: boolean
  googleEmail: string
  googleName: string
}

let pluginInitialized = false

// يحصل على idToken من إضافة جوجل الأصلية (يُهيّئها مرة واحدة).
async function getGoogleIdToken(): Promise<string> {
  if (!pluginInitialized) {
    await SocialLogin.initialize({
      google: {
        webClientId: WEB_CLIENT_ID,
        iOSClientId: IOS_CLIENT_ID || undefined,
        iOSServerClientId: WEB_CLIENT_ID,
        mode: 'online',
      },
    })
    pluginInitialized = true
  }
  // Standard Google identity already returns the ID token/profile requested by
  // the initialized client. Passing custom scopes on Android requires a custom
  // MainActivity implementation and the plugin rejects it at runtime.
  const res = await SocialLogin.login({
    provider: 'google',
    options: {
      style: 'bottom',
      filterByAuthorizedAccounts: false,
      autoSelectEnabled: false,
    },
  })
  const googleResult = res.provider === 'google' ? res.result : null
  const idToken = googleResult?.responseType === 'online' ? googleResult.idToken : null
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

// يبدأ تسجيل الدخول عبر جوجل ويرجع إمّا جلسة جاهزة أو هوية جديدة بانتظار
// بيانات الاستلام. لا يُطلب OTP ولا يتحول رقم الاستلام إلى وسيلة دخول.
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
  return { mode: 'new', google, idToken }
}

// يربط هوية جوجل بحساب مصادَق عليه بجلسة هاتف (بعد OTP، أو من الإعدادات).
export async function linkGoogleToSession(idToken: string, sessionToken: string): Promise<void> {
  if (!idToken || !sessionToken) return
  await callFn({ idToken, sessionToken, action: 'link' })
}

export async function registerGoogleAccount(
  idToken: string,
  profile: GoogleRegistrationProfile,
): Promise<{ sessionToken: string; phone: string; name: string; google: GoogleProfile }> {
  if (!idToken) throw new Error('انتهت محاولة Google. أعد اختيار الحساب.')
  const data = await callFn({ idToken, action: 'register', ...profile })
  if (data.mode !== 'registered' || typeof data.sessionToken !== 'string') {
    throw new Error('تعذّر إنشاء الحساب عبر Google.')
  }
  return {
    sessionToken: data.sessionToken,
    phone: String(data.phone ?? profile.phone),
    name: String(data.name ?? profile.name),
    google: (data.google ?? {}) as GoogleProfile,
  }
}

// يُستخدم من «طرق تسجيل الدخول»: يختار المستخدم حساب Google ثم يُربط
// بالجلسة الحالية مباشرة، مع رفض الخادم لأي هوية مرتبطة بحساب آخر.
export async function linkGoogleAccount(sessionToken: string): Promise<void> {
  if (!sessionToken) throw new Error('انتهت جلسة الدخول. سجّل الدخول مجدداً.')
  const idToken = await getGoogleIdToken()
  await linkGoogleToSession(idToken, sessionToken)
}

export async function getAccountAuthMethods(sessionToken: string): Promise<AccountAuthMethods> {
  if (!sessionToken) throw new Error('انتهت جلسة الدخول. سجّل الدخول مجدداً.')
  const data = await callFn({ action: 'status', sessionToken })
  return {
    deliveryPhone: String(data.deliveryPhone ?? ''),
    phoneLinked: data.phoneLinked === true,
    phoneVerifiedAt: typeof data.phoneVerifiedAt === 'string' ? data.phoneVerifiedAt : null,
    googleLinked: data.googleLinked === true,
    googleEmail: String(data.googleEmail ?? ''),
    googleName: String(data.googleName ?? ''),
  }
}
