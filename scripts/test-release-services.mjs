import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { runInNewContext } from 'node:vm'
import ts from 'typescript'
import { evaluateInjectedScriptExports } from './minify-injected-scripts.mjs'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const loadTypeScriptModule = (relativePath) => {
  const source = readFileSync(resolve(root, relativePath), 'utf8')
  const compiled = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText
  const module = { exports: {} }
  runInNewContext(`(function(exports,module){${compiled}\n})(module.exports,module)`, {
    module, exports: module.exports, URL, Set, Date, Math, atob, TextDecoder, Uint8Array,
  })
  return module.exports
}

const { parseSafePushPayload } = loadTypeScriptModule('src/services/pushPayload.ts')
const storeRouting = loadTypeScriptModule('src/domain/storeRouting.ts')
const { TEMU_DOCUMENT_START_SCRIPT } = loadTypeScriptModule('src/services/temuDocumentStartScript.ts')
const { TEMU_DOCUMENT_START_CSS } = loadTypeScriptModule('src/services/temuDocumentStartScript.ts')

assert.doesNotThrow(
  () => new Function(TEMU_DOCUMENT_START_SCRIPT),
  'Temu document-start policy is not valid emitted JavaScript',
)
for (const forbidden of [
  'MutationObserver', 'setInterval(', "querySelectorAll('*')", 'visualViewport', 'globalThis',
  "var controls = document.querySelectorAll('button,[role=\"button\"],a",
]) {
  assert.equal(
    TEMU_DOCUMENT_START_SCRIPT.includes(forbidden),
    false,
    `Temu document-start policy contains forbidden hot-path work: ${forbidden}`,
  )
}
for (const skuBreakingSelector of [
  'button[aria-label*="add to cart" i]',
  '[role="button"][aria-label*="add to cart" i]',
  'button[class*="addToCart" i]',
  'button[class*="buyNow" i]',
]) {
  assert.equal(
    TEMU_DOCUMENT_START_SCRIPT.includes(skuBreakingSelector),
    false,
    `Temu document-start CSS can hide the real SKU confirmation: ${skuBreakingSelector}`,
  )
}
for (const protectedAriaSelector of [
  '[aria-label*="cart" i]:not([id^="otlobli"])',
  '[aria-label*="account" i]:not([id^="otlobli"])',
  '[aria-label*="سلة"]:not([id^="otlobli"])',
]) {
  assert.ok(
    TEMU_DOCUMENT_START_CSS.includes(protectedAriaSelector),
    `Temu document-start CSS can hide an Otlobli-owned control: ${protectedAriaSelector}`,
  )
}
for (const marker of [
  'window.top !== window',
  'temu\\.com$',
  'bgn[_-]?verification',
  "var cookieDelays = [0, 60, 160, 360, 700, 1200, 2000, 3500, 6000, 10000]",
  'cookieAttempts >= 3',
  "data-otlobli-temu-cookie-auto-accepted",
  "document.addEventListener('click'",
  'insideSkuDialog(control)',
]) {
  assert.ok(TEMU_DOCUMENT_START_SCRIPT.includes(marker), `Temu document-start policy missing ${marker}`)
}

const outsideTemuMetrics = { timers: 0, listeners: 0, domReads: 0 }
const outsideTemuWindow = {}
outsideTemuWindow.top = outsideTemuWindow
runInNewContext(TEMU_DOCUMENT_START_SCRIPT, {
  window: outsideTemuWindow,
  location: { hostname: 'temu.com.evil.example', pathname: '/', search: '', hash: '', href: 'https://temu.com.evil.example/' },
  document: new Proxy({}, { get() { outsideTemuMetrics.domReads++; return undefined } }),
  setTimeout() { outsideTemuMetrics.timers++; return outsideTemuMetrics.timers },
  addEventListener() { outsideTemuMetrics.listeners++ },
  URL,
})
assert.deepEqual(outsideTemuMetrics, { timers: 0, listeners: 0, domReads: 0 }, 'Temu document-start policy escaped its exact host')

const challengeMetrics = { timers: 0, listeners: 0, domReads: 0 }
const challengeWindow = {}
challengeWindow.top = challengeWindow
runInNewContext(TEMU_DOCUMENT_START_SCRIPT, {
  window: challengeWindow,
  location: { hostname: 'www.temu.com', pathname: '/bgn_verification.html', search: '', hash: '', href: 'https://www.temu.com/bgn_verification.html' },
  document: new Proxy({}, { get() { challengeMetrics.domReads++; return undefined } }),
  setTimeout() { challengeMetrics.timers++; return challengeMetrics.timers },
  addEventListener() { challengeMetrics.listeners++ },
  URL,
})
assert.deepEqual(challengeMetrics, { timers: 0, listeners: 0, domReads: 0 }, 'Temu document-start policy touched a human challenge')

const makeInlineStyle = () => {
  const values = new Map()
  return {
    setProperty(name, value, priority = '') { values.set(name, [String(value), String(priority)]) },
    removeProperty(name) { values.delete(name) },
    getPropertyValue(name) { return values.get(name)?.[0] ?? '' },
    getPropertyPriority(name) { return values.get(name)?.[1] ?? '' },
  }
}
const clickFixture = { listener: null }
const fixtureRoot = {
  clientWidth: 384,
  clientHeight: 740,
  appendChild() {},
  contains() { return true },
  setAttribute() {},
}
const clickFixtureDocument = {
  head: fixtureRoot,
  documentElement: fixtureRoot,
  body: {},
  getElementById() { return null },
  createElement() { return { id: '', textContent: '' } },
  querySelectorAll() { return [] },
  addEventListener(type, listener) { if (type === 'click') clickFixture.listener = listener },
}
const clickFixtureWindow = { innerWidth: 384, innerHeight: 740, getComputedStyle() { return null } }
clickFixtureWindow.top = clickFixtureWindow
runInNewContext(TEMU_DOCUMENT_START_SCRIPT, {
  window: clickFixtureWindow,
  location: { hostname: 'www.temu.com', pathname: '/goods.html', search: '?goods_id=1', hash: '', href: 'https://www.temu.com/goods.html?goods_id=1' },
  document: clickFixtureDocument,
  setTimeout() { return 1 },
  addEventListener() {},
  URL,
})
assert.equal(typeof clickFixture.listener, 'function', 'Temu document-start click policy was not installed')
const makeControl = (label, { href = '', productBar = false, skuDialog = false } = {}) => {
  const dialog = { textContent: 'Select size and color' }
  const control = {
    id: '', childElementCount: 0, textContent: label,
    getAttribute(name) {
      if (name === 'href') return href
      if (name === 'aria-label') return label
      return ''
    },
    closest(selector) {
      if (selector === 'a,button,[role="button"]') return control
      if (selector === '#id-shopping-bar') return productBar ? { id: 'id-shopping-bar' } : null
      if (selector.includes('[role="dialog"]')) return skuDialog ? dialog : null
      return null
    },
  }
  return control
}
const dispatchGuardedClick = (control) => {
  const result = { prevented: 0, immediate: 0, stopped: 0 }
  clickFixture.listener({
    target: control,
    preventDefault() { result.prevented++ },
    stopImmediatePropagation() { result.immediate++ },
    stopPropagation() { result.stopped++ },
  })
  return result
}
assert.equal(dispatchGuardedClick(makeControl('Leather shopping bag', { href: '/goods.html?goods_id=2' })).prevented, 0,
  'A legitimate Temu product name was mistaken for the cart')
assert.equal(dispatchGuardedClick(makeControl('Cart', { href: '/cart.html' })).prevented, 1,
  'A genuine Temu cart link was not blocked at document-start')
assert.equal(dispatchGuardedClick(makeControl('Add to cart')).prevented, 0,
  'A generic or hashed SKU confirmation was blocked without page-bar proof')
assert.equal(dispatchGuardedClick(makeControl('Add to cart', { productBar: true })).prevented, 1,
  'The observed Temu page-level shopping bar was not blocked')
assert.equal(dispatchGuardedClick(makeControl('Add to cart', { productBar: true, skuDialog: true })).prevented, 0,
  'The real SKU dialog confirmation was blocked')

const cookieTimers = []
let cookieAttached = true
let cookieClicks = 0
const cookieMarker = { value: '' }
const cookiePageStyle = makeInlineStyle()
const cookieScope = {
  id: 'temu-cookie-consent', className: 'cookie-banner', textContent: 'We use cookies. Accept all',
  style: makeInlineStyle(), parentElement: null,
  getAttribute(name) { return name === 'role' ? 'dialog' : '' },
  setAttribute() {}, removeAttribute() {},
}
const cookieControl = {
  id: 'onetrust-accept-btn-handler', className: '', textContent: 'Accept all', value: '',
  style: makeInlineStyle(), parentElement: cookieScope,
  getAttribute(name) { return name === 'aria-label' ? 'Accept all' : '' },
  click() { cookieClicks++; cookieAttached = false },
}
const cookieDocumentElement = {
  clientWidth: 384, clientHeight: 740, style: cookiePageStyle,
  appendChild() {},
  contains(node) { return node === cookieDocumentElement || cookieAttached },
  setAttribute(name, value) { cookieMarker.value = `${name}:${value}` },
}
const cookieDocument = {
  head: cookieDocumentElement, documentElement: cookieDocumentElement, body: { style: cookiePageStyle },
  getElementById() { return null },
  createElement() { return { id: '', textContent: '' } },
  addEventListener() {},
  querySelectorAll(selector) {
    if (selector.includes('#challenge-form')) return []
    if (selector.includes('#onetrust-accept-btn-handler')) return [cookieControl]
    return []
  },
}
const cookieWindow = { innerWidth: 384, innerHeight: 740, getComputedStyle() { return null } }
cookieWindow.top = cookieWindow
runInNewContext(TEMU_DOCUMENT_START_SCRIPT, {
  window: cookieWindow,
  location: { hostname: 'www.temu.com', pathname: '/', search: '', hash: '', href: 'https://www.temu.com/' },
  document: cookieDocument,
  setTimeout(callback, delay) { cookieTimers.push({ callback, delay }); return cookieTimers.length },
  addEventListener() {},
  URL,
})
cookieTimers.find(({ delay }) => delay === 0)?.callback()
assert.equal(cookieClicks, 1, 'The exact Temu cookie acceptance was not activated')
assert.equal(cookiePageStyle.getPropertyValue('visibility'), '', 'Cookie automation hid the entire page')
cookieTimers.find(({ delay }) => delay === 450)?.callback()
assert.equal(cookieMarker.value, 'data-otlobli-temu-cookie-auto-accepted:1', 'Cookie acceptance completion was not recorded')

assert.equal(storeRouting.storeIdentityFromUrl('https://www.temu.com/sa/goods.html?goods_id=1'), 'temu')
assert.equal(storeRouting.storeIdentityFromUrl('https://m.shein.com/ar/product-p-1.html'), 'shein')
for (const unrelatedUrl of [
  'https://temu.com.evil.example/product',
  'https://nottemu.example/product',
  'https://shein.evil.example/product',
]) {
  assert.equal(storeRouting.storeIdentityFromUrl(unrelatedUrl), undefined, `Store host false-positive: ${unrelatedUrl}`)
}
assert.equal(storeRouting.resolveStoreMessageIdentity('shein', 'https://www.temu.com/goods.html', 'shein'), 'temu')
assert.equal(storeRouting.resolveStoreMessageIdentity('temu', '', 'shein'), 'temu')
assert.equal(storeRouting.resolveStoreMessageIdentity(undefined, '', 'shein'), 'shein')
assert.equal(storeRouting.resolveHostNavigationTarget('home', 'store-select'), 'store-select')
assert.equal(storeRouting.resolveHostNavigationTarget('home', 'home'), 'home')
assert.equal(storeRouting.resolveHostNavigationTarget('cart', 'store-select'), 'cart')
assert.equal(storeRouting.resolveHostNavigationTarget('orders', 'home'), 'orders')
assert.equal(storeRouting.canReuseStandardStoreSession('shein', 'shein', null, false), true)
assert.equal(storeRouting.canReuseStandardStoreSession('shein', 'shein', 'shein', true), true)
assert.equal(storeRouting.canReuseStandardStoreSession('shein', 'shein', 'temu', true), false)
assert.equal(storeRouting.canReuseStandardStoreSession('temu', 'shein', 'temu', true), false)
assert.equal(storeRouting.isCurrentStandardStoreEvent({ store: 'shein', sessionId: 7, id: 'A' }, 7, 'A'), true)
assert.equal(storeRouting.isCurrentStandardStoreEvent({ store: 'shein', sessionId: 7, id: 'A' }, 8, 'A'), false)
assert.equal(storeRouting.isCurrentStandardStoreEvent({ store: 'temu', sessionId: 8 }, 8, 'A'), false)
assert.equal(storeRouting.isCurrentStandardStoreEvent({ store: 'temu', sessionId: 8, id: 'B' }, 8, 'A'), false)
assert.equal(storeRouting.isCurrentStandardStoreEvent(null, 8, 'A'), false)
assert.equal(storeRouting.canAdoptOpeningStandardStoreEvent(
  { store: 'temu', sessionId: 9 }, 9, 'C', 'temu', false, true, false, false,
), true)
assert.equal(storeRouting.canAdoptOpeningStandardStoreEvent(
  { store: 'temu', sessionId: 9 }, 9, 'C', 'shein', false, true, false, false,
), false)
assert.equal(storeRouting.canAdoptOpeningStandardStoreEvent(
  { store: 'temu', sessionId: 9 }, 8, 'C', 'temu', false, true, false, false,
), false)
assert.equal(storeRouting.canAdoptOpeningStandardStoreEvent(
  { store: 'temu', sessionId: 9, id: 'B' }, 9, 'C', 'temu', false, true, false, false,
), false)
assert.equal(storeRouting.canAdoptOpeningStandardStoreEvent(
  { store: 'temu', sessionId: 9 }, 9, 'C', 'temu', true, true, false, false,
), false)
assert.equal(storeRouting.canAdoptOpeningStandardStoreEvent(
  { store: 'temu', sessionId: 9 }, 9, 'C', 'temu', false, false, false, false,
), false)
assert.equal(storeRouting.canAdoptOpeningStandardStoreEvent(
  { store: 'temu', sessionId: 9 }, 9, 'C', 'temu', false, true, true, false,
), false)
assert.equal(storeRouting.canAdoptOpeningStandardStoreEvent(
  { store: 'temu', sessionId: 9 }, 9, 'C', 'temu', false, true, false, true,
), false)
const correctlyBucketedCarts = {
  shein: [{ id: 's', sourceLink: 'https://m.shein.com/ar/product-p-1.html' }],
  temu: [{ id: 't', sourceLink: 'https://www.temu.com/sa/goods.html?goods_id=1' }],
}
assert.equal(storeRouting.repairStoreCartBuckets(correctlyBucketedCarts), correctlyBucketedCarts)
const misbucketedCarts = {
  shein: [
    { id: 'wrong-temu', sourceLink: 'https://www.temu.com/sa/goods.html?goods_id=2' },
    { id: 'unknown', sourceLink: 'https://merchant.example/item' },
  ],
  temu: [
    { id: 'wrong-shein', sourceLink: 'https://m.shein.com/ar/product-p-2.html' },
    { id: 'unknown-temu', sourceLink: 'https://merchant.example/temu-in-path' },
  ],
  legacy: [{ id: 'preserved' }],
}
const misbucketedSnapshot = JSON.stringify(misbucketedCarts)
const repairedCarts = storeRouting.repairStoreCartBuckets(misbucketedCarts)
assert.equal(JSON.stringify(misbucketedCarts), misbucketedSnapshot, 'Cart repair must not mutate persisted input')
assert.equal(JSON.stringify(repairedCarts), JSON.stringify({
  shein: [
    { id: 'unknown', sourceLink: 'https://merchant.example/item' },
    { id: 'wrong-shein', sourceLink: 'https://m.shein.com/ar/product-p-2.html' },
  ],
  temu: [
    { id: 'wrong-temu', sourceLink: 'https://www.temu.com/sa/goods.html?goods_id=2' },
    { id: 'unknown-temu', sourceLink: 'https://merchant.example/temu-in-path' },
  ],
  legacy: [{ id: 'preserved' }],
}))
assert.equal(storeRouting.repairStoreCartBuckets(repairedCarts), repairedCarts, 'Cart repair must be idempotent')

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
  "supabase.rpc('disable_device_token'", 'retryable', 'requestId', 'providerForPushDevice',
  'partial_provider_not_configured', 'configuration', 'notConfigured', 'normalizeApnsPrivateKey',
  'probeApns', "result.reason === 'BadDeviceToken'",
]) {
  assert.ok(push.includes(marker), `Push sender missing ${marker}`)
}
assert.ok(!push.includes("console.error('FCM send failed', res.status, errText)"), 'Push provider errors must not log raw bodies')
const { normalizeApnsPrivateKey, providerForPushDevice } = loadTypeScriptModule('supabase/functions/send-push/routing.ts')
assert.equal(providerForPushDevice('ios', { apns: true, fcm: true }), 'apns')
assert.equal(providerForPushDevice('android', { apns: true, fcm: true }), 'fcm')
assert.equal(providerForPushDevice('ios', { apns: false, fcm: true }), null, 'iOS APNs tokens must never fall back to FCM')
assert.equal(providerForPushDevice('android', { apns: true, fcm: false }), null, 'Android FCM tokens must never fall back to APNs')
const sampleApnsPem = `${['-----BEGIN', 'PRIVATE KEY-----'].join(' ')}\nAAAA\n${['-----END', 'PRIVATE KEY-----'].join(' ')}`
assert.equal(normalizeApnsPrivateKey(sampleApnsPem), sampleApnsPem)
assert.equal(normalizeApnsPrivateKey(sampleApnsPem.replaceAll('\n', '\\n')), sampleApnsPem)
assert.equal(normalizeApnsPrivateKey(Buffer.from(sampleApnsPem).toString('base64')), sampleApnsPem)
const adminPush = readFileSync(resolve(root, 'admin/src/AdminApp.tsx'), 'utf8')
for (const marker of [
  'MANUAL_NOTIFICATION_DATA', "version: '1'", "type: 'system'", "route: 'notifications'",
  'data: MANUAL_NOTIFICATION_DATA', 'PUSH_ERROR_MESSAGES', 'configuration?.apns === false',
  'إشعارات iPhone غير مُهيّأة',
]) {
  assert.ok(adminPush.includes(marker), `Admin push sender missing ${marker}`)
}
const adminOrders = readFileSync(resolve(root, 'supabase/functions/admin-orders/index.ts'), 'utf8')
for (const marker of [
  "version: '1'", "type: 'order_update'", "route: 'orders/details'", 'entityId: order.id',
]) {
  assert.ok(adminOrders.includes(marker), `Order push sender missing ${marker}`)
}
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
assert.ok(otpSender.includes('buildOtpMessage(code)'), 'WhatsApp OTP sender must use the validated message contract')
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
  ['https://m.shein.com/auth', 'blocked-login'],
  ['https://m.shein.com/user/auth', 'blocked-login'],
  ['https://m.shein.com/user/register', 'blocked-signup'],
  ['https://m.shein.com/user/profile', 'blocked-account'],
  ['https://m.shein.com/country', 'blocked-country'],
  ['https://m.shein.com/region', 'blocked-region'],
  ['https://m.shein.com/currency', 'blocked-currency'],
  ['https://m.shein.com/language', 'blocked-language'],
  ['https://m.shein.com/cart', 'blocked-checkout'],
  ['https://m.shein.com/captcha/verify', 'human-verification'],
  ['https://m.shein.com/captcha.html', 'human-verification'],
  ['https://m.shein.com/verify-session', 'human-verification'],
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
for (const required of ['installCount:1', 'MAX_ROOTS=96', 'MAX_NODES_PER_ROOT=320', 'data-otlobli-capture-owned', "document.getElementById('otlobli-region-switching')", ".closest('.sui-drawer.cascade')", 'human-verification', 'challenge-pass-through', 'function paintedChallenge()', 'state.pause=pause;state.resume=install', 'duplicate-install']) {
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
assert.equal(coordinator.isSheinCoordinatorVisuallyReady(browseReady), true, 'The v86.71 flow must release safe browsing while signed region repair continues')
assert.equal(coordinator.isSheinCoordinatorVisuallyReady({ ...browseReady, currencyState: 'mismatch' }), false)
assert.equal(coordinator.isSheinCoordinatorVisuallyReady({ ...browseReady, humanVerificationState: 'required' }), false)
assert.equal(
  coordinator.isSheinCoordinatorReady({ ...state, humanVerificationState: 'required' }),
  false,
  'A painted human-verification surface must never consume the queued product URL',
)

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

let resolvedChallenge = coordinator.transitionSheinRegionCoordinator(state, { type: 'HUMAN_VERIFICATION_REQUIRED' })
resolvedChallenge = coordinator.transitionSheinRegionCoordinator(resolvedChallenge, { type: 'HUMAN_VERIFICATION_RESOLVED' })
assert.equal(coordinator.isSheinCoordinatorReady(resolvedChallenge), false, 'Resolution status alone is not product readiness')
resolvedChallenge = coordinator.transitionSheinRegionCoordinator(resolvedChallenge, {
  type: 'SNAPSHOT', snapshot: { captureState: 'ready' },
})
assert.equal(coordinator.isSheinCoordinatorReady(resolvedChallenge), false, 'An incomplete post-challenge snapshot must not release a queued product')
resolvedChallenge = coordinator.transitionSheinRegionCoordinator(resolvedChallenge, {
  type: 'SNAPSHOT', snapshot: {
    documentGeneration: 'fresh-document', countryState: 'matching', regionState: 'matching',
    currencyState: 'matching', languageState: 'matching', loginState: 'not-required',
    humanVerificationState: 'none', policyState: 'verified', captureState: 'ready', interactive: true,
  },
})
assert.equal(coordinator.isSheinCoordinatorReady(resolvedChallenge), true, 'Only a complete fresh snapshot may restore product readiness')

const appSource = readFileSync(resolve(root, 'src/App.tsx'), 'utf8')
const otpGridStart = appSource.indexOf('<div className="otp-grid"')
const otpGridEnd = appSource.indexOf('</div>', otpGridStart)
const otpGridSource = appSource.slice(otpGridStart, otpGridEnd)
assert.ok(otpGridStart >= 0 && otpGridEnd > otpGridStart, 'OTP input grid is missing')
for (const marker of [
  'inputMode="numeric"',
  "id={index === 0 ? 'one-time-code' : undefined}",
  "name={index === 0 ? 'one-time-code' : undefined}",
  "autoComplete={index === 0 ? 'one-time-code' : 'off'}",
  'maxLength={index === 0 ? otpDigits.length : 1}',
  'event.preventDefault()',
  'pasteOtpDigits(pastedCode)',
]) {
  assert.ok(otpGridSource.includes(marker), `OTP autofill contract missing ${marker}`)
}
assert.equal(otpGridSource.includes('window.setTimeout'), false, 'OTP paste must not add a deferred timer')
const sheinResolvedStart = appSource.indexOf('// Android may complete the genuine challenge')
const sheinResolvedEnd = appSource.indexOf("if (detail?.type === 'humanCheckSkipped')", sheinResolvedStart)
const sheinResolvedBranch = appSource.slice(sheinResolvedStart, sheinResolvedEnd)
assert.ok(sheinResolvedStart >= 0 && sheinResolvedEnd > sheinResolvedStart, 'SHEIN resolved-message branch is missing')
for (const forbidden of [
  'sheinChallengeActiveRef.current = false', "pendingProductUrlRef.current = ''",
  'markStoreWebviewReadyRef', 'navigateStoreWebviewInPage',
  'revealPreparedProductIfReady', 'clearPendingProductPreparation',
]) {
  assert.ok(!sheinResolvedBranch.includes(forbidden), `SHEIN resolved status consumed navigation too early: ${forbidden}`)
}
const challengeSnapshotStart = appSource.indexOf("if (messageStore === 'shein' && sheinChallengeActiveRef.current)")
const challengeSnapshotEnd = appSource.indexOf("const next = transitionSheinCoordinator", challengeSnapshotStart)
const challengeSnapshotGate = appSource.slice(challengeSnapshotStart, challengeSnapshotEnd)
for (const required of [
  '!snapshotDocumentGeneration', "snapshot.captureState !== 'ready'",
  "snapshot.humanVerificationState !== 'none'", 'sheinChallengeDocumentGenerationRef.current',
  'sameResolvedDocument', 'freshSnapshotDocument', 'resolvedUnknownDocument',
  'trustedFreshUnknownDocument', 'sheinChallengeStartedAtRef.current',
]) {
  assert.ok(challengeSnapshotGate.includes(required), `Post-challenge document gate missing ${required}`)
}

const loadedEffectStart = appSource.indexOf("const loadedHandle = InAppBrowser.addListener('browserPageLoaded'")
const temuLoadedStart = appSource.indexOf("if (activeStore === 'temu') {", loadedEffectStart)
const temuLoadedEnd = appSource.indexOf('markStoreWebviewReadyRef.current', temuLoadedStart)
const temuLoadedBranch = appSource.slice(temuLoadedStart, temuLoadedEnd)
assert.ok(loadedEffectStart >= 0 && temuLoadedStart > loadedEffectStart, 'Temu browserPageLoaded branch is missing')
assert.ok(!temuLoadedBranch.includes('pendingProductPageLoadedRef.current = true'), 'Temu native page-load raced queued product readiness')

const temuHumanStart = appSource.indexOf('// Preserve the existing behavior for any non-SHEIN verification page.')
const temuHumanEnd = appSource.indexOf("if (detail?.type === 'humanCheckResolved')", temuHumanStart)
const temuHumanBranch = appSource.slice(temuHumanStart, temuHumanEnd)
assert.ok(temuHumanStart >= 0 && temuHumanEnd > temuHumanStart, 'Temu human-check branch is missing')
assert.ok(!temuHumanBranch.includes('markStoreWebviewReadyRef.current'), 'Temu challenge consumed the queued product URL')
assert.ok(temuHumanBranch.includes('pendingProductRevealRef.current'), 'Temu challenge does not detect a queued product')
assert.ok(!temuHumanBranch.includes('pendingProductNavigationRequestedRef.current'), 'Temu challenge remains hidden before queued PDP navigation starts')
for (const forbidden of ['pendingProductPageLoadedRef.current = true', 'pendingProductVisualReadyRef.current = true', 'revealPreparedProductIfReady()']) {
  assert.ok(!temuHumanBranch.includes(forbidden), `Temu verification incorrectly completes product preparation via ${forbidden}`)
}
for (const required of ['pendingProductVerificationSeenRef.current = true', 'pausePendingProductPreparationTimeout()', 'revealPendingProductVerification()']) {
  assert.ok(temuHumanBranch.includes(required), `Temu verification does not preserve queued product via ${required}`)
}
assert.ok(temuHumanBranch.includes('sheinChallengeResolutionReportedRef.current = false'), 'A later Temu challenge can inherit an old resolved state')
const sheinHumanStart = appSource.indexOf("if (detail?.type === 'humanCheck') {")
const sheinHumanEnd = appSource.indexOf('// Preserve the existing behavior for any non-SHEIN verification page.', sheinHumanStart)
const sheinHumanBranch = appSource.slice(sheinHumanStart, sheinHumanEnd)
assert.ok(sheinHumanStart >= 0 && sheinHumanEnd > sheinHumanStart, 'SHEIN human-check branch is missing')
assert.ok(sheinHumanBranch.includes('pendingProductRevealRef.current'), 'SHEIN challenge does not detect a queued product')
assert.ok(!sheinHumanBranch.includes('pendingProductNavigationRequestedRef.current'), 'SHEIN challenge remains hidden before queued PDP navigation starts')
for (const required of ['pendingProductVerificationSeenRef.current = true', 'pausePendingProductPreparationTimeout()', 'revealPendingProductVerification()']) {
  assert.ok(sheinHumanBranch.includes(required), `SHEIN verification does not preserve queued product via ${required}`)
}
const verificationRevealStart = appSource.indexOf('const revealPendingProductVerification =')
const verificationRevealEnd = appSource.indexOf('const markStoreWebviewReady =', verificationRevealStart)
const verificationRevealBranch = appSource.slice(verificationRevealStart, verificationRevealEnd)
assert.ok(verificationRevealBranch.includes('if (!pendingProductRevealRef.current) return false'), 'Queued verification reveal is not keyed to the pending product')
assert.ok(!verificationRevealBranch.includes('pendingProductNavigationRequestedRef.current'), 'Queued verification reveal still waits for PDP navigation')
for (const required of ['InAppBrowser.show()', 'postWebviewChromeState(returnTarget)']) {
  assert.ok(verificationRevealBranch.includes(required), `Hidden pending verification is not visibly handed off via ${required}`)
}
for (const forbidden of ['clearPendingProductPreparation()', 'sheinReadyRef.current = true', 'pendingBackTargetRef.current =']) {
  assert.ok(!verificationRevealBranch.includes(forbidden), `Verification reveal consumes pending state via ${forbidden}`)
}

const temuReadyStart = appSource.indexOf("if (detail?.type === 'temuPublicReady')")
const temuReadyEnd = appSource.indexOf("if (detail?.type === 'humanCheck')", temuReadyStart)
const temuReadyBranch = appSource.slice(temuReadyStart, temuReadyEnd)
assert.ok(temuReadyStart >= 0 && temuReadyEnd > temuReadyStart, 'Temu stable public-readiness hand-off is missing')
for (const marker of ['sheinChallengeActiveRef.current', 'sameTemuProductNavigation', 'markStoreWebviewReadyRef.current', 'readyDocumentGeneration', 'challengeDocumentGeneration']) {
  assert.ok(temuReadyBranch.includes(marker), `Temu stable public-readiness missing ${marker}`)
}
for (const marker of ['prepareVerifiedProductRetry', 'markStoreWebviewReadyRef.current']) {
  assert.ok(temuReadyBranch.includes(marker), `Verified Temu product retry missing ${marker}`)
}
for (const marker of [
  'sameResolvedDocument',
  'freshReadyDocument',
  'resolvedUnknownDocument',
  'trustedFreshUnknownDocument',
  'sheinChallengeStartedAtRef.current',
  'isNewerStoreDocumentGeneration',
  'currentUrlMatchesMessage = true',
]) {
  assert.ok(temuReadyBranch.includes(marker), `Temu public hand-off generation gate missing ${marker}`)
}

const temuProductStart = appSource.indexOf("if (detail?.type === 'temuProductVisible')")
const temuProductEnd = appSource.indexOf("if (detail?.type === 'sheinSaudiReady'", temuProductStart)
const temuProductBranch = appSource.slice(temuProductStart, temuProductEnd)
for (const marker of [
  'productDocumentGeneration',
  'sameResolvedDocument',
  'freshProductDocument',
  'resolvedUnknownDocument',
  'trustedFreshUnknownDocument',
  'sheinChallengeStartedAtRef.current',
  'isNewerStoreDocumentGeneration',
  'sheinChallengeResolutionReportedRef.current',
  'sheinChallengeActiveRef.current = false',
  'sameTemuProductNavigation',
]) {
  assert.ok(temuProductBranch.includes(marker), `Temu PDP challenge hand-off missing ${marker}`)
}
for (const marker of [
  'const storeDocumentGenerationTimestamp =',
  "Number.parseInt(prefix, 36)",
  'const isNewerStoreDocumentGeneration =',
  'candidateTime > baselineTime',
]) {
  assert.ok(appSource.includes(marker), `Ordered document-generation guard missing ${marker}`)
}
assert.ok(
  temuProductBranch.indexOf('if (sheinChallengeActiveRef.current)') <
    temuProductBranch.indexOf('if (pendingProductRevealRef.current)'),
  'Temu PDP can release the challenge gate only when a cart/order queue exists',
)

const resolvedMessageStart = appSource.indexOf("if (detail?.type === 'humanCheckResolved')")
const temuResolvedEnd = appSource.indexOf('// Android may complete the genuine challenge', resolvedMessageStart)
const temuResolvedBranch = appSource.slice(resolvedMessageStart, temuResolvedEnd)
for (const marker of [
  'if (!sheinChallengeActiveRef.current) return',
  'resolvedDocumentGeneration',
  'sheinChallengeResolutionReportedRef.current = true',
  'armPendingProductPreparationTimeout()',
]) {
  assert.ok(temuResolvedBranch.includes(marker), `Temu resolved-message settlement gate missing ${marker}`)
}
for (const forbidden of [
  'sheinChallengeActiveRef.current = false',
  "sheinChallengeDocumentGenerationRef.current = ''",
  'markStoreWebviewReadyRef.current',
  'revealPreparedProductIfReady()',
]) {
  assert.ok(!temuResolvedBranch.includes(forbidden), `Temu resolved message released the host gate too early via ${forbidden}`)
}
assert.ok(appSource.includes('pendingProductUrl && !pendingProductNavigationRequestedRef.current'), 'Ready hand-off can navigate the same queued product twice')
assert.ok(appSource.includes('pendingProductNavigationAttemptRef.current += 1'), 'Queued product retry is not bounded by navigation attempts')
assert.ok(appSource.includes('if (!expectedUrl || !visibleUrl) return false'), 'Missing Temu product URL can still complete a queued PDP')
assert.match(appSource, /bgn\[_-\]\?verification/, 'Host challenge URL detector misses Temu bgn_verification')
assert.ok(appSource.includes('SHEIN_CHALLENGE_PATH_RE.test(pathname)'), 'Temu region redirect can rewrite a verification route')
assert.ok(appSource.includes('if (isStoreHumanChallengeUrl(url)) {'), 'Temu host does not enter challenge state at the URL boundary')
const verifiedRetryStart = appSource.indexOf('const prepareVerifiedProductRetry =')
const verifiedRetryEnd = appSource.indexOf('const revealPreparedProductIfReady =', verifiedRetryStart)
const verifiedRetryBranch = appSource.slice(verifiedRetryStart, verifiedRetryEnd)
for (const marker of ['pendingProductNavigationAttemptRef.current >= 2', 'sameTemuProductNavigation', 'sameSheinProductNavigation', 'pendingProductUrlRef.current = queuedProductUrl']) {
  assert.ok(verifiedRetryBranch.includes(marker), `Verified product retry contract missing ${marker}`)
}
const revealPreparedStart = appSource.indexOf('const revealPreparedProductIfReady =')
const revealPreparedEnd = appSource.indexOf('const revealPendingProductVerification =', revealPreparedStart)
assert.ok(appSource.slice(revealPreparedStart, revealPreparedEnd).includes('sameSheinProductNavigation'), 'SHEIN Home/challenge page can complete a queued PDP')

const fallbackStart = appSource.indexOf("const startFallback = InAppBrowser.addListener('urlChangeEvent'")
const fallbackEnd = appSource.indexOf('return () => {', fallbackStart)
const fallbackBranch = appSource.slice(fallbackStart, fallbackEnd)
assert.ok(fallbackStart >= 0 && fallbackEnd > fallbackStart, 'Native opening fallback is missing')
assert.ok(fallbackBranch.includes("navigationOwner?.store !== 'shein'") &&
  fallbackBranch.includes('navigationOwner.sessionId !== webviewSessionRef.current'),
'Temu or a stale session can still arm the fixed readiness fallback')
assert.ok(!fallbackBranch.includes('markStoreWebviewReadyRef.current'), 'Fixed timeout can still consume queued store navigation')
assert.ok(fallbackBranch.includes('sheinChallengeActiveRef.current'), 'SHEIN bypass fallback is not challenge-gated')

const humanCheckSource = readFileSync(resolve(root, 'src/services/sheinHumanCheck.ts'), 'utf8')
assert.ok(!humanCheckSource.includes('challengeScanGap'), 'Human-check negative scan cache returned')
assert.ok(humanCheckSource.includes('otlobliSuspendSheinShippingProgressForChallenge'), 'Challenge entry does not cancel region repair')
assert.ok(humanCheckSource.includes('otlobliSuspendProductCaptureForChallenge'), 'Challenge entry does not cancel product capture')
assert.ok(humanCheckSource.includes('otlobliSuspendTemuRuntimeForChallenge'), 'Challenge entry does not suspend Temu-owned surfaces')

const runtimeSource = readFileSync(resolve(root, 'src/services/storeRuntimeCoordinator.ts'), 'utf8')
assert.ok(runtimeSource.indexOf('if (otlobliGuardHumanChallenge())') < runtimeSource.indexOf('if (now >= otlobliMainDue)'), 'Every coordinator wake must guard challenge before due lanes')
const hiddenBranchStart = runtimeSource.indexOf('if (document.hidden) {', runtimeSource.indexOf('function runOtlobliCoordinator'))
const hiddenBranchEnd = runtimeSource.indexOf('\n    }', hiddenBranchStart)
assert.ok(!runtimeSource.slice(hiddenBranchStart, hiddenBranchEnd).includes('scheduleOtlobliCoordinator()'), 'Hidden store document still polls in the background')

const sessionSource = readFileSync(resolve(root, 'src/services/sheinSessionScript.ts'), 'utf8')
assert.match(sessionSource, /bgn\[_-\]\?verification/, 'Injected challenge URL detector misses Temu bgn_verification')
assert.ok(sessionSource.includes('function otlobliSuspendSheinShippingProgressForChallenge'), 'Shipping challenge cleanup is missing')
assert.ok(sessionSource.includes('if (otlobliInterventionPausedForHumanChallenge()) return;\n      try { ensureSheinSaudiShippingSelection();'), 'Deferred shipping repair is not challenge-guarded')
assert.equal((sessionSource.match(/setTimeout\(function \(\) \{\n        if \(otlobliInterventionPausedForHumanChallenge\(\)\) return;/g) || []).length, 2, 'Shipping marker timers are not challenge-guarded')
const shippingTouchStart = sessionSource.indexOf("document.addEventListener('touchmove'")
const shippingTouchEnd = sessionSource.indexOf("}, { capture: true, passive: false });", shippingTouchStart)
assert.ok(sessionSource.slice(shippingTouchStart, shippingTouchEnd).includes('otlobliInterventionPausedForHumanChallenge()'), 'Shipping touch guard can swallow fresh challenge input')
const sessionBootstrapStart = sessionSource.indexOf("if (IS_SHEIN && otlobliScriptEnabled('session') && !OTLOBLI_DIRECT_HUMAN_CHALLENGE")
const sessionBootstrapEnd = sessionSource.indexOf('// Current Temu routing', sessionBootstrapStart)
const sessionBootstrapBranch = sessionSource.slice(sessionBootstrapStart, sessionBootstrapEnd)
assert.ok(sessionBootstrapBranch.includes('!otlobliIsHumanChallenge()'), 'SHEIN bootstrap can normalize route/DOM over an SPA challenge')
assert.ok(sessionBootstrapBranch.indexOf('!otlobliIsHumanChallenge()') < sessionBootstrapBranch.indexOf('history.replaceState'), 'SHEIN bootstrap challenge gate runs after route mutation')

const policySource = readFileSync(resolve(root, 'src/services/sheinPolicyEngine.ts'), 'utf8')
for (const marker of ['#one-pass-custom', '#nine-captcha-custom', '.si-verify-block-request-dialog', "removeChild(policyStyle)"]) {
  assert.ok(policySource.includes(marker), `SHEIN policy challenge isolation missing ${marker}`)
}

const temuRuntimeSource = readFileSync(resolve(root, 'src/services/temuBrowserScript.ts'), 'utf8')
assert.ok(temuRuntimeSource.includes("if (window.__otlobliNativeNavigation === true) return;"), 'Native Temu still rewrites viewport metadata')
assert.ok(temuRuntimeSource.includes("type: 'temuPublicReady'"), 'Temu public readiness signal is missing')
assert.ok(temuRuntimeSource.indexOf('if (__otlobliTemuPublicReadyPostedKey === key) return;') < temuRuntimeSource.indexOf("document.body.textContent || ''"), 'Stable Temu public page still rereads full body text every tick')
assert.ok(!temuRuntimeSource.includes("querySelectorAll('a,button,[role=\"button\"],div,span,i')"), 'Temu search still scans every generic element each tick')
assert.ok(!temuRuntimeSource.includes("'a,button,[role=\"button\"],[role=\"dialog\"]"), 'Temu blocker cleanup still scans every anchor and button')
assert.ok(!temuRuntimeSource.includes('function hideTemuHeaderIconsByProbe()'), 'Dead full-DOM Temu header probe returned')
assert.ok(temuRuntimeSource.includes('shopping\\\\s*bag|\\\\bbag\\\\b|account'), 'Temu category text can still collide with the bag blocker')
for (const marker of [
  "OTLOBLI_TEMU_OWNED_STYLE_ATTR = 'data-otlobli-temu-owned-style'",
  'otlobliRestoreTemuInlineStyles(owned',
  '[data-otlobli-blocked="1"],[data-otlobli-temu-pinned-header="1"]',
  '[data-otlobli-temu-search-restored="1"]',
  "document.body.removeAttribute('data-otlobli-temu-search-mode')",
  'var cacheGap = routeAge > 3000',
  'OTLOBLI_LOW_END ? 3200 : 1800',
  'OTLOBLI_LOW_END ? 8000 : 4500',
]) {
  assert.ok(temuRuntimeSource.includes(marker), `Temu reversible/performance guard missing ${marker}`)
}
assert.ok(!temuRuntimeSource.includes("style.overflow = ''"), 'Temu cleanup still clears a store/CAPTCHA-owned scroll lock')

const temuRuntime = evaluateInjectedScriptExports('src/services/temuBrowserScript.ts').TEMU_BROWSER_SCRIPT
const temuProductActionsStart = temuRuntime.indexOf('function otlobliSyncTemuProductRouteState()')
const temuProductActionsEnd = temuRuntime.indexOf('function otlobliTemuAccountPanelScore(', temuProductActionsStart)
assert.ok(temuProductActionsStart >= 0 && temuProductActionsEnd > temuProductActionsStart, 'Temu bounded PDP action blocker runtime is missing')
const temuProductActionsRuntime = temuRuntime.slice(temuProductActionsStart, temuProductActionsEnd)
for (const marker of [
  'data-otlobli-temu-product-route',
  'data-otlobli-temu-product-action-hidden',
  'document.elementsFromPoint',
  'ei < exact.length && ei < 48',
  'pi < stack.length && pi < 8',
  'temuProductOptionDialog(el)',
  'otlobliInterventionPausedForHumanChallenge()',
]) {
  assert.ok(temuProductActionsRuntime.includes(marker), `Temu PDP action isolation missing ${marker}`)
}
assert.ok(!temuProductActionsRuntime.includes("querySelectorAll('button,[role=\"button\"],a,[tabindex=\"0\"],div,span')"), 'Temu PDP action blocker regressed to a full-page interactive scan')
assert.ok(runtimeSource.indexOf('hideTemuAccountSurfaces();') < runtimeSource.indexOf('ensureAddToCartButton(true);'), 'Temu guest sign-in is not hidden before the Otlobli action appears')
assert.ok(runtimeSource.indexOf('hideTemuNativeProductActions();') < runtimeSource.indexOf('ensureAddToCartButton(true);'), 'Temu native purchase action is not hidden before the Otlobli action appears')

const makeTemuActionFixtureNode = ({ id = '', text = '', className = '', top = 650, bottom = 704, inSkuDialog = false } = {}) => {
  const attributes = new Map()
  const styleWrites = []
  return {
    id,
    textContent: text,
    className,
    tagName: 'BUTTON',
    childElementCount: 0,
    parentElement: null,
    inSkuDialog,
    styleWrites,
    style: { setProperty: (...args) => styleWrites.push(args) },
    getAttribute(name) { return attributes.get(name) ?? '' },
    setAttribute(name, value) { attributes.set(name, String(value)) },
    removeAttribute(name) { attributes.delete(name) },
    hasAttribute(name) { return attributes.has(name) },
    querySelector: () => null,
    closest(selector) { return selector === '[id^="otlobli"]' && this.id.startsWith('otlobli') ? this : null },
    getBoundingClientRect: () => ({ left: 12, right: 332, width: 320, height: bottom - top, top, bottom }),
  }
}
const temuFixtureBody = { tagName: 'BODY' }
const temuProductAdd = makeTemuActionFixtureNode({ text: 'أضف إلى السلة' })
const temuProductLogin = makeTemuActionFixtureNode({ text: 'تسجيل الدخول', className: 'signInBtn-liveHash' })
const otlobliProductAdd = makeTemuActionFixtureNode({ id: 'otlobli-add-btn', text: 'أضف للسلة' })
const temuSkuConfirm = makeTemuActionFixtureNode({ text: 'Add to cart', inSkuDialog: true })
const temuMiddleCopy = makeTemuActionFixtureNode({ text: 'Add to cart tips', top: 320, bottom: 370 })
const temuFixtureNodes = [temuProductAdd, temuProductLogin, otlobliProductAdd, temuSkuConfirm, temuMiddleCopy]
for (const node of temuFixtureNodes) node.parentElement = temuFixtureBody
const rootAttributes = new Map()
let temuFixtureProductRoute = true
let temuFixtureAccountRoute = false
let temuFixtureChallenge = false
let restoredTemuActions = 0
const temuActionFixture = {
  IS_TEMU: true,
  Math,
  String,
  location: { pathname: '/goods.html', search: '?goods_id=12345' },
  document: {
    body: temuFixtureBody,
    documentElement: {
      setAttribute: (name, value) => rootAttributes.set(name, String(value)),
      removeAttribute: (name) => rootAttributes.delete(name),
    },
    querySelectorAll: (selector) => selector === '[data-otlobli-temu-product-action-hidden="1"]'
      ? temuFixtureNodes.filter((node) => node.hasAttribute('data-otlobli-temu-product-action-hidden'))
      : [],
    elementsFromPoint: () => temuFixtureNodes,
  },
  looksLikeProductPage: () => temuFixtureProductRoute,
  otlobliTemuAccountRoute: () => temuFixtureAccountRoute,
  otlobliInterventionPausedForHumanChallenge: () => temuFixtureChallenge,
  viewportSize: () => ({ width: 360, height: 720 }),
  temuCleanText: (value) => String(value || '').replace(/\s+/g, ' ').trim(),
  temuProductOptionDialog: (node) => !!node.inSkuDialog,
  otlobliRememberTemuInlineStyles: () => undefined,
  otlobliRestoreTemuInlineStyles: () => { restoredTemuActions += 1 },
}
runInNewContext(`${temuProductActionsRuntime}\nhideTemuNativeProductActions();`, temuActionFixture)
assert.equal(temuProductAdd.getAttribute('data-otlobli-temu-product-action-hidden'), '1', 'Visible Temu Add to cart survived on a PDP')
assert.equal(temuProductLogin.getAttribute('data-otlobli-temu-product-action-hidden'), '1', 'Visible Temu sign-in survived on a PDP')
for (const node of [temuProductAdd, temuProductLogin]) {
  for (const property of ['display', 'visibility', 'opacity', 'pointer-events']) {
    assert.ok(
      node.styleWrites.some(([name, , priority]) => name === property && priority === 'important'),
      `Temu product blocker marked a control without applying important ${property}`,
    )
  }
}
assert.equal(otlobliProductAdd.hasAttribute('data-otlobli-temu-product-action-hidden'), false, 'Temu blocker hid Otlobli\'s own cart action')
assert.equal(temuSkuConfirm.hasAttribute('data-otlobli-temu-product-action-hidden'), false, 'Temu blocker hid the real SKU option dialog action')
assert.equal(temuMiddleCopy.hasAttribute('data-otlobli-temu-product-action-hidden'), false, 'Temu blocker hid ordinary mid-page copy')
assert.equal(rootAttributes.get('data-otlobli-temu-product-route'), '1', 'Temu PDP route marker was not published for first-paint CSS')

temuFixtureProductRoute = false
runInNewContext(`${temuProductActionsRuntime}\nhideTemuNativeProductActions();`, temuActionFixture)
assert.equal(temuProductAdd.hasAttribute('data-otlobli-temu-product-action-hidden'), false, 'Temu action styles leaked from PDP to Home')
assert.equal(temuProductLogin.hasAttribute('data-otlobli-temu-product-action-hidden'), false, 'Temu sign-in styles leaked from PDP to Home')
assert.equal(restoredTemuActions, 2, 'Temu route exit did not restore exactly the owned PDP controls')
assert.equal(rootAttributes.has('data-otlobli-temu-product-route'), false, 'Temu PDP route marker leaked onto Home')

const accountRouteAction = makeTemuActionFixtureNode({ text: 'Add to cart' })
accountRouteAction.parentElement = temuFixtureBody
temuFixtureNodes.splice(0, temuFixtureNodes.length, accountRouteAction)
temuFixtureProductRoute = true
temuFixtureAccountRoute = true
runInNewContext(`${temuProductActionsRuntime}\nhideTemuNativeProductActions();`, temuActionFixture)
assert.equal(accountRouteAction.hasAttribute('data-otlobli-temu-product-action-hidden'), false, 'Temu blocker modified a deliberate account/login route')

temuFixtureAccountRoute = false
temuFixtureChallenge = true
runInNewContext(`${temuProductActionsRuntime}\nhideTemuNativeProductActions();`, temuActionFixture)
assert.equal(accountRouteAction.hasAttribute('data-otlobli-temu-product-action-hidden'), false, 'Temu blocker modified a live human-verification surface')

const skuTapSource = readFileSync(resolve(root, 'src/services/sheinSkuTap.ts'), 'utf8')
const productCaptureSource = readFileSync(resolve(root, 'src/services/storeProductCaptureScript.ts'), 'utf8')
for (const marker of ['function sheinSuspendSkuReveal()', 'otlobliProductCapturePausedForChallenge()', 'sheinScheduleSkuReveal(function ()']) {
  assert.ok(skuTapSource.includes(marker), `Deferred SKU reveal isolation missing ${marker}`)
}
assert.ok(productCaptureSource.includes("typeof sheinSuspendSkuReveal === 'function'"), 'Product-capture suspension does not cancel SKU reveal work')
assert.ok(productCaptureSource.includes("typeof temuCancelHeroCapture === 'function'"), 'Challenge suspension does not cancel deferred Temu colour capture')
assert.equal((productCaptureSource.match(/temuScheduleHeroCapture\(/g) || []).length, 4, 'Temu colour capture is not owned by one shared scheduler')
assert.equal((productCaptureSource.match(/setTimeout\(captureHero/g) || []).length, 0, 'Legacy unowned Temu hero timers returned')
const productCaptureRuntime = evaluateInjectedScriptExports('src/services/storeProductCaptureScript.ts').STORE_PRODUCT_CAPTURE_SCRIPT
const heroSchedulerStart = productCaptureRuntime.indexOf('var __otlobliTemuHeroCaptureHandles')
const heroSchedulerEnd = productCaptureRuntime.indexOf("if (IS_TEMU && !window.__otlobliTemuClickBound)", heroSchedulerStart)
assert.ok(heroSchedulerStart >= 0 && heroSchedulerEnd > heroSchedulerStart, 'Temu hero scheduler runtime is missing')
const heroSchedulerRuntime = productCaptureRuntime.slice(heroSchedulerStart, heroSchedulerEnd)
let heroTimerId = 0
let heroGoodsId = '101'
let heroChallenge = false
let heroImageReads = 0
const liveHeroTimers = new Map()
const allHeroTimers = new Map()
const heroListeners = {}
const heroWindow = { __otlobliTemuColorGid: '101', __otlobliTemuColorImg: '' }
const heroDocument = {
  hidden: false,
  addEventListener: (type, listener) => { heroListeners[type] = listener },
  querySelectorAll: () => {
    heroImageReads += 1
    return [{
      currentSrc: 'https://img.kwcdn.com/selected-hero.jpg',
      getBoundingClientRect: () => ({ width: 320, height: 320, top: 20 }),
    }]
  },
}
const heroFixture = {
  IS_TEMU: true,
  window: heroWindow,
  document: heroDocument,
  temuGoodsId: () => heroGoodsId,
  otlobliProductCapturePausedForChallenge: () => heroChallenge,
  viewportSize: () => ({ height: 800 }),
  setTimeout: (callback) => {
    const id = ++heroTimerId
    liveHeroTimers.set(id, callback)
    allHeroTimers.set(id, callback)
    return id
  },
  clearTimeout: (id) => liveHeroTimers.delete(id),
}
runInNewContext(heroSchedulerRuntime, heroFixture)
heroFixture.temuScheduleHeroCapture('101')
const supersededHeroTimers = [...liveHeroTimers.keys()]
heroFixture.temuScheduleHeroCapture('101')
assert.equal(liveHeroTimers.size, 2, 'A newer colour tap did not replace the previous 700/1600ms pair')
for (const id of supersededHeroTimers) allHeroTimers.get(id)()
assert.equal(heroImageReads, 0, 'A superseded colour callback still scanned the Temu gallery')
const currentHeroTimer = Math.min(...liveHeroTimers.keys())
const currentHeroCallback = liveHeroTimers.get(currentHeroTimer)
liveHeroTimers.delete(currentHeroTimer)
currentHeroCallback()
assert.equal(heroImageReads, 1, 'The current colour callback did not capture its hero')
assert.equal(heroWindow.__otlobliTemuColorImg, 'https://img.kwcdn.com/selected-hero.jpg')

heroFixture.temuScheduleHeroCapture('101')
const productChangeTimer = Math.min(...liveHeroTimers.keys())
const productChangeCallback = liveHeroTimers.get(productChangeTimer)
liveHeroTimers.delete(productChangeTimer)
heroGoodsId = '202'
productChangeCallback()
assert.equal(liveHeroTimers.size, 0, 'A product change did not cancel all pending hero capture handles')
assert.equal(heroImageReads, 1, 'A stale product callback scanned the new product gallery')

heroWindow.__otlobliTemuColorGid = '202'
heroFixture.temuScheduleHeroCapture('202')
heroChallenge = true
heroFixture.temuCancelHeroCapture()
assert.equal(liveHeroTimers.size, 0, 'Challenge suspension left Temu hero capture timers alive')
heroChallenge = false
heroFixture.temuScheduleHeroCapture('202')
assert.equal(typeof heroListeners.visibilitychange, 'function', 'Temu hero capture has no visibility cancellation hook')
heroListeners.visibilitychange()
assert.equal(liveHeroTimers.size, 0, 'visibilitychange left Temu hero capture timers alive')
assert.ok(!productCaptureSource.includes("document.body.style.overflow = 'hidden'"), 'Add overlay still writes the store/CAPTCHA scroll lock directly')
for (const marker of ['data-otlobli-add-scroll-lock', 'otlobliProductCapturePausedForChallenge()) {\n        overlay.remove(); otlobliReleaseAddingScrollLock(); return;']) {
  assert.ok(productCaptureSource.includes(marker), `Product overlay challenge ownership missing ${marker}`)
}
const blockingSource = readFileSync(resolve(root, 'src/services/storeBlockingScript.ts'), 'utf8')
assert.ok(blockingSource.includes('if (otlobliInterventionPausedForHumanChallenge()) { overlay.remove(); return; }'), 'Loading overlay can swallow fresh challenge input')
const addButtonStart = blockingSource.indexOf('function ensureAddToCartButton(')
const addButtonEnd = blockingSource.indexOf('function ensureBottomNav(', addButtonStart)
const addButtonSource = blockingSource.slice(addButtonStart, addButtonEnd)
assert.ok(addButtonSource.indexOf('if (!onProductPage)') < addButtonSource.indexOf("document.createElement('button')"), 'Home/listing ticks still allocate the PDP action button')
assert.ok(addButtonSource.includes("if (btn.style.display !== targetDisplay) btn.style.display = targetDisplay"), 'PDP action still rewrites layout style every coordinator tick')
assert.ok(temuRuntimeSource.includes('if (otlobliInterventionPausedForHumanChallenge()) { notice.remove(); return; }'), 'Temu loading notice can swallow fresh challenge input')

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
  ['src/services/sheinBrowserScript.ts', '4CB781DB7C4D8CF0FA59D597810D3899CF0F6380C35746E09DB9980224AB5943'],
  ['src/services/storeProductCaptureScript.ts', '4640630FE1A87FED51D49418D00AA83182A2453441192F6DBFB6F7E99FE20183'],
  ['src/services/sheinSkuTap.ts', '6D26FC080244260B13C9CA2B94B87504896F11BD5CFA31CEC76CD479ECC7B2C6'],
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
