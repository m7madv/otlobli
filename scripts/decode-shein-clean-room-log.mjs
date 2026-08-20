import { readFileSync } from 'node:fs'

const inputPath = process.argv[2]
if (!inputPath) {
  throw new Error('Usage: node scripts/decode-shein-clean-room-log.mjs unified.log > decoded.jsonl')
}

const prefix = '[OTLOBLI_SHEIN_CLEAN]'
const lines = readFileSync(inputPath, 'utf8').split(/\r?\n/)
let decoded = 0

for (const [index, line] of lines.entries()) {
  const prefixAt = line.indexOf(prefix)
  if (prefixAt < 0) continue
  const jsonAt = line.indexOf('{', prefixAt + prefix.length)
  const jsonEnd = line.lastIndexOf('}')
  if (jsonAt < 0 || jsonEnd < jsonAt) continue
  const raw = line.slice(jsonAt, jsonEnd + 1)
  try {
    const record = JSON.parse(raw)
    process.stdout.write(`${JSON.stringify({ sourceLine: index + 1, ...record })}\n`)
    decoded += 1
  } catch (error) {
    process.stderr.write(`Skipped malformed clean log at ${inputPath}:${index + 1}: ${error.message}\n`)
  }
}

if (!decoded) {
  throw new Error(`No ${prefix} JSON records found in ${inputPath}`)
}
