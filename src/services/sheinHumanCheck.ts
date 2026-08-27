// Runs inside the active store page. It only observes the store's own verification UI;
// it never clicks, solves, reloads, or changes the verification response.
export const OTLOBLI_SHEIN_HUMAN_CHECK_JS = `
  var __otlobliChallengeNotified = false;
  var __otlobliChallengeResolvedNotified = false;
  var otlobliChallengeActive = false;
  var __otlobliChallengeScanAt = 0;
  var __otlobliChallengeScanResult = false;
  var __otlobliChallengeMissingSince = 0;
  var __otlobliChallengeResolvedAt = 0;
  var __otlobliSheinChallengeCommitCookieBefore = null;
  var __otlobliSheinChallengeCommitProof = false;
  var __otlobliSheinFullPageChallenge = false;

  function otlobliIsSheinFullPageChallenge(href) {
    var route = String(href || '');
    return /\\/risk\\/challenge(?:[/?#]|$)/i.test(route);
  }

  function otlobliReadSheinChallengeCommitCookie() {
    try {
      var entries = String(document.cookie || '').split(';');
      for (var ci = 0; ci < entries.length; ci++) {
        var entry = entries[ci].trim();
        var separator = entry.indexOf('=');
        var name = separator < 0 ? entry : entry.slice(0, separator);
        if (name === '_f_c_llbs_') return separator < 0 ? '' : entry.slice(separator + 1);
      }
    } catch (e) {}
    return null;
  }

  function otlobliSheinChallengeCommitIsConfirmed() {
    if (typeof IS_SHEIN === 'undefined' || !IS_SHEIN) return false;
    if (__otlobliSheinChallengeCommitProof) return true;
    var current = otlobliReadSheinChallengeCommitCookie();
    if (current === null || current === __otlobliSheinChallengeCommitCookieBefore) return false;
    __otlobliSheinChallengeCommitProof = true;
    return true;
  }

  function otlobliMatchesHumanChallengeText(value) {
    var text = String(value || '').replace(/\\s+/g, ' ').trim().slice(0, 1600);
    if (!text) return false;
    return /verify (?:that )?you are (?:a )?human|human verification|security verification|checking your browser|confirm (?:that )?you are (?:a )?human|i(?:'|’)m (?:not a robot|human)|cloudflare|turnstile|التحقق من أنك إنسان|تحقق أنك إنسان|أنا إنسان|لست (?:إنساناً آلياً|روبوت(?:اً)?)|التحقق الأمني|التحقق من الأمان/i.test(text);
  }

  function otlobliMatchesHumanChallengeTimeoutText(value) {
    var text = String(value || '').replace(/\\s+/g, ' ').trim().slice(0, 1600);
    if (!text) return false;
    return /access timed out|access timeout|request timed out|please refresh (?:the )?page and try again|انتهت مهلة الوصول|انتهت مهلة (?:الطلب|الاتصال)|يرجى تحديث الصفحة والمحاولة مرة أخرى/i.test(text);
  }

  function otlobliIsHumanChallenge() {
    try {
      if (otlobliIsHumanChallengeUrl(location.href)) return true;
      if (/just a moment/i.test(document.title || '')) return true;
      var challengeNow = Date.now();
      // Never cache a negative result while ordinary store work is active.
      // SHEIN/Temu can mount a challenge inside the current SPA document
      // without changing the URL; a cached negative would let a blocker or
      // region pass mutate the newly-mounted verification surface. Positive
      // challenge state may still reuse its last scan for 600ms because every
      // Otlobli intervention is already paused during that window.
      if (otlobliChallengeActive && challengeNow - __otlobliChallengeScanAt < 600) {
        return __otlobliChallengeScanResult;
      }
      __otlobliChallengeScanAt = challengeNow;
      var challengeForm = document.getElementById('challenge-form');
      if (challengeForm && sheinElementIsPainted(challengeForm)) return (__otlobliChallengeScanResult = true);
      // Provider scripts remain in the document after a successful check and
      // are not proof that a challenge is still active. Only a painted frame
      // is treated as an active verification surface.
      var providerFrames = document.querySelectorAll('iframe[src*="challenges.cloudflare.com"],iframe[title*="challenge" i],iframe[title*="verification" i]');
      for (var fi = 0; fi < providerFrames.length; fi++) {
        if (sheinElementIsPainted(providerFrames[fi])) return (__otlobliChallengeScanResult = true);
      }
      // SHEIN changes the wrapper name independently of the product page. Keep
      // exact known security surfaces cheap, then use a bounded semantic check
      // for a visible dialog. Never scan or act on arbitrary page content.
      var proprietaryChecks = document.querySelectorAll('.one-pass-dialog,#one-pass-custom,one-pass-custom,#nine-captcha-custom,nine-captcha-custom,.si-verify-block-request-dialog,[class*="risk-one-pass" i]');
      for (var pi = 0; pi < proprietaryChecks.length; pi++) {
        if (sheinElementIsPainted(proprietaryChecks[pi])) return (__otlobliChallengeScanResult = true);
      }

      var semanticChecks = document.querySelectorAll('[role="dialog"],[aria-modal="true"],.sui-dialog__wrapper,[id*="captcha" i],[class*="captcha" i],[id*="challenge" i],[class*="challenge" i],[data-testid*="challenge" i],[class*="one-pass" i],[class*="turnstile" i]');
      // Dialog libraries often leave old nodes mounted. Looking only at the
      // final twelve visible surfaces bounds the work and favours the active UI.
      var semanticStart = Math.max(0, semanticChecks.length - 12);
      for (var si = semanticStart; si < semanticChecks.length; si++) {
        var surface = semanticChecks[si];
        if (!sheinElementIsPainted(surface)) continue;
        var surfaceIdentity = String((surface.id || '') + ' ' + (surface.className || '') + ' ' + (surface.getAttribute && (surface.getAttribute('data-testid') || surface.getAttribute('aria-label')) || '')).slice(0, 600);
        if (/risk-one-pass|captcha|challenge|cf-turnstile|si-verify-block-request/i.test(surfaceIdentity)) return (__otlobliChallengeScanResult = true);
        if (otlobliMatchesHumanChallengeTimeoutText(surface.textContent || '')) return (__otlobliChallengeScanResult = true);
        if (otlobliMatchesHumanChallengeText(surface.textContent || '')) return (__otlobliChallengeScanResult = true);
      }
    } catch (e) {}
    __otlobliChallengeScanResult = false;
    return __otlobliChallengeScanResult;
  }

  function otlobliChallengeAbsenceIsStable(now) {
    if (!__otlobliChallengeMissingSince) {
      __otlobliChallengeMissingSince = now;
      return false;
    }
    if (document.readyState === 'loading' || now - __otlobliChallengeMissingSince < 1200) return false;
    // A full-page SHEIN risk challenge removes one-pass before flow_check commits and then
    // replaces the document. Never release the old document by elapsed time;
    // the host already accepts the fresh non-challenge document hand-off.
    if (typeof IS_SHEIN !== 'undefined' && IS_SHEIN) {
      if (__otlobliSheinFullPageChallenge) return false;
      // Same-document checks can safely finish as soon as the exact provider
      // cookie appears/changes. A longer bounded fallback covers a same-value
      // cookie rewrite that document.cookie cannot distinguish.
      if (otlobliSheinChallengeCommitIsConfirmed()) return true;
      return now - __otlobliChallengeMissingSince >= 5000;
    }
    // Other stores retain the conservative, bounded absence fallback.
    return true;
  }

  function otlobliChallengeSettlementIsStable(now) {
    return !!__otlobliChallengeResolvedAt && document.readyState !== 'loading' &&
      now - __otlobliChallengeResolvedAt >= 600;
  }

  function otlobliFinishChallengeSettlement() {
    if (!__otlobliChallengeResolvedAt) return false;
    __otlobliChallengeResolvedAt = 0;
    try { window.__otlobliStoreNavigationChallengeLocked = false; } catch (e) {}
    try {
      if (window.__otlobliSheinPolicyEngine && window.__otlobliSheinPolicyEngine.resume) {
        window.__otlobliSheinPolicyEngine.resume();
      }
    } catch (e) {}
    try {
      if (window.__otlobliSheinPrivacyCompat && window.__otlobliSheinPrivacyCompat.resume) {
        window.__otlobliSheinPrivacyCompat.resume();
      }
    } catch (e) {}
    return true;
  }

  function otlobliResolveHumanChallenge() {
    if (!otlobliChallengeActive) return false;
    otlobliChallengeActive = false;
    __otlobliChallengeScanResult = false;
    __otlobliChallengeMissingSince = 0;
    __otlobliChallengeResolvedAt = Date.now();
    __otlobliChallengeNotified = false;
    if (typeof IS_SHEIN !== 'undefined' && IS_SHEIN && !__otlobliSheinFullPageChallenge) {
      try {
        if (typeof otlobliResetSheinReadinessAfterChallengeCommit === 'function') {
          otlobliResetSheinReadinessAfterChallengeCommit();
        }
      } catch (e) {}
    }
    if (!__otlobliChallengeResolvedNotified) {
      __otlobliChallengeResolvedNotified = true;
      try {
        if (window.mobileApp && window.mobileApp.postMessage) {
          window.mobileApp.postMessage({ detail: { type: 'humanCheckResolved', documentGeneration: String(window.__otlobliDocumentGeneration || '') } });
        }
      } catch (e) {}
    }
    return true;
  }

  function otlobliHideBackControlForHumanChallenge() {
    try {
      var pageBack = document.getElementById('otlobli-back-btn');
      if (pageBack && pageBack.parentNode) pageBack.parentNode.removeChild(pageBack);
    } catch (e) {}
    try {
      // Invalidate the last visible-state cache so normal maintenance republishes
      // the correct Back state only after the challenge settlement window.
      window.__otlobliNativeBackState = 'challenge-hidden';
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: {
          type: 'otlobliBackButtonState', visible: false, top: 12, target: 'home'
        } });
      }
    } catch (e) {}
  }

  function otlobliEnterChallengeMode() {
    var wasActive = otlobliChallengeActive;
    otlobliChallengeActive = true;
    try { window.__otlobliStoreNavigationChallengeLocked = true; } catch (e) {}
    __otlobliChallengeMissingSince = 0;
    __otlobliChallengeResolvedAt = 0;
    // Detection runs repeatedly while the provider repaints its widget. Enter
    // the protected state once; repeated positive scans only cancel a pending
    // absence window and must not re-disconnect policy observers or re-post.
    if (wasActive) return;
    __otlobliChallengeResolvedNotified = false;
    __otlobliSheinChallengeCommitCookieBefore = typeof IS_SHEIN !== 'undefined' && IS_SHEIN
      ? otlobliReadSheinChallengeCommitCookie()
      : null;
    __otlobliSheinChallengeCommitProof = false;
    __otlobliSheinFullPageChallenge = typeof IS_SHEIN !== 'undefined' && IS_SHEIN &&
      otlobliIsSheinFullPageChallenge(location.href);
    try {
      if (window.__otlobliSheinPolicyEngine && window.__otlobliSheinPolicyEngine.pause) {
        window.__otlobliSheinPolicyEngine.pause();
      }
    } catch (e) {}
    try { if (typeof otlobliSuspendSheinShippingProgressForChallenge === 'function') otlobliSuspendSheinShippingProgressForChallenge(); } catch (e) {}
    try { if (typeof otlobliSuspendProductCaptureForChallenge === 'function') otlobliSuspendProductCaptureForChallenge(); } catch (e) {}
    try { if (typeof otlobliSuspendTemuRuntimeForChallenge === 'function') otlobliSuspendTemuRuntimeForChallenge(); } catch (e) {}
    try {
      var baseStyle = document.getElementById('otlobli-base-style');
      if (baseStyle && baseStyle.parentNode) baseStyle.parentNode.removeChild(baseStyle);
    } catch (e) {}
    // Verification belongs entirely to the live store page. While its visible
    // challenge exists we pause Otlobli's region/blocking/capture work, but do
    // not persist a marker, remove UI, unlock drawers, or mutate body styles.
    otlobliHideBackControlForHumanChallenge();
    otlobliScheduleChallengeNav();
    if (!__otlobliChallengeNotified) {
      __otlobliChallengeNotified = true;
      try {
        if (window.mobileApp && window.mobileApp.postMessage) {
          window.mobileApp.postMessage({ detail: { type: 'humanCheck', documentGeneration: String(window.__otlobliDocumentGeneration || '') } });
        }
      } catch (e) {}
    }
  }
`
