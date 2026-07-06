// Receives the Sham Cash payment notification text forwarded by MacroDroid
// (running on the merchant's phone - the same phone/account used for the
// "مكثفات بيان" project) and confirms whichever pending otlobli order has a
// matching unique payment_amount. Secured by a shared secret header so only
// the merchant's phone can call it.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PAYMENT_WEBHOOK_SECRET = Deno.env.get('PAYMENT_WEBHOOK_SECRET') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

function toAsciiDigits(value: string): string {
  const arabicZero = '٠'.charCodeAt(0)
  const persianZero = '۰'.charCodeAt(0)
  return value.replace(/[٠-٩۰-۹]/g, (digit) => {
    const code = digit.charCodeAt(0)
    if (code >= arabicZero && code <= arabicZero + 9) return String(code - arabicZero)
    if (code >= persianZero && code <= persianZero + 9) return String(code - persianZero)
    return digit
  })
}

function detectCurrency(text: string): 'SYP' | 'USD' {
  return /\$|USD|دولار/i.test(text) ? 'USD' : 'SYP'
}

function normalizeAmount(raw: string, currency: 'SYP' | 'USD'): number {
  const cleaned = toAsciiDigits(raw).replace(/[^\d.]/g, '')
  const value = Number(cleaned)
  if (!Number.isFinite(value) || value <= 0) return 0
  return currency === 'USD' ? Math.round(value * 100) / 100 : Math.round(value)
}

function extractPaymentAmount(text: string, currency: 'SYP' | 'USD'): number {
  const source = toAsciiDigits(text)
  const currencyPattern = currency === 'USD' ? '(?:USD|\\$|دولار)' : '(?:SYP|SYR|ل\\.?\\s*س|ليرة(?:\\s+سورية)?)'
  const before = new RegExp(`(?:مبلغ|قيمة|تحويل|استلام|دفعة|رصيد|${currencyPattern})[^0-9]{0,30}([\\d.,٬،\\s]{2,})`, 'gi')
  const after = new RegExp(`([\\d.,٬،\\s]{2,})[^0-9]{0,16}(?:${currencyPattern}|مبلغ|قيمة|تحويل|استلام|دفعة)`, 'gi')

  const fragments: string[] = []
  for (const pattern of [before, after]) {
    let match = pattern.exec(source)
    while (match) {
      fragments.push(match[1])
      match = pattern.exec(source)
    }
  }

  if (!fragments.length) {
    fragments.push(...(source.match(/[\d.,٬،]{2,}/g) || []))
  }

  const candidates = fragments
    .map((fragment) => normalizeAmount(fragment, currency))
    .filter((amount) => amount > 0)
    .sort((a, b) => b - a)

  return candidates[0] || 0
}

function bodyToText(raw: unknown, contentType: string): string {
  if (raw && typeof raw === 'object') {
    const obj = raw as Record<string, unknown>
    const values = [obj.notificationText, obj.screenText, obj.transactionText, obj.message, obj.text, obj.body, obj.title]
      .filter((value): value is string => typeof value === 'string' && value.length > 0)
    return values.length ? values.join('\n') : JSON.stringify(raw)
  }

  const text = String(raw ?? '')
  if (contentType.includes('application/x-www-form-urlencoded')) {
    const params = new URLSearchParams(text)
    const values = [
      params.get('notificationText'),
      params.get('screenText'),
      params.get('transactionText'),
      params.get('message'),
      params.get('text'),
      params.get('body'),
      params.get('title'),
    ].filter((value): value is string => typeof value === 'string' && value.length > 0)
    if (values.length) return values.join('\n')
  }
  return text
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method not allowed' }), { status: 405 })
  }

  if (!PAYMENT_WEBHOOK_SECRET || req.headers.get('x-payment-secret') !== PAYMENT_WEBHOOK_SECRET) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401 })
  }

  const contentType = req.headers.get('content-type') || ''
  let rawBody: unknown
  try {
    rawBody = contentType.includes('application/json') ? await req.json() : await req.text()
  } catch {
    rawBody = ''
  }

  const notificationText = bodyToText(rawBody, contentType).replace(/\s+/g, ' ').trim().slice(0, 1200)
  if (!notificationText) {
    return new Response(JSON.stringify({ error: 'empty notification' }), { status: 400 })
  }

  const currency = detectCurrency(notificationText)
  const amount = extractPaymentAmount(notificationText, currency)
  if (!amount) {
    return new Response(JSON.stringify({ error: 'no amount found', notificationText }), { status: 400 })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
  const { data, error } = await supabase.rpc('confirm_shamcash_payment_by_amount', {
    match_amount: amount,
    match_currency: currency,
    notification_text: notificationText,
  })

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  const matched = Boolean((data as { matched?: boolean } | null)?.matched)
  return new Response(JSON.stringify(data), { status: matched ? 200 : 404 })
})
