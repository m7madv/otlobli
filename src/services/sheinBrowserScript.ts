export const SHEIN_CAPTURE_SCRIPT = `
(function () {
  if (window.__otlobliInjected) return;
  window.__otlobliInjected = true;

  function cleanTitle(raw) {
    return (raw || '')
      .replace(/<[^>]*>/g, '')
      .replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&quot;/g, '"')
      .replace(/\\s*\\|\\s*SHEIN.*/i, '').replace(/\\s*-\\s*SHEIN.*/i, '')
      .trim();
  }

  function getMeta(prop) {
    var el = document.querySelector('meta[property="' + prop + '"]') || document.querySelector('meta[name="' + prop + '"]');
    return el ? (el.getAttribute('content') || '') : '';
  }

  function getTitle() {
    var fromMeta = cleanTitle(getMeta('og:title'));
    if (fromMeta) return fromMeta;
    var el = document.querySelector('h1, .product-intro__head-name, .goods-name');
    return cleanTitle(el ? el.textContent : '');
  }

  function getPrice() {
    var metaPrice = parseFloat(getMeta('product:price:amount'));
    if (metaPrice > 0) return metaPrice;
    var el = document.querySelector('.product-price .price-content, .product-intro__head-price, [class*="price" i]');
    var text = el ? (el.textContent || '') : '';
    var match = text.match(/[0-9]+\\.?[0-9]*/);
    return match ? parseFloat(match[0]) : 0;
  }

  function getImage() {
    var mainImg = document.querySelector('.product-intro__main-image img, .product-intro__thumbs-item.active img, [class*="main-image" i] img');
    if (mainImg && mainImg.src) return mainImg.src;
    var og = getMeta('og:image');
    if (og) return og;
    var anyImg = document.querySelector('img[src*="ltwebstatic"], img[src*="img.shein"]');
    return anyImg ? anyImg.src : '';
  }

  function findOptionContainer(keyword) {
    var all = document.querySelectorAll('[class*="' + keyword + '" i]');
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      var opts = el.querySelectorAll('li, button, [class*="item" i]');
      if (opts.length >= 2) return el;
    }
    return null;
  }

  function getSelectedWithin(container) {
    if (!container) return '';
    var nodes = container.querySelectorAll('*');
    for (var j = 0; j < nodes.length; j++) {
      var el = nodes[j];
      var cls = ' ' + (el.className || '') + ' ';
      var ariaSel = el.getAttribute('aria-selected') === 'true' || el.getAttribute('aria-checked') === 'true';
      if (ariaSel || /\\s(selected|active|checked|chosen|cur|current)\\s/i.test(cls)) {
        var label = el.getAttribute('aria-label') || el.getAttribute('title') || el.textContent || '';
        label = label.trim();
        if (label && label.length < 40) return label;
      }
    }
    return '';
  }

  function getColorState() {
    var container = findOptionContainer('color');
    return { exists: !!container, selected: getSelectedWithin(container) };
  }

  function getSizeState() {
    var container = findOptionContainer('size');
    return { exists: !!container, selected: getSelectedWithin(container) };
  }

  function looksLikeProductPage() {
    return !!getTitle() && getPrice() > 0 && !!getImage();
  }

  function sendProduct(color, size) {
    try {
      var payload = {
        title: getTitle(),
        priceUsd: getPrice(),
        image: getImage(),
        color: color,
        size: size,
        link: location.href,
      };
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: 'addToCart', product: payload } });
      }
    } catch (e) {}
  }

  window.addEventListener('messageFromNative', function (event) {
    var detail = event && event.detail;
    if (detail && detail.type === 'addToCartAck') {
      var btn = document.getElementById('otlobli-fab');
      if (btn) {
        var original = btn.textContent;
        btn.textContent = '✓ تمت الإضافة لسلة otlobli';
        btn.style.background = '#1aab6f';
        setTimeout(function () {
          btn.textContent = original;
          btn.style.background = '#006948';
        }, 1800);
      }
    }
  });

  function showMessage(btn, text) {
    var msg = document.getElementById('otlobli-msg');
    if (!msg) {
      msg = document.createElement('div');
      msg.id = 'otlobli-msg';
      msg.style.cssText = 'position:fixed;left:16px;right:16px;bottom:78px;z-index:2147483647;' +
        'background:#fff3cd;color:#7a5b00;border:1px solid #ffe28a;border-radius:10px;' +
        'padding:10px 14px;font-size:14px;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,.2);';
      document.body.appendChild(msg);
    }
    msg.textContent = text;
    msg.style.display = 'block';
    clearTimeout(window.__otlobliMsgTimer);
    window.__otlobliMsgTimer = setTimeout(function () { msg.style.display = 'none'; }, 2500);

    if (btn) {
      btn.style.animation = 'none';
      requestAnimationFrame(function () {
        btn.style.animation = 'otlobli-shake 0.4s';
      });
    }
  }

  function ensureShakeStyle() {
    if (document.getElementById('otlobli-style')) return;
    var style = document.createElement('style');
    style.id = 'otlobli-style';
    style.textContent = '@keyframes otlobli-shake {' +
      '10%,90%{transform:translateX(-1px)}' +
      '20%,80%{transform:translateX(2px)}' +
      '30%,50%,70%{transform:translateX(-4px)}' +
      '40%,60%{transform:translateX(4px)}}';
    document.head.appendChild(style);
  }

  function ensureFloatingButton() {
    var existing = document.getElementById('otlobli-fab');
    if (!looksLikeProductPage()) {
      if (existing) existing.remove();
      var msg = document.getElementById('otlobli-msg');
      if (msg) msg.remove();
      return;
    }
    if (existing) return;
    ensureShakeStyle();
    var btn = document.createElement('button');
    btn.id = 'otlobli-fab';
    btn.textContent = 'أضف لسلة otlobli';
    btn.style.cssText = 'position:fixed;left:16px;right:16px;bottom:16px;z-index:2147483647;' +
      'background:#006948;color:#fff;border:none;border-radius:12px;padding:14px;' +
      'font-size:16px;font-weight:bold;box-shadow:0 4px 14px rgba(0,0,0,.35);';
    btn.addEventListener('click', function (event) {
      event.preventDefault();
      event.stopPropagation();
      var colorState = getColorState();
      var sizeState = getSizeState();
      if (sizeState.exists && !sizeState.selected) {
        showMessage(btn, 'حدد المقاس أولاً');
        return;
      }
      if (colorState.exists && !colorState.selected) {
        showMessage(btn, 'حدد اللون أولاً');
        return;
      }
      sendProduct(colorState.selected, sizeState.selected);
    }, true);
    document.body.appendChild(btn);
  }

  function isAddToCartButton(el) {
    var text = (el.textContent || '').trim();
    if (!text || text.length > 40) return false;
    return /add to (bag|cart)/i.test(text);
  }

  function looksLikeCartUrl(href) {
    if (!href) return false;
    return /\/(cart|bag|checkout|order-confirm|payment)(\b|[/?#.])/i.test(href);
  }

  function isCartLink(el) {
    if (el.tagName === 'A' && looksLikeCartUrl(el.getAttribute('href') || el.href || '')) return true;
    var cls = ' ' + (el.className || '') + ' ';
    return /\s(cart-icon|header-cart|j-header-cart)\s/i.test(cls);
  }

  var lastSafeUrl = location.href;

  function blockCartNavigation() {
    if (looksLikeCartUrl(location.href)) {
      if (history.length > 1) history.back();
      else location.href = lastSafeUrl;
      showMessage(null, 'سلة otlobli فقط — أكمل اختيار المنتج واضغط الزر بالأسفل');
    } else {
      lastSafeUrl = location.href;
    }
  }

  document.addEventListener('click', function (event) {
    var el = event.target;
    var depth = 0;
    while (el && depth < 6) {
      if (el.id === 'otlobli-fab') return;
      if (isCartLink(el)) {
        event.preventDefault();
        event.stopPropagation();
        showMessage(null, 'سلة otlobli فقط — أكمل اختيار المنتج واضغط الزر بالأسفل');
        return;
      }
      if (isAddToCartButton(el)) {
        var colorState = getColorState();
        var sizeState = getSizeState();
        sendProduct(colorState.selected, sizeState.selected);
        break;
      }
      el = el.parentElement;
      depth++;
    }
  }, true);

  function tick() {
    blockCartNavigation();
    ensureFloatingButton();
  }

  var tickScheduled = false;
  function scheduleTick() {
    if (tickScheduled) return;
    tickScheduled = true;
    setTimeout(function () {
      tickScheduled = false;
      tick();
    }, 250);
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

  var observer = new MutationObserver(scheduleTick);
  observer.observe(document.body, { childList: true, subtree: false });

  setInterval(tick, 3000);
  tick();
})();
`
