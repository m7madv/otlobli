import { OTLOBLI_SHEIN_HUMAN_CHECK_JS } from './sheinHumanCheck'

export const STORE_BLOCKING_SCRIPT = `
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
    // One below max - see the matching comment on #otlobli-overlay above,
    // same reasoning: never let this win a stacking tie against the nav bar.
    overlay.style.cssText = 'position:fixed;left:0;top:0;width:' + vp.width + 'px;height:' + vp.height + 'px;' +
      'background:#ffffff;z-index:2147483646;display:flex;align-items:center;justify-content:center;';
    overlay.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });
    overlay.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); }, true);
    var spinner = document.createElement('div');
    spinner.style.cssText = 'width:38px;height:38px;border-radius:50%;border:4px solid #d8efe4;' +
      'border-top-color:#006948;animation:otlobli-spin .8s linear infinite;';
    overlay.appendChild(spinner);
    document.body.appendChild(overlay);

    // Used to remove this after a flat 1100ms no matter what - on a slow
    // connection (the Syrian relay especially) the page is often still
    // mid-load well past that, so the spinner vanished early and left the
    // user staring at a half-rendered/blank page with nothing to indicate
    // it was still working. Now it waits for the real page-load signal
    // (with a short minimum so it doesn't just flash) and only force-closes
    // after 8s as a safety net for a page that never fires load at all.
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
      // translateZ forces GPU layer (Android scroll drift fix).
      // 74px + safe-area + 16px gap above the otlobli nav bar.
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
          // فاشلة-بأمان: لا نضيف قبل تأكيد كل بُعد مطلوب؛ أي شكّ → نطلب الاختيار.
          // نقرأ skuSelector الحقيقي: أي بُعد عدده>1 وبلا اختيار والزر مطوي → نفتح
          // الشيت وننتظر اختيار الزبون ثم نُكمل تلقائياً. (النص "4 Color, 1 Size"
          // يبقى بالـDOM خلف الشيت، فلا نعتمد عليه للتفريق.)
          var sku0 = otlobliTemuSku();
          var unmet0 = otlobliTemuUnmetDimResolved(sku0, null);
          if (unmet0) {
            var unmetMessage0 = unmet0.unavailableOnly
              ? 'هذا الخيار غير متوفر حالياً'
              : (unmet0.kind === 'color' ? 'حدد اللون أولاً' : (/موديل/i.test(unmet0.name) ? 'حدد الموديل أولاً' : 'حدد المقاس أولاً'));
            showMessage(btn, unmetMessage0);
            return;
          }
          // ب) منتج مخصص يحتاج صورة (بالكشف الصارم v58) → نُنبّه ونكمل الإضافة
          // (الصورة تُرفق في السلة).
          var persoChk = temuPersonalization();
          if (temuCustomRequirements(persoChk).needsPhoto) {
            showMessage(btn, 'أضف صورتك في السلة قبل إتمام الطلب');
          }
          // ج) منتج تخصيص نصّي (نقش اسم).
          if (persoChk.has && !persoChk.text) {
            if (persoChk.inputVisible) {
              // الحقل ظاهر وفارغ → نطلب الكتابة الآن
              showMessage(btn, 'اكتب النص/الاسم المطلوب أولاً');
              return;
            }
            // الحقل داخل الشيت أو مخفي → نُضيف للسلة مع hint (الاسم يُكتب في السلة)
            showMessage(btn, 'أضف الاسم/النص المطلوب في السلة قبل الدفع');
          }
          // نقرأ عدد الألوان والمقاسات من ملخّص المتغيّرات (أدق من عدّ الـpills).
          function temuFinalizeAdd() {
          var blockMsg = '';
          if (otlobliTemuRecentUnavailableTap()) blockMsg = 'هذا الخيار غير متوفر حالياً';
          // د) فيه ألوان متعددة لكن لم يُحدّد لون — لون وحيد يمرّ مباشرة.
          // يسري على منتجات التخصيص أيضاً (سوارة النقش لها ألوان يجب جذبها).
          // نقرة كرت صورة بلا اسم (أحذية/أجهزة) تُحتسب اختياراً عبر الـswatch.
          // بوابة الخيارات البنيوية (v85.8.40): مصدر الحقيقة هو skuSelector، لا
          // مسح نصوص الصفحة (الذي حجب منتجات بلا مقاس بسبب "قياسي: مجانًا").
          var skuGate = otlobliTemuSku();
          var swatchChosen = !!(window.__otlobliTemuColorSwatch && window.__otlobliTemuColorGid === temuGoodsId());
          var colorUnmet = otlobliTemuUnmetDimResolved(skuGate, 'color');
          if (colorUnmet) {
            if (colorUnmet.unavailableOnly) {
              blockMsg = 'هذا الخيار غير متوفر حالياً';
            }
            // نلتقط صورة كرت اللون المختار للسلة؛ وإن تعذّر تماماً = نحجب.
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
            // مقاس وحيد يُحدَّد تلقائياً؛ مقاس متعدد بلا اختيار → نطلب.
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
          // ز) السعر: لا نضيف بصفر/غير مقروء.
          if (!(temuPriceUsd() > 0)) {
            otlobliRemoveGateSpinner();
            showMessage(btn, 'تعذّر قراءة السعر — انتظر ثانية وحاول');
            return;
          }
          // و) كل شيء مؤكّد → نضيف. الطبقة الكاملة (showAddingOverlay) تتولى
          // من هنا فوراً - نزيل مؤشر التحقق المؤقت أولاً حتى لا يتعارضا.
          otlobliRemoveGateSpinner();
          addToCartFlow({ exists: false }, { exists: false });
          }
          // القرار فوري. طبقة الإضافة تظهر فقط بعد نجاح كل بوابات الخيارات.
          temuFinalizeAdd();
          return;
        }
        if (!IS_SHEIN) {
          addToCartFlow({ exists: false }, { exists: false });
          return;
        }
        // Keep a single SHEIN gate.  In particular, a Curvy quick-add form is
        // a separate product above the PDP; checking the PDP here first makes
        // the selected Curvy size unreachable.  addToCartFlow() resolves the
        // active quick-add form before it performs the ordinary PDP checks.
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

  // otlobli's own bottom nav, drawn inside this webview (a separate native layer
  // drifted out of sync on iOS and left a black gap); env(safe-area-inset-bottom)
  // handles the inset here. Inline-SVG icons, not emoji (emoji render unevenly).
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

  // Yield only for drawer content that is truly painted over the nav.
  function otlobliNavShouldYield(nav) {
    if (!IS_SHEIN || !document.body) return false;
    var navRect = nav.getBoundingClientRect();
    if (navRect.height <= 0) return false;
    // Geometry alone includes a backdrop behind our visible max-z bar.
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
    // Temu scrolls/repaints BODY as its application surface. A fixed child of
    // that surface can remain correct in the DOM yet disappear from WebKit's
    // async scrolling layer during a fast direction change. Keep Otlobli's
    // navigation as a sibling of BODY and give it an isolated paint layer.
    // This was verified against the live Temu DOM with repeated fast swipes.
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
      // iPhone 6/7/8/SE and Plus-class legacy devices have no home indicator
      // and top out at 414x736 CSS px. Modern iPhones are taller (812+ CSS px)
      // even if WKWebView reports env(safe-area-inset-bottom) as 0.
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

  function otlobliEnsureStoreSwitchHint(nav) {
    if (!nav || !nav.querySelector) return;
    var homeTab = nav.querySelector('[data-otlobli-nav-type="openHome"]');
    if (!homeTab) return;
    homeTab.setAttribute('aria-label', 'الرئيسية، اضغط مرتين بسرعة للعودة إلى اختيار المتجر');
    if (homeTab.querySelector('[data-otlobli-store-switch-hint="1"]')) return;
    var hint = document.createElement('span');
    hint.setAttribute('data-otlobli-store-switch-hint', '1');
    hint.style.cssText = 'font:700 10px/12px system-ui,-apple-system,sans-serif!important;margin-top:1px!important;color:#006948!important;white-space:nowrap!important;';
    hint.textContent = 'اضغط مرتين للتبديل';
    homeTab.appendChild(hint);
  }

  function ensureOtlobliNav() {
      // 12px يطابق خط شريط otlobli الحقيقي (0.76rem ≈ 12.2px) — كان 11px
      // فيبدو الشريطان مختلفين عند التنقل بين المتجر وبقية الشاشات.
    var existingNav = document.getElementById('otlobli-nav');
    if (existingNav) {
      if (existingNav.getAttribute('data-otlobli-nav-style') !== OTLOBLI_NAV_STYLE_VERSION) {
        existingNav.style.cssText = OTLOBLI_NAV_CSS;
        existingNav.setAttribute('data-otlobli-nav-style', OTLOBLI_NAV_STYLE_VERSION);
      }
      otlobliResetTemuNavContentOffset(existingNav);
      otlobliStabilizeTemuNavLayer(existingNav);
      otlobliEnsureStoreSwitchHint(existingNav);
      // Re-claim "last child of body": SHEIN keeps inserting nodes at our max
      // z-index, and on a tie the later sibling wins paint, so one could cover +
      // swallow taps on our nav (symptom: cart tab going dead). Throttle to ~2s -
      // moving a mounted node still reflows, and doing it every 300ms flickered.
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
    // Max z-index (appended last so it wins ties) above any SHEIN bottom bar,
    // mirroring otlobli's real .bottom-nav. safe-area floor = max(inset,16px):
    // Android can report 0 with a 3-button bar so taps land in the system strip
    // (native already shrinks WebView bounds via enabledSafeBottomMargin).
    // translateZ(0)/will-change forces a GPU layer (a plain fixed bar vanished
    // behind the Android system bar on scroll-up). direction:rtl ثابت ليبقى
    // ترتيب الأزرار نفسه على كل المتاجر (بدونه ينقلب على LTR مثل تيمو).
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
      // Without its own id, only the #otlobli-nav CONTAINER was recognized
      // as "ours" by the document click listener's otlobli-id guard - by the
      // time the walk reaches that far up, isQuickAddSubmitButton() had
      // ALREADY matched the cart tab's own text ("السلة" is literally in its
      // loose cart-keyword regex) and silently swallowed the click before
      // ever getting there. Confirmed real bug, not a guess: the cart tab's
      // own label defeats SHEIN's "quick add" button blocker, which exists
      // to silently eat listing-card mini cart buttons - ours looked like
      // one of those to it. Each tab needs its own otlobli-prefixed id so
      // that guard catches it at depth 0, before any of the is*() checks run.
      tab.id = 'otlobli-nav-tab-' + i;
      var isActiveTab = item.type === 'openHome';
      // Keep Flex for old WKWebView compatibility, but let each cell stretch
      // through the nav's real content box. A forced 74px button sat lower;
      // CSS Grid collapsed to content width on the user's older iPhone.
      // px ثابت (وليس rem) وخط محدّد صراحةً: بعض المتاجر (تيمو) تضبط خط جذر
      // ضخم فتصير وحدات rem والخط الموروث هائلة فيتشوّه الشريط - التثبيت بالـpx
      // يجعله بنفس مقاس وتصميم شي إن على كل المتاجر.
      tab.style.cssText = 'position:relative!important;flex:1 1 25%!important;width:25%!important;max-width:25%!important;' +
        'min-width:0!important;height:auto!important;min-height:0!important;align-self:stretch!important;border:0!important;' +
        'background:transparent!important;display:flex!important;flex-direction:column!important;align-items:center!important;' +
        'justify-content:center!important;padding:10px 0 0 0!important;margin:0!important;' +
        'box-sizing:border-box!important;font-size:12px!important;line-height:normal!important;font-weight:700!important;' +
        'font-family:system-ui,-apple-system,sans-serif!important;color:' + (isActiveTab ? '#006948' : '#3d4a42') + '!important;' +
        '-webkit-appearance:none!important;appearance:none!important;border-radius:0!important;box-shadow:none!important;' +
        'transform:none!important;transition:none!important;opacity:1!important;touch-action:manipulation!important;' +
        '-webkit-tap-highlight-color:transparent!important;';
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
    otlobliEnsureStoreSwitchHint(nav);
    otlobliResetTemuNavContentOffset(nav);
    if (IS_TEMU) otlobliStabilizeTemuNavLayer(nav);
    else (document.documentElement || document.body).appendChild(nav);
  }

  var __otlobliBackTarget = 'home';

  // history.back() is a SILENT no-op once the back stack is spent - the tap
  // registers and nothing moves (iPhone 6). A real navigation destroys this
  // context before the timer fires, so this can only catch a dead back.
  function otlobliBackOrLeave() {
    var f = location.href, h = sessionStorage.getItem('__otlobliHomePath') || '/';
    try { history.back(); } catch (e) {}
    setTimeout(function () { if (location.href === f) location.assign(location.origin + h); }, 900);
  }

  function ensureBackButton() {
    var temuSearchBack = IS_TEMU && otlobliTemuSearchBackActive();
    // Temu already owns product/category/search navigation. Otlobli supplies
    // only the missing root exit, avoiding a duplicate button on inner pages.
    // Keep SHEIN and cart-return behaviour unchanged.
    var storeHomeRoot = otlobliStoreHomeRoot();
    var shouldShow = __otlobliBackTarget === 'cart' || __otlobliBackTarget === 'orders' || IS_SHEIN
      || (IS_TEMU ? storeHomeRoot : (!storeHomeRoot || looksLikeProductPage()));
    var nativeBackAvailable = !!(window.webkit && window.webkit.messageHandlers
      && window.webkit.messageHandlers.messageHandler);
    var backTop = temuSearchBack ? 30 : ((IS_SHEIN && viewportSize().width <= 390) ? 58 : 12);

    // iOS already owns the one visible Back control above WKWebView. Creating,
    // styling and repeatedly reclaiming a second (hidden) button inside SHEIN
    // was unnecessary page DOM interference; N4 device isolation associated
    // that intervention with SHEIN's intermittent first-load system error.
    if (nativeBackAvailable) {
      var nativeBackTarget = __otlobliBackTarget === 'cart' || __otlobliBackTarget === 'orders'
        ? __otlobliBackTarget
        : ((IS_SHEIN || IS_TEMU) && storeHomeRoot ? 'exit' : 'home');
      var nativeState = (shouldShow ? '1:' : '0:') + backTop + ':' + nativeBackTarget;
      if (window.__otlobliNativeBackState !== nativeState) {
        window.__otlobliNativeBackState = nativeState;
        window.mobileApp.postMessage({ detail: {
          type: 'otlobliBackButtonState', visible: shouldShow, top: backTop, target: nativeBackTarget
        } });
      }
      var stalePageBack = document.getElementById('otlobli-back-btn');
      if (stalePageBack) stalePageBack.remove();
      return;
    }

    var btn = document.getElementById('otlobli-back-btn');
    if (!btn) {
      ensureShakeStyle();
      btn = document.createElement('button');
      btn.id = 'otlobli-back-btn';
      btn.setAttribute('aria-label', IS_TEMU ? 'العودة إلى اختيار المتجر' : 'رجوع');
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
        if (__otlobliBackTarget === 'orders') {
          try {
            if (window.mobileApp && window.mobileApp.postMessage) {
              window.mobileApp.postMessage({ detail: { type: 'backToOrders' } });
            }
          } catch (e) {}
          return;
        }
        // Gate on the home root, never on history.length: language and
        // verification redirects add entries that were never user navigation,
        // so a back() from the root can land on a half-finished check page.
        // Temu search is an overlay with no history entry - clearing the field
        // and firing input exits it; history.back there hung the screen.
        if (IS_TEMU && otlobliTemuSearchBackActive()) {
          otlobliTemuExitSearchMode();
        } else if (IS_SHEIN && storeHomeRoot) {
          try {
            if (window.mobileApp && window.mobileApp.postMessage) {
              window.mobileApp.postMessage({ detail: { type: 'requestStoreExit', store: 'shein' } });
            }
          } catch (e) {}
        } else if (IS_TEMU && storeHomeRoot) {
          try {
            if (window.mobileApp && window.mobileApp.postMessage) {
              window.mobileApp.postMessage({ detail: { type: 'closeStore' } });
            }
          } catch (e) {}
        } else if (!storeHomeRoot || looksLikeProductPage()) {
          otlobliBackOrLeave();
        }
      }, true);
      otlobliStabilizeBackOverlay(btn);
    }
    btn.style.setProperty('top', backTop + 'px', 'important');
    btn.style.display = shouldShow ? 'flex' : 'none';
    if (shouldShow) otlobliStabilizeBackOverlay(btn);
  }

  function isAddToCartText(el) {
    // Never read textContent from a product-page wrapper. On the measured
    // SHEIN 130872819 page some broad "add" class candidates contain almost
    // the complete document; flattening those subtrees every 650ms consumed
    // 81% of the page's sampled JavaScript time on the Note 8.
    var explicitLabel = (el.getAttribute && el.getAttribute('aria-label')) || el.value || '';
    var text = String(explicitLabel || ((el.childElementCount || 0) <= 6 ? el.textContent : '') || '').trim();
    if (!text || text.length > 60) return false;
    // The Arabic-only regex below is what was actually missing - SHEIN's
    // Jordan site (forced to Arabic above) labels this "أضف إلى عربة
    // التسوق"/"أضف للسلة", never the English text this previously only
    // matched, so the click interceptor never caught it and SHEIN's real
    // add-to-cart fired untouched (confirmed by a user screenshot showing
    // SHEIN's own "أضف إلى عربة التسوق بنجاح" success bar).
    return /add to (bag|cart)/i.test(text) || /أضف.*(عربة|السلة|للسلة|الحقيبة|التسوق)/.test(text);
  }

  function isAddToCartButton(el, event) {
    if (!el || el.nodeType !== 1 || !isAddToCartText(el)) return false;
    // Text on a large gallery/page wrapper must never be treated as a button.
    // Require the real compact interactive control and require the pointer to
    // actually be inside its painted rectangle.
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
    return /^(إضافة|أضف|تأكيد|اضافة|add|confirm)\b/i.test(text) || /عربة|السلة|التسوق|الحقيبة|bag|cart/i.test(text);
  }

  function looksLikeCartUrl(href) {
    if (!href) return false;
    return /\\/(cart|bag|checkout|order-confirm|payment)(\\b|[/?#.])/i.test(href);
  }

  function isCartLink(el) {
    if (el.id && el.id.indexOf('otlobli') === 0) return false;
    if (el.tagName === 'A' && looksLikeCartUrl(el.getAttribute('href') || el.href || '')) return true;
    var cls = ' ' + (el.className || '') + ' ';
    return /\\s(cart-icon|header-cart|j-header-cart|shopping-bag|bag-icon)\\s/i.test(cls);
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
    var text = ((el.textContent || '') + '').replace(/\\s+/g, ' ').trim();
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
      if (tag === 'FORM' || /(?:^|[-_\\s])(login|signin|sign-in|auth|phone|email)(?:$|[-_\\s])/.test(hint)) return true;
      node = node.parentElement;
      depth++;
    }
    return false;
  }

  // Block only the actual icon-only menu control on the first tap. SHEIN also
  // uses menu/nav class names on visible category links; treating those textual
  // links as hamburger buttons made the home page feel like a static image.
  // Region/currency/language settings remain protected by their explicit text.
  function isProtectedSheinControl(el) {
    if (!el || !el.getAttribute) return false;
    if (el.id && el.id.indexOf('otlobli') === 0) return false;
    if (otlobliIsSheinTopCategoryEl(el)) return false;
    // Country inside sign-in is the phone prefix selector, not store settings.
    // It and the form's Continue button must remain native and interactive.
    if (isSheinAuthControl(el)) return false;
    var tag = el.tagName;
    var interactive = tag === 'BUTTON' || tag === 'A' || el.getAttribute('role') === 'button' ||
      window.getComputedStyle(el).cursor === 'pointer';
    if (!interactive) return false;
    var shortText = (el.textContent || '').trim();
    var hint = ((el.className || '') + ' ' + (el.getAttribute('aria-label') || '') + ' ' +
      (el.getAttribute('title') || '') + ' ' + (shortText.length <= 40 ? shortText : '')).toLowerCase();
    // Currency/language/region are blocked wherever they appear - including by
    // the visible drawer-item text ("تغيير العملة"/"تغيير اللغة"), so even if
    // the hamburger drawer does manage to open, every dangerous item inside it
    // is dead on tap.
    if (/currency|العملة|عملة|\\bregion\\b|country|البلد|الدولة|language|اللغة|\\blang\\b|لغة|\\bsetting|تغيير العملة|تغيير اللغة/.test(hint)) return true;
    var menuHint = /hamburger|nav-?toggle|side-?menu|drawer|menu-?(btn|button|icon|toggle|bar)|\\bmenu\\b/.test(hint);
    if (menuHint && isIconOnlySheinControl(el)) {
      var rect = el.getBoundingClientRect();
      // Band widened to top<=220 because SHEIN's home page can push its header
      // down behind a top promo/app-install banner, putting the hamburger well
      // below the old top<=140 cutoff - which is exactly why blocking used to
      // only "wake up" after navigating to a product and back (that banner is
      // gone on the second visit).
      if (rect.top >= -10 && rect.top <= 220 && rect.width > 0 && rect.width <= 90 && rect.height > 0 && rect.height <= 90) return true;
    }
    return false;
  }

  document.addEventListener('click', function (event) {
    // ⚠️ تحذير دائم — ممنوع حذف هذا الحارس (خلل حقيقي أضاف منتجات لسلة
    // المستخدم بلا علمه، 2026-07-03): الفحوص أدناه لاعتراض أزرار شي إن وحدها،
    // وaddToCartFlow() تُستدعى هنا بلا حارس تيمو الصارم. بلا
    // "if (!IS_SHEIN) return;" كانت أي نقرة على تيمو تُصادف نص "أضف...السلة"
    // تُضيف المنتج بلا تحقق. أبقِ هذا السطر أولاً دائماً.
    if (!IS_SHEIN) return;
    var el = event.target;
    // A full-screen product gallery may be painted above a still-hit-testable
    // PDP action on older WKWebView. While that exact viewer is open, block
    // only dangerous underlying cart/wishlist controls and otherwise leave
    // the gallery's own tap/swipe/close behavior untouched.
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
      // The customer never needs SHEIN's country drawer: Otlobli owns the
      // fixed Saudi shipping context. Only a narrowly marked automatic click
      // may reach SHEIN's native handler; ordinary taps are swallowed silently.
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
        // Silently swallow - the user asked that tapping a listing-card cart /
        // quick-add do nothing at all (no message). These buttons are also
        // actively hidden by hideListingCardAddButtons, so this is just a
        // belt-and-suspenders fallback for any that slip through.
        event.preventDefault();
        event.stopPropagation();
        return;
      }
      if (isAddToCartButton(el, event)) {
        // Block SHEIN's own click handler from ever firing - otherwise it adds
        // the item to SHEIN's real bag and shows its own "added to bag" toast
        // alongside ours, which is exactly the native-cart usage we're trying
        // to prevent entirely.
        event.preventDefault();
        event.stopPropagation();
        if (!looksLikeProductPage()) {
          // Listing-card "quick add" (not the real product page). Capture from
          // its stripped-down popup is unreliable, so we never run it - and per
          // the user's request we now do this silently, with no message.
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

  // زر "البحث بالصورة" (الكاميرا) يجلس داخل شريط البحث بجانب حقل الإدخال،
  // وليس له اسم/تصنيف يحوي كلمات البحث، فكان يُحجب ويظهر كمربع أسود فارغ.
  // نعتبر أي أيقونة يحتوي أحد آبائها القريبين (حتى 3 مستويات) حقلَ إدخال
  // جزءاً من شريط البحث فلا نحجبها - هكذا تبقى الكاميرا ظاهرة دون الاعتماد
  // على اسمها، وتبقى بقية الأيقونات (خارج شريط البحث) محجوبة كما هي.
  function otlobliNearSearchInput(node) {
    var up = node;
    var hops = 0;
    while (up && hops < 4) {
      // حقل بحث حقيقي قريب (قد لا يكون input عادياً في صفحة البحث)
      if (up.querySelector && up.querySelector('input, textarea, [contenteditable="true"]')) return true;
      // أو حاوية صنفها يدل على شريط البحث - الكاميرا تجلس داخلها
      var c = (up.className && up.className.baseVal !== undefined) ? up.className.baseVal : (up.className || '');
      if (typeof c === 'string' && /search|بحث/i.test(c)) return true;
      up = up.parentElement;
      hops++;
    }
    return false;
  }
  // يجمع كل النصوص/سمات التعريف الدالة من عنصر وكل أبنائه (حتى 15 عنصراً):
  // aria-label، class، href/xlink:href، data-testid/id، ونص عنصر <title>
  // داخل svg. أيقونات تيمو غالباً SVG بلا أي تسمية على الزر الخارجي نفسه —
  // فالفحص السطحي (الزر وحده) يفوّت التسمية الحقيقية المدفونة في عنصر ابن.
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
  // زر "فتح صفحة البحث" المستقل — نفحص الزر وكل أبنائه (لا الزر وحده).
  function otlobliLooksLikeSearchTrigger(el) {
    return /search|بحث/i.test(otlobliCollectIdentityHints(el));
  }
  // أيقونات معروفة نريد حجبها فعلاً (سلة/حساب/قائمة/مفضلة/رسائل) — نفس
  // أسلوب فحص الأبناء المستخدم للبحث. الحجب الآن **إيجابي**: لا نحجب أي
  // أيقونة إلا لو تطابقت صراحة مع إحدى هذه الكلمات، بدل حجب كل شيء
  // والاستثناء بالتخمين (كان يُفوّت البحث لأنه أيضاً بلا تسمية أحياناً).
  var OTLOBLI_KNOWN_DISTRACTION = /cart|bag|basket|shopping|account|profile\b|\buser\b|\bme\b|menu|hamburger|categor|\bnav\b|wishlist|favorite|favourite|\bheart\b|message|inbox|notification|\bchat\b|سلة|السلة|عربة|حساب|حسابي|بروفايل|قائمة|التصنيفات|الأقسام|المفضلة|مفضلة|رسائل|الرسائل|إشعارات|اشعارات/i;
  function otlobliLooksLikeKnownDistraction(el) {
    return OTLOBLI_KNOWN_DISTRACTION.test(otlobliCollectIdentityHints(el));
  }

  function otlobliCompactText(text) {
    return ((text || '') + '').replace(/\\s+/g, ' ').trim();
  }

  function otlobliIsSheinTopCategoryText(text) {
    var t = otlobliCompactText(text);
    return /^(?:\u0643\u0644|\u0646\u0633\u0627\u0621|\u0631\u062c\u0627\u0644|\u0623\u0637\u0641\u0627\u0644|\u0627\u0637\u0641\u0627\u0644|\u0623\u062d\u062c\u0627\u0645 \u0643\u0628\u064a\u0631\u0629|\u0627\u062d\u062c\u0627\u0645 \u0643\u0628\u064a\u0631\u0629|\u0645\u0642\u0627\u0633\u0627\u062a \u0643\u0628\u064a\u0631\u0629|all|women|men|kids|children|curve|plus size)$/i.test(t);
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
    // Wider probe band than just the first ~50px - SHEIN's header height
    // varies by page (the home page's is noticeably taller than a product
    // page's), and a user screenshot showed the wishlist heart and hamburger
    // menu still visible/tappable on the home page because the old probe
    // rows never reached that low.
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
          // Not every clickable icon is a <button>/<a>/role="button" - sites
          // commonly wire a click handler straight onto a styled <div>/<span>
          // (SHEIN's own native-style "share" icon does exactly this). A
          // pointer cursor is a reliable cross-markup signal that an element
          // is meant to be tapped, so treat that as clickable too. As a last
          // resort, an icon-sized element that simply contains an svg/img
          // graphic (and nothing else interactive matched first) is almost
          // always meant to be tapped even with no clickability signal at all.
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

  // Visually hide any SHEIN cart icon/button wherever it shows up - header,
  // or the sticky "add to bag" action bar at the bottom of product pages.
  // Same point-probe + icon-size-cap safety pattern as hideExtraHeaderIcons:
  // walk up from a probed point only until the nearest clickable element,
  // and only touch it if it's actually icon-sized, never a big wrapping
  // container (that size cap is what keeps this safe, unlike the original
  // blind querySelectorAll('a,button') cart lockout that once tore a hole in
  // SHEIN's header).
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

  // Finds SHEIN's top header bar by markup + geometry instead of a fixed pixel
  // band. This is the fix for "blocking only works after I open a product and
  // come back": on the first home load SHEIN floats a promo / app-install
  // banner above the header, pushing the real header (and its hamburger) down
  // past the old fixed probe rows, so nothing matched until a second visit when
  // the banner was gone. Anchoring on the header element itself makes the icon
  // sweep work no matter how far down the banner shoves it.
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

  // Hides every small clickable icon inside SHEIN's header (hamburger, cart,
  // wishlist, inbox, etc.) EXCEPT the search box, anchored to the header
  // element so it works regardless of the header's vertical offset. The
  // hamburger is the real prize here: it opens SHEIN's region/currency/language
  // drawer, and a currency switch silently breaks our USD price capture.
  function hideSheinHeaderControls() {
    var header = findTopHeaderEl();
    if (!header) return;
    var els = header.querySelectorAll('button, a, [role="button"], [class*="icon" i], svg');
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.tagName === 'SVG' || el.tagName === 'svg') {
        // Promote a bare clickable <svg> icon to its nearest tappable wrapper.
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

  // Remove compact quick-add controls from listing cards.
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
      // Already hidden: skip before any geometry read. A rect read after a
      // style write forces one layout per iteration - see the perf guard doc.
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
      // Geometry is intentionally checked before text. Most broad selector
      // matches are large wrappers and can now exit without flattening their
      // full descendant text.
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

  // Now that the webview is full-screen (see browseShein in App.tsx),
  // SHEIN's own page can render its own persistent bottom tab bar AND its
  // sticky product-page action bar (wishlist + add-to-cart), both of which
  // used to be clipped off-screen in the old height-constrained webview -
  // a user screenshot showed the action bar peeking out from behind
  // otlobli's own floating buttons. Find and remove any of these outright
  // instead of just hoping otlobli's own overlays paint above them.
  var __otlobliBottomNavDebugCount = 0;
  var __otlobliBottomNavDeepScanAt = 0;

  function getElementText(el) {
    try { return (el.textContent || '').replace(/\\s+/g, ' ').trim(); } catch (e) {}
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

  // Hide only SHEIN's two confirmed first-order signup surfaces: the compact
  // 15%-off strip, or the newsletter panel with a real email field. These
  // compound checks prevent product discounts and the real auth form from
  // matching this rule.
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
    var offerPattern = /(?:get\\s*15\\s*%\\s*off|15\\s*%\\s*off|\\u0627\\u062d\\u0635\\u0644\\s+\\u0639\\u0644[\\u0649\\u064a]\\s+\\u062e\\u0635\\u0645\\s*15\\s*%|\\u062e\\u0635\\u0645\\s*15\\s*%)/i;
    var signupPattern = /(?:^|\\s)(?:register|sign\\s*up|join\\s*now|\\u062a\\u0633\\u062c\\u064a\\u0644|\\u0633\\u062c\\u0644)(?:\\s|$)/i;
    var newsletterPattern = /(?:exclusive\\s+offers|shein\\s+news|newsletter|unsubscribe|\\u0627\\u0644\\u0639\\u0631\\u0648\\u0636\\s+\\u0627\\u0644\\u062d\\u0635\\u0631\\u064a\\u0629|\\u0623\\u062e\\u0628\\u0627\\u0631\\s+shein|(?:\\u0625|\\u0627)\\u0644\\u063a\\u0627\\u0621\\s+\\u0627\\u0644\\u0627\\u0634\\u062a\\u0631\\u0627\\u0643)/i;
    var emailPattern = /(?:email|e-mail|\\u0627\\u0644\\u0628\\u0631\\u064a\\u062f\\s+\\u0627\\u0644(?:\\u0625|\\u0627)\\u0644\\u0643\\u062a\\u0631\\u0648\\u0646\\u064a|\\u0628\\u0631\\u064a\\u062f\\u0643\\s+\\u0627\\u0644(?:\\u0625|\\u0627)\\u0644\\u0643\\u062a\\u0631\\u0648\\u0646\\u064a)/i;
    var authPattern = /(?:sign\\s*in|log\\s*in|continue\\s+with|phone\\s+number|\\u062a\\u0633\\u062c\\u064a\\u0644\\s+\\u0627\\u0644\\u062f\\u062e\\u0648\\u0644|\\u0631\\u0642\\u0645\\s+\\u0627\\u0644\\u0645\\u0648\\u0628\\u0627\\u064a\\u0644|\\u0627\\u0644\\u0627\\u0633\\u062a\\u0645\\u0631\\u0627\\u0631\\s+\\u0628\\u062c\\u0648\\u062c\\u0644)/i;

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
        var text = String(current.textContent || '').replace(/\\s+/g, ' ').trim()
          .replace(/[\\u064B-\\u065F\\u0670]/g, '');
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

  // Dismiss only unsolicited sign-in dialogs that SHEIN floats over a product.
  // A real login route or a full account page is never modified, and no form
  // field is hidden. This keeps cookie choices from turning into a forced
  // account interruption while preserving user-initiated authentication.
  var __otlobliSheinLoginDismissAt = 0;
  function dismissSheinProductLoginPrompt() {
    if (!IS_SHEIN || !document.body || !looksLikeProductPage()) return;
    if (/(?:\\/user\\/login|\\/login|\\/signin|\\/sign-in|\\/auth)(?:[/?#]|$)/i.test(location.pathname + location.search)) return;
    var now = Date.now();
    if (now - __otlobliSheinLoginDismissAt < 900) return;
    __otlobliSheinLoginDismissAt = now;
    var vp = viewportSize();
    var authPattern = /(?:sign\\s*in|log\\s*in|continue\\s+with|email|phone\\s+number|\\u062a\\u0633\\u062c\\u064a\\u0644\\s+\\u0627\\u0644\\u062f\\u062e\\u0648\\u0644|\\u0627\\u0644\\u0627\\u0633\\u062a\\u0645\\u0631\\u0627\\u0631\\s+\\u0628|\\u0627\\u0644\\u0628\\u0631\\u064a\\u062f\\s+\\u0627\\u0644(?:\\u0625|\\u0627)\\u0644\\u0643\\u062a\\u0631\\u0648\\u0646\\u064a|\\u0631\\u0642\\u0645\\s+\\u0627\\u0644\\u0647\\u0627\\u062a\\u0641)/i;
    var cookiePattern = /cookies?|\\u0645\\u0644\\u0641\\u0627\\u062a \\u062a\\u0639\\u0631\\u064a\\u0641 \\u0627\\u0644\\u0627\\u0631\\u062a\\u0628\\u0627\\u0637/i;
    var closePattern = /^(?:close|dismiss|skip|not now|maybe later|later|\\u00d7|\\u2715|\\u2716|\\u0625\\u063a\\u0644\\u0627\\u0642|\\u0627\\u063a\\u0644\\u0627\\u0642|\\u062a\\u062e\\u0637\\u064a|\\u0644\\u064a\\u0633 \\u0627\\u0644\\u0622\\u0646|\\u0644\\u0627\\u062d\\u0642(?:\\u0627|\\u0627\\u064b))$/i;
    var candidates = document.querySelectorAll(
      '[role="dialog"],[aria-modal="true"],[class*="login"],[class*="signin"],[class*="sign-in"],[class*="modal"],[class*="popup"],[class*="drawer"]'
    );
    for (var ci = candidates.length - 1; ci >= 0; ci--) {
      var candidate = candidates[ci];
      if (!candidate || (candidate.id && candidate.id.indexOf('otlobli') === 0) || !sheinElementIsVisible(candidate)) continue;
      var rect = candidate.getBoundingClientRect();
      if (rect.width < vp.width * 0.55 || rect.height < 90 || rect.bottom < 60 || rect.top > vp.height - 60) continue;
      var text = getElementText(candidate).replace(/[\\u064B-\\u065F\\u0670]/g, '');
      if (!text || text.length > 1800 || !authPattern.test(text) || cookiePattern.test(text)) continue;
      var fields = candidate.querySelectorAll('input, select, textarea');
      if (!fields.length && !/continue\\s+with|\\u0627\\u0644\\u0627\\u0633\\u062a\\u0645\\u0631\\u0627\\u0631\\s+\\u0628/i.test(text)) continue;
      var controls = candidate.querySelectorAll('button, a, [role="button"]');
      var closeTarget = null;
      for (var bi = 0; bi < controls.length; bi++) {
        var control = controls[bi];
        if (!control || (control.id && control.id.indexOf('otlobli') === 0) || !sheinElementIsVisible(control)) continue;
        var label = String(control.innerText || control.textContent || control.getAttribute('aria-label') || control.getAttribute('title') || '')
          .replace(/\\s+/g, ' ').trim();
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

  // SHEIN can draw its own black "added successfully" toast over Otlobli's
  // nav after our capture completes. Hide only that exact compact success
  // message; the real product button and every other bottom action remain.
  var __otlobliCartToastGuardUntil = 0;
  var __otlobliCartToastProductKey = '';
  function hideSheinCartSuccessToast() {
    if (!IS_SHEIN || !document.body) return;
    var quickFooter = document.querySelector('.sui-drawer__open .bsc-quick-add-cart__footerBar');
    if (quickFooter) quickFooter.style.setProperty('display', 'none', 'important');
    // iPhone 6 can restore SHEIN's old black success bar as the product paints.
    // Arm this bounded guard on product entry, not only after Otlobli's add tap.
    var productMatch = location.pathname.match(/-p-(\\d+)/i);
    var productKey = productMatch ? productMatch[1] : '';
    if (!productKey) __otlobliCartToastProductKey = '';
    else if (productKey !== __otlobliCartToastProductKey) {
      __otlobliCartToastProductKey = productKey;
      __otlobliCartToastGuardUntil = Date.now() + 15000;
    }
    if (Date.now() > __otlobliCartToastGuardUntil) return;
    var vp = viewportSize();
    var successPattern = /added to (?:the )?(?:shopping )?(?:bag|cart) successfully|\\u0623\\u0636(?:\\u064a\\u0641|\\u0641)\\s+\\u0625\\u0644\\u0649\\s+(?:\\u0639\\u0631\\u0628\\u0629|\\u062d\\u0642\\u064a\\u0628\\u0629)\\s+\\u0627\\u0644\\u062a\\u0633\\u0648\\u0642\\s+\\u0628\\u0646\\u062c\\u0627\\u062d/i;

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
          .replace(/[\\u064B-\\u065F\\u0670]/g, '')
          .replace(/\\s+/g, ' ')
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

  ${OTLOBLI_SHEIN_HUMAN_CHECK_JS}

  var sheinBlockReported = false;
  function checkForSheinSecurityBlock() {
    if (sheinBlockReported) return;
    if (!document.body) return;
    // The carrier block page has more than eight *direct* children, so that
    // historical guard was invalid. It is still a small error document. A
    // real PDP with 900+ total elements is not the short carrier error and
    // must not pay for a body text flatten/layout every 1.6 seconds.
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
      if (!/^\\d{1,3}\\s*\\/\\s*\\d{1,3}$/.test(value)) continue;
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
    var text = String(el.innerText || el.textContent || '').replace(/\\s+/g, ' ').trim();
    if (text.length > 700 || /review|rating|comment|feedback|\\u0627\\u0644\\u062a\\u0642\\u064a\\u064a\\u0645|\\u0627\\u0644\\u062a\\u0639\\u0644\\u064a\\u0642/i.test(text) || !sheinViewerHasVisibleCounter(el, vp)) return false;
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

  // كشف عارض الصور بملء الشاشة في تيمو (Swipe Gallery Viewer).
  // عندما يكون مفتوحاً يخفي زرنا لأنه يغطي نفس المنطقة ويسبب نقرات خاطئة.
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

  // نقرة تلقائية على المقاس الوحيد لما تكون لوحة الخيارات مفتوحة.
  // يحلّ مشكلة منتجات "ONE SIZE" — تيمو تتطلب نقرة الزبون حتى لو خيار واحد.
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
    // تسجيل فقط — ممنوع .click() هنا نهائياً: النقر التلقائي كان يصيب أحياناً
    // رابطاً صُنّف خطأً كزر مقاس وحيد فيُبحر بالصفحة → شاشة بيضاء بعد دخول
    // المنتج مباشرة (وتعمل عند إعادة الدخول لأن هذا الحارس أعلاه يمنع التكرار).
    // نحن نلتقط البيانات فقط ولا نستخدم سلة تيمو، فلا حاجة لتحديث واجهتها.
    window.__otlobliTemuSize = t;
    window.__otlobliTemuSizeGid = temuGoodsId();
    __otlobliAutoSizeTs = now;
  }

  // يمنع النقر على أي <a href> حقيقي - هذا بالضبط سبّب شاشة بيضاء بعلة
  // سابقة موثّقة (temuAutoSelectSingleSize): عنصر صُنّف خطأً كزر اختيار
  // فكان في الحقيقة رابطاً، والنقر عليه أبحر بالصفحة كلياً. نفحص العنصر
  // وحتى 3 آباء (الحاضن قد يكون هو الرابط الفعلي لا الصورة/النص الداخلي).
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
  // إعادة اختيار اللون/المقاس تلقائياً عند فتح رابط محفوظ من السلة/الطلبات
  // (يحمل معاملات otlobli_color/otlobli_size - انظر otlobliBuildDeepLink).
  // ننقر فعلياً (لا مجرد تسجيل) لأن الهدف إظهار اختيار تيمو المرئي نفسه
  // (الحدّ/الصورة الرئيسية) لا فقط بيانات otlobli الداخلية. حارس أمان
  // صارم (otlobliSafeToClick) يمنع تكرار علة الشاشة البيضاء الموثّقة.
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
    // لا جدولة داخلية - tick() الرئيسي (كل 300ms) يستدعي هذه الدالة أصلاً
    // ويعيد المحاولة تلقائياً حتى انتهاء المحاولات أو النجاح (لا ازدواج).
  }


`
