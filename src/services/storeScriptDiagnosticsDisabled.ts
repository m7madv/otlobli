// Production-build replacement for the internal A-D isolation module. Vite
// aliases the dynamic import here unless the explicit TestFlight diagnostic
// flag is true, so customer assets contain neither the panel nor its messages.
export const buildStoreScriptDiagnosticsPrelude = () => ''
export const buildDiagnosticStoreCaptureScript = () => ''
export const isStoreScriptFlagsChangedMessage = () => false
