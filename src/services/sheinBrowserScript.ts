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
export const SHEIN_CAPTURE_SCRIPT = `
(function () {
  var OTLOBLI_SCRIPT_FLAGS = window.__OTLOBLI_SCRIPT_FLAGS__ || {
    runtime: true, navigation: true, blocking: true, capture: true, session: true
  };
  function otlobliScriptEnabled(name) {
    return OTLOBLI_SCRIPT_FLAGS.runtime !== false && OTLOBLI_SCRIPT_FLAGS[name] !== false;
  }
${SHEIN_SESSION_SCRIPT}
${STORE_PRODUCT_CAPTURE_SCRIPT}
${STORE_BLOCKING_SCRIPT}
${TEMU_BROWSER_SCRIPT}
${STORE_RUNTIME_COORDINATOR_SCRIPT}
})();
`
