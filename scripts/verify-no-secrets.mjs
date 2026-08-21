import { execFileSync } from 'node:child_process'
import { extname, resolve } from 'node:path'
import { readFileSync, statSync } from 'node:fs'

const root = resolve(import.meta.dirname, '..')
const files = execFileSync('git', ['ls-files', '--cached', '--others', '--exclude-standard', '-z'], {
  cwd: root,
  encoding: 'utf8',
}).split('\0').filter(Boolean)

const allowedNonProductionCredentials = new Set([
  'android/app/google-services.json', // Firebase client configuration, not a service account.
  'android/debug.keystore', // Android SDK debug identity; release signing rejects it.
])
const forbiddenFileExtensions = new Set(['.p8', '.p12', '.mobileprovision', '.jks'])
const patterns = [
  ['private key PEM', /-----BEGIN (?:EC |RSA )?PRIVATE KEY-----/],
  ['Google service account', /"type"\s*:\s*"service_account"/],
  ['GitHub personal token', /\b(?:ghp|github_pat)_[A-Za-z0-9_]{20,}\b/],
  ['Stripe live secret', /\bsk_live_[A-Za-z0-9]{16,}\b/],
  ['AWS access key', /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/],
]
const failures = []

for (const relativePath of files) {
  const normalized = relativePath.replace(/\\/g, '/')
  if (!allowedNonProductionCredentials.has(normalized) && forbiddenFileExtensions.has(extname(normalized).toLowerCase())) {
    failures.push(`${normalized}: forbidden credential file type`)
  }
  const absolutePath = resolve(root, relativePath)
  let stats
  try { stats = statSync(absolutePath) } catch { continue }
  if (!stats.isFile() || stats.size > 5_000_000) continue
  let contents
  try { contents = readFileSync(absolutePath, 'utf8') } catch { continue }
  for (const [label, pattern] of patterns) {
    if (pattern.test(contents)) failures.push(`${normalized}: ${label}`)
  }
}

if (failures.length) {
  console.error('Secret scan failed (matched values are intentionally not printed):')
  for (const failure of failures) console.error(`- ${failure}`)
  process.exit(1)
}

console.log(`Secret scan passed (${files.length} tracked/untracked source files; values not printed).`)
