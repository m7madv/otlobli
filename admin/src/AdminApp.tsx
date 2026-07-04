import { useEffect, useMemo, useState } from 'react'

type AdminTab = 'dashboard' | 'orders' | 'payments' | 'shipping' | 'customers' | 'drivers' | 'coupons' | 'settings'

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
  assignedDriverId: string
  rating?: number
  ratingNote?: string
  paymentIssue: boolean
  paymentIssueNote: string
  extraAmountUsd: number
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
const stripBom = (s: string | undefined) => (s || '').replace(/[​-‍﻿]/g, '').trim()
const SUPABASE_URL = stripBom(import.meta.env.VITE_SUPABASE_URL as string | undefined)
const ADMIN_ORDERS_FN   = `${SUPABASE_URL}/functions/v1/admin-orders`
const ADMIN_DRIVERS_FN  = `${SUPABASE_URL}/functions/v1/admin-drivers`
const APP_SETTINGS_FN   = `${SUPABASE_URL}/functions/v1/app-settings`
const ANON_KEY = stripBom(import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined)

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
  return { orders: payload.orders, drivers: payload.drivers ?? [] }
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

const ADMIN_COUPONS_FN = `${SUPABASE_URL}/functions/v1/admin-coupons`

const couponHeaders = (pin: string) => ({
  'content-type': 'application/json',
  'x-admin-pin': pin,
  apikey: ANON_KEY,
  authorization: `Bearer ${ANON_KEY}`,
})

async function fetchCoupons(pin: string): Promise<Coupon[]> {
  const r = await fetch(ADMIN_COUPONS_FN, { headers: couponHeaders(pin) })
  if (!r.ok) throw new Error('coupons_unavailable')
  const payload = (await r.json()) as { coupons: Coupon[] }
  return payload.coupons ?? []
}

async function createCouponApi(pin: string, input: {
  code: string; kind: 'percent' | 'fixed'; value: number; appliesTo: string
  maxUses: number | null; minSubtotalSyp: number; expiresAt: string | null
}): Promise<Coupon> {
  const r = await fetch(ADMIN_COUPONS_FN, { method: 'POST', headers: couponHeaders(pin), body: JSON.stringify(input) })
  if (!r.ok) {
    const err = (await r.json().catch(() => ({}))) as { error?: string }
    throw new Error(err.error || 'coupon_create_failed')
  }
  return ((await r.json()) as { coupon: Coupon }).coupon
}

async function patchCouponApi(pin: string, couponId: string, patch: { active?: boolean }) {
  const r = await fetch(ADMIN_COUPONS_FN, { method: 'PATCH', headers: couponHeaders(pin), body: JSON.stringify({ couponId, patch }) })
  if (!r.ok) throw new Error('coupon_update_failed')
}

async function deleteCouponApi(pin: string, couponId: string) {
  const r = await fetch(ADMIN_COUPONS_FN, { method: 'DELETE', headers: couponHeaders(pin), body: JSON.stringify({ couponId }) })
  if (!r.ok) throw new Error('coupon_delete_failed')
}

const ADMIN_USERS_FN = `${SUPABASE_URL}/functions/v1/admin-users`

type ActivityRow = { phone: string; name: string; city: string; deviceId: string; lastSeen: string; firstSeen: string }
type BlockedRow = { id: string; phone: string | null; deviceId: string | null; reason: string; createdAt: string }

async function fetchUsers(pin: string): Promise<{ activity: ActivityRow[]; blocked: BlockedRow[] }> {
  const r = await fetch(ADMIN_USERS_FN, { headers: couponHeaders(pin) })
  if (!r.ok) throw new Error('users_unavailable')
  return (await r.json()) as { activity: ActivityRow[]; blocked: BlockedRow[] }
}
async function blockUserApi(pin: string, target: { phone?: string; deviceId?: string; reason?: string }) {
  const r = await fetch(ADMIN_USERS_FN, { method: 'POST', headers: couponHeaders(pin), body: JSON.stringify(target) })
  if (!r.ok) { const e = (await r.json().catch(() => ({}))) as { error?: string }; throw new Error(e.error || 'block_failed') }
}
async function unblockUserApi(pin: string, target: { id?: string; phone?: string; deviceId?: string }) {
  const r = await fetch(ADMIN_USERS_FN, { method: 'DELETE', headers: couponHeaders(pin), body: JSON.stringify(target) })
  if (!r.ok) throw new Error('unblock_failed')
}

const ADMIN_WALLET_FN = `${SUPABASE_URL}/functions/v1/admin-wallet`
type WalletTx = { id: string; amountUsd: number; kind: string; note: string; orderId: string | null; createdAt: string }
async function fetchWallet(pin: string, phone: string): Promise<{ balanceUsd: number; transactions: WalletTx[] }> {
  const r = await fetch(`${ADMIN_WALLET_FN}?phone=${encodeURIComponent(phone)}`, { headers: couponHeaders(pin) })
  if (!r.ok) throw new Error('wallet_unavailable')
  return (await r.json()) as { balanceUsd: number; transactions: WalletTx[] }
}
async function walletTopup(pin: string, phone: string, amountUsd: number, note: string): Promise<number> {
  const r = await fetch(ADMIN_WALLET_FN, { method: 'POST', headers: couponHeaders(pin), body: JSON.stringify({ phone, amountUsd, note }) })
  if (!r.ok) throw new Error('topup_failed')
  return ((await r.json()) as { balanceUsd: number }).balanceUsd
}

function timeAgo(iso: string): string {
  if (!iso) return '—'
  const then = new Date(iso).getTime()
  if (Number.isNaN(then)) return '—'
  const mins = Math.floor((Date.now() - then) / 60000)
  if (mins < 1) return 'الآن'
  if (mins < 60) return `قبل ${mins} د`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `قبل ${hrs} س`
  const days = Math.floor(hrs / 24)
  return `قبل ${days} يوم`
}

// ── Main App ──────────────────────────────────────────────────────────────────
function AdminApp() {
  const [pinInput, setPinInput] = useState('')
  const [pin, setPin] = useState('')
  const [orders, setOrders] = useState<Order[]>([])
  const [driverOptions, setDriverOptions] = useState<DriverOption[]>([])
  const [selectedOrderId, setSelectedOrderId] = useState('')
  const [modalOrderId, setModalOrderId] = useState('')
  const [tab, setTab] = useState<AdminTab>('dashboard')
  const [search, setSearch] = useState('')
  const [notice, setNotice] = useState('')
  const [loading, setLoading] = useState(false)
  const [deepLinkOrderId, setDeepLinkOrderId] = useState('')
  const { tracked, toggle: toggleCart, markAll: markAllCart } = useCartTracked()

  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    const orderId = params.get('order')
    if (orderId) setDeepLinkOrderId(orderId)
  }, [])

  const selectedOrder = orders.find((o) => o.id === selectedOrderId) ?? orders[0]
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

  const unlock = () => {
    const nextPin = pinInput.trim()
    if (!nextPin) { showNotice('أدخل رمز الإدارة'); return }
    setLoading(true)
    void fetchOrders(nextPin)
      .then(({ orders: nextOrders, drivers: nextDrivers }) => {
        setPin(nextPin)
        setOrders(nextOrders)
        setDriverOptions(nextDrivers)
        const autoSelect = deepLinkOrderId && nextOrders.find((o) => o.id === deepLinkOrderId)
          ? deepLinkOrderId
          : nextOrders[0]?.id ?? ''
        setSelectedOrderId(autoSelect)
        if (deepLinkOrderId && autoSelect === deepLinkOrderId) {
          setTab('dashboard')
          setModalOrderId(deepLinkOrderId)
        }
        showNotice('تم فتح لوحة الإدارة')
      })
      .catch(() => showNotice('تعذر فتح لوحة الإدارة. تحقق من الرمز أو إعدادات السيرفر'))
      .finally(() => setLoading(false))
  }

  const refresh = () => {
    if (!pin) return
    setLoading(true)
    void fetchOrders(pin)
      .then(({ orders: nextOrders, drivers: nextDrivers }) => {
        setOrders(nextOrders)
        setDriverOptions(nextDrivers)
        showNotice('تم تحديث الطلبات')
      })
      .catch(() => showNotice('تعذر جلب الطلبات'))
      .finally(() => setLoading(false))
  }

  // تحديث تلقائي صامت كل 15 ثانية + تنبيه عند وصول طلب جديد
  useEffect(() => {
    if (!pin) return
    const interval = window.setInterval(() => {
      void fetchOrders(pin)
        .then(({ orders: nextOrders, drivers: nextDrivers }) => {
          setDriverOptions(nextDrivers)
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
  }, [pin])

  const updateOrder = (orderId: string, patch: Partial<Order>) => {
    setOrders((list) => list.map((o) => (o.id === orderId ? { ...o, ...patch } : o)))
    void patchOrder(pin, orderId, patch)
      .then(() => showNotice('تم تحديث الطلب'))
      .catch(() => { showNotice('فشل تحديث الطلب'); refresh() })
  }

  const deleteOrder = (orderId: string) => {
    if (!window.confirm(`حذف الطلب ${orderId} نهائياً؟ لا يمكن التراجع.`)) return
    setOrders((list) => list.filter((o) => o.id !== orderId))
    setModalOrderId('')
    void deleteOrderApi(pin, orderId)
      .then(() => showNotice('تم حذف الطلب'))
      .catch(() => { showNotice('فشل حذف الطلب'); refresh() })
  }

  const markPaid = (order: Order) => {
    updateOrder(order.id, { paymentStatus: 'مدفوع', statusIndex: Math.max(1, order.statusIndex), paidAt: today() })
  }

  const advanceOrder = (order: Order) => {
    const statusIndex = Math.min(order.statusIndex + 1, orderStatuses.length - 1)
    updateOrder(order.id, { statusIndex, paymentStatus: statusIndex > 0 ? 'مدفوع' : order.paymentStatus })
  }

  const openModal = (orderId: string) => {
    setSelectedOrderId(orderId)
    setModalOrderId(orderId)
  }

  if (!pin) {
    return (
      <main className="login-shell">
        <section className="login-card">
          <div className="brand"><span>طلبية</span><small>لوحة الإدارة</small></div>
          <h1>تسجيل دخول الإدارة</h1>
          <p>أدخل رمز الإدارة للوصول إلى الطلبات والمدفوعات والشحن.</p>
          <label className="field">
            <span>رمز الإدارة</span>
            <input
              value={pinInput}
              type="password"
              autoComplete="current-password"
              onChange={(e) => setPinInput(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') unlock() }}
            />
          </label>
          <button className="primary-action" disabled={loading} onClick={unlock}>
            {loading ? 'جار التحقق...' : 'فتح لوحة الإدارة'}
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
              <OrdersTable orders={filteredOrders.slice(0, 8)} tracked={tracked} onOpen={openModal} onMarkPaid={markPaid} />
              <OrderDetail order={selectedOrder} drivers={driverOptions} onOpen={openModal} onMarkPaid={markPaid} onAdvance={advanceOrder} onUpdate={updateOrder} />
            </section>
          </>
        )}
        {tab === 'orders' && <OrdersTable orders={filteredOrders} tracked={tracked} onOpen={openModal} onMarkPaid={markPaid} withFilter />}
        {tab === 'payments' && <OrdersTable orders={filteredOrders.filter((o) => o.paymentStatus !== 'مدفوع')} tracked={tracked} onOpen={openModal} onMarkPaid={markPaid} />}
        {tab === 'shipping' && <ShippingList orders={filteredOrders} drivers={driverOptions} onAdvance={advanceOrder} onUpdate={updateOrder} onOpen={openModal} />}
        {tab === 'customers' && <CustomersPanel orders={orders} pin={pin} showNotice={showNotice} />}
        {tab === 'drivers' && <DriversPanel pin={pin} showNotice={showNotice} />}
        {tab === 'coupons' && <CouponsPanel pin={pin} showNotice={showNotice} />}
        {tab === 'settings' && <SettingsPanel pin={pin} showNotice={showNotice} />}
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

// يستنتج التطبيق (المتجر) الذي طُلب منه من روابط عناصر الطلب.
function orderStore(order: Order): 'shein' | 'temu' | 'mixed' | '' {
  const links = (order.items ?? []).map((i) => (i.sourceLink || '').toLowerCase())
  const hasShein = links.some((l) => l.includes('shein'))
  const hasTemu = links.some((l) => l.includes('temu'))
  if (hasShein && hasTemu) return 'mixed'
  if (hasTemu) return 'temu'
  if (hasShein) return 'shein'
  return ''
}
function storeLabel(s: string) {
  return s === 'temu' ? 'Temu' : s === 'shein' ? 'SHEIN' : s === 'mixed' ? 'مختلط' : '—'
}

// ── Orders Table ──────────────────────────────────────────────────────────────
function OrdersTable({
  orders, tracked, onOpen, onMarkPaid, withFilter = false,
}: {
  orders: Order[]
  tracked: Set<string>
  onOpen: (orderId: string) => void
  onMarkPaid: (order: Order) => void
  withFilter?: boolean
}) {
  const [storeFilter, setStoreFilter] = useState<'all' | 'shein' | 'temu'>('all')
  const shown = withFilter && storeFilter !== 'all'
    ? orders.filter((o) => { const s = orderStore(o); return s === storeFilter || s === 'mixed' })
    : orders
  return (
    <section className="panel table-panel">
      <header>
        <h2>الطلبات</h2>
        <span>{shown.length} طلب</span>
      </header>
      {withFilter && (
        <div className="orders-filter">
          {([['all', 'الكل'], ['shein', 'SHEIN'], ['temu', 'Temu']] as const).map(([key, label]) => (
            <button
              key={key}
              className={`filter-chip${storeFilter === key ? ' is-active' : ''}`}
              onClick={() => setStoreFilter(key)}
            >
              {label}
            </button>
          ))}
        </div>
      )}
      <div className="table-scroll">
        <table>
          <thead>
            <tr>
              <th>رقم الطلب</th>
              <th>التطبيق</th>
              <th>العميل</th>
              <th>المبلغ</th>
              <th>الدفع</th>
              <th>الحالة</th>
              <th>السلة</th>
              <th>إجراء</th>
            </tr>
          </thead>
          <tbody>
            {shown.map((order) => {
              const items = order.items ?? []
              const addedCount = items.filter((_, i) => tracked.has(itemKey(order.id, i))).length
              const allAdded = items.length > 0 && addedCount === items.length
              return (
                <tr key={order.id} className={allAdded ? 'row-done' : ''}>
                  <td><b>{order.id}</b></td>
                  <td><span className={`store-tag store-tag--${orderStore(order) || 'none'}`}>{storeLabel(orderStore(order))}</span></td>
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
                      <button onClick={() => onOpen(order.id)} title="فتح تفاصيل الطلب"><Icon name="open_in_full" /></button>
                      {order.paymentStatus !== 'مدفوع' && <button onClick={() => onMarkPaid(order)}>تأكيد الدفع</button>}
                    </div>
                  </td>
                </tr>
              )
            })}
            {!shown.length && (
              <tr><td colSpan={8}>لا توجد طلبات مطابقة.</td></tr>
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
      <PaymentIssueField order={order} onUpdate={onUpdate} />
      <div className="detail-actions">
        <button className="primary-action" onClick={() => onMarkPaid(order)}>تأكيد الدفع</button>
        <button className="ghost-action" onClick={() => onAdvance(order)}>نقل للمرحلة التالية</button>
      </div>
    </section>
  )
}

// ── Payment Issue Field (admin marks a price/payment mismatch) ───────────────
function PaymentIssueField({ order, onUpdate }: { order: Order; onUpdate: (orderId: string, patch: Partial<Order>) => void }) {
  const [open, setOpen] = useState(order.paymentIssue)
  const [note, setNote] = useState(order.paymentIssueNote)
  const [amount, setAmount] = useState(String(order.extraAmountUsd || ''))

  useEffect(() => {
    setOpen(order.paymentIssue)
    setNote(order.paymentIssueNote)
    setAmount(String(order.extraAmountUsd || ''))
  }, [order.id, order.paymentIssue, order.paymentIssueNote, order.extraAmountUsd])

  const save = (issue: boolean) => {
    onUpdate(order.id, {
      paymentIssue: issue,
      paymentIssueNote: note,
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
        <span>مشكلة دفع / سعر خاطئ</span>
      </label>
      {open && (
        <>
          <textarea
            placeholder="ملاحظة: أي منتج وليش الفرق بالسعر"
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
          <input
            type="number"
            min="0"
            step="0.01"
            placeholder="المبلغ المتبقي بالدولار"
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
function CustomersPanel({ orders, pin, showNotice }: { orders: Order[]; pin: string; showNotice: (m: string) => void }) {
  const [q, setQ] = useState('')
  const [openPhone, setOpenPhone] = useState('')
  const [activity, setActivity] = useState<Record<string, ActivityRow>>({})
  const [blocked, setBlocked] = useState<BlockedRow[]>([])
  const [wallet, setWallet] = useState<{ balanceUsd: number; transactions: WalletTx[] } | null>(null)
  const [walletAmt, setWalletAmt] = useState('')

  useEffect(() => {
    if (!openPhone) { setWallet(null); return }
    setWallet(null); setWalletAmt('')
    void fetchWallet(pin, openPhone).then(setWallet).catch(() => setWallet({ balanceUsd: 0, transactions: [] }))
  }, [openPhone, pin])

  const addFunds = (phone: string, sign: 1 | -1) => {
    const amt = parseFloat(walletAmt)
    if (!(amt > 0)) { showNotice('أدخل مبلغاً صحيحاً'); return }
    void walletTopup(pin, phone, sign * amt, sign > 0 ? 'شحن من الإدارة' : 'خصم من الإدارة')
      .then((bal) => { setWalletAmt(''); showNotice(`تم — الرصيد ${bal.toFixed(2)}$`); void fetchWallet(pin, phone).then(setWallet) })
      .catch(() => showNotice('فشل تعديل الرصيد'))
  }

  const loadUsers = () => {
    void fetchUsers(pin)
      .then((u) => {
        const act: Record<string, ActivityRow> = {}
        for (const a of u.activity) act[a.phone] = a
        setActivity(act)
        setBlocked(u.blocked)
      })
      .catch(() => undefined)
  }
  useEffect(loadUsers, []) // eslint-disable-line react-hooks/exhaustive-deps

  const blockedPhones = new Set(blocked.map((b) => b.phone).filter(Boolean) as string[])
  const isBlocked = (phone: string) => blockedPhones.has(phone)

  const blockCustomer = (phone: string, deviceId: string) => {
    if (!window.confirm(`حظر هذا المستخدم؟ سيُحظر برقمه${deviceId ? ' وبجهازه' : ''} ولن يستطيع استخدام التطبيق.`)) return
    void blockUserApi(pin, { phone, deviceId: deviceId || undefined, reason: 'حظر من لوحة الإدارة' })
      .then(() => { showNotice('تم حظر المستخدم'); loadUsers() })
      .catch((e: Error) => showNotice(e.message === 'already_blocked' ? 'محظور مسبقاً' : 'فشل الحظر'))
  }
  const unblockCustomer = (phone: string) => {
    void unblockUserApi(pin, { phone })
      .then(() => { showNotice('تم فك الحظر'); loadUsers() })
      .catch(() => showNotice('فشل فك الحظر'))
  }

  // تجميع الطلبات حسب رقم الهاتف مع إحصاءات لكل عميل (عدد الطلبات، إجمالي
  // ما دفعه، آخر طلب) — لوحة عملاء حقيقية لا مجرد بطاقات.
  const customers = useMemo(() => {
    const map = new Map<string, { name: string; phone: string; city: string; orders: Order[]; spent: number; last: string }>()
    for (const o of orders) {
      const c = map.get(o.phone) ?? { name: o.customer, phone: o.phone, city: o.city, orders: [], spent: 0, last: o.createdAt }
      c.orders.push(o)
      if (o.paymentStatus === 'مدفوع') c.spent += o.total ?? 0
      if (o.createdAt > c.last) c.last = o.createdAt
      if (!c.name && o.customer) c.name = o.customer
      map.set(o.phone, c)
    }
    return Array.from(map.values()).sort((a, b) => (a.last > b.last ? -1 : 1))
  }, [orders])

  const term = q.trim()
  const filtered = term ? customers.filter((c) => `${c.name} ${c.phone} ${c.city}`.includes(term)) : customers

  return (
    <section className="panel customers-panel">
      <header className="customers-head">
        <h2>العملاء ({customers.length})</h2>
        <input
          className="customer-search"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="بحث بالاسم أو الرقم..."
        />
      </header>

      {filtered.length === 0 ? (
        <p className="muted">لا يوجد عملاء مطابقون.</p>
      ) : (
        <ul className="customer-rows">
          {filtered.map((c) => {
            const open = openPhone === c.phone
            const waPhone = c.phone.replace(/[^0-9]/g, '')
            return (
              <li className={`customer-row${open ? ' is-open' : ''}${isBlocked(c.phone) ? ' is-blocked' : ''}`} key={c.phone}>
                <button className="customer-row-main" onClick={() => setOpenPhone(open ? '' : c.phone)}>
                  <span className="cr-avatar">{c.name?.[0] ?? 'ط'}</span>
                  <span className="cr-info">
                    <strong>{c.name || 'عميل'}{isBlocked(c.phone) && <span className="blocked-tag">محظور</span>}</strong>
                    <small>{c.phone} · {c.city} · آخر ظهور: {timeAgo(activity[c.phone]?.lastSeen ?? '')}</small>
                  </span>
                  <span className="cr-stats">
                    <b>{c.orders.length}</b>
                    <em>{formatMoney(c.spent)}</em>
                  </span>
                  <Icon name={open ? 'expand_less' : 'expand_more'} />
                </button>

                {open && (
                  <div className="customer-detail">
                    <div className="customer-detail-actions">
                      <a className="mini-btn" href={`https://wa.me/${waPhone}`} target="_blank" rel="noreferrer">
                        <Icon name="chat" /> واتساب
                      </a>
                      <CopyBtn text={c.phone} />
                      {isBlocked(c.phone) ? (
                        <button className="mini-btn" onClick={() => unblockCustomer(c.phone)}><Icon name="lock_open" /> فك الحظر</button>
                      ) : (
                        <button className="mini-btn danger" onClick={() => blockCustomer(c.phone, activity[c.phone]?.deviceId ?? '')}><Icon name="block" /> حظر</button>
                      )}
                      <span className="muted">آخر طلب: {c.last}</span>
                    </div>
                    <div className="wallet-box">
                      <div className="wallet-head">
                        <span><Icon name="account_balance_wallet" /> المحفظة</span>
                        <b>{wallet ? `${wallet.balanceUsd.toFixed(2)}$` : '...'}</b>
                      </div>
                      <div className="wallet-add">
                        <input type="number" min="0" step="0.5" value={walletAmt} onChange={(e) => setWalletAmt(e.target.value)} placeholder="مبلغ بالدولار" />
                        <button className="mini-btn" onClick={() => addFunds(c.phone, 1)}><Icon name="add" /> شحن</button>
                        <button className="mini-btn danger" onClick={() => addFunds(c.phone, -1)}><Icon name="remove" /> خصم</button>
                      </div>
                      {wallet && wallet.transactions.length > 0 && (
                        <div className="wallet-tx">
                          {wallet.transactions.slice(0, 6).map((t) => (
                            <div className="wallet-tx-row" key={t.id}>
                              <span className={t.amountUsd >= 0 ? 'pos' : 'neg'}>{t.amountUsd >= 0 ? '+' : ''}{t.amountUsd.toFixed(2)}$</span>
                              <small>{t.note || t.kind}</small>
                              <small className="muted">{new Date(t.createdAt).toLocaleDateString('ar-SY')}</small>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                    <div className="customer-orders">
                      {c.orders.map((o) => (
                        <div className="customer-order" key={o.id}>
                          <strong>{o.id}</strong>
                          <StatusBadge tone={o.paymentStatus === 'مدفوع' ? 'success' : 'pending'}>
                            {orderStatuses[o.statusIndex] ?? o.paymentStatus}
                          </StatusBadge>
                          <span>{formatMoney(o.total)}</span>
                          <small>{o.createdAt}</small>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </li>
            )
          })}
        </ul>
      )}
    </section>
  )
}

// ── Drivers Panel ─────────────────────────────────────────────────────────────
function DriversPanel({ pin, showNotice }: { pin: string; showNotice: (message: string) => void }) {
  const [drivers, setDrivers] = useState<Driver[]>([])
  const [loading, setLoading] = useState(false)
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

  useEffect(() => { load() }, []) // eslint-disable-line react-hooks/exhaustive-deps

  const addDriver = () => {
    const trimmedName = name.trim()
    const trimmedPhone = phone.trim()
    const trimmedCode = loginCode.trim()
    if (!trimmedName) { showNotice('أدخل اسم السواق'); return }
    setLoading(true)
    void createDriver(pin, trimmedName, trimmedPhone, trimmedCode)
      .then(() => {
        setName(''); setPhone(''); setLoginCode('')
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
    if (!window.confirm(`حذف السواق «${driver.name}» نهائياً؟ طلباته المكلَّفة تصبح بلا تكليف.`)) return
    setDrivers((list) => list.filter((d) => d.id !== driver.id))
    void deleteDriver(pin, driver.id)
      .then(() => showNotice('تم حذف السواق'))
      .catch(() => { showNotice('فشل حذف السواق'); load() })
  }

  return (
    <section className="panel table-panel drivers-panel">
      <header>
        <h2>السواقين</h2>
        <span>{drivers.length} سواق</span>
      </header>

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
                    <button className="icon-btn danger" onClick={() => removeDriver(driver)} title="حذف السواق"><Icon name="delete" /></button>
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

// ── Coupons Panel ─────────────────────────────────────────────────────────────
function CouponsPanel({ pin, showNotice }: { pin: string; showNotice: (msg: string) => void }) {
  const [coupons, setCoupons] = useState<Coupon[]>([])
  const [loaded, setLoaded] = useState(false)
  const [busy, setBusy] = useState(false)

  const [code, setCode] = useState('')
  const [kind, setKind] = useState<'percent' | 'fixed'>('percent')
  const [value, setValue] = useState('')
  const [appliesTo, setAppliesTo] = useState<'all' | 'shein' | 'temu'>('all')
  const [minSubtotal, setMinSubtotal] = useState('')
  const [maxUses, setMaxUses] = useState('')
  const [expiresAt, setExpiresAt] = useState('')

  const reload = () => {
    void fetchCoupons(pin)
      .then((list) => { setCoupons(list); setLoaded(true) })
      .catch(() => { setLoaded(true); showNotice('تعذّر جلب الأكواد — تأكّد من نشر دالة admin-coupons') })
  }
  useEffect(reload, []) // eslint-disable-line react-hooks/exhaustive-deps

  const createCoupon = () => {
    const c = code.trim()
    const v = Number(value)
    if (!c || !(v > 0)) { showNotice('أدخل رمزاً وقيمة صحيحة'); return }
    if (kind === 'percent' && v > 100) { showNotice('النسبة يجب أن تكون 100 أو أقل'); return }
    setBusy(true)
    void createCouponApi(pin, {
      code: c,
      kind,
      value: v,
      appliesTo,
      maxUses: maxUses.trim() ? Number(maxUses) : null,
      minSubtotalSyp: minSubtotal.trim() ? Number(minSubtotal) : 0,
      expiresAt: expiresAt.trim() ? new Date(expiresAt).toISOString() : null,
    })
      .then((created) => {
        setCoupons((list) => [created, ...list])
        setCode(''); setValue(''); setMinSubtotal(''); setMaxUses(''); setExpiresAt('')
        showNotice('تم إنشاء الكود')
      })
      .catch((e: Error) => showNotice(e.message === 'code_exists' ? 'هذا الرمز مستخدم مسبقاً' : 'فشل إنشاء الكود'))
      .finally(() => setBusy(false))
  }

  const toggleActive = (c: Coupon) => {
    setCoupons((list) => list.map((x) => (x.id === c.id ? { ...x, active: !x.active } : x)))
    void patchCouponApi(pin, c.id, { active: !c.active })
      .then(() => showNotice(c.active ? 'تم تعطيل الكود' : 'تم تفعيل الكود'))
      .catch(() => { showNotice('فشل التحديث'); reload() })
  }

  const removeCoupon = (c: Coupon) => {
    if (!window.confirm(`حذف الكود «${c.code}» نهائياً؟`)) return
    setCoupons((list) => list.filter((x) => x.id !== c.id))
    void deleteCouponApi(pin, c.id).then(() => showNotice('تم حذف الكود')).catch(() => { showNotice('فشل الحذف'); reload() })
  }

  const describe = (c: Coupon) => {
    const amount = c.kind === 'percent' ? `${c.value}%` : `${c.value}$`
    const store = c.appliesTo === 'all' ? 'كل المتاجر' : c.appliesTo === 'temu' ? 'Temu' : 'SHEIN'
    return `خصم ${amount} · ${store}`
  }

  return (
    <section className="panel coupons-panel">
      <h2>أكواد الخصم</h2>

      <div className="coupon-create card-box">
        <h3>إنشاء كود جديد</h3>
        <div className="coupon-form-grid">
          <label className="field">
            <span>الرمز</span>
            <input value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} placeholder="WELCOME10" />
          </label>
          <label className="field">
            <span>النوع</span>
            <select value={kind} onChange={(e) => setKind(e.target.value as 'percent' | 'fixed')}>
              <option value="percent">نسبة مئوية %</option>
              <option value="fixed">مبلغ ثابت $</option>
            </select>
          </label>
          <label className="field">
            <span>{kind === 'percent' ? 'النسبة (1-100)' : 'المبلغ بالدولار'}</span>
            <input type="number" min="0" value={value} onChange={(e) => setValue(e.target.value)} placeholder={kind === 'percent' ? '10' : '5'} />
          </label>
          <label className="field">
            <span>ينطبق على</span>
            <select value={appliesTo} onChange={(e) => setAppliesTo(e.target.value as 'all' | 'shein' | 'temu')}>
              <option value="all">كل المتاجر</option>
              <option value="shein">SHEIN فقط</option>
              <option value="temu">Temu فقط</option>
            </select>
          </label>
          <label className="field">
            <span>حد أدنى للطلب (ل.س) — اختياري</span>
            <input type="number" min="0" value={minSubtotal} onChange={(e) => setMinSubtotal(e.target.value)} placeholder="0" />
          </label>
          <label className="field">
            <span>سقف الاستخدام الإجمالي — اختياري</span>
            <input type="number" min="0" value={maxUses} onChange={(e) => setMaxUses(e.target.value)} placeholder="بلا حد" />
          </label>
          <label className="field">
            <span>تاريخ الانتهاء — اختياري</span>
            <input type="date" value={expiresAt} onChange={(e) => setExpiresAt(e.target.value)} />
          </label>
        </div>
        <button className="primary-btn" disabled={busy} onClick={createCoupon}>
          <Icon name="add" /> إنشاء الكود
        </button>
        <p className="coupon-hint">الاستخدام مرّة واحدة لكل رقم هاتف ولكل جهاز (منع الاحتيال تلقائي).</p>
      </div>

      {!loaded ? (
        <p className="muted">جارِ تحميل الأكواد...</p>
      ) : coupons.length === 0 ? (
        <p className="muted">لا توجد أكواد بعد — أنشئ أول كود من الأعلى.</p>
      ) : (
        <div className="coupon-list">
          {coupons.map((c) => (
            <div className={`coupon-item${c.active ? '' : ' is-off'}`} key={c.id}>
              <div className="coupon-item-main">
                <strong className="coupon-code">{c.code}</strong>
                <span className="coupon-desc">{describe(c)}</span>
                <small className="coupon-meta">
                  استُخدم {c.usedCount}{c.maxUses ? ` / ${c.maxUses}` : ''}
                  {c.expiresAt ? ` · ينتهي ${new Date(c.expiresAt).toLocaleDateString('ar-SY')}` : ''}
                  {c.minSubtotalSyp ? ` · حد أدنى ${formatMoney(c.minSubtotalSyp)}` : ''}
                </small>
              </div>
              <div className="coupon-item-actions">
                <StatusBadge tone={c.active ? 'success' : 'neutral'}>{c.active ? 'مُفعّل' : 'مُعطّل'}</StatusBadge>
                <button className="icon-btn" onClick={() => toggleActive(c)} title={c.active ? 'تعطيل' : 'تفعيل'}>
                  <Icon name={c.active ? 'toggle_on' : 'toggle_off'} />
                </button>
                <button className="icon-btn danger" onClick={() => removeCoupon(c)} title="حذف">
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
function SettingsPanel({ pin, showNotice }: { pin: string; showNotice: (msg: string) => void }) {
  const [sheinCost,  setSheinCost]  = useState('')
  const [temuCost,   setTemuCost]   = useState('')
  const [usdRate,    setUsdRate]    = useState('')
  const [profit,     setProfit]     = useState('')
  const [shamCode,   setShamCode]   = useState('')
  const [shamBarcode, setShamBarcode] = useState('')
  const [saving,     setSaving]     = useState(false)
  const [loaded,     setLoaded]     = useState(false)

  useEffect(() => {
    void fetch(APP_SETTINGS_FN, {
      headers: { apikey: ANON_KEY, authorization: `Bearer ${ANON_KEY}` },
    })
      .then((r) => r.json() as Promise<Record<string, string>>)
      .then((data) => {
        setSheinCost(data.shipping_cost_shein_syp ?? '90000')
        setTemuCost(data.shipping_cost_temu_syp ?? '90000')
        setUsdRate(data.usd_to_syp_rate ?? '13000')
        setProfit(data.profit_margin_percent ?? '0')
        setShamCode(data.shamcash_code ?? '')
        setShamBarcode(data.shamcash_barcode ?? '')
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

  if (!loaded) return <section className="panel settings"><p>جار تحميل الإعدادات...</p></section>

  return (
    <section className="panel settings">
      <h2>إعدادات التشغيل</h2>

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
        <legend>نسبة الربح (%)</legend>
        <label className="field">
          <span>تُضاف على سعر المنتج</span>
          <div className="settings-row">
            <input
              type="number"
              min="0"
              step="1"
              value={profit}
              onChange={(e) => setProfit(e.target.value)}
            />
            <button
              className="ghost-action"
              disabled={saving}
              onClick={() => void saveSetting('profit_margin_percent', profit)}
            >
              حفظ
            </button>
          </div>
        </label>
      </fieldset>

      <fieldset className="settings-group">
        <legend>الدفع — شام كاش (باركود + كود)</legend>
        <label className="field">
          <span>كود شام كاش (رقم الحساب/الكود الذي يحوّل إليه الزبون)</span>
          <div className="settings-row">
            <input value={shamCode} onChange={(e) => setShamCode(e.target.value)} placeholder="مثال: 0900000000" />
            <button className="ghost-action" disabled={saving} onClick={() => void saveSetting('shamcash_code', shamCode)}>حفظ</button>
          </div>
        </label>
        <label className="field">
          <span>رابط صورة الباركود (اختياري — يظهر للزبون في شاشة الدفع)</span>
          <div className="settings-row">
            <input value={shamBarcode} onChange={(e) => setShamBarcode(e.target.value)} placeholder="https://.../barcode.png" />
            <button className="ghost-action" disabled={saving} onClick={() => void saveSetting('shamcash_barcode', shamBarcode)}>حفظ</button>
          </div>
        </label>
        {shamBarcode && <img className="barcode-preview" src={shamBarcode} alt="باركود شام كاش" />}
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

export default AdminApp
