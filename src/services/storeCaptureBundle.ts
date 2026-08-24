import { OTLOBLI_NAV_BOOTSTRAP_SCRIPT, SHEIN_CAPTURE_SCRIPT, TEMU_CAPTURE_SCRIPT } from './sheinBrowserScript'
import { SHEIN_PRIVACY_COMPAT_SCRIPT } from './sheinPrivacyCompatScript'
import { SHEIN_POLICY_DOCUMENT_START_SCRIPT } from './sheinPolicyEngine'

// This module is deliberately loaded with import() only when a native store is
// about to open. The injected scripts are the largest app-owned JavaScript
// payload; keeping them out of the startup chunk lets login, the store hub and
// the React shell become interactive without parsing store-only source first.
export const buildStoreCaptureScript = (store: 'shein' | 'temu', regions: unknown) => {
  const runtime = store === 'temu' ? TEMU_CAPTURE_SCRIPT : SHEIN_CAPTURE_SCRIPT
  const sheinDocumentStart = store === 'shein'
    ? `${SHEIN_PRIVACY_COMPAT_SCRIPT}\n${SHEIN_POLICY_DOCUMENT_START_SCRIPT}\n`
    : ''
  return `window.__OTLOBLI_STORE_REGIONS__=${JSON.stringify(regions)};\n${sheinDocumentStart}try{\n${runtime}\n}catch(__otlobliCaptureError){}`
}

export { OTLOBLI_NAV_BOOTSTRAP_SCRIPT, SHEIN_CAPTURE_SCRIPT, TEMU_CAPTURE_SCRIPT, SHEIN_POLICY_DOCUMENT_START_SCRIPT, SHEIN_PRIVACY_COMPAT_SCRIPT }
