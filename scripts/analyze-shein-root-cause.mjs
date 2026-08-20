import { readFileSync } from 'node:fs'

const args = process.argv.slice(2)
const inputPath = args.find((arg) => !arg.startsWith('--'))
const option = (name, fallback) => {
  const prefix = `--${name}=`
  return args.find((arg) => arg.startsWith(prefix))?.slice(prefix.length) ?? fallback
}
const goodLabel = option('good', 'FIRST_GOOD')
const frozenLabel = option('frozen', 'SHOW_FROZEN')
if (!inputPath) throw new Error('Usage: npm run analyze:shein-root-cause -- evidence.jsonl [--good=FIRST_GOOD] [--frozen=SHOW_FROZEN]')

const records = readFileSync(inputPath, 'utf8')
  .split(/\r?\n/)
  .filter(Boolean)
  .map((line) => JSON.parse(line))
  .sort((left, right) => Number(left.at ?? 0) - Number(right.at ?? 0) || Number(left.nativeSequence ?? 0) - Number(right.nativeSequence ?? 0))

const isWebSnapshot = (record, label) =>
  record.event === 'web-runtime' && record.stage === 'root-cause-snapshot' && record.snapshotLabel === label
const isNativeSnapshot = (record, label) =>
  record.event === 'native-snapshot' && record.snapshotLabel === label
const last = (items) => items.at(-1)
const good = last(records.filter((record) => isWebSnapshot(record, goodLabel)))
const frozen = last(records.filter((record) => isWebSnapshot(record, frozenLabel)))
if (!good || !frozen) {
  throw new Error(`Missing snapshot labels: good=${goodLabel} found=${!!good}, frozen=${frozenLabel} found=${!!frozen}`)
}

const ignoredKeys = new Set(['at', 'performanceNow', 'sequence', 'nativeSequence', 'runId', 'pid'])
const flatten = (value, prefix = '', output = {}) => {
  if (Array.isArray(value)) {
    output[prefix] = JSON.stringify(value)
    return output
  }
  if (value && typeof value === 'object') {
    for (const [key, nested] of Object.entries(value)) {
      if (ignoredKeys.has(key)) continue
      flatten(nested, prefix ? `${prefix}.${key}` : key, output)
    }
    return output
  }
  output[prefix] = value
  return output
}
const compare = (left, right) => {
  const leftFlat = flatten(left)
  const rightFlat = flatten(right)
  return [...new Set([...Object.keys(leftFlat), ...Object.keys(rightFlat)])]
    .sort()
    .filter((path) => JSON.stringify(leftFlat[path]) !== JSON.stringify(rightFlat[path]))
    .map((path) => ({ path, good: leftFlat[path] ?? null, frozen: rightFlat[path] ?? null }))
}

const frozenAt = Number(frozen.at ?? 0)
const offsets = [-5000, -2000, -1000, 0, 100, 500, 1000, 2000, 5000]
const timeline = offsets.map((offset, index) => {
  const target = frozenAt + offset
  const nextOffset = offsets[index + 1]
  const end = nextOffset === undefined ? target + 1 : frozenAt + nextOffset
  const nearby = records.filter((record) => Number(record.at ?? 0) >= target && Number(record.at ?? 0) < end)
  return {
    offsetMs: offset,
    records: nearby.map((record) => ({
      at: record.at ?? 0,
      event: record.event ?? '',
      stage: record.stage ?? '',
      snapshotLabel: record.snapshotLabel ?? '',
      lifecycleStage: record.lifecycleStage ?? '',
      navigationId: record.navigationId ?? '',
      documentId: record.documentId ?? '',
      path: record.path ?? record.url ?? '',
    })),
  }
})

const heartbeatKeys = ['promiseAgeMs', 'microtaskAgeMs', 'timeoutAgeMs', 'intervalAgeMs', 'rafAgeMs', 'mutationAgeMs', 'messageChannelAgeMs']
const heartbeatAssessment = (snapshot) => Object.fromEntries(heartbeatKeys.map((key) => {
  const value = Number(snapshot.heartbeat?.[key] ?? -1)
  return [key, { value, stale: value < 0 || value > 1500 }]
}))
const errorsBeforeFrozen = records.filter((record) => {
  const at = Number(record.at ?? 0)
  return at >= frozenAt - 10_000 && at <= frozenAt + 2_000 &&
    ['javascript-error', 'promise-rejection', 'resource-error', 'csp-violation', 'navigation-error', 'webcontent-terminated'].includes(record.stage ?? record.event)
})
const frozenNative = last(records.filter((record) => isNativeSnapshot(record, frozenLabel)))
const goodNative = last(records.filter((record) => isNativeSnapshot(record, goodLabel)))

const report = {
  source: inputPath,
  labels: { good: goodLabel, frozen: frozenLabel },
  recordCount: records.length,
  runs: [...new Set(records.map((record) => `${record.runId ?? ''}:${record.pid ?? ''}`))],
  goodIdentity: { runId: good.runId, pid: good.pid, browserId: good.browserId, webViewId: good.webViewId, navigationId: good.navigationId, documentId: good.documentId, at: good.at },
  frozenIdentity: { runId: frozen.runId, pid: frozen.pid, browserId: frozen.browserId, webViewId: frozen.webViewId, navigationId: frozen.navigationId, documentId: frozen.documentId, at: frozen.at },
  heartbeat: { good: heartbeatAssessment(good), frozen: heartbeatAssessment(frozen) },
  webDifferences: compare(good, frozen),
  nativeDifferences: goodNative && frozenNative ? compare(goodNative, frozenNative) : [],
  errorsBeforeFrozen,
  timeline,
}
console.log(JSON.stringify(report, null, 2))
