/**
 * Talabieh WhatsApp Server — Baileys Multi-Session
 * v4.0 — عدة أرقام واتساب مع fallback ذكي
 */

import { makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } from '@whiskeysockets/baileys'
import { Boom } from '@hapi/boom'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const VOLUME_PATH = process.env.RAILWAY_VOLUME_MOUNT_PATH || process.env.RAILWAY_VOLUME_MOUNT || ''
const BASE_AUTH_DIR = VOLUME_PATH
  ? path.join(VOLUME_PATH, 'wa-sessions')
  : path.join(__dirname, '..', 'wa-sessions')

const LEGACY_AUTH_DIR = VOLUME_PATH
  ? path.join(VOLUME_PATH, 'baileys-auth')
  : path.join(__dirname, '..', 'baileys-auth')

const IDLE_TIMEOUT_MS = 5 * 60 * 1000

if (!fs.existsSync(BASE_AUTH_DIR)) {
  fs.mkdirSync(BASE_AUTH_DIR, { recursive: true })
}

// ترحيل الجلسة القديمة (baileys-auth) → wa-sessions/0
if (fs.existsSync(LEGACY_AUTH_DIR)) {
  const legacyFiles = fs.readdirSync(LEGACY_AUTH_DIR).filter(f => !f.startsWith('.'))
  if (legacyFiles.length > 0) {
    const slot0 = path.join(BASE_AUTH_DIR, '0')
    if (!fs.existsSync(slot0) || fs.readdirSync(slot0).length === 0) {
      fs.mkdirSync(slot0, { recursive: true })
      for (const f of legacyFiles) {
        const src = path.join(LEGACY_AUTH_DIR, f)
        if (fs.statSync(src).isFile()) fs.copyFileSync(src, path.join(slot0, f))
      }
      console.log(`📦 ترحيل الجلسة القديمة → slot 0 (${legacyFiles.length} ملف)`)
    }
  }
}

/**
 * @typedef {Object} Session
 * @property {string} id
 * @property {string} authDir
 * @property {import('@whiskeysockets/baileys').WASocket|null} sock
 * @property {boolean} connected
 * @property {string|null} qrCode
 * @property {string|null} phoneNumber
 * @property {NodeJS.Timeout|null} idleTimer
 * @property {Promise<void>|null} connectingPromise
 * @property {'idle'|'connecting'|'connected'|'qr'|'error'} status
 * @property {string} label
 */

/** @type {Map<string, Session>} */
const sessions = new Map()

function getAuthDir(id) {
  return path.join(BASE_AUTH_DIR, id)
}

function loadExistingSessions() {
  try {
    const dirs = fs.readdirSync(BASE_AUTH_DIR).filter(d => {
      const full = path.join(BASE_AUTH_DIR, d)
      return fs.statSync(full).isDirectory() && fs.readdirSync(full).length > 0
    })
    for (const d of dirs) {
      if (!sessions.has(d)) {
        sessions.set(d, createSessionObj(d))
      }
    }
  } catch (_) {}
}

function createSessionObj(id) {
  return {
    id,
    authDir: getAuthDir(id),
    sock: null,
    connected: false,
    qrCode: null,
    phoneNumber: null,
    idleTimer: null,
    connectingPromise: null,
    status: 'idle',
    label: '',
  }
}

function nextSessionId() {
  let i = 0
  while (sessions.has(String(i))) i++
  return String(i)
}

// ── حالة الجلسات ────────────────────────────────────────────

export function getAllSessions() {
  return [...sessions.values()].map(s => ({
    id: s.id,
    connected: s.connected,
    status: s.status,
    phoneNumber: s.phoneNumber,
    label: s.label,
    qrCode: s.qrCode,
    qrImageUrl: s.qrCode
      ? 'https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=' + encodeURIComponent(s.qrCode)
      : null,
  }))
}

export function getSession(id) {
  const s = sessions.get(id)
  if (!s) return null
  return {
    id: s.id,
    connected: s.connected,
    status: s.status,
    phoneNumber: s.phoneNumber,
    label: s.label,
    qrCode: s.qrCode,
    qrImageUrl: s.qrCode
      ? 'https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=' + encodeURIComponent(s.qrCode)
      : null,
  }
}

// التوافقية مع الكود القديم
export function isWhatsappConnected() {
  return [...sessions.values()].some(s => s.connected)
}

export function getConnectionStatus() {
  const connected = [...sessions.values()].find(s => s.connected)
  if (connected) return { connected: true, qr: null, qrImageUrl: null }
  const withQr = [...sessions.values()].find(s => s.qrCode)
  if (withQr) return { connected: false, qr: withQr.qrCode, qrImageUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=' + encodeURIComponent(withQr.qrCode) }
  return { connected: false, qr: null, qrImageUrl: null }
}

export function onConnection(fn) {
  if (isWhatsappConnected()) try { fn({ status: 'connected' }) } catch (_) {}
}

// ── إنشاء / حذف جلسات ────────────────────────────────────

export function createSession(label) {
  const id = nextSessionId()
  const authDir = getAuthDir(id)
  fs.mkdirSync(authDir, { recursive: true })
  const session = createSessionObj(id)
  session.label = label || `رقم ${parseInt(id) + 1}`
  sessions.set(id, session)
  // ابدأ الاتصال فوراً لتوليد QR
  connectSession(id).catch(() => {})
  return { id, label: session.label }
}

export function removeSession(id) {
  const session = sessions.get(id)
  if (!session) return false
  disconnectSession(session)
  try {
    fs.rmSync(session.authDir, { recursive: true, force: true })
  } catch (_) {}
  sessions.delete(id)
  return true
}

// ── اتصال الجلسة ────────────────────────────────────────

function resetIdleTimer(session) {
  if (session.idleTimer) clearTimeout(session.idleTimer)
  session.idleTimer = setTimeout(() => {
    console.log(`💤 Session ${session.id}: idle timeout — disconnecting`)
    disconnectSession(session)
  }, IDLE_TIMEOUT_MS)
}

function disconnectSession(session) {
  if (session.idleTimer) { clearTimeout(session.idleTimer); session.idleTimer = null }
  if (session.sock) { try { session.sock.end() } catch (_) {} }
  session.sock = null
  session.connected = false
  session.qrCode = null
  session.connectingPromise = null
  session.status = 'idle'
}

function clearSessionFiles(session) {
  try {
    if (fs.existsSync(session.authDir)) {
      for (const f of fs.readdirSync(session.authDir)) {
        fs.rmSync(path.join(session.authDir, f), { recursive: true, force: true })
      }
    }
  } catch (_) {}
}

export function connectSession(id) {
  const session = sessions.get(id)
  if (!session) return Promise.reject(new Error('جلسة غير موجودة'))
  if (session.connected && session.sock) return Promise.resolve()
  if (session.connectingPromise) return session.connectingPromise

  session.status = 'connecting'
  session.connectingPromise = new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      session.connectingPromise = null
      session.status = 'error'
      reject(new Error('انتهت مهلة الاتصال'))
    }, 45000)

    initSession(session)
      .then(() => {
        clearTimeout(timeout)
        session.connectingPromise = null
        resolve()
      })
      .catch((err) => {
        clearTimeout(timeout)
        session.connectingPromise = null
        session.status = 'error'
        reject(err)
      })
  })

  return session.connectingPromise
}

async function initSession(session) {
  const { state, saveCreds } = await useMultiFileAuthState(session.authDir)
  const hasCreds = state.creds?.signedPreKey !== undefined
  console.log(`📱 Session ${session.id}: ${hasCreds ? 'جلسة موجودة' : 'جلسة جديدة — انتظر QR'}`)

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
    keepAliveIntervalMs: 30000,
    connectTimeoutMs: 30000,
    defaultQueryTimeoutMs: 20000,
  })

  session.sock = sock
  sock.ev.on('creds.update', saveCreds)

  return new Promise((resolve, reject) => {
    sock.ev.on('connection.update', (update) => {
      const { connection, lastDisconnect, qr } = update

      if (qr) {
        session.qrCode = qr
        session.status = 'qr'
        console.log(`📲 Session ${session.id}: QR ready`)
      }

      if (connection === 'open') {
        session.connected = true
        session.qrCode = null
        session.status = 'connected'
        // استخرج رقم الهاتف من بيانات الاتصال
        const me = sock.user
        if (me?.id) session.phoneNumber = me.id.split(':')[0].split('@')[0]
        console.log(`✅ Session ${session.id}: متصل (${session.phoneNumber || '?'})`)
        resolve()
      }

      if (connection === 'close') {
        session.connected = false
        const code = (lastDisconnect?.error instanceof Boom) ? lastDisconnect.error.output.statusCode : null
        const reason = lastDisconnect?.error?.message || 'unknown'
        console.log(`❌ Session ${session.id}: انقطع (${code}): ${reason}`)

        if (code === DisconnectReason.loggedOut) {
          clearSessionFiles(session)
          session.status = 'error'
          reject(new Error('انتهت الجلسة — يلزم QR جديد'))
        } else if (code === DisconnectReason.restartRequired) {
          session.sock = null
          initSession(session).then(resolve).catch(reject)
        } else {
          session.status = 'error'
          reject(new Error(`انقطع: ${reason}`))
        }
      }
    })
  })
}

// ── إرسال مع fallback ────────────────────────────────────

async function sendWithFallback(fn) {
  const orderedSessions = [...sessions.values()]
    .filter(s => s.connected || s.status === 'idle')
    .sort((a, b) => {
      if (a.connected && !b.connected) return -1
      if (!a.connected && b.connected) return 1
      return parseInt(a.id) - parseInt(b.id)
    })

  if (orderedSessions.length === 0) {
    throw new Error('لا توجد جلسة واتساب متصلة. أضف رقماً من لوحة الإدارة.')
  }

  let lastError = null
  for (const session of orderedSessions) {
    try {
      if (!session.connected) await connectSession(session.id)
      await fn(session)
      resetIdleTimer(session)
      return
    } catch (err) {
      lastError = err
      console.log(`⚠️ Session ${session.id} (${session.phoneNumber || '?'}): فشل الإرسال — ${err.message}`)
    }
  }

  throw lastError || new Error('فشل الإرسال من جميع الأرقام')
}

export async function sendOtpMessage(phone, code) {
  const jid = phone.replace(/[\s\-\(\)\+]/g, '') + '@s.whatsapp.net'
  const msg = `رمز التحقق من otlobli:\n\n${code}\n\nصالح لمدة 5 دقائق.`

  await sendWithFallback(async (session) => {
    await session.sock.sendMessage(jid, { text: msg })
    console.log(`✅ OTP ${code} → ${phone} (session ${session.id})`)
  })
}

export async function sendNotificationMessage(phone, text) {
  const jid = phone.replace(/[\s\-\(\)\+]/g, '') + '@s.whatsapp.net'

  await sendWithFallback(async (session) => {
    await session.sock.sendMessage(jid, { text })
    console.log(`✅ إشعار → ${phone} (session ${session.id})`)
  })
}

// ── التوافقية ────────────────────────────────────────────

export function connectOnDemand() {
  const connected = [...sessions.values()].find(s => s.connected)
  if (connected) return Promise.resolve()
  const first = [...sessions.values()][0]
  if (first) return connectSession(first.id)
  return Promise.reject(new Error('لا توجد جلسات واتساب'))
}

export function getSocket() {
  const connected = [...sessions.values()].find(s => s.connected)
  return connected?.sock ?? null
}

// تحميل الجلسات الموجودة عند بدء السيرفر
loadExistingSessions()
console.log(`📱 ${sessions.size} جلسة واتساب محمّلة`)
