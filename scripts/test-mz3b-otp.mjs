import assert from 'node:assert/strict'
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createMz3bOtp } from '../server/src/mz3bOtp.js'

// Isolated provider doubles only: this suite never contacts MZ3B or Supabase.
const dir = mkdtempSync(join(tmpdir(), 'otlobli-mz3b-'))
const phone = '963900000001'
const other = '963900000002'
const verificationId = '11111111-1111-4111-8111-111111111111'
const secret = 'test-only-otp-hmac-secret-at-least-32-characters'
let sequence = 0
function fixture() {
  let time = Date.parse('2026-09-07T12:00:00Z')
  let sending = () => ({ status: 'pending', id: verificationId, expiresIn: 300 })
  let checking = () => ({ status: 'approved', id: verificationId })
  const calls = []
  const dbPath = join(dir, `${++sequence}.json`)
  const fetcher = async (url, options) => {
    assert.equal(options.redirect, 'error')
    assert.ok(options.signal)
    const body = options.body ? JSON.parse(options.body) : undefined
    calls.push({ url, body, operation: options.headers['Idempotency-Key'] })
    const data = url.endsWith('/summary')
      ? { ready: true, scopes: ['verifications:send', 'verifications:check', 'verifications:read', 'account:read'] }
      : url.endsWith('/check') ? await checking() : await sending()
    return new Response(JSON.stringify(data.body || data), { status: data.http || 200 })
  }
  const config = { key: 'test-provider-key-not-a-real-credential', secret, dbPath, fetcher, now: () => time }
  return { service: createMz3bOtp(config), restart: () => createMz3bOtp(config), calls, dbPath,
    advance: value => { time += value }, send: fn => { sending = fn }, check: fn => { checking = fn } }
}
const rejectsCode = (promise, code) => assert.rejects(promise, error => error.code === code)
try {
  const f = fixture()
  assert.equal(await f.service.readiness(), true)
  assert.deepEqual(await f.service.start(phone), { mode: 'external', otpExpiresInSeconds: 300 })
  const send = f.calls.find(x => x.url.endsWith('/verifications'))
  assert.equal(send.body.to, `+${phone}`)
  assert.equal(send.body.consent.granted, true)
  assert.match(send.operation, /^[0-9a-f-]{36}$/)
  const persisted = readFileSync(f.dbPath, 'utf8')
  assert.equal(persisted.includes(phone), false)
  assert.equal(persisted.includes('test-provider-key'), false)
  await f.restart().start(phone)
  assert.equal(f.calls.filter(x => x.url.endsWith('/verifications')).length, 1, 'client retry reuses accepted attempt')
  let sessions = 0
  const createSession = async value => { assert.equal(value, phone); sessions++; return 'fake-session-token' }
  const verified = await f.service.verify(phone, '123456', createSession)
  assert.equal(verified.sessionToken, 'fake-session-token')
  assert.equal(sessions, 1)
  assert.equal(readFileSync(f.dbPath, 'utf8').includes('123456'), false)
  assert.equal(readFileSync(f.dbPath, 'utf8').includes('fake-session-token'), false)
  await rejectsCode(f.restart().verify(phone, '123456', createSession), 'already_verified')
  await rejectsCode(f.service.verify(other, '123456', createSession), 'no_otp')
  assert.equal(sessions, 1)

  const lost = fixture()
  lost.send(() => { throw new Error('network response lost') })
  await rejectsCode(lost.service.start(phone), 'whatsapp_send_error')
  const original = lost.calls.at(-1)
  lost.advance(65_000)
  lost.send(() => ({ status: 'pending', id: verificationId }))
  await lost.restart().start(phone)
  assert.deepEqual(lost.calls.at(-1), original, 'persisted operation/body/consent survive restart and timeout')

  const invalid = fixture()
  invalid.check(() => ({ status: 'pending', id: verificationId }))
  await invalid.service.start(phone)
  for (let i = 0; i < 5; i++) await rejectsCode(invalid.service.verify(phone, '000000', createSession), 'invalid_code')
  await rejectsCode(invalid.restart().verify(phone, '123456', createSession), 'otp_attempts_locked')
  invalid.advance(61_000)
  await rejectsCode(invalid.service.start(phone), 'otp_attempts_locked')
  assert.equal(sessions, 1, 'HTTP200 pending is never authentication')

  const failed = fixture()
  failed.check(() => ({ status: 'failed', id: verificationId }))
  await failed.service.start(phone)
  await rejectsCode(failed.service.verify(phone, '123456', createSession), 'otp_attempts_locked')
  const wrongId = fixture()
  wrongId.check(() => ({ status: 'approved', id: '22222222-2222-4222-8222-222222222222' }))
  await wrongId.service.start(phone)
  await rejectsCode(wrongId.service.verify(phone, '123456', createSession), 'invalid_code')

  const dbFailure = fixture()
  await dbFailure.service.start(phone)
  await rejectsCode(dbFailure.service.verify(phone, '123456', async () => { throw new Error('database unavailable') }), 'verification_error')
  const checksBefore = dbFailure.calls.filter(x => x.url.endsWith('/check')).length
  await rejectsCode(dbFailure.restart().verify(phone, '654321', createSession), 'invalid_code')
  await dbFailure.restart().verify(phone, '123456', createSession)
  assert.equal(dbFailure.calls.filter(x => x.url.endsWith('/check')).length, checksBefore, 'only exact approved hash recovers persistence failure')

  const fifth = fixture()
  await fifth.service.start(phone)
  fifth.check(() => ({ status: 'pending', id: verificationId }))
  for (let i = 0; i < 4; i++) await rejectsCode(fifth.service.verify(phone, '000000', createSession), 'invalid_code')
  fifth.check(() => ({ status: 'approved', id: verificationId }))
  await rejectsCode(fifth.service.verify(phone, '123456', async () => { throw new Error('RPC failed') }), 'verification_error')
  assert.ok((await fifth.restart().verify(phone, '123456', createSession)).sessionToken, 'exact approved fifth attempt can recover failed RPC without another guess')

  const cumulative = fixture()
  await cumulative.service.start(phone)
  cumulative.check(() => ({ status: 'pending', id: verificationId }))
  for (let i = 0; i < 3; i++) await rejectsCode(cumulative.service.verify(phone, '000000', createSession), 'invalid_code')
  cumulative.advance(61_000)
  await cumulative.service.start(phone)
  for (let i = 0; i < 2; i++) await rejectsCode(cumulative.service.verify(phone, '000000', createSession), 'invalid_code')
  await rejectsCode(cumulative.restart().verify(phone, '123456', createSession), 'otp_attempts_locked')

  const expired = fixture()
  await expired.service.start(phone)
  expired.advance(301_000)
  await rejectsCode(expired.service.verify(phone, '123456', createSession), 'expired_code')

  const rate = fixture()
  for (let i = 0; i < 5; i++) { await rate.service.start(phone); rate.advance(61_000) }
  await rejectsCode(rate.restart().start(phone), 'otp_send_rate_limited')

  const racing = fixture()
  let unblock
  racing.send(() => new Promise(resolve => { unblock = resolve }))
  const first = racing.service.start(phone)
  // Let the readiness fetch and persistent write finish; no actual network.
  while (!unblock) await new Promise(resolve => setImmediate(resolve))
  await rejectsCode(racing.service.start(phone), 'otp_resend_too_soon')
  unblock({ status: 'pending', id: verificationId })
  await first
  let unblockSession
  const firstVerify = racing.service.verify(phone, '123456', () => new Promise(resolve => { unblockSession = resolve }))
  while (!unblockSession) await new Promise(resolve => setImmediate(resolve))
  await rejectsCode(racing.service.verify(phone, '123456', createSession), 'otp_resend_too_soon')
  await rejectsCode(racing.service.start(phone), 'otp_resend_too_soon')
  unblockSession('fake-session')
  await firstVerify

  const corrupt = fixture()
  writeFileSync(corrupt.dbPath, '{truncated')
  await rejectsCode(corrupt.service.start(phone), 'otp_storage_error')
  assert.equal(corrupt.calls.length, 0)
  await rejectsCode(createMz3bOtp({ key: '', secret }).start(phone), 'otp_not_configured')
  for (const value of [null, [], '123', '0' + phone, phone + '/check']) {
    await rejectsCode(f.service.start(value), 'invalid_phone')
  }
  console.log('MZ3B adapter tests passed: readiness, unchanged client contract, privacy, restart/idempotency, rate limits, failed/expired/wrong-id codes, one-time sessions, persistence recovery and concurrency. No live messages sent.')
} finally {
  // Only the exact temporary directory created by this isolated test.
  rmSync(dir, { recursive: true, force: true })
}
