/**
 * Talabieh WhatsApp Server — Baileys
 * v3.0 — On-demand connection (connect only when sending OTP, disconnect after 5min idle)
 */

import { makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } from '@whiskeysockets/baileys'
import { Boom } from '@hapi/boom'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const VOLUME_PATH = process.env.RAILWAY_VOLUME_MOUNT_PATH || process.env.RAILWAY_VOLUME_MOUNT || ''
const AUTH_DIR = VOLUME_PATH
  ? path.join(VOLUME_PATH, 'baileys-auth')
  : path.join(__dirname, '..', 'baileys-auth')

const IDLE_TIMEOUT_MS = 5 * 60 * 1000 // disconnect after 5 min idle

let sock = null
let isConnected = false
let qrCode = null
let idleTimer = null
let connectingPromise = null

if (!fs.existsSync(AUTH_DIR)) {
  fs.mkdirSync(AUTH_DIR, { recursive: true })
  console.log('📁 Created fresh session at:', AUTH_DIR)
}

export function getConnectionStatus() {
  return {
    connected: isConnected,
    qr: qrCode,
    qrImageUrl: qrCode
      ? 'https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=' + encodeURIComponent(qrCode)
      : null,
  }
}

export function isWhatsappConnected() { return isConnected }
export function getSocket() { return sock }
export function onConnection(fn) { if (isConnected) try { fn({ status: 'connected' }) } catch (_) {} }

function resetIdleTimer() {
  if (idleTimer) clearTimeout(idleTimer)
  idleTimer = setTimeout(() => {
    console.log('💤 WhatsApp: idle timeout — disconnecting')
    disconnectGracefully()
  }, IDLE_TIMEOUT_MS)
}

function disconnectGracefully() {
  idleTimer = null
  if (sock) {
    try { sock.end() } catch (_) {}
    sock = null
  }
  isConnected = false
  qrCode = null
}

function clearSession() {
  try {
    const files = fs.readdirSync(AUTH_DIR)
    for (const f of files) fs.unlinkSync(path.join(AUTH_DIR, f))
    console.log('🗑️  Cleared WhatsApp session files')
  } catch (_) {}
}

// Returns a promise that resolves when connected (or rejects on timeout/failure)
export function connectOnDemand() {
  if (isConnected && sock) return Promise.resolve()
  if (connectingPromise) return connectingPromise

  connectingPromise = new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      connectingPromise = null
      reject(new Error('انتهت مهلة الاتصال بـ WhatsApp'))
    }, 40000)

    initWhatsapp()
      .then((resolveOnOpen) => {
        resolveOnOpen.then(() => {
          clearTimeout(timeout)
          connectingPromise = null
          resolve()
        }).catch((err) => {
          clearTimeout(timeout)
          connectingPromise = null
          reject(err)
        })
      })
      .catch((err) => {
        clearTimeout(timeout)
        connectingPromise = null
        reject(err)
      })
  })

  return connectingPromise
}

async function initWhatsapp() {
  const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR)
  const hasCreds = state.creds?.signedPreKey !== undefined
  console.log('📱 WhatsApp ' + (hasCreds ? 'جلسة موجودة — جاري الاتصال' : 'جلسة جديدة — انتظر QR'))

  let version
  try {
    const r = await fetchLatestBaileysVersion()
    version = r.version
  } catch (_) {}

  sock = makeWASocket({
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

  sock.ev.on('creds.update', saveCreds)

  // Returns a promise that resolves when connection opens
  const openPromise = new Promise((resolve, reject) => {
    sock.ev.on('connection.update', (update) => {
      const { connection, lastDisconnect, qr } = update

      if (qr) {
        qrCode = qr
        const url = 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=' + encodeURIComponent(qr)
        console.log('\n📲 QR Code (امسح هذا):\n' + url + '\n')
      }

      if (connection === 'open') {
        isConnected = true
        qrCode = null
        console.log('✅ WhatsApp متصل')
        resolve()
      }

      if (connection === 'close') {
        isConnected = false
        const code = (lastDisconnect?.error instanceof Boom) ? lastDisconnect.error.output.statusCode : null
        const reason = lastDisconnect?.error?.message || 'unknown'
        console.log(`❌ WhatsApp انقطع (${code}): ${reason}`)

        if (code === DisconnectReason.loggedOut || code === 403) {
          console.log('🗑️  الجلسة منتهية — سيُطلب QR جديد في المرة القادمة')
          clearSession()
          reject(new Error('انتهت جلسة WhatsApp. أعد ربط الرقم من خلال QR.'))
        } else if (code === DisconnectReason.restartRequired) {
          // Baileys طلب restart — reconnect مرة واحدة فقط
          sock = null
          initWhatsapp().then((p) => p.then(resolve).catch(reject)).catch(reject)
        } else {
          reject(new Error(`WhatsApp انقطع: ${reason}`))
        }
      }
    })
  })

  return openPromise
}

export async function sendOtpMessage(phone, code) {
  await connectOnDemand()

  const jid = phone.replace(/[\s\-\(\)\+]/g, '') + '@s.whatsapp.net'
  const msg = `رمز التحقق من otlobli:\n\n${code}\n\nصالح لمدة 5 دقائق.`
  await sock.sendMessage(jid, { text: msg })
  console.log(`✅ OTP ${code} → ${phone}`)

  resetIdleTimer()
}

// رسالة واتساب عامة لأي إشعار (تحديث طلب، تأكيد دفع...) - تستخدم نفس
// الاتصال عند الطلب (on-demand) الذي تستخدمه رسائل OTP.
export async function sendNotificationMessage(phone, text) {
  await connectOnDemand()

  const jid = phone.replace(/[\s\-\(\)\+]/g, '') + '@s.whatsapp.net'
  await sock.sendMessage(jid, { text })
  console.log(`✅ إشعار واتساب → ${phone}`)

  resetIdleTimer()
}
