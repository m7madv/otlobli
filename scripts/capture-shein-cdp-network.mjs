import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';

const endpoint = process.argv.find((argument) => argument.startsWith('--endpoint='))
  ?.slice('--endpoint='.length) ?? 'http://127.0.0.1:9222';
const outputPath = process.argv.find((argument) => argument.startsWith('--output='))
  ?.slice('--output='.length) ?? path.resolve('shein-cdp-network.jsonl');
const mode = process.argv.find((argument) => argument.startsWith('--mode='))
  ?.slice('--mode='.length) ?? '';
const runId = process.argv.find((argument) => argument.startsWith('--run-id='))
  ?.slice('--run-id='.length) ?? '';
const containerIdentity = process.argv.find((argument) => argument.startsWith('--container='))
  ?.slice('--container='.length) ?? '';
const allowedModes = new Set([
  'RAW',
  'RAW_WITH_CACHE_GUARD',
  'CAPTURE_ONLY',
  'BLOCKING_ONLY',
  'CAPTURE_AND_BLOCKING',
  'LEGACY_BROWSER_CONTROL',
]);

if (!allowedModes.has(mode) || !runId || !containerIdentity) {
  throw new Error('Required: --mode=<locked mode> --run-id=<native runId> --container=<menu identity>');
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
const output = fs.createWriteStream(outputPath, { flags: 'a' });
const requests = new Map();
const sessions = new Map();
const pendingCommands = new Map();
let socket;
let nextCommandId = 1;
let stopping = false;
let reconnectTimer;

function safeUrl(raw = '') {
  try {
    const value = new URL(String(raw));
    return `${value.origin}${value.pathname}`;
  } catch {
    return '';
  }
}

function sanitizeForLog(value, key = '') {
  const lowerKey = key.toLowerCase();
  if (/(?:cookie|token|authorization|signature|storage|address|account|headers)/.test(lowerKey)) {
    return undefined;
  }
  if (typeof value === 'string') {
    if (/^https?:\/\//i.test(value)) return safeUrl(value);
    return value.slice(0, 1000);
  }
  if (Array.isArray(value)) {
    return value.slice(0, 80).map((entry) => sanitizeForLog(entry)).filter((entry) => entry !== undefined);
  }
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value)
      .map(([childKey, childValue]) => [childKey, sanitizeForLog(childValue, childKey)])
      .filter(([, childValue]) => childValue !== undefined));
  }
  return value;
}

function record(kind, payload = {}) {
  output.write(`${JSON.stringify({
    capturedAt: new Date().toISOString(),
    kind,
    experiment: { mode, runId, containerIdentity },
    ...sanitizeForLog(payload),
  })}\n`);
}

function send(method, params = {}, sessionId, metadata) {
  const id = nextCommandId++;
  const message = { id, method, params };
  if (sessionId) message.sessionId = sessionId;
  if (metadata) pendingCommands.set(id, metadata);
  socket.send(JSON.stringify(message));
  return id;
}

function requestKey(sessionId, requestId) {
  return `${sessionId ?? 'browser'}:${requestId}`;
}

function isRelevantUrl(url = '') {
  return /(?:sheinm\.ltwebstatic\.com|\/pwa_dist\/|\.m?js(?:[?#]|$)|68498|26652)/i.test(url);
}

function isMatchingSheinAsset(url = '') {
  return /^https:\/\/sheinm\.ltwebstatic\.com\/pwa_dist\/assets\/.*\.js(?:[?#]|$)/.test(url);
}

function handleCommandResponse(message) {
  const metadata = pendingCommands.get(message.id);
  if (!metadata) return;
  pendingCommands.delete(message.id);
  if (metadata.kind !== 'response-body') return;

  if (message.error) {
    record('Network.getResponseBodyFailed', {
      ...metadata.request,
      sessionId: metadata.sessionId,
      requestId: metadata.requestId,
      protocolError: message.error,
    });
    return;
  }

  const body = message.result?.body ?? '';
  let bytes;
  try {
    bytes = message.result?.base64Encoded
      ? Buffer.from(body, 'base64')
      : Buffer.from(body, 'utf8');
  } catch {
    bytes = Buffer.alloc(0);
  }
  const prefix = bytes.subarray(0, 256).toString('utf8').trimStart();
  record('Network.responseBodyMetadata', {
    ...metadata.request,
    sessionId: metadata.sessionId,
    requestId: metadata.requestId,
    base64Encoded: Boolean(message.result?.base64Encoded),
    bodyByteLength: bytes.length,
    bodySHA256: createHash('sha256').update(bytes).digest('hex'),
    bodyLooksLikeHTML: prefix.startsWith('<'),
    executableBodyObserved: bytes.length > 0 && !prefix.startsWith('<'),
  });
}

function enablePassiveDomains(sessionId, targetInfo) {
  sessions.set(sessionId, targetInfo);
  record('target-attached', { sessionId, targetInfo });
  send('Network.enable', {
    maxTotalBufferSize: 50 * 1024 * 1024,
    maxResourceBufferSize: 5 * 1024 * 1024,
  }, sessionId);
  send('Runtime.enable', {}, sessionId);
  send('Log.enable', {}, sessionId);
  send('Page.enable', {}, sessionId);
}

function handleProtocolEvent(message) {
  const { method, params = {}, sessionId } = message;

  if (method === 'Target.attachedToTarget') {
    enablePassiveDomains(params.sessionId, params.targetInfo);
    return;
  }

  if (method === 'Target.detachedFromTarget') {
    record('target-detached', params);
    sessions.delete(params.sessionId);
    return;
  }

  if (method === 'Target.targetCreated' ||
      method === 'Target.targetDestroyed' ||
      method === 'Target.targetInfoChanged') {
    record(method, params);
    return;
  }

  if (method === 'Network.requestWillBeSent') {
    const key = requestKey(sessionId, params.requestId);
    const request = {
      url: params.request?.url,
      method: params.request?.method,
      resourceType: params.type,
      documentURL: params.documentURL,
      loaderId: params.loaderId,
      frameId: params.frameId,
      initiator: params.initiator,
      redirectResponse: params.redirectResponse,
      wallTime: params.wallTime,
      timestamp: params.timestamp,
    };
    requests.set(key, request);
    if (params.type === 'Script' || isRelevantUrl(request.url)) {
      record(method, { sessionId, requestId: params.requestId, ...request });
    }
    return;
  }

  if (method === 'Network.requestWillBeSentExtraInfo') {
    const request = requests.get(requestKey(sessionId, params.requestId));
    if (request?.resourceType === 'Script' || isRelevantUrl(request?.url)) {
      record(method, {
        sessionId,
        requestId: params.requestId,
        url: request?.url,
        connectTiming: params.connectTiming,
        associatedCookieCount: Array.isArray(params.associatedCookies) ? params.associatedCookies.length : 0,
      });
    }
    return;
  }

  if (method === 'Network.responseReceived') {
    const key = requestKey(sessionId, params.requestId);
    const request = requests.get(key) ?? {};
    const response = params.response ?? {};
    const merged = {
      ...request,
      url: response.url ?? request.url,
      resourceType: params.type ?? request.resourceType,
      status: response.status,
      mimeType: response.mimeType,
      responseEncodedDataLength: response.encodedDataLength,
      responseTimestamp: params.timestamp,
    };
    requests.set(key, merged);
    if (params.type === 'Script' || isRelevantUrl(merged.url) || /javascript/i.test(response.mimeType ?? '')) {
      record(method, {
        sessionId,
        requestId: params.requestId,
        url: merged.url,
        resourceType: merged.resourceType,
        status: response.status,
        statusText: response.statusText,
        mimeType: response.mimeType,
        protocol: response.protocol,
        fromDiskCache: response.fromDiskCache,
        fromServiceWorker: response.fromServiceWorker,
        fromPrefetchCache: response.fromPrefetchCache,
        encodedDataLength: response.encodedDataLength,
        timestamp: params.timestamp,
        timing: response.timing,
      });
    }
    return;
  }

  if (method === 'Network.responseReceivedExtraInfo') {
    const request = requests.get(requestKey(sessionId, params.requestId));
    if (request?.resourceType === 'Script' || isRelevantUrl(request?.url)) {
      record(method, {
        sessionId,
        requestId: params.requestId,
        url: request?.url,
        statusCode: params.statusCode,
        blockedCookieCount: Array.isArray(params.blockedCookies) ? params.blockedCookies.length : 0,
      });
    }
    return;
  }

  if (method === 'Network.loadingFailed') {
    const request = requests.get(requestKey(sessionId, params.requestId));
    record(method, {
      sessionId,
      requestId: params.requestId,
      request,
      errorText: params.errorText,
      canceled: params.canceled,
      blockedReason: params.blockedReason,
      corsErrorStatus: params.corsErrorStatus,
      resourceType: params.type ?? request?.resourceType,
      timestamp: params.timestamp,
    });
    return;
  }

  if (method === 'Network.loadingFinished') {
    const request = requests.get(requestKey(sessionId, params.requestId));
    if (request?.resourceType === 'Script' || isRelevantUrl(request?.url)) {
      record(method, {
        sessionId,
        requestId: params.requestId,
        request,
        encodedDataLength: params.encodedDataLength,
        timestamp: params.timestamp,
      });
    }
    if (isMatchingSheinAsset(request?.url)) {
      send('Network.getResponseBody', { requestId: params.requestId }, sessionId, {
        kind: 'response-body',
        sessionId,
        requestId: params.requestId,
        request: {
          url: request.url,
          resourceType: request.resourceType,
          status: request.status,
          mimeType: request.mimeType,
          requestTimestamp: request.timestamp,
          responseTimestamp: request.responseTimestamp,
        },
      });
    }
    return;
  }

  if (method === 'Runtime.exceptionThrown' ||
      method === 'Runtime.consoleAPICalled' ||
      method === 'Log.entryAdded' ||
      method === 'Page.frameNavigated' ||
      method === 'Page.lifecycleEvent' ||
      method === 'Page.loadEventFired' ||
      method === 'Page.domContentEventFired') {
    record(method, { sessionId, params });
  }
}

async function connect() {
  if (stopping) return;
  try {
    const response = await fetch(`${endpoint}/json/version`);
    if (!response.ok) throw new Error(`HTTP ${response.status} from /json/version`);
    const version = await response.json();
    if (!version.webSocketDebuggerUrl) throw new Error('No browser WebSocket debugger URL');

    record('bridge-discovered', {
      endpoint,
      browser: version.Browser,
      protocolVersion: version['Protocol-Version'],
    });

    socket = new WebSocket(version.webSocketDebuggerUrl);
    socket.addEventListener('open', () => {
      record('browser-connected');
      send('Target.setDiscoverTargets', { discover: true });
      send('Target.setAutoAttach', {
        autoAttach: true,
        waitForDebuggerOnStart: false,
        flatten: true,
      });
    });
    socket.addEventListener('message', (event) => {
      try {
        const message = JSON.parse(event.data);
        if (message.method) handleProtocolEvent(message);
        if (message.id) handleCommandResponse(message);
        if (message.error) record('protocol-error', message);
      } catch (error) {
        record('protocol-message-error', { error: String(error), data: String(event.data) });
      }
    });
    socket.addEventListener('close', (event) => {
      record('browser-disconnected', { code: event.code, reason: event.reason });
      sessions.clear();
      if (!stopping) reconnectTimer = setTimeout(connect, 500);
    });
    socket.addEventListener('error', (event) => {
      record('browser-socket-error', { message: event.message ?? String(event.type) });
    });
  } catch (error) {
    record('bridge-connect-error', { error: String(error) });
    reconnectTimer = setTimeout(connect, 500);
  }
}

function stop(signal) {
  if (stopping) return;
  stopping = true;
  if (reconnectTimer) clearTimeout(reconnectTimer);
  record('capture-stopped', { signal });
  try { socket?.close(); } catch {}
  output.end(() => process.exit(0));
}

process.on('SIGINT', () => stop('SIGINT'));
process.on('SIGTERM', () => stop('SIGTERM'));
process.on('uncaughtException', (error) => {
  record('uncaught-exception', { error: String(error), stack: error.stack });
  stop('uncaughtException');
});

record('capture-started', {
  endpoint,
  outputPath,
  mode,
  runId,
  containerIdentity,
  privacy: 'URLs exclude query/fragment; headers/cookies/tokens/storage values are excluded',
});
connect();
