/**
 * API Routes للتحقق عبر OTP واتساب
 */

import { Router } from 'express'
import fs from 'fs'
import path from 'path'
import zlib from 'zlib'
import { createRequire } from 'module'
import { fileURLToPath } from 'url'
import { createOtp, verifyOtp } from './otpStore.js'
import { sendOtpMessage, getConnectionStatus } from './whatsapp.js'

const require = createRequire(import.meta.url)
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const router = Router()

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

router.get('/auth/whatsapp/status', (req, res) => {
  const status = getConnectionStatus()
  res.json(status)
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

    // إنشاء session token (بسيط حالياً)
    const sessionToken = `talabieh-${cleanPhone}-${Date.now()}`

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

    res.json({
      mode: 'external',
      sessionToken: `talabieh-${cleanPhone}-${Date.now()}`,
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

let _rateCache = { rate: 0, buy: 0, sell: 0, updatedAt: 0 }
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

  // Look for USD row: find "USD" then grab the two nearest 5-digit numbers (buy / sell)
  const usdBlock = html.match(/USD[\s\S]{0,600}/i)?.[0] ?? ''
  const nums = [...usdBlock.matchAll(/(\d{1,2}[,.]?\d{3})/g)]
    .map(m => parseInt(m[1].replace(/[,.]/g, ''), 10))
    .filter(n => n >= 10000 && n <= 100000)

  if (nums.length >= 2) {
    const [buy, sell] = nums
    return { buy, sell, rate: Math.round((buy + sell) / 2) }
  }
  if (nums.length === 1) {
    return { buy: nums[0], sell: nums[0], rate: nums[0] }
  }
  throw new Error('Could not parse USD rate from sp-today.com')
}

router.get('/exchange-rate', async (req, res) => {
  try {
    const now = Date.now()
    if (_rateCache.rate && now - _rateCache.updatedAt < RATE_TTL) {
      return res.json({ ..._rateCache, cached: true, source: 'sp-today.com' })
    }

    const { buy, sell, rate } = await fetchLiveRate()
    _rateCache = { rate, buy, sell, updatedAt: now }
    console.log(`💱 Exchange rate updated: ${buy}/${sell} SYP/USD`)
    res.json({ rate, buy, sell, updatedAt: now, cached: false, source: 'sp-today.com' })
  } catch (err) {
    console.error('💱 Rate fetch failed:', err.message)
    const fallback = parseInt(process.env.VITE_USD_TO_SYP_RATE ?? '13000', 10)
    // Return cached value if available, otherwise env fallback
    const rate = _rateCache.rate || fallback
    res.json({ rate, buy: rate, sell: rate, updatedAt: _rateCache.updatedAt || Date.now(), cached: !!_rateCache.rate, source: 'fallback' })
  }
})

export default router
