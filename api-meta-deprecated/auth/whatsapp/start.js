import { ApiError, ensurePost, getString, readJsonBody, sendError, sendJson } from '../../_shared/http.js'
import { generateOtpCode, getOtpExpiresInMinutes, getOtpLength, hashOtp, normalizePhone } from '../../_shared/otp.js'
import { createServerSupabaseClient } from '../../_shared/serverSupabase.js'
import { sendWhatsappOtp } from '../../_shared/whatsapp.js'

export default async function handler(req, res) {
  if (!ensurePost(req, res)) {
    return
  }

  try {
    const body = await readJsonBody(req)
    const phone = normalizePhone(getString(body, 'phone'))
    const codeLength = getOtpLength()
    const expiresInMinutes = getOtpExpiresInMinutes()
    const code = generateOtpCode(codeLength)
    const now = new Date()
    const expiresAt = new Date(now.getTime() + expiresInMinutes * 60 * 1000).toISOString()
    const supabase = createServerSupabaseClient()
    const { data, error } = await supabase
      .from('otp_challenges')
      .insert({
        phone,
        channel: 'whatsapp',
        provider: 'whatsapp_cloud_api',
        status: 'pending',
        code_hash: hashOtp(phone, code),
        attempts: 0,
        expires_at: expiresAt,
      })
      .select('id, expires_at')
      .single()

    if (error || !data) {
      throw new ApiError('otp_storage_error', 500, 'تعذر حفظ رمز التحقق في قاعدة البيانات.')
    }

    try {
      const sentMessage = await sendWhatsappOtp(phone, code)
      await supabase
        .from('otp_challenges')
        .update({
          status: 'sent',
          sent_at: now.toISOString(),
          provider_message_id: sentMessage.providerMessageId,
          provider_response: sentMessage.raw,
        })
        .eq('id', data.id)
    } catch (error) {
      await supabase
        .from('otp_challenges')
        .update({
          status: 'failed',
          provider_response: {
            error: error instanceof ApiError ? error.code : 'server_error',
          },
        })
        .eq('id', data.id)
      throw error
    }

    sendJson(res, 200, {
      mode: 'external',
      otpExpiresInSeconds: expiresInMinutes * 60,
    })
  } catch (error) {
    sendError(res, error)
  }
}
