import { OTLOBLI_NAV_BOOTSTRAP_SCRIPT, SHEIN_CAPTURE_SCRIPT } from './sheinBrowserScript'
import { SHEIN_FREEZE_DIAGNOSTIC_SCRIPT } from './sheinFreezeDiagnostics'
import { SHEIN_PERSISTENT_STATE_DIAGNOSTIC_SCRIPT } from './sheinPersistentStateDiagnostics'
import { SHEIN_PRIVACY_COMPAT_SCRIPT } from './sheinPrivacyCompatScript'
import { SHEIN_REGION_DIAGNOSTICS_SCRIPT } from './sheinRegionDiagnostics'
import { SHEIN_TAP_DIAGNOSTIC_CONTEXT_JS, SHEIN_TAP_DIAGNOSTIC_SCRIPT } from './sheinTapDiagnostics'
import {
  normalizeStoreScriptFlags,
  STORE_SCRIPT_DIAGNOSTICS_PANEL_SCRIPT,
  type StoreScriptFlags,
} from './storeScriptDiagnostics'

// This module is deliberately loaded with import() only when a native store is
// about to open. The injected scripts are the largest app-owned JavaScript
// payload; keeping them out of the startup chunk lets login, the store hub and
// the React shell become interactive without parsing store-only source first.
export const buildStoreScriptDiagnosticsPrelude = (
  flags: StoreScriptFlags,
  diagnosticsEnabled: boolean,
) => diagnosticsEnabled
  ? `window.__OTLOBLI_SCRIPT_FLAGS__=${JSON.stringify(normalizeStoreScriptFlags(flags))};`
  : ''

export const buildStoreCaptureScript = (
  regions: unknown,
  flags?: StoreScriptFlags,
  diagnosticsEnabled = false,
  iosRootCauseDiagnostics = false,
) => {
  const normalizedFlags = normalizeStoreScriptFlags(flags)
  const diagnosticsPrelude = buildStoreScriptDiagnosticsPrelude(normalizedFlags, diagnosticsEnabled)
  const diagnosticsPanel = diagnosticsEnabled ? STORE_SCRIPT_DIAGNOSTICS_PANEL_SCRIPT : ''
  const regionDiagnostics = !diagnosticsEnabled || normalizedFlags.runtime
    ? SHEIN_REGION_DIAGNOSTICS_SCRIPT
    : ''
  const runtime = !diagnosticsEnabled || normalizedFlags.runtime
    ? `try{\n${SHEIN_CAPTURE_SCRIPT}\n}catch(__otlobliCaptureError){try{window.__otlobliRegionDiagnostic('capture-runtime-error',{message:String(__otlobliCaptureError&&(__otlobliCaptureError.stack||__otlobliCaptureError.message)||__otlobliCaptureError)},'runtime')}catch(__otlobliDiagnosticError){}}`
    : ''
  const tapContext = iosRootCauseDiagnostics ? SHEIN_TAP_DIAGNOSTIC_CONTEXT_JS : ''
  return `window.__OTLOBLI_STORE_REGIONS__=${JSON.stringify(regions)};\n${SHEIN_PRIVACY_COMPAT_SCRIPT}\n${diagnosticsPrelude}\n${diagnosticsPanel}\n${regionDiagnostics}\n${runtime}\n${tapContext}`
}

export {
  OTLOBLI_NAV_BOOTSTRAP_SCRIPT,
  SHEIN_FREEZE_DIAGNOSTIC_SCRIPT,
  SHEIN_PERSISTENT_STATE_DIAGNOSTIC_SCRIPT,
  SHEIN_PRIVACY_COMPAT_SCRIPT,
  SHEIN_TAP_DIAGNOSTIC_SCRIPT,
}
