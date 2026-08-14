import { readFileSync, readdirSync } from 'node:fs'
import { dirname, extname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { INJECTED_SCRIPT_SOURCE, minifyInjectedScriptExports } from './minify-injected-scripts.mjs'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const failures = []
const read = (path) => readFileSync(resolve(projectRoot, path), 'utf8')

const requireMarkers = (label, path, markers) => {
  const contents = read(path)
  for (const marker of markers) {
    if (!contents.includes(marker)) failures.push(`${label}: missing ${JSON.stringify(marker)} in ${path}`)
  }
}

requireMarkers('Android release optimizer', 'android/app/build.gradle', [
  'minifyEnabled true',
  'shrinkResources true',
  "getDefaultProguardFile('proguard-android-optimize.txt')",
  'debuggable false',
  'jniDebuggable false',
])
requireMarkers('Android extraction controls', 'android/app/src/main/AndroidManifest.xml', [
  'android:allowBackup="false"',
  'android:fullBackupContent="false"',
  'android:dataExtractionRules="@xml/data_extraction_rules"',
  'android:usesCleartextTraffic="false"',
])
requireMarkers('Android R8 reflection controls', 'android/app/proguard-rules.pro', [
  '-keepattributes RuntimeVisibleAnnotations,RuntimeInvisibleAnnotations,AnnotationDefault',
  '@android.webkit.JavascriptInterface <methods>;',
  '-renamesourcefileattribute SourceFile',
])
for (const path of [
  'patches/@capacitor+android+8.4.0.patch',
  'node_modules/@capacitor/android/capacitor/proguard-rules.pro',
]) {
  requireMarkers('Capacitor narrow reflection keep rules', path, [
    '-keep,allowoptimization @com.getcapacitor.annotation.CapacitorPlugin public class *',
    'public <init>();',
  ])
  const broadKeep = path.startsWith('patches/')
    ? '\n+ -keep public class * extends com.getcapacitor.Plugin { *; }'
    : '-keep public class * extends com.getcapacitor.Plugin { *; }'
  if (read(path).includes(broadKeep)) {
    failures.push(`Capacitor narrow reflection keep rules: broad plugin-code keep returned in ${path}`)
  }
}
requireMarkers('production injected-script minifier', 'vite.config.ts', [
  "import { minifyInjectedScripts } from './scripts/minify-injected-scripts.mjs'",
  'plugins: [minifyInjectedScripts(), stripStoreScriptComments(), react()]',
  'sourcemap: false',
])
requireMarkers('patch-compatible dependency pins', 'package.json', [
  '"@capacitor/android": "8.4.0"',
  '"@capacitor/core": "8.4.0"',
  '"@capacitor/ios": "8.4.0"',
  '"@capgo/capacitor-inappbrowser": "8.6.25"',
  '"vite": "8.0.16"',
  '"terser": "5.50.0"',
])
const inAppBrowserPatch = read('patches/@capgo+capacitor-inappbrowser+8.6.25.patch')
const relayPlaceholderCount = inAppBrowserPatch.split('OTLOBLI_RELAY_KEY_PLACEHOLDER').length - 1
if (relayPlaceholderCount !== 2) {
  failures.push(`relay secret hygiene: expected two build-time placeholders in the native patch, found ${relayPlaceholderCount}`)
}
for (const pattern of [
  /private static final String OTLOBLI_RELAY_KEY = "(?!OTLOBLI_RELAY_KEY_PLACEHOLDER)[^"]+"/,
  /static let otlobliRelayKey = "(?!OTLOBLI_RELAY_KEY_PLACEHOLDER)[^"]+"/,
]) {
  if (pattern.test(inAppBrowserPatch)) failures.push('relay secret hygiene: a live relay key is committed in the native patch')
}

const pbx = read('ios/App/App.xcodeproj/project.pbxproj')
for (const setting of [
  'COPY_PHASE_STRIP = YES;',
  'DEAD_CODE_STRIPPING = YES;',
  'DEPLOYMENT_POSTPROCESSING = YES;',
  'ENABLE_TESTABILITY = NO;',
  'STRIP_INSTALLED_PRODUCT = YES;',
  'STRIP_STYLE = all;',
  'STRIP_SWIFT_SYMBOLS = YES;',
]) {
  const occurrences = pbx.split(setting).length - 1
  if (occurrences < 2) failures.push(`iOS Release stripping: expected ${setting} in project and app target Release settings`)
}

try {
  const { exports, metrics } = await minifyInjectedScriptExports(INJECTED_SCRIPT_SOURCE)
  for (const [name, source] of Object.entries(exports)) {
    new Function(source)
    const metric = metrics[name]
    if (metric.minifiedBytes >= metric.originalBytes) {
      failures.push(`injected-script minifier: ${name} did not shrink (${metric.minifiedBytes}/${metric.originalBytes})`)
    }
  }
  const combined = Object.values(exports).join('\n')
  for (const readableSignature of [
    'function sheinSkuMemo',
    'function otlobliInstallNavTouchBridge',
    'function sheinTrackSelectedSkuPrice',
    'function ensureOtlobliNav',
  ]) {
    if (combined.includes(readableSignature)) {
      failures.push(`injected-script minifier: readable implementation signature remains: ${readableSignature}`)
    }
  }
} catch (error) {
  failures.push(`injected-script minifier: ${error instanceof Error ? error.message : String(error)}`)
}

if (process.argv.includes('--dist')) {
  const assetsDir = resolve(projectRoot, 'dist/assets')
  const assets = readdirSync(assetsDir)
  const sourceMaps = assets.filter((name) => extname(name) === '.map')
  if (sourceMaps.length > 0) failures.push(`release bundle: source maps shipped (${sourceMaps.join(', ')})`)
  const javascript = assets
    .filter((name) => extname(name) === '.js')
    .map((name) => readFileSync(resolve(assetsDir, name), 'utf8'))
    .join('\n')
  for (const readableSignature of [
    'function sheinSkuMemo',
    'function otlobliInstallNavTouchBridge',
    'function sheinTrackSelectedSkuPrice',
    'function ensureOtlobliNav',
  ]) {
    if (javascript.includes(readableSignature)) {
      failures.push(`release bundle: readable injected implementation remains: ${readableSignature}`)
    }
  }
  for (const forbiddenSecretMarker of [
    'OTLOBLI_APP_STORE_PASSWORD',
    'OTLOBLI_APP_KEY_PASSWORD',
    'SUPABASE_SERVICE_ROLE_KEY',
    'BEGIN PRIVATE KEY',
  ]) {
    if (javascript.includes(forbiddenSecretMarker)) {
      failures.push(`release bundle: forbidden secret marker shipped: ${forbiddenSecretMarker}`)
    }
  }
}

if (failures.length > 0) {
  console.error('\nRelease hardening FAILED:\n')
  for (const failure of failures) console.error(`- ${failure}`)
  process.exit(1)
}

console.log('Release hardening: OK')
