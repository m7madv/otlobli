import { readFileSync } from 'node:fs'
import { readStoreScriptSources } from './store-script-sources.mjs'

const plugin = readFileSync(
  new URL('../android/app/src/main/java/com/otlobli/app/TemuEmbeddedBrowserPlugin.java', import.meta.url),
  'utf8',
)
const reporter = readFileSync(
  new URL('../android/app/src/main/java/com/otlobli/app/OtlobliIssueReporterPlugin.java', import.meta.url),
  'utf8',
)
const appEntry = readFileSync(new URL('../src/main.tsx', import.meta.url), 'utf8')
const app = readFileSync(new URL('../src/App.tsx', import.meta.url), 'utf8')
const customerStyles = readFileSync(new URL('../src/styles.css', import.meta.url), 'utf8')
const storeCaptureBundleSource = readFileSync(
  new URL('../src/services/storeCaptureBundle.ts', import.meta.url),
  'utf8',
)
const sheinBrowserSource = readFileSync(
  new URL('../src/services/sheinBrowserScript.ts', import.meta.url),
  'utf8',
)
const humanCheckSource = readFileSync(
  new URL('../src/services/sheinHumanCheck.ts', import.meta.url),
  'utf8',
)
const iosSheinBrowser = readFileSync(
  new URL('../ios/App/App/OtlobliSheinBrowserPlugin.swift', import.meta.url),
  'utf8',
)
const inAppBrowserPatch = readFileSync(
  new URL('../patches/@capgo+capacitor-inappbrowser+8.6.25.patch', import.meta.url),
  'utf8',
)
const projectPatchSide = (patch, prefix) => patch
  .split(/\r?\n/)
  .filter((line) => line.startsWith(prefix) && !line.startsWith(prefix.repeat(3)))
  .map((line) => line.slice(1))
  .join('\n')
const inAppBrowserPatchAdded = projectPatchSide(inAppBrowserPatch, '+')
const inAppBrowserPatchRemoved = projectPatchSide(inAppBrowserPatch, '-')
const appliedCapgoIosPlugin = readFileSync(
  new URL('../node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/InAppBrowserPlugin.swift', import.meta.url),
  'utf8',
)
const appliedCapgoIosController = readFileSync(
  new URL('../node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/WKWebViewController.swift', import.meta.url),
  'utf8',
)
const appliedCapgoAndroid = readFileSync(
  new URL('../node_modules/@capgo/capacitor-inappbrowser/android/src/main/java/ee/forgr/capacitor_inappbrowser/WebViewDialog.java', import.meta.url),
  'utf8',
)
const captureScript = readStoreScriptSources(new URL('..', import.meta.url))
const runtimeCoordinator = readFileSync(
  new URL('../src/services/storeRuntimeCoordinator.ts', import.meta.url),
  'utf8',
)
const temuDocumentStartSource = readFileSync(
  new URL('../src/services/temuDocumentStartScript.ts', import.meta.url),
  'utf8',
)
const extensionBuilder = readFileSync(new URL('./build-temu-gecko-extension.mjs', import.meta.url), 'utf8')
const geckoContent = readFileSync(
  new URL('../android/app/src/temuPersonal/assets/temu_extension/content.js', import.meta.url),
  'utf8',
)
const geckoCapture = readFileSync(
  new URL('../android/app/src/temuPersonal/assets/temu_extension/content-capture.js', import.meta.url),
  'utf8',
)
const geckoManifest = JSON.parse(readFileSync(
  new URL('../android/app/src/temuPersonal/assets/temu_extension/manifest.json', import.meta.url),
  'utf8',
))

const requiredPluginMarkers = [
  'private static final int OTLBLI_NAV_RESERVE_DP = 90;',
  'Math.min(getContext().getResources().getDisplayMetrics().widthPixels, dp(440))',
  'Gravity.TOP | Gravity.CENTER_HORIZONTAL',
  'WindowInsets.Type.navigationBars()',
  'insets.getSystemWindowInsetBottom()',
  'dp(OTLBLI_NAV_RESERVE_DP) + Math.max(0, navigationBarInset)',
  'storeLayer.setAlpha(1f);',
  'storeLayer.setVisibility(View.GONE);',
  'settings.setSuspendMediaWhenInactive(true);',
  'protected void handleOnPause()',
  'protected void handleOnResume()',
  'public void acknowledgeAdd(PluginCall call)',
  'private PendingAddRequest beginPendingAddRequest()',
  'detail.put("requestId", addRequest.requestId);',
  'takePendingAddRequest(requestedId.isEmpty() ? null : requestedId)',
  'ADD_ACK_TIMEOUT_MS = 3500L',
]

for (const marker of requiredPluginMarkers) {
  if (!plugin.includes(marker)) {
    throw new Error(`Store surface guard missing plugin marker: ${marker}`)
  }
}

for (const marker of [
  'handlePersonalTemuHomeTap()',
  'showPersonalTemuSecondTapHint()',
  'onNavigate={(target, activationDetail) => {',
  'if (activationDetail === 0)',
  "onClick={(event) => onNavigate('home', event.detail)}",
  'انقر مرة ثانية لفتح قائمة المتاجر',
  'انقر مرتين على «الرئيسية» لفتح قائمة المتاجر',
  'الرئيسية، يفتح قائمة المتاجر مباشرة',
  'TemuEmbeddedBrowser.acknowledgeAdd({ requestId: temuCaptureRequestId })',
  'items.some((item) => item.id === itemId)',
]) {
  if (!app.includes(marker)) throw new Error(`Temu store-return/capture guard missing App marker: ${marker}`)
}

for (const marker of [
  'var homeDoubleTapMs = 320',
  "event.type === 'click' && now - lastPhysicalTouchAt < 450",
  'homeTapTimer = setTimeout(finishSingleHomeTap, homeDoubleTapMs)',
  "event.type === 'click' && event.detail === 0",
  "if (!/(^|\\.)(?:temu|shein)\\.com$/i.test(location.hostname || '')) return;",
  'window.__otlobliStoreNavigationChallengeLocked === true',
  "var challengePath = String(location.pathname || '')",
  "var challengeQuery = String(location.search || '') + String(location.hash || '')",
  '/(?:^|[?&#])(?:captcha|challenge|verification|bgn[_-]?verification|security_token|risk|robot|anti[-_]?bot|human)=/i.test(challengeQuery)',
  'storeNavigationPausedForHumanCheck()',
  "hint.textContent = 'انقر مرة ثانية لفتح قائمة المتاجر'",
  'showStoreSwitchHint();',
  "window.mobileApp.postMessage({ detail: { type: 'closeStore' } })",
]) {
  if (!captureScript.includes(marker)) throw new Error(`Injected store-switch gesture guard missing marker: ${marker}`)
}
const fallbackRouteStart = captureScript.indexOf('var routeOtlobliNavTouch = function (event)')
const fallbackInterceptionStart = captureScript.indexOf('if (event.cancelable) event.preventDefault()', fallbackRouteStart)
const fallbackChallengeGate = captureScript.indexOf('if (storeNavigationPausedForHumanCheck()) return;', fallbackRouteStart)
if (fallbackRouteStart < 0 || fallbackChallengeGate < fallbackRouteStart ||
    fallbackInterceptionStart < 0 || fallbackChallengeGate > fallbackInterceptionStart) {
  throw new Error('Injected store navigation must yield to human verification before intercepting the event')
}
for (const marker of [
  'window.__otlobliStoreNavigationChallengeLocked = true',
  'window.__otlobliStoreNavigationChallengeLocked = false',
]) {
  if (!humanCheckSource.includes(marker)) {
    throw new Error(`Human-verification store-navigation state marker is missing: ${marker}`)
  }
}

for (const staleCopy of ['اضغط مرتين للتبديل', 'اضغط مرتين على الرئيسية لتبديل المتجر']) {
  if (app.includes(staleCopy) || captureScript.includes(staleCopy) ||
      appliedCapgoAndroid.includes(staleCopy) || appliedCapgoIosController.includes(staleCopy) ||
      iosSheinBrowser.includes(staleCopy) || inAppBrowserPatchAdded.includes(staleCopy)) {
    throw new Error(`Store chooser guidance must not retain the old permanent copy: ${staleCopy}`)
  }
}

for (const forbidden of ['location.assign(location.origin + homePath)', 'TemuEmbeddedBrowser.goHome().catch']) {
  if (captureScript.includes(forbidden) || app.includes(forbidden)) {
    throw new Error(`Single Home tap must not reload or navigate the active store: ${forbidden}`)
  }
}

for (const marker of [
  "btn.setAttribute('aria-label', IS_TEMU ? 'العودة إلى اختيار المتجر' : 'رجوع')",
  'function otlobliTemuHomeLikeUrl()',
  'function otlobliStoreHomeRoot()',
  'var storeHomeRoot = otlobliStoreHomeRoot()',
]) {
  if (!captureScript.includes(marker)) throw new Error(`Temu root-exit guard missing marker: ${marker}`)
}

for (const marker of [
  "if (typeof ensureBackButton === 'function') ensureBackButton();",
  '[class*="topTabContainer"] [class*="tab-"]',
  'var cacheGap = routeAge > 3000',
  'OTLOBLI_LOW_END ? 1600 : 900',
  "var OTLOBLI_TEMU_OWNED_STYLE_ATTR = 'data-otlobli-temu-owned-style'",
  'otlobliRestoreTemuInlineStyles(owned',
  '[data-otlobli-temu-pinned-header="1"]',
  "document.body.removeAttribute('data-otlobli-temu-search-mode')",
  'now - __otlobliTemuBlankSince < (OTLOBLI_LOW_END ? 8000 : 4500)',
]) {
  if (!captureScript.includes(marker)) throw new Error(`Temu iPhone stability guard missing marker: ${marker}`)
}

const temuBlockerResetStart = captureScript.indexOf('// v85.8.26: Temu blocker reset')
const temuBlockerResetEnd = captureScript.indexOf('function injectTemuHeaderHideCSS', temuBlockerResetStart)
const temuBlockerReset = captureScript.slice(temuBlockerResetStart, temuBlockerResetEnd)
const temuDownloadShellFunctionStart = temuBlockerReset.indexOf('function otlobliMarkTemuNativeDownloadShell()')
const temuBlockerCss = temuBlockerReset.slice(0, temuDownloadShellFunctionStart)
const temuDownloadShellFunction = temuBlockerReset.slice(temuDownloadShellFunctionStart)
const androidHomeScope =
  'html[data-otlobli-native-platform="android"][data-otlobli-temu-home-route="1"]'
const iosHomeScope =
  'html[data-otlobli-native-platform="ios"][data-otlobli-temu-home-route="1"]'
const androidHomeWrapperSelector =
  `${androidHomeScope} [class*="downloadsWrapper"]`
const iosHomeWrapperSelector =
  `${iosHomeScope} [class*="downloadsWrapper"]`
const androidHomeDownloadShellSelector =
  `${androidHomeScope} [data-otlobli-temu-download-shell="1"]`
const iosHomeDownloadShellSelector =
  `${iosHomeScope} [data-otlobli-temu-download-shell="1"]`
const androidHomeDownloadShellChildrenSelector = `${androidHomeDownloadShellSelector} > *`
const iosHomeDownloadShellChildrenSelector = `${iosHomeDownloadShellSelector} > *`
const androidHomeCollapsedScope =
  `${androidHomeScope}[data-otlobli-temu-download-collapsed="1"]`
const iosHomeCollapsedScope =
  `${iosHomeScope}[data-otlobli-temu-download-collapsed="1"]`
const androidHomeStickyBackgroundSelector =
  `${androidHomeCollapsedScope} [js-selector="bg-cui-top-sticky"]`
const iosHomeStickyBackgroundSelector =
  `${iosHomeCollapsedScope} [js-selector="bg-cui-top-sticky"]`
const wrapperMentions = temuBlockerCss.match(/[^\r\n]*downloadsWrapper[^\r\n]*/g) ?? []
const downloadShellSelectorMentions = temuBlockerCss.match(
  /[^\r\n]*\[data-otlobli-temu-download-shell="1"\][^\r\n]*/g,
) ?? []
const stickyBackgroundMentions = temuBlockerCss.match(
  /[^\r\n]*\[js-selector="bg-cui-top-sticky"\][^\r\n]*/g,
) ?? []
if (temuBlockerResetStart < 0 || temuBlockerResetEnd < 0 ||
    temuDownloadShellFunctionStart < 0 ||
    !temuBlockerReset.includes(androidHomeWrapperSelector) ||
    !temuBlockerReset.includes(iosHomeWrapperSelector) ||
    wrapperMentions.length !== 2 ||
    !wrapperMentions.some((line) => line.includes(androidHomeWrapperSelector)) ||
    !wrapperMentions.some((line) => line.includes(iosHomeWrapperSelector))) {
  throw new Error('Temu download-wrapper collapse must remain scoped to native Android/iOS Home only')
}
if (downloadShellSelectorMentions.length !== 4 ||
    downloadShellSelectorMentions.filter((line) => line.includes(androidHomeScope)).length !== 2 ||
    downloadShellSelectorMentions.filter((line) => line.includes(iosHomeScope)).length !== 2 ||
    !temuBlockerCss.includes(androidHomeDownloadShellSelector) ||
    !temuBlockerCss.includes(androidHomeDownloadShellChildrenSelector) ||
    !temuBlockerCss.includes(iosHomeDownloadShellSelector) ||
    !temuBlockerCss.includes(iosHomeDownloadShellChildrenSelector)) {
  throw new Error('Temu download-shell collapse must target only the shell and its direct children on native Home')
}
if (stickyBackgroundMentions.length !== 2 ||
    stickyBackgroundMentions.filter((line) => line.includes(androidHomeScope)).length !== 1 ||
    stickyBackgroundMentions.filter((line) => line.includes(iosHomeScope)).length !== 1 ||
    !temuBlockerCss.includes(androidHomeStickyBackgroundSelector) ||
    !temuBlockerCss.includes(iosHomeStickyBackgroundSelector)) {
  throw new Error('Temu sticky-header offset repair must remain paired on native Android/iOS Home only')
}
const stickyBackgroundCss = temuBlockerCss.slice(
  temuBlockerCss.indexOf(androidHomeStickyBackgroundSelector),
)
for (const marker of [
  'transform: translate(-50%, 0) !important;',
]) {
  if (!stickyBackgroundCss.includes(marker)) {
    throw new Error(`Temu native Home sticky-header offset repair missing ${marker}`)
  }
}
for (const mention of stickyBackgroundMentions) {
  for (const forbidden of [
    '[class*="sticky"',
    'top: 0',
    'querySelectorAll',
    'setInterval',
  ]) {
    if (mention.includes(forbidden)) {
      throw new Error(`Temu sticky-header offset repair widened to forbidden marker: ${forbidden}`)
    }
  }
}
for (const marker of [
  'function otlobliSyncTemuDownloadCollapsedMarker(root, collapsed)',
  "if (current !== '1') root.setAttribute(marker, '1')",
  'else if (current !== null)',
]) {
  if (!temuBlockerReset.includes(marker)) {
    throw new Error(`Temu collapsed-state marker must update only on a real state transition: ${marker}`)
  }
}
const downloadShellCss = temuBlockerCss.slice(
  temuBlockerCss.indexOf(androidHomeDownloadShellSelector),
)
for (const marker of [
  'height: 0 !important;',
  'min-height: 0 !important;',
  'max-height: 0 !important;',
  'overflow: hidden !important;',
  'padding: 0 !important;',
  'margin: 0 !important;',
  'border: 0 !important;',
]) {
  if (!downloadShellCss.includes(marker)) {
    throw new Error(`Temu native Home download-shell CSS no longer collapses ${marker}`)
  }
}
for (const marker of [
  "var nativePlatform = root.getAttribute('data-otlobli-native-platform')",
  "nativePlatform !== 'android' && nativePlatform !== 'ios'",
  "root.getAttribute('data-otlobli-temu-home-route') !== '1'",
  'otlobliSyncTemuDownloadCollapsedMarker(root, false)',
  "document.querySelector('[class*=\"downloadsWrapper\"]')",
  'for (var depth = 0; shell && depth < 8; depth++)',
  'if (shell.childElementCount > 1)',
  "shell.querySelector('input,[role=\"searchbox\"],[class*=\"wrapperWithSearch\"],[class*=\"searchBar\" i]')",
  'var rect = shell.getBoundingClientRect();',
  'rect.top > 96 || rect.width < viewportWidth * 0.65 || rect.height > 180',
  "shell.setAttribute('data-otlobli-temu-download-shell', '1')",
  'otlobliSyncTemuDownloadCollapsedMarker(root, true)',
]) {
  if (!temuDownloadShellFunction.includes(marker)) {
    throw new Error(`Temu bounded native Home download-shell detector missing marker: ${marker}`)
  }
}
const temuHeaderInjectStart = captureScript.indexOf('function injectTemuHeaderHideCSS', temuBlockerResetStart)
const temuHeaderInjectEnd = captureScript.indexOf('function otlobliSuspendTemuRuntimeForChallenge', temuHeaderInjectStart)
const temuHeaderInject = captureScript.slice(temuHeaderInjectStart, temuHeaderInjectEnd)
const syncHomeRouteAt = temuHeaderInject.indexOf('otlobliSyncTemuProductRouteState();')
const markDownloadShellAt = temuHeaderInject.indexOf('otlobliMarkTemuNativeDownloadShell();')
if (temuHeaderInjectStart < 0 || temuHeaderInjectEnd < 0 || syncHomeRouteAt < 0 ||
    markDownloadShellAt < syncHomeRouteAt) {
  throw new Error('Temu download-shell detector must run after the current SPA Home route is synchronized')
}
for (const marker of [
  "document.documentElement.setAttribute('data-otlobli-native-platform', OTLOBLI_NATIVE_PLATFORM)",
  "var homePath = String(location.pathname || '/').replace(/\\\\/{2,}/g, '/').replace(/\\\\/+$/, '')",
  "var homeRoute = !homePath || /^\\\\/[a-z]{2}(?:-[a-z]{2})?$/i.test(homePath)",
  "homeRoute && !otlobliTemuAccountRoute()",
  "root.setAttribute('data-otlobli-temu-home-route', '1')",
  "root.removeAttribute('data-otlobli-temu-home-route')",
]) {
  if (!captureScript.includes(marker)) {
    throw new Error(`Temu Android Home wrapper route guard missing marker: ${marker}`)
  }
}
for (const forbidden of [
  '__otlobliTemuScrollRehideBound',
  'a,button,[role="button"],div,section,aside,nav,header',
]) {
  if (captureScript.includes(forbidden)) throw new Error(`Temu hot-path scan regression detected: ${forbidden}`)
}
if (runtimeCoordinator.includes('otlobliCleanTemuBlockers(true)')) {
  throw new Error('Temu navigation maintenance must not force a blocker scan')
}

const capgoChallengeCaseStart = appliedCapgoIosController.indexOf('case "humanCheck", "humanCheckResolved":')
const capgoChallengeCaseEnd = appliedCapgoIosController.indexOf('case "sheinSaudiReady"', capgoChallengeCaseStart)
const capgoChallengeCase = appliedCapgoIosController.slice(capgoChallengeCaseStart, capgoChallengeCaseEnd)
if (capgoChallengeCaseStart < 0 || capgoChallengeCaseEnd < 0 ||
    !capgoChallengeCase.includes('cancelOtlobliChallengeReveal()') ||
    !capgoChallengeCase.includes('hideOtlobliLoadingCover()') ||
    capgoChallengeCase.includes('showOtlobliLoadingCover()') ||
    capgoChallengeCase.includes('scheduleOtlobliChallengeReveal()')) {
  throw new Error('Capgo iOS verification UI must dismiss the native cover immediately')
}
const capgoChallengeHandlerStart = appliedCapgoIosController.indexOf('private func handleOtlobliLoadingCoverMessage')
const capgoChallengeHandlerEnd = appliedCapgoIosController.indexOf('func updateButtonTintColors()', capgoChallengeHandlerStart)
const capgoChallengeHandler = appliedCapgoIosController.slice(capgoChallengeHandlerStart, capgoChallengeHandlerEnd)
const capgoChallengeBackHide = capgoChallengeHandler.indexOf('otlobliNativeBackButton?.isHidden = true')
const capgoCoverOptionGuard = capgoChallengeHandler.indexOf('guard otlobliLoadingCoverEnabled else { return }')
if (capgoChallengeHandlerStart < 0 || capgoChallengeHandlerEnd < 0 ||
    capgoChallengeBackHide < 0 || capgoCoverOptionGuard < 0 ||
    capgoChallengeBackHide > capgoCoverOptionGuard) {
  throw new Error('Capgo iOS verification must hide Back before the optional loading-cover guard')
}

for (const marker of [
  'private var otlobliHumanChallengeActive = false',
  'private var otlobliHumanChallengeResolutionReported = false',
  'private func handleOtlobliHumanChallengeMessage(',
  'guard message.frameInfo.isMainFrame',
  'setOtlobliHumanChallengeActive(true)',
  'otlobliHumanChallengeResolutionReported = true',
  'guard trustedReady, otlobliReadyGenerationCanRelease(readyGeneration) else { return }',
  'setOtlobliHumanChallengeActive(false)',
  '!self.otlobliHumanChallengeActive',
  'guard !otlobliHumanChallengeActive else { return }',
  'guard !otlobliHumanChallengeActive else { return false }',
]) {
  if (!appliedCapgoIosController.includes(marker)) {
    throw new Error(`Capgo iOS challenge-navigation isolation missing marker: ${marker}`)
  }
  if (!inAppBrowserPatchAdded.includes(marker)) {
    throw new Error(`Capgo patch does not preserve iOS challenge-navigation marker: ${marker}`)
  }
}
const capgoIosResolvedStart = appliedCapgoIosController.indexOf('if type == "humanCheckResolved"')
const capgoIosResolvedEnd = appliedCapgoIosController.indexOf('var readyGeneration = ""', capgoIosResolvedStart)
const capgoIosResolved = appliedCapgoIosController.slice(capgoIosResolvedStart, capgoIosResolvedEnd)
if (capgoIosResolvedStart < 0 || capgoIosResolvedEnd < 0 ||
    !capgoIosResolved.includes('otlobliHumanChallengeResolutionReported = true') ||
    !capgoIosResolved.includes('setOtlobliHumanChallengeActive(true)') ||
    capgoIosResolved.includes('setOtlobliHumanChallengeActive(false)')) {
  throw new Error('Capgo iOS humanCheckResolved must remain status-only until a trusted ready hand-off')
}

for (const marker of [
  'private volatile boolean otlobliHumanChallengeNavigationLocked = false;',
  'private boolean otlobliHumanChallengeResolutionReported = false;',
  'private void handleOtlobliHumanChallengeMessage(String message, Uri sourceOrigin, boolean isMainFrame)',
  'if (!isMainFrame) return false;',
  'handleOtlobliHumanChallengeMessage(message, sourceOrigin, isMainFrame);',
  'otlobliHumanChallengeNavigationLocked = true;',
  'otlobliHumanChallengeResolutionReported = true;',
  'otlobliReadyDocumentCanReleaseHumanChallenge(readyGeneration)',
  'boolean canGoBack = !otlobliHumanChallengeNavigationLocked && _webView.canGoBack();',
  'if (!otlobliHumanChallengeNavigationLocked && _webView != null && _webView.canGoBack())',
  'if (otlobliHumanChallengeNavigationLocked) {',
]) {
  if (!appliedCapgoAndroid.includes(marker)) {
    throw new Error(`Capgo Android challenge-navigation isolation missing marker: ${marker}`)
  }
  if (!inAppBrowserPatchAdded.includes(marker)) {
    throw new Error(`Capgo patch does not preserve Android challenge-navigation marker: ${marker}`)
  }
}
const capgoAndroidResolvedStart = appliedCapgoAndroid.indexOf('if ("humanCheckResolved".equals(type))')
const capgoAndroidResolvedEnd = appliedCapgoAndroid.indexOf('String readyGeneration = "";', capgoAndroidResolvedStart)
const capgoAndroidResolved = appliedCapgoAndroid.slice(capgoAndroidResolvedStart, capgoAndroidResolvedEnd)
if (capgoAndroidResolvedStart < 0 || capgoAndroidResolvedEnd < 0 ||
    !capgoAndroidResolved.includes('otlobliHumanChallengeResolutionReported = true;') ||
    capgoAndroidResolved.includes('otlobliClearHumanChallengeNavigationGate()')) {
  throw new Error('Capgo Android humanCheckResolved must remain status-only until a trusted ready hand-off')
}

const dedicatedIosChallengeStart = iosSheinBrowser.indexOf('if type == "humanCheck" || type == "humanCheckResolved"')
const dedicatedIosChallengeEnd = iosSheinBrowser.indexOf('if detail["type"] as? String == "otlobliBackButtonState"', dedicatedIosChallengeStart)
const dedicatedIosChallenge = iosSheinBrowser.slice(dedicatedIosChallengeStart, dedicatedIosChallengeEnd)
if (dedicatedIosChallengeStart < 0 || dedicatedIosChallengeEnd < 0 ||
    !dedicatedIosChallenge.includes('setHumanChallengeNavigationLocked(true)') ||
    dedicatedIosChallenge.includes('humanChallengeNavigationLocked = false')) {
  throw new Error('Dedicated SHEIN iOS verification must lock native Back and gestures through resolved status')
}
for (const marker of [
  'private var humanChallengeNavigationLocked = false',
  'webView.allowsBackForwardNavigationGestures = !humanChallengeNavigationLocked',
  'private func setHumanChallengeNavigationLocked(_ locked: Bool)',
  'storeWebView?.allowsBackForwardNavigationGestures = !locked',
  'private func shouldReleaseHumanChallengeNavigation(for detail: [String: Any]) -> Bool',
  'type == "humanCheck" || type == "humanCheckResolved"',
  'setHumanChallengeNavigationLocked(true)',
  'humanChallengeNavigationLocked && shouldReleaseHumanChallengeNavigation(for: detail)',
  'setHumanChallengeNavigationLocked(false)',
  'guard !humanChallengeNavigationLocked else',
]) {
  if (!iosSheinBrowser.includes(marker)) {
    throw new Error(`Dedicated SHEIN iOS challenge-navigation isolation missing marker: ${marker}`)
  }
}

for (const marker of [
  'var countryFromName = sheinCountryCodeFromLabel(name);',
  'var repairStalledFor = repairNow - Math.max(sheinShippingProgressAt || 0, sheinNativeCoverRepairStartedAt);',
  'if (repairStalledFor >= repairStallLimit || repairAge >= repairAbsoluteLimit)',
  'function sheinPrimeRegionRepairFromRoute()',
  'var repairStarted = sheinPrepareNativeSaudiRepair();',
  "sheinRegionCountryLabel() + '</span>'",
]) {
  if (!captureScript.includes(marker)) throw new Error(`SHEIN v86.71 region cascade guard missing marker: ${marker}`)
}

const temuHomeLikePath = (rawPath) => {
  const path = String(rawPath || '/').replace(/\/{2,}/g, '/').replace(/\/+$/, '')
  return !path || /^\/[a-z]{2}(?:-[a-z]{2})?$/i.test(path)
}
for (const [path, expected] of [
  ['/', true],
  ['/qa/', true],
  ['/qa-en/', true],
  ['/goods.html', false],
  ['/qa/search_result.html', false],
  ['/qa/channel/1001.html', false],
]) {
  if (temuHomeLikePath(path) !== expected) {
    throw new Error(`Temu root classifier misclassified ${path}`)
  }
}

for (const marker of [
  'private var nativeNavigationView: UIView?',
  'installNativeNavigation(in: surface)',
  'private func makeNativeNavigation() -> UIView',
  'private func makeNativeNavigationIcon(route: String, color: UIColor) -> UIImage',
  'configuration.image = makeNativeNavigationIcon(route: routes[index], color: color)',
  'button.accessibilityIdentifier = routes[index]',
  '@objc private func nativeNavigationPressed(_ sender: UIButton)',
  'if UIAccessibility.isVoiceOverRunning',
  'DispatchQueue.main.asyncAfter(deadline: .now() + 0.32, execute: timeout)',
  'let routes = ["store-select", "orders", "cart", "profile"]',
  'webView.bottomAnchor.constraint(equalTo: navigation.topAnchor)',
  'let preferredSafeTop = navigation.topAnchor.constraint(',
  'let preferredFloorTop = navigation.topAnchor.constraint(',
  'navigation.heightAnchor.constraint(greaterThanOrEqualToConstant: 90)',
  'navigation.bottomAnchor.constraint(equalTo: surface.bottomAnchor)',
  'let coverBottomAnchor = nativeNavigationView?.topAnchor ?? surface.bottomAnchor',
  'cover.bottomAnchor.constraint(equalTo: coverBottomAnchor)',
  'navigation.layer.shadowOpacity = 0',
  'navigation.transform = .identity',
  'navigation.accessibilityViewIsModal = false',
  'window.__otlobliNativeNavigation=true;',
  'navigateHost(to: target)',
  'parkRenderSurfaceBehindApp()',
  'let revealHost = DispatchWorkItem',
  'DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: revealHost)',
  "window.dispatchEvent(new CustomEvent('otlobli:nativeNavigate'",
  'if nativeBackTarget == "orders"',
  'emit("messageFromWebview", detail: ["type": "backToOrders"])',
]) {
  if (!iosSheinBrowser.includes(marker)) {
    throw new Error(`iOS permanent native navigation guard missing marker: ${marker}`)
  }
}

for (const forbidden of ['UIImage(systemName: "house")', 'UIImage(systemName: symbols[index])']) {
  if (iosSheinBrowser.includes(forbidden)) {
    throw new Error(`iOS permanent navigation must keep the Otlobli icon paths: ${forbidden}`)
  }
}

const iosLoadingCoverStart = iosSheinBrowser.indexOf('private func installLoadingCover(')
const iosLoadingCoverEnd = iosSheinBrowser.indexOf('private func hideLoadingCover()', iosLoadingCoverStart)
const iosLoadingCoverSource = iosSheinBrowser.slice(iosLoadingCoverStart, iosLoadingCoverEnd)
if (iosLoadingCoverStart < 0 || iosLoadingCoverEnd < 0 ||
    iosLoadingCoverSource.includes('makeNativeNavigation') ||
    iosLoadingCoverSource.includes('cover.addSubview(navigation)')) {
  throw new Error('iOS loading cover must stop above, and never own a duplicate of, the permanent native navigation')
}

const iosNativeNavigationStart = iosSheinBrowser.indexOf('private func makeNativeNavigation()')
const iosNativeNavigationEnd = iosSheinBrowser.indexOf('@objc private func nativeNavigationPressed', iosNativeNavigationStart)
const iosNativeNavigationSource = iosSheinBrowser.slice(iosNativeNavigationStart, iosNativeNavigationEnd)
const iosNativeShadowAssignments = [...iosNativeNavigationSource.matchAll(/shadowOpacity\s*=\s*([^\r\n]+)/g)]
if (iosNativeNavigationStart < 0 || iosNativeNavigationEnd < 0 ||
    iosNativeNavigationSource.includes('UIVisualEffectView') ||
    iosNativeNavigationSource.includes('UIView.animate') ||
    iosNativeShadowAssignments.some((match) => !/^0(?:\.0)?\b/.test(match[1].trim()))) {
  throw new Error('iOS permanent native navigation must remain a static opaque UIKit surface without blur, animation or shadow')
}

const iosNativeOwnershipStart = iosSheinBrowser.indexOf('private func nativeNavigationOwnershipScript()')
const iosNativeOwnershipEnd = iosSheinBrowser.indexOf('private func shouldReleaseLoadingCover(', iosNativeOwnershipStart)
const iosNativeOwnershipSource = iosSheinBrowser.slice(iosNativeOwnershipStart, iosNativeOwnershipEnd)
for (const forbidden of ['MutationObserver', 'setTimeout(', 'setInterval(', 'observer.observe(']) {
  if (iosNativeOwnershipStart < 0 || iosNativeOwnershipEnd < 0 || iosNativeOwnershipSource.includes(forbidden)) {
    throw new Error(`iOS native ownership must not maintain a DOM navigation layer: ${forbidden}`)
  }
}

for (const marker of [
  'const nativeStorePrelude = `window.__otlobliNativeNavigation=true;',
  'otlobliNativeNavigation?: boolean',
  'otlobliNativeNavigation: true',
  'enabledSafeBottomMargin: false',
  'otlobliTemuDocumentStartScript?: string',
  "nativeStorePlatform === 'android'",
  'otlobliTemuDocumentStartScript: captureBundle.TEMU_DOCUMENT_START_SCRIPT',
]) {
  if (!app.includes(marker)) throw new Error(`Native store ownership guard missing App marker: ${marker}`)
}
for (const marker of [
  "import { TEMU_DOCUMENT_START_SCRIPT } from './temuDocumentStartScript'",
  'TEMU_DOCUMENT_START_SCRIPT,',
]) {
  if (!storeCaptureBundleSource.includes(marker)) {
    throw new Error(`Temu document-start export missing from the lazy store bundle: ${marker}`)
  }
}
for (const forbidden of [
  'MutationObserver', 'setInterval(', "querySelectorAll('*')", 'visualViewport', 'globalThis',
  "var controls = document.querySelectorAll('button,[role=\"button\"],a",
]) {
  if (temuDocumentStartSource.includes(forbidden)) {
    throw new Error(`Temu document-start policy widened into forbidden work: ${forbidden}`)
  }
}
if (/otlobliTemuDocumentStartScript:\s*`\$\{nativeStorePrelude\}/.test(app)) {
  throw new Error('Temu document-start payload must run its host/challenge guard before writing native globals')
}
for (const marker of [
  'window.top !== window',
  'temu\\\\.com$',
  'bgn[_-]?verification',
  'cookieAttempts >= 3',
  'insideSkuDialog(control)',
  'data-otlobli-temu-cookie-auto-accepted',
]) {
  if (!temuDocumentStartSource.includes(marker)) {
    throw new Error(`Temu document-start policy missing scoped marker: ${marker}`)
  }
}

const assertAndroidTemuDocumentStart = (source, label, { forbidGeneric = true } = {}) => {
  for (const pattern of [
    /private\s+String\s+otlobliTemuDocumentStartScript;/,
    /getOtlobliTemuDocumentStartScript\(\)/,
    /setOtlobliTemuDocumentStartScript\(/,
    /getString\("otlobliTemuDocumentStartScript",\s*null\)/,
    /otlobliIsTemuSession\(\)\s*&&\s*!TextUtils\.isEmpty\(temuDocumentStartScript\)/,
    /addDocumentStartJavaScript\(_webView,\s*temuDocumentStartScript,\s*Collections\.singleton\("\*"\)\)/,
    /injectTemuDocumentStartNavigationFallback\(WebView\s+view\)/,
    /WebViewFeature\.isFeatureSupported\(WebViewFeature\.DOCUMENT_START_SCRIPT\)/,
    /view\.evaluateJavascript\(script,\s*null\)/,
    /injectTemuDocumentStartNavigationFallback\(view\);/,
  ]) {
    if (!pattern.test(source)) {
      throw new Error(`${label}: Temu-only Android document-start injection is incomplete: ${pattern}`)
    }
  }
  if (forbidGeneric && /getString\("otlobliDocumentStartScript"/.test(source)) {
    throw new Error(`${label}: Android must not activate SHEIN's existing iOS document-start option`)
  }
}

assertAndroidTemuDocumentStart(
  `${readFileSync(new URL('../node_modules/@capgo/capacitor-inappbrowser/android/src/main/java/ee/forgr/capacitor_inappbrowser/Options.java', import.meta.url), 'utf8')}\n` +
  `${readFileSync(new URL('../node_modules/@capgo/capacitor-inappbrowser/android/src/main/java/ee/forgr/capacitor_inappbrowser/CapgoInAppBrowserPlugin.java', import.meta.url), 'utf8')}\n` +
  appliedCapgoAndroid,
  'applied Android Capgo',
)
assertAndroidTemuDocumentStart(inAppBrowserPatchAdded, 'Android Capgo patch', { forbidGeneric: false })
const appliedTemuDocumentStartMethod = appliedCapgoAndroid.slice(
  appliedCapgoAndroid.indexOf('private void injectDocumentStartJavaScriptInterface()'),
  appliedCapgoAndroid.indexOf('private void injectDocumentStartPostMessageBridge()', appliedCapgoAndroid.indexOf('private void injectDocumentStartJavaScriptInterface()')),
)
if (!appliedTemuDocumentStartMethod.includes('WebViewFeature.DOCUMENT_START_SCRIPT')) {
  throw new Error('Applied Android Capgo must feature-gate Temu document-start injection')
}
for (const pattern of [
  /\.bottom-nav\s*\{[\s\S]{0,500}?max-width:\s*440px/,
  /\.bottom-nav\s*\{[\s\S]{0,500}?width:\s*min\(100%,\s*440px\)/,
  /\.bottom-nav\s*\{[\s\S]{0,500}?margin-inline:\s*auto/,
]) {
  if (!pattern.test(customerStyles)) {
    throw new Error('React bottom navigation must remain centered with a 440px maximum width')
  }
}
for (const [source, label] of [
  [app, 'App'],
  [storeCaptureBundleSource, 'storeCaptureBundle'],
  [sheinBrowserSource, 'sheinBrowserScript'],
]) {
  if (source.includes('OTLOBLI_NAV_BOOTSTRAP_SCRIPT')) {
    throw new Error(`${label} must not ship or export the legacy DOM navigation bootstrap`)
  }
}

for (const marker of [
  'order-card-footer',
  'order-card-id',
  'رقم الطلب ${item.id}',
  'const openStoreProductFromOrder = (sourceLink: string, fallbackStore: StoreId)',
  "openStoreProductFromCart(sourceLink, 'orders')",
  "screen === 'home' && pendingBackTargetRef.current === 'orders'",
  "returnTarget === 'orders' && (screenRef.current === 'tracking' || screenRef.current === 'home')",
  'className="tracking-product-button"',
  "detail?.type === 'backToOrders'",
]) {
  if (!app.includes(marker)) throw new Error(`Order-number visibility guard missing App marker: ${marker}`)
}

const orderProductOpenStart = app.indexOf('const openStoreProductFromOrder = (sourceLink: string, fallbackStore: StoreId)')
const orderProductOpenEnd = app.indexOf('const openStoreFromHub = (id: StoreId)', orderProductOpenStart)
const orderProductOpenSource = app.slice(orderProductOpenStart, orderProductOpenEnd)
const orderWarmOpen = orderProductOpenSource.indexOf("openStoreProductFromCart(sourceLink, 'orders')")
const orderImmediateHome = orderProductOpenSource.indexOf('navigateToStoreSurface(true)', orderWarmOpen)
if (orderProductOpenStart < 0 || orderProductOpenEnd < 0 || orderWarmOpen < 0 ||
    orderImmediateHome < orderWarmOpen) {
  throw new Error('Order product must enter the warm store flow and commit Home immediately on tap')
}
if (!/\.mobile-content--orders\s*\{[^}]*grid-auto-rows:\s*max-content/s.test(customerStyles)) {
  throw new Error('Orders grid must size each order card from its full content so the footer cannot be clipped')
}

for (const marker of [
  'private void otlobliNavigateHost(String target)',
  'guard let self else { return }',
  'The native back control is also required by Temu',
  '["cart", "orders", "exit"].contains(target)',
  '["type": "backToOrders"]',
  'guard let webView = self.webView else { return }',
  'updates WKWebView.url without a didFinish/pageshow callback',
  'republishOtlobliNativeBackState(in: webView)',
]) {
  if (!inAppBrowserPatchAdded.includes(marker)) {
    throw new Error(`Native root-exit patch guard missing marker: ${marker}`)
  }
}

const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
const requirePattern = (source, pattern, message) => {
  if (!pattern.test(source)) throw new Error(message)
}

const assertDedicatedIosNativeNavigationParity = (source, label) => {
  const installStart = source.indexOf('private func installNativeNavigation(in surface: UIView)')
  const navigationStart = source.indexOf('private func makeNativeNavigation()', installStart)
  const navigationEnd = source.indexOf('@objc private func nativeNavigationPressed', navigationStart)
  if (installStart < 0 || navigationStart < 0 || navigationEnd < 0) {
    throw new Error(`${label}: unable to inspect the dedicated native navigation`)
  }

  const installSource = source.slice(installStart, navigationStart)
  const navigationSource = source.slice(navigationStart, navigationEnd)
  for (const [pattern, message] of [
    [/navigation\.centerXAnchor\.constraint\(equalTo:\s*surface\.safeAreaLayoutGuide\.centerXAnchor\)/, 'navigation is not centered in the safe area'],
    [/navigation\.leadingAnchor\.constraint\(greaterThanOrEqualTo:\s*surface\.safeAreaLayoutGuide\.leadingAnchor\)/, 'safe leading bound is missing'],
    [/navigation\.trailingAnchor\.constraint\(lessThanOrEqualTo:\s*surface\.safeAreaLayoutGuide\.trailingAnchor\)/, 'safe trailing bound is missing'],
    [/navigation\.widthAnchor\.constraint\(lessThanOrEqualToConstant:\s*440\)/, '440pt maximum width is missing'],
    [/let\s+preferredFullSafeWidth\s*=\s*navigation\.widthAnchor\.constraint\(\s*equalTo:\s*surface\.safeAreaLayoutGuide\.widthAnchor\s*\)/, 'preferred full safe width is missing'],
    [/preferredFullSafeWidth\.priority\s*=\s*\.defaultHigh/, 'preferred width priority is missing'],
    [/let\s+preferredSafeTop\s*=\s*navigation\.topAnchor\.constraint\(\s*equalTo:\s*surface\.safeAreaLayoutGuide\.bottomAnchor,\s*constant:\s*-74\s*\)/, '74pt safe-area height is missing'],
    [/preferredSafeTop\.priority\s*=\s*\.defaultHigh/, 'safe-area height priority is missing'],
    [/let\s+preferredFloorTop\s*=\s*navigation\.topAnchor\.constraint\(\s*equalTo:\s*surface\.bottomAnchor,\s*constant:\s*-90\s*\)/, '90pt bottom floor is missing'],
    [/preferredFloorTop\.priority\s*=\s*UILayoutPriority\(rawValue:\s*749\)/, 'bottom-floor priority is missing'],
    [/navigation\.heightAnchor\.constraint\(greaterThanOrEqualToConstant:\s*90\)/, '90pt minimum height is missing'],
    [/navigation\.bottomAnchor\.constraint\(equalTo:\s*surface\.bottomAnchor\)/, 'navigation does not include the bottom safe area'],
    [/scheduleNativeStoreSwitchDiscoveryHint\(\)/, 'entry discovery hint is not scheduled from the native surface'],
    [/message:\s*"انقر «الرئيسية» مرتين لفتح قائمة المتاجر"/, 'entry hint does not describe opening the store chooser'],
    [/message:\s*"انقر مرة ثانية لفتح قائمة المتاجر"/, 'first-tap hint is missing'],
    [/DispatchQueue\.main\.asyncAfter\(deadline:\s*\.now\(\)\s*\+\s*0\.7,\s*execute:\s*discovery\)/, 'entry hint is not a bounded one-shot delay'],
    [/guard\s+isBrowserVisible,[\s\S]{0,100}?!humanChallengeNavigationLocked/, 'entry hint is not gated away from hidden or human-check state'],
  ]) {
    requirePattern(installSource, pattern, `${label}: ${message}`)
  }

  for (const [pattern, message] of [
    [/button\.accessibilityLabel\s*=\s*labels\[index\]/, 'button accessibility label is not the visible destination'],
    [/button\.accessibilityHint\s*=\s*index\s*==\s*0[\s\S]{0,100}?"يفتح قائمة المتاجر مباشرة"/, 'Home accessibility hint does not describe direct activation'],
    [/outgoing\.font\s*=\s*\.systemFont\(ofSize:\s*12,\s*weight:\s*\.bold\)/, 'labels are not fixed bold 12pt'],
    [/configuration\.contentInsets\s*=\s*NSDirectionalEdgeInsets\(top:\s*10,\s*leading:\s*0,\s*bottom:\s*0,\s*trailing:\s*0\)/, 'label/icon content does not keep the matching 10pt top offset'],
    [/let\s+preferredSafeContentBottom\s*=\s*stack\.bottomAnchor\.constraint\(\s*equalTo:\s*navigation\.safeAreaLayoutGuide\.bottomAnchor\s*\)/, 'content is not aligned to the real safe bottom'],
    [/preferredSafeContentBottom\.priority\s*=\s*\.defaultHigh/, 'safe-content priority is missing'],
    [/let\s+preferredFloorContentBottom\s*=\s*stack\.bottomAnchor\.constraint\(\s*equalTo:\s*navigation\.bottomAnchor,\s*constant:\s*-16\s*\)/, '16pt content floor is missing'],
    [/preferredFloorContentBottom\.priority\s*=\s*UILayoutPriority\(rawValue:\s*749\)/, 'content-floor priority is missing'],
    [/stack\.bottomAnchor\.constraint\(lessThanOrEqualTo:\s*navigation\.bottomAnchor,\s*constant:\s*-16\)/, 'required 16pt bottom floor is missing'],
  ]) {
    requirePattern(navigationSource, pattern, `${label}: ${message}`)
  }
  if (/UIFontMetrics|scaledFont\(|adjustsFontForContentSizeCategory\s*=\s*true/.test(navigationSource)) {
    throw new Error(`${label}: fixed navigation labels must not opt into dynamic type scaling`)
  }

  const pressEnd = source.indexOf('private func navigateHost(to target: String)', navigationEnd)
  const pressSource = source.slice(navigationEnd, pressEnd)
  if (pressEnd < 0) throw new Error(`${label}: unable to inspect Home activation`)
  requirePattern(
    pressSource,
    /if\s+UIAccessibility\.isVoiceOverRunning\s*\{[\s\S]{0,220}?navigateHost\(to:\s*target\)[\s\S]{0,80}?return/,
    `${label}: VoiceOver activation must open the chooser directly`,
  )
  requirePattern(
    pressSource,
    /DispatchQueue\.main\.asyncAfter\(deadline:\s*\.now\(\)\s*\+\s*0\.32,\s*execute:\s*timeout\)/,
    `${label}: Home does not retain the 320ms double-activation window`,
  )
  requirePattern(
    pressSource,
    /DispatchQueue\.main\.asyncAfter\(deadline:\s*\.now\(\)\s*\+\s*0\.32,\s*execute:\s*timeout\)[\s\S]{0,100}?showNativeStoreSwitchSecondTapHint\(\)/,
    `${label}: first Home tap does not show the bounded second-tap hint`,
  )
  requirePattern(
    pressSource,
    /guard\s+!humanChallengeNavigationLocked\s+else\s*\{[\s\S]{0,120}?dismissNativeStoreSwitchHint\(\)[\s\S]{0,60}?return/,
    `${label}: store navigation is not inert while human verification owns the surface`,
  )
  const challengeLockStart = source.indexOf('private func setHumanChallengeNavigationLocked(_ locked: Bool)')
  const challengeLockEnd = source.indexOf('private func shouldReleaseHumanChallengeNavigation(', challengeLockStart)
  const challengeLockSource = source.slice(challengeLockStart, challengeLockEnd)
  if (challengeLockStart < 0 || challengeLockEnd < 0) {
    throw new Error(`${label}: unable to inspect human-verification hint ownership`)
  }
  requirePattern(
    challengeLockSource,
    /if\s+locked\s*\{[\s\S]{0,100}?dismissNativeStoreSwitchHint\(\)/,
    `${label}: entering human verification does not dismiss the store-switch hint`,
  )
  const pluginShowStart = source.indexOf('@objc func show(_ call: CAPPluginCall)')
  const pluginShowEnd = source.indexOf('@objc func hide(_ call: CAPPluginCall)', pluginShowStart)
  requirePattern(
    source.slice(pluginShowStart, pluginShowEnd),
    /scheduleNativeStoreSwitchDiscoveryHint\(\)/,
    `${label}: returning to a parked store does not restore a cancelled entry hint`,
  )
  const bridgeShowStart = source.indexOf('case "show":')
  const bridgeShowEnd = source.indexOf('case "navigate":', bridgeShowStart)
  requirePattern(
    source.slice(bridgeShowStart, bridgeShowEnd),
    /scheduleNativeStoreSwitchDiscoveryHint\(\)/,
    `${label}: JavaScript show does not restore a cancelled entry hint`,
  )
}

const assertIosCapgoNativeNavigation = (optionSource, controllerSource, label) => {
  const wiring = optionSource.match(
    /webViewController\.([A-Za-z_]\w*)\s*=\s*call\.getBool\("otlobliNativeNavigation",\s*false\)/,
  )
  if (!wiring) throw new Error(`${label}: scoped option is not wired into the presented controller`)
  const enabledProperty = wiring[1]
  requirePattern(
    controllerSource,
    new RegExp(`(?:open\\s+)?var\\s+${escapeRegExp(enabledProperty)}(?:\\s*:\\s*Bool)?\\s*=\\s*false`),
    `${label}: the wired native-navigation option has no controller state`,
  )

  const localNavigationMatch = controllerSource.match(
    /(?:let|var)\s+([A-Za-z_]\w*)\s*=\s*UIView\(frame:\s*\.zero\)[\s\S]{0,1400}?\1\.accessibilityIdentifier\s*=\s*"otlobli-native-navigation"/,
  )
  if (!localNavigationMatch) throw new Error(`${label}: no accessibility-identified sibling native bar is constructed`)
  const localNavigation = localNavigationMatch[1]
  const navigationStorage = [...controllerSource.matchAll(/private\s+var\s+([A-Za-z_]\w*)\s*:\s*UIView\?/g)]
    .map((match) => match[1])
    .find((candidate) => new RegExp(`${escapeRegExp(candidate)}\\s*=\\s*${escapeRegExp(localNavigation)}\\b`).test(controllerSource))
  if (!navigationStorage) throw new Error(`${label}: the constructed bar is not retained by the controller`)

  requirePattern(
    controllerSource,
    new RegExp(`(?:if\\s+${escapeRegExp(navigationStorage)}\\s*!=\\s*nil\\s*\\{\\s*return\\s*\\}|guard\\s+${escapeRegExp(navigationStorage)}\\s*==\\s*nil\\s+else\\s*\\{\\s*return\\s*\\})`),
    `${label}: native-bar installation is not idempotent`,
  )
  requirePattern(
    controllerSource,
    new RegExp(`view\\.addSubview\\(${escapeRegExp(localNavigation)}\\)`),
    `${label}: native bar is not a sibling of WKWebView`,
  )
  requirePattern(
    controllerSource,
    new RegExp(`let\\s+preferredSafeTop\\s*=\\s*${escapeRegExp(localNavigation)}\\.topAnchor\\.constraint\\(\\s*equalTo:\\s*view\\.safeAreaLayoutGuide\\.bottomAnchor,\\s*constant:\\s*-74\\s*\\)`),
    `${label}: native bar does not own the 74pt safe-area height`,
  )
  requirePattern(
    controllerSource,
    /preferredSafeTop\.priority\s*=\s*\.defaultHigh/,
    `${label}: safe-area height priority is missing`,
  )
  requirePattern(
    controllerSource,
    new RegExp(`let\\s+preferredFloorTop\\s*=\\s*${escapeRegExp(localNavigation)}\\.topAnchor\\.constraint\\(\\s*equalTo:\\s*view\\.bottomAnchor,\\s*constant:\\s*-90\\s*\\)`),
    `${label}: native bar does not preserve the 90pt bottom floor`,
  )
  requirePattern(
    controllerSource,
    /preferredFloorTop\.priority\s*=\s*UILayoutPriority\(rawValue:\s*749\)/,
    `${label}: bottom-floor priority is missing`,
  )
  requirePattern(
    controllerSource,
    new RegExp(`${escapeRegExp(localNavigation)}\\.heightAnchor\\.constraint\\(greaterThanOrEqualToConstant:\\s*90\\)`),
    `${label}: native bar has no 90pt minimum height`,
  )
  requirePattern(
    controllerSource,
    new RegExp(`${escapeRegExp(localNavigation)}\\.bottomAnchor\\.constraint\\(equalTo:\\s*view\\.bottomAnchor\\)`),
    `${label}: native bar does not include the bottom safe area`,
  )
  for (const [pattern, message] of [
    [new RegExp(`${escapeRegExp(localNavigation)}\\.centerXAnchor\\.constraint\\(equalTo:\\s*view\\.safeAreaLayoutGuide\\.centerXAnchor\\)`), 'navigation is not centered in the safe area'],
    [new RegExp(`${escapeRegExp(localNavigation)}\\.leadingAnchor\\.constraint\\(greaterThanOrEqualTo:\\s*view\\.safeAreaLayoutGuide\\.leadingAnchor\\)`), 'safe leading bound is missing'],
    [new RegExp(`${escapeRegExp(localNavigation)}\\.trailingAnchor\\.constraint\\(lessThanOrEqualTo:\\s*view\\.safeAreaLayoutGuide\\.trailingAnchor\\)`), 'safe trailing bound is missing'],
    [new RegExp(`${escapeRegExp(localNavigation)}\\.widthAnchor\\.constraint\\(lessThanOrEqualToConstant:\\s*440\\)`), '440pt maximum width is missing'],
    [new RegExp(`let\\s+preferredFullSafeWidth\\s*=\\s*${escapeRegExp(localNavigation)}\\.widthAnchor\\.constraint\\(\\s*equalTo:\\s*view\\.safeAreaLayoutGuide\\.widthAnchor\\s*\\)`), 'preferred full safe width is missing'],
    [/preferredFullSafeWidth\.priority\s*=\s*\.defaultHigh/, 'preferred width priority is missing'],
  ]) {
    requirePattern(controllerSource, pattern, `${label}: ${message}`)
  }

  const anchorHelper = controllerSource.match(
    /func\s+([A-Za-z_]\w*)\(\)\s*->\s*NSLayoutYAxisAnchor\s*\{[\s\S]{0,650}?return\s+[A-Za-z_]\w*\.topAnchor[\s\S]{0,160}?\}/,
  )
  const directWebViewConstraint = /webView\.bottomAnchor\.constraint\(equalTo:\s*[A-Za-z_]\w*\.topAnchor\)/.test(controllerSource)
  const helperWebViewConstraint = anchorHelper &&
    anchorHelper[0].includes(enabledProperty) &&
    anchorHelper[0].includes(navigationStorage) &&
    new RegExp(`webView\\.bottomAnchor\\.constraint\\(equalTo:\\s*${escapeRegExp(anchorHelper[1])}\\(\\)\\)`).test(controllerSource)
  if (!directWebViewConstraint && !helperWebViewConstraint) {
    throw new Error(`${label}: WKWebView is not constrained above the retained native bar`)
  }

  const coversAboveBar = controllerSource.match(
    /cover\.bottomAnchor\.constraint\(equalTo:\s*[A-Za-z_]\w*\.topAnchor\)/g,
  ) ?? []
  if (coversAboveBar.length < 2) {
    throw new Error(`${label}: loading and offline covers must both stop above the native bar`)
  }

  const navigationStart = localNavigationMatch.index ?? 0
  const navigationStoredAt = controllerSource.indexOf(`${navigationStorage} = ${localNavigation}`, navigationStart)
  const navigationConstruction = controllerSource.slice(navigationStart, navigationStoredAt + navigationStorage.length + localNavigation.length + 8)
  const localStackMatch = navigationConstruction.match(/let\s+([A-Za-z_]\w*)\s*=\s*UIStackView\(arrangedSubviews:/)
  if (!localStackMatch) throw new Error(`${label}: native navigation content stack is missing`)
  const localStack = localStackMatch[1]
  for (const [pattern, message] of [
    [new RegExp(`let\\s+preferredSafeContentBottom\\s*=\\s*${escapeRegExp(localStack)}\\.bottomAnchor\\.constraint\\(\\s*equalTo:\\s*view\\.safeAreaLayoutGuide\\.bottomAnchor\\s*\\)`), 'content is not aligned to the real safe bottom'],
    [/preferredSafeContentBottom\.priority\s*=\s*\.defaultHigh/, 'safe-content priority is missing'],
    [new RegExp(`let\\s+preferredFloorContentBottom\\s*=\\s*${escapeRegExp(localStack)}\\.bottomAnchor\\.constraint\\(\\s*equalTo:\\s*${escapeRegExp(localNavigation)}\\.bottomAnchor,\\s*constant:\\s*-16\\s*\\)`), '16pt content floor is missing'],
    [/preferredFloorContentBottom\.priority\s*=\s*UILayoutPriority\(rawValue:\s*749\)/, 'content-floor priority is missing'],
    [new RegExp(`${escapeRegExp(localStack)}\\.bottomAnchor\\.constraint\\(lessThanOrEqualTo:\\s*${escapeRegExp(localNavigation)}\\.bottomAnchor,\\s*constant:\\s*-16\\)`), 'required 16pt bottom floor is missing'],
  ]) {
    requirePattern(navigationConstruction, pattern, `${label}: ${message}`)
  }
  for (const pattern of [
    new RegExp(`${escapeRegExp(localNavigation)}\\.backgroundColor\\s*=\\s*\\.white`),
    new RegExp(`${escapeRegExp(localNavigation)}\\.isOpaque\\s*=\\s*true`),
    new RegExp(`${escapeRegExp(localNavigation)}\\.layer\\.shadowOpacity\\s*=\\s*0(?:\\.0)?\\b`),
    new RegExp(`${escapeRegExp(localNavigation)}\\.transform\\s*=\\s*\\.identity`),
  ]) {
    requirePattern(navigationConstruction, pattern, `${label}: native bar is not a static opaque shadow-free surface`)
  }
  if (/UIVisualEffectView|UIView\.animate|\.animate\(/.test(navigationConstruction)) {
    throw new Error(`${label}: native bar construction must not blur or animate`)
  }

  const nativeButtonStart = controllerSource.indexOf('private final class OtlobliNativeNavigationButton: UIControl')
  const nativeButtonEndCandidates = [
    controllerSource.indexOf('required init?(coder: NSCoder)', nativeButtonStart),
    controllerSource.indexOf('open class WKWebViewController', nativeButtonStart),
  ].filter((index) => index > nativeButtonStart)
  const nativeButtonEnd = nativeButtonEndCandidates.length > 0
    ? Math.min(...nativeButtonEndCandidates)
    : -1
  const nativeButtonSource = controllerSource.slice(nativeButtonStart, nativeButtonEnd)
  if (nativeButtonStart < 0 || nativeButtonEnd < 0) {
    throw new Error(`${label}: native navigation button implementation is missing`)
  }
  for (const [pattern, message] of [
    [/textLabel\.font\s*=\s*\.systemFont\(ofSize:\s*12,\s*weight:\s*\.bold\)/, 'labels are not fixed bold 12pt'],
    [/textLabel\.adjustsFontForContentSizeCategory\s*=\s*false/, 'label dynamic type scaling is not disabled'],
    [/content\.centerYAnchor\.constraint\(equalTo:\s*centerYAnchor,\s*constant:\s*5\)/, 'content does not keep the matching +5pt vertical offset'],
  ]) {
    requirePattern(nativeButtonSource, pattern, `${label}: ${message}`)
  }
  if (/UIFontMetrics|scaledFont\(|weight:\s*\.semibold|adjustsFontForContentSizeCategory\s*=\s*true/.test(nativeButtonSource)) {
    throw new Error(`${label}: native navigation labels must remain fixed rather than dynamically scaled`)
  }

  for (const route of ['store-select', 'orders', 'cart', 'profile']) {
    requirePattern(
      controllerSource,
      new RegExp(`navigateHostFromJavaScript\\("${route}"`),
      `${label}: route ${route} is not wired to the host`,
    )
  }
  requirePattern(controllerSource, /UIAccessibility\.isVoiceOverRunning/, `${label}: VoiceOver activation is not supported`)
  requirePattern(
    controllerSource,
    /ProcessInfo\.processInfo\.systemUptime[\s\S]{0,220}?<=\s*0\.32/,
    `${label}: Home does not use a monotonic double activation window of at most 320ms`,
  )
  requirePattern(
    controllerSource,
    /homeButton\.accessibilityHint\s*=\s*"يفتح قائمة المتاجر مباشرة"/,
    `${label}: Home accessibility hint does not describe direct activation`,
  )
  const homeActivationStart = controllerSource.indexOf('@objc private func otlobliHomeNavigationDidActivate()')
  const homeActivationEnd = controllerSource.indexOf('@objc private func otlobliOrdersNavigationDidActivate()', homeActivationStart)
  const homeActivationSource = controllerSource.slice(homeActivationStart, homeActivationEnd)
  if (homeActivationStart < 0 || homeActivationEnd < 0) {
    throw new Error(`${label}: unable to inspect Home activation`)
  }
  requirePattern(
    homeActivationSource,
    /if\s+UIAccessibility\.isVoiceOverRunning\s*\{[\s\S]{0,260}?navigateHostFromJavaScript\("store-select"[\s\S]{0,80}?return/,
    `${label}: VoiceOver activation must open the chooser directly`,
  )
  requirePattern(
    homeActivationSource,
    /guard\s+now\s*-\s*otlobliLastHomeActivationAt\s*<=\s*0\.32\s+else\s*\{[\s\S]{0,180}?showOtlobliStoreSwitchHint\(\)[\s\S]{0,60}?return/,
    `${label}: first tap does not show the chooser hint inside the 320ms path`,
  )
  requirePattern(
    homeActivationSource,
    /guard\s+!otlobliHumanChallengeActive\s+else\s*\{[\s\S]{0,100}?dismissOtlobliStoreSwitchHint\(\)[\s\S]{0,60}?return/,
    `${label}: Home is not inert while human verification owns the surface`,
  )
  for (const pattern of [
    /private\s+func\s+otlobliIsStoreSession\(\)\s*->\s*Bool/,
    /host\s*==\s*"shein\.com"\s*\|\|\s*host\.hasSuffix\("\.shein\.com"\)/,
    /guard\s+otlobliIsStoreSession\(\),[\s\S]{0,140}?!otlobliHumanChallengeActive,[\s\S]{0,180}?view\.window\s*!=\s*nil,[\s\S]{0,100}?let\s+navigationView\s*=\s*otlobliNativeNavigationView\s+else\s*\{\s*return\s*\}/,
    /hint\.accessibilityLabel\s*=\s*message/,
    /label\.text\s*=\s*message/,
    /message:\s*"انقر «الرئيسية» مرتين لفتح قائمة المتاجر"/,
    /message:\s*"انقر مرة ثانية لفتح قائمة المتاجر"/,
    /DispatchQueue\.main\.asyncAfter\(deadline:\s*\.now\(\)\s*\+\s*0\.7,\s*execute:\s*discovery\)/,
  ]) {
    requirePattern(controllerSource, pattern, `${label}: entry/first-tap feedback is missing for one of the stores or unscoped`)
  }
  const capgoInstallStart = controllerSource.indexOf('private func installOtlobliNativeNavigationIfNeeded()')
  const capgoInstallEnd = controllerSource.indexOf('private func otlobliIsTemuSession()', capgoInstallStart)
  const capgoInstallSource = controllerSource.slice(capgoInstallStart, capgoInstallEnd)
  if (capgoInstallStart < 0 || capgoInstallEnd < 0 ||
      capgoInstallSource.includes('scheduleOtlobliStoreSwitchDiscoveryHint()')) {
    throw new Error(`${label}: entry hint must not be consumed while a delayed controller is only being constructed`)
  }
  for (const pattern of [
    /private\s+var\s+otlobliStoreSurfaceExternallyVisible\s*=\s*true/,
    /func\s+otlobliSetStoreSurfaceVisible\(_ visible:\s*Bool\)/,
    /if\s+!visible\s*\{[\s\S]{0,100}?dismissOtlobliStoreSwitchHint\(\)[\s\S]{0,60}?return/,
    /DispatchQueue\.main\.async\s*\{\s*\[weak self\][\s\S]{0,100}?scheduleOtlobliStoreSwitchDiscoveryHint\(\)/,
  ]) {
    requirePattern(
      controllerSource,
      pattern,
      `${label}: retained hidden controller does not cancel/re-arm the one-shot entry hint`,
    )
  }
  requirePattern(
    optionSource,
    /webViewController\.otlobliSetStoreSurfaceVisible\(!hidden\)/,
    `${label}: hidden-state owner does not notify the retained controller visibility boundary`,
  )
  if (controllerSource !== inAppBrowserPatchAdded) {
    const viewDidAppearStart = controllerSource.indexOf('override open func viewDidAppear(_ animated: Bool)')
    const viewDidAppearEnd = controllerSource.indexOf('\n    }', viewDidAppearStart)
    const viewDidAppearSource = controllerSource.slice(viewDidAppearStart, viewDidAppearEnd)
    requirePattern(
      viewDidAppearSource,
      /scheduleOtlobliStoreSwitchDiscoveryHint\(\)/,
      `${label}: entry hint is not scheduled from the real visible-controller boundary`,
    )
    const viewDidDisappearStart = controllerSource.indexOf('override open func viewDidDisappear(_ animated: Bool)')
    const viewDidDisappearEnd = controllerSource.indexOf('override open func viewDidLoad()', viewDidDisappearStart)
    const viewDidDisappearSource = controllerSource.slice(viewDidDisappearStart, viewDidDisappearEnd)
    requirePattern(
      viewDidDisappearSource,
      /dismissOtlobliStoreSwitchHint\(\)/,
      `${label}: leaving the visible controller does not dismiss the entry hint`,
    )
  }
  for (const action of ['Orders', 'Cart', 'Profile']) {
    const actionStart = controllerSource.indexOf(`@objc private func otlobli${action}NavigationDidActivate()`)
    const actionEnd = controllerSource.indexOf('\n    }', actionStart)
    const actionSource = controllerSource.slice(actionStart, actionEnd)
    requirePattern(
      actionSource,
      /guard\s+!otlobliHumanChallengeActive\s+else\s*\{\s*return\s*\}/,
      `${label}: ${action} navigation is not inert during human verification`,
    )
  }
}

const assertAndroidCapgoNativeNavigation = (source, label, { requireInsetSources = true } = {}) => {
  requirePattern(
    source,
    /getBoolean\("otlobliNativeNavigation",\s*false\)/,
    `${label}: scoped native-navigation option is not read`,
  )
  const navigationStorages = [...source.matchAll(/private\s+LinearLayout\s+([A-Za-z_]\w*)\s*;/g)]
    .map((match) => match[1])
  const localNavigationMatch = [...source.matchAll(/LinearLayout\s+([A-Za-z_]\w*)\s*=\s*new\s+LinearLayout\(getContext\(\)\)/g)]
    .find((match) => {
      const local = match[1]
      return new RegExp(`root\\.addView\\(${escapeRegExp(local)}\\s*,`).test(source) &&
        navigationStorages.some((storage) => new RegExp(`${escapeRegExp(storage)}\\s*=\\s*${escapeRegExp(local)}\\s*;`).test(source))
    })
  if (!localNavigationMatch) throw new Error(`${label}: retained sibling native bar is not constructed`)
  const localNavigation = localNavigationMatch[1]
  const navigationStorage = navigationStorages.find(
    (candidate) => new RegExp(`${escapeRegExp(candidate)}\\s*=\\s*${escapeRegExp(localNavigation)}\\s*;`).test(source),
  )
  if (!navigationStorage) throw new Error(`${label}: the constructed bar is not retained by the dialog`)
  requirePattern(
    source,
    new RegExp(`${escapeRegExp(navigationStorage)}\\s*!=\\s*null\\)\\s*return`),
    `${label}: native-bar installation is not idempotent`,
  )
  requirePattern(
    source,
    new RegExp(`root\\.addView\\(${escapeRegExp(localNavigation)}\\s*,`),
    `${label}: native bar is not a sibling in the CoordinatorLayout`,
  )
  requirePattern(source, /findViewById\(R\.id\.content_browser_layout\)/, `${label}: WebView content sibling is missing`)

  const navigationStart = localNavigationMatch.index ?? 0
  const navigationAddedAt = source.indexOf(`root.addView(${localNavigation}`, navigationStart)
  const navigationConstruction = source.slice(navigationStart, navigationAddedAt + 200)
  for (const pattern of [
    new RegExp(`${escapeRegExp(localNavigation)}\\.setBackgroundColor\\(Color\\.WHITE\\)`),
    new RegExp(`${escapeRegExp(localNavigation)}\\.setElevation\\(0f\\)`),
    new RegExp(`${escapeRegExp(localNavigation)}\\.setStateListAnimator\\(null\\)`),
    new RegExp(`${escapeRegExp(localNavigation)}\\.setAlpha\\(1f\\)`),
  ]) {
    requirePattern(navigationConstruction, pattern, `${label}: native bar is not a static opaque shadow-free surface`)
  }
  if (/\.animate\(\)|ObjectAnimator|ViewPropertyAnimator/.test(navigationConstruction)) {
    throw new Error(`${label}: native bar construction must not animate`)
  }

  const iconStart = source.indexOf('class OtlobliNavigationIconView extends View')
  const itemStart = source.indexOf('private FrameLayout createOtlobliNativeNavigationItem(', iconStart)
  const installStart = source.indexOf('private void installOtlobliNativeNavigationIfNeeded()', itemStart)
  const iconSource = source.slice(iconStart, itemStart)
  const itemSource = source.slice(itemStart, installStart)
  if (iconStart < 0 || itemStart < 0 || installStart < 0) {
    throw new Error(`${label}: unable to inspect native icon and item geometry`)
  }
  requirePattern(iconSource, /paint\.setStrokeWidth\(1\.8f\);/, `${label}: icon stroke is not the React-equivalent 1.8 viewBox units`)
  if (/setStrokeWidth\([^;\r\n]*\bscale\b[^;\r\n]*\)/.test(iconSource)) {
    throw new Error(`${label}: icon stroke must not multiply by the already-applied canvas scale`)
  }
  for (const [pattern, message] of [
    [/content\.setPadding\(0,\s*otlobliDp\(10\),\s*0,\s*0\);/, 'content does not keep the matching 10dp top padding'],
    [/text\.setTextSize\(TypedValue\.COMPLEX_UNIT_DIP,\s*12\);/, 'labels are not fixed at 12dp'],
    [/text\.setIncludeFontPadding\(false\);/, 'platform font padding is still enabled'],
  ]) {
    requirePattern(itemSource, pattern, `${label}: ${message}`)
  }
  if (/text\.setTextSize\(TypedValue\.COMPLEX_UNIT_SP,\s*12\)/.test(itemSource)) {
    throw new Error(`${label}: navigation labels must not apply Android font scale a second time`)
  }
  requirePattern(
    source,
    /new\s+LinearLayout\.LayoutParams\(ViewGroup\.LayoutParams\.MATCH_PARENT,\s*otlobliDp\(1\)\)/,
    `${label}: separator is not exactly 1dp`,
  )
  for (const [pattern, message] of [
    [/updateOtlobliNativeNavigationInsets\(\s*int\s+opaqueBottomInset,\s*int\s+gestureSafeBottomInset,/, 'opaque and gesture bottom insets are not passed independently'],
    [/visibleBottomFloor\s*=\s*keyboardVisible\s*\?\s*otlobliDp\(16\)\s*:\s*Math\.max\(otlobliDp\(16\),\s*Math\.max\(0,\s*gestureSafeBottomInset\)\)/, 'visible 16dp floor does not independently absorb only the transparent gesture-safe area'],
    [/systemBottomOffset\s*=\s*keyboardVisible\s*\?\s*0\s*:\s*Math\.max\(0,\s*opaqueBottomInset\)/, 'opaque system inset is not tracked as a separate outside offset'],
    [/"config_navBarInteractionMode"[\s\S]{0,300}?getInteger\(modeResource\)\s*==\s*2/, 'gesture navigation is not classified from Android interaction mode 2'],
    [/opaqueBottomInset\s*=\s*usesGestureNavigation\s*\?\s*0\s*:\s*Math\.max\(bars\.bottom,\s*navigationBars\.bottom\)/, 'opaque navigation-bar inset is not gated away from gesture mode'],
    [/gestureSafeBottomInset\s*=\s*usesGestureNavigation\s*\?\s*gestureBottomInset\s*:\s*0/, 'gesture-safe inset is not gated away from opaque navigation mode'],
    [/navigationHeight\s*=\s*otlobliDp\(74\)\s*\+\s*visibleBottomFloor/, 'surface height is not 74dp plus the visible floor'],
    [/navigation\.setPadding\(0,\s*0,\s*0,\s*visibleBottomFloor\)/, 'only the visible floor must be padded inside the white surface'],
    [/navigationParams\.bottomMargin\s*=\s*systemBottomOffset\s*\+\s*keyboardOffset/, 'opaque system inset is not kept outside the white surface'],
    [/contentParams\.bottomMargin\s*=\s*navigationHeight\s*\+\s*systemBottomOffset\s*\+\s*keyboardOffset/, 'content does not reserve 74dp plus visible floor plus opaque system inset'],
    [/navigationWidth\s*=\s*Math\.min\(otlobliDp\(440\),\s*availableWidth\)/, '440dp maximum width is missing'],
    [/centeredGap\s*=\s*Math\.max\(0,\s*\(availableWidth\s*-\s*navigationWidth\)\s*\/\s*2\)/, 'navigation width is not centered'],
    [/navigationParams\.leftMargin\s*=\s*appliedSafeLeft\s*\+\s*centeredGap/, 'centered left margin is missing'],
    [/navigationParams\.rightMargin\s*=\s*appliedSafeRight\s*\+\s*centeredGap/, 'centered right margin is missing'],
    [/boolean\s+otlobliTemuBlankToolbar\s*=\s*isOtlobliNativeNavigationEnabled\(\)\s*&&\s*otlobliIsTemuSession\(\)\s*&&\s*TextUtils\.equals\(_options\.getToolbarType\(\),\s*"blank"\)/, 'Android 15/16 blank-toolbar inset repair is not scoped to Temu native navigation'],
    [/params\.topMargin\s*=\s*otlobliTemuBlankToolbar\s*\?\s*0\s*:\s*statusBarHeight/, 'Android 15/16 still gives the hidden Temu AppBar a duplicate status inset'],
  ]) {
    requirePattern(source, pattern, `${label}: ${message}`)
  }
  if (/Math\.max\(otlobliDp\(16\),\s*(?:safeBottomInset|opaqueBottomInset)\)/.test(source) ||
      /navigationHeight\s*=\s*otlobliDp\(74\)\s*\+\s*visibleBottomFloor\s*\+\s*systemBottomInset/.test(source) ||
      /navigation\.setPadding\(0,\s*0,\s*0,\s*visibleBottomFloor\s*\+\s*systemBottomInset\)/.test(source)) {
    throw new Error(`${label}: opaque system inset must not swallow or inflate the separate visible 16dp floor`)
  }

  for (const route of ['store-select', 'orders', 'cart', 'profile']) {
    requirePattern(source, new RegExp(`otlobliNavigateHost\\("${route}"\\)`), `${label}: route ${route} is not wired to the host`)
  }
  requirePattern(source, /isTouchExplorationEnabled\(\)/, `${label}: TalkBack activation is not supported`)
  requirePattern(
    source,
    /SystemClock\.uptimeMillis\(\)[\s\S]{0,220}?<=\s*320L/,
    `${label}: Home does not use a monotonic double activation window of at most 320ms`,
  )
  requirePattern(
    source,
    /setContentDescription\([\s\S]{0,160}?label\s*\+\s*"، يفتح قائمة المتاجر مباشرة"/,
    `${label}: Home accessibility description does not describe direct activation`,
  )
  const homeActivationStart = source.indexOf('private void handleOtlobliHomeNavigationActivation()')
  const homeActivationEnd = source.indexOf('private void updateOtlobliNativeNavigationInsets(', homeActivationStart)
  const homeActivationSource = source.slice(homeActivationStart, homeActivationEnd)
  if (homeActivationStart < 0 || homeActivationEnd < 0) {
    throw new Error(`${label}: unable to inspect Home activation`)
  }
  requirePattern(
    homeActivationSource,
    /if\s*\(isOtlobliTouchExplorationEnabled\(\)\)\s*\{[\s\S]{0,260}?otlobliNavigateHost\("store-select"\);[\s\S]{0,80}?return;/,
    `${label}: TalkBack activation must open the chooser directly`,
  )
  requirePattern(
    homeActivationSource,
    /else\s*\{[\s\S]{0,100}?otlobliLastHomeActivationAt\s*=\s*now;[\s\S]{0,100}?showOtlobliStoreSwitchHint\(\);/,
    `${label}: first tap does not show the chooser hint inside the 320ms path`,
  )
  requirePattern(
    homeActivationSource,
    /if\s*\(otlobliHumanChallengeNavigationLocked\)\s*\{[\s\S]{0,100}?dismissOtlobliStoreSwitchHint\(\);[\s\S]{0,60}?return;/,
    `${label}: Home is not inert while human verification owns the surface`,
  )
  for (const pattern of [
    /private\s+boolean\s+otlobliIsStoreSession\(\)\s*\{[\s\S]{0,120}?otlobliIsTemuSession\(\)[\s\S]{0,60}?otlobliIsSheinSession\(\)/,
    /private\s+void\s+presentOtlobliStoreSwitchHint\(String message,\s*int duration\)\s*\{[\s\S]{0,180}?!otlobliIsStoreSession\(\)[\s\S]{0,120}?!otlobliStoreSurfaceVisible\(\)[\s\S]{0,120}?otlobliHumanChallengeNavigationLocked\)\s*return;/,
    /presentOtlobliStoreSwitchHint\("انقر «الرئيسية» مرتين لفتح قائمة المتاجر",\s*Toast\.LENGTH_LONG\)/,
    /presentOtlobliStoreSwitchHint\("انقر مرة ثانية لفتح قائمة المتاجر",\s*Toast\.LENGTH_SHORT\)/,
    /mainHandler\.postDelayed\(otlobliStoreSwitchDiscovery,\s*700L\)/,
  ]) {
    requirePattern(source, pattern, `${label}: entry/first-tap feedback is missing for one of the stores or unscoped`)
  }
  const androidInstallStart = source.indexOf('private void installOtlobliNativeNavigationIfNeeded()')
  const androidInstallEnd = source.indexOf('private void dismissOtlobliStoreSwitchHint()', androidInstallStart)
  const androidInstallSource = source.slice(androidInstallStart, androidInstallEnd)
  if (androidInstallStart < 0 || androidInstallEnd < 0 ||
      androidInstallSource.includes('scheduleOtlobliStoreSwitchDiscoveryHint()')) {
    throw new Error(`${label}: entry hint must not be consumed before the dialog is actually shown`)
  }
  const androidShowStart = source.indexOf('public void show()')
  const androidShowEnd = source.indexOf('public void setInstanceId(', androidShowStart)
  const androidShowSource = source.slice(androidShowStart, androidShowEnd)
  requirePattern(
    androidShowSource,
    /scheduleOtlobliStoreSwitchDiscoveryHint\(\);/,
    `${label}: entry hint is not scheduled from the shown-dialog boundary`,
  )
  const androidNavigateStart = source.indexOf('private void otlobliNavigateHost(String target)')
  const androidNavigateEnd = source.indexOf('private void otlobliDispatchNavigateToHost(', androidNavigateStart)
  const androidNavigateSource = source.slice(androidNavigateStart, androidNavigateEnd)
  requirePattern(
    androidNavigateSource,
    /if\s*\(otlobliHumanChallengeNavigationLocked\)\s*\{[\s\S]{0,120}?return;/,
    `${label}: host navigation is not inert during human verification`,
  )
  if (source !== inAppBrowserPatchAdded) {
    const androidHiddenStart = source.indexOf('public void setHidden(boolean hidden)')
    const androidHiddenEnd = source.indexOf('public boolean isHiddenModeActive()', androidHiddenStart)
    const androidHiddenSource = source.slice(androidHiddenStart, androidHiddenEnd)
    requirePattern(
      androidHiddenSource,
      /if\s*\(hidden\)\s*\{\s*dismissOtlobliStoreSwitchHint\(\);/,
      `${label}: hiding the dialog does not cancel the entry hint`,
    )
    const androidDismissStart = source.indexOf('public void dismiss()')
    const androidDismissEnd = source.indexOf('\n    }', androidDismissStart)
    const androidDismissSource = source.slice(androidDismissStart, androidDismissEnd)
    requirePattern(
      androidDismissSource,
      /dismissOtlobliStoreSwitchHint\(\);/,
      `${label}: dismissing the dialog does not cancel the entry hint`,
    )
  }

  const insetPatterns = [
    /navigationHeight\s*=\s*[A-Za-z_]\w*\(74\)\s*\+\s*visibleBottomFloor/,
    /contentParams\.bottomMargin\s*=\s*navigationHeight\s*\+\s*systemBottomOffset\s*\+\s*keyboardOffset/,
  ]
  if (requireInsetSources) insetPatterns.push(
    /WindowInsetsCompat\.Type\.navigationBars\(\)/,
    /WindowInsetsCompat\.Type\.systemGestures\(\)/,
    /WindowInsetsCompat\.Type\.mandatorySystemGestures\(\)/,
    /WindowInsetsCompat\.Type\.ime\(\)/,
  )
  for (const pattern of insetPatterns) {
    requirePattern(source, pattern, `${label}: 74dp content reserve is not bound to safe/gesture/IME insets`)
  }
  const contentOwnedCovers = source.match(
    /isOtlobliNativeNavigationEnabled\(\)\s*\?\s*findViewById\(R\.id\.content_browser_layout\)/g,
  ) ?? []
  if (contentOwnedCovers.length < 2) {
    throw new Error(`${label}: loading and offline covers must stay inside content above the native bar`)
  }
}

for (const legacyNavigation of [
  'otlobliLoadingNavigation',
  'otlobliHandleLoadingNavigationTap',
  'makeLoadingNavigation',
]) {
  if (inAppBrowserPatchAdded.includes(legacyNavigation)) {
    throw new Error(`Capgo patch adds duplicate loading navigation: ${legacyNavigation}`)
  }
  if (inAppBrowserPatch.includes(legacyNavigation) && !inAppBrowserPatchRemoved.includes(legacyNavigation)) {
    throw new Error(`Capgo patch retains duplicate loading navigation outside removed lines: ${legacyNavigation}`)
  }
  if (appliedCapgoIosController.includes(legacyNavigation) || appliedCapgoAndroid.includes(legacyNavigation)) {
    throw new Error(`Applied Capgo sources retain duplicate loading navigation: ${legacyNavigation}`)
  }
}

assertIosCapgoNativeNavigation(appliedCapgoIosPlugin, appliedCapgoIosController, 'applied iOS Capgo')
assertAndroidCapgoNativeNavigation(appliedCapgoAndroid, 'applied Android Capgo')
assertDedicatedIosNativeNavigationParity(iosSheinBrowser, 'dedicated iOS store surface')
assertIosCapgoNativeNavigation(inAppBrowserPatchAdded, inAppBrowserPatchAdded, 'iOS Capgo patch')
assertAndroidCapgoNativeNavigation(inAppBrowserPatchAdded, 'Android Capgo patch', { requireInsetSources: false })

if (/^\s*params\.topMargin\s*=\s*statusBarHeight\s*;/m.test(appliedCapgoAndroid)) {
  throw new Error('Applied Android Capgo restored the unconditional Android 15/16 AppBar status inset')
}
if (!inAppBrowserPatchRemoved.includes('params.topMargin = statusBarHeight;')) {
  throw new Error('Capgo patch does not remove the upstream duplicate Android 15/16 AppBar status inset')
}

const temuBackUrlObserverStart = appliedCapgoIosController.indexOf('case "URL":')
const temuBackUrlObserverEnd = appliedCapgoIosController.indexOf('default:', temuBackUrlObserverStart)
const temuBackUrlObserver = appliedCapgoIosController.slice(temuBackUrlObserverStart, temuBackUrlObserverEnd)
if (temuBackUrlObserverStart < 0 || temuBackUrlObserverEnd < 0 ||
    !temuBackUrlObserver.includes('guard let webView = self.webView else { return }') ||
    !temuBackUrlObserver.includes('republishOtlobliNativeBackState(in: webView)')) {
  throw new Error('Temu iOS Back must re-publish from the WKWebView URL observer for SPA product/Home transitions')
}

if (app.includes('temuAddInFlightRef')) {
  throw new Error('Temu capture must not use a process-wide latch that can block later products')
}

for (const marker of [
  'window.__otlobliAddSafetyTimer = setTimeout',
  "if (detail && detail.type === 'addToCartNack')",
  'clearAddSafetyTimer();',
]) {
  if (!captureScript.includes(marker)) throw new Error(`Capture fail-safe guard missing marker: ${marker}`)
}

if (!extensionBuilder.includes("detail: { type: 'addToCartNack' }")) {
  throw new Error('Temu extension must surface a rejected cart acknowledgement')
}

for (const marker of [
  'window.__otlobliNativeNavigation=true;',
  'window.__otlobliDocumentGeneration=window.__otlobliDocumentGeneration||',
]) {
  if (!extensionBuilder.includes(marker)) {
    throw new Error(`Temu Gecko builder missing native ownership marker: ${marker}`)
  }
}
const geckoFullOwnerStart = geckoContent.indexOf('if (fullCaptureOwnsDocument()) {')
const geckoFullOwnerEnd = geckoContent.indexOf('\n    }', geckoFullOwnerStart)
const geckoFullOwnerBranch = geckoContent.slice(geckoFullOwnerStart, geckoFullOwnerEnd)
if (geckoFullOwnerStart < 0 || geckoFullOwnerEnd < 0 ||
    !geckoFullOwnerBranch.includes('suspendForChallenge()') ||
    !geckoFullOwnerBranch.includes('observer?.disconnect()')) {
  throw new Error('Temu Gecko lightweight guard must restore its styles before the full runtime takes ownership')
}
for (const marker of [
  'const OWNED_STYLE =',
  'const rememberStyle =',
  'const restoreStyle =',
  'const fullCaptureOwnsDocument =',
  'const challengeVisible =',
  '(?:captcha|challenge|verification|bgn[_-]?verification|security_token|risk|robot|anti[-_]?bot|human)=',
  'const publicPageReady =',
  'const postPublicReady =',
  'const postPublicReadyIfStable =',
  'const suspendForChallenge =',
  "postChallengeState('humanCheck')",
  "postChallengeState('humanCheckResolved')",
  'now - challengeMissingSince < 1200',
  'challengeSettledUntil = now + 600',
  'const challengePollMs = 300',
  'setTimeout(schedule, challengePollMs)',
  'publicReadyPostedKey = key',
  'postPublicReadyIfStable(now)',
  'observer?.disconnect()',
  'if (fullCaptureOwnsDocument()) return',
  'setTimeout(periodic, document.hidden ? 5000 : (lowEndDevice ? 2600 : 1800))',
]) {
  if (!geckoContent.includes(marker)) {
    throw new Error(`Temu Gecko challenge/performance guard missing marker: ${marker}`)
  }
}
for (const forbidden of [
  "style.overflow = ''",
  'setInterval(schedule, 1200)',
  "document.querySelectorAll('div,section')",
]) {
  if (geckoContent.includes(forbidden)) {
    throw new Error(`Temu Gecko challenge/performance regression detected: ${forbidden}`)
  }
}
for (const marker of [
  'window.__otlobliNativeNavigation=!0',
  'window.__otlobliDocumentGeneration=',
  'challenge-hidden',
]) {
  if (!geckoCapture.includes(marker)) {
    throw new Error(`Generated Temu Gecko capture is stale or incomplete: ${marker}`)
  }
}
if (geckoManifest.version !== '1.3.22') {
  throw new Error('Temu Gecko extension version must change when its installed runtime changes')
}

if (/storeLayer\.setElevation\s*\(/.test(plugin)) {
  throw new Error('Store surface must not cast an elevation shadow over the React navigation')
}

if (/storeLayer\.animate\(\)\.alpha\(/.test(plugin)) {
  throw new Error('Temu store surface must reveal atomically without a white navigation flash')
}

if (/FLAG_DIM_BEHIND|dimAmount|setDimAmount/.test(plugin)) {
  throw new Error('Embedded Temu surface must not dim MainActivity')
}

const hideStart = plugin.indexOf('private void hideStoreLayer()')
const hideEnd = plugin.indexOf('private void ensureSessionAndOpen(', hideStart)
if (hideStart < 0 || hideEnd < 0) {
  throw new Error('Unable to inspect the store-surface hide lifecycle')
}
const hideBody = plugin.slice(hideStart, hideEnd)
for (const forbidden of ['session.close(', 'releaseSession(', 'setSession(null)']) {
  if (hideBody.includes(forbidden)) {
    throw new Error(`Hiding Temu must preserve its Gecko session: ${forbidden}`)
  }
}

const pauseStart = plugin.indexOf('protected void handleOnPause()')
const resumeStart = plugin.indexOf('protected void handleOnResume()', pauseStart)
const destroyStart = plugin.indexOf('protected void handleOnDestroy()', resumeStart)
if (pauseStart < 0 || resumeStart < 0 || destroyStart < 0) {
  throw new Error('Unable to inspect the Temu app background/resume lifecycle')
}
const pauseBody = plugin.slice(pauseStart, resumeStart)
const resumeBody = plugin.slice(resumeStart, destroyStart)
if (!pauseBody.includes('session.setActive(false);') || !resumeBody.includes('session.setActive(true);')) {
  throw new Error('Temu must become inactive in background and reactivate only when its surface is visible')
}

for (const marker of [
  'memoryGb <= 4',
  "document.documentElement.dataset.otlobliPerformance = 'low'",
  "lowEndStyle.id = 'otlobli-low-end-style'",
  'content-visibility:auto',
]) {
  if (!appEntry.includes(marker)) throw new Error(`Low-end Android runtime profile is missing: ${marker}`)
}

for (const marker of ['findLargestVisibleSurface', 'PixelCopy.request(storeSurface', 'captureWindow(']) {
  if (!reporter.includes(marker)) {
    throw new Error(`Store screenshot guard missing reporter marker: ${marker}`)
  }
}

console.log('Store surface geometry, opacity, dim and screenshot guard: OK')
