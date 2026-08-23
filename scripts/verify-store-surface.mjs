import { readFileSync } from 'node:fs'
import { readStoreScriptSources } from './store-script-sources.mjs'

const plugin = readFileSync(
  new URL('../android/app/src/main/java/com/otlobli/app/TemuEmbeddedBrowserPlugin.java', import.meta.url),
  'utf8',
)
const reporter = readFileSync(
  new URL('../android/app/src/main/java/com/otlobli/app/OtlobliIssueReporterPlugin.java', import.meta.url),
  'utf8',
)
const appEntry = readFileSync(new URL('../src/main.tsx', import.meta.url), 'utf8')
const app = readFileSync(new URL('../src/App.tsx', import.meta.url), 'utf8')
const customerStyles = readFileSync(new URL('../src/styles.css', import.meta.url), 'utf8')
const iosSheinBrowser = readFileSync(
  new URL('../ios/App/App/OtlobliSheinBrowserPlugin.swift', import.meta.url),
  'utf8',
)
const inAppBrowserPatch = readFileSync(
  new URL('../patches/@capgo+capacitor-inappbrowser+8.6.25.patch', import.meta.url),
  'utf8',
)
const captureScript = readStoreScriptSources(new URL('..', import.meta.url))
const runtimeCoordinator = readFileSync(
  new URL('../src/services/storeRuntimeCoordinator.ts', import.meta.url),
  'utf8',
)
const extensionBuilder = readFileSync(new URL('./build-temu-gecko-extension.mjs', import.meta.url), 'utf8')

const requiredPluginMarkers = [
  'private static final int OTLBLI_NAV_RESERVE_DP = 90;',
  'WindowInsets.Type.navigationBars()',
  'insets.getSystemWindowInsetBottom()',
  'dp(OTLBLI_NAV_RESERVE_DP) + Math.max(0, navigationBarInset)',
  'storeLayer.setAlpha(1f);',
  'storeLayer.setVisibility(View.GONE);',
  'settings.setSuspendMediaWhenInactive(true);',
  'protected void handleOnPause()',
  'protected void handleOnResume()',
  'public void acknowledgeAdd(PluginCall call)',
  'private PendingAddRequest beginPendingAddRequest()',
  'detail.put("requestId", addRequest.requestId);',
  'takePendingAddRequest(requestedId.isEmpty() ? null : requestedId)',
  'ADD_ACK_TIMEOUT_MS = 3500L',
]

for (const marker of requiredPluginMarkers) {
  if (!plugin.includes(marker)) {
    throw new Error(`Store surface guard missing plugin marker: ${marker}`)
  }
}

for (const marker of [
  'handlePersonalTemuHomeTap()',
  'onNavigate={(target, activationDetail) => {',
  'if (activationDetail === 0)',
  "onClick={(event) => onNavigate('home', event.detail)}",
  'اضغط مرتين على الرئيسية لتبديل المتجر',
  'TemuEmbeddedBrowser.acknowledgeAdd({ requestId: temuCaptureRequestId })',
  'items.some((item) => item.id === itemId)',
]) {
  if (!app.includes(marker)) throw new Error(`Temu store-return/capture guard missing App marker: ${marker}`)
}

for (const marker of [
  'var homeDoubleTapMs = 320',
  "event.type === 'click' && now - lastPhysicalTouchAt < 450",
  'homeTapTimer = setTimeout(finishSingleHomeTap, homeDoubleTapMs)',
  "event.type === 'click' && event.detail === 0",
  "window.mobileApp.postMessage({ detail: { type: 'closeStore' } })",
]) {
  if (!captureScript.includes(marker)) throw new Error(`Injected store-switch gesture guard missing marker: ${marker}`)
}

for (const forbidden of ['location.assign(location.origin + homePath)', 'TemuEmbeddedBrowser.goHome().catch']) {
  if (captureScript.includes(forbidden) || app.includes(forbidden)) {
    throw new Error(`Single Home tap must not reload or navigate the active store: ${forbidden}`)
  }
}

for (const marker of [
  "btn.setAttribute('aria-label', IS_TEMU ? 'العودة إلى اختيار المتجر' : 'رجوع')",
  'function otlobliTemuHomeLikeUrl()',
  'function otlobliStoreHomeRoot()',
  'var storeHomeRoot = otlobliStoreHomeRoot()',
]) {
  if (!captureScript.includes(marker)) throw new Error(`Temu root-exit guard missing marker: ${marker}`)
}

for (const marker of [
  "if (typeof ensureBackButton === 'function') ensureBackButton();",
  '[class*="topTabContainer"] [class*="tab-"]',
  'now - __otlobliTemuVitalsCacheAt < 240',
]) {
  if (!captureScript.includes(marker)) throw new Error(`Temu iPhone stability guard missing marker: ${marker}`)
}
for (const forbidden of [
  '__otlobliTemuScrollRehideBound',
  'a,button,[role="button"],div,section,aside,nav,header',
]) {
  if (captureScript.includes(forbidden)) throw new Error(`Temu hot-path scan regression detected: ${forbidden}`)
}
if (runtimeCoordinator.includes('otlobliCleanTemuBlockers(true)')) {
  throw new Error('Temu navigation maintenance must not force a blocker scan')
}

for (const marker of [
  'var valueCountry = sheinCountryCodeFromLabel(rawValue);',
  'var repairStalledFor = repairNow - Math.max(sheinShippingProgressAt || 0, sheinNativeCoverRepairStartedAt);',
  'var repairAbsoluteLimit = OTLOBLI_LOW_END ? 45000 : 36000;',
  "'جاري إكمال عنوان الشحن داخل ' + requiredCountryLabel",
]) {
  if (!captureScript.includes(marker)) throw new Error(`SHEIN Qatar cascade guard missing marker: ${marker}`)
}

const temuHomeLikePath = (rawPath) => {
  const path = String(rawPath || '/').replace(/\/{2,}/g, '/').replace(/\/+$/, '')
  return !path || /^\/[a-z]{2}(?:-[a-z]{2})?$/i.test(path)
}
for (const [path, expected] of [
  ['/', true],
  ['/qa/', true],
  ['/qa-en/', true],
  ['/goods.html', false],
  ['/qa/search_result.html', false],
  ['/qa/channel/1001.html', false],
]) {
  if (temuHomeLikePath(path) !== expected) {
    throw new Error(`Temu root classifier misclassified ${path}`)
  }
}

for (const marker of [
  'private func makeLoadingNavigation() -> UIView',
  'private func makeLoadingNavigationIcon(route: String, color: UIColor) -> UIImage',
  'configuration.image = makeLoadingNavigationIcon(route: routes[index], color: color)',
  'button.accessibilityIdentifier = routes[index]',
  '@objc private func loadingNavigationPressed(_ sender: UIButton)',
  'if UIAccessibility.isVoiceOverRunning',
  'navigateHost(to: target)',
  'parkRenderSurfaceBehindApp()',
  'let revealHost = DispatchWorkItem',
  'DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: revealHost)',
  "window.dispatchEvent(new CustomEvent('otlobli:nativeNavigate'",
  'if nativeBackTarget == "orders"',
  'emit("messageFromWebview", detail: ["type": "backToOrders"])',
]) {
  if (!iosSheinBrowser.includes(marker)) {
    throw new Error(`iOS loading navigation guard missing marker: ${marker}`)
  }
}

for (const forbidden of ['UIImage(systemName: "house")', 'UIImage(systemName: symbols[index])']) {
  if (iosSheinBrowser.includes(forbidden)) {
    throw new Error(`iOS loading navigation must copy the permanent Otlobli icon paths: ${forbidden}`)
  }
}

for (const marker of [
  'order-card-footer',
  'order-card-id',
  'رقم الطلب ${item.id}',
  'const openStoreProductFromOrder = (sourceLink: string, fallbackStore: StoreId)',
  "openStoreProductFromCart(sourceLink, 'orders')",
  "screen === 'home' && pendingBackTargetRef.current === 'orders'",
  "returnTarget === 'orders' && (screenRef.current === 'tracking' || screenRef.current === 'home')",
  'className="tracking-product-button"',
  "detail?.type === 'backToOrders'",
]) {
  if (!app.includes(marker)) throw new Error(`Order-number visibility guard missing App marker: ${marker}`)
}

const orderProductOpenStart = app.indexOf('const openStoreProductFromOrder = (sourceLink: string, fallbackStore: StoreId)')
const orderProductOpenEnd = app.indexOf('const openStoreFromHub = (id: StoreId)', orderProductOpenStart)
const orderProductOpenSource = app.slice(orderProductOpenStart, orderProductOpenEnd)
const orderWarmOpen = orderProductOpenSource.indexOf("openStoreProductFromCart(sourceLink, 'orders')")
const orderImmediateHome = orderProductOpenSource.indexOf("screenRef.current = 'home'", orderWarmOpen)
const orderImmediateCommit = orderProductOpenSource.indexOf("flushSync(() => setScreen('home'))", orderImmediateHome)
if (orderProductOpenStart < 0 || orderProductOpenEnd < 0 || orderWarmOpen < 0 ||
    orderImmediateHome < orderWarmOpen || orderImmediateCommit < orderImmediateHome) {
  throw new Error('Order product must enter the warm store flow and commit Home immediately on tap')
}
if (!/\.mobile-content--orders\s*\{[^}]*grid-auto-rows:\s*max-content/s.test(customerStyles)) {
  throw new Error('Orders grid must size each order card from its full content so the footer cannot be clipped')
}

for (const marker of [
  'private void otlobliHandleLoadingNavigationTap(String target)',
  'accessibilityManager.isTouchExplorationEnabled()',
  'private void otlobliNavigateHost(String target)',
  'tab.setOnClickListener(view -> otlobliHandleLoadingNavigationTap',
  'guard let self else { return }',
  'The native back control is also required by Temu',
  '["cart", "orders", "exit"].contains(target)',
  '["type": "backToOrders"]',
]) {
  if (!inAppBrowserPatch.includes(marker)) {
    throw new Error(`Native loading/root-exit patch guard missing marker: ${marker}`)
  }
}

if (app.includes('temuAddInFlightRef')) {
  throw new Error('Temu capture must not use a process-wide latch that can block later products')
}

for (const marker of [
  'window.__otlobliAddSafetyTimer = setTimeout',
  "if (detail && detail.type === 'addToCartNack')",
  'clearAddSafetyTimer();',
]) {
  if (!captureScript.includes(marker)) throw new Error(`Capture fail-safe guard missing marker: ${marker}`)
}

if (!extensionBuilder.includes("detail: { type: 'addToCartNack' }")) {
  throw new Error('Temu extension must surface a rejected cart acknowledgement')
}

if (/storeLayer\.setElevation\s*\(/.test(plugin)) {
  throw new Error('Store surface must not cast an elevation shadow over the React navigation')
}

if (/storeLayer\.animate\(\)\.alpha\(/.test(plugin)) {
  throw new Error('Temu store surface must reveal atomically without a white navigation flash')
}

if (/FLAG_DIM_BEHIND|dimAmount|setDimAmount/.test(plugin)) {
  throw new Error('Embedded Temu surface must not dim MainActivity')
}

const hideStart = plugin.indexOf('private void hideStoreLayer()')
const hideEnd = plugin.indexOf('private void ensureSessionAndOpen(', hideStart)
if (hideStart < 0 || hideEnd < 0) {
  throw new Error('Unable to inspect the store-surface hide lifecycle')
}
const hideBody = plugin.slice(hideStart, hideEnd)
for (const forbidden of ['session.close(', 'releaseSession(', 'setSession(null)']) {
  if (hideBody.includes(forbidden)) {
    throw new Error(`Hiding Temu must preserve its Gecko session: ${forbidden}`)
  }
}

const pauseStart = plugin.indexOf('protected void handleOnPause()')
const resumeStart = plugin.indexOf('protected void handleOnResume()', pauseStart)
const destroyStart = plugin.indexOf('protected void handleOnDestroy()', resumeStart)
if (pauseStart < 0 || resumeStart < 0 || destroyStart < 0) {
  throw new Error('Unable to inspect the Temu app background/resume lifecycle')
}
const pauseBody = plugin.slice(pauseStart, resumeStart)
const resumeBody = plugin.slice(resumeStart, destroyStart)
if (!pauseBody.includes('session.setActive(false);') || !resumeBody.includes('session.setActive(true);')) {
  throw new Error('Temu must become inactive in background and reactivate only when its surface is visible')
}

for (const marker of [
  'memoryGb <= 4',
  "document.documentElement.dataset.otlobliPerformance = 'low'",
  "lowEndStyle.id = 'otlobli-low-end-style'",
  'content-visibility:auto',
]) {
  if (!appEntry.includes(marker)) throw new Error(`Low-end Android runtime profile is missing: ${marker}`)
}

for (const marker of ['findLargestVisibleSurface', 'PixelCopy.request(storeSurface', 'captureWindow(']) {
  if (!reporter.includes(marker)) {
    throw new Error(`Store screenshot guard missing reporter marker: ${marker}`)
  }
}

console.log('Store surface geometry, opacity, dim and screenshot guard: OK')
