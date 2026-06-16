import { Router } from 'express'
import { createOtp, verifyOtp } from './otpStore.js'
import { sendOtpMessage, getConnectionStatus } from './whatsapp.js'

const router = Router()

// ─── WhatsApp OTP ────────────────────────────────────────────

router.get('/auth/whatsapp/status', (req, res) => {
  res.json(getConnectionStatus())
})

router.post('/auth/whatsapp/start', async (req, res) => {
  try {
    const { phone } = req.body
    if (!phone) return res.status(400).json({ error: 'invalid_phone', message: 'أدخل رقم واتساب صحيح.' })

    const cleanPhone = phone.replace(/[\s\-\(\)\+]/g, '')
    if (cleanPhone.length < 10) return res.status(400).json({ error: 'invalid_phone', message: 'رقم الهاتف قصير جداً.' })

    const { code, expiresInSeconds } = createOtp(cleanPhone)
    await sendOtpMessage(cleanPhone, code)
    console.log(`📤 OTP ${code} → ${cleanPhone}`)
    res.json({ mode: 'external', otpExpiresInSeconds: expiresInSeconds })
  } catch (error) {
    console.error('❌ send OTP:', error.message)
    if (error.message.includes('WhatsApp غير متصل')) {
      return res.status(503).json({ error: 'whatsapp_not_configured', message: 'واتساب غير متصل بعد.' })
    }
    res.status(500).json({ error: 'whatsapp_send_error', message: 'تعذر إرسال رسالة واتساب.' })
  }
})

router.post('/auth/whatsapp/verify', async (req, res) => {
  try {
    const { phone, code } = req.body
    if (!phone || !code) return res.status(400).json({ error: 'invalid_request', message: 'بيانات ناقصة.' })

    const cleanPhone = phone.replace(/[\s\-\(\)\+]/g, '')
    const result = verifyOtp(cleanPhone, code)

    if (!result.valid) {
      const messages = {
        no_otp: 'لم يتم إرسال رمز لهذا الرقم.',
        expired: 'انتهت صلاحية الرمز.',
        too_many_attempts: 'تم تجاوز عدد المحاولات.',
        invalid_code: 'رمز التحقق غير صحيح.',
        already_verified: 'تم التحقق من هذا الرمز مسبقاً.',
      }
      return res.status(400).json({ error: result.reason, message: messages[result.reason] || 'رمز غير صحيح.' })
    }

    res.json({ mode: 'external', sessionToken: `talabieh-${cleanPhone}-${Date.now()}` })
  } catch (error) {
    console.error('❌ verify OTP:', error.message)
    res.status(500).json({ error: 'verification_error', message: 'حدث خطأ أثناء التحقق.' })
  }
})

// ─── Exchange Rate (USD → SYP) from sp-today.com ("الليرة اليوم"), fallback to lirat.org ─────

let _rateCache = { rate: 0, buy: 0, sell: 0, updatedAt: 0 }
const RATE_TTL = 30 * 60 * 1000 // 30 دقيقة

async function fetchFromLirat() {
  const res = await fetch('https://lirat.org/wp-json/currency-route/currency/9/damascus.json', {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Accept': 'application/json',
    },
    signal: AbortSignal.timeout(12000),
  })
  if (!res.ok) throw new Error(`lirat.org returned ${res.status}`)
  const series = await res.json()
  if (!Array.isArray(series) || series.length === 0) throw new Error('lirat.org: empty series')
  const last = series[series.length - 1]?.[1]
  const rate = parseInt(last, 10)
  if (!rate || rate < 1000) throw new Error('lirat.org: invalid rate')
  return { buy: rate, sell: rate, rate, source: 'lirat.org' }
}

async function fetchFromSpToday() {
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

  const usdBlock = html.match(/USD[\s\S]{0,600}/i)?.[0] ?? ''
  const nums = [...usdBlock.matchAll(/(\d{1,2}[,.]?\d{3})/g)]
    .map(m => parseInt(m[1].replace(/[,.]/g, ''), 10))
    .filter(n => n >= 10000 && n <= 100000)

  if (nums.length >= 2) return { buy: nums[0], sell: nums[1], rate: Math.round((nums[0] + nums[1]) / 2), source: 'sp-today.com' }
  if (nums.length === 1) return { buy: nums[0], sell: nums[0], rate: nums[0], source: 'sp-today.com' }
  throw new Error('Could not parse USD rate')
}

async function fetchLiveRate() {
  try {
    return await fetchFromSpToday()
  } catch (err) {
    console.error('💱 sp-today.com (الليرة اليوم) failed, falling back to lirat.org:', err.message)
    return await fetchFromLirat()
  }
}

router.get('/exchange-rate', async (req, res) => {
  try {
    const now = Date.now()
    if (_rateCache.rate && now - _rateCache.updatedAt < RATE_TTL) {
      return res.json({ ..._rateCache, cached: true })
    }
    const { buy, sell, rate, source } = await fetchLiveRate()
    _rateCache = { rate, buy, sell, updatedAt: now, source }
    console.log(`💱 سعر الصرف (${source}): ${buy}/${sell} ل.س/دولار`)
    res.json({ rate, buy, sell, updatedAt: now, cached: false, source })
  } catch (err) {
    console.error('💱 خطأ في سعر الصرف:', err.message)
    const fallback = parseInt(process.env.USD_TO_SYP_RATE ?? '13000', 10)
    const rate = _rateCache.rate || fallback
    res.json({ rate, buy: rate, sell: rate, updatedAt: _rateCache.updatedAt || Date.now(), cached: !!_rateCache.rate, source: 'fallback' })
  }
})

export default router
