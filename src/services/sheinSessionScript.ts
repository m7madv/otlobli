import {
  OTLOBLI_NAV_CSS,
  OTLOBLI_NAV_STYLE_VERSION,
  OTLOBLI_NAV_TOUCH_BRIDGE_JS,
  OTLOBLI_SHEIN_BASE_CSS,
} from './sheinNavigationScript'

export const SHEIN_SESSION_SCRIPT = `
  var OTLOBLI_NAV_CSS = ${JSON.stringify(OTLOBLI_NAV_CSS)};
  var OTLOBLI_NAV_STYLE_VERSION = ${JSON.stringify(OTLOBLI_NAV_STYLE_VERSION)};

  ${OTLOBLI_NAV_TOUCH_BRIDGE_JS}

  function ensureOtlobliBaseStyle() {
    var parent = document.head || document.documentElement;
    if (!parent) return false;
    if (document.getElementById('otlobli-base-style')) return true;
    var fontStyle = document.createElement('style');
    fontStyle.id = 'otlobli-base-style';
    fontStyle.textContent = ${JSON.stringify(OTLOBLI_SHEIN_BASE_CSS)};
    parent.appendChild(fontStyle);
    return true;
  }
  if (otlobliScriptEnabled('blocking')) ensureOtlobliBaseStyle();

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
  if (otlobliScriptEnabled('navigation')) ensureViewportFitCover();

  // هل نحن داخل أحد مواقع شي إن؟ منطق الالتقاط/الحجب الخاص بشي إن يعمل فقط
  // عندها؛ على المتاجر الأخرى (تيمو/ترينديول) نكتفي بتنظيف العروض المنبثقة.
  var IS_SHEIN = /shein/i.test(location.hostname);
  var IS_TEMU = /temu/i.test(location.hostname);

  var OTLOBLI_STORE_REGIONS = window.__OTLOBLI_STORE_REGIONS__ || {};
  var OTLOBLI_SHEIN_REGION = OTLOBLI_STORE_REGIONS.shein || {};
  var OTLOBLI_TEMU_REGION = OTLOBLI_STORE_REGIONS.temu || {};
  var SHEIN_REQUIRED_COUNTRY = /^[A-Z]{2}$/.test(String(OTLOBLI_SHEIN_REGION.countryCode || '').toUpperCase())
    ? String(OTLOBLI_SHEIN_REGION.countryCode).toUpperCase()
    : 'SA';
  var SHEIN_REQUIRED_ADDRESS_PATH = Array.isArray(OTLOBLI_SHEIN_REGION.addressPath)
    ? OTLOBLI_SHEIN_REGION.addressPath.map(function (part) {
        return String(part || '').replace(/\\s+/g, ' ').trim();
      }).filter(Boolean).slice(0, 4)
    : [];
  var SHEIN_SUPPORTED_COUNTRY_NAMES = {
    JO: ['Jordan', 'الأردن'],
    SA: ['Saudi Arabia', 'السعودية', 'المملكة العربية السعودية'],
    AE: ['United Arab Emirates', 'UAE', 'الإمارات', 'الإمارات العربية المتحدة'],
    BH: ['Bahrain', 'البحرين'],
    KW: ['Kuwait', 'الكويت'],
    LB: ['Lebanon', 'لبنان'],
    OM: ['Oman', 'عمان', 'عُمان'],
    QA: ['Qatar', 'قطر']
  };
  // Currency and language come from the same validated administration setting
  // as country/address. The production app-settings function currently accepts
  // only USD/ar, but keeping one authoritative object prevents host/script drift.
  var SHEIN_REQUIRED_CURRENCY_CANDIDATE = String(OTLOBLI_SHEIN_REGION.currency || 'USD').toUpperCase();
  var SHEIN_REQUIRED_LANGUAGE_CANDIDATE = String(OTLOBLI_SHEIN_REGION.language || 'ar').toLowerCase();
  var SHEIN_REQUIRED_CURRENCY = ['USD'].indexOf(SHEIN_REQUIRED_CURRENCY_CANDIDATE) >= 0
    ? SHEIN_REQUIRED_CURRENCY_CANDIDATE : 'USD';
  var SHEIN_REQUIRED_LANGUAGE = ['ar'].indexOf(SHEIN_REQUIRED_LANGUAGE_CANDIDATE) >= 0
    ? SHEIN_REQUIRED_LANGUAGE_CANDIDATE : 'ar';
  var SHEIN_REQUIRED_SITE_UID = 'pwar';
  var SHEIN_CHALLENGE_PATH_RE = /\\/(?:cdn-cgi|challenge|captcha|verify|verification|security|robot|risk|anti[-_]?bot|human)(?:\\/|$)/i;
  var SHEIN_CHALLENGE_QUERY_RE = /(?:^|[?&#])(?:captcha|challenge|verification|security_token|risk|robot|anti[-_]?bot|human)=/i;
  var TEMU_REQUIRED_COUNTRY = /^[A-Z]{2}$/.test(String(OTLOBLI_TEMU_REGION.countryCode || '').toUpperCase())
    ? String(OTLOBLI_TEMU_REGION.countryCode).toUpperCase()
    : 'SA';
  var TEMU_REQUIRED_CURRENCY = 'USD';

  // Temu owns its currency/country storage. Writing those keys from an
  // injected script now trips its storage registry and invalidates the guest
  // product session (integration/render returns NEED_LOGIN). The /sa/ URL and
  // native region guard are the only source of region truth here.

  function otlobliEnsureChallengeNav() {
    if (!document.body) return false;
    var nav = document.getElementById('otlobli-nav');
    if (!nav) {
      nav = document.createElement('div');
      nav.id = 'otlobli-nav';
      nav.setAttribute('data-otlobli-challenge-nav', '1');
      var items = [
        {label:'\\u0627\\u0644\\u0631\\u0626\\u064a\\u0633\\u064a\\u0629',icon:'home',type:'openHome'},
        {label:'\\u0637\\u0644\\u0628\\u0627\\u062a\\u064a',icon:'orders',type:'openOrders'},
        {label:'\\u0627\\u0644\\u0633\\u0644\\u0629',icon:'cart',type:'openCart'},
        {label:'\\u062d\\u0633\\u0627\\u0628\\u064a',icon:'profile',type:'openProfile'},
      ];
      for (var ni = 0; ni < items.length; ni++) {
        var item = items[ni];
        var tab = document.createElement('button');
        tab.id = 'otlobli-nav-tab-' + ni;
        tab.textContent = item.label;
        tab.style.cssText = 'position:relative!important;flex:1 1 0!important;height:74px!important;min-height:74px!important;max-height:74px!important;' +
          'border:0!important;background:transparent!important;display:flex!important;flex-direction:column!important;align-items:center!important;justify-content:center!important;gap:4px!important;' +
          'padding:10px 0 0 0!important;margin:0!important;box-sizing:border-box!important;font-size:12px!important;line-height:normal!important;' +
          'font-family:system-ui,-apple-system,sans-serif!important;font-weight:700!important;color:' + (item.type === 'openHome' ? '#006948' : '#3d4a42') + '!important;';
        tab.insertAdjacentHTML('afterbegin','<svg width=22 height=22 viewBox="0 0 24 24" fill=none stroke=currentColor stroke-width=1.8 stroke-linecap=round stroke-linejoin=round>' + OTLOBLI_NAV_ICONS[item.icon] + '</svg>');
        if (item.type === 'openHome') {
          var indicator = document.createElement('span');
          indicator.style.cssText = 'position:absolute!important;top:0!important;width:32px!important;height:4px!important;border-radius:999px!important;background:#006948!important;';
          tab.appendChild(indicator);
        }
        tab.setAttribute('data-otlobli-nav-type', item.type);
        nav.appendChild(tab);
      }
    }
    if (nav.getAttribute('data-otlobli-nav-style') !== OTLOBLI_NAV_STYLE_VERSION) {
      nav.style.cssText = OTLOBLI_NAV_CSS;
      nav.setAttribute('data-otlobli-nav-style', OTLOBLI_NAV_STYLE_VERSION);
    }
    var stableNavHost = document.documentElement || document.body;
    if (nav.parentNode !== stableNavHost ||
        (nav !== stableNavHost.lastElementChild && otlobliNavIsActuallyCovered(nav))) {
      stableNavHost.appendChild(nav);
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

  function otlobliIsHumanChallengeUrl(href) {
    try {
      var u = new URL(href || location.href, location.href);
      if (SHEIN_CHALLENGE_PATH_RE.test(u.pathname)) return true;
      if (SHEIN_CHALLENGE_QUERY_RE.test(u.search + u.hash)) return true;
    } catch (e) {}
    return false;
  }

  if (IS_SHEIN && otlobliIsHumanChallengeUrl(location.href)) {
    // Landing directly on a challenge URL is still a challenge: do not seed the
    // region here either. Writing cookies while SHEIN's token is outstanding is
    // what made a correctly solved verification report "Access timed out".
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
      u.searchParams.set('lang', SHEIN_REQUIRED_LANGUAGE);
      return u.toString();
    } catch (e) {
      return href;
    }
  }

  // SHEIN owns its cookies, localStorage and sessionStorage. Otlobli never
  // patches Storage.prototype or writes guessed region/session keys; preserving
  // the store's native schemas is what keeps a solved human check reusable.

  function sheinNormalizedAddressLabel(value) {
    return String(value || '')
      .replace(/[\u200e\u200f\u202a-\u202e]/g, '')
      .replace(/\\s+/g, ' ')
      .trim();
  }

  function sheinCountryCodeFromLabel(value) {
    var label = sheinNormalizedAddressLabel(value);
    if (!label) return '';
    var codes = Object.keys(SHEIN_SUPPORTED_COUNTRY_NAMES);
    for (var ci = 0; ci < codes.length; ci++) {
      var code = codes[ci];
      var aliases = SHEIN_SUPPORTED_COUNTRY_NAMES[code] || [];
      for (var ai = 0; ai < aliases.length; ai++) {
        if (label.toLowerCase() === String(aliases[ai]).toLowerCase()) return code;
      }
    }
    return '';
  }

  function sheinRequiredCountryOptionText(value) {
    return sheinCountryCodeFromLabel(value) === SHEIN_REQUIRED_COUNTRY;
  }

  function sheinAddressPathLabelMatches(optionText, wanted) {
    var option = sheinNormalizedAddressLabel(optionText).toLowerCase();
    var target = sheinNormalizedAddressLabel(wanted).toLowerCase();
    if (!option || !target) return false;
    var optionParts = option.split('/').map(function (part) { return part.trim(); }).filter(Boolean);
    var targetParts = target.split('/').map(function (part) { return part.trim(); }).filter(Boolean);
    if (!optionParts.length) optionParts = [option];
    if (!targetParts.length) targetParts = [target];
    for (var ti = 0; ti < targetParts.length; ti++) {
      for (var oi = 0; oi < optionParts.length; oi++) {
        if (optionParts[oi] === targetParts[ti]) return true;
      }
    }
    return false;
  }

  function sheinLooksLikeProductRouteForShipping() {
    if (!IS_SHEIN) return false;
    try {
      var u = new URL(location.href);
      return /(?:-p-\\d+|\\/product\\/|\\/goods\\/|\\/item\\/)/i.test(u.pathname || '') ||
        /[?&](?:goods_id|goodsId|product_id|productId|mallCode|skc)=/i.test(u.search || '');
    } catch (e) {}
    return false;
  }

  function sheinLooksLikeProductPageForShipping() {
    if (sheinLooksLikeProductRouteForShipping()) return true;
    return !!document.querySelector('.productShippingTitle,.product-intro__head,[class*="product-intro"]');
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
      var countryFromName = sheinCountryCodeFromLabel(name);
      if (countryFromName) return countryFromName;
      if (countryId === '186') return 'SA';
      if (name || countryId) return 'FOREIGN';
    } catch (e) {}
    return '';
  }

  // country-only is not enough: SHEIN signs country/state/city/district in
  // xAdFlag and its product APIs use that. Require all four + signature.
  function sheinSignedSaudiAddressReady() {
    try {
      var parsed = sheinAddressCookieData();
      if (!parsed) return false;
      var countryOk = sheinAddressCookieCountry() === SHEIN_REQUIRED_COUNTRY;
      if (!countryOk) return false;
      var state = String(parsed.stateId || parsed.state || '').trim();
      var city = String(parsed.cityId || parsed.city || '').trim();
      var district = String(parsed.districtId || parsed.district || '').trim();
      var lastLevel = String(parsed.lastLevelAddressId || parsed.streetId || '').trim();
      var signature = String(parsed.xAdFlag || '').trim();
      // Saudi's live PWA requires all three lower levels. Other supported
      // countries expose a variable-depth cascade; their signed last selected
      // level is authoritative even when there is no separate city/district.
      if (SHEIN_REQUIRED_COUNTRY === 'SA') return !!(state && city && district && signature);
      return !!(signature && (lastLevel || district || city || state));
    } catch (e) {
      return false;
    }
  }

  function sheinRegionDiag(stage, data, key) {
    try {
      if (window.__otlobliRegionDiagnostic) {
        window.__otlobliRegionDiagnostic(stage, data || {}, key || '');
      }
    } catch (e) {}
  }

  var sheinNativeCoverInitialReleased = false;
  var sheinNativeCoverRepairActive = false;
  var sheinNativeCoverRepairStartedAt = 0;
  var sheinNativeCoverCooldownUntil = 0;
  var sheinNativeCoverLastKey = '';
  sheinRegionDiag('capture-script-injected', {
    requiredCountry: SHEIN_REQUIRED_COUNTRY,
    productRoute: sheinLooksLikeProductRouteForShipping(),
    addressCountry: sheinAddressCookieCountry(),
    signedReady: sheinSignedSaudiAddressReady()
  }, 'script');

  var __otlobliFeedRetryCount = 0;
  var __otlobliFeedRetryAfter = 0;

  function sheinRetryableFeedErrorButton() {
    if (!IS_SHEIN || !document.body) return null;
    var retryPattern = /^(?:try again|retry|\\u062d\\u0627\\u0648\\u0644 \\u0645\\u0631\\u0629 \\u0623\\u062e\\u0631\\u0649|\\u0625\\u0639\\u0627\\u062f\\u0629 \\u0627\\u0644\\u0645\\u062d\\u0627\\u0648\\u0644\\u0629)$/i;
    var errorPattern = /there(?:'|\u2019)?s? (?:an? )?error in our system|something went wrong|system error|\\u0645\\u0639\\u0630\\u0631\\u0629|\\u0647\\u0646\\u0627\\u0643\\s+\\u062e\\u0637\\u0623\\s+\\u0645\\u0627\\s+\\u0641\\u064a\\s+\\u0646\\u0638\\u0627\\u0645\\u0646\\u0627/i;
    var controls = document.querySelectorAll('button, [role="button"], a');
    for (var i = 0; i < controls.length; i++) {
      var control = controls[i];
      var label = String(control.textContent || '').replace(/\\s+/g, ' ').trim();
      if (!retryPattern.test(label)) continue;
      var scope = control;
      for (var hop = 0; scope && hop < 6; hop++, scope = scope.parentElement) {
        var text = String(scope.textContent || '').replace(/\\s+/g, ' ').trim();
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

  function sheinPageLooksInteractive() {
    if (!IS_SHEIN || !document.body || document.readyState === 'loading') return false;
    if (otlobliIsHumanChallenge()) return true;
    if (sheinRetryableFeedErrorButton()) return false;
    var bodyText = String(document.body.textContent || '').replace(/\\s+/g, ' ').trim();
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
    if (homeLike) return loadedImageCount >= 2 && (interactiveCount >= 1 || bodyText.length >= 500);
    return interactiveCount >= 1 && (loadedImageCount >= 1 || bodyText.length >= 500);
  }

  function sheinStoredScalarSignal(key, required) {
    try {
      var raw = localStorage.getItem(key);
      if (!raw) return 'unknown';
      var value = raw;
      try {
        var parsed = JSON.parse(raw);
        if (parsed && typeof parsed === 'object') value = parsed.value || parsed.code || parsed.name || '';
        else if (typeof parsed === 'string') value = parsed;
      } catch (e) {}
      value = String(value || '').trim();
      if (!value) return 'unknown';
      return value.toLowerCase() === String(required).toLowerCase() ? 'matching' : 'mismatch';
    } catch (e) {
      return 'unknown';
    }
  }

  function sheinCoordinatorSnapshot() {
    var addressCountry = sheinAddressCookieCountry();
    var countryState = addressCountry
      ? (addressCountry === SHEIN_REQUIRED_COUNTRY ? 'matching' : 'mismatch')
      : 'unknown';
    var regionState = sheinSignedSaudiAddressReady()
      ? 'matching'
      : (countryState === 'mismatch' ? 'mismatch' : 'unknown');
    var currencyState = 'unknown';
    var languageState = 'unknown';
    var loginPathPattern = new RegExp('/(?:user/)?(?:login|signin|sign-in|auth/login)(?:[/?#.-]|$)', 'i');
    var loginState = loginPathPattern.test(location.pathname || '')
      ? 'detected' : 'not-required';
    try {
      var u = new URL(location.href);
      var currencyParam = u.searchParams.get('currency');
      var languageParam = u.searchParams.get('lang') || u.searchParams.get('language');
      if (currencyParam) currencyState = currencyParam.toUpperCase() === SHEIN_REQUIRED_CURRENCY ? 'matching' : 'mismatch';
      var storedCurrency = sheinStoredScalarSignal('currency', SHEIN_REQUIRED_CURRENCY);
      if (storedCurrency === 'mismatch' || currencyState === 'mismatch') currencyState = 'mismatch';
      else if (storedCurrency === 'matching' || currencyState === 'matching') currencyState = 'matching';

      var pathLanguage = String(u.pathname || '').match(new RegExp('^/([a-z]{2})(?:[-/]|$)', 'i'));
      if (pathLanguage) languageState = pathLanguage[1].toLowerCase() === SHEIN_REQUIRED_LANGUAGE ? 'matching' : 'mismatch';
      if (languageParam) {
        var languageParamState = languageParam.toLowerCase() === SHEIN_REQUIRED_LANGUAGE ? 'matching' : 'mismatch';
        if (languageParamState === 'mismatch' || languageState === 'mismatch') languageState = 'mismatch';
        else languageState = 'matching';
      }
      var documentLanguage = String(document.documentElement && document.documentElement.lang || '').toLowerCase();
      if (documentLanguage) {
        var documentLanguageState = documentLanguage.indexOf(SHEIN_REQUIRED_LANGUAGE) === 0 ? 'matching' : 'mismatch';
        if (documentLanguageState === 'mismatch' || languageState === 'mismatch') languageState = 'mismatch';
        else languageState = 'matching';
      }
    } catch (e) {}

    var policy = window.__otlobliSheinPolicyEngine;
    var policyState = policy && policy.version && policy.observer ? 'verified' : (policy ? 'installed' : 'unknown');
    return {
      countryState: countryState,
      regionState: regionState,
      currencyState: currencyState,
      languageState: languageState,
      loginState: loginState,
      humanVerificationState: otlobliIsHumanChallenge() ? 'required' : 'none',
      policyState: policyState,
      captureState: window.__otlobliStoreRuntimeReady === true ? 'ready' : 'installing',
      interactive: sheinPageLooksInteractive()
    };
  }

  function sheinPostNativeCoverState(type) {
    if (!IS_SHEIN) return;
    var key = type + '|' + location.pathname;
    if (key === sheinNativeCoverLastKey) return;
    try {
      if (window.mobileApp && window.mobileApp.postMessage) {
        sheinNativeCoverLastKey = key;
        if (window.__otlobliSheinPolicyEngine && window.__otlobliSheinPolicyEngine.verify) {
          window.__otlobliSheinPolicyEngine.verify('region-state');
        }
        window.mobileApp.postMessage({ detail: { type: type, coordinator: sheinCoordinatorSnapshot() } });
      }
    } catch (e) {}
  }

  var sheinRegionVeilStartedAt = 0;
  function sheinRegionCountryLabel() {
    return ({ JO: '\u0627\u0644\u0623\u0631\u062f\u0646', SA: '\u0627\u0644\u0633\u0639\u0648\u062f\u064a\u0629', AE: '\u0627\u0644\u0625\u0645\u0627\u0631\u0627\u062a', QA: '\u0642\u0637\u0631', KW: '\u0627\u0644\u0643\u0648\u064a\u062a', BH: '\u0627\u0644\u0628\u062d\u0631\u064a\u0646', OM: '\u0639\u064f\u0645\u0627\u0646', LB: '\u0644\u0628\u0646\u0627\u0646' })[SHEIN_REQUIRED_COUNTRY] || SHEIN_REQUIRED_COUNTRY;
  }
  function sheinRegionTransitionVeil(show) {
    if (!IS_SHEIN || !document.body) return;
    var id = 'otlobli-region-switching', el = document.getElementById(id);
    if (!show) {
      if (el) el.remove();
      if (document.documentElement) document.documentElement.classList.remove('otlobli-shein-region-veil-active');
      return;
    }
    sheinRegionVeilStartedAt = sheinRegionVeilStartedAt || Date.now();
    // otlobli: \u0645\u0624\u0634\u0651\u0631 \u0639\u0644\u0648\u064a \u063a\u064a\u0631 \u062d\u0627\u062c\u0628 \u0628\u062f\u0644 \u063a\u0637\u0627\u0621 \u0645\u0644\u0621 \u0627\u0644\u0634\u0627\u0634\u0629 \u0627\u0644\u0630\u064a \u0643\u0627\u0646 \u064a\u0645\u0646\u0639 \u0641\u062a\u062d \u0627\u0644\u0645\u0646\u062a\u062c\u0627\u062a.
    if (!el) {
      el = document.createElement('div');
      el.id = id;
      el.setAttribute('role', 'status');
      el.setAttribute('aria-live', 'polite');
      el.style.cssText = 'position:fixed!important;top:calc(env(safe-area-inset-top, 0px) + 10px)!important;left:50%!important;transform:translateX(-50%)!important;max-width:90vw!important;background:rgba(255,255,255,.97)!important;box-shadow:0 6px 20px rgba(6,63,45,.18)!important;border:1px solid rgba(0,122,82,.18)!important;border-radius:999px!important;z-index:2147483646!important;display:flex!important;align-items:center!important;gap:9px!important;padding:8px 15px!important;direction:rtl!important;font-family:system-ui,-apple-system,sans-serif!important;color:#063f2d!important;pointer-events:none!important;';
      document.body.appendChild(el);
    }
    el.innerHTML = '<span style="width:16px;height:16px;border:3px solid #d8efe4;border-top-color:#007a52;border-radius:50%;display:inline-block;flex-shrink:0;animation:otlobli-spin .8s linear infinite"></span><span style="font-weight:800;font-size:13px;white-space:nowrap">\u062c\u0627\u0631\u064a \u0636\u0628\u0637 \u0627\u0644\u0645\u0646\u0637\u0642\u0629\u2026 \u0625\u0644\u0649 ' + sheinRegionCountryLabel() + '</span>';
  }
  function sheinUpdateRegionTransitionVeil() {
    var el = document.getElementById('otlobli-region-switching');
    if (!el) return;
    if (sheinSignedSaudiAddressReady() || !sheinNativeCoverRepairActive ||
        Date.now() - sheinRegionVeilStartedAt > (OTLOBLI_LOW_END ? 22000 : 16000)) {
      sheinRegionVeilStartedAt = 0;
      sheinRegionTransitionVeil(false);
    }
  }

  function sheinPrepareNativeSaudiRepair() {
    if (sheinNativeCoverRepairActive) {
      sheinRegionDiag('repair-active', {
        elapsedMs: Date.now() - sheinNativeCoverRepairStartedAt
      }, 'active');
      sheinRegionTransitionVeil(true);
      scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 260 : 120);
      return true;
    }
    var now = Date.now();
    if (now < sheinNativeCoverCooldownUntil) {
      sheinRegionDiag('repair-cooldown', {
        remainingMs: sheinNativeCoverCooldownUntil - now
      }, 'cooldown');
      return false;
    }
    sheinNativeCoverRepairActive = true;
    sheinNativeCoverRepairStartedAt = now;
    sheinShippingProgressAt = now;
    sheinRegionVeilStartedAt = now;
    sheinRegionDiag('repair-started', {
      addressCountry: sheinAddressCookieCountry(),
      signedReady: sheinSignedSaudiAddressReady()
    }, 'started');
    sheinRegionTransitionVeil(true);
    var regionVeil = document.getElementById('otlobli-region-switching');
    sheinRegionDiag('region-veil-state', {
      mounted: !!regionVeil,
      zIndex: regionVeil ? regionVeil.style.zIndex : ''
    }, regionVeil ? 'mounted' : 'missing');
    scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 240 : 90);
    return true;
  }

  function updateSheinNativeCoverState() {
    if (!IS_SHEIN) return;
    if (sheinSignedSaudiAddressReady()) {
      // Close SHEIN's resolved drawer first, then release the cover on the
      // next tick after its close animation detaches it.
      if (sheinShippingUiLikelyOpen() && sheinResolvedShippingUiRoot()) {
        closeResolvedSheinShippingUi();
        scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 260 : 160);
        return;
      }
      sheinNativeCoverRepairActive = false;
      sheinNativeCoverRepairStartedAt = 0;
      sheinRegionVeilStartedAt = 0;
      sheinRegionTransitionVeil(false);
      sheinRegionDiag('repair-signed-ready', {
        addressCountry: sheinAddressCookieCountry()
      }, 'ready');
      if (sheinShippingProgressTimer) {
        clearTimeout(sheinShippingProgressTimer);
        sheinShippingProgressTimer = 0;
      }
      if (!sheinNativeCoverInitialReleased && sheinPageLooksInteractive()) {
        sheinNativeCoverInitialReleased = true;
        sheinPostNativeCoverState('sheinSaudiReady');
      }
      return;
    }
    if (sheinNativeCoverRepairActive) {
      if (Date.now() - sheinNativeCoverRepairStartedAt >= 12000) {
        sheinRegionDiag('repair-timeout', {
          addressCountry: sheinAddressCookieCountry(),
          shippingUiOpen: sheinShippingUiLikelyOpen()
        }, 'timeout');
        closeResolvedSheinShippingUi(true);
        sheinNativeCoverRepairActive = false;
        sheinNativeCoverRepairStartedAt = 0;
        sheinNativeCoverCooldownUntil = Date.now() + 2500;
        sheinRegionVeilStartedAt = 0;
        sheinRegionTransitionVeil(false);
        if (sheinShippingProgressTimer) {
          clearTimeout(sheinShippingProgressTimer);
          sheinShippingProgressTimer = 0;
        }
        if (sheinPageLooksInteractive()) {
          sheinNativeCoverInitialReleased = true;
          sheinPostNativeCoverState('sheinPageInteractive');
        }
      }
      return;
    }
    sheinUpdateRegionTransitionVeil();
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
    // SHEIN currently stores values such as "currency" as site-owned JSON.
    // Treating those values as plain strings corrupts its schema and can make
    // an already verified session initialize again. Only the signed address
    // object and the visible shipping label are region authorities here.
    var addressCountry = sheinAddressCookieCountry();
    if (addressCountry && addressCountry !== SHEIN_REQUIRED_COUNTRY) return false;
    if (sheinVisibleForeignRegion()) return false;
    if (sheinLooksLikeProductPageForShipping() && !sheinSignedSaudiAddressReady()) return false;
    return true;
  }

  function sheinShippingRegionFromText(value) {
    try {
      var text = String(value || '').replace(/\\s+/g, ' ').trim();
      var match = text.match(/(?:Shipping|Ships?|Delivery|Deliver(?:ing)?|الشحن|التوصيل)\\s*(?:to|إلى|الي|ل)?\\s*(Jordan|الأردن|Saudi Arabia|السعودية|المملكة العربية السعودية|Bahrain|United Arab Emirates|UAE|Kuwait|Qatar|Oman|Lebanon|البحرين|الإمارات(?: العربية المتحدة)?|الكويت|قطر|عمان|عُمان|لبنان)(?:\\b|(?=\\s|$|[،,.;:()]))/i);
      if (!match) return '';
      var code = sheinCountryCodeFromLabel(match[1] || '');
      return code === SHEIN_REQUIRED_COUNTRY ? SHEIN_REQUIRED_COUNTRY : 'FOREIGN';
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
    return sheinVisibleShippingRegion() === SHEIN_REQUIRED_COUNTRY;
  }

  function sheinUiText(el) {
    return String(el && el.textContent || '')
      .replace(/[\u200e\u200f\u202a-\u202e]/g, '')
      .replace(/\\s+/g, ' ')
      .trim();
  }

  function sheinExactSaudiOptionText(value) {
    return sheinRequiredCountryOptionText(value);
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

  // A SHEIN drawer can remain fully painted while its iOS transition layer
  // temporarily inherits pointer-events:none. Treat that as visible for
  // automation/root discovery; the interaction stabilizer below restores
  // pointer handling only on the verified shipping drawer.
  function sheinElementIsPainted(el) {
    if (!el || !el.getBoundingClientRect) return false;
    try {
      var rect = el.getBoundingClientRect();
      if (!rect || rect.width <= 0 || rect.height <= 0) return false;
      var style = window.getComputedStyle(el);
      return style.display !== 'none' && style.visibility !== 'hidden' &&
        parseFloat(style.opacity || '1') > 0;
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
    // Shipping controls live in a compact drawer/product section. Bounding
    // the rare fallback scan prevents layout/text work over huge product
    // feeds on older Android phones.
    var max = Math.min(nodes.length, sheinNativeCoverRepairActive ? 5000 : 2500);
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

  function sheinFindHomeShippingEntryControl() {
    var target = document.querySelector('.area-selector-entrance[role="button"],.area-selector-entrance');
    if (!target) return null;
    try {
      var style = window.getComputedStyle(target);
      if (style.display !== 'none' && style.visibility !== 'hidden' && style.pointerEvents !== 'none') return target;
    } catch (e) {}
    return null;
  }

  function sheinFindForeignShippingControl() {
    var productTitle = document.querySelector('.productShippingTitle');
    var addressCountry = sheinAddressCookieCountry();
    if (productTitle && sheinElementIsVisible(productTitle)
      && (sheinShippingRegionFromText(sheinUiText(productTitle)) === 'FOREIGN'
        || (addressCountry && addressCountry !== SHEIN_REQUIRED_COUNTRY))) {
      var productButton = productTitle.querySelector('button.productShippingTitle__text-container,button');
      if (productButton && sheinElementIsVisible(productButton)) return productButton;
      return productTitle;
    }
    return sheinFindShippingRegionContextControl() || sheinBestVisibleControl(function (text) {
      return sheinShippingRegionFromText(text) === 'FOREIGN';
    });
  }

  function sheinFindShippingRegionContextControl() {
    if (!document.body || !sheinLooksLikeProductPageForShipping()) return null;
    var nodes = document.querySelectorAll('button,[role="button"],span,div,li');
    for (var i = 0; i < nodes.length && i < 2600; i++) {
      var node = nodes[i];
      if (!node || (node.id && node.id.indexOf('otlobli') === 0) || !sheinElementIsPainted(node)) continue;
      var nodeText = sheinUiText(node);
      if (!nodeText || nodeText.length > 90 || !sheinCountryCodeFromLabel(nodeText)) continue;
      var context = node;
      for (var hop = 0; context && hop < 6; hop++, context = context.parentElement) {
        if (context === document.body || context === document.documentElement) break;
        var text = sheinUiText(context), cls = String(context.className || '');
        if (!text || text.length > 1300 || !/shipping|ship|delivery|deliver|address|location|country|region|productShipping|الشحن|التوصيل|الموقع|موقع|البلد|دولة/i.test(text + ' ' + cls)) continue;
        var directTarget = sheinClosestInteractive(node);
        if (directTarget && sheinElementIsVisible(directTarget)) return directTarget;
        if (context.querySelectorAll) {
          var controls = context.querySelectorAll('button,[role="button"],a');
          for (var ci = 0; ci < controls.length; ci++) {
            if (sheinElementIsVisible(controls[ci])) return controls[ci];
          }
        }
        var contextTarget = sheinClosestInteractive(context);
        if (contextTarget && sheinElementIsVisible(contextTarget)) return contextTarget;
      }
    }
    return null;
  }

  function sheinFindShippingEntryControl() {
    var homeAddress = sheinFindHomeShippingEntryControl();
    if (homeAddress) return homeAddress;
    var productTitle = document.querySelector('.productShippingTitle');
    if (productTitle && sheinElementIsVisible(productTitle)) {
      var productButton = productTitle.querySelector('button.productShippingTitle__text-container,button,[role="button"]');
      if (productButton && sheinElementIsVisible(productButton)) return productButton;
      return sheinClosestInteractive(productTitle);
    }
    var headings = document.querySelectorAll('h1,h2,h3,[role="heading"]');
    for (var hi = 0; hi < headings.length && hi < 120; hi++) {
      var heading = headings[hi];
      if (!/^(?:shipping to|ship to|الشحن (?:إلى|الي))$/i.test(sheinUiText(heading))) continue;
      var scope = heading.parentElement;
      for (var hop = 0; scope && hop < 4; hop++, scope = scope.parentElement) {
        var controls = scope.querySelectorAll('button,[role="button"]');
        for (var ci = 0; ci < controls.length; ci++) {
          if (sheinElementIsVisible(controls[ci]) && sheinCountryCodeFromLabel(sheinUiText(controls[ci]))) {
            return controls[ci];
          }
        }
      }
    }
    return sheinFindShippingRegionContextControl();
  }

  function sheinVisibleCascadeOptions() {
    if (!document.body) return [];
    var nodes = document.querySelectorAll(
      'li.cascade__list--option,[role="option"],.sui-drawer__body ul.upper-list > li,' +
      '.c-address-upper-drawer ul.upper-list > li,.c-address-upper-drawer [role="listbox"] > li,' +
      '[role="listbox"] > li'
    );
    var result = [];
    for (var i = 0; i < nodes.length; i++) {
      if (sheinElementIsPainted(nodes[i])) result.push(nodes[i]);
    }
    return result;
  }

  function sheinVisibleShippingTabs() {
    if (!document.body) return [];
    var nodes = document.querySelectorAll('.address-header-tab .j-tab-item,.address-header-tab [role="tab"],.cascade__tabs [role="tab"],.cascade__tabs .sui-tab-item-mobile');
    var result = [];
    for (var i = 0; i < nodes.length; i++) {
      if (sheinElementIsPainted(nodes[i])) result.push(nodes[i]);
    }
    return result;
  }

  function sheinTranslateRegionLabels(options, tabs) {
    var map = {
      'Saudi Arabia': 'السعودية', 'Riyadh Province': 'منطقة الرياض', 'Riyadh': 'الرياض', 'Al Olaya': 'العليا',
      'Jordan': 'الأردن', 'United Arab Emirates': 'الإمارات', 'UAE': 'الإمارات', 'Kuwait': 'الكويت', 'Qatar': 'قطر',
      'Bahrain': 'البحرين', 'Oman': 'عُمان', 'Lebanon': 'لبنان'
    };
    var nodes = (options || []).concat(tabs || []);
    if (!nodes.length || !document.documentElement) return;
    if (!document.getElementById('otlobli-region-ar-style')) {
      var st = document.createElement('style');
      st.id = 'otlobli-region-ar-style';
      st.textContent = '[data-otlobli-ar-label]::before{content:attr(data-otlobli-ar-label) " / ";font-weight:700;unicode-bidi:isolate;}';
      document.documentElement.appendChild(st);
    }
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i], t = sheinNormalizedAddressLabel(sheinUiText(n)), ar = map[t] || '';
      if (!ar || !n.setAttribute || n.getAttribute('data-otlobli-ar-label') === ar) continue;
      n.setAttribute('data-otlobli-ar-label', ar);
    }
  }

  function sheinFindExactCascadeOption(pattern) {
    var options = sheinVisibleCascadeOptions();
    for (var i = 0; i < options.length; i++) {
      if (pattern.test(sheinUiText(options[i]))) return options[i];
    }
    return null;
  }

  function sheinFirstSelectableCascadeOption(options) {
    for (var oi = 0; oi < options.length; oi++) {
      var option = options[oi];
      var ariaDisabled = String(option.getAttribute && option.getAttribute('aria-disabled') || '').toLowerCase();
      var className = String(option.className || '').toLowerCase();
      if (ariaDisabled === 'true' || /(?:^|\\s)disabled(?:\\s|$)/.test(className)) continue;
      var label = sheinUiText(option);
      if (!label || /^(?:choose|select|اختر)/i.test(label)) continue;
      return option;
    }
    return null;
  }

  function sheinCountryListState(options) {
    var seen = {};
    var target = null;
    var count = 0;
    for (var oi = 0; oi < options.length; oi++) {
      var code = sheinCountryCodeFromLabel(sheinUiText(options[oi]));
      if (!code) continue;
      if (!seen[code]) {
        seen[code] = true;
        count++;
      }
      if (code === SHEIN_REQUIRED_COUNTRY) target = options[oi];
    }
    return { isCountryList: count >= 2, target: target };
  }

  function sheinCountryIndexLetter() {
    var map = { JO: 'J', SA: 'S', AE: 'U', BH: 'B', KW: 'K', LB: 'L', OM: 'O', QA: 'Q' };
    return map[SHEIN_REQUIRED_COUNTRY] || String((SHEIN_SUPPORTED_COUNTRY_NAMES[SHEIN_REQUIRED_COUNTRY] || [''])[0] || '').charAt(0).toUpperCase();
  }

  function sheinAddressListScroller(options) {
    var best = null;
    for (var i = 0; options && i < options.length; i++) {
      for (var node = options[i], hop = 0; node && hop < 8; hop++, node = node.parentElement) {
        try {
          if (node.scrollHeight > node.clientHeight + 24 &&
              (!best || node.clientHeight < best.clientHeight)) best = node;
        } catch (e) {}
      }
    }
    if (best) return best;
    var root = sheinResolvedShippingUiRoot && sheinResolvedShippingUiRoot();
    try {
      return root && root.scrollHeight > root.clientHeight + 24 ? root : null;
    } catch (e) { return null; }
  }

  function sheinCountryRowsInRoot(root) {
    if (!root || !root.querySelectorAll) return [];
    var nodes = root.querySelectorAll('[data-country],[data-country-code],button,[role="option"],[role="button"],li,div,span');
    var rows = [];
    for (var i = 0; i < nodes.length && i < 900; i++) {
      if (!sheinCountryCodeFromLabel(sheinUiText(nodes[i]))) continue;
      var row = sheinClosestInteractive(nodes[i]);
      if (row && row !== root && sheinElementIsPainted(row) && rows.indexOf(row) < 0) rows.push(row);
    }
    return rows;
  }

  function sheinMoveCountryListTowardRequiredCountry(options) {
    if (!options || !options.length) return false;
    if (!sheinPrepareNativeSaudiRepair()) return false;
    var root = sheinResolvedShippingUiRoot && sheinResolvedShippingUiRoot(), wantedLetter = sheinCountryIndexLetter();
    if (wantedLetter && root && root.querySelectorAll) {
      var shortcuts = root.querySelectorAll('button,a,[role="button"],li,span,div');
      for (var si = 0; si < shortcuts.length && si < 260; si++) {
        var shortcut = shortcuts[si];
        var rect = shortcut.getBoundingClientRect();
        if (rect && rect.width <= 64 && rect.height <= 64 && sheinElementIsPainted(shortcut) && sheinUiText(shortcut).toUpperCase() === wantedLetter) {
          return sheinClickNativeShippingControl(shortcut);
        }
      }
    }
    var scroller = sheinAddressListScroller(options);
    if (!scroller) {
      sheinRegionDiag('country-list-scroll', { found: false, country: SHEIN_REQUIRED_COUNTRY }, 'missing');
      return false;
    }
    try {
      var before = scroller.scrollTop;
      var delta = Math.max(160, Math.floor((scroller.clientHeight || 360) * 0.72));
      var order = { BH: 0, JO: 1, KW: 2, LB: 3, OM: 4, QA: 5, SA: 6, AE: 7 };
      var firstCode = sheinCountryCodeFromLabel(sheinUiText(options[0]));
      var direction = firstCode && order[SHEIN_REQUIRED_COUNTRY] < order[firstCode] ? -1 : 1;
      scroller.scrollTop = Math.max(0, before + (direction * delta));
      if (Math.abs(scroller.scrollTop - before) < 2 && direction > 0) scroller.scrollTop = scroller.scrollHeight;
      sheinRegionDiag('country-list-scroll', {
        found: true, before: before, after: scroller.scrollTop,
        max: scroller.scrollHeight - scroller.clientHeight, direction: direction
      }, [before, scroller.scrollTop, direction].join('|'));
      scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 520 : 260);
      return true;
    } catch (e) {
      return false;
    }
  }

  function sheinNativeSaudiAddressStep(addressCountry, visibleOptions, visibleTabs) {
    var options = visibleOptions || sheinVisibleCascadeOptions();
    var tabs = visibleTabs || sheinVisibleShippingTabs();
    if (!options.length) return false;

    var countryList = sheinCountryListState(options);
    if (countryList.isCountryList) {
      return countryList.target
        ? sheinClickNativeShippingControl(countryList.target)
        : sheinMoveCountryListTowardRequiredCountry(options);
    }

    var countryTab = tabs[0] || null;
    var countryTabCode = countryTab ? sheinCountryCodeFromLabel(sheinUiText(countryTab)) : '';
    if (countryTab && countryTabCode && countryTabCode !== SHEIN_REQUIRED_COUNTRY) {
      return sheinClickNativeShippingControl(countryTab);
    }

    var target = null;
    for (var i = 0; i < options.length; i++) {
      if (sheinRequiredCountryOptionText(sheinUiText(options[i]))) {
        target = options[i];
        break;
      }
    }
    if (target) return sheinClickNativeShippingControl(target);

    for (var pi = 0; pi < SHEIN_REQUIRED_ADDRESS_PATH.length && !target; pi++) {
      for (var oi = 0; oi < options.length; oi++) {
        if (sheinAddressPathLabelMatches(sheinUiText(options[oi]), SHEIN_REQUIRED_ADDRESS_PATH[pi])) {
          target = options[oi];
          break;
        }
      }
    }
    if (!target) target = sheinFirstSelectableCascadeOption(options);
    return target ? sheinClickNativeShippingControl(target) : false;
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
  var SHEIN_SHIPPING_MAX_ACTIONS = 24;
  var sheinShippingLastOptionText = '';
  var sheinShippingLastOptionAt = 0;
  var sheinShippingLastTarget = null;
  var sheinShippingSessionKey = '';
  var sheinShippingProgressKey = '';
  var sheinShippingProgressAt = 0;
  var sheinShippingProgressTimer = 0;
  var sheinResolvedShippingRootCache = null;
  var sheinResolvedShippingRootCacheAt = 0;

  function resetSheinShippingProgress(sessionKey) {
    sheinShippingSessionKey = sessionKey || '';
    sheinShippingActionCount = 0;
    sheinShippingLastActionAt = 0;
    sheinShippingLastScanAt = 0;
    sheinShippingLastOptionText = '';
    sheinShippingLastOptionAt = 0;
    sheinShippingLastTarget = null;
    sheinShippingProgressKey = '';
    sheinShippingProgressAt = Date.now();
    if (sheinShippingProgressTimer) {
      clearTimeout(sheinShippingProgressTimer);
      sheinShippingProgressTimer = 0;
    }
  }

  function scheduleSheinShippingProgress(delay) {
    if (!IS_SHEIN || !sheinNativeCoverRepairActive || sheinShippingProgressTimer) return;
    sheinShippingProgressTimer = setTimeout(function () {
      sheinShippingProgressTimer = 0;
      try { ensureSheinSaudiShippingSelection(); } catch (e) {}
      try { updateSheinNativeCoverState(); } catch (e) {}
    }, Math.max(80, Number(delay) || 0));
  }

  function sheinClickNativeShippingControl(target) {
    if (!target || typeof target.click !== 'function') return false;
    if (!sheinPrepareNativeSaudiRepair()) return false;
    var now = Date.now();
    var actionGap = OTLOBLI_LOW_END ? 520 : 260;
    if (now - sheinShippingLastActionAt < actionGap) {
      scheduleSheinShippingProgress(actionGap - (now - sheinShippingLastActionAt) + 30);
      return false;
    }
    var targetText = sheinUiText(target);
    var sameTargetGap = OTLOBLI_LOW_END ? 1250 : 650;
    if (target === sheinShippingLastTarget && targetText &&
        targetText === sheinShippingLastOptionText &&
        now - sheinShippingLastOptionAt < sameTargetGap) {
      scheduleSheinShippingProgress(sameTargetGap - (now - sheinShippingLastOptionAt) + 30);
      return false;
    }
    if (sheinShippingActionCount >= SHEIN_SHIPPING_MAX_ACTIONS) {
      if (now - sheinShippingLastActionAt < (OTLOBLI_LOW_END ? 12000 : 7000)) return false;
      sheinShippingActionCount = 0;
    }
    sheinShippingLastActionAt = now;
    sheinShippingActionCount++;
    sheinShippingLastOptionText = targetText;
    sheinShippingLastOptionAt = now;
    sheinShippingLastTarget = target;
    target.removeAttribute('data-otlobli-blocked');
    target.setAttribute('data-otlobli-shein-shipping-action', '1');
    sheinRegionDiag('shipping-control-click', {
      label: targetText.slice(0, 160),
      actionCount: sheinShippingActionCount
    }, targetText.slice(0, 80));
    try {
      target.click();
      scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 300 : 140);
      return true;
    } catch (e) {
      return false;
    } finally {
      setTimeout(function () {
        try { target.removeAttribute('data-otlobli-shein-shipping-action'); } catch (e) {}
      }, 900);
    }
  }

  function sheinResolvedShippingUiRoot() {
    if (!document.body) return null;
    var now = Date.now();
    var cacheGap = sheinNativeCoverRepairActive ? 90 : 700;
    if (now - sheinResolvedShippingRootCacheAt < cacheGap) {
      if (!sheinResolvedShippingRootCache) return null;
      if (sheinResolvedShippingRootCache.isConnected &&
          sheinElementIsPainted(sheinResolvedShippingRootCache)) {
        return sheinResolvedShippingRootCache;
      }
    }
    var vp = { width: window.innerWidth || 0, height: window.innerHeight || 0 };
    var options = sheinVisibleCascadeOptions();
    var tabs = sheinVisibleShippingTabs();
    var seed = options[0] || tabs[0] || null;
    var matched = null;

    function inspect(el) {
      if (!el || el === document.body || el === document.documentElement || !sheinElementIsPainted(el)) return false;
      var rect = el.getBoundingClientRect();
      if (rect.width < vp.width * 0.72 || rect.height < vp.height * 0.2) return false;
      var text = sheinUiText(el);
      if (!text || text.length > 6500) return false;
      var hasCountry = /Jordan|Saudi Arabia|United Arab Emirates|Bahrain|Kuwait|Lebanon|Oman|Qatar|\\u0627\\u0644\\u0623\\u0631\\u062f\\u0646|\\u0627\\u0644\\u0633\\u0639\\u0648\\u062f\\u064a\\u0629|\\u0627\\u0644\\u0625\\u0645\\u0627\\u0631\\u0627\\u062a|\\u0627\\u0644\\u0628\\u062d\\u0631\\u064a\\u0646|\\u0627\\u0644\\u0643\\u0648\\u064a\\u062a|\\u0644\\u0628\\u0646\\u0627\\u0646|\\u0639\\u0645\\u0627\\u0646|\\u0642\\u0637\\u0631/i.test(text);
      var hasAddressShape = /(?:Choose|Select)\\s+(?:a\\s+)?location|Province|Governorate|District|Riyadh|Al Olaya|\\u0627\\u062e\\u062a\\u064a\\u0627\\u0631\\s+\\u0645\\u0648\\u0642\\u0639|\\u0645\\u0642\\u0627\\u0637\\u0639\\u0629|\\u0645\\u062d\\u0627\\u0641\\u0638\\u0629|\\u0627\\u0644\\u0645\\u062f\\u064a\\u0646\\u0629|\\u0645\\u0646\\u0637\\u0642\\u0629/i.test(text);
      var hasVerifiedUpperDrawerShape = !!(
        el.querySelector &&
        el.querySelector('.header-close,.common-address-header [class*="close" i]') &&
        el.querySelector('.address-header-tab') &&
        el.querySelector('ul.upper-list,[role="listbox"],[class*="upper-list" i]')
      );
      var countryMatches = text.match(/Jordan|Saudi Arabia|United Arab Emirates|Bahrain|Kuwait|Lebanon|Oman|Qatar|\\u0627\\u0644\\u0623\\u0631\\u062f\\u0646|\\u0627\\u0644\\u0633\\u0639\\u0648\\u062f\\u064a\\u0629|\\u0627\\u0644\\u0625\\u0645\\u0627\\u0631\\u0627\\u062a|\\u0627\\u0644\\u0628\\u062d\\u0631\\u064a\\u0646|\\u0627\\u0644\\u0643\\u0648\\u064a\\u062a|\\u0644\\u0628\\u0646\\u0627\\u0646|\\u0639\\u0645\\u0627\\u0646|\\u0642\\u0637\\u0631/ig) || [];
      var hasCountryListShape = countryMatches.length >= 3 &&
        /Shipping\\s+to|Ship\\s+to|\\u0627\\u0644\\u0634\\u062d\\u0646\\s+(?:\\u0625\\u0644\\u0649|\\u0627\\u0644\\u064a)/i.test(text);
      return hasCountry && (hasAddressShape || hasVerifiedUpperDrawerShape || hasCountryListShape);
    }

    if (seed) {
      var current = seed;
      for (var depth = 0; current && current !== document.body && depth < 9; current = current.parentElement, depth++) {
        if (inspect(current)) matched = current;
      }
      if (matched) {
        sheinResolvedShippingRootCache = matched;
        sheinResolvedShippingRootCacheAt = now;
        return matched;
      }
    }

    var candidates = document.querySelectorAll(
      '.c-address-upper-drawer,.sui-drawer__body,[role="dialog"],[aria-modal="true"],' +
      '[class*="drawer"],[class*="cascade"]'
    );
    for (var i = candidates.length - 1; i >= 0; i--) {
      var candidateRoot = null;
      for (var candidate = candidates[i], hop = 0; candidate && candidate !== document.body && hop < 5; candidate = candidate.parentElement, hop++) {
        if (inspect(candidate)) candidateRoot = candidate;
      }
      if (candidateRoot) {
        sheinResolvedShippingRootCache = candidateRoot;
        sheinResolvedShippingRootCacheAt = now;
        return candidateRoot;
      }
    }
    sheinResolvedShippingRootCache = null;
    sheinResolvedShippingRootCacheAt = now;
    return null;
  }

  function closeResolvedSheinShippingUi(allowIncomplete) {
    if (!allowIncomplete && !sheinSignedSaudiAddressReady()) return false;
    var now = Date.now();
    if (now - sheinShippingCloseLastAt < 1200) return false;
    var root = sheinResolvedShippingUiRoot();
    if (!root) return false;
    // SHEIN's current drawer close control is a focusable span:
    // span.header-close[aria-label="إغلاق"]. It is not a button
    // and has no role, so the old selector never found it and the native cover
    // waited for its bounded escape hatch after the address was already
    // signed. Keep the expansion scoped to this verified shipping root.
    var controls = root.querySelectorAll(
      'button,a,[role="button"],input[type="button"],input[type="submit"],' +
      '.header-close,[aria-label][tabindex],[class*="close" i][tabindex]'
    );
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

  var sheinShippingInteractionRoot = null;
  var sheinShippingInteractionStyles = [];
  var sheinShippingBodyLockState = null;
  var sheinShippingTouchGuardInstalled = false;

  function sheinShippingUiLikelyOpen() {
    if (sheinShippingInteractionRoot && sheinShippingInteractionRoot.isConnected) return true;
    return !!document.querySelector(
      '.c-address-upper-drawer,.address-header-tab .j-tab-item,' +
      'li.cascade__list--option,[role="listbox"] > li,.sui-drawer__body [role="option"]'
    ) || !!sheinResolvedShippingUiRoot();
  }

  function sheinRestoreNavAfterShipping() {
    var nav = document.getElementById('otlobli-nav');
    if (!nav) return null;
    nav.style.setProperty('display', 'flex', 'important');
    nav.style.setProperty('visibility', 'visible', 'important');
    nav.style.setProperty('opacity', '1', 'important');
    nav.style.setProperty('pointer-events', 'auto', 'important');
    nav.style.setProperty('background', '#fff', 'important');
    nav.removeAttribute('data-otlobli-nav-yield');
    return nav;
  }

  function sheinRememberShippingStyle(el, name, value) {
    if (!el || !el.style) return;
    var record = null;
    for (var ri = 0; ri < sheinShippingInteractionStyles.length; ri++) {
      if (sheinShippingInteractionStyles[ri].el === el) {
        record = sheinShippingInteractionStyles[ri];
        break;
      }
    }
    if (!record) {
      record = { el: el, props: {} };
      sheinShippingInteractionStyles.push(record);
    }
    if (!Object.prototype.hasOwnProperty.call(record.props, name)) {
      record.props[name] = {
        value: el.style.getPropertyValue(name),
        priority: el.style.getPropertyPriority(name)
      };
    }
    el.style.setProperty(name, value, 'important');
  }

  function sheinRestoreShippingInteractionStyles() {
    for (var ri = 0; ri < sheinShippingInteractionStyles.length; ri++) {
      var record = sheinShippingInteractionStyles[ri];
      if (!record.el || !record.el.style) continue;
      var names = Object.keys(record.props);
      for (var ni = 0; ni < names.length; ni++) {
        var name = names[ni];
        var saved = record.props[name];
        if (saved.value) record.el.style.setProperty(name, saved.value, saved.priority || '');
        else record.el.style.removeProperty(name);
      }
    }
    sheinShippingInteractionStyles = [];
  }

  function sheinLockPageBehindShippingDrawer() {
    if (sheinShippingBodyLockState || !document.body || !document.documentElement) return;
    var body = document.body;
    var html = document.documentElement;
    var y = window.pageYOffset || html.scrollTop || body.scrollTop || 0;
    sheinShippingBodyLockState = {
      y: y,
      bodyPosition: body.style.getPropertyValue('position'),
      bodyPositionPriority: body.style.getPropertyPriority('position'),
      bodyTop: body.style.getPropertyValue('top'),
      bodyTopPriority: body.style.getPropertyPriority('top'),
      bodyLeft: body.style.getPropertyValue('left'),
      bodyLeftPriority: body.style.getPropertyPriority('left'),
      bodyRight: body.style.getPropertyValue('right'),
      bodyRightPriority: body.style.getPropertyPriority('right'),
      bodyWidth: body.style.getPropertyValue('width'),
      bodyWidthPriority: body.style.getPropertyPriority('width'),
      bodyOverflow: body.style.getPropertyValue('overflow'),
      bodyOverflowPriority: body.style.getPropertyPriority('overflow'),
      htmlOverflow: html.style.getPropertyValue('overflow'),
      htmlOverflowPriority: html.style.getPropertyPriority('overflow'),
      htmlOverscroll: html.style.getPropertyValue('overscroll-behavior'),
      htmlOverscrollPriority: html.style.getPropertyPriority('overscroll-behavior')
    };
    body.style.setProperty('position', 'fixed', 'important');
    body.style.setProperty('top', (-y) + 'px', 'important');
    body.style.setProperty('left', '0', 'important');
    body.style.setProperty('right', '0', 'important');
    body.style.setProperty('width', '100%', 'important');
    body.style.setProperty('overflow', 'hidden', 'important');
    html.style.setProperty('overflow', 'hidden', 'important');
    html.style.setProperty('overscroll-behavior', 'none', 'important');
  }

  function sheinRestoreLockedPageStyle(el, name, value, priority) {
    if (!el || !el.style) return;
    if (value) el.style.setProperty(name, value, priority || '');
    else el.style.removeProperty(name);
  }

  function sheinUnlockPageBehindShippingDrawer() {
    if (!sheinShippingBodyLockState || !document.body || !document.documentElement) return;
    var saved = sheinShippingBodyLockState;
    sheinShippingBodyLockState = null;
    var body = document.body;
    var html = document.documentElement;
    sheinRestoreLockedPageStyle(body, 'position', saved.bodyPosition, saved.bodyPositionPriority);
    sheinRestoreLockedPageStyle(body, 'top', saved.bodyTop, saved.bodyTopPriority);
    sheinRestoreLockedPageStyle(body, 'left', saved.bodyLeft, saved.bodyLeftPriority);
    sheinRestoreLockedPageStyle(body, 'right', saved.bodyRight, saved.bodyRightPriority);
    sheinRestoreLockedPageStyle(body, 'width', saved.bodyWidth, saved.bodyWidthPriority);
    sheinRestoreLockedPageStyle(body, 'overflow', saved.bodyOverflow, saved.bodyOverflowPriority);
    sheinRestoreLockedPageStyle(html, 'overflow', saved.htmlOverflow, saved.htmlOverflowPriority);
    sheinRestoreLockedPageStyle(html, 'overscroll-behavior', saved.htmlOverscroll, saved.htmlOverscrollPriority);
    try { window.scrollTo(0, saved.y || 0); } catch (e) {}
  }

  function sheinVisibleDrawerOrDialog() {
    var nodes = document.querySelectorAll('.sui-drawer,[role="dialog"],[aria-modal="true"],[class*="drawer" i],[class*="modal" i],[class*="mask" i]');
    var vpArea = (window.innerWidth || 0) * (window.innerHeight || 0);
    for (var i = 0; i < nodes.length && i < 50; i++) {
      var el = nodes[i];
      if (!sheinElementIsPainted(el)) continue;
      var r = el.getBoundingClientRect();
      if (r.width * r.height > vpArea * 0.08) return true;
    }
    return false;
  }

  function sheinReleaseFixedBodyLock() {
    if (!document.body || !document.documentElement) return;
    var body = document.body;
    var top = body.style.getPropertyValue('top');
    if (body.style.getPropertyValue('position') !== 'fixed' || !top) return;
    var y = -parseFloat(top) || 0;
    body.style.removeProperty('position');
    body.style.removeProperty('top');
    body.style.removeProperty('left');
    body.style.removeProperty('right');
    body.style.removeProperty('width');
    body.style.removeProperty('overflow');
    document.documentElement.style.removeProperty('overflow');
    document.documentElement.style.removeProperty('overscroll-behavior');
    try { if (y > 0) window.scrollTo(0, y); } catch (e) {}
  }

  function sheinClearStaleShippingLock() {
    if (!document.body || !document.documentElement) return;
    var body = document.body;
    var navGuard = document.getElementById('otlobli-nav-region-guard');
    var fixed = body.style.getPropertyValue('position') === 'fixed';
    var top = body.style.getPropertyValue('top');
    if (!navGuard && (!fixed || !top)) return;
    if (sheinShippingBodyLockState || sheinShippingUiLikelyOpen() || sheinVisibleDrawerOrDialog()) return;
    if (navGuard) navGuard.remove();
    if (fixed && top) sheinReleaseFixedBodyLock();
  }

  function sheinInstallShippingTouchGuard() {
    if (sheinShippingTouchGuardInstalled) return;
    sheinShippingTouchGuardInstalled = true;
    document.addEventListener('touchmove', function (event) {
      var root = sheinShippingInteractionRoot;
      if (!root || !root.isConnected) return;
      var target = event.target;
      if (!target || (target !== root && !root.contains(target))) {
        if (event.cancelable) event.preventDefault();
      }
    }, { capture: true, passive: false });
  }

  function stabilizeSheinShippingDrawerInteraction() {
    if (!IS_SHEIN || !document.body) return;
    var root = sheinShippingUiLikelyOpen() ? sheinResolvedShippingUiRoot() : null;
    if (!root) {
      sheinShippingInteractionRoot = null;
      var staleNavGuard = document.getElementById('otlobli-nav-region-guard');
      if (staleNavGuard) staleNavGuard.remove();
      sheinRestoreShippingInteractionStyles();
      sheinUnlockPageBehindShippingDrawer();
      sheinClearStaleShippingLock();
      var restoredNav = sheinRestoreNavAfterShipping();
      if (restoredNav) otlobliApplyNavYield(restoredNav);
      return;
    }

    if (sheinShippingInteractionRoot && sheinShippingInteractionRoot !== root) {
      sheinRestoreShippingInteractionStyles();
    }
    sheinShippingInteractionRoot = root;
    sheinInstallShippingTouchGuard();
    sheinLockPageBehindShippingDrawer();

    sheinRememberShippingStyle(root, 'pointer-events', 'auto');
    sheinRememberShippingStyle(root, 'touch-action', 'pan-y');
    sheinRememberShippingStyle(root, 'overscroll-behavior', 'contain');

    var scrollNodes = root.querySelectorAll(
      '.sui-drawer__body,ul.upper-list,[role="listbox"],[class*="upper-list" i],' +
      '[class*="scroll" i],[class*="cascade" i]'
    );
    for (var si = 0; si < scrollNodes.length; si++) {
      var node = scrollNodes[si];
      if (!sheinElementIsPainted(node)) continue;
      var isScrollable = node.scrollHeight > node.clientHeight + 2;
      sheinRememberShippingStyle(node, 'pointer-events', 'auto');
      sheinRememberShippingStyle(node, 'touch-action', 'pan-y');
      sheinRememberShippingStyle(node, 'overscroll-behavior', 'contain');
      if (isScrollable) {
        sheinRememberShippingStyle(node, 'overflow-y', 'auto');
        sheinRememberShippingStyle(node, '-webkit-overflow-scrolling', 'touch');
      }
    }

    var nav = sheinRestoreNavAfterShipping();
    if (nav) {
      var navGuard = document.getElementById('otlobli-nav-region-guard');
      if (!navGuard) {
        navGuard = document.createElement('div');
        navGuard.id = 'otlobli-nav-region-guard';
        navGuard.setAttribute('aria-hidden', 'true');
        navGuard.style.cssText = 'position:absolute!important;inset:0!important;z-index:2147483647!important;' +
          'display:block!important;background:transparent!important;pointer-events:auto!important;touch-action:none!important;';
        var blockNavDuringRegionChange = function (event) {
          if (event.cancelable) event.preventDefault();
          event.stopPropagation();
          if (event.stopImmediatePropagation) event.stopImmediatePropagation();
        };
        navGuard.addEventListener('pointerdown', blockNavDuringRegionChange, true);
        navGuard.addEventListener('touchstart', blockNavDuringRegionChange, { capture: true, passive: false });
        navGuard.addEventListener('click', blockNavDuringRegionChange, true);
        nav.appendChild(navGuard);
      }
    }

    var chromeIds = ['otlobli-add-btn', 'otlobli-back-btn'];
    for (var ci = 0; ci < chromeIds.length; ci++) {
      var chrome = document.getElementById(chromeIds[ci]);
      if (!chrome) continue;
      sheinRememberShippingStyle(chrome, 'visibility', 'hidden');
      sheinRememberShippingStyle(chrome, 'opacity', '0');
      sheinRememberShippingStyle(chrome, 'pointer-events', 'none');
    }
  }

  function ensureSheinSaudiShippingSelection() {
    if (!IS_SHEIN || !document.body || document.readyState === 'loading') return;
    if (!sheinLooksLikeProductPageForShipping() && !sheinFindHomeShippingEntryControl()) {
      sheinRegionDiag('shipping-entry-not-detected', {
        productRoute: sheinLooksLikeProductRouteForShipping()
      }, String(location.href || '').slice(-180) + '|' + String(document.title || '').slice(0, 80));
      return;
    }
    var now = Date.now();
    var sessionKey = SHEIN_REQUIRED_COUNTRY + ':' + location.pathname;
    if (sessionKey !== sheinShippingSessionKey) resetSheinShippingProgress(sessionKey);
    if (!sheinSignedSaudiAddressReady()) sheinPrepareNativeSaudiRepair();
    var scanGap = sheinNativeCoverRepairActive
      ? (OTLOBLI_LOW_END ? 260 : 120)
      : (OTLOBLI_LOW_END ? 720 : 480);
    if (now - sheinShippingLastScanAt < scanGap) {
      if (sheinNativeCoverRepairActive) {
        scheduleSheinShippingProgress(scanGap - (now - sheinShippingLastScanAt) + 20);
      }
      return;
    }
    sheinShippingLastScanAt = now;
    var addressCountry = sheinAddressCookieCountry();
    if (addressCountry === SHEIN_REQUIRED_COUNTRY && sheinSignedSaudiAddressReady()) {
      sheinShippingActionCount = 0;
      sheinShippingLastTarget = null;
      if (sheinShippingUiLikelyOpen()) closeResolvedSheinShippingUi();
      return;
    }
    var visibleOptions = sheinVisibleCascadeOptions();
    var visibleTabs = sheinVisibleShippingTabs();
    if (!visibleOptions.length) {
      visibleOptions = sheinCountryRowsInRoot(sheinResolvedShippingUiRoot());
      if (visibleOptions.length) {
        sheinRegionDiag('country-row-fallback', {
          count: visibleOptions.length,
          labels: visibleOptions.slice(0, 7).map(sheinUiText)
        }, visibleOptions.slice(0, 7).map(sheinUiText).join('|'));
      }
    }
    sheinRegionDiag('shipping-scan', {
      addressCountry: addressCountry,
      signedReady: sheinSignedSaudiAddressReady(),
      visibleOptions: visibleOptions.length,
      visibleTabs: visibleTabs.length
    }, addressCountry + '|' + visibleOptions.length + '|' + visibleTabs.length);
    sheinTranslateRegionLabels(visibleOptions, visibleTabs);
    var progressKey = addressCountry + '|' +
      visibleTabs.slice(0, 5).map(sheinUiText).join('>') + '|' +
      visibleOptions.slice(0, 8).map(sheinUiText).join('>');
    if (progressKey !== sheinShippingProgressKey) {
      sheinShippingProgressKey = progressKey;
      sheinShippingProgressAt = now;
      sheinShippingLastTarget = null;
      sheinShippingLastOptionText = '';
      sheinShippingLastOptionAt = 0;
    }
    if (sheinShippingActionCount >= SHEIN_SHIPPING_MAX_ACTIONS) {
      if (now - sheinShippingProgressAt < 6000) {
        scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 420 : 220);
        return;
      }
      sheinShippingActionCount = 0;
      sheinShippingLastActionAt = 0;
      sheinShippingLastTarget = null;
    }
    var actionGap = OTLOBLI_LOW_END ? 520 : 260;
    if (now - sheinShippingLastActionAt < actionGap) {
      scheduleSheinShippingProgress(actionGap - (now - sheinShippingLastActionAt) + 30);
      return;
    }
    if (sheinNativeSaudiAddressStep(addressCountry, visibleOptions, visibleTabs)) return;
    if (visibleOptions.length || visibleTabs.length) {
      scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 360 : 160);
      return;
    }
    var visibleRegion = sheinVisibleShippingRegion();
    var entryControl = visibleRegion === 'FOREIGN' ||
      (addressCountry && addressCountry !== SHEIN_REQUIRED_COUNTRY)
      ? sheinFindForeignShippingControl() || sheinFindShippingEntryControl()
      : sheinFindShippingEntryControl();
    sheinRegionDiag('shipping-entry-control', {
      found: !!entryControl,
      visibleRegion: visibleRegion,
      label: entryControl ? sheinUiText(entryControl).slice(0, 160) : ''
    }, (entryControl ? 'found|' : 'missing|') + visibleRegion);
    if (!sheinClickNativeShippingControl(entryControl) && sheinNativeCoverRepairActive) {
      scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 420 : 220);
    }
  }

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

  function sheinPrimeRegionRepairFromRoute() {
    if (!IS_SHEIN || !sheinLooksLikeProductRouteForShipping()) return false;
    if (otlobliIsHumanChallenge()) {
      sheinRegionDiag('prime-blocked-challenge', {}, 'challenge');
      return false;
    }
    if (sheinSignedSaudiAddressReady()) {
      sheinRegionDiag('prime-already-ready', {
        addressCountry: sheinAddressCookieCountry()
      }, 'ready');
      sheinRegionTransitionVeil(false);
      return false;
    }
    sheinRegionDiag('prime-called', {
      addressCountry: sheinAddressCookieCountry()
    }, 'prime');
    if (sheinAddressCookieCountry() && sheinAddressCookieCountry() !== SHEIN_REQUIRED_COUNTRY) {
      sheinRegionDiag('foreign-address-preserved-for-native-repair', {}, 'preserved');
    }
    var repairStarted = sheinPrepareNativeSaudiRepair();
    sheinRegionDiag('prime-repair-result', {
      repairStarted: repairStarted,
      repairActive: sheinNativeCoverRepairActive
    }, repairStarted ? 'started' : 'not-started');
    return repairStarted;
  }

  function ensureSheinSaudiStore() {
    if (!IS_SHEIN) return true;
    // أثناء تحقق «أنا إنسان»: ممنوع أي إعادة تحميل/كتابة — تصفّر حل المستخدم.
    if (otlobliIsHumanChallenge()) return false;
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
      if (sheinLooksLikeProductPageForShipping()) sheinPrepareNativeSaudiRepair();
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

  // فرض العربية خاص بشي إن فقط (غيره قد يضبط كوكي لغة خاطئة فيعيد التحميل بلا داعٍ).
  if (IS_SHEIN && otlobliScriptEnabled('session')) {
    var normalizedArabicUrl = otlobliNormalizeSheinUrl(location.href);
    // ممنوع إعادة تحميل أثناء تحقق «أنا إنسان» — تصفّر حل المستخدم.
    if (shouldReloadSheinForSaudi() && !otlobliIsHumanChallenge()) {
      var arRedirectAttempts = parseInt(sessionStorage.getItem('__otlobliArRedirects') || '0', 10);
      if (arRedirectAttempts < 1) {
        sessionStorage.setItem('__otlobliArRedirects', String(arRedirectAttempts + 1));
        location.replace(normalizedArabicUrl);
        return;
      }
    } else if (normalizedArabicUrl !== location.href) {
      try {
        history.replaceState(history.state, '', normalizedArabicUrl);
      } catch (e) {}
    }
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
  window.__otlobliStoreRuntimeReady = true;

  window.addEventListener('messageFromNative', function (event) {
    var detail = event && event.detail;
    if (!detail || detail.type !== '__verifySheinState') return;
    try {
      if (window.__otlobliSheinPolicyEngine && window.__otlobliSheinPolicyEngine.verify) {
        window.__otlobliSheinPolicyEngine.verify('host-retry');
      }
      if (sheinSignedSaudiAddressReady() && sheinPageLooksInteractive()) {
        sheinPostNativeCoverState('sheinSaudiReady');
        return;
      }
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: 'sheinCoordinatorState', coordinator: sheinCoordinatorSnapshot() } });
      }
    } catch (e) {}
  });

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


`
