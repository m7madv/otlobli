#!/usr/bin/env node

import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { extname, resolve } from 'node:path'

const roots = process.argv.slice(2).map((value) => resolve(value))
if (roots.length === 0) throw new Error('Provide one or more extracted Release artifact paths to scan.')

const forbidden = [
  'SHEIN_TAP_DIAGNOSTIC_CONTEXT_JS',
  '__otlobliTapDiagnosticContext',
  '__otlobliFreezeProbe',
  'otlobli-script-diagnostics',
  'SHEIN_IOS_FREEZE_DIAGNOSTICS',
  'VITE_STORE_SCRIPT_DIAGNOSTICS',
  'RAW_WITH_CACHE_GUARD',
  'CAPTURE_ONLY',
  'BLOCKING_ONLY',
  'CAPTURE_AND_BLOCKING',
  'LEGACY_CONTROL',
  'clean-room container',
  'root-cause heartbeat',
]

const failures = []
const walk = (path) => {
  const metadata = statSync(path)
  if (!metadata.isDirectory()) return [path]
  return readdirSync(path).flatMap((entry) => walk(resolve(path, entry)))
}

for (const root of roots) {
  if (!existsSync(root)) {
    failures.push(`missing artifact path: ${root}`)
    continue
  }
  for (const file of walk(root)) {
    if (extname(file).toLowerCase() === '.map') failures.push(`source map shipped: ${file}`)
    const bytes = readFileSync(file)
    for (const marker of forbidden) {
      const ascii = Buffer.from(marker, 'utf8')
      const utf16 = Buffer.from(marker, 'utf16le')
      if (bytes.includes(ascii) || bytes.includes(utf16)) failures.push(`diagnostic marker ${marker} in ${file}`)
    }
  }
}

if (failures.length) {
  console.error('Release artifact scan FAILED:')
  for (const failure of failures) console.error(`- ${failure}`)
  process.exit(1)
}
console.log(`Release artifact scan passed (${roots.length} extracted root${roots.length === 1 ? '' : 's'}).`)
