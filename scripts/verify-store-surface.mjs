import { readFileSync } from 'node:fs'

const plugin = readFileSync(
  new URL('../android/app/src/main/java/com/otlobli/app/TemuEmbeddedBrowserPlugin.java', import.meta.url),
  'utf8',
)
const reporter = readFileSync(
  new URL('../android/app/src/main/java/com/otlobli/app/OtlobliIssueReporterPlugin.java', import.meta.url),
  'utf8',
)

const requiredPluginMarkers = [
  'private static final int OTLBLI_NAV_RESERVE_DP = 90;',
  'WindowInsets.Type.navigationBars()',
  'insets.getSystemWindowInsetBottom()',
  'dp(OTLBLI_NAV_RESERVE_DP) + Math.max(0, navigationBarInset)',
  'storeLayer.animate().alpha(1f).setDuration(110L).start();',
  'storeLayer.setAlpha(1f);',
  'storeLayer.setVisibility(View.GONE);',
]

for (const marker of requiredPluginMarkers) {
  if (!plugin.includes(marker)) {
    throw new Error(`Store surface guard missing plugin marker: ${marker}`)
  }
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

for (const marker of ['findLargestVisibleSurface', 'PixelCopy.request(storeSurface', 'captureWindow(']) {
  if (!reporter.includes(marker)) {
    throw new Error(`Store screenshot guard missing reporter marker: ${marker}`)
  }
}

console.log('Store surface geometry, opacity, dim and screenshot guard: OK')
