const defaultSupportPhone = '963900000000'

export function getSupportWhatsappPhone() {
  return normalizeWhatsappPhone(import.meta.env.VITE_SUPPORT_WHATSAPP_PHONE || defaultSupportPhone)
}

export function buildWhatsappLink(message: string, phone = getSupportWhatsappPhone()) {
  const encodedMessage = encodeURIComponent(message.trim())
  return `https://wa.me/${phone}${encodedMessage ? `?text=${encodedMessage}` : ''}`
}

function normalizeWhatsappPhone(phone: string) {
  const digits = phone.replace(/\D/g, '')

  if (digits.startsWith('00')) {
    return digits.slice(2)
  }

  return digits || defaultSupportPhone
}
