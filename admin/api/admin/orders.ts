import { createClient } from '@supabase/supabase-js'

declare const process: {
  env: Record<string, string | undefined>
}

type PaymentStatus = 'بانتظار الدفع' | 'مدفوع' | 'فشل المطابقة'

type CartItem = {
  id: string
  title: string
  image: string
  color: string
  size: string
  quantity: number
  priceSyp: number
  sourceLink: string
}

type Order = {
  id: string
  customer: string
  phone: string
  city: string
  address: string
  items: CartItem[]
  total: number
  paymentStatus: PaymentStatus
  statusIndex: number
  qadmousNumber: string
  createdAt: string
  paidAt?: string
}

type RequestLike = {
  method?: string
  headers: Record<string, string | string[] | undefined>
  body?: unknown
}

type ResponseLike = {
  status: (code: number) => ResponseLike
  json: (body: unknown) => void
  setHeader: (name: string, value: string) => void
}

type OrderItemRow = {
  product_id: string
  title: string
  image: string
  color: string
  size: string
  quantity: number
  price_syp: number
  source_link: string
}

type OrderRow = {
  id: string
  customer_name: string
  phone: string
  city: string
  address: string
  total_syp: number
  payment_status: PaymentStatus
  status_index: number
  qadmous_number: string
  created_at: string
  paid_at: string | null
  order_items: OrderItemRow[] | null
}

type OrderPatchBody = {
  orderId?: unknown
  patch?: unknown
}

type OrderPatch = {
  paymentStatus?: PaymentStatus
  statusIndex?: number
  qadmousNumber?: string
  paidAt?: string
}

const adminOrderSelect = `
  id,
  customer_name,
  phone,
  city,
  address,
  total_syp,
  payment_status,
  status_index,
  qadmous_number,
  created_at,
  paid_at,
  order_items (
    product_id,
    title,
    image,
    color,
    size,
    quantity,
    price_syp,
    source_link
  )
`

function getHeader(request: RequestLike, name: string) {
  const value = request.headers[name] ?? request.headers[name.toLowerCase()]
  return Array.isArray(value) ? value[0] : value
}

function parseBody(body: unknown): OrderPatchBody {
  if (!body) {
    return {}
  }

  if (typeof body === 'string') {
    return JSON.parse(body) as OrderPatchBody
  }

  if (typeof body === 'object') {
    return body as OrderPatchBody
  }

  return {}
}

function toOrder(row: OrderRow): Order {
  return {
    id: row.id,
    customer: row.customer_name,
    phone: row.phone,
    city: row.city,
    address: row.address,
    total: row.total_syp,
    paymentStatus: row.payment_status,
    statusIndex: row.status_index,
    qadmousNumber: row.qadmous_number,
    createdAt: row.created_at,
    paidAt: row.paid_at ?? undefined,
    items: (row.order_items ?? []).map((item) => ({
      id: item.product_id,
      title: item.title,
      image: item.image,
      color: item.color,
      size: item.size,
      quantity: item.quantity,
      priceSyp: item.price_syp,
      sourceLink: item.source_link,
    })),
  }
}

function getSupabaseAdmin() {
  const supabaseUrl = process.env.VITE_SUPABASE_URL ?? process.env.SUPABASE_URL
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

  if (!supabaseUrl || !serviceRoleKey) {
    return null
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  })
}

function isAuthorized(request: RequestLike) {
  const adminPin = process.env.ADMIN_PIN
  const incomingPin = getHeader(request, 'x-admin-pin')

  return Boolean(adminPin && incomingPin && incomingPin === adminPin)
}

function normalizePatch(input: unknown) {
  if (!input || typeof input !== 'object') {
    return {}
  }

  const patch = input as OrderPatch
  const update: Record<string, string | number> = {}

  if (patch.paymentStatus) {
    update.payment_status = patch.paymentStatus
  }

  if (typeof patch.statusIndex === 'number') {
    update.status_index = patch.statusIndex
  }

  if (typeof patch.qadmousNumber === 'string') {
    update.qadmous_number = patch.qadmousNumber
  }

  if (typeof patch.paidAt === 'string') {
    update.paid_at = patch.paidAt
  }

  return update
}

export default async function handler(request: RequestLike, response: ResponseLike) {
  response.setHeader('Cache-Control', 'no-store')

  if (!isAuthorized(request)) {
    response.status(401).json({ error: 'unauthorized' })
    return
  }

  const supabase = getSupabaseAdmin()

  if (!supabase) {
    response.status(500).json({ error: 'admin_backend_not_configured' })
    return
  }

  if (request.method === 'GET') {
    const { data, error } = await supabase
      .from('orders')
      .select(adminOrderSelect)
      .order('created_at', { ascending: false })
      .limit(200)
      .returns<OrderRow[]>()

    if (error) {
      response.status(500).json({ error: error.message })
      return
    }

    response.status(200).json({ orders: (data ?? []).map(toOrder) })
    return
  }

  if (request.method === 'PATCH') {
    const body = parseBody(request.body)

    if (typeof body.orderId !== 'string') {
      response.status(400).json({ error: 'orderId_required' })
      return
    }

    const update = normalizePatch(body.patch)
    const { error } = await supabase.from('orders').update(update).eq('id', body.orderId)

    if (error) {
      response.status(500).json({ error: error.message })
      return
    }

    if (typeof update.status_index === 'number') {
      await supabase.from('order_events').insert({
        order_id: body.orderId,
        status_index: update.status_index,
        title: 'تحديث حالة الطلب',
        note: 'تم تحديث الطلب من لوحة الإدارة',
      })
    }

    response.status(200).json({ ok: true })
    return
  }

  response.status(405).json({ error: 'method_not_allowed' })
}
