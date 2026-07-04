import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import type { ReactNode } from 'react'
import {
  allowedProducts,
  blockedProducts,
  FIXED_SHIPPING_SYP,
  initialAddresses,
  initialOrders,
  orderStatuses,
  paymentSettings,
} from './domain/fixtures'
import { makeOrderId, today } from './domain/orders'
import { buildPriceBreakdown, formatMoney, formatPriceSyp, formatUsd, sumPriceLines } from './domain/pricing'
import type { PaymentCurrency } from './domain/pricing'
import type { Address, AppNotification, CartItem, NotificationPrefs, Order, Product, ProductColor, ProductVariant, Recipient, Screen, StatusTone, UserProfile } from './domain/types'
import { getDeviceId, readStoredJson, storageKeys, useStoredState } from './infrastructure/localStorage'
import { appApi } from './services'
import { PAYMENT_MODE, APP_VERSION, cleanEnvValue } from './config'
import { buildWhatsappLink } from './services/whatsappLink'
import { SHEIN_CAPTURE_SCRIPT } from './services/sheinBrowserScript'
import { InAppBrowser, ToolBarType } from '@capgo/capacitor-inappbrowser'

const API_BASE = cleanEnvValue(import.meta.env.VITE_WHATSAPP_API_URL)
const SUPABASE_URL = cleanEnvValue(import.meta.env.VITE_SUPABASE_URL)
const SUPABASE_ANON_KEY = cleanEnvValue(import.meta.env.VITE_SUPABASE_ANON_KEY)
const NOTIFY_URL = SUPABASE_URL ? `${SUPABASE_URL}/functions/v1/telegram-notify` : ''
const APP_SETTINGS_URL = SUPABASE_URL ? `${SUPABASE_URL}/functions/v1/app-settings` : ''
const CUSTOMER_PROFILE_URL = SUPABASE_URL ? `${SUPABASE_URL}/functions/v1/customer-profile` : ''

// موقع SHEIN الذي يتصفّحه الزبون. نستخدم نسخة الأردن لأنها تعرض العربية
// بثبات (نسخة لبنان m.shein.com/lb تعرض الإنجليزية ولا تقبل العربية).
// بلد المصدر الفعلي (لبنان) شأن تشغيلي داخلي لا يؤثر على ما يراه الزبون:
// الأسعار بالدولار نفسها، والزبون لا يرى اسم أي بلد (يُعرض "مركز التجميع").
// السكربت المحقون يقرأ المنطقة من الرابط فيضبط لغة الموقع تلقائياً.
const SHEIN_REGION = 'jo'
const SHEIN_HOME_URL = `https://m.shein.com/${SHEIN_REGION}/?ref=${SHEIN_REGION}&rep=dir&ret=m${SHEIN_REGION}&currency=USD`

// المتاجر المتاحة للتصفّح. الالتقاط التلقائي (سعر/إضافة للسلة) يعمل على شي إن
// فقط حالياً؛ باقي المتاجر تُفتح للتصفّح. لكل متجر سلة منفصلة.
type StoreId = 'shein' | 'temu'
const STORES: { id: StoreId; name: string; url: string }[] = [
  { id: 'shein', name: 'شي إن', url: SHEIN_HOME_URL },
  // ملاحظة: تيمو يحدّد اللغة/العملة/المنطقة من IP الـVPN (ثبت أن locale_override
  // بالرابط يُرفض ويُعاد لكندا)، فالعربية/الأردن/الدولار تتطلب VPN ببلد عربي.
  // /jo/ = الأردن: عربي + دينار أردني (ثابت ≈ 1.41$). يشغّل الزبون VPN أي دولة
  // لكن السكريبت يُحوّل تلقائياً لهذا المسار لضمان العربية بصرف النظر عن الـIP.
  { id: 'temu', name: 'تيمو', url: 'https://www.temu.com/jo/' },
]
const storeUrl = (id: string) => (STORES.find((s) => s.id === id)?.url) ?? SHEIN_HOME_URL

const usesInboundWhatsappAuth = cleanEnvValue(import.meta.env.VITE_WHATSAPP_AUTH_MODE) === 'inbound'

const COUNTRY_CODES = [
  { code: '963', name: 'سوريا', flag: '🇸🇾' },
  { code: '962', name: 'الأردن', flag: '🇯🇴' },
  { code: '966', name: 'السعودية', flag: '🇸🇦' },
  { code: '971', name: 'الإمارات', flag: '🇦🇪' },
  { code: '965', name: 'الكويت', flag: '🇰🇼' },
  { code: '974', name: 'قطر', flag: '🇶🇦' },
  { code: '968', name: 'عُمان', flag: '🇴🇲' },
  { code: '973', name: 'البحرين', flag: '🇧🇭' },
  { code: '961', name: 'لبنان', flag: '🇱🇧' },
  { code: '964', name: 'العراق', flag: '🇮🇶' },
  { code: '20', name: 'مصر', flag: '🇪🇬' },
  { code: '90', name: 'تركيا', flag: '🇹🇷' },
  { code: '49', name: 'ألمانيا', flag: '🇩🇪' },
  { code: '1', name: 'أمريكا', flag: '🇺🇸' },
]

const SYRIA_GOVERNORATES = [
  'دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية', 'طرطوس',
  'درعا', 'السويداء', 'القنيطرة', 'دير الزور', 'الرقة', 'الحسكة', 'إدلب',
]

// فروع شركة القدموس للشحن والتوصيل في سوريا، مرتّبة حسب المحافظة.
// القائمة قابلة للتحديث بحسب فروع القدموس الفعلية.
const QADMOUS_BRANCHES: Record<string, string[]> = {
  'دمشق': [
    'مكتب الحمرا — شارع الحمرا',
    'مكتب البرامكة — زقاق الجن مقابل ملعب تشرين',
    'مكتب الحريقة — بالقرب من بنك سوريا والمهجر',
    'مكتب شارع بغداد',
    'مكتب فكتوريا — مكتب النور',
  ],
  'اللاذقية': [
    'المكتب الرئيسي — ساحة اليمن بناء القدموس',
    'مكتب دوار الزراعة — المشروع السابع',
    'مكتب الرمل الشمالي',
    'مكتب حي الصليبة — سوق التجار',
    'مكتب المحافظة',
  ],
  'طرطوس': [
    'المكتب الرئيسي — البلدية',
    'مكتب الكراج القديم',
    'مكتب بانياس — الكراج العام',
    'مكتب القدموس — الساحة العامة',
  ],
  'حمص': [
    'مكتب الحضارة',
    'مكتب الحواش',
    'مكتب شين غربي — شعبة الكهرباء طريق جبلاية',
  ],
  'حماة': [
    'مكتب كراج البولمان الجديد',
    'مكتب ساحة العاصي',
    'مكتب مصياف — الكراج العام',
    'مكتب سلمية — الكراج العام',
    'مكتب سلحب',
  ],
  'حلب': [
    'مكتب الجميلية',
    'مكتب الراموسة — كراج الراموسة',
  ],
  'السويداء': [
    'مكتب السويداء — طريق دمشق جانب كراج البولمان',
  ],
  'درعا': [
    'مكتب درعا المدينة',
  ],
}

// مهم: نستخدم || وليس ?? لأن secret البناء قد يصل نصاً فارغاً ('') وليس
// undefined، و?? لا تمسك النص الفارغ فيصير parseInt('')=NaN ويصفّر كل
// الأسعار. وفوقها fallback نهائي لو طلعت القيمة غير صالحة لأي سبب.
const DEFAULT_EXCHANGE_RATE = (() => {
  const parsed = parseInt(cleanEnvValue(import.meta.env.VITE_USD_TO_SYP_RATE) || '13000', 10)
  return Number.isFinite(parsed) && parsed > 1000 ? parsed : 13000
})()

const MIN_ORDER_SYP = 500000
const MIN_ORDER_USD = 40

type PendingWhatsappAuth = {
  phone: string
  whatsappUrl: string
  supportPhone: string
  verificationMessage: string
  expiresAt: number
}

function extractCountryCode(fullPhone: string): { code: string; local: string } {
  for (const c of COUNTRY_CODES) {
    if (fullPhone.startsWith(c.code) && c.code.length > 1) {
      return { code: c.code, local: fullPhone.slice(c.code.length) }
    }
  }
  return { code: '963', local: fullPhone.length > 3 ? fullPhone.slice(3) : '' }
}

function Icon({ name }: { name: string }) {
  return <span className="material-symbols-outlined" aria-hidden="true">{name}</span>
}

function StatusBadge({ children, tone = 'neutral' }: { children: string; tone?: StatusTone }) {
  return <span className={`status status--${tone}`}>{children}</span>
}

function getPublicErrorMessage(error: unknown) {
  if (error instanceof Error) {
    return error.message
  }
  return 'حدث خطأ غير متوقع. حاول مرة ثانية.'
}

// نص مشاركة تطبيق SHEIN يحتوي عنوان المنتج بالعربي بجانب الرابط — نستخرجه مجاناً وبدون أي طلب شبكة
function extractFallbackTitle(rawText: string, urlPart: string) {
  const withoutUrls = rawText.replace(urlPart, '').replace(/https?:\/\/\S+/g, '').trim()
  if (!withoutUrls) return ''
  return withoutUrls.slice(0, 120).trim()
}

function App() {
  const [pendingWhatsappAuth, setPendingWhatsappAuth] = useStoredState<PendingWhatsappAuth | null>(
    storageKeys.pendingWhatsappAuth,
    null,
  )
  const [sessionToken, setSessionToken] = useStoredState<string>(storageKeys.sessionToken, '')
  const [userProfile, setUserProfile] = useStoredState<UserProfile | null>(storageKeys.userProfile, null)
  const [paymentCurrency, setPaymentCurrency] = useStoredState<PaymentCurrency>(storageKeys.paymentCurrency, 'SYP')
  const [storedRate, setExchangeRate] = useStoredState<number>(storageKeys.exchangeRate, DEFAULT_EXCHANGE_RATE)
  const exchangeRate = (storedRate && !isNaN(storedRate) && storedRate > 1000) ? storedRate : DEFAULT_EXCHANGE_RATE
  const [shippingCostShein, setShippingCostShein] = useState(FIXED_SHIPPING_SYP)
  const [shippingCostTemu, setShippingCostTemu] = useState(FIXED_SHIPPING_SYP)
  // إعدادات من لوحة الإدارة: نسبة الربح (تُضاف على سعر المنتج) + شام كاش.
  const [profitMarginPercent, setProfitMarginPercent] = useState(0)
  const [shamCashCode, setShamCashCode] = useState('')
  const [shamCashBarcode, setShamCashBarcode] = useState('')

  const [initialNow] = useState(() => Date.now())
  const initialPendingWhatsappAuth =
    usesInboundWhatsappAuth &&
    typeof pendingWhatsappAuth?.expiresAt === 'number' &&
    pendingWhatsappAuth.expiresAt > initialNow
      ? pendingWhatsappAuth
      : null

  const [screen, setScreen] = useState<Screen>(() => {
    const token = readStoredJson<string>(storageKeys.sessionToken, '')
    if (token) {
      const profile = readStoredJson<UserProfile | null>(storageKeys.userProfile, null)
      return profile ? 'home' : 'onboarding'
    }
    return initialPendingWhatsappAuth ? 'otp' : 'login'
  })

  const [link, setLink] = useState('')
  const [sharedText, setSharedText] = useState('')
  const [activeProduct, setActiveProduct] = useState<Product | null>(null)

  const [countryCode, setCountryCode] = useState(() => {
    const stored = initialPendingWhatsappAuth?.phone ?? ''
    return stored ? extractCountryCode(stored).code : '963'
  })
  const [localPhone, setLocalPhone] = useState(() => {
    const stored = initialPendingWhatsappAuth?.phone ?? ''
    return stored ? extractCountryCode(stored).local : ''
  })
  const phone = countryCode + localPhone.replace(/^0+/, '')

  const [otpDigits, setOtpDigits] = useState(['', '', '', ''])
  const otpRefs = useRef<(HTMLInputElement | null)[]>([null, null, null, null])
  const [otpExpiresInSeconds, setOtpExpiresInSeconds] = useState(() =>
    initialPendingWhatsappAuth
      ? Math.max(1, Math.ceil((initialPendingWhatsappAuth.expiresAt - Date.now()) / 1000))
      : 42,
  )
  const [telegramOtp, setTelegramOtp] = useState('')
  const [inboundWhatsappUrl, setInboundWhatsappUrl] = useState(initialPendingWhatsappAuth?.whatsappUrl ?? '')
  const [inboundSupportPhone, setInboundSupportPhone] = useState(initialPendingWhatsappAuth?.supportPhone ?? '')
  const [inboundVerificationMessage, setInboundVerificationMessage] = useState(
    initialPendingWhatsappAuth?.verificationMessage ?? '',
  )
  const [authState, setAuthState] = useState<'idle' | 'sending' | 'verifying'>('idle')
  const [selectedColor, setSelectedColor] = useState<ProductColor | null>(null)
  const [selectedSize, setSelectedSize] = useState<string>('')
  const [quantity, setQuantity] = useState(1)
  const [activeImage, setActiveImage] = useState(0)
  const [notice, setNotice] = useState('')
  const [savedProduct, setSavedProduct] = useStoredState(storageKeys.savedProduct, false)
  const [selectedStore, setSelectedStore] = useStoredState<StoreId>(storageKeys.selectedStore, 'shein')
  const selectedStoreRef = useRef(selectedStore)
  useEffect(() => { selectedStoreRef.current = selectedStore }, [selectedStore])

  // سلة منفصلة لكل متجر، محفوظة كخريطة { storeId: items[] }. السلة القديمة
  // المفردة تُرحَّل مرة واحدة إلى سلة شي إن حتى لا تضيع طلبات الزبون الحالية.
  const [cartsByStore, setCartsByStore] = useStoredState<Record<string, CartItem[]>>(
    storageKeys.cartsByStore,
    (() => {
      const legacy = readStoredJson<CartItem[]>(storageKeys.cartItems, [])
      const init: Record<string, CartItem[]> = {}
      if (legacy.length) init.shein = legacy
      return init
    })(),
  )
  const cartItems = cartsByStore[selectedStore] ?? []
  const setCartItems = useCallback((updater: CartItem[] | ((prev: CartItem[]) => CartItem[])) => {
    setCartsByStore((all) => {
      const current = all[selectedStoreRef.current] ?? []
      const next = typeof updater === 'function'
        ? (updater as (p: CartItem[]) => CartItem[])(current)
        : updater
      return { ...all, [selectedStoreRef.current]: next }
    })
  }, [setCartsByStore])
  const [orders, setOrders] = useStoredState<Order[]>(storageKeys.orders, initialOrders)
  const [addresses, setAddresses] = useStoredState<Address[]>(storageKeys.addresses, initialAddresses)
  const [currentOrderId, setCurrentOrderId] = useStoredState<string>(storageKeys.currentOrderId, '')
  const [recipient, setRecipient] = useStoredState<Recipient>(storageKeys.recipient, {
    name: '', phone: '', governorate: 'دمشق', city: '', details: '', notes: '',
  })
  const [verificationState, setVerificationState] = useState<'idle' | 'checking' | 'matched'>('idle')
  const [pendingPayment, setPendingPayment] = useStoredState<{
    orderId: string
    amount: number
    currency: PaymentCurrency
    expiresAt: string
  } | null>(storageKeys.pendingPayment, null)
  const [manualPriceUsd, setManualPriceUsd] = useState('')
  const [manualColorName, setManualColorName] = useState('')

  const [onboardingName, setOnboardingName] = useState(userProfile?.name ?? '')
  const QADMOUS_GOVS = Object.keys(QADMOUS_BRANCHES)
  const validProfileGov = userProfile?.governorate && QADMOUS_BRANCHES[userProfile.governorate] ? userProfile.governorate : 'دمشق'
  const [onboardingGov, setOnboardingGov] = useState(validProfileGov)
  const [editingProfile, setEditingProfile] = useState(false)
  const [editName, setEditName] = useState('')
  const [editGov, setEditGov] = useState('')
  const [sheinBlockedError, setSheinBlockedError] = useState(false)
  // Both platforms now reach SHEIN directly and need the user's own VPN on -
  // opening the webview immediately just races straight into the network
  // block every time. Detected automatically (no manual "I turned it on"
  // button) via checkSheinReachable() below. Android used to go through a
  // Cloudflare relay instead (no VPN needed) but that path never became
  // fully reliable (a Service Worker could intercept some of the page's own
  // API calls and bypass the relay regardless of fixes), so Android now uses
  // the exact same direct-connection + VPN-gate flow already proven stable
  // on iOS, rather than maintaining two different unreliable paths.
  const [vpnState, setVpnState] = useState<'checking' | 'ok' | 'blocked'>('checking')
  const [notifications, setNotifications] = useStoredState<AppNotification[]>(storageKeys.notifications, [])
  const [notificationPrefs, setNotificationPrefs] = useStoredState<NotificationPrefs>(storageKeys.notificationPrefs, {
    orderUpdates: true,
    payment: true,
    system: true,
    whatsapp: true,
  })
  // يربط نوع الإشعار بمفتاح تفضيله؛ إذا المستخدم طفّى الفئة لا يُنشأ إشعار داخل التطبيق
  const isNotifTypeEnabled = (type: AppNotification['type']) =>
    type === 'order_update' ? notificationPrefs.orderUpdates
      : type === 'payment' ? notificationPrefs.payment
      : notificationPrefs.system
  // ref يبقى متزامناً مع التفضيلات لاستخدامها داخل poll بدون stale closure
  const notificationPrefsRef = useRef(notificationPrefs)
  useEffect(() => { notificationPrefsRef.current = notificationPrefs }, [notificationPrefs])

  // ref يبقى متزامناً مع orders لكشف تغيّر الحالة داخل poll بدون stale closure
  const ordersRef = useRef(orders)
  useEffect(() => { ordersRef.current = orders }, [orders])

  const unreadCount = notifications.filter((n) => !n.read).length

  // يتذكر الشاشة اللي كان عليها المستخدم قبل ما يدخل الإشعارات، حتى زر
  // الرجوع يرجعه لمكانه الأصلي (وليس دايماً للرئيسية)
  const previousScreenRef = useRef<Screen>('home')
  const openNotifications = () => {
    previousScreenRef.current = screen
    setScreen('notifications')
  }

  const addNotification = (n: Omit<AppNotification, 'id' | 'createdAt' | 'read'>) => {
    // يحترم تفضيلات المستخدم: إذا طفّى هالفئة لا يظهر الإشعار داخل التطبيق
    if (!isNotifTypeEnabled(n.type)) return
    setNotifications((prev) => [{
      ...n,
      id: `n-${Date.now()}`,
      createdAt: today(),
      read: false,
    }, ...prev])
    // يصل الإشعار أيضاً على واتساب المستخدم بنفس رقمه المسجَّل دخوله فيه
    // (fire-and-forget، غير حيوي - لا يقطع تجربة المستخدم لو فشل)
    if (API_BASE && phone && notificationPrefs.whatsapp) {
      void fetch(`${API_BASE}/api/notify/whatsapp`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ phone, text: `otlobli: ${n.title}\n${n.body}` }),
      }).catch(() => undefined)
    }
  }

  const order = orders.find((item) => item.id === currentOrderId) ?? orders[0] ?? null

  const showNotice = (message: string) => {
    setNotice(message)
    window.setTimeout(() => setNotice(''), 1900)
  }

  const reorderItems = (pastOrder: Order) => {
    // اكتشف المتجر الذي جاء منه الطلب من رابط المنتج الأول
    const firstLink = pastOrder.items[0]?.sourceLink ?? ''
    const orderStore: StoreId = /temu\.com/i.test(firstLink) ? 'temu' : 'shein'

    // ممنوع التبديل الصامت: كل طلب مرتبط بالمتجر الذي طُلب منه فعلاً، فإذا
    // كان المستخدم حالياً على متجر مختلف، نطلب منه التبديل يدوياً أولاً.
    if (selectedStoreRef.current !== orderStore) {
      const orderStoreName = STORES.find((s) => s.id === orderStore)?.name ?? orderStore
      showNotice(`هذا الطلب من ${orderStoreName} — بدّل إلى ${orderStoreName} أولاً لتقدر تعمل إعادة الطلب`)
      return
    }

    const reordered: CartItem[] = pastOrder.items.map((item, index) => ({
      ...item,
      id: `${item.id}-reorder-${Date.now()}-${index}`,
    }))
    setCartsByStore((all) => ({
      ...all,
      [orderStore]: [...(all[orderStore] ?? []), ...reordered],
    }))
    showNotice('تمت إضافة منتجات الطلب إلى السلة')
    setScreen('cart')
  }

  const logout = () => {
    // تنبيه المالك المطلوب: تسجيل الخروج يُفرّغ السلة الحالية (كل المتاجر)،
    // بينما "طلباتي" محفوظة ولا تتأثر. نؤكّد قبل التنفيذ حتى لا تضيع سلة بالخطأ.
    const hasCartItems = Object.values(cartsByStore).some((items) => items.length > 0)
    const message = hasCartItems
      ? 'تسجيل الخروج سيُفرّغ سلتك الحالية وتضيع أغراضها. طلباتك محفوظة في «طلباتي» ولن تتأثر.\n\nهل تريد المتابعة؟'
      : 'هل تريد تسجيل الخروج؟ طلباتك تبقى محفوظة في «طلباتي».'
    if (!window.confirm(message)) return
    setCartsByStore({})
    setSessionToken('')
    setScreen('login')
  }

  // نبضة الزبون: عند تسجيل الدخول (وكل فتح للتطبيق وهو مسجَّل) نسجّل "آخر ظهور"
  // ونفحص إن كان محظوراً (بالرقم أو معرّف الجهاز) — فنوجّهه لشاشة الحظر. تدهور
  // آمن: أي خطأ يُبقيه يعمل عادياً (لا يُحجب مستخدم شرعي بالخطأ).
  useEffect(() => {
    if (!sessionToken || !phone) return
    let cancelled = false
    void appApi.users
      .heartbeat(phone, getDeviceId(), userProfile?.name ?? recipient.name ?? '', userProfile?.governorate ?? recipient.governorate ?? '')
      .then((res) => { if (!cancelled) setAccountBlocked(res.blocked) })
      .catch(() => undefined)
    void appApi.wallet.getBalance(phone)
      .then((bal) => { if (!cancelled) setWalletBalanceUsd(bal) })
      .catch(() => undefined)
    return () => { cancelled = true }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sessionToken, phone])

  // تجلب ملف الزبون من الخادم بعد نجاح OTP. إذا وُجد الملف → home مباشرة.
  // إذا لم يوجد → onboarding (سيُحفظ الاسم/المحافظة إلى الخادم بعد الإدخال).
  const fetchProfileAfterLogin = async (loginPhone: string): Promise<'home' | 'onboarding'> => {
    if (!CUSTOMER_PROFILE_URL) return userProfile ? 'home' : 'onboarding'
    try {
      const data = await fetch(CUSTOMER_PROFILE_URL, {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          'x-customer-phone': loginPhone,
        },
      }).then((r) => r.json()) as { name?: string; governorate?: string }
      if (data?.name) {
        const profile: UserProfile = { name: data.name, governorate: data.governorate || 'دمشق' }
        setUserProfile(profile)
        setRecipient((r) => ({ ...r, name: profile.name, governorate: profile.governorate }))
        return 'home'
      }
    } catch { /* fallback below */ }
    return userProfile ? 'home' : 'onboarding'
  }

  useEffect(() => {
    const fetchRate = () => {
      fetch(`${API_BASE}/api/exchange-rate`)
        .then((r) => r.json())
        .then((data: { rate?: number }) => {
          if (data.rate && data.rate > 1000) {
            setExchangeRate(data.rate)
          }
        })
        .catch(() => undefined)
    }
    fetchRate()
    const intervalId = window.setInterval(fetchRate, 60 * 60 * 1000)
    return () => window.clearInterval(intervalId)
  }, [setExchangeRate])

  // جلب تكلفة الشحن الديناميكية من لوحة الإدارة عند التشغيل
  useEffect(() => {
    if (!APP_SETTINGS_URL) return
    void fetch(APP_SETTINGS_URL, {
      headers: { 'apikey': SUPABASE_ANON_KEY, 'authorization': `Bearer ${SUPABASE_ANON_KEY}` },
    })
      .then((r) => r.json())
      .then((data: Record<string, string>) => {
        const shein = parseInt(data.shipping_cost_shein_syp ?? '0', 10)
        const temu = parseInt(data.shipping_cost_temu_syp ?? '0', 10)
        if (shein > 0) setShippingCostShein(shein)
        if (temu > 0) setShippingCostTemu(temu)
        const margin = parseFloat(data.profit_margin_percent ?? '0')
        if (!isNaN(margin) && margin >= 0) setProfitMarginPercent(margin)
        if (data.shamcash_code) setShamCashCode(data.shamcash_code)
        if (data.shamcash_barcode) setShamCashBarcode(data.shamcash_barcode)
      })
      .catch(() => undefined)
  }, [])

  useEffect(() => {
    if (screen !== 'otp' || otpExpiresInSeconds <= 0) return undefined
    const timer = window.setInterval(() => {
      setOtpExpiresInSeconds((s) => Math.max(0, s - 1))
    }, 1000)
    return () => window.clearInterval(timer)
  }, [screen, otpExpiresInSeconds])

  useEffect(() => {
    if (screen !== 'otp' || !inboundWhatsappUrl) {
      return undefined
    }

    const checkInboundMessage = () => {
      void appApi.auth
        .verifyOtp(phone, '')
        .then(async () => {
          setSessionToken(phone)
          setPendingWhatsappAuth(null)
          setInboundWhatsappUrl('')
          setInboundSupportPhone('')
          setInboundVerificationMessage('')
          const target = await fetchProfileAfterLogin(phone)
          setScreen(target)
          showNotice('تم تأكيد رقم واتساب من الرسالة')
        })
        .catch(() => undefined)
    }

    checkInboundMessage()
    const intervalId = window.setInterval(checkInboundMessage, 2500)

    return () => window.clearInterval(intervalId)
  }, [inboundWhatsappUrl, phone, screen, setPendingWhatsappAuth, setSessionToken, userProfile])

  // Telegram OTP polling — يتحقق تلقائياً كل 3 ثوانٍ بعد إرسال الرمز للبوت
  useEffect(() => {
    if (screen !== 'otp' || !telegramOtp) return undefined

    const check = () => {
      void appApi.auth
        .verifyOtp(phone, telegramOtp)
        .then(async () => {
          setSessionToken(phone)
          setTelegramOtp('')
          const target = await fetchProfileAfterLogin(phone)
          setScreen(target)
          showNotice('تم تأكيد رقمك بنجاح')
        })
        .catch(() => undefined)
    }

    const intervalId = window.setInterval(check, 3000)
    return () => window.clearInterval(intervalId)
  }, [telegramOtp, phone, screen, setSessionToken, userProfile])

  // Variant helpers
  const getAvailableSizesForColor = (p: Product, colorName: string): string[] => {
    if (!p.variants || p.variants.length === 0) return p.sizes
    const available = p.variants
      .filter(v => v.available && (!v.colorName || v.colorName === colorName))
      .map(v => v.sizeName)
      .filter((s): s is string => !!s)
    return available.length > 0 ? [...new Set(available)] : p.sizes
  }

  const isVariantAvailable = (p: Product, colorName: string | null, sizeName: string): boolean => {
    if (!p.variants || p.variants.length === 0) return true
    const variant = p.variants.find(v =>
      (!v.colorName || v.colorName === colorName) &&
      (!v.sizeName || v.sizeName === sizeName)
    )
    return variant ? variant.available : true
  }

  const availableSizes = useMemo(() => {
    if (!activeProduct) return []
    if (!selectedColor) return activeProduct.sizes
    return getAvailableSizesForColor(activeProduct, selectedColor.name)
  }, [activeProduct, selectedColor])

  const currentVariantAvailable = useMemo(() => {
    if (!activeProduct || !selectedSize) return true
    return isVariantAvailable(activeProduct, selectedColor?.name ?? null, selectedSize)
  }, [activeProduct, selectedColor, selectedSize])

  // نسبة الربح من لوحة الإدارة تُضاف على سعر المنتج (0% = بلا تغيير). تُطبَّق
  // في نقطة واحدة كي يتطابق العرض بصفحة المنتج والسلة والإجمالي المدفوع.
  const applyMargin = (syp: number) => Math.round(syp * (1 + (profitMarginPercent > 0 ? profitMarginPercent : 0) / 100))
  const getItemPriceSyp = (item: { priceSyp: number; priceUsd?: number }) =>
    applyMargin(item.priceSyp > 0 ? item.priceSyp : Math.round((item.priceUsd ?? 0) * exchangeRate))

  // تكلفة الشحن تُحسب بحسب المتجر الحالي وتُحدَّث من الإدارة
  const currentShippingFees = useMemo(() => [
    { label: 'تكلفة الشحن', value: selectedStore === 'temu' ? shippingCostTemu : shippingCostShein },
  ], [selectedStore, shippingCostShein, shippingCostTemu])

  const subtotalBreakdown = useMemo(() => {
    if (cartItems.length > 0) {
      const productsTotal = cartItems.reduce((sum, item) => sum + getItemPriceSyp(item) * item.quantity, 0)
      return [{ label: 'مجموع المنتجات', value: productsTotal }, ...currentShippingFees]
    }
    return buildPriceBreakdown({
      label: 'سعر المنتج',
      productPriceSyp: applyMargin(activeProduct?.priceSyp ?? 0),
      quantity,
      fees: currentShippingFees,
    })
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeProduct?.priceSyp, cartItems, quantity, exchangeRate, currentShippingFees])

  const subtotal = useMemo(() => sumPriceLines(subtotalBreakdown), [subtotalBreakdown])

  // كود الخصم: يُطبَّق فقط بعد تأكيد الخلفية (RPC ذرّية تستهلكه مرة/هاتف/جهاز).
  // appliedCoupon يحمل المبلغ المؤكَّد بالليرة؛ نقصّه على subtotal حتى لا يصير
  // الإجمالي سالباً أبداً. إن لم تُنشَر الخلفية يبقى null فلا يتأثر أي مبلغ.
  const [couponInput, setCouponInput] = useState('')
  const [appliedCoupon, setAppliedCoupon] = useStoredState<{ code: string; discountSyp: number } | null>(
    'talabieh.appliedCoupon',
    null,
  )
  const [couponMsg, setCouponMsg] = useState('')
  const [couponChecking, setCouponChecking] = useState(false)
  // المحفظة: الرصيد بالدولار (يُجلب عند الدخول) + خيار استخدامه بالدفع.
  const [walletBalanceUsd, setWalletBalanceUsd] = useState(0)
  const [useWallet, setUseWallet] = useState(false)
  // حظر الحساب: تُضبط من نبضة الدخول، وتعرض طبقة حجب صلبة لا يمكن تجاوزها.
  const [accountBlocked, setAccountBlocked] = useState(false)

  const couponDiscountSyp = appliedCoupon ? Math.min(Math.max(0, appliedCoupon.discountSyp), subtotal) : 0
  const afterCoupon = Math.max(0, subtotal - couponDiscountSyp)
  // المحفظة: نخصم بالدولار ما يعادل المتبقّي (بعد الكوبون)، محدوداً بالرصيد.
  const walletUsableUsd = useWallet ? Math.min(walletBalanceUsd, afterCoupon / exchangeRate) : 0
  const walletDiscountSyp = Math.min(afterCoupon, Math.round(walletUsableUsd * exchangeRate))
  const breakdown = [
    ...subtotalBreakdown,
    ...(couponDiscountSyp > 0 ? [{ label: `خصم (${appliedCoupon!.code})`, value: -couponDiscountSyp }] : []),
    ...(walletDiscountSyp > 0 ? [{ label: 'رصيد المحفظة', value: -walletDiscountSyp }] : []),
  ]
  const total = Math.max(0, afterCoupon - walletDiscountSyp)
  const meetsMinimumOrder = subtotal >= MIN_ORDER_SYP || subtotal / exchangeRate >= MIN_ORDER_USD

  const couponReasonMessage = (reason?: string) => {
    switch (reason) {
      case 'no_phone': return 'أدخل رقم واتساب المستلم أولاً'
      case 'not_found': return 'كود الخصم غير صحيح'
      case 'inactive':
      case 'not_started': return 'كود الخصم غير مفعّل حالياً'
      case 'expired': return 'انتهت صلاحية كود الخصم'
      case 'wrong_store': return 'هذا الكود لا ينطبق على هذا المتجر'
      case 'below_min': return 'قيمة الطلب أقل من الحد المطلوب لهذا الكود'
      case 'exhausted': return 'انتهت الكمية المتاحة لهذا الكود'
      case 'already_used': return 'لقد استخدمت هذا الكود من قبل'
      case 'offline':
      case 'local': return 'خدمة أكواد الخصم غير متاحة حالياً'
      default: return 'تعذّر تطبيق الكود، حاول لاحقاً'
    }
  }

  const applyCoupon = async () => {
    const code = couponInput.trim()
    if (!code || couponChecking) return
    const custPhone = recipient.phone.trim() || phone
    if (!custPhone) { setCouponMsg('أدخل رقم واتساب المستلم أولاً'); return }
    setCouponChecking(true)
    setCouponMsg('')
    try {
      const res = await appApi.orders.redeemCoupon({
        code,
        phone: custPhone,
        deviceId: getDeviceId(),
        store: selectedStore,
        subtotalSyp: subtotal,
      })
      if (res.valid && res.discountSyp > 0) {
        setAppliedCoupon({ code: res.code || code, discountSyp: res.discountSyp })
        setCouponInput('')
        setCouponMsg('')
      } else {
        setCouponMsg(couponReasonMessage(res.reason))
      }
    } catch {
      setCouponMsg('تعذّر تطبيق الكود، حاول لاحقاً')
    } finally {
      setCouponChecking(false)
    }
  }
  const hasIncompleteCustom = cartItems.some(
    (item) => (item.needsCustomText && !item.customText?.trim()) ||
              (item.needsCustomPhoto && !item.customPhotoDataUrl)
  )
  const formatPrice = (syp: number) => formatPriceSyp(syp, paymentCurrency, exchangeRate)

  const [ratingStars, setRatingStars] = useState(0)
  const [ratingNote, setRatingNote] = useState('')
  const [isSubmittingRating, setIsSubmittingRating] = useState(false)
  // إظهار/إخفاء قائمة منتجات الطلب داخل شاشة تتبّع الطلب.
  const [showTrackingItems, setShowTrackingItems] = useState(false)

  const submitRating = (targetOrderId: string) => {
    if (ratingStars < 1) return
    setIsSubmittingRating(true)
    void appApi.orders.submitOrderRating(targetOrderId, ratingStars, ratingNote.trim())
      .then((ok) => {
        if (ok) {
          setOrders((list) => list.map((item) => (
            item.id === targetOrderId ? { ...item, rating: ratingStars, ratingNote: ratingNote.trim() } : item
          )))
          showNotice('شكراً لتقييمك! 🌟')
        } else {
          showNotice('تعذر حفظ التقييم الآن')
        }
      })
      .catch(() => showNotice('تعذر حفظ التقييم الآن'))
      .finally(() => setIsSubmittingRating(false))
  }

  const fetchProduct = () => {
    if (!link.trim()) {
      showNotice('الصق رابط منتج SHEIN أولاً')
      return
    }
    const fallbackTitle = extractFallbackTitle(sharedText, link)
    setScreen('loading')
    void appApi.catalog.fetchSheinProduct(link, fallbackTitle)
      .then((result) => {
        const priceSyp = result.product.priceSyp || Math.round(result.product.priceUsd * exchangeRate)
        const productWithRate = { ...result.product, priceSyp }
        setActiveProduct(productWithRate)
        const firstColor = result.product.colors[0] ?? null
        setSelectedColor(firstColor)
        const firstSize = result.product.sizes[0] ?? ''
        setSelectedSize(firstSize)
        setActiveImage(0)
        setLink(result.normalizedLink)
        setManualPriceUsd('')
        setManualColorName('')
        setScreen('product')
      })
      .catch((error: unknown) => {
        setScreen('home')
        showNotice(getPublicErrorMessage(error))
      })
  }

  const startLogin = () => {
    if (localPhone.replace(/\D/g, '').length < 7) {
      showNotice('أدخل رقم واتساب صحيح')
      return
    }

    setAuthState('sending')
    void appApi.auth
      .startWhatsappLogin(phone)
      .then((result) => {
        if (!result || typeof result !== 'object') {
          showNotice('تعذّر الاتصال بخادم واتساب. حدّث التطبيق لأحدث نسخة وحاول مجدداً.')
          return
        }
        if (result.telegramOtp) {
          setTelegramOtp(result.telegramOtp)
          setOtpExpiresInSeconds(result.otpExpiresInSeconds)
          setScreen('otp')
          showNotice('أرسل الرمز لبوت تيليغرام للتحقق')
          return
        }

        const pendingAuth = result.whatsappUrl
          ? {
              phone,
              whatsappUrl: result.whatsappUrl,
              supportPhone: result.supportPhone ?? '',
              verificationMessage: result.verificationMessage ?? '',
              expiresAt: Date.now() + result.otpExpiresInSeconds * 1000,
            }
          : null

        setOtpDigits(['', '', '', ''])
        setInboundWhatsappUrl(result.whatsappUrl ?? '')
        setInboundSupportPhone(result.supportPhone ?? '')
        setInboundVerificationMessage(result.verificationMessage ?? '')
        setOtpExpiresInSeconds(result.otpExpiresInSeconds)
        setPendingWhatsappAuth(pendingAuth)
        setScreen('otp')
        showNotice(
          result.requiresInboundWhatsapp
            ? 'أرسل الرسالة الجاهزة لنا على واتساب'
            : result.mode === 'external'
              ? 'تم إرسال الرمز عبر واتساب'
              : 'تم تجهيز رمز تحقق تجريبي',
        )
      })
      .catch((error: unknown) => showNotice(getPublicErrorMessage(error)))
      .finally(() => setAuthState('idle'))
  }

  const verifyOtp = () => {
    if (inboundWhatsappUrl) {
      setAuthState('verifying')
      void appApi.auth
        .verifyOtp(phone, '')
        .then(async () => {
          setSessionToken(phone)
          setPendingWhatsappAuth(null)
          setInboundWhatsappUrl('')
          setInboundSupportPhone('')
          setInboundVerificationMessage('')
          const target = await fetchProfileAfterLogin(phone)
          setScreen(target)
          showNotice('تم تأكيد رقم واتساب من الرسالة')
        })
        .catch((error: unknown) => showNotice(getPublicErrorMessage(error)))
        .finally(() => setAuthState('idle'))
      return
    }

    const code = otpDigits.join('')

    if (code.length !== otpDigits.length) {
      showNotice('أدخل رمز التحقق كاملاً')
      return
    }

    setAuthState('verifying')
    void appApi.auth
      .verifyOtp(phone, code)
      .then(async () => {
        setSessionToken(phone)
        setPendingWhatsappAuth(null)
        const target = await fetchProfileAfterLogin(phone)
        setScreen(target)
        showNotice('تم تأكيد رقم واتساب')
      })
      .catch((error: unknown) => showNotice(getPublicErrorMessage(error)))
      .finally(() => setAuthState('idle'))
  }

  const submitOtp = (code: string) => {
    if (authState !== 'idle') return
    setAuthState('verifying')
    void appApi.auth.verifyOtp(phone, code)
      .then(async () => {
        setSessionToken(phone)
        setPendingWhatsappAuth(null)
        const target = await fetchProfileAfterLogin(phone)
        setScreen(target)
      })
      .catch((error: unknown) => {
        showNotice(getPublicErrorMessage(error))
        setOtpDigits(['', '', '', ''])
        otpRefs.current[0]?.focus()
      })
      .finally(() => setAuthState('idle'))
  }

  const updateOtpDigit = (index: number, value: string) => {
    const cleaned = value.replace(/\D/g, '')
    // ملء تلقائي من iOS أو لصق: الرمز كامل يصل داخل خانة واحدة → وزّعه على كل الخانات
    if (cleaned.length > 1) {
      pasteOtpDigits(cleaned)
      return
    }
    const digit = cleaned.slice(-1)
    const newDigits = otpDigits.map((item, i) => (i === index ? digit : item))
    setOtpDigits(newDigits)
    if (digit && index < otpDigits.length - 1) {
      otpRefs.current[index + 1]?.focus()
    }
    if (digit && newDigits.every(Boolean)) {
      submitOtp(newDigits.join(''))
    }
  }

  const handleOtpKeyDown = (index: number, event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Backspace' && !otpDigits[index] && index > 0) {
      otpRefs.current[index - 1]?.focus()
    }
  }

  const pasteOtpDigits = (value: string) => {
    const digits = value.replace(/\D/g, '').slice(0, otpDigits.length).split('')
    if (!digits.length) return
    const newDigits = otpDigits.map((item, index) => digits[index] ?? item)
    setOtpDigits(newDigits)
    const lastFilled = Math.min(digits.length, otpDigits.length) - 1
    if (lastFilled >= 0) {
      otpRefs.current[lastFilled]?.focus()
    }
    // الرمز اكتمل عبر لصق/ملء تلقائي → تحقّق فوراً دون انتظار ضغط زر
    if (newDigits.every(Boolean)) {
      submitOtp(newDigits.join(''))
    }
  }

  const openWhatsappSupport = (message: string) => {
    window.open(buildWhatsappLink(message), '_blank', 'noreferrer')
  }

  const addToCart = () => {
    if (!activeProduct) return
    if (activeProduct.priceUsd === 0) {
      showNotice('أدخل سعر المنتج بالدولار أولاً')
      return
    }
    if (!currentVariantAvailable) {
      showNotice('هذا الخيار غير متوفر حالياً')
      return
    }
    setCartItems((items) => [...items, {
      id: activeProduct.id,
      title: activeProduct.title,
      image: activeProduct.images[activeImage] ?? '',
      colorImage: selectedColor?.image ?? '',
      color: selectedColor?.name ?? manualColorName.trim(),
      size: selectedSize,
      sizesAvailable: availableSizes,
      sizesUnavailable: activeProduct.sizes.filter((s) => !availableSizes.includes(s)),
      quantity,
      priceUsd: activeProduct.priceUsd,
      priceSyp: activeProduct.priceSyp || Math.round(activeProduct.priceUsd * exchangeRate),
      sourceLink: link || activeProduct.link,
    }])
    showNotice('تمت إضافة المنتج إلى السلة')
    setScreen('cart')
  }

  const sheinOpenedRef = useRef(false)
  // عند تبديل المتجر: نُغلق البراوزر الحالي عمداً قبل فتحه على الجديد.
  // مستمع closeEvent (أدناه) يُعيد الفتح تلقائياً أيضاً لأي إغلاق (حتى لو
  // كان الإغلاق نفسه سبّبه استدعاؤنا) — فبلا هذا العلم، تبديل المتجر يُطلق
  // استدعاءين متسابقين لفتح البراوزر (من useEffect الشاشة + من closeEvent)
  // فيدخل المكوّن الأصلي بحالة عالقة (شاشة بيضاء لا تُصلَح إلا بإغلاق
  // التطبيق كلياً من الخلفية). العلم يمنع إعادة الفتح المزدوجة من closeEvent
  // تحديداً حين يكون الإغلاق مقصوداً من تبديل المتجر.
  const suppressAutoReopenRef = useRef(false)
  const [sheinReady, setSheinReady] = useState(false)
  // Tracks which screen the in-page back button inside the SHEIN webview
  // should return to: 'cart' right after the user taps a cart item (so back
  // re-opens otlobli's cart), 'home' for ordinary browsing from the home tab.
  const pendingBackTargetRef = useRef<'home' | 'cart'>('home')
  // عدّاد تحويل تيمو للعربية — يمنع الحلقة اللانهائية إذا تيمو يتجاوز التحويل
  const temuArabicRedirectRef = useRef(0)
  const temuArabicRedirectTsRef = useRef(0)

  // The SHEIN webview is a separate native layer floating on top of our own
  // React UI, not part of its DOM - trying to size it precisely to "leave a
  // gap above React's bottom-nav" meant keeping two independent native
  // surfaces pixel-aligned, which turned out to drift out of sync on iOS
  // (reported as the nav bar vanishing behind a black void). Sidestep that
  // category of bug entirely: let the webview take the full screen, and draw
  // otlobli's own nav bar *inside* it (see ensureOtlobliNav in the injected
  // script) so there's only ever one surface to get right.
  // A no-cors fetch() turned out NOT to prove anything: the Syrian block
  // doesn't drop the connection, it answers with a real, fully-formed HTML
  // "System Not Avaliable" page - and an opaque no-cors response counts as
  // "succeeded" the moment ANY server answers, block page or not, so that
  // check was reporting "reachable" even while blocked. Loading an actual
  // SHEIN-hosted image sidesteps that: image decode load/error events fire
  // based on whether the bytes that came back are a real image, regardless
  // of CORS - the block page's HTML response fails to decode as one, a real
  // SHEIN asset succeeds.
  const checkSheinReachable = () => {
    return new Promise<boolean>((resolve) => {
      const img = new Image()
      const timer = window.setTimeout(() => {
        img.onload = null
        img.onerror = null
        resolve(false)
      }, 7000)
      img.onload = () => { window.clearTimeout(timer); resolve(true) }
      img.onerror = () => { window.clearTimeout(timer); resolve(false) }
      img.src = `https://m.shein.com/favicon.ico?_=${Date.now()}`
    })
  }

  useEffect(() => {
    if (vpnState !== 'checking') return undefined
    let cancelled = false
    void checkSheinReachable().then((ok) => {
      if (cancelled) return
      if (!ok) { setVpnState('blocked'); return }
      // A VPN that just got toggled on can take a moment to actually settle
      // its routing - this image check can succeed a beat before that's
      // fully done. Opening the real webview immediately then races into a
      // transient DNS/connection failure that gets cached for the rest of
      // that WebView instance's life (confirmed: retrying inside the same
      // session kept failing; only a fresh instance recovered) - a short
      // pause here costs nothing on an already-stable connection and avoids
      // that race when the VPN was just switched on seconds ago.
      window.setTimeout(() => { if (!cancelled) setVpnState('ok') }, 1500)
    })
    return () => { cancelled = true }
  }, [vpnState])

  const browseShein = () => {
    sheinOpenedRef.current = true
    // SHEIN is reached directly on both platforms now, so it only loads once
    // the user's VPN is on - the vpnState check above already confirmed that
    // before this function ever runs.
    void InAppBrowser.openWebView({
      url: storeUrl(selectedStoreRef.current),
      toolbarType: ToolBarType.BLANK,
      preShowScript: SHEIN_CAPTURE_SCRIPT,
      preShowScriptInjectionTime: 'documentStart',
      isPresentAfterPageLoad: true,
      // Without this, the Android system back button can dismiss the whole dialog
      // outright (e.g. from a page with no in-page history, like an image gallery),
      // leaving sheinOpenedRef stuck "true" with no actual webview behind it - a
      // permanently blank home screen. This keeps back navigation inside the webview.
      activeNativeNavigationForWebview: true,
      disableGoBackOnNativeApplication: true,
      // Defaults to false in the plugin itself - without this, the native
      // WebView's own bounds extend all the way to the physical bottom edge
      // (this app targets Android SDK 36, which mandates edge-to-edge
      // display), and the system's own 3-button nav bar then draws ON TOP of
      // whatever's there, overlapping otlobli's nav bar rather than sitting
      // below it. This applies the missing margin at the native WebView
      // level instead of trying to compensate from CSS inside the page
      // (env(safe-area-inset-bottom) was confirmed unreliable in this
      // specific Dialog context, which is a different surface than the
      // main Activity it normally works on).
      enabledSafeBottomMargin: true,
      // Used to route Android traffic through a Cloudflare Worker relay here
      // (outboundProxyRules) so the device's own geo-blocked IP was never
      // what shein.com saw, while iOS skipped it (the relay crashed iOS's
      // WebContent process) and relied on the user's own VPN instead. The
      // relay path never became fully reliable on Android either - a page
      // Service Worker could intercept some of the page's own API calls and
      // answer them with a direct connection that bypassed the relay
      // regardless of fixes - so both platforms now connect directly and
      // rely on the user's VPN, same as iOS always did.
    })
      .then(() => {
        setSheinReady(true)
        const target = pendingBackTargetRef.current
        pendingBackTargetRef.current = 'home'
        void InAppBrowser.postMessage({ detail: { type: '__resize' } })
        void InAppBrowser.postMessage({ detail: { type: '__backTarget', target } })
      })
      .catch(() => { sheinOpenedRef.current = false })
  }

  const screenRef = useRef(screen)
  useEffect(() => { screenRef.current = screen }, [screen])

  useEffect(() => {
    if (screen === 'home') {
      if (sheinOpenedRef.current) {
        const target = pendingBackTargetRef.current
        pendingBackTargetRef.current = 'home'
        void InAppBrowser.show().then(() => {
          void InAppBrowser.postMessage({ detail: { type: '__resize' } })
          void InAppBrowser.postMessage({ detail: { type: '__backTarget', target } })
        })
      } else if (vpnState === 'ok') {
        browseShein()
      }
    } else if (sheinOpenedRef.current) {
      void InAppBrowser.hide()
    }
  }, [screen, vpnState])

  // Navigates the already-open SHEIN webview to a cart item's saved product
  // link and switches back to it, so tapping a product inside the cart shows
  // the real SHEIN page instead of just re-displaying the cart.
  const openSheinProductFromCart = (sourceLink: string) => {
    if (!sourceLink) {
      showNotice('رابط المنتج غير متوفر على SHEIN')
      return
    }
    if (!sheinOpenedRef.current) {
      showNotice('الرجاء الانتظار حتى يتم تجهيز المتجر')
      return
    }
    pendingBackTargetRef.current = 'cart'
    void InAppBrowser.setUrl({ url: sourceLink })
      .catch(() => undefined)
      .then(() => setScreen('home'))
  }

  useEffect(() => {
    const handle = InAppBrowser.addListener('closeEvent', () => {
      sheinOpenedRef.current = false
      setSheinReady(false)
      if (suppressAutoReopenRef.current) {
        suppressAutoReopenRef.current = false
        return
      }
      if (screenRef.current === 'home') browseShein()
    })
    return () => {
      void handle.then((h) => h.remove())
      if (sheinOpenedRef.current) void InAppBrowser.close()
    }
  }, [])

  // اعتراض تحويلات تيمو على مستوى Native: إذا غيّر الخادم الرابط لنسخة غير
  // عربية (بسبب IP الـVPN)، نُعيد التوجيه فوراً لـ /jo/ العربية قبل أن تُعرض.
  // هذا يعمل على مستوى WKWebView مباشرةً، أسرع وأقوى من JS داخل الصفحة.
  useEffect(() => {
    // مقطع الدولة يُفحص بعد الدومين مباشرةً فقط (لا في أي موضع عشوائي بالرابط)
    const ARABIC_TEMU_RE = /temu\.com\/(?:sa|ae|kw|jo|bh|qa|eg|iq|om)(?:\/|\?|#|$)/i
    const LOCALE_SEG_RE = /temu\.com\/[a-z]{2}(?:\/|\?|#|$)/i
    const handle = InAppBrowser.addListener('urlChangeEvent', ({ url }: { url: string }) => {
      if (!/temu\.com/i.test(url)) return
      if (ARABIC_TEMU_RE.test(url)) {
        // وصلنا لنسخة عربية — نُصفّر العدّاد
        temuArabicRedirectRef.current = 0
        return
      }
      // روابط بلا مقطع دولة إطلاقاً (منتجات قسم "الكل" مثلاً: temu.com/goods...)
      // نتركها كما هي — إعادة توجيهها كانت ترمي الزبون للصفحة الرئيسية
      // بدل فتح المنتج (شاشة بيضاء/عودة لنفس القائمة).
      if (!LOCALE_SEG_RE.test(url)) return
      // نسخة غير عربية (us/de/uk/...) — نُحوّل لـ /jo/
      const now = Date.now()
      // حماية الحلقة: 3 محاولات كحد أقصى خلال 15 ثانية
      if (temuArabicRedirectRef.current >= 3 && now - temuArabicRedirectTsRef.current < 15000) return
      if (now - temuArabicRedirectTsRef.current > 15000) temuArabicRedirectRef.current = 0
      temuArabicRedirectRef.current++
      temuArabicRedirectTsRef.current = now
      // نحافظ على مسار المنتج (مثلاً /us/prod.html → /jo/prod.html)
      const arabicUrl = url.replace(/temu\.com\/[a-z]{2}(\/|\?|#|$)/i, 'temu.com/jo$1')
      if (arabicUrl !== url) void InAppBrowser.setUrl({ url: arabicUrl })
    })
    return () => { void handle.then((h) => h.remove()) }
  }, [])

  // Backgrounding the app can drop the native SHEIN webview's visible state
  // without firing any of our own events - resuming then showed a plain
  // black screen (React's home fallback only renders while !sheinReady, but
  // sheinReady was already true from before backgrounding, and the native
  // layer wasn't actually back on screen). Re-assert it the same way the
  // [screen] effect above already does whenever the user switches back to
  // the home tab, just also on resume.
  useEffect(() => {
    const handleVisibility = () => {
      if (document.visibilityState === 'visible' && screenRef.current === 'home' && sheinOpenedRef.current) {
        void InAppBrowser.show().then(() => {
          void InAppBrowser.postMessage({ detail: { type: '__resize' } })
        })
      }
    }
    document.addEventListener('visibilitychange', handleVisibility)
    return () => document.removeEventListener('visibilitychange', handleVisibility)
  }, [])

  useEffect(() => {
    const handle = InAppBrowser.addListener('messageFromWebview', (event: { detail?: Record<string, unknown> }) => {
      const detail = event?.detail

      if (detail?.type === 'sheinBlocked') {
        void InAppBrowser.hide()
        setSheinBlockedError(true)
        return
      }

      if (detail?.type === 'openCart' || detail?.type === 'backToCart') {
        setScreen('cart')
        return
      }

      if (detail?.type === 'openOrders') {
        setScreen('orders')
        return
      }

      if (detail?.type === 'openProfile') {
        setScreen('profile')
        return
      }

      const product = detail?.type === 'addToCart' ? (detail.product as Record<string, unknown> | undefined) : undefined
      const title = typeof product?.title === 'string' ? product.title : ''
      if (!title) return

      // السعر قد يصل رقماً أو نصاً ("12.99") حسب طريقة تمرير جسر iOS للرسالة؛
      // نحوّله بأمان لرقم حتى لا يصير صفر بالفاتورة رغم أنه قُرئ فعلاً من SHEIN.
      const rawPrice = product?.priceUsd
      const parsedPrice = typeof rawPrice === 'number' ? rawPrice : parseFloat(String(rawPrice ?? ''))
      const priceUsd = Number.isFinite(parsedPrice) && parsedPrice > 0 ? parsedPrice : 0
      const sizesAvailable = Array.isArray(product?.sizesAvailable)
        ? (product.sizesAvailable as unknown[]).filter((s): s is string => typeof s === 'string')
        : []
      const sizesUnavailable = Array.isArray(product?.sizesUnavailable)
        ? (product.sizesUnavailable as unknown[]).filter((s): s is string => typeof s === 'string')
        : []
      setCartItems((items) => [...items, {
        id: `shein-${Date.now()}`,
        title,
        image: typeof product?.image === 'string' ? product.image : '',
        colorImage: typeof product?.colorImage === 'string' ? product.colorImage : '',
        color: typeof product?.color === 'string' ? product.color : '',
        size: typeof product?.size === 'string' ? product.size : '',
        sizesAvailable,
        sizesUnavailable,
        quantity: 1,
        priceUsd,
        priceSyp: Math.round(priceUsd * exchangeRate),
        sourceLink: typeof product?.link === 'string' ? product.link : '',
        needsCustomPhoto: typeof product?.needsCustomPhoto === 'boolean' ? product.needsCustomPhoto : false,
        customPhotoNote: typeof product?.customPhotoNote === 'string' ? product.customPhotoNote : '',
        needsCustomText: typeof product?.needsCustomText === 'boolean' ? product.needsCustomText : false,
        customText: typeof product?.customText === 'string' ? product.customText : '',
      }])
      void InAppBrowser.postMessage({ detail: { type: 'addToCartAck' } })
      showNotice('تمت إضافة المنتج إلى السلة')
    })
    return () => { void handle.then((h) => h.remove()) }
  }, [exchangeRate])

  // يعبّئ رقم واتساب المستلم تلقائياً برقم المستخدم المسجَّل دخوله عند دخول
  // صفحة الدفع لأول مرة فقط (لا يطغى على قيمة عدّلها المستخدم يدوياً بعدها)
  useEffect(() => {
    if (screen === 'checkout' && !recipient.phone && phone) {
      setRecipient((r) => ({ ...r, phone }))
    }
  }, [screen])

  // تحديث حالة الطلب من Supabase تلقائياً كل 30 ثانية عند فتح شاشة التتبع
  // يُنشئ إشعاراً تلقائياً إذا تقدّم الطلب لمرحلة جديدة
  useEffect(() => {
    if (screen !== 'tracking' || !currentOrderId) return undefined
    const poll = async () => {
      const data = await appApi.orders.pollOrderStatus(currentOrderId)
      if (!data) return
      const newStatusIndex = data.statusIndex
      // كشف تقدّم الحالة وإنشاء إشعار
      const current = ordersRef.current.find((o) => o.id === currentOrderId)
      if (current && newStatusIndex > current.statusIndex && notificationPrefsRef.current.orderUpdates) {
        const notifId = `status-${currentOrderId}-${newStatusIndex}`
        setNotifications((prev) => {
          if (prev.some((n) => n.id === notifId)) return prev
          return [{
            id: notifId,
            type: 'order_update',
            title: 'تحديث الطلب',
            body: `طلبك ${currentOrderId} انتقل إلى: ${orderStatuses[newStatusIndex] ?? ''}`,
            orderId: currentOrderId,
            createdAt: today(),
            read: false,
          }, ...prev]
        })
      }
      if (data.paymentIssue && !current?.paymentIssue) {
        const notifId = `payment-issue-${currentOrderId}`
        setNotifications((prev) => {
          if (prev.some((n) => n.id === notifId)) return prev
          return [{
            id: notifId,
            type: 'payment_issue',
            title: 'مشكلة بالدفع',
            body: `يوجد مشكلة بطلبك ${currentOrderId}${data.extraAmountUsd > 0 ? ` — متبقي $${data.extraAmountUsd.toFixed(2)}` : ''}`,
            orderId: currentOrderId,
            createdAt: today(),
            read: false,
          }, ...prev]
        })
      }
      setOrders((list) => list.map((o) => {
        if (o.id !== currentOrderId) return o
        return {
          ...o,
          statusIndex: newStatusIndex,
          qadmousNumber: data.qadmousNumber || o.qadmousNumber,
          paidAt: data.paidAt ?? o.paidAt,
          paymentStatus: data.paymentStatus ?? o.paymentStatus,
          paymentIssue: data.paymentIssue,
          paymentIssueNote: data.paymentIssueNote,
          extraAmountUsd: data.extraAmountUsd,
        }
      }))
    }
    void poll()
    const interval = window.setInterval(() => { void poll() }, 30_000)
    return () => window.clearInterval(interval)
  }, [screen, currentOrderId])

  const [isStartingPayment, setIsStartingPayment] = useState(false)

  // ينشئ الطلب ويحفظه في قاعدة البيانات. في وضع 'auto' (الدفع معطّل مؤقتاً)
  // يُسجَّل الطلب مباشرة "مدفوع" وينتقل لشاشة النجاح. في وضع 'shamcash' يُنشأ
  // بحالة "بانتظار الدفع" مع مبلغ فريد وينتقل لشاشة الدفع.
  const confirmOrder = async () => {
    if (cartItems.length === 0) {
      showNotice('السلة فارغة')
      return
    }
    if (!recipient.name.trim()) {
      showNotice('يرجى إدخال اسم المستلم')
      return
    }
    if (!recipient.phone.trim()) {
      showNotice('يرجى إدخال رقم الواتساب')
      return
    }
    if (!recipient.governorate) {
      showNotice('يرجى اختيار المحافظة')
      return
    }
    if (QADMOUS_BRANCHES[recipient.governorate] && !recipient.qadmousBranch) {
      showNotice('يرجى اختيار فرع القدموس للتسليم')
      return
    }
    const incompleteCustom = cartItems.find(
      (item) => (item.needsCustomText && !item.customText?.trim()) ||
                (item.needsCustomPhoto && !item.customPhotoDataUrl)
    )
    if (incompleteCustom) {
      showNotice('يرجى إكمال بيانات المنتجات المخصصة في السلة')
      setScreen('cart')
      return
    }

    if (PAYMENT_MODE === 'shamcash' && pendingPayment) {
      setScreen('payment')
      return
    }

    setIsStartingPayment(true)
    const orderId = makeOrderId(orders)

    // نخصم رصيد المحفظة أولاً وبانتظار (ذرّي بالخلفية) ونحسب الإجمالي من
    // المخصوم الفعلي — فيتطابق الإجمالي المدفوع مع ما خُصم فعلاً من المحفظة.
    // إن فشل الخصم أو تغيّر الرصيد، لا نطبّق خصم محفظة (لا خسارة مال).
    let walletSpentSyp = 0
    if (walletDiscountSyp > 0 && phone) {
      try {
        const r = await appApi.wallet.spend(phone, walletUsableUsd, orderId)
        if (r.ok && r.spentUsd > 0) {
          walletSpentSyp = Math.min(afterCoupon, Math.round(r.spentUsd * exchangeRate))
          setWalletBalanceUsd(r.balanceUsd)
        }
      } catch { /* فشل الخصم → بلا خصم محفظة */ }
    }
    const finalTotal = Math.max(0, afterCoupon - walletSpentSyp)

    const newOrder: Order = {
      id: orderId,
      customer: recipient.name || userProfile?.name || 'عميل otlobli',
      phone: recipient.phone || phone,
      city: recipient.governorate || 'غير محدد',
      address: recipient.qadmousBranch
        ? `فرع القدموس: ${recipient.qadmousBranch}${recipient.details ? ' - ' + recipient.details : ''}`
        : recipient.details || 'فرع القدموس (لم يُحدَّد)',
      items: cartItems,
      total: finalTotal,
      paymentStatus: 'بانتظار الدفع',
      statusIndex: 0,
      qadmousNumber: '',
      createdAt: today(),
    }

    void appApi.orders.createPendingOrder(newOrder, paymentCurrency)
      .then((result) => {
        if (PAYMENT_MODE === 'auto') {
          const savedOrder: Order = {
            ...newOrder,
            id: result.orderId,
            paymentStatus: 'مدفوع',
            statusIndex: 1,
            paidAt: today(),
          }
          setOrders((list) => [savedOrder, ...list])
          setCurrentOrderId(result.orderId)
          setCartItems([])
          setAppliedCoupon(null)
          setCouponInput('')
          setUseWallet(false)
          addNotification({ type: 'payment', title: 'تم استلام طلبك', body: `طلبك ${result.orderId} قيد المعالجة.`, orderId: result.orderId })
          setScreen('success')
          return
        }

        setOrders((list) => [{ ...newOrder, id: result.orderId }, ...list])
        setCurrentOrderId(result.orderId)
        setAppliedCoupon(null)
        setCouponInput('')
        setUseWallet(false)
        setPendingPayment({
          orderId: result.orderId,
          amount: result.paymentAmount,
          currency: result.paymentCurrency,
          expiresAt: result.paymentExpiresAt,
        })
        setScreen('payment')
      })
      .catch((error: unknown) => showNotice(getPublicErrorMessage(error)))
      .finally(() => setIsStartingPayment(false))
  }

  const verifyB2BPayment = () => {
    if (!pendingPayment) return
    setVerificationState('checking')
    void appApi.payments.checkPaymentStatus(pendingPayment.orderId).then((result) => {
      if (result.status === 'مدفوع') {
        showNotice('تم العثور على تحويل مطابق للمبلغ الدقيق')
        const paidOrder = orders.find((o) => o.id === pendingPayment.orderId)
        setOrders((list) => list.map((item) => (
          item.id === pendingPayment.orderId
            ? { ...item, paymentStatus: 'مدفوع', statusIndex: 1, paidAt: result.paidAt ?? today() }
            : item
        )))
        setCartItems([])
        setPendingPayment(null)
        setVerificationState('matched')
        addNotification({ type: 'payment', title: 'تم تأكيد الدفع', body: `تم مطابقة تحويلك للطلب ${pendingPayment.orderId}.`, orderId: pendingPayment.orderId })
        setScreen('success')
        if (paidOrder && NOTIFY_URL) {
          void fetch(NOTIFY_URL, {
            method: 'POST',
            headers: {
              'content-type': 'application/json',
              'apikey': SUPABASE_ANON_KEY,
              'authorization': `Bearer ${SUPABASE_ANON_KEY}`,
              'x-admin-pin': cleanEnvValue(import.meta.env.VITE_ADMIN_PIN),
            },
            body: JSON.stringify({ order: { ...paidOrder, paymentStatus: 'مدفوع', paidAt: result.paidAt ?? today() } }),
          }).catch(() => undefined)
        }
        return
      }

      showNotice('لم يتم العثور على تحويل مطابق بعد')
      setVerificationState('idle')
    })
  }

  const addAddress = () => {
    const id = `ADDR-${addresses.length + 1}`
    const nextAddress: Address = {
      id,
      label: `عنوان ${addresses.length + 1}`,
      name: recipient.name || userProfile?.name || 'عميل otlobli',
      phone: recipient.phone || phone,
      governorate: recipient.governorate || userProfile?.governorate || 'دمشق',
      city: recipient.city || 'دمشق',
      details: recipient.details || 'عنوان جديد',
      notes: recipient.notes || '',
      isDefault: addresses.length === 0,
    }
    setAddresses((list) => [...list, nextAddress])
    showNotice('تم حفظ العنوان')
  }

  const renderScreen = () => {
    // حجب صلب للحساب المحظور: لا شريط سفلي ولا زر رجوع — لا يمكن تجاوزه.
    if (accountBlocked) {
      return (
        <MobileShell active="home" onNavigate={() => undefined} hideBottomNav>
          <main className="mobile-content">
            <section className="empty-state" style={{ textAlign: 'center', marginTop: 40 }}>
              <div className="shipping-watermark"><Icon name="block" /></div>
              <h2 style={{ marginTop: 12 }}>تم إيقاف هذا الحساب</h2>
              <p style={{ marginTop: 8 }}>
                عذراً، تم إيقاف حسابك عن استخدام التطبيق. للاستفسار تواصل معنا عبر واتساب.
              </p>
              <button
                className="primary-action"
                style={{ marginTop: 16 }}
                onClick={() => openWhatsappSupport('مرحبا otlobli، حسابي موقوف وأريد الاستفسار')}
              >
                <Icon name="support_agent" /> تواصل عبر واتساب
              </button>
            </section>
          </main>
        </MobileShell>
      )
    }
    if (screen === 'login') {
      return (
        <AuthShell title="تسجيل الدخول" subtitle="ادخل رقم واتساب لتفعيل حسابك ومتابعة الطلبات">
          <label className="field">
            <span>رقم واتساب</span>
            <div className="phone-field">
              <select
                value={countryCode}
                onChange={(event) => setCountryCode(event.target.value)}
                aria-label="رمز الدولة"
                className="country-select"
              >
                {COUNTRY_CODES.map((c) => (
                  <option key={c.code} value={c.code}>{c.flag} +{c.code}</option>
                ))}
              </select>
              <input
                value={localPhone}
                onChange={(event) => setLocalPhone(event.target.value.replace(/\D/g, ''))}
                inputMode="tel"
                placeholder="912345678"
                dir="ltr"
              />
            </div>
          </label>
          <button className="primary-action" disabled={authState === 'sending'} onClick={startLogin}>
            {authState === 'sending'
              ? usesInboundWhatsappAuth
                ? 'جاري تجهيز واتساب...'
                : 'جاري إرسال الرمز...'
              : usesInboundWhatsappAuth
                ? 'تأكيد عبر واتساب'
                : 'إرسال رمز التحقق'}
            <Icon name="arrow_back" />
          </button>
          <p className="hint">يلزم تأكيد رقم واتساب قبل إنشاء أي طلب.</p>
        </AuthShell>
      )
    }

    if (screen === 'otp') {
      const goBackToLogin = () => {
        setOtpDigits(['', '', '', ''])
        setPendingWhatsappAuth(null)
        setInboundWhatsappUrl('')
        setInboundSupportPhone('')
        setInboundVerificationMessage('')
        setAuthState('idle')
        setScreen('login')
      }
      return (
        <AuthShell
          title={telegramOtp ? 'تأكيد عبر تيليغرام' : inboundWhatsappUrl ? 'تأكيد واتساب' : 'تأكيد الرقم'}
          subtitle={telegramOtp ? 'أرسل الرمز أدناه لبوت تيليغرام' : inboundWhatsappUrl ? 'افتح واتساب وأرسل الرسالة الجاهزة فقط' : 'أدخل الرمز المرسل إلى واتساب'}
          onBack={goBackToLogin}
        >
          {telegramOtp ? (
            <section className="whatsapp-verification">
              <p>افتح تيليغرام وأرسل هذا الرمز لبوت <strong>@Shein_in_syria_bot</strong>:</p>
              <code style={{ fontSize: '2rem', letterSpacing: '0.3em', fontWeight: 'bold', display: 'block', textAlign: 'center', padding: '1rem', background: 'var(--surface-2)', borderRadius: '12px' }}>{telegramOtp}</code>
              <a
                className="primary-action"
                href={`https://t.me/Shein_in_syria_bot?start=${telegramOtp}`}
                target="_blank"
                rel="noreferrer"
              >
                فتح بوت تيليغرام
                <Icon name="open_in_new" />
              </a>
              <p className="hint">بانتظار إرسالك للرمز... سيتم الدخول تلقائياً</p>
            </section>
          ) : inboundWhatsappUrl ? (
            <section className="whatsapp-verification">
              <p>سيفتح واتساب على رقم otlobli. أرسل الرسالة الجاهزة كما هي من نفس الرقم الذي أدخلته.</p>
              <p className="hint">لن يتم التأكيد إذا أرسلت من رقم واتساب مختلف.</p>
              {inboundSupportPhone && <code dir="ltr">+{inboundSupportPhone}</code>}
              {inboundVerificationMessage && <code>{inboundVerificationMessage}</code>}
              <a className="primary-action" href={inboundWhatsappUrl} target="_blank" rel="noreferrer">
                فتح واتساب
                <Icon name="open_in_new" />
              </a>
              <p className="hint">بانتظار وصول الرسالة من واتساب...</p>
            </section>
          ) : (
            <div className="otp-grid" dir="ltr">
              {otpDigits.map((digit, index) => (
                <input
                  key={index}
                  ref={(el) => { otpRefs.current[index] = el }}
                  value={digit}
                  inputMode="numeric"
                  maxLength={1}
                  autoFocus={index === 0}
                  autoComplete={index === 0 ? 'one-time-code' : 'off'}
                  aria-label={`رقم ${index + 1} من رمز التحقق`}
                  onChange={(event) => updateOtpDigit(index, event.target.value)}
                  onKeyDown={(event) => handleOtpKeyDown(index, event)}
                  onPaste={(event) => {
                    event.preventDefault()
                    pasteOtpDigits(event.clipboardData.getData('text'))
                  }}
                />
              ))}
            </div>
          )}
          {!inboundWhatsappUrl && !telegramOtp && (
            <button className="primary-action" disabled={authState === 'verifying'} onClick={verifyOtp}>
              {authState === 'verifying' ? 'جاري الفحص...' : 'تأكيد'}
              <Icon name="verified" />
            </button>
          )}
          {!inboundWhatsappUrl && !telegramOtp && <p className="hint">إعادة الإرسال بعد {otpExpiresInSeconds} ثانية</p>}
        </AuthShell>
      )
    }

    if (screen === 'onboarding') {
      return (
        <AuthShell title="أهلاً بك في otlobli" subtitle="أكمل ملفك الشخصي لتسهيل طلباتك">
          <label className="field">
            <span>الاسم الكامل</span>
            <input
              value={onboardingName}
              onChange={(event) => setOnboardingName(event.target.value)}
              placeholder="مثال: محمد أحمد"
              autoFocus
            />
          </label>
          <label className="field">
            <span>المحافظة</span>
            <select value={onboardingGov} onChange={(event) => setOnboardingGov(event.target.value)}>
              {QADMOUS_GOVS.map((gov) => (
                <option key={gov} value={gov}>{gov}</option>
              ))}
            </select>
          </label>
          <button
            className="primary-action"
            disabled={!onboardingName.trim()}
            onClick={() => {
              const profile: UserProfile = { name: onboardingName.trim(), governorate: onboardingGov }
              setUserProfile(profile)
              setRecipient({ ...recipient, name: profile.name, governorate: profile.governorate })
              // حفظ الملف في الخادم حتى لا يحتاج الزبون إعادة الإدخال عند تسجيل دخول لاحق
              if (CUSTOMER_PROFILE_URL && phone) {
                void fetch(CUSTOMER_PROFILE_URL, {
                  method: 'POST',
                  headers: {
                    'content-type': 'application/json',
                    'apikey': SUPABASE_ANON_KEY,
                    'authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                    'x-customer-phone': phone,
                  },
                  body: JSON.stringify({ name: profile.name, governorate: profile.governorate }),
                }).catch(() => undefined)
              }
              setScreen('home')
            }}
          >
            متابعة
            <Icon name="arrow_back" />
          </button>
        </AuthShell>
      )
    }

    if (screen === 'loading') {
      return (
        <MobileShell active="home" onNavigate={setScreen}>
          <Header title="جلب المنتج" unreadCount={unreadCount} onNotifications={openNotifications} />
          <main className="mobile-content">
            <div className="skeleton-card">
              <div className="skeleton image" />
              <div className="skeleton line wide" />
              <div className="skeleton line" />
              <div className="skeleton chips" />
              <div className="skeleton receipt" />
            </div>
            <div className="loading-copy">
              <span className="spinner" />
              <h2>نقوم بجلب تفاصيل المنتج</h2>
              <p>نقرأ الرابط ونجهز الصور والألوان والمقاسات والتكلفة النهائية.</p>
            </div>
          </main>
        </MobileShell>
      )
    }

    if (screen === 'product') {
      if (!activeProduct) { setScreen('home'); return null }
      return (
        <MobileShell active="home" onNavigate={setScreen} hideBottomNav>
          <Header
            title="تفاصيل المنتج"
            back={() => setScreen('home')}
            actions={['share', savedProduct ? 'favorite' : 'favorite']}
            onAction={(action) => {
              if (action === 'share') {
                void navigator.clipboard?.writeText(activeProduct.link)
                showNotice('تم نسخ رابط المنتج')
              }
              if (action === 'favorite') {
                setSavedProduct((value) => !value)
                showNotice(savedProduct ? 'تم إزالة المنتج من المحفوظات' : 'تم حفظ المنتج')
              }
            }}
          />
          <main className="mobile-content product-page">
            {activeProduct.availability === 'out_of_stock' && (
              <div className="availability-banner out-of-stock">
                <Icon name="warning" />
                <span>هذا المنتج غير متوفر حالياً في جميع الخيارات</span>
              </div>
            )}
            <section className="gallery">
              <img
                src={activeProduct.images[activeImage] ?? 'https://placehold.co/400x500/f5f5f5/aaa?text=SHEIN'}
                alt={activeProduct.title}
                onError={(e) => {
                  const img = e.target as HTMLImageElement
                  img.src = 'https://placehold.co/400x500/f5f5f5/aaa?text=SHEIN'
                }}
              />
              {activeProduct.images.length > 1 && (
                <div className="gallery-dots">
                  {activeProduct.images.map((image, index) => (
                    <button
                      className={index === activeImage ? 'is-active' : ''}
                      key={image}
                      onClick={() => setActiveImage(index)}
                      aria-label={`الصورة ${index + 1}`}
                    />
                  ))}
                </div>
              )}
            </section>
            <section className="product-info">
              <p className="source-label">{activeProduct.source}</p>
              <h1>{activeProduct.title}</h1>
              {activeProduct.priceUsd === 0 ? (
                <div className="price-missing-banner">
                  <Icon name="info" />
                  <p>لم يتمكن النظام من قراءة السعر تلقائياً. افتح المنتج على SHEIN، شاهد السعر، ثم أدخله هنا:</p>
                  <button
                    type="button"
                    className="ghost-action"
                    onClick={() => window.open(activeProduct.link, '_blank', 'noopener,noreferrer')}
                  >
                    <Icon name="open_in_new" />
                    فتح المنتج على SHEIN
                  </button>
                  <div className="manual-price-row">
                    <input
                      type="number"
                      inputMode="decimal"
                      placeholder="مثال: 12.99"
                      value={manualPriceUsd}
                      onChange={(e) => {
                        const v = e.target.value
                        setManualPriceUsd(v)
                        const usd = parseFloat(v)
                        if (!isNaN(usd) && usd > 0) {
                          setActiveProduct((p) => p ? { ...p, priceUsd: usd, priceSyp: Math.round(usd * exchangeRate) } : p)
                        }
                      }}
                      dir="ltr"
                    />
                    <span>USD</span>
                  </div>
                </div>
              ) : (
                <div className="price-row">
                  <strong>{formatMoney(applyMargin(activeProduct.priceSyp))}</strong>
                  <span>${(activeProduct.priceUsd * (1 + (profitMarginPercent > 0 ? profitMarginPercent : 0) / 100)).toFixed(2)}</span>
                  <button
                    type="button"
                    className="text-button"
                    onClick={() => window.open(activeProduct.link, '_blank', 'noopener,noreferrer')}
                  >
                    تحقق من السعر على SHEIN
                  </button>
                </div>
              )}
            </section>
            {activeProduct.colors.length > 0 ? (
              <section className="option-block">
                <div className="option-head">
                  <span>اللون</span>
                  {selectedColor && <b>{selectedColor.name}</b>}
                </div>
                <div className="swatches">
                  {activeProduct.colors.map((color) => (
                    <button
                      className={[
                        color.name === selectedColor?.name ? 'is-selected' : '',
                        color.available === false ? 'is-unavailable' : '',
                      ].join(' ').trim()}
                      key={color.name}
                      onClick={() => {
                        setSelectedColor(color)
                        // reset size if current size not available for new color
                        const sizes = getAvailableSizesForColor(activeProduct, color.name)
                        if (selectedSize && !sizes.includes(selectedSize)) {
                          setSelectedSize(sizes[0] ?? '')
                        }
                      }}
                      aria-label={color.name}
                      title={color.available === false ? 'غير متوفر' : color.name}
                    >
                      {color.image ? (
                        <img
                          src={color.image}
                          alt={color.name}
                          onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}
                        />
                      ) : (
                        <span>{color.name}</span>
                      )}
                    </button>
                  ))}
                </div>
              </section>
            ) : (
              <section className="option-block">
                <div className="option-head">
                  <span>اللون (اختياري)</span>
                </div>
                <div className="manual-price-row">
                  <input
                    value={manualColorName}
                    onChange={(e) => setManualColorName(e.target.value)}
                    placeholder="اكتب اللون كما يظهر على SHEIN، مثال: أسود"
                  />
                </div>
              </section>
            )}
            {availableSizes.length > 0 ? (
              <section className="option-block">
                <div className="option-head">
                  <span>المقاس</span>
                  <button className="text-button" onClick={() => showNotice('دليل المقاسات من صفحة المنتج على Shein')}>
                    <Icon name="straighten" />
                    دليل المقاسات
                  </button>
                </div>
                <div className="size-grid">
                  {availableSizes.map((size) => {
                    const unavailable = !isVariantAvailable(activeProduct, selectedColor?.name ?? null, size)
                    return (
                      <button
                        className={[size === selectedSize ? 'is-selected' : '', unavailable ? 'is-unavailable' : ''].join(' ').trim()}
                        key={size}
                        onClick={() => setSelectedSize(size)}
                        title={unavailable ? 'غير متوفر' : size}
                      >
                        {size}
                      </button>
                    )
                  })}
                </div>
                {!currentVariantAvailable && (
                  <p className="variant-unavailable-hint">الخيار المحدد غير متوفر حالياً</p>
                )}
              </section>
            ) : (
              <section className="option-block">
                <div className="option-head">
                  <span>المقاس (اختياري)</span>
                </div>
                <div className="manual-price-row">
                  <input
                    value={selectedSize}
                    onChange={(e) => setSelectedSize(e.target.value)}
                    placeholder="اكتب المقاس كما يظهر على SHEIN، مثال: M"
                  />
                </div>
              </section>
            )}
            <QuantityControl value={quantity} onChange={setQuantity} />
            <PriceBreakdown items={breakdown} total={total} />
            <InfoRow icon="local_shipping" title="توصيل متوقع" body={`من ${activeProduct.deliveryWindow} إلى باب منزلك في سوريا.`} />
          </main>
          <div className="bottom-actions">
            <button
              className="primary-action"
              onClick={addToCart}
              disabled={!currentVariantAvailable || activeProduct.availability === 'out_of_stock'}
            >
              <Icon name="shopping_cart" />
              {!currentVariantAvailable ? 'الخيار غير متوفر' : 'إضافة إلى السلة'}
            </button>
            <button className="round-action" onClick={() => {
              setSavedProduct(true)
              showNotice('تم حفظ المنتج لوقت لاحق')
            }}>
              <Icon name="bookmark" />
            </button>
          </div>
          <Toast message={notice} />
        </MobileShell>
      )
    }

    if (screen === 'cart') {
      return (
        <MobileShell active="cart" onNavigate={setScreen}>
          <Header title="السلة" back={() => setScreen('home')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <main className="mobile-content mobile-content--cart">
            {cartItems.length > 0 ? (
              <>
                {cartItems.map((item) => (
                  <article className="cart-item" key={item.id}>
                    <button
                      type="button"
                      className="cart-item-view"
                      onClick={() => openSheinProductFromCart(item.sourceLink)}
                      aria-label={`عرض ${item.title} على SHEIN`}
                    >
                      <img
                        src={item.image}
                        alt={item.title}
                        onError={(e) => { (e.target as HTMLImageElement).src = 'https://placehold.co/80x100/f5f5f5/aaa?text=صورة' }}
                      />
                    </button>
                    <div className="cart-item-body">
                      <div className="cart-item-top">
                        <h3
                          className="cart-item-view"
                          onClick={() => openSheinProductFromCart(item.sourceLink)}
                        >
                          {item.title}
                        </h3>
                        <button
                          className="delete-cart"
                          onClick={() => setCartItems((items) => items.filter((i) => i.id !== item.id))}
                          aria-label="حذف"
                        >
                          <Icon name="delete" />
                        </button>
                      </div>
                      <p className="cart-item-variant">
                        {item.colorImage && <img className="cart-item-color-swatch" src={item.colorImage} alt={item.color} />}
                        {item.color} · {item.size}
                      </p>
                      {item.needsCustomText && (
                        <div className="cart-custom-field">
                          <label className="cart-custom-label">
                            النص/الاسم المراد نقشه:
                          </label>
                          <input
                            className="cart-custom-input"
                            type="text"
                            placeholder="مثال: محمد"
                            value={item.customText || ''}
                            onChange={(e) => setCartItems((items) => items.map((i) =>
                              i.id === item.id ? { ...i, customText: e.target.value } : i
                            ))}
                          />
                        </div>
                      )}
                      {item.needsCustomPhoto && (
                        <div className="cart-custom-field">
                          <label className="cart-custom-label">
                            {item.customPhotoNote
                              ? `صورة مخصصة (${item.customPhotoNote})`
                              : 'صورة مخصصة مطلوبة'}
                          </label>
                          {item.customPhotoDataUrl ? (
                            <div className="cart-custom-photo-preview">
                              <img src={item.customPhotoDataUrl} alt="صورتك" />
                              <button
                                className="cart-custom-photo-change"
                                onClick={() => setCartItems((items) => items.map((i) =>
                                  i.id === item.id ? { ...i, customPhotoDataUrl: '' } : i
                                ))}
                              >
                                تغيير
                              </button>
                            </div>
                          ) : (
                            <label className="cart-custom-photo-btn">
                              📷 إرفاق صورة
                              <input
                                type="file"
                                accept="image/*"
                                style={{ display: 'none' }}
                                onChange={(e) => {
                                  const file = e.target.files?.[0]
                                  if (!file) return
                                  const reader = new FileReader()
                                  reader.onload = (ev) => {
                                    const dataUrl = ev.target?.result as string
                                    setCartItems((items) => items.map((i) =>
                                      i.id === item.id ? { ...i, customPhotoDataUrl: dataUrl } : i
                                    ))
                                  }
                                  reader.readAsDataURL(file)
                                }}
                              />
                            </label>
                          )}
                        </div>
                      )}
                      <div className="cart-item-bottom">
                        <strong>{formatPrice(getItemPriceSyp(item) * item.quantity)}</strong>
                        <div className="qty-stepper">
                          <button
                            onClick={() => setCartItems((items) => items.map((i) => i.id === item.id ? { ...i, quantity: Math.max(1, i.quantity - 1) } : i))}
                            aria-label="تقليل"
                          >−</button>
                          <span>{item.quantity}</span>
                          <button
                            onClick={() => setCartItems((items) => items.map((i) => i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i))}
                            aria-label="زيادة"
                          >+</button>
                        </div>
                      </div>
                    </div>
                  </article>
                ))}
                <CurrencyToggle value={paymentCurrency} onChange={setPaymentCurrency} />
                <PriceBreakdown items={breakdown} total={total} format={formatPrice} />
                {!meetsMinimumOrder && (
                  <p className="min-order-notice">
                    الحد الأدنى للطلب {formatMoney(MIN_ORDER_SYP)} (أو {MIN_ORDER_USD}$) — أضف منتجات أكثر للمتابعة
                  </p>
                )}
                {hasIncompleteCustom && (
                  <p className="min-order-notice min-order-notice--warn">
                    ⚠️ أكمل بيانات المنتجات المخصصة (الاسم/الصورة) للمتابعة
                  </p>
                )}
              </>
            ) : (
              <EmptyState title="السلة فارغة" body="تصفح SHEIN من الصفحة الرئيسية وأضف منتجات إلى السلة." />
            )}
          </main>
          <div className="sticky-pay-bar">
            <button className="primary-action" disabled={cartItems.length === 0 || !meetsMinimumOrder || hasIncompleteCustom} onClick={() => setScreen('checkout')}>
              المتابعة للدفع
              <Icon name="arrow_back" />
            </button>
          </div>
        </MobileShell>
      )
    }

    if (screen === 'checkout') {
      return (
        <MobileShell active="cart" onNavigate={setScreen} hideBottomNav>
          <Header title="بيانات الاستلام" back={() => setScreen('cart')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <main className="mobile-content">
            <div className="form-card">
              <label className="field">
                <span>اسم المستلم *</span>
                <input
                  value={recipient.name}
                  onChange={(e) => setRecipient({ ...recipient, name: e.target.value })}
                  placeholder="الاسم الكامل"
                  required
                />
              </label>
              <label className="field">
                <span>رقم واتساب المستلم *</span>
                <input
                  value={recipient.phone}
                  onChange={(e) => setRecipient({ ...recipient, phone: e.target.value })}
                  placeholder="مثال: 963912345678"
                  inputMode="tel"
                  required
                />
              </label>
              <label className="field">
                <span>المحافظة *</span>
                <select
                  value={recipient.governorate}
                  onChange={(e) => setRecipient({ ...recipient, governorate: e.target.value, qadmousBranch: '' })}
                  required
                >
                  {QADMOUS_GOVS.map((gov) => (
                    <option key={gov} value={gov}>{gov}</option>
                  ))}
                </select>
              </label>
              {QADMOUS_BRANCHES[recipient.governorate] && (
                <label className="field">
                  <span>فرع القدموس للاستلام *</span>
                  <select
                    value={recipient.qadmousBranch ?? ''}
                    onChange={(e) => setRecipient({ ...recipient, qadmousBranch: e.target.value })}
                  >
                    <option value="">— اختر أقرب فرع —</option>
                    {QADMOUS_BRANCHES[recipient.governorate].map((branch) => (
                      <option key={branch} value={branch}>{branch}</option>
                    ))}
                  </select>
                </label>
              )}
            </div>
            <InfoRow icon="inventory_2" title="طريقة التوصيل" body="التسليم داخل سوريا عبر القدموس عند توفر رقم الشحنة." />
            <CurrencyToggle value={paymentCurrency} onChange={setPaymentCurrency} />
            <div className="coupon-card">
              {appliedCoupon ? (
                <div className="coupon-applied">
                  <span><Icon name="verified" /> كود «{appliedCoupon.code}» مُطبَّق — خصم {formatPrice(Math.min(appliedCoupon.discountSyp, subtotal))}</span>
                </div>
              ) : (
                <div className="coupon-row">
                  <input
                    className="coupon-input"
                    value={couponInput}
                    onChange={(e) => setCouponInput(e.target.value)}
                    placeholder="كود الخصم (اختياري)"
                    autoCapitalize="characters"
                  />
                  <button
                    className="coupon-apply"
                    disabled={couponChecking || !couponInput.trim()}
                    onClick={applyCoupon}
                  >
                    {couponChecking ? '...' : 'تطبيق'}
                  </button>
                </div>
              )}
              {couponMsg && <p className="coupon-msg">{couponMsg}</p>}
            </div>
            {walletBalanceUsd > 0 && (
              <label className="wallet-toggle">
                <span>
                  <Icon name="account_balance_wallet" /> استخدام رصيد المحفظة
                  <small>الرصيد: {formatUsd(walletBalanceUsd)}</small>
                </span>
                <input type="checkbox" checked={useWallet} onChange={(e) => setUseWallet(e.target.checked)} />
              </label>
            )}
            <PriceBreakdown items={breakdown} total={total} format={formatPrice} />
            {(() => {
              const missingBranch = !!(QADMOUS_BRANCHES[recipient.governorate] && !recipient.qadmousBranch)
              const missingBasic = !recipient.name.trim() || !recipient.phone.trim()
              if (missingBasic) return <p className="min-order-notice">يرجى تعبئة اسم المستلم ورقم الواتساب قبل تأكيد الطلب</p>
              if (missingBranch) return <p className="min-order-notice">يرجى اختيار فرع القدموس للتسليم</p>
              return null
            })()}
            <button
              className="primary-action"
              disabled={isStartingPayment || !recipient.name.trim() || !recipient.phone.trim() || !recipient.governorate || !!(QADMOUS_BRANCHES[recipient.governorate] && !recipient.qadmousBranch)}
              onClick={confirmOrder}
            >
              {isStartingPayment
                ? 'جاري تأكيد الطلب...'
                : PAYMENT_MODE === 'auto' ? 'تأكيد الطلب' : 'الدفع الآن عبر شام كاش'}
              <Icon name={PAYMENT_MODE === 'auto' ? 'check_circle' : 'account_balance_wallet'} />
            </button>
          </main>
        </MobileShell>
      )
    }

    if (screen === 'payment') {
      if (!pendingPayment) {
        return (
          <MobileShell active="cart" onNavigate={setScreen} hideBottomNav>
            <Header title="دفع شام كاش" back={() => setScreen('checkout')} unreadCount={unreadCount} onNotifications={openNotifications} />
            <main className="mobile-content">
              <EmptyState title="لا يوجد طلب بانتظار الدفع" body="رجّع لسلتك وابدأ الدفع من جديد." />
            </main>
          </MobileShell>
        )
      }

      // المبلغ والعملة مثبّتين لحظة إنشاء الطلب (المطابقة التلقائية تعتمد
      // عليه بالضبط) - تبديل عملة العرض هون ما بيغيّر المبلغ المطلوب تحويله.
      const amountLabel = pendingPayment.currency === 'USD'
        ? formatUsd(pendingPayment.amount)
        : formatMoney(pendingPayment.amount)

      return (
        <MobileShell active="cart" onNavigate={setScreen} hideBottomNav>
          <Header title="دفع شام كاش" back={() => setScreen('checkout')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <main className="mobile-content">
            <section className="payment-card">
              {shamCashBarcode
                ? <img className="payment-barcode" src={shamCashBarcode} alt="باركود شام كاش" />
                : <div className="qr-code"><Icon name="qr_code_2" /></div>}
              <p>ادفع عبر شام كاش إلى</p>
              <b>{paymentSettings.receiverName}</b>
              <div className="pay-copy-row">
                <span>{shamCashCode || paymentSettings.receiverAccount}</span>
                <button
                  className="text-button"
                  onClick={() => { void navigator.clipboard?.writeText(shamCashCode || paymentSettings.receiverAccount); showNotice('تم نسخ كود شام كاش') }}
                >
                  نسخ الكود
                </button>
              </div>
              <div className="pay-copy-row pay-amount">
                <strong>{amountLabel}</strong>
                <button
                  className="text-button"
                  onClick={() => { void navigator.clipboard?.writeText(String(pendingPayment.amount)); showNotice('تم نسخ المبلغ') }}
                >
                  نسخ المبلغ
                </button>
              </div>
            </section>
            <div className="instruction-list">
              <p>انسخ الكود والمبلغ، افتح شام كاش، وحوّل <b>نفس المبلغ بالضبط</b>.</p>
              <p>ادفع بـ{pendingPayment.currency === 'USD' ? 'الدولار الأمريكي' : 'الليرة السورية'} فقط لهذا الطلب.</p>
              <p>لا تحتاج كتابة رقم الطلب — المطابقة تتم تلقائياً بالمبلغ الفريد.</p>
            </div>
            <button className="primary-action" disabled={verificationState === 'checking'} onClick={verifyB2BPayment}>
              {verificationState === 'checking' ? 'جاري فحص التحويلات...' : 'فحص الدفع الآن'}
              <Icon name="sync" />
            </button>
          </main>
        </MobileShell>
      )
    }

    if (screen === 'success') {
      return (
        <MobileShell active="orders" onNavigate={setScreen} hideBottomNav>
          <main className="success-screen">
            <div className="success-icon"><Icon name="check" /></div>
            <h1>{PAYMENT_MODE === 'auto' ? 'تم استلام طلبك' : 'تم تأكيد الدفع'}</h1>
            <p>
              {PAYMENT_MODE === 'auto'
                ? 'استلمنا طلبك وسنبدأ بشرائه من SHEIN. تابع حالة الطلب من صفحة طلباتي.'
                : 'تمت مطابقة تحويل شام كاش بالمبلغ الدقيق. سنبدأ بشراء الطلب من SHEIN.'}
            </p>
            <button className="primary-action" onClick={() => setScreen('tracking')}>
              متابعة الطلب
              <Icon name="arrow_back" />
            </button>
          </main>
        </MobileShell>
      )
    }

    if (screen === 'orders') {
      return (
        <MobileShell active="orders" onNavigate={setScreen}>
          <Header title="طلباتي" back={() => setScreen('home')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <main className="mobile-content">
            {orders.length === 0 && (
              <EmptyState title="لا توجد طلبات بعد" body="اطلب منتجاً من الصفحة الرئيسية وسيظهر هنا بعد إتمام الدفع." />
            )}
            {orders.map((item) => (
              <article className="order-card" key={item.id} onClick={() => {
                setCurrentOrderId(item.id)
                setRatingStars(0)
                setRatingNote('')
                setScreen('tracking')
              }}>
                <div className="order-card-row">
                  <div>
                    <strong>{item.id}</strong>
                    <span>{orderStatuses[item.statusIndex]}</span>
                    <small>{item.items.length} منتج · {formatMoney(item.total)}</small>
                  </div>
                  <div className="thumb-stack">
                    <img
                      src={item.items[0]?.image || 'https://placehold.co/60x60/f5f5f5/aaa?text=صورة'}
                      alt=""
                      onError={(e) => { (e.target as HTMLImageElement).src = 'https://placehold.co/60x60/f5f5f5/aaa?text=صورة' }}
                    />
                  </div>
                </div>
                {item.paymentIssue && (
                  <div className="payment-issue-banner" onClick={(e) => e.stopPropagation()}>
                    <p>
                      <Icon name="error" /> يوجد مشكلة بالدفع على هذا الطلب
                      {item.paymentIssueNote ? `: ${item.paymentIssueNote}` : ''}
                    </p>
                    {!!item.extraAmountUsd && item.extraAmountUsd > 0 && (
                      <p className="payment-issue-amount">المتبقي: ${item.extraAmountUsd.toFixed(2)}</p>
                    )}
                    <button
                      className="primary-action"
                      onClick={() => openWhatsappSupport(
                        `مرحبا otlobli، أحتاج دفع المبلغ المتبقي على طلبي ${item.id}${item.extraAmountUsd ? ` ($${item.extraAmountUsd.toFixed(2)})` : ''}`,
                      )}
                    >
                      <Icon name="payments" /> دفع المتبقي عبر واتساب
                    </button>
                  </div>
                )}
                <button
                  className="reorder-btn"
                  onClick={(e) => {
                    e.stopPropagation()
                    reorderItems(item)
                  }}
                >
                  <Icon name="refresh" /> إعادة الطلب
                </button>
              </article>
            ))}
          </main>
        </MobileShell>
      )
    }

    if (screen === 'tracking') {
      if (!order) {
        return (
          <MobileShell active="orders" onNavigate={setScreen}>
            <Header title="تتبع الطلب" back={() => setScreen('orders')} unreadCount={unreadCount} onNotifications={openNotifications} />
            <main className="mobile-content">
              <EmptyState title="لا يوجد طلب" body="اختر طلباً من قائمة طلباتك لتتبعه." />
            </main>
          </MobileShell>
        )
      }
      return (
        <MobileShell active="orders" onNavigate={setScreen}>
          <Header title="تتبع الطلب" back={() => setScreen('orders')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <main className="mobile-content">
            <section className="tracking-head">
              <span>{order.id}</span>
              <StatusBadge tone={order.paymentStatus === 'مدفوع' ? 'success' : 'pending'}>{order.paymentStatus}</StatusBadge>
              <StatusBadge tone="pending">{orderStatuses[order.statusIndex]}</StatusBadge>
              <p>{order.qadmousNumber ? `رقم القدموس: ${order.qadmousNumber}` : 'رقم القدموس سيظهر بعد تسليم الشحنة.'}</p>
            </section>
            <Timeline statusIndex={order.statusIndex} createdAt={order.createdAt} paidAt={order.paidAt} />
            {order.items.length > 0 && (
              <section className="tracking-items">
                <button
                  className="tracking-items-toggle"
                  onClick={() => setShowTrackingItems((v) => !v)}
                >
                  <span><Icon name="shopping_bag" /> {showTrackingItems ? 'إخفاء المنتجات' : `عرض المنتجات (${order.items.length})`}</span>
                </button>
                {showTrackingItems && (
                  <ul className="tracking-items-list">
                    {order.items.map((it) => (
                      <li className="tracking-item" key={it.id}>
                        <img
                          src={it.colorImage || it.image || 'https://placehold.co/56x56/f5f5f5/aaa?text=صورة'}
                          alt=""
                          onError={(e) => { (e.target as HTMLImageElement).src = 'https://placehold.co/56x56/f5f5f5/aaa?text=صورة' }}
                        />
                        <div className="tracking-item-info">
                          <strong>{it.title}</strong>
                          <small>
                            {[it.color, it.size].filter(Boolean).join(' · ')}
                            {it.quantity > 1 ? ` · ×${it.quantity}` : ''}
                          </small>
                        </div>
                      </li>
                    ))}
                  </ul>
                )}
              </section>
            )}
            {order.statusIndex === orderStatuses.length - 1 && (
              order.rating ? (
                <section className="rating-box">
                  <p>شكراً لتقييمك! {'⭐'.repeat(order.rating)}</p>
                </section>
              ) : (
                <section className="rating-box">
                  <p>كيف كانت تجربتك مع هذا الطلب؟</p>
                  <div className="rating-stars">
                    {[1, 2, 3, 4, 5].map((n) => (
                      <button
                        key={n}
                        className={n <= ratingStars ? 'star is-filled' : 'star'}
                        onClick={() => setRatingStars(n)}
                        aria-label={`${n} نجوم`}
                      >
                        <Icon name="star" />
                      </button>
                    ))}
                  </div>
                  <textarea
                    value={ratingNote}
                    onChange={(e) => setRatingNote(e.target.value)}
                    placeholder="ملاحظة (اختياري)"
                    rows={2}
                  />
                  <button
                    className="primary-action"
                    disabled={ratingStars < 1 || isSubmittingRating}
                    onClick={() => submitRating(order.id)}
                  >
                    {isSubmittingRating ? '...' : 'إرسال التقييم'}
                  </button>
                </section>
              )
            )}
            <button
              className="ghost-action"
              style={{ marginTop: 8, marginBottom: 16 }}
              onClick={() => openWhatsappSupport(`مرحبا otlobli، أحتاج مساعدة بخصوص الطلب ${order.id}`)}
            >
              <Icon name="support_agent" /> تواصل معنا عبر واتساب
            </button>
          </main>
        </MobileShell>
      )
    }

    if (screen === 'profile') {
      const avatarLetter = (userProfile?.name ?? recipient.name ?? 'م')[0] ?? 'م'
      const displayName = userProfile?.name ?? recipient.name ?? 'مستخدم otlobli'

      if (editingProfile) {
        return (
          <MobileShell active="profile" onNavigate={setScreen}>
            <Header title="تعديل الملف الشخصي" back={() => setEditingProfile(false)} unreadCount={unreadCount} onNotifications={openNotifications} />
            <main className="mobile-content">
              <div className="form-card">
                <label className="field">
                  <span>الاسم الكامل</span>
                  <input value={editName} onChange={(e) => setEditName(e.target.value)} placeholder="الاسم" />
                </label>
                <label className="field">
                  <span>المحافظة</span>
                  <select value={editGov} onChange={(e) => setEditGov(e.target.value)}>
                    {QADMOUS_GOVS.map((gov) => (
                      <option key={gov} value={gov}>{gov}</option>
                    ))}
                  </select>
                </label>
              </div>
              <button
                className="primary-action"
                disabled={!editName.trim()}
                onClick={() => {
                  const updated: UserProfile = { name: editName.trim(), governorate: editGov }
                  setUserProfile(updated)
                  setRecipient({ ...recipient, name: updated.name, governorate: updated.governorate })
                  setEditingProfile(false)
                  showNotice('تم تحديث الملف الشخصي')
                }}
              >
                حفظ التغييرات
                <Icon name="check" />
              </button>
            </main>
            <Toast message={notice} />
          </MobileShell>
        )
      }

      return (
        <MobileShell active="profile" onNavigate={setScreen}>
          <Header title="حسابي" back={() => setScreen('home')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <main className="mobile-content">
            <section className="profile-card">
              <div className="avatar">{avatarLetter}</div>
              <div>
                <h2>{displayName}</h2>
                <p>{phone ? `+${phone}` : '+963 9xx xxx xxx'}</p>
                {userProfile?.governorate && <small>{userProfile.governorate}</small>}
              </div>
              <button
                className="icon-button"
                onClick={() => {
                  setEditName(userProfile?.name ?? '')
                  setEditGov(userProfile?.governorate ?? 'دمشق')
                  setEditingProfile(true)
                }}
                aria-label="تعديل"
              >
                <Icon name="edit" />
              </button>
            </section>
            <ProfileRow
              icon="currency_exchange"
              label={`عملة الدفع: ${paymentCurrency === 'USD' ? 'دولار أمريكي' : 'ليرة سورية'}`}
              onClick={() => setPaymentCurrency(paymentCurrency === 'USD' ? 'SYP' : 'USD')}
            />
            <ProfileRow icon="storefront" label={`المتجر: ${STORES.find((s) => s.id === selectedStore)?.name ?? ''}`} onClick={() => setScreen('store-select')} />
            <ProfileRow icon="notifications" label="إعدادات الإشعارات" onClick={() => setScreen('notification-settings')} />
            <ProfileRow icon="contract" label="الشروط والأحكام" onClick={() => setScreen('terms')} />
            <ProfileRow icon="support_agent" label="الدعم" onClick={() => setScreen('support')} />
            <button className="profile-row profile-row--danger" onClick={logout}>
              <span><Icon name="logout" /> تسجيل الخروج</span>
              <Icon name="chevron_left" />
            </button>
            <p className="app-version-tag">نسخة التطبيق: {APP_VERSION}</p>
          </main>
        </MobileShell>
      )
    }

    if (screen === 'addresses') {
      return (
        <MobileShell active="profile" onNavigate={setScreen} hideBottomNav>
          <Header title="العناوين" back={() => setScreen('profile')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <AccountDetailLayout>
            {addresses.map((address) => (
              <section className={`address-card ${address.isDefault ? 'is-default' : ''}`} key={address.id}>
                <div>
                  <b>{address.label}</b>
                  {address.isDefault && <StatusBadge tone="success">افتراضي</StatusBadge>}
                </div>
                <p>{address.governorate}، {address.city}، {address.details}</p>
                <small>{address.name} · {address.phone}</small>
                <button className="ghost-action" onClick={() => {
                  setAddresses((list) => list.map((item) => ({ ...item, isDefault: item.id === address.id })))
                  setRecipient(address)
                  showNotice('تم تعيين العنوان الافتراضي')
                }}>
                  تعيين كعنوان افتراضي
                </button>
              </section>
            ))}
            <section className="form-card">
              <h2>إضافة عنوان من بيانات الاستلام الحالية</h2>
              <p className="form-note">عدّل بيانات الاستلام من صفحة الدفع، ثم احفظها هنا كعنوان دائم.</p>
              <button className="primary-action" onClick={addAddress}>حفظ العنوان</button>
            </section>
          </AccountDetailLayout>
          <Toast message={notice} />
        </MobileShell>
      )
    }

    if (screen === 'payment-methods') {
      return (
        <MobileShell active="profile" onNavigate={setScreen} hideBottomNav>
          <Header title="طرق الدفع" back={() => setScreen('profile')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <AccountDetailLayout>
            <section className="wallet-card">
              <div>
                <Icon name="account_balance_wallet" />
                <section>
                  <h2>{paymentSettings.provider}</h2>
                  <p>{paymentSettings.rule}</p>
                </section>
              </div>
              <StatusBadge tone="success">نشط في النسخة التجريبية</StatusBadge>
            </section>
            <section className="payment-rules">
              <h2>تعليمات الدفع للعميل</h2>
              <p>يدفع العميل من أي حساب شام كاش إلى حسابنا التجاري.</p>
              <p>لا نطلب منه رقم الطلب في الملاحظة.</p>
              <p>المطابقة تعتمد على المبلغ الدقيق. أي فرق بسيط يمنع التأكيد التلقائي.</p>
            </section>
          </AccountDetailLayout>
        </MobileShell>
      )
    }

    if (screen === 'blocked-policy') {
      return (
        <MobileShell active="profile" onNavigate={setScreen} hideBottomNav>
          <Header title="سياسة المنتجات" back={() => setScreen('profile')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <AccountDetailLayout>
            <section className="policy-card">
              <h2>نقبل حالياً</h2>
              <div className="policy-grid">{allowedProducts.map((item) => <span key={item}>{item}</span>)}</div>
            </section>
            <section className="policy-card policy-card--warning">
              <h2>لا نقبل حالياً</h2>
              {blockedProducts.map((item) => (
                <div className="policy-row" key={item}>
                  <Icon name="block" />
                  <div>
                    <b>{item}</b>
                    <p>قد تحتاج موافقات أو تسبب رفضاً جمركياً أو تأخيراً في الشحن.</p>
                  </div>
                </div>
              ))}
            </section>
          </AccountDetailLayout>
        </MobileShell>
      )
    }

    if (screen === 'terms') {
      return (
        <MobileShell active="profile" onNavigate={setScreen} hideBottomNav>
          <Header title="الشروط والأحكام" back={() => setScreen('profile')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <AccountDetailLayout>
            <LegalSection title="التسعير">
              السعر النهائي يشمل سعر المنتج والشحن والرسوم التشغيلية المتوقعة. يبقى السعر صالحاً خلال جلسة الدفع فقط.
            </LegalSection>
            <LegalSection title="الدفع">
              يجب دفع نفس المبلغ بالضبط إلى حسابنا التجاري. المطابقة لا تعتمد على رقم الطلب أو حساب المرسل.
            </LegalSection>
            <LegalSection title="الشحن">
              مدة الشحن تقديرية وتعتمد على وصول الطلب إلى مركز التجميع ثم نقله إلى سوريا وتسليمه للقدموس.
            </LegalSection>
            <LegalSection title="الإلغاء">
              يمكن إلغاء الطلب قبل الشراء من المصدر. بعد الشراء يخضع الإلغاء لحالة الشحنة وسياسة المصدر.
            </LegalSection>
          </AccountDetailLayout>
        </MobileShell>
      )
    }

    if (screen === 'support') {
      return (
        <MobileShell active="profile" onNavigate={setScreen} hideBottomNav>
          <Header title="الدعم" back={() => setScreen('profile')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <AccountDetailLayout>
            <section className="support-card">
              <h2>كيف نساعدك؟</h2>
              <p>أرسل رقم الطلب أو رابط المنتج وسيتم الرد عليك عبر واتساب.</p>
              <button
                className="primary-action"
                onClick={() => openWhatsappSupport('مرحبا otlobli، أحتاج مساعدة بخصوص طلب أو منتج.')}
              >
                فتح واتساب
                <Icon name="open_in_new" />
              </button>
            </section>
            <section className="faq-mini">
              {[
                ['متى يظهر رقم القدموس؟', 'بعد تسليم الشحنة لشركة القدموس داخل سوريا.'],
                ['هل يجب كتابة رقم الطلب في التحويل؟', 'لا. في نظام B2B نطابق المبلغ الدقيق فقط.'],
                ['ماذا لو دفعت مبلغاً مختلفاً؟', 'لن يتم التأكيد التلقائي، وسيحتاج الطلب لمراجعة يدوية.'],
              ].map(([question, answer]) => (
                <article key={question}>
                  <h3>{question}</h3>
                  <p>{answer}</p>
                </article>
              ))}
            </section>
          </AccountDetailLayout>
        </MobileShell>
      )
    }

    if (screen === 'store-select') {
      const switchStore = (id: StoreId) => {
        if (id !== selectedStore) {
          setSelectedStore(id)
          selectedStoreRef.current = id
          // ⚠️ لا تُبسّط هذا التسلسل (خلل شاشة بيضاء مؤكَّد 2026-07-03):
          // إغلاق متصفّح المتجر الحالي ثم إعادة فتحه على المتجر الجديد (تُحقن
          // سكربتات otlobli من جديد). ننتظر اكتمال الإغلاق فعلياً قبل التنقل
          // للرئيسية (بدل إطلاق الإغلاق والتنقل معاً في نفس اللحظة) — إغلاق
          // وفتح متزامنين كانا يُدخلان البراوزر الأصلي بحالة عالقة (شاشة
          // بيضاء لا تُصلَح إلا بإغلاق التطبيق كلياً من الخلفية). العلم يمنع
          // مستمع closeEvent من إعادة فتح مكرّرة لهذا الإغلاق المقصود.
          suppressAutoReopenRef.current = true
          sheinOpenedRef.current = false
          setSheinReady(false)
          void InAppBrowser.close().catch(() => undefined).then(() => {
            suppressAutoReopenRef.current = false
            setScreen('home')
          })
          return
        }
        setScreen('home')
      }
      return (
        <MobileShell active="profile" onNavigate={setScreen} hideBottomNav>
          <Header title="اختيار المتجر" back={() => setScreen('profile')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <AccountDetailLayout>
            <p className="settings-hint">اختر المتجر الذي تريد التصفّح والطلب منه. لكل متجر سلة منفصلة.</p>
            {STORES.map((store) => (
              <button
                key={store.id}
                className="notif-setting-row"
                onClick={() => switchStore(store.id)}
                aria-pressed={selectedStore === store.id}
              >
                <span className="notif-setting-icon"><Icon name="storefront" /></span>
                <span className="notif-setting-text">
                  <b>{store.name}</b>
                  <small>{store.id === 'shein' ? 'متاح بالكامل' : 'تصفّح فقط حالياً'}</small>
                </span>
                {selectedStore === store.id && <Icon name="check_circle" />}
              </button>
            ))}
          </AccountDetailLayout>
          <Toast message={notice} />
        </MobileShell>
      )
    }

    if (screen === 'notification-settings') {
      const prefRows: Array<{ key: keyof NotificationPrefs; icon: string; title: string; body: string }> = [
        { key: 'orderUpdates', icon: 'local_shipping', title: 'تحديثات الطلب', body: 'إشعار عند انتقال طلبك لكل مرحلة جديدة (قيد الشراء، في الطريق، تم التسليم...).' },
        { key: 'payment', icon: 'payments', title: 'الدفع', body: 'إشعار عند استلام طلبك وتأكيد الدفع.' },
        { key: 'system', icon: 'campaign', title: 'العروض والتنبيهات', body: 'أخبار otlobli والعروض والتنبيهات العامة.' },
        { key: 'whatsapp', icon: 'chat', title: 'إشعارات واتساب', body: 'وصول نسخة من إشعاراتك على رقم الواتساب المسجَّل، إضافةً لداخل التطبيق.' },
      ]
      return (
        <MobileShell active="profile" onNavigate={setScreen} hideBottomNav>
          <Header title="إعدادات الإشعارات" back={() => setScreen('profile')} unreadCount={unreadCount} onNotifications={openNotifications} />
          <AccountDetailLayout>
            <p className="settings-hint">تحكّم بأنواع الإشعارات التي تصلك. يمكنك إيقاف أي نوع لا يهمّك.</p>
            {prefRows.map((row) => (
              <button
                key={row.key}
                className="notif-setting-row"
                onClick={() => setNotificationPrefs((prev) => ({ ...prev, [row.key]: !prev[row.key] }))}
                aria-pressed={notificationPrefs[row.key]}
              >
                <span className="notif-setting-icon"><Icon name={row.icon} /></span>
                <span className="notif-setting-text">
                  <b>{row.title}</b>
                  <small>{row.body}</small>
                </span>
                <span className={`switch ${notificationPrefs[row.key] ? 'switch--on' : ''}`}>
                  <span className="switch-knob" />
                </span>
              </button>
            ))}
          </AccountDetailLayout>
          <Toast message={notice} />
        </MobileShell>
      )
    }

    if (screen === 'notifications') {
      return (
        <MobileShell active="orders" onNavigate={setScreen} hideBottomNav>
          <Header
            title="الإشعارات"
            back={() => setScreen(previousScreenRef.current)}
            actions={notifications.length > 0 ? ['done_all'] : []}
            onAction={() => setNotifications((prev) => prev.map((n) => ({ ...n, read: true })))}
          />
          <main className="mobile-content">
            {notifications.length === 0 ? (
              <EmptyState title="لا توجد إشعارات" body="ستظهر تحديثات طلباتك هنا تلقائياً." />
            ) : (
              notifications.map((notif) => (
                <article
                  key={notif.id}
                  className={`notification-item ${notif.read ? '' : 'notification-item--unread'}`}
                  onClick={() => {
                    setNotifications((prev) => prev.map((n) => n.id === notif.id ? { ...n, read: true } : n))
                    if (notif.orderId) {
                      setCurrentOrderId(notif.orderId)
                      if (notif.type === 'payment_issue') {
                        setScreen('orders')
                      } else {
                        setRatingStars(0)
                        setRatingNote('')
                        setScreen('tracking')
                      }
                    }
                  }}
                >
                  <div className="notif-icon">
                    <Icon name={notif.type === 'payment_issue' ? 'error' : notif.type === 'payment' ? 'payments' : notif.type === 'order_update' ? 'local_shipping' : 'info'} />
                  </div>
                  <div className="notif-body">
                    <b>{notif.title}</b>
                    <p>{notif.body}</p>
                    <small>{notif.createdAt}</small>
                  </div>
                  {!notif.read && <span className="notif-dot" />}
                </article>
              ))
            )}
          </main>
          <Toast message={notice} />
        </MobileShell>
      )
    }

    const currentStoreName = STORES.find((s) => s.id === selectedStore)?.name ?? 'المتجر'
    return (
      // Keep React's own nav mounted here at all times, even while SHEIN's
      // webview (with its own injected nav - see ensureOtlobliNav) is
      // covering the whole screen on top of it. Conditionally unmounting it
      // while SHEIN is showing meant React had to mount it fresh from
      // scratch the moment the user switched to another tab, right as the
      // native webview was hiding - a real source of the "jump"/flash
      // reported when switching screens. With it always present underneath,
      // hiding the webview just reveals a nav that was already laid out,
      // not one that still needs to render.
      <MobileShell active="home" onNavigate={setScreen}>
        {(!sheinReady || sheinBlockedError || vpnState !== 'ok') && (
          <Header title="otlobli" unreadCount={unreadCount} onNotifications={openNotifications} />
        )}
        {vpnState === 'checking' ? (
          <main className="mobile-content shein-home">
            <section className="greeting">
              <h1>جاري التحقق من الاتصال...</h1>
              <p>نتأكد إن في طريق شبكة سليم لمتجر {currentStoreName}</p>
            </section>
            <span className="spinner" />
          </main>
        ) : vpnState === 'blocked' ? (
          <main className="mobile-content shein-home">
            <div className="empty-state">
              <Icon name="vpn_key" />
              <h2>فعّل الـ VPN أولاً</h2>
              <p>متجر {currentStoreName} محجوب في سوريا - شغّل تطبيق VPN على جهازك، وبعدها اضغط الزر تحت لنتحقق من جديد.</p>
            </div>
            <button className="primary-action" onClick={() => setVpnState('checking')}>
              <Icon name="refresh" />
              تحقّق من جديد
            </button>
          </main>
        ) : sheinBlockedError ? (
          <main className="mobile-content shein-home">
            <div className="empty-state">
              <Icon name="wifi_off" />
              <h2>تعذّر فتح موقع {currentStoreName}</h2>
              <p>يبدو أن الموقع محجوب مؤقتاً. جرّب مرة ثانية أو امسح الكوكيز.</p>
            </div>
            <button className="primary-action" onClick={() => {
              setSheinBlockedError(false)
              // Closes the webview outright instead of setUrl()+show() on the
              // SAME instance - a failed connection attempt (e.g. one that
              // raced a just-toggled VPN still settling) left this exact
              // session stuck repeating that same failure on every retry;
              // only a genuinely fresh instance recovered. closeEvent's own
              // listener re-opens automatically while still on 'home' - only
              // call browseShein() here if that somehow didn't happen.
              void InAppBrowser.close().catch(() => undefined).then(() => {
                if (!sheinOpenedRef.current) browseShein()
              })
            }}>
              <Icon name="refresh" />
              إعادة المحاولة
            </button>
            <button className="ghost-action" onClick={() => {
              setSheinBlockedError(false)
              void InAppBrowser.clearAllCookies().finally(() => {
                void InAppBrowser.close().catch(() => undefined).then(() => {
                  if (!sheinOpenedRef.current) browseShein()
                })
              })
            }}>
              <Icon name="delete_sweep" />
              مسح الكوكيز وإعادة التحميل
            </button>
          </main>
        ) : !sheinReady ? (
          <HomeScreen userName={userProfile?.name} storeName={currentStoreName} onRetry={() => { sheinOpenedRef.current = false; browseShein() }} />
        ) : null}
      </MobileShell>
    )
  }

  return (
    <div className="app-root">
      {renderScreen()}
      <Toast message={notice} />
    </div>
  )
}

function AuthShell({ title, subtitle, children, onBack }: { title: string; subtitle: string; children: ReactNode; onBack?: () => void }) {
  return (
    <div className="auth-shell">
      <div className="auth-card">
        {onBack && (
          <button type="button" className="back-btn" onClick={onBack} aria-label="رجوع">
            <Icon name="arrow_forward" />
            <span>تغيير الرقم</span>
          </button>
        )}
        <div className="brand-lockup">
          <span>otlobli</span>
          <small>اطلب من SHEIN واستلم في سوريا</small>
        </div>
        <h1>{title}</h1>
        <p>{subtitle}</p>
        {children}
      </div>
    </div>
  )
}

function Header({
  title,
  back,
  actions = [],
  onAction,
  unreadCount = 0,
  onNotifications,
}: {
  title: string
  back?: () => void
  actions?: string[]
  onAction?: (action: string) => void
  unreadCount?: number
  onNotifications?: () => void
}) {
  return (
    <header className="app-header">
      <div>
        {back && <button className="icon-button" onClick={back}><Icon name="arrow_forward" /></button>}
        <h1>{title}</h1>
      </div>
      <div>
        {actions.map((action) => (
          <button className="icon-button" key={action} onClick={() => onAction?.(action)}><Icon name={action} /></button>
        ))}
        {!actions.length && (
          <button className="icon-button notif-bell" onClick={onNotifications} aria-label="الإشعارات">
            <Icon name="notifications" />
            {unreadCount > 0 && (
              <span className="notif-badge">{unreadCount > 9 ? '9+' : unreadCount}</span>
            )}
          </button>
        )}
      </div>
    </header>
  )
}

function Toast({ message }: { message: string }) {
  if (!message) {
    return null
  }
  return <div className="toast">{message}</div>
}

function HomeScreen({ userName, onRetry, storeName = 'المتجر' }: { userName?: string; onRetry?: () => void; storeName?: string }) {
  const [timedOut, setTimedOut] = useState(false)
  useEffect(() => {
    const t = window.setTimeout(() => setTimedOut(true), 30_000)
    return () => window.clearTimeout(t)
  }, [])
  return (
    <main className="mobile-content shein-home">
      <section className="greeting">
        <h1>{userName ? `أهلاً، ${userName}` : 'أهلاً بك'}</h1>
        {timedOut ? (
          <p style={{ color: 'var(--danger)' }}>تعذّر فتح موقع {storeName}. تأكد من اتصالك بالإنترنت.</p>
        ) : (
          <p>جاري تجهيز متجر {storeName}...</p>
        )}
      </section>
      {timedOut ? (
        <button className="ghost-action" onClick={onRetry}>
          <Icon name="refresh" /> إعادة المحاولة
        </button>
      ) : (
        <span className="spinner" />
      )}
    </main>
  )
}

const NAV_ICONS = {
  home:    '<path d="M4 11.5 12 4l8 7.5"/><path d="M6 10v9h12v-9"/><path d="M10 19v-5h4v5"/>',
  orders:  '<rect x="4" y="7" width="16" height="13" rx="1.3"/><path d="M4 7l8-4 8 4"/><path d="M12 11v9"/>',
  cart:    '<circle cx="9" cy="20" r="1.3"/><circle cx="18" cy="20" r="1.3"/><path d="M3 4h2l2.2 11.5a2 2 0 0 0 2 1.6h8.6a2 2 0 0 0 2-1.6L21 8H6"/>',
  profile: '<circle cx="12" cy="8" r="3.6"/><path d="M5 20c0-3.8 3.1-6.4 7-6.4s7 2.6 7 6.4"/>',
}

function MobileShell({
  children,
  active,
  onNavigate,
  hideBottomNav,
}: {
  active?: 'home' | 'orders' | 'cart' | 'profile'
  children: ReactNode
  onNavigate?: (screen: Screen) => void
  hideBottomNav?: boolean
}) {
  return (
    <div className="mobile-shell">
      {children}
      {!hideBottomNav && onNavigate && (
        <nav className="bottom-nav">
          <NavButton active={active === 'home'}    svgPaths={NAV_ICONS.home}    label="الرئيسية" onClick={() => onNavigate('home')} />
          <NavButton active={active === 'orders'}  svgPaths={NAV_ICONS.orders}  label="طلباتي"   onClick={() => onNavigate('orders')} />
          <NavButton active={active === 'cart'}    svgPaths={NAV_ICONS.cart}    label="السلة"    onClick={() => onNavigate('cart')} />
          <NavButton active={active === 'profile'} svgPaths={NAV_ICONS.profile} label="حسابي"   onClick={() => onNavigate('profile')} />
        </nav>
      )}
    </div>
  )
}

function NavButton({ active, svgPaths, label, onClick }: { active: boolean; svgPaths: string; label: string; onClick: () => void }) {
  return (
    <button className={active ? 'is-active' : ''} onClick={onClick}>
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" dangerouslySetInnerHTML={{ __html: svgPaths }} />
      <span>{label}</span>
    </button>
  )
}

function ProfileRow({ icon, label, onClick }: { icon: string; label: string; onClick: () => void }) {
  return (
    <button className="profile-row" onClick={onClick}>
      <span><Icon name={icon} /> {label}</span>
      <Icon name="chevron_left" />
    </button>
  )
}

function InfoRow({ icon, title, body, compact = false }: { icon: string; title: string; body: string; compact?: boolean }) {
  return (
    <div className={`info-row ${compact ? 'info-row--compact' : ''}`}>
      <div><Icon name={icon} /></div>
      <section>
        <h3>{title}</h3>
        {body && <p>{body}</p>}
      </section>
    </div>
  )
}

function ChipSection({ title, icon, chips, warning = false }: { title: string; icon: string; chips: string[]; warning?: boolean }) {
  return (
    <section className={`chip-section ${warning ? 'chip-section--warning' : ''}`}>
      <h2><Icon name={icon} /> {title}</h2>
      <div>{chips.map((chip) => <span key={chip}>{chip}</span>)}</div>
    </section>
  )
}

function QuantityControl({ value, onChange }: { value: number; onChange: (next: number) => void }) {
  return (
    <section className="quantity-card">
      <span>الكمية</span>
      <div>
        <button onClick={() => onChange(Math.max(1, value - 1))}><Icon name="remove" /></button>
        <strong>{value}</strong>
        <button onClick={() => onChange(value + 1)}><Icon name="add" /></button>
      </div>
    </section>
  )
}

function PriceBreakdown({
  items,
  total,
  format = formatMoney,
}: {
  items: Array<{ label: string; value: number }>
  total: number
  format?: (value: number) => string
}) {
  return (
    <section className="price-breakdown">
      <h3>تفاصيل التكلفة</h3>
      {items.map((item) => (
        <div className="price-line" key={item.label}>
          <span>{item.label}</span>
          <b>{format(item.value)}</b>
        </div>
      ))}
      <div className="price-total">
        <span>الإجمالي</span>
        <strong>{format(total)}</strong>
      </div>
    </section>
  )
}

function CurrencyToggle({ value, onChange }: { value: PaymentCurrency; onChange: (next: PaymentCurrency) => void }) {
  return (
    <div className="currency-toggle">
      <button className={value === 'SYP' ? 'active' : ''} onClick={() => onChange('SYP')}>ليرة سورية</button>
      <button className={value === 'USD' ? 'active' : ''} onClick={() => onChange('USD')}>دولار أمريكي</button>
    </div>
  )
}

function EmptyState({ title, body }: { title: string; body: string }) {
  return (
    <section className="empty-state">
      <Icon name="shopping_bag" />
      <h2>{title}</h2>
      <p>{body}</p>
    </section>
  )
}

function Timeline({ statusIndex, createdAt, paidAt }: { statusIndex: number; createdAt?: string; paidAt?: string }) {
  const stageDate = (index: number) => {
    if (index > statusIndex) return 'لاحقاً'
    if (index === 0) return createdAt ?? today()
    if (index === 1) return paidAt ?? createdAt ?? today()
    return today()
  }
  return (
    <section className="timeline">
      {orderStatuses.map((status, index) => (
        <div className={index < statusIndex ? 'is-done' : index === statusIndex ? 'is-active' : ''} key={status}>
          <span>{index <= statusIndex ? <Icon name="check" /> : <Icon name="schedule" />}</span>
          <section>
            <h3>{status}</h3>
            <p>{index < statusIndex ? 'تم تحديث هذه المرحلة بنجاح.' : index === statusIndex ? 'هذه المرحلة قيد التنفيذ الآن.' : 'بانتظار الوصول لهذه المرحلة.'}</p>
            <small>{stageDate(index)}</small>
          </section>
        </div>
      ))}
    </section>
  )
}

function AccountDetailLayout({ children }: { children: ReactNode }) {
  return <main className="mobile-content account-detail">{children}</main>
}

function LegalSection({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="legal-section">
      <h2>{title}</h2>
      <p>{children}</p>
    </section>
  )
}

export default App
