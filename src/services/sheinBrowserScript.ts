import cairoArabicFontDataUrl from '@fontsource-variable/cairo/files/cairo-arabic-wght-normal.woff2?inline'

const OTLOBLI_CAIRO_FONT_CSS =
  '@font-face{font-family:"OtlobliCairo";src:url("' + cairoArabicFontDataUrl + '") format("woff2");font-style:normal;font-weight:200 1000;font-display:block;}'

const OTLOBLI_NAV_STYLE_VERSION = 'v85.8.10'
const OTLOBLI_NAV_CSS =
  'position:fixed!important;left:50%!important;right:auto!important;bottom:0!important;top:auto!important;' +
  'transform:translate3d(-50%,0,0)!important;will-change:transform!important;width:100%!important;max-width:440px!important;' +
  'width:min(100vw, 440px)!important;height:90px!important;min-height:90px!important;max-height:90px!important;' +
  'height:calc(74px + max(env(safe-area-inset-bottom, 0px), 16px))!important;' +
  'min-height:calc(74px + max(env(safe-area-inset-bottom, 0px), 16px))!important;' +
  'max-height:calc(74px + max(env(safe-area-inset-bottom, 0px), 16px))!important;' +
  'z-index:2147483647!important;display:flex!important;flex-direction:row!important;align-items:stretch!important;' +
  'direction:rtl!important;overflow:hidden!important;box-sizing:border-box!important;' +
  'background:rgba(255,255,255,.97)!important;border-top:1px solid #bccac0!important;' +
  'backdrop-filter:blur(16px)!important;-webkit-backdrop-filter:blur(16px)!important;' +
  'padding:0 0 16px 0!important;padding:0 0 max(env(safe-area-inset-bottom, 0px), 16px) 0!important;margin:0!important;' +
  'font-family:OtlobliCairo,system-ui,-apple-system,sans-serif!important;font-size:12px!important;line-height:normal!important;' +
  'opacity:1!important;visibility:visible!important;pointer-events:auto!important;'

// Runs as a real WKUserScript before SHEIN's first document starts. It mounts
// only Otlobli's existing bottom navigation; it does not touch SHEIN network,
// storage, region, CSS, or page lifecycle. The full capture script adopts the
// same #otlobli-nav node after page load.
export const OTLOBLI_NAV_BOOTSTRAP_SCRIPT = `
(function () {
  if (window.top !== window || window.__otlobliNavBootstrapInstalled) return;
  window.__otlobliNavBootstrapInstalled = true;

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
    return String((el && (el.innerText || el.textContent)) || '').replace(/\\s+/g, ' ').trim();
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
      // otlobli: auto-accept the cookie consent. High-confidence match - the
      // button label matched acceptPattern AND its surrounding scope matched
      // cookiePattern - so click it so the banner dismisses itself. The customer
      // never has to reach it (it sits behind the fixed nav on tall devices) and
      // can never pick "reject all". Bounded attempts; if the click does not
      // dismiss it we fall through to the raise logic so buttons stay tappable.
      // The human-check prompt never matches acceptPattern, so it is untouched.
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
    try { hideVerifiedStoreBottomNav(); } catch (e) {}
    try { protectCookieConsentAction(); } catch (e) {}
    try { hideExactSheinSignupDiscountBanner(); } catch (e) {}
  }

  function mount() {
    ensureEarlyViewportFitCover();
    // (v85.8.5) حمّل خط Cairo داخل مستند شي إن أيضاً. التطبيق يحمّله عبر @import،
    // لكن WebView شي إن مستند منفصل لا يرث خطوط التطبيق، فكان الشريط المحقون
    // يسقط لخط النظام (SF) بينما شريط React بخط Cairo — وهذا سبب «اختلاف الخط
    // والسماكة» الذي لاحظه المستخدم (Cairo أعرض/أثقل من SF بنفس الحجم). بحقن نفس
    // رابط جوجل هنا يصير الشريطان بخط Cairo نفسه تماماً. إن فشل التحميل (نادر)
    // يسقط لـSF كما هو الحال الآن — لا ضرر إضافي.
    if (!document.getElementById('otlobli-cairo-font')) {
      var fontStyle = document.createElement('style');
      fontStyle.id = 'otlobli-cairo-font';
      fontStyle.textContent = ${JSON.stringify(OTLOBLI_CAIRO_FONT_CSS)};
      (document.head || document.documentElement).appendChild(fontStyle);
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
      { label: '\\u0627\\u0644\\u0631\\u0626\\u064a\\u0633\\u064a\\u0629', icon: icons.home, type: '' },
      { label: '\\u0637\\u0644\\u0628\\u0627\\u062a\\u064a', icon: icons.orders, type: 'openOrders' },
      { label: '\\u0627\\u0644\\u0633\\u0644\\u0629', icon: icons.cart, type: 'openCart' },
      { label: '\\u062d\\u0633\\u0627\\u0628\\u064a', icon: icons.profile, type: 'openProfile' }
    ];

    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var tab = document.createElement('button');
      var active = !item.type;
      tab.id = 'otlobli-nav-tab-' + i;
      tab.style.cssText = 'position:relative!important;flex:1 1 25%!important;width:25%!important;max-width:25%!important;' +
        'min-width:0!important;height:auto!important;min-height:0!important;align-self:stretch!important;border:0!important;' +
        'background:transparent!important;display:flex!important;flex-direction:column!important;align-items:center!important;' +
        'justify-content:center!important;padding:10px 0 0 0!important;margin:0!important;box-sizing:border-box!important;font-size:12px!important;' +
        'line-height:normal!important;font-weight:700!important;font-family:OtlobliCairo,system-ui,-apple-system,sans-serif!important;color:' +
        (active ? '#006948' : '#3d4a42') + '!important;';
      if (active) {
        var indicator = document.createElement('span');
        indicator.style.cssText = 'position:absolute!important;top:0!important;left:50%!important;transform:translateX(-50%)!important;width:32px!important;height:4px!important;border-radius:999px!important;background:#006948!important;';
        tab.appendChild(indicator);
      }
      tab.insertAdjacentHTML('beforeend', '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' +
        item.icon + '</svg><span style="font:inherit!important;line-height:normal!important;margin-top:4px!important">' + item.label + '</span>');
      if (item.type) {
        (function (messageType) {
          tab.addEventListener('click', function (event) {
            event.preventDefault();
            event.stopPropagation();
            try {
              if (window.mobileApp && window.mobileApp.postMessage) {
                window.mobileApp.postMessage({ detail: { type: messageType } });
              }
            } catch (e) {}
          }, true);
        })(item.type);
      }
      nav.appendChild(tab);
    }
    document.body.appendChild(nav);
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
    protectionRuns++;
    runEarlyProtections();
    if (protectionRuns >= 180) clearInterval(protectionTimer);
  }, 250);
})();
`

export const SHEIN_CAPTURE_SCRIPT = `
(function () {
  var OTLOBLI_NAV_CSS = ${JSON.stringify(OTLOBLI_NAV_CSS)};
  var OTLOBLI_NAV_STYLE_VERSION = ${JSON.stringify(OTLOBLI_NAV_STYLE_VERSION)};

  function ensureOtlobliCairoFont() {
    if (document.getElementById('otlobli-cairo-font')) return;
    var fontStyle = document.createElement('style');
    fontStyle.id = 'otlobli-cairo-font';
    fontStyle.textContent = ${JSON.stringify(OTLOBLI_CAIRO_FONT_CSS)};
    (document.head || document.documentElement).appendChild(fontStyle);
  }
  ensureOtlobliCairoFont();

  // env(safe-area-inset-bottom) only resolves to the device's real inset when
  // the PAGE's OWN viewport meta tag declares viewport-fit=cover - otherwise
  // it silently evaluates to 0 everywhere, regardless of device. otlobli's
  // nav bar/back button/add-to-cart button all fall back to a flat 16px in
  // that case (see their max(env(...), 16px) CSS), which doesn't match every
  // phone's actual gesture-bar height - on some it sits too low/cramped.
  // SHEIN's own page doesn't necessarily declare this (it's not built for a
  // notch-aware native shell), so force it here rather than depending on
  // their markup. Re-asserted on every tick (not just once) since SHEIN's own
  // SPA can rewrite this meta tag's content on certain navigations.
  function ensureViewportFitCover() {
    if (!document.head) return;
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.setAttribute('name', 'viewport');
      document.head.appendChild(meta);
    }
    var content = meta.getAttribute('content') || 'width=device-width, initial-scale=1';
    var nextContent = content
      .replace(/,?\\s*viewport-fit=[^,]*/ig, '')
      .replace(/,?\\s*maximum-scale=[^,]*/ig, '')
      .replace(/,?\\s*user-scalable=[^,]*/ig, '');
    nextContent += ', viewport-fit=cover, maximum-scale=1, user-scalable=no';
    if (content !== nextContent) {
      meta.setAttribute('content', nextContent);
    }
  }
  ensureViewportFitCover();

  // SHEIN's regional sites default to English (e.g. "joen"/"lben"); the bare
  // region code ("jo"/"lb") renders Arabic. We read the region from the URL
  // path (/jo/ or /lb/) so this stays correct whichever source country the
  // app is configured for, then force Arabic once via cookie + a reload so it
  // sticks for future loads. Allows up to 2 reload attempts - direct
  // connections can race the cookie write against the page's own first content
  // request on a slow/just-toggled-VPN connection, so one attempt occasionally
  // still rendered English; the retry counter resets per real navigation.
  // هل نحن داخل أحد مواقع شي إن؟ منطق الالتقاط/الحجب الخاص بشي إن يعمل فقط
  // عندها؛ على المتاجر الأخرى (تيمو/ترينديول) نكتفي بتنظيف العروض المنبثقة.
  var IS_SHEIN = /shein/i.test(location.hostname);
  var IS_TEMU = /temu/i.test(location.hostname);

  // (v66-fix) بيانات الـWebView مشتركة/دائمة بين جلسات المتجر. أكّد المستخدم أن
  // شي إن «كصور لا تنكبس» بعد تبديل المتجر (تيمو ثم شي إن)، بينما حذف/إعادة
  // تنصيب التطبيق يُصلحه — أي أن حالة service worker/كاش مُتراكمة من جلسة سابقة
  // تخدم أصولاً معطوبة فلا تُفعَّل الصفحة (hydration). نُلغي تسجيل أي service
  // worker ونمسح Cache Storage عند بداية كل تحميل — fire-and-forget كي لا يعطّل
  // الرسم — فتُطبَّق حالة نظيفة على التحميل التالي (يقارب التنصيب النظيف). لا
  // نلمس localStorage (مسحه العريض يسبب skeleton loading — درس موثق).
  var cleanSheinRuntimeCache = IS_SHEIN;
  try {
    if (sessionStorage.getItem('otlobli_shein_runtime_cleaned') === '1') {
      cleanSheinRuntimeCache = false;
    } else if (IS_SHEIN) {
      sessionStorage.setItem('otlobli_shein_runtime_cleaned', '1');
    }
  } catch (e) {}
  if (cleanSheinRuntimeCache) {
    try {
      if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) {
        navigator.serviceWorker.getRegistrations().then(function (regs) {
          for (var i = 0; i < regs.length; i++) { try { regs[i].unregister(); } catch (e) {} }
        }).catch(function () {});
      }
      if (window.caches && caches.keys) {
        caches.keys().then(function (keys) {
          for (var k = 0; k < keys.length; k++) { try { caches.delete(keys[k]); } catch (e) {} }
        }).catch(function () {});
      }
    } catch (e) {}
  }

  var SHEIN_REQUIRED_COUNTRY = 'SA';
  var SHEIN_REQUIRED_CURRENCY = 'USD';
  var SHEIN_REQUIRED_LANGUAGE = 'ar';
  var SHEIN_REQUIRED_SITE_UID = 'pwar';
  var SHEIN_CHALLENGE_PATH_RE = /\\/(?:cdn-cgi|challenge|captcha|verify|verification|security|robot|risk|anti[-_]?bot|human)(?:\\/|$)/i;
  var SHEIN_CHALLENGE_QUERY_RE = /(?:^|[?&#])(?:captcha|challenge|verification|security_token|risk|robot|anti[-_]?bot|human)=/i;
  var TEMU_REQUIRED_COUNTRY = 'SA';
  var TEMU_REQUIRED_CURRENCY = 'USD';

  function writeTemuSaudiUsdState() {
    if (!IS_TEMU) return;
    try {
      document.cookie = 'currency=' + TEMU_REQUIRED_CURRENCY + '; path=/; max-age=31536000';
      document.cookie = 'currency=' + TEMU_REQUIRED_CURRENCY + '; domain=.temu.com; path=/; max-age=31536000';
      document.cookie = 'currencyCode=' + TEMU_REQUIRED_CURRENCY + '; path=/; max-age=31536000';
      document.cookie = 'currencyCode=' + TEMU_REQUIRED_CURRENCY + '; domain=.temu.com; path=/; max-age=31536000';
      document.cookie = 'country=' + TEMU_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'country=' + TEMU_REQUIRED_COUNTRY + '; domain=.temu.com; path=/; max-age=31536000';
      document.cookie = 'countryCode=' + TEMU_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'countryCode=' + TEMU_REQUIRED_COUNTRY + '; domain=.temu.com; path=/; max-age=31536000';
      try {
        localStorage.setItem('currency', TEMU_REQUIRED_CURRENCY);
        localStorage.setItem('currencyCode', TEMU_REQUIRED_CURRENCY);
        localStorage.setItem('country', TEMU_REQUIRED_COUNTRY);
        localStorage.setItem('countryCode', TEMU_REQUIRED_COUNTRY);
        localStorage.setItem('otlobli_temu_country', TEMU_REQUIRED_COUNTRY);
        localStorage.setItem('otlobli_temu_currency', TEMU_REQUIRED_CURRENCY);
        sessionStorage.setItem('currency', TEMU_REQUIRED_CURRENCY);
        sessionStorage.setItem('currencyCode', TEMU_REQUIRED_CURRENCY);
        sessionStorage.setItem('country', TEMU_REQUIRED_COUNTRY);
        sessionStorage.setItem('countryCode', TEMU_REQUIRED_COUNTRY);
      } catch (e) {}
    } catch (e) {}
  }

  writeTemuSaudiUsdState();

  function otlobliEnsureChallengeNav() {
    if (!document.body) return false;
    var nav = document.getElementById('otlobli-nav');
    if (!nav) {
      nav = document.createElement('div');
      nav.id = 'otlobli-nav';
      nav.setAttribute('data-otlobli-challenge-nav', '1');
      var items = [
        { label: '\\u0627\\u0644\\u0631\\u0626\\u064a\\u0633\\u064a\\u0629', type: '' },
        { label: '\\u0637\\u0644\\u0628\\u0627\\u062a\\u064a', type: 'openOrders' },
        { label: '\\u0627\\u0644\\u0633\\u0644\\u0629', type: 'openCart' },
        { label: '\\u062d\\u0633\\u0627\\u0628\\u064a', type: 'openProfile' },
      ];
      for (var ni = 0; ni < items.length; ni++) {
        var item = items[ni];
        var tab = document.createElement('button');
        tab.id = 'otlobli-nav-tab-' + ni;
        tab.textContent = item.label;
        tab.style.cssText = 'position:relative!important;flex:1 1 0!important;height:74px!important;min-height:74px!important;max-height:74px!important;' +
          'border:0!important;background:transparent!important;display:grid!important;place-items:center!important;align-content:center!important;' +
          'padding:10px 0 0 0!important;margin:0!important;box-sizing:border-box!important;font-size:12px!important;line-height:1.15!important;' +
          'font-family:OtlobliCairo,system-ui,-apple-system,sans-serif!important;font-weight:700!important;color:' + (item.type ? '#3d4a42' : '#006948') + '!important;';
        if (!item.type) {
          var indicator = document.createElement('span');
          indicator.style.cssText = 'position:absolute!important;top:0!important;width:32px!important;height:4px!important;border-radius:999px!important;background:#006948!important;';
          tab.appendChild(indicator);
        } else {
          (function (messageType) {
            tab.addEventListener('click', function (event) {
              event.preventDefault();
              event.stopPropagation();
              try {
                if (window.mobileApp && window.mobileApp.postMessage) {
                  window.mobileApp.postMessage({ detail: { type: messageType } });
                }
              } catch (e) {}
            }, true);
          })(item.type);
        }
        nav.appendChild(tab);
      }
    }
    if (nav.getAttribute('data-otlobli-nav-style') !== OTLOBLI_NAV_STYLE_VERSION) {
      nav.style.cssText = OTLOBLI_NAV_CSS;
      nav.setAttribute('data-otlobli-nav-style', OTLOBLI_NAV_STYLE_VERSION);
    }
    if (nav.parentNode !== document.body ||
        (nav !== document.body.lastElementChild && otlobliNavIsActuallyCovered(nav))) {
      document.body.appendChild(nav);
    }
    return true;
  }

  function otlobliScheduleChallengeNav() {
    if (otlobliEnsureChallengeNav()) return;
    var mount = function () { try { otlobliEnsureChallengeNav(); } catch (e) {} };
    try { document.addEventListener('DOMContentLoaded', mount, { once: true }); } catch (e) {}
    setTimeout(mount, 250);
    setTimeout(mount, 1000);
  }

  // Verification pages can be injected at documentStart before their title,
  // challenge form, or Cloudflare script exists in the DOM.  URL detection
  // therefore has to happen before any Saudi URL/storage normalization: a
  // redirect during that small parsing window restarts the challenge and can
  // look like a black flash followed by the WebView closing.
  function otlobliIsHumanChallengeUrl(href) {
    try {
      var u = new URL(href || location.href, location.href);
      if (SHEIN_CHALLENGE_PATH_RE.test(u.pathname)) return true;
      if (SHEIN_CHALLENGE_QUERY_RE.test(u.search + u.hash)) return true;
    } catch (e) {}
    return false;
  }

  // On an explicit challenge route leave the document completely untouched.
  // The next successful navigation gets a new document and a fresh injection.
  if (IS_SHEIN && otlobliIsHumanChallengeUrl(location.href)) {
    try { writeSheinSaudiState(); } catch (e) {}
    otlobliEnterChallengeMode();
    return;
  }

  function otlobliNormalizeSheinUrl(href) {
    try {
      var u = new URL(href, location.href);
      if (!/shein/i.test(u.hostname)) return href;
      if (otlobliIsHumanChallengeUrl(u.toString())) return u.toString();
      var cleanPath = u.pathname.replace(/^\\/(?:[a-z]{2}(?:en)?|ar-en|ar)(?=\\/|$)/i, '') || '/';
      u.protocol = 'https:';
      u.hostname = 'm.shein.com';
      u.pathname = '/ar' + (cleanPath === '/' ? '/' : cleanPath);
      u.searchParams.set('currency', SHEIN_REQUIRED_CURRENCY);
      u.searchParams.set('localcountry', SHEIN_REQUIRED_COUNTRY);
      u.searchParams.set('country', SHEIN_REQUIRED_COUNTRY);
      u.searchParams.set('countryCode', SHEIN_REQUIRED_COUNTRY);
      u.searchParams.set('country_code', SHEIN_REQUIRED_COUNTRY);
      u.searchParams.set('lang', SHEIN_REQUIRED_LANGUAGE);
      u.searchParams.set('language', SHEIN_REQUIRED_LANGUAGE);
      u.searchParams.set('ship_to', SHEIN_REQUIRED_COUNTRY);
      u.searchParams.set('shipTo', SHEIN_REQUIRED_COUNTRY);
      u.searchParams.set('shipToCountry', SHEIN_REQUIRED_COUNTRY);
      u.searchParams.set('shippingCountry', SHEIN_REQUIRED_COUNTRY);
      u.searchParams.set('shipping_country', SHEIN_REQUIRED_COUNTRY);
      u.searchParams.set('store_country', SHEIN_REQUIRED_COUNTRY);
      return u.toString();
    } catch (e) {
      return href;
    }
  }

  function writeSheinSaudiState() {
    // Seed once per document. Rewriting cookies/storage on every 300 ms tick
    // races SHEIN's own SPA state and can leave rendered controls unhydrated.
    if (window.__otlobliSheinSaudiStateSeeded) return;
    window.__otlobliSheinSaudiStateSeeded = true;
    try {
      document.cookie = 'language=' + SHEIN_REQUIRED_LANGUAGE + '; path=/; max-age=31536000';
      document.cookie = 'language=' + SHEIN_REQUIRED_LANGUAGE + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'site_uid=' + SHEIN_REQUIRED_SITE_UID + '; path=/; max-age=31536000';
      document.cookie = 'site_uid=' + SHEIN_REQUIRED_SITE_UID + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'currency=' + SHEIN_REQUIRED_CURRENCY + '; path=/; max-age=31536000';
      document.cookie = 'currency=' + SHEIN_REQUIRED_CURRENCY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'localcountry=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'localcountry=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'country=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'country=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'countryCode=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'countryCode=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'country_code=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'country_code=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'ship_to=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'ship_to=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'shipTo=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'shipTo=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'shipToCountry=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'shipToCountry=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'shippingCountry=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'shippingCountry=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'shipping_country=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'shipping_country=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      document.cookie = 'store_country=' + SHEIN_REQUIRED_COUNTRY + '; path=/; max-age=31536000';
      document.cookie = 'store_country=' + SHEIN_REQUIRED_COUNTRY + '; domain=.shein.com; path=/; max-age=31536000';
      try {
        localStorage.setItem('language', SHEIN_REQUIRED_LANGUAGE);
        localStorage.setItem('site_uid', SHEIN_REQUIRED_SITE_UID);
        localStorage.setItem('currency', SHEIN_REQUIRED_CURRENCY);
        localStorage.setItem('localcountry', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('country', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('countryCode', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('country_code', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('ship_to', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('shipTo', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('shipToCountry', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('shippingCountry', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('shipping_country', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('store_country', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('otlobli_shein_country', SHEIN_REQUIRED_COUNTRY);
        localStorage.setItem('otlobli_shein_currency', SHEIN_REQUIRED_CURRENCY);
        sessionStorage.setItem('language', SHEIN_REQUIRED_LANGUAGE);
        sessionStorage.setItem('site_uid', SHEIN_REQUIRED_SITE_UID);
        sessionStorage.setItem('currency', SHEIN_REQUIRED_CURRENCY);
        sessionStorage.setItem('localcountry', SHEIN_REQUIRED_COUNTRY);
        sessionStorage.setItem('country', SHEIN_REQUIRED_COUNTRY);
        sessionStorage.setItem('countryCode', SHEIN_REQUIRED_COUNTRY);
        sessionStorage.setItem('country_code', SHEIN_REQUIRED_COUNTRY);
        sessionStorage.setItem('ship_to', SHEIN_REQUIRED_COUNTRY);
        sessionStorage.setItem('shipTo', SHEIN_REQUIRED_COUNTRY);
        sessionStorage.setItem('shipToCountry', SHEIN_REQUIRED_COUNTRY);
        sessionStorage.setItem('shippingCountry', SHEIN_REQUIRED_COUNTRY);
        sessionStorage.setItem('shipping_country', SHEIN_REQUIRED_COUNTRY);
        sessionStorage.setItem('store_country', SHEIN_REQUIRED_COUNTRY);
      } catch (e) {}
    } catch (e) {}
  }

  function coerceSheinSaudiStorageValue(key, value) {
    var k = String(key || '').toLowerCase();
    if (k === 'currency' || k === 'currencycode' || k === 'currency_code') return SHEIN_REQUIRED_CURRENCY;
    if (k === 'localcountry' || k === 'country' || k === 'countrycode' || k === 'country_code' || k === 'ship_to' || k === 'shipto' || k === 'shiptocountry' || k === 'shippingcountry' || k === 'shipping_country' || k === 'store_country') return SHEIN_REQUIRED_COUNTRY;
    if (k === 'language' || k === 'lang') return SHEIN_REQUIRED_LANGUAGE;
    if (k === 'site_uid') return SHEIN_REQUIRED_SITE_UID;
    return value;
  }

  function clearOvercoercedSheinStorage() {
    if (!IS_SHEIN) return;
    var exact = {
      currency: true,
      currencycode: true,
      currency_code: true,
      localcountry: true,
      country: true,
      countrycode: true,
      country_code: true,
      ship_to: true,
      shipto: true,
      shiptocountry: true,
      shippingcountry: true,
      shipping_country: true,
      store_country: true,
      language: true,
      lang: true,
      site_uid: true
    };
    var riskyKey = /country|currency|region|ship|locale|language|lang|site_uid/i;
    [localStorage, sessionStorage].forEach(function (store) {
      try {
        var keys = [];
        for (var i = 0; i < store.length; i += 1) {
          var key = store.key(i);
          if (!key) continue;
          var lower = String(key).toLowerCase();
          if (exact[lower]) continue;
          var value = store.getItem(key);
          if (riskyKey.test(key) && (value === SHEIN_REQUIRED_COUNTRY || value === SHEIN_REQUIRED_CURRENCY || value === SHEIN_REQUIRED_LANGUAGE)) {
            keys.push(key);
          }
        }
        keys.forEach(function (key) { try { store.removeItem(key); } catch (e) {} });
      } catch (e) {}
    });
  }

  function installSheinSaudiStorageGuard() {
    if (!IS_SHEIN || window.__otlobliSheinSaudiStorageGuard) return;
    window.__otlobliSheinSaudiStorageGuard = true;
    try {
      var originalSetItem = Storage.prototype.setItem;
      Storage.prototype.setItem = function (key, value) {
        return originalSetItem.call(this, key, coerceSheinSaudiStorageValue(key, value));
      };
    } catch (e) {}
  }

  // SHEIN's authoritative shipping choice is not localcountry/ipCountry. The
  // native shipping drawer writes a fully resolved addressCookie only after
  // country -> province -> city -> district are selected. Product APIs read
  // this value even when the exit IP belongs to another country.
  function sheinAddressCookieData() {
    if (!IS_SHEIN) return null;
    try {
      var raw = localStorage.getItem('addressCookie');
      if (!raw) return null;
      var parsed = JSON.parse(raw);
      return parsed && typeof parsed === 'object' ? parsed : null;
    } catch (e) {}
    return null;
  }

  function sheinAddressCookieCountry() {
    if (!IS_SHEIN) return '';
    try {
      var parsed = sheinAddressCookieData();
      if (!parsed) return '';
      var value = String((parsed.value || parsed.countryAbbr || parsed.countryCode) || '').toUpperCase();
      if (/^[A-Z]{2}$/.test(value)) return value;
      var name = String(parsed.countryName || '').trim();
      var countryId = String(parsed.countryId || '').trim();
      if (/^Saudi Arabia$/i.test(name) || countryId === '186') return SHEIN_REQUIRED_COUNTRY;
      // Fully resolved native addresses omit value/countryAbbr and keep only
      // countryName/countryId. Any explicit non-Saudi country is authoritative
      // foreign state, even when the visible PDP label has changed to a
      // district name such as "Zone 1".
      if (name || countryId) return 'FOREIGN';
    } catch (e) {}
    return '';
  }

  // A country-only value is not enough. SHEIN signs the resolved native
  // country/state/city/district tuple in xAdFlag; that signed tuple is what its
  // product APIs actually use for shipping. Never claim readiness before all
  // four levels and the server signature exist.
  function sheinSignedSaudiAddressReady() {
    try {
      var parsed = sheinAddressCookieData();
      if (!parsed) return false;
      var countryOk = String(parsed.countryId || '') === '186' || /^Saudi Arabia$/i.test(String(parsed.countryName || '').trim());
      if (!countryOk) return false;
      var state = String(parsed.stateId || parsed.state || '').trim();
      var city = String(parsed.cityId || parsed.city || '').trim();
      var district = String(parsed.districtId || parsed.district || '').trim();
      var signature = String(parsed.xAdFlag || '').trim();
      return !!(state && city && district && signature);
    } catch (e) {
      return false;
    }
  }

  var sheinNativeCoverInitialReleased = false;
  var sheinNativeCoverRepairActive = false;
  var sheinNativeCoverRepairStartedAt = 0;
  var sheinNativeCoverCooldownUntil = 0;
  var sheinNativeCoverLastType = '';
  var sheinNativeCoverLastPostAt = 0;

  var __otlobliFeedRetryCount = 0;
  var __otlobliFeedRetryAfter = 0;

  function sheinRetryableFeedErrorButton() {
    if (!IS_SHEIN || !document.body) return null;
    var retryPattern = /^(?:try again|retry|\\u062d\\u0627\\u0648\\u0644 \\u0645\\u0631\\u0629 \\u0623\\u062e\\u0631\\u0649|\\u0625\\u0639\\u0627\\u062f\\u0629 \\u0627\\u0644\\u0645\\u062d\\u0627\\u0648\\u0644\\u0629)$/i;
    var errorPattern = /there(?:'|\u2019)?s? (?:an? )?error in our system|something went wrong|system error|\\u0645\\u0639\\u0630\\u0631\\u0629|\\u0647\\u0646\\u0627\\u0643\\s+\\u062e\\u0637\\u0623\\s+\\u0645\\u0627\\s+\\u0641\\u064a\\s+\\u0646\\u0638\\u0627\\u0645\\u0646\\u0627/i;
    var controls = document.querySelectorAll('button, [role="button"], a');
    for (var i = 0; i < controls.length; i++) {
      var control = controls[i];
      var label = String(control.innerText || control.textContent || '').replace(/\\s+/g, ' ').trim();
      if (!retryPattern.test(label)) continue;
      var scope = control;
      for (var hop = 0; scope && hop < 6; hop++, scope = scope.parentElement) {
        var text = String(scope.innerText || scope.textContent || '').replace(/\\s+/g, ' ').trim();
        if (text.length > 0 && text.length < 1400 && errorPattern.test(text)) return control;
      }
    }
    return null;
  }

  function retrySheinFeedError() {
    if (__otlobliFeedRetryCount >= 4 || Date.now() < __otlobliFeedRetryAfter) return;
    var retry = sheinRetryableFeedErrorButton();
    if (!retry || retry.disabled) return;
    var rect = retry.getBoundingClientRect();
    if (!rect || rect.width < 20 || rect.height < 20) return;
    __otlobliFeedRetryCount++;
    var delays = [900, 1500, 2400, 4000];
    __otlobliFeedRetryAfter = Date.now() + delays[Math.min(__otlobliFeedRetryCount - 1, delays.length - 1)];
    try { retry.click(); } catch (e) {}
  }

  // browserPageLoaded only proves that WKNavigation finished. SHEIN can still
  // be a partially hydrated shell (section labels with no products/touchable
  // SPA), which is the exact frozen state reported on the second iOS entry.
  // Require live, visible store content before native code accepts readiness.
  function sheinPageLooksInteractive() {
    if (!IS_SHEIN || !document.body || document.readyState === 'loading') return false;
    if (otlobliIsHumanChallenge()) return true;
    if (sheinRetryableFeedErrorButton()) return false;
    var bodyText = String(document.body.innerText || '').replace(/\\s+/g, ' ').trim();
    if (bodyText.length < 180) return false;

    var interactiveCount = 0;
    var controls = document.querySelectorAll('a[href], button, [role="button"], input, select');
    for (var ci = 0; ci < controls.length && interactiveCount < 4; ci++) {
      var control = controls[ci];
      if (!control || (control.id && control.id.indexOf('otlobli') === 0)) continue;
      if (control.closest && control.closest('[id^="otlobli"]')) continue;
      var cr = control.getBoundingClientRect();
      if (!cr || cr.width < 12 || cr.height < 12 || cr.bottom <= 0 || cr.top >= window.innerHeight) continue;
      var ccs = window.getComputedStyle(control);
      if (ccs.display === 'none' || ccs.visibility === 'hidden' || Number(ccs.opacity || 1) < 0.1 || ccs.pointerEvents === 'none') continue;
      interactiveCount++;
    }

    var loadedImageCount = 0;
    var images = document.images || [];
    for (var ii = 0; ii < images.length && loadedImageCount < 3; ii++) {
      var image = images[ii];
      if (!image || !image.complete || image.naturalWidth < 40 || image.naturalHeight < 40) continue;
      if (image.closest && image.closest('[id^="otlobli"]')) continue;
      var ir = image.getBoundingClientRect();
      if (!ir || ir.width < 24 || ir.height < 24 || ir.bottom <= 0 || ir.top >= window.innerHeight * 1.5) continue;
      loadedImageCount++;
    }

    var homeLike = /^\\/ar\\/?$/i.test(location.pathname || '');
    if (homeLike) return interactiveCount >= 3 && loadedImageCount >= 2;
    return interactiveCount >= 1 && (loadedImageCount >= 1 || bodyText.length >= 500);
  }

  function sheinPostNativeCoverState(type) {
    if (!IS_SHEIN) return;
    var now = Date.now();
    if (type === sheinNativeCoverLastType && now - sheinNativeCoverLastPostAt < 750) return;
    sheinNativeCoverLastType = type;
    sheinNativeCoverLastPostAt = now;
    try {
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: type } });
      }
    } catch (e) {}
  }

  // The first call only asks native code to place the already-approved loading
  // cover above this same, fully laid-out WebView. The automatic native click is
  // deliberately delayed until a later tick so no country drawer frame can be
  // painted in front of the customer.
  function sheinPrepareNativeSaudiRepair() {
    if (sheinNativeCoverRepairActive) return true;
    var now = Date.now();
    if (now < sheinNativeCoverCooldownUntil) return false;
    sheinNativeCoverRepairActive = true;
    sheinNativeCoverRepairStartedAt = now;
    sheinPostNativeCoverState('sheinSaudiRepairStart');
    return false;
  }

  function updateSheinNativeCoverState() {
    if (!IS_SHEIN) return;
    if (sheinSignedSaudiAddressReady()) {
      sheinNativeCoverRepairActive = false;
      sheinNativeCoverRepairStartedAt = 0;
      if (sheinPageLooksInteractive()) {
        sheinNativeCoverInitialReleased = true;
        sheinPostNativeCoverState('sheinSaudiReady');
      }
      return;
    }
    if (sheinNativeCoverRepairActive) {
      if (Date.now() - sheinNativeCoverRepairStartedAt >= 15000) {
        // Never trap the customer behind a cover when SHEIN changes its drawer
        // or a security check interrupts the cascade. The bounded click guard
        // already stops further automation; wait before one clean retry.
        sheinNativeCoverRepairActive = false;
        sheinNativeCoverRepairStartedAt = 0;
        sheinNativeCoverCooldownUntil = Date.now() + 120000;
        if (sheinPageLooksInteractive()) {
          sheinNativeCoverInitialReleased = true;
          sheinPostNativeCoverState('sheinPageInteractive');
        }
      }
      return;
    }
    if (!sheinNativeCoverInitialReleased && sheinPageLooksInteractive()) {
      sheinNativeCoverInitialReleased = true;
      sheinPostNativeCoverState('sheinPageInteractive');
    }
  }

  function sheinSaudiSignalsOk() {
    try {
      var u = new URL(location.href);
      if (!/(^|\\.)m\\.shein\\.com$/i.test(u.hostname)) return false;
      if (!/^\\/ar(?:\\/|$)/i.test(u.pathname)) return false;
      var country = u.searchParams.get('country');
      var localcountry = u.searchParams.get('localcountry');
      var currency = u.searchParams.get('currency');
      var lang = u.searchParams.get('lang');
      if (localcountry && localcountry !== SHEIN_REQUIRED_COUNTRY) return false;
      if (country && country !== SHEIN_REQUIRED_COUNTRY) return false;
      if (currency && currency !== SHEIN_REQUIRED_CURRENCY) return false;
      if (lang && lang !== SHEIN_REQUIRED_LANGUAGE) return false;
    } catch (e) {
      return false;
    }
    try {
      if (localStorage.getItem('localcountry') && localStorage.getItem('localcountry') !== SHEIN_REQUIRED_COUNTRY) return false;
      if (localStorage.getItem('country') && localStorage.getItem('country') !== SHEIN_REQUIRED_COUNTRY) return false;
      if (localStorage.getItem('currency') && localStorage.getItem('currency') !== SHEIN_REQUIRED_CURRENCY) return false;
      if (sessionStorage.getItem('localcountry') && sessionStorage.getItem('localcountry') !== SHEIN_REQUIRED_COUNTRY) return false;
      if (sessionStorage.getItem('country') && sessionStorage.getItem('country') !== SHEIN_REQUIRED_COUNTRY) return false;
      if (sessionStorage.getItem('currency') && sessionStorage.getItem('currency') !== SHEIN_REQUIRED_CURRENCY) return false;
    } catch (e) {}
    var addressCountry = sheinAddressCookieCountry();
    if (addressCountry && addressCountry !== SHEIN_REQUIRED_COUNTRY) return false;
    if (sheinVisibleForeignRegion()) return false;
    return true;
  }

  function sheinShippingRegionFromText(value) {
    try {
      var text = String(value || '').replace(/\\s+/g, ' ').trim();
      var match = text.match(/(?:Shipping|Ships?|Delivery|Deliver(?:ing)?|الشحن|التوصيل)\\s*(?:to|إلى|الي|ل)?\\s*(Saudi Arabia|السعودية|المملكة العربية السعودية|Bahrain|United Kingdom|United States|UAE|Kuwait|Qatar|Oman|Jordan|البحرين|الإمارات|الكويت|قطر|عمان|الأردن)(?:\\b|(?=\\s|$|[،,.;:()]))/i);
      if (!match) return '';
      return /Saudi Arabia|السعودية/i.test(match[1] || '') ? 'SA' : 'FOREIGN';
    } catch (e) {
      return '';
    }
  }

  function sheinVisibleShippingRegion() {
    if (!IS_SHEIN || !document.body) return '';
    // A login form also contains "Saudi Arabia" as the +966 phone country.
    // That is not a shipping signal. Only accept a country when SHEIN itself
    // places it next to an explicit shipping/delivery label.
    return sheinShippingRegionFromText((document.body.innerText || '').slice(0, 30000));
  }

  function sheinVisibleForeignRegion() {
    return sheinVisibleShippingRegion() === 'FOREIGN';
  }

  function sheinVisibleSaudiRegion() {
    return sheinVisibleShippingRegion() === 'SA';
  }

  function sheinUiText(el) {
    return String(el && el.textContent || '')
      .replace(/[\u200e\u200f\u202a-\u202e]/g, '')
      .replace(/\\s+/g, ' ')
      .trim();
  }

  function sheinExactSaudiOptionText(value) {
    var text = String(value || '')
      .replace(/[\u200e\u200f\u202a-\u202e]/g, '')
      .replace(/\\s+/g, ' ')
      .trim();
    return /^(?:Saudi Arabia|السعودية|المملكة العربية السعودية)$/i.test(text);
  }

  // Verified against SHEIN's own "shipping to" screen: a real selector has a
  // location heading plus several GCC destinations. Requiring this full shape
  // avoids mistaking the +966 country picker in sign-in for shipping settings.
  function sheinShippingPickerVisible() {
    if (!IS_SHEIN || !document.body) return false;
    var text = String(document.body.innerText || '').slice(0, 30000);
    var hasHeading = /(?:Choose|Select)\\s+(?:a\\s+)?location|اختيار\\s+موقع/i.test(text);
    var hasBahrain = /Bahrain|البحرين/i.test(text);
    var hasSaudi = /Saudi Arabia|السعودية/i.test(text);
    var neighborCount = 0;
    if (/Kuwait|الكويت/i.test(text)) neighborCount++;
    if (/Lebanon|لبنان/i.test(text)) neighborCount++;
    if (/Oman|عمان/i.test(text)) neighborCount++;
    if (/Qatar|قطر/i.test(text)) neighborCount++;
    return hasHeading && hasBahrain && hasSaudi && neighborCount >= 2;
  }

  function sheinElementIsVisible(el) {
    if (!el || !el.getBoundingClientRect) return false;
    try {
      var rect = el.getBoundingClientRect();
      if (!rect || rect.width <= 0 || rect.height <= 0) return false;
      var style = window.getComputedStyle(el);
      return style.display !== 'none' && style.visibility !== 'hidden' && style.pointerEvents !== 'none' && parseFloat(style.opacity || '1') > 0;
    } catch (e) {
      return false;
    }
  }

  function sheinClosestInteractive(el) {
    var node = el;
    var depth = 0;
    while (node && node !== document.body && node !== document.documentElement && depth < 7) {
      var tag = String(node.tagName || '').toUpperCase();
      var role = node.getAttribute && String(node.getAttribute('role') || '').toLowerCase();
      var nativeControl = tag === 'BUTTON' || tag === 'A' || tag === 'LI' || tag === 'LABEL';
      var semanticControl = role === 'button' || role === 'option' || role === 'menuitem' || role === 'link';
      var hasHandler = typeof node.onclick === 'function';
      var pointer = false;
      try { pointer = window.getComputedStyle(node).cursor === 'pointer'; } catch (e) {}
      if (nativeControl || semanticControl || hasHandler || pointer) return node;
      node = node.parentElement;
      depth++;
    }
    return el;
  }

  function sheinBestVisibleControl(textTest) {
    if (!document.body) return null;
    var nodes = document.querySelectorAll('button,a,[role="button"],[role="option"],[role="menuitem"],li,div,span');
    var best = null;
    var bestScore = -1;
    var max = Math.min(nodes.length, 12000);
    for (var i = 0; i < max; i++) {
      var node = nodes[i];
      if (!node || (node.id && node.id.indexOf('otlobli') === 0)) continue;
      var text = sheinUiText(node);
      if (!text || text.length > 180 || !textTest(text)) continue;
      var target = sheinClosestInteractive(node);
      if (!target || (target.id && target.id.indexOf('otlobli') === 0) || !sheinElementIsVisible(target)) continue;
      var targetText = sheinUiText(target);
      if (!targetText || targetText.length > 220) continue;
      var score = (target === node ? 4 : 2) + (node.children && node.children.length === 0 ? 3 : 0) + (220 - targetText.length) / 220;
      if (score > bestScore) {
        best = target;
        bestScore = score;
      }
    }
    return best;
  }

  function sheinFindSaudiShippingOption() {
    return sheinBestVisibleControl(function (text) { return sheinExactSaudiOptionText(text); });
  }

  function sheinFindForeignShippingControl() {
    // On current PDPs the explicit "shipping to <country>" label lives on a
    // non-semantic wrapper, while the actual native control is its child
    // button whose text is only the country name. The generic text scanner
    // therefore sees the foreign region but cannot identify a clickable
    // ancestor. Prefer this narrow SHEIN-owned control before the fallback.
    var productTitle = document.querySelector('.productShippingTitle');
    var addressCountry = sheinAddressCookieCountry();
    if (productTitle && sheinElementIsVisible(productTitle)
      && (sheinShippingRegionFromText(sheinUiText(productTitle)) === 'FOREIGN'
        || (addressCountry && addressCountry !== SHEIN_REQUIRED_COUNTRY))) {
      var productButton = productTitle.querySelector('button.productShippingTitle__text-container,button');
      if (productButton && sheinElementIsVisible(productButton)) return productButton;
      return productTitle;
    }
    return sheinBestVisibleControl(function (text) {
      return sheinShippingRegionFromText(text) === 'FOREIGN';
    });
  }

  function sheinVisibleCascadeOptions() {
    if (!document.body) return [];
    // SHEIN currently serves two native address drawers. One uses the
    // cascade/role=option markup; the other uses a letter-grouped upper-list.
    // Both are scoped to the visible drawer so product/listing <li> elements
    // can never become automatic address targets.
    var nodes = document.querySelectorAll(
      'li.cascade__list--option,[role="option"],.sui-drawer__body ul.upper-list > li'
    );
    var result = [];
    for (var i = 0; i < nodes.length; i++) {
      if (sheinElementIsVisible(nodes[i])) result.push(nodes[i]);
    }
    return result;
  }

  function sheinVisibleShippingTabs() {
    if (!document.body) return [];
    var nodes = document.querySelectorAll('button[role="tab"]');
    var result = [];
    for (var i = 0; i < nodes.length; i++) {
      if (sheinElementIsVisible(nodes[i])) result.push(nodes[i]);
    }
    return result;
  }

  function sheinFindExactCascadeOption(pattern) {
    var options = sheinVisibleCascadeOptions();
    for (var i = 0; i < options.length; i++) {
      if (pattern.test(sheinUiText(options[i]))) return options[i];
    }
    return null;
  }

  // Complete SHEIN's own native address cascade. Selecting the country alone
  // only changes the drawer tab and does not persist shipping. These exact
  // options were observed from SHEIN's live Saudi address data.
  function sheinNativeSaudiAddressStep(addressCountry) {
    var options = sheinVisibleCascadeOptions();
    var tabs = sheinVisibleShippingTabs();
    if (!options.length || !document.querySelector('.productShippingTitle')) return false;

    var target = null;
    for (var i = 0; i < options.length; i++) {
      if (sheinExactSaudiOptionText(sheinUiText(options[i]))) {
        target = options[i];
        break;
      }
    }
    if (!target) target = sheinFindExactCascadeOption(/^Riyadh Province(?:\\/|$)/i);
    if (!target) target = sheinFindExactCascadeOption(/^Riyadh(?:\\/|$)/i);
    if (!target) target = sheinFindExactCascadeOption(/^Al Olaya(?:\\/|$)/i);
    if (target) return sheinClickNativeShippingControl(target);

    if (addressCountry && addressCountry !== SHEIN_REQUIRED_COUNTRY) {
      var countryTab = tabs[0];
      if (countryTab && !sheinExactSaudiOptionText(sheinUiText(countryTab))) {
        return sheinClickNativeShippingControl(countryTab);
      }
    }
    return false;
  }

  function isSheinShippingRegionControl(el) {
    var node = el;
    var depth = 0;
    while (node && node !== document.body && node !== document.documentElement && depth < 8) {
      if (node.getAttribute && node.getAttribute('data-otlobli-shein-shipping-action') === '1') return true;
      var text = sheinUiText(node);
      if (text.length <= 180 && sheinShippingRegionFromText(text)) return true;
      if (text.length <= 80 && sheinExactSaudiOptionText(text) && sheinShippingPickerVisible()) return true;
      node = node.parentElement;
      depth++;
    }
    return false;
  }

  var sheinShippingActionCount = 0;
  var sheinShippingLastActionAt = 0;
  var sheinShippingLastScanAt = 0;
  var sheinShippingCloseLastAt = 0;
  // Slower devices (iPhone 6) need more attempts: each cascade level can take
  // longer than the re-click gap to render, so some clicks get spent retrying.
  // Give the whole country->province->city->district run a generous bounded
  // budget so the final district option is always reached and clicked. Paired
  // with the same-option guard below so the extra budget is not wasted.
  var SHEIN_SHIPPING_MAX_ACTIONS = 24;
  var sheinShippingLastOptionText = '';
  var sheinShippingLastOptionAt = 0;

  function sheinClickNativeShippingControl(target) {
    if (!target || typeof target.click !== 'function') return false;
    if (!sheinPrepareNativeSaudiRepair()) return false;
    var now = Date.now();
    if (now - sheinShippingLastActionAt < 1200) return false;
    // Don't waste the click budget re-tapping the same cascade option while a
    // slow device is still rendering the next level; give it up to 3s to change.
    var targetText = sheinUiText(target);
    if (targetText && targetText === sheinShippingLastOptionText && now - sheinShippingLastOptionAt < 3000) return false;
    // Opening the drawer and resolving country/province/city/district takes up
    // to six native clicks; slow devices need extra retries, so the budget is
    // generous but still bounded (see SHEIN_SHIPPING_MAX_ACTIONS).
    if (sheinShippingActionCount >= SHEIN_SHIPPING_MAX_ACTIONS) {
      if (now - sheinShippingLastActionAt < 120000) return false;
      sheinShippingActionCount = 0;
    }
    sheinShippingLastActionAt = now;
    sheinShippingActionCount++;
    sheinShippingLastOptionText = targetText;
    sheinShippingLastOptionAt = now;
    target.removeAttribute('data-otlobli-blocked');
    target.setAttribute('data-otlobli-shein-shipping-action', '1');
    try {
      target.click();
      return true;
    } catch (e) {
      return false;
    } finally {
      setTimeout(function () {
        try { target.removeAttribute('data-otlobli-shein-shipping-action'); } catch (e) {}
      }, 1500);
    }
  }

  // Once SHEIN has written its signed Saudi address, close only the native
  // address surface that performed that selection. This never navigates,
  // clears storage, or clicks a generic page button; it is deliberately
  // limited to a visible shipping drawer and its exact close/confirm action.
  function sheinResolvedShippingUiRoot() {
    if (!document.body) return null;
    var vp = { width: window.innerWidth || 0, height: window.innerHeight || 0 };
    var options = sheinVisibleCascadeOptions();
    var tabs = sheinVisibleShippingTabs();
    var seed = options[0] || tabs[0] || null;
    var matched = null;

    function inspect(el) {
      if (!el || el === document.body || el === document.documentElement || !sheinElementIsVisible(el)) return false;
      var rect = el.getBoundingClientRect();
      if (rect.width < vp.width * 0.72 || rect.height < vp.height * 0.2) return false;
      var text = sheinUiText(el);
      if (!text || text.length > 6500) return false;
      var hasSaudi = /Saudi Arabia|\\u0627\\u0644\\u0633\\u0639\\u0648\\u062f\\u064a\\u0629/i.test(text);
      var hasAddressShape = /(?:Choose|Select)\\s+(?:a\\s+)?location|Riyadh|Al Olaya|Bahrain|\\u0627\\u062e\\u062a\\u064a\\u0627\\u0631\\s+\\u0645\\u0648\\u0642\\u0639|\\u0627\\u0644\\u0631\\u064a\\u0627\\u0636|\\u0627\\u0644\\u0628\\u062d\\u0631\\u064a\\u0646/i.test(text);
      return hasSaudi && hasAddressShape;
    }

    if (seed) {
      var current = seed;
      for (var depth = 0; current && current !== document.body && depth < 9; current = current.parentElement, depth++) {
        if (inspect(current)) matched = current;
      }
      if (matched) return matched;
    }

    var candidates = document.querySelectorAll(
      '.sui-drawer__body,[role="dialog"],[aria-modal="true"],[class*="drawer"],[class*="cascade"]'
    );
    for (var i = candidates.length - 1; i >= 0; i--) {
      var candidateRoot = null;
      for (var candidate = candidates[i], hop = 0; candidate && candidate !== document.body && hop < 5; candidate = candidate.parentElement, hop++) {
        if (inspect(candidate)) candidateRoot = candidate;
      }
      if (candidateRoot) return candidateRoot;
    }
    return null;
  }

  function closeResolvedSheinShippingUi() {
    if (!sheinSignedSaudiAddressReady()) return false;
    var now = Date.now();
    if (now - sheinShippingCloseLastAt < 1200) return false;
    var root = sheinResolvedShippingUiRoot();
    if (!root) return false;
    var controls = root.querySelectorAll('button, a, [role="button"], input[type="button"], input[type="submit"]');
    var closePattern = /^(?:close|dismiss|done|\\u00d7|\\u2715|\\u2716|\\u0625\\u063a\\u0644\\u0627\\u0642|\\u0627\\u063a\\u0644\\u0627\\u0642|\\u062a\\u0645)$/i;
    var confirmPattern = /^(?:continue|confirm|save|\\u0645\\u062a\\u0627\\u0628\\u0639\\u0629|\\u062a\\u0623\\u0643\\u064a\\u062f|\\u062d\\u0641\\u0638)$/i;
    var closeTarget = null;
    var confirmTarget = null;
    for (var i = 0; i < controls.length; i++) {
      var control = controls[i];
      if (!control || (control.id && control.id.indexOf('otlobli') === 0) || !sheinElementIsVisible(control)) continue;
      var label = String(control.innerText || control.textContent || control.value ||
        control.getAttribute('aria-label') || control.getAttribute('title') || '')
        .replace(/\\s+/g, ' ').trim();
      if (closePattern.test(label)) { closeTarget = control; break; }
      if (!confirmTarget && confirmPattern.test(label)) confirmTarget = control;
      if (!closeTarget) {
        var hint = String((control.className || '') + ' ' + (control.id || '') + ' ' +
          (control.getAttribute('aria-label') || '') + ' ' + (control.getAttribute('title') || '')).toLowerCase();
        var rect = control.getBoundingClientRect();
        var rootRect = root.getBoundingClientRect();
        if (/close|dismiss|drawer-close|popup-close/.test(hint) && rect.width <= 72 && rect.height <= 72 &&
            rect.top <= rootRect.top + Math.max(96, rootRect.height * 0.2)) {
          closeTarget = control;
        }
      }
    }
    var target = closeTarget || confirmTarget;
    if (!target) return false;
    sheinShippingCloseLastAt = now;
    target.setAttribute('data-otlobli-shein-shipping-action', '1');
    try {
      target.click();
      return true;
    } catch (e) {
      return false;
    } finally {
      setTimeout(function () {
        try { target.removeAttribute('data-otlobli-shein-shipping-action'); } catch (e) {}
      }, 1500);
    }
  }

  function ensureSheinSaudiShippingSelection() {
    if (!IS_SHEIN || !document.body || document.readyState === 'loading') return;
    var now = Date.now();
    // tick() runs every 300 ms. DOM-wide text/control inspection does not need
    // that frequency and would be needlessly expensive on older iPhones.
    if (now - sheinShippingLastScanAt < 900) return;
    sheinShippingLastScanAt = now;
    var addressCountry = sheinAddressCookieCountry();
    if (addressCountry === SHEIN_REQUIRED_COUNTRY && sheinSignedSaudiAddressReady()) {
      sheinShippingActionCount = 0;
      closeResolvedSheinShippingUi();
      return;
    }
    if (sheinShippingActionCount >= SHEIN_SHIPPING_MAX_ACTIONS && now - sheinShippingLastActionAt < 120000) return;
    if (now - sheinShippingLastActionAt < 1200) return;
    if (sheinNativeSaudiAddressStep(addressCountry)) return;
    // A native address drawer may be between async cascade stages. Never
    // click the underlying PDP shipping button while that drawer is visible;
    // doing so merely closes it and restarts the selection.
    if (sheinVisibleCascadeOptions().length || sheinVisibleShippingTabs().length) return;
    var visibleRegion = sheinVisibleShippingRegion();
    if (visibleRegion === 'SA') {
      return;
    }
    if (visibleRegion === 'FOREIGN' || (addressCountry && addressCountry !== SHEIN_REQUIRED_COUNTRY)) {
      sheinClickNativeShippingControl(sheinFindForeignShippingControl());
    }
  }

  // Keep region failure internal. The old visible reset button cleared broad
  // storage keys and reloaded SHEIN, which could restart Cloudflare or damage
  // the active SPA. Browsing remains interactive; add-to-cart has its own guard.
  function setSheinSaudiGuardOverlay(visible) {
    if (!IS_SHEIN) return;
    var id = 'otlobli-shein-saudi-guard';
    var old = document.getElementById(id);
    if (old) old.remove();
    if (document.documentElement) document.documentElement.classList.remove('otlobli-shein-saudi-locked');
  }

  function shouldReloadSheinForSaudi() {
    try {
      var u = new URL(location.href);
      if (otlobliIsHumanChallengeUrl(u.toString())) return false;
      if (!/(^|\\.)m\\.shein\\.com$/i.test(u.hostname)) return true;
      if (!/^\\/ar(?:\\/|$)/i.test(u.pathname)) return true;
      var country = u.searchParams.get('country');
      var localcountry = u.searchParams.get('localcountry');
      var currency = u.searchParams.get('currency');
      var lang = u.searchParams.get('lang');
      return (!!localcountry && localcountry !== SHEIN_REQUIRED_COUNTRY) ||
        (!!country && country !== SHEIN_REQUIRED_COUNTRY) ||
        (!!currency && currency !== SHEIN_REQUIRED_CURRENCY) ||
        (!!lang && lang !== SHEIN_REQUIRED_LANGUAGE);
    } catch (e) {
      return false;
    }
  }

  function ensureSheinSaudiStore(options) {
    if (!IS_SHEIN) return true;
    // أثناء تحقق «أنا إنسان»: ممنوع أي إعادة تحميل/كتابة — تصفّر حل المستخدم.
    if (otlobliIsHumanChallenge()) return false;
    installSheinSaudiStorageGuard();
    writeSheinSaudiState();
    var normalized = otlobliNormalizeSheinUrl(location.href);
    var addressCountry = sheinAddressCookieCountry();
    var visibleForeignRegion = addressCountry === SHEIN_REQUIRED_COUNTRY ? false : sheinVisibleForeignRegion();
    if (visibleForeignRegion) {
      window.__otlobliSheinSaudiLocked = true;
      try { sessionStorage.setItem('__otlobliSheinSaudiLocked', '1'); } catch (e) {}
    } else if (addressCountry === SHEIN_REQUIRED_COUNTRY || sheinVisibleSaudiRegion()) {
      window.__otlobliSheinSaudiLocked = false;
      try { sessionStorage.removeItem('__otlobliSheinSaudiLocked'); } catch (e) {}
    }
    var locked = !!window.__otlobliSheinSaudiLocked;
    try { locked = locked || sessionStorage.getItem('__otlobliSheinSaudiLocked') === '1'; } catch (e) {}
    var signalsOk = sheinSaudiSignalsOk();
    var needsReload = shouldReloadSheinForSaudi();
    setSheinSaudiGuardOverlay(locked || visibleForeignRegion);
    if (needsReload || !signalsOk) {
      if (options && options.navigate) {
        var guardKey = '__otlobliSaudiRedirects:' + normalized + ':' + Math.floor(Date.now() / 30000);
        var attempts = parseInt(sessionStorage.getItem(guardKey) || '0', 10);
        if (!locked && attempts < 2) {
          sessionStorage.setItem(guardKey, String(attempts + 1));
          location.replace(normalized);
          return false;
        }
      }
      try {
        history.replaceState(history.state, '', normalized);
      } catch (e) {}
      if (locked || visibleForeignRegion) return false;
    } else if (normalized !== location.href) {
      try {
        history.replaceState(history.state, '', normalized);
      } catch (e) {}
    }
    try {
      var ok = sheinSaudiSignalsOk();
      if (ok && sheinVisibleSaudiRegion()) {
        window.__otlobliSheinSaudiLocked = false;
        try { sessionStorage.removeItem('__otlobliSheinSaudiLocked'); } catch (e) {}
        setSheinSaudiGuardOverlay(false);
      }
      return ok;
    } catch (e) {
      return false;
    }
  }

  // منطق فرض اللغة العربية خاص بمواقع شي إن فقط - على المتاجر الأخرى (تيمو/
  // ترينديول) قد يضبط كوكي لغة خاطئة ويسبب إعادة تحميل بلا داعٍ، فنحصره بشي إن.
  if (IS_SHEIN) {
    clearOvercoercedSheinStorage();
    installSheinSaudiStorageGuard();
    var normalizedArabicUrl = otlobliNormalizeSheinUrl(location.href);
    // حارس صفحة تحقق «أنا إنسان»: ممنوع أي إعادة تحميل أثناءها — تُعيد بدء
    // التحقق فلا يُكمله المستخدم أبداً (كان سبباً في «يطلعني/واجهة صورة»).
    if (shouldReloadSheinForSaudi() && !otlobliIsHumanChallenge()) {
      var arRedirectAttempts = parseInt(sessionStorage.getItem('__otlobliArRedirects') || '0', 10);
      if (arRedirectAttempts < 2) {
        sessionStorage.setItem('__otlobliArRedirects', String(arRedirectAttempts + 1));
        location.replace(normalizedArabicUrl);
        return;
      }
    } else if (normalizedArabicUrl !== location.href) {
      try {
        history.replaceState(history.state, '', normalizedArabicUrl);
      } catch (e) {}
    }
    writeSheinSaudiState();
    if (document.documentElement) {
      document.documentElement.setAttribute('lang', 'ar');
      document.documentElement.setAttribute('dir', 'rtl');
    }
  }

  // Current Temu routing is native-level /sa/ + USD in App.tsx; keep this script from fighting it.
  // التحويل لـ temu.com/jo/ يتم على المستوى الأصلي (urlChangeEvent في App.tsx) قبل
  // تحميل الصفحة؛ التحويل JS كان يتعارض معه ويسبب شاشة بيضاء على بعض المنتجات.

  if (window.__otlobliInjected) return;
  window.__otlobliInjected = true;

  // Remembers the very first page this webview session landed on (the
  // SHEIN home root), persisted in sessionStorage since this whole script
  // re-runs fresh on every navigation. Used to tell "the user is at the
  // top, nothing to go back to" apart from "the user navigated somewhere
  // and there's a real previous page" - relying on history.length for that
  // is unsafe because the language-redirect reload above (and SHEIN's own
  // Cloudflare verification redirect before that) can leave extra entries
  // in history that aren't real user navigation, so a plain history.back()
  // from the home root can land back on a half-finished verification page
  // instead of just doing nothing.
  if (!sessionStorage.getItem('__otlobliHomePath')) {
    sessionStorage.setItem('__otlobliHomePath', location.pathname);
  }
  function looksLikeHomeRoot() {
    var homePath = (sessionStorage.getItem('__otlobliHomePath') || '').replace(/\\/+$/, '');
    return location.pathname.replace(/\\/+$/, '') === homePath;
  }

  // This WebView (hosted inside a native Dialog) reports window.innerWidth/innerHeight
  // as 0, which breaks "position:fixed; left/right/bottom" math for our overlays
  // (they render collapsed, off-screen). document.documentElement.clientWidth/Height
  // stay correct, so compute pixel positions from those instead of CSS viewport units.
  function viewportSize() {
    return {
      width: document.documentElement.clientWidth || window.innerWidth || 360,
      height: document.documentElement.clientHeight || window.innerHeight || 640,
    };
  }

  function ensureNoTextSelection() {
    if (!document.head) return;
    if (document.getElementById('otlobli-no-select-style')) return;
    var style = document.createElement('style');
    style.id = 'otlobli-no-select-style';
    style.textContent =
      'html,body,body *:not(input):not(textarea):not(select):not([contenteditable]){' +
      '-webkit-user-select:none!important;user-select:none!important;-webkit-touch-callout:none!important;}' +
      'input,textarea,select,[contenteditable]{' +
      '-webkit-user-select:text!important;user-select:text!important;-webkit-touch-callout:default!important;}';
    document.head.appendChild(style);
  }

  function cleanTitle(raw) {
    return (raw || '')
      .replace(/<[^>]*>/g, '')
      .replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&quot;/g, '"')
      .replace(/\\s*\\|\\s*SHEIN.*/i, '').replace(/\\s*-\\s*SHEIN.*/i, '')
      .trim();
  }

  function getMeta(prop) {
    var el = document.querySelector('meta[property="' + prop + '"]') || document.querySelector('meta[name="' + prop + '"]');
    return el ? (el.getAttribute('content') || '') : '';
  }

  // SHEIN (like most e-commerce sites) embeds a Schema.org Product block as
  // <script type="application/ld+json">. It's server-rendered into the initial
  // HTML for SEO, so unlike CSS-class-based scraping it doesn't depend on
  // guessing SHEIN's current class names (which break silently whenever they
  // ship a redesign) and it's available even very early in the page load.
  // This is the primary, most reliable source for name/image/price.
  var __otlobliLdCache = null;
  var __otlobliLdCacheUrl = '';
  function getProductJsonLd() {
    if (__otlobliLdCacheUrl === location.href && __otlobliLdCache !== null) return __otlobliLdCache;
    __otlobliLdCacheUrl = location.href;
    __otlobliLdCache = null;
    try {
      var scripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (var i = 0; i < scripts.length; i++) {
        var data;
        try { data = JSON.parse(scripts[i].textContent || ''); } catch (e) { continue; }
        var list = Array.isArray(data) ? data : (data && data['@graph'] ? data['@graph'] : [data]);
        for (var j = 0; j < list.length; j++) {
          var node = list[j];
          var type = node && node['@type'];
          var isProduct = type === 'Product' || (Array.isArray(type) && type.indexOf('Product') !== -1);
          if (node && isProduct) { __otlobliLdCache = node; return node; }
        }
      }
    } catch (e) {}
    return null;
  }

  // SHEIN's <title> tag briefly (or sometimes permanently, on this site) holds
  // a generic site-wide tagline rather than the product name - "Women's and
  // men's clothing, shop fashion on the site | SHEIN" rather than the actual
  // item. Treat that as "no title yet" so retries keep trying the real
  // sources instead of locking onto the generic tagline on the first attempt.
  function looksGenericTitle(t) {
    if (!t) return true;
    return /شي\\s*إن|shein/i.test(t) && /(تسوق|fashion|shop|الموضة)/i.test(t);
  }

  function getTitle(allowGenericFallback) {
    var ld = getProductJsonLd();
    if (ld && ld.name) {
      var fromLd = cleanTitle(ld.name);
      if (fromLd) return fromLd;
    }
    var fromMeta = cleanTitle(getMeta('og:title'));
    if (fromMeta && !looksGenericTitle(fromMeta)) return fromMeta;
    var el = document.querySelector('h1, .product-intro__head-name, .goods-name, [class*="goods-name" i], [class*="product-name" i], [class*="head-name" i]');
    var fromEl = cleanTitle(el ? el.textContent : '');
    if (fromEl && !looksGenericTitle(fromEl)) return fromEl;
    if (fromMeta) return fromMeta;
    if (fromEl) return fromEl;
    if (!allowGenericFallback) return '';
    // Absolute last resort, only once we've given up retrying for a real name.
    return cleanTitle(document.title);
  }

  function getPrice() {
    var ld = getProductJsonLd();
    if (ld && ld.offers) {
      var offers = Array.isArray(ld.offers) ? ld.offers[0] : ld.offers;
      var ldPrice = offers && parseFloat(offers.price || offers.lowPrice);
      if (ldPrice > 0) return ldPrice;
    }
    var metaPrice = parseFloat(getMeta('product:price:amount'));
    if (metaPrice > 0) return metaPrice;
    var el = document.querySelector('.product-price .price-content, .product-intro__head-price, [class*="price" i]');
    var text = el ? (el.textContent || '') : '';
    var match = text.match(/[0-9]+\\.?[0-9]*/);
    return match ? parseFloat(match[0]) : 0;
  }

  // Lazy-loaded SHEIN images often keep a tiny placeholder/blank gif in "src"
  // until they scroll into view, with the real photo sitting in a data-* attr.
  // Reading "src" directly grabs the placeholder, so we check those first.
  // ".src"/".currentSrc" are DOM properties the browser already resolves to a
  // full absolute URL. The raw data-* attributes are NOT resolved though -
  // sites very commonly write protocol-relative image URLs ("//img.cdn.com/x.jpg")
  // which work fine rendered inside SHEIN's own page (inherits SHEIN's https:
  // protocol) but can come back broken once handed to a *different* app/page
  // context downstream, so make sure every URL we hand off is fully absolute.
  function normalizeImageUrl(url) {
    if (!url) return '';
    url = url.trim();
    if (url.indexOf('//') === 0) return 'https:' + url;
    if (url.indexOf('/') === 0) return location.origin + url;
    return url;
  }

  function realImgSrc(img) {
    if (!img) return '';
    var fromSrcset = function (srcset) {
      if (!srcset) return '';
      var parts = String(srcset).split(',').map(function (part) { return part.trim(); }).filter(Boolean);
      if (!parts.length) return '';
      return parts[parts.length - 1].split(/\\s+/)[0] || '';
    };
    var candidates = [
      img.getAttribute && img.getAttribute('data-src'),
      img.getAttribute && img.getAttribute('data-original'),
      img.getAttribute && img.getAttribute('data-lazy-src'),
      img.getAttribute && img.getAttribute('data-lazy'),
      img.getAttribute && img.getAttribute('data-original-src'),
      fromSrcset(img.getAttribute && img.getAttribute('srcset')),
      img.parentElement && img.parentElement.tagName === 'PICTURE' && fromSrcset((img.parentElement.querySelector('source[srcset]') || {}).srcset),
      img.currentSrc,
      img.src,
    ];
    for (var i = 0; i < candidates.length; i++) {
      var v = candidates[i];
      if (v && !/^data:image\\/(?:gif|svg)/i.test(v) && !/blank\\.gif|placeholder|skeleton|transparent/i.test(v)) return normalizeImageUrl(v);
    }
    return '';
  }

  // SHEIN product pages often carry promo banners ("install our app", ad
  // strips, etc.) with their own logo/icon <img> - those can be larger or
  // load faster than the actual product photo, so any heuristic that just
  // grabs "an image on the page" risks grabbing the wrong one. Walk up from
  // each candidate image and skip it entirely if an ancestor's class/id
  // hints it's a banner/ad/app-download widget rather than the product
  // gallery.
  // Confirmed via real captured page data: a generic "banner"/"ad"/"popup"
  // blocklist false-positives on the actual product photo carousel itself
  // (SHEIN's gallery wrapper class chain apparently includes a generic
  // "banner"-ish name used for ANY image carousel, not just promo ones) -
  // that single overly-broad match was excluding every real gallery photo.
  // Scope this down to only the exact "install our app" widget signature.
  function isInPromoWidget(img) {
    var el = img;
    var depth = 0;
    while (el && depth < 6) {
      var hint = ((el.className || '') + ' ' + (el.id || '')).toLowerCase();
      if (/app-download|download-app|applink|app-banner|guide-popup/i.test(hint)) return true;
      el = el.parentElement;
      depth++;
    }
    return false;
  }

  // A real product photo gallery is a cluster of 3+ same-ish SHEIN-hosted
  // <img> siblings sharing a close common ancestor (the swipeable carousel +
  // its thumbnail strip). That structural shape is a far more reliable
  // fingerprint than "biggest image on the page", which can accidentally
  // match a single oversized promo banner instead.
  // Confirmed from a real captured page: SHEIN's gallery photos each sit in
  // their OWN individual <li> wrapper (so grouping by a shared parent/
  // grandparent ELEMENT always produces one-image "groups" of size 1 and
  // never finds anything). What they DO share is the exact same wrapper
  // *className* string (e.g. every photo's direct parent is independently
  // class="crop-image-container"). Group by that className text instead.
  // Smallest rendered side of an image, in CSS px. Off-screen carousel clones
  // still report their full size (they're translated, not collapsed), so they
  // pass; a not-yet-laid-out lazy image reports 0, which we treat as "unknown"
  // (don't filter it out on size alone).
  function renderedMinDim(img) {
    var r = img.getBoundingClientRect();
    var w = r.width || img.clientWidth || 0;
    var h = r.height || img.clientHeight || 0;
    return Math.min(w, h);
  }

  function getGalleryImage() {
    var imgs = document.querySelectorAll(
      'img[src*="ltwebstatic"], img[src*="img.shein"], img[data-src*="ltwebstatic"], img[data-src*="img.shein"]'
    );
    var byParentClass = {};
    var order = [];
    for (var i = 0; i < imgs.length; i++) {
      var img = imgs[i];
      if (isInPromoWidget(img)) continue;
      var src = realImgSrc(img);
      if (!src) continue;
      // Drop icon-sized images (rating stars, color swatches, share/wishlist
      // glyphs). Several of them share a parent class in groups of 3+ (five
      // rating stars, a swatch row), and the old "biggest group wins" rule
      // could pick that over the real photo carousel - a confirmed failure
      // where a cart item showed a gold rating star as its product photo.
      var dim = renderedMinDim(img);
      if (dim > 0 && dim < 64) continue;
      var pCls = img.parentElement ? (img.parentElement.className || '').trim() : '';
      if (!pCls) continue;
      if (!byParentClass[pCls]) { byParentClass[pCls] = []; order.push(pCls); }
      byParentClass[pCls].push(img);
    }
    // Pick the group whose images render LARGEST (the hero photo carousel), not
    // the one with the most members - a "you may also like" strip can carry
    // more thumbnails than the gallery has photos, yet each is far smaller.
    var bestKey = null;
    var bestArea = 0;
    for (var k = 0; k < order.length; k++) {
      var key = order[k];
      if (byParentClass[key].length < 3) continue;
      var grp0 = byParentClass[key];
      var maxArea = 0;
      for (var gi = 0; gi < grp0.length; gi++) {
        var gr = grp0[gi].getBoundingClientRect();
        var area = gr.width * gr.height;
        if (area > maxArea) maxArea = area;
      }
      if (maxArea > bestArea) { bestArea = maxArea; bestKey = key; }
    }
    if (!bestKey) return '';
    // Picking items[0] (first in DOM order) is unreliable, and so is picking
    // the largest on-screen rect: this carousel is an infinite-loop slider
    // that prepends a clone of the LAST slide and appends a clone of the
    // FIRST slide so it can wrap around, and every clone renders at the same
    // size as a real slide (confirmed via logcat: 12 slides in the group,
    // but only 10 unique src hashes - N0 duplicates N10, N11 duplicates N1).
    // The clones sit parked off to the sides of the viewport; only the slide
    // actually visible right now has a bounding rect left close to 0. So
    // pick whichever loaded slide's left is closest to 0 instead.
    var group = byParentClass[bestKey];
    var best = group[0];
    var bestAbsLeft = Infinity;
    for (var g = 0; g < group.length; g++) {
      var rect = group[g].getBoundingClientRect();
      if (rect.width <= 0 || rect.height <= 0) continue;
      var absLeft = Math.abs(rect.left);
      if (absLeft < bestAbsLeft) { bestAbsLeft = absLeft; best = group[g]; }
    }
    return realImgSrc(best);
  }

  // Last-resort fallback: scan every non-promo SHEIN-hosted <img> on the page
  // and pick the one with the largest rendered/declared area.
  function getLargestSheinImage() {
    var imgs = document.querySelectorAll(
      'img[src*="ltwebstatic"], img[src*="img.shein"], img[data-src*="ltwebstatic"], img[data-src*="img.shein"]'
    );
    var best = '';
    var bestArea = 0;
    for (var i = 0; i < imgs.length; i++) {
      if (isInPromoWidget(imgs[i])) continue;
      var src = realImgSrc(imgs[i]);
      if (!src) continue;
      // Same icon-sized skip as getGalleryImage - never let a rating star or
      // swatch win the last-resort "largest image" pick.
      var rdim = renderedMinDim(imgs[i]);
      if (rdim > 0 && rdim < 64) continue;
      var w = imgs[i].naturalWidth || imgs[i].clientWidth || parseInt(imgs[i].getAttribute('width') || '0', 10) || 0;
      var h = imgs[i].naturalHeight || imgs[i].clientHeight || parseInt(imgs[i].getAttribute('height') || '0', 10) || 0;
      var area = w * h;
      if (area >= bestArea) { bestArea = area; best = src; }
    }
    return best;
  }

  function getMainImage() {
    var ld = getProductJsonLd();
    if (ld && ld.image) {
      var ldImg = Array.isArray(ld.image) ? ld.image[0] : ld.image;
      if (typeof ldImg === 'string' && ldImg) return normalizeImageUrl(ldImg);
      if (ldImg && typeof ldImg.url === 'string' && ldImg.url) return normalizeImageUrl(ldImg.url);
    }
    var mainImg = document.querySelector('.product-intro__main-image img, .product-intro__thumbs-item.active img, [class*="main-image" i] img');
    var fromMain = realImgSrc(mainImg);
    if (fromMain && !isInPromoWidget(mainImg)) return fromMain;
    var gallery = getGalleryImage();
    if (gallery) return gallery;
    var og = getMeta('og:image');
    if (og) return normalizeImageUrl(og);
    var largest = getLargestSheinImage();
    if (largest) return largest;
    var anyImg = document.querySelector('img[src*="ltwebstatic"], img[src*="img.shein"]');
    return realImgSrc(anyImg);
  }

  function findOptionContainer(keyword, labelWords) {
    var all = document.querySelectorAll('[class*="' + keyword + '" i]');
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      var opts = el.querySelectorAll('li, button, [class*="item" i]');
      if (opts.length >= 2) return el;
    }
    // Fallback for products where the attribute section's class doesn't
    // literally contain "color"/"size" (SHEIN's internal naming isn't
    // consistent across every product template): find a short text node
    // matching the attribute's visible label (e.g. "اللون") and walk up from
    // there looking for a nearby list of 2+ selectable options.
    if (labelWords) {
      var candidates = document.querySelectorAll('div, span, p, h1, h2, h3, label, b, strong');
      for (var j = 0; j < candidates.length; j++) {
        var text = (candidates[j].textContent || '').trim();
        if (!text || text.length > 20) continue;
        var matched = false;
        for (var w = 0; w < labelWords.length; w++) {
          if (text.indexOf(labelWords[w]) !== -1) { matched = true; break; }
        }
        if (!matched) continue;
        var scope = candidates[j].parentElement;
        for (var hop = 0; hop < 3 && scope; hop++) {
          var opts2 = scope.querySelectorAll('li, button, [class*="item" i], img');
          if (opts2.length >= 2) return scope;
          scope = scope.parentElement;
        }
      }
    }
    return null;
  }

  // Covers every common way a UI marks "this is the chosen option": aria
  // state, a "selected/active/..." class, or an actually-checked radio /
  // checkbox input nested inside the swatch (checked is a live DOM property,
  // not always reflected back onto the HTML attribute, so element.checked
  // has to be read directly rather than via getAttribute).
  function isSelectedSwatchEl(el) {
    if (el.getAttribute('aria-selected') === 'true') return true;
    if (el.getAttribute('aria-checked') === 'true') return true;
    if (el.getAttribute('aria-pressed') === 'true') return true;
    var cls = ' ' + (el.className || '') + ' ';
    if (/\\s(selected|active|checked|chosen|cur|current|picked)\\s/i.test(cls)) return true;
    var input = el.tagName === 'INPUT' ? el : el.querySelector('input[type="radio"], input[type="checkbox"]');
    if (input && input.checked) return true;
    return false;
  }

  // Rejects captured text that's clearly not a real color/size value - e.g.
  // a clock-formatted string like "1:52". Confirmed from a user report: a
  // flash-sale countdown timer elsewhere on the page got mistaken for the
  // size value by the generic "nearby short text" fallback heuristics
  // below, so the cart ended up showing a time instead of S/M/L/XL.
  function looksLikeJunkValue(text) {
    if (!text) return true;
    if (/^(hot|new|sale|best|bestseller|#\\s*\\d+|\\-?\\d+%?)$/i.test(text.trim())) return true;
    return /^\\d{1,2}:\\d{2}(:\\d{2})?$/.test(text);
  }

  function getSelectedWithin(container) {
    if (!container) return '';
    var nodes = container.querySelectorAll('*');
    for (var j = 0; j < nodes.length; j++) {
      var el = nodes[j];
      if (isSelectedSwatchEl(el)) {
        var label = el.getAttribute('aria-label') || el.getAttribute('title') ||
          el.getAttribute('data-color') || el.getAttribute('data-name') || el.getAttribute('data-value') ||
          el.getAttribute('data-attr-value') || '';
        label = (label || '').trim();
        if (!label) {
          var innerImg = el.tagName === 'IMG' ? el : el.querySelector('img');
          if (innerImg) label = (innerImg.getAttribute('alt') || innerImg.getAttribute('title') || '').trim();
        }
        if (!label) label = (el.textContent || '').trim();
        if (label && label.length < 60 && !looksLikeJunkValue(label)) return label;
      }
    }
    return '';
  }

  // The most reliable, class-name-agnostic way to read "which color is
  // currently selected": almost every shopping site prints it as plain text
  // next to the attribute's own label, e.g. "اللون: Apricot" or "Color: Black"
  // - look for any short text node containing one of those label words and
  // take whatever follows the separator (":" / "(" / "-"). This depends only
  // on the visible wording, not on guessing SHEIN's current CSS classes.
  function getAttrLabelValue(container, labelWords) {
    if (!container) return '';
    var scope = container.parentElement || container;
    for (var hop = 0; hop < 3 && scope; hop++) {
      var nodes = scope.querySelectorAll('*');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (container.contains(el) && el !== container) continue;
        var t = (el.textContent || '').trim();
        if (!t || t.length > 70) continue;
        for (var w = 0; w < labelWords.length; w++) {
          var word = labelWords[w];
          var idx = t.toLowerCase().indexOf(word.toLowerCase());
          if (idx === -1) continue;
          var rest = t.slice(idx + word.length).replace(/^[\\s:：\\-–(]+/, '').replace(/[)\\s]+$/, '').trim();
          if (rest && rest.length < 40 && rest.toLowerCase() !== word.toLowerCase() && !looksLikeJunkValue(rest)) return rest;
        }
      }
      scope = scope.parentElement;
    }
    return '';
  }

  // SHEIN often shows a generic swatch badge ("multicolor" thumbnail, a plain
  // dot, etc.) but prints the actual precise color name as a separate text
  // label next to/above the swatch row (e.g. "اللون: Apricot"), outside the
  // swatch list itself. When that label exists it's far more accurate than
  // anything we can infer from the swatch element, so prefer it.
  function getColorHeadingLabel(container) {
    if (!container) return '';
    var scope = container.parentElement;
    for (var hop = 0; hop < 3 && scope; hop++) {
      var candidates = scope.querySelectorAll(
        '[class*="color" i] [class*="name" i], [class*="color" i] [class*="value" i], ' +
        '[class*="selected-attr" i], [class*="attr-value" i], [class*="sku-name" i]'
      );
      for (var i = 0; i < candidates.length; i++) {
        if (container.contains(candidates[i])) continue;
        var text = (candidates[i].textContent || '').trim();
        if (text && text.length > 0 && text.length < 60 && !looksLikeJunkValue(text)) return text;
      }
      scope = scope.parentElement;
    }
    return '';
  }

  // The color swatch the user picked is the single most reliable source for a
  // "this is exactly the color they chose" photo - SHEIN renders each swatch
  // as either a small cropped <img> or a CSS background-image of the actual
  // colorway. The big hero photo can lag a tick behind the swatch click (it
  // fades/lazy-loads in), so prefer the swatch's own image over it.
  // Pulls the colorway photo out of one swatch element: its own <img>, its
  // background-image, or a direct child's background-image (SHEIN sometimes
  // wraps a small <li>/<button> whose image lives on a child div).
  function isColorBadgeEl(el) {
    if (!el || !el.getBoundingClientRect) return false;
    var text = ((el.textContent || '') + '').replace(/\\s+/g, ' ').trim();
    var cls = ' ' + ((el.className || '') + '').toLowerCase() + ' ';
    var r = el.getBoundingClientRect();
    var compact = r.width > 0 && r.width <= 96 && r.height > 0 && r.height <= 48;
    // A circular swatch wrapper can contain only the text of its HOT child.
    // Do not classify that whole 40-60px color tile as the badge itself.
    var cs = window.getComputedStyle(el);
    var before = window.getComputedStyle(el, '::before');
    var hasSwatchVisual = Math.min(r.width, r.height) >= 32 && (
      el.tagName === 'IMG' || !!el.querySelector('img') || /url\\(/.test(cs.backgroundImage || '') || /url\\(/.test(before.backgroundImage || '')
    );
    if (hasSwatchVisual) return false;
    if (compact && /^(hot|new|sale|best|bestseller|\\-?\\d+%?)$/i.test(text)) return true;
    return compact && /(?:^|[\\s_-])(hot|badge|tag|label|discount|promo|best|bestseller)(?:$|[\\s_-])/i.test(cls);
  }

  function isLikelyBadgeImageUrl(src) {
    if (!src) return false;
    return /(?:hot|badge|tag|label|discount|sprite|icon|promo|rank|best)/i.test(src) &&
      !/ltwebstatic|img\\.shein/i.test(src);
  }

  function swatchBackgroundUrl(el, pseudo) {
    try {
      var bg = window.getComputedStyle(el, pseudo || null).backgroundImage || '';
      var match = bg.match(/url\\(["']?(.*?)["']?\\)/);
      return match && match[1] ? match[1] : '';
    } catch (e) {
      return '';
    }
  }

  function rankedSwatchImageFrom(el) {
    if (!el) return '';
    var scope = isColorBadgeEl(el) && el.parentElement ? el.parentElement : el;
    var descendants = scope.querySelectorAll ? scope.querySelectorAll('*') : [];
    var bestSrc = '';
    var bestScore = -1;
    for (var index = -1; index < descendants.length; index++) {
      var node = index < 0 ? scope : descendants[index];
      if (!node || isColorBadgeEl(node)) continue;
      var rect = node.getBoundingClientRect();
      var width = rect.width || 0;
      var height = rect.height || 0;
      if (width < 12 || height < 12 || width > 120 || height > 120) continue;
      var sources = [];
      if (node.tagName === 'IMG') sources.push(realImgSrc(node));
      sources.push(swatchBackgroundUrl(node, null));
      sources.push(swatchBackgroundUrl(node, '::before'));
      sources.push(swatchBackgroundUrl(node, '::after'));
      for (var si = 0; si < sources.length; si++) {
        var src = sources[si];
        if (!src || /blank|placeholder/i.test(src) || isLikelyBadgeImageUrl(src)) continue;
        var minSide = Math.min(width, height);
        var maxSide = Math.max(width, height);
        if (minSide < 18) continue;
        var squareBonus = minSide / Math.max(maxSide, 1) >= 0.62 ? 900 : 0;
        var score = Math.min(width, 96) * Math.min(height, 96) + squareBonus;
        if (/ltwebstatic|img\\.shein|shein/i.test(src)) score += 120;
        if (score > bestScore) {
          bestScore = score;
          bestSrc = src;
        }
      }
    }
    return bestSrc;
  }

  function swatchImageFrom(el) {
    var rankedImage = rankedSwatchImageFrom(el);
    if (rankedImage) return rankedImage;
    var scope = isColorBadgeEl(el) && el.parentElement ? el.parentElement : el;
    // (v85.8.3-fix) شارة HOT/جديد التي يرسمها شي إن فوق حوّاسة اللون هي صورة
    // منفصلة مستضافة على نفس CDN (ltwebstatic) تماماً مثل صورة اللون، فقائمة حظر
    // الروابط (isLikelyBadgeImageUrl) لا تميّزها لأنها تستثني ltwebstatic. الفرق
    // الحقيقي: الشارة طبقة صغيرة في زاوية الحوّاسة بينما صورة اللون تملأها. كان
    // الكود يأخذ أول <img> في ترتيب DOM فيلتقط الشارة أحياناً (ظهرت كأيقونة غريبة
    // في السلة). الآن نختار أكبر صورة فعلية (=صورة اللون) ونتخطّى الطبقات الصغيرة.
    var imgList = scope.tagName === 'IMG' ? [scope] : scope.querySelectorAll('img');
    var bestSrc = '';
    var bestArea = -1;
    for (var ii = 0; ii < imgList.length; ii++) {
      var candImg = imgList[ii];
      if (isColorBadgeEl(candImg)) continue;
      var candSrc = realImgSrc(candImg);
      if (!candSrc || isLikelyBadgeImageUrl(candSrc)) continue;
      var cr = candImg.getBoundingClientRect();
      var cw = cr.width || candImg.naturalWidth || 0;
      var ch = cr.height || candImg.naturalHeight || 0;
      // تخطّى طبقة الشارة الصغيرة في الزاوية (أصغر بكثير من حوّاسة اللون). إن كانت
      // صورة اللون خلفية (background-image) والوحيدة <img> هي الشارة، يسقط هذا كله
      // فيُستخدم مسار الخلفية أدناه — وهو الصحيح.
      if (cw > 0 && ch > 0 && Math.min(cw, ch) < 18) continue;
      var candArea = cw * ch;
      if (candArea > bestArea) { bestArea = candArea; bestSrc = candSrc; }
    }
    if (bestSrc) return bestSrc;
    var bg = isColorBadgeEl(scope) ? '' : window.getComputedStyle(scope).backgroundImage;
    var match = bg && bg.match(/url\\(["']?(.*?)["']?\\)/);
    if (match && match[1] && !/blank|placeholder/i.test(match[1]) && !isLikelyBadgeImageUrl(match[1])) return match[1];
    var children = scope.children;
    for (var c = 0; c < (children ? children.length : 0); c++) {
      if (isColorBadgeEl(children[c])) continue;
      var childBg = window.getComputedStyle(children[c]).backgroundImage;
      var childMatch = childBg && childBg.match(/url\\(["']?(.*?)["']?\\)/);
      if (childMatch && childMatch[1] && !/blank|placeholder/i.test(childMatch[1]) && !isLikelyBadgeImageUrl(childMatch[1])) return childMatch[1];
    }
    return '';
  }

  // How strongly an element looks "ringed/highlighted". SHEIN marks the chosen
  // swatch with a drawn outline (confirmed by the user: the selected swatch is
  // the one with a black ring around it), which shows up as no aria/class flag
  // at all - only as a thicker border / an outline / a box-shadow.
  function ringScore(el) {
    var cs = window.getComputedStyle(el);
    var score = 0;
    var bw = Math.max(parseFloat(cs.borderTopWidth) || 0, parseFloat(cs.borderBottomWidth) || 0,
      parseFloat(cs.borderLeftWidth) || 0, parseFloat(cs.borderRightWidth) || 0);
    if (bw >= 2) score += bw;
    var ow = parseFloat(cs.outlineWidth) || 0;
    if (ow >= 1 && cs.outlineStyle && cs.outlineStyle !== 'none') score += ow + 1;
    if (cs.boxShadow && cs.boxShadow !== 'none') score += 2;
    return score;
  }

  // The icon-sized swatch elements inside the color container that carry an
  // image (an <img>, or a background-image).
  function collectSwatchEls(container) {
    var nodes = container.querySelectorAll('*');
    var out = [];
    for (var n = 0; n < nodes.length; n++) {
      var el = nodes[n];
      var r = el.getBoundingClientRect();
      if (r.width <= 0 || r.width > 80 || r.height <= 0 || r.height > 80) continue;
      if (isColorBadgeEl(el) && !swatchImageFrom(el)) continue;
      var hasImg = el.tagName === 'IMG' || !!el.querySelector('img') ||
        /url\\(/.test(window.getComputedStyle(el).backgroundImage || '');
      if (hasImg && swatchImageFrom(el)) out.push(el);
    }
    return out;
  }

  // The color swatch the user picked is the single most reliable source for a
  // "this is exactly the color they chose" photo - SHEIN renders each swatch as
  // either a small cropped <img> or a CSS background-image of the actual
  // colorway. The big hero photo can lag a tick behind the swatch click (it
  // fades/lazy-loads in), so prefer the swatch's own image over it.
  function getSelectedColorSwatchImage(container, selectedName) {
    if (!container) return '';
    // 1) Explicit selection signals (aria-selected/checked, a "selected"/
    //    "active" class, a checked radio).
    var nodes = container.querySelectorAll('*');
    for (var j = 0; j < nodes.length; j++) {
      if (!isSelectedSwatchEl(nodes[j])) continue;
      var im1 = swatchImageFrom(nodes[j]);
      if (im1) return im1;
    }
    // 2) Match the swatch whose own label (alt/title/aria-label) equals the
    //    color name we already captured - robust for normal named colors.
    if (selectedName && !isGenericColorName(selectedName)) {
      var want = selectedName.trim().toLowerCase();
      var swA = collectSwatchEls(container);
      for (var a = 0; a < swA.length; a++) {
        var lbl = swA[a].getAttribute('aria-label') || swA[a].getAttribute('title') || '';
        var innerImgA = swA[a].tagName === 'IMG' ? swA[a] : swA[a].querySelector('img');
        if (!lbl && innerImgA) lbl = innerImgA.getAttribute('alt') || innerImgA.getAttribute('title') || '';
        if (lbl && lbl.trim().toLowerCase() === want) {
          var imA = swatchImageFrom(swA[a]);
          if (imA) return imA;
        }
      }
    }
    // 3) Drawn-ring fallback: pick the swatch whose outline/border clearly
    //    stands out (the black ring around the chosen one). Only trust it when
    //    exactly ONE swatch is ringed - if they all share the same border,
    //    nothing actually stands out and the signal is meaningless here.
    var swB = collectSwatchEls(container);
    var bestEl = null;
    var bestRing = 0;
    var ringCount = 0;
    for (var b = 0; b < swB.length; b++) {
      var rs = ringScore(swB[b]);
      if (rs >= 2) ringCount++;
      if (rs > bestRing) { bestRing = rs; bestEl = swB[b]; }
    }
    if (bestEl && bestRing >= 2 && ringCount === 1) {
      var imB = swatchImageFrom(bestEl);
      if (imB) return imB;
    }
    return '';
  }

  // SHEIN prints a generic "ألوان متعددة" / "Multicolor" label for products
  // whose swatches it groups under one name (nail-polish sets, print fabrics,
  // etc.). Capturing that verbatim is useless - every variant of the product
  // ends up with the same meaningless color - so treat it as a low-quality
  // value and prefer a more specific name when one is available.
  function isGenericColorName(text) {
    if (!text) return true;
    var t = text.toLowerCase();
    return /ألوان متعددة|متعدد الألوان|متعدد الالوان|multi-?colou?r|multi colou?r|assorted/.test(t);
  }

  function getColorState() {
    var container = findOptionContainer('color', ['اللون', 'Color']);
    // The printed "اللون: X" heading is normally the most reliable source, but
    // when it only yields the generic multicolor label, fall through to the
    // actually-selected swatch's own name (aria-label/title/data-name), which
    // is usually the precise colorway. Only settle for the generic word if
    // nothing more specific exists anywhere.
    var labelVal = getAttrLabelValue(container, ['اللون', 'Color', 'color']) || getColorHeadingLabel(container);
    var swatchVal = getSelectedWithin(container);
    var selected;
    if (labelVal && !isGenericColorName(labelVal)) selected = labelVal;
    else if (swatchVal && !isGenericColorName(swatchVal)) selected = swatchVal;
    else selected = labelVal || swatchVal;
    return { exists: !!container, selected: selected, image: getSelectedColorSwatchImage(container, selected) };
  }

  // Walks every option inside the size container and splits it into
  // available vs unavailable based on the common ways sites mark a sold-out
  // option: aria-disabled, or a class hinting "disabled/soldout/out-of-stock".
  // Heuristic (SHEIN's exact class names aren't guaranteed), but degrades
  // safely - worst case an option lands in "available" when unsure.
  function getSizeOptions(container) {
    var available = [];
    var unavailable = [];
    if (!container) return { available: available, unavailable: unavailable };
    var opts = container.querySelectorAll('li, button, [class*="item" i]');
    for (var i = 0; i < opts.length; i++) {
      var el = opts[i];
      var label = (el.getAttribute('aria-label') || el.getAttribute('title') || el.textContent || '').trim();
      // Was 12 — tuned for short size codes (S/M/L/38/One Size). But SHEIN's
      // "نوع الموديلات" variant names are long (e.g. "4 قطع/مجموعة ذهبية"), so a
      // 12-char cap silently dropped every long option and left just the one
      // short one ("1 قطعة/أ"), which the single-option auto-select below then
      // captured as if the customer had chosen it. 40 keeps real variant names
      // while looksLikeJunkValue still rejects timers/badges.
      if (!label || label.length > 40 || looksLikeJunkValue(label)) continue;
      var cls = ' ' + (el.className || '') + ' ';
      var isDisabled = el.getAttribute('aria-disabled') === 'true' ||
        /\\s(disable|disabled|soldout|sold-out|out-of-stock|unavailable)\\s/i.test(cls);
      var bucket = isDisabled ? unavailable : available;
      if (bucket.indexOf(label) === -1) bucket.push(label);
    }
    return { available: available, unavailable: unavailable };
  }

  function getSizeState() {
    var container = findOptionContainer('size', ['المقاس', 'Size']);
    var opts = getSizeOptions(container);
    var selected = getSelectedWithin(container);
    if (!selected && opts.available.length === 1 && opts.unavailable.length === 0) selected = opts.available[0];
    return {
      exists: !!container,
      selected: selected,
      available: opts.available,
      unavailable: opts.unavailable,
    };
  }

  // SHEIN's own "you haven't chosen a variant yet" signal. Until the customer
  // picks a "نوع الموديلات"/size combination, SHEIN prints a placeholder in the
  // sku summary row ("انقر للشراء" / "Please Select") instead of the chosen
  // value. This is authoritative and beats any chip-class guess: some products
  // paint a default highlight on the first variant chip (which our selection
  // heuristics would otherwise read as "selected"), yet the summary still says
  // "انقر للشراء" — meaning nothing is committed. When this is on screen we must
  // refuse to capture and ask the customer to choose, so we never add a random
  // default variant they never picked.
  function sheinSkuSelectionPending() {
    if (!IS_SHEIN || !document.body) return false;
    var nodes = document.querySelectorAll('div, span, p, a, button');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.children && el.children.length > 3) continue;
      var t = (el.textContent || '').replace(/\\s+/g, ' ').trim();
      if (!t || t.length > 30) continue;
      if (/انقر للشراء|please\\s*select|الرجاء الاختيار|يرجى الاختيار|اختر الخيارات/i.test(t) && sheinElementIsVisible(el)) {
        return true;
      }
    }
    return false;
  }

  function looksLikeProductPage() {
    // SHEIN product detail pages always have a "-p-<id>" segment in the URL
    // (e.g. /ar/some-name-p-12345678-cat-1727.html). The home/category/deals
    // pages don't, so the URL is the reliable PDP signal on its own.
    // IMPORTANT: this used to also require title/price/image to all be
    // truthy before counting as a PDP - but that conflated "is this a
    // product page" with "did our scraping succeed". Any single field
    // failing (e.g. price selector not matching) made the button silently
    // treat a real product page as "not a product page" and just open the
    // (empty) cart instead of attempting to add anything - a totally silent
    // dead end with no error. Now we only gate on the URL, and let
    // addToCartFlow run regardless; its diagnostics chips show exactly
    // which field(s) failed instead of hiding the failure entirely.
    // تيمو: صفحة المنتج = goods بالمسار، أو (احتياط أمتن) وجود عنصر السعر
    // curPrice الذي يظهر فقط بصفحة المنتج - حتى لو لم يتطابق المسار.
    if (IS_TEMU) {
      if (/goods/i.test(location.pathname)) return true;
      try { return !!document.querySelector('[class*="curPrice" i]'); } catch (e) { return false; }
    }
    return /-p-\\d+/i.test(location.pathname);
  }

  function preloadImage(url, timeoutMs) {
    return new Promise(function (resolve) {
      if (!url) { resolve(false); return; }
      var done = false;
      var img = new Image();
      var timer = setTimeout(function () {
        if (!done) { done = true; resolve(false); }
      }, timeoutMs || 2500);
      img.onload = function () { if (!done) { done = true; clearTimeout(timer); resolve(true); } };
      img.onerror = function () { if (!done) { done = true; clearTimeout(timer); resolve(false); } };
      img.src = url;
    });
  }

  function ensureOverlayStyle() {
    if (document.getElementById('otlobli-overlay-style')) return;
    var style = document.createElement('style');
    style.id = 'otlobli-overlay-style';
    style.textContent = '@keyframes otlobli-spin{to{transform:rotate(360deg)}}' +
      '@keyframes otlobli-pop{0%{transform:scale(.86);opacity:0}100%{transform:scale(1);opacity:1}}' +
      '@keyframes otlobli-fade-out{to{opacity:0}}';
    document.head.appendChild(style);
  }

  // A small modal that blocks all touches/clicks behind it while we fetch and
  // verify the chosen product photo - this is the "freeze + load" step the
  // app side waits on before the item actually lands in the otlobli cart.
  function showAddingOverlay(payload) {
    ensureOverlayStyle();
    var existing = document.getElementById('otlobli-overlay');
    if (existing) existing.remove();
    var vp = viewportSize();
    document.body.style.overflow = 'hidden';

    var overlay = document.createElement('div');
    overlay.id = 'otlobli-overlay';
    overlay.setAttribute('data-shown-at', String(Date.now()));
    // One below max (otlobli-nav/back-btn/add-btn all sit at the true max) so
    // this blocking overlay can never end up painted on top of - and
    // swallowing taps meant for - otlobli's own nav bar. Confirmed real: a
    // user could only ever get the cart tab to respond after first bouncing
    // through another tab, exactly the symptom of an overlay occasionally
    // winning the stacking tie and eating the tap.
    overlay.style.cssText = 'position:fixed;left:0;top:0;width:' + vp.width + 'px;height:' + vp.height + 'px;' +
      'background:rgba(10,20,16,.55);z-index:2147483646;display:flex;align-items:center;justify-content:center;';
    overlay.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });
    overlay.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); }, true);

    var card = document.createElement('div');
    card.style.cssText = 'background:#fff;border-radius:16px;padding:20px;width:min(78vw,290px);' +
      'display:flex;flex-direction:column;align-items:center;gap:10px;animation:otlobli-pop .22s ease-out;' +
      'box-shadow:0 14px 32px rgba(0,0,0,.32);';

    var thumbWrap = document.createElement('div');
    thumbWrap.style.cssText = 'width:84px;height:84px;border-radius:12px;overflow:hidden;background:#f2f4f6;' +
      'border:1px solid #e6e8ea;position:relative;';
    var thumb = document.createElement('img');
    thumb.id = 'otlobli-overlay-thumb';
    thumb.style.cssText = 'width:100%;height:100%;object-fit:cover;display:block;';
    thumbWrap.appendChild(thumb);
    var spinner = document.createElement('div');
    spinner.id = 'otlobli-overlay-spinner';
    spinner.style.cssText = 'position:absolute;inset:-3px;border-radius:14px;border:3px solid rgba(0,105,72,.2);' +
      'border-top-color:#006948;animation:otlobli-spin .8s linear infinite;';
    thumbWrap.appendChild(spinner);

    var title = document.createElement('div');
    title.id = 'otlobli-overlay-title';
    title.style.cssText = 'font-size:13px;font-weight:700;color:#191c1e;text-align:center;direction:rtl;line-height:1.4;';

    card.appendChild(thumbWrap);
    card.appendChild(title);

    var meta = document.createElement('div');
    meta.id = 'otlobli-overlay-meta';
    meta.style.cssText = 'font-size:12px;color:#3d4a42;direction:rtl;';
    card.appendChild(meta);

    var status = document.createElement('div');
    status.id = 'otlobli-overlay-status';
    status.style.cssText = 'font-size:12px;color:#006948;font-weight:700;text-align:center;direction:rtl;margin-top:4px;';
    card.appendChild(status);



    overlay.appendChild(card);
    document.body.appendChild(overlay);
    updateOverlayContent(payload, 'جاري التأكد من بيانات المنتج...');
  }

  function updateOverlayContent(payload, statusText) {
    var thumb = document.getElementById('otlobli-overlay-thumb');
    if (thumb && thumb.getAttribute('src') !== payload.image) thumb.src = payload.image || '';

    var title = document.getElementById('otlobli-overlay-title');
    if (title) {
      var titleText = payload.title || 'المنتج';
      title.textContent = titleText.length > 40 ? titleText.slice(0, 40) + '…' : titleText;
    }

    var meta = document.getElementById('otlobli-overlay-meta');
    if (meta) {
      var metaParts = [];
      if (payload.color) metaParts.push(payload.color);
      if (payload.size) metaParts.push(payload.size);
      meta.textContent = metaParts.join(' · ');
      meta.style.display = metaParts.length ? 'block' : 'none';
    }

    var status = document.getElementById('otlobli-overlay-status');
    if (status && statusText) status.textContent = statusText;

    var diag = document.getElementById('otlobli-overlay-internal-diag-disabled');
    if (diag) {
      diag.innerHTML = '';
      var diagFields = [
        ['اسم', !!payload.title],
        ['صورة', !!payload.image],
        ['أيقونة اللون', !!payload.colorImageFound],
        ['سعر', payload.priceUsd > 0],
        ['لون', !!payload.color],
        ['مقاس', !!payload.size],
      ];
      for (var d = 0; d < diagFields.length; d++) {
        var chip = document.createElement('span');
        var ok = diagFields[d][1];
        chip.textContent = (ok ? '✓ ' : '✗ ') + diagFields[d][0];
        chip.style.cssText = 'font-size:10px;font-weight:700;padding:2px 6px;border-radius:8px;direction:rtl;' +
          (ok ? 'background:#e7f7ef;color:#006948;' : 'background:#ffdad6;color:#ba1a1a;');
        diag.appendChild(chip);
      }
    }
  }

  function markOverlaySuccess() {
    var status = document.getElementById('otlobli-overlay-status');
    if (status) status.textContent = '✓ تمت الإضافة لسلة otlobli';
    var spinner = document.getElementById('otlobli-overlay-spinner');
    if (spinner) {
      spinner.style.animation = 'none';
      spinner.style.borderColor = '#1aab6f';
    }
  }

  function removeOverlay(delay) {
    setTimeout(function () {
      var overlay = document.getElementById('otlobli-overlay');
      if (overlay) {
        overlay.style.animation = 'otlobli-fade-out .25s ease-in forwards';
        setTimeout(function () { overlay.remove(); }, 250);
      }
      document.body.style.overflow = '';
    }, delay || 0);
  }

  // ── جذب تيمو ────────────────────────────────────────────────────────────
  // ينظّف نصاً من رموز التحكم بالاتجاه غير المرئية (RLM/LRM/ALM وعلامات
  // العزل الاتجاهي Unicode Bidi Isolates) التي تُدرجها تيمو أحياناً حول
  // النصوص العربية لضبط اتجاه العرض — تجعل المقارنة الحرفية (===) والـregex
  // تفشل صامتة رغم تطابق الشكل المرئي 100%. ثبت من جهاز حقيقي: عنواني
  // "اللون"/"مقاس" ظاهران بوضوح على الصفحة لكن كشف الرأس كان يُرجع "لا
  // رأس قسم لون/مقاس" — بلا هذا التنظيف نفس فئة خلل BOM بالأسرار بالضبط.
  function temuCleanText(s) {
    return (s || '')
      .replace(/[\\u200e\\u200f\\u061c\\u2066\\u2067\\u2068\\u2069\\ufeff\\u200b]/g, '')
      .replace(/\\s+/g, ' ')
      .trim();
  }
  // يُرفق اللون/المقاس المختارين برابط المنتج كمعاملات otlobli_* (تُتجاهَل
  // من تيمو تماماً - معاملات مجهولة بلا أي تأثير على تحميل الصفحة)، لتُقرأ
  // لاحقاً عند إعادة فتح نفس الرابط (temuAutoReselectFromLink) فيُعاد اختيار
  // نفس اللون/المقاس تلقائياً بدل صفحة افتراضية بلا اختيار.
  function temuLooksLikePriceText(text) {
    var txt = temuCleanText(text || '');
    if (!txt || txt.length > 220) return false;
    if (!/[0-9٠-٩]/.test(txt)) return false;
    return /(?:US\\$|\\$|USD|SAR|QAR|AED|KWD|BHD|OMR|ريال|دولار|ر\\.? ?س|ر\\.? ?ق|د\\.? ?إ|د\\.? ?ك)/i.test(txt);
  }

  function temuContainsPrice(el) {
    if (!el) return false;
    try {
      var priceSelector = '[class*="curPrice" i], [class*="price" i], [class*="amount" i], [data-testid*="price" i]';
      if (el.matches && el.matches(priceSelector)) return true;
      if (el.querySelector && el.querySelector(priceSelector)) return true;
      return temuLooksLikePriceText(el.textContent || '');
    } catch (e) {
      return false;
    }
  }

  function otlobliBuildDeepLink(href, color, size) {
    try {
      var sep = href.indexOf('?') >= 0 ? '&' : '?';
      var parts = [];
      if (color) parts.push('otlobli_color=' + encodeURIComponent(color));
      if (size) parts.push('otlobli_size=' + encodeURIComponent(size));
      if (!parts.length) return href;
      return href + sep + parts.join('&');
    } catch (e) {
      return href;
    }
  }
  // العنوان من og:title (نشيل لاحقة " - Temu Canada")، السعر من عنصر صنفه
  // curPrice- (مؤكّد من التشخيص)، الصورة من og:image أو أكبر صورة kwcdn.
  // السعر يُحوَّل للدولار حسب العملة الظاهرة (الدينار مثبّت، الكندي تقريبي).
  function temuTitle() {
    var og = getMeta('og:title') || '';
    return og.replace(/\\s*[-|–—]\\s*Temu\\b.*$/i, '').replace(/\\s+/g, ' ').trim();
  }
  // تحويل شامل لأي عملة قد تظهر حسب دولة الـVPN العشوائية → دولار. عملات
  // الخليج/الأردن مثبّتة (تحويل دقيق)؛ الباقي تقريبي. **العملة المجهولة تُرجع 0
  // فيمنع النظام الإضافة** (لا يدخل سعر خاطئ أبداً = خربطة صفر).
  function temuPriceUsd() {
    var best = '';
    var els = document.querySelectorAll('[class*="curPrice" i]');
    for (var i = 0; i < els.length; i++) {
      var t = (els[i].textContent || '').trim();
      if (t.length <= 28 && /[0-9]/.test(t)) { best = t; break; }
    }
    if (!best) return 0;
    var num = parseFloat(best.replace(/[^0-9.]/g, ''));
    if (!(num > 0) || !isFinite(num)) return 0;
    var s = best;
    var rate = 0;                                   // 0 = عملة مجهولة → يمنع
    // رموز/رموز عملات مميّزة أولاً (CA$ قبل $ المجرّد).
    if (/CA\\$|CAD/i.test(s)) rate = 0.73;
    else if (/A\\$|AUD/i.test(s)) rate = 0.66;
    else if (/NZ\\$|NZD/i.test(s)) rate = 0.61;
    else if (/HK\\$|HKD/i.test(s)) rate = 0.128;
    else if (/SG\\$|SGD/i.test(s)) rate = 0.74;
    else if (/MX\\$|MXN/i.test(s)) rate = 0.058;
    else if (/R\\$|BRL/i.test(s)) rate = 0.18;
    else if (/€|EUR/i.test(s)) rate = 1.08;
    else if (/£|GBP/i.test(s)) rate = 1.27;
    else if (/₹|INR/i.test(s)) rate = 0.012;
    else if (/₺|TRY/i.test(s)) rate = 0.031;
    else if (/JOD|د\\.أ/i.test(s)) rate = 1.41;     // مثبّت
    else if (/AED|د\\.إ/i.test(s)) rate = 0.272;    // مثبّت
    else if (/SAR|ر\\.س/i.test(s)) rate = 0.267;    // مثبّت
    else if (/QAR|ر\\.ق/i.test(s)) rate = 0.275;    // مثبّت
    else if (/KWD|د\\.ك/i.test(s)) rate = 3.25;     // مثبّت
    else if (/BHD/i.test(s)) rate = 2.65;           // مثبّت
    else if (/OMR/i.test(s)) rate = 2.60;           // مثبّت
    else if (/EGP|ج\\.م/i.test(s)) rate = 0.020;
    else if (/US\\$|USD/i.test(s)) rate = 1;        // دولار صريح
    else if (/\\$/.test(s)) rate = 1;               // $ مجرّد = دولار أمريكي
    if (rate <= 0) return 0;                         // عملة مجهولة → يمنع الإضافة
    return Math.round(num * rate * 100) / 100;
  }
  // اللون المختار: تيمو يعرض عنواناً نصّياً "Color: X" (أو "اللون: X") يتحدّث
  // حسب اختيار المستخدم - نلتقط القيمة منه (دليل من صفحات حقيقية).
  function temuColor() {
    // 1) نقرة الزبون على كرت اللون (الأوثق - يحلّ مشكلة بقاء اللون الافتراضي).
    if (window.__otlobliTemuColor && window.__otlobliTemuColorGid === temuGoodsId()) {
      // حماية: رفض قيمة التقطت كود JS (مثل: } for(var ns in extraI18nStore[lang])).
      if (/[{};]|\\bvar\\b|\\bfor\\b|\\bfunction\\b/.test(window.__otlobliTemuColor)) {
        window.__otlobliTemuColor = '';
      } else {
        return window.__otlobliTemuColor;
      }
    }
    // 2) عنوان "Color: X" (اللون الافتراضي قبل أي تغيير).
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    for (var i = 0; i < nodes.length; i++) {
      var t = temuCleanText(nodes[i].textContent);
      if (t.length > 40) continue;
      var m = t.match(/^(?:Color|colour|اللون|لون(?:\\s+[\\u0600-\\u06FF]{2,14})?)\\s*[:：]\\s*(.+)$/i);
      if (m && m[1]) return m[1].trim();
    }
    return '';
  }
  // هل هذا النص رأس قسم لون؟ يشمل "اللون: أبيض" و"اللون" المجردة (بلا
  // نقطتين — الأحذية والساعات والأجهزة) و"لون السوار:" المركّبة.
  // ننظّف الداخل هنا أيضاً (لا فقط عند المستدعي) حتى تستفيد كل نقاط النداء
  // تلقائياً بلا حاجة لتعديلها كلها؛ التنظيف المزدوج بلا ضرر.
  function temuIsColorHeadText(t) {
    t = temuCleanText(t);
    if (!t || t.length > 40) return false;
    if (t === 'اللون' || t === 'Color' || t === 'Colour' || t === 'color' || t === 'colour') return true;
    return /^(?:Color|colour|اللون|لون(?:\\s+[\\u0600-\\u06FF]{2,14})?)\\s*[:：]/i.test(t);
  }
  // هل للمنتج خيارات ألوان؟ (وجود عنوان "Color:"/"اللون:"/"اللون").
  function temuHasColorSection() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) return true;
    }
    return false;
  }
  function temuImage() {
    // 1) إن نقر الزبون لوناً: نفضّل الهيرو المُلتقط بعد النقر (أكبر + صحيح).
    //    إن لم يُلتقط الهيرو بعد (ما زال الشيت مفتوحاً أثناء الالتقاط)،
    //    نستخدم صورة الكرت الصغيرة (swatch) بوصفها مؤكّدة الصحة أكثر من الهيرو
    //    العائد بالـfallback الذي قد يكون للون الافتراضي لا المختار.
    if (window.__otlobliTemuColorGid === temuGoodsId()) {
      // الـswatch أولاً: صورة كرت اللون المختار نفسه = مضمونة اللون 100%.
      // الهيرو المُلتقط قد يكون التقط قبل أن تُحدّث تيمو الصورة (شيت مفتوح)
      // فيدخل لون خاطئ — ثبت من شكوى "اخترت أزرق فانجذب أسود".
      if (window.__otlobliTemuColorSwatch) return window.__otlobliTemuColorSwatch;
      if (window.__otlobliTemuColorImg) return window.__otlobliTemuColorImg;
    }
    // 2) الصورة الرئيسية = أكبر صورة kwcdn في أعلى الصفحة (المعرض الرئيسي)، لا
    // الصور الثانوية أو صور كروت الألوان (عرضها < 200px عادةً). fallback: og:image.
    var imgs = document.querySelectorAll('img');
    var best = '', bestA = 0;
    for (var i = 0; i < imgs.length; i++) {
      var src = imgs[i].currentSrc || imgs[i].src || '';
      if (!/kwcdn|temu/i.test(src)) continue;
      var r = imgs[i].getBoundingClientRect();
      if (r.top > 720 || r.width < 200) continue;          // كروت الألوان < 200px نتجاهلها
      var a = r.width * r.height;
      if (a > bestA) { bestA = a; best = src; }
    }
    return best || getMeta('og:image') || '';
  }

  // هل العنصر له حدّ غامق (أسود/قريب منه)؟ = الخيار المختار في تيمو (مؤكّد من
  // الصور: الخيار المختار - لون أو مقاس - حدّه أسود وباقي الخيارات حدّها فاتح).
  function temuHasDarkBorder(el) {
    var cs = window.getComputedStyle(el);
    // لون الحدّ يُحسب دائماً حتى لو سماكته صفر (المتصفح يُرجع قيمة افتراضية
    // بلا معنى بصري) — ثبت من تشخيص حقيقي: 3 أزرار سماكتها 0 كلها "بحدّ
    // غامق". حدّ بلا سماكة = لا حدّ فعلياً، فنستبعده أولاً.
    var bw = parseFloat(cs.borderTopWidth || '0');
    if (!(bw > 0)) return false;
    var bc = cs.borderTopColor || cs.borderColor || '';
    var m = bc.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?/i);
    if (!m) return false;
    var alpha = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (alpha < 0.4) return false;
    return (+m[1] < 95 && +m[2] < 95 && +m[3] < 95);
  }
  // هل للعنصر outline أو box-shadow ظاهر (غير "none")؟ حلقات الاختيار
  // الدائرية شائعة برسمها عبر هاتين الخاصيتين بدل الحدّ العادي (border) —
  // ثبت من تشخيص حقيقي: حلقة سوداء واضحة حول زر "L" لكن سماكة حدّه 0 تماماً.
  function temuRingStyleMatch(cs) {
    if (!cs) return false;
    var outlineStyle = cs.outlineStyle || 'none';
    var outlineW = parseFloat(cs.outlineWidth || '0');
    if (outlineStyle !== 'none' && outlineW > 0) return true;
    var shadow = cs.boxShadow || 'none';
    return !!shadow && shadow !== 'none';
  }
  // حلقة/ظلّ اختيار — نفحص العنصر نفسه، وكذلك ::before/::after (حلقات
  // الاختيار الدائرية شائع جداً رسمها بعنصر زائف منفصل تماماً عن الأنماط
  // المحسوبة للعنصر الأصلي؛ getComputedStyle(el) وحدها لا تراه إطلاقاً).
  function temuHasRingHighlight(el) {
    if (temuRingStyleMatch(window.getComputedStyle(el))) return true;
    try {
      var before = window.getComputedStyle(el, '::before');
      if (before && before.content && before.content !== 'none' && temuRingStyleMatch(before)) return true;
    } catch (e) {}
    try {
      var after = window.getComputedStyle(el, '::after');
      if (after && after.content && after.content !== 'none' && temuRingStyleMatch(after)) return true;
    } catch (e) {}
    return false;
  }
  // إشارة "مُختار" دلالية (aria/data/اسم صنف) — أوثق بكثير من تخمين مظهر
  // CSS لأنها لا تعتمد على تقنية الرسم البصري (حدّ/outline/shadow/عنصر
  // زائف) إطلاقاً، بل على الحالة الفعلية التي يُعلنها العنصر نفسه. نفحص
  // العنصر ووالده المباشر (الحالة أحياناً على الحاضن لا الزرّ الداخلي).
  function temuHasSemanticSelectedMarker(el) {
    function check(node) {
      if (!node || !node.getAttribute) return false;
      var ariaSel = node.getAttribute('aria-selected');
      var ariaChecked = node.getAttribute('aria-checked');
      var ariaPressed = node.getAttribute('aria-pressed');
      if (ariaSel === 'true' || ariaChecked === 'true' || ariaPressed === 'true') return true;
      var dataSel = node.getAttribute('data-selected') || node.getAttribute('data-active') || node.getAttribute('data-checked');
      if (dataSel === 'true' || dataSel === '1') return true;
      var cls = ((node.className || '') + '').toLowerCase();
      var tokens = cls.replace(/_/g, ' ').replace(/-/g, ' ').split(' ');
      return tokens.indexOf('selected') >= 0 || tokens.indexOf('active') >= 0 ||
        tokens.indexOf('checked') >= 0 || tokens.indexOf('current') >= 0 ||
        tokens.indexOf('chosen') >= 0;
    }
    return check(el) || check(el.parentElement);
  }
  // خلفية فاتحة (أو شفافة)؟ لتمييز أزرار المقاس المحدّدة (حدّ غامق + خلفية
  // فاتحة) عن الأزرار المعبّأة الغامقة مثل مبدّل نظام المقاس "Standard".
  function temuLightBackground(el) {
    var bg = window.getComputedStyle(el).backgroundColor || '';
    var m = bg.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?/i);
    if (!m) return true;
    var alpha = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (alpha < 0.1) return true;            // شفاف = فاتح
    return (+m[1] > 140 || +m[2] > 140 || +m[3] > 140);
  }
  // ذكي وآمن: الخيار المختار (مقاس/متغيّر نصّي) = زر **قابل للنقر**، قصير النص،
  // بلا صورة، بحدّ غامق وخلفية فاتحة، **ظاهر بالشاشة**، وليس سعراً/خصماً/كمية.
  // القابلية للنقر هي ما يميّز زر الخيار عن شارة السعر (غير قابلة للنقر) -
  // وهذا أصلح خطأ التقاط السعر مكان المقاس.
  // عنوان قسم المقاس ("Size"/"المقاس").
  function temuSizeHeadEl() {
    var heads = document.querySelectorAll('div, span, h2, h3, strong, label, p');
    for (var h = 0; h < heads.length; h++) {
      var ht = temuCleanText(heads[h].textContent);
      if (ht === 'Size' || ht === 'المقاس' || ht === 'Size:' || ht === 'المقاس:'
        || ht === 'مقاس' || ht === 'مقاس:' || ht === 'القياس' || ht === 'القياس:'
        || ht === 'الحجم' || ht === 'الحجم:' || ht === 'حجم'
        || ht === 'موديل متوافق' || ht === 'Compatible Model' || ht === 'Compatible model'
        || ht === 'الموديل' || ht === 'موديل'
        || ht === 'أسلوب' || ht === 'Style' || ht === 'Style:' || ht === 'النمط' || ht === 'نوع'
        || (ht.indexOf('Size') === 0 && ht.length <= 12 && !/guide|chart|info/i.test(ht))
        || (ht.indexOf('مقاس') === 0 && ht.length <= 12 && ht.indexOf('مقاسات') < 0)
        || (ht.indexOf('موديل') === 0 && ht.length <= 22)
        || (ht.indexOf('أسلوب') === 0 && ht.length <= 10)
        || (ht.indexOf('Style') === 0 && ht.length <= 10)) return heads[h];
    }
    return null;
  }
  // يحلّل ملخّص المتغيّرات ("1 اللون, 25 موديل متوافق") لمعرفة العدد الفعلي
  // لأن عدّ الـpills على الصفحة غير موثوق (قد يكون الملخّص قبل فتح اللوحة).
  function temuVariantCounts() {
    var el = temuVariantSummaryEl();
    var txt = el ? temuCleanText(el.textContent) : '';
    var cMatch = txt.match(/(\\d+)\\s*(?:colou?rs?|ألوان|اللون|لون)/i);
    var sMatch = txt.match(/(\\d+)\\s*(?:sizes?|مقاس|مقاسات|موديل|model|أسلوب|style|نوع)/i);
    return {
      colors: cMatch ? parseInt(cMatch[1], 10) : -1,  // -1 = غير معروف
      sizes:  sMatch ? parseInt(sMatch[1], 10) : -1,
    };
  }
  // قتامة حدّ العنصر (مجموع RGB، أقل=أغمق؛ 999 لو شفاف/غير موجود).
  function temuBorderDarkness(el) {
    var bc = window.getComputedStyle(el).borderTopColor || '';
    var m = bc.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?/i);
    if (!m) return 999;
    var a = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (a < 0.3) return 999;
    return (+m[1] + +m[2] + +m[3]);
  }
  // سماكة الحدّ العلوي بالبكسل (0 إن لا حدّ).
  function temuBorderWidth(el) {
    var bw = parseFloat(window.getComputedStyle(el).borderTopWidth || '0');
    return isNaN(bw) ? 0 : bw;
  }
  // كاشف "المُختار" متعدد الإشارات ضمن مجموعة أزرار/كروت متجانسة (مقاس أو
  // لون). تيمو تستخدم قوالب مختلفة للتمييز البصري: أحياناً خلفية ممتلئة
  // داكنة، وأحياناً حدّ أسمك فقط بلا تعبئة، ونادراً لون حدّ مختلف فقط.
  // لون الحدّ وحده غير كافٍ — ثبت من تشخيص حقيقي: 4 أزرار مقاس، جميعها
  // سُجِّلت "حدّ غامق" رغم اختيار واحد فقط ظاهرياً (نفس لون الحدّ الافتراضي
  // للكل). نجرّب إشارات بترتيب الأقوى فالأضعف؛ أول إشارة تُرجع تطابقاً
  // واحداً بلا غموض تفوز — أي غموض (صفر أو أكثر من واحد) ننتقل للإشارة
  // التالية، وفشل الكل = فارغ (لا تخمين).
  function temuPickSingleSelected(els) {
    if (!els || els.length < 2) return null;
    // إشارة 0 (الأوثق دائماً): علامة دلالية صريحة (aria/data/اسم صنف) لا
    // تعتمد على تقنية الرسم البصري إطلاقاً — إن وُجدت نثق بها فوراً.
    var semantic = [];
    for (var s = 0; s < els.length; s++) {
      if (temuHasSemanticSelectedMarker(els[s])) semantic.push(els[s]);
    }
    if (semantic.length === 1) return semantic[0];
    // إشارة 1: خلفية ممتلئة داكنة غير شفافة (الأقوى والأوضح بصرياً).
    var filled = [];
    for (var i = 0; i < els.length; i++) {
      var bg = window.getComputedStyle(els[i]).backgroundColor || '';
      var bm = bg.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?/i);
      if (!bm) continue;
      var ba = bm[4] !== undefined ? parseFloat(bm[4]) : 1;
      if (ba < 0.5) continue;
      if ((+bm[1] + +bm[2] + +bm[3]) < 240) filled.push(els[i]);
    }
    if (filled.length === 1) return filled[0];
    // إشارة 2: حلقة outline/box-shadow ظاهرة (حلقات الاختيار الدائرية —
    // ثبت من تشخيص حقيقي: حدّ سماكته 0 لكن حلقة سوداء واضحة حول الزر).
    var ringed = [];
    for (var r = 0; r < els.length; r++) {
      if (temuHasRingHighlight(els[r])) ringed.push(els[r]);
    }
    if (ringed.length === 1) return ringed[0];
    // إشارة 3: سماكة حدّ أكبر بوضوح من كل الباقي (تفوق حقيقي لا تقريبي).
    var widths = [];
    for (var j = 0; j < els.length; j++) widths.push(temuBorderWidth(els[j]));
    var maxW = Math.max.apply(null, widths);
    if (maxW > 0) {
      var wMatches = [], secondMax = 0;
      for (var k = 0; k < widths.length; k++) {
        if (widths[k] === maxW) wMatches.push(els[k]);
        else if (widths[k] > secondMax) secondMax = widths[k];
      }
      if (wMatches.length === 1 && maxW > secondMax && (secondMax === 0 || maxW >= secondMax * 1.3)) {
        return wMatches[0];
      }
    }
    // إشارة 4 (احتياط أخير): حدّ غامق وحيد فعلي السماكة (القوالب التي فعلاً
    // تلوّن حدّ المختار فقط بلا البقية — الحالة الأصلية قبل هذا التوسيع).
    var borderMatches = [];
    for (var b = 0; b < els.length; b++) {
      if (temuHasDarkBorder(els[b])) borderMatches.push(els[b]);
    }
    if (borderMatches.length === 1) return borderMatches[0];
    return null;
  }
  // هل النص يشبه قيمة مقاس حقيقية؟ أرقام (74-80، 38، 9-12 شهر) أو حروف
  // المقاسات القياسية (M/L/XL/One Size). يميّز صف المقاسات الحقيقي عن مفاتيح
  // التبديل النصية المجاورة للرأس (الطول/العمر/قياسي/JO...) التي تخترع تيمو
  // جديداً منها لكل صنف — فلا نعتمد على حفظ الكلمات بل على شكل القيمة.
  function temuSizeLike(t) {
    if (/\\d/.test(t)) return true;
    return /^(?:x{0,3}[sml]|xs|xxs|one.?size|free.?size)$/i.test(t);
  }
  // أزرار المقاس ضمن قسم "Size" فقط — بتجميع حسب الـclass: أزرار الصف
  // الحقيقي تتشارك الصنف نفسه، فأكبر مجموعة "تشبه مقاسات" تفوز، ومفاتيح
  // التبديل (مجموعة صنف آخر بلا أرقام) تخسر تلقائياً مهما كانت كلماتها.
  function temuSizePills() {
    var head = temuSizeHeadEl();
    if (!head) return [];
    var container = head.parentElement, hops = 0;
    var weakBest = [];
    while (container && hops < 6) {
      var cand = container.querySelectorAll('button, a, [role="button"], div, span, label');
      var pills = [];
      for (var i = 0; i < cand.length; i++) {
        var el = cand[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        var t = temuCleanText(el.textContent);
        if (t.length < 1 || t.length > 24) continue;
        // أزرار كمية "−" "+" حرف واحد غير حرفي/رقمي — نتجاهلها.
        if (t.length === 1 && !/[a-zA-Z0-9]/.test(t)) continue;
        if (t.indexOf(':') >= 0) continue;
        if (/[$£€%]/.test(t)) continue;
        if (/\\bfree\\b|\\bapp\\b|guide|standard|qty|^size$/i.test(t)) continue;
        // مفاتيح تبديل معروفة + دليل المقاسات + الكمية (حزام أمان صريح).
        if (/^(?:us|ca|eu|uk|au|jo|sa|ae|kw|qa|bh|om|asia|intl)$/i.test(t)) continue;
        if (t === 'قياسي' || t === 'عادي' || t === 'الطول' || t === 'العمر' || t === 'الوزن'
          || /دليل|كمية|كميه/.test(t)) continue;
        if (el.querySelector && el.querySelector('img')) continue;
        var r = el.getBoundingClientRect();
        if (r.width < 18 || r.width > 260 || r.height < 16 || r.height > 80) continue;
        pills.push(el);
      }
      if (pills.length) {
        // تجميع حسب (class + tag)
        var byCls = {}, order = [];
        for (var p2 = 0; p2 < pills.length; p2++) {
          var ck = ((pills[p2].className || '') + '|' + pills[p2].tagName);
          if (!byCls[ck]) { byCls[ck] = []; order.push(ck); }
          byCls[ck].push(pills[p2]);
        }
        // نجمّع كل المجموعات "القوية" (تشبه مقاسات) بهذا المستوى معاً، لا نكتفي
        // بأكبر واحدة فقط. السبب: الزر المختار غالباً يحمل صنفاً CSS إضافياً
        // ("active"/"selected"...) فيُفرد بمجموعة صنف منفصلة قد تكون بحجم 1 —
        // وكانت تخسر تلقائياً أمام مجموعة البقية الأكبر فتختفي من النتيجة
        // تماماً (ثبت من تشخيص جهاز حقيقي: كل الإشارات صفر رغم زر مُختار
        // ظاهر بوضوح — لأنه لم يكن ضمن الأزرار المفحوصة أصلاً). حارس أمان:
        // نضمّ فقط المجموعات القريبة عمودياً من أكبر مجموعة (نفس الصفّ)، لا
        // أي مجموعة "قوية" بمستوى الصفحة كله.
        var groups = [];
        for (var g = 0; g < order.length; g++) {
          var grp = byCls[order[g]];
          var likes = 0;
          for (var q = 0; q < grp.length; q++) {
            if (temuSizeLike(temuCleanText(grp[q].textContent))) likes++;
          }
          if (likes >= 1 && likes * 2 >= grp.length) groups.push(grp);
        }
        if (groups.length) {
          groups.sort(function (a, b) { return b.length - a.length; });
          var baseTop = groups[0][0].getBoundingClientRect().top;
          var merged = groups[0].slice();
          for (var gi = 1; gi < groups.length; gi++) {
            var gTop = groups[gi][0].getBoundingClientRect().top;
            if (Math.abs(gTop - baseTop) <= 60) merged = merged.concat(groups[gi]);
          }
          return merged;
        }
        var weak = null;
        for (var g2 = 0; g2 < order.length; g2++) {
          var grp2 = byCls[order[g2]];
          if (!weak || grp2.length > weak.length) weak = grp2;
        }
        // مجموعة كلمات بلا أرقام (أسلوب/نمط): نحفظ أفضلها كاحتياط — بسقف
        // حجم يمنع التقاط شبكة تصنيفات كاملة من مستويات عالية.
        if (weak && weak.length <= 10 && hops <= 3 && weak.length > weakBest.length) {
          weakBest = weak;
        }
      }
      container = container.parentElement; hops++;
    }
    return weakBest;
  }
  // معرّف المنتج (ثابت رغم تغيّر المقاس/اللون) - لربط النقرة بالمنتج الصحيح.
  function temuGoodsId() {
    var m = location.href.match(/goods_id=(\\d+)/);
    return m ? m[1] : location.pathname;
  }
  // المقاس المختار. المصدر الأدقّ: آخر زر مقاس **نقره الزبون فعلاً** (نسجّله
  // عبر مستمع نقر) - أوثق بكثير من تخمين العنصر "المحدّد" بصرياً. واحتياطاً:
  // الزر الأغمق حدّاً بوضوح (للمقاس المُختار افتراضياً بلا نقر). أي شكّ=فارغ.
  function temuSelectedSizeFromLabel() {
    // 1) نفحص أولاً عنوان قسم المقاس نفسه — قد يحتوي القيمة ("Size: One-size")
    var head = temuSizeHeadEl();
    if (head) {
      var headText = temuCleanText(head.textContent);
      var hm = headText.match(/Size[\\s\\-]*[:\\-]?[\\s\\-]*(one.?size|free.?size|[\\w ]{2,20})/i);
      if (hm && hm[1]) {
        var hv = hm[1].trim();
        if (!/^size$/i.test(hv) && hv.length >= 2) return hv;
      }
      // 2) نفحص العناصر المجاورة مباشرة للعنوان (قد تكون النص/التاغ المنفصل)
      var parent = head.parentElement;
      if (parent) {
        var kids = parent.children;
        for (var k = 0; k < kids.length; k++) {
          if (kids[k] === head) continue;
          var kt = temuCleanText(kids[k].textContent);
          if (kt.length >= 2 && kt.length <= 30 && /one.?size|free.?size/i.test(kt)) return kt;
        }
      }
    }
    // 3) مسح عام: البحث عن نمط "Size: ONE SIZE" في أي عنصر نصي
    var els = document.querySelectorAll('div, span, p, strong, h3, h2');
    for (var si = 0; si < els.length; si++) {
      var st = temuCleanText(els[si].textContent);
      if (st.length < 4 || st.length > 80) continue;
      var sm = st.match(/Size\\s*:\\s*([^,;|\\n\\r]{1,30})/i);
      if (!sm) sm = st.match(/^(?:المقاس|مقاس|الحجم)\\s*[:：]\\s*([^,;|\\n\\r]{1,30})/);
      if (sm && sm[1]) {
        var sv = sm[1].trim();
        if (sv.length >= 2 && sv.length <= 30 && !/guide|chart|info|دليل/i.test(sv)) return sv;
      }
    }
    return '';
  }
  function temuSelectedSize() {
    var pills = temuSizePills();
    // لا توجد أزرار مقاس — قد يكون المقاس محدداً مسبقاً (مثل "One-size" على الصفحة مباشرة).
    if (pills.length < 1) {
      var headFound = !!temuSizeHeadEl();
      window.__otlobliTemuSizeDiag = headFound ? 'رأس موجود، صفر أزرار مطابقة' : 'لا رأس قسم مقاس';
      return temuSelectedSizeFromLabel();
    }
    // 1) نقرة الزبون المسجّلة (لنفس المنتج، وما زالت ضمن مقاساته الحالية).
    // مهم: ننظّف نص الزر هنا بنفس دالة معالج النقر (temuCleanText) بالضبط —
    // ثبت من تشخيص جهاز حقيقي: تيمو تضيف أحياناً رموز اتجاه غير مرئية حول
    // نص الزر فقط أثناء حالة "مُختار" (الحدّ الأسود ظاهر)، فتصير المقارنة
    // الخام هنا (نص حالي ملوّث) ضد القيمة المسجّلة وقت النقر (نظيفة) فاشلة
    // تحديداً في اللحظة التي الزر ظاهر فيها كمُختار — عكس المطلوب تماماً.
    if (window.__otlobliTemuSize && window.__otlobliTemuSizeGid === temuGoodsId()) {
      for (var k = 0; k < pills.length; k++) {
        if (temuCleanText(pills[k].textContent) === window.__otlobliTemuSize) return window.__otlobliTemuSize;
      }
    }
    // 2) مقاس وحيد = اختيار تلقائي (لا داعي لنقر الزبون عليه).
    if (pills.length === 1) {
      return temuCleanText(pills[0].textContent);
    }
    // 3) لا نقرة صريحة. ثبت من تشخيص حقيقي على جهاز فعلي: بعض قوالب تيمو
    // تجعل حدّ **كل** الأزرار غامقاً افتراضياً (مطابقة اللون وحدها عديمة
    // الفائدة هناك)، بينما قوالب أخرى تميّز المختار بخلفية ممتلئة أو حدّ
    // أسمك. نستخدم كاشفاً متعدد الإشارات (خلفية → سماكة حدّ → لون حدّ) يجرّب
    // كل إشارة حتى يجد تطابقاً واحداً واضحاً؛ أي غموض = فارغ (لا تخمين).
    var defaultPick = temuPickSingleSelected(pills);
    var dbgW = [], dbgF = 0, dbgR = 0;
    for (var dp = 0; dp < pills.length; dp++) {
      dbgW.push(temuBorderWidth(pills[dp]));
      if (temuHasDarkBorder(pills[dp])) dbgF++;
      if (temuHasRingHighlight(pills[dp])) dbgR++;
    }
    window.__otlobliTemuSizeDiag = 'أزرار=' + pills.length + ' حدّغامق=' + dbgF + ' حلقة=' + dbgR + ' سماكات=' + dbgW.join(',');
    if (defaultPick) {
      var dt = temuCleanText(defaultPick.textContent);
      if (dt && dt.length <= 24) { window.__otlobliTemuSizeDiag += ' نجاح[' + dt + ']'; return dt; }
    }
    return '';
  }
  // مقاس وحيد → نحدّده تلقائياً من دون نقر الزبون (يُستدعى في معالج الزر).
  function temuForceSingleSize() {
    if (!temuHasSizeSection() || temuSelectedSize()) return;
    var fpills = temuSizePills();
    if (fpills.length === 1) {
      var ft = temuCleanText(fpills[0].textContent);
      if (ft && ft.length <= 24) {
        // تسجيل فقط بلا .click() — نفس علة temuAutoSelectSingleSize: نقر عنصر
        // مُصنَّف خطأً يُبحر بالصفحة. التسجيل يكفي لالتقاط البيانات.
        window.__otlobliTemuSize = ft;
        window.__otlobliTemuSizeGid = temuGoodsId();
      }
    } else if (fpills.length === 0) {
      // ملخّص "1 Size" في لوحة المتغيّرات → مقاس وحيد غير قابل للنقر
      var fsum = temuVariantSummaryEl();
      if (fsum && /\\b1\\s*(?:size|مقاس|موديل|أسلوب)|مقاس\\s*واحد/i.test(fsum.textContent || '')) {
        window.__otlobliTemuSize = 'ONE SIZE';
        window.__otlobliTemuSizeGid = temuGoodsId();
      }
    }
  }
  // هل للمنتج لون وحيد؟ يُقلّص الصور الملوّنة القريبة من عنوان "Color:".
  function temuHasSingleColor() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    var colorHead = null;
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) { colorHead = nodes[i]; break; }
    }
    if (!colorHead) return false;
    var container = colorHead.parentElement, hops = 0;
    while (container && hops < 5) {
      var imgs = container.querySelectorAll('img');
      var count = 0;
      for (var j = 0; j < imgs.length; j++) {
        var src = imgs[j].currentSrc || imgs[j].src || '';
        if (!/kwcdn|temu/i.test(src)) continue;
        var r = imgs[j].getBoundingClientRect();
        if (r.width >= 28 && r.width < 200 && r.height >= 28 && r.height < 200) count++;
      }
      if (count >= 1) return count === 1;
      container = container.parentElement; hops++;
    }
    return false;
  }
  // يقرأ اللون الحالي من عنوان "اللون: X" فقط (بلا مصادر النقر) — يُستخدم
  // للالتقاط الاحتياطي بعد أي نقرة: كروت الألوان النصية (ساعات) بلا صور
  // لا يلتقطها فرع كرت اللون، لكن تيمو تُحدّث العنوان بعد الاختيار دائماً.
  function temuColorFromHeading() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    for (var i = 0; i < nodes.length; i++) {
      var t = temuCleanText(nodes[i].textContent);
      if (t.length > 40) continue;
      var m = t.match(/^(?:Color|colour|اللون|لون(?:\\s+[\\u0600-\\u06FF]{2,14})?)\\s*[:：]\\s*(.+)$/i);
      if (m && m[1]) {
        var cv = m[1].trim();
        if (cv.length >= 2 && cv.length <= 40 && !/[{};]/.test(cv)) return cv;
      }
    }
    return '';
  }
  // يبحث وقت الجذب عن كرت اللون الذي اسمه يطابق اللون المختار ويعيد صورته —
  // شبكة أمان لالتقاط صورة اللون حين لم يلتقطها مستمع النقر (اختيار داخل
  // الشيت، لون افتراضي محدد مسبقاً، كروت بهيكلية غير متوقعة).
  function temuSelectedColorCardImg(colorName) {
    if (!colorName || colorName.length < 2) return '';
    var lowName = colorName.toLowerCase();
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    var colorHead = null;
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) { colorHead = nodes[i]; break; }
    }
    if (!colorHead) return '';
    var container = colorHead.parentElement, hops = 0;
    while (container && hops < 5) {
      var imgs = container.querySelectorAll('img');
      var swCount = 0, match = '';
      for (var j = 0; j < imgs.length; j++) {
        var src = imgs[j].currentSrc || imgs[j].src || '';
        if (!src || src.indexOf('http') !== 0) continue;
        var r = imgs[j].getBoundingClientRect();
        if (r.width < 28 || r.width > 220 || r.height < 28 || r.height > 220) continue;
        swCount++;
        var alt = temuCleanText(imgs[j].getAttribute('alt') || imgs[j].getAttribute('title') || '').toLowerCase();
        var ptxt = imgs[j].parentElement ? temuCleanText(imgs[j].parentElement.textContent).toLowerCase() : '';
        if ((alt && alt.length >= 2 && (alt === lowName || alt.indexOf(lowName) >= 0 || lowName.indexOf(alt) >= 0))
          || (ptxt && ptxt.length <= 50 && ptxt.indexOf(lowName) >= 0)) { match = src; }
      }
      // وجدنا صفّ كروت الألوان: نُرجع المطابق فقط — لا تخمين إن لم يطابق.
      if (swCount >= 1) return match;
      container = container.parentElement; hops++;
    }
    return '';
  }
  // نفس منطق temuSelectedColorCardImg بالضبط لكن تُرجع الكرت (العنصر
  // القابل للنقر) لا صورته - يُستخدم لإعادة الاختيار التلقائي عبر النقر
  // الفعلي (temuAutoReselectFromLink)، لا مجرد قراءة الصورة.
  function temuFindColorCardEl(colorName) {
    if (!colorName || colorName.length < 2) return null;
    var lowName = colorName.toLowerCase();
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    var colorHead = null;
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) { colorHead = nodes[i]; break; }
    }
    if (!colorHead) return null;
    var container = colorHead.parentElement, hops = 0;
    while (container && hops < 5) {
      var imgs = container.querySelectorAll('img');
      var matches = [];
      for (var j = 0; j < imgs.length; j++) {
        var src = imgs[j].currentSrc || imgs[j].src || '';
        if (!src || src.indexOf('http') !== 0) continue;
        var r = imgs[j].getBoundingClientRect();
        if (r.width < 28 || r.width > 220 || r.height < 28 || r.height > 220) continue;
        var alt = temuCleanText(imgs[j].getAttribute('alt') || imgs[j].getAttribute('title') || '').toLowerCase();
        var parentEl = imgs[j].parentElement || imgs[j];
        var ptxt = temuCleanText(parentEl.textContent).toLowerCase();
        if ((alt && alt.length >= 2 && (alt === lowName || alt.indexOf(lowName) >= 0 || lowName.indexOf(alt) >= 0))
          || (ptxt && ptxt.length <= 50 && ptxt.indexOf(lowName) >= 0)) { matches.push(parentEl); }
      }
      if (imgs.length >= 1) return matches.length === 1 ? matches[0] : null;
      container = container.parentElement; hops++;
    }
    return null;
  }
  // كرت اللون المختار افتراضياً (بلا نقرة الزبون ولا اسم نصي مطابق) — شبكة
  // أمان أخيرة لمنتجات كروت الصور المجرّدة (حقائب/ملابس بلا "اللون: X" ولا
  // alt نصي). الكرت المختار مُعلَّم بحدّ غامق فقط (نفحص الصورة وحاضنَيها
  // المباشرَين لاختلاف هيكلية القوالب). تطابق واحد بالضبط وإلا فارغ.
  function temuDefaultSelectedColorCard() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    var colorHead = null;
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) { colorHead = nodes[i]; break; }
    }
    if (!colorHead) { window.__otlobliTemuColorDiag = 'لا رأس قسم لون'; return null; }
    var container = colorHead.parentElement, hops = 0;
    while (container && hops < 5) {
      var imgs = container.querySelectorAll('img');
      var cards = [], parentEls = [], grandEls = [];
      for (var j = 0; j < imgs.length; j++) {
        var src = imgs[j].currentSrc || imgs[j].src || '';
        if (!src || src.indexOf('http') !== 0) continue;
        var r = imgs[j].getBoundingClientRect();
        if (r.width < 28 || r.width > 220 || r.height < 28 || r.height > 220) continue;
        var parentEl = imgs[j].parentElement || imgs[j];
        var grandEl = parentEl.parentElement || parentEl;
        cards.push({ img: imgs[j], src: src, parentEl: parentEl, grandEl: grandEl });
        parentEls.push(parentEl);
        grandEls.push(grandEl);
      }
      if (cards.length >= 1) {
        // نجرّب الكاشف متعدد الإشارات على مستوى الحاضن المباشر أولاً، ثم
        // الجدّ إن فشل (اختلاف هيكلية القوالب أين تُوضع علامة "المختار").
        var pickedEl = temuPickSingleSelected(parentEls) || temuPickSingleSelected(grandEls);
        if (pickedEl) {
          var pickedCard = null;
          for (var c = 0; c < cards.length; c++) {
            if (cards[c].parentEl === pickedEl || cards[c].grandEl === pickedEl) { pickedCard = cards[c]; break; }
          }
          if (pickedCard) {
            window.__otlobliTemuColorDiag = 'كروت=' + cards.length + ' نجاح';
            var altName = temuCleanText(pickedCard.img.getAttribute('alt') || pickedCard.img.getAttribute('title') || '');
            return { name: altName, image: pickedCard.src };
          }
        }
        var dbgBordered = 0;
        for (var db = 0; db < parentEls.length; db++) { if (temuHasDarkBorder(parentEls[db])) dbgBordered++; }
        window.__otlobliTemuColorDiag = 'كروت=' + cards.length + ' حدّغامق=' + dbgBordered;
        return null; // صفّ موجود لكن لا تطابق واحد واضح — لا تخمين
      }
      container = container.parentElement; hops++;
    }
    window.__otlobliTemuColorDiag = 'رأس موجود، صفر كروت صور (h' + hops + ')';
    return null;
  }
  // جدولة التقاط هيرو اللون (بعد إغلاق الشيت) — مشتركة بين فرعَي الالتقاط.
  function temuScheduleHeroCapture(gid) {
    function captureHero2() {
      if (window.__otlobliTemuColorGid !== gid) return;
      var himgs = document.querySelectorAll('img');
      var hbest = '', hbestA = 0;
      var vpH2 = viewportSize().height;
      for (var hi = 0; hi < himgs.length; hi++) {
        var hsrc = himgs[hi].currentSrc || himgs[hi].src || '';
        if (!/kwcdn|temu/i.test(hsrc)) continue;
        var hr = himgs[hi].getBoundingClientRect();
        if (hr.width < 200 || hr.height < 200) continue;
        // المعرض الرئيسي أعلى الصفحة فقط — لا صور الشيت المفتوح.
        if (hr.top > vpH2 * 0.5) continue;
        var ha = hr.width * hr.height;
        if (ha > hbestA) { hbestA = ha; hbest = hsrc; }
      }
      if (hbest) window.__otlobliTemuColorImg = hbest;
    }
    setTimeout(captureHero2, 700);
    setTimeout(captureHero2, 1600);
  }
  // مستمع نقر يسجّل آخر زر مقاس ضغطه الزبون فعلاً (المصدر الأوثق للمقاس).
  if (IS_TEMU && !window.__otlobliTemuClickBound) {
    window.__otlobliTemuClickBound = true;
    document.addEventListener('click', function (e) {
      // توجيه نقرات شريط otlobli السفلي: تيمو تضيف طبقات بنفس z-index الأقصى
      // بعد شريطنا في DOM فتبتلع نقراته حتى يُعاد ترتيبه (كل ثانيتين). نحن
      // مسجّلون أول مستمع capture على document (السكريبت يعمل documentStart)
      // فنستقبل النقرة قبل أي طبقة دخيلة ونوجّهها للتبويب الصحيح يدوياً.
      try {
        var navEl2 = document.getElementById('otlobli-nav');
        if (navEl2 && typeof e.clientY === 'number') {
          var nr2 = navEl2.getBoundingClientRect();
          if (nr2.height > 0 && e.clientY >= nr2.top && e.clientY <= nr2.bottom
              && e.clientX >= nr2.left && e.clientX <= nr2.right) {
            var inNav2 = false, tn2 = e.target, th2 = 0;
            while (tn2 && th2 < 8) {
              if (tn2.id && String(tn2.id).indexOf('otlobli') === 0) { inNav2 = true; break; }
              tn2 = tn2.parentElement; th2++;
            }
            if (!inNav2) {
              e.preventDefault();
              e.stopPropagation();
              // direction:rtl → التبويب الأول (الرئيسية) في أقصى اليمين
              var relX2 = (e.clientX - nr2.left) / Math.max(1, nr2.width);
              var idx2 = Math.floor((1 - relX2) * 4);
              if (idx2 < 0) idx2 = 0; if (idx2 > 3) idx2 = 3;
              var types2 = ['', 'openOrders', 'openCart', 'openProfile'];
              if (types2[idx2] && window.mobileApp && window.mobileApp.postMessage) {
                window.mobileApp.postMessage({ detail: { type: types2[idx2] } });
              }
              // نعيد شريطنا لآخر الـDOM فوراً ليستعيد أولوية الرسم
              try { document.body.appendChild(navEl2); } catch (err2) {}
              return;
            }
          }
        }
      } catch (errNav) {}
      try {
        // التقاط احتياطي للّون بعد أي نقرة: تيمو تُحدّث عنوان "اللون: X" بعد
        // الاختيار — يغطي كروت الألوان النصية (ساعات/إكسسوارات) التي لا
        // يلتقطها فرع (ب) لأنها بلا صور.
        if (!window.__otlobliTemuHeadingTimer) {
          window.__otlobliTemuHeadingTimer = setTimeout(function () {
            window.__otlobliTemuHeadingTimer = null;
            try {
              var hc = temuColorFromHeading();
              var gidH = temuGoodsId();
              // نقرة كرت لون حديثة (<1.2ث) على نفس المنتج = مصدر أوثق من
              // العنوان الذي قد لا يكون تحدّث بعد — لا نستبدلها.
              var recentCardClick = window.__otlobliTemuColorGid === gidH
                && window.__otlobliTemuColorTs && (Date.now() - window.__otlobliTemuColorTs) < 1200;
              if (hc && !recentCardClick && (window.__otlobliTemuColorGid !== gidH || window.__otlobliTemuColor !== hc)) {
                // منتج مختلف → الـswatch القديم لا يخصّه؛ نفس المنتج → نُبقيه
                // (نقرة كرت الصورة التقطته للتو وقد يسمّي العنوان اللون باسم آخر).
                if (window.__otlobliTemuColorGid !== gidH) window.__otlobliTemuColorSwatch = '';
                window.__otlobliTemuColor = hc;
                window.__otlobliTemuColorGid = gidH;
                window.__otlobliTemuColorImg = '';
                temuScheduleHeroCapture(gidH);
              }
            } catch (errH) {}
          }, 450);
        }
      } catch (errH2) {}
      try {
        // (أ) نقرة على زر مقاس.
        var pills = temuSizePills();
        var node = e.target, hops = 0;
        while (node && hops < 4 && pills.length) {
          var matched = false;
          for (var i = 0; i < pills.length; i++) {
            if (pills[i] === node) {
              var t = temuCleanText(node.textContent);
              if (t && t.length <= 24) {
                window.__otlobliTemuSize = t;
                window.__otlobliTemuSizeGid = temuGoodsId();
              }
              matched = true; break;
            }
          }
          if (matched) return;
          node = node.parentElement; hops++;
        }
        // (ب) نقرة على كرت لون.
        // المنطق: نتحقق من حجم العنصر (كرت فردي ≠ شبكة كاملة)، وندّعم
        // فقط الحالات التي يحوي فيها العنصر 1-4 صور. نأخذ اسم اللون من
        // alt الصورة أولاً، ثم آخر عنصر نصي ظاهر (نتجنب script/style/img).
        // نرفض أي قيمة تبدأ برقم أو تحتوي كود JS (يحلّ مشكلة script tag).
        if (temuHasColorSection()) {
          var isOkColorName = function(s) {
            return s.length >= 2 && s.length <= 50
              && /^[a-zA-Z\\u0600-\\u06FF]/.test(s)
              && !/^(color|image|select|add|qty|free|shipping|size)$/i.test(s)
              && !/[{};]|\\bvar\\b|\\bfor\\b|\\bfunction\\b/.test(s);
          };
          var cnode = e.target, ch = 0;
          while (cnode && ch < 6) {
            var cr3 = cnode.getBoundingClientRect ? cnode.getBoundingClientRect() : null;
            // حجم معقول لكرت لون فردي (يستبعد الشبكة الكاملة)
            if (cr3 && cr3.width > 20 && cr3.width < 300 && cr3.height > 20 && cr3.height < 420) {
              var cImgs = cnode.querySelectorAll ? cnode.querySelectorAll('img') : [];
              if (cImgs.length >= 1 && cImgs.length <= 4) {
                var cardImg2 = cImgs[0];
                // مصدر 1: alt الصورة
                var altN2 = temuCleanText(cardImg2.getAttribute('alt') || cardImg2.getAttribute('title') || '');
                var colorName2 = isOkColorName(altN2) ? altN2 : '';
                if (!colorName2) {
                  // مصدر 2: آخر عنصر ابن مرئي (من الآخر للأول — العنوان عادةً آخر ابن)
                  var cKids = cnode.children ? cnode.children : [];
                  for (var ck = cKids.length - 1; ck >= 0 && !colorName2; ck--) {
                    var ckTag = (cKids[ck].tagName || '').toLowerCase();
                    if (ckTag === 'img' || ckTag === 'script' || ckTag === 'style'
                        || ckTag === 'picture' || ckTag === 'source'
                        || ckTag === 'canvas' || ckTag === 'svg') continue;
                    var ckTxt = (cKids[ck].textContent || '')
                      .replace(/[^\\w\\u0600-\\u06FF\\s().\\-]/g, ' ')
                      .replace(/\\s+/g, ' ').trim();
                    if (isOkColorName(ckTxt)) colorName2 = ckTxt;
                  }
                }
                if (colorName2) {
                  var gidNow = temuGoodsId();
                  window.__otlobliTemuColor = colorName2;
                  window.__otlobliTemuColorGid = gidNow;
                  // طابع زمني: يمنع مؤقّت قراءة العنوان (450ms) من استبدال
                  // هذا اللون بقيمة عنوان لم تتحدّث بعد (سباق زمني).
                  window.__otlobliTemuColorTs = Date.now();
                  // الكرت الصغير = صورة اللون للعرض في السلة (colorImage).
                  // نقبل أي URL مطلق (http/https) لأن Temu قد تعتمد CDN مختلفة.
                  var cSrc = cardImg2.currentSrc || cardImg2.src || '';
                  window.__otlobliTemuColorSwatch = (cSrc && cSrc.indexOf('http') === 0) ? cSrc : '';
                  // امسح الهيرو القديم — سيُحدَّث بعد 250ms حين تُحدّث تيمو صورة الهيرو
                  window.__otlobliTemuColorImg = '';
                  // نحاول التقاط صورة الهيرو مرتين: 300ms و 600ms بعد النقر
                  // (تيمو قد تتأخر في تحديث الهيرو، والمحاولة الثانية هي الأدق)
                  ;(function(gid) {
                    function captureHero() {
                      if (window.__otlobliTemuColorGid !== gid) return;
                      var himgs = document.querySelectorAll('img');
                      var hbest = '', hbestA = 0;
                      var vpH0 = viewportSize().height;
                      for (var hi = 0; hi < himgs.length; hi++) {
                        var hsrc = himgs[hi].currentSrc || himgs[hi].src || '';
                        if (!/kwcdn|temu/i.test(hsrc)) continue;
                        var hr = himgs[hi].getBoundingClientRect();
                        if (hr.width < 200 || hr.height < 200) continue;
                        // المعرض الرئيسي أعلى الصفحة فقط — صور الشيت المفتوح
                        // (النصف السفلي) قد تكون للون قديم.
                        if (hr.top > vpH0 * 0.5) continue;
                        var ha = hr.width * hr.height;
                        if (ha > hbestA) { hbestA = ha; hbest = hsrc; }
                      }
                      if (hbest) window.__otlobliTemuColorImg = hbest;
                    }
                    // نُطيل الانتظار: الشيت قد يبقى مفتوحاً 400-700ms فيلتقط الـtimeout
                  // صورة لون قديمة من داخله بدل الهيرو الصحيح بعد إغلاقه.
                  setTimeout(captureHero, 700);
                  setTimeout(captureHero, 1600);
                  })(gidNow);
                  return;
                }
                // كرت لون بلا اسم (صورة فقط، بلا alt ولا نص — شائع بالفساتين):
                // نسجّل صورته على الأقل، والاسم سيأتي من عنوان "اللون: X" عبر
                // مؤقّت القراءة بعد النقرة. شرط أمان: الكرت قريب عمودياً من
                // رأس قسم اللون (يستبعد كروت المنتجات المقترحة أسفل الصفحة).
                var headNode3 = null;
                var hnScan = document.querySelectorAll('div, span, h2, h3, p, strong');
                for (var hn = 0; hn < hnScan.length; hn++) {
                  if (temuIsColorHeadText((hnScan[hn].textContent || '').trim())) { headNode3 = hnScan[hn]; break; }
                }
                if (headNode3) {
                  var hr3 = headNode3.getBoundingClientRect();
                  var cr4 = cnode.getBoundingClientRect();
                  if (hr3.height > 0 && cr4.top >= hr3.top - 60 && cr4.top - hr3.top < 300) {
                    var cSrc2 = cardImg2.currentSrc || cardImg2.src || '';
                    if (cSrc2 && cSrc2.indexOf('http') === 0) {
                      var gidNow2 = temuGoodsId();
                      if (window.__otlobliTemuColorGid !== gidNow2) window.__otlobliTemuColor = '';
                      window.__otlobliTemuColorGid = gidNow2;
                      window.__otlobliTemuColorSwatch = cSrc2;
                      window.__otlobliTemuColorImg = '';
                      temuScheduleHeroCapture(gidNow2);
                      return;
                    }
                  }
                }
              }
            }
            cnode = cnode.parentElement; ch++;
          }
        }
      } catch (err) {}
    }, true);
  }

  // منتج تخصيص (نقش اسم): نظام إشارات صارم بطبقتين — خربطة صفر.
  // الطبقة 1: عنوان المنتج نفسه يذكر تخصيصاً صريحاً (نقش اسم/محفور/engrav).
  //   لا نمسح كروت "منتجات مقترحة" (كانت تُفعّل جوارب بسبب سوارة مقترحة).
  // الطبقة 2: حقل إدخال هو فعلاً حقل تخصيص — نفحص سياقه (placeholder/label)
  //   لا مجرد وجوده: حقل الكمية "1" وحقل البحث كانا يُفعّلان كل المنتجات!
  var TEMU_PERSO_STRONG = /personaliz|engrav|محفور|محفورة|حفر\\s*اسم|نقش\\s*اسم|نقش\\s*الاسم|نقش\\s*نص|custom\\s*text|custom\\s*name|customiz|اكتب\\s*اسم|اسم\\s*مخصص|نص\\s*مخصص|اكتب\\s*نص|باسمك|بأسمك/i;
  // كلمات تدل أن الحقل حقل تخصيص (في placeholder/aria-label/name/id أو التسمية المجاورة)
  var TEMU_PERSO_INPUT = /نقش|اسم|نص\\s*مخصص|[أإا]دخ[اآ]?ل\\s*(?:النص|الاسم)|اكتب\\s*(?:النص|الاسم)|personaliz|engrav|custom|your\\s*(?:name|text)|enter\\s*(?:name|text)/i;
  // كلمات تنفي أن الحقل حقل تخصيص (كمية/بحث/كوبون/هاتف/بريد/عنوان)
  var TEMU_PERSO_ANTI = /كمية|كميه|qty|quantit|بحث|search|coupon|promo|كوبون|رمز|code|zip|postal|هاتف|phone|جوال|بريد|email|عنوان|address|password|كلمة/i;
  function temuPersoInputHint(inp) {
    var hint = (inp.getAttribute('placeholder') || '') + ' ' +
      (inp.getAttribute('aria-label') || '') + ' ' +
      (inp.getAttribute('name') || '') + ' ' + (inp.id || '');
    // التسمية المجاورة: نص الأب المباشر (قصير فقط — حتى لا نجرّ نص الصفحة كله)
    var par = inp.parentElement;
    for (var h = 0; par && h < 2; h++) {
      var pt = (par.textContent || '').trim();
      if (pt.length <= 90) hint += ' ' + pt;
      par = par.parentElement;
    }
    return hint;
  }
  function temuPersonalization() {
    // الطبقة 1: عنوان المنتج (المصدر الحاسم — لا يتأثر بالمنتجات المقترحة)
    var titleTxt = (temuTitle() || '') + ' ' + (document.title || '');
    var hasStrong = TEMU_PERSO_STRONG.test(titleTxt);
    // الطبقة 2: حقل تخصيص حقيقي مرئي (سياقه يؤكد أنه لإدخال اسم/نص)
    var inputs = document.querySelectorAll('input:not([type="hidden"]):not([type="checkbox"]):not([type="radio"]):not([type="submit"]):not([type="button"]):not([type="number"]):not([type="tel"]):not([type="email"]):not([type="search"]):not([type="file"]), textarea');
    for (var k = 0; k < inputs.length; k++) {
      var inp = inputs[k];
      var im = (inp.getAttribute('inputmode') || '').toLowerCase();
      if (im === 'numeric' || im === 'decimal' || im === 'search' || im === 'tel' || im === 'email') continue;
      var rp = inp.getBoundingClientRect();
      if (rp.width <= 20 || rp.height <= 10) continue;
      var hint = temuPersoInputHint(inp);
      if (TEMU_PERSO_ANTI.test(hint)) continue;           // كمية/بحث/كوبون → ليس تخصيصاً
      if (!TEMU_PERSO_INPUT.test(hint)) continue;          // لا دليل أنه حقل تخصيص → نتجاهله
      var v = (inp.value || '').trim();
      if (/^\\d+$/.test(v)) v = '';                        // قيمة رقمية بحتة = ليست نص نقش
      // (v58) حد أحرف النقش: من خاصية maxlength للحقل نفسه، وإلا من نص
      // التلميح المجاور ("بحد أقصى 10 أحرف" / "max 12 characters").
      var lim = parseInt(inp.getAttribute('maxlength') || '', 10);
      if (!(lim > 0 && lim <= 80)) {
        var lm = hint.match(/(\\d{1,2})\\s*(?:حرف|أحرف|حروف|characters?|chars?|letters?)/i);
        lim = lm ? parseInt(lm[1], 10) : 0;
      }
      return { has: true, text: v, inputVisible: true, textLimit: (lim > 0 && lim <= 80) ? lim : 0 };
    }
    // مؤشر قوي بالعنوان بدون حقل مرئي → التخصيص داخل الشيت، الاسم يُكتب في السلة
    if (hasStrong) return { has: true, text: '', inputVisible: false, textLimit: 0 };
    return { has: false, text: '', textLimit: 0 };
  }
  // (v58) بادج "التخصيص" الذي تضعه تيمو على صورة المنتج — نص قصير مطابق حرفياً.
  // نقيّده بأعلى الصفحة (أول ~900px من المستند) لأن كروت "قد يعجبك أيضاً"
  // أسفل الصفحة تحمل البادج نفسه على منتجات أخرى وكانت ستفعّل كل الصفحات.
  function temuCustomBadgeVisible() {
    var els = document.querySelectorAll('div, span, a, button, label');
    var scrollY = window.pageYOffset || 0;
    for (var i = 0; i < els.length; i++) {
      var t = temuCleanText(els[i].textContent);
      if (!t || t.length > 20) continue;
      if (!/^(?:التخصيص|تخصيص|قابل\\s*للتخصيص|customi[sz]ed?|personali[sz]ed?)$/i.test(t)) continue;
      var r = els[i].getBoundingClientRect();
      if (r.width <= 0 || r.height <= 0) continue;
      if (r.top + scrollY > 900) continue;
      return true;
    }
    return false;
  }
  // (v58) عنصر تحكم فعلي لرفع صورة: حقل ملف يقبل صوراً، أو زر نصّه حرفياً
  // "أضف/ارفع/تحميل صورة". يُستدعى فقط بعد ثبوت أن المنتج مخصص — "أضف صورة"
  // في قسم المراجعات مثلاً كانت تجعل كل المنتجات "تطلب صورة".
  function temuPhotoUploadControl() {
    if (document.querySelector('input[type="file"][accept*="image"], input[type="file"]:not([accept])')) return true;
    var els = document.querySelectorAll('button, a, div, span, label');
    for (var i = 0; i < els.length; i++) {
      var t = temuCleanText(els[i].textContent);
      if (!t || t.length > 22) continue;
      if (!/^(?:أضف|إضافة|ارفع|رفع|تحميل|حمّل)\\s*(?:ال)?صورة(?:\\s*هنا)?$|^(?:add|upload)\\s*(?:a\\s*|your\\s*)?(?:photo|image|picture)s?$/i.test(t)) continue;
      var r = els[i].getBoundingClientRect();
      if (r.width > 0 && r.height > 0) return true;
    }
    return false;
  }
  // أبعاد/وصف الصورة المخصصة المطلوبة — يبحث عن نصوص تذكر قياسات الصورة
  // مثل "800×800 بكسل" أو "photo size: 3:4 ratio" في صفحة المنتج.
  function temuCustomPhotoNote() {
    var els = document.querySelectorAll('div, span, p, li, strong, td, th');
    for (var i = 0; i < els.length; i++) {
      var t = (els[i].textContent || '').trim();
      if (!t || t.length < 4 || t.length > 120) continue;
      if (/\\d+\\s*[*x×]\\s*\\d+\\s*(?:px|pixel|بكسل)?/i.test(t)
       || /photo.*size|size.*photo|صورة.*حجم|حجم.*صورة|image.*size|size.*image/i.test(t)
       || /ratio|aspect|نسبة.*صورة|صورة.*نسبة/i.test(t)) {
        return t.slice(0, 100);
      }
    }
    return '';
  }

  // (v58) إشارات التخصيص الصارمة — "خربطة صفر":
  // تُطبَّق على عنوان المنتج (أو نص تحكم قصير مؤكد) فقط، وحُذفت منها الكلمات
  // العامة المفردة (اسم/نص/كتابة/صورة/رفع/عين/وجه) لأنها تظهر في كل صفحة
  // (مراجعات، شحن، واجهة المتجر، منتجات مقترحة) وكانت السبب الرئيسي في تحويل
  // منتجات عادية إلى "مخصصة" وحجز الدفع عبثاً.
  // تنبيه (v60): كلمة "نقش" وحدها ممنوعة — "بنقشة التنين/منقوش بطبعة" تعني
  // مطبوعاً بنمط جاهز لا تخصيصاً (جراب هاتف عادي فُعّل خطأً بسببها). نطابق
  // نقش فقط في سياق تخصيص صريح: "نقش اسم/نص"، "قابل للنقش"، "انقش اسمك".
  function otlobliCustomTextSignal(text) {
    return /custom\\s*(?:text|name)|personali[sz]|engrav|monogram|name\\s*plate|your\\s*(?:name|text)|enter\\s*(?:name|text)|نقش\\s*(?:اسم|الاسم|نص|النص|حسب)|قابل\\s*للنقش|انقش|محفور(?:ة)?\\s*(?:باسم|بالاسم|باسمك)|حفر\\s*(?:اسم|الاسم|نص)|بالاسم|باسمك|بأسمك|اسم\\s*مخصص|نص\\s*مخصص|اكتب\\s*(?:اسم|الاسم|نص|النص)/i.test(text || '');
  }

  function otlobliCustomPhotoSignal(text) {
    return /custom\\s*(?:photo|image|picture)|(?:upload|add)\\s*(?:a\\s*|your\\s*)?(?:photo|image|picture)|photo\\s*upload|image\\s*upload|with\\s*your\\s*(?:photo|picture)|صورة\\s*مخصصة|بصورتك|صورتك|بالصور|(?:أضف|إضافة|ارفع|رفع|تحميل|حمّل)\\s*(?:ال)?صورة/i.test(text || '');
  }

  function otlobliCustomGenericSignal(text) {
    return /customi[sz]|\\bcustom\\b|personali[sz]|مخصص|التخصيص|تخصيص|بتصميمك|حسب\\s*الطلب|\\bDIY\\b/i.test(text || '');
  }

  function otlobliVisibleCustomText() {
    var out = [];
    var nodes = document.querySelectorAll('h1, h2, h3, p, span, div, button, label, li');
    for (var i = 0; i < nodes.length && out.join(' ').length < 5000; i++) {
      var el = nodes[i];
      var r = el.getBoundingClientRect();
      if (r.width <= 0 || r.height <= 0) continue;
      var t = (el.textContent || '').replace(/\\s+/g, ' ').trim();
      if (!t || t.length > 180) continue;
      if (otlobliCustomGenericSignal(t) || otlobliCustomTextSignal(t) || otlobliCustomPhotoSignal(t) || /\\d+\\s*[*x×]\\s*\\d+/.test(t)) {
        out.push(t);
      }
    }
    return out.join(' ');
  }

  function otlobliCustomPhotoNoteFallback() {
    var pageText = otlobliVisibleCustomText();
    var sizeMatch = pageText.match(/\\d+\\s*[*x×]\\s*\\d+\\s*(?:px|pixel|بكسل)?/i);
    if (sizeMatch) return sizeMatch[0];
    if (otlobliCustomPhotoSignal(pageText)) return 'يرجى إرفاق الصورة المطلوبة لهذا المنتج المخصص';
    return '';
  }

  // (v58) قرار التخصيص لتيمو — طبقتان صارمتان:
  // 1) هل المنتج مخصص أصلاً؟ يُحسم من عنوان المنتج نفسه، أو بادج "التخصيص"
  //    أعلى الصفحة، أو حقل نقش حقيقي مرئي (perso). لا مسح نصي للصفحة كلها —
  //    كروت المنتجات المقترحة والمراجعات كانت تلوّث القرار.
  // 2) ماذا يحتاج (نص/صورة/كلاهما)؟ يُفحص فقط بعد ثبوت (1)، من العنوان
  //    وعناصر تحكم قصيرة مؤكدة. عند الغموض: الافتراض نص، والمستخدم يعدّل
  //    من السلة (أزرار +نص/+صورة و"ليس مخصصاً").
  function temuCustomRequirements(perso) {
    var titleTxt = (temuTitle() || '') + ' ' + (document.title || '');
    var isCustom = otlobliCustomGenericSignal(titleTxt)
      || otlobliCustomTextSignal(titleTxt)
      || otlobliCustomPhotoSignal(titleTxt)
      || !!(perso && perso.has)
      || temuCustomBadgeVisible();
    if (!isCustom) return { needsText: false, needsPhoto: false, photoNote: '', textLimit: 0 };
    var needsText = !!(perso && perso.has) || otlobliCustomTextSignal(titleTxt);
    var needsPhoto = otlobliCustomPhotoSignal(titleTxt) || temuPhotoUploadControl();
    // منتج مخصص وعنوانه يذكر عيوناً/وجهاً/حبيباً بالصورة (أساور نقش العين
    // الرائجة) → صورة، حتى لو لم يقل "صورة" صراحة.
    if (!needsPhoto && /(?:^|[\\s،:])(?:عين|عيون|للعينين|بالعين|وجه|وجهك|بورتريه)|\\bface\\b|\\beyes?\\b|\\bportrait\\b/i.test(titleTxt)) needsPhoto = true;
    // جراب/كفر مخصص بلا ذكر نقش = طباعة صورة عادةً.
    if (!needsText && !needsPhoto && /(phone|case|cover|جراب|كفر|حافظة)/i.test(titleTxt)) needsPhoto = true;
    // مخصص مؤكد والنوع غامض → نص (الأشيَع)، والمستخدم يستطيع التعديل بالسلة.
    if (!needsText && !needsPhoto) needsText = true;
    return {
      needsText: needsText,
      needsPhoto: needsPhoto,
      photoNote: needsPhoto ? (temuCustomPhotoNote() || otlobliCustomPhotoNoteFallback()) : '',
      textLimit: (perso && perso.textLimit) || 0,
    };
  }

  // (v58) نفس مبدأ تيمو: العنوان يحسم "هل هو مخصص"، وحقل الملف يُحتسب فقط
  // بعد ثبوت ذلك (شي إن فيها حقول رفع للمراجعات أيضاً).
  function sheinCustomRequirements() {
    var titleTxt = (getTitle(false) || '') + ' ' + (document.title || '');
    var isCustom = otlobliCustomGenericSignal(titleTxt)
      || otlobliCustomTextSignal(titleTxt)
      || otlobliCustomPhotoSignal(titleTxt);
    if (!isCustom) return { needsText: false, needsPhoto: false, photoNote: '', textLimit: 0 };
    var hasFile = !!document.querySelector('input[type="file"][accept*="image"]');
    var needsText = otlobliCustomTextSignal(titleTxt);
    var needsPhoto = hasFile || otlobliCustomPhotoSignal(titleTxt);
    if (!needsText && !needsPhoto) needsText = true;
    return {
      needsText: needsText,
      needsPhoto: needsPhoto,
      photoNote: needsPhoto ? otlobliCustomPhotoNoteFallback() : '',
      textLimit: 0,
    };
  }

  // هل توجد قائمة مقاسات؟ (عنوان "Size"/"المقاس"/"موديل متوافق")
  function temuHasSizeSection() { return !!temuSizeHeadEl(); }
  // صفحة المنتج المغلقة تعرض ملخّصاً مثل "7 Color, 3 Size" أو "5 اللون, 20 موديل"
  // قبل اكتمال الاختيار — هذا الزر يفتح لوحة الخيارات عند النقر عليه.
  function temuVariantSummaryEl() {
    var els = document.querySelectorAll('div, button, a, span');
    for (var i = 0; i < els.length; i++) {
      var t = temuCleanText(els[i].textContent);
      if (t.length > 65) continue;
      var hasClr = /\\d+\\s*(?:colou?rs?|ألوان|اللون|لون)/i.test(t);
      var hasSz  = /\\d+\\s*(?:sizes?|مقاس|مقاسات|موديل|model)/i.test(t);
      if (hasClr && hasSz) return els[i];
    }
    return null;
  }

  function captureProductPayload(colorState, sizeState, allowGenericTitle) {
    if (IS_TEMU) {
      var perso = temuPersonalization();
      var customReq = temuCustomRequirements(perso);
      // منتج التخصيص: نضع النص المطلوب مكان المقاس ليصل للمالك بوضوح.
      // حارس مزدوج: قيمة رقمية بحتة (حقل كمية التقط خطأً) لا تكون نص نقش أبداً.
      var persoTxt = (perso.text && !/^\\d+$/.test(perso.text)) ? perso.text : '';
      var temuSizeVal = (perso.has && persoTxt) ? ('نقش: ' + persoTxt) : temuSelectedSize();
      var temuColorSwatch = (window.__otlobliTemuColorSwatch && window.__otlobliTemuColorGid === temuGoodsId())
        ? window.__otlobliTemuColorSwatch : '';
      // شبكة أمان: لا swatch مخزّن (اختيار داخل الشيت/لون افتراضي) → نبحث
      // وقت الجذب عن كرت اللون المطابق للاسم المختار ونأخذ صورته.
      var temuColorVal = temuColor();
      if (!temuColorSwatch && temuColorVal) {
        temuColorSwatch = temuSelectedColorCardImg(temuColorVal) || '';
      }
      // شبكة أمان أخيرة: ما زالت الصورة مفقودة (كروت بلا اسم/alt نصي، أو
      // بلا عنوان "اللون: X" أصلاً - شائع بالحقائب/الملابس) → الكرت الوحيد
      // بحدّ غامق ضمن صفّ الألوان = المختار افتراضياً بصرياً.
      if (!temuColorSwatch) {
        var defCard = temuDefaultSelectedColorCard();
        if (defCard) {
          temuColorSwatch = defCard.image;
          if (!temuColorVal && defCard.name) temuColorVal = defCard.name;
        }
      }
      // اختيار بكرت صورة بلا اسم (أحذية/أجهزة): الصورة هي المرجع للمالك.
      if (!temuColorVal && temuColorSwatch) temuColorVal = 'حسب الصورة المرفقة';
      // صورة المنتج بالسلة: عند اختيار لون، صورة كرت اللون مضمونة 100%؛
      // temuImage() احتياط (وهو نفسه يفضّل الـswatch الآن).
      return {
        title: temuTitle(),
        priceUsd: temuPriceUsd(),
        image: temuColorSwatch || temuImage(),
        colorImage: temuColorSwatch,
        colorImageFound: !!temuColorSwatch,
        color: temuColorVal,
        size: temuSizeVal,
        sizesAvailable: [],
        sizesUnavailable: [],
        // نُرفق اللون/المقاس المختارين كمعاملات otlobli_* بالرابط المحفوظ -
        // تيمو تتجاهلها (معاملات مجهولة بلا تأثير) لكن هذا التطبيق يقرأها
        // عند إعادة فتح الرابط لاحقاً (من السلة/الطلبات) ليُعيد اختيار نفس
        // اللون والمقاس تلقائياً بدل صفحة افتراضية بلا اختيار.
        link: otlobliBuildDeepLink(location.href, temuColorVal, temuSizeVal),
        needsCustomPhoto: customReq.needsPhoto,
        customPhotoNote: customReq.photoNote,
        needsCustomText: customReq.needsText,
        customText: persoTxt,
        customTextLimit: customReq.textLimit || 0,
      };
    }
    var sheinCustomReq = sheinCustomRequirements();
    return {
      title: getTitle(allowGenericTitle),
      priceUsd: getPrice(),
      // Main product photo - always the gallery/hero image, never swapped
      // for the (much smaller) color swatch crop. The swatch travels
      // separately as colorImage so the app can show both.
      image: getMainImage(),
      colorImage: colorState.image || '',
      colorImageFound: !!colorState.image,
      color: colorState.selected,
      size: sizeState.selected,
      sizesAvailable: sizeState.available || [],
      sizesUnavailable: sizeState.unavailable || [],
      link: otlobliNormalizeSheinUrl(location.href),
      needsCustomPhoto: sheinCustomReq.needsPhoto,
      customPhotoNote: sheinCustomReq.photoNote,
      needsCustomText: sheinCustomReq.needsText,
      customText: '',
      customTextLimit: sheinCustomReq.textLimit || 0,
    };
  }

  // Dumps real ground-truth data about the current page to the JS console -
  // Android WebView forwards console.log to logcat (tag "chromium"), so this
  // can be read directly with "adb logcat" instead of guessing blind at
  // SHEIN's markup or depending on a perfectly-timed screenshot.
  // logcat truncates long single log entries hard, so log many SHORT lines
  // instead of one big JSON blob - and log what our OWN extraction functions
  // actually return right now, not just raw page data, so the real bug is
  // visible directly instead of needing to re-derive it by hand.
  function debugSnapshot(colorState, sizeState) {
    try {
      console.log('OTLOBLI_DBG A url=' + location.href.slice(0, 140));
      console.log('OTLOBLI_DBG B mainImage()=' + (getMainImage() || 'EMPTY').slice(0, 160));
      console.log('OTLOBLI_DBG C galleryImage()=' + (getGalleryImage() || 'EMPTY').slice(0, 160));

      (function debugGalleryGroup() {
        var imgs2 = document.querySelectorAll('img[src*="ltwebstatic"], img[src*="img.shein"], img[data-src*="ltwebstatic"], img[data-src*="img.shein"]');
        var byCls = {};
        var ord = [];
        for (var i2 = 0; i2 < imgs2.length; i2++) {
          var im = imgs2[i2];
          if (isInPromoWidget(im)) continue;
          var s2 = realImgSrc(im);
          if (!s2) continue;
          var pc = im.parentElement ? (im.parentElement.className || '').trim() : '';
          if (!pc) continue;
          if (!byCls[pc]) { byCls[pc] = []; ord.push(pc); }
          byCls[pc].push(im);
        }
        var bk = null;
        for (var k2 = 0; k2 < ord.length; k2++) {
          if (byCls[ord[k2]].length >= 3 && (!bk || byCls[ord[k2]].length > byCls[bk].length)) bk = ord[k2];
        }
        console.log('OTLOBLI_DBG M bestGroupKey=[' + (bk || 'NONE') + '] size=' + (bk ? byCls[bk].length : 0));
        if (bk) {
          var grp = byCls[bk];
          for (var g2 = 0; g2 < grp.length && g2 < 12; g2++) {
            var r = grp[g2].getBoundingClientRect();
            console.log('OTLOBLI_DBG N' + g2 + ' w=' + Math.round(r.width) + ' h=' + Math.round(r.height) + ' top=' + Math.round(r.top) + ' left=' + Math.round(r.left) + ' src=' + (realImgSrc(grp[g2]) || '').slice(-60));
          }
        }
      })();
      console.log('OTLOBLI_DBG D largestImage()=' + (getLargestSheinImage() || 'EMPTY').slice(0, 160));
      console.log('OTLOBLI_DBG E ogImage=' + (getMeta('og:image') || 'EMPTY').slice(0, 140));
      console.log('OTLOBLI_DBG F capturedColor=[' + colorState.selected + '] capturedSize=[' + sizeState.selected + '] colorImg=' + (colorState.image || 'EMPTY').slice(0, 140));

      var colorContainer = findOptionContainer('color', ['اللون', 'Color']);
      var sizeContainer = findOptionContainer('size', ['المقاس', 'Size']);
      console.log('OTLOBLI_DBG H colorContainerFound=' + !!colorContainer + ' cls=[' + (colorContainer ? colorContainer.className.slice(0, 80) : '') + ']');
      console.log('OTLOBLI_DBG I sizeContainerFound=' + !!sizeContainer + ' cls=[' + (sizeContainer ? sizeContainer.className.slice(0, 80) : '') + ']');
      if (colorContainer) console.log('OTLOBLI_DBG J colorHTML=' + colorContainer.outerHTML.slice(0, 150));
      if (sizeContainer) console.log('OTLOBLI_DBG K sizeHTML=' + sizeContainer.outerHTML.slice(0, 150));

      var byClassColor = document.querySelectorAll('[class*="color" i]');
      console.log('OTLOBLI_DBG L byClassColorCount=' + byClassColor.length);
      for (var bc = 0; bc < byClassColor.length && bc < 5; bc++) {
        console.log('OTLOBLI_DBG L' + bc + ' cls=[' + (byClassColor[bc].className || '').slice(0, 70) + '] kids=' + byClassColor[bc].children.length);
      }

      var imgs = document.querySelectorAll('img[src*="ltwebstatic"], img[src*="img.shein"], img[data-src*="ltwebstatic"], img[data-src*="img.shein"]');
      console.log('OTLOBLI_DBG G imgCount=' + imgs.length);
      for (var i = 0; i < imgs.length && i < 10; i++) {
        var img = imgs[i];
        var pCls = img.parentElement ? (img.parentElement.className || '') : '';
        console.log('OTLOBLI_DBG IMG' + i + ' promo=' + isInPromoWidget(img) + ' parentCls=[' + pCls.slice(0, 50) + '] realSrc=' + (realImgSrc(img) || 'EMPTY').slice(0, 120));
      }
    } catch (e) {
      console.log('OTLOBLI_DBG ERROR ' + e);
    }
  }

  // Shared by both add-to-cart entry points (our floating button, and
  // intercepting SHEIN's own "Add to bag" button): show the freeze/loading
  // modal, then RETRY scraping the page for up to ~5s. SHEIN is a heavy SPA -
  // on first tap the hero photo/title can still be mid-render, so a single
  // immediate read often comes back empty. Polling gives the page time to
  // finish rendering before we give up on any field, and the overlay updates
  // live so the user can see it's actively working, not stuck.
  function addToCartFlow(colorState, sizeState) {
    if (document.getElementById('otlobli-overlay')) return;
    if (IS_SHEIN) {
      var addBtn = document.getElementById('otlobli-add-btn');
      if (!ensureSheinSaudiStore({ navigate: true })) {
        showMessage(addBtn, 'نثبت متجر شي إن على السعودية والدولار... حاول بعد لحظة');
        return;
      }
      if (colorState && colorState.exists && !colorState.selected) {
        showMessage(addBtn, 'حدد اللون أولاً');
        return;
      }
      if (sizeState && sizeState.exists && !sizeState.selected) {
        showMessage(addBtn, 'حدد المقاس أولاً');
        return;
      }
      // Authoritative guard: even if the checks above thought a variant was
      // selected (SHEIN sometimes default-highlights a chip), a visible
      // "انقر للشراء"/"Please Select" placeholder means nothing is committed yet.
      if (sheinSkuSelectionPending()) {
        showMessage(addBtn, 'حدد نوع الموديلات أولاً');
        return;
      }
    }
    if (IS_SHEIN) debugSnapshot(colorState, sizeState);
    var payload = captureProductPayload(colorState, sizeState);
    showAddingOverlay(payload);

    var attempts = 0;
    var maxAttempts = 10;
    var intervalMs = 500;

    function isComplete(p, cs) {
      if (IS_TEMU) {
        // إذا اختار الزبون لوناً ننتظر حتى يُلتقط هيرو اللون (300ms بعد النقر)
        // حتى لا تدخل صورة اللون الافتراضي (الأسود) بدل اللون المختار (الأحمر مثلاً).
        var colorPicked = !!(window.__otlobliTemuColor && window.__otlobliTemuColorGid === temuGoodsId());
        // الـswatch يكفي (هو المصدر المضمون) — لا ننتظر الهيرو إن وُجد.
        var colorImgReady = !colorPicked || !!window.__otlobliTemuColorSwatch || !!window.__otlobliTemuColorImg;
        return !!p.title && !!p.image && p.priceUsd > 0 && colorImgReady;
      }
      return !!p.title && !!p.image && (!cs.exists || !!p.color);
    }

    function finalize(p) {
      // فاشل-بأمان لتيمو: لا نُرسل بيانات ناقصة أبداً (سعر صفر/بلا عنوان/بلا
      // صورة) - بدل ذلك نلغي ونطلب إعادة المحاولة، فلا تدخل خربطة للسلة.
      if (IS_TEMU && (!p.title || !p.image || !(p.priceUsd > 0))) {
        removeOverlay(0);
        var ab = document.getElementById('otlobli-add-btn');
        if (ab) showMessage(ab, 'تعذّر قراءة بيانات المنتج — حاول مرة ثانية');
        return;
      }
      updateOverlayContent(p, 'جاري إضافة المنتج لسلة otlobli...');
      preloadImage(p.image, 2500).then(function (ok) {
        if (!ok) p.image = (IS_TEMU ? temuImage() : getMainImage()) || p.image;
        try {
          if (window.mobileApp && window.mobileApp.postMessage) {
            window.mobileApp.postMessage({ detail: { type: 'addToCart', product: p } });
          }
        } catch (e) {}
        // Safety net: if the native side never acks (e.g. app backgrounded),
        // don't leave the user stuck behind a frozen overlay forever.
        setTimeout(function () {
          if (document.getElementById('otlobli-overlay')) removeOverlay(0);
        }, 4000);
      });
    }

    function attempt() {
      attempts++;
      var exhausted = attempts >= maxAttempts;
      var freshColor = getColorState();
      var freshSize = getSizeState();
      payload = captureProductPayload(freshColor, freshSize, exhausted);
      if (isComplete(payload, freshColor) || exhausted) {
        finalize(payload);
        return;
      }
      updateOverlayContent(payload, 'جاري التأكد من بيانات المنتج... (' + attempts + ')');
      setTimeout(attempt, intervalMs);
    }

    attempt();
  }

  function requestOpenOtlobliCart() {
    try {
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: 'openCart' } });
      }
    } catch (e) {}
  }

  window.addEventListener('messageFromNative', function (event) {
    var detail = event && event.detail;
    if (detail && detail.type === '__resize') {
      window.dispatchEvent(new Event('resize'));
      tick();
      return;
    }
    if (detail && detail.type === '__backTarget') {
      __otlobliBackTarget = detail.target === 'cart' ? 'cart' : 'home';
      ensureBackButton();
      return;
    }
    if (detail && detail.type === 'addToCartAck') {
      var overlay = document.getElementById('otlobli-overlay');
      if (overlay) {
        var shownAt = parseInt(overlay.getAttribute('data-shown-at') || '0', 10);
        var elapsed = Date.now() - shownAt;
        var wait = Math.max(0, 550 - elapsed);
        setTimeout(function () {
          markOverlaySuccess();
          removeOverlay(700);
        }, wait);
      }
    }
  });

  function showMessage(btn, text, durationMs) {
    var msg = document.getElementById('otlobli-msg');
    if (!msg) {
      var vp = viewportSize();
      msg = document.createElement('div');
      msg.id = 'otlobli-msg';
      msg.style.cssText = 'position:fixed;left:16px;top:' + (vp.height - 122) + 'px;width:' + (vp.width - 32) + 'px;z-index:2147483647;' +
        'background:#fff3cd;color:#7a5b00;border:1px solid #ffe28a;border-radius:10px;' +
        'padding:10px 14px;font-size:14px;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,.2);';
      document.body.appendChild(msg);
    }
    msg.textContent = text;
    msg.style.display = 'block';
    clearTimeout(window.__otlobliMsgTimer);
    // رسائل التشخيص (تحوي "[" — قوس السبب) تبقى أطول لإتاحة وقت للتصوير.
    var showFor = durationMs || (text.indexOf('[') >= 0 ? 6000 : 2500);
    window.__otlobliMsgTimer = setTimeout(function () { msg.style.display = 'none'; }, showFor);

    if (btn) {
      btn.style.animation = 'none';
      requestAnimationFrame(function () {
        btn.style.animation = 'otlobli-shake 0.4s';
      });
    }
  }

  // مؤشر تحميل خفيف يظهر فوراً عند الضغط على "أضف للسلة" في تيمو، طوال
  // مهلة التحقق (حتى 5 ثوانٍ) - قبل ظهور الطبقة الكاملة أو رسالة الحجب.
  // بلا هذا، الفاصل الصامت كان يبدو كأن التطبيق تجمّد (شكوى مستخدم حقيقية).
  function otlobliShowGateSpinner() {
    ensureOverlayStyle();
    if (document.getElementById('otlobli-gate-spinner')) return;
    var vp = viewportSize();
    var wrap = document.createElement('div');
    wrap.id = 'otlobli-gate-spinner';
    wrap.style.cssText = 'position:fixed;left:16px;top:' + (vp.height - 122) + 'px;width:' + (vp.width - 32) + 'px;z-index:2147483647;' +
      'background:#fff3cd;color:#7a5b00;border:1px solid #ffe28a;border-radius:10px;' +
      'padding:10px 14px;font-size:14px;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,.2);' +
      'display:flex;align-items:center;justify-content:center;gap:8px;direction:rtl;';
    var spin = document.createElement('span');
    spin.style.cssText = 'width:16px;height:16px;border-radius:50%;border:2px solid rgba(122,91,0,.25);' +
      'border-top-color:#7a5b00;animation:otlobli-spin .8s linear infinite;flex-shrink:0;';
    wrap.appendChild(spin);
    var label = document.createElement('span');
    label.textContent = 'جاري التحقق من المنتج...';
    wrap.appendChild(label);
    document.body.appendChild(wrap);
  }
  function otlobliRemoveGateSpinner() {
    var el = document.getElementById('otlobli-gate-spinner');
    if (el) el.remove();
  }

  function ensureShakeStyle() {
    if (document.getElementById('otlobli-style')) return;
    var style = document.createElement('style');
    style.id = 'otlobli-style';
    style.textContent = '@keyframes otlobli-shake {' +
      '10%,90%{transform:translateX(-1px)}' +
      '20%,80%{transform:translateX(2px)}' +
      '30%,50%,70%{transform:translateX(-4px)}' +
      '40%,60%{transform:translateX(4px)}}' +
      '@keyframes otlobli-slide-up{from{transform:translateY(120%);opacity:0}to{transform:translateY(0);opacity:1}}' +
      '@keyframes otlobli-pop2{from{transform:scale(.5);opacity:0}to{transform:scale(1);opacity:1}}' +
      '@keyframes otlobli-badge-pop{0%{transform:scale(0)}60%{transform:scale(1.35)}100%{transform:scale(1)}}';
    document.head.appendChild(style);
  }

  // Covers the whole page with an opaque, untappable overlay from the very
  // first tick() until SHEIN's UI has had a few polling cycles to actually
  // get hidden/blocked. Without this, there's a real (if short) window
  // right after a page loads where SHEIN's own buttons are rendered but our
  // hide/block pass hasn't reached them yet - confirmed by a user managing
  // to add a product to SHEIN's real cart from that exact window. Better to
  // make the user wait a beat than ever expose anything unprocessed.
  var __otlobliLoadingDone = false;
  function ensureLoadingOverlay() {
    if (__otlobliLoadingDone || document.getElementById('otlobli-loading')) return;
    ensureOverlayStyle();
    var vp = viewportSize();
    var overlay = document.createElement('div');
    overlay.id = 'otlobli-loading';
    // One below max - see the matching comment on #otlobli-overlay above,
    // same reasoning: never let this win a stacking tie against the nav bar.
    overlay.style.cssText = 'position:fixed;left:0;top:0;width:' + vp.width + 'px;height:' + vp.height + 'px;' +
      'background:#ffffff;z-index:2147483646;display:flex;align-items:center;justify-content:center;';
    overlay.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });
    overlay.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); }, true);
    var spinner = document.createElement('div');
    spinner.style.cssText = 'width:38px;height:38px;border-radius:50%;border:4px solid #d8efe4;' +
      'border-top-color:#006948;animation:otlobli-spin .8s linear infinite;';
    overlay.appendChild(spinner);
    document.body.appendChild(overlay);

    // Used to remove this after a flat 1100ms no matter what - on a slow
    // connection (the Syrian relay especially) the page is often still
    // mid-load well past that, so the spinner vanished early and left the
    // user staring at a half-rendered/blank page with nothing to indicate
    // it was still working. Now it waits for the real page-load signal
    // (with a short minimum so it doesn't just flash) and only force-closes
    // after 8s as a safety net for a page that never fires load at all.
    var minTimeElapsed = false;
    var pageReady = document.readyState === 'complete';
    function tryRemoveLoadingOverlay() {
      if (__otlobliLoadingDone || !minTimeElapsed || !pageReady) return;
      __otlobliLoadingDone = true;
      var el = document.getElementById('otlobli-loading');
      if (el) el.remove();
    }
    window.setTimeout(function () { minTimeElapsed = true; tryRemoveLoadingOverlay(); }, 400);
    if (!pageReady) {
      window.addEventListener('load', function () { pageReady = true; tryRemoveLoadingOverlay(); });
    }
    window.setTimeout(function () {
      if (__otlobliLoadingDone) return;
      __otlobliLoadingDone = true;
      var el = document.getElementById('otlobli-loading');
      if (el) el.remove();
    }, 8000);
  }

  // Dedicated "add to cart" action. Used to share a corner with a floating
  // cart-icon button, but that button was dropped entirely - the bottom nav
  // (see ensureOtlobliNav) already has its own "السلة" tab that does the
  // exact same thing, so the floating icon was pure redundancy. Placed
  // bottom-right (thumb reach, doesn't cover the header or SHEIN's own
  // price/title block), and only visible while looking at an actual
  // product page.
  function ensureAddToCartButton() {
    var btn = document.getElementById('otlobli-add-btn');
    if (!btn) {
      ensureShakeStyle();
      btn = document.createElement('button');
      btn.id = 'otlobli-add-btn';
      btn.setAttribute('aria-label', 'إضافة إلى سلة otlobli');
      // Cleared above ensureOtlobliNav's bar (~64px + safe-area) instead of
      // sitting flush with the screen edge, so the two never overlap.
      // translateZ(0)/will-change forces this onto its own GPU compositing
      // layer - a documented Android WebView quirk lets plain position:fixed
      // elements drift with the page during touch-scroll momentum (only
      // snapping back once scrolling fully stops, or in this case ending up
      // hidden behind the system nav bar when scrolling back up) instead of
      // staying pinned to the viewport the whole time; a composited layer
      // is what actually keeps it visually anchored throughout the gesture.
      // The 56px floor this used to need is gone now that the native side
      // applies its own bottom margin (enabledSafeBottomMargin in App.tsx) -
      // that's the real fix for the system nav bar overlap; this env()
      // fallback only needs to cover whatever small gesture-inset remains
      // after that, same as it did before that bug was ever introduced.
      // يُرفع بفجوة ثابتة 16px فوق شريط otlobli السفلي على كل الأجهزة: ارتفاع
      // الشريط = 74px + max(safe-area,16px)، فنضع الزر عند ذلك + 16px. الصيغة
      // القديمة (78px + safe-area) كانت تلاصق الشريط (~4px فقط على آيفون بنَقْش)
      // وتتداخل معه على الأجهزة بلا نَقْش — نستخدم الآن نفس حساب المنطقة الآمنة
      // للشريط تماماً فتبقى الفجوة ثابتة ومريحة أينما كان.
      btn.style.cssText = 'position:fixed;right:14px;bottom:calc(74px + max(env(safe-area-inset-bottom, 0px), 16px) + 16px);' +
        'transform:translateZ(0);will-change:transform;' +
        'min-width:128px;height:48px;z-index:2147483647;' +
        'background:#006948;color:#fff;border:none;border-radius:24px;display:none;align-items:center;' +
        'justify-content:center;gap:6px;font-size:14px;font-weight:800;line-height:1;direction:rtl;' +
        'box-shadow:0 6px 16px rgba(0,0,0,.32);padding:0 18px;animation:otlobli-pop2 .25s ease-out;';
      btn.textContent = '🛍 أضف للسلة';
      btn.addEventListener('click', function (event) {
        event.preventDefault();
        event.stopPropagation();
        if (IS_TEMU) {
          // شجرة قرار كاملة فاشلة-بأمان: لا نضيف أبداً قبل التأكد من كل قيمة
          // مطلوبة؛ أي شكّ → نمنع ونطلب الاختيار (خربطة = صفر).
          // أ) لوحة الخيارات مغلقة وفيها خيارات ("X Color, Y Size") → نفتحها.
          // مهم: نتحقق أن اللوحة مغلقة فعلاً قبل الحجب — النص "4 Color, 1 Size"
          // يبقى بالـDOM حتى بعد فتح اللوحة (خلف الشيت)، فنفرّق بين الحالتين:
          // اللوحة مفتوحة = أزرار المقاس ظاهرة بالشاشة، أو الزبون سبق نقر لون.
          var summaryEl = temuVariantSummaryEl();
          if (summaryEl) {
            var vp2 = viewportSize();
            var sheetAlreadyOpen = false;
            var sizePillsChk = temuSizePills();
            for (var spx = 0; spx < sizePillsChk.length && !sheetAlreadyOpen; spx++) {
              var rspx = sizePillsChk[spx].getBoundingClientRect();
              if (rspx.width > 0 && rspx.height > 0 && rspx.top >= 0 && rspx.top < vp2.height) {
                sheetAlreadyOpen = true;
              }
            }
            if (!sheetAlreadyOpen &&
                (window.__otlobliTemuColor || window.__otlobliTemuColorSwatch) &&
                window.__otlobliTemuColorGid === temuGoodsId()) {
              sheetAlreadyOpen = true;
            }
            // منتج بلا خيارات فعلية ("1 اللون, 1 مقاس") — لا داعي لفتح اللوحة،
            // الجذب الذكي يحدد اللون والمقاس الوحيدين تلقائياً.
            if (!sheetAlreadyOpen) {
              var vcPre = temuVariantCounts();
              if (vcPre.colors === 1 && vcPre.sizes === 1) sheetAlreadyOpen = true;
            }
            if (!sheetAlreadyOpen) {
              showMessage(btn, 'حدد الخيارات أولاً');
              try { summaryEl.click(); } catch (e) {}
              return;
            }
          }
          // ب) منتج مخصص يحتاج صورة (بالكشف الصارم v58) → نُنبّه ونكمل الإضافة
          // (الصورة تُرفق في السلة).
          var persoChk = temuPersonalization();
          if (temuCustomRequirements(persoChk).needsPhoto) {
            showMessage(btn, 'أضف صورتك في السلة قبل إتمام الطلب');
          }
          // ج) منتج تخصيص نصّي (نقش اسم).
          if (persoChk.has && !persoChk.text) {
            if (persoChk.inputVisible) {
              // الحقل ظاهر وفارغ → نطلب الكتابة الآن
              showMessage(btn, 'اكتب النص/الاسم المطلوب أولاً');
              return;
            }
            // الحقل داخل الشيت أو مخفي → نُضيف للسلة مع hint (الاسم يُكتب في السلة)
            showMessage(btn, 'أضف الاسم/النص المطلوب في السلة قبل الدفع');
          }
          // نقرأ عدد الألوان والمقاسات من ملخّص المتغيّرات (أدق من عدّ الـpills).
          function temuFinalizeAdd(attemptsLeft) {
          var vCounts = temuVariantCounts();
          var knownOneColor = vCounts.colors === 1;  // "1 اللون"
          var knownOneSize  = vCounts.sizes  === 1;  // "1 موديل" أو "1 مقاس"
          var blockMsg = '';
          // د) فيه ألوان متعددة لكن لم يُحدّد لون — لون وحيد يمرّ مباشرة.
          // يسري على منتجات التخصيص أيضاً (سوارة النقش لها ألوان يجب جذبها).
          // نقرة كرت صورة بلا اسم (أحذية/أجهزة) تُحتسب اختياراً عبر الـswatch.
          var swatchChosen = !!(window.__otlobliTemuColorSwatch && window.__otlobliTemuColorGid === temuGoodsId());
          if (temuHasColorSection() && !knownOneColor && !temuHasSingleColor()) {
            // حارس صارم: لا يكفي اسم اللون النصي — نتحقق أن **صورة** الكرت
            // نفسها ستُلتقط فعلاً، بنفس سلسلة captureProductPayload بالضبط
            // (نقرة → مطابقة بالاسم → الكرت الوحيد بحدّ غامق). أي فشل في
            // الصورة = حجب، حتى لو اسم اللون معروفاً (يمنع دخول صورة خاطئة).
            var gateColorSwatch = swatchChosen ? window.__otlobliTemuColorSwatch : '';
            var gateColorVal = temuColor();
            if (!gateColorSwatch && gateColorVal) {
              gateColorSwatch = temuSelectedColorCardImg(gateColorVal) || '';
            }
            if (!gateColorSwatch) {
              var gateDefColor = temuDefaultSelectedColorCard();
              if (gateDefColor) gateColorSwatch = gateDefColor.image;
            }
            if (!gateColorSwatch) {
              blockMsg = 'حدد اللون أولاً';
            }
          }
          if (!blockMsg && !persoChk.has) {
            // ذكاء: مقاس وحيد → نحدّده تلقائياً قبل التحقق (يحلّ مشكلة ONE SIZE).
            if (knownOneSize || temuHasSizeSection()) temuForceSingleSize();
            // هـ) فيه مقاسات/موديلات متعددة لكن لم يُحدّد شيء.
            // (لمنتجات التخصيص لا نفحص المقاس — خانته تحمل نص النقش.)
            if (temuHasSizeSection() && !temuSelectedSize() && !knownOneSize) {
              var sHead = temuSizeHeadEl();
              var sLabel = sHead ? (sHead.textContent || '').trim() : 'المقاس';
              blockMsg = /موديل/i.test(sLabel) ? 'حدد موديل جوالك أولاً' : 'حدد المقاس أولاً';
            }
          }
          if (blockMsg) {
            if (attemptsLeft > 0) { setTimeout(function () { temuFinalizeAdd(attemptsLeft - 1); }, 500); return; }
            otlobliRemoveGateSpinner();
            showMessage(btn, blockMsg);
            return;
          }
          // ز) السعر: لا نضيف بصفر/غير مقروء.
          if (!(temuPriceUsd() > 0)) {
            if (attemptsLeft > 0) { setTimeout(function () { temuFinalizeAdd(attemptsLeft - 1); }, 500); return; }
            otlobliRemoveGateSpinner();
            showMessage(btn, 'تعذّر قراءة السعر — انتظر ثانية وحاول');
            return;
          }
          // و) كل شيء مؤكّد → نضيف. الطبقة الكاملة (showAddingOverlay) تتولى
          // من هنا فوراً - نزيل مؤشر التحقق المؤقت أولاً حتى لا يتعارضا.
          otlobliRemoveGateSpinner();
          addToCartFlow({ exists: false }, { exists: false });
          }
          // مؤشر تحميل فوري: التحقق قد يستغرق حتى 5 ثوانٍ (10 محاولات) قبل
          // إظهار طبقة الإضافة الكاملة أو رسالة الحجب - بلا هذا المؤشر يبدو
          // التطبيق متجمداً في تلك الأثناء (شكوى مستخدم حقيقية). لا نغيّر
          // منطق الجذب/التحقق نفسه إطلاقاً - مجرّد تغذية بصرية فورية.
          otlobliShowGateSpinner();
          temuFinalizeAdd(10);
          return;
        }
        if (!IS_SHEIN) {
          addToCartFlow({ exists: false }, { exists: false });
          return;
        }
        var colorState = getColorState();
        var sizeState = getSizeState();
        if (sizeState.exists && !sizeState.selected) {
          showMessage(btn, 'حدد المقاس أولاً');
          return;
        }
        if (colorState.exists && !colorState.selected) {
          showMessage(btn, 'حدد اللون أولاً');
          return;
        }
        addToCartFlow(colorState, sizeState);
      }, true);
      document.body.appendChild(btn);
    }
    // Deliberately NOT re-claiming "last child of body" here on every tick
    // like ensureOtlobliNav does - this button has a pop-in entrance
    // animation (otlobli-pop2), and re-appendChild-ing an EXISTING node
    // retriggers that animation every time, which on a busy SPA page (where
    // something else is *always* getting added after it) meant this button
    // visibly flickered/re-popped every ~300ms. The nav bar doesn't have
    // that animation and visually can't tell the difference, so it was safe
    // there; this one very much could.
    // A full-screen product gallery is for viewing/swiping only. Keeping the
    // floating add button alive inside it exposed a tappable area in SHEIN's
    // black lower letterbox (confirmed on iPhone 16), so both stores suppress
    // the action until their viewer closes.
    var showAddBtn = looksLikeProductPage() &&
      !(IS_TEMU && temuImageViewerOpen()) &&
      !(IS_SHEIN && sheinImageViewerOpen());
    btn.style.display = showAddBtn ? 'flex' : 'none';
  }

  // otlobli's own bottom navigation bar, drawn as part of this page instead
  // of relying on a separately-sized native layer underneath to line up with
  // it pixel-for-pixel (that cross-layer alignment is what went wrong on
  // iOS - the webview and otlobli's React nav drifted out of sync and left a
  // black gap where the nav should be). Since this bar lives inside the same
  // webview as everything else here, env(safe-area-inset-bottom) handles the
  // home-indicator inset correctly with zero native-side math.
  // Plain inline-SVG outline icons instead of emoji - emoji glyphs render
  // inconsistently across platforms/fonts, while these always look the same
  // regardless of what page/font context they're injected into.
  var OTLOBLI_NAV_ICONS = {
    home: '<path d="M4 11.5 12 4l8 7.5"/><path d="M6 10v9h12v-9"/><path d="M10 19v-5h4v5"/>',
    orders: '<rect x="4" y="7" width="16" height="13" rx="1.3"/><path d="M4 7l8-4 8 4"/><path d="M12 11v9"/>',
    cart: '<circle cx="9" cy="20" r="1.3"/><circle cx="18" cy="20" r="1.3"/>' +
      '<path d="M3 4h2l2.2 11.5a2 2 0 0 0 2 1.6h8.6a2 2 0 0 0 2-1.6L21 8H6"/>',
    profile: '<circle cx="12" cy="8" r="3.6"/><path d="M5 20c0-3.8 3.1-6.4 7-6.4s7 2.6 7 6.4"/>',
  };

  var __otlobliNavLastReclaim = 0;
  function otlobliNavIsActuallyCovered(nav) {
    if (!nav || !document.elementFromPoint) return false;
    var rect = nav.getBoundingClientRect();
    if (!rect || rect.width < 1 || rect.height < 1) return false;
    var y = Math.min(window.innerHeight - 1, rect.top + Math.min(34, rect.height / 2));
    var xs = [0.125, 0.375, 0.625, 0.875];
    for (var i = 0; i < xs.length; i++) {
      var hit = document.elementFromPoint(rect.left + rect.width * xs[i], y);
      if (hit && hit !== nav && !nav.contains(hit)) return true;
    }
    return false;
  }

  // When SHEIN opens a bottom drawer/modal (e.g. the "نوع الموديلات" sku
  // picker) it can extend up into — or render its lower options behind — our
  // fixed nav, which sits at the max z-index. A tap on a drawer option that
  // overlaps the nav band was landing on the nav tab underneath instead (a user
  // tapped "50 قطعة" and got sent to "طلباتي"). While such an overlay is on
  // screen the nav must stop intercepting taps so they reach the drawer; we
  // restore it the moment the drawer closes.
  function otlobliNavShouldYield(nav) {
    if (!IS_SHEIN || !document.body) return false;
    var navRect = nav.getBoundingClientRect();
    if (navRect.height <= 0) return false;
    var vp = viewportSize();
    var overlays = document.querySelectorAll('.sui-drawer__body,[role="dialog"],[aria-modal="true"],[class*="drawer" i],[class*="cascade" i]');
    for (var i = 0; i < overlays.length; i++) {
      var m = overlays[i];
      if (!m || (m.id && m.id.indexOf('otlobli') === 0)) continue;
      if (!sheinElementIsVisible(m)) continue;
      var r = m.getBoundingClientRect();
      if (r.width >= vp.width * 0.6 && r.height >= vp.height * 0.25 &&
          r.bottom > navRect.top + 4 && r.top < navRect.bottom) {
        return true;
      }
    }
    return false;
  }

  function otlobliApplyNavYield(nav) {
    var shouldYield = otlobliNavShouldYield(nav);
    var isYielding = nav.getAttribute('data-otlobli-nav-yield') === '1';
    if (shouldYield && !isYielding) {
      nav.style.setProperty('pointer-events', 'none', 'important');
      nav.setAttribute('data-otlobli-nav-yield', '1');
    } else if (!shouldYield && isYielding) {
      nav.style.setProperty('pointer-events', 'auto', 'important');
      nav.removeAttribute('data-otlobli-nav-yield');
    }
  }

  function otlobliStabilizeTemuNavLayer(nav) {
    if (!IS_TEMU || !nav || !document.documentElement) return;
    // Temu scrolls/repaints BODY as its application surface. A fixed child of
    // that surface can remain correct in the DOM yet disappear from WebKit's
    // async scrolling layer during a fast direction change. Keep Otlobli's
    // navigation as a sibling of BODY and give it an isolated paint layer.
    // This was verified against the live Temu DOM with repeated fast swipes.
    if (nav.parentNode !== document.documentElement) {
      document.documentElement.appendChild(nav);
    }
    if (nav.getAttribute('data-otlobli-temu-root-layer') !== '1') {
      nav.style.setProperty('-webkit-backface-visibility', 'hidden', 'important');
      nav.style.setProperty('backface-visibility', 'hidden', 'important');
      nav.style.setProperty('isolation', 'isolate', 'important');
      nav.style.setProperty('contain', 'layout style paint', 'important');
      nav.setAttribute('data-otlobli-temu-root-layer', '1');
    }
  }

  function ensureOtlobliNav() {
      // 12px يطابق خط شريط otlobli الحقيقي (0.76rem ≈ 12.2px) — كان 11px
      // فيبدو الشريطان مختلفين عند التنقل بين المتجر وبقية الشاشات.
    var existingNav = document.getElementById('otlobli-nav');
    if (existingNav) {
      if (existingNav.getAttribute('data-otlobli-nav-style') !== OTLOBLI_NAV_STYLE_VERSION) {
        existingNav.style.cssText = OTLOBLI_NAV_CSS;
        existingNav.setAttribute('data-otlobli-nav-style', OTLOBLI_NAV_STYLE_VERSION);
      }
      otlobliStabilizeTemuNavLayer(existingNav);
      // Re-claiming "last child of body" fixes a real bug (SHEIN's own SPA
      // keeps inserting new elements - promo banners, popups, app-install
      // prompts - some at the SAME max z-index we use, and on a tie the
      // LATER sibling in DOM order wins paint priority; without re-claiming,
      // one of those could end up physically covering, and silently
      // swallowing taps on, our own nav bar - confirmed symptom: cart tab
      // going unresponsive until switching tabs and back). But moving an
      // already-mounted node still costs a reflow even though its position:
      // fixed coordinates don't change, and doing that every single 300ms
      // tick (this runs that often) was visibly unsettling the bar/causing a
      // flicker on a page that's nearly always inserting *something*. Once
      // every ~2s is still fast enough that a stray SHEIN element can't sit
      // on top for long, at a fraction of the reflow cost.
      var now = Date.now();
      var navHost = IS_TEMU && document.documentElement ? document.documentElement : document.body;
      if (existingNav !== navHost.lastElementChild && now - __otlobliNavLastReclaim > 2000 &&
          otlobliNavIsActuallyCovered(existingNav)) {
        __otlobliNavLastReclaim = now;
        navHost.appendChild(existingNav);
      }
      otlobliApplyNavYield(existingNav);
      return;
    }
    ensureShakeStyle();
    var nav = document.createElement('div');
    nav.id = 'otlobli-nav';
    // Max z-index (tied with the other otlobli overlays, and appended last
    // so it wins paint order among ties) - guarantees this sits above any
    // bottom bar SHEIN's own page might render now that the webview is
    // full-screen, rather than hoping ours happens to be on top.
    // Matches otlobli's real .bottom-nav as closely as a separate webview
    // can: same colors (--primary #006948 / --muted #3d4a42), same ~74px
    // min-height, same 4px top indicator bar on the active tab, and the
    // same 440px max-width/centering (matters on tablets - on a phone-width
    // screen this is identical to full width).
    // max() floor matches otlobli's real .bottom-nav (see styles.css): on
    // Android, env(safe-area-inset-bottom) can report 0 even with a 3-button
    // system nav bar on screen, letting taps near the bottom edge land in
    // the system's gesture/button strip instead of these nav buttons.
    // translateZ(0)/will-change forces this onto its own GPU compositing
    // layer - confirmed real symptom: a plain position:fixed bar on Android
    // WebView showed correctly while scrolling down, but disappeared behind
    // the phone's own system navigation bar when scrolling back up. A
    // composited layer keeps it visually pinned to the viewport throughout
    // the scroll gesture instead of drifting with page content/system UI.
    // The system-nav-bar overlap this used to need a bigger floor for is
    // really fixed natively now (enabledSafeBottomMargin in App.tsx) - the
    // WebView's own bounds correctly shrink to avoid the system bar at the
    // native level, so env(safe-area-inset-bottom) only has whatever small
    // gesture-inset is left over to report. Back to the original 16px floor
    // for that, same as before that bug was ever introduced - a bigger one
    // now would just add needless empty space under the icons.
    // direction:rtl ثابت حتى يكون ترتيب الأزرار (الرئيسية يمين ← حسابي يسار)
    // نفسه على كل المتاجر؛ بدونه ينقلب على المتاجر LTR مثل تيمو.
    nav.style.cssText = OTLOBLI_NAV_CSS;
    nav.setAttribute('data-otlobli-nav-style', OTLOBLI_NAV_STYLE_VERSION);
    var items = [
      { label: 'الرئيسية', icon: OTLOBLI_NAV_ICONS.home, type: '' },
      { label: 'طلباتي', icon: OTLOBLI_NAV_ICONS.orders, type: 'openOrders' },
      { label: 'السلة', icon: OTLOBLI_NAV_ICONS.cart, type: 'openCart' },
      { label: 'حسابي', icon: OTLOBLI_NAV_ICONS.profile, type: 'openProfile' },
    ];
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var tab = document.createElement('button');
      // Without its own id, only the #otlobli-nav CONTAINER was recognized
      // as "ours" by the document click listener's otlobli-id guard - by the
      // time the walk reaches that far up, isQuickAddSubmitButton() had
      // ALREADY matched the cart tab's own text ("السلة" is literally in its
      // loose cart-keyword regex) and silently swallowed the click before
      // ever getting there. Confirmed real bug, not a guess: the cart tab's
      // own label defeats SHEIN's "quick add" button blocker, which exists
      // to silently eat listing-card mini cart buttons - ours looked like
      // one of those to it. Each tab needs its own otlobli-prefixed id so
      // that guard catches it at depth 0, before any of the is*() checks run.
      tab.id = 'otlobli-nav-tab-' + i;
      var isActiveTab = !item.type;
      // Keep Flex for old WKWebView compatibility, but let each cell stretch
      // through the nav's real content box. A forced 74px button sat lower;
      // CSS Grid collapsed to content width on the user's older iPhone.
      // px ثابت (وليس rem) وخط محدّد صراحةً: بعض المتاجر (تيمو) تضبط خط جذر
      // ضخم فتصير وحدات rem والخط الموروث هائلة فيتشوّه الشريط - التثبيت بالـpx
      // يجعله بنفس مقاس وتصميم شي إن على كل المتاجر.
      tab.style.cssText = 'position:relative!important;flex:1 1 25%!important;width:25%!important;max-width:25%!important;' +
        'min-width:0!important;height:auto!important;min-height:0!important;align-self:stretch!important;border:0!important;' +
        'background:transparent!important;display:flex!important;flex-direction:column!important;align-items:center!important;' +
        'justify-content:center!important;padding:10px 0 0 0!important;margin:0!important;' +
        'box-sizing:border-box!important;font-size:12px!important;line-height:normal!important;font-weight:700!important;' +
        'font-family:OtlobliCairo,system-ui,-apple-system,sans-serif!important;color:' + (isActiveTab ? '#006948' : '#3d4a42') + '!important;';
      if (isActiveTab) {
        var indicator = document.createElement('span');
        indicator.style.cssText = 'position:absolute!important;top:0!important;left:50%!important;transform:translateX(-50%)!important;width:32px!important;height:4px!important;border-radius:999px!important;background:#006948!important;';
        tab.appendChild(indicator);
      }
      tab.insertAdjacentHTML('beforeend', '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
        'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + item.icon + '</svg>' +
        '<span style="font:inherit!important;line-height:normal!important;margin-top:4px!important">' + item.label + '</span>');
      if (item.type) {
        (function (messageType) {
          tab.addEventListener('click', function (event) {
            event.preventDefault();
            event.stopPropagation();
            try {
              if (window.mobileApp && window.mobileApp.postMessage) {
                window.mobileApp.postMessage({ detail: { type: messageType } });
              }
            } catch (e) {}
          }, true);
        })(item.type);
      }
      nav.appendChild(tab);
    }
    if (IS_TEMU) otlobliStabilizeTemuNavLayer(nav);
    else document.body.appendChild(nav);
  }

  // Lets the user always get back out of wherever they navigated to inside
  // SHEIN. Two modes depending on how this view was entered:
  // - "cart": this webview was opened from a cart item tap; tapping back
  //   asks the app to switch back to the otlobli cart screen.
  // - "home" (default): normal browsing from the home tab; tapping back just
  //   walks the webview's own in-page history, same as a browser back button.
  var __otlobliBackTarget = 'home';

  function ensureBackButton() {
    var btn = document.getElementById('otlobli-back-btn');
    if (!btn) {
      ensureShakeStyle();
      btn = document.createElement('button');
      btn.id = 'otlobli-back-btn';
      btn.setAttribute('aria-label', 'رجوع');
      // Top-right corner, mirroring the cart button's top-left spot, so the
      // two don't crowd into the same corner.
      // translateZ(0)/will-change forces this onto its own GPU compositing
      // layer - see the matching comment on the nav bar's cssText. Confirmed
      // real symptom here too: this button visibly drifted/moved during
      // scroll instead of staying pinned to the same spot on screen.
      btn.style.cssText = 'position:fixed;right:10px;top:12px;width:42px;height:42px;z-index:2147483647;' +
        'transform:translateZ(0);will-change:transform;' +
        'background:rgba(20,24,22,.6);color:#fff;border:none;border-radius:11px;display:none;' +
        'align-items:center;justify-content:center;font-size:30px;line-height:1;font-family:Arial,system-ui,sans-serif;font-weight:700;' +
        'box-shadow:0 4px 12px rgba(0,0,0,.32);animation:otlobli-pop2 .25s ease-out;';
      // Right-pointing arrow reads as "back" in this RTL UI, matching the
      // app's own header back button convention (arrow_forward icon).
      btn.innerHTML = '&#8250;';
      btn.addEventListener('click', function (event) {
        event.preventDefault();
        event.stopPropagation();
        if (__otlobliBackTarget === 'cart') {
          try {
            if (window.mobileApp && window.mobileApp.postMessage) {
              window.mobileApp.postMessage({ detail: { type: 'backToCart' } });
            }
          } catch (e) {}
          return;
        }
        // Only ever go back while we're actually somewhere other than the
        // SHEIN home root - history.length isn't a safe proxy for that (the
        // language-redirect reload and SHEIN's own verification redirect
        // both add entries that were never real user navigation, so a back()
        // from the root could land back on a half-finished verification
        // page instead of doing nothing).
        // تيمو أثناء البحث: البحث overlay بلا history، فتفريغ حقل البحث + إطلاق
        // input event يجعل تيمو يُخفي لوحة الاقتراحات ويرجع للرئيسية، ثم blur
        // يغلق الكيبورد. history.back كان يعلّق الشاشة (لا صفحة سابقة).
        if (IS_TEMU && otlobliTemuSearchMode()) {
          var tsi = otlobliTemuSearchInput();
          if (tsi) {
            try {
              var vproto = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
              if (vproto && vproto.set) vproto.set.call(tsi, ''); else tsi.value = '';
              tsi.dispatchEvent(new Event('input', { bubbles: true }));
            } catch (e) {}
            try { if (tsi.blur) tsi.blur(); } catch (e) {}
          } else if (document.activeElement && document.activeElement.blur) {
            try { document.activeElement.blur(); } catch (e) {}
          }
        } else if (!looksLikeHomeRoot() || (IS_TEMU && looksLikeProductPage())) {
          history.back();
        }
      }, true);
      document.body.appendChild(btn);
    }
    // Deliberately NOT re-claiming "last child of body" here on every tick -
    // see the matching comment in ensureAddToCartButton. This button has the
    // same otlobli-pop2 entrance animation, which a repeated appendChild on
    // an already-mounted node retriggers, causing a visible flicker every
    // ~300ms on a page that's always inserting something else after it.
    // تيمو SPA قد تفتح المنتج على نفس مسار الرئيسية (query string فقط)
    // فكان looksLikeHomeRoot يخفي زر الرجوع داخل المنتج ويحبس الزبون.
    var shouldShow = __otlobliBackTarget === 'cart' || !looksLikeHomeRoot()
      || (IS_TEMU && looksLikeProductPage()) || (IS_TEMU && otlobliTemuSearchMode());
    btn.style.setProperty('top', (IS_SHEIN && viewportSize().width <= 390) ? '58px' : '12px', 'important');
    btn.style.display = shouldShow ? 'flex' : 'none';
  }

  function isAddToCartText(el) {
    var text = (el.textContent || '').trim();
    if (!text || text.length > 60) return false;
    // The Arabic-only regex below is what was actually missing - SHEIN's
    // Jordan site (forced to Arabic above) labels this "أضف إلى عربة
    // التسوق"/"أضف للسلة", never the English text this previously only
    // matched, so the click interceptor never caught it and SHEIN's real
    // add-to-cart fired untouched (confirmed by a user screenshot showing
    // SHEIN's own "أضف إلى عربة التسوق بنجاح" success bar).
    return /add to (bag|cart)/i.test(text) || /أضف.*(عربة|السلة|الحقيبة|التسوق)/.test(text);
  }

  function isAddToCartButton(el, event) {
    if (!el || el.nodeType !== 1 || !isAddToCartText(el)) return false;
    // Text on a large gallery/page wrapper must never be treated as a button.
    // Require the real compact interactive control and require the pointer to
    // actually be inside its painted rectangle.
    var tag = String(el.tagName || '').toUpperCase();
    var role = String(el.getAttribute && el.getAttribute('role') || '').toLowerCase();
    var interactive = tag === 'BUTTON' || tag === 'A' || tag === 'INPUT' ||
      role === 'button' || typeof el.onclick === 'function';
    if (!interactive) {
      try { interactive = window.getComputedStyle(el).cursor === 'pointer'; } catch (e) {}
    }
    if (!interactive || !el.getBoundingClientRect) return false;
    var rect = el.getBoundingClientRect();
    var vp = viewportSize();
    if (!rect || rect.width < 42 || rect.height < 24 || rect.height > 120 || rect.width > vp.width * 0.96) return false;
    if (event && typeof event.clientX === 'number' && typeof event.clientY === 'number') {
      if (event.clientX < rect.left - 2 || event.clientX > rect.right + 2 ||
          event.clientY < rect.top - 2 || event.clientY > rect.bottom + 2) return false;
    }
    return true;
  }

  // SHEIN's "quick add" popup (opened from a listing card, without ever
  // visiting the real product page) doesn't necessarily reuse the same
  // wording as the real product page's button - a user confirmed the exact
  // isAddToCartButton text match above still let one through. This is a
  // deliberately looser net: ANY short button-ish text while we're not on a
  // real product page that even loosely reads like a submit/confirm/add
  // action gets caught too, since the consequence of a false positive here
  // (blocking some unrelated short label) is far cheaper than letting a
  // real add-to-SHEIN's-cart action slip through.
  function isQuickAddSubmitButton(el) {
    if (looksLikeProductPage()) return false;
    var text = (el.textContent || '').trim();
    if (!text || text.length > 30) return false;
    return /^(إضافة|أضف|تأكيد|اضافة|add|confirm)\b/i.test(text) || /عربة|السلة|التسوق|الحقيبة|bag|cart/i.test(text);
  }

  function looksLikeCartUrl(href) {
    if (!href) return false;
    return /\\/(cart|bag|checkout|order-confirm|payment)(\\b|[/?#.])/i.test(href);
  }

  function isCartLink(el) {
    if (el.id && el.id.indexOf('otlobli') === 0) return false;
    if (el.tagName === 'A' && looksLikeCartUrl(el.getAttribute('href') || el.href || '')) return true;
    var cls = ' ' + (el.className || '') + ' ';
    return /\\s(cart-icon|header-cart|j-header-cart|shopping-bag|bag-icon)\\s/i.test(cls);
  }

  // Blocks wishlist/favorite anywhere it shows up - header, product page,
  // or inside SHEIN's own quick-add bottom sheet (the heart icon sitting
  // right next to its add-to-cart button). Matched on text/class/aria-label
  // rather than position, so it's caught no matter which of those places it
  // appears in, instead of needing a separate point-probe per location.
  function isWishlistButton(el) {
    if (el.id && el.id.indexOf('otlobli') === 0) return false;
    var text = (el.textContent || '').trim();
    if (text.length > 30) return false;
    var hint = (el.className || '') + ' ' + (el.getAttribute('aria-label') || '') + ' ' + text;
    return /wishlist|favorite|مفضل/i.test(hint);
  }

  var lastSafeUrl = location.href;

  function blockCartNavigation() {
    if (looksLikeCartUrl(location.href)) {
      if (history.length > 1) history.back();
      else location.href = lastSafeUrl;
      requestOpenOtlobliCart();
    } else {
      lastSafeUrl = location.href;
    }
  }

  function isIconOnlySheinControl(el) {
    if (!el) return false;
    var text = ((el.textContent || '') + '').replace(/\\s+/g, ' ').trim();
    if (text.length > 2) return false;
    if ((el.tagName || '').toUpperCase() === 'SVG') return true;
    return !!(el.querySelector && el.querySelector('svg, img'));
  }

  function isSheinAuthControl(el) {
    var node = el;
    var depth = 0;
    while (node && node !== document.body && node !== document.documentElement && depth < 8) {
      var tag = String(node.tagName || '').toUpperCase();
      var hint = ((node.className || '') + ' ' + (node.id || '') + ' ' +
        (node.getAttribute && node.getAttribute('aria-label') || '')).toLowerCase();
      if (tag === 'FORM' || /(?:^|[-_\\s])(login|signin|sign-in|auth|phone|email)(?:$|[-_\\s])/.test(hint)) return true;
      node = node.parentElement;
      depth++;
    }
    return false;
  }

  // Block only the actual icon-only menu control on the first tap. SHEIN also
  // uses menu/nav class names on visible category links; treating those textual
  // links as hamburger buttons made the home page feel like a static image.
  // Region/currency/language settings remain protected by their explicit text.
  function isProtectedSheinControl(el) {
    if (!el || !el.getAttribute) return false;
    if (el.id && el.id.indexOf('otlobli') === 0) return false;
    if (otlobliIsSheinTopCategoryEl(el)) return false;
    // Country inside sign-in is the phone prefix selector, not store settings.
    // It and the form's Continue button must remain native and interactive.
    if (isSheinAuthControl(el)) return false;
    var tag = el.tagName;
    var interactive = tag === 'BUTTON' || tag === 'A' || el.getAttribute('role') === 'button' ||
      window.getComputedStyle(el).cursor === 'pointer';
    if (!interactive) return false;
    var shortText = (el.textContent || '').trim();
    var hint = ((el.className || '') + ' ' + (el.getAttribute('aria-label') || '') + ' ' +
      (el.getAttribute('title') || '') + ' ' + (shortText.length <= 40 ? shortText : '')).toLowerCase();
    // Currency/language/region are blocked wherever they appear - including by
    // the visible drawer-item text ("تغيير العملة"/"تغيير اللغة"), so even if
    // the hamburger drawer does manage to open, every dangerous item inside it
    // is dead on tap.
    if (/currency|العملة|عملة|\\bregion\\b|country|البلد|الدولة|language|اللغة|\\blang\\b|لغة|\\bsetting|تغيير العملة|تغيير اللغة/.test(hint)) return true;
    var menuHint = /hamburger|nav-?toggle|side-?menu|drawer|menu-?(btn|button|icon|toggle|bar)|\\bmenu\\b/.test(hint);
    if (menuHint && isIconOnlySheinControl(el)) {
      var rect = el.getBoundingClientRect();
      // Band widened to top<=220 because SHEIN's home page can push its header
      // down behind a top promo/app-install banner, putting the hamburger well
      // below the old top<=140 cutoff - which is exactly why blocking used to
      // only "wake up" after navigating to a product and back (that banner is
      // gone on the second visit).
      if (rect.top >= -10 && rect.top <= 220 && rect.width > 0 && rect.width <= 90 && rect.height > 0 && rect.height <= 90) return true;
    }
    return false;
  }

  document.addEventListener('click', function (event) {
    // ⚠️ تحذير دائم — ممنوع حذف هذا الحارس أو تغييره لأي سبب (خلل حقيقي أضاف
    // منتجات لسلة المستخدم بلا علمه، مؤكَّد 2026-07-03):
    // كل الفحوص أدناه (isProtectedSheinControl/isCartLink/isWishlistButton/
    // isQuickAddSubmitButton/isAddToCartButton) مصمّمة حصراً لاعتراض أزرار
    // شي إن الأصلية - وaddToCartFlow() هنا تُستدعى مباشرة بلا المرور بحارس
    // تيمو الصارم (temuFinalizeAdd، انتظار 5 ثوانٍ، تحقق اللون/المقاس). بلا
    // "if (!IS_SHEIN) return;" أدناه، أي نقرة على تيمو تُصادف نصاً يطابق
    // "أضف...السلة" (حتى خلف طبقة معاينة صورة كاملة الشاشة) كانت تُضيف
    // المنتج تلقائياً بلا أي تحقق. إن احتجت تعديل هذا المعالج مستقبلاً، أبقِ
    // هذا الحارس أول سطر بالضبط - لا تُدمِج منطق شي إن وتيمو هنا مطلقاً.
    if (!IS_SHEIN) return;
    var el = event.target;
    // A full-screen product gallery may be painted above a still-hit-testable
    // PDP action on older WKWebView. While that exact viewer is open, block
    // only dangerous underlying cart/wishlist controls and otherwise leave
    // the gallery's own tap/swipe/close behavior untouched.
    if (looksLikeProductPage() && sheinImageViewerOpen(true)) {
      var viewerNode = el;
      for (var viewerDepth = 0; viewerNode && viewerDepth < 7; viewerDepth++, viewerNode = viewerNode.parentElement) {
        if (viewerNode.id && viewerNode.id.indexOf('otlobli') === 0) {
          var viewerOtlobliId = viewerNode.id;
          if (viewerOtlobliId === 'otlobli-nav' || viewerOtlobliId.indexOf('otlobli-nav-tab-') === 0 ||
              viewerOtlobliId === 'otlobli-back-btn') return;
          event.preventDefault();
          if (event.stopImmediatePropagation) event.stopImmediatePropagation();
          event.stopPropagation();
          return;
        }
        if (isAddToCartButton(viewerNode, event) || isQuickAddSubmitButton(viewerNode) ||
            isCartLink(viewerNode) || isWishlistButton(viewerNode)) {
          event.preventDefault();
          if (event.stopImmediatePropagation) event.stopImmediatePropagation();
          event.stopPropagation();
          return;
        }
      }
      return;
    }
    var depth = 0;
    while (el && depth < 6) {
      if (el.id && el.id.indexOf('otlobli') === 0) return;
      // The customer never needs SHEIN's country drawer: Otlobli owns the
      // fixed Saudi shipping context. Only a narrowly marked automatic click
      // may reach SHEIN's native handler; ordinary taps are swallowed silently.
      if (isSheinShippingRegionControl(el)) {
        var shippingNode = el;
        var shippingDepth = 0;
        var automatedShippingAction = false;
        while (shippingNode && shippingDepth < 8) {
          if (shippingNode.getAttribute && shippingNode.getAttribute('data-otlobli-shein-shipping-action') === '1') {
            automatedShippingAction = true;
            break;
          }
          shippingNode = shippingNode.parentElement;
          shippingDepth++;
        }
        if (automatedShippingAction) return;
        event.preventDefault();
        if (event.stopImmediatePropagation) event.stopImmediatePropagation();
        event.stopPropagation();
        return;
      }
      if (el.getAttribute && el.getAttribute('data-otlobli-blocked') === '1') {
        event.preventDefault();
        event.stopPropagation();
        showMessage(null, 'هذا الخيار غير متوفر حالياً');
        return;
      }
      if (isProtectedSheinControl(el)) {
        event.preventDefault();
        event.stopPropagation();
        showMessage(null, 'هذا الخيار غير متوفر حالياً');
        return;
      }
      if (isCartLink(el)) {
        event.preventDefault();
        event.stopPropagation();
        requestOpenOtlobliCart();
        return;
      }
      if (isWishlistButton(el)) {
        event.preventDefault();
        event.stopPropagation();
        showMessage(null, 'هذا الخيار غير متوفر حالياً');
        return;
      }
      if (isQuickAddSubmitButton(el)) {
        // Silently swallow - the user asked that tapping a listing-card cart /
        // quick-add do nothing at all (no message). These buttons are also
        // actively hidden by hideListingCardAddButtons, so this is just a
        // belt-and-suspenders fallback for any that slip through.
        event.preventDefault();
        event.stopPropagation();
        return;
      }
      if (isAddToCartButton(el, event)) {
        // Block SHEIN's own click handler from ever firing - otherwise it adds
        // the item to SHEIN's real bag and shows its own "added to bag" toast
        // alongside ours, which is exactly the native-cart usage we're trying
        // to prevent entirely.
        event.preventDefault();
        event.stopPropagation();
        if (!looksLikeProductPage()) {
          // Listing-card "quick add" (not the real product page). Capture from
          // its stripped-down popup is unreliable, so we never run it - and per
          // the user's request we now do this silently, with no message.
          return;
        }
        var colorState = getColorState();
        var sizeState = getSizeState();
        addToCartFlow(colorState, sizeState);
        return;
      }
      el = el.parentElement;
      depth++;
    }
  }, true);

  // Hide every SHEIN header icon except search (wishlist heart, inbox, hamburger
  // menu, etc.) - same point-probing + "walk up to the nearest small clickable
  // element" pattern as hideStrayFixedBottomBars below, deliberately avoiding a
  // blind document-wide querySelectorAll('a,button') like the earlier cart-icon
  // lockout used: that one matched an oversized wrapping element once and tore
  // a transparent hole in SHEIN's header. Capping at icon-sized elements (and
  // skipping anything that contains/looks like the search input) keeps this
  // safe even if SHEIN's markup doesn't match our assumptions.
  // Point-probing (hideExtraHeaderIcons below) can miss a small icon
  // outright if it just happens to sit between two sample points - a user
  // reported the wishlist heart and hamburger menu sometimes taking
  // minutes to disappear, purely down to probe-grid luck. This is a direct,
  // grid-independent pass: query for the hamburger/wishlist by name instead
  // of by position, so it gets caught on literally the first tick
  // regardless of exactly where it sits. The hamburger is a real risk
  // beyond clutter too - it can lead to SHEIN's own account/region/currency
  // settings, and a currency switch there would silently break price
  // capture (which assumes USD).
  function hideKnownHeaderIconsByHint() {
    var candidates = document.querySelectorAll(
      '[class*="menu" i], [aria-label*="menu" i], [class*="hamburger" i], [class*="nav-toggle" i], ' +
      '[class*="wishlist" i], [class*="favorite" i], [aria-label*="favorite" i], [aria-label*="wishlist" i]'
    );
    for (var i = 0; i < candidates.length; i++) {
      var el = candidates[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (otlobliIsSheinTopCategoryEl(el)) continue;
      if (!isIconOnlySheinControl(el)) continue;
      var rect = el.getBoundingClientRect();
      if (rect.top < -10 || rect.top > 120) continue;
      if (rect.width <= 0 || rect.width > 64 || rect.height <= 0 || rect.height > 64) continue;
      el.setAttribute('data-otlobli-blocked', '1');
      el.style.setProperty('visibility', 'hidden', 'important');
      el.style.setProperty('pointer-events', 'none', 'important');
    }
  }

  // زر "البحث بالصورة" (الكاميرا) يجلس داخل شريط البحث بجانب حقل الإدخال،
  // وليس له اسم/تصنيف يحوي كلمات البحث، فكان يُحجب ويظهر كمربع أسود فارغ.
  // نعتبر أي أيقونة يحتوي أحد آبائها القريبين (حتى 3 مستويات) حقلَ إدخال
  // جزءاً من شريط البحث فلا نحجبها - هكذا تبقى الكاميرا ظاهرة دون الاعتماد
  // على اسمها، وتبقى بقية الأيقونات (خارج شريط البحث) محجوبة كما هي.
  function otlobliNearSearchInput(node) {
    var up = node;
    var hops = 0;
    while (up && hops < 4) {
      // حقل بحث حقيقي قريب (قد لا يكون input عادياً في صفحة البحث)
      if (up.querySelector && up.querySelector('input, textarea, [contenteditable="true"]')) return true;
      // أو حاوية صنفها يدل على شريط البحث - الكاميرا تجلس داخلها
      var c = (up.className && up.className.baseVal !== undefined) ? up.className.baseVal : (up.className || '');
      if (typeof c === 'string' && /search|بحث/i.test(c)) return true;
      up = up.parentElement;
      hops++;
    }
    return false;
  }
  // يجمع كل النصوص/سمات التعريف الدالة من عنصر وكل أبنائه (حتى 15 عنصراً):
  // aria-label، class، href/xlink:href، data-testid/id، ونص عنصر <title>
  // داخل svg. أيقونات تيمو غالباً SVG بلا أي تسمية على الزر الخارجي نفسه —
  // فالفحص السطحي (الزر وحده) يفوّت التسمية الحقيقية المدفونة في عنصر ابن.
  function otlobliCollectIdentityHints(el) {
    var scan = [el];
    if (el.querySelectorAll) {
      var kids = el.querySelectorAll('*');
      for (var i = 0; i < kids.length && i < 15; i++) scan.push(kids[i]);
    }
    var hints = [];
    for (var s = 0; s < scan.length; s++) {
      var node = scan[s];
      if (node.getAttribute) {
        hints.push((node.getAttribute('aria-label') || '').toLowerCase());
        hints.push((node.getAttribute('class') || '').toLowerCase());
        hints.push((node.getAttribute('href') || node.getAttribute('xlink:href') || '').toLowerCase());
        hints.push((node.getAttribute('data-testid') || node.getAttribute('id') || '').toLowerCase());
      }
      var tag = (node.tagName || '').toLowerCase();
      if (tag === 'title') hints.push((node.textContent || '').toLowerCase());
    }
    return hints.join(' ');
  }
  // زر "فتح صفحة البحث" المستقل — نفحص الزر وكل أبنائه (لا الزر وحده).
  function otlobliLooksLikeSearchTrigger(el) {
    return /search|بحث/i.test(otlobliCollectIdentityHints(el));
  }
  // أيقونات معروفة نريد حجبها فعلاً (سلة/حساب/قائمة/مفضلة/رسائل) — نفس
  // أسلوب فحص الأبناء المستخدم للبحث. الحجب الآن **إيجابي**: لا نحجب أي
  // أيقونة إلا لو تطابقت صراحة مع إحدى هذه الكلمات، بدل حجب كل شيء
  // والاستثناء بالتخمين (كان يُفوّت البحث لأنه أيضاً بلا تسمية أحياناً).
  var OTLOBLI_KNOWN_DISTRACTION = /cart|bag|basket|shopping|account|profile\b|\buser\b|\bme\b|menu|hamburger|categor|\bnav\b|wishlist|favorite|favourite|\bheart\b|message|inbox|notification|\bchat\b|سلة|السلة|عربة|حساب|حسابي|بروفايل|قائمة|التصنيفات|الأقسام|المفضلة|مفضلة|رسائل|الرسائل|إشعارات|اشعارات/i;
  function otlobliLooksLikeKnownDistraction(el) {
    return OTLOBLI_KNOWN_DISTRACTION.test(otlobliCollectIdentityHints(el));
  }

  function otlobliCompactText(text) {
    return ((text || '') + '').replace(/\\s+/g, ' ').trim();
  }

  function otlobliIsSheinTopCategoryText(text) {
    var t = otlobliCompactText(text);
    return /^(?:\u0643\u0644|\u0646\u0633\u0627\u0621|\u0631\u062c\u0627\u0644|\u0623\u0637\u0641\u0627\u0644|\u0627\u0637\u0641\u0627\u0644|\u0623\u062d\u062c\u0627\u0645 \u0643\u0628\u064a\u0631\u0629|\u0627\u062d\u062c\u0627\u0645 \u0643\u0628\u064a\u0631\u0629|\u0645\u0642\u0627\u0633\u0627\u062a \u0643\u0628\u064a\u0631\u0629|all|women|men|kids|children|curve|plus size)$/i.test(t);
  }

  function otlobliIsSheinTopCategoryEl(el) {
    if (!IS_SHEIN || !el) return false;
    var text = otlobliCompactText(el.textContent || '');
    if (!text || text.length > 32 || !otlobliIsSheinTopCategoryText(text)) return false;
    var r = el.getBoundingClientRect && el.getBoundingClientRect();
    if (!r) return true;
    return r.top >= -30 && r.top <= 260;
  }

  function hideExtraHeaderIcons() {
    var vp = viewportSize();
    // Wider probe band than just the first ~50px - SHEIN's header height
    // varies by page (the home page's is noticeably taller than a product
    // page's), and a user screenshot showed the wishlist heart and hamburger
    // menu still visible/tappable on the home page because the old probe
    // rows never reached that low.
    var probeYs = [20, 36, 52, 68, 84, 100];
    var steps = 10;
    for (var r = 0; r < probeYs.length; r++) {
      for (var s = 0; s <= steps; s++) {
        var x = Math.round((vp.width * s) / steps);
        var el = document.elementFromPoint(x, probeYs[r]);
        var depth = 0;
        while (el && el !== document.body && el !== document.documentElement && depth < 6) {
          if (el.id && el.id.indexOf('otlobli') === 0) break;
          if (otlobliIsSheinTopCategoryEl(el)) break;
          var elRect = el.getBoundingClientRect();
          var elIconSized = elRect.width > 0 && elRect.width < 64 && elRect.height > 0 && elRect.height < 64;
          // Not every clickable icon is a <button>/<a>/role="button" - sites
          // commonly wire a click handler straight onto a styled <div>/<span>
          // (SHEIN's own native-style "share" icon does exactly this). A
          // pointer cursor is a reliable cross-markup signal that an element
          // is meant to be tapped, so treat that as clickable too. As a last
          // resort, an icon-sized element that simply contains an svg/img
          // graphic (and nothing else interactive matched first) is almost
          // always meant to be tapped even with no clickability signal at all.
          var isClickable = el.tagName === 'BUTTON' || el.tagName === 'A' || el.getAttribute('role') === 'button' ||
            window.getComputedStyle(el).cursor === 'pointer' ||
            (elIconSized && (el.querySelector('svg') || el.querySelector('img')));
          if (isClickable) {
            var hasInput = !!el.querySelector('input') || otlobliNearSearchInput(el);
            var hint = ((el.className || '') + ' ' + (el.getAttribute('aria-label') || '') + ' ' + (el.textContent || '')).toLowerCase();
            var isSearchish = hasInput || /search|بحث|camera|كاميرا|image|صورة|بالصورة|visual|photo|عدسة|lens/.test(hint);
            if (elIconSized && isIconOnlySheinControl(el) && !isSearchish && !otlobliIsSheinTopCategoryEl(el)) {
              el.setAttribute('data-otlobli-blocked', '1');
              el.style.setProperty('visibility', 'hidden', 'important');
              el.style.setProperty('pointer-events', 'none', 'important');
            }
            break;
          }
          el = el.parentElement;
          depth++;
        }
      }
    }
  }

  // Visually hide any SHEIN cart icon/button wherever it shows up - header,
  // or the sticky "add to bag" action bar at the bottom of product pages.
  // Same point-probe + icon-size-cap safety pattern as hideExtraHeaderIcons:
  // walk up from a probed point only until the nearest clickable element,
  // and only touch it if it's actually icon-sized, never a big wrapping
  // container (that size cap is what keeps this safe, unlike the original
  // blind querySelectorAll('a,button') cart lockout that once tore a hole in
  // SHEIN's header).
  function hideSheinCartIcons() {
    var vp = viewportSize();
    var points = [];
    var steps = 10;
    for (var s = 0; s <= steps; s++) {
      points.push([Math.round((vp.width * s) / steps), 20]);
      points.push([Math.round((vp.width * s) / steps), 52]);
      points.push([Math.round((vp.width * s) / steps), vp.height - 28]);
    }
    for (var p = 0; p < points.length; p++) {
      var el = document.elementFromPoint(points[p][0], points[p][1]);
      var depth = 0;
      while (el && el !== document.body && el !== document.documentElement && depth < 6) {
        if (el.id && el.id.indexOf('otlobli') === 0) break;
        var isClickable = el.tagName === 'BUTTON' || el.tagName === 'A' || el.getAttribute('role') === 'button';
        if (isClickable) {
          if (isCartLink(el)) {
            var rect = el.getBoundingClientRect();
            if (rect.width > 0 && rect.width < 80 && rect.height > 0 && rect.height < 80) {
              el.setAttribute('data-otlobli-blocked', '1');
              el.style.setProperty('visibility', 'hidden', 'important');
              el.style.setProperty('pointer-events', 'none', 'important');
            }
          }
          break;
        }
        el = el.parentElement;
        depth++;
      }
    }
  }

  // Finds SHEIN's top header bar by markup + geometry instead of a fixed pixel
  // band. This is the fix for "blocking only works after I open a product and
  // come back": on the first home load SHEIN floats a promo / app-install
  // banner above the header, pushing the real header (and its hamburger) down
  // past the old fixed probe rows, so nothing matched until a second visit when
  // the banner was gone. Anchoring on the header element itself makes the icon
  // sweep work no matter how far down the banner shoves it.
  function findTopHeaderEl() {
    var vp = viewportSize();
    var best = null;
    var bestTop = 99999;
    var nodes = document.querySelectorAll(
      'header, [class*="header" i], [class*="navbar" i], [class*="nav-bar" i], ' +
      '[class*="topbar" i], [class*="top-bar" i], [class*="head-bar" i]'
    );
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      var st = window.getComputedStyle(el);
      if (st.position !== 'fixed' && st.position !== 'sticky' && st.position !== 'absolute' && st.position !== 'relative') continue;
      var r = el.getBoundingClientRect();
      if (r.width < vp.width * 0.6) continue;
      if (r.height <= 0 || r.height > 160) continue;
      if (r.top < -60 || r.top > 240) continue;
      if (r.top < bestTop) { bestTop = r.top; best = el; }
    }
    return best;
  }

  // Hides every small clickable icon inside SHEIN's header (hamburger, cart,
  // wishlist, inbox, etc.) EXCEPT the search box, anchored to the header
  // element so it works regardless of the header's vertical offset. The
  // hamburger is the real prize here: it opens SHEIN's region/currency/language
  // drawer, and a currency switch silently breaks our USD price capture.
  function hideSheinHeaderControls() {
    var header = findTopHeaderEl();
    if (!header) return;
    var els = header.querySelectorAll('button, a, [role="button"], [class*="icon" i], svg');
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.tagName === 'SVG' || el.tagName === 'svg') {
        // Promote a bare clickable <svg> icon to its nearest tappable wrapper.
        var up = el.parentElement;
        var hops = 0;
        while (up && up !== header && hops < 3) {
          var ut = up.tagName;
          if (ut === 'BUTTON' || ut === 'A' || up.getAttribute('role') === 'button' ||
            window.getComputedStyle(up).cursor === 'pointer') { el = up; break; }
          up = up.parentElement; hops++;
        }
      }
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (otlobliIsSheinTopCategoryEl(el)) continue;
      if (!isIconOnlySheinControl(el)) continue;
      if (el.querySelector && el.querySelector('input')) continue; // search field wrapper
      if (otlobliNearSearchInput(el)) continue; // أيقونة داخل شريط البحث (الكاميرا)
      var hint = ((el.className || '') + ' ' + (el.getAttribute && el.getAttribute('aria-label') || '') + ' ' + (el.textContent || '')).toLowerCase();
      if (/search|بحث|camera|كاميرا|image|صورة|بالصورة|visual|photo|عدسة|lens/.test(hint)) continue;
      var rect = el.getBoundingClientRect();
      if (rect.width <= 0 || rect.width > 72 || rect.height <= 0 || rect.height > 72) continue;
      el.setAttribute('data-otlobli-blocked', '1');
      el.style.setProperty('visibility', 'hidden', 'important');
      el.style.setProperty('pointer-events', 'none', 'important');
    }
  }

  // Deletes SHEIN's per-listing-card "quick add to cart" controls - both the
  // little cart icon sitting on each product thumbnail and the quick-add button
  // under the card - so a tap does nothing (the user explicitly asked for these
  // to be removed entirely, not redirected). Matched on SHEIN's add-bag / cart
  // class & aria hints and capped at icon/pill size so it never touches the
  // full-width add bar on a real product page (which the user reaches through
  // otlobli's own button instead).
  function hideListingCardAddButtons() {
    var nodes = document.querySelectorAll(
      '[class*="addbag" i], [class*="add-bag" i], [class*="addtobag" i], [class*="add-to-bag" i], ' +
      '[class*="addcart" i], [class*="add-cart" i], [class*="addtocart" i], [class*="add-to-cart" i], ' +
      '[class*="quickadd" i], [class*="quick-add" i], [class*="quick-cart" i], ' +
      '[class*="cart-icon" i], [class*="bag-icon" i], [class*="addboard" i], ' +
      '[aria-label*="add to" i], [aria-label*="عربة" i], [aria-label*="السلة" i], [aria-label*="أضف" i]'
    );
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      var rect = el.getBoundingClientRect();
      if (rect.width <= 0 || rect.width > 96 || rect.height <= 0 || rect.height > 96) continue;
      el.setAttribute('data-otlobli-blocked', '1');
      el.style.setProperty('visibility', 'hidden', 'important');
      el.style.setProperty('pointer-events', 'none', 'important');
    }
  }

  // Now that the webview is full-screen (see browseShein in App.tsx),
  // SHEIN's own page can render its own persistent bottom tab bar AND its
  // sticky product-page action bar (wishlist + add-to-cart), both of which
  // used to be clipped off-screen in the old height-constrained webview -
  // a user screenshot showed the action bar peeking out from behind
  // otlobli's own floating buttons. Find and remove any of these outright
  // instead of just hoping otlobli's own overlays paint above them.
  var __otlobliBottomNavDebugCount = 0;
  var __otlobliBottomNavDeepScanAt = 0;

  function getElementText(el) {
    try { return (el.innerText || el.textContent || '').replace(/\\s+/g, ' ').trim(); } catch (e) {}
    return '';
  }

  function sheinBottomTabScore(text) {
    if (!text) return 0;
    var score = 0;
    var patterns = [
      /أنا|انا|me|account|profile/i,
      /حقيبة التسوق|السلة|cart|bag|basket/i,
      /ترندات|trends|trending/i,
      /الفئات|الأقسام|الاقسام|categor/i,
      /متجر|shop|store/i,
    ];
    for (var i = 0; i < patterns.length; i++) {
      if (patterns[i].test(text)) score++;
    }
    return score;
  }

  function bottomBarGeometryOk(rect, vp) {
    if (!rect || !vp) return false;
    if (rect.width < vp.width * 0.55) return false;
    if (rect.height <= 0 || rect.height > 190) return false;
    return rect.bottom >= vp.height - 28 || rect.top >= vp.height - 180;
  }

  function hideStoreBottomElement(el, reason, score, rect) {
    if (!el || el === document.body || el === document.documentElement) return false;
    if (el.id && el.id.indexOf('otlobli') === 0) return false;
    try {
      if (el.querySelector && el.querySelector('#otlobli-nav')) return false;
    } catch (e) {}
    el.style.setProperty('display', 'none', 'important');
    el.style.setProperty('visibility', 'hidden', 'important');
    el.style.setProperty('pointer-events', 'none', 'important');
    el.setAttribute('data-otlobli-hidden-store-bottom', reason || 'bottom-nav');
    if (__otlobliBottomNavDebugCount < 4) {
      __otlobliBottomNavDebugCount++;
      try {
        var payload = {
          type: 'bottomNavHidden',
          reason: reason || '',
          score: score || 0,
          tag: el.tagName || '',
          id: el.id || '',
          cls: (el.className && typeof el.className === 'string') ? el.className.slice(0, 120) : '',
          text: getElementText(el).slice(0, 180),
          top: rect ? Math.round(rect.top) : 0,
          bottom: rect ? Math.round(rect.bottom) : 0,
          height: rect ? Math.round(rect.height) : 0,
        };
        if (window.console && console.log) console.log('[otlobli] hid store bottom nav ' + JSON.stringify(payload));
        if (window.mobileApp && window.mobileApp.postMessage) {
          window.mobileApp.postMessage({ detail: { type: 'debugBottomNav', payload: payload } });
        }
      } catch (e2) {}
    }
    return true;
  }

  function findBottomNavRootFrom(el, vp) {
    var cur = el;
    var depth = 0;
    var best = null;
    while (cur && cur !== document.body && cur !== document.documentElement && depth < 10) {
      if (cur.id && cur.id.indexOf('otlobli') === 0) break;
      var rect = cur.getBoundingClientRect();
      if (bottomBarGeometryOk(rect, vp)) {
        var text = getElementText(cur);
        var score = sheinBottomTabScore(text);
        var controls = 0;
        try { controls = cur.querySelectorAll('a,button,[role="button"],[role="tab"],svg,img').length; } catch (e) {}
        if (score >= 2) {
          best = { el: cur, rect: rect, score: score };
        }
      }
      cur = cur.parentElement;
      depth++;
    }
    return best;
  }

  function looksLikeNativeStoreBottomNav(el, rect, vp) {
    if (!el || !rect || rect.width < vp.width * 0.55) return false;
    if (rect.height <= 0 || rect.height > 170) return false;
    if (rect.top < vp.height - 230 && rect.bottom < vp.height - 18) return false;
    var text = getElementText(el);
    if (sheinBottomTabScore(text) >= 2) return true;
    var buttonCount = 0;
    try { buttonCount = el.querySelectorAll('a,button,[role="button"],[role="tab"],svg,img').length; } catch (e) {}
    var keywordHits = 0;
    var keywords = [
      /home|الرئيسية|الرئيسيه/i,
      /category|categories|الفئات|الأقسام|الاقسام/i,
      /cart|bag|basket|السلة|الحقيبة|العربة|عربة/i,
      /me|account|profile|حسابي|أنا|انا/i,
      /sale|deals|offers|العروض/i,
    ];
    for (var k = 0; k < keywords.length; k++) {
      if (keywords[k].test(text)) keywordHits++;
    }
    return keywordHits >= 2;
  }

  function hideForeignBottomNav() {
    var vp = viewportSize();
    var candidates;
    try {
      candidates = document.querySelectorAll(
        'nav, footer, [class*="tab-bar" i], [class*="tabbar" i], [class*="bottom-nav" i], ' +
        '[class*="footer-nav" i], [class*="nav-bar" i], [class*="navbar" i], ' +
        '[role="navigation"], [role="tablist"]'
      );
    } catch (e) {
      candidates = document.querySelectorAll('nav, footer, [role="navigation"], [role="tablist"], div, section, ul');
    }
    for (var i = 0; i < candidates.length; i++) {
      var el = candidates[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      var style = window.getComputedStyle(el);
      var rect = el.getBoundingClientRect();
      var looksLikeBottomNav = looksLikeNativeStoreBottomNav(el, rect, vp);
      var positioned = style.position === 'fixed' || style.position === 'sticky' || style.position === 'absolute';
      if (!looksLikeBottomNav) continue;
      if (!positioned && rect.bottom < vp.height - 18) continue;
      if (rect.width < vp.width * 0.5) continue;
      if (rect.height <= 0 || rect.height > 190) continue;
      hideStoreBottomElement(el, 'selector-bottom-nav', sheinBottomTabScore(getElementText(el)), rect);
    }

    var probeXs = [Math.round(vp.width * 0.12), Math.round(vp.width * 0.32), Math.round(vp.width * 0.5), Math.round(vp.width * 0.68), Math.round(vp.width * 0.88)];
    var probeYs = [Math.round(vp.height - 18), Math.round(vp.height - 46), Math.round(vp.height - 78), Math.round(vp.height - 110)];
    for (var py = 0; py < probeYs.length; py++) {
      for (var px = 0; px < probeXs.length; px++) {
        var hit = document.elementFromPoint(probeXs[px], probeYs[py]);
        var match = findBottomNavRootFrom(hit, vp);
        if (match) hideStoreBottomElement(match.el, 'point-probe-bottom-tabs', match.score, match.rect);
      }
    }

    var now = Date.now();
    if (now - __otlobliBottomNavDeepScanAt > 900) {
      __otlobliBottomNavDeepScanAt = now;
      var all;
      try { all = document.querySelectorAll('nav, footer, [role="navigation"], [role="tablist"], div, section, ul'); } catch (e2) { all = []; }
      for (var a = 0; a < all.length; a++) {
        var node = all[a];
        if (!node || (node.id && node.id.indexOf('otlobli') === 0)) continue;
        var nodeRect = node.getBoundingClientRect();
        if (!bottomBarGeometryOk(nodeRect, vp)) continue;
        var nodeScore = sheinBottomTabScore(getElementText(node));
        if (nodeScore >= 3) hideStoreBottomElement(node, 'deep-scan-bottom-tabs', nodeScore, nodeRect);
      }
    }
  }

  // otlobli: robust, tag-agnostic auto-accept. SHEIN renders its consent
  // buttons as styled <div>s (not <button>/<a>/<input>), so the label-scoped
  // matcher below never finds them and never fires. This scans ALL small
  // elements by their own text, strips bidi control marks, and clicks the
  // accept control (never reject/manage) whenever a cookie consent is on
  // screen. It runs from the same 300ms tick. The human-check ("أنا إنسان")
  // never matches acceptRe, so it is left untouched.
  var __otlobliForceAcceptTries = 0;
  function otlobliForceAcceptCookies() {
    if (!document.body) return;
    if (__otlobliForceAcceptTries >= 10) return;
    var bodyText = document.body.innerText || '';
    if (!/ملفات تعريف الارتباط|cookies?/i.test(bodyText)) return;
    function cleanLabel(s) {
      return String(s || '').replace(/[\\u200e\\u200f\\u061c\\u202a-\\u202e]/g, '').replace(/\\s+/g, ' ').trim();
    }
    var acceptRe = /^(?:قبول(?: الكل)?|accept(?: all)?|allow(?: all)?|agree(?: to all)?|موافق)$/i;
    var badRe = /رفض|reject|decline|deny|إدارة|manage|preferences|settings|تفضيل/i;
    var nodes = document.querySelectorAll('button,[role="button"],a,input[type="button"],input[type="submit"],div,span,li,p');
    var accept = null;
    for (var fi = 0; fi < nodes.length; fi++) {
      var fel = nodes[fi];
      if (fel.children && fel.children.length > 4) continue;
      var ft = cleanLabel(fel.textContent || fel.value || '');
      if (!ft || ft.length > 20) continue;
      if (badRe.test(ft)) continue;
      if (!acceptRe.test(ft)) continue;
      var fr = fel.getBoundingClientRect();
      if (fr.width <= 0 || fr.height <= 0) continue;
      accept = fel;
    }
    if (!accept) return;
    __otlobliForceAcceptTries++;
    try { accept.click(); } catch (e1) {}
    try {
      var types = ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'];
      for (var k = 0; k < types.length; k++) {
        accept.dispatchEvent(new MouseEvent(types[k], { bubbles: true, cancelable: true, view: window }));
      }
    } catch (e2) {}
  }

  // otlobli: auto-accept SHEIN's cookie consent on the customer's behalf. The
  // customer must never be able to pick "reject all" and must never have to hunt
  // for the accept button (it sits behind Otlobli's fixed nav on tall devices),
  // so the exact accept action is clicked as soon as it is confidently found.
  // As a fallback, if the click does not dismiss the banner, its action row is
  // still raised above the fixed nav so it stays reachable.
  var __otlobliCookieScanAt = 0;
  var __otlobliCookieAcceptClicksShein = 0;
  function protectSheinCookieConsentAction() {
    if (!IS_SHEIN || !document.body) return;
    var scanNow = Date.now();
    if (scanNow - __otlobliCookieScanAt < 650) return;
    __otlobliCookieScanAt = scanNow;
    var controls = document.querySelectorAll('button, [role="button"], a, input[type="button"], input[type="submit"]');
    var acceptPattern = /^(?:accept(?: all)?|allow(?: all)?|agree(?: to all)?|\\u0642\\u0628\\u0648\\u0644(?: \\u0627\\u0644\\u0643\\u0644)?|\\u0627\\u0642\\u0628\\u0644(?: \\u0627\\u0644\\u0643\\u0644)?|\\u0627\\u0644\\u0633\\u0645\\u0627\\u062d (?:\\u0644\\u0644\\u0643\\u0644|\\u0644\\u0644\\u062c\\u0645\\u064a\\u0639)|\\u0645\\u0648\\u0627\\u0641\\u0642)$/i;
    var rejectPattern = /^(?:reject all|decline all|deny all|\\u0631\\u0641\\u0636 \\u0627\\u0644\\u0643\\u0644|\\u0639\\u062f\\u0645 \\u0627\\u0644\\u0642\\u0628\\u0648\\u0644)$/i;
    var cookiePattern = /cookies?|\\u0645\\u0644\\u0641\\u0627\\u062a \\u062a\\u0639\\u0631\\u064a\\u0641 \\u0627\\u0644\\u0627\\u0631\\u062a\\u0628\\u0627\\u0637|\\u0627\\u0644\\u062a\\u0642\\u0646\\u064a\\u0627\\u062a \\u0627\\u0644\\u0645\\u0645\\u0627\\u062b\\u0644\\u0629/i;
    var vp = viewportSize();
    for (var i = 0; i < controls.length; i++) {
      var button = controls[i];
      var label = String(button.innerText || button.textContent || button.value || button.getAttribute('aria-label') || '').replace(/\\s+/g, ' ').trim();
      if (!acceptPattern.test(label)) continue;
      var scope = button;
      var cookieScope = null;
      for (var hop = 0; scope && hop < 7; hop++, scope = scope.parentElement) {
        var text = String(scope.innerText || scope.textContent || '').replace(/\\s+/g, ' ').trim();
        if (text.length < 2400 && cookiePattern.test(text)) {
          cookieScope = scope;
          break;
        }
      }
      if (!cookieScope) continue;
      // otlobli: auto-accept (see the note above this function). Click the
      // confidently-matched accept button so the banner dismisses itself before
      // the customer can pick "reject all"; bounded attempts, then fall through
      // to the raise fallback below. The human-check never matches acceptPattern.
      if (__otlobliCookieAcceptClicksShein < 4) {
        var acceptRectS = button.getBoundingClientRect();
        if (acceptRectS.width > 0 && acceptRectS.height > 0) {
          __otlobliCookieAcceptClicksShein++;
          try { button.click(); } catch (eAcceptS) {}
        }
      }
      var scopedControls = cookieScope.querySelectorAll('button, [role="button"], a, input[type="button"], input[type="submit"]');
      var reject = null;
      for (var ri = 0; ri < scopedControls.length; ri++) {
        var rejectLabel = String(scopedControls[ri].innerText || scopedControls[ri].textContent || scopedControls[ri].value || scopedControls[ri].getAttribute('aria-label') || '').replace(/\\s+/g, ' ').trim();
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
      var navTop = navRect && navRect.top > 0 ? navRect.top : vp.height - 86;
      if (actionRect.bottom < navTop - 8) continue;
      if (actionRoot.getAttribute('data-otlobli-cookie-raised') === '1') continue;
      var style = window.getComputedStyle(actionRoot);
      if (style.position === 'static') actionRoot.style.setProperty('position', 'relative', 'important');
      actionRoot.style.setProperty('bottom', Math.max(74, Math.ceil(actionRect.bottom - navTop + 12)) + 'px', 'important');
      actionRoot.style.setProperty('z-index', '2147483646', 'important');
      actionRoot.setAttribute('data-otlobli-cookie-raised', '1');
    }
  }

  // Hide only SHEIN's two confirmed first-order signup surfaces: the compact
  // 15%-off strip, or the newsletter panel with a real email field. These
  // compound checks prevent product discounts and the real auth form from
  // matching this rule.
  var __otlobliSignupLastScanAt = 0;
  function hideSheinSignupDiscountBanner() {
    if (!IS_SHEIN || !document.body || !document.elementsFromPoint) return;
    var scanNow = Date.now();
    if (scanNow - __otlobliSignupLastScanAt < 700) return;
    __otlobliSignupLastScanAt = scanNow;
    var vp = viewportSize();
    var nav = document.getElementById('otlobli-nav');
    var navRect = nav && nav.getBoundingClientRect ? nav.getBoundingClientRect() : null;
    var navTop = navRect && navRect.top > 0 ? navRect.top : vp.height - 90;
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
        var text = getElementText(current).replace(/[\\u064B-\\u065F\\u0670]/g, '');
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
          var offerPlacement = exactOfferStrip && rect.width >= vp.width * 0.62 &&
            rect.height >= 32 && rect.height <= 180 && rect.top >= Math.max(0, navTop - 220) &&
            touchesNav && (positioned || Math.abs(rect.bottom - navTop) <= 48);
          var newsletterPlacement = exactNewsletterPanel && rect.width >= vp.width * 0.62 &&
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

    var xs = [Math.round(vp.width * 0.12), Math.round(vp.width * 0.5), Math.round(vp.width * 0.88)];
    var ys = [Math.max(1, Math.round(navTop - 10)), Math.max(1, Math.round(navTop - 54))];
    for (var yi = 0; yi < ys.length; yi++) {
      for (var xi = 0; xi < xs.length; xi++) {
        var stack = document.elementsFromPoint(xs[xi], ys[yi]);
        for (var si = 0; si < stack.length; si++) inspect(stack[si]);
      }
    }
    var emailInputs = document.getElementsByTagName('input');
    for (var ei = 0; ei < emailInputs.length && ei < 80; ei++) {
      var emailHint = String(emailInputs[ei].getAttribute('type') || '') + ' ' +
        String(emailInputs[ei].getAttribute('placeholder') || '') + ' ' +
        String(emailInputs[ei].getAttribute('aria-label') || '');
      if (emailPattern.test(emailHint)) inspect(emailInputs[ei]);
    }
  }

  // Dismiss only unsolicited sign-in dialogs that SHEIN floats over a product.
  // A real login route or a full account page is never modified, and no form
  // field is hidden. This keeps cookie choices from turning into a forced
  // account interruption while preserving user-initiated authentication.
  var __otlobliSheinLoginDismissAt = 0;
  function dismissSheinProductLoginPrompt() {
    if (!IS_SHEIN || !document.body || !looksLikeProductPage()) return;
    if (/(?:\\/user\\/login|\\/login|\\/signin|\\/sign-in|\\/auth)(?:[/?#]|$)/i.test(location.pathname + location.search)) return;
    var now = Date.now();
    if (now - __otlobliSheinLoginDismissAt < 900) return;
    __otlobliSheinLoginDismissAt = now;
    var vp = viewportSize();
    var authPattern = /(?:sign\\s*in|log\\s*in|continue\\s+with|email|phone\\s+number|\\u062a\\u0633\\u062c\\u064a\\u0644\\s+\\u0627\\u0644\\u062f\\u062e\\u0648\\u0644|\\u0627\\u0644\\u0627\\u0633\\u062a\\u0645\\u0631\\u0627\\u0631\\s+\\u0628|\\u0627\\u0644\\u0628\\u0631\\u064a\\u062f\\s+\\u0627\\u0644(?:\\u0625|\\u0627)\\u0644\\u0643\\u062a\\u0631\\u0648\\u0646\\u064a|\\u0631\\u0642\\u0645\\s+\\u0627\\u0644\\u0647\\u0627\\u062a\\u0641)/i;
    var cookiePattern = /cookies?|\\u0645\\u0644\\u0641\\u0627\\u062a \\u062a\\u0639\\u0631\\u064a\\u0641 \\u0627\\u0644\\u0627\\u0631\\u062a\\u0628\\u0627\\u0637/i;
    var closePattern = /^(?:close|dismiss|skip|not now|maybe later|later|\\u00d7|\\u2715|\\u2716|\\u0625\\u063a\\u0644\\u0627\\u0642|\\u0627\\u063a\\u0644\\u0627\\u0642|\\u062a\\u062e\\u0637\\u064a|\\u0644\\u064a\\u0633 \\u0627\\u0644\\u0622\\u0646|\\u0644\\u0627\\u062d\\u0642(?:\\u0627|\\u0627\\u064b))$/i;
    var candidates = document.querySelectorAll(
      '[role="dialog"],[aria-modal="true"],[class*="login"],[class*="signin"],[class*="sign-in"],[class*="modal"],[class*="popup"],[class*="drawer"]'
    );
    for (var ci = candidates.length - 1; ci >= 0; ci--) {
      var candidate = candidates[ci];
      if (!candidate || (candidate.id && candidate.id.indexOf('otlobli') === 0) || !sheinElementIsVisible(candidate)) continue;
      var rect = candidate.getBoundingClientRect();
      if (rect.width < vp.width * 0.55 || rect.height < 90 || rect.bottom < 60 || rect.top > vp.height - 60) continue;
      var text = getElementText(candidate).replace(/[\\u064B-\\u065F\\u0670]/g, '');
      if (!text || text.length > 1800 || !authPattern.test(text) || cookiePattern.test(text)) continue;
      var fields = candidate.querySelectorAll('input, select, textarea');
      if (!fields.length && !/continue\\s+with|\\u0627\\u0644\\u0627\\u0633\\u062a\\u0645\\u0631\\u0627\\u0631\\s+\\u0628/i.test(text)) continue;
      var controls = candidate.querySelectorAll('button, a, [role="button"]');
      var closeTarget = null;
      for (var bi = 0; bi < controls.length; bi++) {
        var control = controls[bi];
        if (!control || (control.id && control.id.indexOf('otlobli') === 0) || !sheinElementIsVisible(control)) continue;
        var label = String(control.innerText || control.textContent || control.getAttribute('aria-label') || control.getAttribute('title') || '')
          .replace(/\\s+/g, ' ').trim();
        if (closePattern.test(label)) { closeTarget = control; break; }
        var hint = String((control.className || '') + ' ' + (control.id || '') + ' ' +
          (control.getAttribute('aria-label') || '') + ' ' + (control.getAttribute('title') || '')).toLowerCase();
        var controlRect = control.getBoundingClientRect();
        if (/close|dismiss|popup-close|modal-close/.test(hint) && controlRect.width <= 72 && controlRect.height <= 72 &&
            controlRect.top <= rect.top + Math.max(96, rect.height * 0.22)) {
          closeTarget = control;
          break;
        }
      }
      if (!closeTarget) continue;
      try { closeTarget.click(); } catch (e) {}
      return;
    }
  }

  // SHEIN can draw its own black "added successfully" toast over Otlobli's
  // nav after our capture completes. Hide only that exact compact success
  // message; the real product button and every other bottom action remain.
  function hideSheinCartSuccessToast() {
    if (!IS_SHEIN || !document.body) return;
    var vp = viewportSize();
    var successPattern = /added to (?:the )?(?:shopping )?(?:bag|cart) successfully|\\u0623\\u0636(?:\\u064a\\u0641|\\u0641)\\s+\\u0625\\u0644\\u0649\\s+(?:\\u0639\\u0631\\u0628\\u0629|\\u062d\\u0642\\u064a\\u0628\\u0629)\\s+\\u0627\\u0644\\u062a\\u0633\\u0648\\u0642\\s+\\u0628\\u0646\\u062c\\u0627\\u062d/i;

    function inspect(node) {
      var current = node;
      for (var depth = 0; current && current !== document.body && current !== document.documentElement && depth < 7; depth++) {
        if (current.id && current.id.indexOf('otlobli') === 0) return;
        var text = String(current.innerText || current.textContent || '')
          .replace(/[\\u064B-\\u065F\\u0670]/g, '')
          .replace(/\\s+/g, ' ')
          .trim();
        if (text.length > 0 && text.length < 140 && successPattern.test(text)) {
          var rect = current.getBoundingClientRect();
          if (rect.width >= vp.width * 0.35 && rect.height >= 20 && rect.height <= 120 && rect.bottom >= vp.height - 230) {
            current.style.setProperty('display', 'none', 'important');
            current.style.setProperty('visibility', 'hidden', 'important');
            current.style.setProperty('pointer-events', 'none', 'important');
            current.setAttribute('data-otlobli-hidden-cart-toast', '1');
            return;
          }
        }
        current = current.parentElement;
      }
    }

    if (document.elementsFromPoint) {
      var ys = [Math.max(1, vp.height - 8), Math.max(1, vp.height - 52), Math.max(1, vp.height - 100), Math.max(1, vp.height - 150)];
      for (var yi = 0; yi < ys.length; yi++) {
        var stack = document.elementsFromPoint(Math.round(vp.width * 0.5), ys[yi]);
        for (var si = 0; si < stack.length; si++) inspect(stack[si]);
      }
      return;
    }

    var alerts = document.querySelectorAll('[role="alert"], [role="status"], [class*="toast" i], [class*="message" i]');
    for (var ai = 0; ai < alerts.length; ai++) inspect(alerts[ai]);
  }

  // shein.com's own anti-bot system occasionally serves a branded "GSRM
  // Security"/"server's gone missing" block page instead of the real page -
  // observed tied to the session's cookies (clearing them and reloading
  // fixes it immediately). Detected here and handled by the app, since only
  // native code can clear HttpOnly cookies. Reset on navigation so a block
  // on one route doesn't suppress detecting it again on the next.
  // ── وضع التحقق «أنا إنسان» (Cloudflare) — v62 ─────────────────────────────
  // شي إن وضعت موقعها خلف جدار كلاودفلير: صفحة "Just a moment..." تظهر قبل
  // أي محتوى (ثبت بفحص مباشر: HTTP 403 وصفحة تحدي من challenges.cloudflare.com).
  // القاعدة الراسخة: لا نتجاوز التحقق ولا نغطيه ولا نعيد التحميل أثناءه.
  // ما كان يكسر شي إن: حارس السعودية لا يجد مؤشرات سعودية على صفحة التحدي
  // فيعيد تحميلها (حتى مرتين كل 30 ثانية) ويصفّر حل المستخدم قبل إتمامه —
  // فتعلق شي إن للأبد. الحل: نكتشف التحدي، نجمّد كل تدخلاتنا ونزيل عناصرنا
  // من الصفحة، ونبلغ التطبيق (humanCheck) ليطفئ مؤقت «تعذر الفتح» وينتظر.
  var __otlobliChallengeNotified = false;
  // While a Cloudflare / "verify you are human" challenge is on screen we
  // deliberately do nothing (our nodes are removed; the nav is kept by
  // otlobliScheduleChallengeNav). This flag lets the hot polling paths back off
  // so the challenge's own JS gets the CPU and resolves faster — the security
  // check and first paint were slow largely because our 80ms mutation-driven
  // tick kept forcing innerText reflows while Cloudflare was working. The 300ms
  // interval keeps calling tick(), which clears this flag the moment the
  // challenge is gone, so normal hiding/blocking resumes immediately after.
  var otlobliChallengeActive = false;
  function otlobliIsHumanChallenge() {
    try {
      if (otlobliIsHumanChallengeUrl(location.href)) return true;
      if (/just a moment/i.test(document.title || '')) return true;
      if (document.getElementById('challenge-form')) return true;
      if (document.querySelector('script[src*="challenges.cloudflare.com"], iframe[src*="challenges.cloudflare.com"]')) return true;
      if (document.querySelector('[id*="challenge" i], [class*="challenge" i], [data-testid*="challenge" i]')) {
        var challengeText = document.body ? (document.body.innerText || '').slice(0, 2400) : '';
        if (/verify you are human|security verification|checking your browser|cloudflare|إجراء التحقق من الأمان|التحقق من الأمان|لست روبوت|لستَ روبوت|لست روبوتاً|لست روبوتا/i.test(challengeText)) return true;
      }
      var bodyText = document.body ? (document.body.innerText || '').slice(0, 2400) : '';
      if (/m\\.shein\\.com.*إجراء التحقق من الأمان|إجراء التحقق من الأمان|التحقق من أنك لست روبوت|لست روبوت|برامج الروبوت/i.test(bodyText)) return true;
    } catch (e) {}
    return false;
  }
  function otlobliEnterChallengeMode() {
    try { writeSheinSaudiState(); } catch (e) {}
    try {
      var ours = document.querySelectorAll('[id^="otlobli"]');
      for (var ci = 0; ci < ours.length; ci++) {
        try {
          var oid = ours[ci].id || '';
          if (oid === 'otlobli-nav' || oid.indexOf('otlobli-nav-tab-') === 0) continue;
          if (ours[ci].parentNode) ours[ci].parentNode.removeChild(ours[ci]);
        } catch (e) {}
      }
    } catch (e) {}
    otlobliScheduleChallengeNav();
    // An add/loading overlay may have locked scrolling immediately before a
    // same-document challenge appeared.  Removing our nodes is not enough;
    // release that lock so the real verification control remains reachable.
    try { if (document.body) document.body.style.overflow = ''; } catch (e) {}
    if (!__otlobliChallengeNotified) {
      __otlobliChallengeNotified = true;
      try {
        if (window.mobileApp && window.mobileApp.postMessage) {
          window.mobileApp.postMessage({ detail: { type: 'humanCheck' } });
        }
      } catch (e) {}
    }
  }

  var sheinBlockReported = false;
  function checkForSheinSecurityBlock() {
    if (sheinBlockReported) return;
    if (!document.body) return;
    // No childElement-count pre-filter here (a previous version skipped this
    // check entirely whenever body.children.length > 8, meant to dodge the
    // cost of a full-page reflow on busy SHEIN pages) - confirmed broken: the
    // generic carrier-level "System Not Avaliable" block page itself has more
    // than 8 direct body children, so that gate silently skipped the ONE page
    // this function exists to catch, every time, without ever reaching the
    // regex below. This whole check already runs on its own slow 1s interval
    // (not the fast 300ms tick), so one innerText reflow/second is cheap
    // regardless of page complexity - bodyText.length < 2000 below is the
    // real, reliable discriminator (block pages are short; real SHEIN pages
    // never are), not the element count.
    var bodyText = document.body.innerText;
    if (bodyText && bodyText.length < 2000 && /GSRM|gone missing|not avaliable|not available|system not/i.test(bodyText)) {
      sheinBlockReported = true;
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: 'sheinBlocked' } });
      }
    }
  }

  // SHEIN's photo viewer is fixed and near-full-screen, but on older layouts
  // that fixed root is nested several levels below body. Detect it from a few
  // painted points and walk upward to the fixed root; this stays independent
  // of obfuscated classes without scanning the entire product DOM.
  var __otlobliSheinViewerRoot = null;
  var __otlobliSheinViewerDetectedRoot = null;
  var __otlobliSheinViewerScanAt = 0;

  function sheinViewerHasLargeMedia(el, vp) {
    var media = el.querySelectorAll ? el.querySelectorAll('img, picture, canvas, video') : [];
    for (var i = 0; i < media.length && i < 24; i++) {
      var rect = media[i].getBoundingClientRect();
      if (rect.width >= vp.width * 0.5 && rect.height >= vp.height * 0.28) return true;
    }
    return false;
  }

  function isSheinImageViewerCandidate(el, vp) {
    if (!el || (el.id || '').indexOf('otlobli') === 0 || !el.getBoundingClientRect) return false;
    var style = window.getComputedStyle(el);
    if (style.display === 'none' || style.visibility === 'hidden' || parseFloat(style.opacity || '1') <= 0.01) return false;
    var role = String(el.getAttribute && el.getAttribute('role') || '').toLowerCase();
    var ariaModal = String(el.getAttribute && el.getAttribute('aria-modal') || '').toLowerCase();
    if (style.position !== 'fixed' && role !== 'dialog' && ariaModal !== 'true') return false;
    var rect = el.getBoundingClientRect();
    if (rect.width < vp.width * 0.88 || rect.height < vp.height * 0.55) return false;
    if (rect.top > 120 || rect.bottom < vp.height * 0.72) return false;
    var text = String(el.innerText || el.textContent || '').replace(/\\s+/g, ' ').trim();
    if (text.length > 700 || !/\\d+\\s*\\/\\s*\\d+/.test(text)) return false;
    return sheinViewerHasLargeMedia(el, vp);
  }

  function sheinImageViewerRoot(forceScan) {
    if (!IS_SHEIN || !document.body || !looksLikeProductPage()) return null;
    var now = Date.now();
    if (!forceScan && now - __otlobliSheinViewerScanAt < 220) {
      return __otlobliSheinViewerDetectedRoot && document.documentElement.contains(__otlobliSheinViewerDetectedRoot)
        ? __otlobliSheinViewerDetectedRoot : null;
    }
    __otlobliSheinViewerScanAt = now;
    var vp = viewportSize();
    if (__otlobliSheinViewerDetectedRoot && document.documentElement.contains(__otlobliSheinViewerDetectedRoot) &&
        isSheinImageViewerCandidate(__otlobliSheinViewerDetectedRoot, vp)) {
      return __otlobliSheinViewerDetectedRoot;
    }

    var seen = [];
    var points = [
      [Math.round(vp.width * 0.5), Math.round(vp.height * 0.5)],
      [Math.round(vp.width * 0.5), Math.round(vp.height * 0.17)],
      [Math.round(vp.width * 0.5), Math.round(vp.height * 0.76)],
      [Math.round(vp.width * 0.12), Math.round(vp.height * 0.5)],
      [Math.round(vp.width * 0.88), Math.round(vp.height * 0.5)]
    ];
    if (document.elementsFromPoint) {
      for (var pi = 0; pi < points.length; pi++) {
        var stack = document.elementsFromPoint(points[pi][0], points[pi][1]);
        for (var si = 0; si < stack.length; si++) {
          var current = stack[si];
          for (var depth = 0; current && current !== document.body && depth < 12; current = current.parentElement, depth++) {
            if (seen.indexOf(current) >= 0) continue;
            seen.push(current);
            if (isSheinImageViewerCandidate(current, vp)) {
              __otlobliSheinViewerDetectedRoot = current;
              return current;
            }
          }
        }
      }
    }
    var candidates = document.querySelectorAll('[role="dialog"], [aria-modal="true"], body > div, body > section');
    for (var i = candidates.length - 1; i >= 0; i--) {
      if (isSheinImageViewerCandidate(candidates[i], vp)) {
        __otlobliSheinViewerDetectedRoot = candidates[i];
        return candidates[i];
      }
    }
    __otlobliSheinViewerDetectedRoot = null;
    return null;
  }

  function sheinImageViewerOpen(forceScan) {
    return !!sheinImageViewerRoot(!!forceScan);
  }

  // Older WKWebView can keep hit-testing a max-z fixed element while painting
  // a newer composited full-screen sibling over it. When the exact SHEIN
  // viewer appears, reclaim paint order once (not every tick), make the back
  // button opaque over SHEIN's close glyph, and place a transparent guard in
  // the lower black letterbox so taps cannot fall through to a native/add
  // action. Outside the viewer every v85.8.10 nav style remains untouched.
  function stabilizeSheinImageViewerChrome() {
    if (!IS_SHEIN || !document.body) return;
    var viewer = sheinImageViewerRoot();
    var guard = document.getElementById('otlobli-shein-viewer-bottom-guard');
    var nav = document.getElementById('otlobli-nav');
    var back = document.getElementById('otlobli-back-btn');

    if (!viewer) {
      if (guard) guard.remove();
      __otlobliSheinViewerRoot = null;
      if (back) back.style.setProperty('background', 'rgba(20,24,22,.6)', 'important');
      return;
    }

    var vp = viewportSize();
    var navRect = nav && nav.getBoundingClientRect ? nav.getBoundingClientRect() : null;
    var navHeight = navRect && navRect.height > 0 ? Math.round(navRect.height) : 90;
    if (!guard) {
      guard = document.createElement('div');
      guard.id = 'otlobli-shein-viewer-bottom-guard';
      guard.setAttribute('aria-hidden', 'true');
      guard.style.cssText = 'position:fixed!important;left:0!important;right:0!important;' +
        'background:transparent!important;z-index:2147483647!important;pointer-events:auto!important;' +
        'touch-action:none!important;transform:translate3d(0,0,0)!important;will-change:transform!important;';
    }
    guard.style.setProperty('bottom', navHeight + 'px', 'important');
    guard.style.setProperty('height', Math.max(72, Math.min(96, Math.round(vp.height * 0.09))) + 'px', 'important');

    var viewerFollowsChrome = false;
    if (__otlobliSheinViewerRoot === viewer && back && viewer.compareDocumentPosition) {
      viewerFollowsChrome = !!(back.compareDocumentPosition(viewer) & 4);
    }
    if (__otlobliSheinViewerRoot !== viewer || viewerFollowsChrome || !guard.parentElement) {
      // Append in back-to-front order. Moving these existing nodes only on a
      // viewer transition avoids the repeating animation/flicker caused by
      // reclaiming them on every 300ms tick.
      document.body.appendChild(guard);
      if (nav) document.body.appendChild(nav);
      if (back) {
        back.style.setProperty('animation', 'none', 'important');
        document.body.appendChild(back);
      }
      __otlobliSheinViewerRoot = viewer;
    }

    if (nav) {
      nav.style.setProperty('opacity', '1', 'important');
      nav.style.setProperty('visibility', 'visible', 'important');
      nav.style.setProperty('pointer-events', 'auto', 'important');
    }
    if (back) {
      back.style.setProperty('opacity', '1', 'important');
      back.style.setProperty('visibility', 'visible', 'important');
      back.style.setProperty('pointer-events', 'auto', 'important');
      back.style.setProperty('background', 'rgba(20,24,22,.92)', 'important');
    }
  }

  // كشف عارض الصور بملء الشاشة في تيمو (Swipe Gallery Viewer).
  // عندما يكون مفتوحاً يخفي زرنا لأنه يغطي نفس المنطقة ويسبب نقرات خاطئة.
  function temuImageViewerOpen() {
    var vp = viewportSize();
    var minArea = vp.width * vp.height * 0.80;
    var candidates = document.querySelectorAll('body > div, body > section');
    for (var i = 0; i < candidates.length; i++) {
      var el = candidates[i];
      if ((el.id || '').indexOf('otlobli') === 0) continue;
      var cs = window.getComputedStyle(el);
      if (cs.position !== 'fixed') continue;
      if (cs.display === 'none' || cs.visibility === 'hidden') continue;
      var r = el.getBoundingClientRect();
      if (r.width * r.height < minArea) continue;
      if (el.querySelector && el.querySelector('img')) return true;
    }
    return false;
  }

  // نقرة تلقائية على المقاس الوحيد لما تكون لوحة الخيارات مفتوحة.
  // يحلّ مشكلة منتجات "ONE SIZE" — تيمو تتطلب نقرة الزبون حتى لو خيار واحد.
  var __otlobliAutoSizeTs = 0;
  function temuAutoSelectSingleSize() {
    if (!looksLikeProductPage()) return;
    var now = Date.now();
    if (now - __otlobliAutoSizeTs < 1500) return;
    var pills = temuSizePills();
    if (pills.length !== 1) return;
    var pill = pills[0];
    var vp = viewportSize();
    var r = pill.getBoundingClientRect();
    if (r.width <= 0 || r.height <= 0 || r.top < 0 || r.top >= vp.height) return;
    var t = temuCleanText(pill.textContent);
    if (!t || window.__otlobliTemuSize === t) return;
    // تسجيل فقط — ممنوع .click() هنا نهائياً: النقر التلقائي كان يصيب أحياناً
    // رابطاً صُنّف خطأً كزر مقاس وحيد فيُبحر بالصفحة → شاشة بيضاء بعد دخول
    // المنتج مباشرة (وتعمل عند إعادة الدخول لأن هذا الحارس أعلاه يمنع التكرار).
    // نحن نلتقط البيانات فقط ولا نستخدم سلة تيمو، فلا حاجة لتحديث واجهتها.
    window.__otlobliTemuSize = t;
    window.__otlobliTemuSizeGid = temuGoodsId();
    __otlobliAutoSizeTs = now;
  }

  // يمنع النقر على أي <a href> حقيقي - هذا بالضبط سبّب شاشة بيضاء بعلة
  // سابقة موثّقة (temuAutoSelectSingleSize): عنصر صُنّف خطأً كزر اختيار
  // فكان في الحقيقة رابطاً، والنقر عليه أبحر بالصفحة كلياً. نفحص العنصر
  // وحتى 3 آباء (الحاضن قد يكون هو الرابط الفعلي لا الصورة/النص الداخلي).
  function otlobliSafeToClick(el) {
    var node = el, hops = 0;
    while (node && hops < 3) {
      if (node.tagName === 'A') {
        var href = node.getAttribute('href') || '';
        if (href && href !== '#' && href.indexOf('javascript:') !== 0) return false;
      }
      node = node.parentElement; hops++;
    }
    return true;
  }
  // إعادة اختيار اللون/المقاس تلقائياً عند فتح رابط محفوظ من السلة/الطلبات
  // (يحمل معاملات otlobli_color/otlobli_size - انظر otlobliBuildDeepLink).
  // ننقر فعلياً (لا مجرد تسجيل) لأن الهدف إظهار اختيار تيمو المرئي نفسه
  // (الحدّ/الصورة الرئيسية) لا فقط بيانات otlobli الداخلية. حارس أمان
  // صارم (otlobliSafeToClick) يمنع تكرار علة الشاشة البيضاء الموثّقة.
  function temuAutoReselectFromLink() {
    if (!looksLikeProductPage()) return;
    var gid = temuGoodsId();
    if (window.__otlobliAutoReselectDone === gid) return;
    var params;
    try { params = new URLSearchParams(location.search); } catch (e) { window.__otlobliAutoReselectDone = gid; return; }
    var wantColor = params.get('otlobli_color') || '';
    var wantSize = params.get('otlobli_size') || '';
    if (!wantColor && !wantSize) { window.__otlobliAutoReselectDone = gid; return; }
    var attempts = window.__otlobliAutoReselectAttempts || 0;
    if (attempts > 20) { window.__otlobliAutoReselectDone = gid; return; } // ~6 ثوانٍ (tick كل 300ms)
    window.__otlobliAutoReselectAttempts = attempts + 1;
    var colorDone = !wantColor, sizeDone = !wantSize;
    if (wantColor && !(window.__otlobliTemuColor && window.__otlobliTemuColorGid === gid)) {
      var card = temuFindColorCardEl(wantColor);
      if (card && otlobliSafeToClick(card)) {
        try { card.click(); colorDone = true; } catch (e) {}
      }
    } else if (wantColor) {
      colorDone = true;
    }
    if (wantSize && !(window.__otlobliTemuSize && window.__otlobliTemuSizeGid === gid)) {
      var pills = temuSizePills();
      for (var i = 0; i < pills.length; i++) {
        if (temuCleanText(pills[i].textContent) === wantSize) {
          if (otlobliSafeToClick(pills[i])) {
            try { pills[i].click(); sizeDone = true; } catch (e) {}
          }
          break;
        }
      }
    } else if (wantSize) {
      sizeDone = true;
    }
    if (colorDone && sizeDone) window.__otlobliAutoReselectDone = gid;
    // لا جدولة داخلية - tick() الرئيسي (كل 300ms) يستدعي هذه الدالة أصلاً
    // ويعيد المحاولة تلقائياً حتى انتهاء المحاولات أو النجاح (لا ازدواج).
  }

  function tick() {
    // Same documentStart race as the MutationObserver fix above - body can
    // still be null on the very first tick() call (the direct one at the
    // bottom of this script, before the parser has necessarily reached
    // <body>). Every function below ultimately needs body to exist, so bail
    // out cheaply here instead of each of them hitting it separately; the
    // setInterval(tick, 300) already scheduled will simply call this again
    // shortly, by which point the parser is essentially always done with it.
    if (!document.body) return;
    // صفحة تحقق «أنا إنسان» — تجميد كامل لكل تدخلاتنا حتى يكملها المستخدم.
    if (otlobliIsHumanChallenge()) { otlobliChallengeActive = true; otlobliEnterChallengeMode(); return; }
    otlobliChallengeActive = false;
    if (IS_SHEIN) ensureSheinSaudiShippingSelection();
    if (IS_SHEIN) retrySheinFeedError();
    ensureNoTextSelection();
    ensureViewportFitCover();
    if (IS_SHEIN) ensureSheinSaudiStore({ navigate: false });
    ensureBackButton();
    ensureOtlobliNav();
    // المتاجر غير شي إن (تيمو/ترينديول): تصفّح فقط - ننظّف العروض المنبثقة
    // المزعجة ولا نشغّل منطق الالتقاط/الحجب الخاص بشي إن (الذي قد يخرّب صفحاتهم).
    if (!IS_SHEIN) {
      if (IS_TEMU) {
        var temuSearching = otlobliTemuSearchMode();
        try { injectTemuHeaderHideCSS(); } catch (e) {}
        try { ensureTemuNoZoom(); } catch (e) {}
        try { stabilizeTemuSearchChrome(); } catch (e) {}
        // killStorePopups معطّلة لتيمو نهائياً (v57): أكّد اختبار المستخدم
        // (2026-07-10) أنها سبب وميض الشاشة الأبيض كل نصف ثانية — كانت تحجب
        // طبقة كبيرة تطابق PROMO ثم تعيدها المراجعة الذاتية، كل 300ms.
        // لا تُعِد تفعيلها لتيمو. بانر التنزيل يُحجب عبر OTLOBLI_TEMU_HIDE_CSS
        // الثابت (downloadUI فقط، وليس الغلاف downloadsWrapper الحاوي للبحث).
        // أثناء البحث: نوقف دوال إخفاء الكروم حتى لا تبتلع صفوف الاقتراحات.
        if (!temuSearching) {
          try { hideTemuHeaderIconsByProbe(); } catch (e) {}
          try { hideTemuCustomerAccountAndCart(); } catch (e) {}
          try { hideTemuCustomerChrome(); } catch (e) {}
        }
        try { restoreTemuSearchChrome(); } catch (e) {}
        try { restoreTemuLogo(); } catch (e) {}
        try { ensureAddToCartButton(); } catch (e) {}
        try { dismissTemuLoginPopup(); } catch (e) {}
        if (!temuSearching) {
          try { hideTemuSpinWheelPopup(); } catch (e) {}
        }
        try { detectEmptyTemuSearch(); } catch (e) {}
        return;
      }
      try { killStorePopups(); } catch (e) {}
      return;
    }
    ensureLoadingOverlay();
    blockCartNavigation();
    ensureAddToCartButton();
    stabilizeSheinImageViewerChrome();
    hideKnownHeaderIconsByHint();
    hideSheinHeaderControls();
    hideExtraHeaderIcons();
    hideSheinCartIcons();
    hideListingCardAddButtons();
    hideForeignBottomNav();
    otlobliForceAcceptCookies();
    protectSheinCookieConsentAction();
    hideSheinSignupDiscountBanner();
    dismissSheinProductLoginPrompt();
    hideSheinCartSuccessToast();
    hideSheinAppInstallPrompts();
    // Readiness must be the final step. Previously it was posted before the
    // header/cart/listing/nav blockers below ran, so native code could reveal
    // a product for one or two seconds with raw SHEIN chrome still visible.
    updateSheinNativeCoverState();
  }

  // وضع بحث تيمو: عندما يركّز المستخدم حقل البحث ويكتب، تعرض تيمو قائمة
  // اقتراحات أسفل الشريط. دوال إخفاء «كروم» تيمو تعمل كل tick وتخفي تدريجياً
  // عناصر أعلى الصفحة — فكانت تبتلع صفوف الاقتراحات (تظهر ثم تختفي بعد ثانية).
  // أثناء البحث نعلّق تلك الدوال تماماً (كما نعلّق فحوصاتنا أثناء تحدي شي إن)
  // فلا نلمس الاقتراحات، ونُظهر زر الرجوع ليخرج المستخدم من البحث.
  function otlobliTemuSearchInput() {
    if (!IS_TEMU) return null;
    return document.querySelector('input[type="search"], [role="searchbox"], input[placeholder*="بحث"], input[placeholder*="Search" i]');
  }
  // وضع البحث نشط طالما لوحة الاقتراحات ظاهرة — لا فقط أثناء التركيز. حقل بحث
  // تيمو يحتفظ بقيمته والاقتراحات (overlay ._3KC0yZ4V، z-index 999) تبقى ظاهرة
  // حتى بعد إغلاق الكيبورد (blur). الاعتماد على activeElement وحده كان يُنهي وضع
  // البحث باكراً فتعود دوال الإخفاء وتبتلع الاقتراحات ويختفي زر الرجوع. نعتبره
  // نشطاً إذا كان حقل البحث مركّزاً أو يحمل قيمة.
  function otlobliTemuSearchMode() {
    if (!IS_TEMU || !document.body) return false;
    var si = otlobliTemuSearchInput();
    if (si) {
      if (document.activeElement === si) return true;
      if ((si.value || '').trim()) return true;
    }
    if (/search/i.test(location.pathname) || /search/i.test(location.search)) return true;
    return false;
  }

  // يكشف صفحة بحث تيمو الفارغة (الناتجة عن حجب الإعلانات الذي يمنع تحميل
  // نتائج البحث) ويعرض رسالة توضيحية للمستخدم — يعمل مرة واحدة فقط لكل رحلة.
  var __otlobliSearchMsgShown = false;
  function detectEmptyTemuSearch() {
    if (__otlobliSearchMsgShown) return;
    // صفحة نتائج البحث فقط
    if (!/search/i.test(location.href) && !/search/i.test(location.pathname)) return;
    if (looksLikeProductPage()) return;
    // نتحقق بعد اكتمال التحميل
    if (document.readyState !== 'complete') return;
    // إذا وُجدت صور منتجات مرئية — الصفحة ليست فارغة
    var imgs = document.querySelectorAll('img');
    var hasProducts = false;
    for (var i = 0; i < imgs.length; i++) {
      var src = imgs[i].currentSrc || imgs[i].src || '';
      if (!/kwcdn|temu/i.test(src)) continue;
      var r = imgs[i].getBoundingClientRect();
      if (r.width > 80 && r.height > 80) { hasProducts = true; break; }
    }
    if (hasProducts) return;
    __otlobliSearchMsgShown = true;
    console.info('otlobli: temu search appears empty; kept internal only');
  }

  // منع الزوم في تيمو: viewport بلا تكبير + إلغاء إيماءة القرصة + إلغاء
  // تكبير النقر المزدوج (touch-action). تُستدعى دورياً لأن تيمو SPA قد
  // تستبدل وسم الـviewport عند التنقل بين الصفحات.
  var __otlobliNoZoomListeners = false;
  function ensureTemuNoZoom() {
    try {
      var NO_ZOOM = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
      var vpMeta = document.querySelector('meta[name="viewport"]');
      if (!vpMeta && document.head) {
        vpMeta = document.createElement('meta');
        vpMeta.setAttribute('name', 'viewport');
        document.head.appendChild(vpMeta);
      }
      if (vpMeta && vpMeta.getAttribute('content') !== NO_ZOOM) {
        vpMeta.setAttribute('content', NO_ZOOM);
      }
      if (document.documentElement && document.documentElement.style.touchAction !== 'pan-x pan-y') {
        document.documentElement.style.touchAction = 'pan-x pan-y';
      }
      if (document.documentElement) {
        document.documentElement.style.setProperty('-webkit-text-size-adjust', '100%', 'important');
        document.documentElement.style.setProperty('text-size-adjust', '100%', 'important');
        document.documentElement.style.setProperty('max-width', '100vw', 'important');
        document.documentElement.style.setProperty('overflow-x', 'hidden', 'important');
      }
      if (document.body) {
        document.body.style.setProperty('-webkit-text-size-adjust', '100%', 'important');
        document.body.style.setProperty('text-size-adjust', '100%', 'important');
        document.body.style.setProperty('max-width', '100vw', 'important');
        document.body.style.setProperty('overflow-x', 'hidden', 'important');
      }
      if (document.head && !document.getElementById('otlobli-temu-stability-style')) {
        var style = document.createElement('style');
        style.id = 'otlobli-temu-stability-style';
        style.textContent = [
          'html,body{min-width:0!important;width:100%!important;max-width:100vw!important;overflow-x:hidden!important;-webkit-text-size-adjust:100%!important;text-size-adjust:100%!important;scroll-padding-bottom:128px!important;}',
          'input,textarea,select{font-size:16px!important;}',
          '#otlobli-nav{transform:translate3d(-50%,0,0)!important;will-change:transform!important;}',
          '#otlobli-add-btn,#otlobli-back-btn{will-change:transform!important;}',
        ].join('');
        document.head.appendChild(style);
      }
      if (!__otlobliNoZoomListeners) {
        __otlobliNoZoomListeners = true;
        // إيماءة القرصة على iOS WKWebView — touch-action أعلاه يمنع تكبير
        // النقر المزدوج، وهذان يمنعان القرصة. لا نلمس touchend حتى لا نكسر
        // النقرات السريعة المتتالية (زر الكمية مثلاً).
        document.addEventListener('gesturestart', function (e) { e.preventDefault(); }, { passive: false });
        document.addEventListener('gesturechange', function (e) { e.preventDefault(); }, { passive: false });
      }
    } catch (e) {}
  }

  // نص قاعدة CSS التي تُخفي أزرار هيدر تيمو + بانر "تسوّق مثل الملياردير".
  // الأزرار الثلاثة (عربة التسوق/الحساب/الفئات) كلها من نوع .tab-d3nPD داخل
  // حاوية الهيدر topTabContainer. نستهدف أيضاً aria-label الدقيق كطبقة احتياطية
  // لو تغيّرت أسماء الأصناف المُولّدة. اللاحقة العشوائية للأصناف (مثل -RLshn)
  // قد تتغيّر بين الإصدارات لذا نطابق بالبادئة عبر [class*=].
  //
  // تحذير (v57): ممنوع إخفاء .downloadsWrapper كاملاً — على الأجهزة الفعلية
  // شريط البحث بالرئيسية يسكن داخل هذا الغلاف نفسه (درس v35 المكرر في v53)،
  // فإخفاؤه يُخفي البحث معه. كانت المراجعة الذاتية في killStorePopups تنقذه،
  // وبعد تعطيلها لتيمو (سبب الوميض) لا منقذ. نخفي .downloadUI فقط (واجهة
  // بانر التنزيل الفعلية داخل الغلاف) ويبقى الغلاف والبحث ظاهرين.
  var OTLOBLI_TEMU_HIDE_CSS =
    '[class*="tab-d3nPD"],' +
    '[aria-label="عربة التسوق"], [aria-label="الحساب"], [aria-label="الفئات"],' +
    '[class*="downloadUI" i]' +
    '{ display: none !important; visibility: hidden !important; pointer-events: none !important; }' +
    // (v60) غلاف downloadsWrapper يبقى ظاهراً (يحوي البحث — درس v57)، لكن
    // بعد إخفاء بانر downloadUI تبقى حشوة/خلفية الغلاف فتظهر إطاراً أبيض
    // كبيراً حول البحث أحياناً — نصفّر تباعده دون إخفائه.
    '[class*="downloadsWrapper"]' +
    '{ padding: 0 !important; margin: 0 !important; min-height: 0 !important; box-shadow: none !important;' +
    ' background: transparent !important; border: 0 !important; border-radius: 0 !important; }' +
    // (v66-fix) لا نثبّت شريط البحث بـ position:fixed. التثبيت + خلفية #fff +
    // إعادة القياس/الوسم كل tick كان يُنتج مستطيلاً أبيض كبيراً ووميض «ياضي
    // ويطفي» أثناء التمرير (تيمو تُعيد بناء الهيدر فيُزال الوسم ثم يُعاد). نتركه
    // في التدفق الطبيعي ونكتفي بإبقائه ظاهراً بخلفية شفافة — أبسط وأثبت.
    '[data-otlobli-temu-search-shell="1"]' +
    '{ background: transparent !important; box-shadow: none !important; opacity: 1 !important;' +
    ' visibility: visible !important; pointer-events: auto !important; }';
  // نحقن القاعدة في أبكر لحظة ممكنة (documentStart، قبل رسم أي شيء) لمنع أي
  // وميض للعناصر المخفية. لا نعتمد على flag لمرة واحدة، بل نفحص وجود <style>
  // فعلياً في كل استدعاء: لو أزالت تيمو عنصرنا أثناء إعادة بناء الصفحة (عند
  // فتح منتج والرجوع مثلاً) نعيد حقنه فوراً فلا يظهر المخفي أبداً. نستخدم
  // document.head إن وُجد وإلا document.documentElement (المتوفّر دائماً هذا
  // الوقت المبكر) فتُطبَّق القاعدة حتى قبل إنشاء <head>.
  function injectTemuHeaderHideCSS() {
    if (!IS_TEMU) return;
    if (document.getElementById('otlobli-temu-header-hide')) return;
    var parent = document.head || document.documentElement;
    if (!parent) return;
    var style = document.createElement('style');
    style.id = 'otlobli-temu-header-hide';
    style.textContent = OTLOBLI_TEMU_HIDE_CSS;
    parent.appendChild(style);
  }
  // حقن فوري لحظة تحميل السكربت (preShowScript يعمل عند documentStart) — هذا
  // هو ما يمنع ظهور الأزرار/البانر ولو لجزء من الثانية عند أول دخول للمتجر.
  try { injectTemuHeaderHideCSS(); } catch (e) {}

  function hideTemuHeaderIconsByProbe() {
    if (!IS_TEMU || !document.body) return;
    try {
      var all = document.querySelectorAll('a, button, div, span, i, [role="button"]');
      for (var i = 0; i < all.length; i++) {
        var el = all[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (el.closest && el.closest('[data-otlobli-temu-search-shell="1"]')) continue;
        if (el.getAttribute && el.getAttribute('data-otlobli-temu-hidden') === '1') continue;
        var r = el.getBoundingClientRect();
        if (r.width === 0 || r.height === 0) continue;
        if (r.top < 0 || r.top > 160) continue;
        if (r.width > 64 || r.height > 64) continue;
        if (r.width < 14 || r.height < 14) continue;
        var txt = (el.textContent || '').trim();
        var isKnownDistraction = OTLOBLI_KNOWN_DISTRACTION.test(txt) || OTLOBLI_KNOWN_DISTRACTION.test(otlobliCollectIdentityHints(el));
        if (txt.length > 20 && !isKnownDistraction) continue;
        if (otlobliLooksLikeTemuLogo(el)) continue;
        var hints = otlobliCollectIdentityHints(el);
        if (/search|بحث|magnif/i.test(hints)) continue;
        if (el.querySelector && el.querySelector('input, textarea')) continue;
        if (temuContainsPrice(el)) continue;
        el.setAttribute('data-otlobli-temu-hidden', '1');
        el.style.setProperty('visibility', 'hidden', 'important');
        el.style.setProperty('pointer-events', 'none', 'important');
      }
    } catch (e) {}
  }

  // (v65) مُغلِق مهذّب لنافذة تسجيل دخول تيمو المنبثقة عند فتح منتج. لا يحجب
  // محتوى المنتج ولا يُسجّل الدخول — فقط يبحث عن نافذة تسجيل دخول عائمة
  // (position:fixed، تغطية كبيرة، نصّها يذكر تسجيل الدخول) وينقر زر الإغلاق
  // (× / إغلاق / aria-label) أو زر «لاحقاً/تخطّي» إن وُجد. محاولة واحدة كل
  // ظهور (علامة على النافذة) حتى لا نُكرر النقر. إن كانت شاشة تسجيل دخول
  // كاملة (تنقّل صفحة، لا نافذة) فلا نقدر إغلاقها — تلك سياسة تيمو للمنطقة.
  var __otlobliTemuLoginProbeTs = 0;
  function dismissTemuLoginPopup() {
    if (!IS_TEMU || !document.body) return;
    var now = Date.now();
    if (now - __otlobliTemuLoginProbeTs < 900) return; // لا نفحص كل tick
    __otlobliTemuLoginProbeTs = now;
    var LOGIN_RE = /سجّ?ل\\s*الدخول|تسجيل\\s*الدخول|sign\\s*in|log\\s*in|continue\\s*with|تابع\\s*عبر|أنشئ\\s*حساب|create\\s*account/i;
    var CLOSE_RE = /^(?:×|✕|✖|x|close|إغلاق|اغلاق|تخطّ?ي|تخطي|skip|later|لاحقًا|لاحقا|ليس\\s*الآن|not\\s*now)$/i;
    var vp = viewportSize();
    var nodes = document.querySelectorAll('div, section, aside');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.getAttribute && el.getAttribute('data-otlobli-login-handled') === '1') continue;
      var cs = window.getComputedStyle(el);
      if (cs.position !== 'fixed' && cs.position !== 'absolute') continue;
      var r = el.getBoundingClientRect();
      // نافذة كبيرة تغطي جزءاً معتبراً من الشاشة (لا شريط صغير).
      if (r.width < vp.width * 0.6 || r.height < vp.height * 0.35) continue;
      var txt = (el.textContent || '');
      if (txt.length > 600 || !LOGIN_RE.test(txt)) continue;
      // حارس المنتج: لا نلمس طبقة فيها سعر/شبكة صور منتجات (قد تكون المنتج).
      if (temuContainsPrice(el)) continue;
      el.setAttribute('data-otlobli-login-handled', '1');
      // ابحث عن زر إغلاق/تخطّي داخلها وانقره.
      var btns = el.querySelectorAll('button, [role="button"], a, i, span, div');
      var clicked = false;
      for (var b = 0; b < btns.length && !clicked; b++) {
        var bt = btns[b];
        var bTxt = (bt.textContent || '').trim();
        var aria = (bt.getAttribute && (bt.getAttribute('aria-label') || '')) || '';
        var br = bt.getBoundingClientRect();
        if (br.width === 0 || br.height === 0) continue;
        if (CLOSE_RE.test(bTxt) || CLOSE_RE.test(aria.trim())) {
          try { bt.click(); clicked = true; } catch (e) {}
        }
      }
      // إن لم نجد زر إغلاق واضحاً، ننقر خلفية النافذة (تُغلق أغلب النوافذ)
      // فقط إن كانت عائمة تغطي كامل الشاشة (backdrop).
      if (!clicked && cs.position === 'fixed' && r.top <= 2 && r.left <= 2 &&
          r.width >= vp.width - 4 && r.height >= vp.height - 4) {
        try { el.click(); } catch (e) {}
      }
    }
  }

  function hideTemuCustomerAccountAndCart() {
    if (!IS_TEMU || !document.body) return;
    try {
      var search = document.querySelector('input[type="search"], input[placeholder*="Search" i], input[placeholder*="بحث"], [role="searchbox"]');
      var searchLeft = 230;
      if (search) {
        var sr = search.getBoundingClientRect();
        if (sr.width > 40) searchLeft = Math.max(120, sr.left);
      }
      if (searchLeft === 230) {
        var probes = document.querySelectorAll('a, div, span, button');
        for (var pi = 0; pi < probes.length; pi++) {
          var pe = probes[pi];
          var pr = pe.getBoundingClientRect();
          if (pr.top < 0 || pr.top > 180 || pr.width < 100 || pr.height < 20 || pr.height > 60) continue;
          if (otlobliLooksLikeSearchTrigger(pe) || (pe.querySelector && pe.querySelector('input'))) {
            searchLeft = Math.max(120, pr.left);
            break;
          }
        }
      }
      var candidates = [];
      var nodes = document.querySelectorAll('a, button, [role="button"], div, span');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (el.closest && el.closest('[data-otlobli-temu-search-shell="1"]')) continue;
        if (el.getAttribute && el.getAttribute('data-otlobli-temu-hidden') === '1') continue;
        if (el.querySelector && el.querySelector('input, textarea, select')) continue;
        if (temuContainsPrice(el)) continue;
        var txt = temuCleanText(el.textContent);
        var isDistraction = OTLOBLI_KNOWN_DISTRACTION.test(txt) || otlobliLooksLikeKnownDistraction(el);
        if (txt.length > 25 && !isDistraction) continue;
        var r = el.getBoundingClientRect();
        if (r.width < 22 || r.height < 22 || r.width > 72 || r.height > 72) continue;
        if (r.top < 0 || r.top > 150) continue;
        var isSearch = el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || (el.querySelector && el.querySelector('input, textarea, [role="searchbox"]'));
        if (isSearch || otlobliLooksLikeSearchTrigger(el)) continue;
        if (otlobliLooksLikeTemuLogo(el)) continue;
        var beforeSearch = r.left < searchLeft - 12;
        var leftHeaderIcon = r.left >= 0 && r.left <= 145;
        if (!beforeSearch && !leftHeaderIcon) continue;
        candidates.push({ el: el, left: r.left, top: r.top });
      }
      candidates.sort(function (a, b) {
        if (Math.abs(a.top - b.top) > 16) return a.top - b.top;
        return a.left - b.left;
      });
      var hidden = 0;
      var hiddenBuckets = [];
      for (var c = 0; c < candidates.length; c++) {
        if (hidden >= 5) break;
        var duplicateBucket = false;
        for (var hb = 0; hb < hiddenBuckets.length; hb++) {
          if (Math.abs(hiddenBuckets[hb] - candidates[c].left) < 18) duplicateBucket = true;
        }
        if (duplicateBucket) continue;
        candidates[c].el.setAttribute('data-otlobli-temu-hidden', '1');
        candidates[c].el.style.setProperty('visibility', 'hidden', 'important');
        candidates[c].el.style.setProperty('pointer-events', 'none', 'important');
        hiddenBuckets.push(candidates[c].left);
        hidden++;
      }

      var floating = document.querySelectorAll('[class*="float" i], [class*="cart" i], [aria-label*="cart" i], [aria-label*="سلة"]');
      for (var f = 0; f < floating.length; f++) {
        var fcEl = floating[f];
        if (fcEl.id && fcEl.id.indexOf('otlobli') === 0) continue;
        if (temuContainsPrice(fcEl)) continue;
        var fr = fcEl.getBoundingClientRect();
        var fcs = window.getComputedStyle(fcEl);
        if (fr.width < 34 || fr.width > 140 || fr.height < 34 || fr.height > 140) continue;
        if (fcs.position !== 'fixed' && fcs.position !== 'absolute') continue;
        var fcHints = otlobliCollectIdentityHints(fcEl) + ' ' + temuCleanText(fcEl.textContent);
        var looksCart = /(cart|shopping|basket|bag|عربة|سلة|التسوق)/i.test(fcHints);
        var leftFloatingCart = fr.left <= 130 && fr.top >= 70 && fr.top <= viewportSize().height * 0.7 && (looksCart || !!(fcEl.querySelector && fcEl.querySelector('svg,img')));
        if (!leftFloatingCart && fr.top > 180 && fr.bottom < viewportSize().height - 120) continue;
        fcEl.setAttribute('data-otlobli-temu-hidden', '1');
        fcEl.style.setProperty('display', 'none', 'important');
        fcEl.style.setProperty('visibility', 'hidden', 'important');
        fcEl.style.setProperty('pointer-events', 'none', 'important');
      }
    } catch (e) {}
  }

  function hideTemuCustomerChrome() {
    if (!IS_TEMU || !document.body) return;
    try {
      var vp = viewportSize();
      var nodes = document.querySelectorAll('div, section, aside, nav, footer');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (temuContainsPrice(el)) continue;
        var txt = temuCleanText(el.textContent);
        if (!txt || txt.length > 160) continue;
        var r = el.getBoundingClientRect();
        if (r.width < vp.width * 0.45 || r.height <= 0 || r.height > 150) continue;
        var cs = window.getComputedStyle(el);
        var fixedish = cs.position === 'fixed' || cs.position === 'sticky' || cs.position === 'absolute';
        var topAppBanner = r.top >= 0 && r.top < 170 && /temu/i.test(txt) && /(حصل|تنزيل|تطبيق|get|download|app)/i.test(txt);
        var bottomLogin = r.bottom > vp.height - 170 && /(سجل الدخول|تسجيل الدخول|sign in|login|أفضل تجربة|best experience)/i.test(txt);
        var bottomStoreAction = r.bottom > vp.height - 190 && (/(cart|bag|deal|offer|add to|login|sign in)/i.test(txt) || /rgb\\(255,\\s*(?:102|118|128|136|145|153|165),\\s*0\\)/i.test(cs.backgroundColor || ''));
        if (!fixedish && !topAppBanner) continue;
        if (topAppBanner || bottomLogin || bottomStoreAction) {
          // حارس البحث (v57): ممنوع حجب أي حاوية تضم شريط/حقل البحث — العلامة
          // data-otlobli-temu-hidden تمنع الاستعادة نهائياً (otlobliUnhideEl
          // يرفضها)، فحجب حاوية البحث هنا يعني اختفاءه بلا رجعة.
          if (el.querySelector && el.querySelector('input[type="search"], input[placeholder*="Search" i], input[placeholder*="بحث"], [role="searchbox"], [class*="searchBar" i]')) continue;
          el.setAttribute('data-otlobli-temu-hidden', '1');
          el.style.setProperty('display', 'none', 'important');
          el.style.setProperty('pointer-events', 'none', 'important');
        }
      }
    } catch (e) {}
  }

  function otlobliUnhideEl(el) {
    if (!el || (el.id && el.id.indexOf('otlobli') === 0)) return;
    if (el.getAttribute && el.getAttribute('data-otlobli-temu-hidden') === '1') return;
    el.removeAttribute('data-otlobli-blocked');
    el.style.removeProperty('display');
    el.style.setProperty('visibility', 'visible', 'important');
    el.style.setProperty('opacity', '1', 'important');
    el.style.setProperty('pointer-events', 'auto', 'important');
  }

  function otlobliLooksLikeTemuLogo(el) {
    if (!el) return false;
    var txt = (el.textContent || '').trim();
    if (/^TEMU$/i.test(txt)) return true;
    if (el.tagName === 'A') {
      var href = el.getAttribute('href') || '';
      if (/^\\/(?:jo\\/?)?\\.?$/.test(href) || href === '/') {
        var r = el.getBoundingClientRect();
        if (r.width > 60 && r.height > 20 && r.height < 60) return true;
      }
    }
    var logoImg = el.tagName === 'IMG' ? el : (el.querySelector ? el.querySelector('img') : null);
    if (logoImg) {
      var alt = (logoImg.getAttribute('alt') || '').trim();
      if (/^temu$/i.test(alt)) return true;
      var src = logoImg.getAttribute('src') || '';
      if (/logo/i.test(src) && /temu/i.test(src)) return true;
    }
    return false;
  }

  // ملاحظة مهمة: هاتان الدالتان كانتا تستدعيان otlobliUnhideEl على البحث/الشعار
  // + آبائهما (4-5 مستويات) + كل أطفال حاوية البحث. لوحة حساب تيمو (تسجيل الدخول
  // /إنشاء حساب) تعيش داخل نفس حاوية الهيدر (شقيقة/طفلة للبحث) وهي مخفية بـ
  // opacity:0. فكان توسيع الاستعادة للآباء/الأطفال يفرض عليها opacity:1 قسراً
  // فتظهر تلقائياً عند النزول وتقفز الصفحة لأعلى. الآن نستعيد العنصر نفسه فقط
  // (لا آباء ولا أطفال)، فلا نلمس اللوحة إطلاقاً. هذا يكفي لأن الإخفاء الثابت
  // (منذ v57) يستهدف .tab-d3nPD/.downloadUI فقط ولا يخفي حاوية البحث —
  // ملاحظة: استعادة العنصر نفسه لا تنفع أصلاً إن حُجب أحد آبائه بـ display:none.
  function restoreTemuSearchChrome() {
    if (!IS_TEMU || !document.body) return;
    try {
      var nodes = document.querySelectorAll('input[type="search"], input[placeholder*="Search" i], input[placeholder*="بحث"], [role="searchbox"], a, button, div, span');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        var r = el.getBoundingClientRect();
        if (r.top < -20 || r.top > 170 || r.width < 40 || r.height < 16) continue;
        if (!otlobliNearSearchInput(el) && !otlobliLooksLikeSearchTrigger(el)) continue;
        otlobliUnhideEl(el);
      }
    } catch (e) {}
  }

  function otlobliTemuTransformY(transformValue) {
    if (!transformValue || transformValue === 'none') return 0;
    var m3 = transformValue.match(/^matrix3d\(([^)]+)\)$/i);
    if (m3) {
      var p3 = m3[1].split(',');
      var y3 = parseFloat(p3[13]);
      return isFinite(y3) ? y3 : 0;
    }
    var m2 = transformValue.match(/^matrix\(([^)]+)\)$/i);
    if (m2) {
      var p2 = m2[1].split(',');
      var y2 = parseFloat(p2[5]);
      return isFinite(y2) ? y2 : 0;
    }
    return 0;
  }

  function otlobliPinVisibleTemuSearchHeader(control, vp) {
    if (!control) return;
    var node = control;
    for (var i = 0; i < 12 && node && node !== document.body; i++, node = node.parentElement) {
      var style = window.getComputedStyle(node);
      if (style.position !== 'fixed') continue;
      var rect = node.getBoundingClientRect();
      // Only Temu's compact, fully painted top header. Never pin search
      // overlays, suggestions, dialogs, or off-screen copies of the input.
      if (rect.width < vp.width * 0.8 || rect.height < 30 || rect.height > 120 ||
          rect.top < 0 || rect.top > 170 || rect.bottom <= 0) return;
      if (node.getAttribute('data-otlobli-temu-pinned-header') === '1') return;
      var translateY = otlobliTemuTransformY(style.transform);
      // Temu centres this header with translateX(-50%) and changes only Y to
      // hide/show it while scrolling. The old fix replaced the whole transform
      // with translateY(0), losing that X centring and breaking half the page.
      // Preserve responsive X centring and freeze the currently painted Y.
      node.style.setProperty('transform', 'translate3d(-50%,' + translateY + 'px,0)', 'important');
      node.style.setProperty('transition', 'none', 'important');
      node.setAttribute('data-otlobli-temu-pinned-header', '1');
      return;
    }
  }

  function stabilizeTemuSearchChrome() {
    if (!IS_TEMU || !document.body) return;
    try {
      var vp = viewportSize();
      var control = null;
      var direct = document.querySelectorAll(
        'input[type="search"], input[placeholder*="Search" i], input[placeholder*="بحث"], [role="searchbox"]'
      );
      for (var i = 0; i < direct.length; i++) {
        var dr = direct[i].getBoundingClientRect();
        if (dr.width >= 100 && dr.height >= 22 && dr.height <= 64 &&
            dr.bottom > 0 && dr.top < Math.min(vp.height, 180)) { control = direct[i]; break; }
      }
      if (!control) {
        var triggers = document.querySelectorAll('a, button, [role="button"], div');
        for (var t = 0; t < triggers.length; t++) {
          var tr = triggers[t].getBoundingClientRect();
          if (tr.width < 140 || tr.width > vp.width - 4 || tr.height < 26 || tr.height > 64 ||
              tr.bottom <= 0 || tr.top >= Math.min(vp.height, 180)) continue;
          if (otlobliLooksLikeSearchTrigger(triggers[t])) { control = triggers[t]; break; }
        }
      }
      if (!control) return;

      var controlRect = control.getBoundingClientRect();
      // Keep the same shell after it is pinned. Its padding/geometry changes
      // intentionally, so re-running the ancestor heuristic could otherwise
      // walk inward on the next 120ms pass and make the field jump.
      var pinnedShell = control.closest ? control.closest('[data-otlobli-temu-search-shell="1"]') : null;
      var shell = pinnedShell || control;
      var up = pinnedShell ? null : control.parentElement;
      var hops = 0;
      while (up && up !== document.body && hops < 4) {
        var ur = up.getBoundingClientRect();
        if (ur.width >= controlRect.width && ur.width <= vp.width - 4 && ur.height >= controlRect.height && ur.height <= 82) {
          shell = up;
          var identity = otlobliCollectIdentityHints(up);
          if (/search|بحث/i.test(identity) || up.tagName === 'FORM' || up.getAttribute('role') === 'search') break;
        }
        if (ur.width >= vp.width - 2 || ur.height > 96) break;
        up = up.parentElement;
        hops++;
      }

      var oldShells = document.querySelectorAll('[data-otlobli-temu-search-shell="1"]');
      for (var s = 0; s < oldShells.length; s++) {
        if (oldShells[s] !== shell) oldShells[s].removeAttribute('data-otlobli-temu-search-shell');
      }

      var sr = shell.getBoundingClientRect();
      var left = Math.max(4, Math.min(sr.left, vp.width - 104));
      var width = Math.max(100, Math.min(sr.width, vp.width - left - 4));
      shell.setAttribute('data-otlobli-temu-search-shell', '1');
      shell.style.setProperty('--otlobli-temu-search-left', Math.round(left) + 'px');
      shell.style.setProperty('--otlobli-temu-search-width', Math.round(width) + 'px');
      otlobliPinVisibleTemuSearchHeader(control, vp);
    } catch (e) {}
  }

  function restoreTemuLogo() {
    if (!IS_TEMU || !document.body) return;
    try {
      var all = document.querySelectorAll('a, div, span, img');
      for (var i = 0; i < all.length; i++) {
        var el = all[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        var r = el.getBoundingClientRect();
        if (r.top < -20 || r.top > 140 || r.width < 40 || r.height < 16) continue;
        if (!otlobliLooksLikeTemuLogo(el)) continue;
        otlobliUnhideEl(el);
      }
    } catch (e) {}
  }

  function killStorePopups() {
    if (IS_SHEIN) return;
    var vp = viewportSize();
    // مراجعة ذاتية أولاً: أي طبقة أخفيناها ثم كبر محتواها لاحقاً = صفحة منتج
    // أُخفيت خطأً أثناء الرندر (طبقة انتقال SPA نصّها المبكر "خصم 77%" فقط
    // فطابقت ملف العرض الترويجي) → نُعيدها فوراً ونُدرجها بقائمة بيضاء دائمة.
    // هذا كان سبب الشاشة البيضاء عند دخول المنتجات.
    var hiddenEls = document.querySelectorAll('[data-otlobli-blocked="1"]');
    for (var rv = 0; rv < hiddenEls.length; rv++) {
      var hv = hiddenEls[rv];
      if (hv.style.display !== 'none') continue;
      var hvTxt = (hv.textContent || '').length;
      var hvImgs = hv.querySelectorAll ? hv.querySelectorAll('img').length : 0;
      var hvPrice = temuContainsPrice(hv);
      if (hvTxt > 600 || hvImgs >= 4 || hvPrice) {
        hv.style.removeProperty('display');
        hv.setAttribute('data-otlobli-blocked', '0'); // قائمة بيضاء — لن يُحجب ثانية
      }
    }
    // نحجب فقط ما يبدو فعلاً عرضاً ترويجياً (كلمات مميّزة) - لا نحجب أي طبقة
    // كبيرة عمياءً، فلا نخفي محتوى المتجر ولا صفحة "تحقق أنك إنسان" (الكابتشا)
    // فتصير الشاشة بيضاء. النص المحدود يستبعد شبكات المنتجات.
    var PROMO = /spin|claim|reward|coupon|billionaire|incredible deals|free gift|lucky draw|congratulations|% ?off|تهانينا|عجلة الحظ|اربح|جائزة|خصم \\d|الملياردير|مجاناً.*احصل|احصل.*مجاناً/i;
    var els = document.querySelectorAll('div, section, aside');
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.getAttribute && el.getAttribute('data-otlobli-blocked')) continue;
      if (temuContainsPrice(el)) continue;
      var cs = window.getComputedStyle(el);
      if (cs.position !== 'fixed' && cs.position !== 'absolute') continue;
      var z = parseInt(cs.zIndex, 10) || 0;
      if (z < 200) continue;
      var r = el.getBoundingClientRect();
      if (r.width < vp.width * 0.5 || r.height < vp.height * 0.3) continue;
      var txt = (el.textContent || '');
      if (txt.length > 400) continue;       // شبكات المحتوى نصّها طويل - نتجاهلها
      if (!PROMO.test(txt)) continue;        // لا بد أن يقرأ كعرض ترويجي
      // شيت خيارات المنتج (موديل/مقاس/لون/كمية/أضف): نصّه يحوي "خصم 65%"
      // فيطابق ملف الإعلانات ويُحجب تاركاً الخلفية المعتمة فقط — "شاشة عتمة"
      // عند فتح "حدد الموديل". كلمات الشيت المميزة تحصّنه نهائياً.
      if (/الكمية|موديل|المقاس|مقاس|اللون|أضف|السلة|حدد/.test(txt)) continue;
      // حرّاس محتوى المنتج: طبقة فيها سعر أو حقل إدخال أو ≥3 صور منتجات
      // ليست عرضاً ترويجياً بل صفحة/شيت حقيقي — ممنوع حجبها.
      if ((el.querySelector && el.querySelector('input, textarea')) || temuContainsPrice(el)) continue;
      var kwc = 0, kimgs = el.querySelectorAll ? el.querySelectorAll('img') : [];
      for (var ki = 0; ki < kimgs.length && kwc < 3; ki++) {
        if (/kwcdn/i.test(kimgs[ki].currentSrc || kimgs[ki].src || '')) kwc++;
      }
      if (kwc >= 3) continue;
      el.setAttribute('data-otlobli-blocked', '1');
      el.style.setProperty('display', 'none', 'important');
    }
    // العروض المنبثقة تقفل تمرير الصفحة عادةً - نعيد تمكينه
    if (document.body) document.body.style.overflow = '';
    if (document.documentElement) document.documentElement.style.overflow = '';
    // بانر تثبيت التطبيق الأصلي (Smart App Banner) إن وُجد
    var appMeta = document.querySelector('meta[name="apple-itunes-app"]');
    if (appMeta && appMeta.parentNode) appMeta.parentNode.removeChild(appMeta);

    // بانرات نصّية مزعجة — عربي وإنجليزي معاً
    hideStoreBannerByText([
      'billionaire', 'incredible deals', 'shop like', 'open in the app',
      'sign in for the best', 'get the app', 'download the app',
      'الملياردير', 'تسوق مثل', 'احصل على التطبيق', 'تنزيل التطبيق',
    ], 110);

    if (IS_TEMU) {
      // منع الزوم نهائياً (قرصة الأصابع + النقر المزدوج) — تجربة تطبيق أصلي.
      ensureTemuNoZoom();
      // شريط التنقل السفلي الخاص بتيمو (حسابي/السلة/طلباتي/الرئيسية) — نخفيه
      // ليبقى شريط otlobli هو الوحيد الظاهر في الأسفل.
      var hiddenBarDiag = [];
      var allEls = document.querySelectorAll('div, nav, footer, ul');
      for (var nb = 0; nb < allEls.length; nb++) {
        var nv = allEls[nb];
        if (nv.id && nv.id.indexOf('otlobli') === 0) continue;
        if (nv.getAttribute && nv.getAttribute('data-otlobli-blocked')) continue;
        var nvTxt = (nv.textContent || '');
        // نفحص أن يحتوي كلمات التنقل السفلي لتيمو ويكون نصّه قصيراً
        if (!/حسابي|طلباتي|الرئيسية/.test(nvTxt) || nvTxt.length > 60) continue;
        var nvCs = window.getComputedStyle(nv);
        if (nvCs.position !== 'fixed') continue;
        var nvR = nv.getBoundingClientRect();
        if (nvR.top < vp.height * 0.7) continue; // لا بد أن يكون في أسفل الشاشة
        nv.setAttribute('data-otlobli-blocked', '1');
        nv.style.setProperty('display', 'none', 'important');
        hiddenBarDiag.push('[' + nvTxt.replace(/\\s+/g, ' ').slice(0, 70) + ']');
      }
      // شارة "عربة التسوق / شحن مجاني" الخضراء العائمة
      hideStoreBannerByText(['عربة النسوق', 'شحن مجاني', 'عربة التسوق'], 25);
      var floatingCarts = document.querySelectorAll('[class*="float" i], [class*="cart-btn" i], [class*="shopping-cart" i]');
      for (var fc = 0; fc < floatingCarts.length; fc++) {
        var fcEl = floatingCarts[fc];
        if (fcEl.id && fcEl.id.indexOf('otlobli') === 0) continue;
        var fcR = fcEl.getBoundingClientRect();
        if (fcR.width < 40 || fcR.width > 120 || fcR.height < 40 || fcR.height > 120) continue;
        var fcCs = window.getComputedStyle(fcEl);
        if (fcCs.position !== 'fixed' && fcCs.position !== 'absolute') continue;
        fcEl.style.setProperty('display', 'none', 'important');
      }
      // أيقونات الحساب/السلة في رأس الصفحة (أعلى الشاشة) — نخفيها.
      // ثبت من تشخيص جهاز حقيقي: أيقونات تيمو غير دلالية إطلاقاً (أصناف
      // CSS معمّاة بلا معنى مثل "skeletonicon-39bt4" - بناء React بأصناف
      // مُولَّدة). أي مطابقة نصية/دلالية (aria-label/class/aria-selected)
      // عديمة الفائدة هنا بالكامل. الحل الوحيد الموثوق: **الموقع البصري**،
      // ثابت عبر كل الصفحات التي فحصناها: سلة/حساب/قائمة تتجمّع دائماً أقصى
      // يسار الهيدر (أول ~180px)، بينما شريط البحث أعرض بكثير ويبدأ لاحقاً.
      var hiddenIconDiag = [], visibleTopIconDiag = [];
      var LEFT_CLUSTER_MAX = 180;
      // حارس أداء: مسح كل div بالصفحة كل 120ms مكلف على صفحات تيمو الثقيلة
      // (شبكات منتجات ضخمة). نحدّه بـ~5 ثوانٍ بعد كل تنقّل صفحة فقط - كافٍ
      // لالتقاط الأيقونات حتى لو تأخر رندرها، بلا استمرار المسح للأبد.
      if (window.__otlobliIconScanUrl !== location.href) {
        window.__otlobliIconScanUrl = location.href;
        window.__otlobliIconScanAttempts = 0;
      }
      window.__otlobliIconScanAttempts = (window.__otlobliIconScanAttempts || 0) + 1;
      var rawTopBandCount = 0;
      if (window.__otlobliIconScanAttempts <= 40) {
        var headerIcons = document.querySelectorAll('a, button, [role="button"], div');
        for (var k = 0; k < headerIcons.length; k++) {
          var ic = headerIcons[k];
          if (ic.id && ic.id.indexOf('otlobli') === 0) continue;
          if (ic.getAttribute && ic.getAttribute('data-otlobli-blocked')) continue;
          if (ic.querySelector && ic.querySelector('input')) continue;
          var irAll = ic.getBoundingClientRect();
          // ثبت من تشخيص جهاز حقيقي: صفحات المنتج تلتقط الأيقونات صح ضمن
          // 90px الأولى (3 مخفية + 2 محمية بمواقع صحيحة)، لكن الصفحة
          // الرئيسية صفر أيقونات - هيدرها على الأرجح أسفل قليلاً بسبب شريط
          // ترويجي أطول. نطاق أوسع (0-140) يغطي الحالتين بأمان (لا يزال
          // يستبعد بطاقات المنتجات الكبيرة عبر شرط الحجم 24-60px).
          var inTopBand = irAll.top >= 0 && irAll.top <= 140 && irAll.width > 0 && irAll.width <= 60 && irAll.height > 0 && irAll.height <= 60;
          if (!inTopBand) continue;
          // أيقونات الهيدر بلا نص مقروء (صورة/رمز فقط) - يستبعد شارات نصية
          // صغيرة صدفةً بنفس القياس (ثبت من تشخيص حقيقي: عناصر "subtitle/
          // splitline" داخل بطاقات العروض الترويجية بالصفحة الرئيسية).
          if (temuCleanText(ic.textContent).length > 0) continue;
          rawTopBandCount++;
          // ثبت من تشخيص جهاز حقيقي (ثابت عبر 4 منتجات مختلفة): 5 من كل 6
          // مرشّح كانوا يُرفضون سابقاً لاشتراط svg/img — أغلب أيقونات تيمو
          // تُرسم بصورة خلفية CSS (background-image) لا بعنصر svg/img فعلي.
          // لا نشترط محتوى بصري إطلاقاً الآن — الحجم والموقع (مربّع 24-60px
          // بأعلى الشاشة) كافيان للتمييز بمفردهما.
          if (otlobliNearSearchInput(ic)) continue;
          if (otlobliLooksLikeSearchTrigger(ic)) continue;
          if (otlobliLooksLikeTemuLogo(ic)) continue;
          var inLeftCluster = irAll.left >= 0 && irAll.left <= LEFT_CLUSTER_MAX;
          if (!inLeftCluster && !otlobliLooksLikeKnownDistraction(ic)) {
            visibleTopIconDiag.push('[' + otlobliCollectIdentityHints(ic).trim().slice(0, 30) + ' @' + Math.round(irAll.left) + ',' + Math.round(irAll.top) + ']');
            continue;
          }
          ic.setAttribute('data-otlobli-blocked', '1');
          ic.style.setProperty('visibility', 'hidden', 'important');
          ic.style.setProperty('pointer-events', 'none', 'important');
          hiddenIconDiag.push('[' + otlobliCollectIdentityHints(ic).trim().slice(0, 30) + ' @' + Math.round(irAll.left) + ']');
        }
      }
      var rawStatsLine = 'مرشحون بالنطاق العلوي=' + rawTopBandCount;
      // تيمو تطبيق صفحة واحدة (SPA) - التنقل بين المنتجات لا يعيد تحميل
      // الجافاسكربت، فعلم "ظهرت مرة" وحده كان يمنع اللوحة من الظهور ثانية
      // عند دخول منتج جديد، فيرى المستخدم بيانات صفحة قديمة ويظنّها الحالية.
      // نربط العلم بالرابط الحالي بدل تعليقه للأبد.
      if (window.__otlobliHideDiagUrl !== location.href) {
        window.__otlobliHideDiagUrl = location.href;
      }
      // قسم "معلومات عن Temu / خدمة العملاء / مركز الدعم / حماية الشراء" أسفل
      // صفحة المنتج (أزرار أكورديون + أيقونات تواصل اجتماعي + حقوق نشر) —
      // بطلب صريح من المستخدم: يُحجب بالكامل، لا نُبقي أي خيار منه ظاهراً.
      hideTemuFooterSection();
    }
  }
  // يحجب كتلة تذييل تيمو (معلومات المتجر/الدعم/الشروط) بإيجاد أضيق حاوية
  // تحوي 3 كلمات دالة على الأقل — أضيق تطابق (لا أول عنصر بترتيب DOM، الذي
  // قد يكون سلفاً واسعاً يبتلع الصفحة كلها لأن textContent تراكمي للأعلى).
  function hideTemuFooterSection() {
    var markers = ['whaleco', 'معلومات عن temu', 'مركز الدعم', 'خدمة العملاء', 'حماية الشراء'];
    var nodes = document.querySelectorAll('div, section, footer');
    var best = null, bestLen = Infinity;
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.getAttribute && el.getAttribute('data-otlobli-blocked')) continue;
      var txt = (el.textContent || '').toLowerCase();
      if (txt.length < 80) continue;
      var matches = 0;
      for (var m = 0; m < markers.length; m++) { if (txt.indexOf(markers[m]) >= 0) matches++; }
      if (matches < 3) continue;
      // حرّاس أمان: لا نحجب حاوية فيها بحث فعلي أو سعر منتج حقيقي.
      if ((el.querySelector && el.querySelector('input:not([type="hidden"])')) || temuContainsPrice(el)) continue;
      if (txt.length < bestLen) { best = el; bestLen = txt.length; }
    }
    if (best) {
      best.setAttribute('data-otlobli-blocked', '1');
      best.style.setProperty('display', 'none', 'important');
    }
  }
  // لوحة تشخيص مرئية (مرة واحدة لكل صفحة) تُظهر بالضبط ماذا أُخفي وماذا
  // بقي ظاهراً في نطاق الهيدر — بدل التخمين الأعمى لمكان زر البحث.
  function otlobliShowHideDiagnostics(bars, hiddenIcons, visibleIcons, rawStats) {
    if (document.getElementById('otlobli-hide-diag')) return;
    var panel = document.createElement('div');
    panel.id = 'otlobli-hide-diag';
    panel.style.cssText = 'position:fixed;left:8px;right:8px;bottom:140px;z-index:2147483647;' +
      'background:#fff3cd;color:#7a5b00;border:1px solid #ffe28a;border-radius:10px;padding:8px 10px;' +
      'font-size:10px;direction:rtl;text-align:right;max-height:220px;overflow:auto;white-space:pre-wrap;';
    var lines = [];
    if (rawStats) lines.push(rawStats);
    lines.push('أشرطة سفلية مخفية (' + bars.length + '):');
    for (var i = 0; i < bars.length && i < 3; i++) lines.push(bars[i]);
    lines.push('أيقونات هيدر مخفية (' + hiddenIcons.length + '):');
    for (var j = 0; j < hiddenIcons.length && j < 6; j++) lines.push(hiddenIcons[j]);
    lines.push('أيقونات هيدر ظاهرة (' + visibleIcons.length + '):');
    for (var m = 0; m < visibleIcons.length && m < 6; m++) lines.push(visibleIcons[m]);
    panel.textContent = lines.join('\\n');
    document.body.appendChild(panel);
    setTimeout(function () { var p = document.getElementById('otlobli-hide-diag'); if (p) p.remove(); }, 20000);
  }

  // يخفي حاوية بانر نصّي على المتاجر غير شي إن بمطابقة عبارة قصيرة مميّزة،
  // ثم يصعد لأقرب حاوية عريضة (لكن ليست الصفحة كلها) ويخفيها.
  function hideStoreBannerByText(phrases, maxLen) {
    var vp = viewportSize();
    // حاوية تضم شريط البحث أو محتوى منتجات حقيقياً؟ لا يجوز إخفاؤها أبداً —
    // التسلّق كان يبتلع هيدر تيمو (البانر والبحث معاً) فيختفي البحث، وقد
    // يبتلع حاوية صفحة كاملة أثناء الرندر فتصير الشاشة بيضاء.
    function containsSearch(n) {
      if (!n || !n.querySelector) return false;
      if (n.querySelector('input:not([type="hidden"])')
        || n.querySelector('[class*="search" i]')
        || n.querySelector('[aria-label*="بحث"], [aria-label*="search" i]')
        || temuContainsPrice(n)) return true;
      var pImgs = n.querySelectorAll('img'), pk = 0;
      for (var pi = 0; pi < pImgs.length && pk < 3; pi++) {
        if (/kwcdn/i.test(pImgs[pi].currentSrc || pImgs[pi].src || '')) pk++;
      }
      return pk >= 3;
    }
    var nodes = document.querySelectorAll('div, section, aside, a, p, span');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.getAttribute && el.getAttribute('data-otlobli-blocked')) continue;
      var txt = (el.textContent || '');
      if (!txt || txt.length > maxLen) continue;
      var low = txt.toLowerCase();
      var hit = false;
      for (var p = 0; p < phrases.length; p++) { if (low.indexOf(phrases[p]) >= 0) { hit = true; break; } }
      if (!hit) continue;
      var target = el;
      var up = el.parentElement;
      var hops = 0;
      while (up && hops < 3) {
        if (containsSearch(up)) break; // توقّف قبل ابتلاع حاوية البحث
        var ur = up.getBoundingClientRect();
        if (ur.width >= vp.width * 0.5 && ur.height < vp.height * 0.35) target = up;
        up = up.parentElement; hops++;
      }
      if (containsSearch(target)) target = el; // أمان إضافي: نخفي البانر نفسه فقط
      target.setAttribute('data-otlobli-blocked', '1');
      target.style.setProperty('display', 'none', 'important');
    }
  }

  function hideSheinAppInstallPrompts() {
    if (!IS_SHEIN) return;
    var vp = viewportSize();
    var APP_RE = /(get\\s*(the\\s*)?app|open\\s*in\\s*(the\\s*)?app|download\\s*(the\\s*)?app|install\\s*(the\\s*)?app|app\\s*exclusive|\\u0627\\u062d\\u0635\\u0644|\\u062a\\u0637\\u0628\\u064a\\u0642|\\u062a\\u0646\\u0632\\u064a\\u0644)/i;
    // Never scan login/sign-in/dialog surfaces here. The previous broad scan
    // could remove the phone/email input while leaving SHEIN's Continue button,
    // producing the blank, non-working screen observed on the device.
    var nodes = document.querySelectorAll('div, section, aside, header, a, [role="banner"], [class*="app" i]');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (!el || el === document.body || el === document.documentElement) continue;
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.getAttribute && el.getAttribute('data-otlobli-blocked')) continue;
      var txt = (el.textContent || '').replace(/\\s+/g, ' ').trim();
      var hint = ((el.className || '') + ' ' + (el.id || '') + ' ' + txt).toString();
      if (!txt && !/app/i.test(hint)) continue;
      if (txt.length > 520) continue;
      var r = el.getBoundingClientRect();
      if (!r || r.width < 40 || r.height < 24) continue;
      var isTopAppBanner = r.top > -20 && r.top < 190 && r.width > vp.width * 0.55 && r.height < 180 && APP_RE.test(hint);
      if (!isTopAppBanner) continue;
      if (el.querySelector && el.querySelector('form, input, textarea')) continue;
      var target = el;
      var up = el.parentElement;
      var hops = 0;
      while (up && up !== document.body && up !== document.documentElement && hops < 3) {
        var ur = up.getBoundingClientRect();
        var ut = (up.textContent || '').replace(/\\s+/g, ' ').trim();
        if (ut.length > 650) break;
        if (ur.top > -25 && ur.top < 190 && ur.width > vp.width * 0.65 && ur.height < 190) target = up;
        up = up.parentElement;
        hops++;
      }
      target.setAttribute('data-otlobli-blocked', '1');
      target.style.setProperty('display', 'none', 'important');
      target.style.setProperty('visibility', 'hidden', 'important');
      target.style.setProperty('pointer-events', 'none', 'important');
    }
    if (document.body) document.body.style.overflow = '';
    if (document.documentElement) document.documentElement.style.overflow = '';
  }

  function hideTemuSpinWheelPopup() {
    if (!IS_TEMU) return;
    var vp = viewportSize();
    var WHEEL_RE = /(spin|wheel|reward|claim|coupon|lucky|chance|prize|free\\s*gift|congratulations|SAR\\s*\\d|\\u062d\\u0631\\u0651?\\u0643|\\u0641\\u0631\\u0635\\u0629|\\u062c\\u0631\\u0628|\\u062a\\u062d\\u0635\\u0644|\\u062c\\u0627\\u0626\\u0632\\u0629|\\u0645\\u062c\\u0627\\u0646\\u064a|\\u062e\\u0635\\u0645)/i;
    var nodes = document.querySelectorAll('div, section, aside, [role="dialog"], [class*="popup" i], [class*="modal" i], [class*="wheel" i], [class*="spin" i]');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (!el || el === document.body || el === document.documentElement) continue;
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.getAttribute && el.getAttribute('data-otlobli-blocked')) continue;
      var r = el.getBoundingClientRect();
      if (!r || r.width < vp.width * 0.45 || r.height < vp.height * 0.16) continue;
      var cs = window.getComputedStyle(el);
      var positioned = cs.position === 'fixed' || cs.position === 'absolute' || cs.position === 'sticky';
      var z = parseInt(cs.zIndex, 10) || 0;
      if (!positioned && z < 20) continue;
      var txt = (el.textContent || '').replace(/\\s+/g, ' ').trim();
      var hint = ((el.className || '') + ' ' + (el.id || '') + ' ' + txt).toString();
      if (txt.length > 900) continue;
      if (!WHEEL_RE.test(hint)) continue;
      if (el.querySelector && el.querySelector('input:not([type="hidden"]), textarea')) continue;
      var target = el;
      var up = el.parentElement;
      var hops = 0;
      while (up && up !== document.body && up !== document.documentElement && hops < 3) {
        var ur = up.getBoundingClientRect();
        var ucs = window.getComputedStyle(up);
        var ut = (up.textContent || '').replace(/\\s+/g, ' ').trim();
        if (ut.length > 1100) break;
        if ((ucs.position === 'fixed' || ucs.position === 'absolute') && ur.width > vp.width * 0.55 && ur.height > vp.height * 0.22 && ur.height < vp.height * 0.95) target = up;
        up = up.parentElement;
        hops++;
      }
      target.setAttribute('data-otlobli-blocked', '1');
      target.style.setProperty('display', 'none', 'important');
      target.style.setProperty('visibility', 'hidden', 'important');
      target.style.setProperty('pointer-events', 'none', 'important');
    }
    if (document.body) document.body.style.overflow = '';
    if (document.documentElement) document.documentElement.style.overflow = '';
  }


  // Kept tight on purpose - every visible millisecond here is a window where
  // a SHEIN button/icon that's supposed to be hidden or blocked is instead
  // tappable, which is exactly the "nothing should ever be reachable, not
  // even briefly" requirement this whole hide/block system exists for.
  var tickScheduled = false;
  // On low-end devices (iPhone 6 etc. — 2 CPU cores) our own polling competes
  // with Cloudflare's verification JS and SHEIN's image decoding, making a
  // weak-CPU device feel heavy and slow. Relax every hot interval there so the
  // device spends its cycles rendering / passing the challenge instead of on
  // our scans. Modern devices (iPhone 16) keep the original tight timings.
  var OTLOBLI_LOW_END = (typeof navigator !== 'undefined' && (navigator.hardwareConcurrency || 4) <= 2);
  function scheduleTick() {
    sheinBlockReported = false;
    // Don't storm-tick on every Cloudflare DOM mutation during the challenge;
    // the 300ms interval still polls tick() to detect when it ends.
    if (otlobliChallengeActive) return;
    if (tickScheduled) return;
    tickScheduled = true;
    setTimeout(function () {
      tickScheduled = false;
      tick();
    }, OTLOBLI_LOW_END ? 160 : 80);
  }

  var originalPushState = history.pushState;
  history.pushState = function () {
    var result = originalPushState.apply(this, arguments);
    scheduleTick();
    return result;
  };
  var originalReplaceState = history.replaceState;
  history.replaceState = function () {
    var result = originalReplaceState.apply(this, arguments);
    scheduleTick();
    return result;
  };
  window.addEventListener('popstate', scheduleTick);

  // document.body observe(document.body, ...) here used to throw outright
  // at this documentStart injection timing - the parser hasn't necessarily
  // reached <body> yet, so it's still null. Confirmed via the actual error
  // in chromium's console log: "Failed to execute 'observe' on
  // 'MutationObserver': parameter 1 is not of type 'Node'." With nothing
  // catching it, that exception HALTED THE ENTIRE SCRIPT right here - every
  // line after it (both setInterval(tick, ...) calls, the block-detector,
  // the very first tick()) silently never ran for the rest of that page
  // load, no matter how long the page lived. This is the real explanation
  // behind today's whole grab-bag of "sometimes works, sometimes doesn't"
  // symptoms (cart tab, nav position, block detection) - they're all code
  // inside tick()/the intervals below, which this exception was randomly
  // skipping depending only on how fast the page happened to parse relative
  // to when this line ran. document.documentElement (<html>) - unlike body -
  // is guaranteed to exist this early, and observing it with subtree:true
  // covers body and everything under it once they do appear.
  // Do not run geometry/text scans from MutationObserver. SHEIN mutates the
  // product DOM continuously; doing layout work before every paint starves
  // older WKWebView devices and delays image decoding. The coalesced tick owns
  // all inspections at their explicit throttled intervals.
  var observer = new MutationObserver(scheduleTick);
  observer.observe(document.documentElement, { childList: true, subtree: true });

  setInterval(tick, OTLOBLI_LOW_END ? 450 : 300);
  // hideKnownHeaderIconsByHint specifically needs to win what looks like an
  // ongoing fight against SHEIN periodically re-rendering its own header (a
  // user found the hamburger/wishlist icons could stay reachable for
  // several minutes on the home page even though the same code hid them
  // instantly elsewhere) - run it on its own much tighter interval so any
  // freshly re-created icon gets caught within ~120ms instead of waiting
  // for the next general tick.
  setInterval(function () {
    if (otlobliChallengeActive || !IS_SHEIN) return;
    hideKnownHeaderIconsByHint();
    hideSheinHeaderControls();
    hideListingCardAddButtons();
  }, OTLOBLI_LOW_END ? 240 : 120);
  setInterval(function () {
    ensureOtlobliNav();
    if (IS_TEMU) {
      injectTemuHeaderHideCSS();
      stabilizeTemuSearchChrome();
      restoreTemuSearchChrome();
      restoreTemuLogo();
    }
  }, OTLOBLI_LOW_END ? 240 : 120);
  // Own slower interval, not part of tick() - see checkForSheinSecurityBlock's
  // comment on why innerText needs to stay off the 300ms timer. خاص بشي إن فقط.
  setInterval(function () { if (IS_SHEIN) checkForSheinSecurityBlock(); }, 1000);
  tick();
})();
`
