import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const adminAuth = await import(`../server/src/adminAuth.js?test=${Date.now()}`)

function invoke(secret, supplied) {
  if (secret === undefined) delete process.env.WHATSAPP_ADMIN_SECRET
  else process.env.WHATSAPP_ADMIN_SECRET = secret

  let statusCode = 200
  let payload = null
  let nextCalled = false
  const headers = supplied === undefined ? {} : { 'x-whatsapp-admin-secret': supplied }
  const req = { headers }
  const res = {
    setHeader() {},
    status(code) { statusCode = code; return this },
    json(value) { payload = value; return this },
  }
  adminAuth.requireWhatsappAdminSecret(req, res, () => { nextCalled = true })
  return { statusCode, payload, nextCalled }
}

const strongSecret = 'test-only-whatsapp-admin-secret-32-bytes-minimum'
assert.deepEqual(invoke(undefined, undefined), {
  statusCode: 503,
  payload: { error: 'whatsapp_admin_not_configured' },
  nextCalled: false,
})
assert.equal(invoke('too-short', 'too-short').statusCode, 503)
assert.equal(invoke(strongSecret, 'wrong-secret').statusCode, 401)
assert.equal(invoke(strongSecret, strongSecret).nextCalled, true)

const routes = readFileSync(resolve(root, 'server/src/routes.js'), 'utf8')
const index = readFileSync(resolve(root, 'server/src/index.js'), 'utf8')
const whatsapp = readFileSync(resolve(root, 'server/src/whatsapp.js'), 'utf8')
const render = readFileSync(resolve(root, 'server/render.yaml'), 'utf8')
const rootRender = readFileSync(resolve(root, 'render.yaml'), 'utf8')
const setup = readFileSync(resolve(root, 'WHATSAPP_SETUP.md'), 'utf8')
const admin = readFileSync(resolve(root, 'admin/src/AdminApp.tsx'), 'utf8')

for (const marker of [
  "router.post('/session/upload', requireWhatsappAdminSecret",
  "router.post('/session/reset', requireWhatsappAdminSecret",
  "router.get('/auth/whatsapp/status', requireWhatsappAdminSecret",
  "router.get('/whatsapp/sessions', requireWhatsappAdminSecret",
  "router.get('/whatsapp/sessions/:id', requireWhatsappAdminSecret",
  "router.post('/whatsapp/sessions', requireWhatsappAdminSecret",
  "router.delete('/whatsapp/sessions/:id', requireWhatsappAdminSecret",
  "router.post('/whatsapp/sessions/:id/reconnect', requireWhatsappAdminSecret",
  "router.get('/qr', requireWhatsappAdminSecret",
]) {
  assert.ok(routes.includes(marker), `Missing WhatsApp admin guard: ${marker}`)
}
assert.ok(index.includes("app.get('/api/qr-url', requireWhatsappAdminSecret"))
assert.ok(index.includes("express.json({ limit: '256kb' })"))
assert.equal(index.includes("limit: '50mb'"), false, 'Public auth parser must not accept legacy archive-sized bodies')
for (const prefix of ['/api/session', '/api/whatsapp/sessions', '/api/auth/whatsapp/status', '/api/qr']) {
  assert.ok(index.includes(`app.use('${prefix}', requireWhatsappAdminSecret)`), `Missing pre-parser guard: ${prefix}`)
}
assert.ok(index.includes('whatsappSenderReady: isWhatsappConnected()'))
assert.ok(index.includes('whatsappCredentialsPresent: hasWhatsappSessionCredentials()'))
assert.equal(index.includes('isWhatsappConnected() || hasWhatsappSessionCredentials()'), false)
assert.ok(routes.includes("error: 'legacy_session_upload_disabled'"))
assert.ok(routes.includes("error: 'global_session_reset_disabled'"))
assert.ok(admin.includes("'x-whatsapp-admin-secret': whatsappAdminSecret"))
assert.ok(admin.includes('يبقى في الذاكرة لهذه الصفحة فقط ولا يُحفظ في المتصفح'))
assert.equal(/api\.qrserver\.com/.test(`${index}\n${routes}\n${whatsapp}`), false)
assert.equal(/qrCode:\s*s\.qrCode/.test(whatsapp), false, 'Raw QR must not be serialized')
assert.ok(whatsapp.includes('QRCode.toDataURL(qrCode'), 'QR image must be generated locally')
assert.equal(/ADMIN_PIN[\s\S]{0,80}value\s*:/.test(render), false, 'Render must not track an admin PIN')
assert.ok(render.includes('key: WHATSAPP_ADMIN_SECRET'))
assert.ok(render.includes('sync: false'))
assert.ok(rootRender.includes('rootDir: server'))
assert.equal(rootRender.includes('rootDir: server-whatsapp'), false, 'Root deployment must not revive retired phone server')
assert.ok(rootRender.includes('key: WHATSAPP_ADMIN_SECRET'))
assert.ok(setup.includes('VITE_WHATSAPP_AUTH_MODE=real'))
assert.ok(setup.includes('20260821193000_harden_identity_rpc_permissions.sql'))
assert.ok(setup.includes('"authContract": "customer-session-v1"'))
assert.ok(setup.includes('inbound` is intentionally unavailable'))

console.log('WhatsApp admin security tests passed (fail-closed secret, protected lifecycle routes, local-only QR).')
