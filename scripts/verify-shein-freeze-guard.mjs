import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { runInNewContext } from 'node:vm'
import ts from 'typescript'
import { stripInjectedComments } from './strip-injected-comments.mjs'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')

const checks = [
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
    ],
  },
  {
    label: 'diagnostic iPhone trace mode',
    file: 'src/App.tsx',
    markers: [
      'SHEIN_IOS_FREEZE_DIAGNOSTICS',
      'SHEIN_IOS_FREEZE_DIAGNOSTICS_BYPASS_RECOVERY',
      'otlobliFreezeDiagnostics: SHEIN_IOS_FREEZE_DIAGNOSTICS && isIosNative',
      'otlobliFreezeDiagnosticsBypassRecovery:',
      'otlobliLoadingCover: true',
      'SHEIN_FREEZE_DIAGNOSTIC_SCRIPT',
    ],
  },
  {
    label: 'normal-release diagnostics disabled',
    file: 'src/config.ts',
    markers: [
      'export const SHEIN_IOS_FREEZE_DIAGNOSTICS = false',
    ],
  },
  {
    label: 'customer tap diagnostics disabled',
    file: 'src/App.tsx',
    markers: [
      'otlobliTapDiagnostics: false',
    ],
  },
  {
    label: 'stable iPhone first-frame navigation inset',
    file: 'src/services/sheinBrowserScript.ts',
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
    ],
  },
  {
    label: 'SHEIN quick-add cart-link guard',
    file: 'src/services/sheinBrowserScript.ts',
    markers: [
      'function sheinQuickAddProductLink(root,info)',
      "var suffix='-p-'+id+'.html'",
      "'/ar/product-p-'+id+'.html'",
    ],
    forbidden: ["location.origin + '/ar/-p-' + info.goods_id + '.html'"],
  },
  {
    label: 'iPhone resumed product-tap fallback',
    file: 'src/services/sheinBrowserScript.ts',
    markers: [
      'const OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS',
      "d('product-tap-start'+(r?'-href':''))",
      "d('product-tap-fallback')",
      "d('product-tap-route-fallback')",
      "window.__otlobliProductTapAttemptAt=Date.now()",
      "window.__otlobliRecoverSheinChunkOnStalledTap(n[5])",
      'location.assign(n[5])',
    ],
  },
  {
    label: 'SHEIN confirmed chunk-failure recovery',
    file: 'src/services/sheinBrowserScript.ts',
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
    file: 'src/services/sheinBrowserScript.ts',
    markers: [
      'function sheinViewerHasVisibleCounter(el, vp)',
      '!sheinViewerHasVisibleCounter(el, vp)',
      '/review|rating|comment|feedback|',
    ],
  },
  {
    label: 'iPhone 6 SHEIN cart-toast entry guard',
    file: 'src/services/sheinBrowserScript.ts',
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
    file: 'src/services/sheinBrowserScript.ts',
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
    file: 'src/services/sheinBrowserScript.ts',
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
    file: 'src/services/sheinBrowserScript.ts',
    markers: [
      'if (homeLike) return loadedImageCount >= 2 && (interactiveCount >= 1 || bodyText.length >= 500);',
    ],
  },
  {
    label: 'SHEIN document-start native product-add concealment',
    file: 'src/services/sheinBrowserScript.ts',
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
    file: 'src/services/sheinBrowserScript.ts',
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
    label: 'iOS SHEIN cart-product fresh-session isolation',
    file: 'src/App.tsx',
    markers: [
      'const openIosSheinCartProductInFreshSession = (targetUrl: string)',
      'InAppBrowser.close(closingWebviewId ? { id: closingWebviewId } : undefined)',
      'sheinCacheResetPendingRef.current = true',
      'beginPendingProductPreparation(targetUrl)',
      'openIosSheinCartProductInFreshSession(targetUrl)',
    ],
  },
  {
    label: 'SHEIN scroll/navigation interaction guard',
    file: 'src/services/sheinBrowserScript.ts',
    markers: [
      'function sheinRestoreNavAfterShipping()',
      'function sheinLooksLikeProductRouteForShipping()',
      'function sheinRegionTransitionVeil(show)',
      'function sheinPrimeRegionRepairFromRoute()',
      'function sheinRegionDiag(stage, data, key)',
      "sheinRegionDiag('capture-script-injected'",
      "sheinRegionDiag('shipping-entry-control'",
      "sheinRegionDiag('region-veil-state'",
      '__otlobliRegionBootstrapReload:',
      'if (IS_SHEIN) sheinPrimeRegionRepairFromRoute();',
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
    file: 'src/services/sheinBrowserScript.ts',
    markers: [
      // A 2-core device gains nothing from observing every childList change
      // when scheduleTick() returns immediately there.
      'if (OTLOBLI_LOW_END) return true;',
      // Skip geometry on already-hidden nodes: a rect read after a style write
      // forces one synchronous layout per iteration (layout thrashing).
      "if (el.style.visibility === 'hidden') continue;",
      "if (!el || el.style && el.style.display === 'none') return;",
      // The interval itself stays at the v86.117 value, and both add-hiders
      // still run on every pass - the speedup is inside them, not around them.
      'hideListingCardAddButtons();\n    hideSheinNativeProductAdd();\n  }, OTLOBLI_LOW_END ? 650 : 120);',
    ],
    forbidden: [
      'OTLOBLI_VERY_LOW_END',
    ],
  },
]

const failures = []

// SHEIN_CAPTURE_SCRIPT is a TypeScript template literal, so TypeScript/Vite
// validate the host file but do not parse the JavaScript eventually injected
// into the remote store page. A single missing escape can otherwise make the
// entire capture script fail before it mounts the Otlobli blockers and nav.
// Transpile just this source with inert imports, then parse the emitted string
// exactly as the WebView will receive it.
try {
  // Parse the STRIPPED source: the build removes whole-line comments from this
  // module before injecting it, so the stripped text is what the WebView
  // actually receives. Validating the raw source instead would let a stripping
  // mistake reach a real device unnoticed.
  const source = stripInjectedComments(
    readFileSync(resolve(projectRoot, 'src/services/sheinBrowserScript.ts'), 'utf8'),
  )
  const output = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText + '\nexports.__tapFallback=OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS;exports.__chunkBridge=OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS;'
  const scriptModule = { exports: {} }
  new Function('exports', 'require', 'module', output)(scriptModule.exports, () => ({}), scriptModule)
  const captureScript = scriptModule.exports.SHEIN_CAPTURE_SCRIPT
  const bootstrapScript = scriptModule.exports.OTLOBLI_NAV_BOOTSTRAP_SCRIPT
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
  const anchor = {
    tagName: 'A', parentElement: null, isConnected: true,
    href: 'https://m.shein.com/ar/item-p-123.html',
    getAttribute: (name) => name === 'href' ? '/ar/item-p-123.html' : '',
    click: () => undefined, querySelector: () => null,
  }
  const location = { href: 'https://m.shein.com/ar/', assign: (url) => assigned.push(url) }
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
  if (recoveryCalls !== 0) failures.push('SHEIN product tap fallback: direct product anchor caused an unnecessary recovery')
} catch (error) {
  failures.push(`SHEIN capture-script syntax: ${error instanceof Error ? error.message : String(error)}`)
}

try {
  const sheinSource = readFileSync(resolve(projectRoot, 'src/services/sheinBrowserScript.ts'), 'utf8')
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

// The cart regression is specifically caused by navigating an already-used
// iOS SHEIN WebView. Keep the iOS branch ahead of every warm-session shortcut
// and setUrl path so a future refactor cannot silently reintroduce it.
try {
  const appSource = readFileSync(resolve(projectRoot, 'src/App.tsx'), 'utf8')
  const cartOpenStart = appSource.indexOf('const openStoreProductFromCart = (sourceLink: string)')
  const cartOpenEnd = appSource.indexOf("InAppBrowser.addListener('closeEvent'", cartOpenStart)
  const cartOpenSource = appSource.slice(cartOpenStart, cartOpenEnd)
  const iosFreshOpen = cartOpenSource.indexOf('openIosSheinCartProductInFreshSession(targetUrl)')
  const warmReuse = cartOpenSource.indexOf('sameSheinProductNavigation(targetUrl, currentWebviewUrlRef.current)')
  const sameSessionSetUrl = cartOpenSource.indexOf('InAppBrowser.setUrl({ url: targetUrl })')
  if (cartOpenStart < 0 || cartOpenEnd < 0 || iosFreshOpen < 0 || warmReuse < 0 || sameSessionSetUrl < 0 ||
      iosFreshOpen > warmReuse || iosFreshOpen > sameSessionSetUrl) {
    failures.push('SHEIN cart isolation: iOS fresh-session branch must return before warm reuse and setUrl')
  }

  const freshOpenStart = appSource.indexOf('const openIosSheinCartProductInFreshSession = (targetUrl: string)')
  const freshOpenEnd = appSource.indexOf('const openStoreProductFromCart = (sourceLink: string)', freshOpenStart)
  const freshOpenSource = appSource.slice(freshOpenStart, freshOpenEnd)
  if (freshOpenStart < 0 || freshOpenEnd < 0 ||
      !freshOpenSource.includes('sheinCacheResetPendingRef.current = true') ||
      !freshOpenSource.includes('browseSheinRef.current()') ||
      freshOpenSource.includes('InAppBrowser.setUrl')) {
    failures.push('SHEIN cart isolation: fresh iOS session must reset cache and reopen without setUrl reuse')
  }

  const sheinOptionsStart = appSource.indexOf("...(activeStore === 'shein'")
  const temuOptionsStart = appSource.indexOf("        : {", sheinOptionsStart)
  const sheinOptionsSource = appSource.slice(sheinOptionsStart, temuOptionsStart)
  if (sheinOptionsStart < 0 || temuOptionsStart < 0 ||
      !sheinOptionsSource.includes('hidden: true') ||
      !sheinOptionsSource.includes('invisibilityMode: InvisibilityMode.FAKE_VISIBLE')) {
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
} catch (error) {
  failures.push(`SHEIN cart isolation: ${error instanceof Error ? error.message : String(error)}`)
}

for (const check of checks) {
  const absolutePath = resolve(projectRoot, check.file)
  let contents
  try {
    contents = readFileSync(absolutePath, 'utf8')
  } catch (error) {
    failures.push(`${check.label}: cannot read ${check.file} (${error.message})`)
    continue
  }

  for (const marker of check.markers) {
    if (!contents.includes(marker)) {
      failures.push(`${check.label}: missing ${JSON.stringify(marker)} in ${check.file}`)
    }
  }
  for (const forbidden of check.forbidden || []) {
    if (contents.includes(forbidden)) {
      failures.push(`${check.label}: forbidden ${JSON.stringify(forbidden)} in ${check.file}`)
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
