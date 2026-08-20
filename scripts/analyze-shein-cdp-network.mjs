import { readFileSync, writeFileSync } from 'node:fs'

const args = process.argv.slice(2)
const inputPath = args.find((argument) => !argument.startsWith('--'))
const option = (name) => args.find((argument) => argument.startsWith(`--${name}=`))
  ?.slice(`--${name}=`.length)
const outputPath = option('output')
const nativePath = option('native')

if (!inputPath) {
  throw new Error('Usage: node scripts/analyze-shein-cdp-network.mjs evidence.jsonl [--native=decoded-native.jsonl] [--output=report.json]')
}

const readJsonLines = (filePath) => readFileSync(filePath, 'utf8')
  .split(/\r?\n/)
  .filter(Boolean)
  .map((line, index) => {
    try {
      return JSON.parse(line)
    } catch (error) {
      throw new Error(`${filePath}:${index + 1}: ${error.message}`)
    }
  })

const records = readJsonLines(inputPath)
const nativeRecords = nativePath ? readJsonLines(nativePath) : []
const nativeRunIds = [...new Set(nativeRecords.map((record) => record.runId).filter(Boolean))]
const matchingAssetPattern = /^https:\/\/sheinm\.ltwebstatic\.com\/pwa_dist\/assets\/.*\.js(?:[?#]|$)/
const sessions = new Map()

const getSession = (sessionId) => {
  if (!sessions.has(sessionId)) {
    sessions.set(sessionId, {
      sessionId,
      attachedAt: '',
      lastCapturedAt: '',
      targetInfo: null,
      requestsById: new Map(),
      runtimeErrors: [],
    })
  }
  return sessions.get(sessionId)
}

const getRequest = (session, requestId) => {
  if (!session.requestsById.has(requestId)) {
    session.requestsById.set(requestId, {
      requestId,
      url: '',
      requestType: 'Other',
      requestTimestamp: null,
      capturedRequestAt: '',
      responseTimestamp: null,
      capturedResponseAt: '',
      responseStatus: null,
      mimeType: '',
      responseEncodedDataLength: null,
      transferSize: null,
      loadingFinished: false,
      loadingFailed: false,
      loadingFailureText: '',
      blockedReason: '',
      canceled: false,
      initiator: null,
      initiatorStack: null,
      bodyByteLength: null,
      bodySHA256: '',
      executableBodyObserved: null,
      responseBodyInspectionError: '',
    })
  }
  return session.requestsById.get(requestId)
}

const textOf = (record) => {
  const values = [
    record.logText,
    record.params?.entry?.text,
    record.params?.exceptionDetails?.text,
    record.params?.exceptionDetails?.exception?.description,
    record.params?.args?.map((argument) => argument.value ?? argument.description).join(' '),
    record.errorText,
  ]
  return values.filter(Boolean).join(' ')
}

for (const record of records) {
  if (record.kind === 'target-attached' && record.sessionId) {
    const session = getSession(record.sessionId)
    session.attachedAt = record.capturedAt
    session.lastCapturedAt = record.capturedAt
    session.targetInfo = record.targetInfo
    continue
  }
  if (!record.sessionId) continue
  const session = getSession(record.sessionId)
  session.lastCapturedAt = record.capturedAt || session.lastCapturedAt

  if (['Runtime.exceptionThrown', 'Runtime.consoleAPICalled', 'Log.entryAdded'].includes(record.kind)) {
    const errorText = textOf(record)
    if (/ChunkLoadError|Loading chunk/i.test(errorText)) {
      session.runtimeErrors.push({ capturedAt: record.capturedAt, text: errorText })
    }
    continue
  }

  const url = record.url ?? record.request?.url ?? ''
  if (!record.requestId || !matchingAssetPattern.test(url)) continue
  const request = getRequest(session, record.requestId)
  request.url = url

  if (record.kind === 'Network.requestWillBeSent') {
    request.requestType = record.resourceType ?? 'Other'
    request.requestTimestamp = record.timestamp ?? null
    request.capturedRequestAt = record.capturedAt
    request.initiator = record.initiator ?? null
    request.initiatorStack = record.initiator?.stack ?? record.initiator ?? null
  } else if (record.kind === 'Network.responseReceived') {
    request.requestType = record.resourceType ?? request.requestType
    request.responseTimestamp = record.timestamp ?? null
    request.capturedResponseAt = record.capturedAt
    request.responseStatus = record.status ?? null
    request.mimeType = record.mimeType ?? ''
    request.responseEncodedDataLength = record.encodedDataLength ?? null
  } else if (record.kind === 'Network.loadingFinished') {
    request.requestType = record.request?.resourceType ?? request.requestType
    request.loadingFinished = true
    request.transferSize = record.encodedDataLength ?? null
  } else if (record.kind === 'Network.loadingFailed') {
    request.requestType = record.resourceType ?? record.request?.resourceType ?? request.requestType
    request.loadingFailed = true
    request.loadingFailureText = record.errorText ?? ''
    request.blockedReason = record.blockedReason ?? ''
    request.canceled = Boolean(record.canceled)
  } else if (record.kind === 'Network.responseBodyMetadata') {
    request.bodyByteLength = record.bodyByteLength ?? null
    request.bodySHA256 = record.bodySHA256 ?? ''
    request.executableBodyObserved = Boolean(record.executableBodyObserved)
  } else if (record.kind === 'Network.getResponseBodyFailed') {
    request.responseBodyInspectionError = JSON.stringify(record.protocolError ?? {})
  }
}

const nativeTime = (record) => Number(record.at ?? 0)
const nativeForSession = (session) => {
  if (!nativeRecords.length || !session.attachedAt) return []
  const start = Date.parse(session.attachedAt) - 10_000
  const end = Date.parse(session.lastCapturedAt || session.attachedAt) + 10_000
  const timed = nativeRecords.filter((record) => {
    const at = nativeTime(record)
    return at >= start && at <= end
  })
  if (timed.length > 0) return timed
  return nativeRunIds.length === 1 ? nativeRecords : []
}

const summarizeNativeEvidence = (evidence) => {
  const snapshots = evidence.filter((record) =>
    record.event === 'web-runtime' && record.stage === 'root-cause-snapshot')
  const interactions = evidence.filter((record) =>
    record.event === 'web-runtime' && record.stage === 'interaction-reaction')
  const reachedSheinBranch = snapshots.some((record) =>
    record.fingerprint?.root?.id === 'shein-branch' || record.root?.id === 'shein-branch')
  const changedInteractions = interactions.filter((record) =>
    record.pathChanged || record.urlChanged || record.historyChanged || record.rootChanged)
  const nativeChunkErrors = evidence.filter((record) =>
    record.event === 'web-runtime' &&
    ['javascript-error', 'promise-rejection'].includes(record.stage) &&
    /ChunkLoadError|Loading chunk/i.test(`${record.message ?? ''} ${record.stack ?? ''}`))
  return {
    available: evidence.length > 0,
    reachedSheinBranch: evidence.length ? reachedSheinBranch : null,
    interactionSnapshotCount: interactions.length,
    interactionSnapshotsChangingUrlHistoryOrRoot: changedInteractions.length,
    nativeChunkLoadErrorCount: nativeChunkErrors.length,
  }
}

const classifyRequest = (request, chunkErrors) => {
  const fileName = request.url.split('/').at(-1)?.split(/[?#]/)[0] ?? ''
  const followedErrors = chunkErrors.filter((error) =>
    (!request.capturedRequestAt || error.capturedAt >= request.capturedRequestAt) &&
    (!fileName || error.text.includes(fileName) || /ChunkLoadError|Loading chunk/i.test(error.text)))
  const requestType = ['Script', 'XHR', 'Fetch'].includes(request.requestType)
    ? request.requestType
    : 'Other'
  return {
    ...request,
    requestType,
    isRealScriptLoad: requestType === 'Script',
    isSpeculativeRawOrXHRRequest: requestType !== 'Script',
    chunkLoadErrorFollowed: followedErrors.length > 0,
    followedChunkLoadErrors: followedErrors,
  }
}

const sessionList = [...sessions.values()]
  .filter((session) => session.targetInfo?.type === 'page')
  .sort((left, right) => left.attachedAt.localeCompare(right.attachedAt))
  .map((session) => {
    const requests = [...session.requestsById.values()]
      .map((request) => classifyRequest(request, session.runtimeErrors))
      .sort((left, right) => (left.capturedRequestAt || '').localeCompare(right.capturedRequestAt || ''))
    const nativeEvidence = summarizeNativeEvidence(nativeForSession(session))
    return {
      sessionId: session.sessionId,
      attachedAt: session.attachedAt,
      lastCapturedAt: session.lastCapturedAt,
      targetInfo: session.targetInfo,
      matchingRequests: requests,
      requestCounts: Object.fromEntries(['Script', 'XHR', 'Fetch', 'Other'].map((type) => [
        type,
        requests.filter((request) => request.requestType === type).length,
      ])),
      runtimeChunkLoadErrorCount: session.runtimeErrors.length,
      runtimeChunkLoadErrors: session.runtimeErrors,
      nativeEvidence,
    }
  })

const overallNativeEvidence = summarizeNativeEvidence(nativeRecords)

const allRequests = sessionList.flatMap((session) => session.matchingRequests)
const scriptRequests = allRequests.filter((request) => request.isRealScriptLoad)
const speculativeRequests = allRequests.filter((request) => request.isSpeculativeRawOrXHRRequest)
const successfulSpeculative = speculativeRequests.filter((request) =>
  request.responseStatus === 200 || request.responseStatus === 304)
const blockedSpeculative = speculativeRequests.filter((request) =>
  request.loadingFailed && (request.blockedReason || /block|cancel/i.test(request.loadingFailureText)))
const blockedScripts = scriptRequests.filter((request) =>
  request.loadingFailed && (request.blockedReason || /block/i.test(request.loadingFailureText)))
const executableScripts = scriptRequests.filter((request) =>
  request.executableBodyObserved === true ||
  (request.loadingFinished && request.responseStatus === 200 &&
    /javascript|ecmascript/i.test(request.mimeType) && Number(request.transferSize ?? 0) > 0))
const bodylessTextPlain = allRequests.filter((request) =>
  /text\/plain/i.test(request.mimeType) &&
  (request.bodyByteLength === 0 || (request.responseStatus === 304 && Number(request.transferSize ?? 0) <= 256)))
const chunkLoadErrorCount = sessionList.reduce((total, session) =>
  total + Math.max(session.runtimeChunkLoadErrorCount, session.nativeEvidence.nativeChunkLoadErrorCount), 0)

const status = (condition, known = true) => known ? (condition ? 'pass' : 'fail') : 'unknown'
const assertions = {
  matchingRawOrXhrRequestsBlockedOrAbsent: status(
    successfulSpeculative.length === 0 &&
    speculativeRequests.every((request) => blockedSpeculative.includes(request)),
  ),
  matchingScriptRequestsNotBlocked: status(blockedScripts.length === 0, scriptRequests.length > 0),
  requiredScriptBodiesExecutable: status(
    scriptRequests.length > 0 && executableScripts.length === scriptRequests.length,
    scriptRequests.length > 0,
  ),
  noBodylessTextPlainCacheEvidence: status(bodylessTextPlain.length === 0, allRequests.length > 0),
  noRealChunkLoadError: status(chunkLoadErrorCount === 0, sessionList.length > 0),
  sheinBranchReached: status(
    overallNativeEvidence.reachedSheinBranch === true,
    nativeRecords.length > 0,
  ),
  interactionChangedUrlHistoryOrRoot: status(
    overallNativeEvidence.interactionSnapshotsChangingUrlHistoryOrRoot > 0,
    nativeRecords.length > 0,
  ),
}

const report = {
  inputPath,
  nativePath: nativePath ?? null,
  generatedAt: new Date().toISOString(),
  matchingPattern: matchingAssetPattern.source,
  nativeRunIds,
  overallNativeEvidence,
  summary: {
    sessionCount: sessionList.length,
    matchingRequestCount: allRequests.length,
    realScriptRequestCount: scriptRequests.length,
    speculativeRawOrXhrRequestCount: speculativeRequests.length,
    successfulSpeculativeResponseCount: successfulSpeculative.length,
    blockedSpeculativeRequestCount: blockedSpeculative.length,
    blockedScriptRequestCount: blockedScripts.length,
    executableScriptBodyCount: executableScripts.length,
    bodylessTextPlainRecordCount: bodylessTextPlain.length,
    chunkLoadErrorCount,
  },
  assertions,
  sessions: sessionList,
}

const serialized = `${JSON.stringify(report, null, 2)}\n`
if (outputPath) writeFileSync(outputPath, serialized)
else process.stdout.write(serialized)
