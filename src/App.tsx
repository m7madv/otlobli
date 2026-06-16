import { useEffect, useMemo, useRef, useState } from 'react'
import type { ReactNode } from 'react'
import {
  allowedProducts,
  blockedProducts,
  initialAddresses,
  initialOrders,
  orderStatuses,
  paymentSettings,
  shippingFees,
} from './domain/fixtures'
import { makeOrderId, today } from './domain/orders'
import { buildPriceBreakdown, formatMoney, formatPriceSyp, sumPriceLines } from './domain/pricing'
import type { PaymentCurrency } from './domain/pricing'
import type { Address, CartItem, Order, Product, ProductColor, ProductVariant, Recipient, Screen, StatusTone, UserProfile } from './domain/types'
import { readStoredJson, storageKeys, useStoredState } from './infrastructure/localStorage'
import { appApi } from './services'
import { buildWhatsappLink } from './services/whatsappLink'
import { SHEIN_CAPTURE_SCRIPT } from './services/sheinBrowserScript'
import { InAppBrowser, ToolBarType } from '@capgo/capacitor-inappbrowser'

const API_BASE = import.meta.env.VITE_WHATSAPP_API_URL || ''

const usesInboundWhatsappAuth = import.meta.env.VITE_WHATSAPP_AUTH_MODE === 'inbound'

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

const DEFAULT_EXCHANGE_RATE = parseInt(import.meta.env.VITE_USD_TO_SYP_RATE ?? '13000')

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
  const [exchangeRate, setExchangeRate] = useStoredState<number>(storageKeys.exchangeRate, DEFAULT_EXCHANGE_RATE)

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
  const [cartItems, setCartItems] = useStoredState<CartItem[]>(storageKeys.cartItems, [])
  const [orders, setOrders] = useStoredState<Order[]>(storageKeys.orders, initialOrders)
  const [addresses, setAddresses] = useStoredState<Address[]>(storageKeys.addresses, initialAddresses)
  const [currentOrderId, setCurrentOrderId] = useStoredState<string>(storageKeys.currentOrderId, '')
  const [recipient, setRecipient] = useStoredState<Recipient>(storageKeys.recipient, {
    name: '', phone: '', governorate: 'دمشق', city: '', details: '', notes: '',
  })
  const [verificationState, setVerificationState] = useState<'idle' | 'checking' | 'matched'>('idle')
  const [manualPriceUsd, setManualPriceUsd] = useState('')
  const [manualColorName, setManualColorName] = useState('')

  const [onboardingName, setOnboardingName] = useState(userProfile?.name ?? '')
  const [onboardingGov, setOnboardingGov] = useState(userProfile?.governorate ?? 'دمشق')
  const [editingProfile, setEditingProfile] = useState(false)
  const [editName, setEditName] = useState('')
  const [editGov, setEditGov] = useState('')

  const order = orders.find((item) => item.id === currentOrderId) ?? orders[0] ?? null

  const showNotice = (message: string) => {
    setNotice(message)
    window.setTimeout(() => setNotice(''), 1900)
  }

  const logout = () => {
    setSessionToken('')
    setScreen('login')
  }

  useEffect(() => {
    const url = `${API_BASE}/api/exchange-rate`
    fetch(url)
      .then((r) => r.json())
      .then((data: { rate?: number }) => {
        if (data.rate && data.rate > 1000) {
          setExchangeRate(data.rate)
        }
      })
      .catch(() => undefined)
  }, [setExchangeRate])

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
        .then(() => {
          setSessionToken(phone)
          setPendingWhatsappAuth(null)
          setInboundWhatsappUrl('')
          setInboundSupportPhone('')
          setInboundVerificationMessage('')
          if (!userProfile) {
            setScreen('onboarding')
          } else {
            setScreen('home')
          }
          showNotice('تم تأكيد رقم واتساب من الرسالة')
        })
        .catch(() => undefined)
    }

    checkInboundMessage()
    const intervalId = window.setInterval(checkInboundMessage, 2500)

    return () => window.clearInterval(intervalId)
  }, [inboundWhatsappUrl, phone, screen, setPendingWhatsappAuth, setSessionToken, userProfile])

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

  const breakdown = useMemo(() => {
    if (cartItems.length > 0) {
      const itemLines = cartItems.map((item) => ({ label: item.title, value: item.priceSyp * item.quantity }))
      return [...itemLines, ...shippingFees]
    }
    return buildPriceBreakdown({
      label: 'سعر المنتج',
      productPriceSyp: activeProduct?.priceSyp ?? 0,
      quantity,
      fees: shippingFees,
    })
  }, [activeProduct?.priceSyp, cartItems, quantity])

  const total = useMemo(() => sumPriceLines(breakdown), [breakdown])
  const meetsMinimumOrder = total >= MIN_ORDER_SYP || total / exchangeRate >= MIN_ORDER_USD
  const formatPrice = (syp: number) => formatPriceSyp(syp, paymentCurrency, exchangeRate)

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
        .then(() => {
          setSessionToken(phone)
          setPendingWhatsappAuth(null)
          setInboundWhatsappUrl('')
          setInboundSupportPhone('')
          setInboundVerificationMessage('')
          if (!userProfile) {
            setScreen('onboarding')
          } else {
            setScreen('home')
          }
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
      .then(() => {
        setSessionToken(phone)
        setPendingWhatsappAuth(null)
        if (!userProfile) {
          setScreen('onboarding')
        } else {
          setScreen('home')
        }
        showNotice('تم تأكيد رقم واتساب')
      })
      .catch((error: unknown) => showNotice(getPublicErrorMessage(error)))
      .finally(() => setAuthState('idle'))
  }

  const updateOtpDigit = (index: number, value: string) => {
    const digit = value.replace(/\D/g, '').slice(-1)
    setOtpDigits((current) => current.map((item, itemIndex) => (itemIndex === index ? digit : item)))
    if (digit && index < otpDigits.length - 1) {
      otpRefs.current[index + 1]?.focus()
    }
  }

  const handleOtpKeyDown = (index: number, event: React.KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Backspace' && !otpDigits[index] && index > 0) {
      otpRefs.current[index - 1]?.focus()
    }
  }

  const pasteOtpDigits = (value: string) => {
    const digits = value.replace(/\D/g, '').slice(0, otpDigits.length).split('')
    setOtpDigits((current) => current.map((item, index) => digits[index] ?? item))
    const lastFilled = Math.min(digits.length, otpDigits.length) - 1
    if (lastFilled >= 0) {
      otpRefs.current[lastFilled]?.focus()
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
      color: selectedColor?.name ?? manualColorName.trim(),
      size: selectedSize,
      quantity,
      priceSyp: activeProduct.priceSyp,
      sourceLink: link || activeProduct.link,
    }])
    showNotice('تمت إضافة المنتج إلى السلة')
    setScreen('cart')
  }

  const browseShein = () => {
    const dpr = window.devicePixelRatio || 1
    const navEl = document.querySelector('.bottom-nav')
    const navHeightCss = navEl ? navEl.getBoundingClientRect().height : 0
    const widthPx = Math.round(window.innerWidth * dpr)
    const heightPx = Math.round((window.innerHeight - navHeightCss) * dpr)
    void InAppBrowser.openWebView({
      url: 'https://m.shein.com/jo/?ref=jo&rep=dir&ret=mjo&currency=USD',
      toolbarType: ToolBarType.BLANK,
      width: widthPx,
      height: heightPx,
      x: 0,
      y: 0,
      preShowScript: SHEIN_CAPTURE_SCRIPT,
      preShowScriptInjectionTime: 'documentStart',
      isPresentAfterPageLoad: true,
    })
  }

  useEffect(() => {
    if (screen === 'home') {
      browseShein()
      return () => { void InAppBrowser.close() }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [screen])

  useEffect(() => {
    const handle = InAppBrowser.addListener('messageFromWebview', (event: { detail?: Record<string, unknown> }) => {
      const detail = event?.detail
      const product = detail?.type === 'addToCart' ? (detail.product as Record<string, unknown> | undefined) : undefined
      const title = typeof product?.title === 'string' ? product.title : ''
      if (!title) return

      const priceUsd = typeof product?.priceUsd === 'number' ? product.priceUsd : 0
      setCartItems((items) => [...items, {
        id: `shein-${Date.now()}`,
        title,
        image: typeof product?.image === 'string' ? product.image : '',
        color: typeof product?.color === 'string' ? product.color : '',
        size: typeof product?.size === 'string' ? product.size : '',
        quantity: 1,
        priceSyp: Math.round(priceUsd * exchangeRate),
        sourceLink: typeof product?.link === 'string' ? product.link : '',
      }])
      void InAppBrowser.postMessage({ detail: { type: 'addToCartAck' } })
      showNotice('تمت إضافة المنتج إلى السلة')
    })
    return () => { void handle.then((h) => h.remove()) }
  }, [exchangeRate])

  const createPaidOrder = () => {
    if (cartItems.length === 0) {
      showNotice('السلة فارغة')
      return
    }

    const orderId = makeOrderId(orders)
    const newOrder: Order = {
      id: orderId,
      customer: recipient.name || userProfile?.name || 'عميل otlobli',
      phone: recipient.phone || phone,
      city: recipient.city || recipient.governorate || 'غير محدد',
      address: recipient.details || 'عنوان غير مكتمل',
      items: cartItems,
      total,
      paymentStatus: 'مدفوع',
      statusIndex: 1,
      qadmousNumber: '',
      createdAt: today(),
      paidAt: today(),
    }

    setOrders((list) => [newOrder, ...list])
    setCurrentOrderId(orderId)
    setCartItems([])
    setVerificationState('matched')
    setScreen('success')
    void appApi.orders.createOrder(newOrder).then((result) => {
      if (result.persisted) {
        showNotice('تم حفظ الطلب في قاعدة البيانات')
      }
    })
  }

  const verifyB2BPayment = () => {
    setVerificationState('checking')
    void appApi.payments.verifyB2BShamCashPayment(total).then((result) => {
      if (result.status === 'matched') {
        showNotice('تم العثور على تحويل مطابق للمبلغ الدقيق')
        createPaidOrder()
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
      return (
        <AuthShell
          title={inboundWhatsappUrl ? 'تأكيد واتساب' : 'تأكيد الرقم'}
          subtitle={inboundWhatsappUrl ? 'افتح واتساب وأرسل الرسالة الجاهزة فقط' : 'أدخل الرمز المرسل إلى واتساب'}
        >
          {inboundWhatsappUrl ? (
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
          {!inboundWhatsappUrl && (
            <button className="primary-action" disabled={authState === 'verifying'} onClick={verifyOtp}>
              {authState === 'verifying' ? 'جاري الفحص...' : 'تأكيد'}
              <Icon name="verified" />
            </button>
          )}
          {!inboundWhatsappUrl && <p className="hint">إعادة الإرسال بعد {otpExpiresInSeconds} ثانية</p>}
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
              {SYRIA_GOVERNORATES.map((gov) => (
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
          <Header title="جلب المنتج" />
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
                  <strong>{formatMoney(activeProduct.priceSyp)}</strong>
                  <span>${activeProduct.priceUsd.toFixed(2)}</span>
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
          <Header title="السلة" />
          <main className="mobile-content">
            {cartItems.length > 0 ? (
              <>
                {cartItems.map((item) => (
                  <article className="cart-item" key={item.id}>
                    <img
                      src={item.image}
                      alt={item.title}
                      onError={(e) => { (e.target as HTMLImageElement).src = 'https://placehold.co/80x100/f5f5f5/aaa?text=صورة' }}
                    />
                    <div className="cart-item-body">
                      <div className="cart-item-top">
                        <h3>{item.title}</h3>
                        <button
                          className="delete-cart"
                          onClick={() => setCartItems((items) => items.filter((i) => i.id !== item.id))}
                          aria-label="حذف"
                        >
                          <Icon name="delete" />
                        </button>
                      </div>
                      <p>{item.color} · {item.size}</p>
                      <div className="cart-item-bottom">
                        <strong>{formatPrice(item.priceSyp * item.quantity)}</strong>
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
              </>
            ) : (
              <EmptyState title="السلة فارغة" body="تصفح SHEIN من الصفحة الرئيسية وأضف منتجات إلى السلة." />
            )}
            <button className="primary-action" disabled={cartItems.length === 0 || !meetsMinimumOrder} onClick={() => setScreen('checkout')}>
              المتابعة للدفع
              <Icon name="arrow_back" />
            </button>
          </main>
        </MobileShell>
      )
    }

    if (screen === 'checkout') {
      return (
        <MobileShell active="cart" onNavigate={setScreen} hideBottomNav>
          <Header title="بيانات الاستلام" back={() => setScreen('cart')} />
          <main className="mobile-content">
            <div className="form-card">
              {[
                ['name', 'اسم المستلم'],
                ['phone', 'رقم واتساب المستلم'],
                ['governorate', 'المحافظة'],
                ['city', 'المدينة'],
                ['details', 'العنوان التفصيلي'],
              ].map(([key, label]) => (
                <label className="field" key={key}>
                  <span>{label}</span>
                  <input
                    value={recipient[key as keyof Recipient]}
                    onChange={(event) => setRecipient({ ...recipient, [key]: event.target.value })}
                    placeholder={label}
                  />
                </label>
              ))}
              <label className="field">
                <span>ملاحظات التوصيل</span>
                <textarea
                  value={recipient.notes}
                  onChange={(event) => setRecipient({ ...recipient, notes: event.target.value })}
                  placeholder="مثال: الاتصال قبل الوصول"
                />
              </label>
            </div>
            <InfoRow icon="inventory_2" title="طريقة التوصيل" body="التسليم داخل سوريا عبر القدموس عند توفر رقم الشحنة." />
            <CurrencyToggle value={paymentCurrency} onChange={setPaymentCurrency} />
            <PriceBreakdown items={breakdown} total={total} format={formatPrice} />
            <button className="primary-action" onClick={() => setScreen('payment')}>
              الدفع الآن عبر شام كاش
              <Icon name="account_balance_wallet" />
            </button>
          </main>
        </MobileShell>
      )
    }

    if (screen === 'payment') {
      return (
        <MobileShell active="cart" onNavigate={setScreen} hideBottomNav>
          <Header title="دفع شام كاش" back={() => setScreen('checkout')} />
          <main className="mobile-content">
            <CurrencyToggle value={paymentCurrency} onChange={setPaymentCurrency} />
            <section className="payment-card">
              <div className="qr-code"><Icon name="qr_code_2" /></div>
              <p>ادفع إلى حسابنا التجاري</p>
              <b>{paymentSettings.receiverName}</b>
              <span>{paymentSettings.receiverAccount}</span>
              <strong>{formatPrice(total)}</strong>
            </section>
            <div className="instruction-list">
              <p>الدفع من أي حساب شام كاش مقبول، بالليرة السورية أو بالدولار الأمريكي.</p>
              <p>لا تحتاج كتابة رقم الطلب في الملاحظة.</p>
              <p>المهم جداً: ادفع نفس المبلغ بالضبط بالعملة المختارة أعلاه حتى تتم المطابقة تلقائياً.</p>
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
            <h1>تم تأكيد الدفع</h1>
            <p>تمت مطابقة تحويل شام كاش بالمبلغ الدقيق. سنبدأ بشراء الطلب من SHEIN.</p>
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
          <Header title="طلباتي" />
          <main className="mobile-content">
            {orders.length === 0 && (
              <EmptyState title="لا توجد طلبات بعد" body="اطلب منتجاً من الصفحة الرئيسية وسيظهر هنا بعد إتمام الدفع." />
            )}
            {orders.map((item) => (
              <article className="order-card" key={item.id} onClick={() => {
                setCurrentOrderId(item.id)
                setScreen('tracking')
              }}>
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
            <Header title="تتبع الطلب" back={() => setScreen('orders')} />
            <main className="mobile-content">
              <EmptyState title="لا يوجد طلب" body="اختر طلباً من قائمة طلباتك لتتبعه." />
            </main>
          </MobileShell>
        )
      }
      return (
        <MobileShell active="orders" onNavigate={setScreen}>
          <Header title="تتبع الطلب" back={() => setScreen('orders')} />
          <main className="mobile-content">
            <section className="tracking-head">
              <span>{order.id}</span>
              <StatusBadge tone={order.paymentStatus === 'مدفوع' ? 'success' : 'pending'}>{order.paymentStatus}</StatusBadge>
              <StatusBadge tone="pending">{orderStatuses[order.statusIndex]}</StatusBadge>
              <p>{order.qadmousNumber ? `رقم القدموس: ${order.qadmousNumber}` : 'رقم القدموس سيظهر بعد تسليم الشحنة.'}</p>
            </section>
            <Timeline statusIndex={order.statusIndex} />
            <button
              className="ghost-action"
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
            <Header title="تعديل الملف الشخصي" back={() => setEditingProfile(false)} />
            <main className="mobile-content">
              <div className="form-card">
                <label className="field">
                  <span>الاسم الكامل</span>
                  <input value={editName} onChange={(e) => setEditName(e.target.value)} placeholder="الاسم" />
                </label>
                <label className="field">
                  <span>المحافظة</span>
                  <select value={editGov} onChange={(e) => setEditGov(e.target.value)}>
                    {SYRIA_GOVERNORATES.map((gov) => (
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
          <Header title="حسابي" />
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
            <ProfileRow icon="gpp_maybe" label="سياسة المنتجات الممنوعة" onClick={() => setScreen('blocked-policy')} />
            <ProfileRow icon="contract" label="الشروط والأحكام" onClick={() => setScreen('terms')} />
            <ProfileRow icon="support_agent" label="الدعم" onClick={() => setScreen('support')} />
            <button className="profile-row profile-row--danger" onClick={logout}>
              <span><Icon name="logout" /> تسجيل الخروج</span>
              <Icon name="chevron_left" />
            </button>
          </main>
        </MobileShell>
      )
    }

    if (screen === 'addresses') {
      return (
        <MobileShell active="profile" onNavigate={setScreen} hideBottomNav>
          <Header title="العناوين" back={() => setScreen('profile')} />
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
          <Header title="طرق الدفع" back={() => setScreen('profile')} />
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
          <Header title="سياسة المنتجات" back={() => setScreen('profile')} />
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
          <Header title="الشروط والأحكام" back={() => setScreen('profile')} />
          <AccountDetailLayout>
            <LegalSection title="التسعير">
              السعر النهائي يشمل سعر المنتج والشحن والرسوم التشغيلية المتوقعة. يبقى السعر صالحاً خلال جلسة الدفع فقط.
            </LegalSection>
            <LegalSection title="الدفع">
              يجب دفع نفس المبلغ بالضبط إلى حسابنا التجاري. المطابقة لا تعتمد على رقم الطلب أو حساب المرسل.
            </LegalSection>
            <LegalSection title="الشحن">
              مدة الشحن تقديرية وتعتمد على وصول الطلب إلى الأردن ثم نقله إلى سوريا وتسليمه للقدموس.
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
          <Header title="الدعم" back={() => setScreen('profile')} />
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

    return (
      <MobileShell active="home" onNavigate={setScreen}>
        <Header title="otlobli" />
        <HomeScreen browseShein={browseShein} userName={userProfile?.name} />
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

function AuthShell({ title, subtitle, children }: { title: string; subtitle: string; children: ReactNode }) {
  return (
    <div className="auth-shell">
      <div className="auth-card">
        <div className="brand-lockup">
          <span>otlobli</span>
          <small>اطلب من الأردن واستلم في سوريا</small>
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
}: {
  title: string
  back?: () => void
  actions?: string[]
  onAction?: (action: string) => void
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
        {!actions.length && <button className="icon-button"><Icon name="notifications" /></button>}
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

function HomeScreen({
  browseShein,
  userName,
}: {
  browseShein: () => void
  userName?: string
}) {
  return (
    <main className="mobile-content shein-home">
      <section className="greeting">
        <h1>{userName ? `أهلاً، ${userName}` : 'أهلاً بك'}</h1>
        <p>ابدأ تسوق منتجات SHEIN بكل سهولة</p>
      </section>
      <button className="primary-action" onClick={browseShein}>
        تصفح SHEIN
        <Icon name="storefront" />
      </button>
    </main>
  )
}

function MobileShell({
  active,
  children,
  onNavigate,
  hideBottomNav = false,
}: {
  active: 'home' | 'orders' | 'cart' | 'profile'
  children: ReactNode
  onNavigate: (screen: Screen) => void
  hideBottomNav?: boolean
}) {
  return (
    <div className="mobile-shell">
      {children}
      {!hideBottomNav && (
        <nav className="bottom-nav">
          <NavButton active={active === 'home'} icon="home" label="الرئيسية" onClick={() => onNavigate('home')} />
          <NavButton active={active === 'orders'} icon="package_2" label="طلباتي" onClick={() => onNavigate('orders')} />
          <NavButton active={active === 'cart'} icon="shopping_cart" label="السلة" onClick={() => onNavigate('cart')} />
          <NavButton active={active === 'profile'} icon="person" label="حسابي" onClick={() => onNavigate('profile')} />
        </nav>
      )}
    </div>
  )
}

function NavButton({ active, icon, label, onClick }: { active: boolean; icon: string; label: string; onClick: () => void }) {
  return (
    <button className={active ? 'is-active' : ''} onClick={onClick}>
      <Icon name={icon} />
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

function Timeline({ statusIndex }: { statusIndex: number }) {
  return (
    <section className="timeline">
      {orderStatuses.map((status, index) => (
        <div className={index < statusIndex ? 'is-done' : index === statusIndex ? 'is-active' : ''} key={status}>
          <span>{index <= statusIndex ? <Icon name="check" /> : <Icon name="schedule" />}</span>
          <section>
            <h3>{status}</h3>
            <p>{index < statusIndex ? 'تم تحديث هذه المرحلة بنجاح.' : index === statusIndex ? 'هذه المرحلة قيد التنفيذ الآن.' : 'بانتظار الوصول لهذه المرحلة.'}</p>
            <small>{index <= statusIndex ? today() : 'لاحقاً'}</small>
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
