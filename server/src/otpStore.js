/**
 * OTP Storage
 * بسيط: يحفظ OTPs في ملف JSON ويمسحها بعد انتهاء الصلاحية
 */

import { readFileSync, writeFileSync, existsSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const DB_PATH = join(__dirname, '..', 'otp-db.json')

const OTP_EXPIRY_SECONDS = 300 // 5 دقائق
const MAX_ATTEMPTS = 5

function loadDb() {
  if (!existsSync(DB_PATH)) {
    return {}
  }
  try {
    return JSON.parse(readFileSync(DB_PATH, 'utf-8'))
  } catch {
    return {}
  }
}

function saveDb(data) {
  writeFileSync(DB_PATH, JSON.stringify(data, null, 2))
}

function generateOtp() {
  return String(Math.floor(1000 + Math.random() * 9000)) // 4 أرقام
}

export function createOtp(phone) {
  const db = loadDb()
  const code = generateOtp()
  const expiresAt = Date.now() + OTP_EXPIRY_SECONDS * 1000

  db[phone] = {
    code,
    expiresAt,
    attempts: 0,
    verified: false,
    createdAt: new Date().toISOString(),
  }

  saveDb(db)
  return { code, expiresInSeconds: OTP_EXPIRY_SECONDS }
}

export function verifyOtp(phone, code) {
  const db = loadDb()
  const record = db[phone]

  if (!record) {
    return { valid: false, reason: 'no_otp' }
  }

  if (record.verified) {
    return { valid: false, reason: 'already_verified' }
  }

  if (Date.now() > record.expiresAt) {
    delete db[phone]
    saveDb(db)
    return { valid: false, reason: 'expired' }
  }

  record.attempts++
  if (record.attempts > MAX_ATTEMPTS) {
    delete db[phone]
    saveDb(db)
    return { valid: false, reason: 'too_many_attempts' }
  }

  if (record.code !== code) {
    saveDb(db)
    return { valid: false, reason: 'invalid_code' }
  }

  record.verified = true
  saveDb(db)
  return { valid: true, reason: null }
}

export function cleanExpiredOtps() {
  const db = loadDb()
  const now = Date.now()
  let cleaned = false

  for (const [phone, record] of Object.entries(db)) {
    if (now > record.expiresAt) {
      delete db[phone]
      cleaned = true
    }
  }

  if (cleaned) {
    saveDb(db)
  }
}

// تنظيف دوري كل دقيقة
setInterval(cleanExpiredOtps, 60_000)
