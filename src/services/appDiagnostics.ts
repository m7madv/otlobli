export type AppDiagnosticValue = string | number | boolean | null

export type AppDiagnosticEvent = {
  at: string
  name: string
  data?: Record<string, AppDiagnosticValue>
}

export type AppDiagnosticSnapshot = {
  schemaVersion: 1
  sessionId: string
  startedAt: string
  capturedAt: string
  uptimeMs: number
  environment: {
    platform: string
    appVersion: string
    online: boolean
    visibility: string
    locale: string
  }
  context: {
    screen: string
    store: string
  }
  events: AppDiagnosticEvent[]
}

const MAX_EVENTS = 60
const MAX_VALUE_LENGTH = 160
const SENSITIVE_KEY = /token|secret|password|passcode|cookie|authorization|phone|email|name|address|html|body|image|screenshot/i
const events: AppDiagnosticEvent[] = []
const startedAtMs = Date.now()
const sessionId = globalThis.crypto?.randomUUID?.() ?? `session-${startedAtMs.toString(36)}`
let initialized = false
let platform = 'web'
let appVersion = ''

const cleanText = (value: unknown) => String(value ?? '')
  .replace(/Bearer\s+[A-Za-z0-9._~+/-]+=*/gi, 'Bearer [redacted]')
  .replace(/[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}/g, '[redacted]')
  .replace(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi, '[redacted-email]')
  .replace(/\+?\d(?:[\s().-]?\d){7,15}/g, '[redacted-phone]')
  .replace(/https?:\/\/\S+/gi, '[url]')
  .replace(/\b[A-Fa-f0-9]{24,}\b/g, '[redacted]')
  .replace(/\s+/g, ' ')
  .trim()
  .slice(0, MAX_VALUE_LENGTH)

const cleanData = (input?: Record<string, unknown>) => {
  if (!input) return undefined
  const result: Record<string, AppDiagnosticValue> = {}
  for (const [rawKey, value] of Object.entries(input).slice(0, 12)) {
    const key = rawKey.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 40)
    if (!key || SENSITIVE_KEY.test(key)) continue
    if (typeof value === 'string') result[key] = cleanText(value)
    else if (typeof value === 'number' && Number.isFinite(value)) result[key] = value
    else if (typeof value === 'boolean' || value === null) result[key] = value
  }
  return Object.keys(result).length ? result : undefined
}

const errorLabel = (value: unknown) => {
  const raw = value instanceof Error ? value.message : String(value ?? 'unknown')
  return cleanText(raw).replace(/[A-Z]:\\[^\s]+|\/(?:[^\s/]+\/){2,}[^\s]+/gi, '[path]')
}

export function recordAppDiagnostic(name: string, data?: Record<string, unknown>) {
  const eventName = name.replace(/[^a-zA-Z0-9:_-]/g, '').slice(0, 64)
  if (!eventName) return
  events.push({ at: new Date().toISOString(), name: eventName, data: cleanData(data) })
  if (events.length > MAX_EVENTS) events.splice(0, events.length - MAX_EVENTS)
}

export function initializeAppDiagnostics(input: { platform: string; appVersion: string }) {
  platform = cleanText(input.platform) || 'web'
  appVersion = cleanText(input.appVersion)
  if (initialized || typeof window === 'undefined') return
  initialized = true
  recordAppDiagnostic('diagnostics_started', { platform, appVersion })
  window.addEventListener('error', (event) => {
    recordAppDiagnostic('window_error', {
      message: errorLabel(event.error ?? event.message),
      source: event.filename ? event.filename.split('/').pop() : '',
      line: event.lineno,
    })
  })
  window.addEventListener('unhandledrejection', (event) => {
    recordAppDiagnostic('unhandled_rejection', { message: errorLabel(event.reason) })
  })
  window.addEventListener('online', () => recordAppDiagnostic('network_online'))
  window.addEventListener('offline', () => recordAppDiagnostic('network_offline'))
  document.addEventListener('visibilitychange', () => {
    recordAppDiagnostic('visibility_changed', { state: document.visibilityState })
  })
}

export function createAppDiagnosticSnapshot(context: { screen: string; store: string }): AppDiagnosticSnapshot {
  return {
    schemaVersion: 1,
    sessionId,
    startedAt: new Date(startedAtMs).toISOString(),
    capturedAt: new Date().toISOString(),
    uptimeMs: Math.max(0, Date.now() - startedAtMs),
    environment: {
      platform,
      appVersion,
      online: typeof navigator === 'undefined' ? false : navigator.onLine,
      visibility: typeof document === 'undefined' ? 'unknown' : document.visibilityState,
      locale: typeof navigator === 'undefined' ? '' : cleanText(navigator.language),
    },
    context: {
      screen: cleanText(context.screen),
      store: cleanText(context.store),
    },
    events: events.slice(-MAX_EVENTS),
  }
}
