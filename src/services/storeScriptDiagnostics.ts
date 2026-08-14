export type StoreScriptFlags = {
  runtime: boolean
  navigation: boolean
  blocking: boolean
  capture: boolean
  session: boolean
}

export const DEFAULT_STORE_SCRIPT_FLAGS: StoreScriptFlags = {
  runtime: true,
  navigation: true,
  blocking: true,
  capture: true,
  session: true,
}

export const normalizeStoreScriptFlags = (value: unknown): StoreScriptFlags => {
  const candidate = value && typeof value === 'object' ? value as Record<string, unknown> : {}
  return {
    runtime: candidate.runtime !== false,
    navigation: candidate.navigation !== false,
    blocking: candidate.blocking !== false,
    capture: candidate.capture !== false,
    session: candidate.session !== false,
  }
}

// Diagnostic-build only. The control stays outside the normal store runtime,
// so it remains available even when every Otlobli feature is disabled. Each
// change is sent to the host, which recreates one WebView without clearing the
// store's cookies or website data; this gives every comparison a clean runtime
// while preserving the customer's genuine SHEIN session.
export const STORE_SCRIPT_DIAGNOSTICS_PANEL_SCRIPT = `
(function () {
  if (window.top !== window || window.__otlobliScriptDiagnosticsMounted) return;
  window.__otlobliScriptDiagnosticsMounted = true;

  var defaults = { runtime: true, navigation: true, blocking: true, capture: true, session: true };
  var source = window.__OTLOBLI_SCRIPT_FLAGS__ || defaults;
  var flags = {
    runtime: source.runtime !== false,
    navigation: source.navigation !== false,
    blocking: source.blocking !== false,
    capture: source.capture !== false,
    session: source.session !== false
  };
  window.__OTLOBLI_SCRIPT_FLAGS__ = flags;

  function post(detail) {
    try {
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: detail });
      }
    } catch (e) {}
  }

  function reportPaintedStore() {
    if (/shein/i.test(location.hostname)) post({ type: 'sheinPageInteractive', diagnostic: true });
    else if (/temu/i.test(location.hostname)) post({ type: 'temuProductVisible', diagnostic: true, url: location.href });
  }

  function mount() {
    if (!document.body || document.getElementById('otlobli-script-diagnostics')) return;
    var style = document.createElement('style');
    style.id = 'otlobli-script-diagnostics-style';
    style.textContent =
      '#otlobli-script-diagnostics,#otlobli-script-diagnostics *{box-sizing:border-box;font-family:Cairo,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}' +
      '#otlobli-script-diagnostics-trigger{position:fixed;left:0;top:44%;z-index:2147483647;width:50px;min-height:48px;border:1px solid #b8cec2;border-left:0;border-radius:0 14px 14px 0;background:#073f32;color:#fff;font-size:12px;font-weight:800;box-shadow:0 8px 24px rgba(4,38,30,.24);touch-action:manipulation;-webkit-tap-highlight-color:rgba(255,255,255,.18)}' +
      '#otlobli-script-diagnostics[data-open="1"] #otlobli-script-diagnostics-trigger{opacity:0;pointer-events:none}' +
      '#otlobli-script-diagnostics-trigger:focus-visible,#otlobli-script-diagnostics button:focus-visible{outline:3px solid #f6b84b;outline-offset:2px}' +
      '#otlobli-script-diagnostics-backdrop{position:fixed;inset:0;z-index:2147483645;border:0;background:rgba(5,22,18,.44);opacity:0;pointer-events:none;transition:opacity .16s ease;touch-action:manipulation;-webkit-tap-highlight-color:transparent}' +
      '#otlobli-script-diagnostics-panel{position:fixed;z-index:2147483646;left:0;top:0;bottom:0;width:min(88vw,350px);padding:max(18px,env(safe-area-inset-top)) 16px max(18px,env(safe-area-inset-bottom));background:#f7faf8;color:#14251f;box-shadow:18px 0 48px rgba(5,31,24,.22);transform:translateX(-104%);transition:transform .18s ease;overflow-y:auto;overscroll-behavior:contain;direction:rtl;text-align:right}' +
      '#otlobli-script-diagnostics[data-open="1"] #otlobli-script-diagnostics-backdrop{opacity:1;pointer-events:auto}' +
      '#otlobli-script-diagnostics[data-open="1"] #otlobli-script-diagnostics-panel{transform:translateX(0)}' +
      '#otlobli-script-diagnostics-head{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:8px}' +
      '#otlobli-script-diagnostics h2{margin:0;font-size:18px;line-height:1.35;text-wrap:balance}' +
      '#otlobli-script-diagnostics-copy{margin:0 0 14px;color:#53655e;font-size:12px;line-height:1.65}' +
      '#otlobli-script-diagnostics-close{width:42px;height:42px;flex:0 0 42px;border:1px solid #cad8d1;border-radius:12px;background:#fff;color:#173b30;font-size:24px;line-height:1;touch-action:manipulation}' +
      '#otlobli-script-diagnostics-presets{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:0 0 12px}' +
      '#otlobli-script-diagnostics-presets button,#otlobli-script-diagnostics-exit{min-height:44px;border:1px solid #b9cec3;border-radius:12px;background:#fff;color:#0a5d45;font-size:13px;font-weight:800;touch-action:manipulation}' +
      '#otlobli-script-diagnostics-list{display:grid;gap:8px}' +
      '.otlobli-script-diagnostic-row{width:100%;min-height:68px;display:flex;align-items:center;justify-content:space-between;gap:12px;border:1px solid #d5e0da;border-radius:14px;padding:10px 12px;background:#fff;color:#182a24;text-align:right;touch-action:manipulation}' +
      '.otlobli-script-diagnostic-row span:first-child{display:grid;gap:3px;min-width:0}' +
      '.otlobli-script-diagnostic-row b{font-size:13px;line-height:1.4}' +
      '.otlobli-script-diagnostic-row small{color:#65756f;font-size:11px;line-height:1.45;overflow-wrap:anywhere}' +
      '.otlobli-script-diagnostic-toggle{position:relative;width:46px;height:27px;flex:0 0 46px;border-radius:999px;background:#b8c5bf;box-shadow:inset 0 0 0 1px rgba(0,0,0,.05)}' +
      '.otlobli-script-diagnostic-toggle:after{content:"";position:absolute;top:3px;left:3px;width:21px;height:21px;border-radius:50%;background:#fff;box-shadow:0 2px 5px rgba(0,0,0,.2);transform:translateX(0);transition:transform .14s ease}' +
      '.otlobli-script-diagnostic-row[aria-checked="true"] .otlobli-script-diagnostic-toggle{background:#087453}' +
      '.otlobli-script-diagnostic-row[aria-checked="true"] .otlobli-script-diagnostic-toggle:after{transform:translateX(19px)}' +
      '#otlobli-script-diagnostics-status{min-height:38px;margin:12px 0 8px;padding:9px 11px;border-radius:11px;background:#e9f2ed;color:#285345;font-size:12px;line-height:1.55}' +
      '#otlobli-script-diagnostics-exit{width:100%;color:#7e3028;border-color:#e3c7c2}' +
      '#otlobli-script-diagnostics button:active{background-color:#e8f2ed}' +
      '@media(hover:hover){#otlobli-script-diagnostics button:hover{background-color:#edf5f1}}' +
      '@media(prefers-reduced-motion:reduce){#otlobli-script-diagnostics-backdrop,#otlobli-script-diagnostics-panel,.otlobli-script-diagnostic-toggle:after{transition:none}}';
    (document.head || document.documentElement).appendChild(style);

    var root = document.createElement('div');
    root.id = 'otlobli-script-diagnostics';
    root.setAttribute('data-open', '0');

    var trigger = document.createElement('button');
    trigger.id = 'otlobli-script-diagnostics-trigger';
    trigger.type = 'button';
    trigger.setAttribute('aria-label', 'فتح لوحة عزل السكربتات');
    trigger.setAttribute('aria-expanded', 'false');
    trigger.textContent = 'فحص';

    var backdrop = document.createElement('button');
    backdrop.id = 'otlobli-script-diagnostics-backdrop';
    backdrop.type = 'button';
    backdrop.setAttribute('aria-label', 'إغلاق لوحة عزل السكربتات');

    var panel = document.createElement('section');
    panel.id = 'otlobli-script-diagnostics-panel';
    panel.setAttribute('role', 'dialog');
    panel.setAttribute('aria-modal', 'true');
    panel.setAttribute('aria-labelledby', 'otlobli-script-diagnostics-title');

    var head = document.createElement('div');
    head.id = 'otlobli-script-diagnostics-head';
    var title = document.createElement('h2');
    title.id = 'otlobli-script-diagnostics-title';
    title.textContent = 'عزل سكربتات Otlobli';
    var close = document.createElement('button');
    close.id = 'otlobli-script-diagnostics-close';
    close.type = 'button';
    close.setAttribute('aria-label', 'إغلاق اللوحة');
    close.textContent = '×';
    head.appendChild(title);
    head.appendChild(close);
    panel.appendChild(head);

    var copy = document.createElement('p');
    copy.id = 'otlobli-script-diagnostics-copy';
    copy.textContent = 'أطفئ مجموعة واحدة، ثم جرّب الأقسام والمنتجات. سيُعاد فتح المتجر من دون حذف تسجيل الدخول أو التحقق.';
    panel.appendChild(copy);

    var presets = document.createElement('div');
    presets.id = 'otlobli-script-diagnostics-presets';
    var raw = document.createElement('button');
    raw.type = 'button';
    raw.textContent = 'المتجر خام';
    var full = document.createElement('button');
    full.type = 'button';
    full.textContent = 'تشغيل الكل';
    presets.appendChild(raw);
    presets.appendChild(full);
    panel.appendChild(presets);

    var definitions = [
      ['runtime', 'كل تدخلات Otlobli', 'الاختبار الحاسم: يعرض المتجر خاماً مع بقاء زر الفحص فقط'],
      ['navigation', 'الشريط والتنقّل', 'شريط Otlobli والرجوع وإصلاح نقرات المنتج على iPhone'],
      ['blocking', 'الحجب والتنظيف', 'إخفاء الإعلانات والأيقونات وعناصر المتجر غير المطلوبة'],
      ['capture', 'الجذب والإضافة', 'قراءة المنتج وخياراته وزر الإضافة إلى سلة Otlobli'],
      ['session', 'الجلسة والمنطقة', 'التحقق من السعودية وواجهة تغيير عنوان الشحن']
    ];
    var list = document.createElement('div');
    list.id = 'otlobli-script-diagnostics-list';
    var controls = {};

    function render() {
      for (var i = 0; i < definitions.length; i++) {
        var key = definitions[i][0];
        var control = controls[key];
        if (control) control.setAttribute('aria-checked', flags[key] ? 'true' : 'false');
      }
    }

    function apply(next, label) {
      flags = {
        runtime: next.runtime !== false,
        navigation: next.navigation !== false,
        blocking: next.blocking !== false,
        capture: next.capture !== false,
        session: next.session !== false
      };
      window.__OTLOBLI_SCRIPT_FLAGS__ = flags;
      render();
      status.textContent = label + ' — جاري إعادة تشغيل المتجر…';
      post({ type: 'storeScriptFlagsChanged', flags: flags, label: label });
    }

    for (var i = 0; i < definitions.length; i++) {
      (function (definition) {
        var key = definition[0];
        var row = document.createElement('button');
        row.type = 'button';
        row.className = 'otlobli-script-diagnostic-row';
        row.setAttribute('role', 'switch');
        row.setAttribute('aria-checked', flags[key] ? 'true' : 'false');
        row.setAttribute('aria-label', definition[1]);
        var text = document.createElement('span');
        var label = document.createElement('b');
        label.textContent = definition[1];
        var description = document.createElement('small');
        description.textContent = definition[2];
        text.appendChild(label);
        text.appendChild(description);
        var toggle = document.createElement('span');
        toggle.className = 'otlobli-script-diagnostic-toggle';
        toggle.setAttribute('aria-hidden', 'true');
        row.appendChild(text);
        row.appendChild(toggle);
        row.addEventListener('click', function () {
          var next = Object.assign({}, flags);
          next[key] = !flags[key];
          apply(next, definition[1]);
        });
        controls[key] = row;
        list.appendChild(row);
      })(definitions[i]);
    }
    panel.appendChild(list);

    var status = document.createElement('p');
    status.id = 'otlobli-script-diagnostics-status';
    status.setAttribute('role', 'status');
    status.setAttribute('aria-live', 'polite');
    status.textContent = flags.runtime ? 'الوضع الحالي: تدخلات Otlobli مفعّلة' : 'الوضع الحالي: المتجر خام';
    panel.appendChild(status);

    var exit = document.createElement('button');
    exit.id = 'otlobli-script-diagnostics-exit';
    exit.type = 'button';
    exit.textContent = 'العودة لاختيار المتجر';
    exit.addEventListener('click', function () { post({ type: 'closeStore' }); });
    panel.appendChild(exit);

    function setOpen(open) {
      root.setAttribute('data-open', open ? '1' : '0');
      trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
      trigger.setAttribute('aria-hidden', open ? 'true' : 'false');
      trigger.tabIndex = open ? -1 : 0;
      backdrop.hidden = !open;
      panel.hidden = !open;
      panel.setAttribute('aria-hidden', open ? 'false' : 'true');
      panel.inert = !open;
      if (open) close.focus();
      else trigger.focus();
    }
    trigger.addEventListener('click', function () { setOpen(true); });
    backdrop.addEventListener('click', function () { setOpen(false); });
    close.addEventListener('click', function () { setOpen(false); });
    panel.addEventListener('keydown', function (event) {
      if (event.key === 'Escape') setOpen(false);
      if (event.key !== 'Tab') return;
      var focusable = panel.querySelectorAll('button:not([disabled])');
      if (!focusable.length) return;
      var first = focusable[0];
      var last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    });
    raw.addEventListener('click', function () {
      apply({ runtime: false, navigation: false, blocking: false, capture: false, session: false }, 'المتجر خام');
    });
    full.addEventListener('click', function () {
      apply(defaults, 'تشغيل الكل');
    });

    root.appendChild(trigger);
    root.appendChild(backdrop);
    root.appendChild(panel);
    document.body.appendChild(root);
    render();
    setOpen(false);
    reportPaintedStore();
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount, { once: true });
  else mount();
})();
`
