import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')

const checks = [
  {
    label: 'persistent patch',
    file: 'patches/@capgo+capacitor-inappbrowser+8.6.25.patch',
    markers: [
      'func otlobliForceRecompose(force: Bool = false)',
      'webView.removeFromSuperview()',
      'self.view.addSubview(webView)',
      'webView.scrollView.setContentOffset(offset, animated: false)',
      '@objc func appDidBecomeActive(_ notification: NSNotification)',
      '@objc func appWillEnterForeground(_ notification: NSNotification)',
      'UIApplication.willEnterForegroundNotification',
      'private func otlobliRecomposeAllWebViews()',
      'for delay in [0.12, 0.5, 1.2, 2.2]',
      'controller.otlobliForceRecompose(force: true)',
      'messageBody["__otlobliRecompose"] as? Bool == true',
      'public void otlobliOnHostResume()',
      'public void navigate(String target)',
      "new CustomEvent('otlobli:nativeNavigate'",
      'func navigateHostFromJavaScript(_ target: String',
      'window.webkit.messageHandlers.navigate.postMessage',
    ],
  },
  {
    label: 'applied iOS lifecycle patch',
    file: 'node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/InAppBrowserPlugin.swift',
    markers: [
      '@objc func appDidBecomeActive(_ notification: NSNotification)',
      '@objc func appWillEnterForeground(_ notification: NSNotification)',
      'UIApplication.willEnterForegroundNotification',
      'private func otlobliRecomposeAllWebViews()',
      'for delay in [0.12, 0.5, 1.2, 2.2]',
      'controller.otlobliForceRecompose(force: true)',
      'func navigateHostFromJavaScript(_ target: String',
      "new CustomEvent('otlobli:nativeNavigate'",
    ],
  },
  {
    label: 'applied iOS WKWebView patch',
    file: 'node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/WKWebViewController.swift',
    markers: [
      'func otlobliForceRecompose(force: Bool = false)',
      'webView.removeFromSuperview()',
      'self.view.addSubview(webView)',
      'webView.scrollView.setContentOffset(offset, animated: false)',
      'messageBody["__otlobliRecompose"] as? Bool == true',
      'message.name == "navigate"',
      'window.webkit.messageHandlers.navigate.postMessage',
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
]

const failures = []

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
