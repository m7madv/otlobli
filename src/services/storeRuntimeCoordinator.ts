export const STORE_RUNTIME_COORDINATOR_SCRIPT = `
  var __otlobliLegacyTemuDiagnosticsCleaned = false;
  function otlobliGuardHumanChallenge() {
    if (!otlobliScriptEnabled('blocking')) return false;
    var humanChallengeNow = otlobliIsHumanChallenge();
    if (humanChallengeNow) {
      otlobliEnterChallengeMode();
      return true;
    }
    if (otlobliChallengeActive) {
      // Challenge widgets can briefly remove/recreate an iframe while loading
      // the next image. Requiring a stable absence prevents that transient gap
      // from consuming a queued product before the verification token exists.
      if (otlobliChallengeAbsenceIsStable(Date.now())) {
        otlobliResolveHumanChallenge();
      }
      return true;
    }
    if (__otlobliChallengeResolvedAt) {
      // The provider may remove its iframe just before clearance/session state
      // is committed. Finish the bounded settlement in an exclusive pass.
      if (otlobliChallengeSettlementIsStable(Date.now())) {
        otlobliFinishChallengeSettlement();
      }
      return true;
    }
    return false;
  }

  function tick(challengeAlreadyGuarded) {
    if (!document.body || document.hidden) return;
    // Verification owns the live document. Detect it before any Otlobli
    // scroll-lock healing, region work, viewport writes, or DOM blocking so a
    // challenge image/frame cannot be disturbed by our normal store runtime.
    if (!challengeAlreadyGuarded && otlobliGuardHumanChallenge()) return;
    challengeAlreadyGuarded = true;
    if (IS_TEMU) try { otlobliPostTemuPublicReadyIfStable(true); } catch (e) {}
    // Temu's page is already doing expensive async image/layout work while the
    // finger is down. Defer Otlobli's non-critical DOM scans until 320ms after
    // the gesture; the permanent native bar remains immediately responsive.
    if (IS_TEMU && otlobliInteractionActive()) return;
    if (otlobliScriptEnabled('blocking') && IS_SHEIN) ensureOtlobliBaseStyle();
    if (otlobliScriptEnabled('blocking')) otlobliHealOrphanScrollLock();
    if (otlobliScriptEnabled('session') && IS_SHEIN) sheinPrimeRegionRepairFromRoute();
    if (otlobliScriptEnabled('session') && IS_SHEIN) sheinClearStaleShippingLock();
    // Never compete with WebKit's async scrolling or delay a bottom-nav tap
    // with full-page scans. Region repair has its own small progress timer.
    if (otlobliScriptEnabled('session') && IS_SHEIN && otlobliInteractionActive() &&
        !sheinShippingBodyLockState && !sheinShippingUiLikelyOpen()) {
      if (window.__otlobliNativeNavigation !== true && otlobliScriptEnabled('navigationBar') &&
          !document.getElementById('otlobli-nav')) ensureOtlobliNav();
      if (sheinNativeCoverRepairActive) scheduleSheinShippingProgress(OTLOBLI_LOW_END ? 320 : 160);
      return;
    }
    if (otlobliScriptEnabled('session') && IS_SHEIN) ensureSheinSaudiShippingSelection(true);
    if (otlobliScriptEnabled('blocking') && IS_SHEIN) retrySheinFeedError();
    if (otlobliScriptEnabled('blocking')) ensureNoTextSelection(true);
    if (otlobliScriptEnabled('navigationViewport')) ensureViewportFitCover();
    if (otlobliScriptEnabled('session') && IS_SHEIN) ensureSheinSaudiStore();
    if (otlobliScriptEnabled('navigationBack')) ensureBackButton(true);
    if (window.__otlobliNativeNavigation !== true && otlobliScriptEnabled('navigationBar')) ensureOtlobliNav();
    // المتاجر غير شي إن (تيمو/ترينديول): تصفّح فقط - ننظّف العروض المنبثقة
    // المزعجة ولا نشغّل منطق الالتقاط/الحجب الخاص بشي إن (الذي قد يخرّب صفحاتهم).
    if (!IS_SHEIN) {
      if (IS_TEMU) {
        var temuSearching = otlobliTemuSearchMode();
        try { injectTemuHeaderHideCSS(true); } catch (e) {}
        try { ensureTemuNoZoom(); } catch (e) {}
        try { ensureTemuSearchTouchRepair(); } catch (e) {}
        try { otlobliSyncTemuSearchModeState(temuSearching); } catch (e) {}
        try { hideTemuSearchVisibleAccountCart(temuSearching); } catch (e) {}
        // غطاء دخول المنتج: يستر لحظة ظهور الأيقونات قبل حجبها (مرة لكل رابط).
        try { otlobliTemuEntryCover(); } catch (e) {}
        // أول شيء كل تِك: نستعيد أي محتوى منتج حجبه المنظّف خطأً (شاشة بيضاء).
        // غير مقيّد بمهلة المنظّف (1100ms) ليُصلح خلال ~300ms فيصير وميضاً قصيراً
        // لا شاشة بيضاء دائمة — والقائمة البيضاء تمنع تكرار الحجب بعدها.
        try { otlobliTemuRestoreCleanHidden(); } catch (e) {}
        // Product watchdogs are only a readiness path. Once this exact product
        // was confirmed, stop all image/layout rescans until its identity changes.
        var temuProductConfirmed = false;
        try { temuProductConfirmed = otlobliTemuCurrentProductConfirmed(); } catch (e) {}
        if (!temuProductConfirmed) {
          // شبكة أمان أخيرة: إن كانت صفحة المنتج فارغة بصرياً ومحتواها مخفيّ في
          // DOM، نستعيد كل ما أخفيناه (يغطّي المنتجات المحددة التي تفلت من أعلاه).
          try { otlobliTemuBlankPageRescue(); } catch (e) {}
          // إصلاح «محتوى مخفي»: يُجبر محتوى المنتج على الظهور مهما كان مصدر الحجب
          // (CSS ثابت منّا بالصنف، أو انهيار layout) — لا يعتمد على الـattributes.
          try { otlobliTemuForceProductVisible(); } catch (e) {}
          try { otlobliPostTemuProductVisibleIfReady(); } catch (e) {}
        }
        // نظّف أي بقايا للوحات تشخيص Temu القديمة من الجلسات المحفوظة.
        try { if (!__otlobliLegacyTemuDiagnosticsCleaned) {
          var __d1 = document.getElementById('otlobli-temu-diag'); if (__d1) __d1.remove();
          var __d2 = document.getElementById('otlobli-temu-urlprobe'); if (__d2) __d2.remove();
          __otlobliLegacyTemuDiagnosticsCleaned = true;
        } } catch (e) {}
        // إصلاح تلقائي محدود لفشل رندر تيمو عندما يكون DOM نفسه فارغاً.
        if (!temuProductConfirmed) {
          try { otlobliTemuBlankProductNotice(); } catch (e) {}
          try { otlobliTemuBlankPageAutoReload(); } catch (e) {}
        }
        // killStorePopups معطّلة لتيمو نهائياً (v57): أكّد اختبار المستخدم
        // (2026-07-10) أنها سبب وميض الشاشة الأبيض كل نصف ثانية — كانت تحجب
        // طبقة كبيرة تطابق PROMO ثم تعيدها المراجعة الذاتية، كل 300ms.
        // لا تُعِد تفعيلها لتيمو. بانر التنزيل يُحجب عبر OTLOBLI_TEMU_HIDE_CSS
        // الثابت (downloadUI فقط، وليس الغلاف downloadsWrapper الحاوي للبحث).
        // أثناء البحث: نوقف دوال إخفاء الكروم حتى لا تبتلع صفوف الاقتراحات.
        try {
          // Cheap anchor probe keeps the broad legacy popup scan off normal
          // listing ticks. Once its marked ancestor is hidden, skip it too.
          var temuWheelAnchor = document.querySelector(
            '[class*="turnable" i], [class*="diskitem" i], [class*="wheel" i], [class*="spin" i]'
          );
          if (temuWheelAnchor && !(temuWheelAnchor.closest && temuWheelAnchor.closest('[data-otlobli-blocked="1"]'))) {
            hideTemuSpinWheelPopup();
          }
        } catch (e) {}
        try { otlobliCleanTemuBlockers(); } catch (e) {}
        // Product guest chrome is narrower than the general blocker: retain
        // Temu's real account route and SKU dialog, but remove its compact
        // sign-in/purchase actions before exposing Otlobli's own cart button.
        try { hideTemuAccountSurfaces(); } catch (e) {}
        try { hideTemuNativeProductActions(); } catch (e) {}
        try { ensureAddToCartButton(true); } catch (e) {}
        try { detectEmptyTemuSearch(); } catch (e) {}
        return;
      }
      if (otlobliScriptEnabled('blocking')) try { killStorePopups(); } catch (e) {}
      return;
    }
    if (otlobliScriptEnabled('blocking')) ensureLoadingOverlay();
    if (otlobliScriptEnabled('blocking')) blockCartNavigation();
    if (otlobliScriptEnabled('blocking')) hideSheinCartSuccessToast();
    if (otlobliScriptEnabled('capture')) ensureAddToCartButton(true);
    if (otlobliScriptEnabled('blocking')) stabilizeSheinImageViewerChrome();
    if (otlobliScriptEnabled('blocking')) hideExtraHeaderIcons();
    if (otlobliScriptEnabled('blocking')) hideSheinCartIcons();
    if (otlobliScriptEnabled('blocking')) hideForeignBottomNav();
    if (otlobliScriptEnabled('blocking')) hideSheinSignupDiscountBanner();
    if (otlobliScriptEnabled('blocking')) dismissSheinProductLoginPrompt();
    if (otlobliScriptEnabled('blocking')) hideSheinAppInstallPrompts();
    // Readiness must be the final step. Previously it was posted before the
    // header/cart/listing/nav blockers below ran, so native code could reveal
    // a product for one or two seconds with raw SHEIN chrome still visible.
    if (otlobliScriptEnabled('session')) updateSheinNativeCoverState(true);
    // Must run after ensureBack/Nav/Add and after cover-state close attempts,
    // so Otlobli chrome cannot repaint over SHEIN's live shipping drawer.
    if (otlobliScriptEnabled('session')) stabilizeSheinShippingDrawerInteraction();
  }

  // Kept tight on purpose - every visible millisecond here is a window where
  // a SHEIN button/icon that's supposed to be hidden or blocked is instead
  // tappable, which is exactly the "nothing should ever be reachable, not
  // even briefly" requirement this whole hide/block system exists for.
  var tickScheduled = false;
  var otlobliInteractionUntil = 0;
  function markOtlobliInteraction() {
    if (otlobliChallengeActive) return;
    otlobliInteractionUntil = Date.now() + 320;
  }
  function otlobliInteractionActive() {
    return Date.now() < otlobliInteractionUntil;
  }
  document.addEventListener('pointerdown', markOtlobliInteraction, { capture: true, passive: true });
  document.addEventListener('touchstart', markOtlobliInteraction, { capture: true, passive: true });
  document.addEventListener('touchmove', markOtlobliInteraction, { capture: true, passive: true });
  document.addEventListener('scroll', markOtlobliInteraction, { capture: true, passive: true });
  if (otlobliScriptEnabled('capture')) document.addEventListener('click', function (event) {
    if (otlobliChallengeActive) return;
    sheinTrackSelectedSkuPrice(event);
  }, true);
  // Low-end (iPhone 6, 2 cores): our polling competes with Cloudflare's JS and
  // SHEIN's image decoding. Relax the hot intervals; iPhone 16 keeps the tight
  // ones. Never widen these past the documented values - see the perf guard.
  var OTLOBLI_LOW_END = typeof navigator !== 'undefined' && (
    (navigator.hardwareConcurrency || 4) <= 4 ||
    (navigator.deviceMemory && navigator.deviceMemory <= 4) ||
    /Android\\s(?:7|8|9|10)(?:\\D|$)/i.test(navigator.userAgent || '')
  );
  function scheduleTick() {
    sheinBlockReported = false;
    if (document.hidden) return;
    if (OTLOBLI_LOW_END) return;
    // Don't storm-tick on every Cloudflare DOM mutation during the challenge;
    // the 300ms interval still polls tick() to detect when it ends.
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

  // One coordinator owns all recurring work. The old runtime used four
  // permanent intervals plus a full-document MutationObserver, so a single
  // SHEIN repaint could enqueue overlapping scans. Due-times preserve the
  // proven blocker latency while keeping only one timer active.
  var OTLOBLI_MAIN_INTERVAL = OTLOBLI_LOW_END ? 650 : 300;
  var OTLOBLI_BLOCK_INTERVAL = OTLOBLI_LOW_END ? 650 : 120;
  var OTLOBLI_NAV_INTERVAL = OTLOBLI_LOW_END ? 2200 : 1200;
  var OTLOBLI_SECURITY_INTERVAL = OTLOBLI_LOW_END ? 1600 : 1000;
  var OTLOBLI_NATIVE_NAV = window.__otlobliNativeNavigation === true;
  var otlobliMainDue = 0;
  // Block/security passes are SHEIN-only. Keeping them in Temu's min-deadline
  // scheduler previously woke the thread every 120ms just to return early.
  var otlobliBlockDue = IS_SHEIN ? 0 : Infinity;
  var otlobliNavDue = OTLOBLI_NATIVE_NAV ? Infinity : 0;
  var otlobliSecurityDue = IS_SHEIN ? 0 : Infinity;
  var otlobliCoordinatorTimer = 0;

  function runOtlobliBlockers() {
    if (!otlobliScriptEnabled('blocking') || otlobliChallengeActive || !IS_SHEIN || otlobliInteractionActive()) return;
    hideKnownHeaderIconsByHint();
    hideSheinHeaderControls();
    hideListingCardAddButtons();
    hideSheinNativeProductAdd();
  }

  function runOtlobliNavigationMaintenance() {
    if (!otlobliScriptEnabled('navigationBar')) return;
    if (window.__otlobliNativeNavigation !== true &&
        (!otlobliInteractionActive() || !document.getElementById('otlobli-nav'))) ensureOtlobliNav();
    if (!IS_TEMU) return;
    if (otlobliInteractionActive()) return;
    injectTemuHeaderHideCSS(true);
    ensureTemuSearchTouchRepair();
    var intervalTemuSearching = otlobliTemuSearchMode();
    otlobliSyncTemuSearchModeState(intervalTemuSearching);
    try { hideTemuSearchVisibleAccountCart(intervalTemuSearching); } catch (e) {}
    // Header icons are suppressed by document-start CSS. Do not force a broad
    // blocker scan from the navigation cadence; the throttled main pass still
    // handles semantic popup fallbacks without competing with scrolling.
  }

  function scheduleOtlobliCoordinator() {
    clearTimeout(otlobliCoordinatorTimer);
    var nextDue = Math.min(otlobliMainDue, otlobliBlockDue, otlobliNavDue, otlobliSecurityDue);
    otlobliCoordinatorTimer = setTimeout(runOtlobliCoordinator, Math.max(40, nextDue - Date.now()));
  }

  function runOtlobliCoordinator() {
    var now = Date.now();
    if (document.hidden) {
      // No background polling. visibilitychange below re-arms all due-times
      // when the document becomes visible again.
      clearTimeout(otlobliCoordinatorTimer);
      otlobliCoordinatorTimer = 0;
      return;
    }
    // Every wake that could run a DOM-mutating pass performs a fresh challenge
    // guard first. This is deliberately independent from otlobliMainDue: the
    // blocker cadence is tighter than the main cadence, and a challenge can be
    // mounted by an SPA between them without a URL change.
    if (otlobliGuardHumanChallenge()) {
      var challengeGuardFinished = !otlobliChallengeActive && !__otlobliChallengeResolvedAt;
      otlobliMainDue = challengeGuardFinished ? 0 : now + OTLOBLI_MAIN_INTERVAL;
      otlobliBlockDue = IS_SHEIN ? now + OTLOBLI_MAIN_INTERVAL : Infinity;
      otlobliNavDue = OTLOBLI_NATIVE_NAV ? Infinity : now + OTLOBLI_NAV_INTERVAL;
      otlobliSecurityDue = IS_SHEIN ? now + OTLOBLI_MAIN_INTERVAL : Infinity;
      scheduleOtlobliCoordinator();
      return;
    }
    if (IS_TEMU) window.__otlobliTemuDocumentStartPaused = false;
    // The main pass owns challenge detection and must always precede every
    // blocker/security pass. Otherwise a newly-mounted SPA challenge could be
    // touched once by stale product-page blockers before tick() enters the
    // no-intervention verification state.
    if (now >= otlobliMainDue) {
      tick(true);
      otlobliMainDue = now + OTLOBLI_MAIN_INTERVAL;
      if (otlobliChallengeActive || __otlobliChallengeResolvedAt) {
        otlobliBlockDue = IS_SHEIN ? now + OTLOBLI_MAIN_INTERVAL : Infinity;
        otlobliSecurityDue = IS_SHEIN ? now + OTLOBLI_MAIN_INTERVAL : Infinity;
        scheduleOtlobliCoordinator();
        return;
      }
    }
    if (now >= otlobliBlockDue) {
      runOtlobliBlockers();
      otlobliBlockDue = now + OTLOBLI_BLOCK_INTERVAL;
    }
    if (now >= otlobliNavDue) {
      runOtlobliNavigationMaintenance();
      otlobliNavDue = now + OTLOBLI_NAV_INTERVAL;
    }
    if (now >= otlobliSecurityDue) {
      if (otlobliScriptEnabled('blocking') && IS_SHEIN && !otlobliChallengeActive &&
          !otlobliInteractionActive()) checkForSheinSecurityBlock();
      otlobliSecurityDue = now + OTLOBLI_SECURITY_INTERVAL;
    }
    scheduleOtlobliCoordinator();
  }

  document.addEventListener('visibilitychange', function () {
    if (document.hidden) return;
    otlobliMainDue = 0;
    otlobliBlockDue = IS_SHEIN ? 0 : Infinity;
    otlobliSecurityDue = IS_SHEIN ? 0 : Infinity;
    otlobliNavDue = OTLOBLI_NATIVE_NAV ? Infinity : 0;
    runOtlobliCoordinator();
  }, false);
  runOtlobliCoordinator();
`
