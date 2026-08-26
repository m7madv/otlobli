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
const capgoPatchFile = 'patches/@capgo+capacitor-inappbrowser+8.6.25.patch'
const capgoPatchSource = readFileSync(resolve(projectRoot, capgoPatchFile), 'utf8')
const projectPatchSide = (patch, prefix) => patch
  .split(/\r?\n/)
  .filter((line) => line.startsWith(prefix) && !line.startsWith(prefix.repeat(3)))
  .map((line) => line.slice(1))
  .join('\n')
const capgoPatchAdded = projectPatchSide(capgoPatchSource, '+')
const capgoPatchRemoved = projectPatchSide(capgoPatchSource, '-')
const sheinRuntimeSourceFiles = [
  'src/services/sheinBrowserScript.ts',
  'src/services/sheinNavigationScript.ts',
  'src/services/sheinSessionScript.ts',
  'src/services/storeProductCaptureScript.ts',
  'src/services/storeBlockingScript.ts',
  'src/services/temuBrowserScript.ts',
  'src/services/storeRuntimeCoordinator.ts',
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
      'if #available(iOS 17.0, *)',
      'configuration.preferences.inactiveSchedulingPolicy = .throttle',
      'private func isCanonicalSheinHomeURL(_ url: URL?) -> Bool',
      'if isCanonicalSheinHomeURL(webView.url)',
      'chosenAction: "parkStoreAtRoot"',
      'webView?.backForwardList.backList',
      '[OTLOBLI_BACK]',
      'private let nativeBackVerticalOffset: CGFloat = 14',
      'constant: 12 + nativeBackVerticalOffset',
      'CGFloat(max(8, min(top, 120))) + nativeBackVerticalOffset',
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
      'inactiveSchedulingPolicy = .none',
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
    file: capgoPatchFile,
    markers: [
      'func otlobliForceRecompose()',
      'otlobliLifecycleGeneration',
      'webView.removeFromSuperview()',
      'self.view.addSubview(webView)',
      'webView.scrollView.setContentOffset(offset, animated: false)',
      'DispatchQueue.main.asyncAfter(deadline: .now() + 0.25)',
      'controller.otlobliForceRecompose()',
      'UIApplication.shared.applicationState == .active',
      'public void otlobliOnHostResume()',
      'public void navigate(String target)',
      "new CustomEvent('otlobli:nativeNavigate'",
      'func navigateHostFromJavaScript(_ target: String',
      'window.webkit.messageHandlers.navigate.postMessage',
      'انقر «الرئيسية» مرتين لفتح قائمة المتاجر',
      'انقر مرة ثانية لفتح قائمة المتاجر',
      'يفتح قائمة المتاجر مباشرة',
      'if (isOtlobliTouchExplorationEnabled())',
      'now - otlobliLastHomeActivationAt <= 320L',
      'if UIAccessibility.isVoiceOverRunning',
      'now - otlobliLastHomeActivationAt <= 0.32',
      'int opaqueBottomInset,',
      'int gestureSafeBottomInset,',
      'int visibleBottomFloor = keyboardVisible',
      ': Math.max(otlobliDp(16), Math.max(0, gestureSafeBottomInset));',
      'int systemBottomOffset = keyboardVisible ? 0 : Math.max(0, opaqueBottomInset);',
      '"config_navBarInteractionMode"',
      'getInteger(modeResource) == 2',
      'int opaqueBottomInset = usesGestureNavigation',
      'int gestureSafeBottomInset = usesGestureNavigation ? gestureBottomInset : 0;',
      'int navigationHeight = otlobliDp(74) + visibleBottomFloor;',
      'navigation.setPadding(0, 0, 0, visibleBottomFloor);',
      'navigationParams.bottomMargin = systemBottomOffset + keyboardOffset;',
      'contentParams.bottomMargin = navigationHeight + systemBottomOffset + keyboardOffset;',
      'int navigationWidth = Math.min(otlobliDp(440), availableWidth);',
      'navigationView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)',
      'navigationView.widthAnchor.constraint(lessThanOrEqualToConstant: 440)',
    ],
    removedMarkers: [
      '        Log.i("InjectPreShowScript", String.format("PreShowScript script:\\n%s", script));',
      '        print("[InAppBrowser - InjectPreShowScript] PreShowScript script: \\(script)")',
      '                Log.d("WebViewDialog", "Received message from JavaScript: " + message);',
      '        Log.d("InAppBrowserPlugin", "Event data: " + eventData.toString());',
      '        print("Event data: \\(eventData)")',
    ],
    forbidden: [
      'appWillEnterForeground',
      'willEnterForegroundNotification',
      'otlobliRecomposeAllWebViews',
      'for delay in [0.12, 0.5, 1.2, 2.2]',
      'otlobliForceRecompose(force:',
      'اضغط مرتين للتبديل',
      'Math.max(otlobliDp(16), safeBottomInset)',
      'int navigationHeight = otlobliDp(74) + visibleBottomFloor + systemBottomInset;',
      'navigation.setPadding(0, 0, 0, visibleBottomFloor + systemBottomInset);',
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
      'webView.removeFromSuperview()',
      'self.view.addSubview(webView)',
      'webView.scrollView.setContentOffset(offset, animated: false)',
      'message.name == "navigate"',
      'window.webkit.messageHandlers.navigate.postMessage',
      'homeButton.accessibilityHint = "يفتح قائمة المتاجر مباشرة"',
      'hint.accessibilityLabel = message',
      'message: "انقر «الرئيسية» مرتين لفتح قائمة المتاجر"',
      'DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: discovery)',
      'if UIAccessibility.isVoiceOverRunning',
      'guard now - otlobliLastHomeActivationAt <= 0.32 else',
      'showOtlobliStoreSwitchHint()',
      'navigationView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)',
      'navigationView.widthAnchor.constraint(lessThanOrEqualToConstant: 440)',
    ],
    forbidden: [
      'otlobliForceRecompose(force:',
      'print("[InAppBrowser - InjectPreShowScript] PreShowScript script:',
      'اضغط مرتين للتبديل',
    ],
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
      'active ? label + "، يفتح قائمة المتاجر مباشرة" : label',
      'if (isOtlobliTouchExplorationEnabled())',
      'now - otlobliLastHomeActivationAt <= 320L',
      '"انقر «الرئيسية» مرتين لفتح قائمة المتاجر"',
      '"انقر مرة ثانية لفتح قائمة المتاجر"',
      'mainHandler.postDelayed(otlobliStoreSwitchDiscovery, 700L);',
      'showOtlobliStoreSwitchHint();',
      'int opaqueBottomInset,',
      'int gestureSafeBottomInset,',
      'int visibleBottomFloor = keyboardVisible',
      ': Math.max(otlobliDp(16), Math.max(0, gestureSafeBottomInset));',
      'int systemBottomOffset = keyboardVisible ? 0 : Math.max(0, opaqueBottomInset);',
      '"config_navBarInteractionMode"',
      'getInteger(modeResource) == 2',
      'int opaqueBottomInset = usesGestureNavigation',
      'int gestureSafeBottomInset = usesGestureNavigation ? gestureBottomInset : 0;',
      'int navigationHeight = otlobliDp(74) + visibleBottomFloor;',
      'navigation.setPadding(0, 0, 0, visibleBottomFloor);',
      'navigationParams.bottomMargin = systemBottomOffset + keyboardOffset;',
      'contentParams.bottomMargin = navigationHeight + systemBottomOffset + keyboardOffset;',
      'int navigationWidth = Math.min(otlobliDp(440), availableWidth);',
      'int centeredGap = Math.max(0, (availableWidth - navigationWidth) / 2);',
    ],
    forbidden: [
      'Log.i("InjectPreShowScript", String.format("PreShowScript script:',
      'اضغط مرتين للتبديل',
      'Math.max(otlobliDp(16), safeBottomInset)',
      'int navigationHeight = otlobliDp(74) + visibleBottomFloor + systemBottomInset;',
      'navigation.setPadding(0, 0, 0, visibleBottomFloor + systemBottomInset);',
    ],
  },
  {
    label: 'dedicated iOS store-navigation parity',
    file: 'ios/App/App/OtlobliSheinBrowserPlugin.swift',
    markers: [
      'navigation.centerXAnchor.constraint(equalTo: surface.safeAreaLayoutGuide.centerXAnchor)',
      'navigation.widthAnchor.constraint(lessThanOrEqualToConstant: 440)',
      'button.accessibilityLabel = labels[index]',
      '? "يفتح قائمة المتاجر مباشرة"',
      'if UIAccessibility.isVoiceOverRunning',
      'navigateHost(to: target)',
      'DispatchQueue.main.asyncAfter(deadline: .now() + 0.32, execute: timeout)',
      'message: "انقر «الرئيسية» مرتين لفتح قائمة المتاجر"',
      'message: "انقر مرة ثانية لفتح قائمة المتاجر"',
      'scheduleNativeStoreSwitchDiscoveryHint()',
      'showNativeStoreSwitchSecondTapHint()',
      'if locked {',
      'dismissNativeStoreSwitchHint()',
    ],
    forbidden: [
      'اضغط مرتين للتبديل',
    ],
  },
  {
    label: 'Temu first-tap chooser feedback and direct assistive activation',
    file: 'src/App.tsx',
    markers: [
      'showPersonalTemuSecondTapHint()',
      'personalTemuHomeTapTimerRef.current = window.setTimeout(() => {',
      '}, 320)',
      '? \'انقر مرة ثانية لفتح قائمة المتاجر\'',
      '\'انقر مرتين على «الرئيسية» لفتح قائمة المتاجر\'',
      "if (activationDetail === 0)",
      "storeMessageHandlerRef.current({ detail: { type: 'closeStore' }, sourceStore: 'temu' })",
      "ariaLabel={storeSwitchGestureEnabled ? 'الرئيسية، يفتح قائمة المتاجر مباشرة' : undefined}",
    ],
    forbidden: [
      'اضغط مرتين للتبديل',
      'اضغط مرتين على الرئيسية لتبديل المتجر',
    ],
  },
  {
    label: 'Android Personal Temu centered 440dp surface',
    file: 'android/app/src/main/java/com/otlobli/app/TemuEmbeddedBrowserPlugin.java',
    markers: [
      'Math.min(getContext().getResources().getDisplayMetrics().widthPixels, dp(440))',
      'Gravity.TOP | Gravity.CENTER_HORIZONTAL',
    ],
  },
  {
    label: 'Temu bounded native Home-only download-shell collapse',
    file: 'src/services/temuBrowserScript.ts',
    markers: [
      "document.documentElement.setAttribute('data-otlobli-native-platform', OTLOBLI_NATIVE_PLATFORM)",
      'html[data-otlobli-native-platform="android"][data-otlobli-temu-home-route="1"] [class*="downloadsWrapper"]',
      'html[data-otlobli-native-platform="ios"][data-otlobli-temu-home-route="1"] [class*="downloadsWrapper"]',
      'html[data-otlobli-native-platform="android"][data-otlobli-temu-home-route="1"] [data-otlobli-temu-download-shell="1"]',
      'html[data-otlobli-native-platform="android"][data-otlobli-temu-home-route="1"] [data-otlobli-temu-download-shell="1"] > *',
      'html[data-otlobli-native-platform="ios"][data-otlobli-temu-home-route="1"] [data-otlobli-temu-download-shell="1"]',
      'html[data-otlobli-native-platform="ios"][data-otlobli-temu-home-route="1"] [data-otlobli-temu-download-shell="1"] > *',
      'html[data-otlobli-native-platform="android"][data-otlobli-temu-home-route="1"][data-otlobli-temu-download-collapsed="1"] [js-selector="bg-cui-top-sticky"]',
      'html[data-otlobli-native-platform="ios"][data-otlobli-temu-home-route="1"][data-otlobli-temu-download-collapsed="1"] [js-selector="bg-cui-top-sticky"]',
      '{ height: 0 !important; min-height: 0 !important; max-height: 0 !important; overflow: hidden !important;',
      '{ transform: translate(-50%, 0) !important; }',
      'function otlobliSyncTemuDownloadCollapsedMarker(root, collapsed)',
      'function otlobliMarkTemuNativeDownloadShell()',
      "if (current !== '1') root.setAttribute(marker, '1')",
      'else if (current !== null)',
      "var nativePlatform = root.getAttribute('data-otlobli-native-platform')",
      "nativePlatform !== 'android' && nativePlatform !== 'ios'",
      "root.getAttribute('data-otlobli-temu-home-route') !== '1'",
      "document.querySelector('[class*=\"downloadsWrapper\"]')",
      'for (var depth = 0; shell && depth < 8; depth++)',
      'if (shell.childElementCount > 1)',
      "shell.querySelector('input,[role=\"searchbox\"],[class*=\"wrapperWithSearch\"],[class*=\"searchBar\" i]')",
      'var rect = shell.getBoundingClientRect();',
      'rect.top > 96 || rect.width < viewportWidth * 0.65 || rect.height > 180',
      "shell.setAttribute('data-otlobli-temu-download-shell', '1')",
      'otlobliSyncTemuDownloadCollapsedMarker(root, true)',
      'otlobliSyncTemuProductRouteState();',
      'otlobliMarkTemuNativeDownloadShell();',
      "var homePath = String(location.pathname || '/').replace(/\\\\/{2,}/g, '/').replace(/\\\\/+$/, '')",
      "var homeRoute = !homePath || /^\\\\/[a-z]{2}(?:-[a-z]{2})?$/i.test(homePath)",
      "homeRoute && !otlobliTemuAccountRoute()",
      "root.setAttribute('data-otlobli-temu-home-route', '1')",
      "root.removeAttribute('data-otlobli-temu-home-route')",
    ],
  },
  {
    label: 'native message bridge logging guard',
    files: [
      'node_modules/@capgo/capacitor-inappbrowser/android/src/main/java/ee/forgr/capacitor_inappbrowser/CapgoInAppBrowserPlugin.java',
      'node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/InAppBrowserPlugin.swift',
    ],
    markers: [],
    forbidden: [
      'Received message from JavaScript:',
      'Log.d("InAppBrowserPlugin", "Event data:',
      'print("Event data:',
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
      "import('./services/storeCaptureBundle')",
      'storeCaptureBundleLoadingRef',
      'const usesPersonalTemuRuntime =',
      'if (!usesPersonalTemuRuntime)',
    ],
  },
  {
    label: 'lazy store-only capture bundle',
    file: 'src/services/storeCaptureBundle.ts',
    markers: [
      "from './sheinBrowserScript'",
      "from './sheinPrivacyCompatScript'",
      'export const buildStoreCaptureScript',
    ],
    forbidden: [
      "from './sheinFreezeDiagnostics'",
      "from './sheinRegionDiagnostics'",
      "from './storeScriptDiagnostics'",
    ],
  },
  {
    label: 'low-end store hot-path hardening',
    files: [
      'src/services/sheinSessionScript.ts',
      'src/services/sheinPolicyEngine.ts',
      'src/services/temuBrowserScript.ts',
      'src/services/storeBlockingScript.ts',
      'src/services/storeRuntimeCoordinator.ts',
    ],
    markers: [
      'var visibleRegion = sheinVisibleShippingRegion();',
      'sheinSaudiSignalsOk(visibleRegion)',
      'function enqueue(root)',
      'if(queued)schedule();',
      "attributeFilter:['href','action','aria-label','role','data-testid','data-qa','data-type','data-role','data-action','data-name']",
      'var vitals = otlobliTemuProductVitals();',
      'function otlobliTemuCurrentProductConfirmed()',
      "var __otlobliTemuConfirmedProductKey = '';",
      "var __otlobliTemuReadinessRouteKey = '';",
      'function otlobliTemuInvalidateConfirmedProduct()',
      '__otlobliTemuReadinessRouteKey !== key',
      "__otlobliTemuVisibleSinceKey = '';",
      '__otlobliTemuConfirmedProductKey === key',
      'if (!temuProductConfirmed) {',
      'function otlobliSheinBlockedStyleIntact(el)',
      'if (otlobliSheinBlockedStyleIntact(el)) continue;',
      "var hasIconMedia = elIconSized && !!el.querySelector('svg, img');",
    ],
    forbidden: [
      "attributeFilter:['class'",
      'document.activeElement === __otlobliTemuLastSearchInput || knownValue',
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
      "'accept-all'",
      'window.__otlobliSheinPrivacyCompat = { resume: resume };',
      "addEventListener('privacyCookieAgreementShow', resume, false)",
      'function runBurst(id, index)',
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
      "'reject-all'",
      'findRejectAllControl',
    ],
  },
  {
    label: 'store-script responsibility boundaries',
    file: 'src/services/sheinBrowserScript.ts',
    markers: [
      "from './sheinSessionScript'",
      "from './storeProductCaptureScript'",
      "from './storeBlockingScript'",
      "from './temuBrowserScript'",
      "from './storeRuntimeCoordinator'",
      '${sessionScript}',
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
      'OTLOBLI_NAV_BOOTSTRAP_SCRIPT',
    ],
  },
  {
    label: 'isolated DOM navigation fallback dependency',
    file: 'src/services/sheinSessionScript.ts',
    markers: [
      "from './sheinNavigationScript'",
      'OTLOBLI_NAV_TOUCH_BRIDGE_JS',
    ],
  },
  {
    label: 'SHEIN site-owned persistent session',
    file: 'src/services/sheinSessionScript.ts',
    markers: [
      'SHEIN owns its cookies, localStorage and sessionStorage.',
      'preserving',
      'signed address',
      'function sheinPrepareNativeSaudiRepair()',
      'if (sheinSignedSaudiAddressReady())',
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
    label: 'temporary store isolation tooling is absent from production',
    files: ['src/App.tsx', 'src/config.ts', 'vite.config.ts', 'src/services/storeCaptureBundle.ts', 'src/services/sheinBrowserScript.ts', 'src/services/sheinNavigationScript.ts'],
    markers: [
      'export const buildStoreCaptureScript',
      'otlobliLoadingCover: true',
      '${captureBundle.SHEIN_POLICY_DOCUMENT_START_SCRIPT}',
      'const nativeStorePrelude = `window.__otlobliNativeNavigation=true;',
      'otlobliNativeNavigation: true',
      'function otlobliScriptEnabled() { return true; }',
    ],
    forbidden: [
      'STORE_SCRIPT_DIAGNOSTICS',
      'VITE_STORE_SCRIPT_DIAGNOSTICS',
      'storeScriptDiagnostics',
      'storeScriptFlagsChanged',
      '__OTLOBLI_SCRIPT_FLAGS__',
      'navigationEarlyProtection',
      'buildDiagnosticStoreCaptureScript',
      'otlobli-script-diagnostics',
      'SHEIN_IOS_FREEZE_DIAGNOSTICS',
      'SHEIN_IOS_FREEZE_DIAGNOSTICS_BYPASS_RECOVERY',
      'SHEIN_FREEZE_DIAGNOSTIC_SCRIPT',
      'otlobliTapDiagnostics',
      'otlobliFreezeDiagnostics',
      '__OTLOBLI_SHEIN_REGION_DIAGNOSTICS__',
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
      'if (!sheinVisualReadyRef.current &&',
      'isSheinCoordinatorVisuallyReady(next)',
    ],
  },
  {
    label: 'iOS SHEIN safe visual-ready cover release',
    file: 'ios/App/App/OtlobliSheinBrowserPlugin.swift',
    markers: [
      'private func shouldReleaseLoadingCover(for detail: [String: Any]) -> Bool',
      'type == "sheinPageInteractive"',
      'coordinator["currencyState"] as? String == "matching"',
      'coordinator["languageState"] as? String == "matching"',
      'coordinator["policyState"] as? String == "verified"',
      'coordinator["captureState"] as? String == "ready"',
      'countryState != "mismatch" && regionState != "mismatch"',
    ],
  },
  {
    label: 'SHEIN v86.216 browse-ready region continuation with progress-aware repair bound',
    file: 'src/services/sheinSessionScript.ts',
    markers: [
      'var sheinNativeCoverRepairActive = false;',
      "var sheinNativeCoverVisualReadyPath = '';",
      'now - sheinNativeCoverRepairStartedAt >= (OTLOBLI_LOW_END ? 2800 : 1800)',
      'now - sheinNativeCoverInteractiveCheckAt >= (OTLOBLI_LOW_END ? 900 : 450)',
      'var repairStalledFor = repairNow - Math.max(sheinShippingProgressAt || 0, sheinNativeCoverRepairStartedAt);',
      'var repairStallLimit = OTLOBLI_LOW_END ? 20000 : 16000;',
      'var repairAbsoluteLimit = OTLOBLI_LOW_END ? 45000 : 36000;',
      'if (repairStalledFor >= repairStallLimit || repairAge >= repairAbsoluteLimit)',
      'closeResolvedSheinShippingUi(true);',
      "sheinPostNativeCoverState('sheinSaudiReady', true)",
      "sheinPostNativeCoverState('sheinPageInteractive', true)",
    ],
    forbidden: [
      '__otlobliAutomaticRegionRepairExhausted',
      'home-unknown-repair-cancelled',
      'if (!productRoute && !explicitRegionMismatch)',
    ],
  },
  {
    label: 'SHEIN v86.71 automatic product-region preparation',
    file: 'src/services/sheinSessionScript.ts',
    markers: [
      'if (!sheinLooksLikeProductPageForShipping() && !sheinFindHomeShippingEntryControl()) return;',
      'if (!sheinSignedSaudiAddressReady()) sheinPrepareNativeSaudiRepair();',
      'function sheinPrimeRegionRepairFromRoute()',
      'var repairStarted = sheinPrepareNativeSaudiRepair();',
    ],
    forbidden: ['homeRegionBootstrap', 'manualRepair'],
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
    label: 'SHEIN owns product-card navigation',
    file: 'src/services/sheinNavigationScript.ts',
    markers: [
      'export const OTLOBLI_NAV_TOUCH_BRIDGE_JS',
      "if (!messageType) return;",
      "window.addEventListener('touchend', routeOtlobliNavTouch",
      'Product-card taps remain wholly',
    ],
    forbidden: [
      'OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS',
      'OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS',
      'product-tap-route-fallback',
      '__otlobliProductTapAttemptAt',
      'location.assign(',
      "type:'sheinChunkLoadFailure'",
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
      'if (otlobliChallengeActive && challengeNow - __otlobliChallengeScanAt < 600)',
      'function otlobliResolveHumanChallenge()',
      "type: 'humanCheck'",
      "type: 'humanCheckResolved'",
      "documentGeneration: String(window.__otlobliDocumentGeneration || '')",
      'function otlobliHideBackControlForHumanChallenge()',
      "window.__otlobliNativeBackState = 'challenge-hidden'",
      "type: 'otlobliBackButtonState', visible: false",
    ],
    forbidden: [
      '.click()',
      'location.reload(',
      'sessionStorage',
      'otlobli-human-check-guide',
      'otlobliRememberHumanChallenge',
      'otlobliForgetHumanChallenge',
      'sheinUnlockPageBehindShippingDrawer()',
    ],
  },
  {
    label: 'SHEIN verification resolves without product interactivity',
    files: [
      'src/services/sheinHumanCheck.ts',
      'src/services/storeRuntimeCoordinator.ts',
    ],
    markers: [
      'function otlobliGuardHumanChallenge()',
      'if (otlobliGuardHumanChallenge())',
      'if (otlobliChallengeAbsenceIsStable(Date.now()))',
      'otlobliResolveHumanChallenge();',
      'if (otlobliChallengeSettlementIsStable(Date.now()))',
      'otlobliFinishChallengeSettlement();',
    ],
    forbidden: [
      'otlobliLooksLikeRemovedProductPage',
      'otlobliNotifyHumanCheckSkipped',
      'if (!sheinPageLooksInteractive())',
    ],
  },
  {
    label: 'SHEIN auth-route delimiter compatibility',
    files: [
      'src/services/sheinPolicyEngine.ts',
      'src/services/sheinSessionScript.ts',
    ],
    markers: [
      'auth(?:\\/login)?)(?:[/?#.-]|$)',
      'auth(?:/login)?)(?:[/?#.-]|$)',
    ],
  },
  {
    label: 'SHEIN exact login-later dismissal reuses the bounded policy observer',
    file: 'src/services/sheinPolicyEngine.ts',
    markers: [
      'function exactLoginLaterLabel(value)',
      'MAX_DEFERRED_LOGIN_LATER=12',
      'deferredLoginLater=[]',
      'function rememberDeferredLoginLater(el)',
      'function dismissExactLoginLater(el,enabled,defer)',
      'function flushDeferredLoginLater()',
      "LOGIN_LATER_SCOPE_SELECTOR='.s_auth__block-login-tip'",
      "LOGIN_LATER_CONTROL_SELECTOR='button,[role=\"button\"]'",
      'function scanExactLoginLater(root,enabled,defer)',
      'login later|',
      "data-otlobli-login-later-fired",
      'scanExactLoginLater(root,canDismiss,canDefer);',
      'for(var i=0;i<nodes.length&&i<MAX_NODES_PER_ROOT;i++)hide(nodes[i],classify(nodes[i]));',
      'flushDeferredLoginLater();',
    ],
    forbidden: [
      'setInterval(',
      'history.back(',
      'location.assign(',
      "querySelectorAll('div",
      "querySelectorAll('span",
      "LOGIN_LATER_CONTROL_SELECTOR='button,a",
    ],
  },
  {
    label: 'SHEIN runtime readiness resumes the deferred policy outside challenges',
    file: 'src/services/sheinSessionScript.ts',
    markers: [
      'window.__otlobliStoreRuntimeReady = true;',
      'if (!OTLOBLI_DIRECT_HUMAN_CHALLENGE && !otlobliIsHumanChallenge())',
      'window.__otlobliSheinPolicyEngine.resume();',
    ],
  },
  {
    label: 'SHEIN login-later fallback can reach an exact hidden opt-out',
    file: 'src/services/storeBlockingScript.ts',
    markers: [
      'var exactSkipPattern = /^(?:sign',
      "var pageLabel = normalizeLoginLabel(pageControl.textContent || '')",
      "var pageAriaLabel = normalizeLoginLabel(pageControl.getAttribute('aria-label') || '')",
      "var pageTitle = normalizeLoginLabel(pageControl.getAttribute('title') || '')",
      '!exactSkipPattern.test(pageLabel) && !exactSkipPattern.test(pageAriaLabel) && !exactSkipPattern.test(pageTitle)',
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
    label: 'SHEIN native damaged-session recovery path',
    file: 'src/App.tsx',
    markers: [
      'const recoverSheinChunkLoad = (reportedUrl: string)',
      "Capacitor.getPlatform() !== 'ios'",
      'now - sheinChunkRecoveryAtRef.current < 60_000',
      'sheinCacheResetPendingRef.current = true',
      'const sheinRecoveryProductUrl = (region: StoreRegion, ...candidates: string[])',
      'const resumeBackTarget: WebviewBackTarget',
      'pendingBackTargetRef.current = resumeBackTarget',
      'const wantsWarmSheinProductNav',
      'const wantsWarmProductNav = wantsWarmTemuProductNav || wantsWarmSheinProductNav',
      "const rawTargetUrl = wantsWarmProductNav",
      'markStoreWebviewReadyRef.current(webviewSessionRef.current)',
      '!wantsWarmProductNav && initialPendingUrl',
    ],
    forbidden: [
      '__otlobliSkipHomeRegionRepair',
      'wantsWarmSheinRecoveryProductNav',
    ],
  },
  {
    label: 'SHEIN v86.71 server-region cache transition',
    files: [
      'src/App.tsx',
      'src/services/sheinSessionScript.ts',
      'src/services/storeProductCaptureScript.ts',
    ],
    markers: [
      "if (activeStore === 'shein') sheinCacheResetPendingRef.current = true",
      "const shouldResetSheinCache = activeStore === 'shein' && sheinCacheResetPendingRef.current",
      '? InAppBrowser.clearCache()',
      'function ensureSheinSaudiStore()',
      'ensureSheinSaudiStore()',
    ],
    forbidden: [
      '__otlobliAutomaticRegionRepairExhausted',
      'manualRepair === true',
      'ensureSheinSaudiStore(true)',
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
    label: 'SHEIN document-start protection scans are retired after N6 device proof',
    files: sheinRuntimeSourceFiles,
    markers: [
      'hideListingCardAddButtons();',
      'hideSheinNativeProductAdd();',
    ],
    forbidden: [
      'navigationEarlyProtection',
      'function runEarlyProtections()',
      "style.id = 'otlobli-native-add-style'",
      'function hideVerifiedStoreBottomNav()',
      'function hideExactSheinSignupDiscountBanner()',
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
      "var shouldShow = __otlobliBackTarget === 'cart' || __otlobliBackTarget === 'orders' || IS_SHEIN",
      'var storeHomeRoot = otlobliStoreHomeRoot()',
      "type: 'otlobliBackButtonState'",
      'window.__otlobliNativeBackState !== nativeState',
      'var nativeBackAvailable = window.__otlobliNativeNavigation === true ||',
      'if (nativeBackAvailable) {',
      "var stalePageBack = document.getElementById('otlobli-back-btn')",
      'if (stalePageBack) stalePageBack.remove()',
      "btn.style.display = shouldShow ? 'flex' : 'none'",
      'if (shouldShow) otlobliStabilizeBackOverlay(btn)',
      "window.mobileApp.postMessage({ detail: { type: 'closeStore' } })",
      // v86.123: the back button must never absorb a tap and do nothing. A bare
      // history.back() is a silent no-op once the store's back stack is spent,
      // which stranded iPhone 6 customers inside a product after a few hops.
      'function otlobliBackOrLeave()',
      'if (location.href === f) location.assign(location.origin + h)',
      'otlobliBackOrLeave();',
    ],
    forbidden: [
      'function otlobliStabilizeTemuRootOverlay(el)',
      "btn.style.display = shouldShow && !nativeBackAvailable ? 'flex' : 'none'",
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
      'private let otlobliNativeBackVerticalOffset: CGFloat = 14',
      'constant: top + self.otlobliNativeBackVerticalOffset',
      'max(8, min(top, 72)) + self.otlobliNativeBackVerticalOffset',
      'self.view.bringSubviewToFront(button)',
      'otlobliNativeBackButtonDidTap',
      'emit("messageFromWebview", data: ["detail": ["type": "closeStore"]])',
      "document.getElementById('otlobli-back-btn');if(b)b.click()",
      'detail["type"] as? String == "otlobliBackButtonState"',
      'otlobliNativeBackButton?.isHidden = true',
      'private func republishOtlobliNativeBackState(in webView: WKWebView)',
      'republishOtlobliNativeBackState(in: webView)',
      'updates WKWebView.url without a didFinish/pageshow callback',
    ],
  },
  {
    label: 'Temu Back state re-announcement and store-switch discovery',
    files: [
      'src/services/sheinNavigationScript.ts',
      'src/services/storeBlockingScript.ts',
    ],
    markers: [
      "OTLOBLI_NAV_STYLE_VERSION = 'v86.224.1'",
      'data-otlobli-store-switch-hint',
      "hint.textContent = 'انقر مرة ثانية لفتح قائمة المتاجر'",
      'showStoreSwitchHint();',
      "homeTab.setAttribute('aria-label', 'الرئيسية، يفتح قائمة المتاجر مباشرة')",
      "staleHint.parentNode.removeChild(staleHint)",
      "window.__otlobliNativeBackState = '';",
      "window.addEventListener('pageshow', restoreOtlobliNavOnWake, false)",
    ],
    forbidden: [
      'اضغط مرتين للتبديل',
      'اضغط مرتين على الرئيسية لتبديل المتجر',
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
    label: 'SHEIN v86.71 product browsing starts signed region repair',
    files: [
      'src/services/sheinSessionScript.ts',
      'src/App.tsx',
    ],
    markers: [
      'if (!IS_SHEIN || !sheinLooksLikeProductRouteForShipping()) return false;',
      'var repairStarted = sheinPrepareNativeSaudiRepair();',
      '!OTLOBLI_DIRECT_HUMAN_CHALLENGE &&',
      '!otlobliIsHumanChallenge()) {',
      'if (shouldReloadSheinForSaudi())',
      'if (sheinProductIdentityFromUrl(url.toString())) return false',
      'ensureSheinSaudiStore()',
    ],
    forbidden: ['manualRepair', 'initialProductRoute', 'homeRegionBootstrap'],
  },
  {
    label: 'SHEIN scroll/navigation interaction guard',
    files: sheinRuntimeSourceFiles,
    markers: [
      'function sheinRestoreNavAfterShipping()',
      'function sheinLooksLikeProductRouteForShipping()',
      'function sheinRegionTransitionVeil(show)',
      'function sheinPrimeRegionRepairFromRoute()',
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
      'if (!visibleOptions.length) {',
      'visibleOptions = sheinCountryRowsInRoot(sheinResolvedShippingUiRoot());',
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
      'var homeDoubleTapMs = 320',
      "event.type === 'click' && now - lastPhysicalTouchAt < 450",
      'homeTapTimer = setTimeout(finishSingleHomeTap, homeDoubleTapMs)',
      "event.type === 'click' && event.detail === 0",
      'revealStoreChooser()',
      "tab.setAttribute('data-otlobli-nav-type', item.type)",
      'if (!otlobliNavIsActuallyCovered(nav)) return false;',
      "var metaPrice = parseFloat(getMeta('product:price:amount'))",
      "document.querySelector('.product-price .price-content, .product-intro__head-price, [class*=\"price\" i]')",
      'return !!p.title && !!p.image && p.priceUsd > 0 && (!cs.exists || !!p.color)',
      'function sheinTrackSelectedSkuPrice(event)',
      "__otlobliSkuPriceSource = 'selected-mutation'",
      'sheinTrackSelectedSkuPrice(event);',
      'setTimeout(commit, 1500)',
      'var __otlobliInitialCapturePath = location.pathname',
      'function sheinSpaRoutePrice()',
      "__otlobliSkuPriceSource = 'spa-dom'",
      '__otlobliSelectedSkuPriceBefore = getPrice()',
      'function sheinSelectedSkuPricePending()',
      'priceWaits++ < 16',
      'function sheinCountryRowsInRoot(root)',
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

const sheinPolicySource = readFileSync(resolve(projectRoot, 'src/services/sheinPolicyEngine.ts'), 'utf8')
if ((sheinPolicySource.match(/new MutationObserver\(/g) ?? []).length !== 1) {
  failures.push('SHEIN login-later policy: dismissal must reuse exactly the one existing policy observer')
}
const sheinLoginFallbackSource = readFileSync(resolve(projectRoot, 'src/services/storeBlockingScript.ts'), 'utf8')
const exactSkipStart = sheinLoginFallbackSource.indexOf('var exactSkipPattern =')
const exactSkipEnd = sheinLoginFallbackSource.indexOf('__otlobliSheinLoginSkipKey = skipKey;', exactSkipStart)
const exactSkipSource = sheinLoginFallbackSource.slice(exactSkipStart, exactSkipEnd)
if (exactSkipStart < 0 || exactSkipEnd < 0 ||
    exactSkipSource.includes('sheinElementIsVisible') ||
    exactSkipSource.includes("document.querySelector('input')")) {
  failures.push('SHEIN login-later fallback: exact opt-out must remain reachable without layout or form gates')
}

try {
  const { SHEIN_POLICY_DOCUMENT_START_SCRIPT } = evaluateInjectedScriptExports(
    'src/services/sheinPolicyEngine.ts',
  )
  const fixture = { observerConstructions: 0, scopeQueries: 0, controlQueries: 0, messages: [] }
  let loginLaterScope = null
  const makeControl = (label, scoped = true) => {
    const attributes = new Map([['role', 'button']])
    return {
      nodeType: 1,
      tagName: 'DIV',
      id: '',
      className: '',
      textContent: label,
      parentElement: null,
      isConnected: true,
      clicks: 0,
      getAttribute(name) { return attributes.get(name) ?? '' },
      setAttribute(name, value) { attributes.set(name, value) },
      removeAttribute(name) { attributes.delete(name) },
      closest(selector) {
        return scoped && selector === '.s_auth__block-login-tip' ? loginLaterScope : null
      },
      click() { this.clicks++ },
    }
  }
  const exactControls = [
    makeControl('Login Later'),
    makeControl('تسجيل لاحقًا'),
    makeControl('التسجيل لاحقًا'),
    makeControl('تسجيل الدخول لاحقًا'),
    makeControl('التسجيل الدخول لاحقًا'),
  ]
  const inexactControl = makeControl('Login Later Please')
  const outsideExactControl = makeControl('Login Later', false)
  const scopedControls = [...exactControls, inexactControl]
  const candidateControls = [...scopedControls, outsideExactControl]
  loginLaterScope = {
    nodeType: 1,
    matches(selector) { return selector === '.s_auth__block-login-tip' },
    closest() { return null },
    querySelectorAll(selector) {
      fixture.controlQueries++
      return selector === 'button,[role="button"]' ? scopedControls : []
    },
  }
  const styleNodes = new Map()
  const documentElement = {
    nodeType: 1,
    matches() { return false },
    querySelectorAll(selector) {
      if (selector === '.s_auth__block-login-tip') {
        fixture.scopeQueries++
        return [loginLaterScope]
      }
      return candidateControls
    },
    querySelector() { return candidateControls[0] },
    appendChild(node) {
      node.parentNode = this
      styleNodes.set(node.id, node)
    },
  }
  const documentFixture = {
    head: documentElement,
    documentElement,
    readyState: 'complete',
    getElementById(id) { return styleNodes.get(id) ?? null },
    createElement() { return { id: '', textContent: '', parentNode: null } },
    querySelectorAll() { return [] },
    querySelector() { return null },
    addEventListener() {},
  }
  class MutationObserverFixture {
    constructor(callback) {
      fixture.observerConstructions++
      this.callback = callback
    }
    observe() {}
    disconnect() {}
  }
  const windowFixture = {
    mobileApp: { postMessage(message) { fixture.messages.push(message) } },
  }
  const locationFixture = {
    hostname: 'm.shein.com',
    href: 'https://m.shein.com/ar/Black-Dress-p-123.html',
    pathname: '/ar/Black-Dress-p-123.html',
    search: '',
    hash: '',
  }
  runInNewContext(SHEIN_POLICY_DOCUMENT_START_SCRIPT, {
    window: windowFixture,
    document: documentFixture,
    location: locationFixture,
    MutationObserver: MutationObserverFixture,
    URL,
    setTimeout: () => 0,
    getComputedStyle: () => ({ display: 'none', visibility: 'hidden', opacity: '0' }),
  })
  const beforeReady = exactControls.map((control) => control.clicks)
  windowFixture.__otlobliStoreRuntimeReady = true
  windowFixture.__otlobliSheinPolicyEngine.resume()
  const afterFirstResume = exactControls.map((control) => control.clicks)
  windowFixture.__otlobliSheinPolicyEngine.resume()
  const afterSecondResume = exactControls.map((control) => control.clicks)
  if (beforeReady.some((count) => count !== 0) ||
      afterFirstResume.some((count) => count !== 1) ||
      afterSecondResume.some((count) => count !== 1) ||
      inexactControl.clicks !== 0 || outsideExactControl.clicks !== 0 ||
      fixture.observerConstructions !== 1 || fixture.scopeQueries < 3 || fixture.controlQueries < 3) {
    failures.push(`SHEIN login-later policy: exact pre-runtime nodes must defer and fire once on resume (${JSON.stringify({
      beforeReady,
      afterFirstResume,
      afterSecondResume,
      inexactClicks: inexactControl.clicks,
      outsideExactClicks: outsideExactControl.clicks,
      observerConstructions: fixture.observerConstructions,
      scopeQueries: fixture.scopeQueries,
      controlQueries: fixture.controlQueries,
    })})`)
  }
} catch (error) {
  failures.push(`SHEIN login-later deferred fixture: ${error instanceof Error ? error.message : String(error)}`)
}

// Parse the fully composed source exactly as the WebView receives it. The
// evaluator follows the pure local module graph, so splitting responsibilities
// across files cannot make the guard silently validate an empty import stub.
try {
  const scriptModule = {
    exports: evaluateInjectedScriptExports('src/services/sheinBrowserScript.ts'),
  }
  const captureScript = scriptModule.exports.SHEIN_CAPTURE_SCRIPT
  const temuCaptureScript = scriptModule.exports.TEMU_CAPTURE_SCRIPT
  const navigationModule = evaluateInjectedScriptExports('src/services/sheinNavigationScript.ts')
  const bootstrapScript = navigationModule.OTLOBLI_NAV_BOOTSTRAP_SCRIPT
  if (Object.hasOwn(scriptModule.exports, 'OTLOBLI_NAV_BOOTSTRAP_SCRIPT')) {
    failures.push('native navigation ownership: sheinBrowserScript must not export or package the legacy DOM bootstrap')
  }

  const exerciseNativeDomGuard = (script, label, { expectStaleRemoval = false } = {}) => {
    const metrics = { created: 0, listeners: 0, timers: 0, observers: 0, removed: 0 }
    const staleNavigation = { id: 'otlobli-nav', parentNode: null }
    const staleParent = {
      removeChild(node) {
        if (node === staleNavigation) {
          metrics.removed++
          staleNavigation.parentNode = null
        }
      },
    }
    staleNavigation.parentNode = staleParent
    const documentFixture = {
      body: {},
      head: {},
      documentElement: { style: { setProperty() {} }, appendChild() {} },
      getElementById(id) { return id === 'otlobli-nav' ? staleNavigation : null },
      createElement() { metrics.created++; return { style: {}, setAttribute() {}, appendChild() {} } },
      addEventListener() { metrics.listeners++ },
      querySelector() { return null },
      querySelectorAll() { return [] },
    }
    const windowFixture = {
      __otlobliNativeNavigation: true,
      addEventListener() { metrics.listeners++ },
    }
    windowFixture.top = windowFixture
    const context = {
      window: windowFixture,
      document: documentFixture,
      location: { hostname: 'm.shein.com', href: 'https://m.shein.com/ar/' },
      setTimeout() { metrics.timers++; return metrics.timers },
      clearTimeout() {},
      setInterval() { metrics.timers++; return metrics.timers },
      clearInterval() {},
      MutationObserver: class {
        constructor() { metrics.observers++ }
        observe() {}
        disconnect() {}
      },
    }
    try {
      runInNewContext(script, context)
    } catch (error) {
      failures.push(`${label}: native-path fixture failed (${error instanceof Error ? error.message : String(error)})`)
      return
    }
    if (metrics.created || metrics.listeners || metrics.timers || metrics.observers) {
      failures.push(`${label}: native path created DOM/listener maintenance (${JSON.stringify(metrics)})`)
    }
    if (expectStaleRemoval && metrics.removed !== 1) {
      failures.push(`${label}: native path did not remove the one stale #otlobli-nav node`)
    }
  }

  const sourceBetween = (source, startMarker, endMarker, label) => {
    const start = source.indexOf(startMarker)
    const end = source.indexOf(endMarker, start + startMarker.length)
    if (start < 0 || end < 0) {
      failures.push(`${label}: cannot inspect ${startMarker}`)
      return ''
    }
    return source.slice(start, end)
  }

  exerciseNativeDomGuard(
    bootstrapScript,
    'legacy DOM bootstrap suppression',
    { expectStaleRemoval: true },
  )
  for (const [store, runtimeScript] of [['SHEIN', captureScript], ['Temu', temuCaptureScript]]) {
    const touchBridge = sourceBetween(
      runtimeScript,
      'function otlobliInstallNavTouchBridge()',
      'otlobliInstallNavTouchBridge();',
      `${store} native touch bridge suppression`,
    )
    if (touchBridge) {
      exerciseNativeDomGuard(
        `${touchBridge}\notlobliInstallNavTouchBridge();`,
        `${store} native touch bridge suppression`,
      )
    }
    const ensureNavigation = sourceBetween(
      runtimeScript,
      'function ensureOtlobliNav()',
      'function ensureBackButton',
      `${store} native DOM navigation suppression`,
    )
    if (ensureNavigation) {
      exerciseNativeDomGuard(
        `${ensureNavigation}\nensureOtlobliNav();`,
        `${store} native DOM navigation suppression`,
        { expectStaleRemoval: true },
      )
    }
  }
  const challengeNavigation = sourceBetween(
    captureScript,
    'function otlobliEnsureChallengeNav()',
    'function otlobliScheduleChallengeNav',
    'SHEIN challenge native DOM navigation suppression',
  )
  if (challengeNavigation) {
    exerciseNativeDomGuard(
      `${challengeNavigation}\notlobliEnsureChallengeNav();`,
      'SHEIN challenge native DOM navigation suppression',
    )
    const challengeSchedule = sourceBetween(
      captureScript,
      'function otlobliScheduleChallengeNav()',
      'function otlobliIsHumanChallengeUrl',
      'SHEIN challenge native navigation scheduling suppression',
    )
    if (challengeSchedule) {
      exerciseNativeDomGuard(
        `${challengeNavigation}\n${challengeSchedule}\notlobliScheduleChallengeNav();`,
        'SHEIN challenge native navigation scheduling suppression',
      )
    }
  }

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
  const runHumanCheck = ({ exact = [], provider = [], semantic = [], title = '' } = {}) => runInNewContext(
    `${humanCheckScript}\notlobliIsHumanChallenge();`,
    {
      location: { href: 'https://m.shein.com/ar/product-p-520531743.html' },
      document: {
        title,
        body: { textContent: 'ordinary product page' },
        getElementById: () => null,
        querySelector: () => null,
        querySelectorAll: (selector) => {
          if (selector.includes('risk-one-pass')) return exact
          if (selector.startsWith('iframe[')) return provider
          return semantic
        },
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
  if (!runHumanCheck({ provider: [humanSurface({ painted: true })] })) {
    failures.push('SHEIN human check: a painted provider iframe is no longer detected')
  }
  if (runHumanCheck({ provider: [humanSurface({ painted: false })] })) {
    failures.push('SHEIN human check: a hidden stale provider iframe was treated as active')
  }

  const negativeCacheFixture = { visible: false, scans: 0 }
  const negativeCacheResult = runInNewContext(
    `${humanCheckScript}
     var firstNegative = otlobliIsHumanChallenge();
     __fixture.visible = true;
     var immediateMountedChallenge = otlobliIsHumanChallenge();
     ({ firstNegative:firstNegative, immediateMountedChallenge:immediateMountedChallenge });`,
    {
      __fixture: negativeCacheFixture,
      location: { href: 'https://m.shein.com/ar/' },
      document: {
        title: '',
        getElementById: () => null,
        querySelectorAll: (selector) => {
          negativeCacheFixture.scans++
          if (selector.startsWith('iframe[') && negativeCacheFixture.visible) {
            return [humanSurface({ painted: true })]
          }
          return []
        },
      },
      otlobliIsHumanChallengeUrl: () => false,
      sheinElementIsPainted: (surface) => surface.__painted !== false,
      Date: { now: () => 1000 },
      Math, String,
    },
  )
  if (negativeCacheResult.firstNegative !== false ||
      negativeCacheResult.immediateMountedChallenge !== true ||
      negativeCacheFixture.scans < 4) {
    failures.push(`SHEIN human check: an ordinary-page negative scan was cached across a newly mounted SPA challenge (${JSON.stringify({
      result: negativeCacheResult,
      scans: negativeCacheFixture.scans,
    })})`)
  }

  const challengeGuardSource = sourceBetween(
    captureScript,
    'function otlobliGuardHumanChallenge()',
    'function tick(',
    'SHEIN challenge-exclusive guard fixture',
  )
  const coordinatorWakeSource = sourceBetween(
    captureScript,
    'function runOtlobliCoordinator()',
    "document.addEventListener('visibilitychange'",
    'SHEIN challenge-exclusive coordinator fixture',
  )
  if (challengeGuardSource && coordinatorWakeSource) {
    const challengeLifecycleFixture = {
      now: 100,
      visible: true,
      readyState: 'complete',
      pauses: 0,
      resumes: 0,
      privacyResumes: 0,
      resumeOrder: [],
      schedules: 0,
      coordinatorSchedules: 0,
      blockers: 0,
      navigation: 0,
      security: 0,
      normalTicks: 0,
      tickArguments: [],
      messages: [],
    }
    const challengeLifecycle = runInNewContext(
      `${humanCheckScript}
       ${challengeGuardSource}
       var IS_SHEIN=true,IS_TEMU=false,OTLOBLI_NATIVE_NAV=true;
       var OTLOBLI_MAIN_INTERVAL=300,OTLOBLI_BLOCK_INTERVAL=120,OTLOBLI_NAV_INTERVAL=1200,OTLOBLI_SECURITY_INTERVAL=1000;
       var otlobliMainDue=0,otlobliBlockDue=0,otlobliNavDue=Infinity,otlobliSecurityDue=0;
       otlobliIsHumanChallenge=function(){return __fixture.visible;};
       function tick(challengeAlreadyGuarded){__fixture.normalTicks++;__fixture.tickArguments.push(challengeAlreadyGuarded);}
       function runOtlobliBlockers(){__fixture.blockers++;}
       function runOtlobliNavigationMaintenance(){__fixture.navigation++;}
       function checkForSheinSecurityBlock(){__fixture.security++;}
       function otlobliInteractionActive(){return false;}
       function scheduleOtlobliCoordinator(){__fixture.coordinatorSchedules++;}
       ${coordinatorWakeSource}
       function wake(at,visible,readyState){
         __fixture.now=at;__fixture.visible=visible;__fixture.readyState=readyState;
         runOtlobliCoordinator();
       }
       wake(100,true,'complete');
       wake(400,true,'complete');
       wake(700,false,'complete');
       wake(1500,true,'complete');
       wake(1600,false,'complete');
       wake(2799,false,'complete');
       var beforeBoundary={blockers:__fixture.blockers,security:__fixture.security,navigation:__fixture.navigation};
       wake(2800,false,'loading');
       var whileLoading={active:otlobliChallengeActive,resolvedAt:__otlobliChallengeResolvedAt};
       wake(2800,false,'complete');
       var atResolve={active:otlobliChallengeActive,resolvedAt:__otlobliChallengeResolvedAt,blockers:__fixture.blockers,security:__fixture.security};
       wake(3399,false,'complete');
       var beforeSettlement={resumes:__fixture.resumes,privacyResumes:__fixture.privacyResumes,blockers:__fixture.blockers,security:__fixture.security};
       wake(3400,false,'complete');
       var atSettlement={resumes:__fixture.resumes,privacyResumes:__fixture.privacyResumes,blockers:__fixture.blockers,security:__fixture.security,mainDue:otlobliMainDue};
       wake(3440,false,'complete');
       var afterReassessment={ticks:__fixture.normalTicks,args:__fixture.tickArguments.slice(),blockers:__fixture.blockers,security:__fixture.security};
       wake(3700,false,'complete');
       ({beforeBoundary:beforeBoundary,whileLoading:whileLoading,atResolve:atResolve,
         beforeSettlement:beforeSettlement,atSettlement:atSettlement,
         afterReassessment:afterReassessment,afterRelease:{blockers:__fixture.blockers,security:__fixture.security,navigation:__fixture.navigation},
         active:otlobliChallengeActive,resolvedAt:__otlobliChallengeResolvedAt});`,
      {
        __fixture: challengeLifecycleFixture,
        window: {
          __otlobliDocumentGeneration: 'doc-1',
          __otlobliSheinPolicyEngine: {
            pause: () => { challengeLifecycleFixture.pauses++ },
            resume: () => {
              challengeLifecycleFixture.resumes++
              challengeLifecycleFixture.resumeOrder.push('policy')
            },
          },
          __otlobliSheinPrivacyCompat: {
            resume: () => {
              challengeLifecycleFixture.privacyResumes++
              challengeLifecycleFixture.resumeOrder.push('privacy')
            },
          },
          mobileApp: {
            postMessage: (message) => challengeLifecycleFixture.messages.push(
              `${message?.detail?.type ?? ''}:${message?.detail?.documentGeneration ?? ''}`,
            ),
          },
        },
        document: {
          hidden: false,
          body: {},
          get readyState() { return challengeLifecycleFixture.readyState },
        },
        Date: { now: () => challengeLifecycleFixture.now },
        otlobliScriptEnabled: () => true,
        otlobliScheduleChallengeNav: () => { challengeLifecycleFixture.schedules++ },
        Math, String, Infinity,
      },
    )
    const protectedPassesStayedZero = [
      challengeLifecycle.beforeBoundary,
      challengeLifecycle.atResolve,
      challengeLifecycle.beforeSettlement,
      challengeLifecycle.atSettlement,
    ].every((sample) => sample.blockers === 0 && sample.security === 0 && (sample.navigation ?? 0) === 0)
    if (!protectedPassesStayedZero ||
        challengeLifecycle.whileLoading.active !== true || challengeLifecycle.whileLoading.resolvedAt !== 0 ||
        challengeLifecycle.atResolve.active !== false || challengeLifecycle.atResolve.resolvedAt !== 2800 ||
        challengeLifecycle.beforeSettlement.resumes !== 0 || challengeLifecycle.beforeSettlement.privacyResumes !== 0 ||
        challengeLifecycle.atSettlement.resumes !== 1 || challengeLifecycle.atSettlement.privacyResumes !== 1 ||
        challengeLifecycle.atSettlement.mainDue !== 0 ||
        challengeLifecycle.afterReassessment.ticks !== 1 ||
        challengeLifecycle.afterReassessment.args.join(',') !== 'true' ||
        challengeLifecycle.afterReassessment.blockers !== 0 || challengeLifecycle.afterReassessment.security !== 0 ||
        challengeLifecycle.afterRelease.blockers !== 1 || challengeLifecycle.afterRelease.security !== 1 ||
        challengeLifecycle.afterRelease.navigation !== 0 ||
        challengeLifecycle.active !== false || challengeLifecycle.resolvedAt !== 0 ||
        challengeLifecycleFixture.pauses !== 1 || challengeLifecycleFixture.resumes !== 1 ||
        challengeLifecycleFixture.privacyResumes !== 1 || challengeLifecycleFixture.resumeOrder.join(',') !== 'policy,privacy' ||
        challengeLifecycleFixture.schedules !== 1 ||
        challengeLifecycleFixture.messages.join(',') !== 'otlobliBackButtonState:,humanCheck:doc-1,humanCheckResolved:doc-1') {
      failures.push(`SHEIN human check: 1200ms absence/600ms settlement is not coordinator-exclusive (${JSON.stringify({
        lifecycle: challengeLifecycle,
        fixture: challengeLifecycleFixture,
      })})`)
    }

    const nativeTemuCadenceFixture = { now: 100, guards: 0, ticks: 0, blockers: 0, navigation: 0, security: 0, schedules: 0 }
    const nativeTemuCadence = runInNewContext(
      `var IS_SHEIN=false,IS_TEMU=true,OTLOBLI_NATIVE_NAV=true;
       var OTLOBLI_MAIN_INTERVAL=300,OTLOBLI_BLOCK_INTERVAL=120,OTLOBLI_NAV_INTERVAL=1200,OTLOBLI_SECURITY_INTERVAL=1000;
       var otlobliChallengeActive=false,__otlobliChallengeResolvedAt=0;
       var otlobliMainDue=0,otlobliBlockDue=Infinity,otlobliNavDue=Infinity,otlobliSecurityDue=Infinity;
       function otlobliGuardHumanChallenge(){__fixture.guards++;return false;}
       function tick(challengeAlreadyGuarded){if(challengeAlreadyGuarded)__fixture.ticks++;}
       function runOtlobliBlockers(){__fixture.blockers++;}
       function runOtlobliNavigationMaintenance(){__fixture.navigation++;}
       function checkForSheinSecurityBlock(){__fixture.security++;}
       function otlobliScriptEnabled(){return true;}
       function otlobliInteractionActive(){return false;}
       function scheduleOtlobliCoordinator(){__fixture.schedules++;}
       ${coordinatorWakeSource}
       runOtlobliCoordinator();
       __fixture.now=200;runOtlobliCoordinator();
       __fixture.now=400;runOtlobliCoordinator();
       ({mainDue:otlobliMainDue,blockDue:otlobliBlockDue,navDue:otlobliNavDue,securityDue:otlobliSecurityDue});`,
      {
        __fixture: nativeTemuCadenceFixture,
        window: {},
        document: { hidden: false },
        Date: { now: () => nativeTemuCadenceFixture.now },
        Infinity,
      },
    )
    const nativeNavDueAssignments = captureScript.match(
      /otlobliNavDue\s*=\s*OTLOBLI_NATIVE_NAV\s*\?\s*Infinity\s*:\s*(?:0|now\s*\+\s*OTLOBLI_NAV_INTERVAL)/g,
    ) ?? []
    if (nativeNavDueAssignments.length < 3 ||
        !/var\s+otlobliBlockDue\s*=\s*IS_SHEIN\s*\?\s*0\s*:\s*Infinity/.test(captureScript) ||
        !/var\s+otlobliSecurityDue\s*=\s*IS_SHEIN\s*\?\s*0\s*:\s*Infinity/.test(captureScript) ||
        nativeTemuCadenceFixture.guards !== 3 || nativeTemuCadenceFixture.ticks !== 2 ||
        nativeTemuCadenceFixture.blockers !== 0 || nativeTemuCadenceFixture.navigation !== 0 ||
        nativeTemuCadenceFixture.security !== 0 || nativeTemuCadenceFixture.schedules !== 3 ||
        nativeTemuCadence.blockDue !== Infinity || nativeTemuCadence.navDue !== Infinity ||
        nativeTemuCadence.securityDue !== Infinity) {
      failures.push(`Temu native navigation cadence: native mode still schedules duplicate DOM-nav/block/security passes (${JSON.stringify({
        cadence: nativeTemuCadence,
        fixture: nativeTemuCadenceFixture,
      })})`)
    }
  }

  const temuViewportSource = sourceBetween(
    temuCaptureScript,
    'var __otlobliNoZoomListeners = false;',
    'var OTLOBLI_TEMU_HIDE_CSS',
    'Temu viewport stability fixture',
  )
  if (temuViewportSource) {
    const viewportFixture = {
      content: 'width=device-width, initial-scale=1, viewport-fit=cover',
      contentWrites: 0,
      listeners: 0,
      styleCreates: 0,
      style: null,
    }
    const viewportMeta = {
      getAttribute: (name) => name === 'content' ? viewportFixture.content : '',
      setAttribute: (name, value) => {
        if (name === 'content') {
          viewportFixture.content = value
          viewportFixture.contentWrites++
        }
      },
    }
    const viewportResult = runInNewContext(
      `${temuViewportSource}
       ensureTemuNoZoom();
       ensureTemuNoZoom();
       ({content:__fixture.content,writes:__fixture.contentWrites,listeners:__fixture.listeners,styles:__fixture.styleCreates});`,
      {
        __fixture: viewportFixture,
        document: {
          head: {
            appendChild: (node) => {
              if (node?.id === 'otlobli-temu-stability-style') viewportFixture.style = node
            },
          },
          querySelector: (selector) => selector === 'meta[name="viewport"]' ? viewportMeta : null,
          getElementById: (id) => id === 'otlobli-temu-stability-style' ? viewportFixture.style : null,
          createElement: (tag) => {
            if (tag === 'style') viewportFixture.styleCreates++
            return { id: '', textContent: '', setAttribute() {} }
          },
          addEventListener: () => { viewportFixture.listeners++ },
        },
      },
    )
    const expectedViewport = 'width=device-width, initial-scale=1, viewport-fit=cover'
    if (viewportResult.content !== expectedViewport || viewportResult.writes !== 0 ||
        viewportResult.listeners !== 0 || viewportResult.styles !== 0) {
      failures.push(`Temu native viewport ownership: injected maintenance changed viewport or installed gesture/style work (${JSON.stringify(viewportResult)})`)
    }
  }
  if (humanCheckScript.includes('.click(') || humanCheckScript.includes('location.reload(')) {
    failures.push('SHEIN human check: verification must remain entirely user-controlled')
  }
  if (bootstrapScript.includes('navigationEarlyProtection') ||
      bootstrapScript.includes('function runEarlyProtections()') ||
      bootstrapScript.includes('__OTLOBLI_SCRIPT_FLAGS__')) {
    failures.push('SHEIN early protection: temporary isolation flags or device-rejected document-start scans remain')
  }
  if (typeof captureScript !== 'string' || !captureScript.trim()) {
    failures.push('SHEIN capture-script syntax: emitted script is missing')
  } else {
    new Function(captureScript)
    const backLayerStart = captureScript.indexOf('function otlobliStabilizeBackOverlay')
    const backLayerEnd = captureScript.indexOf('function ensureOtlobliNav', backLayerStart)
    const backLayerHelper = captureScript.slice(backLayerStart, backLayerEnd)
    const nativeBackAvailableAt = captureScript.indexOf('var nativeBackAvailable = window.__otlobliNativeNavigation === true ||')
    const nativeBackStateAt = captureScript.indexOf("type: 'otlobliBackButtonState'")
    const nativeBackReturnAt = captureScript.indexOf('if (stalePageBack) stalePageBack.remove();', nativeBackStateAt)
    const pageBackCreationAt = captureScript.indexOf("var btn = document.getElementById('otlobli-back-btn')", nativeBackReturnAt)
    const backDisplayAt = captureScript.indexOf("btn.style.display = shouldShow ? 'flex' : 'none'", pageBackCreationAt)
    const visibleBackReclaimAt = captureScript.indexOf('if (shouldShow) otlobliStabilizeBackOverlay(btn)', backDisplayAt)
    if (nativeBackAvailableAt < 0 || nativeBackStateAt < nativeBackAvailableAt ||
        nativeBackReturnAt < nativeBackStateAt || pageBackCreationAt < nativeBackReturnAt ||
        backDisplayAt < pageBackCreationAt || visibleBackReclaimAt < backDisplayAt) {
      failures.push('SHEIN Back: iOS must publish native state and return before any page button is created; non-native fallback must still reclaim paint')
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

  if (!bootstrapScript.includes('function otlobliInstallNavTouchBridge()') ||
      !bootstrapScript.includes("window.addEventListener('touchend', routeOtlobliNavTouch")) {
    failures.push('DOM fallback navigation: Otlobli tab routing is missing from the isolated fallback bootstrap')
  }
  const bootstrapNativeGuardAt = bootstrapScript.indexOf('if (window.__otlobliNativeNavigation === true)')
  const bootstrapTouchBridgeAt = bootstrapScript.indexOf('function otlobliInstallNavTouchBridge()')
  const bootstrapDomCreationAt = bootstrapScript.indexOf("document.createElement('div')")
  if (bootstrapNativeGuardAt < 0 || bootstrapTouchBridgeAt < bootstrapNativeGuardAt ||
      bootstrapDomCreationAt < bootstrapNativeGuardAt) {
    failures.push('DOM fallback navigation: native ownership must return before listeners, viewport work or #otlobli-nav creation')
  }
  const forbiddenProductNavigationInterventions = [
    'otlobliInstallIosProductTapFallback',
    'otlobliInstallSheinChunkFailureBridge',
    '__otlobliProductTapAttemptAt',
    'product-tap-route-fallback',
    'location.assign(',
    "type:'sheinChunkLoadFailure'",
  ]
  for (const marker of forbiddenProductNavigationInterventions) {
    if (bootstrapScript.includes(marker)) {
      failures.push(`SHEIN navigation ownership: document-start bootstrap still contains ${marker}`)
    }
  }
} catch (error) {
  failures.push(`SHEIN capture-script syntax: ${error instanceof Error ? error.message : String(error)}`)
}

// Parse the exact minified scripts that production packages. This keeps the
// release hardening inside the established iPhone freeze acceptance gate.
try {
  const { exports } = await minifyInjectedScriptExports('src/services/sheinBrowserScript.ts')
  new Function(exports.SHEIN_CAPTURE_SCRIPT)
  new Function(exports.TEMU_CAPTURE_SCRIPT)
  if (Object.hasOwn(exports, 'OTLOBLI_NAV_BOOTSTRAP_SCRIPT')) {
    failures.push('native navigation ownership: minified production runtime still exports the legacy DOM bootstrap')
  }
  if (Buffer.byteLength(exports.SHEIN_CAPTURE_SCRIPT, 'utf8') > 180_000 ||
      Buffer.byteLength(exports.TEMU_CAPTURE_SCRIPT, 'utf8') > 180_000 ||
      exports.SHEIN_CAPTURE_SCRIPT === exports.TEMU_CAPTURE_SCRIPT) {
    failures.push('store runtime split: each minified store runtime must stay independently dead-code-eliminated')
  }
  for (const [store, script] of [['SHEIN', exports.SHEIN_CAPTURE_SCRIPT], ['Temu', exports.TEMU_CAPTURE_SCRIPT]]) {
    try {
      runInNewContext(script, { location: { hostname: 'external.example' } })
    } catch (error) {
      failures.push(`${store} host boundary: off-domain runtime performed work (${error instanceof Error ? error.message : String(error)})`)
    }
  }
} catch (error) {
  failures.push(`SHEIN minified release scripts: ${error instanceof Error ? error.message : String(error)}`)
}

try {
  const bundleModule = evaluateInjectedScriptExports('src/services/storeCaptureBundle.ts')
  const appSource = readFileSync(resolve(projectRoot, 'src/App.tsx'), 'utf8')
  const bundleSource = readFileSync(resolve(projectRoot, 'src/services/storeCaptureBundle.ts'), 'utf8')
  const browserSource = readFileSync(resolve(projectRoot, 'src/services/sheinBrowserScript.ts'), 'utf8')
  if (Object.hasOwn(bundleModule, 'OTLOBLI_NAV_BOOTSTRAP_SCRIPT') ||
      appSource.includes('OTLOBLI_NAV_BOOTSTRAP_SCRIPT') ||
      bundleSource.includes('OTLOBLI_NAV_BOOTSTRAP_SCRIPT') ||
      browserSource.includes('OTLOBLI_NAV_BOOTSTRAP_SCRIPT')) {
    failures.push('native navigation ownership: App/store capture bundle must not ship the legacy DOM bootstrap')
  }
  const productionScript = bundleModule.buildStoreCaptureScript('shein', {})
  const productionTemuScript = bundleModule.buildStoreCaptureScript('temu', {})
  new Function(productionScript)
  new Function(productionTemuScript)
  const forbiddenReleaseMarkers = [
    'otlobli-script-diagnostics',
    '__otlobliTapDiagnosticContext',
    '__otlobliFreezeProbe',
    'storeScriptFlagsChanged',
    'storeDiagnosticState',
    'OTLOBLI FLIGHT RECORDER',
    '__OTLOBLI_SHEIN_REGION_DIAGNOSTICS__',
  ]
  for (const marker of forbiddenReleaseMarkers) {
    if (productionScript.includes(marker)) {
      failures.push(`SHEIN production script: diagnostic marker ${marker} must not ship`)
    }
  }
  if (!productionScript.includes('__otlobliSheinPrivacyCompatInstalled')) {
    failures.push('SHEIN privacy compatibility: customer injection must include the touch-shield fix')
  }
  if (productionTemuScript.includes(bundleModule.SHEIN_PRIVACY_COMPAT_SCRIPT) ||
      productionTemuScript.includes(bundleModule.SHEIN_POLICY_DOCUMENT_START_SCRIPT)) {
    failures.push('store runtime split: Temu must not parse SHEIN privacy/policy code')
  }
  if (!productionScript.includes('__otlobliSheinPolicyEngine')) {
    failures.push('SHEIN policy fallback: post-load customer injection must restore the final document policy')
  }
  if (!productionScript.includes('otlobli-region-switching') || !productionScript.includes('.sui-drawer.cascade')) {
    failures.push('SHEIN signed-region repair: policy must permit only the active internal cascade drawer')
  }
  if (!productionScript.includes('function tick(')) {
    failures.push('SHEIN production script: established runtime coordinator must remain installed')
  }
} catch (error) {
  failures.push(`SHEIN production script syntax: ${error instanceof Error ? error.message : String(error)}`)
}

try {
  const appSource = readFileSync(resolve(projectRoot, 'src/App.tsx'), 'utf8')
  const bundleSource = readFileSync(resolve(projectRoot, 'src/services/storeCaptureBundle.ts'), 'utf8')
  const resolvedStart = appSource.indexOf("if (detail?.type === 'humanCheckResolved')")
  const resolvedEnd = appSource.indexOf("if (detail?.type === 'humanCheckSkipped')", resolvedStart)
  const resolvedSource = appSource.slice(resolvedStart, resolvedEnd)
  const resolvedForbidden = [
    "pendingProductUrlRef.current = ''",
    'markStoreWebviewReadyRef.current',
    'navigateStoreWebviewInPage',
    'revealPreparedProductIfReady',
    'clearPendingProductPreparation',
  ]
  if (resolvedStart < 0 || resolvedEnd < 0 ||
      !resolvedSource.includes("transitionSheinCoordinator({ type: 'HUMAN_VERIFICATION_RESOLVED' })") ||
      !resolvedSource.includes('resolvedDocumentGeneration') ||
      !resolvedSource.includes('sheinChallengeResolutionReportedRef.current = true') ||
      !/return\s*\r?\n\s*}/.test(resolvedSource) ||
      resolvedForbidden.some((marker) => resolvedSource.includes(marker))) {
    failures.push('SHEIN host challenge: humanCheckResolved must be status-only and must not consume/navigate/clear a queued product')
  }

  const snapshotBranchStart = appSource.indexOf("if (detail?.type === 'sheinSaudiReady' || detail?.type === 'sheinPageInteractive'")
  const snapshotBranchEnd = appSource.indexOf("if (detail?.type === 'humanCheck')", snapshotBranchStart)
  const snapshotBranch = appSource.slice(snapshotBranchStart, snapshotBranchEnd)
  for (const marker of [
    'snapshotDocumentGeneration',
    '!hasCoordinatorSnapshot',
    '!snapshotDocumentGeneration',
    "snapshot.captureState !== 'ready'",
    "snapshot.humanVerificationState !== 'none'",
    "snapshot.humanVerificationState !== 'resolved'",
    'sheinChallengeDocumentGenerationRef.current',
    'sheinChallengeResolutionReportedRef.current',
  ]) {
    if (snapshotBranchStart < 0 || snapshotBranchEnd < 0 || !snapshotBranch.includes(marker)) {
      failures.push(`SHEIN host challenge: coordinator hand-off is missing document-scoped gate ${marker}`)
    }
  }

  const optionsStart = appSource.indexOf('const webViewOptions: Parameters<typeof InAppBrowser.openWebView>')
  const storeBranchStart = appSource.indexOf("...(activeStore === 'shein'", optionsStart)
  const optionsEnd = appSource.indexOf('InAppBrowser.openWebView(webViewOptions)', storeBranchStart)
  const commonOptions = appSource.slice(optionsStart, storeBranchStart)
  const completeOptions = appSource.slice(optionsStart, optionsEnd)
  if (optionsStart < 0 || storeBranchStart < 0 || optionsEnd < 0 ||
      !commonOptions.includes('otlobliNativeNavigation: true') ||
      !commonOptions.includes('invisibilityMode: InvisibilityMode.FAKE_VISIBLE') ||
      !completeOptions.includes('enabledSafeBottomMargin: false') ||
      completeOptions.includes('InvisibilityMode.AWARE')) {
    failures.push('Store WebView options: SHEIN and Temu must both inherit native navigation and FAKE_VISIBLE without a safe-bottom duplicate')
  }
  for (const [source, label] of [[appSource, 'App'], [bundleSource, 'storeCaptureBundle']]) {
    if (!source.includes('__otlobliDocumentGeneration=window.__otlobliDocumentGeneration||')) {
      failures.push(`SHEIN document generation: ${label} does not seed a stable per-document identity`)
    }
  }
} catch (error) {
  failures.push(`SHEIN host challenge contract: ${error instanceof Error ? error.message : String(error)}`)
}

// Exercise the compatibility prelude against the exact failure shape found by
// USB/browser diagnostics: a fixed, full-viewport SHEIN privacy layer whose
// action is a styled div. Prove both exact Accept all labels resume after a
// challenge, then prove Reject all is not activated and the iOS-only fallback
// releases the confirmed unresponsive shield.
try {
  const { SHEIN_PRIVACY_COMPAT_SCRIPT } = evaluateInjectedScriptExports(
    'src/services/sheinPrivacyCompatScript.ts',
  )

  const runPrivacyFixture = ({ controlLabel, wakeWith }) => {
    const attributes = new Map()
    const controlAttributes = new Map()
    const appliedStyles = new Map()
    const messages = []
    const scheduled = []
    const globalListeners = new Map()
    let shieldVisible = true
    let challengeVisible = true
    let controlClicks = 0
    let now = 0
    const control = {
      nodeType: 1,
      tagName: 'DIV',
      value: '',
      textContent: controlLabel || '',
      getAttribute(name) { return name === 'aria-label' ? '' : null },
      setAttribute(name, value) { controlAttributes.set(name, value) },
      click() { controlClicks++; shieldVisible = false },
      dispatchEvent() {},
    }
    const shield = {
      style: { setProperty(name, value) { appliedStyles.set(name, value) } },
      getAttribute(name) { return attributes.get(name) || null },
      setAttribute(name, value) { attributes.set(name, value) },
      getBoundingClientRect() { return { left: 0, top: 0, width: 430, height: 932 } },
      querySelectorAll() { return controlLabel ? [control] : [] },
    }
    const challengeNode = {
      getBoundingClientRect() { return { left: 20, top: 40, width: 390, height: 700 } },
    }
    const documentFixture = {
      documentElement: { clientWidth: 430, clientHeight: 932 },
      visibilityState: 'visible',
      querySelectorAll(selector) {
        if (selector.includes('#challenge-form')) return challengeVisible ? [challengeNode] : []
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
        return { display: 'flex', visibility: 'visible', pointerEvents: 'auto', position: 'fixed', opacity: '1' }
      },
      mobileApp: { postMessage(message) { messages.push(message) } },
    }
    windowFixture.top = windowFixture
    const DateFixture = { now() { now += 400; return now } }
    const setTimeoutFixture = (callback, delay) => {
      scheduled.push({ callback, delay })
      return scheduled.length
    }
    const addEventListenerFixture = (name, callback) => {
      globalListeners.set(name, callback)
    }
    new Function(
      'window', 'document', 'location', 'setTimeout', 'addEventListener', 'MouseEvent', 'Date',
      SHEIN_PRIVACY_COMPAT_SCRIPT,
    )(
      windowFixture,
      documentFixture,
      { hostname: 'm.shein.com', pathname: '/ar/', search: '', hash: '' },
      setTimeoutFixture,
      addEventListenerFixture,
      function MouseEvent() {},
      DateFixture,
    )
    let scheduledIndex = 0
    const drainScheduled = () => {
      let passes = 0
      while (scheduledIndex < scheduled.length && passes < 40) {
        scheduled[scheduledIndex++].callback()
        passes++
      }
      return passes
    }
    drainScheduled()
    challengeVisible = false
    if (wakeWith === 'event') globalListeners.get('privacyCookieAgreementShow')?.()
    else windowFixture.__otlobliSheinPrivacyCompat?.resume()
    drainScheduled()
    return {
      appliedStyles,
      attributes,
      controlAttributes,
      messages,
      controlClicks,
      controlTag: control.tagName,
      scheduledCount: scheduled.length,
      hasResume: typeof windowFixture.__otlobliSheinPrivacyCompat?.resume === 'function',
      hasPrivacyEvent: typeof globalListeners.get('privacyCookieAgreementShow') === 'function',
    }
  }

  const acceptFixture = runPrivacyFixture({ controlLabel: 'Accept all', wakeWith: 'resume' })
  const arabicAcceptFixture = runPrivacyFixture({ controlLabel: 'قبول الكل', wakeWith: 'event' })
  for (const [label, fixture] of [['Accept all', acceptFixture], ['قبول الكل', arabicAcceptFixture]]) {
    if (fixture.controlClicks !== 1 ||
        fixture.controlTag !== 'DIV' ||
        fixture.controlAttributes.get('data-otlobli-privacy-action') !== 'accept-all' ||
        !fixture.messages.some((message) => message?.detail?.method === 'accept-all') ||
        fixture.appliedStyles.has('display') || !fixture.hasResume || !fixture.hasPrivacyEvent ||
        fixture.scheduledCount !== 18) {
      failures.push(`SHEIN privacy compatibility: exact styled ${label} must run one bounded post-challenge burst`)
    }
  }

  const fallbackFixture = runPrivacyFixture({ controlLabel: 'Reject all', wakeWith: 'resume' })
  if (fallbackFixture.appliedStyles.get('pointer-events') !== 'none' ||
      fallbackFixture.appliedStyles.get('display') !== 'none' ||
      fallbackFixture.attributes.get('data-otlobli-privacy-neutralized') !== '1' ||
      fallbackFixture.controlClicks !== 0 ||
      !fallbackFixture.messages.some((message) => message?.detail?.method === 'ios-invisible-shield-neutralized')) {
    failures.push('SHEIN privacy compatibility: Reject all must stay untouched while confirmed iOS fallback releases the shield')
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
  const createSurfaceStart = nativeBrowserSource.indexOf('private func createRenderSurface(')
  const createSurfaceEnd = nativeBrowserSource.indexOf('private func destroyRenderSurface()', createSurfaceStart)
  const createSurfaceSource = nativeBrowserSource.slice(createSurfaceStart, createSurfaceEnd)
  const installNavigationAt = createSurfaceSource.indexOf('installNativeNavigation(in: surface)')
  const attachWebViewAt = createSurfaceSource.indexOf('attachWebView(webView, to: surface)')
  const installCoverAt = createSurfaceSource.indexOf('installLoadingCover(in: surface')
  if (createSurfaceStart < 0 || createSurfaceEnd < 0 || installNavigationAt < 0 ||
      attachWebViewAt < installNavigationAt || installCoverAt < attachWebViewAt) {
    failures.push('dedicated iOS native navigation: surface must own the permanent bar before constraining WebView and loading cover above it')
  }
  const loadingCoverStart = nativeBrowserSource.indexOf('private func installLoadingCover(')
  const loadingCoverEnd = nativeBrowserSource.indexOf('private func hideLoadingCover()', loadingCoverStart)
  const loadingCoverSource = nativeBrowserSource.slice(loadingCoverStart, loadingCoverEnd)
  if (loadingCoverStart < 0 || loadingCoverEnd < 0 ||
      !loadingCoverSource.includes('cover.bottomAnchor.constraint(equalTo: coverBottomAnchor)') ||
      loadingCoverSource.includes('makeNativeNavigation') ||
      loadingCoverSource.includes('cover.addSubview(navigation)')) {
    failures.push('dedicated iOS native navigation: loading cover must stop at the bar and must not own a duplicate bar')
  }
  const ownershipStart = nativeBrowserSource.indexOf('private func nativeNavigationOwnershipScript()')
  const ownershipEnd = nativeBrowserSource.indexOf('private func shouldReleaseLoadingCover(', ownershipStart)
  const ownershipSource = nativeBrowserSource.slice(ownershipStart, ownershipEnd)
  if (ownershipStart < 0 || ownershipEnd < 0 ||
      !ownershipSource.includes('window.__otlobliNativeNavigation=true;') ||
      ['MutationObserver', 'setTimeout(', 'setInterval(', 'observer.observe('].some((marker) => ownershipSource.includes(marker))) {
    failures.push('dedicated iOS native navigation: document-start ownership must not run a DOM observer or maintenance timer')
  }
  const nativeBackStart = nativeBrowserSource.indexOf('@objc private func nativeBackPressed()')
  const nativeBackEnd = nativeBrowserSource.indexOf('private func mobileBridgeScript()', nativeBackStart)
  const nativeBackSource = nativeBrowserSource.slice(nativeBackStart, nativeBackEnd)
  const cartDecision = nativeBackSource.indexOf('if nativeBackTarget == "cart"')
  const rootDecision = nativeBackSource.indexOf('if isCanonicalSheinHomeURL(webView.url)')
  const historyDecision = nativeBackSource.indexOf('if webView.canGoBack')
  if (nativeBackStart < 0 || nativeBackEnd < 0 || cartDecision < 0 || rootDecision < cartDecision ||
      historyDecision < rootDecision || !nativeBackSource.includes('lockNativeBackBriefly()')) {
    failures.push('SHEIN native back: cart must stay first and canonical Home must exit before WebKit history')
  }

  const observedRouteStart = nativeBrowserSource.indexOf('private func observeStoreURL(on webView: WKWebView)')
  const observedRouteEnd = nativeBrowserSource.indexOf('private func attachWebView(', observedRouteStart)
  const observedRouteSource = nativeBrowserSource.slice(observedRouteStart, observedRouteEnd)
  const recoveryStart = nativeBrowserSource.indexOf('private func recoverFromBlockedSheinRoute(')
  const recoveryEnd = nativeBrowserSource.indexOf('private func isOutboundFromBlockedSheinRoute(', recoveryStart)
  const recoverySource = nativeBrowserSource.slice(recoveryStart, recoveryEnd)
  if (observedRouteStart < 0 || observedRouteEnd < 0 || recoveryStart < 0 || recoveryEnd < 0 ||
      !observedRouteSource.includes('if self.isBlockedRoute(route)') ||
      observedRouteSource.indexOf('self.recoverFromBlockedSheinRoute(') > observedRouteSource.indexOf('self.savedURL = changedURL') ||
      !recoverySource.includes('if webView.canGoBack') ||
      !recoverySource.includes('webView.goBack()') ||
      !recoverySource.includes('DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)') ||
      !recoverySource.includes('self.isBlockedRoute(self.classifySheinRoute(currentURL))') ||
      !recoverySource.includes('https://m.shein.com/ar/') ||
      ['MutationObserver', 'setInterval(', 'location.reload('].some((marker) => recoverySource.includes(marker))) {
    failures.push('SHEIN iOS SPA auth route: the existing URL observer must leave blocked login once without persisting it or adding recurring work')
  }

  const popupSignature = nativeBrowserSource.indexOf('createWebViewWith configuration:')
  const popupStart = nativeBrowserSource.lastIndexOf('public func webView(', popupSignature)
  const popupEnd = nativeBrowserSource.indexOf('decidePolicyFor navigationAction:', popupSignature)
  const popupSource = nativeBrowserSource.slice(popupStart, popupEnd)
  const popupBlockedGuard = popupSource.indexOf('isBlockedRoute(classifySheinRoute(source))')
  const popupExternalOpen = popupSource.indexOf('UIApplication.shared.open(url)')
  if (popupStart < 0 || popupEnd < 0 || popupBlockedGuard < 0 || popupExternalOpen < 0 ||
      popupBlockedGuard > popupExternalOpen || !popupSource.includes('recoverFromBlockedSheinRoute(')) {
    failures.push('SHEIN iOS SPA auth route: every popup from the blocked login page must be cancelled before any external application can open')
  }

  const outboundStart = nativeBrowserSource.indexOf('private func isOutboundFromBlockedSheinRoute(')
  const outboundEnd = nativeBrowserSource.indexOf('private func emit(', outboundStart)
  const outboundSource = nativeBrowserSource.slice(outboundStart, outboundEnd)
  if (outboundStart < 0 || outboundEnd < 0 ||
      !outboundSource.includes('isBlockedRoute(classifySheinRoute(source))') ||
      !outboundSource.includes('destinationRoute == .external || destinationRoute == .unknown') ||
      (nativeBrowserSource.match(/isOutboundFromBlockedSheinRoute\(url, in: webView\)/g)?.length ?? 0) !== 2) {
    failures.push('SHEIN iOS SPA auth route: Google/Facebook outbound navigation is not fail-closed while the blocked page is being left')
  }
} catch (error) {
  failures.push(`dedicated iOS SHEIN browser structure: ${error instanceof Error ? error.message : String(error)}`)
}

try {
  const androidBrowserSources = [
    readFileSync(resolve(projectRoot, 'node_modules/@capgo/capacitor-inappbrowser/android/src/main/java/ee/forgr/capacitor_inappbrowser/WebViewDialog.java'), 'utf8'),
    capgoPatchAdded,
  ]
  for (const [index, source] of androidBrowserSources.entries()) {
    const label = index === 0 ? 'applied source' : 'persistent patch'
    const recoveryStart = source.indexOf('private boolean otlobliRecoverBlockedSheinHistoryRoute(')
    const recoveryEnd = source.indexOf('private boolean otlobliIsOutboundFromBlockedSheinRoute(', recoveryStart)
    const recoverySource = source.slice(recoveryStart, recoveryEnd)
    if (recoveryStart < 0 || recoveryEnd < 0 ||
        !recoverySource.includes('otlobliIsBlockedSheinRoute(routeClass)') ||
        !recoverySource.includes('if (view.canGoBack())') ||
        !recoverySource.includes('view.goBack();') ||
        !recoverySource.includes('view.postDelayed(() ->') ||
        !recoverySource.includes('String currentUrl = view.getUrl();') ||
        !recoverySource.includes('otlobliIsBlockedSheinRoute(otlobliClassifySheinRoute(currentUrl))') ||
        !recoverySource.includes('}, 200L);') ||
        !recoverySource.includes('view.loadUrl("https://m.shein.com/ar/");') ||
        ['MutationObserver', 'setInterval(', 'reload('].some((marker) => recoverySource.includes(marker)) ||
        !source.includes('if (otlobliRecoverBlockedSheinHistoryRoute(view, url))') ||
        !source.includes('if (otlobliIsOutboundFromBlockedSheinRoute(url))')) {
      failures.push(`SHEIN Android SPA auth route (${label}): visited-history recovery or outbound fail-closed guard is missing`)
    }

    const popupVerificationSource = index === 0 ? source : capgoPatchSource
    const popupStart = index === 0
      ? popupVerificationSource.indexOf('public boolean onCreateWindow(WebView view, boolean isDialog, boolean isUserGesture, android.os.Message resultMsg)')
      : popupVerificationSource.indexOf('String sourceUrl = view != null ? view.getUrl() : null;')
    const popupAnchor = popupVerificationSource.indexOf('WebView.HitTestResult result = view.getHitTestResult();', popupStart)
    const popupSource = popupVerificationSource.slice(popupStart, index === 0
      ? popupVerificationSource.indexOf('public void onCloseWindow(', popupStart)
      : popupAnchor + 'WebView.HitTestResult result = view.getHitTestResult();'.length)
    const popupRecovery = popupSource.indexOf('otlobliRecoverBlockedSheinHistoryRoute(view, sourceUrl)')
    if (popupStart < 0 || popupAnchor < 0 || popupRecovery < 0 || popupRecovery > popupSource.indexOf('WebView.HitTestResult result')) {
      failures.push(`SHEIN Android SPA auth route (${label}): blocked login popups are not cancelled before target=_blank handling`)
    } else if (index === 0) {
      for (const outboundMarker of [
        'shouldLoadBlankTargetInCurrentWebView(data)',
        'permissionHandler.createManagedPopupWindow',
        'Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(data))',
      ]) {
        const outboundIndex = popupSource.indexOf(outboundMarker)
        if (outboundIndex < 0 || popupRecovery > outboundIndex) {
          failures.push(`SHEIN Android SPA auth route (${label}): popup recovery must precede ${outboundMarker}`)
        }
      }
    }
  }
} catch (error) {
  failures.push(`SHEIN Android SPA auth route guard: ${error instanceof Error ? error.message : String(error)}`)
}

try {
  const sheinSource = readSheinRuntimeSource()
  const tickStart = sheinSource.indexOf('function tick(')
  const tickEnd = sheinSource.indexOf('var tickScheduled = false', tickStart)
  const tickSource = sheinSource.slice(tickStart, tickEnd)
  const sheinBranchStart = tickSource.indexOf('ensureLoadingOverlay();')
  const sheinBranch = tickSource.slice(sheinBranchStart)
  const toastGuard = sheinBranch.indexOf('hideSheinCartSuccessToast();')
  const addButton = sheinBranch.search(/ensureAddToCartButton\([^)]*\);/)
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
  const cartOpenStart = appSource.indexOf('const openStoreProductFromCart = (sourceLink: string,')
  const cartOpenEnd = appSource.indexOf("InAppBrowser.addListener('closeEvent'", cartOpenStart)
  const cartOpenSource = appSource.slice(cartOpenStart, cartOpenEnd)
  const warmReuse = cartOpenSource.indexOf('sameSheinProductNavigation(targetUrl, currentWebviewUrlRef.current)')
  const sameSessionNavigate = cartOpenSource.indexOf('navigateStoreWebviewInPage(targetUrl)')
  if (cartOpenStart < 0 || cartOpenEnd < 0 || warmReuse < 0 || sameSessionNavigate < 0 ||
      cartOpenSource.includes('openIosSheinCartProductInFreshSession') ||
      cartOpenSource.includes('InAppBrowser.setUrl({ url: targetUrl })') ||
      cartOpenSource.includes('InAppBrowser.close(')) {
    failures.push('SHEIN persistent session: cart/order product must reuse the verified in-page WebContent context')
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
  const readyGuard = homeVisibilitySource.indexOf('if (!sheinVisualReadyRef.current &&')
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
      !closeStoreSource.includes("recordAppDiagnostic('store_session_parked_for_chooser', { store: 'temu' })") ||
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
  const enterHome = hubOpenSource.indexOf('navigateToStoreSurface()')
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

  const isCapgoPatchCheck = files.length === 1 && files[0] === capgoPatchFile
  const markerContents = isCapgoPatchCheck ? capgoPatchAdded : contents
  const forbiddenContents = isCapgoPatchCheck ? capgoPatchAdded : contents
  for (const marker of check.markers) {
    if (!markerContents.includes(marker)) {
      failures.push(`${check.label}: missing ${JSON.stringify(marker)} in ${files.join(', ')}`)
    }
  }
  for (const marker of check.removedMarkers || []) {
    if (!capgoPatchRemoved.includes(marker)) {
      failures.push(`${check.label}: missing removed ${JSON.stringify(marker)} in ${files.join(', ')}`)
    }
  }
  for (const forbidden of check.forbidden || []) {
    if (forbiddenContents.includes(forbidden)) {
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
