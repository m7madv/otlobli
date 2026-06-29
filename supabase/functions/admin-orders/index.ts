import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const WHATSAPP_SERVER_URL = Deno.env.get('WHATSAPP_SERVER_URL') ?? ''
const DRIVER_URL = Deno.env.get('DRIVER_URL') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'GET, PATCH, DELETE, OPTIONS',
}

const ORDER_STATUS_LABELS = [
  'بانتظار الدفع',
  'تم الدفع',
  'قيد الشراء',
  'تم الشراء',
  'في الطريق إلى مركز التجميع',
  'وصل مركز التجميع',
  'قيد الشحن إلى سوريا',
  'مع القدموس',
  'جاهز للاستلام',
  'تم التسليم',
]

async function notifyCustomerStatusChange(
  phone: string,
  order: { id: string; statusIndex: number; qadmousNumber?: string },
) {
  if (!WHATSAPP_SERVER_URL || !phone) return
  const label = ORDER_STATUS_LABELS[order.statusIndex] ?? ''
  const lines = [`📦 *تحديث على طلبك ${order.id}*`, `الحالة الجديدة: ${label}`]
  if (order.statusIndex === ORDER_STATUS_LABELS.length - 1) {
    lines.push('', 'بانتظارك لاستلام طلبك 🎉')
  } else if (order.qadmousNumber) {
    lines.push(`رقم القدموس: ${order.qadmousNumber}`)
  }

  try {
    await fetch(`${WHATSAPP_SERVER_URL}/api/notify/whatsapp`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ phone, text: lines.join('\n') }),
      signal: AbortSignal.timeout(8000),
    })
  } catch (err) {
    console.error('status change whatsapp failed:', (err as Error).message, order.id)
  }
}

async function notifyCustomerPaymentIssue(
  phone: string,
  order: { id: string; note: string; extraAmountUsd: number },
) {
  if (!WHATSAPP_SERVER_URL || !phone) return
  const lines = [
    `⚠️ *مشكلة بالدفع على طلبك ${order.id}*`,
    order.note || 'يوجد فرق بسعر إحدى القطع.',
  ]
  if (order.extraAmountUsd > 0) {
    lines.push(`المبلغ المتبقي: $${order.extraAmountUsd.toFixed(2)}`)
  }
  lines.push('', 'افتح التطبيق وتابع التفاصيل من صفحة طلباتي.')

  try {
    await fetch(`${WHATSAPP_SERVER_URL}/api/notify/whatsapp`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ phone, text: lines.join('\n') }),
      signal: AbortSignal.timeout(8000),
    })
  } catch (err) {
    console.error('payment issue whatsapp failed:', (err as Error).message, order.id)
  }
}

async function notifyDriverAssignment(
  driverPhone: string,
  driverName: string,
  order: { id: string; customer: string; phone: string; city: string; address: string; itemCount: number },
) {
  if (!WHATSAPP_SERVER_URL) return
  const text = [
    `📦 *طلب جديد مكلَّف لك — ${order.id}*`,
    `👤 ${order.customer}  |  📞 ${order.phone}`,
    `📍 ${order.city} — ${order.address}`,
    `🧾 عدد القطع: ${order.itemCount}`,
    '',
    DRIVER_URL ? `افتح بوابة السواق: ${DRIVER_URL}/?order=${order.id}` : '',
  ].filter(Boolean).join('\n')

  try {
    await fetch(`${WHATSAPP_SERVER_URL}/api/notify/whatsapp`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ phone: driverPhone, text }),
      signal: AbortSignal.timeout(8000),
    })
  } catch (err) {
    console.error('driver assignment whatsapp failed:', (err as Error).message, driverName)
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const pin = req.headers.get('x-admin-pin')
  if (!ADMIN_PIN || pin !== ADMIN_PIN) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // GET — جلب الطلبات + قائمة السواقين الفعّالين
  if (req.method === 'GET') {
    const [{ data, error }, { data: driverRows, error: driverError }] = await Promise.all([
      supabase
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', { ascending: false })
        .limit(500),
      supabase
        .from('drivers')
        .select('id, name')
        .eq('is_active', true)
        .order('name', { ascending: true }),
    ])

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const orders = (data || []).map((row: any) => ({
      id: row.id,
      customer: row.customer_name || row.customer || '',
      phone: row.phone,
      city: row.city,
      address: row.address,
      items: (row.order_items || []).map((item: any) => ({
        id: item.id,
        title: item.title,
        image: item.image,
        color: item.color,
        size: item.size,
        quantity: item.quantity,
        priceSyp: item.price_syp,
        sourceLink: item.source_link,
      })),
      total: row.total_syp ?? row.total ?? 0,
      paymentStatus: row.payment_status,
      statusIndex: row.status_index ?? 0,
      qadmousNumber: row.qadmous_number || '',
      createdAt: row.created_at,
      paidAt: row.paid_at,
      assignedDriverId: row.assigned_driver_id || '',
      rating: row.rating || undefined,
      ratingNote: row.rating_note || '',
      paymentIssue: row.payment_issue || false,
      paymentIssueNote: row.payment_issue_note || '',
      extraAmountUsd: row.extra_amount_usd || 0,
    }))

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const drivers = driverError ? [] : (driverRows || []).map((row: any) => ({ id: row.id, name: row.name }))

    return new Response(JSON.stringify({ orders, drivers }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // PATCH — تحديث طلب
  if (req.method === 'PATCH') {
    const { orderId, patch } = await req.json() as {
      orderId: string
      patch: Record<string, unknown>
    }

    if (!orderId || !patch) {
      return new Response(JSON.stringify({ error: 'missing_fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    // ملاحظة: جدول orders لا يحتوي على عمود updated_at، فلا نضيفه هنا
    const dbPatch: Record<string, unknown> = {}
    if (patch.paymentStatus !== undefined) dbPatch.payment_status = patch.paymentStatus
    if (patch.statusIndex !== undefined) dbPatch.status_index = patch.statusIndex
    if (patch.qadmousNumber !== undefined) dbPatch.qadmous_number = patch.qadmousNumber
    if (patch.paidAt !== undefined) dbPatch.paid_at = patch.paidAt
    if (patch.paymentIssue !== undefined) dbPatch.payment_issue = Boolean(patch.paymentIssue)
    if (patch.paymentIssueNote !== undefined) dbPatch.payment_issue_note = String(patch.paymentIssueNote || '')
    if (patch.extraAmountUsd !== undefined) dbPatch.extra_amount_usd = Number(patch.extraAmountUsd) || 0

    let previousPaymentIssue: boolean | null = null
    if (patch.paymentIssue !== undefined) {
      const { data } = await supabase.from('orders').select('payment_issue').eq('id', orderId).single()
      previousPaymentIssue = data?.payment_issue ?? false
    }

    const assigningDriverId = patch.assignedDriverId !== undefined ? String(patch.assignedDriverId || '') : null
    if (assigningDriverId !== null) {
      dbPatch.assigned_driver_id = assigningDriverId || null
      dbPatch.assigned_at = assigningDriverId ? new Date().toISOString() : null
    }

    const newStatusIndex = typeof patch.statusIndex === 'number' ? patch.statusIndex : null
    let previousOrder: { phone: string; status_index: number } | null = null
    if (newStatusIndex !== null) {
      const { data } = await supabase.from('orders').select('phone, status_index').eq('id', orderId).single()
      previousOrder = data
    }

    const { error } = await supabase.from('orders').update(dbPatch).eq('id', orderId)

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    if (newStatusIndex !== null && previousOrder && previousOrder.status_index !== newStatusIndex) {
      await supabase.from('order_events').insert({
        order_id: orderId,
        status_index: newStatusIndex,
        title: ORDER_STATUS_LABELS[newStatusIndex] ?? '',
        note: '',
      })

      await notifyCustomerStatusChange(previousOrder.phone, {
        id: orderId,
        statusIndex: newStatusIndex,
        qadmousNumber: typeof patch.qadmousNumber === 'string' ? patch.qadmousNumber : undefined,
      })
    }

    if (patch.paymentIssue === true && previousPaymentIssue === false) {
      const { data: order } = await supabase.from('orders').select('phone').eq('id', orderId).single()
      if (order?.phone) {
        await notifyCustomerPaymentIssue(order.phone, {
          id: orderId,
          note: typeof patch.paymentIssueNote === 'string' ? patch.paymentIssueNote : '',
          extraAmountUsd: Number(patch.extraAmountUsd) || 0,
        })
      }
    }

    if (assigningDriverId) {
      const [{ data: driver }, { data: order }, { data: items }] = await Promise.all([
        supabase.from('drivers').select('name, phone').eq('id', assigningDriverId).single(),
        supabase.from('orders').select('customer_name, phone, city, address, status_index').eq('id', orderId).single(),
        supabase.from('order_items').select('id').eq('order_id', orderId),
      ])

      if (driver && order) {
        await supabase.from('order_events').insert({
          order_id: orderId,
          status_index: order.status_index ?? 0,
          title: `تم تكليف السواق ${driver.name}`,
          note: '',
        })

        await notifyDriverAssignment(driver.phone, driver.name, {
          id: orderId,
          customer: order.customer_name,
          phone: order.phone,
          city: order.city,
          address: order.address,
          itemCount: (items || []).length,
        })
      }
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // DELETE — حذف طلب (وبنوده عبر ON DELETE CASCADE)
  if (req.method === 'DELETE') {
    const { orderId } = await req.json() as { orderId: string }

    if (!orderId) {
      return new Response(JSON.stringify({ error: 'missing_order_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const { error } = await supabase.from('orders').delete().eq('id', orderId)

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ error: 'method not allowed' }), {
    status: 405,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })
})
