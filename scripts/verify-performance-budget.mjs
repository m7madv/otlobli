import { readFileSync, readdirSync, statSync } from 'node:fs'
import { dirname, extname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { gzipSync } from 'node:zlib'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const assetsDir = resolve(projectRoot, 'dist/assets')

const budgets = {
  largestJavaScriptRaw: 1_200_000,
  totalJavaScriptGzip: 370_000,
  totalCssRaw: 70_000,
  totalFontsRaw: 100_000,
  sheinScriptSourceRaw: 550_000,
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

const measurements = [
  ['largest JavaScript raw', largestJs.raw, budgets.largestJavaScriptRaw, largestJs.name],
  ['total JavaScript gzip', totalJsGzip, budgets.totalJavaScriptGzip, 'all JS'],
  ['total CSS raw', totalCssRaw, budgets.totalCssRaw, 'all CSS'],
  ['total fonts raw', totalFontsRaw, budgets.totalFontsRaw, 'all woff2'],
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
