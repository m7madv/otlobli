import { useEffect, useMemo, useState } from 'react'

type AdminTab = 'dashboard' | 'orders' | 'payments' | 'shipping' | 'customers' | 'drivers' | 'settings'
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
const ADMIN_ORDERS_FN = `${SUPABASE_URL}/functions/v1/admin-orders`
const ADMIN_DRIVERS_FN = `${SUPABASE_URL}/functions/v1/admin-drivers`
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
        <a className="customer-link" href="https://talabieh.vercel.app" rel="noreferrer" target="_blank">
          فتح تطبيق الزبون
        </a>
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
              <StatCard icon="local_shipping" label="قيد الشحن" value={stats.shippingOrders.length.toString()} note="الأردن إلى سوريا" />
              <StatCard icon="monetization_on" label="إجمالي المبيعات" value={formatMoney(stats.sales)} note="طلبات مدفوعة" dark />
            </section>
            <section className="content-grid">
              <OrdersTable orders={filteredOrders.slice(0, 8)} tracked={tracked} onOpen={openModal} onMarkPaid={markPaid} />
              <OrderDetail order={selectedOrder} drivers={driverOptions} onOpen={openModal} onMarkPaid={markPaid} onAdvance={advanceOrder} onUpdate={updateOrder} />
            </section>
          </>
        )}
        {tab === 'orders' && <OrdersTable orders={filteredOrders} tracked={tracked} onOpen={openModal} onMarkPaid={markPaid} />}
        {tab === 'payments' && <OrdersTable orders={filteredOrders.filter((o) => o.paymentStatus !== 'مدفوع')} tracked={tracked} onOpen={openModal} onMarkPaid={markPaid} />}
        {tab === 'shipping' && <ShippingList orders={filteredOrders} drivers={driverOptions} onAdvance={advanceOrder} onUpdate={updateOrder} onOpen={openModal} />}
        {tab === 'customers' && <CustomersGrid orders={orders} />}
        {tab === 'drivers' && <DriversPanel pin={pin} showNotice={showNotice} />}
        {tab === 'settings' && (
          <section className="panel settings">
            <h2>إعدادات التشغيل</h2>
            <p>تعديل إعدادات الدفع والشحن الدائم سيتم عبر لوحة إعدادات مخصصة لاحقاً.</p>
            <InfoRow label="المطابقة" value="شام كاش B2B بالمبلغ الدقيق فقط" />
            <InfoRow label="الشحن الداخلي" value="القدموس" />
            <InfoRow label="مصدر الطلبات" value="Supabase + Vercel API" />
          </section>
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
  orders, tracked, onOpen, onMarkPaid,
}: {
  orders: Order[]
  tracked: Set<string>
  onOpen: (orderId: string) => void
  onMarkPaid: (order: Order) => void
}) {
  return (
    <section className="panel table-panel">
      <header>
        <h2>الطلبات</h2>
        <span>{orders.length} طلب</span>
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
              return (
                <tr key={order.id} className={allAdded ? 'row-done' : ''}>
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
                      <button onClick={() => onOpen(order.id)} title="فتح تفاصيل الطلب"><Icon name="open_in_full" /></button>
                      {order.paymentStatus !== 'مدفوع' && <button onClick={() => onMarkPaid(order)}>تأكيد الدفع</button>}
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
      <div className="detail-actions">
        <button className="primary-action" onClick={() => onMarkPaid(order)}>تأكيد الدفع</button>
        <button className="ghost-action" onClick={() => onAdvance(order)}>نقل للمرحلة التالية</button>
      </div>
    </section>
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
function CustomersGrid({ orders }: { orders: Order[] }) {
  const customers = Array.from(new Map(orders.map((o) => [o.phone, o])).values())
  return (
    <section className="customers">
      {customers.map((order) => (
        <article className="panel customer" key={order.phone}>
          <div className="avatar">{order.customer[0] ?? 'ط'}</div>
          <h2>{order.customer}</h2>
          <span className="phone-row">{order.phone}<CopyBtn text={order.phone} /></span>
          <p>{order.city}</p>
        </article>
      ))}
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
                  <button onClick={() => toggleActive(driver)}>{driver.isActive ? 'تعطيل' : 'تفعيل'}</button>
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
