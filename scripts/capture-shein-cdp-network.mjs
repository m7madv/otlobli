import fs from 'node:fs';
import path from 'node:path';

const endpoint = process.argv.find((argument) => argument.startsWith('--endpoint='))
  ?.slice('--endpoint='.length) ?? 'http://127.0.0.1:9222';
const outputPath = process.argv.find((argument) => argument.startsWith('--output='))
  ?.slice('--output='.length) ?? path.resolve('shein-cdp-network.jsonl');

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
const output = fs.createWriteStream(outputPath, { flags: 'a' });
const requests = new Map();
const sessions = new Map();
let socket;
let nextCommandId = 1;
let stopping = false;
let reconnectTimer;

function record(kind, payload = {}) {
  output.write(`${JSON.stringify({
    capturedAt: new Date().toISOString(),
    kind,
    ...payload,
  })}\n`);
}

function send(method, params = {}, sessionId) {
  const id = nextCommandId++;
  const message = { id, method, params };
  if (sessionId) message.sessionId = sessionId;
  socket.send(JSON.stringify(message));
  return id;
}

function requestKey(sessionId, requestId) {
  return `${sessionId ?? 'browser'}:${requestId}`;
}

function isRelevantUrl(url = '') {
  return /(?:sheinm\.ltwebstatic\.com|\/pwa_dist\/|\.m?js(?:[?#]|$)|68498|26652)/i.test(url);
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
      record(method, { sessionId, requestId: params.requestId, url: request?.url, params });
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
        timing: response.timing,
        responseHeaders: response.headers,
      });
    }
    return;
  }

  if (method === 'Network.responseReceivedExtraInfo') {
    const request = requests.get(requestKey(sessionId, params.requestId));
    if (request?.resourceType === 'Script' || isRelevantUrl(request?.url)) {
      record(method, { sessionId, requestId: params.requestId, url: request?.url, params });
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
      webSocketDebuggerUrl: version.webSocketDebuggerUrl,
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

record('capture-started', { endpoint, outputPath });
connect();

