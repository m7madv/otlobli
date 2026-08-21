import { createHash } from 'node:crypto'
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs'
import { dirname, extname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const failures = []

const read = (file) => readFileSync(resolve(projectRoot, file), 'utf8')
const sha256 = (file) => createHash('sha256').update(readFileSync(resolve(projectRoot, file))).digest('hex').toUpperCase()

const protectedCaptureHashes = new Map([
  ['src/services/sheinBrowserScript.ts', '6793A8C52D46A8B4F29722A6A6E22B9ABB9B1C35FD95C1A77D0BD14DB46272FC'],
  ['src/services/storeProductCaptureScript.ts', '5A5E2E99A3656E143C108DC2E56463B5214FBDFC4EB030D120806E79BAF41788'],
  ['src/services/sheinSkuTap.ts', 'F675AF9D4FC75595914DF97D907FEE2472691204EEF89F89844871662F676619'],
  ['src/services/storeBrowser.ts', 'A54E19DF8E66B2D49C7B227DD24C7C6B43B2593E97C88047D76D5827DC5452B7'],
  ['src/services/storeRuntimeCoordinator.ts', 'A06E41D1504C2DA20DA8CA7F23E057F1DC51E0AB940417AAD18F0C4890EC8C6B'],
  ['src/domain/types.ts', '5FA37D5ABB06BEBD0ED6B9E6ED62393A70A2F18556D44172259598387FC59175'],
])

for (const [file, expected] of protectedCaptureHashes) {
  const actual = sha256(file)
  if (actual !== expected) failures.push(`protected capture changed: ${file} (${actual})`)
}

const releaseSources = [
  'src/App.tsx',
  'src/config.ts',
  'src/services/storeCaptureBundle.ts',
  'src/services/sheinPolicyEngine.ts',
  'src/services/sheinRegionCoordinator.ts',
  'src/services/sheinOpeningPerformance.ts',
  'src/services/pushNotifications.ts',
  'ios/App/App/OtlobliSheinBrowserPlugin.swift',
  'patches/@capgo+capacitor-inappbrowser+8.6.25.patch',
]
const sourceText = releaseSources.map(read).join('\n')
const bannedMarkers = [
  'SHEIN_TAP_DIAGNOSTIC_CONTEXT_JS',
  '__otlobliTapDiagnostic',
  '__otlobliTapDiagnosticContext',
  '__otlobliFreezeProbe',
  'otlobli-script-diagnostics',
  'storeScriptFlagsChanged',
  'SHEIN_IOS_FREEZE_DIAGNOSTICS',
  'VITE_STORE_SCRIPT_DIAGNOSTICS',
  'RAW_WITH_CACHE_GUARD',
  'CAPTURE_ONLY',
  'BLOCKING_ONLY',
  'CAPTURE_AND_BLOCKING',
  'LEGACY_CONTROL',
  'PREFETCH_FIX',
  '__otlobliTapDiagnosticContext',
  'clean-room container',
  'root-cause heartbeat',
]
for (const marker of bannedMarkers) {
  if (sourceText.includes(marker)) failures.push(`release source contains diagnostic marker: ${marker}`)
}

const nativeBrowser = read('ios/App/App/OtlobliSheinBrowserPlugin.swift')
if (!nativeBrowser.includes('#if DEBUG') || !nativeBrowser.includes('webView.isInspectable = false')) {
  failures.push('custom SHEIN WKWebView must be inspectable only under DEBUG and false in Release')
}
const xcodeProject = read('ios/App/App.xcodeproj/project.pbxproj')
if (!xcodeProject.includes('PrivacyInfo.xcprivacy in Resources')) {
  failures.push('iOS privacy manifest must be part of the Release resources phase')
}
const privacyManifest = read('ios/App/App/PrivacyInfo.xcprivacy')
for (const marker of ['NSPrivacyTracking', 'NSPrivacyCollectedDataTypes', 'NSPrivacyAccessedAPICategoryUserDefaults', 'CA92.1']) {
  if (!privacyManifest.includes(marker)) failures.push(`iOS privacy manifest missing ${marker}`)
}
const patchedBrowser = read('node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/WKWebViewController.swift')
if (patchedBrowser.includes('webView.isInspectable = true')) {
  failures.push('Capgo WKWebView still forces Web Inspector on')
}

function walkFiles(directory) {
  if (!existsSync(directory)) return []
  const out = []
  for (const entry of readdirSync(directory)) {
    const path = resolve(directory, entry)
    if (statSync(path).isDirectory()) out.push(...walkFiles(path))
    else out.push(path)
  }
  return out
}

const artifactArgument = process.argv.find((value) => value.startsWith('--artifacts'))
if (artifactArgument) {
  const platform = artifactArgument.split('=')[1] ?? 'all'
  const roots = ['dist']
  if (platform === 'all' || platform === 'ios') roots.push('ios/App/App/public')
  if (platform === 'all' || platform === 'android') roots.push('android/app/src/main/assets/public')
  const textExtensions = new Set(['.js', '.css', '.html', '.json', '.xml'])
  for (const root of roots) {
    const absoluteRoot = resolve(projectRoot, root)
    if (!existsSync(absoluteRoot)) {
      failures.push(`generated release assets missing: ${root}`)
      continue
    }
    for (const file of walkFiles(absoluteRoot)) {
      if (!textExtensions.has(extname(file).toLowerCase())) continue
      const content = readFileSync(file, 'utf8')
      for (const marker of bannedMarkers) {
        if (content.includes(marker)) failures.push(`generated asset contains ${marker}: ${file}`)
      }
    }
  }
}

if (failures.length) {
  console.error('Production release guard failed:')
  for (const failure of failures) console.error(`- ${failure}`)
  process.exit(1)
}

console.log(`Production release guard passed (${protectedCaptureHashes.size} protected capture hashes).`)
