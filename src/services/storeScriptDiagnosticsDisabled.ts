// Production-build replacement for the internal navigation isolation module. Vite
// aliases the dynamic import here unless the explicit TestFlight diagnostic
// flag is true, so customer assets contain neither the panel nor its messages.
export const buildStoreScriptDiagnosticsPrelude = () => ''
export const buildDiagnosticStoreCaptureScript = () => ''
export const isStoreScriptFlagsChangedMessage = () => false
export const isStoreDiagnosticStateMessage = () => false
export const normalizeStoreDiagnosticState = () => ({
  version: 3,
  activeProfile: 'baseline',
  outcomes: {},
  trace: [],
  journey: { tap: false, url: false, document: false, product: false, error: false },
})
export const appendStoreDiagnosticHostEvent = normalizeStoreDiagnosticState
