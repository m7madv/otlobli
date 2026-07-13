/**
 * API Routes للتحقق عبر OTP واتساب
 */

import { Router } from 'express'
import crypto from 'node:crypto'
import fs from 'fs'
import path from 'path'
import zlib from 'zlib'
import { createRequire } from 'module'
import { fileURLToPath } from 'url'
import { createOtp, verifyOtp } from './otpStore.js'
import { sendOtpMessage, sendNotificationMessage, getConnectionStatus, connectOnDemand, getAllSessions, getSession, createSession, removeSession, connectSession } from './whatsapp.js'
import { supabase } from './supabase.js'
import { sendTelegramNotification, isTelegramConfigured } from './telegram.js'

const require = createRequire(import.meta.url)
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const router = Router()
const CUSTOMER_SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000

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

async function persistExchangeRate(rate) {
  if (!supabase) throw new Error('Supabase is not configured for exchange-rate sync')
  const normalizedRate = Math.round(Number(rate))
  if (!Number.isFinite(normalizedRate) || normalizedRate < 1000 || normalizedRate > 100000) {
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
  const rate = Math.round(Number(data?.value))
  return Number.isFinite(rate) && rate >= 1000 && rate <= 100000 ? rate : 0
}

function getConfiguredExchangeRateFallback() {
  const rate = Math.round(Number(process.env.VITE_USD_TO_SYP_RATE ?? 13000))
  return Number.isFinite(rate) && rate >= 1000 && rate <= 100000 ? rate : 13000
}

// الحصول على حالة اتصال واتساب

// رفع جلسة واتساب مضغوطة (tar.gz base64)
router.post('/api/session/upload', (req, res) => {
  const { tarBase64 } = req.body
  
  if (!tarBase64) {
    return res.status(400).json({ error: 'missing_data', message: 'tarBase64 required' })
  }
  
  try {
    const VOLUME_PATH = process.env.RAILWAY_VOLUME_MOUNT_PATH || process.env.RAILWAY_VOLUME_MOUNT || ''
    const authDir = VOLUME_PATH
      ? path.join(VOLUME_PATH, 'baileys-auth')
      : path.join(__dirname, '..', 'baileys-auth')
    
    const raw = Buffer.from(tarBase64, 'base64')
    const decompressed = zlib.gunzipSync(raw)
    const tempDir = path.join('/tmp', '_session_extract_' + Date.now())
    fs.mkdirSync(tempDir, { recursive: true })
    
    const tarPath = path.join('/tmp', '_session.tar.gz')
    fs.writeFileSync(tarPath, decompressed)
    require('child_process').execSync(`tar -xzf "${tarPath}" -C "${tempDir}"`, { stdio: 'pipe' })
    
    // Find extracted dir and move contents
    fs.mkdirSync(authDir, { recursive: true })
    const extractedItems = fs.readdirSync(tempDir)
    
    let srcDir = tempDir
    if (extractedItems.length === 1 && fs.statSync(path.join(tempDir, extractedItems[0])).isDirectory()) {
      srcDir = path.join(tempDir, extractedItems[0])
    }
    
    fs.readdirSync(srcDir).forEach(f => {
      const src = path.join(srcDir, f)
      const dst = path.join(authDir, f)
      if (fs.statSync(src).isFile()) {
        fs.copyFileSync(src, dst)
      }
    })
    
    // Cleanup
    fs.rmSync(tarPath, { force: true })
    fs.rmSync(tempDir, { recursive: true, force: true })
    
    const fileCount = fs.readdirSync(authDir).length
    console.log('📦 Session uploaded (' + fileCount + ' files) to ' + authDir)
    
    res.json({ success: true, files: fileCount })
  } catch (e) {
    console.error('❌ Session upload error:', e.message)
    res.status(500).json({ error: 'upload_failed', message: e.message })
  }
})

// تصفير جلسة واتساب العالقة (محمي بالـ ADMIN_PIN) — يمسح ملفات الجلسة
// التالفة فيولّد الاتصال التالي رمز QR جديداً للمسح من /api/qr.
// يحلّ الانسداد: جلسة تالفة تفشل بالاتصال بغير 401 فلا تُمسح تلقائياً أبداً.
router.post('/session/reset', (req, res) => {
  const pin = req.headers['x-admin-pin'] || (req.body && req.body.pin)
  if (!process.env.ADMIN_PIN || pin !== process.env.ADMIN_PIN) {
    return res.status(403).json({ error: 'forbidden', message: 'رمز الإدارة غير صحيح.' })
  }
  try {
    const VOLUME_PATH = process.env.RAILWAY_VOLUME_MOUNT_PATH || process.env.RAILWAY_VOLUME_MOUNT || ''
    const authDir = VOLUME_PATH
      ? path.join(VOLUME_PATH, 'baileys-auth')
      : path.join(__dirname, '..', 'baileys-auth')
    let removed = 0
    if (fs.existsSync(authDir)) {
      for (const f of fs.readdirSync(authDir)) {
        fs.rmSync(path.join(authDir, f), { recursive: true, force: true })
        removed++
      }
    }
    // نسخة الجلسة المضغوطة القديمة أيضاً حتى لا تُستعاد عند الإقلاع
    if (VOLUME_PATH) fs.rmSync(path.join(VOLUME_PATH, 'session.tar.gz'), { force: true })
    console.log('🗑️ Session reset via API (' + removed + ' files removed)')
    res.json({ success: true, removed })
  } catch (e) {
    console.error('❌ Session reset error:', e.message)
    res.status(500).json({ error: 'reset_failed', message: e.message })
  }
})

router.get('/auth/whatsapp/status', (req, res) => {
  const status = getConnectionStatus()
  res.json(status)
})

// ── إدارة جلسات واتساب (متعددة) ──────────────────────────

router.get('/whatsapp/sessions', adminAuth, (req, res) => {
  res.json({ sessions: getAllSessions() })
})

router.get('/whatsapp/sessions/:id', adminAuth, (req, res) => {
  const session = getSession(req.params.id)
  if (!session) return res.status(404).json({ error: 'not_found' })
  res.json(session)
})

router.post('/whatsapp/sessions', adminAuth, (req, res) => {
  const { label } = req.body || {}
  const result = createSession(label)
  res.json(result)
})

router.delete('/whatsapp/sessions/:id', adminAuth, (req, res) => {
  const removed = removeSession(req.params.id)
  if (!removed) return res.status(404).json({ error: 'not_found' })
  res.json({ ok: true })
})

router.post('/whatsapp/sessions/:id/reconnect', adminAuth, (req, res) => {
  connectSession(req.params.id)
    .then(() => res.json({ ok: true, session: getSession(req.params.id) }))
    .catch((err) => res.status(500).json({ error: err.message }))
})

// صفحة ربط WhatsApp — تفتح في المتصفح وتعرض QR
router.get('/qr', (req, res) => {
  connectOnDemand().catch(() => {})
  res.setHeader('Content-Type', 'text/html; charset=utf-8')
  res.send(`<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ربط WhatsApp — otlobli</title>
<style>
  body { font-family: system-ui; background: #0f0f0f; color: #fff; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; margin: 0; gap: 20px; }
  h1 { font-size: 1.4rem; margin: 0; }
  #status { color: #aaa; font-size: 0.95rem; }
  #qr-img { width: 280px; height: 280px; border-radius: 16px; background: #fff; display: none; }
  .connected { color: #4ade80; font-size: 1.2rem; font-weight: bold; display: none; }
</style>
</head>
<body>
<h1>🔗 ربط WhatsApp بـ otlobli</h1>
<p id="status">جاري تشغيل الاتصال...</p>
<img id="qr-img" alt="QR Code">
<p class="connected" id="done">✅ تم الربط بنجاح!</p>
<script>
async function poll() {
  try {
    const r = await fetch('/api/auth/whatsapp/status')
    const d = await r.json()
    if (d.connected) {
      document.getElementById('status').textContent = ''
      document.getElementById('qr-img').style.display = 'none'
      document.getElementById('done').style.display = 'block'
      return
    }
    if (d.qrImageUrl) {
      document.getElementById('qr-img').src = d.qrImageUrl
      document.getElementById('qr-img').style.display = 'block'
      document.getElementById('status').textContent = 'افتح WhatsApp ← النقاط الثلاث ← الأجهزة المرتبطة ← ربط جهاز'
    } else {
      document.getElementById('status').textContent = 'جاري التحضير...'
    }
  } catch(_) {}
  setTimeout(poll, 2000)
}
poll()
</script>
</body>
</html>`)
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

    // إنشاء OTP
    const { code, expiresInSeconds } = createOtp(cleanPhone)

    // إرسال OTP عبر واتساب
    await sendOtpMessage(cleanPhone, code)

    console.log(`📤 OTP ${code} sent to ${cleanPhone}`)

    res.json({
      mode: 'external',
      otpExpiresInSeconds: expiresInSeconds,
    })
  } catch (error) {
    console.error('❌ Failed to send OTP:', error.message)

    if (error.message.includes('WhatsApp غير متصل')) {
      return res.status(503).json({
        error: 'whatsapp_not_configured',
        message: 'واتساب server غير مربوط بعد. امسح QR لربط الرقم.',
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
    const result = verifyOtp(cleanPhone, code)

    if (!result.valid) {
      const messages = {
        no_otp: 'لم يتم إرسال رمز لهذا الرقم بعد.',
        expired: 'انتهت صلاحية الرمز. أرسل رمزاً جديداً.',
        too_many_attempts: 'تم تجاوز عدد المحاولات. أرسل رمزاً جديداً.',
        invalid_code: 'رمز التحقق غير صحيح.',
        already_verified: 'هذا الرمز تم التحقق منه مسبقاً.',
      }

      return res.status(400).json({
        error: result.reason,
        message: messages[result.reason] || 'رمز غير صحيح.',
      })
    }

    const sessionToken = await createCustomerSession(cleanPhone)

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
router.post('/auth/whatsapp/inbound/start', async (req, res) => {
  try {
    const { phone } = req.body

    if (!phone) {
      return res.status(400).json({ error: 'invalid_phone', message: 'أدخل رقم الهاتف.' })
    }

    const cleanPhone = phone.replace(/[\s\-\(\)\+]/g, '')
    const { code, expiresInSeconds } = createOtp(cleanPhone)

    console.log(`📥 Inbound OTP ${code} for ${cleanPhone}`)

    res.json({
      mode: 'external',
      otpExpiresInSeconds: expiresInSeconds,
      whatsappUrl: `https://wa.me/${cleanPhone}?text=${code}`,
      requiresInboundWhatsapp: true,
    })
  } catch (error) {
    res.status(500).json({ error: 'server_error', message: 'خطأ في الخادم.' })
  }
})

router.post('/auth/whatsapp/inbound/status', async (req, res) => {
  try {
    const { phone, code } = req.body

    if (!phone || !code) {
      return res.status(400).json({ error: 'invalid_request', message: 'بيانات ناقصة.' })
    }

    const cleanPhone = phone.replace(/[\s\-\(\)\+]/g, '')
    const result = verifyOtp(cleanPhone, code)

    if (!result.valid) {
      return res.status(400).json({
        error: result.reason,
        message: 'رمز غير صحيح أو منتهي الصلاحية.',
      })
    }

    const sessionToken = await createCustomerSession(cleanPhone)

    res.json({
      mode: 'external',
      sessionToken,
    })
  } catch (error) {
    res.status(500).json({ error: 'server_error', message: 'خطأ في الخادم.' })
  }
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
  // الفاصلة إلزامية بالنمط هون لتجنب التقاط أكواد ألوان hex داخل أيقونة SVG
  // (مثل D80027) يلي بتشبه رقم 5 خانات بس بدون فاصلة آلاف
  const nums = [...usdBlock.matchAll(/\d{1,3},\d{3}/g)]
    .map(m => parseInt(m[0].replace(/,/g, ''), 10))
    .filter(n => n >= 10000 && n <= 100000)

  if (nums.length >= 2) {
    const [buy, sell] = nums
    // نستخدم سعر المبيع (الأعلى) كسعر الصرف المعتمد بالتطبيق لا متوسط
    // البيع والشراء، لأنه هو السعر الحقيقي لتحويل الدولار إلى ليرة بالسوق
    return { buy, sell, rate: sell }
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
