import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { runInNewContext } from 'node:vm'
import ts from 'typescript'
import {
  evaluateInjectedScriptExports,
  minifyInjectedScriptExports,
} from './minify-injected-scripts.mjs'
import { stripInjectedComments } from './strip-injected-comments.mjs'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const sheinRuntimeSourceFiles = [
  'src/services/sheinBrowserScript.ts',
  'src/services/sheinNavigationScript.ts',
  'src/services/sheinSessionScript.ts',
  'src/services/storeProductCaptureScript.ts',
  'src/services/storeBlockingScript.ts',
  'src/services/temuBrowserScript.ts',
  'src/services/storeRuntimeCoordinator.ts',
  'src/services/storeScriptDiagnostics.ts',
]
const readSheinRuntimeSource = () => sheinRuntimeSourceFiles
  .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
  .join('\n')

const checks = [
  {
    label: 'dedicated app-owned iOS SHEIN browser',
    file: 'ios/App/App/OtlobliSheinBrowserPlugin.swift',
    markers: [
      'public final class OtlobliSheinBrowserPlugin',
      'One WKWebView owns one complete SHEIN browsing session.',
      'configuration.websiteDataStore = .default()',
      'UIApplication.didReceiveMemoryWarningNotification',
      'private func createRenderSurface(',
      'private func destroyRenderSurface()',
      'private func parkRenderSurfaceBehindApp()',
      'private func navigateInCurrentWebView(to url: URL)',
      'window.location.assign(',
      'private func applicationDidReceiveMemoryWarning()',
      'storeWebView?.stopLoading()',
      'storeWebView?.removeFromSuperview()',
      'attachWebView(webView, to: surface)',
      'webViewWebContentProcessDidTerminate',
      'WKWebsiteDataTypeDiskCache',
      'WKWebsiteDataTypeMemoryCache',
      'removeScriptMessageHandler',
      'browserId = "otlobli-shein-',
      'isAllowedStoreURL(url)',
      'category: "SheinRootCause"',
      'event?.type == .touches',
      'logWebDiagnostic(_ detail:',
      'requestPersistentStateSnapshot(_ stage:',
      'CAPPluginMethod(name: "recordDiagnostic"',
      'webView.isInspectable = diagnosticsEnabled',
    ],
    forbidden: [
      'UIApplication.willEnterForegroundNotification',
      'UIApplication.didEnterBackgroundNotification',
      'UIApplication.didBecomeActiveNotification',
      'foregroundRecomposePending',
      'recomposeAttachedWebViewAfterForeground',
      "PageTransitionEvent('pageshow'",
      'webView.removeFromSuperview()',
      'WKProcessPool()',
      'CADisplayLink',
      'needsForegroundRebind',
      'needsRenderSurfaceRebuild',
      'snapshotView(',
      'operatingSystemVersion.majorVersion',
      'WKWebsiteDataTypeCookies',
      'WKWebsiteDataTypeLocalStorage',
      'webView.reload()',
      'for delay in [0.12, 0.5, 1.2, 2.2]',
      'replaceVisibleRenderSurface',
      'queueRouteReplacement',
      'routeReplacementQueued',
      'restoreAfterBackground',
      'navigationAction.navigationType == .linkActivated',
    ],
  },
  {
    label: 'dedicated iOS SHEIN browser registration',
    files: [
      'ios/App/App/OtlobliBridgeViewController.swift',
      'ios/App/App/Base.lproj/Main.storyboard',
      'ios/App/App.xcodeproj/project.pbxproj',
    ],
    markers: [
      'bridge?.registerPluginInstance(OtlobliSheinBrowserPlugin())',
      'customClass="OtlobliBridgeViewController"',
      'OtlobliBridgeViewController.swift in Sources',
      'OtlobliSheinBrowserPlugin.swift in Sources',
    ],
  },
  {
    label: 'SHEIN platform browser boundary',
    file: 'src/services/storeBrowser.ts',
    markers: [
      "registerPlugin<NativeSheinBrowserApi>('OtlobliSheinBrowser')",
      "Capacitor.getPlatform() === 'ios'",
      'isSheinUrl(options.url)',
      "activeBackend = 'native-shein'",
      'CapgoInAppBrowser.openWebView(options)',
      'NativeSheinBrowser.clearCache()',
      'preserving cookies/localStorage in WKWebsiteDataStore.default()',
    ],
  },
  {
    label: 'app routes store operations through platform browser boundary',
    file: 'src/App.tsx',
    markers: [
      "import { StoreBrowser as InAppBrowser } from './services/storeBrowser'",
    ],
    forbidden: [
      "import { BackgroundColor, InAppBrowser, InvisibilityMode, ToolBarType } from '@capgo/capacitor-inappbrowser'",
    ],
  },
  {
    label: 'persistent patch',
    file: 'patches/@capgo+capacitor-inappbrowser+8.6.25.patch',
    markers: [
      'func otlobliForceRecompose()',
      'otlobliFreezeDiagnosticsEnabled',
      'otlobliFreezeDiagnosticsBypassRecovery',
      'otlobliLifecycleGeneration',
      'app-did-become-active-recompose-skipped',
      'app-did-become-active-recompose-cancelled-not-active',
      'js-recompose-request-skipped',
      'copyOtlobliFreezeDiagnosticReport',
      'webView.removeFromSuperview()',
      'self.view.addSubview(webView)',
      'webView.scrollView.setContentOffset(offset, animated: false)',
      '@objc func appDidBecomeActive(_ notification: NSNotification)',
      'DispatchQueue.main.asyncAfter(deadline: .now() + 0.25)',
      'controller.otlobliForceRecompose()',
      'UIApplication.shared.applicationState == .active',
      'otlobliFreezeDiagnosticsEnabled',
      'app-did-become-active-recompose-skipped',
      'messageBody["__otlobliRecompose"] as? Bool == true',
      'public void otlobliOnHostResume()',
      'public void navigate(String target)',
      "new CustomEvent('otlobli:nativeNavigate'",
      'func navigateHostFromJavaScript(_ target: String',
      'window.webkit.messageHandlers.navigate.postMessage',
    ],
    forbidden: [
      'appWillEnterForeground',
      'willEnterForegroundNotification',
      'otlobliRecomposeAllWebViews',
      'for delay in [0.12, 0.5, 1.2, 2.2]',
      'otlobliForceRecompose(force:',
    ],
  },
  {
    label: 'applied iOS lifecycle patch',
    file: 'node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/InAppBrowserPlugin.swift',
    markers: [
      '@objc func appDidBecomeActive(_ notification: NSNotification)',
      'DispatchQueue.main.asyncAfter(deadline: .now() + 0.25)',
      'controller.otlobliForceRecompose()',
      'otlobliLifecycleGeneration',
      'app-did-become-active-recompose-cancelled-not-active',
      'UIApplication.shared.applicationState == .active',
      'func navigateHostFromJavaScript(_ target: String',
      "new CustomEvent('otlobli:nativeNavigate'",
    ],
    forbidden: [
      'appWillEnterForeground',
      'willEnterForegroundNotification',
      'otlobliRecomposeAllWebViews',
      'for delay in [0.12, 0.5, 1.2, 2.2]',
      'otlobliForceRecompose(force:',
    ],
  },
  {
    label: 'applied iOS WKWebView patch',
    file: 'node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/WKWebViewController.swift',
    markers: [
      'func otlobliForceRecompose()',
      'otlobliFreezeDiagnosticsEnabled',
      'js-recompose-request-skipped',
      'copyOtlobliFreezeDiagnosticReport',
      'webView.removeFromSuperview()',
      'self.view.addSubview(webView)',
      'webView.scrollView.setContentOffset(offset, animated: false)',
      'messageBody["__otlobliRecompose"] as? Bool == true',
      'message.name == "navigate"',
      'window.webkit.messageHandlers.navigate.postMessage',
    ],
    forbidden: ['otlobliForceRecompose(force:'],
  },
  {
    label: 'applied Android host-resume patch',
    file: 'node_modules/@capgo/capacitor-inappbrowser/android/src/main/java/ee/forgr/capacitor_inappbrowser/WebViewDialog.java',
    markers: [
      'public void otlobliOnHostResume()',
      'webView.onResume()',
      'webView.invalidate()',
      'webView.requestLayout()',
      'public void navigate(String target)',
      "new CustomEvent('otlobli:nativeNavigate'",
    ],
  },
  {
    label: 'store-region rebuild guard',
    file: 'src/App.tsx',
    markers: [
      'const previousStoreRegionsRef = useRef(storeRegions)',
      'if (JSON.stringify(previous[activeStore]) === JSON.stringify(storeRegions[activeStore])) return',
      "window.addEventListener('otlobli:nativeNavigate'",
      'flushSync(() => setScreen(target))',
      'useTopInset: !isIosNative',
      'if (loadedWebviewId && !webviewIdRef.current && webviewOpeningRef.current && !webviewClosingRef.current)',
      "stage: 'host-page-loaded-id-adopted'",
      "detail?.type === 'sheinRegionDiagnostic'",
      '__OTLOBLI_SHEIN_REGION_DIAGNOSTICS__',
      "import('./services/storeCaptureBundle')",
      'storeCaptureBundleLoadingRef',
    ],
  },
  {
    label: 'lazy store-only capture bundle',
    file: 'src/services/storeCaptureBundle.ts',
    markers: [
      "from './sheinBrowserScript'",
      "from './sheinFreezeDiagnostics'",
      "from './sheinPersistentStateDiagnostics'",
      "from './sheinPrivacyCompatScript'",
      "from './sheinRegionDiagnostics'",
      "from './sheinTapDiagnostics'",
      'export const buildStoreCaptureScript',
    ],
  },
  {
    label: 'always-on SHEIN privacy touch-shield compatibility',
    file: 'src/services/sheinPrivacyCompatScript.ts',
    markers: [
      'SHEIN_PRIVACY_COMPAT_SCRIPT',
      '[class*="shein_privacy_agreement"]',
      "type: 'sheinPrivacyResolved'",
      "method: method",
      "'reject-all'",
      "window.__otlobliNativePlatform || ''",
      "style.position !== 'fixed'",
      "rect.width < viewport.width * 0.85",
      "data-otlobli-privacy-neutralized",
      'scheduledDelays = [0, 60, 160, 360, 700, 1200, 2000, 3500, 6000, 10000]',
    ],
    forbidden: [
      'MutationObserver',
      'setInterval(',
      'localStorage.',
      'sessionStorage.',
      'document.cookie',
    ],
  },
  {
    label: 'store-script responsibility boundaries',
    file: 'src/services/sheinBrowserScript.ts',
    markers: [
      "from './sheinNavigationScript'",
      "from './sheinSessionScript'",
      "from './storeProductCaptureScript'",
      "from './storeBlockingScript'",
      "from './temuBrowserScript'",
      "from './storeRuntimeCoordinator'",
      '${SHEIN_SESSION_SCRIPT}',
      '${STORE_PRODUCT_CAPTURE_SCRIPT}',
      '${STORE_BLOCKING_SCRIPT}',
      '${TEMU_BROWSER_SCRIPT}',
      '${STORE_RUNTIME_COORDINATOR_SCRIPT}',
    ],
    forbidden: [
      'function tick()',
      'function ensureAddToCartButton()',
      'function hideSheinNativeProductAdd()',
      'Storage.prototype',
    ],
  },
  {
    label: 'SHEIN site-owned persistent session',
    file: 'src/services/sheinSessionScript.ts',
    markers: [
      'SHEIN owns its cookies, localStorage and sessionStorage.',
      'preserving',
      'signed address',
      "sheinRegionDiag('foreign-address-preserved-for-native-repair'",
    ],
    forbidden: [
      'Storage.prototype.setItem',
      'document.cookie =',
      "localStorage.setItem('currency'",
      "localStorage.setItem('country'",
      "localStorage.setItem('localcountry'",
      "sessionStorage.setItem('currency'",
      "sessionStorage.setItem('country'",
      "sessionStorage.setItem('localcountry'",
      "localStorage.getItem('currency')",
      "sessionStorage.getItem('currency')",
      "removeItem('addressCookie')",
      '__otlobliRegionBootstrapReload:',
      'product-bootstrap-reload',
    ],
  },
  {
    label: 'minimal SHEIN entry URL contract',
    file: 'src/App.tsx',
    markers: [
      'const applySheinRegionQuery = (url: URL, region: StoreRegion)',
      "url.searchParams.set('currency', region.currency)",
      "url.searchParams.set('localcountry', region.countryCode)",
      "url.searchParams.set('lang', region.language)",
    ],
    forbidden: [
      "url.searchParams.set('countryCode'",
      "url.searchParams.set('country_code'",
      "url.searchParams.set('language'",
      "url.searchParams.set('ship_to'",
      "url.searchParams.set('shipTo'",
      "url.searchParams.set('shipToCountry'",
      "url.searchParams.set('shippingCountry'",
      "url.searchParams.set('shipping_country'",
      "url.searchParams.set('store_country'",
    ],
  },
  {
    label: 'native WebView session persistence',
    file: 'src/App.tsx',
    markers: [
      'verified WebContent process; persistent cookies alone are insufficient.',
      'InAppBrowser.hide()',
    ],
    forbidden: [
      'InAppBrowser.clearAllCookies(',
      'InAppBrowser.clearCookies(',
    ],
  },
  {
    label: 'same-store chooser reentry preserves native session',
    file: 'src/App.tsx',
    markers: [
      'const pendingStoreOpenAfterCloseRef = useRef(false)',
      "pendingStoreOpenAfterCloseRef.current = screenRef.current === 'home'",
      "recordAppDiagnostic('store_session_parked_for_chooser', { store: 'shein' })",
      'if (sheinOpenedRef.current) void InAppBrowser.hide()',
      'Returning to the chooser is app navigation, not the end of the',
      'A real store switch still closes',
      'pendingStoreOpenAfterCloseRef.current = false',
    ],
  },
  {
    label: 'diagnostic script isolation panel',
    file: 'src/services/storeScriptDiagnostics.ts',
    markers: [
      'STORE_SCRIPT_DIAGNOSTICS_PANEL_SCRIPT',
      "['runtime', 'كل تدخلات Otlobli'",
      "['navigation', 'الشريط والتنقّل'",
      "['blocking', 'الحجب والتنظيف'",
      "['capture', 'الجذب والإضافة'",
      "['session', 'الجلسة والمنطقة'",
      "post({ type: 'storeScriptFlagsChanged', flags: flags, label: label })",
      "post({ type: 'closeStore' })",
      "status.setAttribute('aria-live', 'polite')",
      '@media(prefers-reduced-motion:reduce)',
      'overscroll-behavior:contain',
    ],
    forbidden: [
      'document.cookie',
      'localStorage.setItem',
      'MutationObserver',
      'setInterval(',
      'transition:all',
    ],
  },
  {
    label: 'diagnostic toggles remain test-build only',
    file: 'src/config.ts',
    markers: [
      'export const STORE_SCRIPT_DIAGNOSTICS =',
      'VITE_STORE_SCRIPT_DIAGNOSTICS',
      'v86.193-passive-native-foreground',
      'v86.195-ios-live-web-inspector-diagnostic',
      'VITE_SHEIN_IOS_ROOT_CAUSE_DIAGNOSTICS',
    ],
  },
  {
    label: 'iOS default persistent website data store',
    file: 'node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/InAppBrowserPlugin.swift',
    markers: [
      'return [WKWebsiteDataStore.default()]',
    ],
  },
  {
    label: 'diagnostic iPhone trace mode',
    file: 'src/App.tsx',
    markers: [
      'SHEIN_IOS_FREEZE_DIAGNOSTICS',
      'SHEIN_IOS_FREEZE_DIAGNOSTICS_BYPASS_RECOVERY',
      "const iosRootCauseDiagnostics = SHEIN_IOS_FREEZE_DIAGNOSTICS && isIosNative && activeStore === 'shein'",
      'otlobliFreezeDiagnostics: iosRootCauseDiagnostics',
      'otlobliFreezeDiagnosticsBypassRecovery:',
      'otlobliLoadingCover: true',
      'SHEIN_FREEZE_DIAGNOSTIC_SCRIPT',
      'SHEIN_PERSISTENT_STATE_DIAGNOSTIC_SCRIPT',
      'SHEIN_TAP_DIAGNOSTIC_SCRIPT',
      "recordIosSheinRootCauseDiagnostic('foreground-decision'",
    ],
  },
  {
    label: 'normal-release diagnostics default disabled',
    file: 'src/config.ts',
    markers: [
      'export const SHEIN_IOS_FREEZE_DIAGNOSTICS =',
      'VITE_SHEIN_IOS_ROOT_CAUSE_DIAGNOSTICS',
      "toLowerCase() === 'true'",
    ],
    forbidden: ['export const SHEIN_IOS_FREEZE_DIAGNOSTICS = true'],
  },
  {
    label: 'tap diagnostics isolated to dedicated iOS build',
    file: 'src/App.tsx',
    markers: [
      'otlobliTapDiagnostics: iosRootCauseDiagnostics',
    ],
  },
  {
    label: 'stable iPhone first-frame navigation inset',
    files: sheinRuntimeSourceFiles,
    markers: [
      'var(--otlobli-sb,16px)',
      'window.__otlobliSafeBottom',
      "root.style.setProperty('--otlobli-sb'",
    ],
  },
  {
    label: 'iOS SHEIN ready-reveal gate',
    file: 'src/App.tsx',
    markers: [
      'InvisibilityMode.FAKE_VISIBLE',
      'hidden: true',
      'if (webviewOpeningRef.current || !sheinReadyRef.current) return undefined',
    ],
  },
  {
    label: 'price diagnostic excluded from normal releases',
    file: 'src/App.tsx',
    markers: [],
    forbidden: [
      "./services/sheinPriceDiagnostics",
      'SHEIN_PRICE_DIAGNOSTICS_SCRIPT',
    ],
  },
  {
    label: 'diagnostic SHEIN event probe',
    file: 'src/services/sheinFreezeDiagnostics.ts',
    markers: [
      "type:'otlobliFreezeDiagnostic'",
      "['visibilitychange','pageshow','pagehide','freeze','resume','focus','blur']",
      'window.__otlobliFreezeProbe',
      "'script-chunk'",
      'sourceHash',
    ],
  },
  {
    label: 'passive non-sensitive persistent-state probe',
    file: 'src/services/sheinPersistentStateDiagnostics.ts',
    markers: [
      'SHEIN_PERSISTENT_STATE_DIAGNOSTIC_SCRIPT',
      "d.type='otlobliPersistentStateDiagnostic'",
      'cookieKeysHash',
      'cookieStateHash',
      'localKeysHash',
      'localStateHash',
      'sessionKeysHash',
      'sessionStateHash',
      'caches.keys()',
      'navigator.serviceWorker.getRegistrations()',
      'indexedDB.databases()',
      "addEventListener('touchstart'",
      'e.isTrusted',
    ],
    forbidden: [
      'setInterval(',
      'MutationObserver',
      'removeItem(',
      'clear()',
      'location.reload(',
      'location.assign(',
      'document.cookie=',
      'localStorage.setItem(',
      'sessionStorage.setItem(',
    ],
  },
  {
    label: 'SHEIN quick-add cart-link guard',
    files: sheinRuntimeSourceFiles,
    markers: [
      'function sheinQuickAddProductLink(root,info)',
      "var suffix='-p-'+id+'.html'",
      "'/ar/product-p-'+id+'.html'",
    ],
    forbidden: ["location.origin + '/ar/-p-' + info.goods_id + '.html'"],
  },
  {
    label: 'iPhone resumed product-tap fallback',
    files: sheinRuntimeSourceFiles,
    markers: [
      'const OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS',
      "f('product-tap-start'+(o?'-target':''))",
      "f('product-tap-fallback')",
      "f('product-tap-route-fallback')",
      "g(o?'armed':'ignored-no-product-target'",
      "'data-goods-id','data-goods_id','data-product-id','data-product_id','data-id','fsp-key'",
      "'/product-p-'+d+'.html'",
      "'override-non-product-route'",
      "window.__otlobliProductTapAttemptAt=Date.now()",
      'location.assign(n[5])',
    ],
    forbidden: [
      'n[0].click()',
    ],
  },
  {
    label: 'SHEIN live human-verification compatibility guard',
    file: 'src/services/sheinHumanCheck.ts',
    markers: [
      'function otlobliMatchesHumanChallengeText(value)',
      '[class*="risk-one-pass" i]',
      '.sui-dialog__wrapper',
      'var semanticStart = Math.max(0, semanticChecks.length - 12);',
      'if (!sheinElementIsPainted(surface)) continue;',
      'otlobliMatchesHumanChallengeText(surface.textContent || \'\')',
      "type: 'humanCheck'",
    ],
    forbidden: [
      '.click()',
      'location.reload(',
    ],
  },
  {
    label: 'SHEIN confirmed chunk-failure recovery',
    files: sheinRuntimeSourceFiles,
    markers: [
      'const OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS',
      "type:'sheinChunkLoadFailure'",
      'ChunkLoadError|Loading chunk',
      'product=/-p-\\\\d+/i.test(location.pathname)',
      'window.__otlobliSheinChunkFailureAt=Date.now()',
      'window.__otlobliRecoverSheinChunkOnStalledTap=function(url)',
    ],
    forbidden: [
      "Bridge(){if(!/shein/i.test(location.hostname)||!/-p-",
    ],
  },
  {
    label: 'SHEIN review section is not a photo viewer',
    files: sheinRuntimeSourceFiles,
    markers: [
      'function sheinViewerHasVisibleCounter(el, vp)',
      '!sheinViewerHasVisibleCounter(el, vp)',
      '/review|rating|comment|feedback|',
    ],
  },
  {
    label: 'iPhone 6 SHEIN cart-toast entry guard',
    files: sheinRuntimeSourceFiles,
    markers: [
      "var __otlobliCartToastProductKey = '';",
      'var productMatch = location.pathname.match(/-p-(\\\\d+)/i);',
      'if (productKey !== __otlobliCartToastProductKey)',
      '__otlobliCartToastGuardUntil = Date.now() + 15000;',
      "current.setAttribute('data-otlobli-hidden-cart-toast', '1')",
    ],
  },
  {
    label: 'SHEIN chunk recovery host path',
    file: 'src/App.tsx',
    markers: [
      'const recoverSheinChunkLoad = (reportedUrl: string)',
      "Capacitor.getPlatform() !== 'ios'",
      "detail?.type === 'sheinChunkLoadFailure'",
      'now - sheinChunkRecoveryAtRef.current < 60_000',
      'sheinCacheResetPendingRef.current = true',
      'const sheinRecoveryProductUrl = (region: StoreRegion, ...candidates: string[])',
      "const resumeBackTarget: 'home' | 'cart'",
      'pendingBackTargetRef.current = resumeBackTarget',
    ],
  },
  {
    label: 'SHEIN runtime-cache ownership',
    files: sheinRuntimeSourceFiles,
    markers: [],
    forbidden: [
      'cleanSheinRuntimeCache',
      'otlobli_shein_runtime_cleaned',
      'navigator.serviceWorker.getRegistrations',
      'caches.delete(keys[k])',
    ],
  },
  {
    label: 'SHEIN weak-device background-work guard',
    files: sheinRuntimeSourceFiles,
    markers: [
      'function restoreOtlobliNavOnWake()',
      "window.addEventListener('pageshow', restoreOtlobliNavOnWake, false)",
      'if (!document.hidden) restoreOtlobliNavOnWake()',
      'if (document.hidden) return;',
    ],
    forbidden: [
      'bootstrapLowEnd ? 2500 : 1500',
    ],
  },
  {
    label: 'SHEIN home visual readiness accepts non-semantic product cards',
    files: sheinRuntimeSourceFiles,
    markers: [
      'if (homeLike) return loadedImageCount >= 2 && (interactiveCount >= 1 || bodyText.length >= 500);',
    ],
  },
  {
    label: 'SHEIN document-start native product-add concealment',
    files: sheinRuntimeSourceFiles,
    markers: [
      "style.id = 'otlobli-native-add-style'",
      '[class*="add-to-bag" i]',
      '[class*="add-cart" i]',
      '[aria-label*="أضف إلى عربة" i]',
    ],
  },
  {
    label: 'supported VPN does not become a false network gate',
    file: 'src/App.tsx',
    markers: [
      'const previouslyReachable = storeReachableRef.current',
      'const trustedStoreAccess = !isBlockedStoreCountry',
      "reason === 'network' && trustedStoreAccess ? 'preparation' : reason",
      'storeReachableRef.current = true',
      "storeOpenFailureReason === 'network' ? <button",
      'if (!recoverSheinChunkLoad(failingUrl)) showStoreOpenFailure()',
    ],
  },
  {
    label: 'iPhone 6 back button body stacking layer',
    files: sheinRuntimeSourceFiles,
    markers: [
      'function otlobliStabilizeBackOverlay(el)',
      'document.body || document.documentElement',
      'host.lastElementChild !== el',
      'otlobliNavIsActuallyCovered(el)',
      "el.style.setProperty('animation', 'none', 'important')",
      "el.style.setProperty('z-index', '2147483647', 'important')",
      'otlobliStabilizeBackOverlay(btn)',
      '|| looksLikeProductPage() || temuSearchBack',
      "type: 'otlobliBackButtonState'",
      'window.__otlobliNativeBackState !== nativeState',
      'if (shouldShow) otlobliStabilizeBackOverlay(btn)',
      // v86.123: the back button must never absorb a tap and do nothing. A bare
      // history.back() is a silent no-op once the store's back stack is spent,
      // which stranded iPhone 6 customers inside a product after a few hops.
      'function otlobliBackOrLeave()',
      'if (location.href === f) location.assign(location.origin + h)',
      'otlobliBackOrLeave();',
    ],
    forbidden: [
      'function otlobliStabilizeTemuRootOverlay(el)',
      // The raw call, unguarded, is what dead-ended the button. Keep the
      // verified wrapper.
      '        } else if (!looksLikeHomeRoot() || looksLikeProductPage()) {\n          history.back();',
    ],
  },
  {
    label: 'iPhone native back button remains above SHEIN compositor layers',
    file: 'patches/@capgo+capacitor-inappbrowser+8.6.25.patch',
    markers: [
      'private var otlobliNativeBackButton: UIButton?',
      'button.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: top)',
      'self.view.bringSubviewToFront(button)',
      'otlobliNativeBackButtonDidTap',
      "document.getElementById('otlobli-back-btn');if(b)b.click()",
      'detail["type"] as? String == "otlobliBackButtonState"',
      'otlobliNativeBackButton?.isHidden = true',
    ],
  },
  {
    label: 'legacy SHEIN cart-link repair',
    file: 'src/App.tsx',
    markers: [
      'const bareQuickAddProduct = path.match(/^\\/-p-(\\d+)\\.html$/i)',
      'path = `/product-p-${bareQuickAddProduct[1]}.html`',
    ],
  },
  {
    label: 'iOS SHEIN cart-product persistent verified session',
    file: 'src/App.tsx',
    markers: [
      'const navigateStoreWebviewInPage = (url: string)',
      'window.location.assign(',
      'beginPendingProductPreparation(targetUrl)',
      'const navigate = navigateStoreWebviewInPage(targetUrl)',
    ],
    forbidden: [
      'openIosSheinCartProductInFreshSession',
      'recoverSheinCartProductSession',
      'sheinCartProductRecoveryInFlightRef',
    ],
  },
  {
    label: 'SHEIN scroll/navigation interaction guard',
    files: sheinRuntimeSourceFiles,
    markers: [
      'function sheinRestoreNavAfterShipping()',
      'function sheinLooksLikeProductRouteForShipping()',
      'function sheinRegionTransitionVeil(show)',
      'function sheinPrimeRegionRepairFromRoute()',
      'function sheinRegionDiag(stage, data, key)',
      "sheinRegionDiag('capture-script-injected'",
      "sheinRegionDiag('shipping-entry-control'",
      "sheinRegionDiag('region-veil-state'",
      "if (otlobliScriptEnabled('session') && IS_SHEIN) sheinPrimeRegionRepairFromRoute();",
      "nav.style.setProperty('pointer-events', 'auto', 'important')",
      "nav.removeAttribute('data-otlobli-nav-yield')",
      "if (nav.querySelector('#otlobli-nav-region-guard'))",
      'function otlobliInteractionActive()',
      'if (IS_SHEIN && otlobliInteractionActive() &&',
      '!sheinShippingBodyLockState && !sheinShippingUiLikelyOpen()',
      'scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 320 : 160)',
      'sheinShippingUiLikelyOpen() && sheinResolvedShippingUiRoot()',
      "typeof window.mobileApp.navigate === 'function'",
      'window.mobileApp.navigate(nativeTarget)',
      'var stableNavHost = document.documentElement || document.body',
      'stableNavHost.appendChild(nav)',
      'function completeSelectedCompoundSize(container, selected)',
      'completeSelectedCompoundSize(container, getSelectedWithin(container))',
      // v86.38: the summary may be outside the drawer container; accept its
      // second segment only when a selected option inside that container confirms it.
      "var combinedTitles = document.querySelectorAll('.goods-size__title",
      'var combinedUnconfirmed = false',
      "headingKey !== 'لون/مقاس'",
      'h < 3 && scope && scope !== document.body',
      'row.indexOf(heading) === 0 && row.length < 60',
      "var selectedNodes = container.querySelectorAll('*')",
      'value === rest || (value.length < 60 && value.indexOf(rest) === 0)',
      "return first + ' / ' + rest",
      "if (combinedUnconfirmed) return ''",
      // v86.30: offers.lowPrice is the CHEAPEST variant and must never be a
      // price source. JSON stays a fallback, but only via offers.price.
      'var ldPrice = offers && parseFloat(offers.price)',
      // v86.30: PDP price roots must stay scoped away from recommendation rails.
      'OTLOBLI_PRICE_RAIL_HINT',
      'function sheinInRecommendationRail(el)',
      'function sheinPdpPriceScope()',
      'if (sheinInRecommendationRail(roots[j])) continue',
      // v86.30: the captured price must carry the branch that produced it.
      'priceSource: sheinPriceSource',
      // v86.31: bare Arabic option labels + never ship a range ("from") price.
      'var OTLOBLI_COLOR_LABELS',
      'var OTLOBLI_SIZE_LABELS',
      'function sheinHeadPriceIsRange()',
      "__otlobliSkuPriceSource = 'range-blocked'",
      // v86.33: SHEIN's current price markup. Device diagnostics returned
      // "roots: 0" for the old selectors, so these must not regress.
      'var OTLOBLI_PRICE_SEL',
      'var OTLOBLI_MAIN_PRICE_SEL',
      'productPriceContainer',
      '[class*="from-tag" i]',
      // v86.34: the collapsed placeholder must not block the add while the
      // options drawer covers it, and the picked sku must survive its close.
      'function sheinCovered(el)',
      '&& sheinElementIsVisible(el) && !sheinCovered(el)',
      'function sheinSkuMemo(key, value)',
      // v86.43: a range price means no variant is committed - never add then.
      'if (sheinHeadPriceIsRange()) {',
      "showMessage(document.getElementById('otlobli-add-btn'), 'حدد الخيارات أولاً')",
      "sheinSkuMemo('s', selected)",
      // v86.35: a visible nav must stay first-tap responsive while SHEIN's
      // product-options backdrop is open, without stealing a truly covered row.
      'const OTLOBLI_NAV_TOUCH_BRIDGE_JS',
      'function otlobliInstallNavTouchBridge()',
      "window.addEventListener('touchend', routeOtlobliNavTouch",
      "tab.setAttribute('data-otlobli-nav-type', item.type)",
      'if (!otlobliNavIsActuallyCovered(nav)) return false;',
      "var metaPrice = parseFloat(getMeta('product:price:amount'))",
      "document.querySelector('.product-price .price-content, .product-intro__head-price, [class*=\"price\" i]')",
      'return !!p.title && !!p.image && p.priceUsd > 0 && (!cs.exists || !!p.color)',
      'function sheinTrackSelectedSkuPrice(event)',
      "__otlobliSkuPriceSource = 'selected-mutation'",
      "document.addEventListener('click', sheinTrackSelectedSkuPrice, true)",
      "sheinRegionDiag('selected-sku-price-capture'",
      'setTimeout(commit, 1500)',
      'var __otlobliInitialCapturePath = location.pathname',
      'function sheinSpaRoutePrice()',
      "__otlobliSkuPriceSource = 'spa-dom'",
      '__otlobliSelectedSkuPriceBefore = getPrice()',
      'function sheinSelectedSkuPricePending()',
      'priceWaits++ < 16',
      'function sheinCountryRowsInRoot(root)',
      "sheinRegionDiag('country-row-fallback'",
      "sheinRegionDiag('country-list-scroll'",
      'node.clientHeight < best.clientHeight',
    ],
    forbidden: [
      'function sheinQuantitySizeSummary()',
      '__otlobliQuantitySizeSummaryCache',
      'function sheinLiveSkuPrice()',
      'stableSheinPriceReads >= 2',
      "sheinRegionDiag('price-capture'",
    ],
  },
  {
    label: 'bounded SHEIN region diagnostics',
    file: 'src/services/sheinRegionDiagnostics.ts',
    markers: [
      "type: 'sheinRegionDiagnostic'",
      "window.__otlobliRegionDiagnostic('capture-evaluation-start'",
      'pending.length < 32',
      'attempts >= 20',
      'clearInterval(flushTimer)',
    ],
  },
  {
    // v86.124 low-end speedups. Each removes work without weakening a single
    // check, and each was reached by a slower path before. Do not drop these
    // to "simplify" the hot loops - and never buy speed back by lengthening an
    // interval instead, which is what produced the rejected v86.118/v86.121.
    label: 'low-end hot-path work removal',
    files: sheinRuntimeSourceFiles,
    markers: [
      // One timer owns the recurring lanes; a full-document observer no longer
      // turns every store repaint into another Otlobli scan.
      'function scheduleOtlobliCoordinator()',
      'var OTLOBLI_BLOCK_INTERVAL = OTLOBLI_LOW_END ? 650 : 120;',
      'function runOtlobliBlockers()',
      // Skip geometry on already-hidden nodes: a rect read after a style write
      // forces one synchronous layout per iteration (layout thrashing).
      "if (el.style.visibility === 'hidden') continue;",
      "if (!el || el.style && el.style.display === 'none') return;",
      'hideListingCardAddButtons();\n    hideSheinNativeProductAdd();',
    ],
    forbidden: [
      'OTLOBLI_VERY_LOW_END',
      'observer.observe(root, { childList: true, subtree: true })',
    ],
  },
  {
    label: 'single recurring store coordinator',
    file: 'src/services/storeRuntimeCoordinator.ts',
    markers: [
      'function runOtlobliCoordinator()',
      'function runOtlobliNavigationMaintenance()',
      'checkForSheinSecurityBlock();',
      'runOtlobliCoordinator();',
    ],
    forbidden: [
      'setInterval(',
      'new MutationObserver(scheduleTick)',
    ],
  },
]

const failures = []

// Parse the fully composed source exactly as the WebView receives it. The
// evaluator follows the pure local module graph, so splitting responsibilities
// across files cannot make the guard silently validate an empty import stub.
try {
  const scriptModule = {
    exports: evaluateInjectedScriptExports('src/services/sheinBrowserScript.ts'),
  }
  const navigationModule = evaluateInjectedScriptExports('src/services/sheinNavigationScript.ts')
  const captureScript = scriptModule.exports.SHEIN_CAPTURE_SCRIPT
  const bootstrapScript = scriptModule.exports.OTLOBLI_NAV_BOOTSTRAP_SCRIPT
  scriptModule.exports.__tapFallback = navigationModule.OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS
  scriptModule.exports.__chunkBridge = navigationModule.OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS

  const humanSource = stripInjectedComments(
    readFileSync(resolve(projectRoot, 'src/services/sheinHumanCheck.ts'), 'utf8'),
  )
  const humanOutput = ts.transpileModule(humanSource, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText
  const humanModule = { exports: {} }
  new Function('exports', 'require', 'module', humanOutput)(humanModule.exports, () => ({}), humanModule)
  const humanCheckScript = humanModule.exports.OTLOBLI_SHEIN_HUMAN_CHECK_JS
  new Function(humanCheckScript)
  const humanSurface = ({ text = '', id = '', className = '', painted = true } = {}) => ({
    id, className, textContent: text, __painted: painted,
    getAttribute: () => '',
  })
  const runHumanCheck = ({ exact = [], semantic = [], title = '' } = {}) => runInNewContext(
    `${humanCheckScript}\notlobliIsHumanChallenge();`,
    {
      location: { href: 'https://m.shein.com/ar/product-p-520531743.html' },
      document: {
        title,
        body: { textContent: 'ordinary product page' },
        getElementById: () => null,
        querySelector: () => null,
        querySelectorAll: (selector) => selector.includes('risk-one-pass') ? exact : semantic,
      },
      sessionStorage: { getItem: () => null, removeItem: () => undefined, setItem: () => undefined },
      otlobliIsHumanChallengeUrl: () => false,
      sheinElementIsPainted: (surface) => surface.__painted !== false,
      Date, Math, String,
    },
  )
  if (!runHumanCheck({
    exact: [humanSurface({
      className: 'risk-one-pass-content',
      text: 'يرجى النقر لإكمال الإجراءات التالية للتحقق من أنك إنسان أنا إنسان',
    })],
  })) failures.push('SHEIN human check: live risk-one-pass dialog is no longer detected')
  if (!runHumanCheck({
    semantic: [humanSurface({
      className: 'sui-dialog__wrapper future-dialog-name',
      text: 'Please confirm that you are a human to continue',
    })],
  })) failures.push('SHEIN human check: renamed semantic verification dialog is no longer detected')
  if (runHumanCheck({
    semantic: [humanSurface({
      className: 'sui-dialog__wrapper',
      text: 'خصم إضافي سجّل الدخول للاستفادة من العرض',
    })],
  })) failures.push('SHEIN human check: ordinary promotion dialog was mistaken for verification')
  if (runHumanCheck({
    exact: [humanSurface({
      className: 'risk-one-pass-content',
      text: 'أنا إنسان',
      painted: false,
    })],
  })) failures.push('SHEIN human check: hidden stale verification template was treated as active')
  if (humanCheckScript.includes('.click(') || humanCheckScript.includes('location.reload(')) {
    failures.push('SHEIN human check: verification must remain entirely user-controlled')
  }
  const nativeAddStyleAt = bootstrapScript.indexOf("style.id = 'otlobli-native-add-style'")
  const nativeAddProductGuardAt = bootstrapScript.indexOf("if (!/-p-\\d+/i.test(location.pathname)) return;", nativeAddStyleAt)
  if (nativeAddStyleAt < 0 || nativeAddProductGuardAt < nativeAddStyleAt) {
    failures.push('SHEIN native product-add concealment: CSS must mount before a later SPA product route')
  }
  if (typeof captureScript !== 'string' || !captureScript.trim()) {
    failures.push('SHEIN capture-script syntax: emitted script is missing')
  } else {
    new Function(captureScript)
    const backLayerStart = captureScript.indexOf('function otlobliStabilizeBackOverlay')
    const backLayerEnd = captureScript.indexOf('function ensureOtlobliNav', backLayerStart)
    const backLayerHelper = captureScript.slice(backLayerStart, backLayerEnd)
    const backDisplayAt = captureScript.indexOf("btn.style.display = shouldShow ? 'flex' : 'none'")
    const nativeBackStateAt = captureScript.indexOf("type: 'otlobliBackButtonState'")
    const visibleBackReclaimAt = captureScript.indexOf('if (shouldShow) otlobliStabilizeBackOverlay(btn)', nativeBackStateAt)
    if (backDisplayAt < 0 || nativeBackStateAt < backDisplayAt || visibleBackReclaimAt < nativeBackStateAt) {
      failures.push('iPhone 6 back layer: visible/native state must be resolved before the final paint reclaim')
    }
    const backLayerStyles = {}
    const backLayerChildren = []
    const backLayerBody = {
      lastElementChild: null,
      appendChild: (node) => {
        const previous = backLayerChildren.indexOf(node)
        if (previous >= 0) backLayerChildren.splice(previous, 1)
        backLayerChildren.push(node)
        node.parentNode = backLayerBody
        backLayerBody.lastElementChild = node
      },
    }
    const backLayerButton = {
      parentNode: {},
      getBoundingClientRect: () => ({ left: 320, top: 58, width: 42, height: 42 }),
      contains: () => false,
      style: { setProperty: (name, value, priority) => { backLayerStyles[name] = `${value}:${priority}` } },
    }
    let backLayerHit = backLayerButton
    const backLayerDocument = {
      body: backLayerBody,
      documentElement: {},
      elementFromPoint: () => backLayerHit,
    }
    runInNewContext(`${backLayerHelper}\notlobliStabilizeBackOverlay(button)`, {
      document: backLayerDocument, window: { innerHeight: 667 }, button: backLayerButton,
      otlobliNavIsActuallyCovered: () => backLayerHit !== backLayerButton,
    })
    const stickyPrice = { id: 'shein-sticky-price' }
    backLayerBody.appendChild(stickyPrice)
    backLayerHit = stickyPrice
    runInNewContext(`${backLayerHelper}\notlobliStabilizeBackOverlay(button)`, {
      document: backLayerDocument, window: { innerHeight: 667 }, button: backLayerButton,
      otlobliNavIsActuallyCovered: () => backLayerHit !== backLayerButton,
    })
    if (backLayerButton.parentNode !== backLayerBody ||
        backLayerBody.lastElementChild !== backLayerButton ||
        backLayerStyles['z-index'] !== '2147483647:important' ||
        backLayerStyles.animation !== 'none:important' ||
        backLayerStyles['pointer-events'] !== 'auto:important') {
      failures.push('iPhone 6 back layer: button does not reclaim the last body paint layer')
    }
    const viewerStart = captureScript.indexOf('function sheinViewerHasLargeMedia')
    const viewerEnd = captureScript.indexOf('function sheinImageViewerRoot', viewerStart)
    const viewerHelpers = captureScript.slice(viewerStart, viewerEnd)
    const viewerCandidate = (text, counter) => ({
      id: '', innerText: text,
      matches: () => false,
      querySelector: () => null,
      getBoundingClientRect: () => ({ width: 400, height: 780, top: 0, bottom: 780 }),
      querySelectorAll: (selector) => selector.startsWith('img')
        ? [{ getBoundingClientRect: () => ({ width: 300, height: 400 }) }]
        : [{ textContent: counter, getBoundingClientRect: () => ({ width: 34, height: 18, top: 20, bottom: 38 }) }],
    })
    const detectsViewer = (text, counter) => runInNewContext(
      `${viewerHelpers}\nisSheinImageViewerCandidate(candidate, vp)`,
      {
        candidate: viewerCandidate(text, counter), vp: { width: 400, height: 800 },
        window: { getComputedStyle: () => ({ display: 'block', visibility: 'visible', opacity: '1', position: 'fixed' }) },
        parseFloat, parseInt, String,
      },
    )
    if (detectsViewer('التقييمات 4.9/5', '4.9/5')) failures.push('SHEIN viewer guard: rating was mistaken for an image counter')
    if (detectsViewer('التعليقات 1/7', '1/7')) failures.push('SHEIN viewer guard: review section was mistaken for a photo viewer')
    if (!detectsViewer('1/7', '1/7')) failures.push('SHEIN viewer guard: real image counter no longer detects the photo viewer')

    const toastStart = captureScript.indexOf('var __otlobliCartToastGuardUntil = 0;')
    const toastEnd = captureScript.indexOf('var sheinBlockReported', toastStart)
    const toastHelpers = captureScript.slice(toastStart, toastEnd)
    const runCartToastGuard = (pathname) => {
      const hidden = {}
      const body = {}, documentElement = {}
      const toast = {
        id: '', textContent: 'أضف إلى عربة التسوق بنجاح', parentElement: body,
        style: { setProperty: (name, value) => { hidden[name] = value } },
        setAttribute: (name, value) => { hidden[name] = value },
        getBoundingClientRect: () => ({ width: 340, height: 52, top: 595, bottom: 647 }),
      }
      runInNewContext(`${toastHelpers}\nhideSheinCartSuccessToast();`, {
        IS_SHEIN: true, location: { pathname }, Date: { now: () => 1_000 },
        viewportSize: () => ({ width: 375, height: 667 }),
        document: {
          body, documentElement,
          querySelector: () => null,
          querySelectorAll: () => [toast],
          elementsFromPoint: () => [toast],
        },
      })
      return hidden
    }
    const productToast = runCartToastGuard('/ar/item-p-123.html')
    if (productToast.display !== 'none' || productToast['data-otlobli-hidden-cart-toast'] !== '1') {
      failures.push('SHEIN cart toast: product entry did not hide the restored black success bar')
    }
    if (runCartToastGuard('/ar/').display === 'none') {
      failures.push('SHEIN cart toast: non-product entry armed the success-bar guard')
    }
  }

  const chunkCase = (pathname, attemptedTap) => {
    const listeners = {}
    const messages = []
    const now = 100_000
    const window = {
      mobileApp: { postMessage: (message) => messages.push(message) },
      __otlobliProductTapAttemptAt: attemptedTap ? now : 0,
      __otlobliProductTapAttemptUrl: attemptedTap ? 'https://m.shein.com/ar/item-p-77.html' : '',
    }
    runInNewContext(scriptModule.exports.__chunkBridge, {
      window,
      location: { hostname: 'm.shein.com', pathname, href: `https://m.shein.com${pathname}` },
      Date: { now: () => now },
      addEventListener: (name, listener) => { listeners[name] = listener },
    })
    listeners.error({ message: 'ChunkLoadError: Loading chunk 42 failed' })
    return { messages, window }
  }

  let chunk = chunkCase('/ar/', false)
  if (chunk.messages.length !== 0) failures.push('SHEIN chunk bridge: listing error caused eager recovery')
  if (!chunk.window.__otlobliRecoverSheinChunkOnStalledTap('https://m.shein.com/ar/item-p-88.html') ||
      chunk.messages.length !== 1) failures.push('SHEIN chunk bridge: stalled tap did not recover a recorded listing chunk')
  chunk = chunkCase('/ar/', true)
  if (chunk.messages.length !== 1 || !String(chunk.messages[0]?.detail?.url).includes('-p-77')) {
    failures.push('SHEIN chunk bridge: chunk after a stalled product tap did not preserve the product URL')
  }
  chunk = chunkCase('/ar/item-p-99.html', false)
  if (chunk.messages.length !== 1) failures.push('SHEIN chunk bridge: confirmed product-route recovery regressed')

  const handlers = {}, timers = [], assigned = []
  let recoveryCalls = 0
  let anchorClicks = 0
  const anchor = {
    tagName: 'A', parentElement: null, isConnected: true,
    href: 'https://m.shein.com/ar/item-p-123.html',
    getAttribute: (name) => name === 'href' ? '/ar/item-p-123.html' : '',
    click: () => { anchorClicks++ }, querySelector: () => null, querySelectorAll: () => [],
  }
  const location = {
    origin: 'https://m.shein.com', pathname: '/ar/', href: 'https://m.shein.com/ar/',
    assign: (url) => assigned.push(url),
  }
  runInNewContext(scriptModule.exports.__tapFallback, {
    window: { __otlobliRecoverSheinChunkOnStalledTap: () => { recoveryCalls++; return true } }, location,
    navigator: { userAgent: 'iPhone', platform: 'iPhone', maxTouchPoints: 5 },
    document: { addEventListener: (name, listener) => { handlers[name] = listener } },
    clearTimeout: () => undefined,
    setTimeout: (callback) => { timers.push(callback); return timers.length },
    Date, Math,
  })
  const touch = { target: { tagName: 'IMG', parentElement: anchor }, changedTouches: [{ clientX: 20, clientY: 30 }] }
  handlers.touchstart(touch)
  handlers.touchend(touch)
  while (timers.length) timers.shift()()
  if (assigned[0] !== anchor.href) failures.push('SHEIN product tap fallback: direct product anchor was not assigned')
  if (anchorClicks !== 0) failures.push('SHEIN product tap fallback: direct product anchor was replay-clicked before assignment')
  if (recoveryCalls !== 0) failures.push('SHEIN product tap fallback: direct product anchor caused an unnecessary recovery')

  let collectionClicks = 0
  const collectionCard = {
    tagName: 'LI', className: 'sd-ccc-products__item', parentElement: null, isConnected: true,
    classList: { contains: () => false },
    getAttribute: (name) => name === 'role' ? 'link' : '',
    click: () => { collectionClicks++ }, querySelector: () => null, querySelectorAll: () => [],
  }
  const collectionTouch = {
    target: { tagName: 'IMG', parentElement: collectionCard },
    changedTouches: [{ clientX: 22, clientY: 34 }],
  }
  const assignedBeforeCollection = assigned.length
  handlers.touchstart(collectionTouch)
  handlers.touchend(collectionTouch)
  while (timers.length) timers.shift()()
  if (collectionClicks !== 0 || assigned.length !== assignedBeforeCollection || recoveryCalls !== 0) {
    failures.push('SHEIN product tap fallback: collection/list card without a direct PDP href was changed')
  }

  const searchAnchor = {
    tagName: 'A', parentElement: null, isConnected: true,
    href: 'https://m.shein.com/ar/BATMAN-X-SHEIN-Keychain-p-49330027.html',
    getAttribute: (name) => name === 'href' ? '/ar/BATMAN-X-SHEIN-Keychain-p-49330027.html' : '',
    querySelector: () => null, querySelectorAll: () => [],
  }
  const searchCard = {
    tagName: 'DIV', className: 'bs-product-card multi-product-card', parentElement: null,
    getAttribute: (name) => name === 'role' ? 'listitem' : '',
    querySelector: (selector) => selector === 'a[href*="-p-"]' ? searchAnchor : null,
    querySelectorAll: (selector) => selector === 'a[href*="-p-"]' ? [searchAnchor] : [],
  }
  searchAnchor.parentElement = searchCard
  const searchImageWrapper = {
    tagName: 'DIV', className: 'bs-product-card__ratio-image__thumb', parentElement: searchCard,
    getAttribute: () => '', querySelector: () => null, querySelectorAll: () => [],
  }
  const searchImage = {
    tagName: 'IMG', className: 'bs-product-card-transform-img', parentElement: searchImageWrapper,
    getAttribute: () => '', querySelector: () => null, querySelectorAll: () => [],
  }
  const searchTouch = { target: searchImage, changedTouches: [{ clientX: 25, clientY: 35 }] }
  location.href = 'https://m.shein.com/ar/pdsearch/batman/'
  location.pathname = '/ar/pdsearch/batman/'
  const assignedBeforeSearch = assigned.length
  handlers.touchstart(searchTouch)
  handlers.touchend(searchTouch)
  while (timers.length) timers.shift()()
  if (assigned[assignedBeforeSearch] !== searchAnchor.href) {
    failures.push('SHEIN product tap fallback: image tap inside a live bs-product-card did not use its sibling PDP link')
  }

  const renamedAnchor = {
    tagName: 'A', parentElement: null, isConnected: true,
    href: 'https://m.shein.com/ar/future-card-p-520531743.html',
    getAttribute: (name) => name === 'href' ? '/ar/future-card-p-520531743.html' : '',
    querySelector: () => null, querySelectorAll: () => [],
  }
  const renamedCard = {
    tagName: 'DIV', className: 'sui-feed-unit-v9', parentElement: null,
    getAttribute: () => '',
    querySelector: () => renamedAnchor,
    querySelectorAll: () => [renamedAnchor],
  }
  renamedAnchor.parentElement = renamedCard
  const renamedImage = {
    tagName: 'IMG', className: 'future-image', parentElement: renamedCard,
    getAttribute: () => '', querySelector: () => null, querySelectorAll: () => [],
  }
  const assignedBeforeRenamedCard = assigned.length
  const renamedTouch = { target: renamedImage, changedTouches: [{ clientX: 26, clientY: 36 }] }
  handlers.touchstart(renamedTouch)
  handlers.touchend(renamedTouch)
  while (timers.length) timers.shift()()
  if (assigned[assignedBeforeRenamedCard] !== renamedAnchor.href) {
    failures.push('SHEIN product tap fallback: renamed single-product card was tied to a CSS class name')
  }

  const otherAnchor = {
    tagName: 'A', parentElement: null, isConnected: true,
    href: 'https://m.shein.com/ar/other-p-520531744.html',
    getAttribute: (name) => name === 'href' ? '/ar/other-p-520531744.html' : '',
    querySelector: () => null, querySelectorAll: () => [],
  }
  const multiProductList = {
    tagName: 'SECTION', className: 'future-feed', parentElement: null,
    getAttribute: () => '', querySelector: () => renamedAnchor,
    querySelectorAll: () => [renamedAnchor, otherAnchor],
  }
  const ambiguousImage = {
    tagName: 'IMG', parentElement: multiProductList,
    getAttribute: () => '', querySelector: () => null, querySelectorAll: () => [],
  }
  const assignedBeforeAmbiguousList = assigned.length
  const ambiguousTouch = { target: ambiguousImage, changedTouches: [{ clientX: 27, clientY: 37 }] }
  handlers.touchstart(ambiguousTouch)
  handlers.touchend(ambiguousTouch)
  while (timers.length) timers.shift()()
  if (assigned.length !== assignedBeforeAmbiguousList) {
    failures.push('SHEIN product tap fallback: ambiguous multi-product list guessed the wrong PDP')
  }

  const flashCard = {
    tagName: 'DIV', className: 'flash-sale__product-item flash-sale__product-waterfall-item', parentElement: null,
    getAttribute: (name) => name === 'role' ? 'listitem' : (name === 'data-id' ? '87475338' : ''),
    querySelector: () => null, querySelectorAll: () => [],
  }
  const flashImage = {
    tagName: 'IMG', className: 'product-item__main-img', parentElement: flashCard,
    getAttribute: () => '', querySelector: () => null, querySelectorAll: () => [],
  }
  const flashTouch = { target: flashImage, changedTouches: [{ clientX: 28, clientY: 38 }] }
  location.href = 'https://m.shein.com/ar/flash-sale.html'
  location.pathname = '/ar/flash-sale.html'
  const assignedBeforeFlash = assigned.length
  handlers.touchstart(flashTouch)
  handlers.touchend(flashTouch)
  while (timers.length) timers.shift()()
  if (assigned[assignedBeforeFlash] !== 'https://m.shein.com/ar/product-p-87475338.html') {
    failures.push('SHEIN product tap fallback: data-id-only flash-sale product did not receive a valid PDP route')
  }

  location.href = 'https://m.shein.com/ar/'
  location.pathname = '/ar/'
  const assignedBeforeNaturalRoute = assigned.length
  handlers.touchstart(touch)
  handlers.touchend(touch)
  location.href = anchor.href
  while (timers.length) timers.shift()()
  if (assigned.length !== assignedBeforeNaturalRoute) {
    failures.push('SHEIN product tap fallback: natural product navigation was assigned a second time')
  }

  location.href = 'https://m.shein.com/ar/pdsearch/wrong-brand/'
  const assignedBeforeWrongRoute = assigned.length
  handlers.touchstart(touch)
  handlers.touchend(touch)
  location.href = 'https://m.shein.com/ar/Brands/BATMAN-sc-123.html'
  while (timers.length) timers.shift()()
  if (assigned[assignedBeforeWrongRoute] !== anchor.href) {
    failures.push('SHEIN product tap fallback: a wrong non-product SPA route suppressed the direct PDP fallback')
  }
} catch (error) {
  failures.push(`SHEIN capture-script syntax: ${error instanceof Error ? error.message : String(error)}`)
}

// Parse the exact minified scripts that production packages. This keeps the
// release hardening inside the established iPhone freeze acceptance gate.
try {
  const { exports } = await minifyInjectedScriptExports('src/services/sheinBrowserScript.ts')
  new Function(exports.SHEIN_CAPTURE_SCRIPT)
  new Function(exports.OTLOBLI_NAV_BOOTSTRAP_SCRIPT)
} catch (error) {
  failures.push(`SHEIN minified release scripts: ${error instanceof Error ? error.message : String(error)}`)
}

try {
  const diagnosticsModule = evaluateInjectedScriptExports('src/services/storeScriptDiagnostics.ts')
  new Function(diagnosticsModule.STORE_SCRIPT_DIAGNOSTICS_PANEL_SCRIPT)
  const persistentDiagnostics = evaluateInjectedScriptExports('src/services/sheinPersistentStateDiagnostics.ts')
  const tapDiagnostics = evaluateInjectedScriptExports('src/services/sheinTapDiagnostics.ts')
  new Function(persistentDiagnostics.SHEIN_PERSISTENT_STATE_DIAGNOSTIC_SCRIPT)
  new Function(tapDiagnostics.SHEIN_TAP_DIAGNOSTIC_SCRIPT)
  const bundleModule = evaluateInjectedScriptExports('src/services/storeCaptureBundle.ts')
  const rawFlags = { runtime: false, navigation: false, blocking: false, capture: false, session: false }
  const rawScript = bundleModule.buildStoreCaptureScript({}, rawFlags, true)
  const fullDiagnosticScript = bundleModule.buildStoreCaptureScript({}, {
    runtime: true, navigation: true, blocking: true, capture: true, session: true,
  }, true)
  const productionScript = bundleModule.buildStoreCaptureScript({}, undefined, false)
  const rootCauseScript = bundleModule.buildStoreCaptureScript({}, undefined, false, true)
  new Function(rawScript)
  new Function(fullDiagnosticScript)
  new Function(rootCauseScript)
  if (!rawScript.includes('otlobli-script-diagnostics') ||
      !rawScript.includes('__otlobliSheinPrivacyCompatInstalled') ||
      !rawScript.includes('[class*="shein_privacy_agreement"]') ||
      rawScript.includes('function tick()') ||
      rawScript.includes('setInterval(') || rawScript.includes('__otlobliRegionDiagnostic')) {
    failures.push('SHEIN script isolation: raw-store preset must keep privacy compatibility and exclude the normal coordinator')
  }
  if (!fullDiagnosticScript.includes('otlobli-script-diagnostics') || !fullDiagnosticScript.includes('function tick()')) {
    failures.push('SHEIN script isolation: full diagnostic preset must contain both panel and normal coordinator')
  }
  if (productionScript.includes('otlobli-script-diagnostics')) {
    failures.push('SHEIN script isolation: normal customer injection must not include the diagnostic panel')
  }
  if (!productionScript.includes('__otlobliSheinPrivacyCompatInstalled')) {
    failures.push('SHEIN privacy compatibility: normal customer injection must include the touch-shield fix')
  }
  if (productionScript.includes('capture-context-ready') || !rootCauseScript.includes('capture-context-ready')) {
    failures.push('SHEIN root-cause diagnostics: tap context must exist only in the dedicated diagnostic script')
  }
} catch (error) {
  failures.push(`SHEIN script isolation syntax: ${error instanceof Error ? error.message : String(error)}`)
}

// Exercise the compatibility prelude against the exact failure shape found by
// USB/browser diagnostics: a fixed, full-viewport SHEIN privacy layer whose
// action is a styled div. First prove Reject all releases the layer, then prove
// the iOS-only fallback releases an unresponsive shield without touching any
// unrelated overlay selector.
try {
  const { SHEIN_PRIVACY_COMPAT_SCRIPT } = evaluateInjectedScriptExports(
    'src/services/sheinPrivacyCompatScript.ts',
  )

  const runPrivacyFixture = ({ includeReject }) => {
    const attributes = new Map()
    const appliedStyles = new Map()
    const messages = []
    const scheduled = []
    let shieldVisible = true
    let rejectClicks = 0
    let now = 0
    const reject = {
      value: '',
      textContent: 'Reject all',
      getAttribute(name) { return name === 'aria-label' ? '' : null },
      setAttribute() {},
      click() { rejectClicks++; shieldVisible = false },
      dispatchEvent() {},
    }
    const shield = {
      style: { setProperty(name, value) { appliedStyles.set(name, value) } },
      getAttribute(name) { return attributes.get(name) || null },
      setAttribute(name, value) { attributes.set(name, value) },
      getBoundingClientRect() { return { left: 0, top: 0, width: 430, height: 932 } },
      querySelectorAll() { return includeReject ? [reject] : [] },
    }
    const documentFixture = {
      documentElement: { clientWidth: 430, clientHeight: 932 },
      visibilityState: 'visible',
      querySelectorAll(selector) {
        return selector === '[class*="shein_privacy_agreement"]' && shieldVisible ? [shield] : []
      },
      addEventListener() {},
    }
    const windowFixture = {
      top: null,
      innerWidth: 430,
      innerHeight: 932,
      __otlobliNativePlatform: 'ios',
      getComputedStyle() {
        return { display: 'flex', visibility: 'visible', pointerEvents: 'auto', position: 'fixed' }
      },
      mobileApp: { postMessage(message) { messages.push(message) } },
    }
    windowFixture.top = windowFixture
    const DateFixture = { now() { now += 400; return now } }
    const setTimeoutFixture = (callback, delay) => {
      scheduled.push({ callback, delay })
      return scheduled.length
    }
    new Function(
      'window', 'document', 'location', 'setTimeout', 'addEventListener', 'MouseEvent', 'Date',
      SHEIN_PRIVACY_COMPAT_SCRIPT,
    )(
      windowFixture,
      documentFixture,
      { hostname: 'm.shein.com', pathname: '/ar/', search: '', hash: '' },
      setTimeoutFixture,
      () => {},
      function MouseEvent() {},
      DateFixture,
    )
    scheduled.sort((a, b) => a.delay - b.delay)
    for (const task of scheduled) task.callback()
    return { appliedStyles, attributes, messages, rejectClicks }
  }

  const rejectFixture = runPrivacyFixture({ includeReject: true })
  if (rejectFixture.rejectClicks !== 1 ||
      !rejectFixture.messages.some((message) => message?.detail?.method === 'reject-all') ||
      rejectFixture.appliedStyles.has('display')) {
    failures.push('SHEIN privacy compatibility: styled Reject all control must resolve the shield first')
  }

  const fallbackFixture = runPrivacyFixture({ includeReject: false })
  if (fallbackFixture.appliedStyles.get('pointer-events') !== 'none' ||
      fallbackFixture.appliedStyles.get('display') !== 'none' ||
      fallbackFixture.attributes.get('data-otlobli-privacy-neutralized') !== '1' ||
      !fallbackFixture.messages.some((message) => message?.detail?.method === 'ios-invisible-shield-neutralized')) {
    failures.push('SHEIN privacy compatibility: confirmed unresponsive iOS shield must release pointer events')
  }
} catch (error) {
  failures.push(`SHEIN privacy compatibility fixture: ${error instanceof Error ? error.message : String(error)}`)
}

try {
  const nativeBrowserSource = readFileSync(
    resolve(projectRoot, 'ios/App/App/OtlobliSheinBrowserPlugin.swift'),
    'utf8',
  )
  const webViewConstructors = nativeBrowserSource.match(/\bWKWebView\s*\(/g)?.length ?? 0
  const displayLinkConstructors = nativeBrowserSource.match(/\bCADisplayLink\s*\(/g)?.length ?? 0
  if (webViewConstructors !== 1) {
    failures.push(`dedicated iOS SHEIN browser: expected one WKWebView constructor, got ${webViewConstructors}`)
  }
  if (displayLinkConstructors !== 0) {
    failures.push(`dedicated iOS SHEIN browser: expected no same-instance display-link repair, got ${displayLinkConstructors}`)
  }
} catch (error) {
  failures.push(`dedicated iOS SHEIN browser structure: ${error instanceof Error ? error.message : String(error)}`)
}

try {
  const sheinSource = readSheinRuntimeSource()
  const tickStart = sheinSource.indexOf('function tick()')
  const tickEnd = sheinSource.indexOf('var tickScheduled = false', tickStart)
  const tickSource = sheinSource.slice(tickStart, tickEnd)
  const sheinBranchStart = tickSource.indexOf('ensureLoadingOverlay();')
  const sheinBranch = tickSource.slice(sheinBranchStart)
  const toastGuard = sheinBranch.indexOf('hideSheinCartSuccessToast();')
  const addButton = sheinBranch.indexOf('ensureAddToCartButton();')
  if (tickStart < 0 || tickEnd < 0 || sheinBranchStart < 0 || toastGuard < 0 ||
      addButton < 0 || toastGuard > addButton) {
    failures.push('SHEIN cart toast: entry guard must run before the Otlobli add button is exposed')
  }
} catch (error) {
  failures.push(`SHEIN cart toast ordering: ${error instanceof Error ? error.message : String(error)}`)
}

// Low-end PDP guard: never flatten large selector candidates before the
// geometry check, and keep the two full-document text scans bounded/cheap.
try {
  const sheinSource = readSheinRuntimeSource()
  const nativeAddStart = sheinSource.indexOf('function hideSheinNativeProductAdd()')
  const nativeAddEnd = sheinSource.indexOf('var __otlobliBottomNavDebugCount', nativeAddStart)
  const nativeAdd = sheinSource.slice(nativeAddStart, nativeAddEnd)
  const geometryGate = nativeAdd.indexOf('if (r.width < 64')
  const textGate = nativeAdd.indexOf('if (!isAddToCartText(el)) return;')
  if (nativeAddStart < 0 || nativeAddEnd < 0 || geometryGate < 0 || textGate < 0 || geometryGate > textGate) {
    failures.push('SHEIN low-end PDP: native add geometry must reject large wrappers before reading text')
  }

  const textStart = sheinSource.indexOf('function isAddToCartText(el)')
  const textEnd = sheinSource.indexOf('function isAddToCartButton', textStart)
  const textHelper = sheinSource.slice(textStart, textEnd)
  if (!textHelper.includes('(el.childElementCount || 0) <= 6 ? el.textContent')) {
    failures.push('SHEIN low-end PDP: add-text helper must bound descendant text flattening')
  }

  if (sheinSource.includes('function otlobliForceAcceptCookies()') ||
      sheinSource.includes('function protectSheinCookieConsentAction()') ||
      sheinSource.includes('function protectCookieConsentAction()')) {
    failures.push('SHEIN privacy compatibility: stale accept/raise implementations must not race the single owner')
  }

  const blockStart = sheinSource.indexOf('function checkForSheinSecurityBlock()')
  const blockEnd = sheinSource.indexOf('var __otlobliSheinViewerRoot', blockStart)
  const blockHelper = sheinSource.slice(blockStart, blockEnd)
  if (!blockHelper.includes("document.getElementsByTagName('*').length > 900") ||
      !blockHelper.includes('document.body.textContent') || blockHelper.includes('document.body.innerText') ||
      !/GSRM\|gone missing\|not avaliable\|not available\|system not/.test(blockHelper)) {
    failures.push('SHEIN low-end PDP: security-block detector must stay effective without full-page layout reads')
  }
} catch (error) {
  failures.push(`SHEIN low-end PDP guard: ${error instanceof Error ? error.message : String(error)}`)
}

try {
  const nativeSource = readFileSync(resolve(projectRoot, 'ios/App/App/OtlobliSheinBrowserPlugin.swift'), 'utf8')
  const constructors = nativeSource.match(/WKWebView\(frame:/g) || []
  const memoryStart = nativeSource.indexOf('@objc private func applicationDidReceiveMemoryWarning()')
  const hideStart = nativeSource.indexOf('case "hide":')
  const showStart = nativeSource.indexOf('case "show":', hideStart)
  const navigateStart = nativeSource.indexOf('case "navigate":', showStart)
  const handlerEnd = nativeSource.indexOf('default:', navigateStart)
  const ordinaryHide = nativeSource.slice(hideStart, showStart)
  const ordinaryNavigate = nativeSource.slice(navigateStart, handlerEnd)
  const mutatesOnForeground =
    nativeSource.includes('UIApplication.didEnterBackgroundNotification') ||
    nativeSource.includes('UIApplication.didBecomeActiveNotification') ||
    nativeSource.includes('recomposeAttachedWebViewAfterForeground') ||
    nativeSource.includes('foregroundRecomposePending') ||
    nativeSource.includes("PageTransitionEvent('pageshow'")
  if (constructors.length !== 1 || memoryStart < 0 || mutatesOnForeground ||
      hideStart < 0 || showStart < 0 || navigateStart < 0 || handlerEnd < 0 ||
      ordinaryHide.includes('destroyRenderSurface()') || ordinaryNavigate.includes('destroyRenderSurface()')) {
    failures.push('SHEIN native session: background/foreground must leave the one live WKWebView attached and untouched')
  }
} catch (error) {
  failures.push(`SHEIN native persistent-session guard: ${error instanceof Error ? error.message : String(error)}`)
}

// SHEIN's verified home and the selected product must remain in the exact same
// WebContent process. A fresh WKWebView can retain cookies yet lose the live
// risk proof, producing the product-list spinner captured on the real iPhone.
try {
  const appSource = readFileSync(resolve(projectRoot, 'src/App.tsx'), 'utf8')
  const cartOpenStart = appSource.indexOf('const openStoreProductFromCart = (sourceLink: string)')
  const cartOpenEnd = appSource.indexOf("InAppBrowser.addListener('closeEvent'", cartOpenStart)
  const cartOpenSource = appSource.slice(cartOpenStart, cartOpenEnd)
  const warmReuse = cartOpenSource.indexOf('sameSheinProductNavigation(targetUrl, currentWebviewUrlRef.current)')
  const sameSessionNavigate = cartOpenSource.indexOf('navigateStoreWebviewInPage(targetUrl)')
  if (cartOpenStart < 0 || cartOpenEnd < 0 || warmReuse < 0 || sameSessionNavigate < 0 ||
      cartOpenSource.includes('openIosSheinCartProductInFreshSession') ||
      cartOpenSource.includes('InAppBrowser.setUrl({ url: targetUrl })') ||
      cartOpenSource.includes('InAppBrowser.close(')) {
    failures.push('SHEIN persistent session: cart product must reuse the verified in-page WebContent context')
  }

  if (appSource.includes('const openIosSheinCartProductInFreshSession') ||
      appSource.includes('const recoverSheinCartProductSession') ||
      appSource.includes('sheinCartProductRecoveryInFlightRef')) {
    failures.push('SHEIN persistent session: obsolete fresh-session recovery must stay removed')
  }

  const sheinOptionsStart = appSource.indexOf("...(activeStore === 'shein'")
  const temuOptionsStart = appSource.indexOf("        : {", sheinOptionsStart)
  const sheinOptionsSource = appSource.slice(sheinOptionsStart, temuOptionsStart)
  if (sheinOptionsStart < 0 || temuOptionsStart < 0 ||
      !sheinOptionsSource.includes('hidden: true') ||
      !sheinOptionsSource.includes('invisibilityMode: InvisibilityMode.FAKE_VISIBLE') ||
      !sheinOptionsSource.includes('isPresentAfterPageLoad: isIosNative')) {
    failures.push('SHEIN ready reveal: iOS must prepare the SHEIN WebView offscreen at full device size')
  }

  const homeVisibilityStart = appSource.indexOf("if (screen === 'home')", temuOptionsStart)
  const homeVisibilityEnd = appSource.indexOf("} else if (sheinOpenedRef.current)", homeVisibilityStart)
  const homeVisibilitySource = appSource.slice(homeVisibilityStart, homeVisibilityEnd)
  const readyGuard = homeVisibilitySource.indexOf('if (webviewOpeningRef.current || !sheinReadyRef.current) return undefined')
  const showCall = homeVisibilitySource.indexOf('InAppBrowser.show()')
  if (homeVisibilityStart < 0 || homeVisibilityEnd < 0 || readyGuard < 0 || showCall < 0 || readyGuard > showCall) {
    failures.push('SHEIN ready reveal: readiness guard must run before the native WebView is shown')
  }

  const storeSwitchStart = appSource.indexOf('const switchSelectedStore = (id: StoreId, afterSwitch: () => void)')
  const storeSwitchEnd = appSource.indexOf('const openStoreFromHub = (id: StoreId)', storeSwitchStart)
  const storeSwitchSource = appSource.slice(storeSwitchStart, storeSwitchEnd)
  if (storeSwitchStart < 0 || storeSwitchEnd < 0 || storeSwitchSource.includes('InAppBrowser.clearCache()')) {
    failures.push('SHEIN fast entry: an ordinary store switch must preserve the healthy HTTP/WebKit cache')
  }

  // Actual backend switches still close asynchronously, so an open request in
  // that narrow window remains queued. Same-store chooser navigation, however,
  // must never manufacture that close in the first place.
  const browseStart = appSource.indexOf('const browseShein = () => {')
  const browseEnd = appSource.indexOf('browseSheinRef.current = browseShein', browseStart)
  const browseSource = appSource.slice(browseStart, browseEnd)
  const closingGate = browseSource.indexOf('if (webviewClosingRef.current)')
  const queueWhileClosing = browseSource.indexOf("pendingStoreOpenAfterCloseRef.current = screenRef.current === 'home'")
  const openingGate = browseSource.indexOf('if (sheinOpenedRef.current || webviewOpeningRef.current) return')
  if (browseStart < 0 || browseEnd < 0 || closingGate < 0 || queueWhileClosing < 0 || openingGate < 0 ||
      closingGate > queueWhileClosing || queueWhileClosing > openingGate) {
    failures.push('SHEIN reentry: a store-open request must be queued before the native-closing early return')
  }

  const closeStoreStart = appSource.indexOf("if (detail?.type === 'closeStore')")
  const closeStoreEnd = appSource.indexOf("if (detail?.type === 'requestStoreExit')", closeStoreStart)
  const closeStoreSource = appSource.slice(closeStoreStart, closeStoreEnd)
  if (closeStoreStart < 0 || closeStoreEnd < 0 ||
      !closeStoreSource.includes("recordAppDiagnostic('store_session_parked_for_chooser', { store: 'shein' })") ||
      !closeStoreSource.includes('InAppBrowser.hide()') ||
      closeStoreSource.includes('InAppBrowser.close(') ||
      closeStoreSource.includes('webviewSessionRef.current += 1') ||
      closeStoreSource.includes('sheinOpenedRef.current = false') ||
      closeStoreSource.includes('setSheinReady(false)')) {
    failures.push('SHEIN same-store reentry: chooser exit must park, never close or reset, the verified session')
  }

  const hubOpenStart = appSource.indexOf('const openStoreFromHub = (id: StoreId)')
  const hubOpenEnd = appSource.indexOf('const switchCartStore = (id: StoreId)', hubOpenStart)
  const hubOpenSource = appSource.slice(hubOpenStart, hubOpenEnd)
  const armReentry = hubOpenSource.indexOf('pendingStoreOpenAfterCloseRef.current = false')
  const enterHome = hubOpenSource.indexOf("screenRef.current = 'home'")
  if (hubOpenStart < 0 || hubOpenEnd < 0 || armReentry < 0 || enterHome < 0 || armReentry > enterHome) {
    failures.push('SHEIN reentry: the hub tap must clear stale close state before entering Home')
  }

  if (!appSource.includes("const shouldResetSheinCache = activeStore === 'shein' && sheinCacheResetPendingRef.current") ||
      !appSource.includes('const prepareStoreWebview = shouldResetSheinCache') ||
      !appSource.includes('sheinCacheResetPendingRef.current = true')) {
    failures.push('SHEIN recovery: bounded damaged-session cache reset must remain available')
  }
} catch (error) {
  failures.push(`SHEIN persistent session: ${error instanceof Error ? error.message : String(error)}`)
}

for (const check of checks) {
  const files = check.files || [check.file]
  let contents = ''
  try {
    contents = files
      .map((file) => readFileSync(resolve(projectRoot, file), 'utf8'))
      .join('\n')
  } catch (error) {
    failures.push(`${check.label}: cannot read ${files.join(', ')} (${error.message})`)
    continue
  }

  for (const marker of check.markers) {
    if (!contents.includes(marker)) {
      failures.push(`${check.label}: missing ${JSON.stringify(marker)} in ${files.join(', ')}`)
    }
  }
  for (const forbidden of check.forbidden || []) {
    if (contents.includes(forbidden)) {
      failures.push(`${check.label}: forbidden ${JSON.stringify(forbidden)} in ${files.join(', ')}`)
    }
  }
}

if (failures.length > 0) {
  console.error('\nSHEIN iPhone freeze guard FAILED:\n')
  for (const failure of failures) console.error(`- ${failure}`)
  console.error('\nRead docs/SHEIN_IOS_FREEZE_GUARD.md before changing the patch or lifecycle.\n')
  process.exit(1)
}

console.log('SHEIN iPhone freeze guard: OK')
