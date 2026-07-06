const BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN') ?? ''
const CHAT_ID = Deno.env.get('TELEGRAM_CHAT_ID') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const ADMIN_APP_URL = (Deno.env.get('ADMIN_APP_URL') ?? 'https://talabieh-admin.vercel.app').replace(/\/+$/, '')

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'POST, PUT, OPTIONS',
}

type OrderPayload = {
  id?: string
  customer?: string
  phone?: string
  city?: string
  address?: string
  total?: number
  paymentStatus?: string
  paymentAmount?: number
  paymentCurrency?: string
  paymentExpiresAt?: string
  items?: Array<Record<string, unknown>>
}

function formatMoney(value: number) {
  return `${(value || 0).toLocaleString('ar-SY')} ل.س`
}

function formatPaymentAmount(order: OrderPayload) {
  if (typeof order.paymentAmount !== 'number') return ''
  if (order.paymentCurrency === 'USD') return `${order.paymentAmount.toFixed(2)} USD`
  if (order.paymentCurrency === 'EUR') return `${order.paymentAmount.toFixed(2)} EUR`
  return formatMoney(Math.round(order.paymentAmount))
}

function buildAdminLink(orderId: string) {
  return `${ADMIN_APP_URL}/?order=${encodeURIComponent(orderId)}`
}

function buildOrderMessage(order: OrderPayload) {
  const orderId = String(order.id || '')
  const isPaid = order.paymentStatus === 'مدفوع'
  const itemsCount = Array.isArray(order.items) ? order.items.length : 0
  const paymentAmount = formatPaymentAmount(order)
  const lines = [
    isPaid ? `تم تأكيد الدفع للطلب ${orderId}` : `طلب جديد بانتظار الدفع ${orderId}`,
    `العميل: ${order.customer || 'عميل otlobli'}`,
    `الهاتف: ${order.phone || 'غير محدد'}`,
    `الاستلام: ${(order.city || 'غير محدد')} - ${(order.address || 'بدون تفاصيل')}`,
    `عدد المنتجات: ${itemsCount}`,
    `إجمالي الطلب: ${formatMoney(Number(order.total || 0))}`,
  ]

  if (paymentAmount) {
    lines.push(`المبلغ المطلوب: ${paymentAmount}`)
  }

  if (order.paymentExpiresAt) {
    lines.push(`انتهاء المهلة: ${order.paymentExpiresAt}`)
  }

  if (!isPaid) {
    lines.push('تأكد إذا وصلك الدفع قبل اعتماد الطلب.')
  }

  lines.push(`لوحة الإدارة: ${buildAdminLink(orderId)}`)
  return lines.join('\n')
}

async function sendTelegram(text: string) {
  if (!BOT_TOKEN || !CHAT_ID || !text.trim()) return
  await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      chat_id: CHAT_ID,
      text,
      disable_web_page_preview: true,
    }),
  })
}

async function fetchOrderFromDb(orderId: string) {
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY || !orderId) return null
  const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
  const { data } = await supabase.from('orders').select('*, order_items(*)').eq('id', orderId).single()
  if (!data) return null
  return {
    id: data.id,
    customer: data.customer_name,
    phone: data.phone,
    city: data.city,
    address: data.address,
    total: data.total_syp,
    paymentStatus: data.payment_status,
    paymentAmount: data.payment_amount,
    paymentCurrency: data.payment_currency,
    paymentExpiresAt: data.payment_expires_at,
    items: data.order_items ?? [],
  } satisfies OrderPayload
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors })

  if (req.method === 'POST') {
    const { order } = (await req.json()) as { order?: OrderPayload }
    if (!order?.id) {
      return new Response(JSON.stringify({ error: 'missing_order' }), {
        status: 400,
        headers: { ...cors, 'content-type': 'application/json' },
      })
    }

    await sendTelegram(buildOrderMessage(order))
    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...cors, 'content-type': 'application/json' },
    })
  }

  if (req.method === 'PUT') {
    const payload = (await req.json()) as { record?: { id?: string; payment_status?: string } }
    const record = payload?.record
    if (record?.id && record.payment_status === 'مدفوع') {
      const order = await fetchOrderFromDb(record.id)
      if (order) await sendTelegram(buildOrderMessage(order))
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...cors, 'content-type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ error: 'method not allowed' }), {
    status: 405,
    headers: { ...cors, 'content-type': 'application/json' },
  })
})
