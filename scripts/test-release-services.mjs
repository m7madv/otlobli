import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { runInNewContext } from 'node:vm'
import ts from 'typescript'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const loadTypeScriptModule = (relativePath) => {
  const source = readFileSync(resolve(root, relativePath), 'utf8')
  const compiled = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText
  const module = { exports: {} }
  runInNewContext(`(function(exports,module){${compiled}\n})(module.exports,module)`, {
    module, exports: module.exports, URL, Set, Date, Math,
  })
  return module.exports
}

const { parseSafePushPayload } = loadTypeScriptModule('src/services/pushPayload.ts')

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
for (const marker of [
  'accounts.google.com', 'ALLOWED_AUDS.includes', 'exp * 1000 <= Date.now()', 'claims.sub',
  "body.action === 'configuration-check'", 'configured: ALLOWED_AUDS.includes(clientId)',
  "supabase.rpc('auth_schema_readiness')", "schema.version === 'auth-v86.212-1'",
]) {
  assert.ok(google.includes(marker), `Google verifier missing ${marker}`)
}
const apple = readFileSync(resolve(root, 'supabase/functions/apple-auth/index.ts'), 'utf8')
for (const marker of [
  'createRemoteJWKSet', "issuer: 'https://appleid.apple.com'", 'audience: expectedClientId ?? ALLOWED_AUDS',
  'claims.nonce !== nonce', 'APPLE_REDIRECT_URIS_JSON', 'parameters.redirect_uri = redirectUri',
  'exchangedToken.claims.sub !== verifiedToken.claims.sub', 'client_id: appleClientId',
  '.eq(\'client_id\', appleClientId)', "onConflict: 'provider_user_id,client_id'", 'idToken,',
  "body.action === 'configuration-check'",
  'const signingReady = ALLOWED_AUD_SET.has(clientId) && redirect.valid',
  'await appleClientSecret(clientId)', 'PENDING_AUTHORIZATION_TTL_MS',
  "body.action === 'cancel-registration'", "gt('pending_expires_at'",
  'cleanupExpiredPendingAuthorizations',
  "supabase.rpc('auth_schema_readiness')", "schema.version === 'auth-v86.212-1'",
]) {
  assert.ok(apple.includes(marker), `Apple verifier missing ${marker}`)
}
const appleHandler = apple.slice(apple.indexOf('Deno.serve(async (req) =>'))
const suppliedTokenBranch = appleHandler.slice(
  appleHandler.indexOf('if (idToken) {'),
  appleHandler.indexOf('} else {\n    if (!authorizationCode'),
)
assert.ok(
  suppliedTokenBranch.indexOf('verifyAppleIdToken(idToken, rawNonce)') <
    suppliedTokenBranch.indexOf('exchangeAuthorizationCode(authorizationCode, verifiedToken.clientId'),
  'Apple native flow must verify its supplied token before selecting a client for code exchange',
)
const codeOnlyBranch = appleHandler.slice(appleHandler.indexOf('} else {\n    if (!authorizationCode'))
assert.ok(
  codeOnlyBranch.indexOf('ALLOWED_AUD_SET.has(requestedClientId)') <
    codeOnlyBranch.indexOf('exchangeAuthorizationCode(authorizationCode, requestedClientId'),
  'Apple code-only flow must reject clients outside APPLE_CLIENT_IDS before exchange',
)
assert.ok(
  codeOnlyBranch.indexOf('exchangeAuthorizationCode(authorizationCode, requestedClientId') <
    codeOnlyBranch.indexOf('verifyAppleIdToken(exchange.idToken, rawNonce, requestedClientId)') &&
    codeOnlyBranch.indexOf('verifyAppleIdToken(exchange.idToken, rawNonce, requestedClientId)') <
      codeOnlyBranch.indexOf('const claims = verifiedToken.claims'),
  'Apple code-only flow must treat the exchanged verified ID token as authoritative before account access',
)
assert.equal(/console\.(?:log|info|warn|error|debug)/.test(apple), false, 'Apple auth must not log credentials or secrets')
assert.equal(apple.includes(".eq('refresh_token'"), false, 'Apple refresh tokens must never enter PostgREST filter URLs')
const appleCallback = readFileSync(resolve(root, 'supabase/functions/apple-oauth-callback/index.ts'), 'utf8')
for (const marker of [
  "const APP_CALLBACK = 'otlobli://apple-auth'", "success: 'true'", "'Cache-Control': 'no-store, max-age=0'",
  'safeState(state)', "contentType.startsWith('application/x-www-form-urlencoded')",
]) {
  assert.ok(appleCallback.includes(marker), `Apple callback missing ${marker}`)
}
for (const forbidden of ['client_secret', 'access_token', 'refresh_token', 'id_token']) {
  assert.equal(appleCallback.includes(forbidden), false, `Apple callback must not forward ${forbidden}`)
}
const lifecycle = readFileSync(resolve(root, 'supabase/functions/account-lifecycle/index.ts'), 'utf8')
for (const marker of [
  'appleid.apple.com/auth/revoke', 'token_type_hint', 'resolve_customer_for_account_deletion', 'delete_customer_account',
  'for (const authorization of appleAuthorizations', "select('refresh_token,client_id')", 'client_id: clientId',
  "payload.error === 'invalid_grant' || payload.error === 'invalid_token'",
]) {
  assert.ok(lifecycle.includes(marker), `Account lifecycle missing ${marker}`)
}
const push = readFileSync(resolve(root, 'supabase/functions/send-push/index.ts'), 'utf8')
for (const marker of [
  'allowedTypes', 'allowedRoutes', "return json({ error: 'invalid_payload' }, 400)", 'x-push-secret',
  "const APNS_TOPIC = 'com.otlobli.app'", "'apns-expiration': expiration", "'apns-push-type': 'alert'",
  "'apns-priority': '10'", 'DeviceTokenNotForTopic', 'retryStatuses', 'attempt < 3',
  "supabase.rpc('disable_device_token'", 'retryable', 'requestId',
]) {
  assert.ok(push.includes(marker), `Push sender missing ${marker}`)
}
assert.ok(!push.includes("console.error('FCM send failed', res.status, errText)"), 'Push provider errors must not log raw bodies')
const pushClient = readFileSync(resolve(root, 'src/services/pushNotifications.ts'), 'utf8')
for (const marker of ['getPushContext', 'p_environment: pushContext.environment', 'detach_device_token', 'pendingLaunchDestination', 'queueMicrotask']) {
  assert.ok(pushClient.includes(marker), `Push client missing ${marker}`)
}
const rotationHandler = pushClient.slice(pushClient.indexOf('async function onRegistration'), pushClient.indexOf('async function installListeners'))
assert.ok(
  rotationHandler.indexOf('latestDeviceToken = token') < rotationHandler.indexOf('if (!activeSessionToken || !activePlatform) return'),
  'Push rotation must be retained even while logged out',
)
const detachHandler = pushClient.slice(pushClient.indexOf('export async function detachPushToken'), pushClient.indexOf('export async function openPushSettings'))
assert.ok(
  detachHandler.indexOf("activeSessionToken = ''") < detachHandler.indexOf("supabase.rpc('detach_device_token'"),
  'Logout must stop token ownership before the network detach can fail',
)
const migration = readFileSync(resolve(root, 'supabase/migrations/20260821090000_production_auth_push.sql'), 'utf8')
for (const marker of ['pg_advisory_xact_lock', 'delete from public.apple_authorizations', 'upsert_device_token_v2']) {
  assert.ok(migration.includes(marker), `Production migration missing ${marker}`)
}
const appleClientMigration = readFileSync(resolve(root, 'supabase/migrations/20260821183000_apple_authorization_client_id.sql'), 'utf8')
for (const marker of [
  "set client_id = 'com.otlobli.app'", 'alter column client_id set not null',
  'primary key (provider_user_id, client_id)', 'apple_authorizations_client_id_nonempty',
  'pending_expires_at', 'apple_authorizations_pending_expiry',
]) {
  assert.ok(appleClientMigration.includes(marker), `Apple client migration missing ${marker}`)
}
const authPermissionMigration = readFileSync(resolve(root, 'supabase/migrations/20260821193000_harden_identity_rpc_permissions.sql'), 'utf8')
for (const marker of [
  'create_customer_session_for_customer', 'find_identity_customer', 'touch_identity_login',
  'phone_auth_readiness', "'contract', 'customer-session-v1'",
  'auth_schema_readiness', "'version', 'auth-v86.212-1'",
  'revoke all on function public.link_customer_identity',
  'revoke all on function public.delete_customer_account',
  "'customer_identity:' || p_provider || ':' || p_provider_user_id",
  'existing_customer_id is distinct from session_customer_id',
  'from public, anon, authenticated', 'to service_role',
  'resolve_customer_for_account_deletion',
]) {
  assert.ok(authPermissionMigration.includes(marker), `Identity permission migration missing ${marker}`)
}
const retiredAuthMigration = readFileSync(resolve(root, 'supabase/migrations_v86_auth_push.sql'), 'utf8')
assert.ok(
  retiredAuthMigration.includes('is retired; deploy timestamped migrations instead') &&
    !retiredAuthMigration.includes('grant execute on function public.link_customer_identity'),
  'Historical auth migration must fail closed instead of reopening privileged RPCs',
)
const supabaseConfig = readFileSync(resolve(root, 'supabase/config.toml'), 'utf8')
assert.ok(
  supabaseConfig.includes('[functions.apple-oauth-callback]') && supabaseConfig.includes('verify_jwt = false'),
  'Apple OAuth callback must be reproducibly deployed without JWT verification',
)
const whatsappServer = readFileSync(resolve(root, 'server/src/index.js'), 'utf8')
for (const marker of ["supabase.rpc('phone_auth_readiness')", 'sessionStoreReady', 'authContract', 'whatsappSenderReady']) {
  assert.ok(whatsappServer.includes(marker), `WhatsApp health contract missing ${marker}`)
}
const whatsappSender = readFileSync(resolve(root, 'server/src/whatsapp.js'), 'utf8')
const otpSender = whatsappSender.slice(
  whatsappSender.indexOf('export async function sendOtpMessage'),
  whatsappSender.indexOf('export async function sendNotificationMessage'),
)
assert.equal(otpSender.includes('OTP ${code}'), false, 'WhatsApp sender must not log plaintext OTP values')
assert.equal(otpSender.includes('${phone}'), false, 'WhatsApp sender must not log OTP recipient phone numbers')
const socialLoginPatch = readFileSync(resolve(root, 'patches/@capgo+capacitor-social-login+8.3.38.patch'), 'utf8')
assert.ok(socialLoginPatch.includes('-        call.setKeepAlive(true);'), 'Android Apple calls must not remain kept alive after completion')
assert.ok(
  socialLoginPatch.includes('-            Log.i(SocialLoginPlugin.LOG_TAG, String.format("Google restoreState: %s", object));'),
  'Android Google restore must not log stored ID/access tokens',
)

const policy = loadTypeScriptModule('src/services/sheinPolicyEngine.ts')
const routeCases = [
  ['https://m.shein.com/ar/', 'home'],
  ['https://m.shein.com/ar/category/Women-sc-00828516.html', 'category'],
  ['https://m.shein.com/ar/search?search=dress', 'search'],
  ['https://m.shein.com/ar/Solid-Dress-p-123456.html', 'product'],
  ['https://m.shein.com/user/login', 'blocked-login'],
  ['https://m.shein.com/user/register', 'blocked-signup'],
  ['https://m.shein.com/user/profile', 'blocked-account'],
  ['https://m.shein.com/country', 'blocked-country'],
  ['https://m.shein.com/region', 'blocked-region'],
  ['https://m.shein.com/currency', 'blocked-currency'],
  ['https://m.shein.com/language', 'blocked-language'],
  ['https://m.shein.com/cart', 'blocked-checkout'],
  ['https://m.shein.com/captcha/verify', 'human-verification'],
]
for (const [url, expected] of routeCases) {
  assert.equal(policy.classifySheinRoute(url), expected, `Unexpected SHEIN route policy for ${url}`)
}
assert.equal(policy.isBlockedSheinRoute('human-verification'), false)
assert.equal(policy.isBlockedSheinRoute('product'), false)
const policyScript = policy.SHEIN_POLICY_DOCUMENT_START_SCRIPT
assert.equal((policyScript.match(/new MutationObserver/g) ?? []).length, 1, 'Policy must own one observer')
for (const forbidden of ["addEventListener('click'", "addEventListener('pointer", 'preventDefault(', 'window.fetch=', 'XMLHttpRequest.prototype', 'console.error=', 'history.pushState']) {
  assert.ok(!policyScript.includes(forbidden), `Policy contains forbidden global interception: ${forbidden}`)
}
for (const required of ['installCount:1', 'MAX_ROOTS=96', 'MAX_NODES_PER_ROOT=320', 'data-otlobli-capture-owned', 'human-verification', 'duplicate-install']) {
  assert.ok(policyScript.includes(required), `Policy missing bounded/idempotent marker: ${required}`)
}

const coordinator = loadTypeScriptModule('src/services/sheinRegionCoordinator.ts')
const requiredRegion = { countryCode: 'sa', currency: 'usd', language: 'AR' }
let state = coordinator.createSheinRegionCoordinator(requiredRegion)
state = coordinator.transitionSheinRegionCoordinator(state, { type: 'OPEN', required: requiredRegion })
state = coordinator.transitionSheinRegionCoordinator(state, { type: 'POLICY_INSTALLING' })
state = coordinator.transitionSheinRegionCoordinator(state, { type: 'SNAPSHOT', snapshot: {
  countryState: 'matching', regionState: 'matching', currencyState: 'matching', languageState: 'matching',
  loginState: 'not-required', humanVerificationState: 'none', policyState: 'verified', captureState: 'ready', interactive: true,
} })
assert.equal(state.phase, 'READY')
assert.equal(coordinator.isSheinCoordinatorVisuallyReady(state), true)
assert.deepEqual(JSON.parse(JSON.stringify(state.required)), { countryCode: 'SA', currency: 'USD', language: 'ar' })

const browseReady = {
  ...state,
  phase: 'VERIFYING',
  countryState: 'unknown',
  regionState: 'unknown',
}
assert.equal(coordinator.isSheinCoordinatorReady(browseReady), false, 'Signed region is still required for transaction readiness')
assert.equal(coordinator.isSheinCoordinatorVisuallyReady(browseReady), true, 'Safe localized browsing should not wait for the signed region cascade')
assert.equal(coordinator.isSheinCoordinatorVisuallyReady({ ...browseReady, currencyState: 'mismatch' }), false)
assert.equal(coordinator.isSheinCoordinatorVisuallyReady({ ...browseReady, humanVerificationState: 'required' }), false)

let mismatch = coordinator.createSheinRegionCoordinator(requiredRegion)
mismatch = coordinator.transitionSheinRegionCoordinator(mismatch, { type: 'OPEN', required: requiredRegion })
mismatch = coordinator.transitionSheinRegionCoordinator(mismatch, { type: 'SNAPSHOT', snapshot: { currencyState: 'mismatch' } })
assert.equal(mismatch.phase, 'FAILED')
assert.equal(mismatch.countryState, 'unknown', 'Coordinator fields must remain independent')

let repair = coordinator.createSheinRegionCoordinator(requiredRegion)
repair = coordinator.transitionSheinRegionCoordinator(repair, { type: 'OPEN', required: requiredRegion })
repair = coordinator.transitionSheinRegionCoordinator(repair, { type: 'REPAIR_REQUIRED', code: 'first' })
assert.equal(repair.phase, 'REPAIRING_ONCE')
assert.equal(repair.repairCount, 1)
repair = coordinator.transitionSheinRegionCoordinator(repair, { type: 'REPAIR_REQUIRED', code: 'second' })
assert.equal(repair.phase, 'FAILED')

let challenge = coordinator.createSheinRegionCoordinator(requiredRegion)
challenge = coordinator.transitionSheinRegionCoordinator(challenge, { type: 'OPEN', required: requiredRegion })
challenge = coordinator.transitionSheinRegionCoordinator(challenge, { type: 'HUMAN_VERIFICATION_REQUIRED' })
assert.equal(challenge.phase, 'HUMAN_VERIFICATION')
assert.equal(challenge.humanVerificationState, 'required')

const opening = loadTypeScriptModule('src/services/sheinOpeningPerformance.ts')
let trace = opening.createSheinOpeningTrace(1000)
trace = opening.markSheinOpeningPhase(trace, 'browserOpenRequested', 1100)
trace = opening.markSheinOpeningPhase(trace, 'storeVisibleInteractive', 2500)
const record = opening.completeSheinOpeningTrace(trace)
assert.equal(record.totalMs, 1500)
assert.deepEqual(JSON.parse(JSON.stringify(opening.summarizeSheinOpeningRecords([
  { ...record, totalMs: 1000 }, { ...record, totalMs: 2000 }, { ...record, totalMs: 3000 },
]))), { samples: 3, medianMs: 2000, p95Ms: 3000, slowestMs: 3000 })

const protectedHashes = new Map([
  ['src/services/sheinBrowserScript.ts', '332BD28F21817A40FCEE982580F0EF118BB59A1E297E2FE4104BF7002872D2DB'],
  ['src/services/storeProductCaptureScript.ts', 'BD3766735D978D6E1D6DCDA72F55E85592B006E10A5C326CE4177C214D7183B5'],
  ['src/services/sheinSkuTap.ts', '79A1011CF55344D06BFCFC796FCAEB5CFF58F705F7FD95BA1686D69D802DEE83'],
])
for (const [file, expected] of protectedHashes) {
  const actual = createHash('sha256').update(readFileSync(resolve(root, file))).digest('hex').toUpperCase()
  assert.equal(actual, expected, `Product-capture regression: ${file}`)
}

const nativeBrowser = readFileSync(resolve(root, 'ios/App/App/OtlobliSheinBrowserPlugin.swift'), 'utf8')
const nativeBack = nativeBrowser.slice(nativeBrowser.indexOf('@objc private func nativeBackPressed()'), nativeBrowser.indexOf('private func mobileBridgeScript()'))
assert.ok(nativeBack.indexOf('if isCanonicalSheinHomeURL(webView.url)') < nativeBack.indexOf('if webView.canGoBack'), 'Root Back must exit before WebKit history')
assert.ok(nativeBack.includes('webView.goBack()'), 'Product/category Back must retain WebKit history')

console.log('Release service tests passed (policy, region, opening, capture hashes, push, auth and deletion guards).')
