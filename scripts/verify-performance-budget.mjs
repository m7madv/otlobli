import { readFileSync, readdirSync, statSync } from 'node:fs'
import { dirname, extname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { gzipSync } from 'node:zlib'
import { INJECTED_SCRIPT_SOURCE, minifyInjectedScriptExports } from './minify-injected-scripts.mjs'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const assetsDir = resolve(projectRoot, 'dist/assets')

// The store scripts are injected into the SHEIN/Temu page as source text, so
// what matters to a two-core iPhone is the size AFTER the build strips
// comments — that is what JavaScriptCore tokenises at documentStart, before the
// store can paint. `shippedStoreScriptsRaw` measures exactly those emitted
// strings and is the real device budget.
//
// `sheinScriptSourceRaw` still exists, but only as a coarse bound on the source
// file. Its old 550,000 ceiling was doing double duty as the device budget, and
// it had grown so tight (67 bytes free) that documenting an optimisation cost
// more budget than the optimisation saved. Comments no longer reach the device,
// so the source may carry its rationale; the device cost is now bounded
// directly, and more tightly, by the measurement above. Do not treat this as
// permission to grow the shipped scripts.
const budgets = {
  startupJavaScriptRaw: 720_000,
  largestJavaScriptRaw: 1_200_000,
  totalJavaScriptGzip: 370_000,
  totalCssRaw: 70_000,
  totalFontsRaw: 100_000,
  shippedStoreScriptsRaw: 470_000,
  sheinScriptSourceRaw: 600_000,
}

// Transpile the store-script module with the same stripping the build applies,
// then measure the template literals it exports — the bytes the WebView gets.
const measureShippedStoreScripts = async () => {
  const { exports } = await minifyInjectedScriptExports(INJECTED_SCRIPT_SOURCE)
  return Object.values(exports)
    .filter((value) => typeof value === 'string')
    .reduce((total, value) => total + Buffer.byteLength(value, 'utf8'), 0)
}

const files = readdirSync(assetsDir).map((name) => {
  const path = resolve(assetsDir, name)
  const raw = readFileSync(path)
  return { name, path, extension: extname(name), raw: raw.length, gzip: gzipSync(raw).length }
})

const js = files.filter((file) => file.extension === '.js')
const css = files.filter((file) => file.extension === '.css')
const fonts = files.filter((file) => file.extension === '.woff2')
const largestJs = js.reduce((largest, file) => file.raw > largest.raw ? file : largest, { name: 'none', raw: 0 })
const totalJsGzip = js.reduce((total, file) => total + file.gzip, 0)
const totalCssRaw = css.reduce((total, file) => total + file.raw, 0)
const totalFontsRaw = fonts.reduce((total, file) => total + file.raw, 0)
const sheinScriptSourceRaw = statSync(resolve(projectRoot, 'src/services/sheinBrowserScript.ts')).size
const indexHtml = readFileSync(resolve(projectRoot, 'dist/index.html'), 'utf8')
const startupJavaScriptNames = [...indexHtml.matchAll(/<script[^>]+src="[^"]*\/assets\/([^"]+\.js)"/g)]
  .map((match) => match[1])
const startupJavaScriptRaw = startupJavaScriptNames.reduce((total, name) => {
  const entry = js.find((file) => file.name === name)
  if (!entry) throw new Error(`Startup JavaScript asset is missing: ${name}`)
  return total + entry.raw
}, 0)
if (startupJavaScriptNames.length === 0) throw new Error('Unable to locate the startup JavaScript entry in dist/index.html')

const measurements = [
  ['startup JavaScript raw', startupJavaScriptRaw, budgets.startupJavaScriptRaw, startupJavaScriptNames.join(', ')],
  ['largest JavaScript raw', largestJs.raw, budgets.largestJavaScriptRaw, largestJs.name],
  ['total JavaScript gzip', totalJsGzip, budgets.totalJavaScriptGzip, 'all JS'],
  ['total CSS raw', totalCssRaw, budgets.totalCssRaw, 'all CSS'],
  ['total fonts raw', totalFontsRaw, budgets.totalFontsRaw, 'all woff2'],
  ['shipped store scripts raw', await measureShippedStoreScripts(), budgets.shippedStoreScriptsRaw, 'injected into the store page, minified'],
  ['SHEIN script source raw', sheinScriptSourceRaw, budgets.sheinScriptSourceRaw, 'src/services/sheinBrowserScript.ts'],
]

const failures = []
console.log('\nLow-end performance budget:\n')
for (const [label, actual, maximum, detail] of measurements) {
  const status = actual <= maximum ? 'OK' : 'FAIL'
  console.log(`- ${status} ${label}: ${actual} / ${maximum} bytes (${detail})`)
  if (actual > maximum) failures.push(`${label} is ${actual} bytes; maximum is ${maximum}`)
}

if (failures.length > 0) {
  console.error('\nPerformance budget FAILED. Preserve features; split/defer code or remove duplication instead of raising the limits.\n')
  for (const failure of failures) console.error(`- ${failure}`)
  console.error('\nRead docs/LOW_END_DEVICE_PERFORMANCE_GUARD.md.\n')
  process.exit(1)
}

console.log('\nLow-end performance budget: OK')
