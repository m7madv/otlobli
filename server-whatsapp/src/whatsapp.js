import { makeWASocket, useMultiFileAuthState, DisconnectReason, fetchLatestBaileysVersion } from '@whiskeysockets/baileys'
import { Boom } from '@hapi/boom'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// AUTH_DIR: يمكن تغييره عبر env var، وإلا يُحفظ محلياً
const AUTH_DIR = process.env.AUTH_DIR || path.join(__dirname, '..', 'baileys-auth')

let sock = null
let isConnected = false
let qrCode = null
let cbQueue = []

if (!fs.existsSync(AUTH_DIR)) {
  fs.mkdirSync(AUTH_DIR, { recursive: true })
  console.log('📁 Created session dir:', AUTH_DIR)
}

export function onConnection(fn) {
  if (typeof fn !== 'function') return
  cbQueue.push(fn)
  if (isConnected) try { fn({ status: 'connected' }) } catch (_) {}
}

export function isWhatsappConnected() { return isConnected }
export function getSocket() { return sock }

export function getConnectionStatus() {
  return {
    connected: isConnected,
    qr: qrCode,
    qrImageUrl: qrCode
      ? 'https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=' + encodeURIComponent(qrCode)
      : null,
  }
}

function emit(ev) {
  for (const fn of cbQueue) try { fn(ev) } catch (_) {}
}

export async function sendOtpMessage(phone, code) {
  if (!isConnected || !sock) throw new Error('WhatsApp غير متصل')
  const jid = phone.replace(/[\s\-\(\)\+]/g, '') + '@s.whatsapp.net'
  const msg = `*Talabieh*\n\n🔐 *رمز التحقق*\n\n${code}\n\n⏰ صالح 5 دقائق`
  await sock.sendMessage(jid, { text: msg })
  console.log(`✅ OTP ${code} → ${phone}`)
}

export async function initWhatsapp() {
  const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR)
  const hasCreds = state.creds?.signedPreKey !== undefined
  console.log('📱 WhatsApp ' + (hasCreds ? 'جلسة موجودة' : 'جلسة جديدة — امسح QR'))

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
    keepAliveIntervalMs: 15000,
    connectTimeoutMs: 60000,
    defaultQueryTimeoutMs: 30000,
    retryRequestDelayMs: 1000,
    maxRetries: 10,
  })

  sock.ev.on('creds.update', saveCreds)

  sock.ev.on('connection.update', (update) => {
    const { connection, lastDisconnect, qr } = update

    if (qr) {
      qrCode = qr
      const url = 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=' + encodeURIComponent(qr)
      console.log('\n📲 QR Code:\n' + url + '\n')
      emit({ status: 'qr', qr, qrUrl: url })
    }

    if (connection === 'open') {
      isConnected = true
      qrCode = null
      console.log('\n✅ WhatsApp متصل!\n')
      emit({ status: 'connected' })
    }

    if (connection === 'close') {
      isConnected = false
      const code = (lastDisconnect?.error instanceof Boom) ? lastDisconnect.error.output.statusCode : null
      console.log(`❌ انقطع (${code}) — إعادة الاتصال...`)
      const delay = code === DisconnectReason.restartRequired ? 0 : 3000
      setTimeout(() => {
        initWhatsapp().catch(e => console.error('reconnect fail:', e.message))
      }, delay)
    }
  })

  return sock
}
