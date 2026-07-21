import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const WHATSAPP_SERVER_URL = Deno.env.get('WHATSAPP_SERVER_URL') ?? ''
const ORDER_NOTIFY_SECRET = Deno.env.get('ORDER_NOTIFY_SECRET') ?? ''
const DRIVER_URL = Deno.env.get('DRIVER_URL') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
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

type OrderItemRow = {
  id: string
  product_id?: string
  title: string
  image: string
  color: string
  size: string
  quantity: number
  price_syp: number
  source_link: string
  custom_text?: string
  custom_photo?: string
  custom_photo_note?: string
  owner_member_key?: string
  owner_phone?: string
  owner_name?: string
}

type OrderRow = {
  id: string
  customer_name?: string
  customer?: string
  phone: string
  city: string
  address: string
  order_items?: OrderItemRow[]
  total_syp?: number
  total?: number
  payment_status: string
  status_index?: number
  qadmous_number?: string
  created_at: string
  paid_at?: string
  assigned_driver_id?: string
  rating?: number
  rating_note?: string
  payment_issue?: boolean
  payment_issue_note?: string
  extra_amount_usd?: number
  invoice?: { label: string; amountUsd: number }[]
  issues?: Record<string, unknown>[]
  group_id?: string
  group_code?: string
  delivery_member_key?: string
  delivery_owner_phone?: string
  delivery_owner_name?: string
}

type DriverRow = {
  id: string
  name: string
}

type WalletRow = {
  customer_id: string
  amount_syp: number
}

type CustomerRow = {
  id: string
  phone: string
  name?: string
  governorate?: string
  city?: string
  qadmous_branch?: string
  details?: string
  blocked?: boolean
  created_at?: string
  updated_at?: string
}

function normalizeOrderIssues(value: unknown, itemOwners = new Map<string, OrderItemRow>()) {
  const raw = Array.isArray(value) ? value : []
  const issues = raw
    .filter((issue): issue is Record<string, unknown> => !!issue && typeof issue === 'object')
    .map((issue) => {
      const itemId = String(issue.itemId ?? '').slice(0, 200)
      const owner = itemOwners.get(itemId)
      const requestPhoto = issue.requestPhoto === true || issue.responseType === 'image'
      return {
        id: String(issue.id ?? '').slice(0, 120),
        type: String(issue.type ?? 'other').slice(0, 40),
        itemId,
        note: String(issue.note ?? '').slice(0, 500),
        options: Array.isArray(issue.options)
          ? issue.options.map((option) => String(option).trim().slice(0, 120)).filter(Boolean).slice(0, 20)
          : [],
        requiredSize: String(issue.requiredSize ?? '').slice(0, 120),
        amountUsd: Math.max(0, Math.round((Number(issue.amountUsd) || 0) * 100) / 100),
        requestPhoto,
        responseType: requestPhoto ? 'image' : (issue.responseType === 'option' ? 'option' : 'text'),
        ownerMemberKey: owner?.owner_member_key || '',
        ownerPhone: owner?.owner_phone || '',
        ownerName: owner?.owner_name || '',
        resolved: issue.resolved === true,
        resolvedValue: String(issue.resolvedValue ?? '').slice(0, 2000),
        resolvedPhotoDataUrl: String(issue.resolvedPhotoDataUrl ?? '').slice(0, 4_000_000),
      }
    })
    .filter((issue) => issue.id !== '')
  const unresolved = issues.filter((issue) => !issue.resolved)
  const paymentTotal = unresolved
    .filter((issue) => issue.type === 'payment')
    .reduce((sum, issue) => sum + issue.amountUsd, 0)
  const note = unresolved
    .map((issue) => issue.note || issue.type)
    .filter(Boolean)
    .join('\n')
    .slice(0, 2000)
  return {
    issues,
    paymentIssue: unresolved.length > 0,
    paymentIssueNote: note,
    extraAmountUsd: Math.round(paymentTotal * 100) / 100,
  }
}

function mergeIssueDrafts(incoming: unknown, current: unknown) {
  const incomingList = Array.isArray(incoming) ? incoming : []
  const currentList = Array.isArray(current)
    ? current.filter((issue): issue is Record<string, unknown> => !!issue && typeof issue === 'object')
    : []
  const currentById = new Map(currentList.map((issue) => [String(issue.id ?? ''), issue]))
  const incomingIds = new Set<string>()
  const merged = incomingList.map((issue) => {
    const record = (issue && typeof issue === 'object' ? issue : {}) as Record<string, unknown>
    const id = String(record.id ?? '')
    incomingIds.add(id)
    const currentIssue = currentById.get(id)
    if (currentIssue?.resolved === true && record.resolved !== true) {
      return { ...record, resolved: true, resolvedValue: currentIssue.resolvedValue ?? '' }
    }
    return record
  })
  currentList.forEach((issue) => {
    const id = String(issue.id ?? '')
    if (id && issue.resolved === true && !incomingIds.has(id)) merged.push(issue)
  })
  return merged
}

async function notifyCustomerStatusChange(
  phone: string,
  order: { id: string; statusIndex: number; qadmousNumber?: string },
) {
  if (!WHATSAPP_SERVER_URL || !ORDER_NOTIFY_SECRET || !phone) return
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
      headers: { 'content-type': 'application/json', 'x-service-secret': ORDER_NOTIFY_SECRET },
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
  if (!WHATSAPP_SERVER_URL || !ORDER_NOTIFY_SECRET || !phone) return
  const lines = [
    `⚠️ *طلبك ${order.id} يحتاج إجراء منك*`,
    order.note || 'يوجد تفصيل يحتاج مراجعتك قبل متابعة الطلب.',
  ]
  if (order.extraAmountUsd > 0) {
    lines.push(`المبلغ المطلوب إضافياً: $${order.extraAmountUsd.toFixed(2)}`)
  }
  lines.push('', 'افتح التطبيق من صفحة طلباتي لمراجعة التفاصيل وإكمال المطلوب.')

  try {
    await fetch(`${WHATSAPP_SERVER_URL}/api/notify/whatsapp`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-service-secret': ORDER_NOTIFY_SECRET },
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
  if (!WHATSAPP_SERVER_URL || !ORDER_NOTIFY_SECRET) return
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
      headers: { 'content-type': 'application/json', 'x-service-secret': ORDER_NOTIFY_SECRET },
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
    const [
      { data, error },
      { data: driverRows, error: driverError },
      { data: customerRows, error: customerError },
      { data: walletRows },
    ] = await Promise.all([
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
      supabase
        .from('customers')
        .select('id, phone, name, governorate, city, qadmous_branch, details, blocked, created_at, updated_at')
        .order('updated_at', { ascending: false })
        .limit(500),
      supabase
        .from('wallet_transactions')
        .select('customer_id, amount_syp'),
    ])

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const orders = ((data || []) as OrderRow[]).map((row) => ({
      id: row.id,
      customer: row.customer_name || row.customer || '',
      phone: row.phone,
      city: row.city,
      address: row.address,
      items: (row.order_items || []).map((item) => ({
        // Use the order-item UUID for admin actions so two members ordering
        // the same vendor product can still receive separate, owner-scoped
        // issues. Customer payloads also expose this as orderItemId.
        id: item.id,
        title: item.title,
        image: item.image,
        color: item.color,
        size: item.size,
        quantity: item.quantity,
        priceSyp: item.price_syp,
        sourceLink: item.source_link,
        customText: item.custom_text || '',
        customPhotoDataUrl: item.custom_photo || '',
        customPhotoNote: item.custom_photo_note || '',
        ownerMemberKey: item.owner_member_key || '',
        ownerPhone: item.owner_phone || '',
        ownerName: item.owner_name || '',
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
      invoice: Array.isArray(row.invoice) ? row.invoice : [],
      issues: Array.isArray(row.issues) ? row.issues : [],
      groupId: row.group_id || '',
      groupCode: row.group_code || '',
      deliveryMemberKey: row.delivery_member_key || '',
      deliveryOwnerPhone: row.delivery_owner_phone || '',
      deliveryOwnerName: row.delivery_owner_name || '',
    }))

    const drivers = driverError ? [] : ((driverRows || []) as DriverRow[]).map((row) => ({ id: row.id, name: row.name }))

    const walletByCustomer = new Map<string, number>()
    ;((walletRows || []) as WalletRow[]).forEach((row) => {
      const key = String(row.customer_id || '')
      walletByCustomer.set(key, (walletByCustomer.get(key) || 0) + (Number(row.amount_syp) || 0))
    })

    const statsByPhone = new Map<string, { orderCount: number; totalSpentSyp: number; lastOrderAt: string }>()
    orders.forEach((order) => {
      const prev = statsByPhone.get(order.phone) || { orderCount: 0, totalSpentSyp: 0, lastOrderAt: '' }
      prev.orderCount += 1
      prev.totalSpentSyp += Number(order.total) || 0
      prev.lastOrderAt = prev.lastOrderAt && prev.lastOrderAt > order.createdAt ? prev.lastOrderAt : order.createdAt
      statsByPhone.set(order.phone, prev)
    })

    const customers = customerError ? [] : ((customerRows || []) as CustomerRow[]).map((row) => {
      const stats = statsByPhone.get(row.phone) || { orderCount: 0, totalSpentSyp: 0, lastOrderAt: '' }
      return {
        id: row.id,
        phone: row.phone,
        name: row.name || '',
        governorate: row.governorate || '',
        city: row.city || '',
        qadmousBranch: row.qadmous_branch || '',
        details: row.details || '',
        blocked: row.blocked === true,
        walletBalanceSyp: walletByCustomer.get(row.id) || 0,
        orderCount: stats.orderCount,
        totalSpentSyp: stats.totalSpentSyp,
        lastOrderAt: stats.lastOrderAt,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      }
    })

    return new Response(JSON.stringify({ orders, drivers, customers }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // PATCH — تحديث طلب
  if (req.method === 'POST') {
    const body = await req.json() as {
      action?: string
      phone?: string
      name?: string
      amountSyp?: number
      kind?: string
      note?: string
      orderId?: string
      blocked?: boolean
    }

    // حظر/فك حظر مستخدم: تحديث مباشر لعمود blocked عبر الرقم (لا يمرّ عبر
    // ensure_customer لأنها ترفض المحظورين). المحظور يُمنع لاحقاً من الدخول
    // والطلب مركزياً داخل ensure_customer.
    if (body.action === 'set_blocked') {
      const targetPhone = String(body.phone || '').replace(/\s+/g, '')
      if (!targetPhone) {
        return new Response(JSON.stringify({ error: 'missing_phone' }), {
          status: 400,
          headers: { ...corsHeaders, 'content-type': 'application/json' },
        })
      }
      const { error: blockError } = await supabase
        .from('customers')
        .update({ blocked: body.blocked === true, updated_at: new Date().toISOString() })
        .eq('phone', targetPhone)
      if (blockError) {
        return new Response(JSON.stringify({ error: blockError.message }), {
          status: 500,
          headers: { ...corsHeaders, 'content-type': 'application/json' },
        })
      }
      return new Response(JSON.stringify({ ok: true, blocked: body.blocked === true }), {
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    if (body.action !== 'wallet_transaction') {
      return new Response(JSON.stringify({ error: 'unknown_action' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const phone = String(body.phone || '').replace(/\s+/g, '')
    const amountSyp = Math.trunc(Number(body.amountSyp) || 0)
    if (!phone || amountSyp === 0) {
      return new Response(JSON.stringify({ error: 'missing_wallet_fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const { data: customerId, error: customerError } = await supabase.rpc('ensure_customer', {
      p_phone: phone,
      p_name: String(body.name || ''),
      p_governorate: 'دمشق',
      p_qadmous_branch: '',
      p_city: '',
      p_details: '',
    })

    if (customerError || !customerId) {
      return new Response(JSON.stringify({ error: customerError?.message || 'customer_error' }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const { error: txError } = await supabase.from('wallet_transactions').insert({
      customer_id: customerId,
      phone,
      order_id: body.orderId || null,
      amount_syp: amountSyp,
      amount_usd: 0,
      kind: body.kind || 'manual_adjustment',
      note: String(body.note || ''),
      created_by: 'admin',
    })

    if (txError) {
      return new Response(JSON.stringify({ error: txError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

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
    let currentStructuredIssues: unknown[] = []
    let issueItems: OrderItemRow[] = []
    let normalizedIssueState: ReturnType<typeof normalizeOrderIssues> | null = null
    if (patch.issues !== undefined) {
      const { data: currentOrder } = await supabase
        .from('orders')
        .select('issues, order_items(id, product_id, owner_member_key, owner_phone, owner_name)')
        .eq('id', orderId)
        .single()
      currentStructuredIssues = Array.isArray(currentOrder?.issues) ? currentOrder.issues : []
      issueItems = Array.isArray(currentOrder?.order_items) ? currentOrder.order_items as OrderItemRow[] : []
    }
    if (patch.paymentStatus !== undefined) {
      const paymentStatus = String(patch.paymentStatus)
      const paidAt = typeof patch.paidAt === 'string' && patch.paidAt ? patch.paidAt : null
      const { error: paymentError } = await supabase.rpc('admin_set_order_payment_status', {
        p_order_id: orderId,
        p_payment_status: paymentStatus,
        p_paid_at: paidAt,
      })
      if (paymentError) {
        return new Response(JSON.stringify({ error: paymentError.message }), {
          status: 400,
          headers: { ...corsHeaders, 'content-type': 'application/json' },
        })
      }
    }
    if (patch.statusIndex !== undefined) dbPatch.status_index = patch.statusIndex
    if (patch.qadmousNumber !== undefined) dbPatch.qadmous_number = patch.qadmousNumber
    if (patch.paidAt !== undefined && patch.paymentStatus === undefined) dbPatch.paid_at = patch.paidAt
    if (patch.paymentIssue !== undefined && patch.issues === undefined) dbPatch.payment_issue = Boolean(patch.paymentIssue)
    if (patch.paymentIssueNote !== undefined && patch.issues === undefined) dbPatch.payment_issue_note = String(patch.paymentIssueNote || '')
    if (patch.extraAmountUsd !== undefined && patch.issues === undefined) dbPatch.extra_amount_usd = Number(patch.extraAmountUsd) || 0
    // مشاكل الطلب المنظمة: نحفظ المصفوفة كما هي (الواجهة تبنيها منقّاة).
    if (patch.issues !== undefined) {
      const itemOwners = new Map<string, OrderItemRow>()
      issueItems.forEach((item) => {
        itemOwners.set(item.id, item)
        if (item.product_id && !itemOwners.has(item.product_id)) itemOwners.set(item.product_id, item)
      })
      const issueState = normalizeOrderIssues(mergeIssueDrafts(patch.issues, currentStructuredIssues), itemOwners)
      normalizedIssueState = issueState
      dbPatch.issues = issueState.issues
      dbPatch.payment_issue = issueState.paymentIssue
      dbPatch.payment_issue_note = issueState.paymentIssueNote
      dbPatch.extra_amount_usd = issueState.extraAmountUsd
    }
    // فاتورة الطلب: بنود {label, amountUsd} فقط — ننقّي الشكل قبل الحفظ.
    if (patch.invoice !== undefined) {
      dbPatch.invoice = Array.isArray(patch.invoice)
        ? patch.invoice
          .map((line) => {
            const rec = (line && typeof line === 'object' ? line : {}) as Record<string, unknown>
            return {
              label: String(rec.label ?? '').slice(0, 120),
              amountUsd: Math.round((Number(rec.amountUsd) || 0) * 100) / 100,
            }
          })
          .filter((line) => line.label.trim() !== '')
        : []
    }

    let previousPaymentIssue: boolean | null = null
    if (patch.paymentIssue !== undefined || patch.issues !== undefined) {
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

    const { error } = Object.keys(dbPatch).length > 0
      ? await supabase.from('orders').update(dbPatch).eq('id', orderId)
      : { error: null }

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

    if (Boolean(dbPatch.payment_issue) && (previousPaymentIssue === false || normalizedIssueState)) {
      const existingIds = new Set(currentStructuredIssues.map((issue) => String((issue as Record<string, unknown>)?.id ?? '')))
      const newIssues = normalizedIssueState?.issues.filter((issue) => !issue.resolved && !existingIds.has(issue.id)) ?? []
      const { data: order } = await supabase.from('orders').select('phone').eq('id', orderId).single()
      // Structured saves notify only genuinely new issue IDs. Re-saving an
      // existing draft must not spam every unresolved group member again.
      const issuesToNotify = normalizedIssueState ? newIssues : []
      const recipientPhones = new Set(issuesToNotify.map((issue) => issue.ownerPhone || order?.phone || '').filter(Boolean))
      if (!normalizedIssueState && previousPaymentIssue === false && order?.phone) recipientPhones.add(order.phone)
      for (const recipientPhone of recipientPhones) {
        const recipientIssues = issuesToNotify.filter((issue) => (issue.ownerPhone || order?.phone || '') === recipientPhone)
        await notifyCustomerPaymentIssue(recipientPhone, {
          id: orderId,
          note: recipientIssues.map((issue) => issue.note || issue.type).filter(Boolean).join('\n') || String(dbPatch.payment_issue_note || ''),
          extraAmountUsd: recipientIssues.filter((issue) => issue.type === 'payment').reduce((sum, issue) => sum + issue.amountUsd, 0)
            || Number(dbPatch.extra_amount_usd) || 0,
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
