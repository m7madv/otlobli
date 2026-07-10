import type { StartLoginResult, VerifyOtpResult, TalabiehApi } from './appApi'
import { cleanEnvValue } from '../config'
import { storageKeys } from '../infrastructure/localStorage'

type ErrorBody = {
  error?: string
  message?: string
}

const errorMessages: Record<string, string> = {
  invalid_phone: 'أدخل رقم واتساب صحيح مع رمز الدولة.',
  invalid_code: 'رمز التحقق غير صحيح.',
  expired_code: 'انتهت صلاحية الرمز. أرسل رمزاً جديداً.',
  too_many_attempts: 'تم تجاوز عدد المحاولات. أرسل رمزاً جديداً.',
  whatsapp_not_configured: 'واتساب API غير مربوط بعد. نحتاج مفاتيح Meta لتفعيل الإرسال الحقيقي.',
  whatsapp_message_pending: 'لم تصل رسالة واتساب بعد. سنؤكد الحساب تلقائياً فور وصولها.',
  supabase_not_configured: 'قاعدة البيانات غير مجهزة لحفظ رموز واتساب بعد.',
  otp_storage_error: 'تعذر حفظ رمز التحقق في قاعدة البيانات.',
  whatsapp_send_error: 'تعذر إرسال رسالة واتساب من Meta حالياً.',
}

export const whatsappAuthMode = cleanEnvValue(import.meta.env.VITE_WHATSAPP_AUTH_MODE)
export const isWhatsappApiAuthEnabled = whatsappAuthMode === 'real' || whatsappAuthMode === 'inbound'

// API Base URL — يستخدم Vercel proxy محلي أو السيرفر المباشر Railway في الإنتاج
const API_BASE = cleanEnvValue(import.meta.env.VITE_WHATSAPP_API_URL)

function getErrorBody(value: unknown): ErrorBody {
  if (!value || typeof value !== 'object') {
    return {}
  }

  return value as ErrorBody
}

async function postJson<T>(path: string, body: Record<string, string>): Promise<T> {
  const url = API_BASE ? `${API_BASE}${path}` : path

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  })

  const responseBody = await response.json().catch(() => null)

  if (!response.ok) {
    const errorBody = getErrorBody(responseBody)
    const message = errorBody.message ?? (errorBody.error ? errorMessages[errorBody.error] : null)
    throw new Error(message ?? 'حدث خطأ أثناء الاتصال بخدمة واتساب.')
  }

  return responseBody as T
}

export const whatsappAuthApi: TalabiehApi['auth'] = {
  startWhatsappLogin(phone: string) {
    const path = whatsappAuthMode === 'inbound' ? '/api/auth/whatsapp/inbound/start' : '/api/auth/whatsapp/start'
    return postJson<StartLoginResult>(path, { phone })
  },
  async verifyOtp(phone: string, code: string) {
    const path = whatsappAuthMode === 'inbound' ? '/api/auth/whatsapp/inbound/status' : '/api/auth/whatsapp/verify'
    const result = await postJson<VerifyOtpResult>(path, { phone, code })
    // Persist immediately so the authenticated profile request that follows
    // this promise can use the token before React's state effect runs.
    if (result.sessionToken && typeof window !== 'undefined') {
      window.localStorage.setItem(storageKeys.sessionToken, JSON.stringify(result.sessionToken))
    }
    return result
  },
}
