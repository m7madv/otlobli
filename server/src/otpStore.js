/**
 * Persistent, rate-limited OTP storage for production WhatsApp login.
 * Only an HMAC of each code is written to disk; plaintext codes exist only
 * long enough to be sent to the requested WhatsApp number.
 */

import crypto from 'node:crypto'
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const DB_PATH = process.env.OTP_DB_PATH || join(__dirname, '..', 'otp-db.json')
const OTP_HASH_SECRET = process.env.OTP_HASH_SECRET || ''

const OTP_EXPIRY_SECONDS = 300
const RESEND_COOLDOWN_MS = 60_000
const SEND_WINDOW_MS = 60 * 60 * 1000
const MAX_SENDS_PER_WINDOW = 5
const ATTEMPT_WINDOW_MS = 15 * 60 * 1000
const MAX_FAILED_ATTEMPTS = 5

function loadDb() {
  if (!existsSync(DB_PATH)) return {}
  try {
    const value = JSON.parse(readFileSync(DB_PATH, 'utf-8'))
    return value && typeof value === 'object' && !Array.isArray(value) ? value : {}
  } catch {
    return {}
  }
}

function saveDb(data) {
  writeFileSync(DB_PATH, JSON.stringify(data))
}

function requireOtpSecret() {
  if (OTP_HASH_SECRET.length < 32) {
    const error = new Error('OTP hashing is not configured')
    error.code = 'otp_not_configured'
    throw error
  }
}

function codeHash(phone, code) {
  requireOtpSecret()
  return crypto.createHmac('sha256', OTP_HASH_SECRET).update(`${phone}:${code}`).digest('hex')
}

function constantTimeEqual(left, right) {
  const leftBytes = Buffer.from(String(left))
  const rightBytes = Buffer.from(String(right))
  return leftBytes.length === rightBytes.length && crypto.timingSafeEqual(leftBytes, rightBytes)
}

function activeTimestamps(values, cutoff) {
  return Array.isArray(values)
    ? values.map(Number).filter((value) => Number.isFinite(value) && value >= cutoff)
    : []
}

export function isOtpSecurityConfigured() {
  return OTP_HASH_SECRET.length >= 32
}

export function createOtp(phone) {
  requireOtpSecret()
  const db = loadDb()
  const now = Date.now()
  const previous = db[phone] && typeof db[phone] === 'object' ? db[phone] : {}
  const sendHistory = activeTimestamps(previous.sendHistory, now - SEND_WINDOW_MS)
  const failedAttempts = activeTimestamps(previous.failedAttempts, now - ATTEMPT_WINDOW_MS)
  const lastSentAt = Number(previous.lastSentAt || 0)

  if (failedAttempts.length >= MAX_FAILED_ATTEMPTS) {
    const error = new Error('OTP attempts are temporarily locked')
    error.code = 'otp_attempts_locked'
    error.retryAfterSeconds = Math.max(1, Math.ceil((failedAttempts[0] + ATTEMPT_WINDOW_MS - now) / 1000))
    throw error
  }
  if (lastSentAt && now - lastSentAt < RESEND_COOLDOWN_MS) {
    const error = new Error('OTP resend cooldown is active')
    error.code = 'otp_resend_too_soon'
    error.retryAfterSeconds = Math.max(1, Math.ceil((lastSentAt + RESEND_COOLDOWN_MS - now) / 1000))
    throw error
  }
  if (sendHistory.length >= MAX_SENDS_PER_WINDOW) {
    const error = new Error('OTP send rate limit reached')
    error.code = 'otp_send_rate_limited'
    error.retryAfterSeconds = Math.max(1, Math.ceil((sendHistory[0] + SEND_WINDOW_MS - now) / 1000))
    throw error
  }

  const code = String(crypto.randomInt(100000, 1000000))
  db[phone] = {
    codeHash: codeHash(phone, code),
    expiresAt: now + OTP_EXPIRY_SECONDS * 1000,
    failedAttempts,
    sendHistory: [...sendHistory, now],
    lastSentAt: now,
    verified: false,
  }
  saveDb(db)
  return { code, expiresInSeconds: OTP_EXPIRY_SECONDS }
}

export function verifyOtp(phone, code) {
  try {
    requireOtpSecret()
  } catch {
    return { valid: false, reason: 'otp_not_configured' }
  }
  const db = loadDb()
  const record = db[phone]
  if (!record || typeof record !== 'object') return { valid: false, reason: 'no_otp' }
  if (record.verified) return { valid: false, reason: 'already_verified' }

  const now = Date.now()
  if (!Number.isFinite(Number(record.expiresAt)) || now > Number(record.expiresAt)) {
    delete record.codeHash
    record.verified = false
    saveDb(db)
    return { valid: false, reason: 'expired' }
  }

  const failedAttempts = activeTimestamps(record.failedAttempts, now - ATTEMPT_WINDOW_MS)
  if (failedAttempts.length >= MAX_FAILED_ATTEMPTS) {
    record.failedAttempts = failedAttempts
    saveDb(db)
    return { valid: false, reason: 'too_many_attempts' }
  }

  const suppliedHash = codeHash(phone, String(code))
  if (!record.codeHash || !constantTimeEqual(record.codeHash, suppliedHash)) {
    failedAttempts.push(now)
    record.failedAttempts = failedAttempts
    saveDb(db)
    return { valid: false, reason: failedAttempts.length >= MAX_FAILED_ATTEMPTS ? 'too_many_attempts' : 'invalid_code' }
  }

  record.verified = true
  record.failedAttempts = failedAttempts
  saveDb(db)
  return { valid: true, reason: null }
}

// A correct OTP is reserved before the asynchronous customer-session write.
// If that write fails, reopen only that exact live challenge without resetting
// either its failed-attempt budget or its resend budget.
export function releaseOtpVerification(phone, code) {
  const db = loadDb()
  const record = db[phone]
  if (!record || !record.verified || Date.now() > Number(record.expiresAt)) return false
  const suppliedHash = codeHash(phone, String(code))
  if (!record.codeHash || !constantTimeEqual(record.codeHash, suppliedHash)) return false
  record.verified = false
  saveDb(db)
  return true
}

export function cleanExpiredOtps() {
  const db = loadDb()
  const now = Date.now()
  let changed = false
  for (const [phone, rawRecord] of Object.entries(db)) {
    if (!rawRecord || typeof rawRecord !== 'object') {
      delete db[phone]
      changed = true
      continue
    }
    const sendHistory = activeTimestamps(rawRecord.sendHistory, now - SEND_WINDOW_MS)
    const failedAttempts = activeTimestamps(rawRecord.failedAttempts, now - ATTEMPT_WINDOW_MS)
    if (sendHistory.length === 0 && failedAttempts.length === 0 && now > Number(rawRecord.expiresAt || 0)) {
      delete db[phone]
      changed = true
      continue
    }
    if (sendHistory.length !== (rawRecord.sendHistory?.length ?? 0) ||
        failedAttempts.length !== (rawRecord.failedAttempts?.length ?? 0)) {
      rawRecord.sendHistory = sendHistory
      rawRecord.failedAttempts = failedAttempts
      changed = true
    }
  }
  if (changed) saveDb(db)
}

const cleanupTimer = setInterval(cleanExpiredOtps, 60_000)
cleanupTimer.unref?.()
