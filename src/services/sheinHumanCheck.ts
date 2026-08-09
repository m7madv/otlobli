// Runs inside SHEIN's page. It only observes the store's own verification UI;
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

  function otlobliIsHumanChallenge() {
    try {
      if (otlobliIsHumanChallengeUrl(location.href)) return true;
      if (/just a moment/i.test(document.title || '')) return true;
      var challengeNow = Date.now();
      if (!otlobliChallengeActive && challengeNow - __otlobliChallengeScanAt < 1500) return __otlobliChallengeScanResult;
      __otlobliChallengeScanAt = challengeNow;
      if (document.getElementById('challenge-form')) return (__otlobliChallengeScanResult = true);
      if (document.querySelector('script[src*="challenges.cloudflare.com"],iframe[src*="challenges.cloudflare.com"]')) return (__otlobliChallengeScanResult = true);
      var proprietaryChecks = document.querySelectorAll('.one-pass-dialog,#one-pass-custom,one-pass-custom,#nine-captcha-custom,nine-captcha-custom,.si-verify-block-request-dialog');
      for (var pi = 0; pi < proprietaryChecks.length; pi++) {
        if (sheinElementIsPainted(proprietaryChecks[pi])) return (__otlobliChallengeScanResult = true);
      }
      if (document.querySelector('[id*="challenge" i],[class*="challenge" i],[data-testid*="challenge" i]')) {
        var challengeText = document.body ? (document.body.textContent || '').slice(0, 3200) : '';
        if (/verify you are human|security verification|checking your browser|cloudflare|التحقق من أنك إنسان|أنا إنسان|لست روبوت|التحقق من الأمان/i.test(challengeText)) return (__otlobliChallengeScanResult = true);
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
      guide.innerHTML = '<strong style="display:block;font-size:13px;font-weight:800">تحقق SHEIN مطلوب لفتح المنتجات</strong><span style="display:block;margin-top:2px;font-size:12px">اضغط «أنا إنسان» داخل الصفحة للمتابعة، أو ارجع من الشريط بالأسفل.</span>';
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
    try { writeSheinSaudiState(); } catch (e) {}
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
