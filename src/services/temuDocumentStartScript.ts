// This is the only Temu policy allowed to run at Android document-start. Keep
// it small and selector-driven: the full capture/runtime remains post-load and
// owns every semantic or geometry-based scan.
export const TEMU_DOCUMENT_START_CSS =
  '[class*="downloadUI" i],[class*="openApp" i],' +
  '[class*="topTabContainer"] [class*="tab-"],' +
  '[aria-label*="cart" i]:not([id^="otlobli"]),[aria-label*="basket" i]:not([id^="otlobli"]),' +
  '[aria-label*="shopping bag" i]:not([id^="otlobli"]),' +
  '[aria-label*="account" i]:not([id^="otlobli"]),[aria-label*="profile" i]:not([id^="otlobli"]),' +
  '[aria-label*="sign in" i]:not([id^="otlobli"]),' +
  '[aria-label*="\u0633\u0644\u0629"]:not([id^="otlobli"]),' +
  '[aria-label*="\u0639\u0631\u0628\u0629 \u0627\u0644\u062a\u0633\u0648\u0642"]:not([id^="otlobli"]),' +
  '[aria-label*="\u062d\u0633\u0627\u0628"]:not([id^="otlobli"]),' +
  '[aria-label*="\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644"]:not([id^="otlobli"]),' +
  'a[href*="/cart" i],a[href*="/basket" i],a[href*="/login" i],a[href*="/signin" i],' +
  'a[href*="/account" i],a[href*="/profile" i],' +
  // This is Temu's observed page-level sticky product row. Do not add generic
  // add-to-cart button selectors here: the real SKU dialog must keep its own
  // confirmation action. The post-load bounded cleaner handles layout variants.
  '#id-shopping-bar,button[class*="signInBtn-" i]' +
  '{display:none!important;visibility:hidden!important;opacity:0!important;pointer-events:none!important;}'

export const TEMU_DOCUMENT_START_SCRIPT = `
(function () {
  if (window.top !== window || !/(^|\\.)temu\\.com$/i.test(location.hostname || '')) return;
  if (/\\/(?:cdn-cgi|challenge|captcha|verify|verification|bgn[_-]?verification|security|robot|risk|anti[-_]?bot|human)(?:[/?#.-]|$)/i.test(location.pathname || '') ||
      /(?:^|[?&#])(?:captcha|challenge|verification|bgn[_-]?verification|security_token|risk|robot|anti[-_]?bot|human)=/i.test((location.search || '') + (location.hash || ''))) return;
  if (window.__otlobliTemuDocumentStartInstalled) return;
  window.__otlobliTemuDocumentStartInstalled = true;

  var STYLE_ID = 'otlobli-temu-document-start-style';
  var HIDE_CSS = ${JSON.stringify(TEMU_DOCUMENT_START_CSS)};
  var cookieDone = false;
  var cookieAttempts = 0;
  var cookiePending = false;
  var cookieDelays = [0, 60, 160, 360, 700, 1200, 2000, 3500, 6000, 10000];
  var acceptPattern = /^(?:accept all(?: cookies?)?|allow all(?: cookies?)?|agree to all|\\u0642\\u0628\\u0648\\u0644 (?:\\u0627\\u0644\\u0643\\u0644|\\u0627\\u0644\\u062c\\u0645\\u064a\\u0639)|\\u0627\\u0642\\u0628\\u0644 (?:\\u0627\\u0644\\u0643\\u0644|\\u0627\\u0644\\u062c\\u0645\\u064a\\u0639)|\\u0627\\u0644\\u0633\\u0645\\u0627\\u062d (?:\\u0644\\u0644\\u0643\\u0644|\\u0644\\u0644\\u062c\\u0645\\u064a\\u0639)|\\u0645\\u0648\\u0627\\u0641\\u0642 \\u0639\\u0644\\u0649 \\u0627\\u0644\\u0643\\u0644|\\u0627\\u0644\\u0645\\u0648\\u0627\\u0641\\u0642\\u0629 \\u0639\\u0644\\u0649 \\u0627\\u0644\\u0643\\u0644)$/i;
  var cookiePattern = /cookies?|cookie policy|\\u0645\\u0644\\u0641\\u0627\\u062a \\u062a\\u0639\\u0631\\u064a\\u0641 \\u0627\\u0644\\u0627\\u0631\\u062a\\u0628\\u0627\\u0637|\\u062a\\u0642\\u0646\\u064a\\u0627\\u062a \\u0645\\u0645\\u0627\\u062b\\u0644\\u0629/i;
  var blockedActionPattern = /^(?:cart|shopping cart|basket|shopping bag|bag|account|my account|profile|sign\\s*in|log\\s*in|login|\\u0633\\u0644\\u0629(?: \\u0627\\u0644\\u062a\\u0633\\u0648\\u0642)?|\\u0639\\u0631\\u0628\\u0629 \\u0627\\u0644\\u062a\\u0633\\u0648\\u0642|\\u062d\\u0633\\u0627\\u0628(?:\\u064a)?|\\u062a\\u0633\\u062c\\u064a\\u0644 \\u0627\\u0644\\u062f\\u062e\\u0648\\u0644)(?:\\s*[(:]?\\s*\\d+\\s*(?:items?|\\u0639\\u0646\\u0627\\u0635\\u0631)?\\s*\\)?)?$/i;
  var productActionPattern = /^(?:add\\s+to\\s+(?:cart|bag)|buy\\s+now|select\\s+(?:an?\\s+)?options?|choose\\s+options?|\\u0623\\u0636\\u0641 \\u0625\\u0644\\u0649 \\u0627\\u0644\\u0633\\u0644\\u0629|\\u062d\\u062f\\u062f \\u062e\\u064a\\u0627\\u0631(?:\\u0627\\u064b|\\u0627)?|\\u0627\\u062e\\u062a\\u0631 \\u062e\\u064a\\u0627\\u0631(?:\\u0627\\u064b|\\u0627)?|\\u0627\\u0634\\u062a\\u0631 \\u0627\\u0644\\u0622\\u0646)$/i;

  function cleanText(value) {
    return String(value || '')
      .replace(/[\\u200e\\u200f\\u061c\\u202a-\\u202e]/g, '')
      .replace(/\\s+/g, ' ')
      .trim();
  }

  function challengeUrl() {
    return /\\/(?:cdn-cgi|challenge|captcha|verify|verification|bgn[_-]?verification|security|robot|risk|anti[-_]?bot|human)(?:[/?#.-]|$)/i.test(location.pathname || '') ||
      /(?:^|[?&#])(?:captcha|challenge|verification|bgn[_-]?verification|security_token|risk|robot|anti[-_]?bot|human)=/i.test((location.search || '') + (location.hash || ''));
  }

  function challengeVisible() {
    if (challengeUrl()) return true;
    try {
      var nodes = document.querySelectorAll(
        '#challenge-form,iframe[title*="challenge" i],iframe[title*="verification" i],' +
        '#one-pass-custom,one-pass-custom,#nine-captcha-custom,nine-captcha-custom,' +
        '[class*="captcha" i],[class*="bgn-verification" i],[class*="security-verification" i]'
      );
      var viewportWidth = window.innerWidth || (document.documentElement && document.documentElement.clientWidth) || 0;
      var viewportHeight = window.innerHeight || (document.documentElement && document.documentElement.clientHeight) || 0;
      for (var i = Math.max(0, nodes.length - 12); i < nodes.length; i++) {
        var rect = nodes[i].getBoundingClientRect ? nodes[i].getBoundingClientRect() : null;
        if (!rect || rect.width <= 4 || rect.height <= 4 || rect.right <= 0 || rect.bottom <= 0 ||
            (viewportWidth > 0 && rect.left >= viewportWidth) || (viewportHeight > 0 && rect.top >= viewportHeight)) continue;
        var style = window.getComputedStyle ? window.getComputedStyle(nodes[i]) : null;
        if (style && (style.display === 'none' || style.visibility === 'hidden' ||
            style.visibility === 'collapse' || Number(style.opacity || 1) <= 0.01)) continue;
        return true;
      }
    } catch (e) {}
    return false;
  }

  function paused() {
    return window.__otlobliTemuDocumentStartPaused === true || challengeVisible();
  }

  function installStyle() {
    if (paused() || document.getElementById(STYLE_ID)) return;
    var parent = document.head || document.documentElement;
    if (!parent) return;
    var style = document.createElement('style');
    style.id = STYLE_ID;
    style.textContent = HIDE_CSS;
    parent.appendChild(style);
  }
  window.__otlobliInstallTemuDocumentStartGuard = installStyle;
  installStyle();
  try { document.addEventListener('DOMContentLoaded', installStyle, { once: true }); } catch (e) {}

  function insideSkuDialog(node) {
    if (!node || !node.closest) return false;
    var dialog = node.closest('[role="dialog"],[aria-modal="true"],[class*="sku" i],[class*="option" i],[class*="drawer" i]');
    if (!dialog) return false;
    var text = cleanText(dialog.textContent).slice(0, 800);
    return /(?:size|color|quantity|select option|choose option|\\u0645\\u0642\\u0627\\u0633|\\u0627\\u0644\\u0644\\u0648\\u0646|\\u0627\\u0644\\u0643\\u0645\\u064a\\u0629|\\u062d\\u062f\\u062f \\u062e\\u064a\\u0627\\u0631)/i.test(text);
  }

  function blockedHref(control) {
    var href = control && control.getAttribute ? control.getAttribute('href') : '';
    if (!href) return false;
    try {
      var target = new URL(href, location.href);
      if (!/(^|\\.)temu\\.com$/i.test(target.hostname || '')) return false;
      var route = (target.pathname || '') + ' ' + (target.hash || '');
      var tokens = route.toLowerCase().split(/[^a-z0-9]+/);
      for (var i = 0; i < tokens.length; i++) {
        if (/^(?:cart|basket|checkout|payment|account|profile|login|signin|member|orders?)$/.test(tokens[i] || '')) return true;
      }
    } catch (e) {}
    return false;
  }

  document.addEventListener('click', function (event) {
    if (paused()) return;
    var control = event.target && event.target.closest
      ? event.target.closest('a,button,[role="button"]')
      : null;
    if (!control || (control.id && control.id.indexOf('otlobli') === 0) ||
        (control.closest && control.closest('[id^="otlobli"]')) || insideSkuDialog(control)) return;
    var label = cleanText(
      (control.getAttribute && (control.getAttribute('aria-label') || control.getAttribute('title'))) ||
      ((control.childElementCount || 0) <= 6 ? control.textContent : '')
    ).slice(0, 120);
    var observedProductBar = !!(control.closest && control.closest('#id-shopping-bar'));
    if (!blockedHref(control) && !blockedActionPattern.test(label) &&
        !(observedProductBar && productActionPattern.test(label))) return;
    event.preventDefault();
    if (event.stopImmediatePropagation) event.stopImmediatePropagation();
    event.stopPropagation();
  }, true);

  function cookieControlLabel(control) {
    return cleanText(
      (control.getAttribute && control.getAttribute('aria-label')) ||
      control.value || control.textContent || ''
    );
  }

  function cookieScopeFor(control, boundary) {
    var current = control;
    for (var hop = 0; current && hop < 8; hop++, current = current.parentElement) {
      if (current === document.body || current === document.documentElement) break;
      var text = cleanText(current.textContent);
      var hints = current.getAttribute
        ? cleanText((current.id || '') + ' ' + (current.className || '') + ' ' +
          (current.getAttribute('role') || '') + ' ' + (current.getAttribute('aria-label') || '') + ' ' +
          (current.getAttribute('data-testid') || ''))
        : '';
      var semanticScope = /cookie|consent|privacy|onetrust|cybot|dialog|alertdialog/i.test(hints);
      if (current.style && text.length > 0 && text.length <= 5000 && cookiePattern.test(text) &&
          (semanticScope || current === boundary)) return current;
      if (current === boundary) break;
    }
    return null;
  }

  function cookieMatch(control, boundary) {
    if (!control) return null;
    var label = cookieControlLabel(control);
    if (!label || label.length > 48 || !acceptPattern.test(label)) return null;
    var scope = cookieScopeFor(control, boundary);
    return scope ? { control: control, scope: scope } : null;
  }

  function findCookieAction() {
    // Prefer provider-standard exact hooks, then inspect only bounded consent
    // roots. Never enumerate every button/link in a large product document.
    var direct = document.querySelectorAll(
      '#onetrust-accept-btn-handler,#CybotCookiebotDialogBodyLevelButtonLevelOptinAllowAll,' +
      '[data-testid*="accept-all" i],[data-testid*="acceptAll" i],' +
      'button[aria-label="Accept all" i],[role="button"][aria-label="Accept all" i]'
    );
    for (var di = 0; di < direct.length && di < 12; di++) {
      var directMatch = cookieMatch(direct[di]);
      if (directMatch) return directMatch;
    }
    var roots = document.querySelectorAll(
      '#onetrust-banner-sdk,#CybotCookiebotDialog,' +
      '[id*="cookie" i],[class*="cookie-banner" i],[class*="cookie-consent" i],' +
      '[data-testid*="cookie" i],[aria-label*="cookie" i],' +
      '[role="dialog"],[role="alertdialog"],dialog'
    );
    for (var ri = 0; ri < roots.length && ri < 16; ri++) {
      var rootText = cleanText(roots[ri].textContent);
      if (!rootText || rootText.length > 5000 || !cookiePattern.test(rootText)) continue;
      var controls = roots[ri].querySelectorAll
        ? roots[ri].querySelectorAll('button,[role="button"],a,input[type="button"],input[type="submit"]')
        : [];
      for (var ci = 0; ci < controls.length && ci < 32; ci++) {
        var scopedMatch = cookieMatch(controls[ci], roots[ri]);
        if (scopedMatch) return scopedMatch;
      }
    }
    return null;
  }

  function cookieNodeAttached(node) {
    return !!(node && document.documentElement && document.documentElement.contains(node));
  }

  function restoreCookieScope(scope, original) {
    if (!cookieNodeAttached(scope) || !scope.style) return;
    for (var i = 0; i < original.length; i++) {
      if (original[i][1]) scope.style.setProperty(original[i][0], original[i][1], original[i][2]);
      else scope.style.removeProperty(original[i][0]);
    }
    scope.removeAttribute('data-otlobli-temu-cookie-pending');
  }

  function activateCookieAction(match) {
    cookiePending = true;
    cookieAttempts++;
    var scope = match.scope;
    var original = ['opacity', 'visibility', 'pointer-events'].map(function (name) {
      return [name, scope.style.getPropertyValue(name), scope.style.getPropertyPriority(name)];
    });
    scope.setAttribute('data-otlobli-temu-cookie-pending', '1');
    scope.style.setProperty('opacity', '0', 'important');
    scope.style.setProperty('visibility', 'hidden', 'important');
    scope.style.setProperty('pointer-events', 'none', 'important');
    try { match.control.click(); } catch (e) {}
    setTimeout(function () {
      if (!paused() && cookieNodeAttached(match.control)) {
        try { match.control.click(); } catch (e) {}
      }
    }, 80);
    setTimeout(function () {
      cookiePending = false;
      if (!cookieNodeAttached(scope)) {
        cookieDone = true;
        if (document.documentElement) document.documentElement.setAttribute('data-otlobli-temu-cookie-auto-accepted', '1');
        return;
      }
      restoreCookieScope(scope, original);
    }, 450);
  }

  function scanCookieConsent() {
    if (cookieDone || cookiePending || cookieAttempts >= 3 || paused() || !document.documentElement) return;
    var match = findCookieAction();
    if (match) activateCookieAction(match);
  }

  for (var i = 0; i < cookieDelays.length; i++) setTimeout(scanCookieConsent, cookieDelays[i]);
  try { document.addEventListener('DOMContentLoaded', scanCookieConsent, { once: true }); } catch (e) {}
  try { addEventListener('pageshow', scanCookieConsent, false); } catch (e) {}
})();
`
