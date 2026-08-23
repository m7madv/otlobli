export const TEMU_BROWSER_SCRIPT = `
  // وضع بحث تيمو: عندما يركّز المستخدم حقل البحث ويكتب، تعرض تيمو قائمة
  // اقتراحات أسفل الشريط. دوال إخفاء «كروم» تيمو تعمل كل tick وتخفي تدريجياً
  // عناصر أعلى الصفحة — فكانت تبتلع صفوف الاقتراحات (تظهر ثم تختفي بعد ثانية).
  // أثناء البحث نعلّق تلك الدوال تماماً (كما نعلّق فحوصاتنا أثناء تحدي شي إن)
  // فلا نلمس الاقتراحات، ونُظهر زر الرجوع ليخرج المستخدم من البحث.
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
  // وضع البحث نشط طالما لوحة الاقتراحات ظاهرة — لا فقط أثناء التركيز. حقل بحث
  // تيمو يحتفظ بقيمته والاقتراحات (overlay ._3KC0yZ4V، z-index 999) تبقى ظاهرة
  // حتى بعد إغلاق الكيبورد (blur). الاعتماد على activeElement وحده كان يُنهي وضع
  // البحث باكراً فتعود دوال الإخفاء وتبتلع الاقتراحات ويختفي زر الرجوع. نعتبره
  // نشطاً إذا كان حقل البحث مركّزاً أو يحمل قيمة.
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
          /^[‹›<>←→❮❯\u2039\u203a]$/.test(arrowText);
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
          /^[‹›<>←→❮❯\u2039\u203a]$/.test(txt);
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

  // يكشف صفحة بحث تيمو الفارغة (الناتجة عن حجب الإعلانات الذي يمنع تحميل
  // نتائج البحث) ويعرض رسالة توضيحية للمستخدم — يعمل مرة واحدة فقط لكل رحلة.
  var __otlobliSearchMsgShown = false;
  function detectEmptyTemuSearch() {
    if (__otlobliSearchMsgShown) return;
    // صفحة نتائج البحث فقط
    if (!/search/i.test(location.href) && !/search/i.test(location.pathname)) return;
    if (looksLikeProductPage()) return;
    // نتحقق بعد اكتمال التحميل
    if (document.readyState !== 'complete') return;
    // إذا وُجدت صور منتجات مرئية — الصفحة ليست فارغة
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

  // منع الزوم في تيمو: viewport بلا تكبير + إلغاء إيماءة القرصة + إلغاء
  // تكبير النقر المزدوج (touch-action). تُستدعى دورياً لأن تيمو SPA قد
  // تستبدل وسم الـviewport عند التنقل بين الصفحات.
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
        // إيماءة القرصة على iOS WKWebView — touch-action أعلاه يمنع تكبير
        // النقر المزدوج، وهذان يمنعان القرصة. لا نلمس touchend حتى لا نكسر
        // النقرات السريعة المتتالية (زر الكمية مثلاً).
        document.addEventListener('gesturestart', function (e) { e.preventDefault(); }, { passive: false });
        document.addEventListener('gesturechange', function (e) { e.preventDefault(); }, { passive: false });
      }
    } catch (e) {}
  }

  // CSS تُخفي أزرار هيدر تيمو (السلة/الحساب/الفئات، كلها .tab-d3nPD داخل
  // topTabContainer) + بانر "تسوّق مثل الملياردير". نطابق بالبادئة [class*=]
  // لأن لاحقة الأصناف عشوائية، وaria-label كطبقة احتياطية.
  // تحذير (v57): ممنوع إخفاء .downloadsWrapper كاملاً — شريط بحث الرئيسية
  // يسكن داخله على الأجهزة الفعلية (درس v35 المكرر في v53) فيختفي معه، ولا
  // منقذ بعد تعطيل killStorePopups لتيمو (سبب الوميض). نخفي .downloadUI فقط.
  var OTLOBLI_TEMU_HIDE_CSS =
    '[aria-label*="cart" i], [aria-label*="basket" i], [aria-label*="bag" i],' +
    '[aria-label*="account" i], [aria-label*="profile" i],' +
    '[aria-label*="سلة"], [aria-label*="عربة"], [aria-label*="حساب"],' +
    '[class*="downloadUI" i]' +
    '{ display: none !important; visibility: hidden !important; pointer-events: none !important; }' +
    // (v60) غلاف downloadsWrapper يبقى ظاهراً (يحوي البحث — درس v57)، لكن
    // بعد إخفاء بانر downloadUI تبقى حشوة/خلفية الغلاف فتظهر إطاراً أبيض
    // كبيراً حول البحث أحياناً — نصفّر تباعده دون إخفائه.
    '[class*="downloadsWrapper"]' +
    '{ padding: 0 !important; margin: 0 !important; min-height: 0 !important; box-shadow: none !important;' +
    ' background: transparent !important; border: 0 !important; border-radius: 0 !important; }' +
    // (v66-fix) لا نثبّت شريط البحث بـ position:fixed. التثبيت + خلفية #fff +
    // إعادة القياس/الوسم كل tick كان يُنتج مستطيلاً أبيض كبيراً ووميض «ياضي
    // ويطفي» أثناء التمرير (تيمو تُعيد بناء الهيدر فيُزال الوسم ثم يُعاد). نتركه
    // في التدفق الطبيعي ونكتفي بإبقائه ظاهراً بخلفية شفافة — أبسط وأثبت.
    '[data-otlobli-temu-search-shell="1"]' +
    '{ background: transparent !important; box-shadow: none !important; opacity: 1 !important;' +
    ' visibility: visible !important; pointer-events: auto !important; }' +
    'body:not([data-otlobli-temu-search-mode="1"]) [data-otlobli-temu-category-strip="1"]' +
    '{ display: flex !important; align-items: center !important; overflow-x: auto !important;' +
    ' -webkit-overflow-scrolling: touch !important; visibility: visible !important;' +
    ' opacity: 1 !important; pointer-events: auto !important; }' +
    // Live Temu account surfaces observed in WebKit/iPhone layout. Scoped to
    // non-account routes so a deliberate Temu account page can still render.
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

  // v85.8.26: Temu blocker reset. Do not style search, header, category rows,
  // downloadsWrapper, or product grids. Only hide account/cart/app/promo nodes.
  OTLOBLI_TEMU_HIDE_CSS =
    '[data-otlobli-temu-clean-hidden="1"],' +
    // Live iPhone Temu paints cart/account/category shortcut cells as hashed
    // tab-* children of topTabContainer. Hide that stable structural surface
    // at document-start so the icons never flash before the JS cleaner runs.
    'body:not([data-otlobli-temu-account-route="1"]) [class*="topTabContainer"] [class*="tab-"],' +
    '[aria-label*="cart" i], [aria-label*="basket" i], [aria-label*="shopping bag" i],' +
    '[aria-label*="account" i], [aria-label*="profile" i], [aria-label*="sign in" i],' +
    'a[href*="cart" i], a[href*="login" i], a[href*="signin" i], a[href*="account" i],' +
    // ⚠️ لا تُعِد [class*="appDownload"]/[class*="downloadApp"] أبداً: صنف Temu
    // "withAppDownload-1iFDH" يغلّف #main (الصفحة كلها) و"appDownload" جزء منه،
    // فكانا يطبّقان display:none+pointer-events:none على الصفحة بأكملها = شاشة
    // بيضاء، ثم بعد force-visible تُعاد رؤيتها لكنها تبقى مجمّدة "كأنها صورة"
    // (pointer-events:none باقٍ). البانر الفعلي صنفه downloadUI ويُحجب أدناه.
    '[class*="downloadUI" i], [class*="openApp" i]' +
    '{ display: none !important; visibility: hidden !important; opacity: 0 !important; pointer-events: none !important; }';
  // نحقن القاعدة في أبكر لحظة ممكنة (documentStart، قبل رسم أي شيء) لمنع أي
  // وميض للعناصر المخفية. لا نعتمد على flag لمرة واحدة، بل نفحص وجود <style>
  // فعلياً في كل استدعاء: لو أزالت تيمو عنصرنا أثناء إعادة بناء الصفحة (عند
  // فتح منتج والرجوع مثلاً) نعيد حقنه فوراً فلا يظهر المخفي أبداً. نستخدم
  // document.head إن وُجد وإلا document.documentElement (المتوفّر دائماً هذا
  // الوقت المبكر) فتُطبَّق القاعدة حتى قبل إنشاء <head>.
  function injectTemuHeaderHideCSS() {
    if (!IS_TEMU) return;
    // وضع اختبار "الحجب مطفأ" (زر لوحة التشخيص): نزيل CSS الحجب ولا نعيده.
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
  // حقن فوري لحظة تحميل السكربت (preShowScript يعمل عند documentStart) — هذا
  // هو ما يمنع ظهور الأزرار/البانر ولو لجزء من الثانية عند أول دخول للمتجر.
  try { injectTemuHeaderHideCSS(); } catch (e) {}

  // مراجعة ذاتية لِما حجبته otlobliCleanTemuBlockers: العنصر المحجوب يصير
  // rect=0 فيتخطّاه المنظّف ولا يُعاد فحصه أبداً — فأي حجب خاطئ يبقى دائماً.
  // على صفحة المنتج، regex الـpromo يطابق "خصم/شحن مجاني" فيحجب حاوية أثناء
  // الرندر قبل تحميل السعر (يفشل حارس السعر)، والنتيجة شاشة بيضاء دائمة تظهر
  // فيها الصورة ثم تبيضّ. نفحص المحتوى (يعمل رغم display:none) ونستعيد أي عنصر
  // صار محتوى منتج، ونُدرجه بقائمة بيضاء دائمة (data-otlobli-temu-keep) لمنع
  // وميض الحجب/الاستعادة المتكرّر الذي عطّل killStorePopups سابقاً.
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

  // شبكة أمان أخيرة ضد الشاشة البيضاء على منتجات محددة: تغطّي أي حجب خاطئ
  // مهما كانت الدالة أو بنية DOM (لا تعتمد على تخمين "أي عنصر هو المنتج").
  // المنطق: على صفحة منتج، إن لم تُوجد أي صورة منتج كبيرة **مرئية** في نطاق
  // المحتوى، لكن DOM يحوي محتوى منتج (صور/سعر) = أخفيناه خطأً → نستعيد كل ما
  // أخفيناه على تيمو. إن بقيت الصفحة فارغة رغم ذلك فـDOM كان فارغاً أصلاً =
  // فشل رندر من Temu لا حجب منّا (تشخيص ذاتي). العناصر المُستعادة تُوسم keep.
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

  // يقيس المحتوى المرئي/المخفي على صفحة منتج تيمو مرّة واحدة (يُعاد استخدامه
  // في التشخيص وإعادة التحميل التلقائي حتى لا يتكرّر المنطق).
  var __otlobliTemuVitalsCacheKey = '';
  var __otlobliTemuVitalsCacheAt = 0;
  var __otlobliTemuVitalsCache = null;
  function otlobliTemuProductVitals() {
    var cacheKey = (location.pathname || '') + (location.search || '');
    var now = Date.now();
    // Several product watchdogs consume the same measurement in one 300ms
    // coordinator pass. Share that result so a single tick never walks every
    // Temu image five separate times on the WebKit main thread.
    if (__otlobliTemuVitalsCache && __otlobliTemuVitalsCacheKey === cacheKey &&
        now - __otlobliTemuVitalsCacheAt < 240) return __otlobliTemuVitalsCache;
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
    __otlobliTemuVitalsCacheKey = cacheKey;
    __otlobliTemuVitalsCacheAt = now;
    __otlobliTemuVitalsCache = { domImg: domImg, visImg: visImg, hasPrice: hasPrice, domHasContent: domHasContent, state: state };
    return __otlobliTemuVitalsCache;
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
        var txt = (el.textContent || '').replace(/\\s+/g, ' ').trim();
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
          var txt = (el.textContent || '').replace(/\\s+/g, ' ').trim();
          if (/\\d/.test(txt)) return true;
        }
      }
    } catch (e) {}
    return false;
  }

  // ورقة دخول تيمو المصغّرة (فوق صفحة المنتج من السلة) قد تحمل عبارة دخول واحدة
  // فتفلت من بوابة الإشارتين ثم تبيّض الصفحة. نكتفي هنا بإشارة واحدة مؤكَّدة بحقل
  // هاتف/بريد/كلمة مرور أو زر تواصل اجتماعي ضمن نطاق كبير مرئي. بوابة فقط (تؤخّر
  // إظهار الـWebView، لا تحجب) فلا تسبّب شاشة بيضاء بذاتها.
  function otlobliTemuLoginSheetVisible() {
    try {
      var vp = viewportSize();
      var signInRe = /sign\\s*in|log\\s*in|continue\\s*with|تسجيل\\s*الدخول|سجّ?ل\\s*الدخول|تابع\\s*عبر|المتابعة\\s*عبر/i;
      var socialRe = /google|facebook|apple|whatsapp|continue\\s*with|المتابعة\\s*عبر|تابع\\s*عبر/i;
      var nodes = document.querySelectorAll('[role="dialog"],[aria-modal="true"],div,section,form');
      for (var i = 0; i < nodes.length && i < 400; i++) {
        var el = nodes[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (!sheinElementIsVisible(el)) continue;
        var r = el.getBoundingClientRect();
        if (r.width < Math.min(260, vp.width * 0.55) || r.height < 120) continue;
        if (r.bottom <= 90 || r.top >= vp.height - 120) continue;
        var txt = (el.textContent || '').replace(/\\s+/g, ' ').trim();
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
  // كم يجب أن يبقى محتوى المنتج ظاهراً بثبات قبل كشف الـWebView (بالمللي ثانية).
  var OTLOBLI_TEMU_STABLE_MS = 900;
  function otlobliPostTemuProductVisibleIfReady() {
    if (!IS_TEMU || !document.body) return;
    try {
      var now = Date.now();
      var key = temuGoodsId() + '|' + (location.href || '').split('#')[0];
      // أي حالة تنفي "الظهور المستقر" (ليست صفحة منتج، بحث، سطح حساب/دخول، أو لا
      // محتوى مرئي) تُصفّر المؤقّت — فلا تُحسب الرسمة العابرة التي ترتدّ عنها تيمو
      // إلى شاشة الدخول ثم البياض. هذا سبب «دخول لحظي ثم أبيض»: كانت البوابة تكشف
      // على أول رسمة قبل الارتداد.
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
      // بدأ الظهور لهذا المنتج: سجّل لحظته ولا تكشف بعد.
      if (__otlobliTemuVisibleSinceKey !== key) {
        __otlobliTemuVisibleSinceKey = key;
        __otlobliTemuVisibleSince = now;
        return;
      }
      // لم يمرّ زمن الثبات بعد — انتظر (لو ارتدّت تيمو سيُصفَّر المؤقّت أعلاه).
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

  // يختار مرساة محتوى المنتج (أول صورة تيمو في DOM، أو عنصر السعر).
  function otlobliTemuContentAnchor() {
    var imgs = document.querySelectorAll('img');
    for (var i = 0; i < imgs.length; i++) {
      var s = imgs[i].currentSrc || imgs[i].src || '';
      if (/kwcdn|temu/i.test(s)) return imgs[i];
    }
    try { return document.querySelector('[class*="curPrice" i]'); } catch (e) { return null; }
  }

  // يصعد من مرساة المحتوى ويجد أول سلف يُلغي الظهور (display:none/visibility/
  // opacity/حجم صفر) — يعيد وصفاً مقروءاً (وسم/صنف/السبب) للتشخيص.
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
          var cls = (((node.className || '') + '') || node.id || '').replace(/\\s+/g, '.').slice(0, 46);
          return (node.tagName || '?') + '.' + cls + ' ' + why;
        }
      } catch (e) {}
      node = node.parentElement; depth++;
    }
    return 'لا سلف مخفي';
  }

  // الشاشة البيضاء «محتوى مخفي»: DOM فيه منتج بلا شيء مرئي وليس الحجب من
  // attributes لدينا، بل سلف يُلغي ظهوره. نصعد من مرساة المحتوى ونفرض الظهور
  // بأنماط inline مهمة، ونوسمه keep حتى لا تعبث به الحاجبات.
  // مهم (v85.8.44): يفرض مرّة ثم **يتوقف** فور ظهور المحتوى (visImg>0) — لا
  // يُزيل ما فرضه أبداً. إزالة v85.8.42 كانت تُنشئ حلقة فرض/إزالة = وميض أبيض
  // سريع (الفرض نفسه هو ما يجعل المحتوى مرئياً، فإزالته تُخفيه ثانيةً فوراً).
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
  // يُزيل الأنماط القسرية التي أضافتها force-visible فور تعافي الصفحة، فتعود
  // تخطيطات وتفاعلات Temu (نقر الألوان/المقاسات) لحالتها الأصلية الطبيعية.
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

  // استعادة كل ما أخفيناه على تيمو + إزالة CSS الحجب الثابت — لوضع الاختبار
  // "الحجب مطفأ" (زر اللوحة): يثبت أو ينفي أن الحجب هو مخرّب الجذب.
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

  // يلتقط لقطة نظيفة من DOM منتج الجوّال الحقيقي (البنية فقط: وسوم/أصناف/سمات
  // aria-data/نص) لينسخها الزبون ويلصقها لي — فأبني مصنع اختبار محلي بـDOM
  // حقيقي بدل التخمين. ننظّف السكربت/الأنماط/الصور الطويلة ونضغط المسافات.
  function otlobliTemuDumpProductDom() {
    var root = document.body.cloneNode(true);
    // نزيل ما لا يفيد التحليل ويضخّم الحجم.
    var kill = root.querySelectorAll('script,style,noscript,link,meta,svg,path,canvas,iframe,[id^="otlobli"]');
    for (var i = 0; i < kill.length; i++) { if (kill[i].parentNode) kill[i].parentNode.removeChild(kill[i]); }
    // نقصّر src/srcset/style الطويلة (base64/روابط) ونُبقي الأصناف والسمات الدلالية.
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
    var html = root.innerHTML.replace(/>\\s+</g, '><').replace(/\\s{2,}/g, ' ');
    if (html.length > 120000) html = html.slice(0, 120000);
    var payload = 'URL: ' + location.href.split('?')[0] + '\\n' +
      'العنوان: ' + (document.title || '').slice(0, 80) + '\\n\\n' + html;
    // نسخ للحافظة مع بديل execCommand (أوثق داخل WebView).
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

  // إصلاح تلقائي لفشل رندر تيمو: إن بقيت صفحة المنتج فارغة بصرياً و DOM فارغ
  // فعلاً (لا محتوى مخفي — فذاك يتكفّل به watchdog) لأكثر من 3.5 ثانية = تيمو
  // لم ترسم الصفحة → نعيد تحميل الرابط مرّة واحدة (يُصلح غالباً فشل SPA).
  // Keep an honest loading state only while a new product route has no product
  // DOM at all. Viewport visibility is not page readiness: after scrolling,
  // the hero image and price legitimately leave the viewport. Once a product
  // was confirmed visible, never cover that same product later in its lifetime.
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

  // غطاء دخول المنتج (شكوى مستخدم): عند فتح منتج كانت أيقونات تيمو تظهر لحظةً
  // قبل أن يلحقها الحجب (المنظّف مقيّد بمهلة 1100/1800ms). الحل المطلوب صراحةً:
  // غطاء تحميل قصير يستر الصفحة، نشغّل تحته موجات حجب قسرية سريعة، ثم نرفعه —
  // فلا يرى الزبون العناصر المحجوبة إطلاقاً. مرة واحدة لكل رابط منتج.
  var __otlobliTemuCoverUrl = '';
  function otlobliTemuEntryCover() {
    if (window.__otlobliTemuHideOff) return; // وضع اختبار: الحجب مطفأ
    if (!looksLikeProductPage() || otlobliTemuSearchMode()) return;
    var url = (location.href || '').split('#')[0];
    if (__otlobliTemuCoverUrl === url) return;
    __otlobliTemuCoverUrl = url;
    // v85.8.68: never paint a full-page white cover on Temu product entry.
    // On real iPhones, a login/auth sheet can briefly mount before the PDP
    // content; covering that phase made the page look permanently blank if the
    // SPA delayed timers or mutated the URL. Run the same immediate cleanup
    // waves without putting an opaque layer above the product.
    try { otlobliCleanTemuBlockers(true); } catch (e) {}
    setTimeout(function () { try { otlobliCleanTemuBlockers(true); } catch (e) {} }, 260);
    setTimeout(function () { try { otlobliCleanTemuBlockers(true); } catch (e) {} }, 620);
  }

  var __otlobliTemuCleanBlockersTs = 0;
  function otlobliCleanTemuBlockers(force) {
    if (!IS_TEMU || !document.body) return;
    // Temu renders its real sign-in screen inside a generic .container.
    // The blocker cleaner used to classify that full-page form as an account
    // promo and hide it with important inline styles, leaving only a white
    // page after a product was gated to /login.html. Account routes are an
    // intentional destination: never clean them, and undo only styles that
    // this cleaner itself applied in case an SPA transition changed routes.
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
      var accountCartRe = /cart|basket|shopping\\s*bag|bag|account|profile|sign\\s*in|signin|login|log\\s*in|\u0633\u0644\u0629|\u0639\u0631\u0628\u0629|\u062d\u0633\u0627\u0628|\u062f\u062e\u0648\u0644|\u062a\u0633\u062c\u064a\u0644/i;
      var appRe = /download\\s*(the\\s*)?app|open\\s*app|get\\s*app|install\\s*app|app\\s*download|\u062a\u0637\u0628\u064a\u0642|\u062a\u0646\u0632\u064a\u0644|\u062d\u0645\u0644|\u0627\u0644\u062a\u0637\u0628\u064a\u0642/i;
      var promoRe = /coupon|voucher|offer|deal|promo|promotion|reward|spin|free\\s*gift|claim|flash\\s*sale|\u0642\u0633\u064a\u0645|\u0643\u0648\u0628\u0648\u0646|\u0639\u0631\u0636|\u0639\u0631\u0648\u0636|\u062e\u0635\u0645|\u0647\u062f\u064a\u0629|\u062c\u0627\u0626\u0632\u0629|\u0627\u0631\u0628\u062d|\u0634\u062d\u0646\\s*\u0645\u062c\u0627\u0646/i;

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
        // قائمة بيضاء دائمة: عنصر استعادته المراجعة الذاتية بعد حجب خاطئ — لا
        // يُحجب ثانيةً أبداً (يمنع دورة الحجب/الاستعادة والوميض المتكرّر).
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
        'a,button,[role="button"],[role="dialog"],[aria-modal="true"],' +
        '[class*="downloadUI" i],[class*="openApp" i],' +
        '[class*="coupon" i],[class*="voucher" i],[class*="promo" i],' +
        '[class*="wheel" i],[class*="spin" i],[class*="reward" i],[class*="gift" i],' +
        '[class*="popup" i],[class*="modal" i],[class*="dialog" i],[class*="overlay" i]'
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
        // على صفحة المنتج، "خصم/شحن مجاني/عرض" جزء طبيعي من كل منتج، فلا تكفي
        // وحدها لاعتبار العنصر عرضاً منبثقاً. نشترط كلمة عرض قوية (كوبون/عجلة
        // الحظ/اربح/هدية/جائزة...) — بدون هذا كان يُحجب محتوى المنتج فتبيضّ
        // الصفحة. الحساب/التطبيق يبقيان كما هما (ليسا محتوى منتج طبيعياً).
        if (promo && looksLikeProductPage() && !accountCart && !appInstall) {
          promo = /coupon|voucher|spin|free\\s*gift|lucky\\s*draw|claim|reward|قسيمة|كوبون|عجلة\\s*الحظ|اربح|هدية\\s*مجان|جائزة|الملياردير/i.test(hints);
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
        var semanticCartAccount = /(cart|basket|shopping\\s*bag|account|profile|sign\\s*in|login|\u0633\u0644\u0629|\u0639\u0631\u0628\u0629|\u062d\u0633\u0627\u0628|\u062f\u062e\u0648\u0644|\u062a\u0633\u062c\u064a\u0644)/i.test(hints);
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
        if (!/(account|profile|cart|basket|orders?|home|\u062d\u0633\u0627\u0628\u064a|\u0627\u0644\u0633\u0644\u0629|\u0637\u0644\u0628\u0627\u062a\u064a|\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629)/i.test(barText) &&
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

  // (v65) مُغلِق مهذّب لنافذة تسجيل دخول تيمو المنبثقة عند فتح منتج. لا يحجب
  // محتوى المنتج ولا يُسجّل الدخول — فقط يبحث عن نافذة تسجيل دخول عائمة
  // (position:fixed، تغطية كبيرة، نصّها يذكر تسجيل الدخول) وينقر زر الإغلاق
  // (× / إغلاق / aria-label) أو زر «لاحقاً/تخطّي» إن وُجد. محاولة واحدة كل
  // ظهور (علامة على النافذة) حتى لا نُكرر النقر. إن كانت شاشة تسجيل دخول
  // كاملة (تنقّل صفحة، لا نافذة) فلا نقدر إغلاقها — تلك سياسة تيمو للمنطقة.
  var __otlobliTemuLoginProbeTs = 0;
  function dismissTemuLoginPopup() {
    if (!IS_TEMU || !document.body) return;
    var now = Date.now();
    var searchMode = otlobliTemuSearchMode();
    if (now - __otlobliTemuLoginProbeTs < (searchMode ? 420 : 900)) return; // لا نفحص كل tick
    __otlobliTemuLoginProbeTs = now;
    var LOGIN_RE = /سجّ?ل\\s*الدخول|تسجيل\\s*الدخول|sign\\s*in|log\\s*in|continue\\s*with|تابع\\s*عبر|أنشئ\\s*حساب|create\\s*account|\u062a\u0633\u062c\u064a\u0644\\s*\u0627\u0644\u062f\u062e\u0648\u0644|\u0625\u0646\u0634\u0627\u0621\\s*\u062d\u0633\u0627\u0628|\u0627\u0644\u0631\u0635\u064a\u062f\\s*\u0627\u0644\u0627\u0626\u062a\u0645\u0627\u0646\u064a|\u0642\u0633\u0627\u0626\u0645|\u0637\u0644\u0628\u0627\u062a\u0643|\u0633\u062c\u0644\\s*\u0627\u0644\u062a\u0635\u0641\u062d|\u0627\u0644\u0639\u0646\u0627\u0648\u064a\u0646|\u062f\u0639\u0645\\s*\u0627\u0644\u0639\u0645\u0644\u0627\u0621/i;
    var CLOSE_RE = /^(?:×|✕|✖|x|close|إغلاق|اغلاق|تخطّ?ي|تخطي|skip|later|لاحقًا|لاحقا|ليس\\s*الآن|not\\s*now)$/i;
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
      // نافذة كبيرة تغطي جزءاً معتبراً من الشاشة (لا شريط صغير).
      if (r.width < vp.width * 0.55 || r.height < vp.height * (searchMode ? 0.22 : 0.35)) continue;
      var txt = (el.textContent || '');
      if (txt.length > (searchMode ? 1400 : 600) || (!LOGIN_RE.test(txt) && !otlobliTemuLooksLikeAccountPanelText(txt))) continue;
      if (searchMode && searchInputForPopup && el.contains && el.contains(searchInputForPopup)) continue;
      if (searchMode && el.querySelector && el.querySelector('input[type="search"], input[placeholder*="Search" i], input[placeholder*="بحث"], [role="searchbox"]')) continue;
      // حارس المنتج: لا نلمس طبقة فيها سعر/شبكة صور منتجات (قد تكون المنتج).
      if (!searchMode && temuContainsPrice(el)) continue;
      el.setAttribute('data-otlobli-login-handled', '1');
      // ابحث عن زر إغلاق/تخطّي داخلها وانقره.
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
      // إن لم نجد زر إغلاق واضحاً، ننقر خلفية النافذة (تُغلق أغلب النوافذ)
      // فقط إن كانت عائمة تغطي كامل الشاشة (backdrop).
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
        var bottomStoreAction = r.bottom > vp.height - 190 && (/(cart|bag|deal|offer|add to|login|sign in)/i.test(txt) || /rgb\\(255,\\s*(?:102|118|128|136|145|153|165),\\s*0\\)/i.test(cs.backgroundColor || ''));
        if (!fixedish && !topAppBanner) continue;
        if (topAppBanner || bottomLogin || bottomStoreAction) {
          // حارس البحث (v57): ممنوع حجب أي حاوية تضم شريط/حقل البحث — العلامة
          // data-otlobli-temu-hidden تمنع الاستعادة نهائياً (otlobliUnhideEl
          // يرفضها)، فحجب حاوية البحث هنا يعني اختفاءه بلا رجعة.
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
      if (/^\\/(?:jo\\/?)?\\.?$/.test(href) || href === '/') {
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
    return /sign\\s*in|log\\s*in|create\\s*account|orders?|coupons?|credit|settings|addresses?|support|best\\s*experience|تسجيل\\s*الدخول|سجل\\s*الدخول|إنشاء\\s*حساب|طلباتك|القسائم|العروض|الرصيد\\s*الائتماني|الإعدادات|العناوين|دعم\\s*العملاء|أفضل\\s*تجربة/i.test(text || '');
  }

  function otlobliTemuAccountRoute() {
    var path = (location.pathname || '').toLowerCase();
    var hash = (location.hash || '').toLowerCase();
    var route = path + ' ' + hash;
    var tokens = route.split(/[^a-z0-9]+/i);
    for (var i = 0; i < tokens.length; i++) {
      if (/^(account|login|signin|sign|profile|user|member|order|orders|coupon|credit|address)$/i.test(tokens[i] || '')) return true;
    }
    if (/[#?&](?:page|scene|tab|route)=(?:account|login|profile|user|orders?|coupon|credit|address)\\b/i.test(location.href || '')) return true;
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
    if (/sign\\s*in|log\\s*in|تسجيل\\s*الدخول|سجل\\s*الدخول/i.test(t)) score++;
    if (/create\\s*account|إنشاء\\s*حساب/i.test(t)) score++;
    if (/orders?|طلباتك/i.test(t)) score++;
    if (/coupons?|القسائم|العروض/i.test(t)) score++;
    if (/credit|الرصيد\\s*الائتماني/i.test(t)) score++;
    if (/settings|addresses?|support|الإعدادات|العناوين|دعم\\s*العملاء/i.test(t)) score++;
    if (/best\\s*experience|أفضل\\s*تجربة/i.test(t)) score++;
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
          (/best\\s*experience|أفضل\\s*تجربة|سجل\\s*الدخول/i.test(txt) || fixedish);
        var dropdown = (score >= 3 || exactClass) && r.top < Math.min(340, vp.height * 0.58) && r.height >= 35;
        if (!bottomLogin && !dropdown) continue;
        if (el.querySelector && el.querySelector('[class*="searchBar" i], input[type="search"], [role="searchbox"]')) {
          // Do not hide the header/search container itself. The account panel
          // lives as a sibling/child nearby, and narrower descendants match.
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
        var looksSheet = /available\\s+offers|service\\s+guarantee|free\\s+shipping|delivery\\s+guarantee|\u0627\u0644\u0639\u0631\u0648\u0636\\s+\u0627\u0644\u0645\u062a\u0648\u0641\u0631\u0629|\u0636\u0645\u0627\u0646\\s+\u0627\u0644\u062e\u062f\u0645\u0629|\u0627\u0644\u0634\u062d\u0646\\s+\u0645\u062c\u0627\u0646|\u0636\u0645\u0627\u0646\\s+\u0627\u0644\u062a\u0648\u0635\u064a\u0644|\u0644\u0645\u0627\u0630\u0627\\s+\u062a\u062e\u062a\u0627\u0631\\s+temu|\u0645\u062f\u0641\u0648\u0639\u0627\u062a\\s+\u0622\u0645\u0646\u0629/i.test(txt);
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

  // نستعيد العنصر نفسه فقط (لا آباء ولا أطفال): لوحة حساب تيمو تعيش داخل حاوية
  // الهيدر مخفيةً بـopacity:0، فتوسيع الاستعادة كان يفرض عليها الظهور فتقفز
  // الصفحة. يكفي ذلك لأن الإخفاء الثابت يستهدف .tab-d3nPD/.downloadUI فقط.
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
    var m3 = transformValue.match(/^matrix3d\\(([^)]+)\\)$/i);
    if (m3) {
      var p3 = m3[1].split(',');
      var y3 = parseFloat(p3[13]);
      return isFinite(y3) ? y3 : 0;
    }
    var m2 = transformValue.match(/^matrix\\(([^)]+)\\)$/i);
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
      // Only Temu's compact, fully painted top header. Never pin search
      // overlays, suggestions, dialogs, or off-screen copies of the input.
      if (rect.width < vp.width * 0.8 || rect.height < 30 || rect.height > 260 ||
          rect.top < -180 || rect.top > 170 || rect.bottom <= 0) return;
      if (!node.hasAttribute('data-otlobli-temu-original-transform')) {
        node.setAttribute('data-otlobli-temu-original-transform', node.style.transform || '');
        node.setAttribute('data-otlobli-temu-original-transition', node.style.transition || '');
      }
      // Temu centres this header with translateX(-50%) and changes only Y to
      // hide/show it while scrolling. The old fix replaced the whole transform
      // with translateY(0), losing that X centring and breaking half the page.
      // Preserve responsive X centring, but force Y to zero every tick. Temu
      // rewrites this transform while scrolling to hide the search/logo row.
      // If we only set it once, the row disappears again on the next scroll.
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
    // The first injected document is not a stable Home identity: Temu can
    // redirect /qa/ through another locale before the runtime is installed,
    // and its Home tab may later normalize the route again. Classify Temu's
    // actual root forms instead of comparing against that first saved path.
    var path = String(location.pathname || '/').replace(/\\/{2,}/g, '/').replace(/\\/+$/, '');
    if (!path) return true;
    return /^\\/[a-z]{2}(?:-[a-z]{2})?$/i.test(path);
  }

  function otlobliStoreHomeRoot() {
    return IS_TEMU ? otlobliTemuHomeLikeUrl() : looksLikeHomeRoot();
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
      // Keep the same shell after it is pinned. Its padding/geometry changes
      // intentionally, so re-running the ancestor heuristic could otherwise
      // walk inward on the next 120ms pass and make the field jump.
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
    // مراجعة ذاتية أولاً: أي طبقة أخفيناها ثم كبر محتواها لاحقاً = صفحة منتج
    // أُخفيت خطأً أثناء الرندر (طبقة انتقال SPA نصّها المبكر "خصم 77%" فقط
    // فطابقت ملف العرض الترويجي) → نُعيدها فوراً ونُدرجها بقائمة بيضاء دائمة.
    // هذا كان سبب الشاشة البيضاء عند دخول المنتجات.
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
    // نحجب فقط ما يبدو فعلاً عرضاً ترويجياً (كلمات مميّزة) - لا نحجب أي طبقة
    // كبيرة عمياءً، فلا نخفي محتوى المتجر ولا صفحة "تحقق أنك إنسان" (الكابتشا)
    // فتصير الشاشة بيضاء. النص المحدود يستبعد شبكات المنتجات.
    var PROMO = /spin|claim|reward|coupon|billionaire|incredible deals|free gift|lucky draw|congratulations|% ?off|تهانينا|عجلة الحظ|اربح|جائزة|خصم \\d|الملياردير|مجاناً.*احصل|احصل.*مجاناً/i;
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
      // شيت خيارات المنتج (موديل/مقاس/لون/كمية/أضف): نصّه يحوي "خصم 65%"
      // فيطابق ملف الإعلانات ويُحجب تاركاً الخلفية المعتمة فقط — "شاشة عتمة"
      // عند فتح "حدد الموديل". كلمات الشيت المميزة تحصّنه نهائياً.
      if (/الكمية|موديل|المقاس|مقاس|اللون|أضف|السلة|حدد/.test(txt)) continue;
      // حرّاس محتوى المنتج: طبقة فيها سعر أو حقل إدخال أو ≥3 صور منتجات
      // ليست عرضاً ترويجياً بل صفحة/شيت حقيقي — ممنوع حجبها.
      if ((el.querySelector && el.querySelector('input, textarea')) || temuContainsPrice(el)) continue;
      var kwc = 0, kimgs = el.querySelectorAll ? el.querySelectorAll('img') : [];
      for (var ki = 0; ki < kimgs.length && kwc < 3; ki++) {
        if (/kwcdn/i.test(kimgs[ki].currentSrc || kimgs[ki].src || '')) kwc++;
      }
      if (kwc >= 3) continue;
      el.setAttribute('data-otlobli-blocked', '1');
      el.style.setProperty('display', 'none', 'important');
    }
    // العروض المنبثقة تقفل تمرير الصفحة عادةً - نعيد تمكينه
    if (document.body) document.body.style.overflow = '';
    if (document.documentElement) document.documentElement.style.overflow = '';
    // بانر تثبيت التطبيق الأصلي (Smart App Banner) إن وُجد
    var appMeta = document.querySelector('meta[name="apple-itunes-app"]');
    if (appMeta && appMeta.parentNode) appMeta.parentNode.removeChild(appMeta);

    // بانرات نصّية مزعجة — عربي وإنجليزي معاً
    hideStoreBannerByText([
      'billionaire', 'incredible deals', 'shop like', 'open in the app',
      'sign in for the best', 'get the app', 'download the app',
      'الملياردير', 'تسوق مثل', 'احصل على التطبيق', 'تنزيل التطبيق',
    ], 110);

    if (IS_TEMU) {
      // منع الزوم نهائياً (قرصة الأصابع + النقر المزدوج) — تجربة تطبيق أصلي.
      ensureTemuNoZoom();
      // شريط التنقل السفلي الخاص بتيمو (حسابي/السلة/طلباتي/الرئيسية) — نخفيه
      // ليبقى شريط otlobli هو الوحيد الظاهر في الأسفل.
      var hiddenBarDiag = [];
      var allEls = document.querySelectorAll('div, nav, footer, ul');
      for (var nb = 0; nb < allEls.length; nb++) {
        var nv = allEls[nb];
        if (nv.id && nv.id.indexOf('otlobli') === 0) continue;
        if (nv.getAttribute && nv.getAttribute('data-otlobli-blocked')) continue;
        var nvTxt = (nv.textContent || '');
        // نفحص أن يحتوي كلمات التنقل السفلي لتيمو ويكون نصّه قصيراً
        if (!/حسابي|طلباتي|الرئيسية/.test(nvTxt) || nvTxt.length > 60) continue;
        var nvCs = window.getComputedStyle(nv);
        if (nvCs.position !== 'fixed') continue;
        var nvR = nv.getBoundingClientRect();
        if (nvR.top < vp.height * 0.7) continue; // لا بد أن يكون في أسفل الشاشة
        nv.setAttribute('data-otlobli-blocked', '1');
        nv.style.setProperty('display', 'none', 'important');
        hiddenBarDiag.push('[' + nvTxt.replace(/\\s+/g, ' ').slice(0, 70) + ']');
      }
      // شارة "عربة التسوق / شحن مجاني" الخضراء العائمة
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
      // أيقونات الحساب/السلة في رأس الصفحة (أعلى الشاشة) — نخفيها.
      // ثبت من تشخيص جهاز حقيقي: أيقونات تيمو غير دلالية إطلاقاً (أصناف
      // CSS معمّاة بلا معنى مثل "skeletonicon-39bt4" - بناء React بأصناف
      // مُولَّدة). أي مطابقة نصية/دلالية (aria-label/class/aria-selected)
      // عديمة الفائدة هنا بالكامل. الحل الوحيد الموثوق: **الموقع البصري**،
      // ثابت عبر كل الصفحات التي فحصناها: سلة/حساب/قائمة تتجمّع دائماً أقصى
      // يسار الهيدر (أول ~180px)، بينما شريط البحث أعرض بكثير ويبدأ لاحقاً.
      var hiddenIconDiag = [], visibleTopIconDiag = [];
      var LEFT_CLUSTER_MAX = 180;
      // حارس أداء: مسح كل div بالصفحة كل 120ms مكلف على صفحات تيمو الثقيلة
      // (شبكات منتجات ضخمة). نحدّه بـ~5 ثوانٍ بعد كل تنقّل صفحة فقط - كافٍ
      // لالتقاط الأيقونات حتى لو تأخر رندرها، بلا استمرار المسح للأبد.
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
          // ثبت من تشخيص جهاز حقيقي: صفحات المنتج تلتقط الأيقونات صح ضمن
          // 90px الأولى (3 مخفية + 2 محمية بمواقع صحيحة)، لكن الصفحة
          // الرئيسية صفر أيقونات - هيدرها على الأرجح أسفل قليلاً بسبب شريط
          // ترويجي أطول. نطاق أوسع (0-140) يغطي الحالتين بأمان (لا يزال
          // يستبعد بطاقات المنتجات الكبيرة عبر شرط الحجم 24-60px).
          var inTopBand = irAll.top >= 0 && irAll.top <= 140 && irAll.width > 0 && irAll.width <= 60 && irAll.height > 0 && irAll.height <= 60;
          if (!inTopBand) continue;
          // أيقونات الهيدر بلا نص مقروء (صورة/رمز فقط) - يستبعد شارات نصية
          // صغيرة صدفةً بنفس القياس (ثبت من تشخيص حقيقي: عناصر "subtitle/
          // splitline" داخل بطاقات العروض الترويجية بالصفحة الرئيسية).
          if (temuCleanText(ic.textContent).length > 0) continue;
          rawTopBandCount++;
          // ثبت من تشخيص جهاز حقيقي (ثابت عبر 4 منتجات مختلفة): 5 من كل 6
          // مرشّح كانوا يُرفضون سابقاً لاشتراط svg/img — أغلب أيقونات تيمو
          // تُرسم بصورة خلفية CSS (background-image) لا بعنصر svg/img فعلي.
          // لا نشترط محتوى بصري إطلاقاً الآن — الحجم والموقع (مربّع 24-60px
          // بأعلى الشاشة) كافيان للتمييز بمفردهما.
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
      // تيمو تطبيق صفحة واحدة (SPA) - التنقل بين المنتجات لا يعيد تحميل
      // الجافاسكربت، فعلم "ظهرت مرة" وحده كان يمنع اللوحة من الظهور ثانية
      // عند دخول منتج جديد، فيرى المستخدم بيانات صفحة قديمة ويظنّها الحالية.
      // نربط العلم بالرابط الحالي بدل تعليقه للأبد.
      if (window.__otlobliHideDiagUrl !== location.href) {
        window.__otlobliHideDiagUrl = location.href;
      }
      // قسم "معلومات عن Temu / خدمة العملاء / مركز الدعم / حماية الشراء" أسفل
      // صفحة المنتج (أزرار أكورديون + أيقونات تواصل اجتماعي + حقوق نشر) —
      // بطلب صريح من المستخدم: يُحجب بالكامل، لا نُبقي أي خيار منه ظاهراً.
      hideTemuFooterSection();
    }
  }
  // يحجب كتلة تذييل تيمو (معلومات المتجر/الدعم/الشروط) بإيجاد أضيق حاوية
  // تحوي 3 كلمات دالة على الأقل — أضيق تطابق (لا أول عنصر بترتيب DOM، الذي
  // قد يكون سلفاً واسعاً يبتلع الصفحة كلها لأن textContent تراكمي للأعلى).
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
      // حرّاس أمان: لا نحجب حاوية فيها بحث فعلي أو سعر منتج حقيقي.
      if ((el.querySelector && el.querySelector('input:not([type="hidden"])')) || temuContainsPrice(el)) continue;
      if (txt.length < bestLen) { best = el; bestLen = txt.length; }
    }
    if (best) {
      best.setAttribute('data-otlobli-blocked', '1');
      best.style.setProperty('display', 'none', 'important');
    }
  }
  // يخفي حاوية بانر نصّي على المتاجر غير شي إن بمطابقة عبارة قصيرة مميّزة،
  // ثم يصعد لأقرب حاوية عريضة (لكن ليست الصفحة كلها) ويخفيها.
  function hideStoreBannerByText(phrases, maxLen) {
    var vp = viewportSize();
    var onTemuAccountRoute = IS_TEMU && otlobliTemuAccountRoute();
    // حاوية تضم شريط البحث أو محتوى منتجات حقيقياً؟ لا يجوز إخفاؤها أبداً —
    // التسلّق كان يبتلع هيدر تيمو (البانر والبحث معاً) فيختفي البحث، وقد
    // يبتلع حاوية صفحة كاملة أثناء الرندر فتصير الشاشة بيضاء.
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
    var APP_RE = /(get\\s*(the\\s*)?app|open\\s*in\\s*(the\\s*)?app|download\\s*(the\\s*)?app|install\\s*(the\\s*)?app|app\\s*exclusive|\\u0627\\u062d\\u0635\\u0644|\\u062a\\u0637\\u0628\\u064a\\u0642|\\u062a\\u0646\\u0632\\u064a\\u0644)/i;
    // Never scan login/sign-in/dialog surfaces here. The previous broad scan
    // could remove the phone/email input while leaving SHEIN's Continue button,
    // producing the blank, non-working screen observed on the device.
    var nodes = document.querySelectorAll('div, section, aside, header, a, [role="banner"], [class*="app" i]');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (!el || el === document.body || el === document.documentElement) continue;
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.getAttribute && el.getAttribute('data-otlobli-blocked')) continue;
      var txt = (el.textContent || '').replace(/\\s+/g, ' ').trim();
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
        var ut = (up.textContent || '').replace(/\\s+/g, ' ').trim();
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
    var WHEEL_RE = /(spin|wheel|reward|claim|coupon|lucky|chance|prize|free\\s*gift|congratulations|SAR\\s*\\d|\\u062d\\u0631\\u0651?\\u0643|\\u0641\\u0631\\u0635\\u0629|\\u062c\\u0631\\u0628|\\u062a\\u062d\\u0635\\u0644|\\u062c\\u0627\\u0626\\u0632\\u0629|\\u0645\\u062c\\u0627\\u0646\\u064a|\\u062e\\u0635\\u0645)/i;
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
      var txt = (el.textContent || '').replace(/\\s+/g, ' ').trim();
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
        var ut = (up.textContent || '').replace(/\\s+/g, ' ').trim();
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



`
