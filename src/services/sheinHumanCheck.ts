// Runs inside the active store page. It only observes the store's own verification UI;
// it never clicks, solves, reloads, or changes the verification response.
export const OTLOBLI_SHEIN_HUMAN_CHECK_JS = `
  var __otlobliChallengeNotified = false;
  var __otlobliChallengeResolvedNotified = false;
  var otlobliChallengeActive = false;
  var __otlobliChallengeScanAt = 0;
  var __otlobliChallengeScanResult = false;

  function otlobliMatchesHumanChallengeText(value) {
    var text = String(value || '').replace(/\s+/g, ' ').trim().slice(0, 1600);
    if (!text) return false;
    return /verify (?:that )?you are (?:a )?human|human verification|security verification|checking your browser|confirm (?:that )?you are (?:a )?human|i(?:'|’)m (?:not a robot|human)|cloudflare|turnstile|التحقق من أنك إنسان|تحقق أنك إنسان|أنا إنسان|لست (?:إنساناً آلياً|روبوت(?:اً)?)|التحقق الأمني|التحقق من الأمان/i.test(text);
  }

  function otlobliIsHumanChallenge() {
    try {
      if (otlobliIsHumanChallengeUrl(location.href)) return true;
      if (/just a moment/i.test(document.title || '')) return true;
      var challengeNow = Date.now();
      var challengeScanGap = otlobliChallengeActive ? 600 : 1500;
      if (challengeNow - __otlobliChallengeScanAt < challengeScanGap) return __otlobliChallengeScanResult;
      __otlobliChallengeScanAt = challengeNow;
      if (document.getElementById('challenge-form')) return (__otlobliChallengeScanResult = true);
      if (document.querySelector('script[src*="challenges.cloudflare.com"],iframe[src*="challenges.cloudflare.com"]')) return (__otlobliChallengeScanResult = true);
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
        if (otlobliMatchesHumanChallengeText(surface.textContent || '')) return (__otlobliChallengeScanResult = true);
      }
    } catch (e) {}
    __otlobliChallengeScanResult = false;
    return __otlobliChallengeScanResult;
  }

  function otlobliResolveHumanChallenge() {
    if (!otlobliChallengeActive) return false;
    otlobliChallengeActive = false;
    __otlobliChallengeScanResult = false;
    __otlobliChallengeNotified = false;
    if (!__otlobliChallengeResolvedNotified) {
      __otlobliChallengeResolvedNotified = true;
      try {
        if (window.mobileApp && window.mobileApp.postMessage) {
          window.mobileApp.postMessage({ detail: { type: 'humanCheckResolved' } });
        }
      } catch (e) {}
    }
    return true;
  }

  function otlobliEnterChallengeMode() {
    otlobliChallengeActive = true;
    __otlobliChallengeResolvedNotified = false;
    // Verification belongs entirely to the live store page. While its visible
    // challenge exists we pause Otlobli's region/blocking/capture work, but do
    // not persist a marker, remove UI, unlock drawers, or mutate body styles.
    otlobliScheduleChallengeNav();
    if (!__otlobliChallengeNotified) {
      __otlobliChallengeNotified = true;
      try {
        if (window.mobileApp && window.mobileApp.postMessage) {
          window.mobileApp.postMessage({ detail: { type: 'humanCheck' } });
        }
      } catch (e) {}
    }
  }
`
