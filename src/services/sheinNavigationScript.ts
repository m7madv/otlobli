
export const OTLOBLI_SHEIN_BASE_CSS = '.login-bar.j-login-bar{display:none!important}'

export const OTLOBLI_NAV_STYLE_VERSION = 'v86.210.0'
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

// Document-start touch routing beats modal click cancellation. Home deliberately
// waits for the platform double-tap window: one tap is deliberately a no-op,
// while two physical taps reveal Otlobli's store chooser without destroying the
// parked browser session. A click synthesized after touchend must never count as
// the second tap. Keyboard/assistive activation is treated as the intentional
// store-switch action so this gesture remains accessible.
export const OTLOBLI_NAV_TOUCH_BRIDGE_JS = `
  function otlobliInstallNavTouchBridge() {
    if (window.__otlobliNavTouchBridgeBound) return;
    window.__otlobliNavTouchBridgeBound = true;
    var homeDoubleTapMs = 320;
    var lastPhysicalTouchAt = 0;
    var homeTapAt = 0;
    var homeTapTimer = 0;
    var clearPendingHomeTap = function () {
      if (homeTapTimer) clearTimeout(homeTapTimer);
      homeTapTimer = 0;
      homeTapAt = 0;
    };
    var finishSingleHomeTap = function () {
      clearPendingHomeTap();
    };
    var revealStoreChooser = function () {
      clearPendingHomeTap();
      try {
        if (window.mobileApp && window.mobileApp.postMessage) {
          window.mobileApp.postMessage({ detail: { type: 'closeStore' } });
        }
      } catch (chooserError) {}
    };
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
      if (event.type === 'click' && now - lastPhysicalTouchAt < 450) return;
      if (event.type === 'touchend') lastPhysicalTouchAt = now;
      if (messageType === 'openHome') {
        if (event.type === 'click' && event.detail === 0) {
          revealStoreChooser();
          return;
        }
        if (homeTapTimer && now - homeTapAt <= homeDoubleTapMs) {
          revealStoreChooser();
          return;
        }
        clearPendingHomeTap();
        homeTapAt = now;
        homeTapTimer = setTimeout(finishSingleHomeTap, homeDoubleTapMs);
        return;
      }
      clearPendingHomeTap();
      if (now - (window.__otlobliNavTouchBridgeAt || 0) < 450) return;
      window.__otlobliNavTouchBridgeAt = now;
      try {
        if (window.mobileApp && window.mobileApp.postMessage) {
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


// Runs as a real WKUserScript before SHEIN's first document starts. It mounts
// only Otlobli's existing bottom navigation. Product-card taps remain wholly
// owned by SHEIN: forcing location.assign or reacting to page chunk promises
// from this navigation layer was proven on the real iPhone to replace a healthy
// SPA transition with a reload/spinner loop. The full capture script adopts the
// same #otlobli-nav node after page load.
export const OTLOBLI_NAV_BOOTSTRAP_SCRIPT = `
(function () {
  if (window.top !== window || window.__otlobliNavBootstrapInstalled) return;
  window.__otlobliNavBootstrapInstalled = true;

  ${OTLOBLI_NAV_TOUCH_BRIDGE_JS}

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

  function mount() {
    var root = document.documentElement, inset = Number(window.__otlobliSafeBottom || 0);
    if (root && isFinite(inset)) root.style.setProperty('--otlobli-sb', Math.round(Math.min(60, Math.max(16, inset))) + 'px');
    ensureEarlyViewportFitCover();
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
    if (document.getElementById('otlobli-nav')) return true;

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
        (active ? '#006948' : '#3d4a42') + '!important;-webkit-appearance:none!important;appearance:none!important;' +
        'border-radius:0!important;box-shadow:none!important;transform:none!important;transition:none!important;opacity:1!important;' +
        'touch-action:manipulation!important;-webkit-tap-highlight-color:transparent!important;';
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
    return true;
  }

  ensureEarlyViewportFitCover();
  if (!mount()) {
    document.addEventListener('DOMContentLoaded', mount, false);
    timer = setInterval(function () {
      attempts++;
      if (mount() || attempts >= 400) clearInterval(timer);
    }, 25);
  }
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
