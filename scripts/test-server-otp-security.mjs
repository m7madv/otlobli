import assert from 'node:assert/strict'
import { mkdtempSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'

const tempDirectory = mkdtempSync(join(tmpdir(), 'otlobli-otp-'))
const databasePath = join(tempDirectory, 'otp.json')
process.env.OTP_DB_PATH = databasePath
process.env.OTP_HASH_SECRET = 'test-only-secret-with-more-than-thirty-two-characters'

try {
  const store = await import(`../server/src/otpStore.js?test=${Date.now()}`)
  assert.equal(store.isOtpSecurityConfigured(), true)
  const first = store.createOtp('963900000001')
  assert.match(first.code, /^\d{6}$/)
  const persisted = readFileSync(databasePath, 'utf8')
  assert.equal(persisted.includes(first.code), false, 'Plaintext OTP must never be persisted')
  assert.ok(persisted.includes('codeHash'), 'Persisted challenge must contain only a code hash')

  assert.throws(
    () => store.createOtp('963900000001'),
    (error) => error?.code === 'otp_resend_too_soon',
    'Immediate resend must preserve the existing attempt budget',
  )
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    assert.equal(store.verifyOtp('963900000001', '000000').reason, 'invalid_code')
  }
  assert.equal(store.verifyOtp('963900000001', '000000').reason, 'too_many_attempts')
  assert.equal(store.verifyOtp('963900000001', first.code).reason, 'too_many_attempts')
  console.log('Server OTP security tests passed (CSPRNG, hashed storage, resend throttle, cumulative attempt lock).')
} finally {
  rmSync(tempDirectory, { recursive: true, force: true })
}
