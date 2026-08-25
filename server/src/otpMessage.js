const OTP_CODE_PATTERN = /^\d{6}$/

export function buildOtpMessage(code) {
  const normalizedCode = String(code ?? '').trim()
  if (!OTP_CODE_PATTERN.test(normalizedCode)) {
    throw new TypeError('invalid_otp_code')
  }

  return `رمز التحقق لتطبيق Otlobli هو: ${normalizedCode}\nصالح لمدة خمس دقائق. لا تشارك هذا الرمز مع أي شخص.`
}
