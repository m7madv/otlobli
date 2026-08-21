import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { runInNewContext } from 'node:vm'
import ts from 'typescript'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const source = readFileSync(resolve(root, 'src/services/pushPayload.ts'), 'utf8')
const compiled = ts.transpileModule(source, {
  compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
}).outputText
const module = { exports: {} }
runInNewContext(`(function(exports,module){${compiled}\n})(module.exports,module)`, { module, exports: module.exports })
const { parseSafePushPayload } = module.exports

assert.equal(JSON.stringify(
  parseSafePushPayload({ version: 1, type: 'order_update', route: 'orders/details', entityId: 'ORD-42' }),
), JSON.stringify({ screen: 'tracking', entityId: 'ORD-42' }))
assert.equal(JSON.stringify(parseSafePushPayload({ version: 1, type: 'wallet_update', route: 'wallet' })), JSON.stringify({ screen: 'payment-methods' }))
assert.equal(JSON.stringify(parseSafePushPayload({ version: 1, type: 'system', route: 'notifications' })), JSON.stringify({ screen: 'notifications' }))
assert.equal(parseSafePushPayload({ version: 2, route: 'orders' }), null)
assert.equal(parseSafePushPayload({ version: 1, route: 'https://evil.example/' }), null)
assert.equal(parseSafePushPayload({ version: 1, route: 'orders/details' }), null)
assert.equal(parseSafePushPayload({ version: 1, route: 'orders/details', entityId: 'x'.repeat(129) }), null)

const google = readFileSync(resolve(root, 'supabase/functions/google-auth/index.ts'), 'utf8')
for (const marker of ['accounts.google.com', 'ALLOWED_AUDS.includes', 'exp * 1000 <= Date.now()', 'claims.sub']) {
  assert.ok(google.includes(marker), `Google verifier missing ${marker}`)
}
const apple = readFileSync(resolve(root, 'supabase/functions/apple-auth/index.ts'), 'utf8')
for (const marker of ['createRemoteJWKSet', "issuer: 'https://appleid.apple.com'", 'audience: ALLOWED_AUDS', 'claims.nonce !== nonce', 'exchangeAuthorizationCode', 'apple_authorizations']) {
  assert.ok(apple.includes(marker), `Apple verifier missing ${marker}`)
}
const lifecycle = readFileSync(resolve(root, 'supabase/functions/account-lifecycle/index.ts'), 'utf8')
for (const marker of ['appleid.apple.com/auth/revoke', 'token_type_hint', 'get_customer_id_for_session', 'delete_customer_account', 'for (const authorization of appleAuthorizations']) {
  assert.ok(lifecycle.includes(marker), `Account lifecycle missing ${marker}`)
}
const push = readFileSync(resolve(root, 'supabase/functions/send-push/index.ts'), 'utf8')
for (const marker of ['allowedTypes', 'allowedRoutes', "return json({ error: 'invalid_payload' }, 400)", 'x-push-secret']) {
  assert.ok(push.includes(marker), `Push sender missing ${marker}`)
}
const pushClient = readFileSync(resolve(root, 'src/services/pushNotifications.ts'), 'utf8')
for (const marker of ['getPushContext', 'p_environment: pushContext.environment', 'detach_device_token']) {
  assert.ok(pushClient.includes(marker), `Push client missing ${marker}`)
}
const rotationHandler = pushClient.slice(pushClient.indexOf('async function onRegistration'), pushClient.indexOf('async function installListeners'))
assert.ok(
  rotationHandler.indexOf('latestDeviceToken = token') < rotationHandler.indexOf('if (!activeSessionToken || !activePlatform) return'),
  'Push rotation must be retained even while logged out',
)
const migration = readFileSync(resolve(root, 'supabase/migrations/20260821090000_production_auth_push.sql'), 'utf8')
for (const marker of ['pg_advisory_xact_lock', 'delete from public.apple_authorizations', 'upsert_device_token_v2']) {
  assert.ok(migration.includes(marker), `Production migration missing ${marker}`)
}

console.log('Release service tests passed (payload allowlist + Google/Apple verification guards).')
