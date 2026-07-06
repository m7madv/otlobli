export const FULL_NAME_ERROR_MESSAGE = 'يرجى إدخال الاسم الكامل باستخدام كلمتين على الأقل.'

const ARABIC_LATIN_NAME_PATTERN = /^[\p{Script=Arabic}A-Za-z][\p{Script=Arabic}A-Za-z' -]*$/u
const ANY_DIGIT_PATTERN = /[0-9\u0660-\u0669\u06F0-\u06F9]/
const DISALLOWED_NAME_CHARS = /[^\p{Script=Arabic}A-Za-z' -]+/gu

function normalizeNamePunctuation(value: string) {
  return value
    .replace(/[’`]/g, "'")
    .replace(/[‐‑‒–—―]/g, '-')
}

export function sanitizeFullNameInput(value: string) {
  return normalizeNamePunctuation(value)
    .replace(DISALLOWED_NAME_CHARS, '')
    .replace(/\s{2,}/g, ' ')
    .replace(/-{2,}/g, '-')
    .replace(/^ +/g, '')
}

export function normalizeFullName(value: string) {
  return sanitizeFullNameInput(value)
    .replace(/\s+/g, ' ')
    .trim()
}

export function getFullNameValidationError(value: string) {
  const normalized = normalizeFullName(value)
  const parts = normalized.split(' ').filter(Boolean)

  if (parts.length < 2) return FULL_NAME_ERROR_MESSAGE
  if (ANY_DIGIT_PATTERN.test(normalized)) return FULL_NAME_ERROR_MESSAGE
  if (!ARABIC_LATIN_NAME_PATTERN.test(normalized)) return FULL_NAME_ERROR_MESSAGE
  if (parts.some((part) => !/^[\p{Script=Arabic}A-Za-z][\p{Script=Arabic}A-Za-z'-]*$/u.test(part))) {
    return FULL_NAME_ERROR_MESSAGE
  }

  return ''
}

export function isFullNameValid(value: string) {
  return getFullNameValidationError(value) === ''
}
