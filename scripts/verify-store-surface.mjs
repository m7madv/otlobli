import { readFileSync } from 'node:fs'

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
const captureScript = readFileSync(new URL('../src/services/sheinBrowserScript.ts', import.meta.url), 'utf8')
const extensionBuilder = readFileSync(new URL('./build-temu-gecko-extension.mjs', import.meta.url), 'utf8')

const requiredPluginMarkers = [
  'private static final int OTLBLI_NAV_RESERVE_DP = 90;',
  'WindowInsets.Type.navigationBars()',
  'insets.getSystemWindowInsetBottom()',
  'dp(OTLBLI_NAV_RESERVE_DP) + Math.max(0, navigationBarInset)',
  'storeLayer.animate().alpha(1f).setDuration(110L).start();',
  'storeLayer.setAlpha(1f);',
  'storeLayer.setVisibility(View.GONE);',
  'settings.setSuspendMediaWhenInactive(true);',
  'protected void handleOnPause()',
  'protected void handleOnResume()',
  'public void acknowledgeAdd(PluginCall call)',
  'private GeckoResult<Object> beginPendingAddResult()',
  'ADD_ACK_TIMEOUT_MS = 3500L',
]

for (const marker of requiredPluginMarkers) {
  if (!plugin.includes(marker)) {
    throw new Error(`Store surface guard missing plugin marker: ${marker}`)
  }
}

for (const marker of [
  "homeDestination={personalTemuSurfaceActive ? 'stores' : 'home'}",
  'setStoreSwitchHintSeen(true)',
  'TemuEmbeddedBrowser.acknowledgeAdd()',
]) {
  if (!app.includes(marker)) throw new Error(`Temu store-return/capture guard missing App marker: ${marker}`)
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
