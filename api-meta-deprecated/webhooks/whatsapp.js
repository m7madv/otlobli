import { createHmac, timingSafeEqual } from 'crypto'
import { ApiError, readRawBody, sendError, sendJson } from '../_shared/http.js'
import { getOtpLength, isSameOtpHash, normalizePhone } from '../_shared/otp.js'
import { createServerSupabaseClient, getEnv } from '../_shared/serverSupabase.js'

export default async function handler(req, res) {
  if (req.method === 'GET') {
    verifyWebhook(req, res)
    return
  }

  if (req.method !== 'POST') {
    sendJson(res, 405, { error: 'method_not_allowed' })
    return
  }

  try {
    const rawBody = await readRawBody(req)
    verifyMetaSignature(req, rawBody)
    const payload = parseWebhookPayload(rawBody)
    const messages = extractIncomingTextMessages(payload)
    console.info('whatsapp_webhook_received', {
      message_count: messages.length,
      object: payload.object ?? '',
    })

    if (messages.length) {
      const supabase = createServerSupabaseClient()

      for (const message of messages) {
        await verifyInboundMessage(supabase, message)
      }
    }

    sendJson(res, 200, { ok: true })
  } catch (error) {
    sendError(res, error)
  }
}

function parseWebhookPayload(rawBody) {
  if (!rawBody.trim()) {
    return {}
  }

  try {
    return JSON.parse(rawBody)
  } catch {
    throw new ApiError('invalid_json', 400, 'صيغة الطلب غير صحيحة.')
  }
}

function verifyMetaSignature(req, rawBody) {
  const appSecret = getEnv('WHATSAPP_APP_SECRET')

  if (!appSecret) {
    return
  }

  const signature = String(req.headers['x-hub-signature-256'] ?? '')

  if (!signature.startsWith('sha256=')) {
    throw new ApiError('invalid_webhook_signature', 401, 'تعذر التحقق من مصدر رسالة واتساب.')
  }

  const expected = `sha256=${createHmac('sha256', appSecret).update(rawBody).digest('hex')}`
  const signatureBuffer = Buffer.from(signature, 'utf8')
  const expectedBuffer = Buffer.from(expected, 'utf8')

  if (signatureBuffer.length !== expectedBuffer.length || !timingSafeEqual(signatureBuffer, expectedBuffer)) {
    throw new ApiError('invalid_webhook_signature', 401, 'تعذر التحقق من مصدر رسالة واتساب.')
  }
}

function verifyWebhook(req, res) {
  const url = new URL(req.url ?? '', 'https://talabieh.vercel.app')
  const mode = url.searchParams.get('hub.mode')
  const token = url.searchParams.get('hub.verify_token')
  const challenge = url.searchParams.get('hub.challenge')
  const expectedToken = getEnv('WHATSAPP_WEBHOOK_VERIFY_TOKEN')

  if (!expectedToken) {
    sendJson(res, 503, { error: 'webhook_not_configured' })
    return
  }

  if (mode === 'subscribe' && token === expectedToken && challenge) {
    res.statusCode = 200
    res.setHeader('Content-Type', 'text/plain; charset=utf-8')
    res.end(challenge)
    return
  }

  sendJson(res, 403, { error: 'webhook_verification_failed' })
}

async function verifyInboundMessage(supabase, message) {
  const phone = normalizePhone(message.from)
  const code = extractOtpCode(message.text)

  if (!code) {
    console.info('whatsapp_webhook_ignored', {
      reason: 'missing_code',
      phone_suffix: phone.slice(-4),
      business_phone_number_id: message.businessPhoneNumberId,
      business_display_phone: message.businessDisplayPhone,
    })
    return
  }

  const { data, error } = await supabase
    .from('otp_challenges')
    .select('id, code_hash, expires_at, created_at')
    .eq('phone', phone)
    .eq('channel', 'whatsapp')
    .eq('provider', 'whatsapp_inbound_link')
    .eq('status', 'pending')
    .order('created_at', { ascending: false })
    .limit(5)

  if (error || !data?.length) {
    console.info('whatsapp_webhook_ignored', {
      reason: error ? 'challenge_query_error' : 'no_pending_challenge',
      phone_suffix: phone.slice(-4),
    })
    return
  }

  for (const challenge of data) {
    if (new Date(challenge.expires_at).getTime() < Date.now()) {
      await supabase.from('otp_challenges').update({ status: 'expired' }).eq('id', challenge.id)
      continue
    }

    if (!isSameOtpHash(phone, code, challenge.code_hash)) {
      continue
    }

    await supabase
      .from('otp_challenges')
      .update({
        status: 'verified',
        verified_at: new Date().toISOString(),
        provider_message_id: message.id,
        provider_response: {
          from: message.from,
          text: message.text,
          profile_name: message.profileName,
          message_id: message.id,
          business_phone_number_id: message.businessPhoneNumberId,
          business_display_phone: message.businessDisplayPhone,
          received_at: message.timestamp,
          source: 'whatsapp_webhook',
        },
      })
      .eq('id', challenge.id)

    await upsertVerifiedCustomer(supabase, phone, message.profileName)
    console.info('whatsapp_webhook_verified', {
      phone_suffix: phone.slice(-4),
      business_phone_number_id: message.businessPhoneNumberId,
      business_display_phone: message.businessDisplayPhone,
      matched_by: 'code_and_phone',
    })
    return
  }

  console.info('whatsapp_webhook_ignored', {
    reason: 'no_matching_pending_challenge',
    phone_suffix: phone.slice(-4),
    has_code: Boolean(code),
    business_phone_number_id: message.businessPhoneNumberId,
    business_display_phone: message.businessDisplayPhone,
  })
}

async function upsertVerifiedCustomer(supabase, phone, profileName) {
  const customer = {
    phone,
    updated_at: new Date().toISOString(),
  }

  await supabase.from('customers').upsert(customer, { onConflict: 'phone' })
}

function extractOtpCode(text) {
  const match = text.match(new RegExp(`\\b(\\d{${getOtpLength()}})\\b`))
  return match?.[1] ?? ''
}

function extractIncomingTextMessages(payload) {
  const messages = []

  for (const entry of Array.isArray(payload.entry) ? payload.entry : []) {
    for (const change of Array.isArray(entry.changes) ? entry.changes : []) {
      const value = change.value ?? {}
      const metadata = value.metadata ?? {}
      const contactNamesByPhone = new Map()

      for (const contact of Array.isArray(value.contacts) ? value.contacts : []) {
        const phone = String(contact.wa_id ?? '')
        const profileName = String(contact.profile?.name ?? '').trim()

        if (phone && profileName) {
          contactNamesByPhone.set(phone, profileName)
        }
      }

      for (const message of Array.isArray(value.messages) ? value.messages : []) {
        if (message.type !== 'text' || typeof message.text?.body !== 'string') {
          continue
        }

        messages.push({
          id: String(message.id ?? ''),
          from: String(message.from ?? ''),
          text: message.text.body,
          timestamp: String(message.timestamp ?? ''),
          profileName: contactNamesByPhone.get(String(message.from ?? '')) ?? '',
          businessPhoneNumberId: String(metadata.phone_number_id ?? ''),
          businessDisplayPhone: String(metadata.display_phone_number ?? ''),
        })
      }
    }
  }

  return messages
}
