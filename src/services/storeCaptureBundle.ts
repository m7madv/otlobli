import { OTLOBLI_NAV_BOOTSTRAP_SCRIPT, SHEIN_CAPTURE_SCRIPT } from './sheinBrowserScript'
import { SHEIN_PRIVACY_COMPAT_SCRIPT } from './sheinPrivacyCompatScript'
import { SHEIN_POLICY_DOCUMENT_START_SCRIPT } from './sheinPolicyEngine'

// This module is deliberately loaded with import() only when a native store is
// about to open. The injected scripts are the largest app-owned JavaScript
// payload; keeping them out of the startup chunk lets login, the store hub and
// the React shell become interactive without parsing store-only source first.
export const buildStoreCaptureScript = (regions: unknown) =>
  `window.__OTLOBLI_STORE_REGIONS__=${JSON.stringify(regions)};\n${SHEIN_PRIVACY_COMPAT_SCRIPT}\ntry{\n${SHEIN_CAPTURE_SCRIPT}\n}catch(__otlobliCaptureError){}`

export { OTLOBLI_NAV_BOOTSTRAP_SCRIPT, SHEIN_CAPTURE_SCRIPT, SHEIN_POLICY_DOCUMENT_START_SCRIPT, SHEIN_PRIVACY_COMPAT_SCRIPT }
