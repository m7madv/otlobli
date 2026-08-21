/**
 * Talabieh OTP Server — WhatsApp via Baileys
 * v2.4 — QR Mode
 */

import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import fs from 'fs'
import path from 'path'
import { createRequire } from 'module'
import { fileURLToPath } from 'url'
import { onConnection, isWhatsappConnected, hasWhatsappSessionCredentials } from './whatsapp.js'
import routes from './routes.js'
import { supabase } from './supabase.js'
import { isOtpSecurityConfigured } from './otpStore.js'
import { requireWhatsappAdminSecret } from './adminAuth.js'

const require = createRequire(import.meta.url)
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const PORT = process.env.PORT || 3001

if (process.env.RAILWAY_SERVICE_ID) {
  console.log('🚂 Railway environment detected')
}

// Restore session from uploaded session.tar.gz in volume
const VOLUME_PATH = process.env.RAILWAY_VOLUME_MOUNT_PATH || process.env.RAILWAY_VOLUME_MOUNT || ''
const AUTH_DIR = VOLUME_PATH
  ? path.join(VOLUME_PATH, 'baileys-auth')
  : path.join(__dirname, '..', 'baileys-auth')

const sessionTar = VOLUME_PATH
  ? path.join(VOLUME_PATH, 'session.tar.gz')
  : path.join(__dirname, '..', 'session.tar.gz')

if (fs.existsSync(sessionTar)) {
  try {
    const existingFiles = fs.existsSync(AUTH_DIR) ? fs.readdirSync(AUTH_DIR) : []
    if (existingFiles.length === 0) {
      fs.mkdirSync(AUTH_DIR, { recursive: true })
      const tempDir = path.join('/tmp', '_session_extract_' + Date.now())
      fs.mkdirSync(tempDir, { recursive: true })
      require('child_process').execSync(`tar -xzf "${sessionTar}" -C "${tempDir}"`, { stdio: 'pipe' })
      
      // Find extracted dir and move
      let srcDir = tempDir
      const items = fs.readdirSync(tempDir)
      if (items.length === 1 && fs.statSync(path.join(tempDir, items[0])).isDirectory()) {
        srcDir = path.join(tempDir, items[0])
      }
      fs.readdirSync(srcDir).forEach(f => {
        const src = path.join(srcDir, f)
        if (fs.statSync(src).isFile()) {
          fs.copyFileSync(src, path.join(AUTH_DIR, f))
        }
      })
      fs.rmSync(tempDir, { recursive: true, force: true })
      const count = fs.readdirSync(AUTH_DIR).length
      console.log('✅ Session restored from session.tar.gz (' + count + ' files)')
    } else {
      console.log('📁 Session already exists (' + existingFiles.length + ' files)')
    }
  } catch (e) {
    console.log('⚠️ Session restore from tar:', e.message)
  }
} else {
  console.log('📁 No session.tar.gz found at', sessionTar)
}

const app = express()
app.set('trust proxy', 1)

app.use(cors())
// Reject management traffic before parsing a potentially large request body.
// CORS runs first so a browser's header preflight can complete without a secret.
app.use('/api/session', requireWhatsappAdminSecret)
app.use('/api/whatsapp/sessions', requireWhatsappAdminSecret)
app.use('/api/auth/whatsapp/status', requireWhatsappAdminSecret)
app.use('/api/qr', requireWhatsappAdminSecret)
// Session archives are disabled, so no public API needs a multi-megabyte body.
// Keep the parser bounded to reduce memory-amplification risk on auth routes.
app.use(express.json({ limit: '256kb' }))
app.use(express.urlencoded({ extended: true, limit: '256kb' }))

app.use('/api', routes)

let authReadinessCache = { checkedAt: 0, ready: false, contract: '' }

async function getAuthReadiness() {
  const now = Date.now()
  if (now - authReadinessCache.checkedAt < 30000) return authReadinessCache
  if (!supabase) {
    authReadinessCache = { checkedAt: now, ready: false, contract: '' }
    return authReadinessCache
  }
  const { data, error } = await supabase.rpc('phone_auth_readiness')
  const result = data && typeof data === 'object' ? data : {}
  authReadinessCache = {
    checkedAt: now,
    ready: !error && result.ready === true && result.contract === 'customer-session-v1' && isOtpSecurityConfigured(),
    contract: typeof result.contract === 'string' ? result.contract : '',
  }
  return authReadinessCache
}

app.get('/health', async (req, res) => {
  const authReadiness = await getAuthReadiness().catch(() => ({ ready: false, contract: '' }))
  res.json({
    status: 'ok',
    whatsappConnected: isWhatsappConnected(),
    whatsappSenderReady: isWhatsappConnected(),
    whatsappCredentialsPresent: hasWhatsappSessionCredentials(),
    qrAvailable: !isWhatsappConnected(),
    sessionStoreReady: authReadiness.ready,
    authContract: authReadiness.contract,
    otpSecurityReady: isOtpSecurityConfigured(),
  })
})

app.get('/api/qr-url', requireWhatsappAdminSecret, (req, res) => {
  res.status(410).json({ error: 'legacy_qr_endpoint_disabled' })
})

console.log('🚀 Server started — WhatsApp connects on-demand when OTP is requested')
onConnection(() => {})

app.listen(PORT, () => {
  console.log(`\n🚀 Talabieh OTP Server — QR Mode`)
  console.log(`📍 http://0.0.0.0:${PORT}`)
})
