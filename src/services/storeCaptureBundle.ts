import { SHEIN_CAPTURE_SCRIPT, TEMU_CAPTURE_SCRIPT } from './sheinBrowserScript'
import { SHEIN_PRIVACY_COMPAT_SCRIPT } from './sheinPrivacyCompatScript'
import { SHEIN_POLICY_DOCUMENT_START_SCRIPT } from './sheinPolicyEngine'
import { TEMU_DOCUMENT_START_SCRIPT } from './temuDocumentStartScript'

export type StoreCaptureHostContext = {
  nativeNavigation?: boolean
  safeBottom?: number
  platform?: string
}

// This module is deliberately loaded with import() only when a native store is
// about to open. The injected scripts are the largest app-owned JavaScript
// payload; keeping them out of the startup chunk lets login, the store hub and
// the React shell become interactive without parsing store-only source first.
export const buildStoreCaptureScript = (
  store: 'shein' | 'temu',
  regions: unknown,
  host: StoreCaptureHostContext = {},
) => {
  const runtime = store === 'temu' ? TEMU_CAPTURE_SCRIPT : SHEIN_CAPTURE_SCRIPT
  const sheinDocumentStart = store === 'shein'
    ? `${SHEIN_PRIVACY_COMPAT_SCRIPT}\n${SHEIN_POLICY_DOCUMENT_START_SCRIPT}\n`
    : ''
  const hostPrelude = host.nativeNavigation
    ? `window.__otlobliNativeNavigation=true;\nwindow.__otlobliSafeBottom=${Number.isFinite(host.safeBottom) ? host.safeBottom : 0};\nwindow.__otlobliNativePlatform=${JSON.stringify(host.platform ?? '')};\nwindow.__otlobliDocumentGeneration=window.__otlobliDocumentGeneration||(Date.now().toString(36)+'-'+Math.random().toString(36).slice(2));\n`
    : ''
  return `${hostPrelude}window.__OTLOBLI_STORE_REGIONS__=${JSON.stringify(regions)};\n${sheinDocumentStart}try{\n${runtime}\n}catch(__otlobliCaptureError){}`
}

export {
  SHEIN_CAPTURE_SCRIPT,
  TEMU_CAPTURE_SCRIPT,
  SHEIN_POLICY_DOCUMENT_START_SCRIPT,
  SHEIN_PRIVACY_COMPAT_SCRIPT,
  TEMU_DOCUMENT_START_SCRIPT,
}
