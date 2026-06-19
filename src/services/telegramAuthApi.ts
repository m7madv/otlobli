import type { StartLoginResult, VerifyOtpResult, TalabiehApi } from './appApi'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || ''
const ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || ''
const FN_URL = `${SUPABASE_URL}/functions/v1/telegram-auth`

const headers = {
  'content-type': 'application/json',
  'apikey': ANON_KEY,
  'authorization': `Bearer ${ANON_KEY}`,
}

export const isTelegramAuthEnabled = Boolean(SUPABASE_URL && ANON_KEY)

export const telegramAuthApi: TalabiehApi['auth'] = {
  async startWhatsappLogin(phone: string): Promise<StartLoginResult> {
    const res = await fetch(`${FN_URL}?action=generate`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ phone }),
    })
    if (!res.ok) throw new Error('تعذّر إرسال رمز التحقق.')
    const data = await res.json() as { otp: string; bot: string }
    return {
      mode: 'external',
      otpExpiresInSeconds: 600,
      telegramOtp: data.otp,
    }
  },

  async verifyOtp(phone: string, code: string): Promise<VerifyOtpResult> {
    const res = await fetch(`${FN_URL}?action=check&phone=${encodeURIComponent(phone)}&otp=${encodeURIComponent(code)}`, {
      headers,
    })
    if (!res.ok) throw new Error('تعذّر التحقق.')
    const data = await res.json() as { verified: boolean; expired?: boolean }
    if (data.expired) throw new Error('انتهت صلاحية الرمز. اطلب رمزاً جديداً.')
    if (!data.verified) throw new Error('لم يتم التحقق بعد. أرسل الرمز لبوت تيليغرام أولاً.')
    return { mode: 'external', sessionToken: phone }
  },
}
