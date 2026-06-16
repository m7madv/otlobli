import { ApiError, ensurePost, getString, readJsonBody, sendError, sendJson } from '../../../_shared/http.js'
import { generateOtpCode, getOtpExpiresInMinutes, getOtpLength, hashOtp, normalizePhone } from '../../../_shared/otp.js'
import { createServerSupabaseClient, getEnv } from '../../../_shared/serverSupabase.js'

const defaultSupportPhone = '963900000000'

export default async function handler(req, res) {
  if (!ensurePost(req, res)) {
    return
  }

  try {
    const body = await readJsonBody(req)
    const phone = normalizePhone(getString(body, 'phone'))
    const supportPhone = normalizeSupportPhone(getEnv('SUPPORT_WHATSAPP_PHONE') || getEnv('VITE_SUPPORT_WHATSAPP_PHONE'))
    const codeLength = getOtpLength()
    const expiresInMinutes = getOtpExpiresInMinutes()
    const code = generateOtpCode(codeLength)
    const verificationMessage = `طلبية ${code}`
    const expiresAt = new Date(Date.now() + expiresInMinutes * 60 * 1000).toISOString()
    const supabase = createServerSupabaseClient()
    const { error } = await supabase.from('otp_challenges').insert({
      phone,
      channel: 'whatsapp',
      provider: 'whatsapp_inbound_link',
      status: 'pending',
      code_hash: hashOtp(phone, code),
      attempts: 0,
      expires_at: expiresAt,
      provider_response: {
        flow: 'customer_sends_code_to_business_chat',
      },
    })

    if (error) {
      console.error('otp_inbound_storage_error', error)
      throw new ApiError('otp_storage_error', 500, 'تعذر حفظ رمز التحقق في قاعدة البيانات.')
    }

    sendJson(res, 200, {
      mode: 'external',
      otpExpiresInSeconds: expiresInMinutes * 60,
      supportPhone,
      verificationMessage,
      requiresInboundWhatsapp: true,
      whatsappUrl: `https://wa.me/${supportPhone}?text=${encodeURIComponent(verificationMessage)}`,
    })
  } catch (error) {
    sendError(res, error)
  }
}

function normalizeSupportPhone(phone) {
  const digits = phone.replace(/\D/g, '')

  if (digits.startsWith('00')) {
    return digits.slice(2)
  }

  return digits || defaultSupportPhone
}
