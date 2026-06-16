import { createHmac, randomInt, timingSafeEqual } from 'crypto'
import { ApiError } from './http.js'
import { getEnv } from './serverSupabase.js'

export function normalizePhone(rawPhone) {
  let phone = rawPhone.replace(/\D/g, '')

  if (phone.startsWith('00')) {
    phone = phone.slice(2)
  }

  if (phone.startsWith('0') && phone.length === 10) {
    phone = `963${phone.slice(1)}`
  }

  if (phone.startsWith('9') && phone.length === 9) {
    phone = `963${phone}`
  }

  if (!/^[1-9]\d{7,14}$/.test(phone)) {
    throw new ApiError('invalid_phone', 400, 'أدخل رقم واتساب صحيح مع رمز الدولة.')
  }

  return phone
}

export function normalizeOtpCode(rawCode, length) {
  const code = rawCode.replace(/\D/g, '')

  if (code.length !== length) {
    throw new ApiError('invalid_code', 400, 'رمز التحقق غير صحيح.')
  }

  return code
}

export function getOtpLength() {
  const value = Number.parseInt(getEnv('WHATSAPP_OTP_CODE_LENGTH') || '4', 10)
  return Number.isFinite(value) && value >= 4 && value <= 8 ? value : 4
}

export function getOtpExpiresInMinutes() {
  const value = Number.parseInt(getEnv('WHATSAPP_OTP_EXPIRES_MINUTES') || '5', 10)
  return Number.isFinite(value) && value >= 1 && value <= 15 ? value : 5
}

export function generateOtpCode(length) {
  const max = 10 ** length
  return randomInt(0, max).toString().padStart(length, '0')
}

export function hashOtp(phone, code) {
  return createHmac('sha256', getOtpHashSecret()).update(`${phone}:${code}`).digest('hex')
}

export function isSameOtpHash(phone, code, expectedHash) {
  const hash = hashOtp(phone, code)
  const hashBuffer = Buffer.from(hash, 'hex')
  const expectedBuffer = Buffer.from(expectedHash, 'hex')

  return hashBuffer.length === expectedBuffer.length && timingSafeEqual(hashBuffer, expectedBuffer)
}

export function createSessionToken(phone, challengeId) {
  return createHmac('sha256', getOtpHashSecret()).update(`${phone}:${challengeId}:session`).digest('hex')
}

function getOtpHashSecret() {
  const secret = getEnv('OTP_HASH_SECRET') || getEnv('SUPABASE_SERVICE_ROLE_KEY')

  if (!secret) {
    throw new ApiError('supabase_not_configured', 503, 'قاعدة البيانات غير مجهزة لحفظ رموز واتساب بعد.')
  }

  return secret
}
