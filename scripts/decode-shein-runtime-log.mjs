import { readFileSync } from 'node:fs'

const inputPath = process.argv[2]
const source = inputPath
  ? readFileSync(inputPath, 'utf8')
  : readFileSync(0, 'utf8')

const linePattern = /\[OtlobliSheinRuntime\] event=(\S+) run=(\S+) pid=(\d+) seq=(\d+) part=(\d+)\/(\d+) payload_b64=(\S+)/
const records = new Map()

for (const line of source.split(/\r?\n/)) {
  const match = line.match(linePattern)
  if (!match) continue
  const [, event, runId, pid, sequenceText, partText, partCountText, chunk] = match
  const sequence = Number(sequenceText)
  const part = Number(partText)
  const partCount = Number(partCountText)
  const key = `${runId}:${pid}:${sequence}`
  const record = records.get(key) ?? {
    event,
    runId,
    pid: Number(pid),
    sequence,
    partCount,
    parts: new Map(),
  }
  if (record.partCount !== partCount || record.event !== event) {
    throw new Error(`Conflicting chunks for ${key}`)
  }
  record.parts.set(part, chunk)
  records.set(key, record)
}

let incomplete = 0
for (const record of [...records.values()].sort((left, right) =>
  left.runId.localeCompare(right.runId) || left.sequence - right.sequence)) {
  const missing = []
  const chunks = []
  for (let part = 1; part <= record.partCount; part += 1) {
    const chunk = record.parts.get(part)
    if (chunk === undefined) missing.push(part)
    else chunks.push(chunk)
  }
  if (missing.length) {
    incomplete += 1
    console.error(`Incomplete ${record.runId}:${record.pid}:${record.sequence}; missing parts ${missing.join(',')}`)
    continue
  }
  const json = Buffer.from(chunks.join(''), 'base64').toString('utf8')
  const payload = JSON.parse(json)
  console.log(JSON.stringify(payload))
}

if (records.size === 0) {
  console.error('No OtlobliSheinRuntime records found.')
  process.exitCode = 1
} else if (incomplete > 0) {
  process.exitCode = 2
}
