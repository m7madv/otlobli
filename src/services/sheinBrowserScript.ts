import { OTLOBLI_NAV_BOOTSTRAP_SCRIPT } from './sheinNavigationScript'
import { SHEIN_SESSION_SCRIPT } from './sheinSessionScript'
import { STORE_PRODUCT_CAPTURE_SCRIPT } from './storeProductCaptureScript'
import { STORE_BLOCKING_SCRIPT } from './storeBlockingScript'
import { TEMU_BROWSER_SCRIPT } from './temuBrowserScript'
import { STORE_RUNTIME_COORDINATOR_SCRIPT } from './storeRuntimeCoordinator'

export { OTLOBLI_NAV_BOOTSTRAP_SCRIPT }

// The store runtime is kept in one lexical scope inside the remote page, but
// each source file owns one responsibility. This preserves cross-section
// function calls while keeping navigation, session, capture and blocking
// independently reviewable and testable.
const STORE_HOST_FLAGS = `  var IS_SHEIN = /shein/i.test(location.hostname);
  var IS_TEMU = /temu/i.test(location.hostname);`

const storeScopedSessionScript = (store: 'shein' | 'temu') => {
  // The other store is a literal false, allowing the production minifier to
  // remove its unreachable branches and unused helpers completely.
  const scopedFlags = store === 'shein'
    ? `  var IS_SHEIN = /shein/i.test(location.hostname);
  var IS_TEMU = false;`
    : `  var IS_SHEIN = false;
  var IS_TEMU = /temu/i.test(location.hostname);`
  const scoped = SHEIN_SESSION_SCRIPT.replace(STORE_HOST_FLAGS, scopedFlags)
  if (scoped === SHEIN_SESSION_SCRIPT) throw new Error('Store runtime host flags were not scoped')
  return scoped
}

const buildStoreRuntime = (store: 'shein' | 'temu') => {
  const sessionScript = storeScopedSessionScript(store)
  const storeHostGuard = store === 'shein'
    ? `  if (!/(^|\\.)shein\\.com$/i.test(location.hostname)) return;`
    : `  if (!/(^|\\.)temu\\.com$/i.test(location.hostname)) return;`
  return `
(function () {
${storeHostGuard}
  function otlobliScriptEnabled() { return true; }
${sessionScript}
${STORE_PRODUCT_CAPTURE_SCRIPT}
${STORE_BLOCKING_SCRIPT}
${TEMU_BROWSER_SCRIPT}
${STORE_RUNTIME_COORDINATOR_SCRIPT}
})();
`
}

// Each WebView now tokenises only the code reachable for its own store. This
// keeps the same reviewed source and behaviour while avoiding the old cost of
// parsing SHEIN and Temu together on every navigation.
export const SHEIN_CAPTURE_SCRIPT = buildStoreRuntime('shein')
export const TEMU_CAPTURE_SCRIPT = buildStoreRuntime('temu')
