import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8')
const fail = (message) => {
  console.error(`SHEIN clean-room guard failed: ${message}`)
  process.exitCode = 1
}
const requireText = (source, text, label) => {
  if (!source.includes(text)) fail(`${label} is missing ${JSON.stringify(text)}`)
}
const rejectText = (source, text, label) => {
  if (source.includes(text)) fail(`${label} unexpectedly contains ${JSON.stringify(text)}`)
}

const mode = read('ios/App/App/SheinCleanBrowser/SheinCleanBrowserMode.swift')
const scripts = read('ios/App/App/SheinCleanBrowser/SheinCleanBrowserScripts.swift')
const controller = read('ios/App/App/SheinCleanBrowser/SheinCleanBrowserViewController.swift')
const plugin = read('ios/App/App/SheinCleanBrowser/SheinCleanBrowserPlugin.swift')
const bridge = read('ios/App/App/OtlobliBridgeViewController.swift')
const storeBrowser = read('src/services/storeBrowser.ts')
const app = read('src/App.tsx')
const config = read('src/config.ts')
const project = read('ios/App/App.xcodeproj/project.pbxproj')
const recorder = read('scripts/capture-shein-cdp-network.mjs')
const legacyPath = path.join(root, 'ios/App/App/OtlobliSheinBrowserPlugin.swift')
const legacyHash = crypto.createHash('sha256').update(fs.readFileSync(legacyPath)).digest('hex')

const expectedModes = [
  'case raw = 0',
  'case rawWithCacheGuard = 1',
  'case captureOnly = 2',
  'case blockingOnly = 3',
  'case captureAndBlocking = 4',
  'case legacyControl = 5',
]
for (const expected of expectedModes) requireText(mode, expected, 'mode list')

for (const rawName of ['RAW', 'RAW_WITH_CACHE_GUARD', 'CAPTURE_ONLY', 'BLOCKING_ONLY', 'CAPTURE_AND_BLOCKING', 'LEGACY_BROWSER_CONTROL']) {
  requireText(mode, `"${rawName}"`, 'mode wire identity')
}

const exactRuleFragments = [
  '"url-filter": "^https://sheinm\\\\.ltwebstatic\\\\.com/pwa_dist/assets/.*\\\\.js"',
  '"url-filter-is-case-sensitive": true',
  '"resource-type": ["raw"]',
  '"type": "block"',
]
for (const fragment of exactRuleFragments) requireText(mode, fragment, 'exact cache guard')
rejectText(mode, '"resource-type": ["script"]', 'cache guard')
const encodedRule = mode.match(/static let json = #"""([\s\S]*?)"""#/)?.[1]
if (!encodedRule) {
  fail('exact cache guard JSON literal could not be extracted')
} else {
  try {
    const parsed = JSON.parse(encodedRule)
    if (parsed.length !== 1 || parsed[0]?.trigger?.['resource-type']?.join(',') !== 'raw' ||
        parsed[0]?.action?.type !== 'block') {
      fail('exact cache guard JSON parsed to an unexpected rule')
    }
  } catch (error) {
    fail(`exact cache guard JSON does not parse: ${error.message}`)
  }
}

requireText(scripts, 'var scripts = [WKUserScript(', 'RAW diagnostic-only script list')
requireText(scripts, 'source: passiveDiagnostics(runId: runId, mode: mode)', 'RAW passive probe')
requireText(scripts, 'if mode.usesCapture', 'capture module boundary')
requireText(scripts, 'source: captureModule', 'capture module boundary')
requireText(scripts, 'if mode.usesBlocking', 'blocking module boundary')
requireText(scripts, 'source: blockingModule', 'blocking module boundary')
for (const legacyMarker of [
  'SHEIN_CAPTURE_SCRIPT',
  'SHEIN_SESSION_SCRIPT',
  'OTLOBLI_NAV_BOOTSTRAP_SCRIPT',
  'SHEIN_PRIVACY_COMPAT_SCRIPT',
  '__otlobliRootCauseProbe',
  'window.mobileApp',
]) rejectText(scripts, legacyMarker, 'clean scripts')

for (const networkPatch of ['XMLHttpRequest.prototype', 'window.fetch =', 'history.pushState =', 'history.replaceState =']) {
  rejectText(scripts, networkPatch, 'passive diagnostics')
}

const blockingSource = scripts.slice(scripts.indexOf('static let blockingModule'))
for (const forbiddenSelector of [
  '[class*="login',
  '[class*="captcha',
  '[class*="privacy',
  '[class*="risk',
  'preventDefault()',
  'stopPropagation()',
  'pointer-events',
]) rejectText(blockingSource, forbiddenSelector, 'clean blocking module')

requireText(controller, 'static let guestLandingURL = URL(string: "https://m.shein.com/")!', 'public guest URL')
requireText(controller, 'guard webView.canGoBack, !root else', 'canonical-root Back guard')
requireText(controller, 'webView.goBack()', 'native Back behavior')
requireText(controller, '// Evidence only. No reload, recreation, recovery, or store switch.', 'termination evidence boundary')
rejectText(controller, '.reload(', 'clean controller')
rejectText(controller, 'WKWebsiteDataStore.default()', 'clean controller storage')
rejectText(controller, 'forceStoreVpnRecheck', 'clean controller')

requireText(plugin, 'WKWebsiteDataStore(forIdentifier: identifier)', 'persistent per-mode profile')
requireText(plugin, 'guard #available(iOS 17.0, *)', 'profile availability gate')
requireText(plugin, 'setUrl is disabled for the locked clean-room session', 'host navigation isolation')
requireText(plugin, 'Host script execution is disabled for clean-room modes', 'host script isolation')
requireText(plugin, 'Mode containers are evidence. Never clear or mutate them implicitly.', 'mode cache preservation')
rejectText(plugin, 'otlobliDocumentStartScript', 'clean plugin')

if (legacyHash !== '6a6d6a16a5eed040618988c9d5b5ac6d8f88ddd187f4bc095c0f1c1aa710382e') {
  fail(`legacy OtlobliSheinBrowserPlugin.swift changed (${legacyHash})`)
}

requireText(bridge, 'registerPluginInstance(SheinCleanBrowserPlugin())', 'native plugin registration')
requireText(storeBrowser, "registerPlugin<NativeSheinBrowserApi>('SheinCleanBrowser')", 'TypeScript plugin registration')
requireText(storeBrowser, "implementation !== 'legacy-control'", 'Mode 5 legacy routing')
requireText(storeBrowser, 'isCleanSheinSession()', 'clean host boundary')
for (const hostBoundary of [
  'clean-room-host-region-change-ignored',
  'if (InAppBrowser.isCleanSheinSession()) return',
  'clean-room-page-loaded-host-runtime-skipped',
  'isCleanSheinDiagnosticWebview(id)',
  'currentVpnState !== \'ok\' && !cleanRoomDiagnosticEntry',
]) requireText(app, hostBoundary, 'clean host isolation')
requireText(config, 'VITE_SHEIN_CLEAN_ROOM_DIAGNOSTICS', 'diagnostic feature flag')
requireText(config, "VITE_SHEIN_CLEAN_ROOM_DIAGNOSTICS ?? 'true'", 'diagnostic IPA default')
requireText(config, "'2026.08.21-v86.204-shein-clean-room'", 'diagnostic version marker')
for (const privacyBoundary of [
  '--mode=',
  '--run-id=',
  '--container=',
  'URLs exclude query/fragment; headers/cookies/tokens/storage values are excluded',
  "(?:cookie|token|authorization|signature|storage|address|account|headers)",
]) requireText(recorder, privacyBoundary, 'CDP evidence privacy boundary')

for (const file of [
  'SheinCleanBrowserMode.swift',
  'SheinCleanBrowserScripts.swift',
  'SheinCleanBrowserViewController.swift',
  'SheinCleanBrowserPlugin.swift',
]) requireText(project, `${file} in Sources`, 'Xcode source membership')
requireText(project, 'CURRENT_PROJECT_VERSION = 1066;', 'iOS build number')
requireText(project, 'MARKETING_VERSION = 86.204;', 'iOS marketing version')

if (!process.exitCode) {
  console.log('SHEIN clean-room guard passed: RAW isolation, exact raw-only guard, independent modules, persistent mode profiles, and unchanged legacy browser verified.')
}
