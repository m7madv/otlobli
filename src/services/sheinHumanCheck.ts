// Runs inside the active store page. It only observes the store's own verification UI;
// it never clicks, solves, reloads, or changes the verification response.
export const OTLOBLI_SHEIN_HUMAN_CHECK_JS = `
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
    var text = String(value || '').replace(/\s+/g, ' ').trim().slice(0, 1600);
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
    var text = String(document.body.innerText || document.body.textContent || '').replace(/\\s+/g, ' ').trim();
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
    // No region write here. Seeding 26 .shein.com cookies plus localStorage the
    // instant a challenge appears changes the session fingerprint between the
    // moment SHEIN issues its token and the moment it validates the answer, so
    // a correctly solved check comes back "Access timed out, please refresh the
    // page and try again". The rule already exists in ensureSheinSaudiStore()
    // ("ممنوع أي إعادة تحميل/كتابة أثناء التحقق") — this path was breaking it.
    // The Saudi state is written once the customer has finished, below.
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
`
