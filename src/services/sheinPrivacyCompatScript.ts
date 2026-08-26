// SHEIN occasionally paints its mobile privacy agreement as an invisible,
// full-viewport layer on iOS. The page underneath is complete and alive, but
// that layer keeps pointer-events and prevents every store control from being
// tapped. This compatibility prelude is intentionally independent from the
// optional navigation, blocking, capture and session features: a raw SHEIN
// page still has to remain usable.
//
// The current SHEIN control is a styled <div>, so this code matches its exact
// action text rather than assuming a button tag. It activates the site-owned
// "Accept all" action. Only a confirmed SHEIN
// privacy-agreement layer that covers almost the entire viewport may be
// neutralized, and that last-resort path is restricted to the native iOS app.
export const SHEIN_PRIVACY_COMPAT_SCRIPT = `
(function () {
  if (window.top !== window || !/(^|\\.)shein\\.com$/i.test(location.hostname)) return;
  if (window.__otlobliSheinPrivacyCompatInstalled) {
    try {
      if (window.__otlobliSheinPrivacyCompat && window.__otlobliSheinPrivacyCompat.resume) {
        window.__otlobliSheinPrivacyCompat.resume();
      }
    } catch (e) {}
    return;
  }
  window.__otlobliSheinPrivacyCompatInstalled = true;

  var startedAt = Date.now();
  var acceptAttempts = 0;
  var sawBlockingShield = false;
  var reportedMethod = '';
  var burstId = 0;
  var scheduledDelays = [0, 60, 160, 360, 700, 1200, 2000, 3500, 6000, 10000];

  function cleanLabel(value) {
    return String(value || '')
      .replace(/[\\u200e\\u200f\\u061c\\u202a-\\u202e]/g, '')
      .replace(/\\s+/g, ' ')
      .trim();
  }

  function report(method) {
    if (reportedMethod) return;
    reportedMethod = method;
    try {
      var detail = { type: 'sheinPrivacyResolved', method: method };
      var handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.messageHandler;
      if (window.mobileApp && window.mobileApp.postMessage) window.mobileApp.postMessage({ detail: detail });
      else if (handler) handler.postMessage({ detail: detail });
    } catch (e) {}
  }

  function isHumanChallenge() {
    if (/\\/(?:cdn-cgi|challenge|captcha|verify|verification|bgn[_-]?verification|security|robot|risk|anti[-_]?bot|human)(?:[/?#.-]|$)/i.test(location.pathname || '') ||
        /(?:^|[?&#])(?:captcha|challenge|verification|bgn[_-]?verification|security_token|risk|robot|anti[-_]?bot|human)=/i.test((location.search || '') + (location.hash || ''))) return true;
    try {
      var nodes = document.querySelectorAll('#challenge-form,iframe[title*="challenge" i],iframe[title*="verification" i],.one-pass-dialog,#one-pass-custom,one-pass-custom,#nine-captcha-custom,nine-captcha-custom,.si-verify-block-request-dialog,[class*="risk-one-pass" i],[class*="captcha" i],[class*="challenge" i],[class*="verification" i]');
      for (var i = Math.max(0, nodes.length - 12); i < nodes.length; i++) {
        var node = nodes[i];
        var style = window.getComputedStyle(node);
        var rect = node.getBoundingClientRect();
        if (style.display !== 'none' && style.visibility !== 'hidden' && Number(style.opacity || 1) > 0 &&
            rect.width > 4 && rect.height > 4) return true;
      }
    } catch (e) {}
    return false;
  }

  function viewportSize() {
    var root = document.documentElement;
    return {
      width: Math.max(1, (root && root.clientWidth) || window.innerWidth || 1),
      height: Math.max(1, (root && root.clientHeight) || window.innerHeight || 1)
    };
  }

  function findBlockingPrivacyShield() {
    if (!document.documentElement) return null;
    var candidates = document.querySelectorAll('[class*="shein_privacy_agreement"]');
    var viewport = viewportSize();
    for (var i = 0; i < candidates.length; i++) {
      var candidate = candidates[i];
      if (!candidate || candidate.getAttribute('data-otlobli-privacy-neutralized') === '1') continue;
      var style;
      var rect;
      try {
        style = window.getComputedStyle(candidate);
        rect = candidate.getBoundingClientRect();
      } catch (e) {
        continue;
      }
      if (!style || style.display === 'none' || style.visibility === 'hidden' || style.pointerEvents === 'none') continue;
      if (style.position !== 'fixed') continue;
      if (rect.width < viewport.width * 0.85 || rect.height < viewport.height * 0.85) continue;
      if (rect.left > viewport.width * 0.1 || rect.top > viewport.height * 0.1) continue;
      return candidate;
    }
    return null;
  }

  function findAcceptAllControl(shield) {
    var acceptPattern = /^(?:accept all|\\u0642\\u0628\\u0648\\u0644 \\u0627\\u0644\\u0643\\u0644)$/i;
    var controls = shield.querySelectorAll('button,[role="button"],div');
    for (var i = 0; i < controls.length && i < 160; i++) {
      var control = controls[i];
      var label = cleanLabel(control.textContent || '');
      if (label.length > 24 || !acceptPattern.test(label)) continue;
      return control;
    }
    return null;
  }

  function activateAccept(control) {
    acceptAttempts++;
    control.setAttribute('data-otlobli-privacy-action', 'accept-all');
    try { control.click(); } catch (e1) {}
    if (acceptAttempts < 2) return;
    try {
      var events = ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'];
      for (var i = 0; i < events.length; i++) {
        control.dispatchEvent(new MouseEvent(events[i], { bubbles: true, cancelable: true, view: window }));
      }
    } catch (e2) {}
  }

  function neutralizeIosShield(shield) {
    shield.setAttribute('data-otlobli-privacy-neutralized', '1');
    shield.setAttribute('aria-hidden', 'true');
    shield.style.setProperty('pointer-events', 'none', 'important');
    shield.style.setProperty('visibility', 'hidden', 'important');
    shield.style.setProperty('display', 'none', 'important');
    report('ios-invisible-shield-neutralized');
  }

  function scan() {
    if (isHumanChallenge()) return;
    var shield = findBlockingPrivacyShield();
    if (!shield) {
      if (sawBlockingShield && acceptAttempts > 0) report('accept-all');
      return;
    }
    sawBlockingShield = true;
    var accept = findAcceptAllControl(shield);
    if (accept && acceptAttempts < 3) {
      activateAccept(accept);
      return;
    }
    var isNativeIos = String(window.__otlobliNativePlatform || '').toLowerCase() === 'ios';
    if (isNativeIos && (acceptAttempts >= 2 || Date.now() - startedAt >= 1500)) {
      neutralizeIosShield(shield);
    }
  }

  function runBurst(id, index) {
    if (id !== burstId) return;
    scan();
    if (index + 1 >= scheduledDelays.length) return;
    setTimeout(function () {
      runBurst(id, index + 1);
    }, scheduledDelays[index + 1] - scheduledDelays[index]);
  }

  function resume() {
    startedAt = Date.now();
    acceptAttempts = 0;
    sawBlockingShield = false;
    burstId++;
    runBurst(burstId, 0);
  }

  window.__otlobliSheinPrivacyCompat = { resume: resume };
  try { document.addEventListener('DOMContentLoaded', scan, { once: true }); } catch (e1) {}
  try { addEventListener('pageshow', scan, false); } catch (e2) {}
  try {
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') scan();
    }, false);
  } catch (e3) {}
  try { addEventListener('privacyCookieAgreementShow', resume, false); } catch (e4) {}
  resume();
})();
`
