import { ApiError, ensurePost, getString, readJsonBody, sendError, sendJson } from '../../_shared/http.js'
import {
  createSessionToken,
  getOtpLength,
  isSameOtpHash,
  normalizeOtpCode,
  normalizePhone,
} from '../../_shared/otp.js'
import { createServerSupabaseClient } from '../../_shared/serverSupabase.js'

const maxAttempts = 5

export default async function handler(req, res) {
  if (!ensurePost(req, res)) {
    return
  }

  try {
    const body = await readJsonBody(req)
    const phone = normalizePhone(getString(body, 'phone'))
    const code = normalizeOtpCode(getString(body, 'code'), getOtpLength())
    const supabase = createServerSupabaseClient()
    const { data, error } = await supabase
      .from('otp_challenges')
      .select('id, code_hash, expires_at, attempts')
      .eq('phone', phone)
      .eq('channel', 'whatsapp')
      .eq('status', 'sent')
      .is('verified_at', null)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (error) {
      throw new ApiError('otp_storage_error', 500, 'تعذر قراءة رمز التحقق من قاعدة البيانات.')
    }

    if (!data) {
      throw new ApiError('invalid_code', 400, 'رمز التحقق غير صحيح.')
    }

    if (new Date(data.expires_at).getTime() < Date.now()) {
      await supabase.from('otp_challenges').update({ status: 'expired' }).eq('id', data.id)
      throw new ApiError('expired_code', 400, 'انتهت صلاحية الرمز. أرسل رمزاً جديداً.')
    }

    if (data.attempts >= maxAttempts) {
      await supabase.from('otp_challenges').update({ status: 'failed' }).eq('id', data.id)
      throw new ApiError('too_many_attempts', 429, 'تم تجاوز عدد المحاولات. أرسل رمزاً جديداً.')
    }

    if (!isSameOtpHash(phone, code, data.code_hash)) {
      const nextAttempts = data.attempts + 1
      await supabase
        .from('otp_challenges')
        .update({
          attempts: nextAttempts,
          ...(nextAttempts >= maxAttempts ? { status: 'failed' } : {}),
        })
        .eq('id', data.id)
      throw new ApiError('invalid_code', 400, 'رمز التحقق غير صحيح.')
    }

    await supabase
      .from('otp_challenges')
      .update({
        status: 'verified',
        verified_at: new Date().toISOString(),
      })
      .eq('id', data.id)

    sendJson(res, 200, {
      mode: 'external',
      sessionToken: createSessionToken(phone, data.id),
    })
  } catch (error) {
    sendError(res, error)
  }
}
