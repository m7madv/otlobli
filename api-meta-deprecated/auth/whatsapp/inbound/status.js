import { ApiError, ensurePost, getString, readJsonBody, sendError, sendJson } from '../../../_shared/http.js'
import { createSessionToken, normalizePhone } from '../../../_shared/otp.js'
import { createServerSupabaseClient } from '../../../_shared/serverSupabase.js'

export default async function handler(req, res) {
  if (!ensurePost(req, res)) {
    return
  }

  try {
    const body = await readJsonBody(req)
    const phone = normalizePhone(getString(body, 'phone'))
    const supabase = createServerSupabaseClient()
    const { data, error } = await supabase
      .from('otp_challenges')
      .select('id, status, expires_at, verified_at')
      .eq('phone', phone)
      .eq('channel', 'whatsapp')
      .eq('provider', 'whatsapp_inbound_link')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (error) {
      throw new ApiError('otp_storage_error', 500, 'تعذر قراءة رمز التحقق من قاعدة البيانات.')
    }

    if (!data) {
      throw new ApiError('invalid_code', 400, 'رمز التحقق غير صحيح.')
    }

    if (data.status === 'verified' && data.verified_at) {
      sendJson(res, 200, {
        mode: 'external',
        sessionToken: createSessionToken(phone, data.id),
      })
      return
    }

    if (new Date(data.expires_at).getTime() < Date.now()) {
      await supabase.from('otp_challenges').update({ status: 'expired' }).eq('id', data.id)
      throw new ApiError('expired_code', 400, 'انتهت صلاحية الرمز. أرسل رمزاً جديداً.')
    }

    throw new ApiError(
      'whatsapp_message_pending',
      409,
      'لم تصل رسالة واتساب بعد. سنؤكد الحساب تلقائياً فور وصولها.',
    )
  } catch (error) {
    sendError(res, error)
  }
}
