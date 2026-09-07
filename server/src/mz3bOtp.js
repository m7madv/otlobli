/** Server-only adapter for the existing Otlobli phone-auth contract.
 * Runs in ONE Node process with persistent local storage (the current pm2 fork).
 * No OTP, phone number or API key is stored in the challenge journal.
 */
import crypto from 'node:crypto'
import { existsSync, readFileSync, writeFileSync, renameSync, statSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const API = 'https://mz3b.com/api/v1'
const MINUTE = 60_000
const HOUR = 60 * MINUTE
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export const isMz3bEnabled = () => process.env.WHATSAPP_OTP_PROVIDER === 'mz3b'

export function createMz3bOtp({
  key = process.env.MZ3B_API_KEY || '',
  secret = process.env.OTP_HASH_SECRET || '',
  dbPath = process.env.MZ3B_OTP_DB_PATH || fileURLToPath(new URL('../mz3b-otp-db.json', import.meta.url)),
  fetcher = (...args) => fetch(...args),
  now = Date.now,
} = {}) {
  const busy = new Set()
  let health = { at: 0, ready: false }
  const hash = (value) => crypto.createHmac('sha256', secret).update(value).digest('hex')
  const fail = (code, status = 503, retryAfterSeconds = 60) => {
    const error = new Error(code)
    Object.assign(error, { code, status, retryAfterSeconds })
    throw error
  }
  const requireConfig = () => {
    if (!key || secret.length < 32) fail('otp_not_configured')
  }
  function read() {
    requireConfig()
    if (!existsSync(dbPath)) return {}
    // Corruption fails closed; never reset rate limits or reuse a spent code.
    if (statSync(dbPath).size > 8_000_000) fail('otp_storage_error')
    try {
      const data = JSON.parse(readFileSync(dbPath, 'utf8'))
      if (!data || Array.isArray(data) || typeof data !== 'object') fail('otp_storage_error')
      return data
    } catch { return fail('otp_storage_error') }
  }
  function save(id, record) {
    const data = read()
    for (const [entry, value] of Object.entries(data)) {
      if (entry !== id && !busy.has(entry) && Number(value?.lastSentAt) < now() - HOUR) delete data[entry]
    }
    if (!data[id] && Object.keys(data).length >= 2000) fail('otp_storage_error')
    data[id] = record
    try {
      writeFileSync(`${dbPath}.tmp`, JSON.stringify(data), { mode: 0o600, flush: true })
      renameSync(`${dbPath}.tmp`, dbPath)
    } catch { fail('otp_storage_error') }
  }
  async function locked(phone, action) {
    requireConfig()
    if (typeof phone !== 'string' || !/^[1-9]\d{9,14}$/.test(phone)) fail('invalid_phone', 400)
    const id = hash(`phone:${phone}`)
    if (busy.has(id)) fail('otp_resend_too_soon', 429, 3)
    busy.add(id)
    try { return await action(id) } finally { busy.delete(id) }
  }
  async function request(path, method = 'GET', body, operationId) {
    requireConfig()
    try {
      const response = await fetcher(`${API}${path}`, {
        method, redirect: 'error', signal: AbortSignal.timeout(20_000),
        headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json',
          ...(operationId ? { 'Idempotency-Key': operationId } : {}) },
        ...(body ? { body: JSON.stringify(body) } : {}),
      })
      const data = await response.json()
      return { ok: response.ok, status: response.status, data,
        retry: Math.min(3600, Math.max(1, Number(response.headers.get('Retry-After')) || 60)) }
    } catch { return { ok: false, status: 503, data: {}, retry: 60 } }
  }
  async function readiness() {
    if (now() - health.at < 30_000) return health.ready
    const result = await request('/account/summary').catch(() => null)
    const scopes = result?.data?.scopes || []
    health = { at: now(), ready: result?.ok === true && result.data?.ready === true
      && ['verifications:send', 'verifications:check', 'verifications:read', 'account:read'].every(s => scopes.includes(s)) }
    try { read() } catch { health.ready = false }
    return health.ready
  }
  const fresh = (values, age) => (Array.isArray(values) ? values : []).filter(t => Number.isFinite(t) && t > now() - age)
  function checkBudget(record) {
    record.checks = fresh(record.checks, 15 * MINUTE)
    if (record.checks.length >= 5) fail('otp_attempts_locked', 429, Math.ceil((record.checks[0] + 15 * MINUTE - now()) / 1000))
  }
  async function start(phone) {
    return locked(phone, async id => {
      let record = read()[id] || {}
      checkBudget(record)
      const time = now()
      // A lost response (including the shipped client's automatic retry) must
      // retain the original operation/body. Never generate a fallback send.
      if (record.operationId && record.expiresAt > time && !record.consumed
          && (record.uncertain || time - record.lastSentAt < MINUTE)) {
        if (!record.uncertain) return { mode: 'external', otpExpiresInSeconds: Math.max(1, Math.floor((record.expiresAt - time) / 1000)) }
      } else {
        if (time - Number(record.lastSentAt || 0) < MINUTE) fail('otp_resend_too_soon', 429)
        const sends = fresh(record.sends, HOUR)
        if (sends.length >= 5) fail('otp_send_rate_limited', 429, Math.ceil((sends[0] + HOUR - time) / 1000))
        if (!await readiness()) fail('whatsapp_not_configured')
        const operationId = crypto.randomUUID()
        record = { operationId, createdAt: time, lastSentAt: time, expiresAt: time + 5 * MINUTE,
          sends: [...sends, time], checks: record.checks, uncertain: true, consumed: false,
          // /start is invoked by the existing explicit WhatsApp OTP action.
          // The context is this pre-auth transaction, never a customer token.
          body: { locale: 'ar', purpose: 'authentication',
            consent: { granted: true, occurredAt: new Date(time).toISOString(), reference: `otlobli:login:${operationId}` },
            context: { userSessionId: crypto.randomUUID() } } }
        save(id, record) // durable BEFORE contacting the provider
      }
      const result = await request('/verifications', 'POST', { to: `+${phone}`, ...record.body }, record.operationId)
      if (UUID.test(result.data?.id || '')) record.verificationId = result.data.id
      if (result.ok && result.data?.status === 'pending' && record.verificationId) {
        record.uncertain = false
        save(id, record)
        return { mode: 'external', otpExpiresInSeconds: Math.max(1, Math.floor((record.expiresAt - now()) / 1000)) }
      }
      save(id, record) // retain uncertainty even if provider sent before timing out
      if (result.status === 429) fail('otp_send_rate_limited', 429, result.retry)
      fail('whatsapp_send_error')
    })
  }
  async function verify(phone, code, createSession) {
    return locked(phone, async id => {
      if (typeof code !== 'string' || !/^\d{6}$/.test(code)) fail('invalid_code', 400)
      const record = read()[id]
      if (!record?.verificationId) fail('no_otp', 400)
      if (record.consumed) fail('already_verified', 400)
      if (record.expiresAt <= now()) fail('expired_code', 400)
      const digest = hash(`code:${id}:${record.operationId}:${code}`)
      if (record.approvedHash) {
        const match = crypto.timingSafeEqual(Buffer.from(record.approvedHash), Buffer.from(digest))
        if (!match) {
          checkBudget(record)
          record.checks.push(now()); save(id, record)
          fail('invalid_code', 400)
        }
      } else {
        checkBudget(record)
        // Count before awaiting: failures, lost responses and restarts do not
        // reset the cumulative verification budget.
        record.checks.push(now()); save(id, record)
        const result = await request(`/verifications/${record.verificationId}/check`, 'POST', { code })
        if (!result.ok || result.data?.id !== record.verificationId || result.data?.status !== 'approved') {
          if (result.status === 429 || result.data?.status === 'failed') fail('otp_attempts_locked', 429, result.retry)
          if (result.status === 410) fail('expired_code', 400)
          if (result.status >= 500) fail('verification_error')
          fail('invalid_code', 400)
        }
        record.approvedHash = digest
      }
      record.consumed = true
      save(id, record) // one-time reservation BEFORE customer-session RPC
      try {
        const sessionToken = await createSession(phone)
        return { mode: 'external', sessionToken }
      } catch {
        // Only the exact approved code can retry a failed persistence write.
        record.consumed = false
        save(id, record)
        fail('verification_error')
      }
    })
  }
  return { start, verify, readiness }
}

export const mz3bOtp = createMz3bOtp()

export function respondMz3bError(error, res) {
  const messages = {
    invalid_phone: 'أدخل رقم واتساب صحيح مع رمز الدولة.',
    invalid_code: 'رمز التحقق غير صحيح.',
    no_otp: 'لم يتم إرسال رمز لهذا الرقم بعد.',
    already_verified: 'هذا الرمز استُخدم مسبقًا. أرسل رمزًا جديدًا.',
    expired_code: 'انتهت صلاحية الرمز. أرسل رمزًا جديدًا.',
    otp_resend_too_soon: 'انتظر قليلًا قبل المحاولة مجددًا.',
    otp_send_rate_limited: 'تم طلب رموز كثيرة. حاول لاحقًا.',
    otp_attempts_locked: 'تم إيقاف المحاولات مؤقتًا. حاول لاحقًا.',
    whatsapp_send_error: 'تعذر تأكيد إرسال الرمز. انتظر قليلًا ثم حاول مجددًا.',
    whatsapp_not_configured: 'خدمة واتساب غير جاهزة حاليًا. حاول لاحقًا.',
  }
  const code = Object.hasOwn(messages, error?.code) ? error.code : 'verification_error'
  const status = [400, 429, 503].includes(error?.status) ? error.status : 503
  if (status === 429) res.setHeader('Retry-After', String(error.retryAfterSeconds || 60))
  return res.status(status).json({ error: code, message: messages[code] || 'تعذر إكمال التحقق حاليًا. حاول لاحقًا.' })
}
