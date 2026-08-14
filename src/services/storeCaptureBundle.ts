import { OTLOBLI_NAV_BOOTSTRAP_SCRIPT, SHEIN_CAPTURE_SCRIPT } from './sheinBrowserScript'
import { SHEIN_FREEZE_DIAGNOSTIC_SCRIPT } from './sheinFreezeDiagnostics'
import { SHEIN_REGION_DIAGNOSTICS_SCRIPT } from './sheinRegionDiagnostics'
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
  return `window.__OTLOBLI_STORE_REGIONS__=${JSON.stringify(regions)};\n${diagnosticsPrelude}\n${diagnosticsPanel}\n${regionDiagnostics}\n${runtime}`
}

export { OTLOBLI_NAV_BOOTSTRAP_SCRIPT, SHEIN_FREEZE_DIAGNOSTIC_SCRIPT }
