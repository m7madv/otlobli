import { useEffect, useMemo, useState } from 'react'

type AdminTab = 'dashboard' | 'orders' | 'payments' | 'shipping' | 'customers' | 'drivers' | 'coupons' | 'settings'
type PaymentStatus = 'بانتظار الدفع' | 'مدفوع' | 'فشل المطابقة'

type Coupon = {
  id: string
  code: string
  kind: 'percent' | 'fixed'
  value: number
  appliesTo: 'all' | 'shein' | 'temu'
  active: boolean
  maxUses: number | null
  usedCount: number
  minSubtotalSyp: number
  startsAt: string | null
  expiresAt: string | null
  createdAt: string
}

type CartItem = {
  id: string
  title: string
  image: string
  color: string
  size: string
  quantity: number
  priceSyp: number
  sourceLink: string
  // بيانات المنتجات المخصصة (نقش/صورة) — يرسلها تطبيق الزبون داخل عناصر الطلب
  needsCustomText?: boolean
  customText?: string
  needsCustomPhoto?: boolean
  customPhotoNote?: string
  customPhotoDataUrl?: string
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
  assignedDriverId: string
  rating?: number
  ratingNote?: string
  paymentIssue: boolean
  paymentIssueNote: string
  extraAmountUsd: number
  groupId?: string
  groupCode?: string
}

type Customer = {
  id: string
  phone: string
  name: string
  governorate: string
  city: string
  qadmousBranch: string
  details: string
  walletBalanceSyp: number
  orderCount: number
  totalSpentSyp: number
  lastOrderAt: string
  createdAt: string
  updatedAt: string
}

type DriverOption = {
  id: string
  name: string
}

type Driver = DriverOption & {
  phone: string
  loginCode: string
  isActive: boolean
  createdAt: string
}

type OrdersResponse = {
  orders: Order[]
  drivers: DriverOption[]
  customers?: Customer[]
}

const orderStatuses = [
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

function formatMoney(value: number) {
  return `${(value ?? 0).toLocaleString('ar-SY')} ل.س`
}

function today() {
  return new Date().toISOString().slice(0, 10)
}

function Icon({ name }: { name: string }) {
  return <span className="material-symbols-outlined" aria-hidden="true">{name}</span>
}

function StatusBadge({ children, tone = 'neutral' }: { children: string; tone?: 'success' | 'pending' | 'neutral' }) {
  return <span className={`status status--${tone}`}>{children}</span>
}

// ── Cart tracking (localStorage) ──────────────────────────────────────────────
function useCartTracked() {
  const [tracked, setTracked] = useState<Set<string>>(() => {
    try {
      const raw = localStorage.getItem('admin_cart_tracked')
      return new Set(raw ? (JSON.parse(raw) as string[]) : [])
    } catch {
      return new Set<string>()
    }
  })

  const toggle = (key: string) => {
    setTracked((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      localStorage.setItem('admin_cart_tracked', JSON.stringify([...next]))
      return next
    })
  }

  const markAll = (keys: string[]) => {
    setTracked((prev) => {
      const next = new Set(prev)
      const allDone = keys.every((k) => next.has(k))
      if (allDone) keys.forEach((k) => next.delete(k))
      else keys.forEach((k) => next.add(k))
      localStorage.setItem('admin_cart_tracked', JSON.stringify([...next]))
      return next
    })
  }

  return { tracked, toggle, markAll }
}

function itemKey(orderId: string, idx: number) {
  return `${orderId}::${idx}`
}

// ── Copy to clipboard ─────────────────────────────────────────────────────────
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

// ── Supabase ──────────────────────────────────────────────────────────────────
// تنظيف أي حرف BOM (U+FEFF) أو مسافات خفية تتسرّب عند لصق المفاتيح في إعدادات
// Vercel — وجودها في headers يجعل المتصفح يرفض الطلب بالكامل بصمت (non ISO-8859-1).
const stripBom = (s: string | undefined) => (s || '').replace(/[\uFEFF\u200B\u200C\u200D]/g, '').trim()
const SUPABASE_URL = stripBom(import.meta.env.VITE_SUPABASE_URL as string | undefined)
const ADMIN_ORDERS_FN   = `${SUPABASE_URL}/functions/v1/admin-orders`
const ADMIN_DRIVERS_FN  = `${SUPABASE_URL}/functions/v1/admin-drivers`
const ADMIN_COUPONS_FN  = `${SUPABASE_URL}/functions/v1/admin-coupons`
const APP_SETTINGS_FN   = `${SUPABASE_URL}/functions/v1/app-settings`
const WA_API_BASE = stripBom(import.meta.env.VITE_WHATSAPP_API_URL as string | undefined) || ''
const ANON_KEY = stripBom(import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined)
const ADMIN_SESSION_STORAGE_KEY = 'talabieh_admin_session'

type AdminSession = {
  pin: string
  version: string
}

function readAdminSession(): AdminSession | null {
  try {
    const raw = localStorage.getItem(ADMIN_SESSION_STORAGE_KEY)
    if (!raw) return null
    const parsed = JSON.parse(raw) as Partial<AdminSession>
    if (!parsed.pin || !parsed.version) return null
    return { pin: parsed.pin, version: parsed.version }
  } catch {
    return null
  }
}

function writeAdminSession(session: AdminSession | null) {
  try {
    if (!session) {
      localStorage.removeItem(ADMIN_SESSION_STORAGE_KEY)
      return
    }
    localStorage.setItem(ADMIN_SESSION_STORAGE_KEY, JSON.stringify(session))
  } catch {
    // ignore storage issues
  }
}

async function fetchPublicSettings() {
  const response = await fetch(APP_SETTINGS_FN, {
    headers: { apikey: ANON_KEY, authorization: `Bearer ${ANON_KEY}` },
  })
  if (!response.ok) throw new Error('settings_unavailable')
  return response.json() as Promise<Record<string, string>>
}

async function fetchOrders(pin: string) {
  const response = await fetch(ADMIN_ORDERS_FN, {
    headers: {
      'x-admin-pin': pin,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
  })
  if (!response.ok) throw new Error('orders_unavailable')
  const payload = (await response.json()) as OrdersResponse
  return { orders: payload.orders, drivers: payload.drivers ?? [], customers: payload.customers ?? [] }
}

async function addWalletTransaction(pin: string, customer: Pick<Customer, 'phone' | 'name'>, amountSyp: number, note: string) {
  const response = await fetch(ADMIN_ORDERS_FN, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-admin-pin': pin,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({
      action: 'wallet_transaction',
      phone: customer.phone,
      name: customer.name,
      amountSyp,
      note,
      kind: 'manual_adjustment',
    }),
  })
  if (!response.ok) throw new Error('wallet_transaction_failed')
}

async function fetchDrivers(pin: string) {
  const response = await fetch(ADMIN_DRIVERS_FN, {
    headers: {
      'x-admin-pin': pin,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
  })
  if (!response.ok) throw new Error('drivers_unavailable')
  const payload = (await response.json()) as { drivers: Driver[] }
  return payload.drivers
}

async function createDriver(pin: string, name: string, phone: string, loginCode: string) {
  const response = await fetch(ADMIN_DRIVERS_FN, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-admin-pin': pin,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({ name, phone, loginCode }),
  })
  if (!response.ok) throw new Error('driver_create_failed')
  const payload = (await response.json()) as { driver: Driver }
  return payload.driver
}

async function patchDriver(pin: string, driverId: string, patch: Partial<Pick<Driver, 'isActive'>>) {
  const response = await fetch(ADMIN_DRIVERS_FN, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      'x-admin-pin': pin,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({ driverId, patch }),
  })
  if (!response.ok) throw new Error('driver_update_failed')
}

async function deleteDriver(pin: string, driverId: string) {
  const response = await fetch(ADMIN_DRIVERS_FN, {
    method: 'DELETE',
    headers: {
      'content-type': 'application/json',
      'x-admin-pin': pin,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({ driverId }),
  })
  if (!response.ok) throw new Error('driver_delete_failed')
}

async function patchOrder(pin: string, orderId: string, patch: Partial<Order>) {
  const response = await fetch(ADMIN_ORDERS_FN, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      'x-admin-pin': pin,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({ orderId, patch }),
  })
  if (!response.ok) throw new Error('order_update_failed')
}

async function deleteOrderApi(pin: string, orderId: string) {
  const response = await fetch(ADMIN_ORDERS_FN, {
    method: 'DELETE',
    headers: {
      'content-type': 'application/json',
      'x-admin-pin': pin,
      'apikey': ANON_KEY,
      'authorization': `Bearer ${ANON_KEY}`,
    },
    body: JSON.stringify({ orderId }),
  })
  if (!response.ok) throw new Error('order_delete_failed')
}

function couponHeaders(pin: string) {
  return {
    'content-type': 'application/json',
    'x-admin-pin': pin,
    apikey: ANON_KEY,
    authorization: `Bearer ${ANON_KEY}`,
  }
}

async function fetchCoupons(pin: string) {
  const response = await fetch(ADMIN_COUPONS_FN, {
    headers: couponHeaders(pin),
  })
  if (!response.ok) throw new Error('coupons_unavailable')
  const payload = (await response.json()) as { coupons: Coupon[] }
  return payload.coupons ?? []
}

async function createCouponApi(pin: string, input: {
  code: string
  kind: 'percent' | 'fixed'
  value: number
  appliesTo: 'all' | 'shein' | 'temu'
  maxUses: number | null
  minSubtotalSyp: number
  expiresAt: string | null
}) {
  const response = await fetch(ADMIN_COUPONS_FN, {
    method: 'POST',
    headers: couponHeaders(pin),
    body: JSON.stringify(input),
  })
  if (!response.ok) {
    const errorBody = (await response.json().catch(() => ({}))) as { error?: string }
    throw new Error(errorBody.error || 'coupon_create_failed')
  }
  const payload = (await response.json()) as { coupon: Coupon }
  return payload.coupon
}

async function patchCouponApi(pin: string, couponId: string, patch: { active?: boolean }) {
  const response = await fetch(ADMIN_COUPONS_FN, {
    method: 'PATCH',
    headers: couponHeaders(pin),
    body: JSON.stringify({ couponId, patch }),
  })
  if (!response.ok) throw new Error('coupon_update_failed')
}

async function deleteCouponApi(pin: string, couponId: string) {
  const response = await fetch(ADMIN_COUPONS_FN, {
    method: 'DELETE',
    headers: couponHeaders(pin),
    body: JSON.stringify({ couponId }),
  })
  if (!response.ok) throw new Error('coupon_delete_failed')
}

// ── Main App ──────────────────────────────────────────────────────────────────
function AdminApp() {
  const [pinInput, setPinInput] = useState(() => readAdminSession()?.pin ?? '')
  const [pin, setPin] = useState('')
  const [bootingSession, setBootingSession] = useState(() => Boolean(readAdminSession()))
  const [sessionVersion, setSessionVersion] = useState('1')
  const [orders, setOrders] = useState<Order[]>([])
  const [customers, setCustomers] = useState<Customer[]>([])
  const [driverOptions, setDriverOptions] = useState<DriverOption[]>([])
  const [selectedOrderId, setSelectedOrderId] = useState('')
  const [selectedOrderIds, setSelectedOrderIds] = useState<Set<string>>(() => new Set())
  const [modalOrderId, setModalOrderId] = useState('')
  const [tab, setTab] = useState<AdminTab>('dashboard')
  const [search, setSearch] = useState('')
  const [notice, setNotice] = useState('')
  const [loading, setLoading] = useState(false)
  const [deepLinkOrderId] = useState(() => new URLSearchParams(window.location.search).get('order') ?? '')
  const { tracked, toggle: toggleCart, markAll: markAllCart } = useCartTracked()

  const selectedOrder = orders.find((o) => o.id === selectedOrderId)
  const modalOrder = orders.find((o) => o.id === modalOrderId)

  const filteredOrders = orders.filter((order) => {
    const haystack = `${order.id} ${order.customer} ${order.phone} ${order.city} ${order.paymentStatus} ${orderStatuses[order.statusIndex] ?? ''}`
    return haystack.includes(search.trim())
  })

  const stats = useMemo(() => {
    const paidOrders = orders.filter((o) => o.paymentStatus === 'مدفوع')
    const pendingPayments = orders.filter((o) => o.paymentStatus === 'بانتظار الدفع')
    const shippingOrders = orders.filter((o) => o.statusIndex >= 6 && o.statusIndex < 9)
    const sales = paidOrders.reduce((sum, o) => sum + (o.total ?? 0), 0)
    return { paidOrders, pendingPayments, shippingOrders, sales }
  }, [orders])

  const showNotice = (message: string) => {
    setNotice(message)
    window.setTimeout(() => setNotice(''), 2200)
  }

  const closeSession = (message?: string, clearInput = false) => {
    setPin('')
    setOrders([])
    setCustomers([])
    setDriverOptions([])
    setSelectedOrderId('')
    setModalOrderId('')
    setBootingSession(false)
    writeAdminSession(null)
    if (clearInput) setPinInput('')
    if (message) showNotice(message)
  }

  const unlock = async (forcedPin?: string, silent = false) => {
    const nextPin = (forcedPin ?? pinInput).trim()
    if (!nextPin) {
      if (!silent) showNotice('أدخل رمز الإدارة')
      setBootingSession(false)
      return
    }
    setLoading(true)
    try {
      const settings = await fetchPublicSettings()
      const nextVersion = settings.admin_session_version ?? '1'
      const { orders: nextOrders, drivers: nextDrivers, customers: nextCustomers } = await fetchOrders(nextPin)
      setSessionVersion(nextVersion)
      setPin(nextPin)
      setPinInput(nextPin)
      setOrders(nextOrders)
      setCustomers(nextCustomers)
      setDriverOptions(nextDrivers)
      writeAdminSession({ pin: nextPin, version: nextVersion })
      const autoSelect = deepLinkOrderId && nextOrders.find((o) => o.id === deepLinkOrderId)
        ? deepLinkOrderId
        : ''
      setSelectedOrderId(autoSelect)
      if (deepLinkOrderId && autoSelect === deepLinkOrderId) {
        setTab('dashboard')
        setModalOrderId(deepLinkOrderId)
      }
      if (!silent) showNotice('تم فتح لوحة الإدارة')
    } catch {
      if (silent) {
        closeSession()
      } else {
        showNotice('تعذر فتح لوحة الإدارة. تحقق من الرمز أو إعدادات السيرفر')
      }
    } finally {
      setLoading(false)
      setBootingSession(false)
    }
  }

  const refresh = () => {
    if (!pin) return
    setLoading(true)
    void Promise.all([fetchPublicSettings(), fetchOrders(pin)])
      .then(([settings, { orders: nextOrders, drivers: nextDrivers, customers: nextCustomers }]) => {
        const nextVersion = settings.admin_session_version ?? '1'
        if (nextVersion !== sessionVersion) {
          closeSession('تم تسجيل الخروج من هذه الجلسة', true)
          return
        }
        setOrders(nextOrders)
        setCustomers(nextCustomers)
        setDriverOptions(nextDrivers)
        showNotice('تم تحديث الطلبات')
      })
      .catch(() => showNotice('تعذر جلب الطلبات'))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    const storedSession = readAdminSession()
    if (!storedSession) return
    void fetchPublicSettings()
      .then((settings) => {
        const nextVersion = settings.admin_session_version ?? '1'
        setSessionVersion(nextVersion)
        if (storedSession.version !== nextVersion) {
          closeSession()
          return
        }
        void unlock(storedSession.pin, true)
      })
      .catch(() => setBootingSession(false))
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // تحديث تلقائي صامت كل 15 ثانية + تنبيه عند وصول طلب جديد
  useEffect(() => {
    if (!pin) return
    const interval = window.setInterval(() => {
      void Promise.all([fetchPublicSettings(), fetchOrders(pin)])
        .then(([settings, { orders: nextOrders, drivers: nextDrivers, customers: nextCustomers }]) => {
          const nextVersion = settings.admin_session_version ?? '1'
          if (nextVersion !== sessionVersion) {
            closeSession('تم تسجيل الخروج من هذه الجلسة', true)
            return
          }
          setDriverOptions(nextDrivers)
          setCustomers(nextCustomers)
          setOrders((prev) => {
            if (nextOrders.length > prev.length) {
              const diff = nextOrders.length - prev.length
              showNotice(`🔔 ${diff} طلب جديد وصل`)
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
  }, [pin, sessionVersion])

  const updateOrder = (orderId: string, patch: Partial<Order>) => {
    setOrders((list) => list.map((o) => (o.id === orderId ? { ...o, ...patch } : o)))
    void patchOrder(pin, orderId, patch)
      .then(() => showNotice('تم تحديث الطلب'))
      .catch(() => { showNotice('فشل تحديث الطلب'); refresh() })
  }

  const deleteOrder = (orderId: string) => {
    if (!window.confirm(`حذف الطلب ${orderId} نهائياً؟ لا يمكن التراجع.`)) return
    setOrders((list) => list.filter((o) => o.id !== orderId))
    setSelectedOrderIds((prev) => {
      const next = new Set(prev)
      next.delete(orderId)
      return next
    })
    setSelectedOrderId((current) => current === orderId ? '' : current)
    setModalOrderId('')
    void deleteOrderApi(pin, orderId)
      .then(() => showNotice('تم حذف الطلب'))
      .catch(() => { showNotice('فشل حذف الطلب'); refresh() })
  }

  const toggleSelectedOrder = (orderId: string) => {
    setSelectedOrderIds((prev) => {
      const next = new Set(prev)
      if (next.has(orderId)) next.delete(orderId)
      else next.add(orderId)
      return next
    })
  }

  const clearSelectedOrders = () => setSelectedOrderIds(new Set())

  const deleteSelectedOrders = () => {
    const ids = [...selectedOrderIds]
    if (!ids.length) return
    if (!window.confirm(`حذف ${ids.length} طلب نهائياً؟ لا يمكن التراجع.`)) return
    setOrders((list) => list.filter((o) => !selectedOrderIds.has(o.id)))
    setSelectedOrderIds(new Set())
    setSelectedOrderId((current) => selectedOrderIds.has(current) ? '' : current)
    setModalOrderId((current) => selectedOrderIds.has(current) ? '' : current)
    void Promise.all(ids.map((id) => deleteOrderApi(pin, id)))
      .then(() => showNotice('تم حذف الطلبات المحددة'))
      .catch(() => { showNotice('فشل حذف بعض الطلبات'); refresh() })
  }

  const markPaid = (order: Order) => {
    updateOrder(order.id, { paymentStatus: 'مدفوع', statusIndex: Math.max(1, order.statusIndex), paidAt: today() })
  }

  const advanceOrder = (order: Order) => {
    const statusIndex = Math.min(order.statusIndex + 1, orderStatuses.length - 1)
    updateOrder(order.id, { statusIndex, paymentStatus: statusIndex > 0 ? 'مدفوع' : order.paymentStatus })
  }

  const openModal = (orderId: string) => {
    if (selectedOrderIds.size > 0) {
      toggleSelectedOrder(orderId)
      return
    }
    setSelectedOrderId(orderId)
    setModalOrderId(orderId)
  }

  if (!pin) {
    return (
      <main className="login-shell">
        <section className="login-card">
          <div className="brand"><span>طلبية</span><small>لوحة الإدارة</small></div>
          <h1>تسجيل دخول الإدارة</h1>
          <p>{bootingSession ? 'جار التحقق من جلستك المحفوظة...' : 'أدخل رمز الإدارة للوصول إلى الطلبات والمدفوعات والشحن.'}</p>
          <label className="field">
            <span>رمز الإدارة</span>
            <input
              value={pinInput}
              type="password"
              autoComplete="current-password"
              onChange={(e) => setPinInput(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') void unlock() }}
            />
          </label>
          <button className="primary-action" disabled={loading || bootingSession} onClick={() => void unlock()}>
            {loading || bootingSession ? 'جار التحقق...' : 'فتح لوحة الإدارة'}
            <Icon name="lock_open" />
          </button>
          {notice && <p className="notice">{notice}</p>}
        </section>
      </main>
    )
  }

  return (
    <div className="admin-shell">
      <aside className="sidebar">
        <div className="brand"><span>طلبية</span><small>إدارة العمليات</small></div>
        {([
          ['dashboard', 'لوحة التحكم', 'dashboard'],
          ['orders', 'الطلبات', 'receipt_long'],
          ['payments', 'المدفوعات', 'payments'],
          ['shipping', 'الشحن', 'local_shipping'],
          ['customers', 'العملاء', 'group'],
          ['drivers', 'السواقين', 'local_shipping'],
          ['coupons', 'أكواد الخصم', 'sell'],
          ['settings', 'الإعدادات', 'settings'],
        ] as const).map(([key, label, icon]) => (
          <button className={tab === key ? 'is-active' : ''} key={key} onClick={() => setTab(key as AdminTab)}>
            <Icon name={icon} />
            {label}
            {key === 'payments' && stats.pendingPayments.length > 0 && (
              <span className="sidebar-badge">{stats.pendingPayments.length}</span>
            )}
          </button>
        ))}
      </aside>

      <main className="main">
        <header className="topbar">
          <div>
            <h1>لوحة إدارة طلبية</h1>
            <p>إدارة الطلبات والمدفوعات والشحن من قاعدة Supabase.</p>
          </div>
          <div className="top-actions">
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="بحث عن طلب أو عميل..." />
            <button onClick={refresh} disabled={loading}><Icon name="refresh" /> تحديث</button>
            <button onClick={() => closeSession('تم تسجيل الخروج من هذا الجهاز', true)}><Icon name="logout" /> خروج</button>
          </div>
        </header>

        {tab === 'dashboard' && (
          <>
            <section className="stats">
              <StatCard icon="today" label="إجمالي الطلبات" value={orders.length.toString()} note="من قاعدة البيانات" />
              <StatCard icon="pending_actions" label="بانتظار الدفع" value={stats.pendingPayments.length.toString()} note="تحتاج متابعة" />
              <StatCard icon="local_shipping" label="قيد الشحن" value={stats.shippingOrders.length.toString()} note="مركز التجميع إلى سوريا" />
              <StatCard icon="monetization_on" label="إجمالي المبيعات" value={formatMoney(stats.sales)} note="طلبات مدفوعة" dark />
            </section>
            <section className="content-grid">
              <OrdersTable
                orders={filteredOrders.slice(0, 8)}
                tracked={tracked}
                selectedIds={selectedOrderIds}
                onOpen={openModal}
                onToggleSelect={toggleSelectedOrder}
                onClearSelection={clearSelectedOrders}
                onDeleteSelected={deleteSelectedOrders}
                onMarkPaid={markPaid}
              />
              <OrderDetail order={selectedOrder} drivers={driverOptions} onOpen={openModal} onMarkPaid={markPaid} onAdvance={advanceOrder} onUpdate={updateOrder} />
            </section>
          </>
        )}
        {tab === 'orders' && (
          <OrdersTable
            orders={filteredOrders}
            tracked={tracked}
            selectedIds={selectedOrderIds}
            onOpen={openModal}
            onToggleSelect={toggleSelectedOrder}
            onClearSelection={clearSelectedOrders}
            onDeleteSelected={deleteSelectedOrders}
            onMarkPaid={markPaid}
          />
        )}
        {tab === 'payments' && (
          <OrdersTable
            orders={filteredOrders.filter((o) => o.paymentStatus !== 'مدفوع')}
            tracked={tracked}
            selectedIds={selectedOrderIds}
            onOpen={openModal}
            onToggleSelect={toggleSelectedOrder}
            onClearSelection={clearSelectedOrders}
            onDeleteSelected={deleteSelectedOrders}
            onMarkPaid={markPaid}
          />
        )}
        {tab === 'shipping' && <ShippingList orders={filteredOrders} drivers={driverOptions} onAdvance={advanceOrder} onUpdate={updateOrder} onOpen={openModal} />}
        {tab === 'customers' && (
          <CustomersGrid
            pin={pin}
            customers={customers}
            orders={orders}
            onRefresh={refresh}
            showNotice={showNotice}
          />
        )}
        {tab === 'drivers' && <DriversPanel pin={pin} showNotice={showNotice} />}
        {tab === 'coupons' && <CouponsPanel pin={pin} showNotice={showNotice} />}
        {tab === 'settings' && (
          <SettingsPanel
            pin={pin}
            showNotice={showNotice}
            onLogoutEverywhere={() => closeSession('تم تسجيل الخروج من جميع الأجهزة', true)}
          />
        )}
      </main>

      {/* ── Order Modal ── */}
      {modalOrder && (
        <OrderModal
          order={modalOrder}
          drivers={driverOptions}
          tracked={tracked}
          onToggle={toggleCart}
          onMarkAll={markAllCart}
          onClose={() => setModalOrderId('')}
          onMarkPaid={markPaid}
          onAdvance={advanceOrder}
          onUpdate={updateOrder}
          onDelete={deleteOrder}
        />
      )}

      {notice && <div className="toast">{notice}</div>}
    </div>
  )
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
function StatCard({ icon, label, value, note, dark = false }: { icon: string; label: string; value: string; note: string; dark?: boolean }) {
  return (
    <article className={dark ? 'stat stat--dark' : 'stat'}>
      <Icon name={icon} />
      <p>{label}</p>
      <strong>{value}</strong>
      <span>{note}</span>
    </article>
  )
}

// ── Orders Table ──────────────────────────────────────────────────────────────
function OrdersTable({
  orders, tracked, selectedIds, onOpen, onToggleSelect, onClearSelection, onDeleteSelected, onMarkPaid,
}: {
  orders: Order[]
  tracked: Set<string>
  selectedIds: Set<string>
  onOpen: (orderId: string) => void
  onToggleSelect: (orderId: string) => void
  onClearSelection: () => void
  onDeleteSelected: () => void
  onMarkPaid: (order: Order) => void
}) {
  const selectionActive = selectedIds.size > 0

  return (
    <section className="panel table-panel">
      <header>
        <div>
          <h2>الطلبات</h2>
          <span>{selectionActive ? `${selectedIds.size} محدد` : `${orders.length} طلب`}</span>
        </div>
        {selectionActive && (
          <div className="selection-actions">
            <button className="ghost-action" onClick={onClearSelection}>إلغاء التحديد</button>
            <button className="danger-action" onClick={onDeleteSelected}>
              <Icon name="delete" /> حذف المحدد
            </button>
          </div>
        )}
      </header>
      <div className="table-scroll">
        <table>
          <thead>
            <tr>
              <th>رقم الطلب</th>
              <th>العميل</th>
              <th>المبلغ</th>
              <th>الدفع</th>
              <th>الحالة</th>
              <th>السلة</th>
              <th>إجراء</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => {
              const items = order.items ?? []
              const addedCount = items.filter((_, i) => tracked.has(itemKey(order.id, i))).length
              const allAdded = items.length > 0 && addedCount === items.length
              const selected = selectedIds.has(order.id)
              return (
                <tr
                  key={order.id}
                  className={`${allAdded ? 'row-done' : ''} ${selected ? 'row-selected' : ''}`}
                  onClick={() => selectionActive ? onToggleSelect(order.id) : onOpen(order.id)}
                  onDoubleClick={() => onOpen(order.id)}
                  onContextMenu={(event) => {
                    event.preventDefault()
                    onToggleSelect(order.id)
                  }}
                >
                  <td><b>{order.id}</b></td>
                  <td>
                    <span>{order.customer}</span>
                    <CopyBtn text={order.phone} />
                  </td>
                  <td>{formatMoney(order.total)}</td>
                  <td><StatusBadge tone={order.paymentStatus === 'مدفوع' ? 'success' : 'pending'}>{order.paymentStatus}</StatusBadge></td>
                  <td><StatusBadge>{orderStatuses[order.statusIndex] ?? 'غير محدد'}</StatusBadge></td>
                  <td>
                    <span className={`cart-progress ${allAdded ? 'cart-progress--done' : ''}`}>
                      {items.length > 0 ? `${addedCount}/${items.length}` : '—'}
                    </span>
                  </td>
                  <td>
                    <div className="row-actions">
                      <button
                        onClick={(event) => {
                          event.stopPropagation()
                          if (selectionActive) onToggleSelect(order.id)
                          else onOpen(order.id)
                        }}
                        onPointerDown={(event) => {
                          const timer = window.setTimeout(() => onToggleSelect(order.id), 520)
                          const clear = () => window.clearTimeout(timer)
                          event.currentTarget.addEventListener('pointerup', clear, { once: true })
                          event.currentTarget.addEventListener('pointerleave', clear, { once: true })
                        }}
                        title={selectionActive ? 'تحديد الطلب' : 'فتح تفاصيل الطلب'}
                      >
                        <Icon name={selected ? 'check_circle' : 'open_in_full'} />
                      </button>
                      {order.paymentStatus !== 'مدفوع' && (
                        <button
                          onClick={(event) => {
                            event.stopPropagation()
                            onMarkPaid(order)
                          }}
                        >
                          تأكيد الدفع
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              )
            })}
            {!orders.length && (
              <tr><td colSpan={7}>لا توجد طلبات مطابقة.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  )
}

// ── Driver Assign Field ──────────────────────────────────────────────────────
function DriverAssignField({
  order, drivers, onUpdate,
}: {
  order: Order
  drivers: DriverOption[]
  onUpdate: (orderId: string, patch: Partial<Order>) => void
}) {
  const assignedDriver = drivers.find((d) => d.id === order.assignedDriverId)
  return (
    <label className="field driver-assign">
      <span>السواق المكلَّف</span>
      <select
        key={order.id}
        defaultValue={order.assignedDriverId}
        onChange={(e) => onUpdate(order.id, { assignedDriverId: e.target.value })}
      >
        <option value="">— بلا تكليف —</option>
        {drivers.map((d) => (
          <option key={d.id} value={d.id}>{d.name}</option>
        ))}
      </select>
      {assignedDriver && <small className="driver-assign-note">📦 مكلَّف لـ {assignedDriver.name} — وصله إشعار واتساب</small>}
    </label>
  )
}

// ── Order Detail (sidebar panel) ──────────────────────────────────────────────
function OrderDetail({
  order, drivers, onOpen, onMarkPaid, onAdvance, onUpdate,
}: {
  order?: Order
  drivers: DriverOption[]
  onOpen: (orderId: string) => void
  onMarkPaid: (order: Order) => void
  onAdvance: (order: Order) => void
  onUpdate: (orderId: string, patch: Partial<Order>) => void
}) {
  if (!order) {
    return (
      <section className="panel empty">
        <Icon name="receipt_long" />
        <h2>لا يوجد طلب محدد</h2>
        <p>اختر طلباً من الجدول لعرض تفاصيله.</p>
      </section>
    )
  }

  const items = order.items ?? []

  return (
    <section className="panel detail">
      <header>
        <div>
          <h2>{order.id}</h2>
          <StatusBadge tone={order.paymentStatus === 'مدفوع' ? 'success' : 'pending'}>{order.paymentStatus}</StatusBadge>
        </div>
        <button className="open-modal-btn" onClick={() => onOpen(order.id)} title="فتح واجهة كاملة">
          <Icon name="open_in_full" />
          <span>واجهة كاملة</span>
        </button>
      </header>

      <div className="detail-items">
        {items.map((item, idx) => (
          <div className="detail-product" key={idx}>
            {item.image && <img src={item.image} alt={item.title} />}
            <div>
              <h3>{item.title}</h3>
              <p className="item-meta">
                {item.color && <span>🎨 {item.color}</span>}
                {item.size && <span>📐 {item.size}</span>}
                <span>× {item.quantity}</span>
                <span>{formatMoney((item.priceSyp ?? 0) * (item.quantity ?? 0))}</span>
              </p>
              {item.customText && (
                <p className="custom-text-chip">✍️ النص المطلوب: <strong>{item.customText}</strong></p>
              )}
              {item.customPhotoDataUrl && (
                <a
                  className="custom-photo-chip"
                  href={item.customPhotoDataUrl}
                  download={`custom-${order.id}-${idx + 1}.jpg`}
                  title="صورة التخصيص من الزبون — اضغط للتنزيل"
                >
                  <img src={item.customPhotoDataUrl} alt="صورة التخصيص" />
                  <span>📷 صورة التخصيص — تنزيل</span>
                </a>
              )}
              {item.sourceLink && (
                <a className="shein-link" href={item.sourceLink} rel="noreferrer" target="_blank">
                  فتح SHEIN{item.color ? ` — ${item.color}` : ''}{item.size ? ` / ${item.size}` : ''}
                </a>
              )}
            </div>
          </div>
        ))}
      </div>

      <InfoRow label="العميل" value={`${order.customer} · ${order.phone}`} />
      <InfoRow label="العنوان" value={`${order.city} · ${order.address}`} />
      <InfoRow label="الحالة" value={orderStatuses[order.statusIndex] ?? 'غير محدد'} />
      <InfoRow label="الإجمالي" value={formatMoney(order.total)} />
      {order.rating && (
        <InfoRow label="تقييم العميل" value={`${'⭐'.repeat(order.rating)}${order.ratingNote ? ' — ' + order.ratingNote : ''}`} />
      )}
      <label className="field">
        <span>رقم القدموس</span>
        <input
          key={order.id}
          defaultValue={order.qadmousNumber}
          onBlur={(e) => onUpdate(order.id, { qadmousNumber: e.target.value, statusIndex: Math.max(7, order.statusIndex) })}
          placeholder="مثال: KD-22091"
        />
      </label>
      <DriverAssignField order={order} drivers={drivers} onUpdate={onUpdate} />
      <PaymentIssueField
        key={`${order.id}-${order.paymentIssue}-${order.paymentIssueNote}-${order.extraAmountUsd}`}
        order={order}
        onUpdate={onUpdate}
      />
      <div className="detail-actions">
        <button className="primary-action" onClick={() => onMarkPaid(order)}>تأكيد الدفع</button>
        <button className="ghost-action" onClick={() => onAdvance(order)}>نقل للمرحلة التالية</button>
      </div>
    </section>
  )
}

const issueTypes = [
  { value: 'price', label: 'فرق سعر / مبلغ إضافي', action: 'ادفع المبلغ المطلوب من التطبيق أو تواصل معنا لتأكيد الدفع.' },
  { value: 'size', label: 'المقاس غير واضح أو غير متوفر', action: 'افتح التطبيق واختر المقاس الصحيح أو اكتب البديل المناسب.' },
  { value: 'color', label: 'اللون غير واضح أو غير متوفر', action: 'افتح التطبيق وحدد اللون الصحيح أو البديل المناسب.' },
  { value: 'custom_photo', label: 'منتج مخصص يحتاج صورة', action: 'افتح التطبيق وأرسل الصورة المطلوبة للمنتج.' },
  { value: 'custom_text', label: 'منتج مخصص يحتاج نص أو اسم', action: 'افتح التطبيق واكتب النص المطلوب للمنتج.' },
  { value: 'unavailable', label: 'المنتج غير متوفر', action: 'افتح التطبيق لاختيار بديل أو حذف المنتج من الطلب.' },
  { value: 'quantity', label: 'مشكلة بالكمية', action: 'افتح التطبيق وأكد الكمية المطلوبة.' },
  { value: 'link', label: 'رابط المنتج غير صالح', action: 'افتح التطبيق وأرسل رابط المنتج الصحيح.' },
  { value: 'other', label: 'مشكلة أخرى', action: 'افتح التطبيق لمراجعة تفاصيل المشكلة.' },
]

function buildIssueNote(issueType: string, itemLabel: string, customNote: string) {
  const type = issueTypes.find((entry) => entry.value === issueType) ?? issueTypes[0]
  return [
    `نوع المشكلة: ${type.label}`,
    itemLabel ? `المنتج: ${itemLabel}` : '',
    customNote.trim() ? `ملاحظة الإدارة: ${customNote.trim()}` : '',
    `المطلوب من الزبون: ${type.action}`,
  ].filter(Boolean).join('\n')
}

// ── Product / order issue field ──────────────────────────────────────────────
function PaymentIssueField({ order, onUpdate }: { order: Order; onUpdate: (orderId: string, patch: Partial<Order>) => void }) {
  const [open, setOpen] = useState(order.paymentIssue)
  const [issueType, setIssueType] = useState('price')
  const [itemIndex, setItemIndex] = useState('')
  const [customNote, setCustomNote] = useState(order.paymentIssueNote)
  const [amount, setAmount] = useState(String(order.extraAmountUsd || ''))

  const save = (issue: boolean) => {
    const item = itemIndex === '' ? null : order.items[Number(itemIndex)]
    const itemLabel = item ? `${Number(itemIndex) + 1}. ${item.title}` : ''
    onUpdate(order.id, {
      paymentIssue: issue,
      paymentIssueNote: issue ? buildIssueNote(issueType, itemLabel, customNote) : '',
      extraAmountUsd: Number(amount) || 0,
    })
  }

  return (
    <div className={`field payment-issue-field ${order.paymentIssue ? 'active' : ''}`}>
      <label className="checkbox-row">
        <input
          type="checkbox"
          checked={open}
          onChange={(e) => {
            setOpen(e.target.checked)
            if (!e.target.checked) save(false)
          }}
        />
        <span>مشكلة تحتاج إشعار الزبون</span>
      </label>
      {open && (
        <>
          <div className="issue-grid">
            <label className="field">
              <span>المنتج</span>
              <select value={itemIndex} onChange={(e) => setItemIndex(e.target.value)}>
                <option value="">الطلب كامل / غير محدد</option>
                {order.items.map((item, index) => (
                  <option key={`${item.id || item.title}-${index}`} value={index}>
                    {index + 1}. {item.title.slice(0, 70)}
                  </option>
                ))}
              </select>
            </label>
            <label className="field">
              <span>نوع المشكلة</span>
              <select value={issueType} onChange={(e) => setIssueType(e.target.value)}>
                {issueTypes.map((entry) => (
                  <option key={entry.value} value={entry.value}>{entry.label}</option>
                ))}
              </select>
            </label>
          </div>
          <textarea
            placeholder="ملاحظة إضافية للزبون: مثال اللون المطلوب غير متوفر، أرسل صورة أو اختر بديل..."
            value={customNote}
            onChange={(e) => setCustomNote(e.target.value)}
          />
          <input
            type="number"
            min="0"
            step="0.01"
            placeholder="المبلغ الإضافي بالدولار إن وجد"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
          <button className="ghost-action" onClick={() => save(true)}>حفظ وإشعار الزبون</button>
        </>
      )}
    </div>
  )
}

// ── Order Modal (full-screen) ─────────────────────────────────────────────────
function OrderModal({
  order, drivers, tracked, onToggle, onMarkAll, onClose, onMarkPaid, onAdvance, onUpdate, onDelete,
}: {
  order: Order
  drivers: DriverOption[]
  tracked: Set<string>
  onToggle: (key: string) => void
  onMarkAll: (keys: string[]) => void
  onClose: () => void
  onMarkPaid: (order: Order) => void
  onAdvance: (order: Order) => void
  onUpdate: (orderId: string, patch: Partial<Order>) => void
  onDelete: (orderId: string) => void
}) {
  const items = order.items ?? []
  const keys = items.map((_, i) => itemKey(order.id, i))
  const addedCount = keys.filter((k) => tracked.has(k)).length
  const allAdded = items.length > 0 && addedCount === items.length

  // Close on Escape
  useEffect(() => {
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [onClose])

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>

        {/* Header */}
        <div className="modal-header">
          <div className="modal-title">
            <h2>{order.id}</h2>
            <StatusBadge tone={order.paymentStatus === 'مدفوع' ? 'success' : 'pending'}>
              {order.paymentStatus}
            </StatusBadge>
            <StatusBadge>{orderStatuses[order.statusIndex] ?? 'غير محدد'}</StatusBadge>
          </div>
          <div className="modal-customer">
            <span><Icon name="person" />{order.customer}</span>
            <span className="phone-row">
              <Icon name="phone" />{order.phone}
              <CopyBtn text={order.phone} />
            </span>
            <span><Icon name="location_on" />{order.city} · {order.address}</span>
          </div>
          <button className="modal-close" onClick={onClose}><Icon name="close" /></button>
        </div>

        {/* Progress bar */}
        <div className="modal-progress">
          <div className="progress-label">
            <span>إضافة لسلة SHEIN</span>
            <b>{addedCount} من {items.length} منتج</b>
          </div>
          <div className="progress-bar">
            <div
              className="progress-fill"
              style={{ width: items.length ? `${(addedCount / items.length) * 100}%` : '0%' }}
            />
          </div>
          <button
            className={allAdded ? 'mark-all-btn done' : 'mark-all-btn'}
            onClick={() => onMarkAll(keys)}
          >
            <Icon name={allAdded ? 'remove_done' : 'done_all'} />
            {allAdded ? 'إلغاء تأشير الكل' : 'تأشير الكل كمضاف'}
          </button>
        </div>

        {/* Items grid */}
        <div className="modal-items">
          {items.map((item, idx) => {
            const key = itemKey(order.id, idx)
            const done = tracked.has(key)
            return (
              <div className={`modal-item ${done ? 'modal-item--done' : ''}`} key={idx}>
                {item.image && <img src={item.image} alt={item.title} />}
                <div className="modal-item-body">
                  <h3>{item.title}</h3>
                  <div className="item-meta">
                    {item.color && <span>🎨 {item.color}</span>}
                    {item.size && <span>📐 {item.size}</span>}
                    <span>× {item.quantity ?? 1}</span>
                    <span>{formatMoney((item.priceSyp ?? 0) * (item.quantity ?? 1))}</span>
                  </div>
                  {item.customText && (
                    <p className="custom-text-chip">✍️ النص المطلوب: <strong>{item.customText}</strong></p>
                  )}
                  {item.customPhotoDataUrl && (
                    <a
                      className="custom-photo-chip"
                      href={item.customPhotoDataUrl}
                      download={`custom-${order.id}-${idx + 1}.jpg`}
                      title="صورة التخصيص من الزبون — اضغط للتنزيل"
                    >
                      <img src={item.customPhotoDataUrl} alt="صورة التخصيص" />
                      <span>📷 صورة التخصيص — تنزيل</span>
                    </a>
                  )}
                  <div className="modal-item-actions">
                    {item.sourceLink && (
                      <a className="shein-link" href={item.sourceLink} rel="noreferrer" target="_blank">
                        <Icon name="open_in_new" />
                        فتح SHEIN{item.color ? ` — ${item.color}` : ''}{item.size ? ` / ${item.size}` : ''}
                      </a>
                    )}
                    <button
                      className={done ? 'cart-btn cart-btn--done' : 'cart-btn'}
                      onClick={() => onToggle(key)}
                    >
                      <Icon name={done ? 'check_circle' : 'add_shopping_cart'} />
                      {done ? 'تمت الإضافة' : 'أضفت للسلة؟'}
                    </button>
                  </div>
                </div>
                {done && <div className="done-ribbon">✓</div>}
              </div>
            )
          })}
        </div>

        {/* Footer */}
        <div className="modal-footer">
          <InfoRow label="الإجمالي" value={formatMoney(order.total)} />
          {order.rating && (
            <InfoRow label="تقييم العميل" value={`${'⭐'.repeat(order.rating)}${order.ratingNote ? ' — ' + order.ratingNote : ''}`} />
          )}
          <label className="field">
            <span>رقم القدموس</span>
            <input
              key={order.id}
              defaultValue={order.qadmousNumber}
              onBlur={(e) => onUpdate(order.id, { qadmousNumber: e.target.value, statusIndex: Math.max(7, order.statusIndex) })}
              placeholder="مثال: KD-22091"
            />
          </label>
          <DriverAssignField order={order} drivers={drivers} onUpdate={onUpdate} />
          <PaymentIssueField order={order} onUpdate={onUpdate} />
          <div className="detail-actions">
            <button className="primary-action" onClick={() => onMarkPaid(order)}>تأكيد الدفع</button>
            <button className="ghost-action" onClick={() => onAdvance(order)}>نقل للمرحلة التالية</button>
            <button className="danger-action" onClick={() => onDelete(order.id)}>
              <Icon name="delete" /> حذف الطلب
            </button>
            <button className="ghost-action" onClick={onClose}>إغلاق</button>
          </div>
        </div>

      </div>
    </div>
  )
}

// ── Shipping List ─────────────────────────────────────────────────────────────
function ShippingList({
  orders, drivers, onAdvance, onUpdate, onOpen,
}: {
  orders: Order[]
  drivers: DriverOption[]
  onAdvance: (order: Order) => void
  onUpdate: (orderId: string, patch: Partial<Order>) => void
  onOpen: (orderId: string) => void
}) {
  return (
    <section className="panel shipping-list">
      <header>
        <h2>الشحن والقدموس</h2>
        <span>{orders.length} طلب</span>
      </header>
      {orders.map((order) => {
        const assignedDriver = drivers.find((d) => d.id === order.assignedDriverId)
        return (
          <article key={order.id}>
            <div>
              <b>{order.id}</b>
              <span>{order.customer} · {order.city}</span>
              <small>{orderStatuses[order.statusIndex] ?? 'غير محدد'}</small>
              {assignedDriver && <small>📦 {assignedDriver.name}</small>}
            </div>
            <input
              key={order.id}
              defaultValue={order.qadmousNumber}
              onBlur={(e) => onUpdate(order.id, { qadmousNumber: e.target.value, statusIndex: Math.max(7, order.statusIndex) })}
              placeholder="رقم القدموس"
            />
            <select
              key={`${order.id}-driver`}
              defaultValue={order.assignedDriverId}
              onChange={(e) => onUpdate(order.id, { assignedDriverId: e.target.value })}
            >
              <option value="">— بلا تكليف —</option>
              {drivers.map((d) => (
                <option key={d.id} value={d.id}>{d.name}</option>
              ))}
            </select>
            <button onClick={() => onAdvance(order)}>تحديث المرحلة</button>
            <button onClick={() => onOpen(order.id)} title="فتح تفاصيل"><Icon name="open_in_full" /></button>
          </article>
        )
      })}
    </section>
  )
}

// ── Customers Grid ────────────────────────────────────────────────────────────
function CustomersGrid({
  pin, customers, orders, onRefresh, showNotice,
}: {
  pin: string
  customers: Customer[]
  orders: Order[]
  onRefresh: () => void
  showNotice: (message: string) => void
}) {
  const fallbackCustomers: Customer[] = Array.from(new Map(orders.map((o) => [o.phone, o])).values()).map((order) => ({
    id: order.phone,
    phone: order.phone,
    name: order.customer,
    governorate: order.city,
    city: order.city,
    qadmousBranch: '',
    details: order.address,
    walletBalanceSyp: 0,
    orderCount: orders.filter((o) => o.phone === order.phone).length,
    totalSpentSyp: orders.filter((o) => o.phone === order.phone).reduce((sum, o) => sum + o.total, 0),
    lastOrderAt: order.createdAt,
    createdAt: order.createdAt,
    updatedAt: order.createdAt,
  }))
  const visibleCustomers = customers.length ? customers : fallbackCustomers
  const [amounts, setAmounts] = useState<Record<string, string>>({})
  const [notes, setNotes] = useState<Record<string, string>>({})

  const submitWallet = (customer: Customer) => {
    const amount = Math.trunc(Number(amounts[customer.phone] || 0))
    if (!amount) { showNotice('أدخل مبلغ المحفظة'); return }
    void addWalletTransaction(pin, customer, amount, notes[customer.phone] || '')
      .then(() => {
        setAmounts((prev) => ({ ...prev, [customer.phone]: '' }))
        setNotes((prev) => ({ ...prev, [customer.phone]: '' }))
        showNotice('تم تسجيل حركة المحفظة')
        onRefresh()
      })
      .catch(() => showNotice('فشل تسجيل حركة المحفظة'))
  }
  return (
    <section className="customers">
      {visibleCustomers.map((customer) => (
        <article className="panel customer" key={customer.phone}>
          <div className="avatar">{customer.name[0] ?? 'ط'}</div>
          <h2>{customer.name || 'عميل بدون اسم'}</h2>
          <span className="phone-row">{customer.phone}<CopyBtn text={customer.phone} /></span>
          <p>{customer.governorate || customer.city || 'محافظة غير محددة'}</p>
          {customer.qadmousBranch && <p>{customer.qadmousBranch}</p>}
          <div className="customer-metrics">
            <b>{customer.orderCount} طلب</b>
            <b>{formatMoney(customer.totalSpentSyp)}</b>
            <b className={customer.walletBalanceSyp >= 0 ? 'wallet-positive' : 'wallet-negative'}>
              {formatMoney(customer.walletBalanceSyp)}
            </b>
          </div>
          <div className="wallet-adjust">
            <input
              value={amounts[customer.phone] || ''}
              onChange={(e) => setAmounts((prev) => ({ ...prev, [customer.phone]: e.target.value }))}
              inputMode="numeric"
              placeholder="+5000 أو -5000"
              dir="ltr"
            />
            <input
              value={notes[customer.phone] || ''}
              onChange={(e) => setNotes((prev) => ({ ...prev, [customer.phone]: e.target.value }))}
              placeholder="ملاحظة الحركة"
            />
            <button onClick={() => submitWallet(customer)}>
              <Icon name="account_balance_wallet" /> تسجيل
            </button>
          </div>
        </article>
      ))}
    </section>
  )
}

// ── Drivers Panel ─────────────────────────────────────────────────────────────
function DriversPanel({ pin, showNotice }: { pin: string; showNotice: (message: string) => void }) {
  const [drivers, setDrivers] = useState<Driver[]>([])
  const [loading, setLoading] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')
  const [loginCode, setLoginCode] = useState('')

  const load = () => {
    setLoading(true)
    void fetchDrivers(pin)
      .then(setDrivers)
      .catch(() => showNotice('تعذر جلب السواقين'))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    const timer = window.setTimeout(load, 0)
    return () => window.clearTimeout(timer)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const addDriver = () => {
    const trimmedName = name.trim()
    const trimmedPhone = phone.trim()
    const trimmedCode = loginCode.trim()
    if (!trimmedName) { showNotice('أدخل اسم السواق'); return }
    setLoading(true)
    void createDriver(pin, trimmedName, trimmedPhone, trimmedCode)
      .then(() => {
        setName(''); setPhone(''); setLoginCode('')
        setShowForm(false)
        showNotice(trimmedPhone ? 'تمت إضافة السواق وإرسال رمز الدخول له على واتساب' : 'تمت إضافة السواق — انسخ رمز الدخول من الجدول وسلّمه له')
        load()
      })
      .catch(() => showNotice('فشل إضافة السواق'))
      .finally(() => setLoading(false))
  }

  const toggleActive = (driver: Driver) => {
    void patchDriver(pin, driver.id, { isActive: !driver.isActive })
      .then(() => { showNotice('تم تحديث السواق'); load() })
      .catch(() => showNotice('فشل تحديث السواق'))
  }

  const removeDriver = (driver: Driver) => {
    if (!window.confirm(`حذف السواق «${driver.name}» نهائياً؟`)) return
    setDrivers((list) => list.filter((entry) => entry.id !== driver.id))
    void deleteDriver(pin, driver.id)
      .then(() => showNotice('تم حذف السواق'))
      .catch(() => {
        showNotice('فشل حذف السواق')
        load()
      })
  }

  return (
    <section className="panel table-panel drivers-panel">
      <header>
        <h2>السواقين</h2>
        <div className="panel-head-actions">
          <span>{drivers.length} سواق</span>
          <button className="ghost-action" onClick={() => setShowForm((value) => !value)}>
            <Icon name={showForm ? 'close' : 'person_add'} />
            {showForm ? 'إغلاق' : 'إضافة سائق'}
          </button>
        </div>
      </header>

      {showForm && (
        <div className="driver-add-form">
          <label className="field">
            <span>الاسم</span>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="مثال: أبو محمد" />
          </label>
          <label className="field">
            <span>كلمة السر / رمز الدخول (اختياري — لو فاضي بنولّده تلقائي)</span>
            <input value={loginCode} onChange={(e) => setLoginCode(e.target.value)} placeholder="مثال: 7741" />
          </label>
          <label className="field">
            <span>الهاتف (اختياري — لإشعار واتساب تلقائي)</span>
            <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="مثال: 9613xxxxxxx" />
          </label>
          <button className="primary-action" disabled={loading} onClick={addDriver}>
            <Icon name="person_add" /> إضافة سواق
          </button>
        </div>
      )}

      <div className="table-scroll">
        <table>
          <thead>
            <tr>
              <th>الاسم</th>
              <th>الهاتف</th>
              <th>رمز الدخول</th>
              <th>الحالة</th>
              <th>إجراء</th>
            </tr>
          </thead>
          <tbody>
            {drivers.map((driver) => (
              <tr key={driver.id}>
                <td><b>{driver.name}</b></td>
                <td>{driver.phone ? (<><span>{driver.phone}</span><CopyBtn text={driver.phone} /></>) : <span>—</span>}</td>
                <td><span>{driver.loginCode}</span><CopyBtn text={driver.loginCode} /></td>
                <td><StatusBadge tone={driver.isActive ? 'success' : 'neutral'}>{driver.isActive ? 'فعّال' : 'معطّل'}</StatusBadge></td>
                <td>
                  <div className="row-actions">
                    <button onClick={() => toggleActive(driver)}>{driver.isActive ? 'تعطيل' : 'تفعيل'}</button>
                    <button className="icon-btn danger" onClick={() => removeDriver(driver)} title="حذف السواق">
                      <Icon name="delete" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {!drivers.length && (
              <tr><td colSpan={5}>لا يوجد سواقين بعد.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  )
}

function CouponsPanel({ pin, showNotice }: { pin: string; showNotice: (message: string) => void }) {
  const [coupons, setCoupons] = useState<Coupon[]>([])
  const [loaded, setLoaded] = useState(false)
  const [busy, setBusy] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [code, setCode] = useState('')
  const [kind, setKind] = useState<'percent' | 'fixed'>('percent')
  const [value, setValue] = useState('')
  const [appliesTo, setAppliesTo] = useState<'all' | 'shein' | 'temu'>('all')
  const [minSubtotal, setMinSubtotal] = useState('')
  const [maxUses, setMaxUses] = useState('')
  const [expiresAt, setExpiresAt] = useState('')

  const reload = () => {
    void fetchCoupons(pin)
      .then((list) => {
        setCoupons(list)
        setLoaded(true)
      })
      .catch(() => {
        setLoaded(true)
        showNotice('تعذر جلب أكواد الخصم')
      })
  }

  useEffect(reload, []) // eslint-disable-line react-hooks/exhaustive-deps

  const createCoupon = () => {
    const normalizedCode = code.trim().toUpperCase()
    const numericValue = Number(value)
    if (!normalizedCode || !(numericValue > 0)) {
      showNotice('أدخل رمزاً وقيمة صحيحة')
      return
    }
    if (kind === 'percent' && numericValue > 100) {
      showNotice('النسبة يجب أن تكون 100 أو أقل')
      return
    }

    setBusy(true)
    void createCouponApi(pin, {
      code: normalizedCode,
      kind,
      value: numericValue,
      appliesTo,
      maxUses: maxUses.trim() ? Math.max(1, Math.round(Number(maxUses))) : null,
      minSubtotalSyp: Math.max(0, Math.round(Number(minSubtotal) || 0)),
      expiresAt: expiresAt.trim() ? new Date(expiresAt).toISOString() : null,
    })
      .then((coupon) => {
        setCoupons((list) => [coupon, ...list])
        setCode('')
        setValue('')
        setMinSubtotal('')
        setMaxUses('')
        setExpiresAt('')
        setShowForm(false)
        showNotice('تم إنشاء كود الخصم')
      })
      .catch((error: Error) => {
        showNotice(error.message === 'code_exists' ? 'الكود موجود مسبقاً' : 'فشل إنشاء الكود')
      })
      .finally(() => setBusy(false))
  }

  const toggleCoupon = (coupon: Coupon) => {
    setCoupons((list) => list.map((entry) => (
      entry.id === coupon.id ? { ...entry, active: !entry.active } : entry
    )))
    void patchCouponApi(pin, coupon.id, { active: !coupon.active })
      .then(() => showNotice(coupon.active ? 'تم تعطيل الكود' : 'تم تفعيل الكود'))
      .catch(() => {
        showNotice('فشل تحديث الكود')
        reload()
      })
  }

  const removeCoupon = (coupon: Coupon) => {
    if (!window.confirm(`حذف الكود «${coupon.code}» نهائياً؟`)) {
      return
    }
    setCoupons((list) => list.filter((entry) => entry.id !== coupon.id))
    void deleteCouponApi(pin, coupon.id)
      .then(() => showNotice('تم حذف الكود'))
      .catch(() => {
        showNotice('فشل حذف الكود')
        reload()
      })
  }

  const describeCoupon = (coupon: Coupon) => {
    const amount = coupon.kind === 'percent' ? `${coupon.value}%` : `${coupon.value}$`
    const storeLabel = coupon.appliesTo === 'all'
      ? 'كل المتاجر'
      : coupon.appliesTo === 'temu'
        ? 'Temu'
        : 'SHEIN'
    return `خصم ${amount} · ${storeLabel}`
  }

  return (
    <section className="panel coupons-panel">
      <header className="compact-panel-head">
        <h2>أكواد الخصم</h2>
        <button className="ghost-action" onClick={() => setShowForm((value) => !value)}>
          <Icon name={showForm ? 'close' : 'add'} />
          {showForm ? 'إغلاق' : 'إنشاء كود خصم'}
        </button>
      </header>

      {showForm && (
        <div className="card-box">
          <h3>إنشاء كود جديد</h3>
          <div className="coupon-form-grid">
            <label className="field">
              <span>الرمز</span>
              <input value={code} onChange={(event) => setCode(event.target.value.toUpperCase())} placeholder="WELCOME10" />
            </label>
            <label className="field">
              <span>النوع</span>
              <select value={kind} onChange={(event) => setKind(event.target.value as 'percent' | 'fixed')}>
                <option value="percent">نسبة مئوية</option>
                <option value="fixed">مبلغ ثابت بالدولار</option>
              </select>
            </label>
            <label className="field">
              <span>القيمة</span>
              <input type="number" min="0" step="1" value={value} onChange={(event) => setValue(event.target.value)} />
            </label>
            <label className="field">
              <span>المتجر</span>
              <select value={appliesTo} onChange={(event) => setAppliesTo(event.target.value as 'all' | 'shein' | 'temu')}>
                <option value="all">كل المتاجر</option>
                <option value="shein">SHEIN</option>
                <option value="temu">Temu</option>
              </select>
            </label>
            <label className="field">
              <span>الحد الأدنى (ل.س)</span>
              <input type="number" min="0" step="1000" value={minSubtotal} onChange={(event) => setMinSubtotal(event.target.value)} />
            </label>
            <label className="field">
              <span>عدد الاستخدامات</span>
              <input type="number" min="1" step="1" value={maxUses} onChange={(event) => setMaxUses(event.target.value)} placeholder="اختياري" />
            </label>
            <label className="field">
              <span>تاريخ الانتهاء</span>
              <input type="date" value={expiresAt} onChange={(event) => setExpiresAt(event.target.value)} />
            </label>
          </div>
          <button className="primary-btn" disabled={busy} onClick={createCoupon}>
            <Icon name="add" /> إنشاء الكود
          </button>
          <p className="coupon-hint">الاستخدام مرة واحدة لكل رقم هاتف ولكل جهاز.</p>
        </div>
      )}

      {!loaded ? (
        <p className="muted">جار تحميل الأكواد...</p>
      ) : coupons.length === 0 ? (
        <p className="muted">لا توجد أكواد بعد.</p>
      ) : (
        <div className="coupon-list">
          {coupons.map((coupon) => (
            <div className={`coupon-item${coupon.active ? '' : ' is-off'}`} key={coupon.id}>
              <div className="coupon-item-main">
                <strong className="coupon-code">{coupon.code}</strong>
                <span className="coupon-desc">{describeCoupon(coupon)}</span>
                <small className="coupon-meta">
                  استُخدم {coupon.usedCount}{coupon.maxUses ? ` / ${coupon.maxUses}` : ''}
                  {coupon.expiresAt ? ` · ينتهي ${new Date(coupon.expiresAt).toLocaleDateString('ar-SY')}` : ''}
                  {coupon.minSubtotalSyp ? ` · حد أدنى ${formatMoney(coupon.minSubtotalSyp)}` : ''}
                </small>
              </div>
              <div className="coupon-item-actions">
                <StatusBadge tone={coupon.active ? 'success' : 'neutral'}>
                  {coupon.active ? 'مفعل' : 'معطل'}
                </StatusBadge>
                <button className="icon-btn" onClick={() => toggleCoupon(coupon)} title={coupon.active ? 'تعطيل' : 'تفعيل'}>
                  <Icon name={coupon.active ? 'toggle_on' : 'toggle_off'} />
                </button>
                <button className="icon-btn danger" onClick={() => removeCoupon(coupon)} title="حذف">
                  <Icon name="delete" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  )
}

// ── Settings Panel ────────────────────────────────────────────────────────────
function SettingsPanel({
  pin,
  showNotice,
  onLogoutEverywhere,
}: {
  pin: string
  showNotice: (msg: string) => void
  onLogoutEverywhere: () => void
}) {
  const [sheinCost,  setSheinCost]  = useState('')
  const [temuCost,   setTemuCost]   = useState('')
  const [usdRate,    setUsdRate]    = useState('')
  const [sheinQr,     setSheinQr]    = useState('')
  const [temuQr,      setTemuQr]     = useState('')
  const [sheinCode,   setSheinCode]  = useState('')
  const [temuCode,    setTemuCode]   = useState('')
  const [referralDiscount, setReferralDiscount] = useState('0')
  const [productProfitPercent, setProductProfitPercent] = useState('0')
  const [featureGroupOrders, setFeatureGroupOrders] = useState(true)
  const [featureWallet, setFeatureWallet] = useState(true)
  const [featureCoupons, setFeatureCoupons] = useState(true)
  const [saving,     setSaving]     = useState(false)
  const [loaded,     setLoaded]     = useState(false)

  useEffect(() => {
    void fetchPublicSettings()
      .then((data) => {
        setSheinCost(data.shipping_cost_shein_syp ?? '90000')
        setTemuCost(data.shipping_cost_temu_syp ?? '90000')
        setUsdRate(data.usd_to_syp_rate ?? '13000')
        setSheinQr(data.shamcash_qr_shein_data_url ?? '')
        setTemuQr(data.shamcash_qr_temu_data_url ?? '')
        setSheinCode(data.shamcash_code_shein ?? '')
        setTemuCode(data.shamcash_code_temu ?? '')
        setReferralDiscount(data.referral_discount_syp ?? '0')
        setProductProfitPercent(data.product_profit_percent ?? '0')
        setFeatureGroupOrders(data.feature_group_orders !== 'false')
        setFeatureWallet(data.feature_wallet !== 'false')
        setFeatureCoupons(data.feature_coupons !== 'false')
        setLoaded(true)
      })
      .catch(() => showNotice('تعذر جلب الإعدادات'))
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const saveSetting = (key: string, value: string) => {
    setSaving(true)
    return fetch(APP_SETTINGS_FN, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-admin-pin': pin,
        apikey: ANON_KEY,
        authorization: `Bearer ${ANON_KEY}`,
      },
      body: JSON.stringify({ key, value }),
    })
      .then((r) => { if (!r.ok) throw new Error(); showNotice('تم حفظ الإعداد') })
      .catch(() => showNotice('فشل حفظ الإعداد'))
      .finally(() => setSaving(false))
  }

  const logoutAllDevices = () => {
    setSaving(true)
    void fetch(APP_SETTINGS_FN, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-admin-pin': pin,
        apikey: ANON_KEY,
        authorization: `Bearer ${ANON_KEY}`,
      },
      body: JSON.stringify({ key: 'admin_session_version', value: String(Date.now()) }),
    })
      .then((r) => {
        if (!r.ok) throw new Error()
        onLogoutEverywhere()
      })
      .catch(() => showNotice('فشل تسجيل الخروج من جميع الأجهزة'))
      .finally(() => setSaving(false))
  }

  const readQrFile = (file: File, onReady: (value: string) => void) => {
    if (!file.type.startsWith('image/')) {
      showNotice('اختر صورة للباركود')
      return
    }
    if (file.size > 900 * 1024) {
      showNotice('حجم صورة الباركود كبير، استخدم صورة أصغر')
      return
    }
    const reader = new FileReader()
    reader.onload = () => onReady(String(reader.result || ''))
    reader.onerror = () => showNotice('تعذر قراءة صورة الباركود')
    reader.readAsDataURL(file)
  }

  if (!loaded) return <section className="panel settings"><p>جار تحميل الإعدادات...</p></section>

  return (
    <section className="panel settings">
      <h2>إعدادات التشغيل</h2>
      <p className="settings-intro">هذه القيم تظهر مباشرة داخل التطبيق وتؤثر على تكلفة الطلب والدفع لكل من SHEIN وTemu.</p>

      <div className="settings-overview">
        <article>
          <span>سعر الصرف الحالي</span>
          <b>{usdRate || '13000'} ل.س</b>
          <small>لكل 1 USD</small>
        </article>
        <article>
          <span>شحن SHEIN</span>
          <b>{sheinCost || '0'} ل.س</b>
          <small>مفعل داخل التطبيق</small>
        </article>
        <article>
          <span>شحن Temu</span>
          <b>{temuCost || '0'} ل.س</b>
          <small>مفعل داخل التطبيق</small>
        </article>
        <article>
          <span>شام كاش</span>
          <b>{[sheinQr, temuQr].filter(Boolean).length}/2</b>
          <small>{[sheinQr, temuQr, sheinCode, temuCode].every(Boolean) ? 'الكود والباركود جاهزان' : 'يلزم استكمال الكود أو الباركود'}</small>
        </article>
      </div>

      <fieldset className="settings-group">
        <legend>تكلفة الشحن (بالليرة السورية)</legend>

        <label className="field">
          <span>شحن SHEIN</span>
          <div className="settings-row">
            <input
              type="number"
              min="0"
              step="500"
              value={sheinCost}
              onChange={(e) => setSheinCost(e.target.value)}
            />
            <button
              className="ghost-action"
              disabled={saving}
              onClick={() => void saveSetting('shipping_cost_shein_syp', sheinCost)}
            >
              حفظ
            </button>
          </div>
        </label>

        <label className="field">
          <span>شحن Temu</span>
          <div className="settings-row">
            <input
              type="number"
              min="0"
              step="500"
              value={temuCost}
              onChange={(e) => setTemuCost(e.target.value)}
            />
            <button
              className="ghost-action"
              disabled={saving}
              onClick={() => void saveSetting('shipping_cost_temu_syp', temuCost)}
            >
              حفظ
            </button>
          </div>
        </label>
      </fieldset>

      <fieldset className="settings-group">
        <legend>سعر الصرف</legend>
        <label className="field">
          <span>دولار → ليرة سورية</span>
          <div className="settings-row">
            <input
              type="number"
              min="0"
              step="100"
              value={usdRate}
              onChange={(e) => setUsdRate(e.target.value)}
            />
            <button
              className="ghost-action"
              disabled={saving}
              onClick={() => void saveSetting('usd_to_syp_rate', usdRate)}
            >
              حفظ
            </button>
          </div>
        </label>
      </fieldset>

      <fieldset className="settings-group">
        <legend>باركود شام كاش</legend>

        <div className="settings-qr-grid">
          <label className="field">
            <span>باركود SHEIN</span>
            <div className="settings-qr-preview">
              {sheinQr ? <img src={sheinQr} alt="باركود شام كاش لشي إن" /> : <Icon name="qr_code_2" />}
            </div>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => {
                const file = e.target.files?.[0]
                if (file) readQrFile(file, setSheinQr)
              }}
            />
            <div className="settings-row">
              <input
                value={sheinCode}
                onChange={(e) => setSheinCode(e.target.value)}
                placeholder="كود شام كاش لشي إن"
                dir="ltr"
              />
              <button
                className="ghost-action"
                disabled={saving}
                onClick={() => void saveSetting('shamcash_code_shein', sheinCode)}
              >
                حفظ الكود
              </button>
            </div>
            <div className="settings-row">
              <button
                className="ghost-action"
                disabled={saving}
                onClick={() => void saveSetting('shamcash_qr_shein_data_url', sheinQr)}
              >
                حفظ
              </button>
              <button
                className="ghost-action"
                disabled={saving}
                onClick={() => { setSheinQr(''); void saveSetting('shamcash_qr_shein_data_url', '') }}
              >
                مسح
              </button>
            </div>
          </label>

          <label className="field">
            <span>باركود Temu</span>
            <div className="settings-qr-preview">
              {temuQr ? <img src={temuQr} alt="باركود شام كاش لتيمو" /> : <Icon name="qr_code_2" />}
            </div>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => {
                const file = e.target.files?.[0]
                if (file) readQrFile(file, setTemuQr)
              }}
            />
            <div className="settings-row">
              <input
                value={temuCode}
                onChange={(e) => setTemuCode(e.target.value)}
                placeholder="كود شام كاش لتيمو"
                dir="ltr"
              />
              <button
                className="ghost-action"
                disabled={saving}
                onClick={() => void saveSetting('shamcash_code_temu', temuCode)}
              >
                حفظ الكود
              </button>
            </div>
            <div className="settings-row">
              <button
                className="ghost-action"
                disabled={saving}
                onClick={() => void saveSetting('shamcash_qr_temu_data_url', temuQr)}
              >
                حفظ
              </button>
              <button
                className="ghost-action"
                disabled={saving}
                onClick={() => { setTemuQr(''); void saveSetting('shamcash_qr_temu_data_url', '') }}
              >
                مسح
              </button>
            </div>
          </label>
        </div>
      </fieldset>

      <fieldset className="settings-group">
        <legend>ربح المنتجات</legend>
        <label className="field">
          <span>نسبة الربح المخفية على سعر المنتج</span>
          <div className="settings-row">
            <input
              type="number"
              min="0"
              step="0.1"
              value={productProfitPercent}
              onChange={(e) => setProductProfitPercent(e.target.value)}
              placeholder="مثال: 1"
            />
            <button
              className="ghost-action"
              disabled={saving}
              onClick={() => void saveSetting('product_profit_percent', productProfitPercent)}
            >
              حفظ
            </button>
          </div>
        </label>
        <p className="settings-intro">تُضاف هذه النسبة إلى سعر المنتج فقط، بدون إظهارها كسطر منفصل للزبون.</p>
      </fieldset>

      <fieldset className="settings-group">
        <legend>خصم الإحالة</legend>
        <label className="field">
          <span>قيمة خصم الإحالة بالليرة السورية</span>
          <div className="settings-row">
            <input
              type="number"
              min="0"
              step="1000"
              value={referralDiscount}
              onChange={(e) => setReferralDiscount(e.target.value)}
            />
            <button
              className="ghost-action"
              disabled={saving}
              onClick={() => void saveSetting('referral_discount_syp', referralDiscount)}
            >
              حفظ
            </button>
          </div>
        </label>
      </fieldset>

      <fieldset className="settings-group">
        <legend>تفعيل وتعطيل الميزات</legend>
        <p className="settings-intro">أوقف أو فعّل ميزات التطبيق. التغيير يظهر فوراً عند فتح التطبيق.</p>
        {([
          ['feature_group_orders', 'الطلب المشترك', featureGroupOrders, setFeatureGroupOrders] as const,
          ['feature_wallet', 'المحفظة', featureWallet, setFeatureWallet] as const,
          ['feature_coupons', 'الكوبونات', featureCoupons, setFeatureCoupons] as const,
        ]).map(([key, label, value, setter]) => (
          <label className="field" key={key} style={{ display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer' }}>
            <input
              type="checkbox"
              checked={value}
              onChange={(e) => {
                const next = e.target.checked
                setter(next)
                void saveSetting(key, String(next))
              }}
              style={{ width: 20, height: 20, accentColor: '#6366f1' }}
            />
            <span style={{ fontSize: 15 }}>{label}</span>
          </label>
        ))}
      </fieldset>

      <WhatsAppSessionsPanel pin={pin} showNotice={showNotice} />

      <fieldset className="settings-group">
        <legend>جلسة الإدارة</legend>
        <p className="settings-intro">سيبقى تسجيل الدخول محفوظًا على هذا الجهاز حتى تختار تسجيل الخروج من جميع الأجهزة.</p>
        <button className="danger-action" disabled={saving} onClick={logoutAllDevices}>
          <Icon name="logout" /> تسجيل الخروج من جميع الأجهزة
        </button>
      </fieldset>

      <fieldset className="settings-group">
        <legend>معلومات ثابتة</legend>
        <InfoRow label="المطابقة"      value="شام كاش B2B بالمبلغ الدقيق فقط" />
        <InfoRow label="الشحن الداخلي" value="القدموس" />
        <InfoRow label="مصدر الطلبات"  value="Supabase + Vercel API" />
      </fieldset>
    </section>
  )
}

// ── Info Row ──────────────────────────────────────────────────────────────────
function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="info-row">
      <span>{label}</span>
      <b>{value}</b>
    </div>
  )
}

// ── WhatsApp Sessions Panel ─────────────────────────────────────────────────

type WaSession = {
  id: string
  connected: boolean
  status: string
  phoneNumber: string | null
  label: string
  qrCode: string | null
  qrImageUrl: string | null
}

function WhatsAppSessionsPanel({ pin, showNotice }: { pin: string; showNotice: (msg: string) => void }) {
  const [sessions, setSessions] = useState<WaSession[]>([])
  const [loading, setLoading] = useState(true)
  const [adding, setAdding] = useState(false)

  const waFetch = (path: string, opts?: RequestInit) =>
    fetch(`${WA_API_BASE}/api${path}`, {
      ...opts,
      headers: {
        'content-type': 'application/json',
        'x-admin-pin': pin,
        ...(opts?.headers || {}),
      },
    })

  const loadSessions = () => {
    waFetch('/whatsapp/sessions')
      .then(r => r.json())
      .then(d => setSessions(d.sessions || []))
      .catch(() => showNotice('تعذر جلب جلسات واتساب'))
      .finally(() => setLoading(false))
  }

  useEffect(() => { loadSessions() }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // تحديث حالة QR كل 3 ثوانٍ إذا في جلسة بحالة qr أو connecting
  useEffect(() => {
    const hasActiveQr = sessions.some(s => s.status === 'qr' || s.status === 'connecting')
    if (!hasActiveQr) return
    const timer = setInterval(loadSessions, 3000)
    return () => clearInterval(timer)
  }, [sessions]) // eslint-disable-line react-hooks/exhaustive-deps

  const addSession = () => {
    setAdding(true)
    waFetch('/whatsapp/sessions', { method: 'POST', body: JSON.stringify({}) })
      .then(r => {
        if (!r.ok) throw new Error()
        showNotice('تم إنشاء جلسة جديدة — امسح QR لربط الرقم')
        loadSessions()
      })
      .catch(() => showNotice('فشل إنشاء جلسة واتساب'))
      .finally(() => setAdding(false))
  }

  const removeSessionById = (id: string) => {
    waFetch(`/whatsapp/sessions/${id}`, { method: 'DELETE' })
      .then(r => {
        if (!r.ok) throw new Error()
        setSessions(prev => prev.filter(s => s.id !== id))
        showNotice('تم حذف الرقم')
      })
      .catch(() => showNotice('فشل حذف الجلسة'))
  }

  const reconnectSession = (id: string) => {
    waFetch(`/whatsapp/sessions/${id}/reconnect`, { method: 'POST' })
      .then(() => { showNotice('جاري إعادة الاتصال...'); loadSessions() })
      .catch(() => showNotice('فشل إعادة الاتصال'))
  }

  if (!WA_API_BASE) {
    return (
      <fieldset className="settings-group">
        <legend>أرقام واتساب</legend>
        <p className="settings-intro">خدمة واتساب غير مربوطة. أضف VITE_WHATSAPP_API_URL في إعدادات المشروع.</p>
      </fieldset>
    )
  }

  return (
    <fieldset className="settings-group">
      <legend>أرقام واتساب (OTP + إشعارات)</legend>
      <p className="settings-intro">
        أضف أرقام واتساب لإرسال رموز التحقق وإشعارات الطلبات. لو فشل الأول يُستخدم الثاني تلقائياً.
      </p>

      {loading ? (
        <p>جاري التحميل...</p>
      ) : sessions.length === 0 ? (
        <p style={{ color: '#ef4444', fontSize: 14 }}>لا توجد أرقام مربوطة. أضف رقماً جديداً.</p>
      ) : (
        <div style={{ display: 'grid', gap: 12 }}>
          {sessions.map((s, i) => (
            <div key={s.id} style={{
              border: '1px solid #e5e7eb',
              borderRadius: 12,
              padding: 14,
              background: s.connected ? '#f0fdf4' : s.status === 'qr' ? '#fffbeb' : '#fef2f2',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                <span style={{
                  width: 10, height: 10, borderRadius: '50%',
                  background: s.connected ? '#22c55e' : s.status === 'qr' ? '#eab308' : '#ef4444',
                  flexShrink: 0,
                }} />
                <b style={{ flex: 1 }}>
                  {s.phoneNumber ? `+${s.phoneNumber}` : `رقم ${i + 1}`}
                  {s.connected && <span style={{ color: '#22c55e', fontWeight: 400, marginRight: 8 }}> — متصل</span>}
                  {s.status === 'qr' && <span style={{ color: '#eab308', fontWeight: 400, marginRight: 8 }}> — بانتظار مسح QR</span>}
                  {s.status === 'error' && <span style={{ color: '#ef4444', fontWeight: 400, marginRight: 8 }}> — غير متصل</span>}
                </b>
                <span style={{ color: '#9ca3af', fontSize: 12 }}>#{i + 1}</span>
              </div>

              {s.status === 'qr' && s.qrImageUrl && (
                <div style={{ textAlign: 'center', margin: '12px 0' }}>
                  <p style={{ fontSize: 13, color: '#92400e', marginBottom: 8 }}>
                    افتح واتساب ← النقاط الثلاث ← الأجهزة المرتبطة ← ربط جهاز ← امسح هذا الباركود
                  </p>
                  <img
                    src={s.qrImageUrl}
                    alt="QR Code"
                    style={{ width: 220, height: 220, borderRadius: 12, background: '#fff', border: '1px solid #e5e7eb' }}
                  />
                </div>
              )}

              {s.status === 'connecting' && (
                <p style={{ fontSize: 13, color: '#6b7280', textAlign: 'center' }}>جاري الاتصال...</p>
              )}

              <div className="settings-row" style={{ marginTop: 8 }}>
                {!s.connected && s.status !== 'qr' && s.status !== 'connecting' && (
                  <button className="ghost-action" onClick={() => reconnectSession(s.id)}>
                    إعادة اتصال
                  </button>
                )}
                <button
                  className="ghost-action"
                  style={{ color: '#ef4444' }}
                  onClick={() => { if (confirm('هل تريد حذف هذا الرقم؟')) removeSessionById(s.id) }}
                >
                  حذف
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      <button
        className="ghost-action"
        disabled={adding}
        onClick={addSession}
        style={{ marginTop: 12, width: '100%', justifyContent: 'center' }}
      >
        + إضافة رقم واتساب جديد
      </button>
    </fieldset>
  )
}

export default AdminApp
