import { useEffect, useMemo, useState } from 'react'

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

type PaymentStatus = 'بانتظار الدفع' | 'مدفوع' | 'فشل المطابقة'

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
  assignedAt?: string
}

type OrdersResponse = {
  driverName: string
  orders: Order[]
}

const orderStatuses = [
  'بانتظار الدفع',
  'تم الدفع',
  'قيد الشراء',
  'تم الشراء',
  'في الطريق إلى الأردن',
  'وصل الأردن',
  'قيد الشحن إلى سوريا',
  'مع القدموس',
  'جاهز للاستلام',
  'تم التسليم',
]

function formatMoney(value: number) {
  return `${(value ?? 0).toLocaleString('ar-SY')} ل.س`
}

function Icon({ name }: { name: string }) {
  return <span className="material-symbols-outlined" aria-hidden="true">{name}</span>
}

const stripBom = (s: string | undefined) => (s || '').replace(/[​-‍﻿]/g, '').trim()
const SUPABASE_URL = stripBom(import.meta.env.VITE_SUPABASE_URL as string | undefined)
const DRIVER_ORDERS_FN = `${SUPABASE_URL}/functions/v1/driver-orders`
const ANON_KEY = stripBom(import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined)

const STORAGE_CODE = 'driver_login_code'
const STORAGE_LAST_SEEN = 'driver_last_seen_assigned_at'

async function fetchDriverOrders(code: string) {
  const response = await fetch(DRIVER_ORDERS_FN, {
    headers: {
      'x-driver-code': code,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
  })
  if (!response.ok) throw new Error('unauthorized')
  return (await response.json()) as OrdersResponse
}

async function patchDriverOrder(code: string, orderId: string, patch: Partial<Pick<Order, 'statusIndex' | 'qadmousNumber'>>) {
  const response = await fetch(DRIVER_ORDERS_FN, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      'x-driver-code': code,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({ orderId, patch }),
  })
  if (!response.ok) throw new Error('update_failed')
}

function CopyBtn({ text }: { text: string }) {
  const [copied, setCopied] = useState(false)
  const copy = () => {
    navigator.clipboard.writeText(text).then(() => {
      setCopied(true)
      setTimeout(() => setCopied(false), 1800)
    })
  }
  return (
    <button className="copy-btn" onClick={copy} title="نسخ">
      <Icon name={copied ? 'check' : 'content_copy'} />
    </button>
  )
}

type View = 'list' | 'print-single' | 'print-sheet'

function DriverApp() {
  const [codeInput, setCodeInput] = useState('')
  const [code, setCode] = useState('')
  const [driverName, setDriverName] = useState('')
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(false)
  const [notice, setNotice] = useState('')
  const [lastSeenAt, setLastSeenAt] = useState('')
  const [view, setView] = useState<View>('list')
  const [printOrderId, setPrintOrderId] = useState('')

  useEffect(() => {
    const savedCode = localStorage.getItem(STORAGE_CODE) || ''
    const savedSeen = localStorage.getItem(STORAGE_LAST_SEEN) || ''
    setLastSeenAt(savedSeen)
    if (savedCode) login(savedCode)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const showNotice = (message: string) => {
    setNotice(message)
    window.setTimeout(() => setNotice(''), 2200)
  }

  const login = (rawCode: string) => {
    const nextCode = rawCode.trim()
    if (!nextCode) { showNotice('أدخل رمز الدخول'); return }
    setLoading(true)
    void fetchDriverOrders(nextCode)
      .then(({ driverName: name, orders: nextOrders }) => {
        setCode(nextCode)
        setDriverName(name)
        setOrders(nextOrders)
        localStorage.setItem(STORAGE_CODE, nextCode)
        showNotice(`أهلاً ${name}`)
      })
      .catch(() => showNotice('رمز الدخول غير صحيح'))
      .finally(() => setLoading(false))
  }

  const logout = () => {
    localStorage.removeItem(STORAGE_CODE)
    setCode('')
    setDriverName('')
    setOrders([])
    setCodeInput('')
  }

  const refresh = () => {
    if (!code) return
    setLoading(true)
    void fetchDriverOrders(code)
      .then(({ orders: nextOrders }) => { setOrders(nextOrders); showNotice('تم التحديث') })
      .catch(() => showNotice('تعذر تحديث الطلبات'))
      .finally(() => setLoading(false))
  }

  // تحديث صامت كل 15 ثانية + نغمة تنبيه عند تكليف طلب جديد
  useEffect(() => {
    if (!code) return
    const interval = window.setInterval(() => {
      void fetchDriverOrders(code)
        .then(({ orders: nextOrders }) => {
          setOrders((prev) => {
            if (nextOrders.length > prev.length) {
              const diff = nextOrders.length - prev.length
              showNotice(`🔔 ${diff} طلب جديد مكلَّف لك`)
              try {
                const ctx = new (window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext)()
                const osc = ctx.createOscillator()
                const gain = ctx.createGain()
                osc.connect(gain); gain.connect(ctx.destination)
                osc.frequency.value = 880; gain.gain.value = 0.1
                osc.start(); osc.stop(ctx.currentTime + 0.18)
              } catch { /* الصوت غير حيوي */ }
            }
            return nextOrders
          })
        })
        .catch(() => undefined)
    }, 15000)
    return () => window.clearInterval(interval)
  }, [code])

  const unreadCount = useMemo(
    () => orders.filter((o) => o.assignedAt && o.assignedAt > lastSeenAt).length,
    [orders, lastSeenAt],
  )

  const markSeen = () => {
    const now = new Date().toISOString()
    setLastSeenAt(now)
    localStorage.setItem(STORAGE_LAST_SEEN, now)
  }

  const updateOrder = (orderId: string, patch: Partial<Pick<Order, 'statusIndex' | 'qadmousNumber'>>) => {
    setOrders((list) => list.map((o) => (o.id === orderId ? { ...o, ...patch } : o)))
    void patchDriverOrder(code, orderId, patch)
      .then(() => showNotice('تم التحديث'))
      .catch(() => { showNotice('فشل التحديث'); refresh() })
  }

  const advanceOrder = (order: Order) => {
    const statusIndex = Math.min(order.statusIndex + 1, orderStatuses.length - 1)
    updateOrder(order.id, { statusIndex })
  }

  const openPrintSingle = (orderId: string) => {
    setPrintOrderId(orderId)
    setView('print-single')
  }

  // ── شاشة تسجيل الدخول ──────────────────────────────────────────────────────
  if (!code) {
    return (
      <main className="login-shell">
        <section className="login-card">
          <div className="brand"><span>otlobli</span><small>بوابة السواق</small></div>
          <h1>تسجيل دخول السواق</h1>
          <p>أدخل رمز الدخول الذي وصلك على واتساب.</p>
          <label className="field">
            <span>رمز الدخول</span>
            <input
              value={codeInput}
              inputMode="numeric"
              autoComplete="one-time-code"
              onChange={(e) => setCodeInput(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') login(codeInput) }}
            />
          </label>
          <button className="primary-action" disabled={loading} onClick={() => login(codeInput)}>
            {loading ? 'جار التحقق...' : 'دخول'}
            <Icon name="lock_open" />
          </button>
          {notice && <p className="notice">{notice}</p>}
        </section>
      </main>
    )
  }

  // ── شاشة طباعة ملصق مفرد ───────────────────────────────────────────────────
  if (view === 'print-single') {
    const order = orders.find((o) => o.id === printOrderId)
    return (
      <div className="driver-shell">
        <div className="print-toolbar">
          <button className="ghost-action" onClick={() => setView('list')}><Icon name="arrow_forward" /> رجوع</button>
          <button className="primary-action" onClick={() => window.print()}><Icon name="print" /> طباعة</button>
        </div>
        {order && <SingleLabel order={order} />}
      </div>
    )
  }

  // ── شاشة طباعة ورقة A4 (كل الطلبات) ────────────────────────────────────────
  if (view === 'print-sheet') {
    return (
      <div className="driver-shell">
        <div className="print-toolbar">
          <button className="ghost-action" onClick={() => setView('list')}><Icon name="arrow_forward" /> رجوع</button>
          <button className="primary-action" onClick={() => window.print()}><Icon name="print" /> طباعة الورقة</button>
        </div>
        <div className="label-sheet">
          {orders.map((order) => <LabelCell key={order.id} order={order} />)}
        </div>
      </div>
    )
  }

  // ── الشاشة الرئيسية ─────────────────────────────────────────────────────────
  return (
    <div className="driver-shell">
      <header className="driver-topbar">
        <div className="brand"><span>otlobli</span><small>{driverName}</small></div>
        <div className="topbar-actions">
          <button className="icon-button notif-bell" onClick={markSeen} title="الإشعارات">
            <Icon name="notifications" />
            {unreadCount > 0 && <span className="notif-badge">{unreadCount > 9 ? '9+' : unreadCount}</span>}
          </button>
          <button className="icon-button" onClick={refresh} disabled={loading} title="تحديث">
            <Icon name="refresh" />
          </button>
          <button className="icon-button" onClick={logout} title="خروج">
            <Icon name="logout" />
          </button>
        </div>
      </header>

      {orders.length > 0 && (
        <div style={{ display: 'flex', justifyContent: 'center', padding: '12px 16px 0' }}>
          <button className="ghost-action" onClick={() => setView('print-sheet')}>
            <Icon name="print" /> طباعة ملصقات كل الطلبات (A4)
          </button>
        </div>
      )}

      {orders.length === 0 ? (
        <div className="empty-state">
          <Icon name="local_shipping" />
          <h2>ما عندك طلبات مكلَّفة حالياً</h2>
          <p>رح يوصلك إشعار واتساب وبيظهر هون فور ما الإدارة تكلفك بطلب.</p>
        </div>
      ) : (
        <div className="orders-list">
          {orders.map((order) => (
            <OrderCard
              key={order.id}
              order={order}
              onUpdate={updateOrder}
              onAdvance={advanceOrder}
              onPrintSingle={openPrintSingle}
            />
          ))}
        </div>
      )}

      {notice && <div className="toast">{notice}</div>}
    </div>
  )
}

// ── Order Card ────────────────────────────────────────────────────────────────
function OrderCard({
  order, onUpdate, onAdvance, onPrintSingle,
}: {
  order: Order
  onUpdate: (orderId: string, patch: Partial<Pick<Order, 'statusIndex' | 'qadmousNumber'>>) => void
  onAdvance: (order: Order) => void
  onPrintSingle: (orderId: string) => void
}) {
  const items = order.items ?? []
  return (
    <article className="order-card">
      <div className="order-card-header">
        <h2>{order.id}</h2>
        <span className="status">{orderStatuses[order.statusIndex] ?? 'غير محدد'}</span>
      </div>

      <div className="customer-block">
        <b>{order.customer}</b>
        <span className="phone-row">📞 {order.phone}<CopyBtn text={order.phone} /></span>
        <span>📍 {order.city} — {order.address}</span>
      </div>

      <div className="order-items">
        {items.map((item, idx) => (
          <div className="order-item" key={idx}>
            {item.image && <img src={item.image} alt={item.title} />}
            <div>
              <h4>{item.title}</h4>
              <div className="item-meta">
                {item.color && <span>🎨 {item.color}</span>}
                {item.size && <span>📐 {item.size}</span>}
                <span>× {item.quantity ?? 1}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      <label className="field">
        <span>رقم القدموس</span>
        <input
          key={order.id}
          defaultValue={order.qadmousNumber}
          onBlur={(e) => onUpdate(order.id, { qadmousNumber: e.target.value })}
          placeholder="مثال: KD-22091"
        />
      </label>

      <div className="order-card-actions">
        <button className="ghost-action" onClick={() => onPrintSingle(order.id)}>
          <Icon name="print" /> طباعة ملصق
        </button>
        <button className="primary-action" onClick={() => onAdvance(order)}>
          <Icon name="arrow_forward" /> نقل للمرحلة التالية
        </button>
      </div>
    </article>
  )
}

// ── Single Label (~10×15cm) ───────────────────────────────────────────────────
function SingleLabel({ order }: { order: Order }) {
  return (
    <div className="label-single">
      <div className="label-strip">
        <span>otlobli</span>
        <span>{order.id}</span>
      </div>
      <div className="label-body">
        <div className="label-name">{order.customer}</div>
        <div className="label-row"><b>📞 الهاتف:</b> {order.phone}</div>
        <div className="label-row"><b>📍 المدينة:</b> {order.city}</div>
        <div className="label-row"><b>العنوان:</b> {order.address}</div>
        <div className="label-row"><b>عدد القطع:</b> {(order.items ?? []).length}</div>
      </div>
      <div className="label-footer">
        <span>رقم القدموس: {order.qadmousNumber || '—'}</span>
        <span>{formatMoney(order.total)}</span>
      </div>
    </div>
  )
}

// ── Label Cell (for A4 sheet) ─────────────────────────────────────────────────
function LabelCell({ order }: { order: Order }) {
  return (
    <div className="label-cell">
      <div className="label-cell-title">otlobli — {order.id}</div>
      <div className="label-cell-name">{order.customer}</div>
      <small>📞 {order.phone}</small>
      <small>📍 {order.city} — {order.address}</small>
      <small>عدد القطع: {(order.items ?? []).length} · قدموس: {order.qadmousNumber || '—'}</small>
    </div>
  )
}

export default DriverApp
