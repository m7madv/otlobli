
(() => {
  const post = (payload) => {
    try {
      const sent = browser.runtime.sendNativeMessage('otlobli', payload)
      if (payload && payload.detail && payload.detail.type === 'addToCart') {
        void sent.then(() => {
          window.dispatchEvent(new CustomEvent('messageFromNative', {
            detail: { type: 'addToCartAck' },
          }))
        }).catch(() => {
          window.dispatchEvent(new CustomEvent('messageFromNative', {
            detail: { type: 'addToCartNack' },
          }))
        })
      } else {
        void sent.catch(() => undefined)
      }
    } catch (_) {}
  }
  window.mobileApp = { postMessage: post }
})();

;

if (/^(?:www\.)?temu\.com$/i.test(location.hostname) &&
    (/\/goods\.html$/i.test(location.pathname) || /(?:^|-)g-\d+\.html$/i.test(location.pathname) ||
     /[?&]goods_id=\d+/i.test(location.search))) {

(function () {

  var OTLOBLI_NAV_CSS = "position:fixed!important;left:50%!important;right:auto!important;bottom:0!important;top:auto!important;transform:translate3d(-50%,0,0)!important;will-change:transform!important;width:100%!important;max-width:440px!important;width:min(100vw, 440px)!important;height:90px!important;min-height:90px!important;max-height:90px!important;height:calc(74px + max(env(safe-area-inset-bottom,0px),var(--otlobli-sb,16px),16px))!important;min-height:calc(74px + max(env(safe-area-inset-bottom,0px),var(--otlobli-sb,16px),16px))!important;max-height:calc(74px + max(env(safe-area-inset-bottom,0px),var(--otlobli-sb,16px),16px))!important;z-index:2147483647!important;display:flex!important;flex-direction:row!important;align-items:stretch!important;direction:rtl!important;overflow:hidden!important;box-sizing:border-box!important;background:#fff!important;border-top:1px solid #bccac0!important;backdrop-filter:none!important;-webkit-backdrop-filter:none!important;padding:0 0 16px 0!important;padding:0 0 max(env(safe-area-inset-bottom,0px),var(--otlobli-sb,16px),16px) 0!important;margin:0!important;font-family:system-ui,-apple-system,sans-serif!important;font-size:12px!important;line-height:normal!important;opacity:1!important;visibility:visible!important;pointer-events:auto!important;";
  var OTLOBLI_NAV_STYLE_VERSION = "v86.104.0";

  
  function otlobliInstallNavTouchBridge() {
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


  function ensureOtlobliBaseStyle() {
    var parent = document.head || document.documentElement;
    if (!parent) return false;
    if (document.getElementById('otlobli-base-style')) return true;
    var fontStyle = document.createElement('style');
    fontStyle.id = 'otlobli-base-style';
    fontStyle.textContent = ".login-bar.j-login-bar{display:none!important}";
    parent.appendChild(fontStyle);
    return true;
  }
  ensureOtlobliBaseStyle();

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
      .replace(/,?\s*viewport-fit=[^,]*/ig, '')
      .replace(/,?\s*maximum-scale=[^,]*/ig, '')
      .replace(/,?\s*user-scalable=[^,]*/ig, '');
    nextContent += ', viewport-fit=cover, maximum-scale=1, user-scalable=no';
    if (content !== nextContent) {
      meta.setAttribute('content', nextContent);
    }
  }
  ensureViewportFitCover();

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
        return String(part || '').replace(/\s+/g, ' ').trim();
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
  var SHEIN_REQUIRED_CURRENCY = 'USD';
  var SHEIN_REQUIRED_LANGUAGE = 'ar';
  var SHEIN_REQUIRED_SITE_UID = 'pwar';
  var SHEIN_CHALLENGE_PATH_RE = /\/(?:cdn-cgi|challenge|captcha|verify|verification|security|robot|risk|anti[-_]?bot|human)(?:\/|$)/i;
  var SHEIN_CHALLENGE_QUERY_RE = /(?:^|[?&#])(?:captcha|challenge|verification|security_token|risk|robot|anti[-_]?bot|human)=/i;
  var TEMU_REQUIRED_COUNTRY = /^[A-Z]{2}$/.test(String(OTLOBLI_TEMU_REGION.countryCode || '').toUpperCase())
    ? String(OTLOBLI_TEMU_REGION.countryCode).toUpperCase()
    : 'SA';
  var TEMU_REQUIRED_CURRENCY = 'USD';


  function otlobliEnsureChallengeNav() {
    if (!document.body) return false;
    var nav = document.getElementById('otlobli-nav');
    if (!nav) {
      nav = document.createElement('div');
      nav.id = 'otlobli-nav';
      nav.setAttribute('data-otlobli-challenge-nav', '1');
      var items = [
        {label:'\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',icon:'home',type:'openHome'},
        {label:'\u0637\u0644\u0628\u0627\u062a\u064a',icon:'orders',type:'openOrders'},
        {label:'\u0627\u0644\u0633\u0644\u0629',icon:'cart',type:'openCart'},
        {label:'\u062d\u0633\u0627\u0628\u064a',icon:'profile',type:'openProfile'},
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
    otlobliEnterChallengeMode();
    return;
  }

  function otlobliNormalizeSheinUrl(href) {
    try {
      var u = new URL(href, location.href);
      if (!/shein/i.test(u.hostname)) return href;
      if (otlobliIsHumanChallengeUrl(u.toString())) return u.toString();
      var cleanPath = u.pathname.replace(/^\/(?:[a-z]{2}(?:en)?|ar-en|ar)(?=\/|$)/i, '') || '/';
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


  function sheinNormalizedAddressLabel(value) {
    return String(value || '')
      .replace(/[‎‏‪-‮]/g, '')
      .replace(/\s+/g, ' ')
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
      return /(?:-p-\d+|\/product\/|\/goods\/|\/item\/)/i.test(u.pathname || '') ||
        /[?&](?:goods_id|goodsId|product_id|productId|mallCode|skc)=/i.test(u.search || '');
    } catch (e) {}
    return false;
  }

  function sheinLooksLikeProductPageForShipping() {
    if (sheinLooksLikeProductRouteForShipping()) return true;
    return !!document.querySelector('.productShippingTitle,.product-intro__head,[class*="product-intro"]');
  }

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
    var retryPattern = /^(?:try again|retry|\u062d\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649|\u0625\u0639\u0627\u062f\u0629 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629)$/i;
    var errorPattern = /there(?:'|’)?s? (?:an? )?error in our system|something went wrong|system error|\u0645\u0639\u0630\u0631\u0629|\u0647\u0646\u0627\u0643\s+\u062e\u0637\u0623\s+\u0645\u0627\s+\u0641\u064a\s+\u0646\u0638\u0627\u0645\u0646\u0627/i;
    var controls = document.querySelectorAll('button, [role="button"], a');
    for (var i = 0; i < controls.length; i++) {
      var control = controls[i];
      var label = String(control.textContent || '').replace(/\s+/g, ' ').trim();
      if (!retryPattern.test(label)) continue;
      var scope = control;
      for (var hop = 0; scope && hop < 6; hop++, scope = scope.parentElement) {
        var text = String(scope.textContent || '').replace(/\s+/g, ' ').trim();
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
    var bodyText = String(document.body.textContent || '').replace(/\s+/g, ' ').trim();
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

    var homeLike = /^\/ar\/?$/i.test(location.pathname || '');
    if (homeLike) return loadedImageCount >= 2 && (interactiveCount >= 1 || bodyText.length >= 500);
    return interactiveCount >= 1 && (loadedImageCount >= 1 || bodyText.length >= 500);
  }

  function sheinPostNativeCoverState(type) {
    if (!IS_SHEIN) return;
    var key = type + '|' + location.pathname;
    if (key === sheinNativeCoverLastKey) return;
    try {
      if (window.mobileApp && window.mobileApp.postMessage) {
        sheinNativeCoverLastKey = key;
        window.mobileApp.postMessage({ detail: { type: type } });
      }
    } catch (e) {}
  }

  var sheinRegionVeilStartedAt = 0;
  function sheinRegionCountryLabel() {
    return ({ JO: 'الأردن', SA: 'السعودية', AE: 'الإمارات', QA: 'قطر', KW: 'الكويت', BH: 'البحرين', OM: 'عُمان', LB: 'لبنان' })[SHEIN_REQUIRED_COUNTRY] || SHEIN_REQUIRED_COUNTRY;
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
    if (!el) {
      el = document.createElement('div');
      el.id = id;
      el.setAttribute('role', 'status');
      el.setAttribute('aria-live', 'polite');
      el.style.cssText = 'position:fixed!important;top:calc(env(safe-area-inset-top, 0px) + 10px)!important;left:50%!important;transform:translateX(-50%)!important;max-width:90vw!important;background:rgba(255,255,255,.97)!important;box-shadow:0 6px 20px rgba(6,63,45,.18)!important;border:1px solid rgba(0,122,82,.18)!important;border-radius:999px!important;z-index:2147483646!important;display:flex!important;align-items:center!important;gap:9px!important;padding:8px 15px!important;direction:rtl!important;font-family:system-ui,-apple-system,sans-serif!important;color:#063f2d!important;pointer-events:none!important;';
      document.body.appendChild(el);
    }
    el.innerHTML = '<span style="width:16px;height:16px;border:3px solid #d8efe4;border-top-color:#007a52;border-radius:50%;display:inline-block;flex-shrink:0;animation:otlobli-spin .8s linear infinite"></span><span style="font-weight:800;font-size:13px;white-space:nowrap">جاري ضبط المنطقة… إلى ' + sheinRegionCountryLabel() + '</span>';
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
      if (!/(^|\.)m\.shein\.com$/i.test(u.hostname)) return false;
      if (!/^\/ar(?:\/|$)/i.test(u.pathname)) return false;
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
    var addressCountry = sheinAddressCookieCountry();
    if (addressCountry && addressCountry !== SHEIN_REQUIRED_COUNTRY) return false;
    if (sheinVisibleForeignRegion()) return false;
    if (sheinLooksLikeProductPageForShipping() && !sheinSignedSaudiAddressReady()) return false;
    return true;
  }

  function sheinShippingRegionFromText(value) {
    try {
      var text = String(value || '').replace(/\s+/g, ' ').trim();
      var match = text.match(/(?:Shipping|Ships?|Delivery|Deliver(?:ing)?|الشحن|التوصيل)\s*(?:to|إلى|الي|ل)?\s*(Jordan|الأردن|Saudi Arabia|السعودية|المملكة العربية السعودية|Bahrain|United Arab Emirates|UAE|Kuwait|Qatar|Oman|Lebanon|البحرين|الإمارات(?: العربية المتحدة)?|الكويت|قطر|عمان|عُمان|لبنان)(?:\b|(?=\s|$|[،,.;:()]))/i);
      if (!match) return '';
      var code = sheinCountryCodeFromLabel(match[1] || '');
      return code === SHEIN_REQUIRED_COUNTRY ? SHEIN_REQUIRED_COUNTRY : 'FOREIGN';
    } catch (e) {
      return '';
    }
  }

  function sheinVisibleShippingRegion() {
    if (!IS_SHEIN || !document.body) return '';
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
      .replace(/[‎‏‪-‮]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
  }

  function sheinExactSaudiOptionText(value) {
    return sheinRequiredCountryOptionText(value);
  }

  function sheinShippingPickerVisible() {
    if (!IS_SHEIN || !document.body) return false;
    var text = String(document.body.innerText || '').slice(0, 30000);
    var hasHeading = /(?:Choose|Select)\s+(?:a\s+)?location|اختيار\s+موقع/i.test(text);
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
      if (ariaDisabled === 'true' || /(?:^|\s)disabled(?:\s|$)/.test(className)) continue;
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
      var hasCountry = /Jordan|Saudi Arabia|United Arab Emirates|Bahrain|Kuwait|Lebanon|Oman|Qatar|\u0627\u0644\u0623\u0631\u062f\u0646|\u0627\u0644\u0633\u0639\u0648\u062f\u064a\u0629|\u0627\u0644\u0625\u0645\u0627\u0631\u0627\u062a|\u0627\u0644\u0628\u062d\u0631\u064a\u0646|\u0627\u0644\u0643\u0648\u064a\u062a|\u0644\u0628\u0646\u0627\u0646|\u0639\u0645\u0627\u0646|\u0642\u0637\u0631/i.test(text);
      var hasAddressShape = /(?:Choose|Select)\s+(?:a\s+)?location|Province|Governorate|District|Riyadh|Al Olaya|\u0627\u062e\u062a\u064a\u0627\u0631\s+\u0645\u0648\u0642\u0639|\u0645\u0642\u0627\u0637\u0639\u0629|\u0645\u062d\u0627\u0641\u0638\u0629|\u0627\u0644\u0645\u062f\u064a\u0646\u0629|\u0645\u0646\u0637\u0642\u0629/i.test(text);
      var hasVerifiedUpperDrawerShape = !!(
        el.querySelector &&
        el.querySelector('.header-close,.common-address-header [class*="close" i]') &&
        el.querySelector('.address-header-tab') &&
        el.querySelector('ul.upper-list,[role="listbox"],[class*="upper-list" i]')
      );
      var countryMatches = text.match(/Jordan|Saudi Arabia|United Arab Emirates|Bahrain|Kuwait|Lebanon|Oman|Qatar|\u0627\u0644\u0623\u0631\u062f\u0646|\u0627\u0644\u0633\u0639\u0648\u062f\u064a\u0629|\u0627\u0644\u0625\u0645\u0627\u0631\u0627\u062a|\u0627\u0644\u0628\u062d\u0631\u064a\u0646|\u0627\u0644\u0643\u0648\u064a\u062a|\u0644\u0628\u0646\u0627\u0646|\u0639\u0645\u0627\u0646|\u0642\u0637\u0631/ig) || [];
      var hasCountryListShape = countryMatches.length >= 3 &&
        /Shipping\s+to|Ship\s+to|\u0627\u0644\u0634\u062d\u0646\s+(?:\u0625\u0644\u0649|\u0627\u0644\u064a)/i.test(text);
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
    var controls = root.querySelectorAll(
      'button,a,[role="button"],input[type="button"],input[type="submit"],' +
      '.header-close,[aria-label][tabindex],[class*="close" i][tabindex]'
    );
    var closePattern = /^(?:close|dismiss|done|\u00d7|\u2715|\u2716|\u0625\u063a\u0644\u0627\u0642|\u0627\u063a\u0644\u0627\u0642|\u062a\u0645)$/i;
    var confirmPattern = /^(?:continue|confirm|save|\u0645\u062a\u0627\u0628\u0639\u0629|\u062a\u0623\u0643\u064a\u062f|\u062d\u0641\u0638)$/i;
    var closeTarget = null;
    var confirmTarget = null;
    for (var i = 0; i < controls.length; i++) {
      var control = controls[i];
      if (!control || (control.id && control.id.indexOf('otlobli') === 0) || !sheinElementIsVisible(control)) continue;
      var label = String(control.innerText || control.textContent || control.value ||
        control.getAttribute('aria-label') || control.getAttribute('title') || '')
        .replace(/\s+/g, ' ').trim();
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
      if (!/(^|\.)m\.shein\.com$/i.test(u.hostname)) return true;
      if (!/^\/ar(?:\/|$)/i.test(u.pathname)) return true;
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

  if (IS_SHEIN) {
    var normalizedArabicUrl = otlobliNormalizeSheinUrl(location.href);
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
    if (document.documentElement) {
      document.documentElement.setAttribute('lang', 'ar');
      document.documentElement.setAttribute('dir', 'rtl');
    }
  }


  if (window.__otlobliInjected) return;
  window.__otlobliInjected = true;
  window.__otlobliStoreRuntimeReady = true;

  if (!sessionStorage.getItem('__otlobliHomePath')) {
    sessionStorage.setItem('__otlobliHomePath', location.pathname);
  }
  function looksLikeHomeRoot() {
    var homePath = (sessionStorage.getItem('__otlobliHomePath') || '').replace(/\/+$/, '');
    return location.pathname.replace(/\/+$/, '') === homePath;
  }

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
      .replace(/\s*\|\s*SHEIN.*/i, '').replace(/\s*-\s*SHEIN.*/i, '')
      .trim();
  }

  function getMeta(prop) {
    var el = document.querySelector('meta[property="' + prop + '"]') || document.querySelector('meta[name="' + prop + '"]');
    return el ? (el.getAttribute('content') || '') : '';
  }

  var __otlobliInitialCapturePath = location.pathname;
  function sheinSpaCaptureRoute() {
    return IS_SHEIN && location.pathname !== __otlobliInitialCapturePath;
  }

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

  function looksGenericTitle(t) {
    if (!t) return true;
    return /شي\s*إن|shein/i.test(t) && /(تسوق|fashion|shop|الموضة)/i.test(t);
  }

  function getTitle(allowGenericFallback) {
    if (sheinSpaCaptureRoute()) {
      var liveTitle = document.querySelector('.product-intro__head-name') || document.querySelector('h1');
      var fromLive = cleanTitle(liveTitle ? liveTitle.textContent : '');
      if (fromLive && !looksGenericTitle(fromLive)) return fromLive;
    }
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
    return cleanTitle(document.title);
  }

  var __otlobliSelectedSkuPrice = 0;
  var __otlobliSelectedSkuPriceKey = '';
  var __otlobliSelectedSkuColor = '';
  var __otlobliSelectedSkuColorImage = '';
  var __otlobliSelectedSkuPricePath = '';
  var __otlobliSelectedSkuPriceAt = 0;
  var __otlobliSelectedSkuPriceBefore = 0;
  var __otlobliSelectedSkuPriceObserver = null;
  var __otlobliSelectedSkuPriceRun = 0, __otlobliSkuPriceSource = '';
  function sheinCurrentSelectionKey() {
    var color = getColorState();
    var size = getSizeState();
    return String(color.selected || '') + '|' + String(size.selected || '');
  }

  function sheinUsdValue(text) {
    var match = String(text || '').match(/(?:US\$|USD|\$)\s*([0-9][0-9,.]*)/i);
    if (!match) return 0;
    var raw = match[1];
    if (raw.indexOf('.') >= 0 && raw.indexOf(',') >= 0) raw = raw.replace(/,/g, '');
    else if (/,[0-9]{1,2}$/.test(raw)) raw = raw.replace(',', '.');
    else raw = raw.replace(/,/g, '');
    var value = parseFloat(raw);
    return value > 0 ? value : 0;
  }

  function sheinPriceFromChangedRoot(root) {
    if (!root || !sheinElementIsPainted(root)) return 0;
    var best = 0, bestScore = -1;
    var inspect = function (el) {
      if (!sheinElementIsPainted(el)) return;
      var text = String(el.textContent || '').replace(/\s+/g, ' ').trim();
      if (!text || text.indexOf('%') >= 0 || (text.match(/(?:US\$|USD|\$)/gi) || []).length !== 1) return;
      var value = sheinUsdValue(text);
      if (!(value > 0)) return;
      var style = window.getComputedStyle(el);
      var hint = String(el.className || '') + ' ' + String(el.parentElement && el.parentElement.className || '');
      if (/line-through/i.test(style.textDecorationLine || style.textDecoration || '') ||
          /(?:old|original|retail|market|compare|cross|del|strikethrough)(?:-|_|\s|$)/i.test(hint)) return;
      var score = parseFloat(style.fontSize || '0') + (/current|sale|final|special|price-content|main-price/i.test(hint) ? 12 : 0);
      if (score >= bestScore) { best = value; bestScore = score; }
    };
    inspect(root);
    var priced = root.querySelectorAll('[class*="price" i], [class*="amount" i]');
    for (var i = 0; i < priced.length && i < 40; i++) inspect(priced[i]);
    if (bestScore < 0) {
      var nodes = root.querySelectorAll('*');
      for (var j = 0; j < nodes.length && j < 80; j++) inspect(nodes[j]);
    }
    return best;
  }

  var OTLOBLI_PRICE_RAIL_HINT = /recommend|similar|also-?like|you-?may|often-?bought|frequently|related|goods-?list|product-?list|listing|rail|carousel|swiper|slider|footer/i;

  function sheinInRecommendationRail(el) {
    var node = el, depth = 0;
    while (node && node !== document.body && node !== document.documentElement && depth < 10) {
      var hint = String(node.className || '') + ' ' + String(node.id || '');
      if (OTLOBLI_PRICE_RAIL_HINT.test(hint)) return true;
      node = node.parentElement;
      depth++;
    }
    return false;
  }

  function sheinPdpPriceScope() {
    var anchor = document.querySelector('.product-intro__head-price') ||
      document.querySelector('.product-intro__head-name');
    if (anchor) {
      var box = (anchor.closest && anchor.closest('.product-intro')) || anchor.parentElement;
      if (box) return box;
    }
    var name = document.querySelector('.product-intro__head-name') || document.querySelector('h1');
    var node = name, depth = 0;
    while (node && node !== document.body && depth < 6) {
      if (node.querySelector && node.querySelector('.product-price, [class*="head-price" i]')) return node;
      node = node.parentElement;
      depth++;
    }
    return null;
  }

  var OTLOBLI_PRICE_SEL = '.product-intro__head-price, [class*="productPriceContainer" i], [class*="head-price" i]';
  var OTLOBLI_MAIN_PRICE_SEL = '[class*="bsc-main-price" i], [class*="main-price" i]';

  function sheinHeadPriceIsRange() {
    var f = document.querySelector('[class*="from-tag" i]');
    if (f && sheinElementIsPainted(f)) return true;
    var roots = document.querySelectorAll(OTLOBLI_PRICE_SEL);
    for (var i = 0; i < roots.length && i < 4; i++) {
      var t = String(roots[i].textContent || '').replace(/\s+/g, ' ');
      if (/(?:^|[\s(])(?:من|from|starting at)\s*(?:US\$|USD|\$)/i.test(t)) return true;
    }
    return false;
  }

  function sheinSpaRoutePrice() {
    if (!IS_SHEIN) return 0;
    if (sheinHeadPriceIsRange()) return 0;
    var price = 0;
    var mains = document.querySelectorAll(OTLOBLI_MAIN_PRICE_SEL);
    for (var m = 0; m < mains.length && m < 4; m++) {
      if (!sheinElementIsPainted(mains[m])) continue;
      var mv = sheinUsdValue(mains[m].textContent || '');
      if (mv > 0) price = mv;
    }
    if (price > 0) return price;
    var heads = document.querySelectorAll(OTLOBLI_PRICE_SEL);
    for (var i = 0; i < heads.length && i < 8; i++) {
      var head = sheinPriceFromChangedRoot(heads[i]);
      if (head > 0) price = head;
    }
    if (price > 0) return price;
    var scope = sheinPdpPriceScope();
    var roots = (scope || document).querySelectorAll('.product-price');
    for (var j = 0; j < roots.length && j < 12; j++) {
      if (sheinInRecommendationRail(roots[j])) continue;
      var found = sheinPriceFromChangedRoot(roots[j]);
      if (found > 0) price = found;
    }
    return price;
  }

  function sheinTrackSelectedSkuPrice(event) {
    if (!IS_SHEIN || !document.body) return;
    var target = event && event.target;
    if (!target || !target.closest || target.closest('[id^="otlobli-"]')) return;
    var colorBox = findOptionContainer('color', OTLOBLI_COLOR_LABELS);
    var sizeBox = findOptionContainer('size', OTLOBLI_SIZE_LABELS);
    var drawerGroup = target.closest('.SIZE_ITEM_HOOK');
    var inActiveDrawerGroup = !!(drawerGroup &&
      __otlobliSheinDrawerPath === location.pathname && !sheinIsQuantityEl(drawerGroup));
    if (!inActiveDrawerGroup &&
        (!colorBox || !colorBox.contains(target)) &&
        (!sizeBox || !sizeBox.contains(target))) return;
    if (colorBox && colorBox.contains(target)) {
      var tappedSw = target.closest(
        'li,button,[role="radio"],[role="option"],[class*="item" i],[class*="color" i]') || target;
      var tapLbl = sheinSelectionLabel(tappedSw);
      var tapImage = swatchImageFrom(tappedSw);
      if ((tapLbl && !isGenericColorName(tapLbl)) || tapImage) {
        if (tapLbl) __otlobliSelectedSkuColor = tapLbl;
        if (tapImage) __otlobliSelectedSkuColorImage = tapImage;
        __otlobliSelectedSkuPricePath = location.pathname;
        __otlobliSelectedSkuPriceAt = Date.now();
      }
    }
    __otlobliSelectedSkuPriceBefore = getPrice();
    __otlobliSelectedSkuPriceAt = 0;
    if (__otlobliSelectedSkuPriceObserver) __otlobliSelectedSkuPriceObserver.disconnect();
    var run = ++__otlobliSelectedSkuPriceRun;
    var roots = [], priceChanged = false;
    var selector = OTLOBLI_PRICE_SEL + ', .product-price, ' + OTLOBLI_MAIN_PRICE_SEL;
    var rememberRoot = function (node) {
      if (!node || node.nodeType !== 1) return;
      var root = node.matches && node.matches(selector) ? node : (node.closest && node.closest(selector));
      if (!root && node.querySelector) root = node.querySelector(selector);
      if (root) {
        priceChanged = true;
        if (!roots.includes(root) && roots.length < 8) roots.push(root);
      }
    };
    __otlobliSelectedSkuPriceObserver = new MutationObserver(function (records) {
      priceChanged = false;
      for (var i = 0; i < records.length; i++) {
        rememberRoot(records[i].target.nodeType === 3 ? records[i].target.parentElement : records[i].target);
        for (var j = 0; records[i].addedNodes && j < records[i].addedNodes.length; j++) rememberRoot(records[i].addedNodes[j]);
      }
      if (priceChanged) commit();
    });
    __otlobliSelectedSkuPriceObserver.observe(document.body, {
      subtree: true, childList: true, characterData: true, attributes: true,
      attributeFilter: ['class', 'style', 'hidden', 'aria-hidden']
    });
    if (inActiveDrawerGroup) {
      var drawerRoot = target.closest('.sui-drawer');
      var initialPriceRoots = drawerRoot && drawerRoot.querySelectorAll(OTLOBLI_MAIN_PRICE_SEL);
      for (var pr = 0; initialPriceRoots && pr < initialPriceRoots.length && pr < 8; pr++) rememberRoot(initialPriceRoots[pr]);
    }
    var commit = function () {
      if (run !== __otlobliSelectedSkuPriceRun) return;
      var price = 0;
      for (var i = 0; i < roots.length; i++) {
        var found = sheinPriceFromChangedRoot(roots[i]);
        if (found > 0) price = found;
      }
      if (!(price > 0)) return;
      __otlobliSelectedSkuPrice = price;
      __otlobliSelectedSkuPriceKey = sheinCurrentSelectionKey();
      __otlobliSelectedSkuPricePath = location.pathname;
      __otlobliSelectedSkuPriceAt = Date.now();
    };
    setTimeout(commit, 90);
    setTimeout(commit, 260);
    setTimeout(commit, 700);
    setTimeout(commit, 1500);
    setTimeout(function () {
      if (run !== __otlobliSelectedSkuPriceRun || !__otlobliSelectedSkuPriceObserver) return;
      commit();
      __otlobliSelectedSkuPriceObserver.disconnect();
      __otlobliSelectedSkuPriceObserver = null;
    }, 1750);
  }

  function sheinSelectedSkuPricePending() {
    if (sheinActiveQuickAddDrawer()) return false;
    if (!__otlobliSelectedSkuPriceObserver) return false;
    var ready = __otlobliSelectedSkuPrice > 0 &&
      __otlobliSelectedSkuPricePath === location.pathname &&
      __otlobliSelectedSkuPriceKey === sheinCurrentSelectionKey() &&
      __otlobliSelectedSkuPriceAt > 0;
    return !ready || Math.abs(__otlobliSelectedSkuPrice - __otlobliSelectedSkuPriceBefore) < 0.0001;
  }

  function getPrice() {
    var selectionKey = sheinCurrentSelectionKey();
    if (__otlobliSelectedSkuPrice > 0 &&
        __otlobliSelectedSkuPricePath === location.pathname &&
        (__otlobliSelectedSkuPriceKey === selectionKey || selectionKey === '|') &&
        Date.now() - __otlobliSelectedSkuPriceAt < 1800000) {
      __otlobliSkuPriceSource = 'selected-mutation';
      return __otlobliSelectedSkuPrice;
    }
    var spaPrice = sheinSpaRoutePrice();
    if (spaPrice > 0) { __otlobliSkuPriceSource = 'spa-dom'; return spaPrice; }
    if (sheinHeadPriceIsRange()) { __otlobliSkuPriceSource = 'range-blocked'; return 0; }
    var ld = getProductJsonLd();
    if (ld && ld.offers) {
      var offers = Array.isArray(ld.offers) ? ld.offers[0] : ld.offers;
      var ldPrice = offers && parseFloat(offers.price);
      if (ldPrice > 0) { __otlobliSkuPriceSource = 'json'; return ldPrice; }
    }
    var metaPrice = parseFloat(getMeta('product:price:amount'));
    if (metaPrice > 0) { __otlobliSkuPriceSource = 'meta'; return metaPrice; }
    var el = document.querySelector('.product-price .price-content, .product-intro__head-price, [class*="price" i]');
    var text = el ? (el.textContent || '') : '';
    var match = text.match(/[0-9]+\.?[0-9]*/);
    __otlobliSkuPriceSource = match ? 'legacy-dom' : 'missing';
    return match ? parseFloat(match[0]) : 0;
  }

  try {
    window.__otlobliDiag = {
      price: getPrice,
      source: function () { return __otlobliSkuPriceSource; },
      color: getColorState,
      size: getSizeState,
      find: findOptionContainer,
      labels: function () { return { color: OTLOBLI_COLOR_LABELS, size: OTLOBLI_SIZE_LABELS }; },
      isRange: sheinHeadPriceIsRange,
      spa: sheinSpaRoutePrice,
      key: sheinCurrentSelectionKey,
      skuEntry: sheinSkuSelectionEntry,
      openDrawer: sheinOpenSkuDrawer,
      storeVariant: sheinStoreVariant,
      quick: sheinQuickAddPayload,
      pending: sheinSelectedSkuPricePending,
      saved: function () {
        return {
          price: __otlobliSelectedSkuPrice, key: __otlobliSelectedSkuPriceKey,
          path: __otlobliSelectedSkuPricePath, at: __otlobliSelectedSkuPriceAt,
          before: __otlobliSelectedSkuPriceBefore,
          observing: !!__otlobliSelectedSkuPriceObserver,
        };
      },
    };
  } catch (e) {}

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
      return parts[parts.length - 1].split(/\s+/)[0] || '';
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
      if (v && !/^data:image\/(?:gif|svg)/i.test(v) && !/blank\.gif|placeholder|skeleton|transparent/i.test(v)) return normalizeImageUrl(v);
    }
    return '';
  }

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
      var dim = renderedMinDim(img);
      if (dim > 0 && dim < 64) continue;
      var pCls = img.parentElement ? (img.parentElement.className || '').trim() : '';
      if (!pCls) continue;
      if (!byParentClass[pCls]) { byParentClass[pCls] = []; order.push(pCls); }
      byParentClass[pCls].push(img);
    }
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
    if (sheinSpaCaptureRoute()) {
      var liveMain = document.querySelector('.product-intro__main-image img, .product-intro__main-image');
      var liveSrc = realImgSrc(liveMain);
      if (liveSrc && !isInPromoWidget(liveMain)) return liveSrc;
    }
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

  var OTLOBLI_COLOR_LABELS = ['اللون', 'لون', 'Color', 'Colour'];
  var OTLOBLI_SIZE_LABELS = ['المقاس', 'مقاس', 'الحجم', 'Size'];

  var QTY_RE = /الكمية|كمية|quantity/i;
  function sheinGroupHeading(el) {
    if (!el) return '';
    var h = el.querySelector && el.querySelector('.goods-size__title');
    if (h) return normalizedOptionText(h.textContent);
    var node = el.parentElement;
    for (var up = 0; up < 4 && node; up++) {
      var titles = node.querySelectorAll ? node.querySelectorAll('.goods-size__title') : [];
      var nearest = null;
      for (var ti = 0; ti < titles.length; ti++) {
        if (titles[ti].compareDocumentPosition(el) & 4) nearest = titles[ti];
      }
      if (nearest) return normalizedOptionText(nearest.textContent);
      node = node.parentElement;
    }
    return '';
  }

  function sheinHeadingMatchesLabels(el, labelWords) {
    if (!labelWords) return false;
    var head = sheinGroupHeading(el).replace(/[:：]/g, ' ').toLowerCase();
    if (!head) return false;
    for (var w = 0; w < labelWords.length; w++) {
      if (head.indexOf(labelWords[w].toLowerCase()) !== -1) return true;
    }
    return false;
  }

  function sheinIsQuantityEl(el) {
    if (!el) return false;
    var t = (el.textContent || '').trim();
    if (t.length < 20 && QTY_RE.test(t)) return true;
    return QTY_RE.test(sheinGroupHeading(el));
  }

  function findOptionContainer(keyword, labelWords) {
    var all = document.querySelectorAll('[class*="' + keyword + '" i]');
    var fallback = null, active = null, activeCount = 1e9, activeMatch = false;
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      var cls = ' ' + (el.className || '') + ' ';
      if (/review|comment|rating|feedback/i.test(cls)) continue;
      if (IS_SHEIN && sheinIsQuantityEl(el)) continue;
      var opts = el.querySelectorAll('li, button, [class*="item" i]');
      if (opts.length < 2) continue;
      var rect = el.getBoundingClientRect();
      var rendered = sheinElementIsVisible(el) && !sheinCovered(el);
      if (rendered) fallback = fallback || el;
      var inView = rect.bottom > 0 && rect.right > 0 &&
        rect.top < (document.documentElement.clientHeight || 0) &&
        rect.left < (document.documentElement.clientWidth || 0);
      if (!(inView && rendered)) continue;
      var matches = IS_SHEIN && sheinHeadingMatchesLabels(el, labelWords);
      var picked = isSelectedSwatchEl(el) && (!active || !isSelectedSwatchEl(active));
      var better;
      if (!active) better = true;
      else if (matches !== activeMatch) better = matches;
      else better = (opts.length < activeCount) || picked;
      if (better) { active = el; activeCount = opts.length; activeMatch = matches; }
    }
    if (__otlobliSheinDrawerPath === location.pathname && !active) return null;
    if (IS_SHEIN && keyword === 'color' && active && active.getAttribute('role') === 'radio') {
      var colorRow = active.parentElement;
      for (var cr = 0; cr < 4 && colorRow; cr++, colorRow = colorRow.parentElement) {
        if (colorRow.querySelectorAll('[role="radio"]').length >= 2) return colorRow;
      }
    }
    var base = active || fallback;
    if (base && active && labelWords) {
      var heads = base.querySelectorAll('div, span, p, h1, h2, h3, label, b, strong');
      for (var h = 0; h < heads.length; h++) {
        var headText = normalizedOptionText(heads[h].textContent).replace(/[:：]$/, '').toLowerCase();
        var exact = false;
        for (var lw = 0; lw < labelWords.length; lw++) {
          if (headText === labelWords[lw].toLowerCase()) { exact = true; break; }
        }
        if (!exact) continue;
        var group = heads[h].parentElement;
        for (var gh = 0; gh < 3 && group && (group === base || base.contains(group)); gh++) {
          if (group.querySelectorAll('li, button, [class*="item" i], img').length >= 2) return group;
          group = group.parentElement;
        }
      }
    }
    if (base) return base;
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
          if (opts2.length >= 2 && sheinElementIsVisible(scope) && !sheinCovered(scope)) return scope;
          scope = scope.parentElement;
        }
      }
    }
    return null;
  }

  function isSelectedSwatchEl(el) {
    if (el.getAttribute('aria-selected') === 'true') return true;
    if (el.getAttribute('aria-checked') === 'true') return true;
    if (el.getAttribute('aria-pressed') === 'true') return true;
    var cls = ' ' + (el.className || '') + ' ';
    if (/\s(selected|active|checked|chosen|cur|current|picked)\s/i.test(cls)) return true;
    var input = el.tagName === 'INPUT' ? el : el.querySelector('input[type="radio"], input[type="checkbox"]');
    if (input && input.checked) return true;
    return false;
  }

  function looksLikeJunkValue(text) {
    if (!text) return true;
    if (/^(hot|new|sale|best|bestseller|#\s*\d+|\-?\d+%?)$/i.test(text.trim())) return true;
    return /^\d{1,2}:\d{2}(:\d{2})?$/.test(text);
  }

  function sheinHasManyOptionChildren(el) {
    return !!(el && el.querySelectorAll &&
      el.querySelectorAll('li,button,[role="radio"],[role="option"],[role="button"],[class*="item" i]').length > 1);
  }

  function sheinSelectionLabel(el) {
    if (!el) return '';
    var label = el.getAttribute('aria-label') || el.getAttribute('title') ||
      el.getAttribute('data-color') || el.getAttribute('data-name') || el.getAttribute('data-value') ||
      el.getAttribute('data-attr-value') || '';
    label = normalizedOptionText(label);
    if (!label) {
      var innerImg = el.tagName === 'IMG' ? el : el.querySelector && el.querySelector('img');
      if (innerImg) label = normalizedOptionText(innerImg.getAttribute('alt') || innerImg.getAttribute('title') || '');
    }
    if (!label && !sheinHasManyOptionChildren(el)) label = normalizedOptionText(el.textContent);
    return label && label.length < 60 && !looksLikeJunkValue(label) ? label : '';
  }

  function sheinRgb(value) {
    var m = String(value || '').match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?/i);
    return m ? [+m[1], +m[2], +m[3], m[4] === undefined ? 1 : +m[4]] : null;
  }

  function sheinLooksVisuallySelected(el) {
    try {
      if (!sheinSelectionLabel(el) || sheinHasManyOptionChildren(el)) return false;
      var r = el.getBoundingClientRect();
      if (!r || r.width < 20 || r.height < 20 || r.width > 280 || r.height > 120) return false;
      var cs = window.getComputedStyle(el);
      var bg = sheinRgb(cs.backgroundColor);
      var fg = sheinRgb(cs.color);
      return !!(bg && bg[3] > 0.55 && bg[0] < 80 && bg[1] < 80 && bg[2] < 80 &&
        (!fg || (fg[0] > 150 && fg[1] > 150 && fg[2] > 150)));
    } catch (e) { return false; }
  }

  function getSelectedWithin(container) {
    if (!container) return '';
    var nodes = container.querySelectorAll('*');
    for (var j = -1; j < nodes.length; j++) {
      var el = j < 0 ? container : nodes[j];
      if (isSelectedSwatchEl(el)) {
        var label = sheinSelectionLabel(el);
        if (label) return label;
      }
    }
    var opts = container.querySelectorAll('li,button,[role="radio"],[role="option"],[role="button"],[class*="item" i]');
    for (var o = 0; o < opts.length; o++) {
      if (sheinLooksVisuallySelected(opts[o])) return sheinSelectionLabel(opts[o]);
    }
    return '';
  }

  function sheinSelectedQuantityOption(scope) {
    var picks = (scope || document).querySelectorAll('.goods-size__sizes-item.size-active,[data-attr_value][aria-checked="true"]');
    for (var i = 0; i < picks.length; i++) {
      if (!sheinIsQuantityEl(picks[i])) continue;
      var value = normalizedOptionText(picks[i].getAttribute('data-attr_value') || picks[i].textContent);
      if (value && value.length < 60) return value;
    }
    return '';
  }

  function normalizedOptionText(value) {
    return String(value || '').replace(/\s+/g, ' ').trim();
  }

  function sheinPieceCountKey(value) {
    var text = normalizedOptionText(value).toUpperCase().replace(/\s+/g, '');
    var match = text.match(/^(\d+)(?:PC|PCS|PIECE|PIECES)$/) ||
      text.match(/^(?:PC|PCS|CP)(\d+)$/);
    return match ? match[1] : '';
  }

  function sheinSimpleSize(value) {
    var text = normalizedOptionText(value);
    return /^(?:xxs|xs|s|m|l|xl|xxl|xxxl|one\s*size|[2-9]\d|[1-9]\d{2})$/i.test(text) ? text : '';
  }

  function completeSelectedCompoundSize(container, selected) {
    if (container && selected) {
      var combinedUnconfirmed = false;
      var combinedTitles = document.querySelectorAll('.goods-size__title,[class*="size__title" i]');
      for (var c = 0; c < combinedTitles.length && c < 4; c++) {
        var heading = normalizedOptionText(combinedTitles[c].textContent);
        var headingKey = heading.replace(/\s+/g, '').toLowerCase();
        if (headingKey !== 'لون/مقاس' && headingKey !== 'color/size' && headingKey !== 'colour/size') continue;
        var next = combinedTitles[c].nextElementSibling;
        var summary = normalizedOptionText(next && next.textContent);
        var scope = combinedTitles[c];
        for (var h = 0; !summary && h < 3 && scope && scope !== document.body; h++) {
          scope = scope.parentElement;
          var row = normalizedOptionText(scope && scope.textContent);
          if (row.indexOf(heading) === 0 && row.length < 60) summary = row.slice(heading.length).trim();
        }
        var chosen = summary.split('/');
        var first = normalizedOptionText(chosen[0]);
        var rest = normalizedOptionText(chosen.slice(1).join(' / '));
        if (summary.length < 60 && first === normalizedOptionText(selected) && rest) {
          combinedUnconfirmed = true;
          var selectedNodes = container.querySelectorAll('*');
          for (var s = 0; s < selectedNodes.length; s++) {
            if (!isSelectedSwatchEl(selectedNodes[s])) continue;
            var value = normalizedOptionText(selectedNodes[s].getAttribute('aria-label') ||
              selectedNodes[s].getAttribute('title') || selectedNodes[s].getAttribute('data-value') || selectedNodes[s].textContent);
            if (value === rest || (value.length < 60 && value.indexOf(rest) === 0)) return first + ' / ' + rest;
          }
        }
      }
      if (combinedUnconfirmed) return '';
    }
    var pieceKey = sheinPieceCountKey(selected);
    if (!container || !pieceKey) return selected;
    var nodes = container.querySelectorAll('*');
    var pickedSize = '';
    for (var i = 0; i < nodes.length; i++) {
      if (!isSelectedSwatchEl(nodes[i])) continue;
      var value = nodes[i].getAttribute('aria-label') || nodes[i].getAttribute('title') ||
        nodes[i].getAttribute('data-name') || nodes[i].getAttribute('data-value') ||
        nodes[i].getAttribute('data-attr-value') || nodes[i].textContent || '';
      pickedSize = pickedSize || sheinSimpleSize(value);
      var control = nodes[i].closest &&
        nodes[i].closest('button, li, [role="radio"], [role="option"], [role="button"], [class*="item" i]');
      if (!control || !sheinElementIsVisible(control)) continue;
      var full = normalizedOptionText(control.textContent);
      if (!full || full.length > 60 || !/[\/+|]/.test(full)) continue;
      var parts = full.split(/\s*[\/+|]\s*/);
      var hasPiece = false, hasSize = false;
      for (var p = 0; p < parts.length; p++) {
        if (sheinPieceCountKey(parts[p]) === pieceKey) hasPiece = true;
        else if (sheinSimpleSize(parts[p])) hasSize = true;
      }
      if (hasPiece && hasSize) return full;
    }
    return pickedSize ? pickedSize + ' / ' + selected : selected;
  }

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
          var rest = t.slice(idx + word.length).replace(/^[\s:：\-–(]+/, '').replace(/[)\s]+$/, '').trim();
          if (rest && rest.length < 40 && rest.toLowerCase() !== word.toLowerCase() && !looksLikeJunkValue(rest)) return rest;
        }
      }
      scope = scope.parentElement;
    }
    return '';
  }

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

  function isColorBadgeEl(el) {
    if (!el || !el.getBoundingClientRect) return false;
    var text = ((el.textContent || '') + '').replace(/\s+/g, ' ').trim();
    var cls = ' ' + ((el.className || '') + '').toLowerCase() + ' ';
    var r = el.getBoundingClientRect();
    var compact = r.width > 0 && r.width <= 96 && r.height > 0 && r.height <= 48;
    var cs = window.getComputedStyle(el);
    var before = window.getComputedStyle(el, '::before');
    var hasSwatchVisual = Math.min(r.width, r.height) >= 32 && (
      el.tagName === 'IMG' || !!el.querySelector('img') || /url\(/.test(cs.backgroundImage || '') || /url\(/.test(before.backgroundImage || '')
    );
    if (hasSwatchVisual) return false;
    if (compact && /^(hot|new|sale|best|bestseller|\-?\d+%?)$/i.test(text)) return true;
    return compact && /(?:^|[\s_-])(hot|badge|tag|label|discount|promo|best|bestseller)(?:$|[\s_-])/i.test(cls);
  }

  function isLikelyBadgeImageUrl(src) {
    if (!src) return false;
    return /(?:hot|badge|tag|label|discount|sprite|icon|promo|rank|best)/i.test(src) &&
      !/ltwebstatic|img\.shein/i.test(src);
  }

  function swatchBackgroundUrl(el, pseudo) {
    try {
      var bg = window.getComputedStyle(el, pseudo || null).backgroundImage || '';
      var match = bg.match(/url\(["']?(.*?)["']?\)/);
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
        if (/ltwebstatic|img\.shein|shein/i.test(src)) score += 120;
        if (score > bestScore) {
          bestScore = score;
          bestSrc = src;
        }
      }
    }
    return bestSrc;
  }

  function swatchImageFrom(el) {
    if (!el) return '';
    var rankedImage = rankedSwatchImageFrom(el);
    if (rankedImage) return rankedImage;
    var scope = isColorBadgeEl(el) && el.parentElement ? el.parentElement : el;
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
      if (cw > 0 && ch > 0 && Math.min(cw, ch) < 18) continue;
      var candArea = cw * ch;
      if (candArea > bestArea) { bestArea = candArea; bestSrc = candSrc; }
    }
    if (bestSrc) return bestSrc;
    var bg = isColorBadgeEl(scope) ? '' : window.getComputedStyle(scope).backgroundImage;
    var match = bg && bg.match(/url\(["']?(.*?)["']?\)/);
    if (match && match[1] && !/blank|placeholder/i.test(match[1]) && !isLikelyBadgeImageUrl(match[1])) return match[1];
    var children = scope.children;
    for (var c = 0; c < (children ? children.length : 0); c++) {
      if (isColorBadgeEl(children[c])) continue;
      var childBg = window.getComputedStyle(children[c]).backgroundImage;
      var childMatch = childBg && childBg.match(/url\(["']?(.*?)["']?\)/);
      if (childMatch && childMatch[1] && !/blank|placeholder/i.test(childMatch[1]) && !isLikelyBadgeImageUrl(childMatch[1])) return childMatch[1];
    }
    return '';
  }

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

  function collectSwatchEls(container) {
    var nodes = container.querySelectorAll('*');
    var out = [];
    for (var n = 0; n < nodes.length; n++) {
      var el = nodes[n];
      var r = el.getBoundingClientRect();
      if (r.width <= 0 || r.width > 80 || r.height <= 0 || r.height > 80) continue;
      if (isColorBadgeEl(el) && !swatchImageFrom(el)) continue;
      var hasImg = el.tagName === 'IMG' || !!el.querySelector('img') ||
        /url\(/.test(window.getComputedStyle(el).backgroundImage || '');
      if (hasImg && swatchImageFrom(el)) out.push(el);
    }
    return out;
  }

  function getSelectedColorSwatchImage(container, selectedName) {
    if (!container) return '';
    var nodes = container.querySelectorAll('*');
    for (var j = -1; j < nodes.length; j++) {
      var selectedNode = j < 0 ? container : nodes[j];
      if (!isSelectedSwatchEl(selectedNode)) continue;
      if (sheinHasManyOptionChildren(selectedNode) && selectedNode.getAttribute('role') !== 'radio') continue;
      var im1 = swatchImageFrom(selectedNode);
      if (im1) return im1;
    }
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

  function isGenericColorName(text) {
    if (!text) return true;
    var t = text.toLowerCase();
    return /ألوان متعددة|متعدد الألوان|متعدد الالوان|multi-?colou?r|multi colou?r|assorted/.test(t);
  }

  function sheinPageColorHeading() {
    var heads = document.querySelectorAll('.main-sales-attr-container');
    for (var i = 0; i < heads.length && i < 4; i++) {
      if (!sheinElementIsVisible(heads[i])) continue;
      var match = normalizedOptionText(heads[i].textContent).match(/^(?:اللون|لون|colou?r)s*[:：]s*(.{1,39})$/i);
      if (match && !looksLikeJunkValue(match[1])) return normalizedOptionText(match[1]);
    }
    return '';
  }

  function getColorState() {
    var container = findOptionContainer('color', OTLOBLI_COLOR_LABELS);
    var pageVal = sheinDrawerCompoundSizeState() ? '' : sheinPageColorHeading();
    var labelVal = pageVal || getAttrLabelValue(container, ['اللون', 'Color', 'color']) || getColorHeadingLabel(container);
    var swatchVal = getSelectedWithin(container);
    var selected;
    if (swatchVal && !isGenericColorName(swatchVal)) selected = swatchVal;
    else if (labelVal && !isGenericColorName(labelVal)) selected = labelVal;
    else selected = labelVal || swatchVal;
    selected = sheinSkuMemo('c', selected);
    return { exists: !!container, selected: selected, image: getSelectedColorSwatchImage(container, selected) };
  }

  function getSizeOptions(container) {
    var available = [];
    var unavailable = [];
    if (!container) return { available: available, unavailable: unavailable };
    var opts = container.querySelectorAll('li, button, [class*="item" i]');
    for (var i = 0; i < opts.length; i++) {
      var el = opts[i];
      if (sheinHasManyOptionChildren(el)) continue;
      var label = (el.getAttribute('aria-label') || el.getAttribute('title') || el.textContent || '').trim();
      if (!label || label.length > 40 || looksLikeJunkValue(label)) continue;
      var cls = ' ' + (el.className || '') + ' ';
      var isDisabled = el.getAttribute('aria-disabled') === 'true' ||
        /\s(disable|disabled|soldout|sold-out|out-of-stock|unavailable)\s/i.test(cls);
      var bucket = isDisabled ? unavailable : available;
      if (bucket.indexOf(label) === -1) bucket.push(label);
    }
    return { available: available, unavailable: unavailable };
  }

  function sheinDrawerCompoundSizeState() {
    if (__otlobliSheinDrawerPath !== location.pathname) return null;
    var groups = document.querySelectorAll('.SIZE_ITEM_HOOK');
    var picked = [], available = [], unavailable = [], found = 0;
    for (var i = 0; i < groups.length && i < 6; i++) {
      var group = groups[i];
      if (!sheinElementIsVisible(group) || sheinCovered(group)) continue;
      if (sheinIsQuantityEl(group)) continue;
      var r = group.getBoundingClientRect();
      if (r.bottom <= 0 || r.right <= 0 || r.top >= innerHeight || r.left >= innerWidth) continue;
      var opts = getSizeOptions(group);
      if (!opts.available.length && !opts.unavailable.length) continue;
      found++;
      available = opts.available;
      unavailable = opts.unavailable;
      var value = getSelectedWithin(group);
      if (!value && available.length === 1 && !unavailable.length) value = available[0];
      if (!value) return { exists: true, selected: '', available: available, unavailable: unavailable };
      if (picked.indexOf(value) < 0) picked.push(value);
    }
    if (!found) return null;
    if (picked.length === 2 && sheinPieceCountKey(picked[0]) && sheinSimpleSize(picked[1])) picked.reverse();
    return { exists: true, selected: picked.join(' / '), available: available, unavailable: unavailable };
  }

  function getSizeState() {
    var drawerState = sheinDrawerCompoundSizeState();
    if (drawerState) {
      if (drawerState.selected) drawerState.selected = sheinSkuMemo('s', drawerState.selected);
      return drawerState;
    }
    var container = findOptionContainer('size', OTLOBLI_SIZE_LABELS);
    var opts = getSizeOptions(container);
    var selected = completeSelectedCompoundSize(container, getSelectedWithin(container));
    if (!selected && opts.available.length === 1 && opts.unavailable.length === 0) selected = opts.available[0];
    selected = sheinSkuMemo('s', selected);
    return {
      exists: !!container,
      selected: selected,
      available: opts.available,
      unavailable: opts.unavailable,
    };
  }

  function sheinCovered(el) {
    try {
      var r = el.getBoundingClientRect();
      var x = r.left + r.width / 2, y = r.top + r.height / 2;
      var vw = document.documentElement.clientWidth || 0;
      var vh = document.documentElement.clientHeight || 0;
      if (x < 0 || y < 0 || x > vw || y > vh) return false;
      var top = document.elementFromPoint(x, y);
      if (!top) return false;
      return !(top === el || el.contains(top) || top.contains(el));
    } catch (e) { return false; }
  }

  var __otlobliSkuMemo = {};
  var __otlobliSheinDrawerPath = '';
  function sheinSkuMemo(key, value) {
    var m = __otlobliSkuMemo[location.pathname] || (__otlobliSkuMemo[location.pathname] = {});
    if (value) m[key] = value;
    return m[key] || '';
  }

  
  var OTLOBLI_SKU_PROMPT = /انقر للشراء|please\s*select|الرجاء الاختيار|يرجى الاختيار|اختر الخيارات/i;

  function sheinTapElement(el) {
    if (!el) return false;
    var r = el.getBoundingClientRect();
    var vw = document.documentElement.clientWidth || innerWidth;
    var vh = document.documentElement.clientHeight || innerHeight;
    var x = Math.max(1, Math.min(vw - 2, r.left + r.width / 2));
    var y = Math.max(1, Math.min(vh - 2, r.top + r.height / 2));
    var target = el;
    if (!(el.classList && el.classList.contains('j-select-to-buy'))) {
      try {
        var hit = document.elementFromPoint(x, y);
        if (hit && (hit === el || el.contains(hit))) target = hit;
      } catch (e) {}
    }
    function fire(Ctor, type, extra) {
      try {
        var init = { bubbles: true, cancelable: true, composed: true, view: window,
          detail: 1, clientX: x, clientY: y, screenX: x, screenY: y };
        for (var k in extra) init[k] = extra[k];
        return target.dispatchEvent(new Ctor(type, init));
      } catch (e) { return null; }
    }
    var touches = [];
    try {
      touches = [new Touch({ identifier: 1, target: target, clientX: x, clientY: y,
        pageX: x + scrollX, pageY: y + scrollY, screenX: x, screenY: y,
        radiusX: 12, radiusY: 12, rotationAngle: 0, force: 1 })];
    } catch (e) {}
    var pointer = { pointerId: 1, pointerType: 'touch', isPrimary: true, width: 24, height: 24, pressure: 0.5 };
    var touched = false, cancelled = false;
    if (window.PointerEvent) fire(PointerEvent, 'pointerdown', pointer);
    if (window.TouchEvent && touches.length) {
      touched = true;
      if (fire(TouchEvent, 'touchstart', { touches: touches, targetTouches: touches, changedTouches: touches }) === false) cancelled = true;
    }
    pointer.pressure = 0;
    if (window.PointerEvent) fire(PointerEvent, 'pointerup', pointer);
    if (touched && fire(TouchEvent, 'touchend', { touches: [], targetTouches: [], changedTouches: touches }) === false) cancelled = true;
    if (!cancelled) {
      fire(MouseEvent, 'mousedown');
      fire(MouseEvent, 'mouseup');
      fire(MouseEvent, 'click');
    }
    try {
      window.__otlobliTapTrace = target.tagName + '.' + String(target.className || '').slice(0, 40) +
        ' touch=' + (touched ? 1 : 0) + ' cancel=' + (cancelled ? 1 : 0) +
        ' at=' + Math.round(x) + ',' + Math.round(y);
    } catch (e) {}
    return true;
  }

  function sheinLowestOptionGroup() {
    var list = document.querySelectorAll('.SIZE_ITEM_HOOK');
    var best = null, low = -1;
    for (var i = 0; i < list.length; i++) {
      var r = list[i].getBoundingClientRect();
      if (r.height > 0 && r.bottom > low) { low = r.bottom; best = list[i]; }
    }
    return best;
  }

  function sheinClearOptionsFromButton(el) {
    if (!el) return;
    var btn = document.getElementById('otlobli-add-btn');
    var top = btn ? btn.getBoundingClientRect().top : innerHeight;
    var prev = el.style.scrollMarginBottom;
    el.style.scrollMarginBottom = (Math.max(0, innerHeight - top) + 26) + 'px';
    try { el.scrollIntoView({ block: 'end' }); } catch (e) {}
    setTimeout(function () { el.style.scrollMarginBottom = prev; }, 700);
  }

  function sheinRevealSkuOptions(round) {
    setTimeout(function () {
      var g = sheinLowestOptionGroup();
      if (!g) { if (round < 5) sheinRevealSkuOptions(round + 1); return; }
      sheinClearOptionsFromButton(g);
      if (round < 9) sheinRevealSkuOptions(9);
    }, round === 9 ? 850 : 280);
  }

  function sheinSkuPromptNode(row) {
    if (!row) return null;
    if (row.classList && row.classList.contains('j-select-to-buy')) return row;
    var hook = row.querySelector('.j-select-to-buy');
    if (hook) return hook;
    var nodes = row.querySelectorAll('li, div, span, p, a, button, i');
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i];
      if (n.children.length > 2) continue;
      var t = (n.textContent || '').replace(/\s+/g, ' ').trim();
      if (t && t.length < 30 && OTLOBLI_SKU_PROMPT.test(t) && sheinElementIsVisible(n)) return n;
    }
    return null;
  }



  function sheinSkuSelectionEntry() {
    if (!IS_SHEIN || !document.body) return null;
    var hook = document.querySelector('.j-select-to-buy');
    if (hook && sheinElementIsVisible(hook)) return hook;
    var titles = document.querySelectorAll('.goods-size__title,[class*="size__title" i]');
    for (var h = 0; h < titles.length && h < 4; h++) {
      var key = normalizedOptionText(titles[h].textContent).replace(/\s+/g, '').toLowerCase();
      if (key !== 'لون/مقاس' && key !== 'مقاس/لون' && key !== 'color/size' &&
          key !== 'size/color' && key !== 'colour/size' && key !== 'size/colour') continue;
      var row = titles[h].closest('.goods-detail__top-other') || titles[h].parentElement;
      if (!row || !sheinElementIsVisible(row) || sheinCovered(row)) continue;
      return row;
    }
    var nodes = document.querySelectorAll('li, div, span, p, a, button');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.children && el.children.length > 3) continue;
      var t = (el.textContent || '').replace(/\s+/g, ' ').trim();
      if (!t || t.length > 30) continue;
      if (OTLOBLI_SKU_PROMPT.test(t) && sheinElementIsVisible(el) && !sheinCovered(el)) return el;
    }
    return null;
  }

  function sheinOpenSkuDrawer() {
    sheinResolvedShippingRootCacheAt = 0;
    var shippingRoot = sheinShippingInteractionRoot;
    if (!(shippingRoot && shippingRoot.isConnected && sheinElementIsPainted(shippingRoot))) {
      shippingRoot = sheinResolvedShippingUiRoot();
    }
    if (shippingRoot) {
      __otlobliSheinDrawerPath = '';
      __otlobliSkuMemo[location.pathname] = {};
      showMessage(document.getElementById('otlobli-add-btn'), 'أغلق قائمة الشحن أولاً');
      return true;
    }
    if (sheinDrawerCompoundSizeState()) return false;
    var entry = sheinSkuSelectionEntry();
    if (entry) {
      if (sheinLowestOptionGroup()) {
        __otlobliSheinDrawerPath = location.pathname;
        return false;
      }
      __otlobliSheinDrawerPath = location.pathname;
      __otlobliSkuMemo[location.pathname] = {};
      var ctrl = sheinSkuPromptNode(entry) || entry;
      sheinClearOptionsFromButton(ctrl);
      setTimeout(function () {
        sheinTapElement(ctrl);
        sheinRevealSkuOptions(0);
      }, 260);
      return true;
    }
    if (sheinHeadPriceIsRange()) {
      __otlobliSkuMemo[location.pathname] = {};
      sheinClearOptionsFromButton(sheinLowestOptionGroup());
      showMessage(document.getElementById('otlobli-add-btn'), 'حدد الخيارات أولاً');
      return true;
    }
    return false;
  }

  function sheinRevealSizeOptions() {
    var group = findOptionContainer('size', OTLOBLI_SIZE_LABELS);
    if (!group) return;
    try {
      sheinClearOptionsFromButton(sheinLowestOptionGroup() || group);
      var control = group.querySelector('button:not([disabled]),[role="option"],li');
      if (control && control.focus) control.focus({ preventScroll: true });
    } catch (e) {}
  }

  function looksLikeProductPage() {
    if (IS_TEMU) {
      if (/goods/i.test(location.pathname) || /(?:^|-)g-\d+\.html$/i.test(location.pathname)) return true;
      try { return !!document.querySelector('[class*="curPrice" i]'); } catch (e) { return false; }
    }
    return /-p-\d+/i.test(location.pathname);
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

  function showAddingOverlay(payload) {
    ensureOverlayStyle();
    var existing = document.getElementById('otlobli-overlay');
    if (existing) existing.remove();
    var vp = viewportSize();
    document.body.style.overflow = 'hidden';

    var overlay = document.createElement('div');
    overlay.id = 'otlobli-overlay';
    overlay.setAttribute('data-shown-at', String(Date.now()));
    overlay.style.cssText = 'position:fixed;left:0;top:0;width:' + vp.width + 'px;height:' + vp.height + 'px;' +
      'background:rgba(13,18,22,.42);z-index:2147483646;display:flex;align-items:center;justify-content:center;';
    overlay.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });
    overlay.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); }, true);

    var card = document.createElement('div');
    card.style.cssText = 'background:transparent;border:0;border-radius:0;padding:0 28px;width:min(86vw,340px);' +
      'display:flex;flex-direction:column;align-items:center;gap:8px;animation:otlobli-pop .22s ease-out;' +
      'box-shadow:none;color:#fff;font-family:Cairo,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;text-shadow:0 1px 8px rgba(0,0,0,.28);';

    var thumbWrap = document.createElement('div');
    thumbWrap.style.cssText = 'width:34px;height:34px;border-radius:50%;overflow:hidden;background:transparent;' +
      'border:0;position:relative;margin-bottom:2px;';
    var thumb = document.createElement('img');
    thumb.id = 'otlobli-overlay-thumb';
    thumb.style.cssText = 'width:100%;height:100%;object-fit:cover;display:none;';
    thumbWrap.appendChild(thumb);
    var spinner = document.createElement('div');
    spinner.id = 'otlobli-overlay-spinner';
    spinner.style.cssText = 'position:absolute;inset:0;border-radius:50%;border:3px solid rgba(255,255,255,.24);' +
      'border-top-color:#fff;animation:otlobli-spin .8s linear infinite;';
    thumbWrap.appendChild(spinner);

    var title = document.createElement('div');
    title.id = 'otlobli-overlay-title';
    title.style.cssText = 'font-size:14px;font-weight:700;color:#fff;text-align:center;direction:rtl;line-height:1.45;max-width:100%;';

    card.appendChild(thumbWrap);
    card.appendChild(title);

    var meta = document.createElement('div');
    meta.id = 'otlobli-overlay-meta';
    meta.style.cssText = 'font-size:12px;color:rgba(255,255,255,.82);direction:rtl;line-height:1.45;text-align:center;';
    card.appendChild(meta);

    var status = document.createElement('div');
    status.id = 'otlobli-overlay-status';
    status.style.cssText = 'font-size:12px;color:#d8f7e8;font-weight:700;text-align:center;direction:rtl;margin-top:2px;line-height:1.45;';
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
    if (status) status.textContent = '✓ تم جذب المنتج بنجاح';
    var spinner = document.getElementById('otlobli-overlay-spinner');
    if (spinner) {
      spinner.style.animation = 'none';
      spinner.style.borderColor = '#1aab6f';
    }
  }

  function markOverlayFailure() {
    var status = document.getElementById('otlobli-overlay-status');
    if (status) status.textContent = 'تعذّرت إضافة المنتج — حاول مرة ثانية';
    var spinner = document.getElementById('otlobli-overlay-spinner');
    if (spinner) {
      spinner.style.animation = 'none';
      spinner.style.borderColor = '#ba1a1a';
    }
  }

  function clearAddSafetyTimer() {
    if (!window.__otlobliAddSafetyTimer) return;
    clearTimeout(window.__otlobliAddSafetyTimer);
    window.__otlobliAddSafetyTimer = 0;
  }

  function failAddFlow() {
    clearAddSafetyTimer();
    markOverlayFailure();
    removeOverlay(900);
    var addButton = document.getElementById('otlobli-add-btn');
    if (addButton) showMessage(addButton, 'تعذّرت إضافة المنتج — حاول مرة ثانية');
  }

  function removeOverlay(delay) {
    setTimeout(function () {
      var overlay = document.getElementById('otlobli-overlay');
      if (overlay) {
        overlay.style.animation = 'otlobli-fade-out .25s ease-in forwards';
        setTimeout(function () { overlay.remove(); }, 250);
      }
      otlobliReleaseAddingScrollLock();
    }, delay || 0);
  }

  function otlobliReleaseAddingScrollLock() {
    try { if (document.body) document.body.style.overflow = ''; } catch (e) {}
    try { if (document.documentElement) document.documentElement.style.overflow = ''; } catch (e) {}
  }

  function otlobliHealOrphanScrollLock() {
    if (document.getElementById('otlobli-overlay')) return;
    var bodyLocked = document.body && document.body.style.overflow === 'hidden';
    var rootLocked = document.documentElement && document.documentElement.style.overflow === 'hidden';
    if (!bodyLocked && !rootLocked) return;
    if (IS_SHEIN && (sheinShippingBodyLockState || sheinShippingUiLikelyOpen())) return;
    otlobliReleaseAddingScrollLock();
  }

  function temuCleanText(s) {
    return (s || '')
      .replace(/[\u200e\u200f\u061c\u2066\u2067\u2068\u2069\ufeff\u200b]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
  }
  function temuStripQuantity(value) {
    var v = temuCleanText(value).replace(/(?:\u0627\u0644\u0643\u0645\u064a\u0629|\u0643\u0645\u064a\u0629|quantity|qty)\s*[:：]?\s*\d*.*$/i, '');
    return temuCleanText(v);
  }
  function temuLooksLikePriceText(text) {
    var txt = temuCleanText(text || '');
    if (!txt || txt.length > 220) return false;
    if (!/[0-9٠-٩]/.test(txt)) return false;
    return /(?:US\$|\$|USD|SAR|QAR|AED|KWD|BHD|OMR|ريال|دولار|ر\.? ?س|ر\.? ?ق|د\.? ?إ|د\.? ?ك)/i.test(txt);
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

  function temuLooksLikeProductContent(el) {
    if (!el) return false;
    try {
      if (temuContainsPrice(el)) return true;
      var text = temuCleanText(el.textContent);
      if (text.length > 80 && /تم البيع|الشحن|مستودع|محلي|خصم|اللون|الكمية|sold|shipping|colour|color|quantity/i.test(text) &&
          /[0-9٠-٩]|ر\.?\s*س|ريال|SAR/i.test(text)) {
        return true;
      }
      if (el.querySelector && el.querySelector('[class*="curPrice" i], [class*="goods" i], [class*="product" i], h1, h2')) {
        return true;
      }
      var imgs = el.querySelectorAll ? el.querySelectorAll('img') : [];
      var largeProductImages = 0;
      for (var i = 0; i < imgs.length; i++) {
        var src = imgs[i].currentSrc || imgs[i].src || '';
        if (!/kwcdn|temu/i.test(src)) continue;
        var r = imgs[i].getBoundingClientRect ? imgs[i].getBoundingClientRect() : { width: 0, height: 0 };
        if (r.width >= 90 && r.height >= 90) largeProductImages++;
      }
      return largeProductImages >= 1 && text.length > 25 &&
        /تم البيع|الشحن|مستودع|محلي|خصم|اللون|الكمية|sold|shipping|colour|color|quantity/i.test(text);
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
  function temuTitle() {
    var og = getMeta('og:title') || '';
    return og.replace(/\s*[-|–—]\s*Temu\b.*$/i, '').replace(/\s+/g, ' ').trim();
  }
  function temuActiveSkuPriceText() {
    var dialogs = document.querySelectorAll('[role="dialog"]');
    var first = Math.max(0, dialogs.length - 8);
    for (var d = dialogs.length - 1; d >= first; d--) {
      var dialog = dialogs[d];
      if (!temuProductOptionDialog(dialog)) continue;
      var rect = dialog.getBoundingClientRect();
      var style = window.getComputedStyle(dialog);
      if (rect.width < 1 || rect.height < 1 || style.display === 'none' ||
          style.visibility === 'hidden' || parseFloat(style.opacity || '1') <= 0.01) continue;
      var selectors = [
        '[class*="salePriceRich" i]',
        '[class*="currentPrice" i]',
        '[class*="curPrice" i]'
      ];
      for (var s = 0; s < selectors.length; s++) {
        var priceEl = dialog.querySelector(selectors[s]);
        var priceText = temuCleanText(priceEl && priceEl.textContent);
        if (priceText.length <= 28 && temuLooksLikePriceText(priceText)) return priceText;
      }
    }
    return '';
  }
  function temuPriceUsd() {
    var best = temuActiveSkuPriceText();
    var els = document.querySelectorAll('[class*="curPrice" i]');
    for (var i = 0; !best && i < els.length; i++) {
      var t = (els[i].textContent || '').trim();
      if (t.length <= 28 && /[0-9]/.test(t)) { best = t; break; }
    }
    if (!best) return 0;
    var num = parseFloat(best.replace(/[^0-9.]/g, ''));
    if (!(num > 0) || !isFinite(num)) return 0;
    var s = best;
    var rate = 0;                                   // 0 = عملة مجهولة → يمنع
    if (/CA\$|CAD/i.test(s)) rate = 0.73;
    else if (/A\$|AUD/i.test(s)) rate = 0.66;
    else if (/NZ\$|NZD/i.test(s)) rate = 0.61;
    else if (/HK\$|HKD/i.test(s)) rate = 0.128;
    else if (/SG\$|SGD/i.test(s)) rate = 0.74;
    else if (/MX\$|MXN/i.test(s)) rate = 0.058;
    else if (/R\$|BRL/i.test(s)) rate = 0.18;
    else if (/€|EUR/i.test(s)) rate = 1.08;
    else if (/£|GBP/i.test(s)) rate = 1.27;
    else if (/₹|INR/i.test(s)) rate = 0.012;
    else if (/₺|TRY/i.test(s)) rate = 0.031;
    else if (/JOD|د\.أ/i.test(s)) rate = 1.41;     // مثبّت
    else if (/AED|د\.إ/i.test(s)) rate = 0.272;    // مثبّت
    else if (/SAR|ر\.س/i.test(s)) rate = 0.267;    // مثبّت
    else if (/QAR|ر\.ق/i.test(s)) rate = 0.275;    // مثبّت
    else if (/KWD|د\.ك/i.test(s)) rate = 3.25;     // مثبّت
    else if (/BHD/i.test(s)) rate = 2.65;           // مثبّت
    else if (/OMR/i.test(s)) rate = 2.60;           // مثبّت
    else if (/EGP|ج\.م/i.test(s)) rate = 0.020;
    else if (/US\$|USD/i.test(s)) rate = 1;        // دولار صريح
    else if (/\$/.test(s)) rate = 1;               // $ مجرّد = دولار أمريكي
    if (rate <= 0) return 0;                         // عملة مجهولة → يمنع الإضافة
    return Math.round(num * rate * 100) / 100;
  }
  function temuColor() {
    if (window.__otlobliTemuColor && window.__otlobliTemuColorGid === temuGoodsId()) {
      if (/[{};]|\bvar\b|\bfor\b|\bfunction\b/.test(window.__otlobliTemuColor)) {
        window.__otlobliTemuColor = '';
      } else {
        var stored = temuStripQuantity(window.__otlobliTemuColor);
        if (stored) return stored;
        window.__otlobliTemuColor = '';
      }
    }
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    for (var i = 0; i < nodes.length; i++) {
      var t = temuCleanText(nodes[i].textContent);
      if (t.length > 40) continue;
      var m = t.match(/^(?:Color|colour|اللون|لون(?:\s+[\u0600-\u06FF]{2,14})?)\s*[:：]\s*(.+)$/i);
      if (m && m[1]) {
        var head = temuStripQuantity(m[1]);
        if (head) return head;
      }
    }
    return '';
  }
  function temuIsColorHeadText(t) {
    t = temuCleanText(t);
    if (!t || t.length > 40) return false;
    if (t === 'اللون' || t === 'Color' || t === 'Colour' || t === 'color' || t === 'colour') return true;
    return /^(?:Color|colour|اللون|لون(?:\s+[\u0600-\u06FF]{2,14})?)\s*[:：]/i.test(t);
  }
  function temuHasColorSection() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) return true;
    }
    return false;
  }
  function temuImage() {
    if (window.__otlobliTemuColorGid === temuGoodsId()) {
      if (window.__otlobliTemuColorSwatch) return window.__otlobliTemuColorSwatch;
      if (window.__otlobliTemuColorImg) return window.__otlobliTemuColorImg;
    }
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

  function temuHasDarkBorder(el) {
    var cs = window.getComputedStyle(el);
    var bw = parseFloat(cs.borderTopWidth || '0');
    if (!(bw > 0)) return false;
    var bc = cs.borderTopColor || cs.borderColor || '';
    var m = bc.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?/i);
    if (!m) return false;
    var alpha = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (alpha < 0.4) return false;
    return (+m[1] < 95 && +m[2] < 95 && +m[3] < 95);
  }
  function temuRingStyleMatch(cs) {
    if (!cs) return false;
    var outlineStyle = cs.outlineStyle || 'none';
    var outlineW = parseFloat(cs.outlineWidth || '0');
    if (outlineStyle !== 'none' && outlineW > 0) return true;
    var shadow = cs.boxShadow || 'none';
    return !!shadow && shadow !== 'none';
  }
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
  function temuOptionUnavailable(el) {
    try {
      var node = el, depth = 0;
      while (node && node !== document.body && node !== document.documentElement && depth < 5) {
        if (node.id && node.id.indexOf('otlobli') === 0) return false;
        if (node.disabled) return true;
        if (node.getAttribute) {
          if (node.getAttribute('disabled') !== null) return true;
          if (node.getAttribute('aria-disabled') === 'true') return true;
          var dataAttrs = ['data-disabled', 'data-sold-out', 'data-soldout', 'data-out-of-stock', 'data-unavailable', 'data-status', 'data-stock-status'];
          for (var da = 0; da < dataAttrs.length; da++) {
            var dv = node.getAttribute(dataAttrs[da]);
            if (dv && /^(?:1|true|disabled|soldout|sold-out|outofstock|out-of-stock|unavailable|notavailable|not-available)$/i.test(dv)) return true;
          }
          var clsRaw = (node.className && node.className.baseVal !== undefined) ? node.className.baseVal : (node.className || '');
          var hint = (' ' + clsRaw + ' ' + (node.id || '') + ' ' +
            (node.getAttribute('aria-label') || '') + ' ' + (node.getAttribute('title') || '') + ' ').toLowerCase();
          if (/(?:^|[\s_-])(?:disable|disabled|soldout|sold-out|sold_out|outofstock|out-of-stock|out_of_stock|unavailable|notavailable|not-available)(?:$|[\s_-])/i.test(hint)) return true;
          var role = (node.getAttribute('role') || '').toLowerCase();
          var choiceShell = role === 'radio' || node.getAttribute('aria-checked') !== null || node.getAttribute('aria-selected') !== null;
          if (depth === 0 && choiceShell && node.querySelector) {
            var disabledChild = node.querySelector('[disabled], [aria-disabled="true"], [data-disabled="true"], [data-disabled="1"], [data-sold-out], [data-soldout], [data-out-of-stock], [data-unavailable], [class*="disabled"], [class*="disable"], [class*="soldout"], [class*="sold-out"], [class*="outofstock"], [class*="out-of-stock"], [class*="unavailable"], [class*="notavailable"], [class*="not-available"]');
            if (disabledChild) return true;
          }
          var txt = temuCleanText((node.getAttribute('aria-label') || '') + ' ' +
            (node.getAttribute('title') || '') + ' ' + (node.textContent || ''));
          if (txt && txt.length <= 140 &&
              /sold\s*out|out\s*of\s*stock|unavailable|not\s*available|غير\s+مت(?:وفر|اح)|نفد|نفدت|انتهى\s+المخزون|مباع|تم\s+البيع/i.test(txt)) return true;
        }
        if (depth <= 2 && node.getBoundingClientRect) {
          var cs = window.getComputedStyle(node);
          var op = parseFloat(cs.opacity || '1');
          if (!isNaN(op) && op > 0 && op < 0.45) return true;
          if (cs.pointerEvents === 'none') return true;
        }
        node = node.parentElement; depth++;
      }
    } catch (e) {}
    return false;
  }

  function temuVisibleOptionTextAvailable(optionText) {
    var wanted = temuCleanText(optionText);
    if (!wanted) return false;
    var saw = false;
    try {
      var nodes = document.querySelectorAll('[role="radio"], [aria-checked], [aria-selected], button, [role="button"]');
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].id && nodes[i].id.indexOf('otlobli') === 0) continue;
        if (temuCleanText(nodes[i].textContent) !== wanted) continue;
        saw = true;
        if (!temuOptionUnavailable(nodes[i])) return true;
      }
    } catch (e) {}
    return !saw;
  }

  function otlobliTemuMarkUnavailableTap() {
    try {
      window.__otlobliTemuUnavailableTapGid = temuGoodsId();
      window.__otlobliTemuUnavailableTapTs = Date.now();
    } catch (e) {}
  }

  function otlobliTemuRecentUnavailableTap() {
    try {
      return window.__otlobliTemuUnavailableTapGid === temuGoodsId() &&
        window.__otlobliTemuUnavailableTapTs &&
        (Date.now() - window.__otlobliTemuUnavailableTapTs) < 8000;
    } catch (e) {}
    return false;
  }

  function temuLightBackground(el) {
    var bg = window.getComputedStyle(el).backgroundColor || '';
    var m = bg.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?/i);
    if (!m) return true;
    var alpha = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (alpha < 0.1) return true;            // شفاف = فاتح
    return (+m[1] > 140 || +m[2] > 140 || +m[3] > 140);
  }
  function temuVariantColorCountMatch(txt) {
    return temuCleanText(txt).match(/(\d+)\s*(?:اللون|لون|ألوان|الألوان|colou?rs?)/i);
  }
  function temuVariantSecondOptionCountMatch(txt) {
    var dimensionCount = temuCleanText(txt).match(/(\d+)\s*(?:الحجم|حجم)/i);
    if (dimensionCount) return dimensionCount;
    return temuCleanText(txt).match(/(\d+)\s*(?:الموديل|موديل|models?|مقاس|مقاسات|sizes?|أسلوب|نمط|style|نوع|type|ram|rom|memory|storage|capacity|gb|g\b|ذاكرة|الذاكرة|رام|الرام|سعة|السعة|تخزين|التخزين|أغراض|اغراض|الأغراض|الاغراض|غرض|الغرض|عنصر|العنصر|عناصر|العناصر|قطع|القطع|قطعة|القطعة|items?|pieces?|pcs?)/i);
  }
  function temuVariantSecondOptionName(txt) {
    var t = temuCleanText(txt);
    if (/موديل|models?/i.test(t)) return 'الموديل';
    if (/أسلوب|نمط|style|نوع|type/i.test(t)) return 'أسلوب';
    if (/أغراض|اغراض|غرض|عنصر|عناصر|قطع|قطعة|items?|pieces?|pcs?/i.test(t)) return 'أغراض';
    return 'مقاس';
  }
  function temuLooksLikeVariantOptionLabel(text) {
    var ht = temuCleanText(text);
    if (!ht || ht.length > 58) return false;
    if (/guide|chart|info|دليل/i.test(ht)) return false;
    if (!/[:：]/.test(ht) && ht.length > 14) return false;
    if (/^(?:Size|Compatible\s*Model|Model|Style|Type|Memory|Storage|Capacity|RAM|ROM|Items?|Pieces?|PCS)\s*[:：]?/i.test(ht)) return true;
    if (/^(?:ال)?(?:مقاس|قياس|حجم|موديل|أسلوب|نمط|نوع|ذاكرة|رام|سعة|تخزين|أغراض|اغراض|غرض|عنصر|عناصر|قطع|قطعة)\s*[:：]?/i.test(ht)) return true;
    return false;
  }
  function temuSizeHeadEl() {
    var heads = document.querySelectorAll('div, span, h2, h3, strong, label, p');
    for (var h = 0; h < heads.length; h++) {
      var ht = temuCleanText(heads[h].textContent);
      if (temuLooksLikeVariantOptionLabel(ht)) return heads[h];
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
  function temuVariantCounts() {
    var el = temuVariantSummaryEl();
    var txt = el ? temuCleanText(el.textContent) : '';
    var cMatch = temuVariantColorCountMatch(txt);
    var sMatch = temuVariantSecondOptionCountMatch(txt);
    return {
      colors: cMatch ? parseInt(cMatch[1], 10) : -1,  // -1 = غير معروف
      sizes:  sMatch ? parseInt(sMatch[1], 10) : -1,
    };
  }
  function temuBorderDarkness(el) {
    var bc = window.getComputedStyle(el).borderTopColor || '';
    var m = bc.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?/i);
    if (!m) return 999;
    var a = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (a < 0.3) return 999;
    return (+m[1] + +m[2] + +m[3]);
  }
  function temuBorderWidth(el) {
    var bw = parseFloat(window.getComputedStyle(el).borderTopWidth || '0');
    return isNaN(bw) ? 0 : bw;
  }
  function temuPickSingleSelected(els) {
    if (!els || els.length < 2) return null;
    var availableEls = [];
    for (var ae = 0; ae < els.length; ae++) {
      if (!temuOptionUnavailable(els[ae])) availableEls.push(els[ae]);
    }
    els = availableEls;
    if (els.length < 2) return null;
    var semantic = [];
    for (var s = 0; s < els.length; s++) {
      if (temuHasSemanticSelectedMarker(els[s])) semantic.push(els[s]);
    }
    if (semantic.length === 1) return semantic[0];
    var filled = [];
    for (var i = 0; i < els.length; i++) {
      var bg = window.getComputedStyle(els[i]).backgroundColor || '';
      var bm = bg.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?/i);
      if (!bm) continue;
      var ba = bm[4] !== undefined ? parseFloat(bm[4]) : 1;
      if (ba < 0.5) continue;
      if ((+bm[1] + +bm[2] + +bm[3]) < 240) filled.push(els[i]);
    }
    if (filled.length === 1) return filled[0];
    var ringed = [];
    for (var r = 0; r < els.length; r++) {
      if (temuHasRingHighlight(els[r])) ringed.push(els[r]);
    }
    if (ringed.length === 1) return ringed[0];
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
    var borderMatches = [];
    for (var b = 0; b < els.length; b++) {
      if (temuHasDarkBorder(els[b])) borderMatches.push(els[b]);
    }
    if (borderMatches.length === 1) return borderMatches[0];
    return null;
  }
  function temuSizeLike(t) {
    if (/\d/.test(t)) return true;
    return /^(?:x{0,3}[sml]|xs|xxs|one.?size|free.?size)$/i.test(t);
  }
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
        if (temuOptionUnavailable(el)) continue;
        var t = temuCleanText(el.textContent);
        if (t.length < 1 || t.length > 24) continue;
        if (t.length === 1 && !/[a-zA-Z0-9]/.test(t)) continue;
        if (t.indexOf(':') >= 0) continue;
        if (/[$£€%]/.test(t)) continue;
        if (/\bfree\b|\bapp\b|guide|standard|qty|^size$/i.test(t)) continue;
        if (/^(?:us|ca|eu|uk|au|jo|sa|ae|kw|qa|bh|om|asia|intl)$/i.test(t)) continue;
        if (t === 'قياسي' || t === 'عادي' || t === 'الطول' || t === 'العمر' || t === 'الوزن'
          || /دليل|كمية|كميه/.test(t)) continue;
        if (/^\d+$/.test(t)) {
          var qPrev = el.previousElementSibling, qNext = el.nextElementSibling;
          var qPv = qPrev ? temuCleanText(qPrev.textContent) : '';
          var qNx = qNext ? temuCleanText(qNext.textContent) : '';
          var isStep = function (s) { return s === '+' || s === '-' || s === '−'; };
          if (isStep(qPv) && isStep(qNx)) continue;
        }
        if (el.querySelector && el.querySelector('img')) continue;
        var r = el.getBoundingClientRect();
        if (r.width < 18 || r.width > 260 || r.height < 16 || r.height > 80) continue;
        pills.push(el);
      }
      if (pills.length) {
        var byCls = {}, order = [];
        for (var p2 = 0; p2 < pills.length; p2++) {
          var ck = ((pills[p2].className || '') + '|' + pills[p2].tagName);
          if (!byCls[ck]) { byCls[ck] = []; order.push(ck); }
          byCls[ck].push(pills[p2]);
        }
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
        if (weak && weak.length <= 10 && hops <= 3 && weak.length > weakBest.length) {
          weakBest = weak;
        }
      }
      container = container.parentElement; hops++;
    }
    return weakBest;
  }
  function temuGoodsId() {
    var m = location.href.match(/goods_id=(\d+)/);
    return m ? m[1] : location.pathname;
  }
  function temuSelectedSizeFromLabel() {
    var head = temuSizeHeadEl();
    if (head) {
      var headText = temuCleanText(head.textContent);
      var inlineVal = headText.match(/[:：]\s*(.{1,44})$/);
      if (inlineVal && inlineVal[1]) {
        var iv = inlineVal[1].trim();
        if (iv.length >= 1 && !/دليل|guide|chart/i.test(iv)) return iv;
      }
      var hm = headText.match(/Size[\s\-]*[:\-]?[\s\-]*(one.?size|free.?size|[\w ]{2,20})/i);
      if (hm && hm[1]) {
        var hv = hm[1].trim();
        if (!/^size$/i.test(hv) && hv.length >= 2) return hv;
      }
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
    var els = document.querySelectorAll('div, span, p, strong, h3, h2');
    for (var si = 0; si < els.length; si++) {
      var st = temuCleanText(els[si].textContent);
      if (st.length < 4 || st.length > 80) continue;
      var sm = st.match(/Size\s*:\s*([^,;|\n\r]{1,30})/i);
      if (!sm) sm = st.match(/^(?:المقاس|مقاس|الحجم)\s*[:：]\s*([^,;|\n\r]{1,30})/);
      if (sm && sm[1]) {
        var sv = sm[1].trim();
        if (sv.length >= 2 && sv.length <= 30 && !/guide|chart|info|دليل/i.test(sv)) return sv;
      }
    }
    return '';
  }
  function temuSelectedSize() {
    var structuralMultiSize = false;
    try {
      var sk = otlobliTemuSku();
      for (var d = 0; d < sk.dims.length; d++) {
        var dd = sk.dims[d];
        if (dd.kind !== 'size') continue;
        if (dd.selected && dd.selected !== 'محدد' && dd.selected.length <= 30) return dd.selected;
        if (dd.count > 1) structuralMultiSize = true;
      }
    } catch (e) {}
    if (window.__otlobliTemuSize && window.__otlobliTemuSizeGid === temuGoodsId()) {
      var cachedSize0 = temuCleanText(window.__otlobliTemuSize);
      if (cachedSize0 && cachedSize0.length <= 40 && temuVisibleOptionTextAvailable(cachedSize0)) return cachedSize0;
    }
    if (structuralMultiSize) {
      window.__otlobliTemuSizeDiag = 'عدة مقاسات بلا اختيار صريح';
      return '';
    }
    var pills = temuSizePills();
    if (pills.length < 1) {
      var headFound = !!temuSizeHeadEl();
      window.__otlobliTemuSizeDiag = headFound ? 'رأس موجود، صفر أزرار مطابقة' : 'لا رأس قسم مقاس';
      return temuSelectedSizeFromLabel();
    }
    if (window.__otlobliTemuSize && window.__otlobliTemuSizeGid === temuGoodsId()) {
      for (var k = 0; k < pills.length; k++) {
        if (!temuOptionUnavailable(pills[k]) && temuCleanText(pills[k].textContent) === window.__otlobliTemuSize) return window.__otlobliTemuSize;
      }
    }
    if (pills.length === 1) {
      return temuCleanText(pills[0].textContent);
    }
    window.__otlobliTemuSizeDiag = 'أزرار متعددة بلا اختيار صريح';
    return '';
  }
  function temuForceSingleSize() {
    if (!temuHasSizeSection() || temuSelectedSize()) return;
    var fpills = temuSizePills();
    if (fpills.length === 1) {
      var ft = temuCleanText(fpills[0].textContent);
      if (ft && ft.length <= 24) {
        window.__otlobliTemuSize = ft;
        window.__otlobliTemuSizeGid = temuGoodsId();
      }
    } else if (fpills.length === 0) {
      var fsum = temuVariantSummaryEl();
      if (fsum && /\b1\s*(?:size|مقاس|موديل|أسلوب)|مقاس\s*واحد/i.test(fsum.textContent || '')) {
        window.__otlobliTemuSize = 'ONE SIZE';
        window.__otlobliTemuSizeGid = temuGoodsId();
      }
    }
  }
  function temuColorChoiceCardCount() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    var colorHead = null;
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) { colorHead = nodes[i]; break; }
    }
    if (!colorHead) return 0;
    var container = colorHead.parentElement, hops = 0;
    while (container && hops < 5) {
      var imgs = container.querySelectorAll('img');
      var count = 0;
      for (var j = 0; j < imgs.length; j++) {
        var src = imgs[j].currentSrc || imgs[j].src || '';
        if (!/kwcdn|temu/i.test(src)) continue;
        var r = imgs[j].getBoundingClientRect();
        if (r.width >= 28 && r.width < 200 && r.height >= 28 && r.height < 200 && !temuOptionUnavailable(imgs[j].parentElement || imgs[j])) count++;
      }
      if (count >= 1) return count;
      container = container.parentElement; hops++;
    }
    return 0;
  }
  function temuHasSingleColor() {
    var count = temuColorChoiceCardCount();
    if (count >= 1) return count === 1;
    return !!temuColorFromHeading();
  }
  function temuColorFromHeading() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    for (var i = 0; i < nodes.length; i++) {
      var t = temuCleanText(nodes[i].textContent);
      if (t.length > 40) continue;
      var m = t.match(/^(?:Color|colour|اللون|لون(?:\s+[\u0600-\u06FF]{2,14})?)\s*[:：]\s*(.+)$/i);
      if (m && m[1]) {
        var cv = m[1].trim();
        if (cv.length >= 2 && cv.length <= 40 && !/[{};]/.test(cv)) return cv;
      }
    }
    return '';
  }
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
        if (temuOptionUnavailable(imgs[j].parentElement || imgs[j])) continue;
        swCount++;
        var alt = temuCleanText(imgs[j].getAttribute('alt') || imgs[j].getAttribute('title') || '').toLowerCase();
        var ptxt = imgs[j].parentElement ? temuCleanText(imgs[j].parentElement.textContent).toLowerCase() : '';
        if ((alt && alt.length >= 2 && (alt === lowName || alt.indexOf(lowName) >= 0 || lowName.indexOf(alt) >= 0))
          || (ptxt && ptxt.length <= 50 && ptxt.indexOf(lowName) >= 0)) { match = src; }
      }
      if (swCount >= 1) return match;
      container = container.parentElement; hops++;
    }
    return '';
  }
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
        if (temuOptionUnavailable(parentEl)) continue;
        var ptxt = temuCleanText(parentEl.textContent).toLowerCase();
        if ((alt && alt.length >= 2 && (alt === lowName || alt.indexOf(lowName) >= 0 || lowName.indexOf(alt) >= 0))
          || (ptxt && ptxt.length <= 50 && ptxt.indexOf(lowName) >= 0)) { matches.push(parentEl); }
      }
      if (imgs.length >= 1) return matches.length === 1 ? matches[0] : null;
      container = container.parentElement; hops++;
    }
    return null;
  }
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
        if (temuOptionUnavailable(parentEl) || temuOptionUnavailable(grandEl)) continue;
        cards.push({ img: imgs[j], src: src, parentEl: parentEl, grandEl: grandEl });
        parentEls.push(parentEl);
        grandEls.push(grandEl);
      }
      if (cards.length >= 1) {
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
        if (hr.top > vpH2 * 0.5) continue;
        var ha = hr.width * hr.height;
        if (ha > hbestA) { hbestA = ha; hbest = hsrc; }
      }
      if (hbest) window.__otlobliTemuColorImg = hbest;
    }
    setTimeout(captureHero2, 700);
    setTimeout(captureHero2, 1600);
  }
  if (IS_TEMU && !window.__otlobliTemuClickBound) {
    window.__otlobliTemuClickBound = true;
    document.addEventListener('click', function (e) {
      try {
        var tEl0 = e.target;
        var inRadio0 = (tEl0 && tEl0.closest) ? tEl0.closest('[role="radio"]') : null;
        var inSku0 = (tEl0 && tEl0.closest) ? tEl0.closest('[class*="skuSelector"]') : null;
        window.__otlobliLastTap = {
          tag: (tEl0 && tEl0.tagName) || '?',
          radio: !!inRadio0, sku: !!inSku0,
          before: inRadio0 ? (inRadio0.getAttribute('aria-checked') || '?') : '-',
          after: '?'
        };
        if (inRadio0 && temuOptionUnavailable(inRadio0)) {
          window.__otlobliLastTap.disabled = 'yes';
          otlobliTemuMarkUnavailableTap();
        }
        if (inRadio0) {
          setTimeout(function () {
            try { if (window.__otlobliLastTap) window.__otlobliLastTap.after = inRadio0.getAttribute('aria-checked') || '?'; } catch (e2) {}
          }, 450);
          (function (radioEl, gidAtClick) {
            setTimeout(function () {
              try {
                if (temuOptionUnavailable(radioEl)) {
                  if (window.__otlobliLastTap) window.__otlobliLastTap.disabled = 'yes';
                  return;
                }
                window.__otlobliTemuUnavailableTapTs = 0;
                var groupName = otlobliTemuSkuOptionGroupName(radioEl);
                var optionText = otlobliTemuSkuOptionValue(radioEl, false);
                var hasImage = !!(radioEl.querySelector && radioEl.querySelector('img'));
                var colorGroup = /اللون|لون|colou?r/i.test(groupName) || (hasImage && !/موديل|مقاس|size|model|iphone|آيفون|ايفون/i.test(groupName));
                if (!colorGroup && optionText && optionText.length <= 40
                    && !/أضف|السلة|الكمية|quantity|shipping|خصم|عرض/i.test(optionText)) {
                  window.__otlobliTemuSize = optionText;
                  window.__otlobliTemuSizeGid = gidAtClick;
                }
              } catch (e3) {}
            }, 120);
          })(inRadio0, temuGoodsId());
        }
      } catch (eTap) {}
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
              var relX2 = (e.clientX - nr2.left) / Math.max(1, nr2.width);
              var idx2 = Math.floor((1 - relX2) * 4);
              if (idx2 < 0) idx2 = 0; if (idx2 > 3) idx2 = 3;
              var types2 = ['openHome', 'openOrders', 'openCart', 'openProfile'];
              if (types2[idx2] && window.mobileApp && window.mobileApp.postMessage) {
                if (types2[idx2] === 'openHome') {
                  try {
                    var homePath2 = sessionStorage.getItem('__otlobliHomePath') || (location.hostname.indexOf('temu.') >= 0 ? '/sa/' : '/ar/');
                    location.assign(location.origin + homePath2);
                  } catch (homeError2) {}
                  return;
                }
                var nativeTarget2 = types2[idx2] === 'openOrders' ? 'orders' : (types2[idx2] === 'openCart' ? 'cart' : 'profile');
                if (typeof window.mobileApp.navigate === 'function') {
                  window.mobileApp.navigate(nativeTarget2);
                } else {
                  window.mobileApp.postMessage({ detail: { type: types2[idx2] } });
                  if (typeof window.mobileApp.hide === 'function') window.mobileApp.hide();
                }
              }
              try { (document.documentElement || document.body).appendChild(navEl2); } catch (err2) {}
              return;
            }
          }
        }
      } catch (errNav) {}
      try {
        if (!window.__otlobliTemuHeadingTimer) {
          window.__otlobliTemuHeadingTimer = setTimeout(function () {
            window.__otlobliTemuHeadingTimer = null;
            try {
              var hc = temuColorFromHeading();
              var gidH = temuGoodsId();
              var recentCardClick = window.__otlobliTemuColorGid === gidH
                && window.__otlobliTemuColorTs && (Date.now() - window.__otlobliTemuColorTs) < 1200;
              if (hc && !recentCardClick && (window.__otlobliTemuColorGid !== gidH || window.__otlobliTemuColor !== hc)) {
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
        var pills = temuSizePills();
        var node = e.target, hops = 0;
        while (node && hops < 4 && pills.length) {
          var matched = false;
          for (var i = 0; i < pills.length; i++) {
            if (pills[i] === node) {
              var t = temuCleanText(node.textContent);
              if (t && t.length <= 24) {
                window.__otlobliTemuUnavailableTapTs = 0;
                window.__otlobliTemuSize = t;
                window.__otlobliTemuSizeGid = temuGoodsId();
              }
              matched = true; break;
            }
          }
          if (matched) return;
          node = node.parentElement; hops++;
        }
        if (temuHasColorSection()) {
          var isOkColorName = function(s) {
            return s.length >= 2 && s.length <= 50
              && /^[a-zA-Z\u0600-\u06FF]/.test(s)
              && !/^(color|image|select|add|qty|free|shipping|size)$/i.test(s)
              && !/[{};]|\bvar\b|\bfor\b|\bfunction\b/.test(s);
          };
          var cnode = e.target, ch = 0;
          while (cnode && ch < 6) {
            var cr3 = cnode.getBoundingClientRect ? cnode.getBoundingClientRect() : null;
            var cnodeUnavailable = temuOptionUnavailable(cnode);
            if (cnodeUnavailable) otlobliTemuMarkUnavailableTap();
            if (!cnodeUnavailable && cr3 && cr3.width > 20 && cr3.width < 300 && cr3.height > 20 && cr3.height < 420) {
              var cImgs = cnode.querySelectorAll ? cnode.querySelectorAll('img') : [];
              if (cImgs.length >= 1 && cImgs.length <= 4) {
                var cardImg2 = cImgs[0];
                var altN2 = temuCleanText(cardImg2.getAttribute('alt') || cardImg2.getAttribute('title') || '');
                var colorName2 = isOkColorName(altN2) ? altN2 : '';
                if (!colorName2) {
                  var cKids = cnode.children ? cnode.children : [];
                  for (var ck = cKids.length - 1; ck >= 0 && !colorName2; ck--) {
                    var ckTag = (cKids[ck].tagName || '').toLowerCase();
                    if (ckTag === 'img' || ckTag === 'script' || ckTag === 'style'
                        || ckTag === 'picture' || ckTag === 'source'
                        || ckTag === 'canvas' || ckTag === 'svg') continue;
                    var ckTxt = (cKids[ck].textContent || '')
                      .replace(/[^\w\u0600-\u06FF\s().\-]/g, ' ')
                      .replace(/\s+/g, ' ').trim();
                    if (isOkColorName(ckTxt)) colorName2 = ckTxt;
                  }
                }
                colorName2 = temuStripQuantity(colorName2);
                if (colorName2) {
                  var gidNow = temuGoodsId();
                  window.__otlobliTemuUnavailableTapTs = 0;
                  window.__otlobliTemuColor = colorName2;
                  window.__otlobliTemuColorGid = gidNow;
                  window.__otlobliTemuColorTs = Date.now();
                  var cSrc = cardImg2.currentSrc || cardImg2.src || '';
                  window.__otlobliTemuColorSwatch = (cSrc && cSrc.indexOf('http') === 0) ? cSrc : '';
                  window.__otlobliTemuColorImg = '';
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
                        if (hr.top > vpH0 * 0.5) continue;
                        var ha = hr.width * hr.height;
                        if (ha > hbestA) { hbestA = ha; hbest = hsrc; }
                      }
                      if (hbest) window.__otlobliTemuColorImg = hbest;
                    }
                  setTimeout(captureHero, 700);
                  setTimeout(captureHero, 1600);
                  })(gidNow);
                  return;
                }
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
                      window.__otlobliTemuUnavailableTapTs = 0;
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

  var TEMU_PERSO_STRONG = /personaliz|engrav|محفور|محفورة|حفر\s*اسم|نقش\s*اسم|نقش\s*الاسم|نقش\s*نص|custom\s*text|custom\s*name|customiz|اكتب\s*اسم|اسم\s*مخصص|نص\s*مخصص|اكتب\s*نص|باسمك|بأسمك/i;
  var TEMU_PERSO_INPUT = /نقش|اسم|نص\s*مخصص|[أإا]دخ[اآ]?ل\s*(?:النص|الاسم)|اكتب\s*(?:النص|الاسم)|personaliz|engrav|custom|your\s*(?:name|text)|enter\s*(?:name|text)/i;
  var TEMU_PERSO_ANTI = /كمية|كميه|qty|quantit|بحث|search|coupon|promo|كوبون|رمز|code|zip|postal|هاتف|phone|جوال|بريد|email|عنوان|address|password|كلمة/i;
  function temuPersoInputHint(inp) {
    var hint = (inp.getAttribute('placeholder') || '') + ' ' +
      (inp.getAttribute('aria-label') || '') + ' ' +
      (inp.getAttribute('name') || '') + ' ' + (inp.id || '');
    var par = inp.parentElement;
    for (var h = 0; par && h < 2; h++) {
      var pt = (par.textContent || '').trim();
      if (pt.length <= 90) hint += ' ' + pt;
      par = par.parentElement;
    }
    return hint;
  }
  function temuPersonalization() {
    var titleTxt = (temuTitle() || '') + ' ' + (document.title || '');
    var hasStrong = TEMU_PERSO_STRONG.test(titleTxt);
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
      if (/^\d+$/.test(v)) v = '';                        // قيمة رقمية بحتة = ليست نص نقش
      var lim = parseInt(inp.getAttribute('maxlength') || '', 10);
      if (!(lim > 0 && lim <= 80)) {
        var lm = hint.match(/(\d{1,2})\s*(?:حرف|أحرف|حروف|characters?|chars?|letters?)/i);
        lim = lm ? parseInt(lm[1], 10) : 0;
      }
      return { has: true, text: v, inputVisible: true, textLimit: (lim > 0 && lim <= 80) ? lim : 0 };
    }
    if (hasStrong) return { has: true, text: '', inputVisible: false, textLimit: 0 };
    return { has: false, text: '', textLimit: 0 };
  }
  function temuCustomBadgeVisible() {
    var els = document.querySelectorAll('div, span, a, button, label');
    var scrollY = window.pageYOffset || 0;
    for (var i = 0; i < els.length; i++) {
      var t = temuCleanText(els[i].textContent);
      if (!t || t.length > 20) continue;
      if (!/^(?:التخصيص|تخصيص|قابل\s*للتخصيص|customi[sz]ed?|personali[sz]ed?)$/i.test(t)) continue;
      var r = els[i].getBoundingClientRect();
      if (r.width <= 0 || r.height <= 0) continue;
      if (r.top + scrollY > 900) continue;
      return true;
    }
    return false;
  }
  function temuPhotoUploadControl() {
    if (document.querySelector('input[type="file"][accept*="image"], input[type="file"]:not([accept])')) return true;
    var els = document.querySelectorAll('button, a, div, span, label');
    for (var i = 0; i < els.length; i++) {
      var t = temuCleanText(els[i].textContent);
      if (!t || t.length > 22) continue;
      if (!/^(?:أضف|إضافة|ارفع|رفع|تحميل|حمّل)\s*(?:ال)?صورة(?:\s*هنا)?$|^(?:add|upload)\s*(?:a\s*|your\s*)?(?:photo|image|picture)s?$/i.test(t)) continue;
      var r = els[i].getBoundingClientRect();
      if (r.width > 0 && r.height > 0) return true;
    }
    return false;
  }
  function temuCustomPhotoNote() {
    var els = document.querySelectorAll('div, span, p, li, strong, td, th');
    for (var i = 0; i < els.length; i++) {
      var t = (els[i].textContent || '').trim();
      if (!t || t.length < 4 || t.length > 120) continue;
      if (/\d+\s*[*x×]\s*\d+\s*(?:px|pixel|بكسل)?/i.test(t)
       || /photo.*size|size.*photo|صورة.*حجم|حجم.*صورة|image.*size|size.*image/i.test(t)
       || /ratio|aspect|نسبة.*صورة|صورة.*نسبة/i.test(t)) {
        return t.slice(0, 100);
      }
    }
    return '';
  }

  function otlobliCustomTextSignal(text) {
    return /custom\s*(?:text|name)|personali[sz]|engrav|monogram|name\s*plate|your\s*(?:name|text)|enter\s*(?:name|text)|نقش\s*(?:اسم|الاسم|نص|النص|حسب)|قابل\s*للنقش|انقش|محفور(?:ة)?\s*(?:باسم|بالاسم|باسمك)|حفر\s*(?:اسم|الاسم|نص)|بالاسم|باسمك|بأسمك|اسم\s*مخصص|نص\s*مخصص|اكتب\s*(?:اسم|الاسم|نص|النص)/i.test(text || '');
  }

  function otlobliCustomPhotoSignal(text) {
    return /custom\s*(?:photo|image|picture)|(?:upload|add)\s*(?:a\s*|your\s*)?(?:photo|image|picture)|photo\s*upload|image\s*upload|with\s*your\s*(?:photo|picture)|صورة\s*مخصصة|بصورتك|صورتك|بالصور|(?:أضف|إضافة|ارفع|رفع|تحميل|حمّل)\s*(?:ال)?صورة/i.test(text || '');
  }

  function otlobliCustomGenericSignal(text) {
    return /customi[sz]|\bcustom\b|personali[sz]|مخصص|التخصيص|تخصيص|بتصميمك|حسب\s*الطلب|\bDIY\b/i.test(text || '');
  }

  function otlobliVisibleCustomText() {
    var out = [];
    var nodes = document.querySelectorAll('h1, h2, h3, p, span, div, button, label, li');
    for (var i = 0; i < nodes.length && out.join(' ').length < 5000; i++) {
      var el = nodes[i];
      var r = el.getBoundingClientRect();
      if (r.width <= 0 || r.height <= 0) continue;
      var t = (el.textContent || '').replace(/\s+/g, ' ').trim();
      if (!t || t.length > 180) continue;
      if (otlobliCustomGenericSignal(t) || otlobliCustomTextSignal(t) || otlobliCustomPhotoSignal(t) || /\d+\s*[*x×]\s*\d+/.test(t)) {
        out.push(t);
      }
    }
    return out.join(' ');
  }

  function otlobliCustomPhotoNoteFallback() {
    var pageText = otlobliVisibleCustomText();
    var sizeMatch = pageText.match(/\d+\s*[*x×]\s*\d+\s*(?:px|pixel|بكسل)?/i);
    if (sizeMatch) return sizeMatch[0];
    if (otlobliCustomPhotoSignal(pageText)) return 'يرجى إرفاق الصورة المطلوبة لهذا المنتج المخصص';
    return '';
  }

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
    if (!needsPhoto && /(?:^|[\s،:])(?:عين|عيون|للعينين|بالعين|وجه|وجهك|بورتريه)|\bface\b|\beyes?\b|\bportrait\b/i.test(titleTxt)) needsPhoto = true;
    if (!needsText && !needsPhoto && /(phone|case|cover|جراب|كفر|حافظة)/i.test(titleTxt)) needsPhoto = true;
    if (!needsText && !needsPhoto) needsText = true;
    return {
      needsText: needsText,
      needsPhoto: needsPhoto,
      photoNote: needsPhoto ? (temuCustomPhotoNote() || otlobliCustomPhotoNoteFallback()) : '',
      textLimit: (perso && perso.textLimit) || 0,
    };
  }

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

  function temuHasSizeSection() { return !!temuSizeHeadEl(); }
  function temuProductOptionDialog(node) {
    if (!IS_TEMU || !looksLikeProductPage() || !node || !node.querySelectorAll) return false;
    var dialog = node.matches && node.matches('[role="dialog"]')
      ? node
      : (node.closest && node.closest('[role="dialog"]'));
    if (!dialog || dialog.querySelectorAll('[role="radio"]').length < 2) return false;
    return !!dialog.querySelector('[class*="sku" i],[class*="spec" i]');
  }
  function temuHasSelectableSecondOption() {
    var pills = temuSizePills();
    if (pills.length > 0) return true;
    var counts = temuVariantCounts();
    return counts.sizes > 1;
  }
  function temuVariantSummaryEl() {
    var els = document.querySelectorAll('div, button, a, span');
    for (var i = 0; i < els.length; i++) {
      var t = temuCleanText(els[i].textContent);
      if (t.length > 65) continue;
      var hasClr = !!temuVariantColorCountMatch(t);
      var hasSz  = !!temuVariantSecondOptionCountMatch(t);
      if (hasClr && hasSz) return els[i];
    }
    return null;
  }

  function otlobliTemuCollapsedVariantRow() {
    try {
      var triggers = document.querySelectorAll('button, [role="button"], a, div, span');
      for (var i = 0; i < triggers.length; i++) {
        var trigger = triggers[i];
        if (trigger.id && trigger.id.indexOf('otlobli') === 0) continue;
        var triggerText = temuCleanText((trigger.getAttribute && (trigger.getAttribute('aria-label') || trigger.getAttribute('title'))) || trigger.textContent || '');
        if (!/^(?:حدد|select|choose)$/i.test(triggerText) && !/(?:حدد|select|choose)/i.test(triggerText)) continue;
        var tr = trigger.getBoundingClientRect ? trigger.getBoundingClientRect() : null;
        if (tr && (tr.width <= 0 || tr.height <= 0)) continue;
        var node = trigger, depth = 0;
        while (node && node !== document.body && depth < 6) {
          var r = node.getBoundingClientRect ? node.getBoundingClientRect() : null;
          if (r && (r.width <= 0 || r.height <= 0)) { node = node.parentElement; depth++; continue; }
          var txt = temuCleanText((node.getAttribute && (node.getAttribute('aria-label') || node.getAttribute('title'))) || node.textContent || '');
          if (txt.length >= 8 && txt.length <= 220 && /(?:حدد|select|choose)/i.test(txt) && !temuContainsPrice(node)) {
            var colorMatch = temuVariantColorCountMatch(txt);
            var sizeMatch = temuVariantSecondOptionCountMatch(txt);
            var colorCount = colorMatch ? (parseInt(colorMatch[1], 10) || 0) : 0;
            var sizeCount = sizeMatch ? (parseInt(sizeMatch[1], 10) || 0) : 0;
            if (colorCount > 0 || sizeCount > 0) {
              var sizeName = temuVariantSecondOptionName(txt);
              return { el: trigger, text: txt, colors: colorCount, sizes: sizeCount, sizeName: sizeName };
            }
          }
          node = node.parentElement; depth++;
        }
      }
    } catch (e) {}
    return null;
  }

  function otlobliTemuSkuOptionGroupName(opt) {
    try {
      var optRect = opt && opt.getBoundingClientRect ? opt.getBoundingClientRect() : null;
      var node = opt, depth = 0;
      while (node && depth < 7) {
        var heads = node.querySelectorAll ? node.querySelectorAll('[class*="type-"][aria-label], [class*="specTypeName"], [class*="type-"]') : [];
        var best = '', bestDy = 999999, fallback = '';
        for (var h = 0; h < heads.length; h++) {
          var ht = temuCleanText((heads[h].getAttribute && heads[h].getAttribute('aria-label')) || heads[h].textContent || '');
          if (!ht || ht.length > 80 || /الكمية|كمية|quantity/i.test(ht)) continue;
          if (!fallback) fallback = ht;
          if (!optRect || !heads[h].getBoundingClientRect) continue;
          var hr = heads[h].getBoundingClientRect();
          if (hr.height <= 0 || hr.bottom > optRect.bottom + 8) continue;
          var dy = Math.abs(optRect.top - hr.bottom);
          if (dy < bestDy) { bestDy = dy; best = ht; }
        }
        if (best) return best;
        if (fallback && depth < 3) return fallback;
        node = node.parentElement; depth++;
      }
    } catch (e) {}
    return '';
  }

  function otlobliTemuSkuOptionValue(opt, isColor) {
    try {
      if (!opt) return '';
      var im = opt.querySelector && opt.querySelector('img');
      var imgTxt = im ? temuCleanText((im.getAttribute && (im.getAttribute('alt') || im.getAttribute('title'))) || '') : '';
      var txt = temuCleanText(opt.textContent || '');
      if (isColor && imgTxt) return imgTxt;
      if (txt && txt.length <= 50) return txt;
      return imgTxt || 'selected';
    } catch (e) {}
    return '';
  }

  function otlobliTemuSku() {
    var out = { hasSelector: false, single: false, dims: [], collapsedEl: null };
    try {
      var sels = document.querySelectorAll('[class*="skuSelector"]');
      var collapsed = null;
      for (var i = 0; i < sels.length; i++) {
        if (!/skuSelector-/.test((sels[i].className || '') + '')) continue;
        if (sels[i].getAttribute('role') === 'button') { collapsed = sels[i]; break; }
      }
      if (collapsed) {
        out.hasSelector = true; out.collapsedEl = collapsed;
        var infoEl = collapsed.querySelector('[class*="info-"]');
        var infoTxt = temuCleanText(infoEl ? infoEl.textContent : (collapsed.getAttribute('aria-label') || ''));
        if (/singleOnsale/.test((collapsed.className || '') + '') ||
            /خيار واحد فقط|يتوفر خيار واحد|only one option/i.test(infoTxt)) {
          out.single = true;
        }
        var cM = temuVariantColorCountMatch(infoTxt);
        var sM = temuVariantSecondOptionCountMatch(infoTxt);
        if (cM) out.dims.push({ kind: 'color', name: 'اللون', count: parseInt(cM[1], 10), selected: null, source: 'collapsed' });
        if (sM) out.dims.push({ kind: 'size', name: temuVariantSecondOptionName(infoTxt), count: parseInt(sM[1], 10), selected: null, source: 'collapsed' });
      }
      if (!collapsed) {
        var looseCollapsed = otlobliTemuCollapsedVariantRow();
        if (looseCollapsed) {
          out.hasSelector = true; out.collapsedEl = looseCollapsed.el;
          if (looseCollapsed.colors > 0) out.dims.push({ kind: 'color', name: 'اللون', count: looseCollapsed.colors, selected: null, source: 'collapsed' });
          if (looseCollapsed.sizes > 0) out.dims.push({ kind: 'size', name: looseCollapsed.sizeName || 'مقاس', count: looseCollapsed.sizes, selected: null, source: 'collapsed' });
        }
      }
      var groups = document.querySelectorAll('[class*="specListWrap"],[class*="specTypes-"]');
      for (var g = 0; g < groups.length; g++) {
        var head = groups[g].querySelector('[class*="type-"][aria-label], [class*="specTypeName"], [class*="type-"]');
        var nm = head ? temuCleanText((head.getAttribute && head.getAttribute('aria-label')) || head.textContent || '') : '';
        if (!nm || /الكمية|كمية|quantity/i.test(nm)) continue;
        var isColor = /اللون|لون|colou?r/i.test(nm);
        var opts = groups[g].querySelectorAll('[role="radio"], [aria-checked], [aria-selected]');
        var availableOpts = [];
        for (var av = 0; av < opts.length; av++) {
          if (!temuOptionUnavailable(opts[av])) availableOpts.push(opts[av]);
        }
        var sel = null;
        for (var o = 0; o < availableOpts.length; o++) {
          if (availableOpts[o].getAttribute('aria-checked') === 'true' || availableOpts[o].getAttribute('aria-selected') === 'true') {
            var im = availableOpts[o].querySelector('img');
            sel = (im && im.getAttribute('alt')) || temuCleanText(availableOpts[o].textContent) || 'محدد';
          }
        }
        if (!sel && isColor && opts.length) {
          var optList = [];
          for (var oo = 0; oo < availableOpts.length; oo++) optList.push(availableOpts[oo]);
          var pickedOpt = temuPickSingleSelected(optList);
          if (pickedOpt) sel = otlobliTemuSkuOptionValue(pickedOpt, isColor);
        }
        if (!sel && isColor) {
          var sv = groups[g].querySelector('[class*="specValue"]');
          if (sv) { var svt = temuCleanText(sv.textContent).replace(/^[:：]\s*/, ''); if (svt && svt.length <= 24) sel = svt; }
        }
        out.hasSelector = true;
        for (var cd = out.dims.length - 1; cd >= 0; cd--) {
          if (out.dims[cd].source === 'collapsed' && out.dims[cd].kind === (isColor ? 'color' : 'size')) {
            out.dims.splice(cd, 1);
          }
        }
        var unavailableOnly = opts.length > 0 && availableOpts.length === 0;
        out.dims.push({ kind: isColor ? 'color' : 'size', name: nm, count: unavailableOnly ? 2 : (availableOpts.length || 1), selected: sel || null, unavailableOnly: unavailableOnly, source: 'expanded' });
      }
    } catch (e) {}
    return out;
  }
  function otlobliTemuUnmetDim(sku, kind) {
    if (sku.single) return null;
    for (var i = 0; i < sku.dims.length; i++) {
      var d = sku.dims[i];
      if (kind && d.kind !== kind) continue;
      if (d.count > 1 && !d.selected) return d;
    }
    return null;
  }

  function otlobliTemuCurrentColorPicked() {
    try {
      return !!((window.__otlobliTemuColor || window.__otlobliTemuColorSwatch) &&
        window.__otlobliTemuColorGid === temuGoodsId());
    } catch (e) {}
    return false;
  }

  function otlobliTemuUnmetDimResolved(sku, kind) {
    var unmet = otlobliTemuUnmetDim(sku, kind);
    if (!unmet) return null;
    if (unmet.unavailableOnly) return unmet;
    if (unmet.kind === 'color' && otlobliTemuCurrentColorPicked()) {
      if (kind) return null;
      return otlobliTemuUnmetDimResolved(sku, 'size');
    }
    if (unmet.kind === 'size' && temuSelectedSize()) {
      if (kind) return null;
      return otlobliTemuUnmetDimResolved(sku, 'color');
    }
    return unmet;
  }

  function sheinStoreVariant() {
    try {
      var el = document.getElementById('app');
      var comp = el && el._vnode && el._vnode.component;
      var store = comp && comp.proxy && comp.proxy.$store;
      var pd = store && store.state && store.state.productDetail;
      if (!pd) return null;
      var cold = pd.coldModules || {}, hot = pd.hotModules || {};
      var gid = String((cold.productInfo || {}).goods_id || '');
      var color = '', image = '';
      var msa = (cold.saleAttr && cold.saleAttr.mainSaleAttribute) ||
        (hot.saleAttr && hot.saleAttr.mainSaleAttribute);
      var mArr = (msa && msa.info && msa.info.length !== undefined) ? msa.info : [];
      for (var i = 0; i < mArr.length; i++) {
        if (String(mArr[i].goods_id) === gid) {
          color = normalizedOptionText(mArr[i].attr_value || '');
          image = normalizeImageUrl(mArr[i].goods_image || mArr[i].goods_color_image || mArr[i].attrImg || '');
          break;
        }
      }
      if (!color && mArr.length === 1) {
        color = normalizedOptionText(mArr[0].attr_value || '');
        image = normalizeImageUrl(mArr[0].goods_image || '');
      }
      try {
        var drs = document.querySelectorAll('.sui-drawer');
        for (var dd = 0; dd < drs.length; dd++) {
          if (!sheinElementIsVisible(drs[dd])) continue;
          var cis = drs[dd].querySelectorAll('.bs-color-square-image__item,[class*="color__item" i]');
          var dcol = '';
          for (var ci = 0; ci < cis.length; ci++) {
            if (!(/(?:^|\s)active/.test(cis[ci].className) || cis[ci].getAttribute('aria-checked') === 'true')) continue;
            var cim = cis[ci].querySelector('img');
            dcol = normalizedOptionText(cis[ci].getAttribute('aria-label') || (cim && cim.getAttribute('alt')) || '');
            if (dcol) break;
          }
          if (dcol) {
            color = dcol;
            for (var mj = 0; mj < mArr.length; mj++) {
              if (normalizedOptionText(mArr[mj].attr_value || '') === dcol) {
                image = normalizeImageUrl(mArr[mj].goods_image || mArr[mj].goods_color_image || mArr[mj].attrImg || '') || image;
                break;
              }
            }
            break;
          }
        }
      } catch (e) {}
      var selVals = [];
      var domSel = document.querySelectorAll('[data-attr_value_id][aria-checked="true"],[data-attr_value_id].size-active');
      for (var d = 0; d < domSel.length; d++) {
        var sv = normalizedOptionText(domSel[d].getAttribute('data-attr_value') || '');
        if (sv) selVals.push(sv);
      }
      var ml = (hot.saleAttr && hot.saleAttr.multiLevelSaleAttribute) ||
        (cold.saleAttr && cold.saleAttr.multiLevelSaleAttribute);
      var skuList = (ml && ml.sku_list && ml.sku_list.length !== undefined) ? ml.sku_list : [];
      var matched = null;
      for (var s = 0; s < skuList.length; s++) {
        var names = (skuList[s].sku_sale_attr || []).map(function (a) { return normalizedOptionText(a.attr_value_name || ''); });
        var all = selVals.length > 0;
        for (var w = 0; w < selVals.length; w++) { if (names.indexOf(selVals[w]) < 0) { all = false; break; } }
        if (all) { matched = skuList[s]; break; }
      }
      if (!matched && skuList.length === 1) matched = skuList[0];
      var size = '', skuCode = '', priceUsd = 0;
      if (matched) {
        skuCode = String(matched.sku_code || '');
        var parts = [], attrs = matched.sku_sale_attr || [];
        for (var b = 0; b < attrs.length; b++) {
          var an = normalizedOptionText(attrs[b].attr_name || '');
          var vn = normalizedOptionText(attrs[b].attr_value_name || '');
          if (!vn) continue;
          if (/^ال?لون$/.test(an) || (color && vn === color)) { if (!color) color = vn; continue; }
          parts.push(vn);
        }
        size = parts.join(' / ');
        var sp = matched.priceInfo && matched.priceInfo.salePrice;
        if (sp) priceUsd = parseFloat(sp.usdAmount || sp.amount || 0) || 0;
      }
      if (!color && !size && !(priceUsd > 0)) return null;
      return { skuCode: skuCode, color: color, image: image, size: size, priceUsd: priceUsd };
    } catch (e) { return null; }
  }

  function sheinSizeUnselected(scope) {
    try {
      var host = scope && scope.querySelectorAll ? scope : document;
      var o = host.querySelectorAll('[data-attr_value][data-attr_value_id]');
      var tot = 0, sel = 0, first = null;
      for (var i = 0; i < o.length; i++) {
        var h = normalizedOptionText(sheinGroupHeading(o[i]));
        if (!/مقاس|الحجم/.test(h) && h.toLowerCase() !== 'size') continue;
        tot++;
        if (!first) first = o[i];
        if (o[i].getAttribute('aria-checked') === 'true' || /size-active/.test(o[i].className)) sel++;
      }
      if (tot >= 2 && !sel) {
        try { if (first && first.scrollIntoView) first.scrollIntoView({ block: 'center' }); } catch (e) {}
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  function sheinActiveQuickAddDrawer() {
    var drawers = document.querySelectorAll('.bsc-quick-add-cart');
    for (var i = drawers.length - 1; i >= 0; i--) {
      if (sheinElementIsPainted(drawers[i]) && drawers[i].querySelector('.quickAddName__name')) return drawers[i];
    }
    return null;
  }

  function sheinQuickSizeBox(root) {
    var groups = root.querySelectorAll('.goods-size__wrapper > div');
    for (var i = 0; i < groups.length; i++) {
      var label = normalizedOptionText((groups[i].querySelector('.goods-size__title') || {}).textContent || '');
      if (/مقاس|حجم|size/i.test(label)) return groups[i];
    }
    return root.querySelector('.goods-size');
  }

  function sheinQuickBundleCount(size) {
    var count = (String(size || '').match(/\+/g) || []).length;
    return count ? count + 1 : 1;
  }

  function sheinQuickAddSelectionState() {
    var root = sheinActiveQuickAddDrawer();
    if (!root) return null;
    var sizeBox = sheinQuickSizeBox(root);
    if (!sizeBox) {
      var candidates = root.querySelectorAll('[class*="size" i]');
      for (var i = 0; i < candidates.length; i++) {
        var options = getSizeOptions(candidates[i]);
        if (options.available.length + options.unavailable.length >= 2) {
          sizeBox = candidates[i];
          break;
        }
      }
    }
    var sizeOptions = getSizeOptions(sizeBox);
    var sizePick = sizeBox && sizeBox.querySelector('.goods-size__sizes-item.size-active,[data-attr_value][aria-checked="true"],.size-active');
    var size = normalizedOptionText((sizePick && (sizePick.getAttribute('data-attr_value') || sizePick.textContent)) || getSelectedWithin(sizeBox));
    var colorBox = root.querySelector('.bs-main-sales-attr');
    var colorPick = colorBox && colorBox.querySelector('.bs-color__item.active,.bs-color__item[aria-checked="true"]');
    var colorText = normalizedOptionText((root.querySelector('.bs-main-sales-attr__header-title') || {}).textContent || '')
      .replace(/^[^:：]+[:：]s*/, '').trim() || getSelectedWithin(colorBox);
    var colorOptions = colorBox ? colorBox.querySelectorAll('.bs-color__item,[role="radio"],[data-attr_value]') : [];
    return {
      root: root,
      sizeBox: sizeBox,
      color: { exists: colorOptions.length > 1, selected: colorText, image: swatchImageFrom(colorPick) },
      size: { exists: !!sizeBox && sizeOptions.available.length + sizeOptions.unavailable.length >= 2,
        selected: size, available: sizeOptions.available || [], unavailable: sizeOptions.unavailable || [] }
    };
  }

  function sheinQuickAddProductLink(root,info){
    var id=String(info&&info.goods_id||'').replace(/D/g,'');
    if(!id)return location.href;
    var suffix='-p-'+id+'.html';
    try{var a=root.querySelector('a[href*="'+suffix+'"]');if(a&&a.href)return a.href}catch(e){}
    return location.origin+'/ar/product-p-'+id+'.html';
  }

  function sheinQuickAddPayload() {
    var root = sheinActiveQuickAddDrawer();
    if (!root) return null;
    var info = {}, node = root, app, comp;
    for (var hop = 0; node && hop < 9 && !info.goods_id; node = node.parentElement, hop++) try {
      app = node.__vue_app__; comp = app && app._container && app._container._vnode && app._container._vnode.component;
      info = (comp && comp.setupState && comp.setupState.productInfo) || info;
    } catch (e) {}
    var title = cleanTitle((root.querySelector('.quickAddName__name') || {}).textContent || info.goods_name || '');
    var active = root.querySelector('.bsc-gallery__swiper-slide-active');
    var image = realImgSrc(active && active.querySelector('img.crop-image-container__real-image,img:not([aria-hidden])')) ||
      realImgSrc(root.querySelector('.crop-image-container__real-image')) || normalizeImageUrl(info.goods_img || '');
    var colorHead = root.querySelector('.bs-main-sales-attr__header-title');
    var color = normalizedOptionText((colorHead && colorHead.textContent) || '').replace(/^[^:：]+[:：]s*/, '').trim();
    var colorPick = root.querySelector('.bs-color__item.active,.bs-color__item[aria-checked="true"]');
    var colorImage = swatchImageFrom(colorPick);
    var sizeBox = sheinQuickSizeBox(root);
    var sizePick = sizeBox && sizeBox.querySelector('.goods-size__sizes-item.size-active,[data-attr_value][aria-checked="true"]');
    var size = normalizedOptionText((sizePick && (sizePick.getAttribute('data-attr_value') || sizePick.textContent)) || '');
    var quantityOption = sheinSelectedQuantityOption(root);
    var sizes = getSizeOptions(sizeBox);
    var price = sheinUsdValue((root.querySelector('.quickPrice__main') || {}).textContent || '') || sheinPriceFromChangedRoot(root);
    var link = sheinQuickAddProductLink(root, info);
    if (!title || !(price > 0) || !image) return null;
    return { title: title, priceUsd: price, priceSource: 'quick-add', image: image, colorImage: colorImage,
      colorImageFound: !!colorImage, color: color, size: size, quantityOption: quantityOption, skuCode: '', sizesAvailable: sizes.available || [],
      bundleCount: sheinQuickBundleCount(size),
      sizesUnavailable: sizes.unavailable || [], link: otlobliNormalizeSheinUrl(link), needsCustomPhoto: false,
      customPhotoNote: '', needsCustomText: false, customText: '', customTextLimit: 0 };
  }

  function captureProductPayload(colorState, sizeState, allowGenericTitle) {
    if (IS_TEMU) {
      var perso = temuPersonalization();
      var customReq = temuCustomRequirements(perso);
      var persoTxt = (perso.text && !/^\d+$/.test(perso.text)) ? perso.text : '';
      var temuSizeVal = (perso.has && persoTxt) ? ('نقش: ' + persoTxt) : temuSelectedSize();
      var temuColorSwatch = (window.__otlobliTemuColorSwatch && window.__otlobliTemuColorGid === temuGoodsId())
        ? window.__otlobliTemuColorSwatch : '';
      var temuColorVal = temuColor();
      if (!temuColorSwatch && temuColorVal) {
        temuColorSwatch = temuSelectedColorCardImg(temuColorVal) || '';
      }
      if (!temuColorSwatch) {
        var defCard = temuDefaultSelectedColorCard();
        if (defCard) {
          temuColorSwatch = defCard.image;
          if (!temuColorVal && defCard.name) temuColorVal = defCard.name;
        }
      }
      if (!temuColorVal && temuColorSwatch) temuColorVal = 'حسب الصورة المرفقة';
      temuColorVal = temuStripQuantity(temuColorVal);
      temuSizeVal = temuStripQuantity(temuSizeVal);
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
        link: otlobliBuildDeepLink(location.href, temuColorVal, temuSizeVal),
        needsCustomPhoto: customReq.needsPhoto,
        customPhotoNote: customReq.photoNote,
        needsCustomText: customReq.needsText,
        customText: persoTxt,
        customTextLimit: customReq.textLimit || 0,
      };
    }
    var sheinQuick = sheinQuickAddPayload();
    if (sheinQuick) return sheinQuick;
    var sheinCustomReq = sheinCustomRequirements();
    var sheinPriceUsd = getPrice();
    var sheinPriceSource = __otlobliSkuPriceSource;
    var sheinColorSel = colorState.selected;
    var sheinColorImg = colorState.image;
    var sheinSizeSel = sizeState.selected;
    var sheinQuantityOption = sheinSelectedQuantityOption();
    var sheinSizesAvail = sizeState.available || [];
    var sheinSizesUnavail = sizeState.unavailable || [];
    if (__otlobliSelectedSkuPricePath === location.pathname &&
        Date.now() - __otlobliSelectedSkuPriceAt < 1800000) {
      if (__otlobliSelectedSkuColorImage) sheinColorImg = __otlobliSelectedSkuColorImage;
      if (__otlobliSheinDrawerPath === location.pathname) {
        if (__otlobliSelectedSkuColor) sheinColorSel = __otlobliSelectedSkuColor;
        var kSize = String(__otlobliSelectedSkuPriceKey || '').split('|')[1];
        if (kSize) sheinSizeSel = kSize;
      }
    }
    var sheinStoreV = sheinStoreVariant();
    var sheinSkuCode = '';
    if (sheinStoreV) {
      sheinSkuCode = sheinStoreV.skuCode;
      if (sheinStoreV.color) sheinColorSel = sheinStoreV.color;
      if (sheinStoreV.image && !sheinColorImg) sheinColorImg = sheinStoreV.image;
      if (sheinStoreV.size) {
        sheinSizeSel = sheinStoreV.size;
        sheinSizesAvail = []; sheinSizesUnavail = [];
      }
      if (sheinStoreV.priceUsd > 0) {
        sheinPriceUsd = sheinStoreV.priceUsd;
        sheinPriceSource = 'store-sku';
      }
    }
    if (sheinSizeSel && sheinColorSel && sheinSizeSel === sheinColorSel) {
      sheinSizeSel = '';
      sheinSizesAvail = [];
      sheinSizesUnavail = [];
    }
    return {
      title: getTitle(allowGenericTitle),
      priceUsd: sheinPriceUsd,
      priceSource: sheinPriceSource,
      image: getMainImage() || sheinColorImg,
      colorImage: sheinColorImg || '',
      colorImageFound: !!sheinColorImg,
      color: sheinColorSel,
      size: sheinSizeSel,
      quantityOption: sheinQuantityOption,
      skuCode: sheinSkuCode,
      sizesAvailable: sheinSizesAvail,
      sizesUnavailable: sheinSizesUnavail,
      link: otlobliNormalizeSheinUrl(location.href),
      needsCustomPhoto: sheinCustomReq.needsPhoto,
      customPhotoNote: sheinCustomReq.photoNote,
      needsCustomText: sheinCustomReq.needsText,
      customText: '',
      customTextLimit: sheinCustomReq.textLimit || 0,
    };
  }

  function addToCartFlow(colorState, sizeState) {
    if (document.getElementById('otlobli-overlay')) return;
    var quickPayload = null;
    if (IS_SHEIN) {
      __otlobliCartToastGuardUntil = Date.now() + 7000;
      var addBtn = document.getElementById('otlobli-add-btn');
      if (!ensureSheinSaudiStore()) {
        showMessage(addBtn, 'نثبت منطقة الشحن المختارة والدولار... حاول بعد لحظة');
        return;
      }
      var quickAddState = sheinQuickAddSelectionState();
      if (quickAddState) {
        colorState = quickAddState.color;
        sizeState = quickAddState.size;
        quickPayload = sheinQuickAddPayload();
        if (!quickPayload) {
          showMessage(addBtn, 'تعذّر قراءة خيار المنتج — حاول مرة ثانية');
          return;
        }
      } else if (sheinOpenSkuDrawer()) {
        return;
      }
      if (colorState && colorState.exists && !colorState.selected) {
        showMessage(addBtn, 'حدد اللون أولاً');
        return;
      }
      if (sizeState && sizeState.exists && !sizeState.selected) {
        if (quickAddState && quickAddState.sizeBox && quickAddState.sizeBox.scrollIntoView) {
          try { quickAddState.sizeBox.scrollIntoView({ block: 'center' }); } catch (e) {}
        } else {
          sheinRevealSizeOptions();
        }
        showMessage(addBtn, 'حدد المقاس أولاً');
        return;
      }
      if (sheinSizeUnselected(quickAddState && quickAddState.root)) {
        showMessage(addBtn, 'الرجاء تحديد المقاس أولاً');
        return;
      }
    }
    var payload = quickPayload || captureProductPayload(colorState, sizeState);
    showAddingOverlay(payload);
    clearAddSafetyTimer();
    window.__otlobliAddSafetyTimer = setTimeout(function () {
      if (document.getElementById('otlobli-overlay')) failAddFlow();
    }, 5000);

    var attempts = 0;
    var priceWaits = 0;
    var maxAttempts = IS_TEMU ? 3 : 10;
    var intervalMs = IS_TEMU ? 150 : 500;
    function isComplete(p, cs) {
      if (IS_TEMU) {
        var colorPicked = !!(window.__otlobliTemuColor && window.__otlobliTemuColorGid === temuGoodsId());
        var colorImgReady = !colorPicked || !!window.__otlobliTemuColorSwatch || !!window.__otlobliTemuColorImg;
        return !!p.title && !!p.image && p.priceUsd > 0 && colorImgReady;
      }
      return !!p.title && !!p.image && p.priceUsd > 0 && (!cs.exists || !!p.color);
    }

    function finalize(p) {
      if (IS_SHEIN) {
        sheinRegionDiag('selected-sku-price-capture', {
          captured: p.priceUsd,
          source: __otlobliSkuPriceSource,
          spaRoute: sheinSpaCaptureRoute(),
          before: __otlobliSelectedSkuPriceBefore,
          priceWaits: priceWaits,
          tracked: __otlobliSelectedSkuPrice,
          trackedKey: __otlobliSelectedSkuPriceKey,
          currentKey: sheinCurrentSelectionKey()
        }, [p.priceUsd, __otlobliSkuPriceSource, __otlobliSelectedSkuPrice,
          __otlobliSelectedSkuPriceKey, sheinCurrentSelectionKey()].join('|'));
      }
      if (!p.title || !p.image || !(p.priceUsd > 0)) {
        clearAddSafetyTimer();
        removeOverlay(0);
        var ab = document.getElementById('otlobli-add-btn');
        if (ab) showMessage(ab, 'تعذّر قراءة بيانات المنتج — حاول مرة ثانية');
        return;
      }
      updateOverlayContent(p, 'جاري إضافة المنتج لسلة otlobli...');
      function postProduct() {
        try {
          if (window.mobileApp && window.mobileApp.postMessage) {
            window.mobileApp.postMessage({ detail: { type: 'addToCart', product: p } });
          }
        } catch (e) {}
      }
      if (IS_TEMU) {
        postProduct();
        return;
      }
      preloadImage(p.image, 2500).then(function (ok) {
        if (!ok) p.image = getMainImage() || p.image;
        postProduct();
      });
    }

    function attempt() {
      try {
        if (quickPayload) {
          finalize(quickPayload);
          return;
        }
        if (IS_SHEIN && sheinSelectedSkuPricePending() && priceWaits++ < 16) {
          updateOverlayContent(payload, 'جاري تثبيت سعر الخيار المختار...');
          setTimeout(attempt, 120);
          return;
        }
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
      } catch (e) {
        failAddFlow();
      }
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
      clearAddSafetyTimer();
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
      return;
    }
    if (detail && detail.type === 'addToCartNack') {
      failAddFlow();
    }
  });

  function showMessage(btn, text, durationMs) {
    ensureShakeStyle();
    var msg = document.getElementById('otlobli-msg');
    if (!msg) {
      msg = document.createElement('div');
      msg.id = 'otlobli-msg';
      msg.style.cssText = 'position:fixed;left:22px;right:22px;bottom:calc(env(safe-area-inset-bottom,0px) + 98px);z-index:2147483647;' +
        'background:rgba(23,29,36,.92);color:#fff;border:0;border-radius:14px;' +
        'padding:10px 14px;font-size:13px;font-weight:700;line-height:1.45;text-align:center;' +
        'box-shadow:0 12px 28px rgba(15,22,32,.24);font-family:Cairo,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;' +
        'backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);animation:otlobli-slide-up .16s ease-out;direction:rtl;';
      document.body.appendChild(msg);
    }
    msg.textContent = text;
    msg.style.display = 'block';
    clearTimeout(window.__otlobliMsgTimer);
    var showFor = durationMs || (text.indexOf('[') >= 0 ? 6000 : 2500);
    window.__otlobliMsgTimer = setTimeout(function () { msg.style.display = 'none'; }, showFor);

    if (btn) {
      btn.style.animation = 'none';
      requestAnimationFrame(function () {
        btn.style.animation = 'otlobli-shake 0.4s';
      });
    }
  }

  function otlobliShowGateSpinner() {
    ensureOverlayStyle();
    ensureShakeStyle();
    if (document.getElementById('otlobli-gate-spinner')) return;
    var wrap = document.createElement('div');
    wrap.id = 'otlobli-gate-spinner';
    wrap.style.cssText = 'position:fixed;left:22px;right:22px;bottom:calc(env(safe-area-inset-bottom,0px) + 98px);z-index:2147483647;' +
      'background:rgba(23,29,36,.92);color:#fff;border:0;border-radius:14px;' +
      'padding:10px 14px;font-size:13px;font-weight:700;line-height:1.45;text-align:center;box-shadow:0 12px 28px rgba(15,22,32,.24);' +
      'font-family:Cairo,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);animation:otlobli-slide-up .16s ease-out;' +
      'display:flex;align-items:center;justify-content:center;gap:8px;direction:rtl;';
    var spin = document.createElement('span');
    spin.style.cssText = 'width:15px;height:15px;border-radius:50%;border:2px solid rgba(255,255,255,.28);' +
      'border-top-color:#fff;animation:otlobli-spin .8s linear infinite;flex-shrink:0;';
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

  var __otlobliLoadingDone = false;
  function ensureLoadingOverlay() {
    if (__otlobliLoadingDone || document.getElementById('otlobli-loading')) return;
    ensureOverlayStyle();
    var vp = viewportSize();
    var overlay = document.createElement('div');
    overlay.id = 'otlobli-loading';
    overlay.style.cssText = 'position:fixed;left:0;top:0;width:' + vp.width + 'px;height:' + vp.height + 'px;' +
      'background:#ffffff;z-index:2147483646;display:flex;align-items:center;justify-content:center;';
    overlay.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });
    overlay.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); }, true);
    var spinner = document.createElement('div');
    spinner.style.cssText = 'width:38px;height:38px;border-radius:50%;border:4px solid #d8efe4;' +
      'border-top-color:#006948;animation:otlobli-spin .8s linear infinite;';
    overlay.appendChild(spinner);
    document.body.appendChild(overlay);

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

  var __otlobliQuickAddClearanceNext = 0;
  var OTLOBLI_ADD_BUTTON_REVISION = '2026-08-09-curvy-form-snapshot';
  function ensureAddToCartButton() {
    var btn = document.getElementById('otlobli-add-btn');
    if (btn && btn.getAttribute('data-otlobli-add-revision') !== OTLOBLI_ADD_BUTTON_REVISION) {
      try { btn.remove(); } catch (e) { if (btn.parentNode) btn.parentNode.removeChild(btn); }
      btn = null;
    }
    if (!btn) {
      ensureShakeStyle();
      btn = document.createElement('button');
      btn.id = 'otlobli-add-btn';
      btn.setAttribute('aria-label', 'إضافة إلى سلة otlobli');
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
          var sku0 = otlobliTemuSku();
          var unmet0 = otlobliTemuUnmetDimResolved(sku0, null);
          if (unmet0) {
            var unmetMessage0 = unmet0.unavailableOnly
              ? 'هذا الخيار غير متوفر حالياً'
              : (unmet0.kind === 'color' ? 'حدد اللون أولاً' : (/موديل/i.test(unmet0.name) ? 'حدد الموديل أولاً' : 'حدد المقاس أولاً'));
            showMessage(btn, unmetMessage0);
            return;
          }
          var persoChk = temuPersonalization();
          if (temuCustomRequirements(persoChk).needsPhoto) {
            showMessage(btn, 'أضف صورتك في السلة قبل إتمام الطلب');
          }
          if (persoChk.has && !persoChk.text) {
            if (persoChk.inputVisible) {
              showMessage(btn, 'اكتب النص/الاسم المطلوب أولاً');
              return;
            }
            showMessage(btn, 'أضف الاسم/النص المطلوب في السلة قبل الدفع');
          }
          function temuFinalizeAdd() {
          var blockMsg = '';
          if (otlobliTemuRecentUnavailableTap()) blockMsg = 'هذا الخيار غير متوفر حالياً';
          var skuGate = otlobliTemuSku();
          var swatchChosen = !!(window.__otlobliTemuColorSwatch && window.__otlobliTemuColorGid === temuGoodsId());
          var colorUnmet = otlobliTemuUnmetDimResolved(skuGate, 'color');
          if (colorUnmet) {
            if (colorUnmet.unavailableOnly) {
              blockMsg = 'هذا الخيار غير متوفر حالياً';
            }
            var gateColorSwatch = swatchChosen ? window.__otlobliTemuColorSwatch : '';
            var gateColorVal = temuColor();
            if (!gateColorSwatch && gateColorVal) {
              gateColorSwatch = temuSelectedColorCardImg(gateColorVal) || '';
            }
            if (!gateColorSwatch) {
              var gateDefColor = temuDefaultSelectedColorCard();
              if (gateDefColor) gateColorSwatch = gateDefColor.image;
            }
            var colorPickedG = swatchChosen || (window.__otlobliTemuColorGid === temuGoodsId() && !!window.__otlobliTemuColor);
            if (!blockMsg && !gateColorSwatch && !gateColorVal && !colorPickedG) {
              blockMsg = 'حدد اللون أولاً';
            }
          }
          if (!blockMsg) {
            try { temuForceSingleSize(); } catch (e) {}
            var sizeUnmet = otlobliTemuUnmetDimResolved(skuGate, 'size');
            if (sizeUnmet && !temuSelectedSize()) {
              blockMsg = sizeUnmet.unavailableOnly ? 'هذا الخيار غير متوفر حالياً' : (/موديل/i.test(sizeUnmet.name) ? 'حدد الموديل أولاً' : 'حدد المقاس أولاً');
            }
          }
          if (blockMsg) {
            otlobliRemoveGateSpinner();
            showMessage(btn, blockMsg);
            return;
          }
          if (!(temuPriceUsd() > 0)) {
            otlobliRemoveGateSpinner();
            showMessage(btn, 'تعذّر قراءة السعر — انتظر ثانية وحاول');
            return;
          }
          otlobliRemoveGateSpinner();
          addToCartFlow({ exists: false }, { exists: false });
          }
          temuFinalizeAdd();
          return;
        }
        if (!IS_SHEIN) {
          addToCartFlow({ exists: false }, { exists: false });
          return;
        }
        var colorState = getColorState();
        var sizeState = getSizeState();
        addToCartFlow(colorState, sizeState);
      }, true);
      document.body.appendChild(btn);
    }
    btn.setAttribute('data-otlobli-add-revision', OTLOBLI_ADD_BUTTON_REVISION);
    var showAddBtn = looksLikeProductPage() &&
      !(IS_TEMU && !otlobliTemuHasVisibleProductContent(otlobliTemuProductVitals())) &&
      !(IS_TEMU && temuImageViewerOpen()) &&
      !(IS_SHEIN && sheinImageViewerOpen());
    btn.style.display = showAddBtn ? 'flex' : 'none';
    if (IS_SHEIN && showAddBtn && Date.now() >= __otlobliQuickAddClearanceNext) {
      __otlobliQuickAddClearanceNext = Date.now() + 500;
      var quick = sheinActiveQuickAddDrawer();
      var scroller = quick && quick.parentElement;
      if (quick && scroller && scroller.classList.contains('sui-drawer__body')) {
        var room = Math.ceil(innerHeight - btn.getBoundingClientRect().top) + 20;
        var roomText = room + 'px';
        if (scroller.style.paddingBottom !== roomText) {
          scroller.style.paddingBottom = roomText;
          scroller.style.scrollPaddingBottom = roomText;
        }
        var groups = quick.querySelectorAll('.goods-size');
        var lastGroup = groups[groups.length - 1];
        if (lastGroup) {
          var key = scroller.scrollHeight + ':' + lastGroup.offsetTop + ':' + lastGroup.offsetHeight + ':' + room;
          if (quick.getAttribute('data-otlobli-add-clearance') !== key) {
            var shift = Math.ceil(lastGroup.getBoundingClientRect().bottom - (btn.getBoundingClientRect().top - 14));
            if (shift > 0) scroller.scrollTop += shift;
            quick.setAttribute('data-otlobli-add-clearance', key);
          }
        }
      }
    }
  }

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

  function otlobliNavShouldYield(nav) {
    if (!IS_SHEIN || !document.body) return false;
    var navRect = nav.getBoundingClientRect();
    if (navRect.height <= 0) return false;
    if (!otlobliNavIsActuallyCovered(nav)) return false;
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
    if (nav.querySelector('#otlobli-nav-region-guard')) {
      nav.style.setProperty('pointer-events', 'auto', 'important');
      nav.removeAttribute('data-otlobli-nav-yield');
      return;
    }
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
    if (nav.parentNode !== document.documentElement) {
      document.documentElement.appendChild(nav);
    }
    var temuBottom = otlobliTemuNavBottomOffset();
    if (nav.style.getPropertyValue('bottom') !== temuBottom) {
      nav.style.setProperty('bottom', temuBottom, 'important');
    }
    if (nav.style.getPropertyValue('transform') !== 'translate3d(-50%,0,0)') {
      nav.style.setProperty('transform', 'translate3d(-50%,0,0)', 'important');
      nav.style.setProperty('-webkit-transform', 'translate3d(-50%,0,0)', 'important');
    }
    if (nav.getAttribute('data-otlobli-temu-root-layer') !== '1') {
      nav.style.setProperty('-webkit-backface-visibility', 'hidden', 'important');
      nav.style.setProperty('backface-visibility', 'hidden', 'important');
      nav.style.setProperty('isolation', 'isolate', 'important');
      nav.style.setProperty('contain', 'layout style paint', 'important');
      nav.setAttribute('data-otlobli-temu-root-layer', '1');
    }
  }

  function otlobliReadSafeAreaBottomPx() {
    try {
      var now = Date.now();
      if (window.__otlobliSafeAreaBottomAt && now - window.__otlobliSafeAreaBottomAt < 750) {
        return window.__otlobliSafeAreaBottomPx || 0;
      }
      var host = document.body || document.documentElement;
      if (!host) return 0;
      var probe = document.createElement('div');
      probe.style.cssText = 'position:fixed!important;left:0!important;bottom:0!important;width:0!important;height:0!important;' +
        'padding-bottom:env(safe-area-inset-bottom, 0px)!important;visibility:hidden!important;pointer-events:none!important;';
      host.appendChild(probe);
      var px = parseFloat(window.getComputedStyle(probe).paddingBottom || '0') || 0;
      probe.parentNode && probe.parentNode.removeChild(probe);
      window.__otlobliSafeAreaBottomPx = px;
      window.__otlobliSafeAreaBottomAt = now;
      return px;
    } catch (e) {}
    return 0;
  }

  function otlobliTemuNavBottomOffset() {
    try {
      var ua = navigator.userAgent || '';
      var isAppleMobile = /iP(?:hone|od|ad)/i.test(ua) ||
        ((navigator.platform || '') === 'MacIntel' && (navigator.maxTouchPoints || 0) > 1);
      if (!isAppleMobile) return '-18px';
      if (otlobliReadSafeAreaBottomPx() > 1) return '-18px';
      return otlobliLooksLikeLegacyIOSViewport() ? '0px' : '-18px';
    } catch (e) {}
    return '-18px';
  }

  function otlobliLooksLikeLegacyIOSViewport() {
    try {
      var w = Math.min(window.innerWidth || 0, window.innerHeight || 0);
      var h = Math.max(window.innerWidth || 0, window.innerHeight || 0);
      var dpr = window.devicePixelRatio || 1;
      return dpr >= 2 && w <= 414 && h <= 736;
    } catch (e) {}
    return false;
  }

  function otlobliResetTemuNavContentOffset(nav) {
    if (!IS_TEMU || !nav || !nav.querySelectorAll) return;
    if (nav.getAttribute('data-otlobli-temu-nav-content-align') === 'v85.8.54-reset') return;
    var tabs = nav.querySelectorAll('button[id^="otlobli-nav-tab-"]');
    for (var i = 0; i < tabs.length; i++) {
      var tab = tabs[i];
      var svg = tab.querySelector && tab.querySelector('svg');
      if (svg && svg.style) {
        svg.style.removeProperty('transform');
        svg.style.removeProperty('-webkit-transform');
      }
      var spans = tab.querySelectorAll ? tab.querySelectorAll('span') : [];
      for (var s = 0; s < spans.length; s++) {
        var span = spans[s];
        if (!span || !span.textContent || !span.textContent.trim()) continue;
        span.style.removeProperty('transform');
        span.style.removeProperty('-webkit-transform');
      }
    }
    nav.setAttribute('data-otlobli-temu-nav-content-align', 'v85.8.54-reset');
  }

  function otlobliStabilizeBackOverlay(el) {
    var host = document.body || document.documentElement;
    if (!el || !host) return;
    if (el.parentNode !== host ||
        (host.lastElementChild !== el && otlobliNavIsActuallyCovered(el))) {
      el.style.setProperty('animation', 'none', 'important');
      host.appendChild(el);
    }
    el.style.setProperty('-webkit-backface-visibility', 'hidden', 'important');
    el.style.setProperty('backface-visibility', 'hidden', 'important');
    el.style.setProperty('position', 'fixed', 'important');
    el.style.setProperty('z-index', '2147483647', 'important');
    el.style.setProperty('transform', 'translate3d(0,0,0)', 'important');
    el.style.setProperty('pointer-events', 'auto', 'important');
  }

  function ensureOtlobliNav() { return;
    var existingNav = document.getElementById('otlobli-nav');
    if (existingNav) {
      if (existingNav.getAttribute('data-otlobli-nav-style') !== OTLOBLI_NAV_STYLE_VERSION) {
        existingNav.style.cssText = OTLOBLI_NAV_CSS;
        existingNav.setAttribute('data-otlobli-nav-style', OTLOBLI_NAV_STYLE_VERSION);
      }
      otlobliResetTemuNavContentOffset(existingNav);
      otlobliStabilizeTemuNavLayer(existingNav);
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
    nav.style.cssText = OTLOBLI_NAV_CSS;
    nav.setAttribute('data-otlobli-nav-style', OTLOBLI_NAV_STYLE_VERSION);
    var items = [
      { label: 'الرئيسية', icon: OTLOBLI_NAV_ICONS.home, type: 'openHome' },
      { label: 'طلباتي', icon: OTLOBLI_NAV_ICONS.orders, type: 'openOrders' },
      { label: 'السلة', icon: OTLOBLI_NAV_ICONS.cart, type: 'openCart' },
      { label: 'حسابي', icon: OTLOBLI_NAV_ICONS.profile, type: 'openProfile' },
    ];
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var tab = document.createElement('button');
      tab.id = 'otlobli-nav-tab-' + i;
      var isActiveTab = item.type === 'openHome';
      tab.style.cssText = 'position:relative!important;flex:1 1 25%!important;width:25%!important;max-width:25%!important;' +
        'min-width:0!important;height:auto!important;min-height:0!important;align-self:stretch!important;border:0!important;' +
        'background:transparent!important;display:flex!important;flex-direction:column!important;align-items:center!important;' +
        'justify-content:center!important;padding:10px 0 0 0!important;margin:0!important;' +
        'box-sizing:border-box!important;font-size:12px!important;line-height:normal!important;font-weight:700!important;' +
        'font-family:system-ui,-apple-system,sans-serif!important;color:' + (isActiveTab ? '#006948' : '#3d4a42') + '!important;';
      if (isActiveTab) {
        var indicator = document.createElement('span');
        indicator.style.cssText = 'position:absolute!important;top:0!important;left:50%!important;transform:translateX(-50%)!important;width:32px!important;height:4px!important;border-radius:999px!important;background:#006948!important;';
        tab.appendChild(indicator);
      }
      tab.insertAdjacentHTML('beforeend', '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
        'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + item.icon + '</svg>' +
        '<span style="font:inherit!important;line-height:normal!important;margin-top:4px!important">' + item.label + '</span>');
      if (item.type) {
        tab.setAttribute('data-otlobli-nav-type', item.type);
      }
      nav.appendChild(tab);
    }
    otlobliResetTemuNavContentOffset(nav);
    if (IS_TEMU) otlobliStabilizeTemuNavLayer(nav);
    else (document.documentElement || document.body).appendChild(nav);
  }

  var __otlobliBackTarget = 'home';

  function otlobliBackOrLeave() {
    var f = location.href, h = sessionStorage.getItem('__otlobliHomePath') || '/';
    try { history.back(); } catch (e) {}
    setTimeout(function () { if (location.href === f) location.assign(location.origin + h); }, 900);
  }

  function ensureBackButton() { return;
    var btn = document.getElementById('otlobli-back-btn');
    if (!btn) {
      ensureShakeStyle();
      btn = document.createElement('button');
      btn.id = 'otlobli-back-btn';
      btn.setAttribute('aria-label', 'رجوع');
      btn.style.cssText = 'position:fixed;right:10px;top:12px;width:42px;height:42px;z-index:2147483647;' +
        'transform:translateZ(0);will-change:transform;' +
        'background:rgba(20,24,22,.6);color:#fff;border:none;border-radius:11px;display:none;' +
        'align-items:center;justify-content:center;font-size:30px;line-height:1;font-family:Arial,system-ui,sans-serif;font-weight:700;' +
        'box-shadow:0 4px 12px rgba(0,0,0,.32);animation:otlobli-pop2 .25s ease-out;';
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
        if (IS_SHEIN && looksLikeHomeRoot()) {
          try {
            if (window.mobileApp && window.mobileApp.postMessage) {
              window.mobileApp.postMessage({ detail: { type: 'requestStoreExit', store: 'shein' } });
            }
          } catch (e) {}
        } else if (IS_TEMU && otlobliTemuSearchBackActive()) {
          otlobliTemuExitSearchMode();
        } else if (!looksLikeHomeRoot() || looksLikeProductPage()) {
          otlobliBackOrLeave();
        }
      }, true);
      otlobliStabilizeBackOverlay(btn);
    }
    var temuSearchBack = IS_TEMU && otlobliTemuSearchBackActive();
    var shouldShow = IS_SHEIN || __otlobliBackTarget === 'cart' || !looksLikeHomeRoot()
      || looksLikeProductPage() || temuSearchBack;
    var backTop = temuSearchBack ? 30 : ((IS_SHEIN && viewportSize().width <= 390) ? 58 : 12);
    btn.style.setProperty('top', backTop + 'px', 'important');
    btn.style.display = shouldShow ? 'flex' : 'none';
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.messageHandler) {
      var nativeBackTarget = __otlobliBackTarget === 'cart'
        ? 'cart'
        : (IS_SHEIN && looksLikeHomeRoot() ? 'exit' : 'home');
      var nativeState = (shouldShow ? '1:' : '0:') + backTop + ':' + nativeBackTarget;
      if (window.__otlobliNativeBackState !== nativeState) {
        window.__otlobliNativeBackState = nativeState;
        window.mobileApp.postMessage({ detail: {
          type: 'otlobliBackButtonState', visible: shouldShow, top: backTop, target: nativeBackTarget
        } });
      }
    }
    if (shouldShow) otlobliStabilizeBackOverlay(btn);
  }

  function isAddToCartText(el) {
    var explicitLabel = (el.getAttribute && el.getAttribute('aria-label')) || el.value || '';
    var text = String(explicitLabel || ((el.childElementCount || 0) <= 6 ? el.textContent : '') || '').trim();
    if (!text || text.length > 60) return false;
    return /add to (bag|cart)/i.test(text) || /أضف.*(عربة|السلة|للسلة|الحقيبة|التسوق)/.test(text);
  }

  function isAddToCartButton(el, event) {
    if (!el || el.nodeType !== 1 || !isAddToCartText(el)) return false;
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

  function isQuickAddSubmitButton(el) {
    if (looksLikeProductPage()) return false;
    var text = (el.textContent || '').trim();
    if (!text || text.length > 30) return false;
    return /^(إضافة|أضف|تأكيد|اضافة|add|confirm)/i.test(text) || /عربة|السلة|التسوق|الحقيبة|bag|cart/i.test(text);
  }

  function looksLikeCartUrl(href) {
    if (!href) return false;
    return /\/(cart|bag|checkout|order-confirm|payment)(\b|[/?#.])/i.test(href);
  }

  function isCartLink(el) {
    if (el.id && el.id.indexOf('otlobli') === 0) return false;
    if (el.tagName === 'A' && looksLikeCartUrl(el.getAttribute('href') || el.href || '')) return true;
    var cls = ' ' + (el.className || '') + ' ';
    return /\s(cart-icon|header-cart|j-header-cart|shopping-bag|bag-icon)\s/i.test(cls);
  }

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
    var text = ((el.textContent || '') + '').replace(/\s+/g, ' ').trim();
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
      if (tag === 'FORM' || /(?:^|[-_\s])(login|signin|sign-in|auth|phone|email)(?:$|[-_\s])/.test(hint)) return true;
      node = node.parentElement;
      depth++;
    }
    return false;
  }

  function isProtectedSheinControl(el) {
    if (!el || !el.getAttribute) return false;
    if (el.id && el.id.indexOf('otlobli') === 0) return false;
    if (otlobliIsSheinTopCategoryEl(el)) return false;
    if (isSheinAuthControl(el)) return false;
    var tag = el.tagName;
    var interactive = tag === 'BUTTON' || tag === 'A' || el.getAttribute('role') === 'button' ||
      window.getComputedStyle(el).cursor === 'pointer';
    if (!interactive) return false;
    var shortText = (el.textContent || '').trim();
    var hint = ((el.className || '') + ' ' + (el.getAttribute('aria-label') || '') + ' ' +
      (el.getAttribute('title') || '') + ' ' + (shortText.length <= 40 ? shortText : '')).toLowerCase();
    if (/currency|العملة|عملة|\bregion\b|country|البلد|الدولة|language|اللغة|\blang\b|لغة|\bsetting|تغيير العملة|تغيير اللغة/.test(hint)) return true;
    var menuHint = /hamburger|nav-?toggle|side-?menu|drawer|menu-?(btn|button|icon|toggle|bar)|\bmenu\b/.test(hint);
    if (menuHint && isIconOnlySheinControl(el)) {
      var rect = el.getBoundingClientRect();
      if (rect.top >= -10 && rect.top <= 220 && rect.width > 0 && rect.width <= 90 && rect.height > 0 && rect.height <= 90) return true;
    }
    return false;
  }

  document.addEventListener('click', function (event) {
    if (!IS_SHEIN) return;
    var el = event.target;
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
        event.preventDefault();
        event.stopPropagation();
        return;
      }
      if (isAddToCartButton(el, event)) {
        event.preventDefault();
        event.stopPropagation();
        if (!looksLikeProductPage()) {
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

  function otlobliNearSearchInput(node) {
    var up = node;
    var hops = 0;
    while (up && hops < 4) {
      if (up.querySelector && up.querySelector('input, textarea, [contenteditable="true"]')) return true;
      var c = (up.className && up.className.baseVal !== undefined) ? up.className.baseVal : (up.className || '');
      if (typeof c === 'string' && /search|بحث/i.test(c)) return true;
      up = up.parentElement;
      hops++;
    }
    return false;
  }
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
  function otlobliLooksLikeSearchTrigger(el) {
    return /search|بحث/i.test(otlobliCollectIdentityHints(el));
  }
  var OTLOBLI_KNOWN_DISTRACTION = /cart|bag|basket|shopping|account|profile|user|me|menu|hamburger|categor|nav|wishlist|favorite|favourite|heart|message|inbox|notification|chat|سلة|السلة|عربة|حساب|حسابي|بروفايل|قائمة|التصنيفات|الأقسام|المفضلة|مفضلة|رسائل|الرسائل|إشعارات|اشعارات/i;
  function otlobliLooksLikeKnownDistraction(el) {
    return OTLOBLI_KNOWN_DISTRACTION.test(otlobliCollectIdentityHints(el));
  }

  function otlobliCompactText(text) {
    return ((text || '') + '').replace(/\s+/g, ' ').trim();
  }

  function otlobliIsSheinTopCategoryText(text) {
    var t = otlobliCompactText(text);
    return /^(?:كل|نساء|رجال|أطفال|اطفال|أحجام كبيرة|احجام كبيرة|مقاسات كبيرة|all|women|men|kids|children|curve|plus size)$/i.test(t);
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

  function hideSheinHeaderControls() {
    var header = findTopHeaderEl();
    if (!header) return;
    var els = header.querySelectorAll('button, a, [role="button"], [class*="icon" i], svg');
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.tagName === 'SVG' || el.tagName === 'svg') {
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
      if (el.style.visibility === 'hidden') continue;
      var rect = el.getBoundingClientRect();
      if (rect.width <= 0 || rect.width > 96 || rect.height <= 0 || rect.height > 96) continue;
      el.setAttribute('data-otlobli-blocked', '1');
      el.style.setProperty('visibility', 'hidden', 'important');
      el.style.setProperty('pointer-events', 'none', 'important');
    }
  }

  var __otlobliNativeAddScanAt = 0;
  function hideSheinNativeProductAdd() {
    if (!IS_SHEIN || !looksLikeProductPage()) return;
    var now = Date.now();
    if (now - __otlobliNativeAddScanAt < 450) return;
    __otlobliNativeAddScanAt = now;
    var vp = viewportSize();
    var nav = document.getElementById('otlobli-nav');
    var nr = nav && nav.getBoundingClientRect ? nav.getBoundingClientRect() : null;
    var navTop = nr && nr.top > 0 ? nr.top : vp.height - 90;
    function hide(el) {
      if (!el || el.style && el.style.display === 'none') return;
      if (!el.getBoundingClientRect || (el.closest && el.closest('[id^="otlobli"]'))) return;
      var r = el.getBoundingClientRect();
      if (r.width < 64 || r.width > vp.width * 1.05 || r.height < 24 || r.height > 100 || r.bottom < navTop - 190 || r.top > navTop + 24) return;
      if (!isAddToCartText(el)) return;
      el.style.setProperty('display', 'none', 'important');
      el.style.setProperty('visibility', 'hidden', 'important');
      el.style.setProperty('pointer-events', 'none', 'important');
      el.setAttribute('data-otlobli-hidden-native-add', 'product-action');
    }
    var nodes = document.querySelectorAll('button,a,[role="button"],[class*="add" i],[aria-label*="add" i]');
    for (var i = 0; i < nodes.length && i < 140; i++) hide(nodes[i]);
    if (!document.elementsFromPoint) return;
    var xs = [Math.round(vp.width * .2), Math.round(vp.width * .5), Math.round(vp.width * .8)];
    var ys = [Math.max(1, navTop - 12), Math.max(1, navTop - 48), Math.max(1, navTop - 84)];
    for (var y = 0; y < ys.length; y++) for (var x = 0; x < xs.length; x++) {
      var stack = document.elementsFromPoint(xs[x], ys[y]);
      for (var s = 0; s < stack.length; s++) hide(stack[s]);
    }
  }

  var __otlobliBottomNavDebugCount = 0;
  var __otlobliBottomNavDeepScanAt = 0;

  function getElementText(el) {
    try { return (el.textContent || '').replace(/\s+/g, ' ').trim(); } catch (e) {}
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

  var __otlobliForceAcceptTries = 0;
  var __otlobliForceAcceptScans = 0;
  function otlobliForceAcceptCookies() {
    if (!document.body) return;
    if (__otlobliForceAcceptTries >= 10 || __otlobliForceAcceptScans >= 16) return;
    __otlobliForceAcceptScans++;
    var bodyText = document.body.textContent || '';
    if (!/ملفات تعريف الارتباط|cookies?/i.test(bodyText)) return;
    function cleanLabel(s) {
      return String(s || '').replace(/[\u200e\u200f\u061c\u202a-\u202e]/g, '').replace(/\s+/g, ' ').trim();
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

  var __otlobliCookieScanAt = 0;
  var __otlobliCookieAcceptClicksShein = 0;
  function protectSheinCookieConsentAction() {
    if (!IS_SHEIN || !document.body) return;
    var scanNow = Date.now();
    if (scanNow - __otlobliCookieScanAt < 650) return;
    __otlobliCookieScanAt = scanNow;
    var controls = document.querySelectorAll('button, [role="button"], a, input[type="button"], input[type="submit"]');
    var acceptPattern = /^(?:accept(?: all)?|allow(?: all)?|agree(?: to all)?|\u0642\u0628\u0648\u0644(?: \u0627\u0644\u0643\u0644)?|\u0627\u0642\u0628\u0644(?: \u0627\u0644\u0643\u0644)?|\u0627\u0644\u0633\u0645\u0627\u062d (?:\u0644\u0644\u0643\u0644|\u0644\u0644\u062c\u0645\u064a\u0639)|\u0645\u0648\u0627\u0641\u0642)$/i;
    var rejectPattern = /^(?:reject all|decline all|deny all|\u0631\u0641\u0636 \u0627\u0644\u0643\u0644|\u0639\u062f\u0645 \u0627\u0644\u0642\u0628\u0648\u0644)$/i;
    var cookiePattern = /cookies?|\u0645\u0644\u0641\u0627\u062a \u062a\u0639\u0631\u064a\u0641 \u0627\u0644\u0627\u0631\u062a\u0628\u0627\u0637|\u0627\u0644\u062a\u0642\u0646\u064a\u0627\u062a \u0627\u0644\u0645\u0645\u0627\u062b\u0644\u0629/i;
    var vp = viewportSize();
    for (var i = 0; i < controls.length; i++) {
      var button = controls[i];
      var label = String(button.innerText || button.textContent || button.value || button.getAttribute('aria-label') || '').replace(/\s+/g, ' ').trim();
      if (!acceptPattern.test(label)) continue;
      var scope = button;
      var cookieScope = null;
      for (var hop = 0; scope && hop < 7; hop++, scope = scope.parentElement) {
        var text = String(scope.innerText || scope.textContent || '').replace(/\s+/g, ' ').trim();
        if (text.length < 2400 && cookiePattern.test(text)) {
          cookieScope = scope;
          break;
        }
      }
      if (!cookieScope) continue;
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
        var rejectLabel = String(scopedControls[ri].innerText || scopedControls[ri].textContent || scopedControls[ri].value || scopedControls[ri].getAttribute('aria-label') || '').replace(/\s+/g, ' ').trim();
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

  var __otlobliSignupLastScanAt = 0;
  function hideSheinSignupDiscountBanner() {
    if (!IS_SHEIN || !document.body || !document.elementsFromPoint) return;
    var scanNow = Date.now();
    if (scanNow - __otlobliSignupLastScanAt < (OTLOBLI_LOW_END ? 1800 : 700)) return;
    __otlobliSignupLastScanAt = scanNow;
    var vp = viewportSize();
    var nav = document.getElementById('otlobli-nav');
    var navRect = nav && nav.getBoundingClientRect ? nav.getBoundingClientRect() : null;
    var navTop = navRect && navRect.top > 0 ? navRect.top : vp.height - 90;
    var offerPattern = /(?:get\s*15\s*%\s*off|15\s*%\s*off|\u0627\u062d\u0635\u0644\s+\u0639\u0644[\u0649\u064a]\s+\u062e\u0635\u0645\s*15\s*%|\u062e\u0635\u0645\s*15\s*%)/i;
    var signupPattern = /(?:^|\s)(?:register|sign\s*up|join\s*now|\u062a\u0633\u062c\u064a\u0644|\u0633\u062c\u0644)(?:\s|$)/i;
    var newsletterPattern = /(?:exclusive\s+offers|shein\s+news|newsletter|unsubscribe|\u0627\u0644\u0639\u0631\u0648\u0636\s+\u0627\u0644\u062d\u0635\u0631\u064a\u0629|\u0623\u062e\u0628\u0627\u0631\s+shein|(?:\u0625|\u0627)\u0644\u063a\u0627\u0621\s+\u0627\u0644\u0627\u0634\u062a\u0631\u0627\u0643)/i;
    var emailPattern = /(?:email|e-mail|\u0627\u0644\u0628\u0631\u064a\u062f\s+\u0627\u0644(?:\u0625|\u0627)\u0644\u0643\u062a\u0631\u0648\u0646\u064a|\u0628\u0631\u064a\u062f\u0643\s+\u0627\u0644(?:\u0625|\u0627)\u0644\u0643\u062a\u0631\u0648\u0646\u064a)/i;
    var authPattern = /(?:sign\s*in|log\s*in|continue\s+with|phone\s+number|\u062a\u0633\u062c\u064a\u0644\s+\u0627\u0644\u062f\u062e\u0648\u0644|\u0631\u0642\u0645\s+\u0627\u0644\u0645\u0648\u0628\u0627\u064a\u0644|\u0627\u0644\u0627\u0633\u062a\u0645\u0631\u0627\u0631\s+\u0628\u062c\u0648\u062c\u0644)/i;

    var inspected = [];
    function inspect(node) {
      var current = node;
      var matched = null;
      for (var depth = 0; current && current !== document.body && current !== document.documentElement && depth < 9; depth++) {
        if (current.id && current.id.indexOf('otlobli') === 0) break;
        if (inspected.indexOf(current) >= 0) {
          current = current.parentElement;
          continue;
        }
        inspected.push(current);
        var text = String(current.textContent || '').replace(/\s+/g, ' ').trim()
          .replace(/[\u064B-\u065F\u0670]/g, '');
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

  var __otlobliSheinLoginDismissAt = 0;
  function dismissSheinProductLoginPrompt() {
    if (!IS_SHEIN || !document.body || !looksLikeProductPage()) return;
    if (/(?:\/user\/login|\/login|\/signin|\/sign-in|\/auth)(?:[/?#]|$)/i.test(location.pathname + location.search)) return;
    var now = Date.now();
    if (now - __otlobliSheinLoginDismissAt < 900) return;
    __otlobliSheinLoginDismissAt = now;
    var vp = viewportSize();
    var authPattern = /(?:sign\s*in|log\s*in|continue\s+with|email|phone\s+number|\u062a\u0633\u062c\u064a\u0644\s+\u0627\u0644\u062f\u062e\u0648\u0644|\u0627\u0644\u0627\u0633\u062a\u0645\u0631\u0627\u0631\s+\u0628|\u0627\u0644\u0628\u0631\u064a\u062f\s+\u0627\u0644(?:\u0625|\u0627)\u0644\u0643\u062a\u0631\u0648\u0646\u064a|\u0631\u0642\u0645\s+\u0627\u0644\u0647\u0627\u062a\u0641)/i;
    var cookiePattern = /cookies?|\u0645\u0644\u0641\u0627\u062a \u062a\u0639\u0631\u064a\u0641 \u0627\u0644\u0627\u0631\u062a\u0628\u0627\u0637/i;
    var closePattern = /^(?:close|dismiss|skip|not now|maybe later|later|\u00d7|\u2715|\u2716|\u0625\u063a\u0644\u0627\u0642|\u0627\u063a\u0644\u0627\u0642|\u062a\u062e\u0637\u064a|\u0644\u064a\u0633 \u0627\u0644\u0622\u0646|\u0644\u0627\u062d\u0642(?:\u0627|\u0627\u064b))$/i;
    var candidates = document.querySelectorAll(
      '[role="dialog"],[aria-modal="true"],[class*="login"],[class*="signin"],[class*="sign-in"],[class*="modal"],[class*="popup"],[class*="drawer"]'
    );
    for (var ci = candidates.length - 1; ci >= 0; ci--) {
      var candidate = candidates[ci];
      if (!candidate || (candidate.id && candidate.id.indexOf('otlobli') === 0) || !sheinElementIsVisible(candidate)) continue;
      var rect = candidate.getBoundingClientRect();
      if (rect.width < vp.width * 0.55 || rect.height < 90 || rect.bottom < 60 || rect.top > vp.height - 60) continue;
      var text = getElementText(candidate).replace(/[\u064B-\u065F\u0670]/g, '');
      if (!text || text.length > 1800 || !authPattern.test(text) || cookiePattern.test(text)) continue;
      var fields = candidate.querySelectorAll('input, select, textarea');
      if (!fields.length && !/continue\s+with|\u0627\u0644\u0627\u0633\u062a\u0645\u0631\u0627\u0631\s+\u0628/i.test(text)) continue;
      var controls = candidate.querySelectorAll('button, a, [role="button"]');
      var closeTarget = null;
      for (var bi = 0; bi < controls.length; bi++) {
        var control = controls[bi];
        if (!control || (control.id && control.id.indexOf('otlobli') === 0) || !sheinElementIsVisible(control)) continue;
        var label = String(control.innerText || control.textContent || control.getAttribute('aria-label') || control.getAttribute('title') || '')
          .replace(/\s+/g, ' ').trim();
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

  var __otlobliCartToastGuardUntil = 0;
  var __otlobliCartToastProductKey = '';
  function hideSheinCartSuccessToast() {
    if (!IS_SHEIN || !document.body) return;
    var quickFooter = document.querySelector('.sui-drawer__open .bsc-quick-add-cart__footerBar');
    if (quickFooter) quickFooter.style.setProperty('display', 'none', 'important');
    var productMatch = location.pathname.match(/-p-(\d+)/i);
    var productKey = productMatch ? productMatch[1] : '';
    if (!productKey) __otlobliCartToastProductKey = '';
    else if (productKey !== __otlobliCartToastProductKey) {
      __otlobliCartToastProductKey = productKey;
      __otlobliCartToastGuardUntil = Date.now() + 15000;
    }
    if (Date.now() > __otlobliCartToastGuardUntil) return;
    var vp = viewportSize();
    var successPattern = /added to (?:the )?(?:shopping )?(?:bag|cart) successfully|\u0623\u0636(?:\u064a\u0641|\u0641)\s+\u0625\u0644\u0649\s+(?:\u0639\u0631\u0628\u0629|\u062d\u0642\u064a\u0628\u0629)\s+\u0627\u0644\u062a\u0633\u0648\u0642\s+\u0628\u0646\u062c\u0627\u062d/i;

    var inspected = [];
    function inspect(node) {
      var current = node;
      for (var depth = 0; current && current !== document.body && current !== document.documentElement && depth < 7; depth++) {
        if (current.id && current.id.indexOf('otlobli') === 0) return;
        if (inspected.indexOf(current) >= 0) {
          current = current.parentElement;
          continue;
        }
        inspected.push(current);
        var text = String(current.textContent || '')
          .replace(/[\u064B-\u065F\u0670]/g, '')
          .replace(/\s+/g, ' ')
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
    }

    var alerts = document.querySelectorAll('[role="alert"], [role="status"], [class*="toast" i], [class*="message" i]');
    for (var ai = 0; ai < alerts.length; ai++) inspect(alerts[ai]);
  }

  
  var OTLOBLI_HUMAN_CHECK_PENDING_KEY = '__otlobliHumanCheckPendingAt';
  var __otlobliChallengePendingAt = 0;
  try {
    __otlobliChallengePendingAt = parseInt(sessionStorage.getItem(OTLOBLI_HUMAN_CHECK_PENDING_KEY) || '0', 10) || 0;
    if (__otlobliChallengePendingAt && Date.now() - __otlobliChallengePendingAt > 900000) {
      sessionStorage.removeItem(OTLOBLI_HUMAN_CHECK_PENDING_KEY);
      __otlobliChallengePendingAt = 0;
    }
  } catch (e) {}

  var __otlobliChallengeNotified = false;
  var __otlobliChallengeResolvedNotified = false;
  var __otlobliChallengeSkippedNotified = false;
  var otlobliChallengeActive = !!__otlobliChallengePendingAt;
  var __otlobliChallengeScanAt = 0;
  var __otlobliChallengeScanResult = false;

  function otlobliRememberHumanChallenge() {
    if (__otlobliChallengePendingAt) return;
    __otlobliChallengePendingAt = Date.now();
    try { sessionStorage.setItem(OTLOBLI_HUMAN_CHECK_PENDING_KEY, String(__otlobliChallengePendingAt)); } catch (e) {}
  }

  function otlobliForgetHumanChallenge() {
    __otlobliChallengePendingAt = 0;
    try { sessionStorage.removeItem(OTLOBLI_HUMAN_CHECK_PENDING_KEY); } catch (e) {}
    var guide = document.getElementById('otlobli-human-check-guide');
    if (guide) guide.remove();
  }

  function otlobliMatchesHumanChallengeText(value) {
    var text = String(value || '').replace(/s+/g, ' ').trim().slice(0, 1600);
    if (!text) return false;
    return /verify (?:that )?you are (?:a )?human|human verification|security verification|checking your browser|confirm (?:that )?you are (?:a )?human|i(?:'|’)m (?:not a robot|human)|cloudflare|turnstile|التحقق من أنك إنسان|تحقق أنك إنسان|أنا إنسان|لست (?:إنساناً آلياً|روبوت(?:اً)?)|التحقق الأمني|التحقق من الأمان/i.test(text);
  }

  function otlobliIsHumanChallenge() {
    try {
      if (otlobliIsHumanChallengeUrl(location.href)) return true;
      if (/just a moment/i.test(document.title || '')) return true;
      var challengeNow = Date.now();
      if (!otlobliChallengeActive && challengeNow - __otlobliChallengeScanAt < 1500) return __otlobliChallengeScanResult;
      __otlobliChallengeScanAt = challengeNow;
      if (document.getElementById('challenge-form')) return (__otlobliChallengeScanResult = true);
      if (document.querySelector('script[src*="challenges.cloudflare.com"],iframe[src*="challenges.cloudflare.com"]')) return (__otlobliChallengeScanResult = true);
      var proprietaryChecks = document.querySelectorAll('.one-pass-dialog,#one-pass-custom,one-pass-custom,#nine-captcha-custom,nine-captcha-custom,.si-verify-block-request-dialog,[class*="risk-one-pass" i]');
      for (var pi = 0; pi < proprietaryChecks.length; pi++) {
        if (sheinElementIsPainted(proprietaryChecks[pi])) return (__otlobliChallengeScanResult = true);
      }

      var semanticChecks = document.querySelectorAll('[role="dialog"],[aria-modal="true"],.sui-dialog__wrapper,[id*="captcha" i],[class*="captcha" i],[id*="challenge" i],[class*="challenge" i],[data-testid*="challenge" i],[class*="one-pass" i],[class*="turnstile" i]');
      var semanticStart = Math.max(0, semanticChecks.length - 12);
      for (var si = semanticStart; si < semanticChecks.length; si++) {
        var surface = semanticChecks[si];
        if (!sheinElementIsPainted(surface)) continue;
        var surfaceIdentity = String((surface.id || '') + ' ' + (surface.className || '') + ' ' + (surface.getAttribute && (surface.getAttribute('data-testid') || surface.getAttribute('aria-label')) || '')).slice(0, 600);
        if (/risk-one-pass|captcha|challenge|cf-turnstile|si-verify-block-request/i.test(surfaceIdentity)) return (__otlobliChallengeScanResult = true);
        if (otlobliMatchesHumanChallengeText(surface.textContent || '')) return (__otlobliChallengeScanResult = true);
      }
    } catch (e) {}
    __otlobliChallengeScanResult = false;
    return __otlobliChallengeScanResult;
  }

  function otlobliEnsureHumanCheckGuide() {
    if (!document.body) return;
    var guide = document.getElementById('otlobli-human-check-guide');
    if (!guide) {
      guide = document.createElement('div');
      guide.id = 'otlobli-human-check-guide';
      guide.setAttribute('role', 'status');
      guide.setAttribute('aria-live', 'polite');
      guide.style.cssText = 'position:fixed!important;top:calc(env(safe-area-inset-top,0px) + 10px)!important;left:50%!important;transform:translateX(-50%)!important;width:calc(100% - 24px)!important;max-width:390px!important;box-sizing:border-box!important;z-index:2147483646!important;pointer-events:none!important;direction:rtl!important;text-align:right!important;background:#f4fbf7!important;color:#12382b!important;border:1px solid #b9ddcc!important;border-radius:14px!important;box-shadow:0 8px 24px rgba(15,61,45,.16)!important;padding:10px 12px!important;font-family:system-ui,-apple-system,sans-serif!important;line-height:1.45!important;';
      var challengeStoreLabel = IS_TEMU ? 'Temu' : 'SHEIN';
      guide.innerHTML = '<strong style="display:block;font-size:13px;font-weight:800">تحقق ' + challengeStoreLabel + ' مطلوب لفتح المنتجات</strong><span style="display:block;margin-top:2px;font-size:12px">أكمل التحقق داخل الصفحة للمتابعة، أو ارجع من الشريط بالأسفل.</span>';
      document.body.appendChild(guide);
    }
  }

  function otlobliLooksLikeRemovedProductPage() {
    if (!IS_SHEIN || !document.body) return false;
    var text = String(document.body.innerText || document.body.textContent || '').replace(/\s+/g, ' ').trim();
    if (!text || text.length > 900) return false;
    return /تمت إزالة المنتج|تم حذف المنتج|المنتج لم يعد متوفراً|product (?:has been )?removed|product is no longer available/i.test(text);
  }

  function otlobliNotifyHumanCheckSkipped() {
    if (__otlobliChallengeSkippedNotified) return;
    __otlobliChallengeSkippedNotified = true;
    otlobliChallengeActive = false;
    otlobliForgetHumanChallenge();
    try {
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: 'humanCheckSkipped' } });
      }
    } catch (e) {}
  }

  function otlobliEnterChallengeMode() {
    otlobliRememberHumanChallenge();
    try {
      var ours = document.querySelectorAll('[id^="otlobli"]');
      for (var ci = 0; ci < ours.length; ci++) {
        try {
          var oid = ours[ci].id || '';
          if (oid === 'otlobli-nav' || oid === 'otlobli-human-check-guide' || oid.indexOf('otlobli-nav-tab-') === 0) continue;
          if (ours[ci].parentNode) ours[ci].parentNode.removeChild(ours[ci]);
        } catch (e) {}
      }
    } catch (e) {}
    otlobliScheduleChallengeNav();
    otlobliEnsureHumanCheckGuide();
    try { sheinUnlockPageBehindShippingDrawer(); sheinReleaseFixedBodyLock(); } catch (e) {}
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
    if (document.getElementsByTagName('*').length > 900) return;
    var bodyText = document.body.textContent;
    if (bodyText && bodyText.length < 2000 && /GSRM|gone missing|not avaliable|not available|system not/i.test(bodyText)) {
      sheinBlockReported = true;
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: 'sheinBlocked' } });
      }
    }
  }

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

  function sheinViewerHasVisibleCounter(el, vp) {
    var nodes = el.querySelectorAll ? el.querySelectorAll('span,em,i,[class*="count" i],[class*="index" i]') : [];
    for (var i = 0; i < nodes.length && i < 120; i++) {
      var value = String(nodes[i].textContent || '').trim();
      if (!/^\d{1,3}\s*\/\s*\d{1,3}$/.test(value)) continue;
      var parts = value.split('/');
      var current = parseInt(parts[0], 10), total = parseInt(parts[1], 10);
      var rect = nodes[i].getBoundingClientRect();
      if (current > 0 && total > 1 && current <= total && rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.top < vp.height) return true;
    }
    return false;
  }

  function isSheinImageViewerCandidate(el, vp) {
    if (!el || (el.id || '').indexOf('otlobli') === 0 || !el.getBoundingClientRect) return false;
    if ((el.matches && el.matches('.bsc-quick-add-cart')) ||
        (el.querySelector && el.querySelector('.bsc-quick-add-cart'))) return false;
    var style = window.getComputedStyle(el);
    if (style.display === 'none' || style.visibility === 'hidden' || parseFloat(style.opacity || '1') <= 0.01) return false;
    var role = String(el.getAttribute && el.getAttribute('role') || '').toLowerCase();
    var ariaModal = String(el.getAttribute && el.getAttribute('aria-modal') || '').toLowerCase();
    if (style.position !== 'fixed' && role !== 'dialog' && ariaModal !== 'true') return false;
    var rect = el.getBoundingClientRect();
    if (rect.width < vp.width * 0.88 || rect.height < vp.height * 0.55) return false;
    if (rect.top > 120 || rect.bottom < vp.height * 0.72) return false;
    var text = String(el.innerText || el.textContent || '').replace(/\s+/g, ' ').trim();
    if (text.length > 700 || /review|rating|comment|feedback|\u0627\u0644\u062a\u0642\u064a\u064a\u0645|\u0627\u0644\u062a\u0639\u0644\u064a\u0642/i.test(text) || !sheinViewerHasVisibleCounter(el, vp)) return false;
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
      document.body.appendChild(guard);
      if (nav) (document.documentElement || document.body).appendChild(nav);
      if (back) {
        back.style.setProperty('animation', 'none', 'important');
        otlobliStabilizeBackOverlay(back);
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
    window.__otlobliTemuSize = t;
    window.__otlobliTemuSizeGid = temuGoodsId();
    __otlobliAutoSizeTs = now;
  }

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
  }




  function otlobliTemuUsableSearchField(el, vp) {
    if (!el) return false;
    if (el.disabled) return false;
    var type = ((el.getAttribute && el.getAttribute('type')) || '').toLowerCase();
    if (type && !/^(search|text|url|tel)$/.test(type)) return false;
    var r = el.getBoundingClientRect();
    if (r.width < 80 || r.height < 20 || r.height > 72) return false;
    if (r.bottom <= 0 || r.top < -8 || r.top > Math.min(210, vp.height * 0.36)) return false;
    return true;
  }

  var __otlobliTemuLastSearchInput = null;
  function otlobliTemuRememberSearchInput(el) {
    if (el) __otlobliTemuLastSearchInput = el;
    return el;
  }

  function otlobliTemuSearchInput() {
    if (!IS_TEMU || !document.body) return null;
    try {
      var vp = viewportSize();
      var focused = document.activeElement;
      if (focused && focused.getBoundingClientRect) {
        var focusedTag = (focused.tagName || '').toLowerCase();
        var focusedType = ((focused.getAttribute && focused.getAttribute('type')) || '').toLowerCase();
        var focusedRole = ((focused.getAttribute && focused.getAttribute('role')) || '').toLowerCase();
        var focusedHints = otlobliCollectIdentityHints(focused) + ' ' +
          ((focused.getAttribute && (focused.getAttribute('placeholder') || focused.getAttribute('aria-label') || focused.getAttribute('name') || '')) || '');
        var focusedRect = focused.getBoundingClientRect();
        var focusedLooksText = focusedTag === 'input' || focusedTag === 'textarea' || focused.getAttribute('contenteditable') === 'true';
        var focusedLooksSearch = focusedRole === 'searchbox' || /search|بحث/i.test(focusedHints);
        var focusedBadType = /^(email|password|number|hidden|checkbox|radio|submit|button)$/i.test(focusedType);
        if (focusedLooksText && focusedLooksSearch && !focusedBadType &&
          focusedRect.width >= 20 && focusedRect.height >= 8 &&
          focusedRect.bottom > 0 && focusedRect.top >= -12 && focusedRect.top <= Math.min(260, vp.height * 0.42)) {
          return otlobliTemuRememberSearchInput(focused);
        }
      }
      var direct = document.querySelectorAll('input[type="search"], [role="searchbox"], input[placeholder*="بحث"], input[placeholder*="Search" i]');
      for (var d = 0; d < direct.length; d++) {
        if (otlobliTemuUsableSearchField(direct[d], vp)) return otlobliTemuRememberSearchInput(direct[d]);
      }
      var fields = document.querySelectorAll('input, textarea, [contenteditable="true"]');
      for (var i = 0; i < fields.length; i++) {
        var el = fields[i];
        if (!otlobliTemuUsableSearchField(el, vp)) continue;
        var hints = otlobliCollectIdentityHints(el);
        var ph = ((el.getAttribute && (el.getAttribute('placeholder') || el.getAttribute('aria-label') || el.getAttribute('name') || '')) || '');
        var value = typeof el.value === 'string' ? el.value : (el.textContent || '');
        if (/search|بحث/i.test(hints + ' ' + ph)) return otlobliTemuRememberSearchInput(el);
        if (value && value.length <= 80 && !/(email|mail|password|pass|login|account|حساب|دخول)/i.test(hints + ' ' + ph)) return otlobliTemuRememberSearchInput(el);
      }
    } catch (e) {}
    return null;
  }

  function otlobliTemuSearchInputForExit() {
    var input = otlobliTemuSearchInput();
    if (input) return input;
    try {
      if (__otlobliTemuLastSearchInput && document.contains && document.contains(__otlobliTemuLastSearchInput)) {
        return __otlobliTemuLastSearchInput;
      }
      var vp = viewportSize();
      var nodes = document.querySelectorAll('input[type="search"], [role="searchbox"], input[placeholder*="Search" i], input[placeholder*="بحث"]');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        var r = el.getBoundingClientRect();
        if (r.width >= 20 && r.height >= 8 && r.bottom > 0 && r.top >= -20 && r.top <= Math.min(320, vp.height * 0.5)) {
          return otlobliTemuRememberSearchInput(el);
        }
      }
    } catch (e) {}
    return null;
  }
  var __otlobliTemuSearchModeCacheTs = 0;
  var __otlobliTemuSearchModeCacheHref = '';
  var __otlobliTemuSearchModeCacheValue = false;
  var __otlobliTemuSearchExitSuppressUntil = 0;
  var __otlobliTemuSearchBackGraceUntil = 0;
  function otlobliTemuSearchMode() {
    if (!IS_TEMU || !document.body) return false;
    var si = otlobliTemuSearchInput();
    if (si) {
      if (document.activeElement === si) return true;
    }
    if (Date.now() < __otlobliTemuSearchExitSuppressUntil && otlobliTemuHomeLikeUrl()) return false;
    if (/search/i.test(location.pathname) || /search/i.test(location.search)) return true;
    var now = Date.now();
    var href = location.href || '';
    if (href === __otlobliTemuSearchModeCacheHref && now - __otlobliTemuSearchModeCacheTs < 90) {
      return __otlobliTemuSearchModeCacheValue;
    }
    var found = false;
    var overlays = document.querySelectorAll('div, section, aside');
    var vp = viewportSize();
    for (var i = 0; i < overlays.length; i++) {
      var el = overlays[i];
      var r = el.getBoundingClientRect();
      if (r.width < vp.width * 0.7 || r.height < 80 || r.top < 0 || r.top > 280) continue;
      var txt = temuCleanText(el.textContent);
      if (txt.length > 320) continue;
      if (/(رائج الآن|اقتراح|بحث شائع|search|suggest|trending)/i.test(txt)) { found = true; break; }
    }
    __otlobliTemuSearchModeCacheTs = now;
    __otlobliTemuSearchModeCacheHref = href;
    __otlobliTemuSearchModeCacheValue = found;
    return found;
  }

  function otlobliTemuSearchBackActive() {
    if (!IS_TEMU || !document.body) return false;
    try {
      if (document.body.getAttribute('data-otlobli-temu-search-mode') === '1') return true;
      if (otlobliTemuSearchMode()) return true;
      if (Date.now() < __otlobliTemuSearchBackGraceUntil && otlobliTemuSearchInputForExit()) return true;
    } catch (e) {}
    return false;
  }

  function otlobliTemuClearActiveSearchShells() {
    try {
      var marked = document.querySelectorAll('[data-otlobli-temu-active-search-shell="1"]');
      for (var i = 0; i < marked.length; i++) {
        marked[i].removeAttribute('data-otlobli-temu-active-search-shell');
      }
      var frames = document.querySelectorAll('[data-otlobli-temu-active-search-frame="1"]');
      for (var f = 0; f < frames.length; f++) {
        frames[f].removeAttribute('data-otlobli-temu-active-search-frame');
      }
    } catch (e) {}
  }

  function otlobliSyncTemuSearchModeState(searchMode) {
    if (!IS_TEMU || !document.body) return;
    try {
      var active = typeof searchMode === 'boolean' ? searchMode : otlobliTemuSearchMode();
      if (active) {
        document.body.setAttribute('data-otlobli-temu-search-mode', '1');
        __otlobliTemuSearchBackGraceUntil = Date.now() + (OTLOBLI_LOW_END ? 1200 : 800);
      } else {
        document.body.removeAttribute('data-otlobli-temu-search-mode');
        otlobliTemuClearActiveSearchShells();
      }
    } catch (e) {}
  }

  function otlobliHideTemuSearchExitOverlays() {
    if (!IS_TEMU || !document.body) return;
    try {
      var vp = viewportSize();
      var nodes = document.querySelectorAll('[data-otlobli-temu-search-exit-hidden="1"], div, section, aside');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (!el || (el.id && el.id.indexOf('otlobli') === 0)) continue;
        if (el.closest && (el.closest('#otlobli-nav') || el.closest('#otlobli-back-btn'))) continue;
        if (el.querySelector && el.querySelector('input, textarea, [role="searchbox"]')) continue;
        if (temuContainsPrice(el)) continue;
        var r = el.getBoundingClientRect();
        if (r.width < vp.width * 0.55 || r.height < 34 || r.height > vp.height * 0.72) continue;
        if (r.bottom < -4 || r.top < -4 || r.top > 340) continue;
        var txt = temuCleanText(el.textContent);
        if (!txt || txt.length > 700) continue;
        if (otlobliTemuAccountPanelScore(txt) >= 2) continue;
        if (!/(رائج الآن|اقتراح|بحث شائع|عمليات البحث|search|suggest|trending|recent searches|popular searches)/i.test(txt)) continue;
        el.setAttribute('data-otlobli-temu-search-exit-hidden', '1');
        el.setAttribute('data-otlobli-temu-hidden', '1');
        el.style.setProperty('display', 'none', 'important');
        el.style.setProperty('visibility', 'hidden', 'important');
        el.style.setProperty('opacity', '0', 'important');
        el.style.setProperty('pointer-events', 'none', 'important');
      }
    } catch (e) {}
  }

  function otlobliResetTemuHomeAfterSearchExit(input, clearValue) {
    try {
      var now = Date.now();
      __otlobliTemuSearchExitSuppressUntil = Math.max(__otlobliTemuSearchExitSuppressUntil, now + (OTLOBLI_LOW_END ? 1400 : 900));
      __otlobliTemuSearchBackGraceUntil = 0;
      if (input) {
        if (clearValue && typeof input.value === 'string' && input.value) {
          input.value = '';
        } else if (clearValue && input.isContentEditable) {
          input.textContent = '';
        }
        try { input.dispatchEvent(new Event('input', { bubbles: true })); } catch (e0) {}
        try { input.dispatchEvent(new Event('search', { bubbles: true })); } catch (e1) {}
        try { input.dispatchEvent(new Event('change', { bubbles: true })); } catch (e2) {}
        try { input.blur(); } catch (e3) {}
      }
      otlobliSyncTemuSearchModeState(false);
      otlobliHideTemuSearchExitOverlays();
      otlobliWakeTemuHomeHeaderAfterSearchExit();
      otlobliCleanTemuBlockers(true);
      ensureBackButton();
    } catch (e4) {}
  }

  function otlobliScheduleTemuHomeAfterSearchExit(input, clearValue) {
    otlobliResetTemuHomeAfterSearchExit(input, clearValue);
    setTimeout(function () { otlobliResetTemuHomeAfterSearchExit(null, false); }, 80);
    setTimeout(function () { otlobliResetTemuHomeAfterSearchExit(null, false); }, OTLOBLI_LOW_END ? 520 : 260);
  }

  function otlobliTemuClickNativeBackControl() {
    if (!IS_TEMU || !document.body) return false;
    try {
      var vp = viewportSize();
      var nodes = document.querySelectorAll('button, a, [role="button"], div, span, i');
      var best = null;
      var bestScore = -1;
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (el.closest && (el.closest('#otlobli-nav') || el.closest('#otlobli-back-btn'))) continue;
        if (el.querySelector && el.querySelector('input, textarea, [role="searchbox"]')) continue;
        var r = el.getBoundingClientRect();
        if (r.width < 18 || r.width > 72 || r.height < 18 || r.height > 72) continue;
        if (r.top < 0 || r.top > 260 || r.left < -4 || r.right > vp.width + 4) continue;
        var hints = otlobliCollectIdentityHints(el) + ' ' + temuCleanText(el.textContent);
        if (/camera|كاميرا|cart|basket|bag|account|login|menu|logo|temu/i.test(hints)) continue;
        var arrowText = temuCleanText(el.textContent);
        var looksBack = /(back|go back|previous|prev|return|رجوع|عودة|السابق|arrow|chevron)/i.test(hints) ||
          /^[‹›<>←→❮❯‹›]$/.test(arrowText);
        if (!looksBack && otlobliTemuSearchMode()) {
          looksBack = r.top < 240 && r.width <= 56 && r.height <= 64 && (r.left <= 80 || r.right >= vp.width - 80) &&
            !(el.querySelector && el.querySelector('input, textarea, [role="searchbox"]')) &&
            !otlobliLooksLikeSearchTrigger(el);
        }
        if (!looksBack) continue;
        var edge = Math.min(Math.max(0, r.left), Math.max(0, vp.width - r.right));
        var score = 200 - r.top - edge;
        if (score > bestScore) { bestScore = score; best = el; }
      }
      if (!best) return false;
      try { best.click(); return true; } catch (e) {}
      try {
        best.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
        return true;
      } catch (e2) {}
    } catch (e3) {}
    return false;
  }

  function restoreTemuSearchBackControls() {
    if (!IS_TEMU || !document.body) return;
    try {
      var nodes = document.querySelectorAll('[data-otlobli-temu-hidden="1"], button, a, [role="button"], div, span, i');
      var vp = viewportSize();
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (el.querySelector && el.querySelector('input, textarea, [role="searchbox"]')) continue;
        var txt = temuCleanText(el.textContent);
        var hints = otlobliCollectIdentityHints(el) + ' ' + txt;
        if (/camera|كاميرا|cart|basket|bag|account|login|menu|logo|temu/i.test(hints)) continue;
        var r = el.getBoundingClientRect();
        var looksBack = /(back|go back|previous|prev|return|رجوع|عودة|السابق|arrow|chevron)/i.test(hints) ||
          /^[‹›<>←→❮❯‹›]$/.test(txt);
        if (!looksBack && otlobliTemuSearchMode()) {
          looksBack = r.top < 240 && r.width <= 56 && r.height <= 64 && (r.left <= 80 || r.right >= vp.width - 80) &&
            !(el.querySelector && el.querySelector('input, textarea, [role="searchbox"]')) &&
            !otlobliLooksLikeSearchTrigger(el);
        }
        if (!looksBack) continue;
        if (r.width > 0 && r.height > 0 && (r.top < -4 || r.top > 260 || r.right < -4 || r.left > vp.width + 4)) continue;
        el.setAttribute('data-otlobli-temu-native-search-back', '1');
        el.setAttribute('data-otlobli-temu-hidden', '1');
        el.style.setProperty('visibility', 'hidden', 'important');
        el.style.setProperty('opacity', '0', 'important');
        el.style.setProperty('pointer-events', 'none', 'important');
      }
    } catch (e) {}
  }

  function otlobliTemuExitSearchMode() {
    if (!IS_TEMU) return false;
    var searchInputForExit = otlobliTemuSearchInputForExit();
    var si = searchInputForExit;
    var siValue = si && typeof si.value === 'string' ? si.value : (si ? (si.textContent || '') : '');
    if (si && (document.activeElement === si || siValue)) {
      __otlobliTemuSearchModeCacheTs = Date.now();
      __otlobliTemuSearchModeCacheHref = location.href || '';
      __otlobliTemuSearchModeCacheValue = false;
      otlobliScheduleTemuHomeAfterSearchExit(si, false);
      return true;
    }
    if (/search/i.test(location.pathname + location.search + location.hash) && history.length > 1) {
      try {
        history.back();
        otlobliScheduleTemuHomeAfterSearchExit(searchInputForExit, false);
        return true;
      } catch (e) {}
    }
    if (document.activeElement && document.activeElement.blur) {
      try { document.activeElement.blur(); } catch (e3) {}
      __otlobliTemuSearchModeCacheTs = Date.now();
      __otlobliTemuSearchModeCacheHref = location.href || '';
      __otlobliTemuSearchModeCacheValue = false;
      otlobliScheduleTemuHomeAfterSearchExit(si, false);
      return true;
    }
    return false;
  }

  var __otlobliSearchMsgShown = false;
  function detectEmptyTemuSearch() {
    if (__otlobliSearchMsgShown) return;
    if (!/search/i.test(location.href) && !/search/i.test(location.pathname)) return;
    if (looksLikeProductPage()) return;
    if (document.readyState !== 'complete') return;
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
        document.addEventListener('gesturestart', function (e) { e.preventDefault(); }, { passive: false });
        document.addEventListener('gesturechange', function (e) { e.preventDefault(); }, { passive: false });
      }
    } catch (e) {}
  }

  var OTLOBLI_TEMU_HIDE_CSS =
    '[aria-label*="cart" i], [aria-label*="basket" i], [aria-label*="bag" i],' +
    '[aria-label*="account" i], [aria-label*="profile" i],' +
    '[aria-label*="سلة"], [aria-label*="عربة"], [aria-label*="حساب"],' +
    '[class*="downloadUI" i]' +
    '{ display: none !important; visibility: hidden !important; pointer-events: none !important; }' +
    '[class*="downloadsWrapper"]' +
    '{ padding: 0 !important; margin: 0 !important; min-height: 0 !important; box-shadow: none !important;' +
    ' background: transparent !important; border: 0 !important; border-radius: 0 !important; }' +
    '[data-otlobli-temu-search-shell="1"]' +
    '{ background: transparent !important; box-shadow: none !important; opacity: 1 !important;' +
    ' visibility: visible !important; pointer-events: auto !important; }' +
    'body:not([data-otlobli-temu-search-mode="1"]) [data-otlobli-temu-category-strip="1"]' +
    '{ display: flex !important; align-items: center !important; overflow-x: auto !important;' +
    ' -webkit-overflow-scrolling: touch !important; visibility: visible !important;' +
    ' opacity: 1 !important; pointer-events: auto !important; }' +
    'body:not([data-otlobli-temu-account-route="1"]) [class*="panel-"][class*="adaptPad"],' +
    'body:not([data-otlobli-temu-account-route="1"]) [class*="signInWrap-"],' +
    'body:not([data-otlobli-temu-account-route="1"]) [class*="signInBtn-"],' +
    'body:not([data-otlobli-temu-account-route="1"]) [class*="topItems-"],' +
    'body:not([data-otlobli-temu-account-route="1"]) [class*="bottomContent-"],' +
    'body:not([data-otlobli-temu-account-route="1"]) [class*="container-3zpvw"],' +
    'body:not([data-otlobli-temu-account-route="1"]) [class*="wrap-6ZxH0"],' +
    'body:not([data-otlobli-temu-account-route="1"]) [class*="guideText-"],' +
    'body:not([data-otlobli-temu-account-route="1"]) [class*="guideButton-"]' +
    '{ display: none !important; visibility: hidden !important; opacity: 0 !important; pointer-events: none !important; }';

  OTLOBLI_TEMU_HIDE_CSS =
    '[data-otlobli-temu-clean-hidden="1"],' +
    '[aria-label*="cart" i], [aria-label*="basket" i], [aria-label*="shopping bag" i],' +
    '[aria-label*="account" i], [aria-label*="profile" i], [aria-label*="sign in" i],' +
    'a[href*="cart" i], a[href*="login" i], a[href*="signin" i], a[href*="account" i],' +
    '[class*="downloadUI" i], [class*="openApp" i]' +
    '{ display: none !important; visibility: hidden !important; opacity: 0 !important; pointer-events: none !important; }';
  function injectTemuHeaderHideCSS() {
    if (!IS_TEMU) return;
    if (window.__otlobliTemuHideOff) {
      var stOff = document.getElementById('otlobli-temu-header-hide');
      if (stOff && stOff.parentNode) stOff.parentNode.removeChild(stOff);
      return;
    }
    try { otlobliSyncTemuAccountRouteState(); } catch (e) {}
    if (document.getElementById('otlobli-temu-header-hide')) return;
    var parent = document.head || document.documentElement;
    if (!parent) return;
    var style = document.createElement('style');
    style.id = 'otlobli-temu-header-hide';
    style.textContent = OTLOBLI_TEMU_HIDE_CSS;
    parent.appendChild(style);
  }
  try { injectTemuHeaderHideCSS(); } catch (e) {}

  function otlobliTemuRestoreCleanHidden() {
    if (!IS_TEMU || !document.body) return;
    try {
      var hidden = document.querySelectorAll('[data-otlobli-temu-clean-hidden="1"]');
      for (var i = 0; i < hidden.length; i++) {
        var el = hidden[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (!temuContainsPrice(el) && !temuLooksLikeProductContent(el)) continue;
        el.setAttribute('data-otlobli-temu-keep', '1');
        el.removeAttribute('data-otlobli-temu-clean-hidden');
        el.style.removeProperty('display');
        el.style.removeProperty('visibility');
        el.style.removeProperty('opacity');
        el.style.removeProperty('pointer-events');
      }
    } catch (e) {}
  }

  function otlobliTemuBlankPageRescue() {
    if (!IS_TEMU || !document.body) return;
    try {
      if (!looksLikeProductPage()) return;
      if (otlobliTemuSearchMode()) return;
      var vp = viewportSize();
      var imgs = document.querySelectorAll('img');
      var visibleProductImg = false, domProductImg = false;
      for (var i = 0; i < imgs.length; i++) {
        var src = imgs[i].currentSrc || imgs[i].src || '';
        if (!/kwcdn|temu/i.test(src)) continue;
        domProductImg = true;
        var r = imgs[i].getBoundingClientRect();
        if (r.width >= 110 && r.height >= 110 && r.bottom > 70 && r.top < vp.height - 60) {
          visibleProductImg = true; break;
        }
      }
      if (visibleProductImg) return; // الصفحة ليست فارغة — لا تدخّل
      var domHasContent = domProductImg || !!document.querySelector('[class*="curPrice" i], [class*="goods" i]');
      if (!domHasContent) return; // لا محتوى في DOM بعد — ربما تُحمّل، لا نتدخّل
      var hidden = document.querySelectorAll(
        '[data-otlobli-temu-clean-hidden="1"],[data-otlobli-temu-hidden="1"],[data-otlobli-temu-search-chrome-hidden="1"]'
      );
      for (var h = 0; h < hidden.length; h++) {
        var el = hidden[h];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (el.closest && (el.closest('#otlobli-nav') || el.closest('#otlobli-back-btn') || el.closest('#otlobli-add-btn'))) continue;
        el.setAttribute('data-otlobli-temu-keep', '1');
        el.removeAttribute('data-otlobli-temu-clean-hidden');
        el.removeAttribute('data-otlobli-temu-hidden');
        el.removeAttribute('data-otlobli-temu-search-chrome-hidden');
        el.style.removeProperty('display');
        el.style.removeProperty('visibility');
        el.style.removeProperty('opacity');
        el.style.removeProperty('pointer-events');
      }
    } catch (e) {}
  }

  function otlobliTemuProductVitals() {
    var vp = viewportSize();
    var imgs = document.querySelectorAll('img');
    var domImg = 0, visImg = 0;
    for (var i = 0; i < imgs.length; i++) {
      var s = imgs[i].currentSrc || imgs[i].src || '';
      if (!/kwcdn|temu/i.test(s)) continue;
      domImg++;
      var r = imgs[i].getBoundingClientRect();
      if (r.width >= 110 && r.height >= 110 && r.bottom > 70 && r.top < vp.height - 60) visImg++;
    }
    var hasPrice = false;
    try { hasPrice = !!document.querySelector('[class*="curPrice" i]'); } catch (e) {}
    var domHasContent = domImg > 0 || hasPrice;
    var state = visImg > 0 ? 'سليمة' : (domHasContent ? 'محتوى مخفي' : 'DOM فارغ');
    return { domImg: domImg, visImg: visImg, hasPrice: hasPrice, domHasContent: domHasContent, state: state };
  }

  function otlobliTemuVisibleAccountSurfaceOpen() {
    try {
      var nodes = document.querySelectorAll(
        '[data-otlobli-temu-account-surface="1"],[role="dialog"],[aria-modal="true"],' +
        '[class*="panel-"][class*="adaptPad"],[class*="signInWrap-"],[class*="signInBtn-"],' +
        '[class*="topItems-"],[class*="bottomContent-"],[class*="container-3zpvw"],[class*="wrap-6ZxH0"]'
      );
      var vp = viewportSize();
      for (var i = 0; i < nodes.length && i < 40; i++) {
        var el = nodes[i];
        if (!sheinElementIsVisible(el)) continue;
        var r = el.getBoundingClientRect();
        if (r.width < Math.min(260, vp.width * 0.55) || r.height < 70) continue;
        if (r.bottom <= 80 || r.top >= vp.height - 120) continue;
        var txt = (el.textContent || '').replace(/\s+/g, ' ').trim();
        if (otlobliTemuAccountPanelScore(txt) >= 2) return true;
      }
    } catch (e) {}
    return false;
  }

  function otlobliTemuHasVisibleProductContent(v) {
    try {
      if (v && v.visImg > 0) return true;
      var selectors = [
        '[class*="curPrice" i]',
        '[class*="salePrice" i]',
        '[class*="price" i]'
      ];
      var vp = viewportSize();
      for (var i = 0; i < selectors.length; i++) {
        var nodes = document.querySelectorAll(selectors[i]);
        for (var j = 0; j < nodes.length; j++) {
          var el = nodes[j];
          if (!sheinElementIsVisible(el)) continue;
          var r = el.getBoundingClientRect();
          if (r.bottom <= 56 || r.top >= vp.height - 70) continue;
          var txt = (el.textContent || '').replace(/\s+/g, ' ').trim();
          if (/\d/.test(txt)) return true;
        }
      }
    } catch (e) {}
    return false;
  }

  function otlobliTemuLoginSheetVisible() {
    try {
      var vp = viewportSize();
      var signInRe = /sign\s*in|log\s*in|continue\s*with|تسجيل\s*الدخول|سجّ?ل\s*الدخول|تابع\s*عبر|المتابعة\s*عبر/i;
      var socialRe = /google|facebook|apple|whatsapp|continue\s*with|المتابعة\s*عبر|تابع\s*عبر/i;
      var nodes = document.querySelectorAll('[role="dialog"],[aria-modal="true"],div,section,form');
      for (var i = 0; i < nodes.length && i < 400; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (!sheinElementIsVisible(el)) continue;
        var r = el.getBoundingClientRect();
        if (r.width < Math.min(260, vp.width * 0.55) || r.height < 120) continue;
        if (r.bottom <= 90 || r.top >= vp.height - 120) continue;
        var txt = (el.textContent || '').replace(/\s+/g, ' ').trim();
        if (txt.length > 900) continue;
        if (!signInRe.test(txt)) continue;
        var hasControl = !!el.querySelector(
          'input[type="tel"],input[type="password"],input[type="email"],' +
          'input[autocomplete*="tel"],input[name*="phone" i]'
        );
        if (hasControl || socialRe.test(txt)) return true;
      }
    } catch (e) {}
    return false;
  }

  var __otlobliTemuProductVisibleKey = '';
  var __otlobliTemuProductVisibleTs = 0;
  var __otlobliTemuConfirmedProductIdentity = '';
  var __otlobliTemuVisibleSinceKey = '';
  var __otlobliTemuVisibleSince = 0;
  var OTLOBLI_TEMU_STABLE_MS = 900;
  function otlobliPostTemuProductVisibleIfReady() {
    if (!IS_TEMU || !document.body) return;
    try {
      var now = Date.now();
      var key = temuGoodsId() + '|' + (location.href || '').split('#')[0];
      if (!looksLikeProductPage() || otlobliTemuSearchMode() ||
          otlobliTemuVisibleAccountSurfaceOpen() || otlobliTemuLoginSheetVisible()) {
        __otlobliTemuVisibleSince = 0; __otlobliTemuVisibleSinceKey = '';
        return;
      }
      var v = otlobliTemuProductVitals();
      if (!otlobliTemuHasVisibleProductContent(v)) {
        __otlobliTemuVisibleSince = 0; __otlobliTemuVisibleSinceKey = '';
        return;
      }
      if (__otlobliTemuVisibleSinceKey !== key) {
        __otlobliTemuVisibleSinceKey = key;
        __otlobliTemuVisibleSince = now;
        return;
      }
      if (now - __otlobliTemuVisibleSince < OTLOBLI_TEMU_STABLE_MS) return;
      if (__otlobliTemuProductVisibleKey === key && now - __otlobliTemuProductVisibleTs < 1400) return;
      __otlobliTemuProductVisibleKey = key;
      __otlobliTemuProductVisibleTs = now;
      __otlobliTemuConfirmedProductIdentity = temuGoodsId() || location.pathname;
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: 'temuProductVisible', url: location.href, key: key } });
      }
    } catch (e) {}
  }

  function otlobliTemuLooksLikeLargeProductFlowContainer(el, rect, style, vp) {
    try {
      if (!looksLikeProductPage() || !el || !rect || !style || !vp) return false;
      if (style.position === 'fixed' || style.position === 'absolute' || style.position === 'sticky') return false;
      if (rect.width < vp.width * 0.72) return false;
      if (rect.height < Math.min(vp.height * 0.35, 260)) return false;
      if (rect.top > Math.min(280, vp.height * 0.42)) return false;
      if (el.closest && el.closest('#otlobli-nav,#otlobli-back-btn,#otlobli-add-btn')) return false;
      return true;
    } catch (e) {}
    return false;
  }

  function otlobliTemuContentAnchor() {
    var imgs = document.querySelectorAll('img');
    for (var i = 0; i < imgs.length; i++) {
      var s = imgs[i].currentSrc || imgs[i].src || '';
      if (/kwcdn|temu/i.test(s)) return imgs[i];
    }
    try { return document.querySelector('[class*="curPrice" i]'); } catch (e) { return null; }
  }

  function otlobliTemuHiddenAncestorInfo() {
    var node = otlobliTemuContentAnchor();
    if (!node) return 'لا مرساة';
    var depth = 0;
    while (node && node !== document.body && node !== document.documentElement && depth < 45) {
      try {
        var cs = window.getComputedStyle(node);
        var r = node.getBoundingClientRect();
        var why = '';
        if (cs.display === 'none') why = 'display:none';
        else if (cs.visibility === 'hidden') why = 'visibility';
        else if (parseFloat(cs.opacity || '1') < 0.05) why = 'opacity0';
        else if (r.height <= 2 || r.width <= 2) why = 'حجم' + Math.round(r.width) + 'x' + Math.round(r.height);
        if (why) {
          var cls = (((node.className || '') + '') || node.id || '').replace(/\s+/g, '.').slice(0, 46);
          return (node.tagName || '?') + '.' + cls + ' ' + why;
        }
      } catch (e) {}
      node = node.parentElement; depth++;
    }
    return 'لا سلف مخفي';
  }

  function otlobliTemuForceProductVisible() {
    if (!IS_TEMU || !document.body) return;
    try {
      if (!looksLikeProductPage() || otlobliTemuSearchMode()) return;
      var v = otlobliTemuProductVitals();
      if (v.visImg > 0 || !v.domHasContent) return; // سليمة أو DOM فارغ — لا نتدخّل
      var node = otlobliTemuContentAnchor();
      if (!node) return;
      var depth = 0;
      while (node && node !== document.documentElement && depth < 45) {
        if (!(node.id && node.id.indexOf('otlobli') === 0)) {
          try {
            var cs = window.getComputedStyle(node);
            if (cs.display === 'none') { node.style.setProperty('display', 'block', 'important'); node.setAttribute('data-otlobli-temu-keep', '1'); }
            if (cs.visibility === 'hidden') { node.style.setProperty('visibility', 'visible', 'important'); }
            if (parseFloat(cs.opacity || '1') < 0.05) { node.style.setProperty('opacity', '1', 'important'); }
            var r = node.getBoundingClientRect();
            if (r.height <= 2) node.style.setProperty('min-height', 'auto', 'important');
          } catch (e) {}
        }
        node = node.parentElement; depth++;
      }
    } catch (e) {}
  }
  function otlobliTemuUndoForcedVisible() {
    try {
      var forced = document.querySelectorAll('[data-otlobli-forced-vis]');
      for (var i = 0; i < forced.length; i++) {
        var el = forced[i];
        var props = (el.getAttribute('data-otlobli-forced-vis') || '').split(',');
        for (var p = 0; p < props.length; p++) { if (props[p]) el.style.removeProperty(props[p]); }
        el.removeAttribute('data-otlobli-forced-vis');
      }
    } catch (e) {}
  }

  function otlobliTemuUnhideAllForTest() {
    try {
      var st = document.getElementById('otlobli-temu-header-hide');
      if (st && st.parentNode) st.parentNode.removeChild(st);
      var hidden = document.querySelectorAll('[data-otlobli-temu-clean-hidden="1"],[data-otlobli-temu-hidden="1"],[data-otlobli-temu-search-chrome-hidden="1"]');
      for (var i = 0; i < hidden.length; i++) {
        var el = hidden[i];
        el.removeAttribute('data-otlobli-temu-clean-hidden');
        el.removeAttribute('data-otlobli-temu-hidden');
        el.removeAttribute('data-otlobli-temu-search-chrome-hidden');
        el.style.removeProperty('display');
        el.style.removeProperty('visibility');
        el.style.removeProperty('opacity');
        el.style.removeProperty('pointer-events');
      }
    } catch (e) {}
  }

  function otlobliTemuDumpProductDom() {
    var root = document.body.cloneNode(true);
    var kill = root.querySelectorAll('script,style,noscript,link,meta,svg,path,canvas,iframe,[id^="otlobli"]');
    for (var i = 0; i < kill.length; i++) { if (kill[i].parentNode) kill[i].parentNode.removeChild(kill[i]); }
    var withAttrs = root.querySelectorAll('*');
    for (var a = 0; a < withAttrs.length; a++) {
      var el = withAttrs[a];
      var at = el.attributes;
      for (var k = at.length - 1; k >= 0; k--) {
        var nm = at[k].name, vl = at[k].value;
        if (nm === 'src' || nm === 'srcset' || nm === 'style' || nm === 'href') {
          el.setAttribute(nm, vl.slice(0, 40));
        } else if (vl.length > 60 && !/aria|role|data-|class/i.test(nm)) {
          el.removeAttribute(nm);
        }
      }
    }
    var html = root.innerHTML.replace(/>\s+</g, '><').replace(/\s{2,}/g, ' ');
    if (html.length > 120000) html = html.slice(0, 120000);
    var payload = 'URL: ' + location.href.split('?')[0] + '\n' +
      'العنوان: ' + (document.title || '').slice(0, 80) + '\n\n' + html;
    try { if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(payload); } catch (e) {}
    try {
      var ta = document.createElement('textarea');
      ta.value = payload; ta.style.cssText = 'position:fixed;left:-9999px;top:0;';
      document.body.appendChild(ta); ta.select();
      try { document.execCommand('copy'); } catch (e2) {}
      document.body.removeChild(ta);
    } catch (e3) {}
    return payload;
  }

  function otlobliTemuBlankProductNotice() {
    if (!IS_TEMU || !document.body) return;
    var notice = document.getElementById('otlobli-temu-product-loading');
    var show = false;
    try {
      var identity = temuGoodsId() || location.pathname;
      var v = otlobliTemuProductVitals();
      show = looksLikeProductPage() && !otlobliTemuSearchMode() &&
        __otlobliTemuConfirmedProductIdentity !== identity && !v.domHasContent;
    } catch (e) {}
    if (!show) {
      if (notice) notice.remove();
      return;
    }
    if (notice) return;
    ensureOverlayStyle();
    var vp = viewportSize();
    notice = document.createElement('div');
    notice.id = 'otlobli-temu-product-loading';
    notice.setAttribute('role', 'status');
    notice.setAttribute('aria-live', 'polite');
    notice.style.cssText = 'position:fixed;left:0;top:0;width:' + vp.width + 'px;height:' + vp.height + 'px;' +
      'z-index:2147483646;background:#fff;display:flex;align-items:center;justify-content:center;' +
      'box-sizing:border-box;padding:24px 24px 150px;direction:rtl;font-family:Cairo,system-ui,sans-serif;';
    notice.innerHTML = '<div style="display:flex;max-width:290px;flex-direction:column;align-items:center;text-align:center;color:#123d30">' +
      '<span style="width:34px;height:34px;border:4px solid #d8efe4;border-top-color:#007a52;border-radius:50%;animation:otlobli-spin .8s linear infinite"></span>' +
      '<strong style="margin-top:16px;font-size:17px;line-height:1.5">جاري فتح المنتج…</strong>' +
      '<span style="margin-top:5px;color:#65736e;font-size:13px;line-height:1.65">نحاول فتحه كضيف داخل تيمو السعودية</span>' +
      '</div>';
    notice.addEventListener('touchmove', function (event) { event.preventDefault(); }, { passive: false });
    document.body.appendChild(notice);
  }

  var __otlobliTemuBlankUrl = '';
  var __otlobliTemuBlankSince = 0;
  function otlobliTemuBlankPageAutoReload() {
    if (!IS_TEMU || !document.body) return;
    try {
      if (!looksLikeProductPage() || otlobliTemuSearchMode()) { __otlobliTemuBlankSince = 0; return; }
      var v = otlobliTemuProductVitals();
      var identity = temuGoodsId() || (location.pathname + location.search).slice(0, 180);
      var retryKey = '__otlobliTemuBlankReload:' + identity;
      if (__otlobliTemuConfirmedProductIdentity === identity ||
          v.visImg > 0 || otlobliTemuHasVisibleProductContent(v)) {
        __otlobliTemuBlankSince = 0;
        try { sessionStorage.removeItem(retryKey); } catch (e) {}
        return;
      }
      if (v.domHasContent) return;                                 // محجوب — للـwatchdog لا لإعادة التحميل
      var url = location.href, now = Date.now();
      var retryState = '';
      try { retryState = sessionStorage.getItem(retryKey) || ''; } catch (e) {}
      if (retryState === 'blocked') return;
      if (__otlobliTemuBlankUrl !== url) { __otlobliTemuBlankUrl = url; __otlobliTemuBlankSince = now; return; }
      if (!__otlobliTemuBlankSince) { __otlobliTemuBlankSince = now; return; }
      if (now - __otlobliTemuBlankSince < 3500) return;
      if (retryState === 'retry') {
        try { sessionStorage.setItem(retryKey, 'blocked'); } catch (e) {}
        return;
      }
      try { sessionStorage.setItem(retryKey, 'retry'); } catch (e) {}
      location.reload();
    } catch (e) {}
  }

  var __otlobliTemuCoverUrl = '';
  function otlobliTemuEntryCover() {
    if (window.__otlobliTemuHideOff) return; // وضع اختبار: الحجب مطفأ
    if (!looksLikeProductPage() || otlobliTemuSearchMode()) return;
    var url = (location.href || '').split('#')[0];
    if (__otlobliTemuCoverUrl === url) return;
    __otlobliTemuCoverUrl = url;
    try { otlobliCleanTemuBlockers(true); } catch (e) {}
    setTimeout(function () { try { otlobliCleanTemuBlockers(true); } catch (e) {} }, 260);
    setTimeout(function () { try { otlobliCleanTemuBlockers(true); } catch (e) {} }, 620);
  }

  if (IS_TEMU && !window.__otlobliTemuScrollRehideBound) {
    window.__otlobliTemuScrollRehideBound = true;
    var __otlobliTemuScrollHideTs = 0;
    window.addEventListener('scroll', function () {
      var n = Date.now();
      if (n - __otlobliTemuScrollHideTs < 350) return;
      __otlobliTemuScrollHideTs = n;
      setTimeout(function () { try { otlobliCleanTemuBlockers(true); } catch (e) {} }, 120);
    }, { passive: true, capture: true });
  }

  var __otlobliTemuCleanBlockersTs = 0;
  function otlobliCleanTemuBlockers(force) {
    if (!IS_TEMU || !document.body) return;
    if (otlobliTemuAccountRoute()) {
      var authNodes = document.querySelectorAll('[data-otlobli-temu-clean-hidden="1"]');
      for (var ai = 0; ai < authNodes.length; ai++) {
        var authNode = authNodes[ai];
        authNode.style.removeProperty('display');
        authNode.style.removeProperty('visibility');
        authNode.style.removeProperty('opacity');
        authNode.style.removeProperty('pointer-events');
        authNode.removeAttribute('data-otlobli-temu-clean-hidden');
      }
      return;
    }
    if (window.__otlobliTemuHideOff) return; // وضع اختبار: الحجب مطفأ
    var now = Date.now();
    if (!force && now - __otlobliTemuCleanBlockersTs < (OTLOBLI_LOW_END ? 1800 : 1100)) return;
    __otlobliTemuCleanBlockersTs = now;
    try {
      if (otlobliTemuSearchMode()) return;
      var vp = viewportSize();
      var accountCartRe = /cart|basket|shopping\s*bag|bag|account|profile|sign\s*in|signin|login|log\s*in|سلة|عربة|حساب|دخول|تسجيل/i;
      var appRe = /download\s*(the\s*)?app|open\s*app|get\s*app|install\s*app|app\s*download|تطبيق|تنزيل|حمل|التطبيق/i;
      var promoRe = /coupon|voucher|offer|deal|promo|promotion|reward|spin|free\s*gift|claim|flash\s*sale|قسيم|كوبون|عرض|عروض|خصم|هدية|جائزة|اربح|شحن\s*مجان/i;

      function hideCleanNode(el) {
        el.setAttribute('data-otlobli-temu-clean-hidden', '1');
        el.style.setProperty('display', 'none', 'important');
        el.style.setProperty('visibility', 'hidden', 'important');
        el.style.setProperty('opacity', '0', 'important');
        el.style.setProperty('pointer-events', 'none', 'important');
      }

      function protectedTemuContent(el, text, target) {
        if (!el || (el.id && el.id.indexOf('otlobli') === 0)) return true;
        if (temuProductOptionDialog(el)) return true;
        if (el.getAttribute && el.getAttribute('data-otlobli-temu-keep') === '1') return true;
        if (el.closest && (el.closest('#otlobli-nav') || el.closest('#otlobli-back-btn') || el.closest('#otlobli-add-btn'))) return true;
        if (el.querySelector && el.querySelector('input[type="search"], [role="searchbox"], input[placeholder*="Search"]')) return true;
        var blockerTarget = !!(target && (target.accountCart || target.appInstall || target.promo));
        var protectRect = el.getBoundingClientRect ? el.getBoundingClientRect() : null;
        var protectStyle = protectRect ? window.getComputedStyle(el) : null;
        if (otlobliLooksLikeSearchTrigger(el)) return true;
        var nearSearchBand = !blockerTarget && protectRect &&
          protectRect.top <= Math.min(260, vp.height * 0.45) && protectRect.bottom >= -8;
        if (nearSearchBand && otlobliNearSearchInput(el)) return true;
        var protectFixed = protectStyle &&
          (protectStyle.position === 'fixed' || protectStyle.position === 'absolute' || protectStyle.position === 'sticky');
        if (otlobliTemuLooksLikeLargeProductFlowContainer(el, protectRect, protectStyle, vp)) return true;
        var floatingBlocker = blockerTarget && protectRect && protectFixed &&
          protectRect.width >= vp.width * 0.42 && protectRect.height >= 28 &&
          (protectRect.top <= 320 || protectRect.bottom >= vp.height - 180);
        if (floatingBlocker) {
          if (temuContainsPrice(el)) return true;
          if (el.querySelectorAll && el.querySelectorAll('img').length >= 3 && text.length > 40) return true;
          return false;
        }
        if (otlobliTemuLooksLikeCategoryOrFilter(el)) {
          return true;
        }
        if (temuContainsPrice(el)) return true;
        if (el.querySelectorAll && el.querySelectorAll('img').length >= 3 && text.length > 40) return true;
        return false;
      }

      var nodes = document.querySelectorAll(
        '[data-otlobli-temu-clean-hidden="1"],' +
        'a,button,[role="button"],div,section,aside,nav,header'
      );
      var hidden = 0;
      for (var i = 0; i < nodes.length && hidden < 30; i++) {
        var el = nodes[i];
        if (!el || !el.getBoundingClientRect) continue;
        var r = el.getBoundingClientRect();
        if (r.width <= 0 || r.height <= 0 || r.bottom < -4 || r.top > vp.height + 4) continue;
        var text = temuCleanText(el.textContent);
        if (text.length > 1600) continue;
        var hints = (otlobliCollectIdentityHints(el) + ' ' + text).slice(0, 2200);
        var accountCart = accountCartRe.test(hints);
        var appInstall = appRe.test(hints);
        var promo = promoRe.test(hints);
        if (promo && looksLikeProductPage() && !accountCart && !appInstall) {
          promo = /coupon|voucher|spin|free\s*gift|lucky\s*draw|claim|reward|قسيمة|كوبون|عجلة\s*الحظ|اربح|هدية\s*مجان|جائزة|الملياردير/i.test(hints);
        }
        if (!accountCart && !appInstall && !promo && el.getAttribute('data-otlobli-temu-clean-hidden') !== '1') continue;
        if (protectedTemuContent(el, text, { accountCart: accountCart, appInstall: appInstall, promo: promo })) continue;
        var cs = window.getComputedStyle(el);

        var fixedish = cs.position === 'fixed' || cs.position === 'absolute' || cs.position === 'sticky';
        var compactHeader = r.top <= 260 && r.width >= 14 && r.height >= 14 && r.width <= 170 && r.height <= 96;
        var sheetLike = fixedish && r.width >= vp.width * 0.42 && r.height >= 28 &&
          (r.top <= 320 || r.bottom >= vp.height - 180);
        var bannerLike = r.width >= vp.width * 0.55 && r.height >= 24 && r.height <= 190 &&
          (r.top <= 220 || r.bottom >= vp.height - 190);
        var topFlowAccount = !looksLikeProductPage() && r.top <= 340;

        if ((accountCart && (compactHeader || sheetLike || fixedish || topFlowAccount)) ||
            (appInstall && (compactHeader || sheetLike || bannerLike)) ||
            (promo && (sheetLike || bannerLike))) {
          hideCleanNode(el);
          hidden++;
        }
      }
    } catch (e) {}
  }

  function hideTemuSearchVisibleAccountCart(searchMode) {
    if (!IS_TEMU || !document.body) return;
    if (window.__otlobliTemuHideOff) return; // وضع اختبار: الحجب مطفأ
    try {
      var active = typeof searchMode === 'boolean' ? searchMode : otlobliTemuSearchMode();
      if (!active && !/search/i.test(location.pathname + location.search + location.hash)) return;
      var vp = viewportSize();
      var input = otlobliTemuSearchInputForExit() || otlobliTemuSearchInput();
      var inputRect = input && input.getBoundingClientRect ? input.getBoundingClientRect() : null;
      var searchTop = inputRect && inputRect.height > 0 ? inputRect.top : 230;
      var nodes = document.querySelectorAll('a,button,[role="button"],div,span,i');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (!el || !el.getBoundingClientRect) continue;
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (el.closest && (el.closest('#otlobli-nav') || el.closest('#otlobli-back-btn') || el.closest('#otlobli-add-btn'))) continue;
        if (el.querySelector && el.querySelector('input,textarea,[role="searchbox"]')) continue;
        if (otlobliLooksLikeSearchTrigger(el) || otlobliLooksLikeTemuLogo(el)) continue;
        var r = el.getBoundingClientRect();
        if (r.width <= 0 || r.height <= 0) continue;
        var txt = temuCleanText(el.textContent);
        var hints = otlobliCollectIdentityHints(el) + ' ' + txt;
        var topIconOnly = r.top >= 0 && r.bottom <= searchTop - 4 &&
          r.left >= -4 && r.left <= Math.max(180, vp.width * 0.46) &&
          r.width >= 18 && r.width <= 72 && r.height >= 18 && r.height <= 72 &&
          txt.length <= 3;
        var semanticCartAccount = /(cart|basket|shopping\s*bag|account|profile|sign\s*in|login|سلة|عربة|حساب|دخول|تسجيل)/i.test(hints);
        var tag = (el.tagName || '').toLowerCase();
        var role = (el.getAttribute && (el.getAttribute('role') || '').toLowerCase()) || '';
        var interactive = tag === 'a' || tag === 'button' || role === 'button';
        var compactSemantic = semanticCartAccount && interactive &&
          r.width >= 18 && r.width <= 90 && r.height >= 18 && r.height <= 90 &&
          txt.length <= 32 && !temuContainsPrice(el);
        if (topIconOnly || compactSemantic) {
          el.setAttribute('data-otlobli-temu-search-chrome-hidden', '1');
          el.style.setProperty('visibility', 'hidden', 'important');
          el.style.setProperty('opacity', '0', 'important');
          el.style.setProperty('pointer-events', 'none', 'important');
        }
      }

      var bars = document.querySelectorAll('nav,footer,div,[role="navigation"],[role="tablist"]');
      for (var b = 0; b < bars.length; b++) {
        var bar = bars[b];
        if (!bar || !bar.getBoundingClientRect) continue;
        if (bar.id && bar.id.indexOf('otlobli') === 0) continue;
        if (bar.closest && bar.closest('#otlobli-nav')) continue;
        var br = bar.getBoundingClientRect();
        if (br.width < vp.width * 0.55 || br.height < 34 || br.height > 180 || br.top < vp.height - 210) {
          continue;
        }
        var cs = window.getComputedStyle(bar);
        if (cs.position !== 'fixed' && cs.position !== 'sticky' && cs.position !== 'absolute') continue;
        var barText = temuCleanText(bar.textContent);
        if (barText.length > 120) continue;
        var navLikeChildren = bar.children && bar.children.length >= 3 && bar.children.length <= 5;
        if (!/(account|profile|cart|basket|orders?|home|حسابي|السلة|طلباتي|الرئيسية)/i.test(barText) &&
            !(navLikeChildren && br.height >= 48 && br.height <= 120)) continue;
        bar.setAttribute('data-otlobli-temu-search-chrome-hidden', '1');
        bar.style.setProperty('display', 'none', 'important');
        bar.style.setProperty('visibility', 'hidden', 'important');
        bar.style.setProperty('opacity', '0', 'important');
        bar.style.setProperty('pointer-events', 'none', 'important');
      }
    } catch (e) {}
  }

  function hideTemuHeaderIconsByProbe() {
    if (!IS_TEMU || !document.body) return;
    try {
      var all = document.querySelectorAll('a, button, div, span, i, [role="button"]');
      for (var i = 0; i < all.length; i++) {
        var el = all[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (otlobliTemuLooksLikeCategoryOrFilter(el)) continue;
        if (el.closest && el.closest('[data-otlobli-temu-search-shell="1"]')) continue;
        if (el.getAttribute && el.getAttribute('data-otlobli-temu-hidden') === '1') continue;
        var r = el.getBoundingClientRect();
        if (r.width === 0 || r.height === 0) continue;
        if (r.top < 0 || r.top > 240) continue;
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

  var __otlobliTemuLoginProbeTs = 0;
  function dismissTemuLoginPopup() {
    if (!IS_TEMU || !document.body) return;
    var now = Date.now();
    var searchMode = otlobliTemuSearchMode();
    if (now - __otlobliTemuLoginProbeTs < (searchMode ? 420 : 900)) return; // لا نفحص كل tick
    __otlobliTemuLoginProbeTs = now;
    var LOGIN_RE = /سجّ?ل\s*الدخول|تسجيل\s*الدخول|sign\s*in|log\s*in|continue\s*with|تابع\s*عبر|أنشئ\s*حساب|create\s*account|تسجيل\s*الدخول|إنشاء\s*حساب|الرصيد\s*الائتماني|قسائم|طلباتك|سجل\s*التصفح|العناوين|دعم\s*العملاء/i;
    var CLOSE_RE = /^(?:×|✕|✖|x|close|إغلاق|اغلاق|تخطّ?ي|تخطي|skip|later|لاحقًا|لاحقا|ليس\s*الآن|not\s*now)$/i;
    var vp = viewportSize();
    var searchInputForPopup = searchMode ? otlobliTemuSearchInput() : null;
    var nodes = document.querySelectorAll('div, section, aside');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      var cs = window.getComputedStyle(el);
      var r = el.getBoundingClientRect();
      var handled = el.getAttribute && el.getAttribute('data-otlobli-login-handled') === '1';
      if (handled && (!searchMode || r.width <= 0 || r.height <= 0)) continue;
      if (cs.position !== 'fixed' && cs.position !== 'absolute') {
        if (!searchMode || r.top < 0 || r.top > vp.height * 0.62) continue;
      }
      if (r.width < vp.width * 0.55 || r.height < vp.height * (searchMode ? 0.22 : 0.35)) continue;
      var txt = (el.textContent || '');
      if (txt.length > (searchMode ? 1400 : 600) || (!LOGIN_RE.test(txt) && !otlobliTemuLooksLikeAccountPanelText(txt))) continue;
      if (searchMode && searchInputForPopup && el.contains && el.contains(searchInputForPopup)) continue;
      if (searchMode && el.querySelector && el.querySelector('input[type="search"], input[placeholder*="Search" i], input[placeholder*="بحث"], [role="searchbox"]')) continue;
      if (!searchMode && temuContainsPrice(el)) continue;
      el.setAttribute('data-otlobli-login-handled', '1');
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
      if (!clicked && cs.position === 'fixed' && r.top <= 2 && r.left <= 2 &&
          r.width >= vp.width - 4 && r.height >= vp.height - 4) {
        try { el.click(); } catch (e) {}
      }
      if (!clicked && searchMode) {
        el.setAttribute('data-otlobli-temu-search-login-hidden', '1');
        el.style.setProperty('display', 'none', 'important');
        el.style.setProperty('visibility', 'hidden', 'important');
        el.style.setProperty('pointer-events', 'none', 'important');
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
        if (otlobliTemuLooksLikeCategoryOrFilter(el)) continue;
        if (el.closest && el.closest('[data-otlobli-temu-search-shell="1"]')) continue;
        if (el.getAttribute && el.getAttribute('data-otlobli-temu-hidden') === '1') continue;
        if (el.querySelector && el.querySelector('input, textarea, select')) continue;
        if (temuContainsPrice(el)) continue;
        var txt = temuCleanText(el.textContent);
        var isDistraction = OTLOBLI_KNOWN_DISTRACTION.test(txt) || otlobliLooksLikeKnownDistraction(el);
        if (txt.length > 25 && !isDistraction) continue;
        var r = el.getBoundingClientRect();
        if (r.width < 22 || r.height < 22 || r.width > 72 || r.height > 72) continue;
        if (r.top < 0 || r.top > 240) continue;
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
        if (otlobliTemuLooksLikeCategoryOrFilter(el)) continue;
        if (temuContainsPrice(el)) continue;
        var txt = temuCleanText(el.textContent);
        if (!txt || txt.length > 160) continue;
        var r = el.getBoundingClientRect();
        if (r.width < vp.width * 0.45 || r.height <= 0 || r.height > 150) continue;
        var cs = window.getComputedStyle(el);
        var fixedish = cs.position === 'fixed' || cs.position === 'sticky' || cs.position === 'absolute';
        var topAppBanner = r.top >= 0 && r.top < 170 && /temu/i.test(txt) && /(حصل|تنزيل|تطبيق|get|download|app)/i.test(txt);
        var bottomLogin = r.bottom > vp.height - 170 && /(سجل الدخول|تسجيل الدخول|sign in|login|أفضل تجربة|best experience)/i.test(txt);
        var bottomStoreAction = r.bottom > vp.height - 190 && (/(cart|bag|deal|offer|add to|login|sign in)/i.test(txt) || /rgb\(255,\s*(?:102|118|128|136|145|153|165),\s*0\)/i.test(cs.backgroundColor || ''));
        if (!fixedish && !topAppBanner) continue;
        if (topAppBanner || bottomLogin || bottomStoreAction) {
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
    if (el.getAttribute && el.getAttribute('data-otlobli-temu-search-exit-hidden') === '1') return;
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
      if (/^\/(?:jo\/?)?\.?$/.test(href) || href === '/') {
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

  function otlobliTemuLooksLikeCategoryOrFilter(el) {
    if (!IS_TEMU || !el) return false;
    try {
      var txt = temuCleanText(el.textContent);
      if (!txt || txt.length > 90) return false;
      if (/(cart|basket|bag|account|login|profile|download|app|search|suggest|trending|recent searches|popular searches|سلة|عربة|حساب|تسجيل|تنزيل|تطبيق|بحث|اقتراح|رائج)/i.test(txt)) return false;
      var categoryWords = /(الكل|نساء|رجال|الرئيسية|مجوهرات|رياض|أطفال|اطفال|إلكترون|الكترون|أكياس|اكياس|صناعة|صناعي|منتجات|الجمال|المحافظة|الحرف|الصفقات|نجوم|الأكثر|الاكثر|كل|home|women|men|jewel|sport|kids|child|electron|bag|industrial|beauty|craft|deals|stars|popular|all)/i;
      if (!categoryWords.test(txt)) return false;
      var r = el.getBoundingClientRect ? el.getBoundingClientRect() : null;
      if (r && r.top > 340) return false;
      return true;
    } catch (e) {}
    return false;
  }

  function otlobliTemuLooksLikeAccountPanelText(text) {
    return /sign\s*in|log\s*in|create\s*account|orders?|coupons?|credit|settings|addresses?|support|best\s*experience|تسجيل\s*الدخول|سجل\s*الدخول|إنشاء\s*حساب|طلباتك|القسائم|العروض|الرصيد\s*الائتماني|الإعدادات|العناوين|دعم\s*العملاء|أفضل\s*تجربة/i.test(text || '');
  }

  function otlobliTemuAccountRoute() {
    var path = (location.pathname || '').toLowerCase();
    var hash = (location.hash || '').toLowerCase();
    var route = path + ' ' + hash;
    var tokens = route.split(/[^a-z0-9]+/i);
    for (var i = 0; i < tokens.length; i++) {
      if (/^(account|login|signin|sign|profile|user|member|order|orders|coupon|credit|address)$/i.test(tokens[i] || '')) return true;
    }
    if (/[#?&](?:page|scene|tab|route)=(?:account|login|profile|user|orders?|coupon|credit|address)\b/i.test(location.href || '')) return true;
    return false;
  }

  function otlobliSyncTemuAccountRouteState() {
    if (!document.body) return;
    if (otlobliTemuAccountRoute()) {
      document.body.setAttribute('data-otlobli-temu-account-route', '1');
    } else {
      document.body.removeAttribute('data-otlobli-temu-account-route');
    }
  }

  function otlobliTemuAccountPanelScore(text) {
    var t = text || '';
    var score = 0;
    if (/sign\s*in|log\s*in|تسجيل\s*الدخول|سجل\s*الدخول/i.test(t)) score++;
    if (/create\s*account|إنشاء\s*حساب/i.test(t)) score++;
    if (/orders?|طلباتك/i.test(t)) score++;
    if (/coupons?|القسائم|العروض/i.test(t)) score++;
    if (/credit|الرصيد\s*الائتماني/i.test(t)) score++;
    if (/settings|addresses?|support|الإعدادات|العناوين|دعم\s*العملاء/i.test(t)) score++;
    if (/best\s*experience|أفضل\s*تجربة/i.test(t)) score++;
    return score;
  }

  function hideTemuAccountSurfaces() {
    if (!IS_TEMU || !document.body || otlobliTemuAccountRoute()) return;
    try {
      otlobliSyncTemuAccountRouteState();
      var vp = viewportSize();
      var seen = [];
      var nodes = [];
      function addNode(node) {
        if (!node || !node.getBoundingClientRect) return;
        for (var s = 0; s < seen.length; s++) if (seen[s] === node) return;
        seen.push(node);
        nodes.push(node);
      }
      var exact = document.querySelectorAll(
        '[data-otlobli-temu-account-surface="1"],' +
        '[class*="panel-"][class*="adaptPad"],' +
        '[class*="signInWrap-"],[class*="signInBtn-"],' +
        '[class*="topItems-"],[class*="bottomContent-"],' +
        '[class*="container-3zpvw"],[class*="wrap-6ZxH0"],' +
        '[class*="guideText-"],[class*="guideButton-"]'
      );
      for (var e = 0; e < exact.length; e++) {
        var root = exact[e].closest ? exact[e].closest('[class*="panel-"][class*="adaptPad"],[class*="container-3zpvw"]') : null;
        addNode(root || exact[e]);
      }
      if (otlobliTemuSearchMode() && document.elementsFromPoint) {
        var xs = [vp.width * 0.2, vp.width * 0.5, vp.width * 0.8];
        var ys = [54, 96, 150, 220, Math.max(40, vp.height - 112)];
        for (var xi = 0; xi < xs.length; xi++) {
          for (var yi = 0; yi < ys.length; yi++) {
            var stack = document.elementsFromPoint(xs[xi], ys[yi]);
            for (var si = 0; si < stack.length && si < 10; si++) {
              var n = stack[si];
              for (var hops = 0; n && n !== document.body && hops < 4; hops++, n = n.parentElement) {
                var nt = temuCleanText(n.textContent);
                if (nt && nt.length < 1500 && otlobliTemuAccountPanelScore(nt) >= 2) addNode(n);
              }
            }
          }
        }
      }
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (el.closest && (el.closest('#otlobli-nav') || el.closest('#otlobli-back-btn'))) continue;
        var r = el.getBoundingClientRect();
        if (r.width < vp.width * 0.42 || r.height < 35 || r.height > vp.height * 0.82) continue;
        if (r.bottom < 0 || r.top > vp.height + 2) continue;
        var txt = temuCleanText(el.textContent);
        if (txt.length > 1500) continue;
        var score = otlobliTemuAccountPanelScore(txt);
        var cls = String(el.className || '');
        var exactClass = /panel-.*adaptPad|signInWrap-|signInBtn-|topItems-|bottomContent-|container-3zpvw|wrap-6ZxH0|guideText-|guideButton-/i.test(cls);
        if (score < 2 && !exactClass) continue;
        var cs = window.getComputedStyle(el);
        var fixedish = cs.position === 'fixed' || cs.position === 'absolute' || cs.position === 'sticky';
        if (otlobliTemuLooksLikeLargeProductFlowContainer(el, r, cs, vp)) continue;
        var bottomLogin = r.bottom > vp.height - 180 && score >= 2 &&
          (/best\s*experience|أفضل\s*تجربة|سجل\s*الدخول/i.test(txt) || fixedish);
        var dropdown = (score >= 3 || exactClass) && r.top < Math.min(340, vp.height * 0.58) && r.height >= 35;
        if (!bottomLogin && !dropdown) continue;
        if (el.querySelector && el.querySelector('[class*="searchBar" i], input[type="search"], [role="searchbox"]')) {
          continue;
        }
        if (looksLikeProductPage() && temuLooksLikeProductContent(el)) continue;
        if (!fixedish && !bottomLogin && r.top > 180) continue;
        el.setAttribute('data-otlobli-temu-account-surface', '1');
        el.setAttribute('data-otlobli-temu-hidden', '1');
        el.style.setProperty('display', 'none', 'important');
        el.style.setProperty('visibility', 'hidden', 'important');
        el.style.setProperty('opacity', '0', 'important');
        el.style.setProperty('pointer-events', 'none', 'important');
      }
    } catch (e) {}
  }

  function hideTemuDistractingSheets() {
    if (!IS_TEMU || !document.body) return;
    try {
      var vp = viewportSize();
      var onAccountRoute = otlobliTemuAccountRoute();
      var nodes = document.querySelectorAll('[data-otlobli-temu-distraction-sheet="1"], div, section, aside');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (el.closest && (el.closest('#otlobli-nav') || el.closest('#otlobli-back-btn'))) continue;
        if (el.querySelector && el.querySelector('input, textarea, [role="searchbox"], [class*="searchBar" i]')) continue;
        if (temuContainsPrice(el)) continue;
        var r = el.getBoundingClientRect();
        if (r.width < vp.width * 0.55 || r.height < 28 || r.height > vp.height * 0.92) continue;
        if (r.bottom < -4 || r.top > vp.height + 4) continue;
        var txt = temuCleanText(el.textContent);
        if (!txt || txt.length > 2200) continue;
        var looksSheet = /available\s+offers|service\s+guarantee|free\s+shipping|delivery\s+guarantee|العروض\s+المتوفرة|ضمان\s+الخدمة|الشحن\s+مجان|ضمان\s+التوصيل|لماذا\s+تختار\s+temu|مدفوعات\s+آمنة/i.test(txt);
        var accountScore = otlobliTemuAccountPanelScore(txt);
        var accountSheet = !onAccountRoute && accountScore >= 2;
        if (!looksSheet && !accountSheet) continue;
        var cs = window.getComputedStyle(el);
        var fixedish = cs.position === 'fixed' || cs.position === 'absolute' || cs.position === 'sticky';
        if (otlobliTemuLooksLikeLargeProductFlowContainer(el, r, cs, vp)) continue;
        var modalLike = fixedish || r.top < 260 || r.bottom > vp.height - 220;
        if (!modalLike) continue;
        el.setAttribute('data-otlobli-temu-distraction-sheet', '1');
        el.setAttribute('data-otlobli-temu-hidden', '1');
        el.style.setProperty('display', 'none', 'important');
        el.style.setProperty('visibility', 'hidden', 'important');
        el.style.setProperty('opacity', '0', 'important');
        el.style.setProperty('pointer-events', 'none', 'important');
      }
    } catch (e) {}
  }

  function restoreTemuSearchChrome() {
    if (!IS_TEMU || !document.body) return;
    try {
      var nodes = document.querySelectorAll('input, textarea, [contenteditable="true"], [role="searchbox"], a, button, div, span');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        var r = el.getBoundingClientRect();
        if (r.top < -20 || r.top > 170 || r.width < 40 || r.height < 16) continue;
        if (!otlobliNearSearchInput(el) && !otlobliLooksLikeSearchTrigger(el)) continue;
        otlobliUnhideEl(el);
        if (otlobliTemuSearchMode()) {
          var parent = el.parentElement;
          for (var p = 0; parent && parent !== document.body && p < 3; p++, parent = parent.parentElement) {
            if (parent.id && parent.id.indexOf('otlobli') === 0) break;
            if (parent.getAttribute && parent.getAttribute('data-otlobli-temu-search-exit-hidden') === '1') break;
            if (parent.getAttribute && parent.getAttribute('data-otlobli-temu-hidden') === '1') break;
            var parentText = temuCleanText(parent.textContent);
            if (parentText.length > 80 && otlobliTemuLooksLikeAccountPanelText(parentText)) break;
            parent.removeAttribute('data-otlobli-temu-hidden');
            parent.style.removeProperty('display');
            parent.style.setProperty('visibility', 'visible', 'important');
            parent.style.setProperty('opacity', '1', 'important');
            parent.style.setProperty('pointer-events', 'auto', 'important');
          }
          if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.getAttribute('role') === 'searchbox') {
            el.style.setProperty('pointer-events', 'auto', 'important');
            el.style.setProperty('-webkit-user-select', 'text', 'important');
            el.style.setProperty('user-select', 'text', 'important');
          }
        }
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
    if (otlobliTemuSearchMode()) return;
    var node = control;
    for (var i = 0; i < 12 && node && node !== document.body; i++, node = node.parentElement) {
      var style = window.getComputedStyle(node);
      if (style.position !== 'fixed') continue;
      var rect = node.getBoundingClientRect();
      if (rect.width < vp.width * 0.8 || rect.height < 30 || rect.height > 260 ||
          rect.top < -180 || rect.top > 170 || rect.bottom <= 0) return;
      if (!node.hasAttribute('data-otlobli-temu-original-transform')) {
        node.setAttribute('data-otlobli-temu-original-transform', node.style.transform || '');
        node.setAttribute('data-otlobli-temu-original-transition', node.style.transition || '');
      }
      node.style.setProperty('transform', 'translate3d(-50%,0,0)', 'important');
      node.style.setProperty('transition', 'none', 'important');
      node.style.setProperty('top', '0px', 'important');
      node.style.setProperty('visibility', 'visible', 'important');
      node.style.setProperty('opacity', '1', 'important');
      node.style.setProperty('pointer-events', 'auto', 'important');
      node.setAttribute('data-otlobli-temu-pinned-header', '1');
      return;
    }
  }

  function otlobliReleaseTemuSearchPinning() {
    if (!IS_TEMU || !document.body) return;
    try {
      var shells = document.querySelectorAll('[data-otlobli-temu-search-shell="1"]');
      for (var s = 0; s < shells.length; s++) {
        shells[s].removeAttribute('data-otlobli-temu-search-shell');
        shells[s].style.removeProperty('--otlobli-temu-search-left');
        shells[s].style.removeProperty('--otlobli-temu-search-width');
      }
      var pinned = document.querySelectorAll('[data-otlobli-temu-pinned-header="1"]');
      for (var p = 0; p < pinned.length; p++) {
        var el = pinned[p];
        var originalTransform = el.getAttribute('data-otlobli-temu-original-transform');
        var originalTransition = el.getAttribute('data-otlobli-temu-original-transition');
        if (originalTransform) el.style.setProperty('transform', originalTransform);
        else el.style.removeProperty('transform');
        if (originalTransition) el.style.setProperty('transition', originalTransition);
        else el.style.removeProperty('transition');
        el.removeAttribute('data-otlobli-temu-pinned-header');
        el.removeAttribute('data-otlobli-temu-original-transform');
        el.removeAttribute('data-otlobli-temu-original-transition');
      }
    } catch (e) {}
  }

  function restoreTemuCategoryStrip() {
    if (!IS_TEMU || !document.body) return;
    try {
      function showCategoryStripEl(el, forceDisplay) {
        if (!el || !otlobliTemuLooksLikeCategoryOrFilter(el)) return false;
        if (el.getAttribute && el.getAttribute('data-otlobli-temu-search-exit-hidden') === '1') return false;
        var hasSeveralItems = (el.children && el.children.length >= 2) || temuCleanText(el.textContent).length > 14;
        if (!hasSeveralItems) return false;
        el.setAttribute('data-otlobli-temu-category-strip', '1');
        el.removeAttribute('data-otlobli-temu-hidden');
        el.style.removeProperty('display');
        el.style.removeProperty('visibility');
        el.style.removeProperty('pointer-events');
        el.style.removeProperty('opacity');
        var cs = window.getComputedStyle(el);
        var r = el.getBoundingClientRect();
        if (forceDisplay || cs.display === 'none' || r.height < 6 || r.width < 20) {
          el.style.setProperty('display', 'flex', 'important');
          el.style.setProperty('align-items', 'center', 'important');
          el.style.setProperty('overflow-x', 'auto', 'important');
          el.style.setProperty('-webkit-overflow-scrolling', 'touch', 'important');
        }
        el.style.setProperty('visibility', 'visible', 'important');
        el.style.setProperty('opacity', '1', 'important');
        el.style.setProperty('pointer-events', 'auto', 'important');
        return true;
      }
      var nodes = document.querySelectorAll('[data-otlobli-temu-hidden="1"]');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.getAttribute && el.getAttribute('data-otlobli-temu-search-exit-hidden') === '1') continue;
        if (showCategoryStripEl(el, false)) {
          continue;
        }
        var r = el.getBoundingClientRect();
        if (r.width < 20 || r.height < 12 || r.top < 45 || r.top > 240) continue;
        var txt = temuCleanText(el.textContent);
        if (!txt || txt.length > 80) continue;
        if (!/(^الكل$|الصفقات|منتجات|نجوم|الأكثر|الاكثر|مستلزمات|حيوانات|أجهزة|اجهزة|الأطفال|الاطفال|الجمال|all|deals|rating|stars|popular|beauty|kids|home|pets|electronics)/i.test(txt)) continue;
        if (/(cart|basket|bag|account|login|download|app|تطبيق|تنزيل|حساب|سلة|عربة|تسجيل)/i.test(txt)) continue;
        el.removeAttribute('data-otlobli-temu-hidden');
        el.style.removeProperty('display');
        el.style.removeProperty('visibility');
        el.style.removeProperty('pointer-events');
        el.style.removeProperty('opacity');
      }
      var strips = document.querySelectorAll('nav, section, div, [role="tablist"], [class*="category" i], [class*="cat" i], [class*="tab" i]');
      var restored = 0;
      for (var s = 0; s < strips.length; s++) {
        if (restored >= 3) break;
        var strip = strips[s];
        if (strip.id && strip.id.indexOf('otlobli') === 0) continue;
        if (strip.getAttribute && strip.getAttribute('data-otlobli-temu-search-exit-hidden') === '1') continue;
        if (strip.closest && (strip.closest('#otlobli-nav') || strip.closest('#otlobli-back-btn'))) continue;
        var stripRect = strip.getBoundingClientRect();
        if (stripRect.top > 280) continue;
        var stripStyle = window.getComputedStyle(strip);
        if (stripStyle.display !== 'none' && stripStyle.visibility !== 'hidden' && parseFloat(stripStyle.opacity || '1') >= 0.1 && stripRect.height >= 6) continue;
        if (showCategoryStripEl(strip, true)) restored++;
      }
    } catch (e) {}
  }

  function otlobliTemuCategoryStripVisible(vp) {
    try {
      var nodes = document.querySelectorAll('div, a, button, span');
      var count = 0;
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (!otlobliTemuLooksLikeCategoryOrFilter(el)) continue;
        var r = el.getBoundingClientRect();
        if (r.width < 18 || r.height < 8 || r.right <= 0 || r.left >= vp.width) continue;
        if (r.top < 4 || r.top > 190 || r.bottom <= 8) continue;
        var cs = window.getComputedStyle(el);
        if (cs.display === 'none' || cs.visibility === 'hidden' || parseFloat(cs.opacity || '1') < 0.1) continue;
        count++;
        if (count >= 3) return true;
      }
    } catch (e) {}
    return false;
  }

  var __otlobliTemuHomeHeaderWakeUrl = '';
  var __otlobliTemuHomeHeaderWakeUntil = 0;
  var __otlobliTemuHomeHeaderWakeCount = 0;
  function otlobliWakeTemuHomeHeaderAfterSearchExit() {
    if (!IS_TEMU || !otlobliTemuHomeLikeUrl()) return;
    var url = (location.origin || '') + location.pathname + location.search;
    __otlobliTemuHomeHeaderWakeUrl = url;
    __otlobliTemuHomeHeaderWakeUntil = Date.now() + (OTLOBLI_LOW_END ? 2200 : 1400);
    __otlobliTemuHomeHeaderWakeCount = 0;
  }

  function otlobliTemuHomeLikeUrl() {
    if (!IS_TEMU) return false;
    var path = (location.pathname || '') + ' ' + (location.search || '') + ' ' + (location.hash || '');
    if (/search|goods|product|cart|checkout|order|account|login|sign/i.test(path)) return false;
    return true;
  }

  function otlobliResetTemuHomeHeaderWakeIfNeeded() {
    var url = (location.origin || '') + location.pathname + location.search;
    if (__otlobliTemuHomeHeaderWakeUrl === url) return;
    __otlobliTemuHomeHeaderWakeUrl = url;
    __otlobliTemuHomeHeaderWakeUntil = Date.now() + (OTLOBLI_LOW_END ? 9000 : 6500);
    __otlobliTemuHomeHeaderWakeCount = 0;
  }

  function otlobliForceTemuHomeHeaderState() {
    if (!IS_TEMU || !document.body) return;
    if (!otlobliTemuHomeLikeUrl() || otlobliTemuSearchMode()) return;
    otlobliResetTemuHomeHeaderWakeIfNeeded();
    try {
      var vp = viewportSize();
      var now = Date.now();
      if (now < __otlobliTemuHomeHeaderWakeUntil && __otlobliTemuHomeHeaderWakeCount < (OTLOBLI_LOW_END ? 18 : 14)) {
        if (!otlobliTemuCategoryStripVisible(vp)) {
          var y = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
          if (y > 1 && y < 520) {
            try { window.scrollTo(0, 0); } catch (e0) {}
          } else if (y <= 1 && (__otlobliTemuHomeHeaderWakeCount < 5 || __otlobliTemuHomeHeaderWakeCount % 3 === 0)) {
            try {
              window.scrollTo(0, 1);
              setTimeout(function () { try { window.scrollTo(0, 0); } catch (e) {} }, 35);
            } catch (e1) {}
          }
        }
        try { window.dispatchEvent(new Event('scroll')); } catch (e2) {}
        try { window.dispatchEvent(new Event('resize')); } catch (e3) {}
        __otlobliTemuHomeHeaderWakeCount++;
      }

      var nodes = document.querySelectorAll('[data-otlobli-temu-hidden="1"], nav, section, div, a, button, span');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (!otlobliTemuLooksLikeCategoryOrFilter(el)) continue;
        otlobliUnhideEl(el);
        var row = el;
        var best = el;
        for (var d = 0; d < 7 && row && row !== document.body; d++, row = row.parentElement) {
          var rr = row.getBoundingClientRect();
          var rt = temuCleanText(row.textContent);
          if (rr.width >= vp.width * 0.68 && rr.height >= 18 && rr.height <= 118 &&
              rr.top > -140 && rr.top < 260 && rt.length <= 360) {
            best = row;
          }
        }
        if (!best || (best.id && best.id.indexOf('otlobli') === 0)) continue;
        best.removeAttribute('data-otlobli-temu-hidden');
        best.style.removeProperty('display');
        best.style.setProperty('visibility', 'visible', 'important');
        best.style.setProperty('opacity', '1', 'important');
        best.style.setProperty('pointer-events', 'auto', 'important');
        best.style.setProperty('transition', 'none', 'important');
        best.style.setProperty('max-height', 'none', 'important');
        best.style.setProperty('overflow-x', 'auto', 'important');
        best.style.setProperty('overflow-y', 'visible', 'important');
        best.style.setProperty('-webkit-overflow-scrolling', 'touch', 'important');
      }
    } catch (e4) {}
  }

  var __otlobliTemuSearchTouchRepairInstalled = false;
  function ensureTemuSearchTouchRepair() {
    if (!IS_TEMU || __otlobliTemuSearchTouchRepairInstalled || !document) return;
    __otlobliTemuSearchTouchRepairInstalled = true;
    var repair = function (event) {
      try {
        var target = event.target;
        if (!target || (target.closest && (target.closest('#otlobli-nav') || target.closest('#otlobli-back-btn')))) return;
        var targetLooksSearch = otlobliLooksLikeSearchTrigger(target) ||
          !!(target.closest && target.closest('[class*="searchBar" i], input[type="search"], input[placeholder*="Search" i], input[placeholder*="بحث"], [role="searchbox"]'));
        var searchModeNow = otlobliTemuSearchMode();
        if (!searchModeNow && targetLooksSearch) {
          setTimeout(function () {
            try {
              var delayedInput = otlobliTemuSearchInput();
              var delayedSearchMode = otlobliTemuSearchMode();
              otlobliSyncTemuSearchModeState(delayedSearchMode);
              otlobliCleanTemuBlockers(true);
              if (delayedInput && delayedSearchMode && document.activeElement !== delayedInput) {
                try { delayedInput.focus({ preventScroll: true }); } catch (e) { try { delayedInput.focus(); } catch (e2) {} }
              }
            } catch (e3) {}
          }, 90);
          return;
        }
        if (!searchModeNow) return;
        var input = otlobliTemuSearchInput();
        if (!input) return;
        var point = event.touches && event.touches[0] ? event.touches[0] : event;
        var ir = input.getBoundingClientRect();
        var inSearchBand = point && point.clientY >= Math.max(0, ir.top - 36) && point.clientY <= ir.bottom + 36;
        var onSearchControl = target === input || (target.closest && target.closest('input[type="search"], input[placeholder*="Search" i], input[placeholder*="بحث"], [role="searchbox"]'));
        if (!onSearchControl && !inSearchBand && !otlobliLooksLikeSearchTrigger(target)) return;
        input.style.setProperty('pointer-events', 'auto', 'important');
        input.style.setProperty('-webkit-user-select', 'text', 'important');
        input.style.setProperty('user-select', 'text', 'important');
        if (event.type === 'touchstart') return;
        try { input.focus({ preventScroll: true }); } catch (e) { try { input.focus(); } catch (e2) {} }
      } catch (e3) {}
    };
    document.addEventListener('touchstart', repair, true);
    document.addEventListener('click', repair, true);
  }

  function stabilizeTemuSearchChrome() {
    if (!IS_TEMU || !document.body) return;
    if (otlobliTemuSearchMode()) { otlobliReleaseTemuSearchPinning(); return; }
    try {
      var vp = viewportSize();
      var control = null;
      var fallbackInput = otlobliTemuSearchInput();
      if (fallbackInput) {
        var fr = fallbackInput.getBoundingClientRect();
        if (fr.width >= 100 && fr.height >= 22 && fr.height <= 64 &&
            fr.bottom > 0 && fr.top < Math.min(vp.height, 180)) control = fallbackInput;
      }
      var direct = document.querySelectorAll(
        'input[type="search"], input[placeholder*="Search" i], input[placeholder*="بحث"], [role="searchbox"]'
      );
      for (var i = 0; !control && i < direct.length; i++) {
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
    var onTemuAccountRoute = IS_TEMU && otlobliTemuAccountRoute();
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
    var PROMO = /spin|claim|reward|coupon|billionaire|incredible deals|free gift|lucky draw|congratulations|% ?off|تهانينا|عجلة الحظ|اربح|جائزة|خصم \d|الملياردير|مجاناً.*احصل|احصل.*مجاناً/i;
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
      if (onTemuAccountRoute && otlobliTemuAccountPanelScore(txt) >= 2) continue;
      if (!PROMO.test(txt)) continue;        // لا بد أن يقرأ كعرض ترويجي
      if (/الكمية|موديل|المقاس|مقاس|اللون|أضف|السلة|حدد/.test(txt)) continue;
      if ((el.querySelector && el.querySelector('input, textarea')) || temuContainsPrice(el)) continue;
      var kwc = 0, kimgs = el.querySelectorAll ? el.querySelectorAll('img') : [];
      for (var ki = 0; ki < kimgs.length && kwc < 3; ki++) {
        if (/kwcdn/i.test(kimgs[ki].currentSrc || kimgs[ki].src || '')) kwc++;
      }
      if (kwc >= 3) continue;
      el.setAttribute('data-otlobli-blocked', '1');
      el.style.setProperty('display', 'none', 'important');
    }
    if (document.body) document.body.style.overflow = '';
    if (document.documentElement) document.documentElement.style.overflow = '';
    var appMeta = document.querySelector('meta[name="apple-itunes-app"]');
    if (appMeta && appMeta.parentNode) appMeta.parentNode.removeChild(appMeta);

    hideStoreBannerByText([
      'billionaire', 'incredible deals', 'shop like', 'open in the app',
      'sign in for the best', 'get the app', 'download the app',
      'الملياردير', 'تسوق مثل', 'احصل على التطبيق', 'تنزيل التطبيق',
    ], 110);

    if (IS_TEMU) {
      ensureTemuNoZoom();
      var hiddenBarDiag = [];
      var allEls = document.querySelectorAll('div, nav, footer, ul');
      for (var nb = 0; nb < allEls.length; nb++) {
        var nv = allEls[nb];
        if (nv.id && nv.id.indexOf('otlobli') === 0) continue;
        if (nv.getAttribute && nv.getAttribute('data-otlobli-blocked')) continue;
        var nvTxt = (nv.textContent || '');
        if (!/حسابي|طلباتي|الرئيسية/.test(nvTxt) || nvTxt.length > 60) continue;
        var nvCs = window.getComputedStyle(nv);
        if (nvCs.position !== 'fixed') continue;
        var nvR = nv.getBoundingClientRect();
        if (nvR.top < vp.height * 0.7) continue; // لا بد أن يكون في أسفل الشاشة
        nv.setAttribute('data-otlobli-blocked', '1');
        nv.style.setProperty('display', 'none', 'important');
        hiddenBarDiag.push('[' + nvTxt.replace(/\s+/g, ' ').slice(0, 70) + ']');
      }
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
      var hiddenIconDiag = [], visibleTopIconDiag = [];
      var LEFT_CLUSTER_MAX = 180;
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
          var inTopBand = irAll.top >= 0 && irAll.top <= 140 && irAll.width > 0 && irAll.width <= 60 && irAll.height > 0 && irAll.height <= 60;
          if (!inTopBand) continue;
          if (temuCleanText(ic.textContent).length > 0) continue;
          rawTopBandCount++;
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
      if (window.__otlobliHideDiagUrl !== location.href) {
        window.__otlobliHideDiagUrl = location.href;
      }
      hideTemuFooterSection();
    }
  }
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
      if ((el.querySelector && el.querySelector('input:not([type="hidden"])')) || temuContainsPrice(el)) continue;
      if (txt.length < bestLen) { best = el; bestLen = txt.length; }
    }
    if (best) {
      best.setAttribute('data-otlobli-blocked', '1');
      best.style.setProperty('display', 'none', 'important');
    }
  }
  function hideStoreBannerByText(phrases, maxLen) {
    var vp = viewportSize();
    var onTemuAccountRoute = IS_TEMU && otlobliTemuAccountRoute();
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
      if (onTemuAccountRoute && otlobliTemuAccountPanelScore(txt) >= 2) continue;
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

  var __otlobliAppPromptScanAt = 0;
  function hideSheinAppInstallPrompts() {
    if (!IS_SHEIN) return;
    var scanNow = Date.now();
    if (scanNow - __otlobliAppPromptScanAt < 1800) return;
    __otlobliAppPromptScanAt = scanNow;
    var vp = viewportSize();
    var APP_RE = /(get\s*(the\s*)?app|open\s*in\s*(the\s*)?app|download\s*(the\s*)?app|install\s*(the\s*)?app|app\s*exclusive|\u0627\u062d\u0635\u0644|\u062a\u0637\u0628\u064a\u0642|\u062a\u0646\u0632\u064a\u0644)/i;
    var nodes = document.querySelectorAll('div, section, aside, header, a, [role="banner"], [class*="app" i]');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (!el || el === document.body || el === document.documentElement) continue;
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.getAttribute && el.getAttribute('data-otlobli-blocked')) continue;
      var txt = (el.textContent || '').replace(/\s+/g, ' ').trim();
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
        var ut = (up.textContent || '').replace(/\s+/g, ' ').trim();
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
    var onAccountRoute = otlobliTemuAccountRoute();
    var WHEEL_RE = /(spin|wheel|reward|claim|coupon|lucky|chance|prize|free\s*gift|congratulations|SAR\s*\d|\u062d\u0631\u0651?\u0643|\u0641\u0631\u0635\u0629|\u062c\u0631\u0628|\u062a\u062d\u0635\u0644|\u062c\u0627\u0626\u0632\u0629|\u0645\u062c\u0627\u0646\u064a|\u062e\u0635\u0645)/i;
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
      var txt = (el.textContent || '').replace(/\s+/g, ' ').trim();
      var hint = ((el.className || '') + ' ' + (el.id || '') + ' ' + txt).toString();
      if (txt.length > 900) continue;
      if (onAccountRoute && otlobliTemuAccountPanelScore(txt) >= 2) continue;
      if (!WHEEL_RE.test(hint)) continue;
      if (el.querySelector && el.querySelector('input:not([type="hidden"]), textarea')) continue;
      if (temuProductOptionDialog(el)) continue;
      var target = el;
      var up = el.parentElement;
      var hops = 0;
      while (up && up !== document.body && up !== document.documentElement && hops < 3) {
        var ur = up.getBoundingClientRect();
        var ucs = window.getComputedStyle(up);
        var ut = (up.textContent || '').replace(/\s+/g, ' ').trim();
        if (ut.length > 1100) break;
        if ((ucs.position === 'fixed' || ucs.position === 'absolute') && ur.width > vp.width * 0.55 && ur.height > vp.height * 0.22 && ur.height < vp.height * 0.95) target = up;
        up = up.parentElement;
        hops++;
      }
      if (temuProductOptionDialog(target)) continue;
      target.setAttribute('data-otlobli-blocked', '1');
      target.style.setProperty('display', 'none', 'important');
      target.style.setProperty('visibility', 'hidden', 'important');
      target.style.setProperty('pointer-events', 'none', 'important');
    }
    if (document.body) document.body.style.overflow = '';
    if (document.documentElement) document.documentElement.style.overflow = '';
  }





  function tick() {
    if (!document.body) return;
    otlobliHealOrphanScrollLock();
    if (IS_SHEIN && sheinLooksLikeProductRouteForShipping()) {
      sheinRegionDiag('tick-product-route', {
        addressCountry: sheinAddressCookieCountry(),
        signedReady: sheinSignedSaudiAddressReady()
      }, 'tick');
    }
    if (IS_SHEIN) sheinPrimeRegionRepairFromRoute();
    if (IS_SHEIN) sheinClearStaleShippingLock();
    if (IS_SHEIN && otlobliInteractionActive() &&
        !sheinShippingBodyLockState && !sheinShippingUiLikelyOpen()) {
      if (!document.getElementById('otlobli-nav')) ensureOtlobliNav();
      if (sheinNativeCoverRepairActive) scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 320 : 160);
      return;
    }
    if (otlobliIsHumanChallenge()) {
      otlobliChallengeActive = true;
      __otlobliChallengeResolvedNotified = false;
      otlobliEnterChallengeMode();
      return;
    }
    if (otlobliChallengeActive) {
      if (otlobliLooksLikeRemovedProductPage()) {
        otlobliNotifyHumanCheckSkipped();
        return;
      }
      if (!sheinPageLooksInteractive()) {
        otlobliScheduleChallengeNav();
        return;
      }
      otlobliChallengeActive = false;
      otlobliForgetHumanChallenge();
      if (!__otlobliChallengeResolvedNotified) {
        __otlobliChallengeResolvedNotified = true;
        try {
          if (window.mobileApp && window.mobileApp.postMessage) {
            window.mobileApp.postMessage({ detail: { type: 'humanCheckResolved' } });
          }
        } catch (e) {}
      }
    }
    if (IS_SHEIN) ensureSheinSaudiShippingSelection();
    if (IS_SHEIN) retrySheinFeedError();
    ensureNoTextSelection();
    ensureViewportFitCover();
    if (IS_SHEIN) ensureSheinSaudiStore();
    ensureBackButton();
    ensureOtlobliNav();
    if (!IS_SHEIN) {
      if (IS_TEMU) {
        var temuSearching = otlobliTemuSearchMode();
        try { injectTemuHeaderHideCSS(); } catch (e) {}
        try { ensureTemuNoZoom(); } catch (e) {}
        try { ensureTemuSearchTouchRepair(); } catch (e) {}
        try { otlobliSyncTemuSearchModeState(temuSearching); } catch (e) {}
        try { hideTemuSearchVisibleAccountCart(temuSearching); } catch (e) {}
        try { otlobliTemuEntryCover(); } catch (e) {}
        try { otlobliTemuRestoreCleanHidden(); } catch (e) {}
        try { otlobliTemuBlankPageRescue(); } catch (e) {}
        try { otlobliTemuForceProductVisible(); } catch (e) {}
        try { otlobliPostTemuProductVisibleIfReady(); } catch (e) {}
        try {
          var __d1 = document.getElementById('otlobli-temu-diag'); if (__d1) __d1.remove();
          var __d2 = document.getElementById('otlobli-temu-urlprobe'); if (__d2) __d2.remove();
        } catch (e) {}
        try { otlobliTemuBlankProductNotice(); } catch (e) {}
        try { otlobliTemuBlankPageAutoReload(); } catch (e) {}
        try {
          var temuWheelAnchor = document.querySelector(
            '[class*="turnable" i], [class*="diskitem" i], [class*="wheel" i], [class*="spin" i]'
          );
          if (temuWheelAnchor && !(temuWheelAnchor.closest && temuWheelAnchor.closest('[data-otlobli-blocked="1"]'))) {
            hideTemuSpinWheelPopup();
          }
        } catch (e) {}
        try { otlobliCleanTemuBlockers(); } catch (e) {}
        try { ensureAddToCartButton(); } catch (e) {}
        try { detectEmptyTemuSearch(); } catch (e) {}
        return;
      }
      try { killStorePopups(); } catch (e) {}
      return;
    }
    ensureLoadingOverlay();
    blockCartNavigation();
    hideSheinCartSuccessToast();
    ensureAddToCartButton();
    stabilizeSheinImageViewerChrome();
    hideExtraHeaderIcons();
    hideSheinCartIcons();
    hideForeignBottomNav();
    otlobliForceAcceptCookies();
    protectSheinCookieConsentAction();
    hideSheinSignupDiscountBanner();
    dismissSheinProductLoginPrompt();
    hideSheinAppInstallPrompts();
    updateSheinNativeCoverState();
    stabilizeSheinShippingDrawerInteraction();
  }

  var tickScheduled = false;
  var otlobliInteractionUntil = 0;
  function markOtlobliInteraction() {
    otlobliInteractionUntil = Date.now() + 320;
  }
  function otlobliInteractionActive() {
    return Date.now() < otlobliInteractionUntil;
  }
  document.addEventListener('pointerdown', markOtlobliInteraction, { capture: true, passive: true });
  document.addEventListener('touchstart', markOtlobliInteraction, { capture: true, passive: true });
  document.addEventListener('touchmove', markOtlobliInteraction, { capture: true, passive: true });
  document.addEventListener('scroll', markOtlobliInteraction, { capture: true, passive: true });
  document.addEventListener('click', sheinTrackSelectedSkuPrice, true);
  var OTLOBLI_LOW_END = typeof navigator !== 'undefined' && (
    (navigator.hardwareConcurrency || 4) <= 4 ||
    (navigator.deviceMemory && navigator.deviceMemory <= 4) ||
    /Android\s(?:7|8|9|10)(?:\D|$)/i.test(navigator.userAgent || '')
  );
  function scheduleTick() {
    sheinBlockReported = false;
    if (OTLOBLI_LOW_END) return;
    if (otlobliChallengeActive) return;
    if (IS_SHEIN && otlobliInteractionActive() && !sheinShippingBodyLockState && !sheinShippingUiLikelyOpen()) {
      if (sheinNativeCoverRepairActive) scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 320 : 160);
      return;
    }
    if (tickScheduled) return;
    tickScheduled = true;
    setTimeout(function () {
      tickScheduled = false;
      tick();
    }, OTLOBLI_LOW_END ? 220 : 80);
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

  var OTLOBLI_MAIN_INTERVAL = OTLOBLI_LOW_END ? 650 : 300;
  var OTLOBLI_BLOCK_INTERVAL = OTLOBLI_LOW_END ? 650 : 120;
  var OTLOBLI_NAV_INTERVAL = OTLOBLI_LOW_END ? 2200 : 1200;
  var OTLOBLI_SECURITY_INTERVAL = OTLOBLI_LOW_END ? 1600 : 1000;
  var otlobliMainDue = 0;
  var otlobliBlockDue = 0;
  var otlobliNavDue = 0;
  var otlobliSecurityDue = 0;
  var otlobliCoordinatorTimer = 0;

  function runOtlobliBlockers() {
    if (otlobliChallengeActive || !IS_SHEIN || otlobliInteractionActive()) return;
    hideKnownHeaderIconsByHint();
    hideSheinHeaderControls();
    hideListingCardAddButtons();
    hideSheinNativeProductAdd();
  }

  function runOtlobliNavigationMaintenance() {
    if (!otlobliInteractionActive() || !document.getElementById('otlobli-nav')) ensureOtlobliNav();
    if (!IS_TEMU) return;
    injectTemuHeaderHideCSS();
    ensureTemuSearchTouchRepair();
    var intervalTemuSearching = otlobliTemuSearchMode();
    otlobliSyncTemuSearchModeState(intervalTemuSearching);
    try { hideTemuSearchVisibleAccountCart(intervalTemuSearching); } catch (e) {}
    try { otlobliCleanTemuBlockers(true); } catch (e) {}
  }

  function scheduleOtlobliCoordinator() {
    clearTimeout(otlobliCoordinatorTimer);
    var nextDue = Math.min(otlobliMainDue, otlobliBlockDue, otlobliNavDue, otlobliSecurityDue);
    otlobliCoordinatorTimer = setTimeout(runOtlobliCoordinator, Math.max(40, nextDue - Date.now()));
  }

  function runOtlobliCoordinator() {
    var now = Date.now();
    if (document.hidden) {
      otlobliMainDue = now + OTLOBLI_MAIN_INTERVAL;
      otlobliBlockDue = now + OTLOBLI_BLOCK_INTERVAL;
      otlobliNavDue = now + OTLOBLI_NAV_INTERVAL;
      otlobliSecurityDue = now + OTLOBLI_SECURITY_INTERVAL;
      scheduleOtlobliCoordinator();
      return;
    }
    if (now >= otlobliBlockDue) {
      runOtlobliBlockers();
      otlobliBlockDue = now + OTLOBLI_BLOCK_INTERVAL;
    }
    if (now >= otlobliMainDue) {
      tick();
      otlobliMainDue = now + OTLOBLI_MAIN_INTERVAL;
    }
    if (now >= otlobliNavDue) {
      runOtlobliNavigationMaintenance();
      otlobliNavDue = now + OTLOBLI_NAV_INTERVAL;
    }
    if (now >= otlobliSecurityDue) {
      if (IS_SHEIN && !otlobliInteractionActive()) checkForSheinSecurityBlock();
      otlobliSecurityDue = now + OTLOBLI_SECURITY_INTERVAL;
    }
    scheduleOtlobliCoordinator();
  }

  document.addEventListener('visibilitychange', function () {
    if (document.hidden) return;
    otlobliMainDue = otlobliBlockDue = otlobliNavDue = otlobliSecurityDue = 0;
    runOtlobliCoordinator();
  }, false);
  runOtlobliCoordinator();

})();

}

