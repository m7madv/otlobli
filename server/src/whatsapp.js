/**
 * Talabieh WhatsApp Server — Baileys
 * v2.4 — QR Mode clean (This is the one that worked)
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

let sock = null
let isConnected = false
let qrCode = null
let cbQueue = []

// Create fresh session dir
if (!fs.existsSync(AUTH_DIR)) {
  fs.mkdirSync(AUTH_DIR, { recursive: true })
  console.log('📁 Created fresh session at:', AUTH_DIR)
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
  console.log(`✅ OTP ${code} to ${phone}`)
}

export async function initWhatsapp() {
  const { state, saveCreds } = await useMultiFileAuthState(AUTH_DIR)
  const hasCreds = state.creds?.signedPreKey !== undefined
  console.log('📱 WhatsApp ' + (hasCreds ? 'جلسة موجودة' : 'جلسة جديدة'))

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
      console.log('\n📲 QR:\n' + url + '\n')
      emit({ status: 'qr', qr, qrUrl: url })
    }

    if (connection === 'open') {
      isConnected = true
      qrCode = null
      console.log('\n✅✅✅ WhatsApp connected ✅✅✅\n')
      emit({ status: 'connected' })
    }

    if (connection === 'close') {
      isConnected = false
      const code = (lastDisconnect?.error instanceof Boom) ? lastDisconnect.error.output.statusCode : null
      const reason = lastDisconnect?.error?.message || 'unknown'
      console.log(`❌ Disco (${code}): ${reason}`)

      // NEVER clear session on reconnect — always retry
      const reconnectDelay = code === DisconnectReason.restartRequired ? 0 : 2000
      console.log('🔄 Reconnecting in ' + reconnectDelay + 'ms...')
      setTimeout(() => {
        initWhatsapp().catch(e => console.error('reconnect fail:', e.message))
      }, reconnectDelay)
    }
  })

  return sock
}
