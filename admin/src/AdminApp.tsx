import { useMemo, useState } from 'react'

type AdminTab = 'dashboard' | 'orders' | 'payments' | 'shipping' | 'customers' | 'settings'
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

type OrdersResponse = {
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
  return `${value.toLocaleString('ar-SY')} ل.س`
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

async function fetchOrders(pin: string) {
  const response = await fetch('/api/admin/orders', {
    headers: {
      'x-admin-pin': pin,
    },
  })

  if (!response.ok) {
    throw new Error('orders_unavailable')
  }

  const payload = (await response.json()) as OrdersResponse
  return payload.orders
}

async function patchOrder(pin: string, orderId: string, patch: Partial<Order>) {
  const response = await fetch('/api/admin/orders', {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      'x-admin-pin': pin,
    },
    body: JSON.stringify({ orderId, patch }),
  })

  if (!response.ok) {
    throw new Error('order_update_failed')
  }
}

function AdminApp() {
  const [pinInput, setPinInput] = useState('')
  const [pin, setPin] = useState('')
  const [orders, setOrders] = useState<Order[]>([])
  const [selectedOrderId, setSelectedOrderId] = useState('')
  const [tab, setTab] = useState<AdminTab>('dashboard')
  const [search, setSearch] = useState('')
  const [notice, setNotice] = useState('')
  const [loading, setLoading] = useState(false)

  const selectedOrder = orders.find((order) => order.id === selectedOrderId) ?? orders[0]
  const filteredOrders = orders.filter((order) => {
    const haystack = `${order.id} ${order.customer} ${order.phone} ${order.city} ${order.paymentStatus} ${orderStatuses[order.statusIndex] ?? ''}`
    return haystack.includes(search.trim())
  })

  const stats = useMemo(() => {
    const paidOrders = orders.filter((order) => order.paymentStatus === 'مدفوع')
    const pendingPayments = orders.filter((order) => order.paymentStatus === 'بانتظار الدفع')
    const shippingOrders = orders.filter((order) => order.statusIndex >= 6 && order.statusIndex < 9)
    const sales = paidOrders.reduce((sum, order) => sum + order.total, 0)

    return { paidOrders, pendingPayments, shippingOrders, sales }
  }, [orders])

  const showNotice = (message: string) => {
    setNotice(message)
    window.setTimeout(() => setNotice(''), 2200)
  }

  const unlock = () => {
    const nextPin = pinInput.trim()

    if (!nextPin) {
      showNotice('أدخل رمز الإدارة')
      return
    }

    setLoading(true)
    void fetchOrders(nextPin)
      .then((nextOrders) => {
        setPin(nextPin)
        setOrders(nextOrders)
        setSelectedOrderId(nextOrders[0]?.id ?? '')
        showNotice('تم فتح لوحة الإدارة')
      })
      .catch(() => showNotice('تعذر فتح لوحة الإدارة. تحقق من الرمز أو إعدادات السيرفر'))
      .finally(() => setLoading(false))
  }

  const refresh = () => {
    if (!pin) {
      return
    }

    setLoading(true)
    void fetchOrders(pin)
      .then((nextOrders) => {
        setOrders(nextOrders)
        showNotice('تم تحديث الطلبات')
      })
      .catch(() => showNotice('تعذر جلب الطلبات'))
      .finally(() => setLoading(false))
  }

  const updateOrder = (orderId: string, patch: Partial<Order>) => {
    setOrders((list) => list.map((order) => (order.id === orderId ? { ...order, ...patch } : order)))
    void patchOrder(pin, orderId, patch)
      .then(() => showNotice('تم تحديث الطلب'))
      .catch(() => {
        showNotice('فشل تحديث الطلب')
        refresh()
      })
  }

  const markPaid = (order: Order) => {
    updateOrder(order.id, {
      paymentStatus: 'مدفوع',
      statusIndex: Math.max(1, order.statusIndex),
      paidAt: today(),
    })
  }

  const advanceOrder = (order: Order) => {
    const statusIndex = Math.min(order.statusIndex + 1, orderStatuses.length - 1)
    updateOrder(order.id, {
      statusIndex,
      paymentStatus: statusIndex > 0 ? 'مدفوع' : order.paymentStatus,
    })
  }

  if (!pin) {
    return (
      <main className="login-shell">
        <section className="login-card">
          <div className="brand">
            <span>طلبية</span>
            <small>لوحة الإدارة</small>
          </div>
          <h1>تسجيل دخول الإدارة</h1>
          <p>أدخل رمز الإدارة للوصول إلى الطلبات والمدفوعات والشحن.</p>
          <label className="field">
            <span>رمز الإدارة</span>
            <input
              value={pinInput}
              type="password"
              autoComplete="current-password"
              onChange={(event) => setPinInput(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') {
                  unlock()
                }
              }}
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
        <div className="brand">
          <span>طلبية</span>
          <small>إدارة العمليات</small>
        </div>
        {[
          ['dashboard', 'لوحة التحكم', 'dashboard'],
          ['orders', 'الطلبات', 'receipt_long'],
          ['payments', 'المدفوعات', 'payments'],
          ['shipping', 'الشحن', 'local_shipping'],
          ['customers', 'العملاء', 'group'],
          ['settings', 'الإعدادات', 'settings'],
        ].map(([key, label, icon]) => (
          <button className={tab === key ? 'is-active' : ''} key={key} onClick={() => setTab(key as AdminTab)}>
            <Icon name={icon} />
            {label}
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
            <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="بحث عن طلب أو عميل..." />
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
              <OrdersTable orders={filteredOrders.slice(0, 8)} onSelect={setSelectedOrderId} onMarkPaid={markPaid} />
              <OrderDetail order={selectedOrder} onMarkPaid={markPaid} onAdvance={advanceOrder} onUpdate={updateOrder} />
            </section>
          </>
        )}
        {tab === 'orders' && <OrdersTable orders={filteredOrders} onSelect={setSelectedOrderId} onMarkPaid={markPaid} />}
        {tab === 'payments' && <OrdersTable orders={filteredOrders.filter((order) => order.paymentStatus !== 'مدفوع')} onSelect={setSelectedOrderId} onMarkPaid={markPaid} />}
        {tab === 'shipping' && (
          <ShippingList orders={filteredOrders} onAdvance={advanceOrder} onUpdate={updateOrder} />
        )}
        {tab === 'customers' && <CustomersGrid orders={orders} />}
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
      {notice && <div className="toast">{notice}</div>}
    </div>
  )
}

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

function OrdersTable({ orders, onSelect, onMarkPaid }: { orders: Order[]; onSelect: (orderId: string) => void; onMarkPaid: (order: Order) => void }) {
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
              <th>المدينة</th>
              <th>إجراء</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.id}>
                <td>{order.id}</td>
                <td>{order.customer}</td>
                <td>{formatMoney(order.total)}</td>
                <td><StatusBadge tone={order.paymentStatus === 'مدفوع' ? 'success' : 'pending'}>{order.paymentStatus}</StatusBadge></td>
                <td><StatusBadge>{orderStatuses[order.statusIndex] ?? 'غير محدد'}</StatusBadge></td>
                <td>{order.city}</td>
                <td>
                  <div className="row-actions">
                    <button onClick={() => onSelect(order.id)}><Icon name="visibility" /></button>
                    {order.paymentStatus !== 'مدفوع' && <button onClick={() => onMarkPaid(order)}>تأكيد الدفع</button>}
                  </div>
                </td>
              </tr>
            ))}
            {!orders.length && (
              <tr>
                <td colSpan={7}>لا توجد طلبات مطابقة.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  )
}

function OrderDetail({
  order,
  onMarkPaid,
  onAdvance,
  onUpdate,
}: {
  order?: Order
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

  const firstItem = order.items[0]

  return (
    <section className="panel detail">
      <header>
        <h2>{order.id}</h2>
        <StatusBadge tone={order.paymentStatus === 'مدفوع' ? 'success' : 'pending'}>{order.paymentStatus}</StatusBadge>
      </header>
      <div className="detail-product">
        {firstItem && <img src={firstItem.image} alt={firstItem.title} />}
        <div>
          <h3>{firstItem?.title ?? 'منتج غير محدد'}</h3>
          <p>{firstItem?.color} · {firstItem?.size} · الكمية {firstItem?.quantity}</p>
          {firstItem?.sourceLink && <a href={firstItem.sourceLink} rel="noreferrer" target="_blank">فتح رابط المنتج</a>}
        </div>
      </div>
      <InfoRow label="العميل" value={`${order.customer} · ${order.phone}`} />
      <InfoRow label="العنوان" value={`${order.city} · ${order.address}`} />
      <InfoRow label="الحالة" value={orderStatuses[order.statusIndex] ?? 'غير محدد'} />
      <InfoRow label="الإجمالي" value={formatMoney(order.total)} />
      <label className="field">
        <span>رقم القدموس</span>
        <input
          defaultValue={order.qadmousNumber}
          onBlur={(event) => onUpdate(order.id, { qadmousNumber: event.target.value, statusIndex: Math.max(7, order.statusIndex) })}
          placeholder="مثال: KD-22091"
        />
      </label>
      <div className="detail-actions">
        <button className="primary-action" onClick={() => onMarkPaid(order)}>تأكيد الدفع</button>
        <button className="ghost-action" onClick={() => onAdvance(order)}>نقل للمرحلة التالية</button>
      </div>
    </section>
  )
}

function ShippingList({
  orders,
  onAdvance,
  onUpdate,
}: {
  orders: Order[]
  onAdvance: (order: Order) => void
  onUpdate: (orderId: string, patch: Partial<Order>) => void
}) {
  return (
    <section className="panel shipping-list">
      <header>
        <h2>الشحن والقدموس</h2>
        <span>{orders.length} طلب</span>
      </header>
      {orders.map((order) => (
        <article key={order.id}>
          <div>
            <b>{order.id}</b>
            <span>{order.customer} · {order.city}</span>
            <small>{orderStatuses[order.statusIndex] ?? 'غير محدد'}</small>
          </div>
          <input
            defaultValue={order.qadmousNumber}
            onBlur={(event) => onUpdate(order.id, { qadmousNumber: event.target.value, statusIndex: Math.max(7, order.statusIndex) })}
            placeholder="رقم القدموس"
          />
          <button onClick={() => onAdvance(order)}>تحديث المرحلة</button>
        </article>
      ))}
    </section>
  )
}

function CustomersGrid({ orders }: { orders: Order[] }) {
  const customers = Array.from(new Map(orders.map((order) => [order.phone, order])).values())

  return (
    <section className="customers">
      {customers.map((order) => (
        <article className="panel customer" key={order.phone}>
          <div className="avatar">{order.customer[0] ?? 'ط'}</div>
          <h2>{order.customer}</h2>
          <p>{order.phone}</p>
          <span>{order.city}</span>
        </article>
      ))}
    </section>
  )
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="info-row">
      <span>{label}</span>
      <b>{value}</b>
    </div>
  )
}

export default AdminApp
