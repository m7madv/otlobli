import assert from 'node:assert/strict'
import { createRequire } from 'node:module'
import { mkdtempSync, rmSync } from 'node:fs'
import { join } from 'node:path'
import { tmpdir } from 'node:os'

const dir = mkdtempSync(join(tmpdir(), 'otlobli-mz3b-http-'))
Object.assign(process.env, {
  WHATSAPP_OTP_PROVIDER: 'mz3b', MZ3B_API_KEY: 'isolated-http-test-key',
  OTP_HASH_SECRET: 'isolated-http-test-secret-at-least-32-characters',
  MZ3B_OTP_DB_PATH: join(dir, 'provider.json'), OTP_DB_PATH: join(dir, 'legacy.json'),
  SUPABASE_URL: 'https://isolated-supabase.invalid', SUPABASE_SERVICE_ROLE_KEY: 'isolated-test-only',
})
const nativeFetch = globalThis.fetch
const id = '33333333-3333-4333-8333-333333333333'
let sends = 0
let sessions = 0
let server
globalThis.fetch = async (url, options) => {
  assert.ok(String(url).startsWith('https://mz3b.com/api/v1/'), 'test must not contact an external service')
  let body
  if (url.endsWith('/summary')) body = { ready: true, scopes: ['verifications:send', 'verifications:check', 'verifications:read', 'account:read'] }
  else if (url.endsWith('/check')) body = { id, status: JSON.parse(options.body).code === '123456' ? 'approved' : 'pending' }
  else { sends++; body = { id, status: 'pending', expiresIn: 300 } }
  return new Response(JSON.stringify(body))
}
try {
  const require = createRequire(new URL('../server/package.json', import.meta.url))
  const express = require('express')
  const { supabase } = await import('../server/src/supabase.js')
  supabase.rpc = async (name, params) => {
    assert.equal(name, 'create_customer_session')
    assert.equal(params.p_phone, '963900000001')
    assert.match(params.p_token_hash, /^[a-f0-9]{64}$/)
    sessions++
    return { error: null }
  }
  const { default: routes } = await import('../server/src/routes.js')
  const app = express()
  app.use(express.json())
  app.use('/api', routes)
  server = await new Promise(resolve => { const s = app.listen(0, '127.0.0.1', () => resolve(s)) })
  const base = `http://127.0.0.1:${server.address().port}/api/auth/whatsapp`
  const post = async (route, body) => {
    const res = await nativeFetch(`${base}/${route}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) })
    return { status: res.status, body: await res.json() }
  }
  assert.equal((await post('start', { phone: {} })).status, 400)
  assert.equal(sends, 0)
  const start = await post('start', { phone: '+963 900000001' })
  assert.equal(start.status, 200)
  assert.equal(start.body.mode, 'external')
  assert.ok(start.body.otpExpiresInSeconds <= 300)
  await post('start', { phone: '963900000001' })
  assert.equal(sends, 1)
  assert.equal((await post('verify', { phone: '963900000001', code: '654321' })).status, 400)
  assert.equal(sessions, 0)
  const verify = await post('verify', { phone: '963900000001', code: '123456' })
  assert.equal(verify.status, 200)
  assert.equal(verify.body.mode, 'external')
  assert.match(verify.body.sessionToken, /^[A-Za-z0-9_-]{43}$/)
  assert.equal(sessions, 1)
  assert.equal((await post('verify', { phone: '963900000001', code: '123456' })).status, 400)
  assert.equal(sessions, 1)
  console.log('MZ3B HTTP contract passed: existing start/verify routes, formatting, invalid inputs/codes, one send on retry, hashed session RPC and replay rejection. Providers mocked; no live messages or sessions.')
} finally {
  globalThis.fetch = nativeFetch
  if (server) await new Promise(resolve => server.close(resolve))
  rmSync(dir, { recursive: true, force: true })
}
