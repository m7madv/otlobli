import { ApiError } from './http.js'
import { getEnv, getOptionalEnv } from './serverSupabase.js'

export async function sendWhatsappOtp(phone, code) {
  const accessToken = getEnv('WHATSAPP_ACCESS_TOKEN')
  const phoneNumberId = getEnv('WHATSAPP_PHONE_NUMBER_ID')
  const templateName = getEnv('WHATSAPP_OTP_TEMPLATE_NAME')

  if (!accessToken || !phoneNumberId || !templateName) {
    throw new ApiError(
      'whatsapp_not_configured',
      503,
      'واتساب API غير مربوط بعد. نحتاج مفاتيح Meta لتفعيل الإرسال الحقيقي.',
    )
  }

  const apiVersion = getOptionalEnv('WHATSAPP_GRAPH_VERSION', 'v25.0')
  const languageCode = getOptionalEnv('WHATSAPP_OTP_TEMPLATE_LANGUAGE', 'ar')
  const components = buildOtpTemplateComponents(code)
  const response = await fetch(`https://graph.facebook.com/${apiVersion}/${phoneNumberId}/messages`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: phone,
      type: 'template',
      template: {
        name: templateName,
        language: {
          code: languageCode,
        },
        ...(components.length ? { components } : {}),
      },
    }),
  })

  const raw = await response.json().catch(() => ({}))

  if (!response.ok) {
    console.error('whatsapp_send_error', response.status, raw)
    throw new ApiError('whatsapp_send_error', 502, 'تعذر إرسال رسالة واتساب من Meta حالياً.')
  }

  return {
    providerMessageId: raw.messages?.[0]?.id ?? null,
    raw,
  }
}

function buildOtpTemplateComponents(code) {
  const components = []

  if (getEnv('WHATSAPP_TEMPLATE_USES_BODY_CODE') !== 'false') {
    components.push({
      type: 'body',
      parameters: [{ type: 'text', text: code }],
    })
  }

  if (getEnv('WHATSAPP_TEMPLATE_HAS_COPY_CODE_BUTTON') === 'true') {
    components.push({
      type: 'button',
      sub_type: 'copy_code',
      index: '0',
      parameters: [{ type: 'coupon_code', coupon_code: code }],
    })
  }

  return components
}
