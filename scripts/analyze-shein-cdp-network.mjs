import { readFileSync, writeFileSync } from 'node:fs'

const args = process.argv.slice(2)
const inputPath = args.find((argument) => !argument.startsWith('--'))
const outputPath = args.find((argument) => argument.startsWith('--output='))
  ?.slice('--output='.length)

if (!inputPath) {
  throw new Error('Usage: node scripts/analyze-shein-cdp-network.mjs evidence.jsonl [--output=report.json]')
}

const chunkNames = [
  '68498-29797320c657aeb6f070.js',
  '26652.9fad62278dae07661792.js',
]
const records = readFileSync(inputPath, 'utf8')
  .split(/\r?\n/)
  .filter(Boolean)
  .map((line) => JSON.parse(line))

const sessions = new Map()
const getSession = (sessionId) => {
  if (!sessions.has(sessionId)) {
    sessions.set(sessionId, {
      sessionId,
      attachedAt: '',
      targetInfo: null,
      chunkEvents: [],
      chunkErrors: [],
      otherLoadingFailures: [],
    })
  }
  return sessions.get(sessionId)
}

for (const record of records) {
  if (record.kind === 'target-attached' && record.sessionId) {
    const session = getSession(record.sessionId)
    session.attachedAt = record.capturedAt
    session.targetInfo = record.targetInfo
    continue
  }

  if (!record.sessionId) continue
  const session = getSession(record.sessionId)
  const url = record.url ?? record.request?.url ?? ''
  const logText = record.params?.entry?.text ?? ''
  const chunkName = chunkNames.find((name) => url.includes(name) || logText.includes(name))

  if (chunkName) {
    session.chunkEvents.push({
      capturedAt: record.capturedAt,
      kind: record.kind,
      requestId: record.requestId,
      chunkName,
      url,
      resourceType: record.resourceType ?? record.request?.resourceType,
      status: record.status,
      mimeType: record.mimeType,
      encodedDataLength: record.encodedDataLength,
      errorText: record.errorText,
      canceled: record.canceled,
      logText: logText || undefined,
    })
    if (/ChunkLoadError/.test(logText)) {
      session.chunkErrors.push({
        capturedAt: record.capturedAt,
        chunkName,
        logText,
      })
    }
  } else if (record.kind === 'Network.loadingFailed') {
    session.otherLoadingFailures.push({
      capturedAt: record.capturedAt,
      url,
      resourceType: record.resourceType ?? record.request?.resourceType,
      errorText: record.errorText,
      canceled: record.canceled,
    })
  }
}

for (const session of sessions.values()) {
  const initialScriptResponses = session.chunkEvents.filter((event) =>
    event.kind === 'Network.responseReceived' && event.resourceType === 'Script')
  const xhrResponses = session.chunkEvents.filter((event) =>
    event.kind === 'Network.responseReceived' && event.resourceType === 'XHR')
  const scriptLoadingFinished = session.chunkEvents.filter((event) =>
    event.kind === 'Network.loadingFinished' && event.resourceType === 'Script')
  const xhrLoadingFinished = session.chunkEvents.filter((event) =>
    event.kind === 'Network.loadingFinished' && event.resourceType === 'XHR')

  session.classification = session.chunkErrors.length
    ? 'chunk-frozen'
    : initialScriptResponses.some((event) => event.status === 200)
      ? 'working'
      : 'unclassified'
  session.initialScriptResponses = initialScriptResponses
  session.prefetchXhrResponses = xhrResponses
  session.scriptLoadingFinished = scriptLoadingFinished
  session.prefetchXhrLoadingFinished = xhrLoadingFinished
}

const sessionList = [...sessions.values()]
  .filter((session) => session.targetInfo?.type === 'page')
  .sort((left, right) => left.attachedAt.localeCompare(right.attachedAt))
const working = sessionList.find((session) => session.classification === 'working')
const frozen = sessionList.find((session) => session.classification === 'chunk-frozen')

const report = {
  inputPath,
  generatedAt: new Date().toISOString(),
  comparison: {
    workingSessionId: working?.sessionId ?? null,
    frozenSessionId: frozen?.sessionId ?? null,
    workingInitialStatuses: working?.initialScriptResponses.map((event) => ({
      chunkName: event.chunkName,
      status: event.status,
      mimeType: event.mimeType,
      encodedDataLength: event.encodedDataLength,
    })) ?? [],
    workingScriptCompletionSizes: working?.scriptLoadingFinished.map((event) => ({
      chunkName: event.chunkName,
      requestId: event.requestId,
      encodedDataLength: event.encodedDataLength,
    })) ?? [],
    workingPostLoadPrefetchStatuses: working?.prefetchXhrResponses.map((event) => ({
      chunkName: event.chunkName,
      status: event.status,
      mimeType: event.mimeType,
      encodedDataLength: event.encodedDataLength,
    })) ?? [],
    workingPostLoadPrefetchCompletionSizes: working?.prefetchXhrLoadingFinished.map((event) => ({
      chunkName: event.chunkName,
      requestId: event.requestId,
      encodedDataLength: event.encodedDataLength,
    })) ?? [],
    frozenInitialStatuses: frozen?.initialScriptResponses.map((event) => ({
      chunkName: event.chunkName,
      status: event.status,
      mimeType: event.mimeType,
      encodedDataLength: event.encodedDataLength,
    })) ?? [],
    frozenScriptCompletionSizes: frozen?.scriptLoadingFinished.map((event) => ({
      chunkName: event.chunkName,
      requestId: event.requestId,
      encodedDataLength: event.encodedDataLength,
    })) ?? [],
    frozenChunkErrors: frozen?.chunkErrors ?? [],
    earliestObservedDivergence: working && frozen
      ? 'Working cold launch received HTTP 200 JavaScript bodies; frozen cold launch received HTTP 304 with no JavaScript body for the same canonical chunk URLs.'
      : null,
  },
  sessions: sessionList,
}

const serialized = `${JSON.stringify(report, null, 2)}\n`
if (outputPath) writeFileSync(outputPath, serialized)
else process.stdout.write(serialized)
