// ============================================================================
// otlobli — WhatsApp OTP sender (Baileys) — احترافي متعدّد الأرقام
//
// ملاحظة صريحة: Baileys طريقة غير رسمية، ولا يوجد إعداد يمنع الحظر 100%.
// هذا الملف يقلّل الحظر عبر ممارسات مشروعة (توزيع حمل، حدود إرسال، إحماء،
// التحقق من وجود الرقم، أنماط إرسال طبيعية) ويضمن استمرار الخدمة عبر مجموعة
// أرقام + failover تلقائي، فحتى لو انحظر رقم تبقى الخدمة تعمل من الباقي.
//
// إضافة رقم جديد: عرّفه في WHATSAPP_NUMBERS (مثال: main,n2,n3) ثم أعد التشغيل
// وامسح QR الخاص به عبر /api/qr-url?number=n2 . الجلسات محفوظة في مجلدات فرعية.
// ============================================================================
import { makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } from '@whiskeysockets/baileys'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const AUTH_BASE = process.env.AUTH_DIR || path.join(__dirname, '..', 'baileys-auth')

// حدود مشروعة لتقليل الحظر (قابلة للضبط من env)
const PER_MIN = Number(process.env.WA_PER_NUMBER_PER_MIN || 6)          // إرسال/دقيقة لكل رقم
const PER_DAY = Number(process.env.WA_PER_NUMBER_PER_DAY || 200)        // سقف يومي لكل رقم (بعد الإحماء)
const WARMUP_DAYS = Number(process.env.WA_WARMUP_DAYS || 3)             // أيام الإحماء التدريجي
const WARMUP_DAY1 = Number(process.env.WA_WARMUP_DAY1 || 30)            // سقف اليوم الأول لرقم جديد
const MIN_GAP_MS = Number(process.env.WA_MIN_SEND_GAP_MS || 4000)       // فاصل أدنى بين رسائل نفس الرقم
const SEND_JITTER_MS = Number(process.env.WA_SEND_JITTER_MS || 1500)    // تأخير عشوائي بسيط قبل الإرسال (سلوك طبيعي)

const TELEGRAM_TOKEN = process.env.TELEGRAM_BOT_TOKEN || ''
const TELEGRAM_ALERT_CHAT = process.env.TELEGRAM_ALERT_CHAT_ID || process.env.TELEGRAM_CHAT_ID || ''

/** @type {Map<string, any>} label -> number state */
const numbers = new Map()
let cbQueue = []

function todayKey() {
  return new Date().toISOString().slice(0, 10)
}

function labelDir(label) {
  return path.join(AUTH_BASE, label)
}

function stateFile(label) {
  return path.join(labelDir(label), '_otlobli_meta.json')
}

// إحماء: رقم عمره يوم واحد يبدأ بسقف صغير ويرتفع تدريجياً حتى PER_DAY.
function dailyCap(num) {
  const ageDays = Math.floor((Date.now() - (num.firstSeenAt || Date.now())) / 86400000)
  if (ageDays >= WARMUP_DAYS) return PER_DAY
  const step = (PER_DAY - WARMUP_DAY1) / Math.max(WARMUP_DAYS, 1)
  return Math.round(WARMUP_DAY1 + step * ageDays)
}

function loadMeta(label) {
  try { return JSON.parse(fs.readFileSync(stateFile(label), 'utf-8')) } catch { return {} }
}
function saveMeta(num) {
  try {
    fs.writeFileSync(stateFile(num.label), JSON.stringify({
      firstSeenAt: num.firstSeenAt, sentTotal: num.sentTotal,
      dayKey: num.dayKey, sentToday: num.sentToday, banned: num.banned,
    }))
  } catch (_) {}
}

// ترحيل الجلسة القديمة (ملفات creds مباشرة داخل baileys-auth) إلى مجلد main/.
function migrateLegacy() {
  try {
    if (!fs.existsSync(AUTH_BASE)) { fs.mkdirSync(AUTH_BASE, { recursive: true }); return }
    if (fs.existsSync(path.join(AUTH_BASE, 'creds.json')) && !fs.existsSync(path.join(AUTH_BASE, 'main'))) {
      const dst = labelDir('main')
      fs.mkdirSync(dst, { recursive: true })
      for (const f of fs.readdirSync(AUTH_BASE)) {
        const src = path.join(AUTH_BASE, f)
        if (fs.statSync(src).isFile()) fs.renameSync(src, path.join(dst, f))
      }
      console.log('📦 رُحّلت الجلسة القديمة إلى main/')
    }
  } catch (e) { console.error('migrate legacy fail:', e.message) }
}

function resolveLabels() {
  const env = (process.env.WHATSAPP_NUMBERS || '').split(',').map(s => s.trim()).filter(Boolean)
  if (env.length) return env
  // اكتشاف المجلدات الفرعية الموجودة
  try {
    const subs = fs.readdirSync(AUTH_BASE).filter(f => {
      try { return fs.statSync(path.join(AUTH_BASE, f)).isDirectory() } catch { return false }
    })
    if (subs.length) return subs
  } catch (_) {}
  return ['main']
}

function emit(ev) { for (const fn of cbQueue) try { fn(ev) } catch (_) {} }

export function onConnection(fn) {
  if (typeof fn !== 'function') return
  cbQueue.push(fn)
  if ([...numbers.values()].some(n => n.connected)) try { fn({ status: 'connected' }) } catch (_) {}
}

async function alertBan(label, reason) {
  console.error(`🚫 الرقم [${label}] محظور/خرج (${reason}) — أُوقف وحُوّل الحمل لغيره`)
  if (!TELEGRAM_TOKEN || !TELEGRAM_ALERT_CHAT) return
  const text = `🚫 otlobli: رقم واتساب [${label}] توقّف (${reason}).\n` +
    `الأرقام الصحّية الآن: ${healthyCount()}. امسح QR جديد للرقم عبر /api/qr-url?number=${label}`
  try {
    await fetch(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`, {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ chat_id: TELEGRAM_ALERT_CHAT, text }),
    })
  } catch (_) {}
}

async function initNumber(label) {
  const dir = labelDir(label)
  fs.mkdirSync(dir, { recursive: true })
  const meta = loadMeta(label)
  const { state, saveCreds } = await useMultiFileAuthState(dir)

  let num = numbers.get(label)
  if (!num) {
    num = {
      label, sock: null, connected: false, banned: false, qr: null,
      firstSeenAt: meta.firstSeenAt || Date.now(),
      sentTotal: meta.sentTotal || 0,
      dayKey: meta.dayKey || todayKey(),
      sentToday: meta.dayKey === todayKey() ? (meta.sentToday || 0) : 0,
      lastSentAt: 0, reconnectTimer: null,
    }
    numbers.set(label, num)
  }
  num.banned = false

  let version
  try { version = (await fetchLatestBaileysVersion()).version } catch (_) {}

  const sock = makeWASocket({
    auth: state,
    version,
    browser: ['Chrome (Linux)', '', ''],
    syncFullHistory: false,
    markOnlineOnConnect: false,
    fireInitQueries: false,
    shouldSyncConnectionMessage: false,
    emitOwnEvents: false,
    getMessage: () => undefined,
    keepAliveIntervalMs: 15000,
    connectTimeoutMs: 60000,
    defaultQueryTimeoutMs: 30000,
    retryRequestDelayMs: 1000,
    maxRetries: 10,
  })
  num.sock = sock
  sock.ev.on('creds.update', saveCreds)

  sock.ev.on('connection.update', (update) => {
    const { connection, lastDisconnect, qr } = update
    if (qr) {
      num.qr = qr
      console.log(`\n📲 QR للرقم [${label}]:\nhttps://api.qrserver.com/v1/create-qr-code/?size=500x500&data=${encodeURIComponent(qr)}\n`)
      emit({ status: 'qr', label, qr })
    }
    if (connection === 'open') {
      num.connected = true
      num.qr = null
      num.firstSeenAt = num.firstSeenAt || Date.now()
      saveMeta(num)
      console.log(`✅ الرقم [${label}] متصل`)
      emit({ status: 'connected', label })
    }
    if (connection === 'close') {
      num.connected = false
      const statusCode = lastDisconnect?.error?.output?.statusCode
        ?? lastDisconnect?.error?.output?.payload?.statusCode ?? null

      // حظر/تسجيل خروج: لا تُعد الاتصال لرقم ميت — أوقفه ونبّه.
      if (statusCode === DisconnectReason.loggedOut || statusCode === 403 || statusCode === 401) {
        num.banned = true
        saveMeta(num)
        void alertBan(label, `status ${statusCode}`)
        emit({ status: 'banned', label })
        return
      }
      // استبدال الجلسة: لا تدخل في حلقة عدوانية.
      const delay = statusCode === DisconnectReason.restartRequired ? 0
        : statusCode === DisconnectReason.connectionReplaced ? 15000 : 4000
      clearTimeout(num.reconnectTimer)
      num.reconnectTimer = setTimeout(() => {
        initNumber(label).catch(e => console.error(`reconnect [${label}] fail:`, e.message))
      }, delay)
    }
  })

  return sock
}

function rollDayIfNeeded(num) {
  const tk = todayKey()
  if (num.dayKey !== tk) { num.dayKey = tk; num.sentToday = 0; saveMeta(num) }
}

function canSend(num) {
  rollDayIfNeeded(num)
  return num.connected && !num.banned
    && num.sentToday < dailyCap(num)
    && (Date.now() - num.lastSentAt) >= MIN_GAP_MS
}

function healthyCount() {
  return [...numbers.values()].filter(n => n.connected && !n.banned).length
}

// اختيار الرقم الأقل استخداماً مؤخراً (توزيع حمل عادل).
function pickNumber() {
  const eligible = [...numbers.values()].filter(canSend)
  if (!eligible.length) return null
  eligible.sort((a, b) => a.lastSentAt - b.lastSentAt || a.sentToday - b.sentToday)
  return eligible[0]
}

function toJid(phone) {
  return phone.replace(/[\s\-()+]/g, '') + '@s.whatsapp.net'
}

const sleep = (ms) => new Promise(r => setTimeout(r, ms))

async function verifyOnWhatsapp(sock, jid) {
  try {
    const res = await sock.onWhatsApp(jid)
    // إذا رجّع نتيجة صريحة بعدم الوجود نتجنّب الإرسال (سبب حظر شائع).
    if (Array.isArray(res) && res.length) return res[0]?.exists !== false
    return true // عند الشك لا نمنع (بعض النسخ ترجّع فارغاً)
  } catch (_) { return true }
}

/**
 * يرسل رمز OTP عبر أفضل رقم متاح مع failver تلقائي وإعادة محاولة.
 * يرمي خطأً فقط إذا فشلت كل الأرقام (وقتها يحوّل التطبيق لتيليغرام).
 */
export async function sendOtpMessage(phone, code) {
  const jid = toJid(phone)
  const msg = `*otlobli*\n\n🔐 *رمز التحقق*\n\n${code}\n\n⏰ صالح 5 دقائق`

  const tried = new Set()
  let lastErr = null
  for (let attempt = 0; attempt < numbers.size + 1; attempt++) {
    const num = pickNumber()
    if (!num || tried.has(num.label)) break
    tried.add(num.label)

    // تحقّق أن الرقم على واتساب مرة واحدة (بأول رقم صحّي).
    if (attempt === 0 && !(await verifyOnWhatsapp(num.sock, jid))) {
      throw new Error('recipient_not_on_whatsapp')
    }

    try {
      // سلوك طبيعي: حضور "يكتب" ثم تأخير عشوائي بسيط قبل الإرسال.
      try { await num.sock.sendPresenceUpdate('composing', jid) } catch (_) {}
      await sleep(600 + Math.floor(Math.random() * SEND_JITTER_MS))
      await num.sock.sendMessage(jid, { text: msg })
      try { await num.sock.sendPresenceUpdate('paused', jid) } catch (_) {}

      num.lastSentAt = Date.now()
      num.sentToday += 1
      num.sentTotal += 1
      saveMeta(num)
      console.log(`✅ OTP → ${phone} عبر [${num.label}] (${num.sentToday}/${dailyCap(num)} اليوم)`)
      return { via: num.label }
    } catch (e) {
      lastErr = e
      console.error(`⚠️ فشل الإرسال عبر [${num.label}]:`, e.message)
      num.lastSentAt = Date.now() // لا تعاود فوراً على نفس الرقم
    }
  }
  throw new Error(lastErr ? `all_numbers_failed: ${lastErr.message}` : 'no_healthy_whatsapp_number')
}

export function isWhatsappConnected() { return healthyCount() > 0 }

// توافقية: أول رقم فيه QR أو الحالة العامة.
export function getConnectionStatus() {
  const withQr = [...numbers.values()].find(n => n.qr)
  const connected = healthyCount() > 0
  return {
    connected,
    qr: withQr?.qr || null,
    qrImageUrl: withQr?.qr
      ? 'https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=' + encodeURIComponent(withQr.qr)
      : null,
  }
}

export function getNumberQr(label) {
  const num = numbers.get(label)
  if (!num) return { error: 'unknown_number' }
  if (num.connected) return { connected: true, label }
  if (num.qr) return { connected: false, label, qrUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=' + encodeURIComponent(num.qr) }
  return { connected: false, label, message: num.banned ? 'الرقم محظور — يحتاج مسح QR جديد' : 'QR غير متاح بعد' }
}

export function getPoolStatus() {
  return {
    healthy: healthyCount(),
    total: numbers.size,
    numbers: [...numbers.values()].map(n => ({
      label: n.label,
      connected: n.connected,
      banned: n.banned,
      sentToday: n.sentToday,
      dailyCap: dailyCap(n),
      sentTotal: n.sentTotal,
      lastSentAt: n.lastSentAt || null,
      needsQr: !n.connected && !!n.qr,
    })),
  }
}

export async function initWhatsapp() {
  migrateLegacy()
  const labels = resolveLabels()
  console.log(`📱 مجموعة واتساب: ${labels.join(', ')} (حد/دقيقة=${PER_MIN}, حد/يوم=${PER_DAY})`)
  for (const label of labels) {
    await initNumber(label).catch(e => console.error(`init [${label}] fail:`, e.message))
  }
  return numbers
}
