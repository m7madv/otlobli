/**
 * API Routes للتحقق عبر OTP واتساب
 */

import { Router } from 'express'
import crypto from 'node:crypto'
import { createOtp, verifyOtp, releaseOtpVerification } from './otpStore.js'
import { sendOtpMessage, sendNotificationMessage, getConnectionStatusForAdmin, getAllSessionsForAdmin, getSessionForAdmin, createSession, removeSession, connectSession } from './whatsapp.js'
import { supabase } from './supabase.js'
import { sendTelegramNotification, isTelegramConfigured } from './telegram.js'
import { requireWhatsappAdminSecret } from './adminAuth.js'

const router = Router()
const CUSTOMER_SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000
const OTP_START_IP_WINDOW_MS = 15 * 60 * 1000
const OTP_START_IP_MAX = 10
const otpStartRequestsByIp = new Map()

function asyncRoute(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next)
}

function consumeOtpStartIpBudget(req) {
  const now = Date.now()
  const requester = String(req.ip || req.socket?.remoteAddress || 'unknown').slice(0, 128)
  const active = (otpStartRequestsByIp.get(requester) || [])
    .filter((timestamp) => timestamp >= now - OTP_START_IP_WINDOW_MS)
  if (active.length >= OTP_START_IP_MAX) {
    return Math.max(1, Math.ceil((active[0] + OTP_START_IP_WINDOW_MS - now) / 1000))
  }
  active.push(now)
  otpStartRequestsByIp.set(requester, active)
  if (otpStartRequestsByIp.size > 10000) {
    for (const [key, timestamps] of otpStartRequestsByIp) {
      if (!timestamps.some((timestamp) => timestamp >= now - OTP_START_IP_WINDOW_MS)) {
        otpStartRequestsByIp.delete(key)
      }
    }
  }
  return 0
}

function otpStartErrorResponse(error, res) {
  const errorCode = String(error?.code || '')
  const retryAfterSeconds = Math.max(1, Number(error?.retryAfterSeconds || 60))
  const messages = {
    otp_resend_too_soon: 'انتظر قليلاً قبل طلب رمز جديد.',
    otp_send_rate_limited: 'تم طلب رموز كثيرة لهذا الرقم. حاول لاحقاً.',
    otp_attempts_locked: 'تم إيقاف المحاولات مؤقتاً. حاول لاحقاً.',
  }
  if (errorCode === 'otp_not_configured') {
    return res.status(503).json({ error: errorCode, message: 'خدمة رمز التحقق غير مهيأة.' })
  }
  if (messages[errorCode]) {
    res.setHeader('Retry-After', String(retryAfterSeconds))
    return res.status(429).json({ error: errorCode, message: messages[errorCode], retryAfterSeconds })
  }
  return null
}

async function createCustomerSession(phone) {
  if (!supabase) {
    throw new Error('Supabase is not configured for customer sessions')
  }

  const sessionToken = crypto.randomBytes(32).toString('base64url')
  const tokenHash = crypto.createHash('sha256').update(sessionToken).digest('hex')
  const expiresAt = new Date(Date.now() + CUSTOMER_SESSION_TTL_MS).toISOString()
  const { error } = await supabase.rpc('create_customer_session', {
    p_phone: phone,
    p_token_hash: tokenHash,
    p_expires_at: expiresAt,
  })

  if (error) {
    throw new Error(`Failed to persist customer session: ${error.message}`)
  }

  return sessionToken
}

function hasValidServiceSecret(req) {
  const expected = process.env.ORDER_NOTIFY_SECRET || ''
  const supplied = String(req.headers['x-service-secret'] || '')
  if (!expected || !supplied) return false
  const expectedBytes = Buffer.from(expected)
  const suppliedBytes = Buffer.from(supplied)
  return expectedBytes.length === suppliedBytes.length
    && crypto.timingSafeEqual(expectedBytes, suppliedBytes)
}

async function hasValidCustomerSession(req, phone) {
  if (!supabase) return false
  const authorization = String(req.headers.authorization || '')
  const token = authorization.startsWith('Bearer ') ? authorization.slice(7).trim() : ''
  if (!token) return false
  const { error } = await supabase.rpc('require_customer_session', {
    p_session_token: token,
    p_phone: phone,
  })
  return !error
}

const NEW_LIRA_RATE_CEILING = 1000

function normalizeNewLiraRate(value) {
  const rate = Math.round(Number(value) * 100) / 100
  return Number.isFinite(rate) && rate > 0 && rate < NEW_LIRA_RATE_CEILING ? rate : 0
}

async function persistExchangeRate(rate) {
  if (!supabase) throw new Error('Supabase is not configured for exchange-rate sync')
  const normalizedRate = normalizeNewLiraRate(rate)
  if (!normalizedRate) {
    throw new Error('Exchange rate is outside the accepted range')
  }
  const { error } = await supabase
    .from('app_settings')
    .upsert({ key: 'usd_to_syp_rate', value: String(normalizedRate) }, { onConflict: 'key' })
  if (error) throw new Error(`Failed to persist exchange rate: ${error.message}`)
  return normalizedRate
}

async function readPersistedExchangeRate() {
  if (!supabase) return 0
  const { data, error } = await supabase
    .from('app_settings')
    .select('value')
    .eq('key', 'usd_to_syp_rate')
    .maybeSingle()
  if (error) throw new Error(`Failed to read persisted exchange rate: ${error.message}`)
  return normalizeNewLiraRate(data?.value)
}

function getConfiguredExchangeRateFallback() {
  return normalizeNewLiraRate(process.env.VITE_USD_TO_SYP_RATE ?? 131.7) || 131.7
}

// الحصول على حالة اتصال واتساب

// استيراد الأرشيف القديم معطّل: كان يشغّل tar على بيانات مرفوعة. إعادة الربط
// الآمنة تتم بإنشاء جلسة جديدة ثم مسح QR المحلي من مسار الجلسات المحمي.
router.post('/session/upload', requireWhatsappAdminSecret, (req, res) => {
  res.status(410).json({ error: 'legacy_session_upload_disabled' })
})

// reset العام القديم معطّل حتى لا يمسح كل المرسلين دفعة واحدة. احذف جلسة
// محددة من /whatsapp/sessions/:id ثم أنشئ بديلاً.
router.post('/session/reset', requireWhatsappAdminSecret, (req, res) => {
  res.status(410).json({ error: 'global_session_reset_disabled' })
})

router.get('/auth/whatsapp/status', requireWhatsappAdminSecret, asyncRoute(async (req, res) => {
  res.json(await getConnectionStatusForAdmin())
}))

// ── إدارة جلسات واتساب (متعددة) ──────────────────────────

router.get('/whatsapp/sessions', requireWhatsappAdminSecret, asyncRoute(async (req, res) => {
  res.json({ sessions: await getAllSessionsForAdmin() })
}))

router.get('/whatsapp/sessions/:id', requireWhatsappAdminSecret, asyncRoute(async (req, res) => {
  const session = await getSessionForAdmin(req.params.id)
  if (!session) return res.status(404).json({ error: 'not_found' })
  res.json(session)
}))

router.post('/whatsapp/sessions', requireWhatsappAdminSecret, (req, res) => {
  const { label } = req.body || {}
  const result = createSession(label)
  res.json(result)
})

router.delete('/whatsapp/sessions/:id', requireWhatsappAdminSecret, (req, res) => {
  const removed = removeSession(req.params.id)
  if (!removed) return res.status(404).json({ error: 'not_found' })
  res.json({ ok: true })
})

router.post('/whatsapp/sessions/:id/reconnect', requireWhatsappAdminSecret, (req, res) => {
  connectSession(req.params.id)
    .then(async () => res.json({ ok: true, session: await getSessionForAdmin(req.params.id) }))
    .catch((err) => res.status(500).json({ error: err.message }))
})

// لا توجد صفحة QR عامة. الربط يتم فقط عبر مسارات الجلسة المحمية، والصورة
// تُولد محلياً داخل الخادم ولا تُرسل مادتها إلى خدمة QR خارجية.
router.get('/qr', requireWhatsappAdminSecret, (req, res) => {
  res.status(410).json({ error: 'browser_qr_endpoint_disabled' })
})

// بدء تسجيل الدخول - إرسال OTP
router.post('/auth/whatsapp/start', async (req, res) => {
  try {
    const { phone } = req.body

    if (!phone) {
      return res.status(400).json({ error: 'invalid_phone', message: 'أدخل رقم واتساب صحيح مع رمز الدولة.' })
    }

    // تنظيف الرقم
    const cleanPhone = phone.replace(/[\s\-\(\)\+]/g, '')

    if (cleanPhone.length < 10) {
      return res.status(400).json({ error: 'invalid_phone', message: 'رقم الهاتف قصير جدًا.' })
    }

    const ipRetryAfter = consumeOtpStartIpBudget(req)
    if (ipRetryAfter > 0) {
      res.setHeader('Retry-After', String(ipRetryAfter))
      return res.status(429).json({
        error: 'otp_ip_rate_limited',
        message: 'تم طلب رموز كثيرة من هذا الجهاز. حاول لاحقاً.',
        retryAfterSeconds: ipRetryAfter,
      })
    }

    // إنشاء OTP
    const { code, expiresInSeconds } = createOtp(cleanPhone)

    // إرسال OTP عبر واتساب
    await sendOtpMessage(cleanPhone, code)

    res.json({
      mode: 'external',
      otpExpiresInSeconds: expiresInSeconds,
    })
  } catch (error) {
    const otpErrorResponse = otpStartErrorResponse(error, res)
    if (otpErrorResponse) return otpErrorResponse
    console.error('❌ Failed to send OTP:', error.message)

    if (error.message.includes('WhatsApp غير متصل') || error.message.includes('لا توجد جلسة')) {
      return res.status(503).json({
        error: 'whatsapp_not_configured',
        message: 'واتساب server غير مربوط بعد. امسح QR لربط الرقم.',
      })
    }

    if (error.message.includes('recipient_not_on_whatsapp')) {
      return res.status(400).json({
        error: 'recipient_not_on_whatsapp',
        message: 'هذا الرقم غير مسجّل على واتساب. تأكد من الرقم أو استخدم تيليغرام.',
      })
    }

    res.status(500).json({
      error: 'whatsapp_send_error',
      message: 'تعذر إرسال رسالة واتساب.',
    })
  }
})

// التحقق من OTP
router.post('/auth/whatsapp/verify', async (req, res) => {
  try {
    const { phone, code } = req.body

    if (!phone || !code) {
      return res.status(400).json({
        error: 'invalid_request',
        message: 'الرجاء إرسال رقم الهاتف ورمز التحقق.',
      })
    }

    const cleanPhone = phone.replace(/[\s\-\(\)\+]/g, '')
    if (!/^\d{6}$/.test(String(code))) {
      return res.status(400).json({ error: 'invalid_code', message: 'رمز التحقق غير صحيح.' })
    }
    const result = verifyOtp(cleanPhone, code)

    if (!result.valid) {
      const messages = {
        no_otp: 'لم يتم إرسال رمز لهذا الرقم بعد.',
        expired: 'انتهت صلاحية الرمز. أرسل رمزاً جديداً.',
        too_many_attempts: 'تم تجاوز عدد المحاولات. أرسل رمزاً جديداً.',
        invalid_code: 'رمز التحقق غير صحيح.',
        already_verified: 'هذا الرمز تم التحقق منه مسبقاً.',
      }

      const status = result.reason === 'otp_not_configured' ? 503 : 400
      return res.status(status).json({
        error: result.reason,
        message: messages[result.reason] || 'رمز غير صحيح.',
      })
    }

    let sessionToken
    try {
      sessionToken = await createCustomerSession(cleanPhone)
    } catch (error) {
      releaseOtpVerification(cleanPhone, String(code))
      throw error
    }

    res.json({
      mode: 'external',
      sessionToken,
    })
  } catch (error) {
    console.error('❌ Verify error:', error.message)

    res.status(500).json({
      error: 'verification_error',
      message: 'حدث خطأ أثناء التحقق.',
    })
  }
})

// Inbound mode - للتأكد من إرسال رسالة (optional)
router.post('/auth/whatsapp/inbound/start', (_req, res) => {
  res.status(410).json({ error: 'inbound_auth_unavailable', message: 'استخدم إرسال رمز واتساب.' })
})

router.post('/auth/whatsapp/inbound/status', (_req, res) => {
  res.status(410).json({ error: 'inbound_auth_unavailable', message: 'استخدم إرسال رمز واتساب.' })
})

// ============================================================
// 🛍️ Shein Product Scraper
// ============================================================

// جلب بيانات منتج Shein - v2
router.post('/catalog/fetch-shein-product', async (req, res) => {
  try {
    const { url } = req.body

    if (!url) {
      return res.status(400).json({ error: 'missing_url', message: 'رابط المنتج مطلوب.' })
    }

    if (!url.includes('shein.com')) {
      return res.status(400).json({ error: 'invalid_url', message: 'الرابط يجب أن يكون من Shein.' })
    }

    console.log(`📦 Fetching Shein product: ${url}`)

    // استيراد ديناميكي عشان ما يعلق السيرفر
    const { fetchSheinProduct } = await import('./sheinScraper.js')
    const productData = await fetchSheinProduct(url)

    if (!productData || (!productData.title && !productData.goodsId)) {
      return res.status(500).json({ error: 'scrape_failed', message: 'تعذر جلب بيانات المنتج.' })
    }

    console.log(`✅ Product fetched: ${productData.title || productData.goodsId}`)

    res.json({
      success: true,
      product: productData,
    })
  } catch (error) {
    console.error('❌ Shein fetch error:', error.message)
    res.status(500).json({
      error: 'fetch_error',
      message: 'حدث خطأ أثناء جلب بيانات المنتج: ' + error.message,
    })
  }
})

// ============================================================
// 💱 Exchange Rate (USD → SYP) from sp-today.com
// ============================================================

let _rateCache = { rate: 0, buy: 0, sell: 0, updatedAt: 0, source: 'none' }
let _rateRefreshPromise = null
const RATE_TTL = 30 * 60 * 1000 // 30 minutes

async function fetchLiveRate() {
  const res = await fetch('https://sp-today.com/en', {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    },
    signal: AbortSignal.timeout(12000),
  })

  if (!res.ok) throw new Error(`sp-today returned ${res.status}`)
  const html = await res.text()

  // أول ظهور لكلمة "USD" بالصفحة هو بوسم meta SEO (keywords) قبل بطاقة السعر
  // الفعلية بكثير، فلازم نرتكز على رابط بطاقة الدولار نفسها لا أول ظهور للكلمة
  const anchorIndex = html.indexOf('/currency/us-dollar')
  const usdBlock = anchorIndex === -1 ? '' : html.slice(anchorIndex, anchorIndex + 3000)
  const text = usdBlock.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ')
  const readPair = (label) => {
    const asNew = new RegExp(`${label}\\s+(\\d{1,4}(?:\\.\\d{1,2})?)\\b(?!\\s*,)`, 'i').exec(text)
    if (asNew) return Number(asNew[1])
    const asOld = new RegExp(`${label}\\s+(\\d{1,3}(?:,\\d{3})+)`, 'i').exec(text)
    if (asOld) return Number(asOld[1].replace(/,/g, '')) / 100
    return 0
  }

  const buy = readPair('Buy')
  const sell = readPair('Sell')
  if (sell) return { buy: buy || sell, sell, rate: sell }
  if (buy) return { buy, sell: buy, rate: buy }

  // Layout fallback: comma is mandatory to avoid SVG colour codes, and these
  // values are old SYP so they are converted exactly once.
  const nums = [...text.matchAll(/\d{1,3},\d{3}/g)]
    .map(m => parseInt(m[0].replace(/,/g, ''), 10))
    .filter(n => n >= 10000 && n <= 100000)
    .map(n => n / 100)

  if (nums.length >= 2) {
    return { buy: nums[0], sell: nums[1], rate: nums[1] }
  }
  if (nums.length === 1) {
    return { buy: nums[0], sell: nums[0], rate: nums[0] }
  }
  throw new Error('Could not parse USD rate from sp-today.com')
}

async function refreshExchangeRate() {
  if (_rateRefreshPromise) return _rateRefreshPromise

  const refreshPromise = (async () => {
    const { buy, sell, rate: liveRate } = await fetchLiveRate()
    // Persist first. The app must never display a fresh market rate while SQL
    // still settles orders and wallet reservations with an older value.
    const rate = await persistExchangeRate(liveRate)
    const updatedAt = Date.now()
    _rateCache = { rate, buy, sell, updatedAt, source: 'sp-today.com' }
    console.log(`💱 Exchange rate updated and persisted: ${buy}/${sell} SYP/USD`)
    return { ..._rateCache, cached: false }
  })()

  _rateRefreshPromise = refreshPromise
  try {
    return await refreshPromise
  } finally {
    if (_rateRefreshPromise === refreshPromise) _rateRefreshPromise = null
  }
}

async function resolvePersistedFallbackRate() {
  const persistedRate = await readPersistedExchangeRate()
  if (persistedRate) {
    _rateCache = {
      rate: persistedRate,
      buy: persistedRate,
      sell: persistedRate,
      updatedAt: Date.now(),
      source: 'supabase',
    }
    return { ..._rateCache, cached: false }
  }

  // If the row is unexpectedly absent, persist the only candidate before
  // exposing it. Returning an unpersisted value would recreate the checkout
  // mismatch this endpoint is intended to prevent.
  const hadCachedRate = Boolean(_rateCache.rate)
  const candidate = _rateCache.rate || getConfiguredExchangeRateFallback()
  const rate = await persistExchangeRate(candidate)
  _rateCache = {
    rate,
    buy: rate,
    sell: rate,
    updatedAt: Date.now(),
    source: hadCachedRate ? 'cache' : 'fallback',
  }
  return { ..._rateCache, cached: hadCachedRate }
}

router.get('/exchange-rate', async (req, res) => {
  res.set('Cache-Control', 'no-store')
  try {
    const now = Date.now()
    if (_rateCache.rate && now - _rateCache.updatedAt < RATE_TTL) {
      // app_settings is the SQL source of truth. Revalidate every cached reply
      // so an admin update or another replica can never be hidden for 30 min.
      const persistedRate = await readPersistedExchangeRate()
      if (persistedRate === _rateCache.rate) {
        return res.json({ ..._rateCache, cached: true })
      }
      if (persistedRate) {
        _rateCache = {
          rate: persistedRate,
          buy: persistedRate,
          sell: persistedRate,
          updatedAt: now,
          source: 'supabase',
        }
        return res.json({ ..._rateCache, cached: false })
      }
    }

    return res.json(await refreshExchangeRate())
  } catch (err) {
    console.error('💱 Rate fetch failed:', err.message)
    try {
      return res.json(await resolvePersistedFallbackRate())
    } catch (fallbackError) {
      console.error('💱 Safe persisted fallback failed:', fallbackError.message)
      return res.status(503).json({ error: 'exchange_rate_unavailable' })
    }
  }
})

// ============================================================
// 📲 إشعار واتساب للمستخدم — يُستدعى من التطبيق عند إنشاء إشعار تطبيق
// (تحديث حالة طلب، تأكيد دفع...) ليصل للمستخدم على نفس رقم الواتساب
// المسجَّل دخوله فيه
// ============================================================

router.post('/notify/whatsapp', async (req, res) => {
  try {
    const { phone, text } = req.body
    if (!phone || !text) {
      return res.status(400).json({ error: 'missing_fields' })
    }
    if (!hasValidServiceSecret(req) && !(await hasValidCustomerSession(req, phone))) {
      return res.status(401).json({ error: 'unauthorized' })
    }
    await sendNotificationMessage(phone, text)
    res.json({ ok: true })
  } catch (err) {
    console.error('WhatsApp notify error:', err.message)
    res.status(500).json({ error: 'notify_failed', message: err.message })
  }
})

// ============================================================
// 📬 إشعار الطلب (تليقرام) — يُستدعى من التطبيق بعد تأكيد الدفع
// ============================================================

router.post('/orders/notify', async (req, res) => {
  try {
    if (!hasValidServiceSecret(req)) {
      return res.status(401).json({ error: 'unauthorized' })
    }
    const { order } = req.body
    if (!order || !order.id) {
      return res.status(400).json({ error: 'missing_order' })
    }

    if (isTelegramConfigured()) {
      await sendTelegramNotification(order)
    }

    res.json({ ok: true })
  } catch (err) {
    console.error('Notify error:', err.message)
    res.status(500).json({ error: 'notify_failed' })
  }
})

// ============================================================
// 🔐 لوحة الإدارة — /api/admin/orders
// ============================================================

function adminAuth(req, res, next) {
  const pin = req.headers['x-admin-pin']
  const expected = process.env.ADMIN_PIN
  if (!expected) {
    return res.status(503).json({ error: 'admin_not_configured', message: 'ADMIN_PIN غير مضبوط على السيرفر.' })
  }
  if (!pin || pin !== expected) {
    return res.status(401).json({ error: 'unauthorized', message: 'رمز الإدارة غير صحيح.' })
  }
  next()
}

// GET /api/admin/orders — جلب كل الطلبات
router.get('/admin/orders', adminAuth, async (req, res) => {
  if (!supabase) {
    return res.status(503).json({ error: 'supabase_not_configured', message: 'Supabase غير مضبوط.' })
  }

  try {
    const { data, error } = await supabase
      .from('orders')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(500)

    if (error) throw error

    const orders = (data || []).map((row) => ({
      id: row.id,
      customer: row.customer,
      phone: row.phone,
      city: row.city,
      address: row.address,
      items: row.items || [],
      total: row.total,
      paymentStatus: row.payment_status,
      statusIndex: row.status_index ?? 0,
      qadmousNumber: row.qadmous_number || '',
      createdAt: row.created_at,
      paidAt: row.paid_at,
    }))

    res.json({ orders })
  } catch (err) {
    console.error('Admin fetch orders error:', err.message)
    res.status(500).json({ error: 'fetch_failed', message: err.message })
  }
})

// PATCH /api/admin/orders — تحديث طلب
router.patch('/admin/orders', adminAuth, async (req, res) => {
  if (!supabase) {
    return res.status(503).json({ error: 'supabase_not_configured' })
  }

  const { orderId, patch } = req.body
  if (!orderId || !patch) {
    return res.status(400).json({ error: 'missing_fields' })
  }

  try {
    const dbPatch = {}
    if (patch.paymentStatus !== undefined) dbPatch.payment_status = patch.paymentStatus
    if (patch.statusIndex !== undefined) dbPatch.status_index = patch.statusIndex
    if (patch.qadmousNumber !== undefined) dbPatch.qadmous_number = patch.qadmousNumber
    if (patch.paidAt !== undefined) dbPatch.paid_at = patch.paidAt
    dbPatch.updated_at = new Date().toISOString()

    const { error } = await supabase.from('orders').update(dbPatch).eq('id', orderId)
    if (error) throw error

    // إذا تأكد الدفع → أرسل إشعار تليقرام
    if (patch.paymentStatus === 'مدفوع' && isTelegramConfigured()) {
      const { data } = await supabase.from('orders').select('*').eq('id', orderId).single()
      if (data) {
        await sendTelegramNotification({
          id: data.id,
          customer: data.customer,
          phone: data.phone,
          city: data.city,
          address: data.address,
          items: data.items,
          total: data.total,
          paymentStatus: 'مدفوع',
          paidAt: patch.paidAt || new Date().toISOString(),
        })
      }
    }

    res.json({ ok: true })
  } catch (err) {
    console.error('Admin patch order error:', err.message)
    res.status(500).json({ error: 'update_failed', message: err.message })
  }
})

// GET /api/admin/status — حالة السيرفر
router.get('/admin/status', adminAuth, (req, res) => {
  res.json({
    supabase: !!supabase,
    telegram: isTelegramConfigured(),
  })
})

export default router
