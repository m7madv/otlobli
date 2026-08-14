
export const OTLOBLI_SHEIN_BASE_CSS = '.login-bar.j-login-bar{display:none!important}'

export const OTLOBLI_NAV_STYLE_VERSION = 'v86.104.0'
const SB = 'max(env(safe-area-inset-bottom,0px),var(--otlobli-sb,16px),16px)'
export const OTLOBLI_NAV_CSS =
  'position:fixed!important;left:50%!important;right:auto!important;bottom:0!important;top:auto!important;' +
  'transform:translate3d(-50%,0,0)!important;will-change:transform!important;width:100%!important;max-width:440px!important;' +
  'width:min(100vw, 440px)!important;height:90px!important;min-height:90px!important;max-height:90px!important;' +
  'height:calc(74px + ' + SB + ')!important;' +
  'min-height:calc(74px + ' + SB + ')!important;' +
  'max-height:calc(74px + ' + SB + ')!important;' +
  'z-index:2147483647!important;display:flex!important;flex-direction:row!important;align-items:stretch!important;' +
  'direction:rtl!important;overflow:hidden!important;box-sizing:border-box!important;' +
  'background:#fff!important;border-top:1px solid #bccac0!important;' +
  'backdrop-filter:none!important;-webkit-backdrop-filter:none!important;' +
  'padding:0 0 16px 0!important;padding:0 0 ' + SB + ' 0!important;margin:0!important;' +
  'font-family:system-ui,-apple-system,sans-serif!important;font-size:12px!important;line-height:normal!important;' +
  'opacity:1!important;visibility:visible!important;pointer-events:auto!important;'

// Document-start touch routing beats modal click cancellation. The timestamp
// deduplicates the synthetic click that follows a completed touch.
export const OTLOBLI_NAV_TOUCH_BRIDGE_JS = `
  function otlobliInstallNavTouchBridge() {
    var featureFlags = window.__OTLOBLI_SCRIPT_FLAGS__;
    if (featureFlags && (featureFlags.runtime === false || featureFlags.navigation === false)) return;
    if (window.__otlobliNavTouchBridgeBound) return;
    window.__otlobliNavTouchBridgeBound = true;
    var routeOtlobliNavTouch = function (event) {
      var node = event.target, messageType = '';
      for (var depth = 0; node && depth < 8; depth++, node = node.parentElement) {
        if (node.getAttribute) messageType = node.getAttribute('data-otlobli-nav-type') || '';
        if (messageType) break;
      }
      if (!messageType) return;
      if (event.cancelable) event.preventDefault();
      event.stopPropagation();
      if (event.stopImmediatePropagation) event.stopImmediatePropagation();
      var now = Date.now();
      if (now - (window.__otlobliNavTouchBridgeAt || 0) < 450) return;
      window.__otlobliNavTouchBridgeAt = now;
      try {
        if (window.mobileApp && window.mobileApp.postMessage) {
          if (messageType === 'openHome') {
            try {
              var homePath = sessionStorage.getItem('__otlobliHomePath') || (location.hostname.indexOf('temu.') >= 0 ? '/sa/' : '/ar/');
              location.assign(location.origin + homePath);
            } catch (homeError) {}
            return;
          }
          var nativeTarget = messageType === 'openOrders' ? 'orders' : (messageType === 'openCart' ? 'cart' : 'profile');
          if (typeof window.mobileApp.navigate === 'function') window.mobileApp.navigate(nativeTarget);
          else {
            window.mobileApp.postMessage({ detail: { type: messageType } });
            if (typeof window.mobileApp.hide === 'function') window.mobileApp.hide();
          }
        }
      } catch (e) {}
    };
    window.addEventListener('touchend', routeOtlobliNavTouch, { capture: true, passive: false });
    window.addEventListener('click', routeOtlobliNavTouch, true);
  }
  otlobliInstallNavTouchBridge();
`

const OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS = `
function otlobliInstallIosProductTapFallback(){var u=navigator.userAgent||'',s,t;if(!(/iP(?:hone|od|ad)/i.test(u)||navigator.platform==='MacIntel'&&(navigator.maxTouchPoints||0)>1))return;function i(v){var m=String(v||'').match(/-p-(\\d+)/i);return m&&m[1]||''}function a(n){for(var x=0;n&&x<12;x++,n=n.parentElement)if(n.tagName==='A'&&i(n.getAttribute('href')||''))return n;return null}function q(n){if(!n||!n.querySelectorAll)return null;var z=n.querySelectorAll('a[href*="-p-"]'),l=null,d='';for(var x=0;x<z.length&&x<16;x++){var v=z[x].href||z[x].getAttribute&&z[x].getAttribute('href')||'',p=i(v);if(!p)continue;if(d&&p!==d)return null;if(!d){d=p;l=z[x]}}return l}function e(n){if(!n||!n.getAttribute)return'';var k=['data-goods-id','data-goods_id','data-product-id','data-product_id','data-id','fsp-key'];for(var x=0;x<k.length;x++){var v=String(n.getAttribute(k[x])||'');if(/^\\d{5,}$/.test(v))return v}return''}function c(n){var l=a(n);if(l)return l;for(var x=0;n&&x<12;x++,n=n.parentElement){if(/^(?:IMG|PICTURE|SOURCE|SVG|PATH)$/i.test(n.tagName||''))continue;var z=q(n);if(z)return n;var k=String(n.className||''),r=n.getAttribute&&n.getAttribute('role'),v=e(n);if(v&&(r==='listitem'||r==='link'||/product-card|product-item|goods-card|goods-item|waterfall-item|flash-sale__product|multi-product-card/i.test(k)))return n}return null}function p(v){var n=v.changedTouches&&v.changedTouches[0];return n&&[n.clientX,n.clientY]}function h(n){try{var l=a(n),z=l||q(n),v=z&&(z.href||z.getAttribute&&z.getAttribute('href'))||'',d=i(v);if(v&&d)return[v,d];d=e(n);if(!d)return null;var m=String(location.pathname||'').match(/^\\/[^/]+/),b=m&&m[0]||'/ar';return[location.origin+b+'/product-p-'+d+'.html',d]}catch(x){return null}}function f(x){try{window.__otlobliFreezeProbe&&window.__otlobliFreezeProbe(x)}catch(v){}}function g(x,o){try{window.__otlobliTapDiagnostic&&window.__otlobliTapDiagnostic(x,o||{})}catch(v){}}document.addEventListener('touchstart',function(v){clearTimeout(t);var n=c(v.target),r=p(v),o=h(n);s=n&&r&&o?[n,location.href,Date.now(),r[0],r[1],o[0],o[1]]:null;if(n){f('product-tap-start'+(o?'-target':''));g(o?'armed':'ignored-no-product-target',{productHref:o&&o[0]||'',productId:o&&o[1]||'',pageHref:location.href})}},{capture:true,passive:true});document.addEventListener('touchend',function(v){var n=s,r=p(v);s=null;if(!n||!r||c(v.target)!==n[0]||Date.now()-n[2]>650||Math.abs(r[0]-n[3])+Math.abs(r[1]-n[4])>16)return;f('product-tap-fallback');g('scheduled',{pageHref:n[1],productHref:n[5],productId:n[6]});clearTimeout(t);t=setTimeout(function(){var m=i(location.href);if(m===n[6]){g('skipped-product-route-ready',{before:n[1],after:location.href,productId:n[6]});return}window.__otlobliProductTapAttemptAt=Date.now();window.__otlobliProductTapAttemptUrl=n[5];f('product-tap-route-fallback');g(location.href===n[1]?'location-assign':'override-non-product-route',{from:location.href,to:n[5],productId:n[6]});location.assign(n[5])},500)},{capture:true,passive:true})}
otlobliInstallIosProductTapFallback();
`

const OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS = `function otlobliInstallSheinChunkFailureBridge(){if(!/shein/i.test(location.hostname)||window.__otlobliSheinChunkFailureBridge)return;window.__otlobliSheinChunkFailureBridge=1;var sent=0,product=/-p-\\d+/i.test(location.pathname);function s(url,m){if(sent)return false;sent=1;try{var d={type:'sheinChunkLoadFailure',url:url||location.href,message:String(m||'').slice(0,180)},h=window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.messageHandler;if(window.mobileApp&&window.mobileApp.postMessage)window.mobileApp.postMessage({detail:d});else if(h)h.postMessage({detail:d});return true}catch(e){return false}}function p(v){var m='';try{m=String(v&&((v.message||v.reason)||(v.error&&v.error.message))||v||'')}catch(e){}if(!/ChunkLoadError|Loading chunk\\s+\\d+\\s+failed/i.test(m))return;window.__otlobliSheinChunkFailureAt=Date.now();if(product||Date.now()-(window.__otlobliProductTapAttemptAt||0)<15000)s(window.__otlobliProductTapAttemptUrl,m)}window.__otlobliRecoverSheinChunkOnStalledTap=function(url){if(sent)return true;return Date.now()-(window.__otlobliSheinChunkFailureAt||0)<600000&&s(url,'stalled product tap after ChunkLoadError')};addEventListener('error',function(e){p(e&&((e.error&&e.error.message)||e.message))},true);addEventListener('unhandledrejection',function(e){p(e&&e.reason)})}otlobliInstallSheinChunkFailureBridge();`

export { OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS, OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS }

// Runs as a real WKUserScript before SHEIN's first document starts. It mounts
// only Otlobli's existing bottom navigation; it does not touch SHEIN network,
// storage, region, CSS, or page lifecycle. The full capture script adopts the
// same #otlobli-nav node after page load.
export const OTLOBLI_NAV_BOOTSTRAP_SCRIPT = `
(function () {
  if (window.top !== window || window.__otlobliNavBootstrapInstalled) return;
  window.__otlobliNavBootstrapInstalled = true;

  ${OTLOBLI_NAV_TOUCH_BRIDGE_JS}
  ${OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS}
  ${OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS}

  var timer = 0;
  var attempts = 0;
  var icons = {
    home: '<path d="M4 11.5 12 4l8 7.5"/><path d="M6 10v9h12v-9"/><path d="M10 19v-5h4v5"/>',
    orders: '<rect x="4" y="7" width="16" height="13" rx="1.3"/><path d="M4 7l8-4 8 4"/><path d="M12 11v9"/>',
    cart: '<circle cx="9" cy="20" r="1.3"/><circle cx="18" cy="20" r="1.3"/><path d="M3 4h2l2.2 11.5a2 2 0 0 0 2 1.6h8.6a2 2 0 0 0 2-1.6L21 8H6"/>',
    profile: '<circle cx="12" cy="8" r="3.6"/><path d="M5 20c0-3.8 3.1-6.4 7-6.4s7 2.6 7 6.4"/>'
  };

  function ensureEarlyViewportFitCover() {
    if (!document.head) return;
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.setAttribute('name', 'viewport');
      document.head.appendChild(meta);
    }
    var content = String(meta.getAttribute('content') || 'width=device-width, initial-scale=1');
    if (!/viewport-fit\\s*=\\s*cover/i.test(content)) {
      content = content.replace(/\\s*,?\\s*viewport-fit\\s*=\\s*[^,]+/ig, '');
      meta.setAttribute('content', content.replace(/\\s*,\\s*$/, '') + ', viewport-fit=cover');
    }
  }

  function normalizedText(el) {
    return String((el && el.textContent) || '').replace(/\\s+/g, ' ').trim();
  }

  function storeBottomTabScore(text) {
    var patterns = [
      /home|\\u0627\\u0644\\u0631\\u0626\\u064a\\u0633\\u064a\\u0629/i,
      /categor|\\u0627\\u0644\\u0641\\u0626\\u0627\\u062a|\\u0627\\u0644\\u0623\\u0642\\u0633\\u0627\\u0645/i,
      /cart|bag|basket|\\u0627\\u0644\\u0633\\u0644\\u0629|\\u062d\\u0642\\u064a\\u0628\\u0629/i,
      /account|profile|\\u062d\\u0633\\u0627\\u0628\\u064a|\\u0623\\u0646\\u0627/i,
      /store|shop|trends|\\u0645\\u062a\\u062c\\u0631|\\u062a\\u0631\\u0646\\u062f\\u0627\\u062a/i
    ];
    var score = 0;
    for (var i = 0; i < patterns.length; i++) if (patterns[i].test(text)) score++;
    return score;
  }

  function hideStoreBottomFromPoint(node, vpWidth, vpHeight) {
    var current = node;
    var matched = null;
    for (var depth = 0; current && current !== document.body && current !== document.documentElement && depth < 9; depth++) {
      if (current.id && current.id.indexOf('otlobli') === 0) break;
      var rect = current.getBoundingClientRect();
      if (rect.width >= vpWidth * 0.55 && rect.height >= 24 && rect.height <= 170 &&
          (rect.bottom >= vpHeight - 30 || rect.top >= vpHeight - 190) &&
          storeBottomTabScore(normalizedText(current)) >= 3) {
        matched = current;
      }
      current = current.parentElement;
    }
    if (!matched) return;
    matched.style.setProperty('display', 'none', 'important');
    matched.style.setProperty('visibility', 'hidden', 'important');
    matched.style.setProperty('pointer-events', 'none', 'important');
    matched.setAttribute('data-otlobli-hidden-store-bottom', 'bootstrap-point-tabs');
  }

  function hideVerifiedStoreBottomNav() {
    if (!document.body) return;
    var vpHeight = window.innerHeight || document.documentElement.clientHeight || 0;
    var vpWidth = window.innerWidth || document.documentElement.clientWidth || 0;
    var nodes = document.querySelectorAll(
      'nav, [role="navigation"], [role="tablist"], [class*="tab-bar" i], [class*="tabbar" i], [class*="bottom-nav" i], [class*="footer-nav" i]'
    );
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (!el || (el.id && el.id.indexOf('otlobli') === 0)) continue;
      var rect = el.getBoundingClientRect();
      if (rect.width < vpWidth * 0.55 || rect.height < 24 || rect.height > 160) continue;
      if (rect.bottom < vpHeight - 30 && rect.top < vpHeight - 180) continue;
      if (storeBottomTabScore(normalizedText(el)) < 2) continue;
      el.style.setProperty('display', 'none', 'important');
      el.style.setProperty('visibility', 'hidden', 'important');
      el.style.setProperty('pointer-events', 'none', 'important');
      el.setAttribute('data-otlobli-hidden-store-bottom', 'bootstrap-verified-tabs');
    }

    // SHEIN's older/iPhone-6 markup uses obfuscated plain divs without nav
    // roles or stable classes. elementsFromPoint returns the whole visual
    // stack, including the real five-tab bar underneath Otlobli's nav, so we
    // can identify it by exact tab semantics without scanning the whole DOM.
    if (document.elementsFromPoint) {
      var xs = [Math.round(vpWidth * 0.12), Math.round(vpWidth * 0.32), Math.round(vpWidth * 0.5), Math.round(vpWidth * 0.68), Math.round(vpWidth * 0.88)];
      var ys = [Math.max(1, vpHeight - 6), Math.max(1, vpHeight - 42), Math.max(1, vpHeight - 78)];
      for (var yi = 0; yi < ys.length; yi++) {
        for (var xi = 0; xi < xs.length; xi++) {
          var stack = document.elementsFromPoint(xs[xi], ys[yi]);
          for (var si = 0; si < stack.length; si++) hideStoreBottomFromPoint(stack[si], vpWidth, vpHeight);
        }
      }
    }
  }

  var __otlobliEarlyNativeAddScanAt = 0;
  function hideEarlySheinProductAdd() {
    if (!/shein/i.test(location.hostname)) return;
    if (document.head && !document.getElementById('otlobli-native-add-style')) {
      var style = document.createElement('style');
      style.id = 'otlobli-native-add-style';
      style.textContent = '[class*="add-bag" i],[class*="addbag" i],[class*="add-to-bag" i],[class*="addtobag" i],' +
        '[class*="add-cart" i],[class*="addcart" i],[class*="add-to-cart" i],[class*="addtocart" i],' +
        '[aria-label*="add to bag" i],[aria-label*="add to cart" i],[aria-label*="أضف إلى عربة" i],[aria-label*="أضف للسلة" i]' +
        '{display:none!important;visibility:hidden!important;pointer-events:none!important}';
      document.head.appendChild(style);
    }
    if (!/-p-\\d+/i.test(location.pathname)) return;
    if (!document.body) return;
    var now = Date.now();
    if (now - __otlobliEarlyNativeAddScanAt < 350) return;
    __otlobliEarlyNativeAddScanAt = now;
    var vh = window.innerHeight || document.documentElement.clientHeight || 0;
    var vw = window.innerWidth || document.documentElement.clientWidth || 0;
    var nav = document.getElementById('otlobli-nav');
    var nr = nav && nav.getBoundingClientRect ? nav.getBoundingClientRect() : null;
    var navTop = nr && nr.top > 0 ? nr.top : vh - 90;
    var addPattern = /add\\s+to\\s+(?:bag|cart)|أضف[\\s\\S]{0,24}(?:عربة|السلة|للسلة|الحقيبة|التسوق)/i;
    function hide(el) {
      if (!el || !el.getBoundingClientRect || (el.closest && el.closest('[id^="otlobli"]'))) return;
      var label = normalizedText(el) + ' ' + String(el.getAttribute && el.getAttribute('aria-label') || '');
      if (!label || label.length > 90 || !addPattern.test(label)) return;
      var r = el.getBoundingClientRect();
      if (r.width < 64 || r.width > vw * 1.05 || r.height < 24 || r.height > 100 || r.bottom < navTop - 190 || r.top > navTop + 24) return;
      el.style.setProperty('display', 'none', 'important');
      el.style.setProperty('visibility', 'hidden', 'important');
      el.style.setProperty('pointer-events', 'none', 'important');
      el.setAttribute('data-otlobli-hidden-native-add', 'bootstrap-product-action');
    }
    var nodes = document.querySelectorAll('button,a,[role="button"],[class*="add" i],[aria-label*="add" i]');
    for (var i = 0; i < nodes.length && i < 140; i++) hide(nodes[i]);
    if (!document.elementsFromPoint) return;
    var xs = [Math.round(vw * .2), Math.round(vw * .5), Math.round(vw * .8)];
    var ys = [Math.max(1, navTop - 12), Math.max(1, navTop - 48), Math.max(1, navTop - 84)];
    for (var y = 0; y < ys.length; y++) for (var x = 0; x < xs.length; x++) {
      var stack = document.elementsFromPoint(xs[x], ys[y]);
      for (var s = 0; s < stack.length; s++) hide(stack[s]);
    }
  }

  var __otlobliEarlyCookieScanAt = 0;
  var __otlobliCookieAcceptClicks = 0;
  function protectCookieConsentAction() {
    if (!document.body) return;
    var scanNow = Date.now();
    if (scanNow - __otlobliEarlyCookieScanAt < 650) return;
    __otlobliEarlyCookieScanAt = scanNow;
    var buttons = document.querySelectorAll('button, [role="button"], a, input[type="button"], input[type="submit"]');
    var acceptPattern = /^(?:accept(?: all)?|allow(?: all)?|agree(?: to all)?|\\u0642\\u0628\\u0648\\u0644(?: \\u0627\\u0644\\u0643\\u0644)?|\\u0627\\u0642\\u0628\\u0644(?: \\u0627\\u0644\\u0643\\u0644)?|\\u0627\\u0644\\u0633\\u0645\\u0627\\u062d (?:\\u0644\\u0644\\u0643\\u0644|\\u0644\\u0644\\u062c\\u0645\\u064a\\u0639)|\\u0645\\u0648\\u0627\\u0641\\u0642)$/i;
    var rejectPattern = /^(?:reject all|decline all|deny all|\\u0631\\u0641\\u0636 \\u0627\\u0644\\u0643\\u0644|\\u0639\\u062f\\u0645 \\u0627\\u0644\\u0642\\u0628\\u0648\\u0644)$/i;
    var cookiePattern = /cookies?|\\u0645\\u0644\\u0641\\u0627\\u062a \\u062a\\u0639\\u0631\\u064a\\u0641 \\u0627\\u0644\\u0627\\u0631\\u062a\\u0628\\u0627\\u0637|\\u0627\\u0644\\u062a\\u0642\\u0646\\u064a\\u0627\\u062a \\u0627\\u0644\\u0645\\u0645\\u0627\\u062b\\u0644\\u0629/i;
    var vpHeight = window.innerHeight || document.documentElement.clientHeight || 0;
    for (var i = 0; i < buttons.length; i++) {
      var button = buttons[i];
      var buttonLabel = normalizedText(button) || String(button.value || '').replace(/\\s+/g, ' ').trim();
      if (!acceptPattern.test(buttonLabel)) continue;
      var scope = button;
      var cookieScope = null;
      for (var hop = 0; scope && hop < 7; hop++, scope = scope.parentElement) {
        var scopeText = normalizedText(scope);
        if (scopeText.length < 2400 && cookiePattern.test(scopeText)) {
          cookieScope = scope;
          break;
        }
      }
      if (!cookieScope) continue;
      if (__otlobliCookieAcceptClicks < 4) {
        var acceptRect0 = button.getBoundingClientRect();
        if (acceptRect0.width > 0 && acceptRect0.height > 0) {
          __otlobliCookieAcceptClicks++;
          try { button.click(); } catch (eAccept0) {}
        }
      }
      var scopedControls = cookieScope.querySelectorAll('button, [role="button"], a, input[type="button"], input[type="submit"]');
      var reject = null;
      for (var ri = 0; ri < scopedControls.length; ri++) {
        var rejectLabel = normalizedText(scopedControls[ri]) || String(scopedControls[ri].value || '').replace(/\\s+/g, ' ').trim();
        if (rejectPattern.test(rejectLabel)) { reject = scopedControls[ri]; break; }
      }
      var actionRoot = button;
      if (reject) {
        for (var parent = button.parentElement, depth = 0; parent && parent !== cookieScope.parentElement && depth < 6; parent = parent.parentElement, depth++) {
          var parentRect = parent.getBoundingClientRect();
          if (parent.contains(reject) && parentRect.height > 0 && parentRect.height <= 220) {
            actionRoot = parent;
            break;
          }
        }
      } else if (button.parentElement) {
        actionRoot = button.parentElement;
      }
      var actionRect = actionRoot.getBoundingClientRect();
      if (actionRect.height <= 0 || actionRect.height > 220) {
        actionRoot = button;
        actionRect = button.getBoundingClientRect();
      }
      var nav = document.getElementById('otlobli-nav');
      var navRect = nav && nav.getBoundingClientRect ? nav.getBoundingClientRect() : null;
      var navTop = navRect && navRect.top > 0 ? navRect.top : vpHeight - 86;
      if (actionRect.bottom < navTop - 8) continue;
      if (actionRoot.getAttribute('data-otlobli-cookie-raised') === '1') continue;
      var style = window.getComputedStyle(actionRoot);
      if (style.position === 'static') actionRoot.style.setProperty('position', 'relative', 'important');
      actionRoot.style.setProperty('bottom', Math.max(74, Math.ceil(actionRect.bottom - navTop + 12)) + 'px', 'important');
      actionRoot.style.setProperty('z-index', '2147483646', 'important');
      actionRoot.setAttribute('data-otlobli-cookie-raised', '1');
    }
  }

  // SHEIN injects a compact first-order registration offer after cookie
  // consent on older layouts. Identify that one strip by its exact semantics
  // and bottom-edge geometry instead of relying on obfuscated class names or
  // hiding generic promotional elements (which would also match products).
  var __otlobliEarlySignupScanAt = 0;
  function hideExactSheinSignupDiscountBanner() {
    if (!document.body || !document.elementsFromPoint) return;
    var scanNow = Date.now();
    if (scanNow - __otlobliEarlySignupScanAt < 650) return;
    __otlobliEarlySignupScanAt = scanNow;
    var vpHeight = window.innerHeight || document.documentElement.clientHeight || 0;
    var vpWidth = window.innerWidth || document.documentElement.clientWidth || 0;
    var nav = document.getElementById('otlobli-nav');
    var navRect = nav && nav.getBoundingClientRect ? nav.getBoundingClientRect() : null;
    var navTop = navRect && navRect.top > 0 ? navRect.top : vpHeight - 90;
    var offerPattern = /(?:get\\s*15\\s*%\\s*off|15\\s*%\\s*off|\\u0627\\u062d\\u0635\\u0644\\s+\\u0639\\u0644[\\u0649\\u064a]\\s+\\u062e\\u0635\\u0645\\s*15\\s*%|\\u062e\\u0635\\u0645\\s*15\\s*%)/i;
    var signupPattern = /(?:^|\\s)(?:register|sign\\s*up|join\\s*now|\\u062a\\u0633\\u062c\\u064a\\u0644|\\u0633\\u062c\\u0644)(?:\\s|$)/i;
    var newsletterPattern = /(?:exclusive\\s+offers|shein\\s+news|newsletter|unsubscribe|\\u0627\\u0644\\u0639\\u0631\\u0648\\u0636\\s+\\u0627\\u0644\\u062d\\u0635\\u0631\\u064a\\u0629|\\u0623\\u062e\\u0628\\u0627\\u0631\\s+shein|(?:\\u0625|\\u0627)\\u0644\\u063a\\u0627\\u0621\\s+\\u0627\\u0644\\u0627\\u0634\\u062a\\u0631\\u0627\\u0643)/i;
    var emailPattern = /(?:email|e-mail|\\u0627\\u0644\\u0628\\u0631\\u064a\\u062f\\s+\\u0627\\u0644(?:\\u0625|\\u0627)\\u0644\\u0643\\u062a\\u0631\\u0648\\u0646\\u064a|\\u0628\\u0631\\u064a\\u062f\\u0643\\s+\\u0627\\u0644(?:\\u0625|\\u0627)\\u0644\\u0643\\u062a\\u0631\\u0648\\u0646\\u064a)/i;
    var authPattern = /(?:sign\\s*in|log\\s*in|continue\\s+with|phone\\s+number|\\u062a\\u0633\\u062c\\u064a\\u0644\\s+\\u0627\\u0644\\u062f\\u062e\\u0648\\u0644|\\u0631\\u0642\\u0645\\s+\\u0627\\u0644\\u0645\\u0648\\u0628\\u0627\\u064a\\u0644|\\u0627\\u0644\\u0627\\u0633\\u062a\\u0645\\u0631\\u0627\\u0631\\s+\\u0628\\u062c\\u0648\\u062c\\u0644)/i;

    function inspect(node) {
      var current = node;
      var matched = null;
      for (var depth = 0; current && current !== document.body && current !== document.documentElement && depth < 9; depth++) {
        if (current.id && current.id.indexOf('otlobli') === 0) break;
        var text = normalizedText(current).replace(/[\\u064B-\\u065F\\u0670]/g, '');
        var hasEmailInput = false;
        if (text.length > 0 && text.length < 720 && signupPattern.test(text)) {
          var inputs = current.querySelectorAll ? current.querySelectorAll('input') : [];
          for (var ii = 0; ii < inputs.length; ii++) {
            var inputHint = String(inputs[ii].getAttribute('type') || '') + ' ' +
              String(inputs[ii].getAttribute('placeholder') || '') + ' ' +
              String(inputs[ii].getAttribute('aria-label') || '');
            if (emailPattern.test(inputHint)) { hasEmailInput = true; break; }
          }
        }
        var authSurface = authPattern.test(text);
        var exactOfferStrip = !authSurface && offerPattern.test(text) && signupPattern.test(text);
        var exactNewsletterPanel = !authSurface && signupPattern.test(text) && newsletterPattern.test(text) && hasEmailInput;
        if (text.length > 0 && text.length < 720 && (exactOfferStrip || exactNewsletterPanel)) {
          var rect = current.getBoundingClientRect();
          var style = window.getComputedStyle(current);
          var positioned = style.position === 'fixed' || style.position === 'sticky' || style.position === 'absolute';
          var touchesNav = rect.bottom >= navTop - 36 && rect.top < navTop + 20;
          var offerPlacement = exactOfferStrip && rect.width >= vpWidth * 0.62 &&
            rect.height >= 32 && rect.height <= 180 && rect.top >= Math.max(0, navTop - 220) &&
            touchesNav && (positioned || Math.abs(rect.bottom - navTop) <= 48);
          var newsletterPlacement = exactNewsletterPanel && rect.width >= vpWidth * 0.62 &&
            rect.height >= 80 && rect.height <= 520;
          if (offerPlacement || newsletterPlacement) {
            matched = current;
          }
        }
        current = current.parentElement;
      }
      if (!matched) return;
      matched.style.setProperty('display', 'none', 'important');
      matched.style.setProperty('visibility', 'hidden', 'important');
      matched.style.setProperty('pointer-events', 'none', 'important');
      matched.setAttribute('data-otlobli-hidden-shein-signup', 'exact-offer-or-newsletter');
    }

    var xs = [Math.round(vpWidth * 0.12), Math.round(vpWidth * 0.5), Math.round(vpWidth * 0.88)];
    var ys = [Math.max(1, Math.round(navTop - 10)), Math.max(1, Math.round(navTop - 54))];
    for (var yi = 0; yi < ys.length; yi++) {
      for (var xi = 0; xi < xs.length; xi++) {
        var stack = document.elementsFromPoint(xs[xi], ys[yi]);
        for (var si = 0; si < stack.length; si++) inspect(stack[si]);
      }
    }
    // The larger newsletter variant can be ordinary page content rather than
    // fixed. Start from its tiny set of email inputs so it is removed while
    // still off-screen, before scrolling could reveal it above the nav.
    var emailInputs = document.getElementsByTagName('input');
    for (var ei = 0; ei < emailInputs.length && ei < 80; ei++) {
      var emailHint = String(emailInputs[ei].getAttribute('type') || '') + ' ' +
        String(emailInputs[ei].getAttribute('placeholder') || '') + ' ' +
        String(emailInputs[ei].getAttribute('aria-label') || '');
      if (emailPattern.test(emailHint)) inspect(emailInputs[ei]);
    }
  }

  function runEarlyProtections() {
    try { hideEarlySheinProductAdd(); } catch (e) {}
    try { hideVerifiedStoreBottomNav(); } catch (e) {}
    try { protectCookieConsentAction(); } catch (e) {}
    try { hideExactSheinSignupDiscountBanner(); } catch (e) {}
  }

  function mount() {
    var root = document.documentElement, inset = Number(window.__otlobliSafeBottom || 0);
    if (root && isFinite(inset)) root.style.setProperty('--otlobli-sb', Math.round(Math.min(60, Math.max(16, inset))) + 'px');
    ensureEarlyViewportFitCover();
    try { hideEarlySheinProductAdd(); } catch (e) {}
    if (!document.getElementById('otlobli-base-style')) {
      var fontParent = document.head || document.documentElement;
      if (fontParent) {
        var fontStyle = document.createElement('style');
        fontStyle.id = 'otlobli-base-style';
        fontStyle.textContent = ${JSON.stringify(OTLOBLI_SHEIN_BASE_CSS)};
        fontParent.appendChild(fontStyle);
      }
    }
    if (!document.body) return false;
    if (document.getElementById('otlobli-nav')) {
      runEarlyProtections();
      return true;
    }

    var nav = document.createElement('div');
    nav.id = 'otlobli-nav';
    nav.style.cssText = ${JSON.stringify(OTLOBLI_NAV_CSS)};
    nav.setAttribute('data-otlobli-nav-style', ${JSON.stringify(OTLOBLI_NAV_STYLE_VERSION)});

    var items = [
      { label: '\\u0627\\u0644\\u0631\\u0626\\u064a\\u0633\\u064a\\u0629', icon: icons.home, type: 'openHome' },
      { label: '\\u0637\\u0644\\u0628\\u0627\\u062a\\u064a', icon: icons.orders, type: 'openOrders' },
      { label: '\\u0627\\u0644\\u0633\\u0644\\u0629', icon: icons.cart, type: 'openCart' },
      { label: '\\u062d\\u0633\\u0627\\u0628\\u064a', icon: icons.profile, type: 'openProfile' }
    ];

    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var tab = document.createElement('button');
        var active = item.type === 'openHome';
      tab.id = 'otlobli-nav-tab-' + i;
      tab.style.cssText = 'position:relative!important;flex:1 1 25%!important;width:25%!important;max-width:25%!important;' +
        'min-width:0!important;height:auto!important;min-height:0!important;align-self:stretch!important;border:0!important;' +
        'background:transparent!important;display:flex!important;flex-direction:column!important;align-items:center!important;' +
        'justify-content:center!important;padding:10px 0 0 0!important;margin:0!important;box-sizing:border-box!important;font-size:12px!important;' +
        'line-height:normal!important;font-weight:700!important;font-family:system-ui,-apple-system,sans-serif!important;color:' +
        (active ? '#006948' : '#3d4a42') + '!important;';
      if (active) {
        var indicator = document.createElement('span');
        indicator.style.cssText = 'position:absolute!important;top:0!important;left:50%!important;transform:translateX(-50%)!important;width:32px!important;height:4px!important;border-radius:999px!important;background:#006948!important;';
        tab.appendChild(indicator);
      }
      tab.insertAdjacentHTML('beforeend', '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' +
        item.icon + '</svg><span style="font:inherit!important;line-height:normal!important;margin-top:4px!important">' + item.label + '</span>');
      if (item.type) {
        tab.setAttribute('data-otlobli-nav-type', item.type);
      }
      nav.appendChild(tab);
    }
    document.documentElement.appendChild(nav);
    runEarlyProtections();
    return true;
  }

  if (!mount()) {
    document.addEventListener('DOMContentLoaded', mount, false);
    timer = setInterval(function () {
      attempts++;
      if (mount() || attempts >= 400) clearInterval(timer);
    }, 25);
  }
  var protectionRuns = 0;
  var protectionTimer = setInterval(function () {
    if (window.__otlobliStoreRuntimeReady) {
      clearInterval(protectionTimer);
      return;
    }
    protectionRuns++;
    runEarlyProtections();
    if (protectionRuns >= 180) clearInterval(protectionTimer);
  }, 250);
  // The nav is attached to documentElement, so replacing SHEIN's app root
  // normally leaves it intact. Recheck on real wake events rather than waking
  // every weak device forever with a background DOM timer.
  function restoreOtlobliNavOnWake() {
    try { mount(); } catch (e) {}
  }
  window.addEventListener('pageshow', restoreOtlobliNavOnWake, false);
  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) restoreOtlobliNavOnWake();
  }, false);
})();
`
