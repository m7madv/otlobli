import fs from 'node:fs'

function argument(name, required = true) {
  const value = process.argv.find((item) => item.startsWith(`--${name}=`))?.slice(name.length + 3)
  if (required && !value) throw new Error(`Missing --${name}=<path>`)
  return value
}

function readJson(file, fallback = null) {
  if (!file || !fs.existsSync(file)) return fallback
  return JSON.parse(fs.readFileSync(file, 'utf8'))
}

function readJsonl(file) {
  if (!file || !fs.existsSync(file)) return []
  return fs.readFileSync(file, 'utf8').split(/\r?\n/).filter(Boolean).flatMap((line, index) => {
    try { return [{ sourceLine: index + 1, ...JSON.parse(line) }] }
    catch { return [] }
  })
}

function eventTime(record) {
  if (Number.isFinite(Number(record.at))) return Number(record.at)
  const raw = record.capturedAt ?? record.timestamp ?? record.utc
  const parsed = raw ? Date.parse(raw) : Number.NaN
  return Number.isFinite(parsed) ? parsed : null
}

function compactEvent(record) {
  return {
    at: eventTime(record),
    source: record.source ?? record.kind ?? record.event ?? 'unknown',
    event: record.event ?? record.kind ?? record.marker ?? 'unknown',
    mode: record.mode ?? record.experiment?.mode ?? null,
    runId: record.runId ?? record.experiment?.runId ?? null,
    appPid: record.appPid ?? record.pid ?? null,
    webViewId: record.webViewId ?? null,
    navigationId: record.navigationId ?? null,
    documentId: record.documentId ?? null,
    root: record.root ?? record.after ?? record.rootAfter ?? null,
    operation: record.operation ?? null,
    module: record.module ?? null,
    message: record.message ?? record.error ?? record.reason ?? null,
  }
}

const manifestPath = argument('manifest')
const markersPath = argument('markers')
const runtimePath = argument('runtime')
const processesPath = argument('processes', false)
const networkPath = argument('network')
const cachePath = argument('cache', false)
const outputPath = argument('output')
const reportPath = argument('report')

const manifest = readJson(manifestPath, {})
const markers = readJsonl(markersPath)
const runtime = readJsonl(runtimePath)
const processes = readJsonl(processesPath)
const network = readJson(networkPath, {})
const cache = readJson(cachePath, null)

const runtimeChunkErrors = runtime.filter((record) =>
  record.kind === 'chunk-load-error' || /ChunkLoadError|Loading chunk/i.test(`${record.message ?? ''} ${record.stack ?? ''}`))
const javascriptFailures = runtime.filter((record) =>
  ['javascript-error', 'unhandled-rejection', 'chunk-load-error', 'resource-error'].includes(record.kind))
const moduleOperations = runtime.filter((record) => record.kind === 'module-operation')
const moduleErrors = moduleOperations.filter((record) => /error/i.test(record.operation ?? ''))
const rootSnapshots = runtime.filter((record) =>
  ['snapshot', 'heartbeat', 'document-start', 'click-reaction', 'lifecycle'].includes(record.kind) &&
  (record.root || record.after))
const reachedSheinBranch = rootSnapshots.some((record) =>
  record.root?.sheinBranchExists === true || record.after?.sheinBranchExists === true)
const onlyAppRootObserved = rootSnapshots.some((record) =>
  record.root?.onlyAppRoot === true || record.after?.onlyAppRoot === true)
const changedClicks = runtime.filter((record) => record.kind === 'click-reaction' &&
  (record.pathChanged || record.urlChanged || record.historyChanged || record.rootChanged))
const freezeMarker = markers.find((record) => record.marker === 'FREEZE_VISIBLE')
const workingMarkers = markers.filter((record) => /WORKING_CONFIRMED/.test(record.marker ?? ''))
const processPids = [...new Set(runtime.map((record) => Number(record.appPid)).filter((value) => value > 0))]
const polledAppPids = [...new Set(processes.map((record) => Number(record.appPid)).filter((value) => value > 0))]
const appPids = [...new Set([...processPids, ...polledAppPids])]
const webContentPids = [...new Set(processes.flatMap((record) => record.webContentPids ?? []).map(Number).filter((value) => value > 0))]

const networkSummary = network.summary ?? {}
const assertions = network.assertions ?? {}
const poisoningSequence = networkSummary.poisoningSequenceDetected === true
const scriptBodiesHealthy = assertions.requiredScriptBodiesExecutable === 'pass' &&
  assertions.matchingScriptRequestsNotBlocked === 'pass'
const zeroChunkErrors = Number(networkSummary.chunkLoadErrorCount ?? runtimeChunkErrors.length) === 0

let classification = 'insufficient-evidence'
let verdict = 'No measured causal verdict is available.'
let t0 = null
let t0Class = null

const bodylessScript = (network.sessions ?? []).flatMap((session) => session.matchingRequests ?? [])
  .filter((request) => request.isRealScriptLoad && request.responseStatus === 304 &&
    (request.bodyByteLength === 0 || Number(request.transferSize ?? 0) <= 256 || /text\/plain/i.test(request.mimeType ?? '')))
  .sort((left, right) => String(left.capturedResponseAt ?? '').localeCompare(String(right.capturedResponseAt ?? '')))[0]

if (poisoningSequence) {
  classification = 'cache-poisoning-sequence-proven'
  verdict = 'A required Script received a bodyless 304 representation before a genuine ChunkLoadError and hydration failure.'
  t0 = bodylessScript?.capturedResponseAt ? Date.parse(bodylessScript.capturedResponseAt) : null
  t0Class = 'required-script-body-missing'
} else if (freezeMarker && moduleErrors.length && scriptBodiesHealthy && zeroChunkErrors) {
  classification = 'owned-module-operation-failure-proven'
  verdict = 'Required Script bodies were healthy; the earliest recorded failure is an Otlobli-owned module operation error.'
  t0 = eventTime(moduleErrors[0])
  t0Class = 'module-operation-error'
} else if (freezeMarker && javascriptFailures.length && !poisoningSequence) {
  classification = 'runtime-failure-measured-cache-sequence-absent'
  verdict = 'The visible freeze follows a measured JavaScript/resource failure, but the proven v86.202 poisoning sequence is absent.'
  t0 = eventTime(javascriptFailures[0])
  t0Class = javascriptFailures[0].kind
} else if (!freezeMarker && workingMarkers.length) {
  classification = 'failure-not-reproduced'
  verdict = 'The selected scenario completed with a working confirmation and no FREEZE_VISIBLE marker.'
} else if (freezeMarker) {
  verdict = 'The freeze was marked, but no earlier failing Script, runtime, lifecycle, or owned-module operation was captured.'
}

const allEvents = [
  ...markers.map((record) => ({ ...record, source: 'operator-marker' })),
  ...runtime.map((record) => ({ ...record, source: 'app-runtime' })),
  ...processes.map((record) => ({ ...record, source: 'process-poll' })),
].filter((record) => eventTime(record) !== null).sort((left, right) => eventTime(left) - eventTime(right))

const centeredTimeline = t0 === null ? [] : allEvents
  .filter((record) => Math.abs(eventTime(record) - t0) <= 5000)
  .map((record) => ({ relativeMs: eventTime(record) - t0, ...compactEvent(record) }))

const missingMeasurements = []
if (!markers.length) missingMeasurements.push('operator markers')
if (!runtime.length) missingMeasurements.push('app runtime NDJSON')
if (!network.sessions?.length) missingMeasurements.push('CDP page/network session')
if (!processes.length) missingMeasurements.push('process polling')
if (!cache) missingMeasurements.push('read-only scenario NetworkCache copy/inspection')
if (freezeMarker && t0 === null) missingMeasurements.push('an operation or resource failure before the visible freeze')

const analysis = {
  generatedAt: new Date().toISOString(),
  scenario: manifest.scenario ?? null,
  mode: manifest.mode ?? null,
  runId: manifest.runId ?? null,
  websiteDataContainer: manifest.websiteDataContainer ?? null,
  classification,
  verdict,
  earliestDivergence: t0 === null ? null : { at: new Date(t0).toISOString(), class: t0Class },
  identity: {
    appPids,
    appPidTransitionCount: Math.max(0, appPids.length - 1),
    webContentPids,
    runtimeWebViewIds: [...new Set(runtime.map((record) => record.webViewId).filter(Boolean))],
    runtimeDocumentIds: [...new Set(runtime.map((record) => record.documentId).filter(Boolean))],
    runtimeNavigationIds: [...new Set(runtime.map((record) => record.navigationId).filter(Boolean))],
  },
  phenotype: {
    freezeMarked: Boolean(freezeMarker),
    workingConfirmationCount: workingMarkers.length,
    reachedSheinBranch,
    onlyAppRootObserved,
    changedTrustedClickCount: changedClicks.length,
  },
  network: networkSummary,
  networkAssertions: assertions,
  runtime: {
    chunkLoadErrorCount: runtimeChunkErrors.length,
    javascriptFailureCount: javascriptFailures.length,
    moduleOperationCount: moduleOperations.length,
    moduleErrorCount: moduleErrors.length,
    captureOperations: moduleOperations.filter((record) => record.module === 'capture').length,
    blockingOperations: moduleOperations.filter((record) => record.module === 'blocking').length,
  },
  cache: cache ? {
    matchingRecordCount: cache.matchingRecordCount,
    matchingRecordsWithBodyOrBlobEvidence: cache.matchingRecordsWithBodyOrBlobEvidence,
    matchingRecordsWithoutBodyOrBlobEvidence: cache.matchingRecordsWithoutBodyOrBlobEvidence,
    textPlainRecordsWithoutBodyOrBlobEvidence: cache.textPlainRecordsWithoutBodyOrBlobEvidence,
  } : null,
  missingMeasurements,
  centeredTimeline,
}

fs.writeFileSync(outputPath, `${JSON.stringify(analysis, null, 2)}\n`)

const rows = centeredTimeline.map((record) =>
  `| ${record.relativeMs} | ${record.source} | ${record.event} | ${record.appPid ?? ''} | ${record.webViewId ?? ''} | ${record.documentId ?? ''} |`)
const report = `# SHEIN final-forensics scenario report

- Scenario: \`${analysis.scenario ?? 'unknown'}\`
- Mode: \`${analysis.mode ?? 'unknown'}\`
- Run ID: \`${analysis.runId ?? 'unknown'}\`
- Persistent container: \`${analysis.websiteDataContainer ?? 'unknown'}\`
- Classification: **${analysis.classification}**
- Verdict: ${analysis.verdict}

## Earliest measured divergence

${analysis.earliestDivergence ? `\`${analysis.earliestDivergence.at}\` — \`${analysis.earliestDivergence.class}\`` : 'No causal T0 was measured.'}

## Evidence summary

- App PIDs: ${analysis.identity.appPids.length ? analysis.identity.appPids.map((value) => `\`${value}\``).join(', ') : 'none captured'}
- WebContent PIDs observed: ${analysis.identity.webContentPids.length ? analysis.identity.webContentPids.map((value) => `\`${value}\``).join(', ') : 'none captured'}
- WebView IDs: ${analysis.identity.runtimeWebViewIds.length ? analysis.identity.runtimeWebViewIds.map((value) => `\`${value}\``).join(', ') : 'none captured'}
- Reached \`#shein-branch\`: \`${analysis.phenotype.reachedSheinBranch}\`
- Freeze marker: \`${analysis.phenotype.freezeMarked}\`
- Network ChunkLoadError count: \`${analysis.network.chunkLoadErrorCount ?? 'unknown'}\`
- Runtime ChunkLoadError count: \`${analysis.runtime.chunkLoadErrorCount}\`
- Capture/Blocking operation records: \`${analysis.runtime.captureOperations}/${analysis.runtime.blockingOperations}\`
- Missing measurements: ${analysis.missingMeasurements.length ? analysis.missingMeasurements.join('; ') : 'none'}

## T0-centered timeline

| Relative ms | Source | Event | App PID | WebView ID | Document ID |
| ---: | --- | --- | ---: | --- | --- |
${rows.length ? rows.join('\n') : '| — | — | No causal T0 measured | — | — | — |'}

## Interpretation boundary

This report classifies only the selected fresh persistent scenario. Visual similarity to another incident is not treated as causal proof.
`
fs.writeFileSync(reportPath, report)
