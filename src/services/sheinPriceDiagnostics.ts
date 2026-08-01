// SHEIN price/option capture diagnostics overlay.
//
// Lives OUTSIDE sheinBrowserScript.ts on purpose: that file is measured by
// scripts/verify-performance-budget.mjs and has almost no headroom left. This
// file only reads window.__otlobliDiag, which the capture script publishes, so
// every number shown here comes from the functions that actually ship - never
// from a re-implementation that could quietly disagree with them.
//
// Everything inside the template literal below ships verbatim (it is a string,
// so the minifier cannot touch it). Keep explanation up here, where it is free,
// and keep the injected body lean - it counts against the JS bundle budget.
//
// It answers the questions ten rounds of blind price fixes could not:
//   - which branch produced the price (source), and whether it was a range price
//   - whether the colour/size containers were found at all, and under which
//     heading text, so wrong label matching is visible instead of guessed
//   - every short visible heading, flagged with whether our label lists match
//     it - this is what pins down a new SHEIN template
//   - the real price roots with each candidate's text, font size, line-through
//   - the exact payload handed to the app on the last add-to-cart
//
// The overlay is a red "تشخيص" button above the bottom nav; it opens a
// selectable, copyable report. Both element ids start with "otlobli-" so the
// capture script's own handlers ignore them.
export const SHEIN_PRICE_DIAGNOSTICS_SCRIPT = `
(function () {
  if (window.__otlobliPriceDiagInstalled) return;
  window.__otlobliPriceDiagInstalled = true;

  var LAST_ADD = null;
  var tries = 0;
  var timer = setInterval(function () {
    tries++;
    try {
      var app = window.mobileApp;
      if (app && typeof app.postMessage === 'function' && !app.__otlobliWrapped) {
        var orig = app.postMessage.bind(app);
        app.postMessage = function (msg) {
          try {
            var d = msg && msg.detail;
            if (d && d.type === 'addToCart') LAST_ADD = { at: Date.now(), p: d.product };
          } catch (e) {}
          return orig(msg);
        };
        app.__otlobliWrapped = true;
        clearInterval(timer);
      }
    } catch (e) {}
    if (tries > 120) clearInterval(timer);
  }, 500);

  function txt(el, max) {
    var t = String((el && el.textContent) || '').replace(/\\s+/g, ' ').trim();
    max = max || 90;
    return t.length > max ? t.slice(0, max) + '…' : t;
  }
  function cls(el) {
    var c = String((el && el.className) || '');
    c = c.replace(/\\s+/g, ' ').trim();
    return c.length > 70 ? c.slice(0, 70) + '…' : (c || '(بلا)');
  }
  function vis(el) {
    try {
      var r = el.getBoundingClientRect();
      if (!r || r.width <= 0 || r.height <= 0) return false;
      var s = window.getComputedStyle(el);
      return s.display !== 'none' && s.visibility !== 'hidden';
    } catch (e) { return false; }
  }

  function build() {
    var D = window.__otlobliDiag;
    var L = [];
    var add = function (s) { L.push(s == null ? '' : String(s)); };
    add('تشخيص سعر SHEIN');
    add('مسار: ' + location.pathname);
    add('');
    if (!D) {
      add('!! __otlobliDiag مفقود — لم يُحقن سكربت الالتقاط.');
      return L.join('\\n');
    }
    var go = function (n, fn) {
      try { return fn(); } catch (e) { add('  خطأ ' + n + ': ' + e); return null; }
    };

    add('=== الالتقاط ===');
    add('السعر: ' + go('price', function () { return D.price(); }));
    add('المصدر: ' + go('source', function () { return D.source(); }));
    add('نطاق؟ ' + go('range', function () { return D.isRange() ? 'نعم' : 'لا'; }));
    add('spa: ' + go('spa', function () { return D.spa(); }));
    add('مفتاح: [' + go('key', function () { return D.key(); }) + ']');
    add('ينتظر؟ ' + go('pend', function () { return D.pending() ? 'نعم' : 'لا'; }));
    var sv = go('saved', function () { return D.saved(); });
    if (sv) {
      add('محفوظ: ' + sv.price + ' | مفتاح: [' + sv.key + ']');
      add('  مسار: ' + sv.path + ' | مراقب؟ ' + (sv.observing ? 'نعم' : 'لا'));
    }
    add('');

    var lab = go('labels', function () { return D.labels(); }) || { color: [], size: [] };
    add('=== اللون ===');
    var c = go('color', function () { return D.color(); });
    var cB = go('fc', function () { return D.find('color', lab.color); });
    add('حاوية: ' + (cB ? 'وجدت — ' + cls(cB) : '!! مفقودة'));
    if (c) add('مختار: [' + (c.selected || '') + '] | exists=' + c.exists);
    add('=== المقاس ===');
    var s = go('size', function () { return D.size(); });
    var sB = go('fs', function () { return D.find('size', lab.size); });
    add('حاوية: ' + (sB ? 'وجدت — ' + cls(sB) : '!! مفقودة'));
    if (s) {
      add('مختار: [' + (s.selected || '') + '] | exists=' + s.exists);
      add('متاح: ' + ((s.available || []).join(' , ') || '-'));
    }
    add('');

    add('=== عناوين (تطابق؟) ===');
    var hit = function (list, t) {
      for (var i = 0; i < (list || []).length; i++) if (t.indexOf(list[i]) !== -1) return list[i];
      return '';
    };
    var seen = {}, n = 0;
    var els = document.querySelectorAll('div,span,p,h1,h2,h3,label,b,strong');
    for (var i = 0; i < els.length && n < 45; i++) {
      var el = els[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.children && el.children.length > 2) continue;
      var t = txt(el, 30);
      if (!t || t.length > 26 || seen[t] || !vis(el)) continue;
      seen[t] = 1;
      var mc = hit(lab.color, t), ms = hit(lab.size, t);
      add('[' + t + ']' + (mc ? ' <=C(' + mc + ')' : (ms ? ' <=S(' + ms + ')' : ''))
        + '  cls=' + cls(el));
      n++;
    }

    add('=== أسعار ===');
    var roots = document.querySelectorAll('.product-intro__head-price,[class*="productPriceContainer" i],[class*="head-price" i],[class*="main-price" i]');
    add('جذور: ' + roots.length);
    for (var r = 0; r < roots.length && r < 6; r++) {
      var rt = roots[r];
      add('-- ' + (r + 1) + ' ظاهر=' + (vis(rt) ? 'نعم' : 'لا') + ' | ' + cls(rt));
      add('    "' + txt(rt, 120) + '"');
      var kids = rt.querySelectorAll('*'), pr = 0;
      for (var k = 0; k < kids.length && pr < 10; k++) {
        var kd = kids[k], kt = txt(kd, 28);
        if (!kt || kt.indexOf('$') === -1) continue;
        if (kd.children && kd.children.length > 1) continue;
        var st = window.getComputedStyle(kd);
        var sk = /line-through/.test((st.textDecorationLine || '') + ' ' + (st.textDecoration || ''));
        add('      • "' + kt + '"  ' + Math.round(parseFloat(st.fontSize || '0')) + 'px'
          + (sk ? ' مشطوب' : '') + '  cls=' + cls(kd));
        pr++;
      }
    }

    add('=== آخر إضافة ===');
    if (!LAST_ADD) {
      add('(لا إضافة بعد)');
    } else {
      var p = LAST_ADD.p || {};
      add('قبل ' + Math.round((Date.now() - LAST_ADD.at) / 1000) + 'ث');
      add('مُرسل: ' + p.priceUsd + ' | المصدر: ' + p.priceSource);
      add('لون: [' + (p.color || '') + '] | مقاس: [' + (p.size || '') + ']');
      add('عنوان: ' + String(p.title || '').slice(0, 70));
    }
    return L.join('\\n');
  }

  function style() {
    if (document.getElementById('otlobli-pdc')) return;
    var s = document.createElement('style');
    s.id = 'otlobli-pdc';
    s.textContent = '#otlobli-pdb{position:fixed;left:10px;bottom:96px;z-index:2147483500;'
      + 'padding:10px 14px;border:0;border-radius:20px;background:#b91c1c;color:#fff;font:700 13px sans-serif}'
      + '#otlobli-pdp{position:fixed;inset:0;z-index:2147483600;background:#0b1120;display:flex;flex-direction:column}'
      + '#otlobli-pdp .b{display:flex;gap:8px;padding:10px}'
      + '#otlobli-pdp button{flex:1;padding:12px;border:0;border-radius:8px;color:#fff;font:700 15px sans-serif}'
      + '#otlobli-pdp pre{flex:1;overflow:auto;margin:0;padding:12px;color:#e5e7eb;'
      + 'font:11px/1.5 monospace;white-space:pre-wrap;word-break:break-word;direction:ltr;'
      + 'text-align:left;-webkit-user-select:text!important;user-select:text!important}';
    (document.head || document.documentElement).appendChild(s);
  }

  function panel() {
    var old = document.getElementById('otlobli-pdp');
    if (old) old.parentNode.removeChild(old);
    style();
    var rep = build();
    var w = document.createElement('div');
    w.id = 'otlobli-pdp';
    var bar = document.createElement('div');
    bar.className = 'b';
    var copy = document.createElement('button');
    copy.textContent = 'نسخ';
    copy.style.background = '#047857';
    var close = document.createElement('button');
    close.textContent = 'إغلاق';
    close.style.background = '#374151';
    bar.appendChild(copy);
    bar.appendChild(close);
    var pre = document.createElement('pre');
    pre.textContent = rep;
    close.addEventListener('click', function (e) {
      e.stopPropagation();
      if (w.parentNode) w.parentNode.removeChild(w);
    }, true);
    copy.addEventListener('click', function (e) {
      e.stopPropagation();
      var no = function () { copy.textContent = 'انسخ يدوياً'; };
      try {
        navigator.clipboard.writeText(rep).then(function () { copy.textContent = 'تم ✓'; }, no);
      } catch (e2) { no(); }
    }, true);
    w.appendChild(bar);
    w.appendChild(pre);
    (document.body || document.documentElement).appendChild(w);
  }

  function btn() {
    if (!document.body || document.getElementById('otlobli-pdb')) return;
    style();
    var b = document.createElement('button');
    b.id = 'otlobli-pdb';
    b.textContent = 'تشخيص';
    b.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      panel();
    }, true);
    document.body.appendChild(b);
  }

  btn();
  setInterval(btn, 1500);
})();
`
