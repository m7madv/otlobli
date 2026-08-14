import { OTLOBLI_NAV_BOOTSTRAP_SCRIPT, SHEIN_CAPTURE_SCRIPT } from './sheinBrowserScript'
import { SHEIN_FREEZE_DIAGNOSTIC_SCRIPT } from './sheinFreezeDiagnostics'
import { SHEIN_REGION_DIAGNOSTICS_SCRIPT } from './sheinRegionDiagnostics'

// This module is deliberately loaded with import() only when a native store is
// about to open. The injected scripts are the largest app-owned JavaScript
// payload; keeping them out of the startup chunk lets login, the store hub and
// the React shell become interactive without parsing store-only source first.
export const buildStoreCaptureScript = (regions: unknown) =>
  `window.__OTLOBLI_STORE_REGIONS__=${JSON.stringify(regions)};\n${SHEIN_REGION_DIAGNOSTICS_SCRIPT}\ntry{\n${SHEIN_CAPTURE_SCRIPT}\n}catch(__otlobliCaptureError){try{window.__otlobliRegionDiagnostic('capture-runtime-error',{message:String(__otlobliCaptureError&&(__otlobliCaptureError.stack||__otlobliCaptureError.message)||__otlobliCaptureError)},'runtime')}catch(__otlobliDiagnosticError){}}`

export { OTLOBLI_NAV_BOOTSTRAP_SCRIPT, SHEIN_FREEZE_DIAGNOSTIC_SCRIPT }
