const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || ''
const CHAT_ID = process.env.TELEGRAM_CHAT_ID || ''
const ADMIN_URL = process.env.ADMIN_URL || 'https://talabieh-admin.vercel.app'
const API = `https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`

export async function sendTelegramNotification(order) {
  if (!BOT_TOKEN || !CHAT_ID) return

  const itemLines = (order.items || [])
    .map((item) => `  • ${item.title} — ${item.color || ''} / ${item.size || ''} × ${item.quantity}`)
    .join('\n')

  const statusLabel = order.paymentStatus === 'مدفوع' ? '✅ مدفوع' : '⏳ بانتظار الدفع'
  const adminLink = `${ADMIN_URL}?order=${order.id}`

  const text = [
    `🛍 *طلب جديد — ${order.id}*`,
    `👤 ${order.customer}  |  📞 ${order.phone}`,
    `📍 ${order.city} — ${order.address}`,
    ``,
    `*المنتجات:*`,
    itemLines,
    ``,
    `💰 الإجمالي: ${order.total?.toLocaleString('ar-SY')} ل.س`,
    `${statusLabel}`,
    order.paidAt ? `🕒 وقت الدفع: ${order.paidAt}` : '',
    ``,
    `🔗 [افتح في لوحة الإدارة](${adminLink})`,
  ]
    .filter((l) => l !== undefined)
    .join('\n')

  try {
    const res = await fetch(API, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ chat_id: CHAT_ID, text, parse_mode: 'Markdown' }),
      signal: AbortSignal.timeout(8000),
    })
    if (!res.ok) {
      const body = await res.text()
      console.error('Telegram error:', res.status, body)
    } else {
      console.log('📨 Telegram notification sent for order', order.id)
    }
  } catch (err) {
    console.error('Telegram send failed:', err.message)
  }
}

export function isTelegramConfigured() {
  return !!(BOT_TOKEN && CHAT_ID)
}
