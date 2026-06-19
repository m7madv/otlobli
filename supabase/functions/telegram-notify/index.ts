const BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN') ?? ''
const CHAT_ID = Deno.env.get('TELEGRAM_CHAT_ID') ?? ''
const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'POST, PUT, OPTIONS',
}

async function sendTelegram(order: Record<string, unknown>) {
  if (!BOT_TOKEN || !CHAT_ID) return
  const items = (order.items as Array<Record<string, unknown>>) || []
  const itemLines = items
    .map((i) => `  * ${i.title} - ${i.color || ''} / ${i.size || ''} x ${i.quantity}`)
    .join('\n')
  const total = ((order.total as number) || 0).toLocaleString('ar-SY')
  const text = [
    `طلب جديد - ${order.id}`,
    `العميل: ${order.customer} | هاتف: ${order.phone}`,
    `العنوان: ${order.city} - ${order.address}`,
    '',
    'المنتجات:',
    itemLines,
    '',
    `الاجمالي: ${total} ل.س`,
    'تم الدفع',
  ].join('\n')
  await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ chat_id: CHAT_ID, text }),
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors })

  if (req.method === 'POST') {
    const pin = req.headers.get('x-admin-pin')
    if (!ADMIN_PIN || pin !== ADMIN_PIN) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers: cors })
    }
    const { order } = (await req.json()) as { order: Record<string, unknown> }
    if (!order?.id)
      return new Response(JSON.stringify({ error: 'missing_order' }), { status: 400, headers: cors })
    await sendTelegram(order)
    return new Response(JSON.stringify({ ok: true }), { headers: cors })
  }

  // Database Webhook من Supabase عند تغيير payment_status
  if (req.method === 'PUT') {
    const payload = (await req.json()) as { record: Record<string, unknown> }
    const record = payload?.record
    if (record?.payment_status === 'مدفوع') {
      const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
      const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
      const { data } = await supabase.from('orders').select('*').eq('id', record.id).single()
      if (data) await sendTelegram(data)
    }
    return new Response(JSON.stringify({ ok: true }), { headers: cors })
  }

  return new Response(JSON.stringify({ error: 'method not allowed' }), { status: 405, headers: cors })
})
