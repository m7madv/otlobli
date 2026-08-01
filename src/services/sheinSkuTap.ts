// SHEIN "انقر للشراء" options-drawer activation, injected into the capture
// script's own scope.
//
// Lives OUTSIDE sheinBrowserScript.ts for the same reason sheinPriceDiagnostics
// does: that file is measured by scripts/verify-performance-budget.mjs and has
// almost no headroom left, and the budget's own instruction is to split rather
// than raise it. The template below is interpolated verbatim into
// SHEIN_CAPTURE_SCRIPT next to sheinSkuSelectionEntry, so it shares that
// closure - sheinElementIsVisible, sheinCovered, sheinDrawerCompoundSizeState,
// showMessage and __otlobliSheinDrawerPath are the capture script's own.
// It ships in the same injected string, so it still counts against the real
// (bundle raw/gzip) budget; only the source-file proxy changes. Everything
// inside the template ships verbatim - a string the minifier cannot touch - so
// the explanation lives up here, where it is free, and the body stays lean.
//
// Why it exists: on device the drawer never opened. v86.43 activated the row
// with a bare element.click(), which reaches only listeners bound to `click` on
// that exact node or an ancestor - SHEIN's mobile PDP binds the options entry
// with a touch directive on an inner chip, so nothing fired at all and the add
// button silently did nothing (sheinOpenSkuDrawer returned true regardless).
//
// sheinTapElement replays a real tap: pointer -> touch -> mouse -> click on the
// deepest node under the target's centre, so every binding on the way up fires.
// When the page cancels the touch (what a tap handler does) the mouse/click
// tail is dropped exactly like a browser drops it - sending it anyway would
// activate a dual-bound row twice and toggle the drawer straight back shut.
// __otlobliTapTrace records what was actually hit; without it a failed tap is
// invisible and the next fix is another blind guess, which is what cost v86.43.
//
// sheinSkuPromptNode aims at the chip that literally reads "انقر للشراء" - the
// control the shopper taps - rather than the row, which is only its label.
//
// One tap and nothing else. v86.44 also ran a confirm/retry timer that re-tapped
// the row after 450ms when it could not prove the drawer had opened. That probe
// was wrong, the second tap undid the first, and the user got a refusal message
// on every product. Device verdict on v86.44 was "خربت الدنيا". Never re-tap
// blind: diagnose with __otlobliTapTrace first.
//
// sheinRevealSkuOptions is why v86.45 still looked dead. Measured over CDP on the
// user's Note 8 (SM-N950F, product 1pc-Tabletop-Jewelry-Storage-Box): pressing
// أضف للسلة DID activate SHEIN's control - .SIZE_ITEM_HOOK went 0 -> 2 and four
// .sui-drawer nodes appeared, and __otlobliTapTrace recorded the hit - but SHEIN
// renders the revealed نوع الموديلات / مقاس groups ~500 CSS px BELOW the fold, so
// the screen did not change by one pixel and the shopper reported "لا يحدث شيء
// أبدا". Scrolling the last revealed group to centre put both groups on screen.
// The press was never the missing piece; showing its result was.
export const OTLOBLI_SKU_TAP_JS = `
  var OTLOBLI_SKU_PROMPT = /انقر للشراء|please\\s*select|الرجاء الاختيار|يرجى الاختيار|اختر الخيارات/i;

  function sheinTapElement(el) {
    if (!el) return false;
    var r = el.getBoundingClientRect();
    var vw = document.documentElement.clientWidth || innerWidth;
    var vh = document.documentElement.clientHeight || innerHeight;
    var x = Math.max(1, Math.min(vw - 2, r.left + r.width / 2));
    var y = Math.max(1, Math.min(vh - 2, r.top + r.height / 2));
    var target = el;
    try {
      var hit = document.elementFromPoint(x, y);
      if (hit && (hit === el || el.contains(hit))) target = hit;
    } catch (e) {}
    function fire(Ctor, type, extra) {
      try {
        var init = { bubbles: true, cancelable: true, composed: true, view: window,
          detail: 1, clientX: x, clientY: y, screenX: x, screenY: y };
        for (var k in extra) init[k] = extra[k];
        return target.dispatchEvent(new Ctor(type, init));
      } catch (e) { return null; }
    }
    var touches = [];
    try {
      touches = [new Touch({ identifier: 1, target: target, clientX: x, clientY: y,
        pageX: x + scrollX, pageY: y + scrollY, screenX: x, screenY: y,
        radiusX: 12, radiusY: 12, rotationAngle: 0, force: 1 })];
    } catch (e) {}
    var pointer = { pointerId: 1, pointerType: 'touch', isPrimary: true, width: 24, height: 24, pressure: 0.5 };
    var touched = false, cancelled = false;
    if (window.PointerEvent) fire(PointerEvent, 'pointerdown', pointer);
    if (window.TouchEvent && touches.length) {
      touched = true;
      if (fire(TouchEvent, 'touchstart', { touches: touches, targetTouches: touches, changedTouches: touches }) === false) cancelled = true;
    }
    pointer.pressure = 0;
    if (window.PointerEvent) fire(PointerEvent, 'pointerup', pointer);
    if (touched && fire(TouchEvent, 'touchend', { touches: [], targetTouches: [], changedTouches: touches }) === false) cancelled = true;
    if (!cancelled) {
      fire(MouseEvent, 'mousedown');
      fire(MouseEvent, 'mouseup');
      fire(MouseEvent, 'click');
    }
    try {
      window.__otlobliTapTrace = target.tagName + '.' + String(target.className || '').slice(0, 40) +
        ' touch=' + (touched ? 1 : 0) + ' cancel=' + (cancelled ? 1 : 0) +
        ' at=' + Math.round(x) + ',' + Math.round(y);
    } catch (e) {}
    return true;
  }

  function sheinRevealSkuOptions(round) {
    setTimeout(function () {
      var h = document.querySelectorAll('.SIZE_ITEM_HOOK');
      if (!h.length) { if (round < 5) sheinRevealSkuOptions(round + 1); return; }
      try { h[h.length - 1].scrollIntoView({ block: 'center' }); } catch (e) {}
    }, 280);
  }

  function sheinSkuPromptNode(row) {
    if (!row) return null;
    var nodes = row.querySelectorAll('div, span, p, a, button, i');
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i];
      if (n.children.length > 2) continue;
      var t = (n.textContent || '').replace(/\\s+/g, ' ').trim();
      if (t && t.length < 30 && OTLOBLI_SKU_PROMPT.test(t) && sheinElementIsVisible(n)) return n;
    }
    return null;
  }

`
