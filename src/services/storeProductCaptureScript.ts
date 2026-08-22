import { OTLOBLI_SKU_TAP_JS } from './sheinSkuTap'

export const STORE_PRODUCT_CAPTURE_SCRIPT = `
  function ensureNoTextSelection() {
    if (!document.head) return;
    if (document.getElementById('otlobli-no-select-style')) return;
    var style = document.createElement('style');
    style.id = 'otlobli-no-select-style';
    style.textContent =
      'html,body,body *:not(input):not(textarea):not(select):not([contenteditable]){' +
      '-webkit-user-select:none!important;user-select:none!important;-webkit-touch-callout:none!important;}' +
      'input,textarea,select,[contenteditable]{' +
      '-webkit-user-select:text!important;user-select:text!important;-webkit-touch-callout:default!important;}';
    document.head.appendChild(style);
  }

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

  var __otlobliInitialCapturePath = location.pathname;
  function sheinSpaCaptureRoute() {
    return IS_SHEIN && location.pathname !== __otlobliInitialCapturePath;
  }

  // Static product metadata; current SKU price must come from the painted PDP.
  var __otlobliLdCache = null;
  var __otlobliLdCacheUrl = '';
  function getProductJsonLd() {
    if (__otlobliLdCacheUrl === location.href && __otlobliLdCache !== null) return __otlobliLdCache;
    __otlobliLdCacheUrl = location.href;
    __otlobliLdCache = null;
    try {
      var scripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (var i = 0; i < scripts.length; i++) {
        var data;
        try { data = JSON.parse(scripts[i].textContent || ''); } catch (e) { continue; }
        var list = Array.isArray(data) ? data : (data && data['@graph'] ? data['@graph'] : [data]);
        for (var j = 0; j < list.length; j++) {
          var node = list[j];
          var type = node && node['@type'];
          var isProduct = type === 'Product' || (Array.isArray(type) && type.indexOf('Product') !== -1);
          if (node && isProduct) { __otlobliLdCache = node; return node; }
        }
      }
    } catch (e) {}
    return null;
  }

  function looksGenericTitle(t) {
    if (!t) return true;
    return /شي\\s*إن|shein/i.test(t) && /(تسوق|fashion|shop|الموضة)/i.test(t);
  }

  function getTitle(allowGenericFallback) {
    if (sheinSpaCaptureRoute()) {
      var liveTitle = document.querySelector('.product-intro__head-name') || document.querySelector('h1');
      var fromLive = cleanTitle(liveTitle ? liveTitle.textContent : '');
      if (fromLive && !looksGenericTitle(fromLive)) return fromLive;
    }
    var ld = getProductJsonLd();
    if (ld && ld.name) {
      var fromLd = cleanTitle(ld.name);
      if (fromLd) return fromLd;
    }
    var fromMeta = cleanTitle(getMeta('og:title'));
    if (fromMeta && !looksGenericTitle(fromMeta)) return fromMeta;
    var el = document.querySelector('h1, .product-intro__head-name, .goods-name, [class*="goods-name" i], [class*="product-name" i], [class*="head-name" i]');
    var fromEl = cleanTitle(el ? el.textContent : '');
    if (fromEl && !looksGenericTitle(fromEl)) return fromEl;
    if (fromMeta) return fromMeta;
    if (fromEl) return fromEl;
    if (!allowGenericFallback) return '';
    // Absolute last resort, only once we've given up retrying for a real name.
    return cleanTitle(document.title);
  }

  var __otlobliSelectedSkuPrice = 0;
  var __otlobliSelectedSkuPriceKey = '';
  var __otlobliSelectedSkuColor = '';
  var __otlobliSelectedSkuColorImage = '';
  var __otlobliSelectedSkuPricePath = '';
  var __otlobliSelectedSkuPriceAt = 0;
  var __otlobliSelectedSkuPriceBefore = 0;
  var __otlobliSelectedSkuPriceObserver = null;
  var __otlobliSelectedSkuPriceRun = 0, __otlobliSkuPriceSource = '';
  function sheinCurrentSelectionKey() {
    var color = getColorState();
    var size = getSizeState();
    return String(color.selected || '') + '|' + String(size.selected || '');
  }

  function sheinUsdValue(text) {
    var match = String(text || '').match(/(?:US\\$|USD|\\$)\\s*([0-9][0-9,.]*)/i);
    if (!match) return 0;
    var raw = match[1];
    if (raw.indexOf('.') >= 0 && raw.indexOf(',') >= 0) raw = raw.replace(/,/g, '');
    else if (/,[0-9]{1,2}$/.test(raw)) raw = raw.replace(',', '.');
    else raw = raw.replace(/,/g, '');
    var value = parseFloat(raw);
    return value > 0 ? value : 0;
  }

  function sheinPriceFromChangedRoot(root) {
    if (!root || !sheinElementIsPainted(root)) return 0;
    var best = 0, bestScore = -1;
    var inspect = function (el) {
      if (!sheinElementIsPainted(el)) return;
      var text = String(el.textContent || '').replace(/\\s+/g, ' ').trim();
      if (!text || text.indexOf('%') >= 0 || (text.match(/(?:US\\$|USD|\\$)/gi) || []).length !== 1) return;
      var value = sheinUsdValue(text);
      if (!(value > 0)) return;
      var style = window.getComputedStyle(el);
      var hint = String(el.className || '') + ' ' + String(el.parentElement && el.parentElement.className || '');
      if (/line-through/i.test(style.textDecorationLine || style.textDecoration || '') ||
          /(?:old|original|retail|market|compare|cross|del|strikethrough)(?:-|_|\\s|$)/i.test(hint)) return;
      var score = parseFloat(style.fontSize || '0') + (/current|sale|final|special|price-content|main-price/i.test(hint) ? 12 : 0);
      if (score >= bestScore) { best = value; bestScore = score; }
    };
    inspect(root);
    // Targeted first: a blind walk stopped at the 60th descendant, past which the
    // real price node can sit (coupon/flash/member chips), so getPrice() fell to
    // the JSON-LD base - "intermittent". Class-targeted needs fewer style reads.
    var priced = root.querySelectorAll('[class*="price" i], [class*="amount" i]');
    for (var i = 0; i < priced.length && i < 40; i++) inspect(priced[i]);
    if (bestScore < 0) {
      var nodes = root.querySelectorAll('*');
      for (var j = 0; j < nodes.length && j < 80; j++) inspect(nodes[j]);
    }
    return best;
  }

  // Recommendation rails sit BELOW the PDP and reuse the generic .product-price
  // class, so an unscoped scan can read a RECOMMENDED item's price. Explains
  // different products landing in the cart with one identical price (same rail
  // on every PDP) and why a restart cleared it (rail not mounted on cold load).
  var OTLOBLI_PRICE_RAIL_HINT = /recommend|similar|also-?like|you-?may|often-?bought|frequently|related|goods-?list|product-?list|listing|rail|carousel|swiper|slider|footer/i;

  function sheinInRecommendationRail(el) {
    var node = el, depth = 0;
    while (node && node !== document.body && node !== document.documentElement && depth < 10) {
      var hint = String(node.className || '') + ' ' + String(node.id || '');
      if (OTLOBLI_PRICE_RAIL_HINT.test(hint)) return true;
      node = node.parentElement;
      depth++;
    }
    return false;
  }

  function sheinPdpPriceScope() {
    var anchor = document.querySelector('.product-intro__head-price') ||
      document.querySelector('.product-intro__head-name');
    if (anchor) {
      var box = (anchor.closest && anchor.closest('.product-intro')) || anchor.parentElement;
      if (box) return box;
    }
    var name = document.querySelector('.product-intro__head-name') || document.querySelector('h1');
    var node = name, depth = 0;
    while (node && node !== document.body && depth < 6) {
      if (node.querySelector && node.querySelector('.product-price, [class*="head-price" i]')) return node;
      node = node.parentElement;
      depth++;
    }
    return null;
  }

  // "من $8.63" / "from $8.63" is a RANGE start (== offers.lowPrice), never what
  // the shopper buys - seen on the click-to-buy template before a variant is
  // committed. If that is all the page exposes, capture must fail closed.
  // See v86.33 in docs/SHEIN_IOS_FREEZE_GUARD.md.
  var OTLOBLI_PRICE_SEL = '.product-intro__head-price, [class*="productPriceContainer" i], [class*="head-price" i]';
  var OTLOBLI_MAIN_PRICE_SEL = '[class*="bsc-main-price" i], [class*="main-price" i]';

  function sheinHeadPriceIsRange() {
    var f = document.querySelector('[class*="from-tag" i]');
    if (f && sheinElementIsPainted(f)) return true;
    var roots = document.querySelectorAll(OTLOBLI_PRICE_SEL);
    for (var i = 0; i < roots.length && i < 4; i++) {
      var t = String(roots[i].textContent || '').replace(/\\s+/g, ' ');
      if (/(?:^|[\\s(])(?:من|from|starting at)\\s*(?:US\\$|USD|\\$)/i.test(t)) return true;
    }
    return false;
  }

  function sheinSpaRoutePrice() {
    if (!IS_SHEIN) return 0;
    if (sheinHeadPriceIsRange()) return 0;
    var price = 0;
    var mains = document.querySelectorAll(OTLOBLI_MAIN_PRICE_SEL);
    for (var m = 0; m < mains.length && m < 4; m++) {
      if (!sheinElementIsPainted(mains[m])) continue;
      var mv = sheinUsdValue(mains[m].textContent || '');
      if (mv > 0) price = mv;
    }
    if (price > 0) return price;
    var heads = document.querySelectorAll(OTLOBLI_PRICE_SEL);
    for (var i = 0; i < heads.length && i < 8; i++) {
      var head = sheinPriceFromChangedRoot(heads[i]);
      if (head > 0) price = head;
    }
    if (price > 0) return price;
    var scope = sheinPdpPriceScope();
    var roots = (scope || document).querySelectorAll('.product-price');
    for (var j = 0; j < roots.length && j < 12; j++) {
      if (sheinInRecommendationRail(roots[j])) continue;
      var found = sheinPriceFromChangedRoot(roots[j]);
      if (found > 0) price = found;
    }
    return price;
  }

  function sheinTrackSelectedSkuPrice(event) {
    if (!IS_SHEIN || !document.body) return;
    var target = event && event.target;
    if (!target || !target.closest || target.closest('[id^="otlobli-"]')) return;
    var colorBox = findOptionContainer('color', OTLOBLI_COLOR_LABELS);
    var sizeBox = findOptionContainer('size', OTLOBLI_SIZE_LABELS);
    var drawerGroup = target.closest('.SIZE_ITEM_HOOK');
    var inActiveDrawerGroup = !!(drawerGroup &&
      __otlobliSheinDrawerPath === location.pathname && !sheinIsQuantityEl(drawerGroup));
    if (!inActiveDrawerGroup &&
        (!colorBox || !colorBox.contains(target)) &&
        (!sizeBox || !sizeBox.contains(target))) return;
    if (colorBox && colorBox.contains(target)) {
      var tappedSw = target.closest(
        'li,button,[role="radio"],[role="option"],[class*="item" i],[class*="color" i]') || target;
      var tapLbl = sheinSelectionLabel(tappedSw);
      var tapImage = swatchImageFrom(tappedSw);
      if ((tapLbl && !isGenericColorName(tapLbl)) || tapImage) {
        if (tapLbl) __otlobliSelectedSkuColor = tapLbl;
        if (tapImage) __otlobliSelectedSkuColorImage = tapImage;
        __otlobliSelectedSkuPricePath = location.pathname;
        __otlobliSelectedSkuPriceAt = Date.now();
      }
    }
    __otlobliSelectedSkuPriceBefore = getPrice();
    __otlobliSelectedSkuPriceAt = 0;
    if (__otlobliSelectedSkuPriceObserver) __otlobliSelectedSkuPriceObserver.disconnect();
    var run = ++__otlobliSelectedSkuPriceRun;
    var roots = [], priceChanged = false;
    var selector = OTLOBLI_PRICE_SEL + ', .product-price, ' + OTLOBLI_MAIN_PRICE_SEL;
    var rememberRoot = function (node) {
      if (!node || node.nodeType !== 1) return;
      var root = node.matches && node.matches(selector) ? node : (node.closest && node.closest(selector));
      if (!root && node.querySelector) root = node.querySelector(selector);
      if (root) {
        priceChanged = true;
        if (!roots.includes(root) && roots.length < 8) roots.push(root);
      }
    };
    __otlobliSelectedSkuPriceObserver = new MutationObserver(function (records) {
      priceChanged = false;
      for (var i = 0; i < records.length; i++) {
        rememberRoot(records[i].target.nodeType === 3 ? records[i].target.parentElement : records[i].target);
        for (var j = 0; records[i].addedNodes && j < records[i].addedNodes.length; j++) rememberRoot(records[i].addedNodes[j]);
      }
      if (priceChanged) commit();
    });
    __otlobliSelectedSkuPriceObserver.observe(document.body, {
      subtree: true, childList: true, characterData: true, attributes: true,
      attributeFilter: ['class', 'style', 'hidden', 'aria-hidden']
    });
    if (inActiveDrawerGroup) {
      var drawerRoot = target.closest('.sui-drawer');
      var initialPriceRoots = drawerRoot && drawerRoot.querySelectorAll(OTLOBLI_MAIN_PRICE_SEL);
      for (var pr = 0; initialPriceRoots && pr < initialPriceRoots.length && pr < 8; pr++) rememberRoot(initialPriceRoots[pr]);
    }
    var commit = function () {
      if (run !== __otlobliSelectedSkuPriceRun) return;
      var price = 0;
      for (var i = 0; i < roots.length; i++) {
        var found = sheinPriceFromChangedRoot(roots[i]);
        if (found > 0) price = found;
      }
      if (!(price > 0)) return;
      __otlobliSelectedSkuPrice = price;
      __otlobliSelectedSkuPriceKey = sheinCurrentSelectionKey();
      __otlobliSelectedSkuPricePath = location.pathname;
      __otlobliSelectedSkuPriceAt = Date.now();
      // Colour/image are NOT stashed here (getColorState races the closing
      // sheet). They are locked deterministically at swatch-tap time above.
    };
    setTimeout(commit, 90);
    setTimeout(commit, 260);
    setTimeout(commit, 700);
    setTimeout(commit, 1500);
    setTimeout(function () {
      if (run !== __otlobliSelectedSkuPriceRun || !__otlobliSelectedSkuPriceObserver) return;
      commit();
      __otlobliSelectedSkuPriceObserver.disconnect();
      __otlobliSelectedSkuPriceObserver = null;
    }, 1750);
  }

  function sheinSelectedSkuPricePending() {
    if (sheinActiveQuickAddDrawer()) return false;
    if (!__otlobliSelectedSkuPriceObserver) return false;
    var ready = __otlobliSelectedSkuPrice > 0 &&
      __otlobliSelectedSkuPricePath === location.pathname &&
      __otlobliSelectedSkuPriceKey === sheinCurrentSelectionKey() &&
      __otlobliSelectedSkuPriceAt > 0;
    return !ready || Math.abs(__otlobliSelectedSkuPrice - __otlobliSelectedSkuPriceBefore) < 0.0001;
  }

  function getPrice() {
    var selectionKey = sheinCurrentSelectionKey();
    // The click-to-buy template commits the variant inside a drawer, and the
    // option groups are gone once it closes, so the live key degrades to "|".
    // Keep honouring the price captured for this route in that case, otherwise
    // the correct drawer price would be thrown away the moment the sheet shuts.
    if (__otlobliSelectedSkuPrice > 0 &&
        __otlobliSelectedSkuPricePath === location.pathname &&
        (__otlobliSelectedSkuPriceKey === selectionKey || selectionKey === '|') &&
        Date.now() - __otlobliSelectedSkuPriceAt < 1800000) {
      __otlobliSkuPriceSource = 'selected-mutation';
      return __otlobliSelectedSkuPrice;
    }
    var spaPrice = sheinSpaRoutePrice();
    if (spaPrice > 0) { __otlobliSkuPriceSource = 'spa-dom'; return spaPrice; }
    // A range head price means JSON/meta carry that same low end, so every
    // remaining source is wrong here. Fail closed rather than undercharge.
    if (sheinHeadPriceIsRange()) { __otlobliSkuPriceSource = 'range-blocked'; return 0; }
    var ld = getProductJsonLd();
    if (ld && ld.offers) {
      var offers = Array.isArray(ld.offers) ? ld.offers[0] : ld.offers;
      // Never offers.lowPrice: it is the CHEAPEST variant, a price the shopper
      // never saw. Returning 0 makes addToCartFlow block instead of charging it.
      var ldPrice = offers && parseFloat(offers.price);
      if (ldPrice > 0) { __otlobliSkuPriceSource = 'json'; return ldPrice; }
    }
    var metaPrice = parseFloat(getMeta('product:price:amount'));
    if (metaPrice > 0) { __otlobliSkuPriceSource = 'meta'; return metaPrice; }
    var el = document.querySelector('.product-price .price-content, .product-intro__head-price, [class*="price" i]');
    var text = el ? (el.textContent || '') : '';
    var match = text.match(/[0-9]+\\.?[0-9]*/);
    __otlobliSkuPriceSource = match ? 'legacy-dom' : 'missing';
    return match ? parseFloat(match[0]) : 0;
  }

  try {
    window.__otlobliDiag = {
      price: getPrice,
      source: function () { return __otlobliSkuPriceSource; },
      color: getColorState,
      size: getSizeState,
      find: findOptionContainer,
      labels: function () { return { color: OTLOBLI_COLOR_LABELS, size: OTLOBLI_SIZE_LABELS }; },
      isRange: sheinHeadPriceIsRange,
      spa: sheinSpaRoutePrice,
      key: sheinCurrentSelectionKey,
      skuEntry: sheinSkuSelectionEntry,
      openDrawer: sheinOpenSkuDrawer,
      storeVariant: sheinStoreVariant,
      quick: sheinQuickAddPayload,
      pending: sheinSelectedSkuPricePending,
      saved: function () {
        return {
          price: __otlobliSelectedSkuPrice, key: __otlobliSelectedSkuPriceKey,
          path: __otlobliSelectedSkuPricePath, at: __otlobliSelectedSkuPriceAt,
          before: __otlobliSelectedSkuPriceBefore,
          observing: !!__otlobliSelectedSkuPriceObserver,
        };
      },
    };
  } catch (e) {}

  function normalizeImageUrl(url) {
    if (!url) return '';
    url = url.trim();
    if (url.indexOf('//') === 0) return 'https:' + url;
    if (url.indexOf('/') === 0) return location.origin + url;
    return url;
  }

  function realImgSrc(img) {
    if (!img) return '';
    var fromSrcset = function (srcset) {
      if (!srcset) return '';
      var parts = String(srcset).split(',').map(function (part) { return part.trim(); }).filter(Boolean);
      if (!parts.length) return '';
      return parts[parts.length - 1].split(/\\s+/)[0] || '';
    };
    var candidates = [
      img.getAttribute && img.getAttribute('data-src'),
      img.getAttribute && img.getAttribute('data-original'),
      img.getAttribute && img.getAttribute('data-lazy-src'),
      img.getAttribute && img.getAttribute('data-lazy'),
      img.getAttribute && img.getAttribute('data-original-src'),
      fromSrcset(img.getAttribute && img.getAttribute('srcset')),
      img.parentElement && img.parentElement.tagName === 'PICTURE' && fromSrcset((img.parentElement.querySelector('source[srcset]') || {}).srcset),
      img.currentSrc,
      img.src,
    ];
    for (var i = 0; i < candidates.length; i++) {
      var v = candidates[i];
      if (v && !/^data:image\\/(?:gif|svg)/i.test(v) && !/blank\\.gif|placeholder|skeleton|transparent/i.test(v)) return normalizeImageUrl(v);
    }
    return '';
  }

  function isInPromoWidget(img) {
    var el = img;
    var depth = 0;
    while (el && depth < 6) {
      var hint = ((el.className || '') + ' ' + (el.id || '')).toLowerCase();
      if (/app-download|download-app|applink|app-banner|guide-popup/i.test(hint)) return true;
      el = el.parentElement;
      depth++;
    }
    return false;
  }

  function renderedMinDim(img) {
    var r = img.getBoundingClientRect();
    var w = r.width || img.clientWidth || 0;
    var h = r.height || img.clientHeight || 0;
    return Math.min(w, h);
  }

  function getGalleryImage() {
    var imgs = document.querySelectorAll(
      'img[src*="ltwebstatic"], img[src*="img.shein"], img[data-src*="ltwebstatic"], img[data-src*="img.shein"]'
    );
    var byParentClass = {};
    var order = [];
    for (var i = 0; i < imgs.length; i++) {
      var img = imgs[i];
      if (isInPromoWidget(img)) continue;
      var src = realImgSrc(img);
      if (!src) continue;
      var dim = renderedMinDim(img);
      if (dim > 0 && dim < 64) continue;
      var pCls = img.parentElement ? (img.parentElement.className || '').trim() : '';
      if (!pCls) continue;
      if (!byParentClass[pCls]) { byParentClass[pCls] = []; order.push(pCls); }
      byParentClass[pCls].push(img);
    }
    var bestKey = null;
    var bestArea = 0;
    for (var k = 0; k < order.length; k++) {
      var key = order[k];
      if (byParentClass[key].length < 3) continue;
      var grp0 = byParentClass[key];
      var maxArea = 0;
      for (var gi = 0; gi < grp0.length; gi++) {
        var gr = grp0[gi].getBoundingClientRect();
        var area = gr.width * gr.height;
        if (area > maxArea) maxArea = area;
      }
      if (maxArea > bestArea) { bestArea = maxArea; bestKey = key; }
    }
    if (!bestKey) return '';
    var group = byParentClass[bestKey];
    var best = group[0];
    var bestAbsLeft = Infinity;
    for (var g = 0; g < group.length; g++) {
      var rect = group[g].getBoundingClientRect();
      if (rect.width <= 0 || rect.height <= 0) continue;
      var absLeft = Math.abs(rect.left);
      if (absLeft < bestAbsLeft) { bestAbsLeft = absLeft; best = group[g]; }
    }
    return realImgSrc(best);
  }

  function getLargestSheinImage() {
    var imgs = document.querySelectorAll(
      'img[src*="ltwebstatic"], img[src*="img.shein"], img[data-src*="ltwebstatic"], img[data-src*="img.shein"]'
    );
    var best = '';
    var bestArea = 0;
    for (var i = 0; i < imgs.length; i++) {
      if (isInPromoWidget(imgs[i])) continue;
      var src = realImgSrc(imgs[i]);
      if (!src) continue;
      var rdim = renderedMinDim(imgs[i]);
      if (rdim > 0 && rdim < 64) continue;
      var w = imgs[i].naturalWidth || imgs[i].clientWidth || parseInt(imgs[i].getAttribute('width') || '0', 10) || 0;
      var h = imgs[i].naturalHeight || imgs[i].clientHeight || parseInt(imgs[i].getAttribute('height') || '0', 10) || 0;
      var area = w * h;
      if (area >= bestArea) { bestArea = area; best = src; }
    }
    return best;
  }

  function getMainImage() {
    if (sheinSpaCaptureRoute()) {
      var liveMain = document.querySelector('.product-intro__main-image img, .product-intro__main-image');
      var liveSrc = realImgSrc(liveMain);
      if (liveSrc && !isInPromoWidget(liveMain)) return liveSrc;
    }
    var ld = getProductJsonLd();
    if (ld && ld.image) {
      var ldImg = Array.isArray(ld.image) ? ld.image[0] : ld.image;
      if (typeof ldImg === 'string' && ldImg) return normalizeImageUrl(ldImg);
      if (ldImg && typeof ldImg.url === 'string' && ldImg.url) return normalizeImageUrl(ldImg.url);
    }
    var mainImg = document.querySelector('.product-intro__main-image img, .product-intro__thumbs-item.active img, [class*="main-image" i] img');
    var fromMain = realImgSrc(mainImg);
    if (fromMain && !isInPromoWidget(mainImg)) return fromMain;
    var gallery = getGalleryImage();
    if (gallery) return gallery;
    var og = getMeta('og:image');
    if (og) return normalizeImageUrl(og);
    var largest = getLargestSheinImage();
    if (largest) return largest;
    var anyImg = document.querySelector('img[src*="ltwebstatic"], img[src*="img.shein"]');
    return realImgSrc(anyImg);
  }

  var OTLOBLI_COLOR_LABELS = ['اللون', 'لون', 'Color', 'Colour'];
  var OTLOBLI_SIZE_LABELS = ['المقاس', 'مقاس', 'الحجم', 'Size'];

  var QTY_RE = /الكمية|كمية|quantity/i;
  function sheinGroupHeading(el) {
    if (!el) return '';
    var h = el.querySelector && el.querySelector('.goods-size__title');
    if (h) return normalizedOptionText(h.textContent);
    var node = el.parentElement;
    for (var up = 0; up < 4 && node; up++) {
      var titles = node.querySelectorAll ? node.querySelectorAll('.goods-size__title') : [];
      var nearest = null;
      for (var ti = 0; ti < titles.length; ti++) {
        if (titles[ti].compareDocumentPosition(el) & 4) nearest = titles[ti];
      }
      if (nearest) return normalizedOptionText(nearest.textContent);
      node = node.parentElement;
    }
    return '';
  }

  function sheinHeadingMatchesLabels(el, labelWords) {
    if (!labelWords) return false;
    var head = sheinGroupHeading(el).replace(/[:：]/g, ' ').toLowerCase();
    if (!head) return false;
    for (var w = 0; w < labelWords.length; w++) {
      if (head.indexOf(labelWords[w].toLowerCase()) !== -1) return true;
    }
    return false;
  }

  function sheinIsQuantityEl(el) {
    if (!el) return false;
    var t = (el.textContent || '').trim();
    if (t.length < 20 && QTY_RE.test(t)) return true;
    return QTY_RE.test(sheinGroupHeading(el));
  }

  function findOptionContainer(keyword, labelWords) {
    var all = document.querySelectorAll('[class*="' + keyword + '" i]');
    var fallback = null, active = null, activeCount = 1e9, activeMatch = false;
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      var cls = ' ' + (el.className || '') + ' ';
      if (/review|comment|rating|feedback/i.test(cls)) continue;
      if (IS_SHEIN && sheinIsQuantityEl(el)) continue;
      var opts = el.querySelectorAll('li, button, [class*="item" i]');
      if (opts.length < 2) continue;
      var rect = el.getBoundingClientRect();
      var rendered = sheinElementIsVisible(el) && !sheinCovered(el);
      // SHEIN keeps hidden product/recommendation templates in the DOM.  A
      // hidden colour row is not a customer choice and must never block add.
      if (rendered) fallback = fallback || el;
      var inView = rect.bottom > 0 && rect.right > 0 &&
        rect.top < (document.documentElement.clientHeight || 0) &&
        rect.left < (document.documentElement.clientWidth || 0);
      if (!(inView && rendered)) continue;
      // Prefer the group whose heading matches the requested attribute so a
      // "نوع الموديلات" group never wins the size slot over the real "مقاس"
      // (cloud tray p-420303185). Same-tier tiebreak: fewest options.
      var matches = IS_SHEIN && sheinHeadingMatchesLabels(el, labelWords);
      var picked = isSelectedSwatchEl(el) && (!active || !isSelectedSwatchEl(active));
      var better;
      if (!active) better = true;
      else if (matches !== activeMatch) better = matches;
      else better = (opts.length < activeCount) || picked;
      if (better) { active = el; activeCount = opts.length; activeMatch = matches; }
    }
    if (__otlobliSheinDrawerPath === location.pathname && !active) return null;
    // SHEIN gives every colour tile an "item" class, so the selected tile can
    // otherwise win over its row. Return the row: all sibling icons must be
    // recognised both for selection and for the tapped-swatch lock.
    if (IS_SHEIN && keyword === 'color' && active && active.getAttribute('role') === 'radio') {
      var colorRow = active.parentElement;
      for (var cr = 0; cr < 4 && colorRow; cr++, colorRow = colorRow.parentElement) {
        if (colorRow.querySelectorAll('[role="radio"]').length >= 2) return colorRow;
      }
    }
    var base = active || fallback;
    if (base && active && labelWords) {
      var heads = base.querySelectorAll('div, span, p, h1, h2, h3, label, b, strong');
      for (var h = 0; h < heads.length; h++) {
        var headText = normalizedOptionText(heads[h].textContent).replace(/[:：]$/, '').toLowerCase();
        var exact = false;
        for (var lw = 0; lw < labelWords.length; lw++) {
          if (headText === labelWords[lw].toLowerCase()) { exact = true; break; }
        }
        if (!exact) continue;
        var group = heads[h].parentElement;
        for (var gh = 0; gh < 3 && group && (group === base || base.contains(group)); gh++) {
          if (group.querySelectorAll('li, button, [class*="item" i], img').length >= 2) return group;
          group = group.parentElement;
        }
      }
    }
    if (base) return base;
    if (labelWords) {
      var candidates = document.querySelectorAll('div, span, p, h1, h2, h3, label, b, strong');
      for (var j = 0; j < candidates.length; j++) {
        var text = (candidates[j].textContent || '').trim();
        if (!text || text.length > 20) continue;
        var matched = false;
        for (var w = 0; w < labelWords.length; w++) {
          if (text.indexOf(labelWords[w]) !== -1) { matched = true; break; }
        }
        if (!matched) continue;
        var scope = candidates[j].parentElement;
        for (var hop = 0; hop < 3 && scope; hop++) {
          var opts2 = scope.querySelectorAll('li, button, [class*="item" i], img');
          if (opts2.length >= 2 && sheinElementIsVisible(scope) && !sheinCovered(scope)) return scope;
          scope = scope.parentElement;
        }
      }
    }
    return null;
  }

  function isSelectedSwatchEl(el) {
    if (el.getAttribute('aria-selected') === 'true') return true;
    if (el.getAttribute('aria-checked') === 'true') return true;
    if (el.getAttribute('aria-pressed') === 'true') return true;
    var cls = ' ' + (el.className || '') + ' ';
    if (/\\s(selected|active|checked|chosen|cur|current|picked)\\s/i.test(cls)) return true;
    var input = el.tagName === 'INPUT' ? el : el.querySelector('input[type="radio"], input[type="checkbox"]');
    if (input && input.checked) return true;
    return false;
  }

  function looksLikeJunkValue(text) {
    if (!text) return true;
    if (/^(hot|new|sale|best|bestseller|#\\s*\\d+|\\-?\\d+%?)$/i.test(text.trim())) return true;
    return /^\\d{1,2}:\\d{2}(:\\d{2})?$/.test(text);
  }

  function sheinHasManyOptionChildren(el) {
    return !!(el && el.querySelectorAll &&
      el.querySelectorAll('li,button,[role="radio"],[role="option"],[role="button"],[class*="item" i]').length > 1);
  }

  function sheinSelectionLabel(el) {
    if (!el) return '';
    var label = el.getAttribute('aria-label') || el.getAttribute('title') ||
      el.getAttribute('data-color') || el.getAttribute('data-name') || el.getAttribute('data-value') ||
      el.getAttribute('data-attr-value') || '';
    label = normalizedOptionText(label);
    if (!label) {
      var innerImg = el.tagName === 'IMG' ? el : el.querySelector && el.querySelector('img');
      if (innerImg) label = normalizedOptionText(innerImg.getAttribute('alt') || innerImg.getAttribute('title') || '');
    }
    if (!label && !sheinHasManyOptionChildren(el)) label = normalizedOptionText(el.textContent);
    return label && label.length < 60 && !looksLikeJunkValue(label) ? label : '';
  }

  function sheinRgb(value) {
    var m = String(value || '').match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?/i);
    return m ? [+m[1], +m[2], +m[3], m[4] === undefined ? 1 : +m[4]] : null;
  }

  function sheinLooksVisuallySelected(el) {
    try {
      if (!sheinSelectionLabel(el) || sheinHasManyOptionChildren(el)) return false;
      var r = el.getBoundingClientRect();
      if (!r || r.width < 20 || r.height < 20 || r.width > 280 || r.height > 120) return false;
      var cs = window.getComputedStyle(el);
      var bg = sheinRgb(cs.backgroundColor);
      var fg = sheinRgb(cs.color);
      return !!(bg && bg[3] > 0.55 && bg[0] < 80 && bg[1] < 80 && bg[2] < 80 &&
        (!fg || (fg[0] > 150 && fg[1] > 150 && fg[2] > 150)));
    } catch (e) { return false; }
  }

  function getSelectedWithin(container) {
    if (!container) return '';
    var nodes = container.querySelectorAll('*');
    for (var j = -1; j < nodes.length; j++) {
      var el = j < 0 ? container : nodes[j];
      if (isSelectedSwatchEl(el)) {
        var label = sheinSelectionLabel(el);
        if (label) return label;
      }
    }
    var opts = container.querySelectorAll('li,button,[role="radio"],[role="option"],[role="button"],[class*="item" i]');
    for (var o = 0; o < opts.length; o++) {
      if (sheinLooksVisuallySelected(opts[o])) return sheinSelectionLabel(opts[o]);
    }
    return '';
  }

  function sheinSelectedQuantityOption(scope) {
    var picks = (scope || document).querySelectorAll('.goods-size__sizes-item.size-active,[data-attr_value][aria-checked="true"]');
    for (var i = 0; i < picks.length; i++) {
      if (!sheinIsQuantityEl(picks[i])) continue;
      var value = normalizedOptionText(picks[i].getAttribute('data-attr_value') || picks[i].textContent);
      if (value && value.length < 60) return value;
    }
    return '';
  }

  function normalizedOptionText(value) {
    return String(value || '').replace(/\\s+/g, ' ').trim();
  }

  function sheinPieceCountKey(value) {
    var text = normalizedOptionText(value).toUpperCase().replace(/\\s+/g, '');
    var match = text.match(/^(\\d+)(?:PC|PCS|PIECE|PIECES)$/) ||
      text.match(/^(?:PC|PCS|CP)(\\d+)$/);
    return match ? match[1] : '';
  }

  function sheinSimpleSize(value) {
    var text = normalizedOptionText(value);
    return /^(?:xxs|xs|s|m|l|xl|xxl|xxxl|one\\s*size|[2-9]\\d|[1-9]\\d{2})$/i.test(text) ? text : '';
  }

  function completeSelectedCompoundSize(container, selected) {
    if (container && selected) {
      var combinedUnconfirmed = false;
      var combinedTitles = document.querySelectorAll('.goods-size__title,[class*="size__title" i]');
      for (var c = 0; c < combinedTitles.length && c < 4; c++) {
        var heading = normalizedOptionText(combinedTitles[c].textContent);
        var headingKey = heading.replace(/\\s+/g, '').toLowerCase();
        if (headingKey !== 'لون/مقاس' && headingKey !== 'color/size' && headingKey !== 'colour/size') continue;
        var next = combinedTitles[c].nextElementSibling;
        var summary = normalizedOptionText(next && next.textContent);
        var scope = combinedTitles[c];
        for (var h = 0; !summary && h < 3 && scope && scope !== document.body; h++) {
          scope = scope.parentElement;
          var row = normalizedOptionText(scope && scope.textContent);
          if (row.indexOf(heading) === 0 && row.length < 60) summary = row.slice(heading.length).trim();
        }
        var chosen = summary.split('/');
        var first = normalizedOptionText(chosen[0]);
        var rest = normalizedOptionText(chosen.slice(1).join(' / '));
        if (summary.length < 60 && first === normalizedOptionText(selected) && rest) {
          combinedUnconfirmed = true;
          var selectedNodes = container.querySelectorAll('*');
          for (var s = 0; s < selectedNodes.length; s++) {
            if (!isSelectedSwatchEl(selectedNodes[s])) continue;
            var value = normalizedOptionText(selectedNodes[s].getAttribute('aria-label') ||
              selectedNodes[s].getAttribute('title') || selectedNodes[s].getAttribute('data-value') || selectedNodes[s].textContent);
            if (value === rest || (value.length < 60 && value.indexOf(rest) === 0)) return first + ' / ' + rest;
          }
        }
      }
      if (combinedUnconfirmed) return '';
    }
    var pieceKey = sheinPieceCountKey(selected);
    if (!container || !pieceKey) return selected;
    var nodes = container.querySelectorAll('*');
    var pickedSize = '';
    for (var i = 0; i < nodes.length; i++) {
      if (!isSelectedSwatchEl(nodes[i])) continue;
      var value = nodes[i].getAttribute('aria-label') || nodes[i].getAttribute('title') ||
        nodes[i].getAttribute('data-name') || nodes[i].getAttribute('data-value') ||
        nodes[i].getAttribute('data-attr-value') || nodes[i].textContent || '';
      pickedSize = pickedSize || sheinSimpleSize(value);
      var control = nodes[i].closest &&
        nodes[i].closest('button, li, [role="radio"], [role="option"], [role="button"], [class*="item" i]');
      if (!control || !sheinElementIsVisible(control)) continue;
      var full = normalizedOptionText(control.textContent);
      if (!full || full.length > 60 || !/[\\/+|]/.test(full)) continue;
      var parts = full.split(/\\s*[\\/+|]\\s*/);
      var hasPiece = false, hasSize = false;
      for (var p = 0; p < parts.length; p++) {
        if (sheinPieceCountKey(parts[p]) === pieceKey) hasPiece = true;
        else if (sheinSimpleSize(parts[p])) hasSize = true;
      }
      if (hasPiece && hasSize) return full;
    }
    return pickedSize ? pickedSize + ' / ' + selected : selected;
  }

  function getAttrLabelValue(container, labelWords) {
    if (!container) return '';
    var scope = container.parentElement || container;
    for (var hop = 0; hop < 3 && scope; hop++) {
      var nodes = scope.querySelectorAll('*');
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (container.contains(el) && el !== container) continue;
        var t = (el.textContent || '').trim();
        if (!t || t.length > 70) continue;
        for (var w = 0; w < labelWords.length; w++) {
          var word = labelWords[w];
          var idx = t.toLowerCase().indexOf(word.toLowerCase());
          if (idx === -1) continue;
          var rest = t.slice(idx + word.length).replace(/^[\\s:：\\-–(]+/, '').replace(/[)\\s]+$/, '').trim();
          if (rest && rest.length < 40 && rest.toLowerCase() !== word.toLowerCase() && !looksLikeJunkValue(rest)) return rest;
        }
      }
      scope = scope.parentElement;
    }
    return '';
  }

  function getColorHeadingLabel(container) {
    if (!container) return '';
    var scope = container.parentElement;
    for (var hop = 0; hop < 3 && scope; hop++) {
      var candidates = scope.querySelectorAll(
        '[class*="color" i] [class*="name" i], [class*="color" i] [class*="value" i], ' +
        '[class*="selected-attr" i], [class*="attr-value" i], [class*="sku-name" i]'
      );
      for (var i = 0; i < candidates.length; i++) {
        if (container.contains(candidates[i])) continue;
        var text = (candidates[i].textContent || '').trim();
        if (text && text.length > 0 && text.length < 60 && !looksLikeJunkValue(text)) return text;
      }
      scope = scope.parentElement;
    }
    return '';
  }

  function isColorBadgeEl(el) {
    if (!el || !el.getBoundingClientRect) return false;
    var text = ((el.textContent || '') + '').replace(/\\s+/g, ' ').trim();
    var cls = ' ' + ((el.className || '') + '').toLowerCase() + ' ';
    var r = el.getBoundingClientRect();
    var compact = r.width > 0 && r.width <= 96 && r.height > 0 && r.height <= 48;
    // A circular swatch wrapper can contain only the text of its HOT child.
    // Do not classify that whole 40-60px color tile as the badge itself.
    var cs = window.getComputedStyle(el);
    var before = window.getComputedStyle(el, '::before');
    var hasSwatchVisual = Math.min(r.width, r.height) >= 32 && (
      el.tagName === 'IMG' || !!el.querySelector('img') || /url\\(/.test(cs.backgroundImage || '') || /url\\(/.test(before.backgroundImage || '')
    );
    if (hasSwatchVisual) return false;
    if (compact && /^(hot|new|sale|best|bestseller|\\-?\\d+%?)$/i.test(text)) return true;
    return compact && /(?:^|[\\s_-])(hot|badge|tag|label|discount|promo|best|bestseller)(?:$|[\\s_-])/i.test(cls);
  }

  function isLikelyBadgeImageUrl(src) {
    if (!src) return false;
    return /(?:hot|badge|tag|label|discount|sprite|icon|promo|rank|best)/i.test(src) &&
      !/ltwebstatic|img\\.shein/i.test(src);
  }

  function swatchBackgroundUrl(el, pseudo) {
    try {
      var bg = window.getComputedStyle(el, pseudo || null).backgroundImage || '';
      var match = bg.match(/url\\(["']?(.*?)["']?\\)/);
      return match && match[1] ? match[1] : '';
    } catch (e) {
      return '';
    }
  }

  function rankedSwatchImageFrom(el) {
    if (!el) return '';
    var scope = isColorBadgeEl(el) && el.parentElement ? el.parentElement : el;
    var descendants = scope.querySelectorAll ? scope.querySelectorAll('*') : [];
    var bestSrc = '';
    var bestScore = -1;
    for (var index = -1; index < descendants.length; index++) {
      var node = index < 0 ? scope : descendants[index];
      if (!node || isColorBadgeEl(node)) continue;
      var rect = node.getBoundingClientRect();
      var width = rect.width || 0;
      var height = rect.height || 0;
      if (width < 12 || height < 12 || width > 120 || height > 120) continue;
      var sources = [];
      if (node.tagName === 'IMG') sources.push(realImgSrc(node));
      sources.push(swatchBackgroundUrl(node, null));
      sources.push(swatchBackgroundUrl(node, '::before'));
      sources.push(swatchBackgroundUrl(node, '::after'));
      for (var si = 0; si < sources.length; si++) {
        var src = sources[si];
        if (!src || /blank|placeholder/i.test(src) || isLikelyBadgeImageUrl(src)) continue;
        var minSide = Math.min(width, height);
        var maxSide = Math.max(width, height);
        if (minSide < 18) continue;
        var squareBonus = minSide / Math.max(maxSide, 1) >= 0.62 ? 900 : 0;
        var score = Math.min(width, 96) * Math.min(height, 96) + squareBonus;
        if (/ltwebstatic|img\\.shein|shein/i.test(src)) score += 120;
        if (score > bestScore) {
          bestScore = score;
          bestSrc = src;
        }
      }
    }
    return bestSrc;
  }

  function swatchImageFrom(el) {
    // Some valid SHEIN forms, including Curvy quick-add, expose only a size
    // group. A missing colour control is not an error and must not abort the
    // whole add-to-cart flow while trying to read its thumbnail.
    if (!el) return '';
    var rankedImage = rankedSwatchImageFrom(el);
    if (rankedImage) return rankedImage;
    var scope = isColorBadgeEl(el) && el.parentElement ? el.parentElement : el;
    var imgList = scope.tagName === 'IMG' ? [scope] : scope.querySelectorAll('img');
    var bestSrc = '';
    var bestArea = -1;
    for (var ii = 0; ii < imgList.length; ii++) {
      var candImg = imgList[ii];
      if (isColorBadgeEl(candImg)) continue;
      var candSrc = realImgSrc(candImg);
      if (!candSrc || isLikelyBadgeImageUrl(candSrc)) continue;
      var cr = candImg.getBoundingClientRect();
      var cw = cr.width || candImg.naturalWidth || 0;
      var ch = cr.height || candImg.naturalHeight || 0;
      if (cw > 0 && ch > 0 && Math.min(cw, ch) < 18) continue;
      var candArea = cw * ch;
      if (candArea > bestArea) { bestArea = candArea; bestSrc = candSrc; }
    }
    if (bestSrc) return bestSrc;
    var bg = isColorBadgeEl(scope) ? '' : window.getComputedStyle(scope).backgroundImage;
    var match = bg && bg.match(/url\\(["']?(.*?)["']?\\)/);
    if (match && match[1] && !/blank|placeholder/i.test(match[1]) && !isLikelyBadgeImageUrl(match[1])) return match[1];
    var children = scope.children;
    for (var c = 0; c < (children ? children.length : 0); c++) {
      if (isColorBadgeEl(children[c])) continue;
      var childBg = window.getComputedStyle(children[c]).backgroundImage;
      var childMatch = childBg && childBg.match(/url\\(["']?(.*?)["']?\\)/);
      if (childMatch && childMatch[1] && !/blank|placeholder/i.test(childMatch[1]) && !isLikelyBadgeImageUrl(childMatch[1])) return childMatch[1];
    }
    return '';
  }

  function ringScore(el) {
    var cs = window.getComputedStyle(el);
    var score = 0;
    var bw = Math.max(parseFloat(cs.borderTopWidth) || 0, parseFloat(cs.borderBottomWidth) || 0,
      parseFloat(cs.borderLeftWidth) || 0, parseFloat(cs.borderRightWidth) || 0);
    if (bw >= 2) score += bw;
    var ow = parseFloat(cs.outlineWidth) || 0;
    if (ow >= 1 && cs.outlineStyle && cs.outlineStyle !== 'none') score += ow + 1;
    if (cs.boxShadow && cs.boxShadow !== 'none') score += 2;
    return score;
  }

  function collectSwatchEls(container) {
    var nodes = container.querySelectorAll('*');
    var out = [];
    for (var n = 0; n < nodes.length; n++) {
      var el = nodes[n];
      var r = el.getBoundingClientRect();
      if (r.width <= 0 || r.width > 80 || r.height <= 0 || r.height > 80) continue;
      if (isColorBadgeEl(el) && !swatchImageFrom(el)) continue;
      var hasImg = el.tagName === 'IMG' || !!el.querySelector('img') ||
        /url\\(/.test(window.getComputedStyle(el).backgroundImage || '');
      if (hasImg && swatchImageFrom(el)) out.push(el);
    }
    return out;
  }

  function getSelectedColorSwatchImage(container, selectedName) {
    if (!container) return '';
    var nodes = container.querySelectorAll('*');
    for (var j = -1; j < nodes.length; j++) {
      var selectedNode = j < 0 ? container : nodes[j];
      if (!isSelectedSwatchEl(selectedNode)) continue;
      // SHEIN's selected colour <li> contains visual wrapper/inner nodes
      // whose class names include "item". It is still one radio choice.
      if (sheinHasManyOptionChildren(selectedNode) && selectedNode.getAttribute('role') !== 'radio') continue;
      var im1 = swatchImageFrom(selectedNode);
      if (im1) return im1;
    }
    if (selectedName && !isGenericColorName(selectedName)) {
      var want = selectedName.trim().toLowerCase();
      var swA = collectSwatchEls(container);
      for (var a = 0; a < swA.length; a++) {
        var lbl = swA[a].getAttribute('aria-label') || swA[a].getAttribute('title') || '';
        var innerImgA = swA[a].tagName === 'IMG' ? swA[a] : swA[a].querySelector('img');
        if (!lbl && innerImgA) lbl = innerImgA.getAttribute('alt') || innerImgA.getAttribute('title') || '';
        if (lbl && lbl.trim().toLowerCase() === want) {
          var imA = swatchImageFrom(swA[a]);
          if (imA) return imA;
        }
      }
    }
    var swB = collectSwatchEls(container);
    var bestEl = null;
    var bestRing = 0;
    var ringCount = 0;
    for (var b = 0; b < swB.length; b++) {
      var rs = ringScore(swB[b]);
      if (rs >= 2) ringCount++;
      if (rs > bestRing) { bestRing = rs; bestEl = swB[b]; }
    }
    if (bestEl && bestRing >= 2 && ringCount === 1) {
      var imB = swatchImageFrom(bestEl);
      if (imB) return imB;
    }
    return '';
  }

  function isGenericColorName(text) {
    if (!text) return true;
    var t = text.toLowerCase();
    return /ألوان متعددة|متعدد الألوان|متعدد الالوان|multi-?colou?r|multi colou?r|assorted/.test(t);
  }

  function sheinPageColorHeading() {
    var heads = document.querySelectorAll('.main-sales-attr-container');
    for (var i = 0; i < heads.length && i < 4; i++) {
      if (!sheinElementIsVisible(heads[i])) continue;
      var match = normalizedOptionText(heads[i].textContent).match(/^(?:اللون|لون|colou?r)\s*[:：]\s*(.{1,39})$/i);
      if (match && !looksLikeJunkValue(match[1])) return normalizedOptionText(match[1]);
    }
    return '';
  }

  function getColorState() {
    var container = findOptionContainer('color', OTLOBLI_COLOR_LABELS);
    var pageVal = sheinDrawerCompoundSizeState() ? '' : sheinPageColorHeading();
    var labelVal = pageVal || getAttrLabelValue(container, ['اللون', 'Color', 'color']) || getColorHeadingLabel(container);
    var swatchVal = getSelectedWithin(container);
    var selected;
    if (swatchVal && !isGenericColorName(swatchVal)) selected = swatchVal;
    else if (labelVal && !isGenericColorName(labelVal)) selected = labelVal;
    else selected = labelVal || swatchVal;
    selected = sheinSkuMemo('c', selected);
    return { exists: !!container, selected: selected, image: getSelectedColorSwatchImage(container, selected) };
  }

  function getSizeOptions(container) {
    var available = [];
    var unavailable = [];
    if (!container) return { available: available, unavailable: unavailable };
    var opts = container.querySelectorAll('li, button, [class*="item" i]');
    for (var i = 0; i < opts.length; i++) {
      var el = opts[i];
      if (sheinHasManyOptionChildren(el)) continue;
      var label = (el.getAttribute('aria-label') || el.getAttribute('title') || el.textContent || '').trim();
      if (!label || label.length > 40 || looksLikeJunkValue(label)) continue;
      var cls = ' ' + (el.className || '') + ' ';
      var isDisabled = el.getAttribute('aria-disabled') === 'true' ||
        /\\s(disable|disabled|soldout|sold-out|out-of-stock|unavailable)\\s/i.test(cls);
      var bucket = isDisabled ? unavailable : available;
      if (bucket.indexOf(label) === -1) bucket.push(label);
    }
    return { available: available, unavailable: unavailable };
  }

  function sheinDrawerCompoundSizeState() {
    if (__otlobliSheinDrawerPath !== location.pathname) return null;
    var groups = document.querySelectorAll('.SIZE_ITEM_HOOK');
    var picked = [], available = [], unavailable = [], found = 0;
    for (var i = 0; i < groups.length && i < 6; i++) {
      var group = groups[i];
      if (!sheinElementIsVisible(group) || sheinCovered(group)) continue;
      if (sheinIsQuantityEl(group)) continue;
      var r = group.getBoundingClientRect();
      if (r.bottom <= 0 || r.right <= 0 || r.top >= innerHeight || r.left >= innerWidth) continue;
      var opts = getSizeOptions(group);
      if (!opts.available.length && !opts.unavailable.length) continue;
      found++;
      available = opts.available;
      unavailable = opts.unavailable;
      var value = getSelectedWithin(group);
      if (!value && available.length === 1 && !unavailable.length) value = available[0];
      if (!value) return { exists: true, selected: '', available: available, unavailable: unavailable };
      if (picked.indexOf(value) < 0) picked.push(value);
    }
    if (!found) return null;
    if (picked.length === 2 && sheinPieceCountKey(picked[0]) && sheinSimpleSize(picked[1])) picked.reverse();
    return { exists: true, selected: picked.join(' / '), available: available, unavailable: unavailable };
  }

  function getSizeState() {
    var drawerState = sheinDrawerCompoundSizeState();
    if (drawerState) {
      if (drawerState.selected) drawerState.selected = sheinSkuMemo('s', drawerState.selected);
      return drawerState;
    }
    var container = findOptionContainer('size', OTLOBLI_SIZE_LABELS);
    var opts = getSizeOptions(container);
    var selected = completeSelectedCompoundSize(container, getSelectedWithin(container));
    if (!selected && opts.available.length === 1 && opts.unavailable.length === 0) selected = opts.available[0];
    selected = sheinSkuMemo('s', selected);
    return {
      exists: !!container,
      selected: selected,
      available: opts.available,
      unavailable: opts.unavailable,
    };
  }

  function sheinCovered(el) {
    try {
      var r = el.getBoundingClientRect();
      var x = r.left + r.width / 2, y = r.top + r.height / 2;
      var vw = document.documentElement.clientWidth || 0;
      var vh = document.documentElement.clientHeight || 0;
      if (x < 0 || y < 0 || x > vw || y > vh) return false;
      var top = document.elementFromPoint(x, y);
      if (!top) return false;
      return !(top === el || el.contains(top) || top.contains(el));
    } catch (e) { return false; }
  }

  var __otlobliSkuMemo = {};
  var __otlobliSheinDrawerPath = '';
  function sheinSkuMemo(key, value) {
    var m = __otlobliSkuMemo[location.pathname] || (__otlobliSkuMemo[location.pathname] = {});
    if (value) m[key] = value;
    return m[key] || '';
  }

  ${OTLOBLI_SKU_TAP_JS}

  function sheinSkuSelectionEntry() {
    if (!IS_SHEIN || !document.body) return null;
    var hook = document.querySelector('.j-select-to-buy');
    if (hook && sheinElementIsVisible(hook)) return hook;
    var titles = document.querySelectorAll('.goods-size__title,[class*="size__title" i]');
    for (var h = 0; h < titles.length && h < 4; h++) {
      var key = normalizedOptionText(titles[h].textContent).replace(/\\s+/g, '').toLowerCase();
      // Device-measured: SHEIN prints this heading in either order.
      if (key !== 'لون/مقاس' && key !== 'مقاس/لون' && key !== 'color/size' &&
          key !== 'size/color' && key !== 'colour/size' && key !== 'size/colour') continue;
      var row = titles[h].closest('.goods-detail__top-other') || titles[h].parentElement;
      if (!row || !sheinElementIsVisible(row) || sheinCovered(row)) continue;
      return row;
    }
    var nodes = document.querySelectorAll('li, div, span, p, a, button');
    for (var i = 0; i < nodes.length; i++) {
      var el = nodes[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      if (el.children && el.children.length > 3) continue;
      var t = (el.textContent || '').replace(/\\s+/g, ' ').trim();
      if (!t || t.length > 30) continue;
      if (OTLOBLI_SKU_PROMPT.test(t) && sheinElementIsVisible(el) && !sheinCovered(el)) return el;
    }
    return null;
  }

  function sheinOpenSkuDrawer() {
    sheinResolvedShippingRootCacheAt = 0;
    var shippingRoot = sheinShippingInteractionRoot;
    if (!(shippingRoot && shippingRoot.isConnected && sheinElementIsPainted(shippingRoot))) {
      shippingRoot = sheinResolvedShippingUiRoot();
    }
    if (shippingRoot) {
      __otlobliSheinDrawerPath = '';
      __otlobliSkuMemo[location.pathname] = {};
      showMessage(document.getElementById('otlobli-add-btn'), 'أغلق قائمة الشحن أولاً');
      return true;
    }
    if (sheinDrawerCompoundSizeState()) return false;
    var entry = sheinSkuSelectionEntry();
    if (entry) {
      // The control TOGGLES (device-measured): pressing it while the groups
      // are open shuts them. Adopt that state and fall through instead.
      if (sheinLowestOptionGroup()) {
        __otlobliSheinDrawerPath = location.pathname;
        return false;
      }
      __otlobliSheinDrawerPath = location.pathname;
      __otlobliSkuMemo[location.pathname] = {};
      // Bring the control on screen before pressing it: at rest it sits below
      // the fold, and a press aimed at clamped coordinates lands on whatever
      // happens to be at the viewport edge.
      var ctrl = sheinSkuPromptNode(entry) || entry;
      sheinClearOptionsFromButton(ctrl);
      setTimeout(function () {
        sheinTapElement(ctrl);
        sheinRevealSkuOptions(0);
      }, 260);
      return true;
    }
    // No entry resolved, yet a range ("من") price is still printed - that only
    // happens while NO variant is committed, so refuse rather than ship the low
    // end with a stale remembered combination. See v86.43 in the freeze doc.
    if (sheinHeadPriceIsRange()) {
      __otlobliSkuMemo[location.pathname] = {};
      // Telling the shopper to choose while the chips sit behind our own
      // floating button is the same dead end as doing nothing (device-measured
      // on 3-Tier-Large-Capacity: the only group lived at 717-753, under both
      // the add button at 620 and the nav at 684).
      sheinClearOptionsFromButton(sheinLowestOptionGroup());
      showMessage(document.getElementById('otlobli-add-btn'), 'حدد الخيارات أولاً');
      return true;
    }
    return false;
  }

  // Centring was not enough: our own floating add button covered the very chips
  // this message tells the shopper to tap (device-measured).
  function sheinRevealSizeOptions() {
    var group = findOptionContainer('size', OTLOBLI_SIZE_LABELS);
    if (!group) return;
    try {
      sheinClearOptionsFromButton(sheinLowestOptionGroup() || group);
      var control = group.querySelector('button:not([disabled]),[role="option"],li');
      if (control && control.focus) control.focus({ preventScroll: true });
    } catch (e) {}
  }

  function looksLikeProductPage() {
    if (IS_TEMU) {
      if (/goods/i.test(location.pathname)) return true;
      try { return !!document.querySelector('[class*="curPrice" i]'); } catch (e) { return false; }
    }
    return /-p-\\d+/i.test(location.pathname);
  }

  function preloadImage(url, timeoutMs) {
    return new Promise(function (resolve) {
      if (!url) { resolve(false); return; }
      var done = false;
      var img = new Image();
      var timer = setTimeout(function () {
        if (!done) { done = true; resolve(false); }
      }, timeoutMs || 2500);
      img.onload = function () { if (!done) { done = true; clearTimeout(timer); resolve(true); } };
      img.onerror = function () { if (!done) { done = true; clearTimeout(timer); resolve(false); } };
      img.src = url;
    });
  }

  function ensureOverlayStyle() {
    if (document.getElementById('otlobli-overlay-style')) return;
    var style = document.createElement('style');
    style.id = 'otlobli-overlay-style';
    style.textContent = '@keyframes otlobli-spin{to{transform:rotate(360deg)}}' +
      '@keyframes otlobli-pop{0%{transform:scale(.86);opacity:0}100%{transform:scale(1);opacity:1}}' +
      '@keyframes otlobli-fade-out{to{opacity:0}}';
    document.head.appendChild(style);
  }

  // A small modal that blocks all touches/clicks behind it while we fetch and
  // verify the chosen product photo - this is the "freeze + load" step the
  // app side waits on before the item actually lands in the otlobli cart.
  function showAddingOverlay(payload) {
    ensureOverlayStyle();
    var existing = document.getElementById('otlobli-overlay');
    if (existing) existing.remove();
    var vp = viewportSize();
    document.body.style.overflow = 'hidden';

    var overlay = document.createElement('div');
    overlay.id = 'otlobli-overlay';
    overlay.setAttribute('data-shown-at', String(Date.now()));
    // One below max (otlobli-nav/back-btn/add-btn all sit at the true max) so
    // this blocking overlay can never end up painted on top of - and
    // swallowing taps meant for - otlobli's own nav bar. Confirmed real: a
    // user could only ever get the cart tab to respond after first bouncing
    // through another tab, exactly the symptom of an overlay occasionally
    // winning the stacking tie and eating the tap.
    overlay.style.cssText = 'position:fixed;left:0;top:0;width:' + vp.width + 'px;height:' + vp.height + 'px;' +
      'background:rgba(13,18,22,.42);z-index:2147483646;display:flex;align-items:center;justify-content:center;';
    overlay.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });
    overlay.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); }, true);

    var card = document.createElement('div');
    card.style.cssText = 'background:transparent;border:0;border-radius:0;padding:0 28px;width:min(86vw,340px);' +
      'display:flex;flex-direction:column;align-items:center;gap:8px;animation:otlobli-pop .22s ease-out;' +
      'box-shadow:none;color:#fff;font-family:Cairo,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;text-shadow:0 1px 8px rgba(0,0,0,.28);';

    var thumbWrap = document.createElement('div');
    thumbWrap.style.cssText = 'width:34px;height:34px;border-radius:50%;overflow:hidden;background:transparent;' +
      'border:0;position:relative;margin-bottom:2px;';
    var thumb = document.createElement('img');
    thumb.id = 'otlobli-overlay-thumb';
    thumb.style.cssText = 'width:100%;height:100%;object-fit:cover;display:none;';
    thumbWrap.appendChild(thumb);
    var spinner = document.createElement('div');
    spinner.id = 'otlobli-overlay-spinner';
    spinner.style.cssText = 'position:absolute;inset:0;border-radius:50%;border:3px solid rgba(255,255,255,.24);' +
      'border-top-color:#fff;animation:otlobli-spin .8s linear infinite;';
    thumbWrap.appendChild(spinner);

    var title = document.createElement('div');
    title.id = 'otlobli-overlay-title';
    title.style.cssText = 'font-size:14px;font-weight:700;color:#fff;text-align:center;direction:rtl;line-height:1.45;max-width:100%;';

    card.appendChild(thumbWrap);
    card.appendChild(title);

    var meta = document.createElement('div');
    meta.id = 'otlobli-overlay-meta';
    meta.style.cssText = 'font-size:12px;color:rgba(255,255,255,.82);direction:rtl;line-height:1.45;text-align:center;';
    card.appendChild(meta);

    var status = document.createElement('div');
    status.id = 'otlobli-overlay-status';
    status.style.cssText = 'font-size:12px;color:#d8f7e8;font-weight:700;text-align:center;direction:rtl;margin-top:2px;line-height:1.45;';
    card.appendChild(status);



    overlay.appendChild(card);
    document.body.appendChild(overlay);
    updateOverlayContent(payload, 'جاري التأكد من بيانات المنتج...');
  }

  function updateOverlayContent(payload, statusText) {
    var thumb = document.getElementById('otlobli-overlay-thumb');
    if (thumb && thumb.getAttribute('src') !== payload.image) thumb.src = payload.image || '';

    var title = document.getElementById('otlobli-overlay-title');
    if (title) {
      var titleText = payload.title || 'المنتج';
      title.textContent = titleText.length > 40 ? titleText.slice(0, 40) + '…' : titleText;
    }

    var meta = document.getElementById('otlobli-overlay-meta');
    if (meta) {
      var metaParts = [];
      if (payload.color) metaParts.push(payload.color);
      if (payload.size) metaParts.push(payload.size);
      meta.textContent = metaParts.join(' · ');
      meta.style.display = metaParts.length ? 'block' : 'none';
    }

    var status = document.getElementById('otlobli-overlay-status');
    if (status && statusText) status.textContent = statusText;

    var diag = document.getElementById('otlobli-overlay-internal-diag-disabled');
    if (diag) {
      diag.innerHTML = '';
      var diagFields = [
        ['اسم', !!payload.title],
        ['صورة', !!payload.image],
        ['أيقونة اللون', !!payload.colorImageFound],
        ['سعر', payload.priceUsd > 0],
        ['لون', !!payload.color],
        ['مقاس', !!payload.size],
      ];
      for (var d = 0; d < diagFields.length; d++) {
        var chip = document.createElement('span');
        var ok = diagFields[d][1];
        chip.textContent = (ok ? '✓ ' : '✗ ') + diagFields[d][0];
        chip.style.cssText = 'font-size:10px;font-weight:700;padding:2px 6px;border-radius:8px;direction:rtl;' +
          (ok ? 'background:#e7f7ef;color:#006948;' : 'background:#ffdad6;color:#ba1a1a;');
        diag.appendChild(chip);
      }
    }
  }

  function markOverlaySuccess() {
    var status = document.getElementById('otlobli-overlay-status');
    if (status) status.textContent = '✓ تم جذب المنتج بنجاح';
    var spinner = document.getElementById('otlobli-overlay-spinner');
    if (spinner) {
      spinner.style.animation = 'none';
      spinner.style.borderColor = '#1aab6f';
    }
  }

  function markOverlayFailure() {
    var status = document.getElementById('otlobli-overlay-status');
    if (status) status.textContent = 'تعذّرت إضافة المنتج — حاول مرة ثانية';
    var spinner = document.getElementById('otlobli-overlay-spinner');
    if (spinner) {
      spinner.style.animation = 'none';
      spinner.style.borderColor = '#ba1a1a';
    }
  }

  function clearAddSafetyTimer() {
    if (!window.__otlobliAddSafetyTimer) return;
    clearTimeout(window.__otlobliAddSafetyTimer);
    window.__otlobliAddSafetyTimer = 0;
  }

  function failAddFlow() {
    clearAddSafetyTimer();
    markOverlayFailure();
    removeOverlay(900);
    var addButton = document.getElementById('otlobli-add-btn');
    if (addButton) showMessage(addButton, 'تعذّرت إضافة المنتج — حاول مرة ثانية');
  }

  function removeOverlay(delay) {
    setTimeout(function () {
      var overlay = document.getElementById('otlobli-overlay');
      if (overlay) {
        overlay.style.animation = 'otlobli-fade-out .25s ease-in forwards';
        setTimeout(function () { overlay.remove(); }, 250);
      }
      otlobliReleaseAddingScrollLock();
    }, delay || 0);
  }

  // showAddingOverlay() locks page scrolling, and removeOverlay() used to be the
  // only way back. Any path that skipped it - an error, a back gesture, a Temu
  // SPA route change mid-add - left the product page permanently unscrollable.
  // Observed on the real Note 8: a Temu product page would not move a single
  // pixel while the site itself was alive, so the customer could never reach
  // the size options below the fold and the item was added with none chosen.
  // Restore on both elements, since the scrolling box differs between stores.
  function otlobliReleaseAddingScrollLock() {
    try { if (document.body) document.body.style.overflow = ''; } catch (e) {}
    try { if (document.documentElement) document.documentElement.style.overflow = ''; } catch (e) {}
  }

  // Self-heal: whatever went wrong, a scroll lock with no overlay on screen is
  // never correct. Cheap enough for the low-end tick (one lookup + one read).
  function otlobliHealOrphanScrollLock() {
    if (document.getElementById('otlobli-overlay')) return;
    var bodyLocked = document.body && document.body.style.overflow === 'hidden';
    var rootLocked = document.documentElement && document.documentElement.style.overflow === 'hidden';
    if (!bodyLocked && !rootLocked) return;
    if (IS_SHEIN && (sheinShippingBodyLockState || sheinShippingUiLikelyOpen())) return;
    otlobliReleaseAddingScrollLock();
  }

  // جذب تيمو
  // ينظّف رموز التحكم بالاتجاه غير المرئية (RLM/LRM/ALM وعزل Unicode Bidi)
  // التي تدرجها تيمو حول النص العربي فتُفشل === والـregex رغم تطابق الشكل.
  function temuCleanText(s) {
    return (s || '')
      .replace(/[\\u200e\\u200f\\u061c\\u2066\\u2067\\u2068\\u2069\\ufeff\\u200b]/g, '')
      .replace(/\\s+/g, ' ')
      .trim();
  }
  // Quantity is a sibling of color/size in Temu's current product DOM. Keep
  // that label out of captured options without changing browsing behavior.
  function temuStripQuantity(value) {
    var v = temuCleanText(value).replace(/(?:\\u0627\\u0644\\u0643\\u0645\\u064a\\u0629|\\u0643\\u0645\\u064a\\u0629|quantity|qty)\\s*[:：]?\\s*\\d*.*$/i, '');
    return temuCleanText(v);
  }
  // يُرفق اللون/المقاس المختارين برابط المنتج كمعاملات otlobli_* (تُتجاهَل
  // من تيمو تماماً - معاملات مجهولة بلا أي تأثير على تحميل الصفحة)، لتُقرأ
  // لاحقاً عند إعادة فتح نفس الرابط (temuAutoReselectFromLink) فيُعاد اختيار
  // نفس اللون/المقاس تلقائياً بدل صفحة افتراضية بلا اختيار.
  function temuLooksLikePriceText(text) {
    var txt = temuCleanText(text || '');
    if (!txt || txt.length > 220) return false;
    if (!/[0-9٠-٩]/.test(txt)) return false;
    return /(?:US\\$|\\$|USD|SAR|QAR|AED|KWD|BHD|OMR|ريال|دولار|ر\\.? ?س|ر\\.? ?ق|د\\.? ?إ|د\\.? ?ك)/i.test(txt);
  }

  function temuContainsPrice(el) {
    if (!el) return false;
    try {
      var priceSelector = '[class*="curPrice" i], [class*="price" i], [class*="amount" i], [data-testid*="price" i]';
      if (el.matches && el.matches(priceSelector)) return true;
      if (el.querySelector && el.querySelector(priceSelector)) return true;
      return temuLooksLikePriceText(el.textContent || '');
    } catch (e) {
      return false;
    }
  }

  function temuLooksLikeProductContent(el) {
    if (!el) return false;
    try {
      if (temuContainsPrice(el)) return true;
      var text = temuCleanText(el.textContent);
      if (text.length > 80 && /تم البيع|الشحن|مستودع|محلي|خصم|اللون|الكمية|sold|shipping|colour|color|quantity/i.test(text) &&
          /[0-9٠-٩]|ر\\.?\\s*س|ريال|SAR/i.test(text)) {
        return true;
      }
      if (el.querySelector && el.querySelector('[class*="curPrice" i], [class*="goods" i], [class*="product" i], h1, h2')) {
        return true;
      }
      var imgs = el.querySelectorAll ? el.querySelectorAll('img') : [];
      var largeProductImages = 0;
      for (var i = 0; i < imgs.length; i++) {
        var src = imgs[i].currentSrc || imgs[i].src || '';
        if (!/kwcdn|temu/i.test(src)) continue;
        var r = imgs[i].getBoundingClientRect ? imgs[i].getBoundingClientRect() : { width: 0, height: 0 };
        if (r.width >= 90 && r.height >= 90) largeProductImages++;
      }
      return largeProductImages >= 1 && text.length > 25 &&
        /تم البيع|الشحن|مستودع|محلي|خصم|اللون|الكمية|sold|shipping|colour|color|quantity/i.test(text);
    } catch (e) {
      return false;
    }
  }

  function otlobliBuildDeepLink(href, color, size) {
    try {
      var sep = href.indexOf('?') >= 0 ? '&' : '?';
      var parts = [];
      if (color) parts.push('otlobli_color=' + encodeURIComponent(color));
      if (size) parts.push('otlobli_size=' + encodeURIComponent(size));
      if (!parts.length) return href;
      return href + sep + parts.join('&');
    } catch (e) {
      return href;
    }
  }
  // العنوان من og:title (نشيل لاحقة " - Temu Canada")، السعر من عنصر صنفه
  // curPrice- (مؤكّد من التشخيص)، الصورة من og:image أو أكبر صورة kwcdn.
  // السعر يُحوَّل للدولار حسب العملة الظاهرة (الدينار مثبّت، الكندي تقريبي).
  function temuTitle() {
    var og = getMeta('og:title') || '';
    return og.replace(/\\s*[-|–—]\\s*Temu\\b.*$/i, '').replace(/\\s+/g, ' ').trim();
  }
  // تحويل شامل لأي عملة قد تظهر حسب دولة الـVPN العشوائية → دولار. عملات
  // الخليج/الأردن مثبّتة (تحويل دقيق)؛ الباقي تقريبي. **العملة المجهولة تُرجع 0
  // فيمنع النظام الإضافة** (لا يدخل سعر خاطئ أبداً = خربطة صفر).
  // Temu keeps the PDP entry price mounted after a SKU changes.  The active
  // option drawer owns the selected variant's live price, so read that small,
  // visible root first and only then fall back to the PDP's curPrice.
  function temuActiveSkuPriceText() {
    var dialogs = document.querySelectorAll('[role="dialog"]');
    var first = Math.max(0, dialogs.length - 8);
    for (var d = dialogs.length - 1; d >= first; d--) {
      var dialog = dialogs[d];
      if (!temuProductOptionDialog(dialog)) continue;
      var rect = dialog.getBoundingClientRect();
      var style = window.getComputedStyle(dialog);
      if (rect.width < 1 || rect.height < 1 || style.display === 'none' ||
          style.visibility === 'hidden' || parseFloat(style.opacity || '1') <= 0.01) continue;
      var selectors = [
        '[class*="salePriceRich" i]',
        '[class*="currentPrice" i]',
        '[class*="curPrice" i]'
      ];
      for (var s = 0; s < selectors.length; s++) {
        var priceEl = dialog.querySelector(selectors[s]);
        var priceText = temuCleanText(priceEl && priceEl.textContent);
        if (priceText.length <= 28 && temuLooksLikePriceText(priceText)) return priceText;
      }
    }
    return '';
  }
  function temuPriceUsd() {
    var best = temuActiveSkuPriceText();
    var els = document.querySelectorAll('[class*="curPrice" i]');
    for (var i = 0; !best && i < els.length; i++) {
      var t = (els[i].textContent || '').trim();
      if (t.length <= 28 && /[0-9]/.test(t)) { best = t; break; }
    }
    if (!best) return 0;
    var num = parseFloat(best.replace(/[^0-9.]/g, ''));
    if (!(num > 0) || !isFinite(num)) return 0;
    var s = best;
    var rate = 0;                                   // 0 = عملة مجهولة → يمنع
    // رموز/رموز عملات مميّزة أولاً (CA$ قبل $ المجرّد).
    if (/CA\\$|CAD/i.test(s)) rate = 0.73;
    else if (/A\\$|AUD/i.test(s)) rate = 0.66;
    else if (/NZ\\$|NZD/i.test(s)) rate = 0.61;
    else if (/HK\\$|HKD/i.test(s)) rate = 0.128;
    else if (/SG\\$|SGD/i.test(s)) rate = 0.74;
    else if (/MX\\$|MXN/i.test(s)) rate = 0.058;
    else if (/R\\$|BRL/i.test(s)) rate = 0.18;
    else if (/€|EUR/i.test(s)) rate = 1.08;
    else if (/£|GBP/i.test(s)) rate = 1.27;
    else if (/₹|INR/i.test(s)) rate = 0.012;
    else if (/₺|TRY/i.test(s)) rate = 0.031;
    else if (/JOD|د\\.أ/i.test(s)) rate = 1.41;     // مثبّت
    else if (/AED|د\\.إ/i.test(s)) rate = 0.272;    // مثبّت
    else if (/SAR|ر\\.س/i.test(s)) rate = 0.267;    // مثبّت
    else if (/QAR|ر\\.ق/i.test(s)) rate = 0.275;    // مثبّت
    else if (/KWD|د\\.ك/i.test(s)) rate = 3.25;     // مثبّت
    else if (/BHD/i.test(s)) rate = 2.65;           // مثبّت
    else if (/OMR/i.test(s)) rate = 2.60;           // مثبّت
    else if (/EGP|ج\\.م/i.test(s)) rate = 0.020;
    else if (/US\\$|USD/i.test(s)) rate = 1;        // دولار صريح
    else if (/\\$/.test(s)) rate = 1;               // $ مجرّد = دولار أمريكي
    if (rate <= 0) return 0;                         // عملة مجهولة → يمنع الإضافة
    return Math.round(num * rate * 100) / 100;
  }
  // اللون المختار: تيمو يعرض عنواناً نصّياً "Color: X" (أو "اللون: X") يتحدّث
  // حسب اختيار المستخدم - نلتقط القيمة منه (دليل من صفحات حقيقية).
  function temuColor() {
    // 1) نقرة الزبون على كرت اللون (الأوثق - يحلّ مشكلة بقاء اللون الافتراضي).
    if (window.__otlobliTemuColor && window.__otlobliTemuColorGid === temuGoodsId()) {
      // حماية: رفض قيمة التقطت كود JS (مثل: } for(var ns in extraI18nStore[lang])).
      if (/[{};]|\\bvar\\b|\\bfor\\b|\\bfunction\\b/.test(window.__otlobliTemuColor)) {
        window.__otlobliTemuColor = '';
      } else {
        var stored = temuStripQuantity(window.__otlobliTemuColor);
        if (stored) return stored;
        window.__otlobliTemuColor = '';
      }
    }
    // 2) عنوان "Color: X" (اللون الافتراضي قبل أي تغيير).
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    for (var i = 0; i < nodes.length; i++) {
      var t = temuCleanText(nodes[i].textContent);
      if (t.length > 40) continue;
      var m = t.match(/^(?:Color|colour|اللون|لون(?:\\s+[\\u0600-\\u06FF]{2,14})?)\\s*[:：]\\s*(.+)$/i);
      if (m && m[1]) {
        var head = temuStripQuantity(m[1]);
        if (head) return head;
      }
    }
    return '';
  }
  // هل هذا النص رأس قسم لون؟ يشمل "اللون: أبيض" و"اللون" المجردة (بلا
  // نقطتين — الأحذية والساعات والأجهزة) و"لون السوار:" المركّبة.
  // ننظّف الداخل هنا أيضاً (لا فقط عند المستدعي) حتى تستفيد كل نقاط النداء
  // تلقائياً بلا حاجة لتعديلها كلها؛ التنظيف المزدوج بلا ضرر.
  function temuIsColorHeadText(t) {
    t = temuCleanText(t);
    if (!t || t.length > 40) return false;
    if (t === 'اللون' || t === 'Color' || t === 'Colour' || t === 'color' || t === 'colour') return true;
    return /^(?:Color|colour|اللون|لون(?:\\s+[\\u0600-\\u06FF]{2,14})?)\\s*[:：]/i.test(t);
  }
  // هل للمنتج خيارات ألوان؟ (وجود عنوان "Color:"/"اللون:"/"اللون").
  function temuHasColorSection() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) return true;
    }
    return false;
  }
  function temuImage() {
    // 1) إن نقر الزبون لوناً: نفضّل الهيرو المُلتقط بعد النقر (أكبر + صحيح).
    //    إن لم يُلتقط الهيرو بعد (ما زال الشيت مفتوحاً أثناء الالتقاط)،
    //    نستخدم صورة الكرت الصغيرة (swatch) بوصفها مؤكّدة الصحة أكثر من الهيرو
    //    العائد بالـfallback الذي قد يكون للون الافتراضي لا المختار.
    if (window.__otlobliTemuColorGid === temuGoodsId()) {
      // الـswatch أولاً: صورة كرت اللون المختار نفسه = مضمونة اللون 100%.
      // الهيرو المُلتقط قد يكون التقط قبل أن تُحدّث تيمو الصورة (شيت مفتوح)
      // فيدخل لون خاطئ — ثبت من شكوى "اخترت أزرق فانجذب أسود".
      if (window.__otlobliTemuColorSwatch) return window.__otlobliTemuColorSwatch;
      if (window.__otlobliTemuColorImg) return window.__otlobliTemuColorImg;
    }
    // 2) الصورة الرئيسية = أكبر صورة kwcdn في أعلى الصفحة (المعرض الرئيسي)، لا
    // الصور الثانوية أو صور كروت الألوان (عرضها < 200px عادةً). fallback: og:image.
    var imgs = document.querySelectorAll('img');
    var best = '', bestA = 0;
    for (var i = 0; i < imgs.length; i++) {
      var src = imgs[i].currentSrc || imgs[i].src || '';
      if (!/kwcdn|temu/i.test(src)) continue;
      var r = imgs[i].getBoundingClientRect();
      if (r.top > 720 || r.width < 200) continue;          // كروت الألوان < 200px نتجاهلها
      var a = r.width * r.height;
      if (a > bestA) { bestA = a; best = src; }
    }
    return best || getMeta('og:image') || '';
  }

  // هل العنصر له حدّ غامق (أسود/قريب منه)؟ = الخيار المختار في تيمو (مؤكّد من
  // الصور: الخيار المختار - لون أو مقاس - حدّه أسود وباقي الخيارات حدّها فاتح).
  function temuHasDarkBorder(el) {
    var cs = window.getComputedStyle(el);
    // لون الحدّ يُحسب دائماً حتى لو سماكته صفر (المتصفح يُرجع قيمة افتراضية
    // بلا معنى بصري) — ثبت من تشخيص حقيقي: 3 أزرار سماكتها 0 كلها "بحدّ
    // غامق". حدّ بلا سماكة = لا حدّ فعلياً، فنستبعده أولاً.
    var bw = parseFloat(cs.borderTopWidth || '0');
    if (!(bw > 0)) return false;
    var bc = cs.borderTopColor || cs.borderColor || '';
    var m = bc.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?/i);
    if (!m) return false;
    var alpha = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (alpha < 0.4) return false;
    return (+m[1] < 95 && +m[2] < 95 && +m[3] < 95);
  }
  // هل للعنصر outline أو box-shadow ظاهر (غير "none")؟ حلقات الاختيار
  // الدائرية شائعة برسمها عبر هاتين الخاصيتين بدل الحدّ العادي (border) —
  // ثبت من تشخيص حقيقي: حلقة سوداء واضحة حول زر "L" لكن سماكة حدّه 0 تماماً.
  function temuRingStyleMatch(cs) {
    if (!cs) return false;
    var outlineStyle = cs.outlineStyle || 'none';
    var outlineW = parseFloat(cs.outlineWidth || '0');
    if (outlineStyle !== 'none' && outlineW > 0) return true;
    var shadow = cs.boxShadow || 'none';
    return !!shadow && shadow !== 'none';
  }
  // حلقة/ظلّ اختيار — نفحص العنصر نفسه، وكذلك ::before/::after (حلقات
  // الاختيار الدائرية شائع جداً رسمها بعنصر زائف منفصل تماماً عن الأنماط
  // المحسوبة للعنصر الأصلي؛ getComputedStyle(el) وحدها لا تراه إطلاقاً).
  function temuHasRingHighlight(el) {
    if (temuRingStyleMatch(window.getComputedStyle(el))) return true;
    try {
      var before = window.getComputedStyle(el, '::before');
      if (before && before.content && before.content !== 'none' && temuRingStyleMatch(before)) return true;
    } catch (e) {}
    try {
      var after = window.getComputedStyle(el, '::after');
      if (after && after.content && after.content !== 'none' && temuRingStyleMatch(after)) return true;
    } catch (e) {}
    return false;
  }
  // إشارة "مُختار" دلالية (aria/data/اسم صنف) — أوثق بكثير من تخمين مظهر
  // CSS لأنها لا تعتمد على تقنية الرسم البصري (حدّ/outline/shadow/عنصر
  // زائف) إطلاقاً، بل على الحالة الفعلية التي يُعلنها العنصر نفسه. نفحص
  // العنصر ووالده المباشر (الحالة أحياناً على الحاضن لا الزرّ الداخلي).
  function temuHasSemanticSelectedMarker(el) {
    function check(node) {
      if (!node || !node.getAttribute) return false;
      var ariaSel = node.getAttribute('aria-selected');
      var ariaChecked = node.getAttribute('aria-checked');
      var ariaPressed = node.getAttribute('aria-pressed');
      if (ariaSel === 'true' || ariaChecked === 'true' || ariaPressed === 'true') return true;
      var dataSel = node.getAttribute('data-selected') || node.getAttribute('data-active') || node.getAttribute('data-checked');
      if (dataSel === 'true' || dataSel === '1') return true;
      var cls = ((node.className || '') + '').toLowerCase();
      var tokens = cls.replace(/_/g, ' ').replace(/-/g, ' ').split(' ');
      return tokens.indexOf('selected') >= 0 || tokens.indexOf('active') >= 0 ||
        tokens.indexOf('checked') >= 0 || tokens.indexOf('current') >= 0 ||
        tokens.indexOf('chosen') >= 0;
    }
    return check(el) || check(el.parentElement);
  }
  // خلفية فاتحة (أو شفافة)؟ لتمييز أزرار المقاس المحدّدة (حدّ غامق + خلفية
  // فاتحة) عن الأزرار المعبّأة الغامقة مثل مبدّل نظام المقاس "Standard".
  function temuOptionUnavailable(el) {
    try {
      var node = el, depth = 0;
      while (node && node !== document.body && node !== document.documentElement && depth < 5) {
        if (node.id && node.id.indexOf('otlobli') === 0) return false;
        if (node.disabled) return true;
        if (node.getAttribute) {
          if (node.getAttribute('disabled') !== null) return true;
          if (node.getAttribute('aria-disabled') === 'true') return true;
          var dataAttrs = ['data-disabled', 'data-sold-out', 'data-soldout', 'data-out-of-stock', 'data-unavailable', 'data-status', 'data-stock-status'];
          for (var da = 0; da < dataAttrs.length; da++) {
            var dv = node.getAttribute(dataAttrs[da]);
            if (dv && /^(?:1|true|disabled|soldout|sold-out|outofstock|out-of-stock|unavailable|notavailable|not-available)$/i.test(dv)) return true;
          }
          var clsRaw = (node.className && node.className.baseVal !== undefined) ? node.className.baseVal : (node.className || '');
          var hint = (' ' + clsRaw + ' ' + (node.id || '') + ' ' +
            (node.getAttribute('aria-label') || '') + ' ' + (node.getAttribute('title') || '') + ' ').toLowerCase();
          if (/(?:^|[\\s_-])(?:disable|disabled|soldout|sold-out|sold_out|outofstock|out-of-stock|out_of_stock|unavailable|notavailable|not-available)(?:$|[\\s_-])/i.test(hint)) return true;
          var role = (node.getAttribute('role') || '').toLowerCase();
          var choiceShell = role === 'radio' || node.getAttribute('aria-checked') !== null || node.getAttribute('aria-selected') !== null;
          if (depth === 0 && choiceShell && node.querySelector) {
            var disabledChild = node.querySelector('[disabled], [aria-disabled="true"], [data-disabled="true"], [data-disabled="1"], [data-sold-out], [data-soldout], [data-out-of-stock], [data-unavailable], [class*="disabled"], [class*="disable"], [class*="soldout"], [class*="sold-out"], [class*="outofstock"], [class*="out-of-stock"], [class*="unavailable"], [class*="notavailable"], [class*="not-available"]');
            if (disabledChild) return true;
          }
          var txt = temuCleanText((node.getAttribute('aria-label') || '') + ' ' +
            (node.getAttribute('title') || '') + ' ' + (node.textContent || ''));
          if (txt && txt.length <= 140 &&
              /sold\\s*out|out\\s*of\\s*stock|unavailable|not\\s*available|\u063a\u064a\u0631\\s+\u0645\u062a(?:\u0648\u0641\u0631|\u0627\u062d)|\u0646\u0641\u062f|\u0646\u0641\u062f\u062a|\u0627\u0646\u062a\u0647\u0649\\s+\u0627\u0644\u0645\u062e\u0632\u0648\u0646|\u0645\u0628\u0627\u0639|\u062a\u0645\\s+\u0627\u0644\u0628\u064a\u0639/i.test(txt)) return true;
        }
        if (depth <= 2 && node.getBoundingClientRect) {
          var cs = window.getComputedStyle(node);
          var op = parseFloat(cs.opacity || '1');
          if (!isNaN(op) && op > 0 && op < 0.45) return true;
          if (cs.pointerEvents === 'none') return true;
        }
        node = node.parentElement; depth++;
      }
    } catch (e) {}
    return false;
  }

  function temuVisibleOptionTextAvailable(optionText) {
    var wanted = temuCleanText(optionText);
    if (!wanted) return false;
    var saw = false;
    try {
      var nodes = document.querySelectorAll('[role="radio"], [aria-checked], [aria-selected], button, [role="button"]');
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].id && nodes[i].id.indexOf('otlobli') === 0) continue;
        if (temuCleanText(nodes[i].textContent) !== wanted) continue;
        saw = true;
        if (!temuOptionUnavailable(nodes[i])) return true;
      }
    } catch (e) {}
    return !saw;
  }

  function otlobliTemuMarkUnavailableTap() {
    try {
      window.__otlobliTemuUnavailableTapGid = temuGoodsId();
      window.__otlobliTemuUnavailableTapTs = Date.now();
    } catch (e) {}
  }

  function otlobliTemuRecentUnavailableTap() {
    try {
      return window.__otlobliTemuUnavailableTapGid === temuGoodsId() &&
        window.__otlobliTemuUnavailableTapTs &&
        (Date.now() - window.__otlobliTemuUnavailableTapTs) < 8000;
    } catch (e) {}
    return false;
  }

  function temuLightBackground(el) {
    var bg = window.getComputedStyle(el).backgroundColor || '';
    var m = bg.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?/i);
    if (!m) return true;
    var alpha = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (alpha < 0.1) return true;            // شفاف = فاتح
    return (+m[1] > 140 || +m[2] > 140 || +m[3] > 140);
  }
  // ذكي وآمن: الخيار المختار (مقاس/متغيّر نصّي) = زر **قابل للنقر**، قصير النص،
  // بلا صورة، بحدّ غامق وخلفية فاتحة، **ظاهر بالشاشة**، وليس سعراً/خصماً/كمية.
  // القابلية للنقر هي ما يميّز زر الخيار عن شارة السعر (غير قابلة للنقر) -
  // وهذا أصلح خطأ التقاط السعر مكان المقاس.
  // عنوان قسم المقاس ("Size"/"المقاس").
  function temuVariantColorCountMatch(txt) {
    return temuCleanText(txt).match(/(\\d+)\\s*(?:\u0627\u0644\u0644\u0648\u0646|\u0644\u0648\u0646|\u0623\u0644\u0648\u0627\u0646|\u0627\u0644\u0623\u0644\u0648\u0627\u0646|colou?rs?)/i);
  }
  function temuVariantSecondOptionCountMatch(txt) {
    var dimensionCount = temuCleanText(txt).match(/(\\d+)\\s*(?:الحجم|حجم)/i);
    if (dimensionCount) return dimensionCount;
    return temuCleanText(txt).match(/(\\d+)\\s*(?:\u0627\u0644\u0645\u0648\u062f\u064a\u0644|\u0645\u0648\u062f\u064a\u0644|models?|\u0645\u0642\u0627\u0633|\u0645\u0642\u0627\u0633\u0627\u062a|sizes?|\u0623\u0633\u0644\u0648\u0628|\u0646\u0645\u0637|style|\u0646\u0648\u0639|type|ram|rom|memory|storage|capacity|gb|g\\b|\u0630\u0627\u0643\u0631\u0629|\u0627\u0644\u0630\u0627\u0643\u0631\u0629|\u0631\u0627\u0645|\u0627\u0644\u0631\u0627\u0645|\u0633\u0639\u0629|\u0627\u0644\u0633\u0639\u0629|\u062a\u062e\u0632\u064a\u0646|\u0627\u0644\u062a\u062e\u0632\u064a\u0646|\u0623\u063a\u0631\u0627\u0636|\u0627\u063a\u0631\u0627\u0636|\u0627\u0644\u0623\u063a\u0631\u0627\u0636|\u0627\u0644\u0627\u063a\u0631\u0627\u0636|\u063a\u0631\u0636|\u0627\u0644\u063a\u0631\u0636|\u0639\u0646\u0635\u0631|\u0627\u0644\u0639\u0646\u0635\u0631|\u0639\u0646\u0627\u0635\u0631|\u0627\u0644\u0639\u0646\u0627\u0635\u0631|\u0642\u0637\u0639|\u0627\u0644\u0642\u0637\u0639|\u0642\u0637\u0639\u0629|\u0627\u0644\u0642\u0637\u0639\u0629|items?|pieces?|pcs?)/i);
  }
  function temuVariantSecondOptionName(txt) {
    var t = temuCleanText(txt);
    if (/\u0645\u0648\u062f\u064a\u0644|models?/i.test(t)) return '\u0627\u0644\u0645\u0648\u062f\u064a\u0644';
    if (/\u0623\u0633\u0644\u0648\u0628|\u0646\u0645\u0637|style|\u0646\u0648\u0639|type/i.test(t)) return '\u0623\u0633\u0644\u0648\u0628';
    if (/\u0623\u063a\u0631\u0627\u0636|\u0627\u063a\u0631\u0627\u0636|\u063a\u0631\u0636|\u0639\u0646\u0635\u0631|\u0639\u0646\u0627\u0635\u0631|\u0642\u0637\u0639|\u0642\u0637\u0639\u0629|items?|pieces?|pcs?/i.test(t)) return '\u0623\u063a\u0631\u0627\u0636';
    return '\u0645\u0642\u0627\u0633';
  }
  function temuLooksLikeVariantOptionLabel(text) {
    var ht = temuCleanText(text);
    if (!ht || ht.length > 58) return false;
    if (/guide|chart|info|\u062f\u0644\u064a\u0644/i.test(ht)) return false;
    // \u062c\u0645\u0644\u0629 \u0637\u0648\u064a\u0644\u0629 \u0628\u0644\u0627 \u0646\u0642\u0637\u062a\u064a\u0646 = \u0646\u0635 \u0648\u0635\u0641\u064a \u0644\u0627 \u0631\u0623\u0633 \u0642\u0633\u0645
    if (!/[:\uff1a]/.test(ht) && ht.length > 14) return false;
    if (/^(?:Size|Compatible\\s*Model|Model|Style|Type|Memory|Storage|Capacity|RAM|ROM|Items?|Pieces?|PCS)\\s*[:\uff1a]?/i.test(ht)) return true;
    if (/^(?:\u0627\u0644)?(?:\u0645\u0642\u0627\u0633|\u0642\u064a\u0627\u0633|\u062d\u062c\u0645|\u0645\u0648\u062f\u064a\u0644|\u0623\u0633\u0644\u0648\u0628|\u0646\u0645\u0637|\u0646\u0648\u0639|\u0630\u0627\u0643\u0631\u0629|\u0631\u0627\u0645|\u0633\u0639\u0629|\u062a\u062e\u0632\u064a\u0646|\u0623\u063a\u0631\u0627\u0636|\u0627\u063a\u0631\u0627\u0636|\u063a\u0631\u0636|\u0639\u0646\u0635\u0631|\u0639\u0646\u0627\u0635\u0631|\u0642\u0637\u0639|\u0642\u0637\u0639\u0629)\\s*[:\uff1a]?/i.test(ht)) return true;
    return false;
  }
  function temuSizeHeadEl() {
    var heads = document.querySelectorAll('div, span, h2, h3, strong, label, p');
    for (var h = 0; h < heads.length; h++) {
      var ht = temuCleanText(heads[h].textContent);
      if (temuLooksLikeVariantOptionLabel(ht)) return heads[h];
      if (ht === 'Size' || ht === 'المقاس' || ht === 'Size:' || ht === 'المقاس:'
        || ht === 'مقاس' || ht === 'مقاس:' || ht === 'القياس' || ht === 'القياس:'
        || ht === 'الحجم' || ht === 'الحجم:' || ht === 'حجم'
        || ht === 'موديل متوافق' || ht === 'Compatible Model' || ht === 'Compatible model'
        || ht === 'الموديل' || ht === 'موديل'
        || ht === 'أسلوب' || ht === 'Style' || ht === 'Style:' || ht === 'النمط' || ht === 'نوع'
        || (ht.indexOf('Size') === 0 && ht.length <= 12 && !/guide|chart|info/i.test(ht))
        || (ht.indexOf('مقاس') === 0 && ht.length <= 12 && ht.indexOf('مقاسات') < 0)
        || (ht.indexOf('موديل') === 0 && ht.length <= 22)
        || (ht.indexOf('أسلوب') === 0 && ht.length <= 10)
        || (ht.indexOf('Style') === 0 && ht.length <= 10)) return heads[h];
    }
    return null;
  }
  // يحلّل ملخّص المتغيّرات ("1 اللون, 25 موديل متوافق") لمعرفة العدد الفعلي
  // لأن عدّ الـpills على الصفحة غير موثوق (قد يكون الملخّص قبل فتح اللوحة).
  function temuVariantCounts() {
    var el = temuVariantSummaryEl();
    var txt = el ? temuCleanText(el.textContent) : '';
    var cMatch = temuVariantColorCountMatch(txt);
    var sMatch = temuVariantSecondOptionCountMatch(txt);
    return {
      colors: cMatch ? parseInt(cMatch[1], 10) : -1,  // -1 = غير معروف
      sizes:  sMatch ? parseInt(sMatch[1], 10) : -1,
    };
  }
  // قتامة حدّ العنصر (مجموع RGB، أقل=أغمق؛ 999 لو شفاف/غير موجود).
  function temuBorderDarkness(el) {
    var bc = window.getComputedStyle(el).borderTopColor || '';
    var m = bc.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?/i);
    if (!m) return 999;
    var a = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (a < 0.3) return 999;
    return (+m[1] + +m[2] + +m[3]);
  }
  // سماكة الحدّ العلوي بالبكسل (0 إن لا حدّ).
  function temuBorderWidth(el) {
    var bw = parseFloat(window.getComputedStyle(el).borderTopWidth || '0');
    return isNaN(bw) ? 0 : bw;
  }
  // كاشف "المُختار" متعدد الإشارات لأزرار/كروت متجانسة (مقاس/لون). لون الحدّ
  // وحده غير كافٍ (كل الأزرار قد تحمل نفس الحدّ). نجرّب الإشارات من الأقوى
  // للأضعف؛ أول إشارة تُرجع تطابقاً واحداً بلا غموض تفوز، وفشل الكل = فارغ.
  function temuPickSingleSelected(els) {
    if (!els || els.length < 2) return null;
    var availableEls = [];
    for (var ae = 0; ae < els.length; ae++) {
      if (!temuOptionUnavailable(els[ae])) availableEls.push(els[ae]);
    }
    els = availableEls;
    if (els.length < 2) return null;
    // إشارة 0 (الأوثق دائماً): علامة دلالية صريحة (aria/data/اسم صنف) لا
    // تعتمد على تقنية الرسم البصري إطلاقاً — إن وُجدت نثق بها فوراً.
    var semantic = [];
    for (var s = 0; s < els.length; s++) {
      if (temuHasSemanticSelectedMarker(els[s])) semantic.push(els[s]);
    }
    if (semantic.length === 1) return semantic[0];
    // إشارة 1: خلفية ممتلئة داكنة غير شفافة (الأقوى والأوضح بصرياً).
    var filled = [];
    for (var i = 0; i < els.length; i++) {
      var bg = window.getComputedStyle(els[i]).backgroundColor || '';
      var bm = bg.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?/i);
      if (!bm) continue;
      var ba = bm[4] !== undefined ? parseFloat(bm[4]) : 1;
      if (ba < 0.5) continue;
      if ((+bm[1] + +bm[2] + +bm[3]) < 240) filled.push(els[i]);
    }
    if (filled.length === 1) return filled[0];
    // إشارة 2: حلقة outline/box-shadow ظاهرة (حلقات الاختيار الدائرية —
    // ثبت من تشخيص حقيقي: حدّ سماكته 0 لكن حلقة سوداء واضحة حول الزر).
    var ringed = [];
    for (var r = 0; r < els.length; r++) {
      if (temuHasRingHighlight(els[r])) ringed.push(els[r]);
    }
    if (ringed.length === 1) return ringed[0];
    // إشارة 3: سماكة حدّ أكبر بوضوح من كل الباقي (تفوق حقيقي لا تقريبي).
    var widths = [];
    for (var j = 0; j < els.length; j++) widths.push(temuBorderWidth(els[j]));
    var maxW = Math.max.apply(null, widths);
    if (maxW > 0) {
      var wMatches = [], secondMax = 0;
      for (var k = 0; k < widths.length; k++) {
        if (widths[k] === maxW) wMatches.push(els[k]);
        else if (widths[k] > secondMax) secondMax = widths[k];
      }
      if (wMatches.length === 1 && maxW > secondMax && (secondMax === 0 || maxW >= secondMax * 1.3)) {
        return wMatches[0];
      }
    }
    // إشارة 4 (احتياط أخير): حدّ غامق وحيد فعلي السماكة (القوالب التي فعلاً
    // تلوّن حدّ المختار فقط بلا البقية — الحالة الأصلية قبل هذا التوسيع).
    var borderMatches = [];
    for (var b = 0; b < els.length; b++) {
      if (temuHasDarkBorder(els[b])) borderMatches.push(els[b]);
    }
    if (borderMatches.length === 1) return borderMatches[0];
    return null;
  }
  // هل النص يشبه قيمة مقاس حقيقية؟ أرقام (74-80، 38، 9-12 شهر) أو حروف
  // المقاسات القياسية (M/L/XL/One Size). يميّز صف المقاسات الحقيقي عن مفاتيح
  // التبديل النصية المجاورة للرأس (الطول/العمر/قياسي/JO...) التي تخترع تيمو
  // جديداً منها لكل صنف — فلا نعتمد على حفظ الكلمات بل على شكل القيمة.
  function temuSizeLike(t) {
    if (/\\d/.test(t)) return true;
    return /^(?:x{0,3}[sml]|xs|xxs|one.?size|free.?size)$/i.test(t);
  }
  // أزرار المقاس ضمن قسم "Size" فقط — بتجميع حسب الـclass: أزرار الصف
  // الحقيقي تتشارك الصنف نفسه، فأكبر مجموعة "تشبه مقاسات" تفوز، ومفاتيح
  // التبديل (مجموعة صنف آخر بلا أرقام) تخسر تلقائياً مهما كانت كلماتها.
  function temuSizePills() {
    var head = temuSizeHeadEl();
    if (!head) return [];
    var container = head.parentElement, hops = 0;
    var weakBest = [];
    while (container && hops < 6) {
      var cand = container.querySelectorAll('button, a, [role="button"], div, span, label');
      var pills = [];
      for (var i = 0; i < cand.length; i++) {
        var el = cand[i];
        if (el.id && el.id.indexOf('otlobli') === 0) continue;
        if (temuOptionUnavailable(el)) continue;
        var t = temuCleanText(el.textContent);
        if (t.length < 1 || t.length > 24) continue;
        // أزرار كمية "−" "+" حرف واحد غير حرفي/رقمي — نتجاهلها.
        if (t.length === 1 && !/[a-zA-Z0-9]/.test(t)) continue;
        if (t.indexOf(':') >= 0) continue;
        if (/[$£€%]/.test(t)) continue;
        if (/\\bfree\\b|\\bapp\\b|guide|standard|qty|^size$/i.test(t)) continue;
        // مفاتيح تبديل معروفة + دليل المقاسات + الكمية (حزام أمان صريح).
        if (/^(?:us|ca|eu|uk|au|jo|sa|ae|kw|qa|bh|om|asia|intl)$/i.test(t)) continue;
        if (t === 'قياسي' || t === 'عادي' || t === 'الطول' || t === 'العمر' || t === 'الوزن'
          || /دليل|كمية|كميه/.test(t)) continue;
        // حارس عدّاد الكمية (v85.8.37): الرقم بين زرّي +/− في [−][1][+] ليس
        // مقاساً — كان يُلتقط كزر مقاس شبحي فيفعّل بوابة "حدد المقاس أولاً"
        // على منتجات بلا مقاسات (ثبت من لقطة الوسادة).
        if (/^\\d+$/.test(t)) {
          var qPrev = el.previousElementSibling, qNext = el.nextElementSibling;
          var qPv = qPrev ? temuCleanText(qPrev.textContent) : '';
          var qNx = qNext ? temuCleanText(qNext.textContent) : '';
          var isStep = function (s) { return s === '+' || s === '-' || s === '−'; };
          if (isStep(qPv) && isStep(qNx)) continue;
        }
        if (el.querySelector && el.querySelector('img')) continue;
        var r = el.getBoundingClientRect();
        if (r.width < 18 || r.width > 260 || r.height < 16 || r.height > 80) continue;
        pills.push(el);
      }
      if (pills.length) {
        // تجميع حسب (class + tag)
        var byCls = {}, order = [];
        for (var p2 = 0; p2 < pills.length; p2++) {
          var ck = ((pills[p2].className || '') + '|' + pills[p2].tagName);
          if (!byCls[ck]) { byCls[ck] = []; order.push(ck); }
          byCls[ck].push(pills[p2]);
        }
        // نجمّع كل المجموعات "القوية" (تشبه مقاسات) بهذا المستوى، لا الأكبر فقط:
        // الزر المختار غالباً يحمل صنف CSS إضافياً (active/selected) فيُفرد بمجموعة
        // حجمها 1 وتخسر أمام الأكبر فتختفي. حارس أمان: نضمّ فقط المجموعات القريبة
        // عمودياً من أكبر مجموعة (نفس الصفّ)، لا أي مجموعة بمستوى الصفحة.
        var groups = [];
        for (var g = 0; g < order.length; g++) {
          var grp = byCls[order[g]];
          var likes = 0;
          for (var q = 0; q < grp.length; q++) {
            if (temuSizeLike(temuCleanText(grp[q].textContent))) likes++;
          }
          if (likes >= 1 && likes * 2 >= grp.length) groups.push(grp);
        }
        if (groups.length) {
          groups.sort(function (a, b) { return b.length - a.length; });
          var baseTop = groups[0][0].getBoundingClientRect().top;
          var merged = groups[0].slice();
          for (var gi = 1; gi < groups.length; gi++) {
            var gTop = groups[gi][0].getBoundingClientRect().top;
            if (Math.abs(gTop - baseTop) <= 60) merged = merged.concat(groups[gi]);
          }
          return merged;
        }
        var weak = null;
        for (var g2 = 0; g2 < order.length; g2++) {
          var grp2 = byCls[order[g2]];
          if (!weak || grp2.length > weak.length) weak = grp2;
        }
        // مجموعة كلمات بلا أرقام (أسلوب/نمط): نحفظ أفضلها كاحتياط — بسقف
        // حجم يمنع التقاط شبكة تصنيفات كاملة من مستويات عالية.
        if (weak && weak.length <= 10 && hops <= 3 && weak.length > weakBest.length) {
          weakBest = weak;
        }
      }
      container = container.parentElement; hops++;
    }
    return weakBest;
  }
  // معرّف المنتج (ثابت رغم تغيّر المقاس/اللون) - لربط النقرة بالمنتج الصحيح.
  function temuGoodsId() {
    var m = location.href.match(/goods_id=(\\d+)/);
    return m ? m[1] : location.pathname;
  }
  // المقاس المختار. المصدر الأدقّ: آخر زر مقاس **نقره الزبون فعلاً** (نسجّله
  // عبر مستمع نقر) - أوثق بكثير من تخمين العنصر "المحدّد" بصرياً. واحتياطاً:
  // الزر الأغمق حدّاً بوضوح (للمقاس المُختار افتراضياً بلا نقر). أي شكّ=فارغ.
  function temuSelectedSizeFromLabel() {
    // 1) نفحص أولاً عنوان قسم المقاس نفسه — قد يحتوي القيمة ("Size: One-size")
    var head = temuSizeHeadEl();
    if (head) {
      var headText = temuCleanText(head.textContent);
      // (v85.8.37) قيمة مضمّنة بعد النقطتين لأي رأس خيار = محددة مسبقاً:
      // "الموديل: BHB1200"، "ذاكرة الوصول العشوائي + روم: 8 جيجا + 128 جيجا".
      // كانت تُقرأ فقط بصيغ Size/مقاس فتُحجب منتجات محسومة أصلاً بـ"حدد
      // موديل جوالك أولاً" (ثبت من لقطات الخلاط والتابلت).
      var inlineVal = headText.match(/[:：]\\s*(.{1,44})$/);
      if (inlineVal && inlineVal[1]) {
        var iv = inlineVal[1].trim();
        if (iv.length >= 1 && !/دليل|guide|chart/i.test(iv)) return iv;
      }
      var hm = headText.match(/Size[\\s\\-]*[:\\-]?[\\s\\-]*(one.?size|free.?size|[\\w ]{2,20})/i);
      if (hm && hm[1]) {
        var hv = hm[1].trim();
        if (!/^size$/i.test(hv) && hv.length >= 2) return hv;
      }
      // 2) نفحص العناصر المجاورة مباشرة للعنوان (قد تكون النص/التاغ المنفصل)
      var parent = head.parentElement;
      if (parent) {
        var kids = parent.children;
        for (var k = 0; k < kids.length; k++) {
          if (kids[k] === head) continue;
          var kt = temuCleanText(kids[k].textContent);
          if (kt.length >= 2 && kt.length <= 30 && /one.?size|free.?size/i.test(kt)) return kt;
        }
      }
    }
    // 3) مسح عام: البحث عن نمط "Size: ONE SIZE" في أي عنصر نصي
    var els = document.querySelectorAll('div, span, p, strong, h3, h2');
    for (var si = 0; si < els.length; si++) {
      var st = temuCleanText(els[si].textContent);
      if (st.length < 4 || st.length > 80) continue;
      var sm = st.match(/Size\\s*:\\s*([^,;|\\n\\r]{1,30})/i);
      if (!sm) sm = st.match(/^(?:المقاس|مقاس|الحجم)\\s*[:：]\\s*([^,;|\\n\\r]{1,30})/);
      if (sm && sm[1]) {
        var sv = sm[1].trim();
        if (sv.length >= 2 && sv.length <= 30 && !/guide|chart|info|دليل/i.test(sv)) return sv;
      }
    }
    return '';
  }
  function temuSelectedSize() {
    // v85.8.41: القيمة المختارة من الخيار aria-checked داخل skuSelector — الأدقّ
    // والأنظف. يمنع التقاط كل الأزرار ("XXL XL L M S") بدل المقاس الواحد المختار.
    var structuralMultiSize = false;
    try {
      var sk = otlobliTemuSku();
      for (var d = 0; d < sk.dims.length; d++) {
        var dd = sk.dims[d];
        if (dd.kind !== 'size') continue;
        if (dd.selected && dd.selected !== 'محدد' && dd.selected.length <= 30) return dd.selected;
        if (dd.count > 1) structuralMultiSize = true;
      }
    } catch (e) {}
    if (window.__otlobliTemuSize && window.__otlobliTemuSizeGid === temuGoodsId()) {
      var cachedSize0 = temuCleanText(window.__otlobliTemuSize);
      if (cachedSize0 && cachedSize0.length <= 40 && temuVisibleOptionTextAvailable(cachedSize0)) return cachedSize0;
    }
    // البنية الموثوقة تقول إن هناك عدة مقاسات ولم تعلن Temu واحداً محدداً.
    // لا نسمح لأي حد/ظل/خلفية CSS أن يحوّل هذا إلى اختيار؛ هذه بالضبط كانت
    // تضيف المنتج بالمقاس الخطأ. نقرة العميل المسجلة أعلاه تبقى صالحة فوراً.
    if (structuralMultiSize) {
      window.__otlobliTemuSizeDiag = 'عدة مقاسات بلا اختيار صريح';
      return '';
    }
    var pills = temuSizePills();
    // لا توجد أزرار مقاس — قد يكون المقاس محدداً مسبقاً (مثل "One-size" على الصفحة مباشرة).
    if (pills.length < 1) {
      var headFound = !!temuSizeHeadEl();
      window.__otlobliTemuSizeDiag = headFound ? 'رأس موجود، صفر أزرار مطابقة' : 'لا رأس قسم مقاس';
      return temuSelectedSizeFromLabel();
    }
    // 1) نقرة الزبون المسجّلة (لنفس المنتج، وضمن مقاساته الحالية). ننظّف نص
    // الزر بـtemuCleanText بالضبط كمعالج النقر: تيمو تحقن رموز اتجاه حول نص
    // الزر أثناء حالة "مُختار" فتفشل المقارنة الخام ضد القيمة المسجّلة النظيفة.
    if (window.__otlobliTemuSize && window.__otlobliTemuSizeGid === temuGoodsId()) {
      for (var k = 0; k < pills.length; k++) {
        if (!temuOptionUnavailable(pills[k]) && temuCleanText(pills[k].textContent) === window.__otlobliTemuSize) return window.__otlobliTemuSize;
      }
    }
    // 2) مقاس وحيد = اختيار تلقائي (لا داعي لنقر الزبون عليه).
    if (pills.length === 1) {
      return temuCleanText(pills[0].textContent);
    }
    // عدة أزرار بلا aria صريحة وبلا نقرة عميل = غير محدد. التخمين البصري
    // مرفوض للمقاس لأنه قد يختار أول مقاس لمجرد أن قالبه أغمق من البقية.
    window.__otlobliTemuSizeDiag = 'أزرار متعددة بلا اختيار صريح';
    return '';
  }
  // مقاس وحيد → نحدّده تلقائياً من دون نقر الزبون (يُستدعى في معالج الزر).
  function temuForceSingleSize() {
    if (!temuHasSizeSection() || temuSelectedSize()) return;
    var fpills = temuSizePills();
    if (fpills.length === 1) {
      var ft = temuCleanText(fpills[0].textContent);
      if (ft && ft.length <= 24) {
        // تسجيل فقط بلا .click() — نفس علة temuAutoSelectSingleSize: نقر عنصر
        // مُصنَّف خطأً يُبحر بالصفحة. التسجيل يكفي لالتقاط البيانات.
        window.__otlobliTemuSize = ft;
        window.__otlobliTemuSizeGid = temuGoodsId();
      }
    } else if (fpills.length === 0) {
      // ملخّص "1 Size" في لوحة المتغيّرات → مقاس وحيد غير قابل للنقر
      var fsum = temuVariantSummaryEl();
      if (fsum && /\\b1\\s*(?:size|مقاس|موديل|أسلوب)|مقاس\\s*واحد/i.test(fsum.textContent || '')) {
        window.__otlobliTemuSize = 'ONE SIZE';
        window.__otlobliTemuSizeGid = temuGoodsId();
      }
    }
  }
  // هل للمنتج لون وحيد؟ يُقلّص الصور الملوّنة القريبة من عنوان "Color:".
  function temuColorChoiceCardCount() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    var colorHead = null;
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) { colorHead = nodes[i]; break; }
    }
    if (!colorHead) return 0;
    var container = colorHead.parentElement, hops = 0;
    while (container && hops < 5) {
      var imgs = container.querySelectorAll('img');
      var count = 0;
      for (var j = 0; j < imgs.length; j++) {
        var src = imgs[j].currentSrc || imgs[j].src || '';
        if (!/kwcdn|temu/i.test(src)) continue;
        var r = imgs[j].getBoundingClientRect();
        if (r.width >= 28 && r.width < 200 && r.height >= 28 && r.height < 200 && !temuOptionUnavailable(imgs[j].parentElement || imgs[j])) count++;
      }
      if (count >= 1) return count;
      container = container.parentElement; hops++;
    }
    return 0;
  }
  function temuHasSingleColor() {
    var count = temuColorChoiceCardCount();
    if (count >= 1) return count === 1;
    return !!temuColorFromHeading();
  }
  // يقرأ اللون الحالي من عنوان "اللون: X" فقط (بلا مصادر النقر) — يُستخدم
  // للالتقاط الاحتياطي بعد أي نقرة: كروت الألوان النصية (ساعات) بلا صور
  // لا يلتقطها فرع كرت اللون، لكن تيمو تُحدّث العنوان بعد الاختيار دائماً.
  function temuColorFromHeading() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    for (var i = 0; i < nodes.length; i++) {
      var t = temuCleanText(nodes[i].textContent);
      if (t.length > 40) continue;
      var m = t.match(/^(?:Color|colour|اللون|لون(?:\\s+[\\u0600-\\u06FF]{2,14})?)\\s*[:：]\\s*(.+)$/i);
      if (m && m[1]) {
        var cv = m[1].trim();
        if (cv.length >= 2 && cv.length <= 40 && !/[{};]/.test(cv)) return cv;
      }
    }
    return '';
  }
  // يبحث وقت الجذب عن كرت اللون الذي اسمه يطابق اللون المختار ويعيد صورته —
  // شبكة أمان لالتقاط صورة اللون حين لم يلتقطها مستمع النقر (اختيار داخل
  // الشيت، لون افتراضي محدد مسبقاً، كروت بهيكلية غير متوقعة).
  function temuSelectedColorCardImg(colorName) {
    if (!colorName || colorName.length < 2) return '';
    var lowName = colorName.toLowerCase();
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    var colorHead = null;
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) { colorHead = nodes[i]; break; }
    }
    if (!colorHead) return '';
    var container = colorHead.parentElement, hops = 0;
    while (container && hops < 5) {
      var imgs = container.querySelectorAll('img');
      var swCount = 0, match = '';
      for (var j = 0; j < imgs.length; j++) {
        var src = imgs[j].currentSrc || imgs[j].src || '';
        if (!src || src.indexOf('http') !== 0) continue;
        var r = imgs[j].getBoundingClientRect();
        if (r.width < 28 || r.width > 220 || r.height < 28 || r.height > 220) continue;
        if (temuOptionUnavailable(imgs[j].parentElement || imgs[j])) continue;
        swCount++;
        var alt = temuCleanText(imgs[j].getAttribute('alt') || imgs[j].getAttribute('title') || '').toLowerCase();
        var ptxt = imgs[j].parentElement ? temuCleanText(imgs[j].parentElement.textContent).toLowerCase() : '';
        if ((alt && alt.length >= 2 && (alt === lowName || alt.indexOf(lowName) >= 0 || lowName.indexOf(alt) >= 0))
          || (ptxt && ptxt.length <= 50 && ptxt.indexOf(lowName) >= 0)) { match = src; }
      }
      // وجدنا صفّ كروت الألوان: نُرجع المطابق فقط — لا تخمين إن لم يطابق.
      if (swCount >= 1) return match;
      container = container.parentElement; hops++;
    }
    return '';
  }
  // نفس منطق temuSelectedColorCardImg بالضبط لكن تُرجع الكرت (العنصر
  // القابل للنقر) لا صورته - يُستخدم لإعادة الاختيار التلقائي عبر النقر
  // الفعلي (temuAutoReselectFromLink)، لا مجرد قراءة الصورة.
  function temuFindColorCardEl(colorName) {
    if (!colorName || colorName.length < 2) return null;
    var lowName = colorName.toLowerCase();
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    var colorHead = null;
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) { colorHead = nodes[i]; break; }
    }
    if (!colorHead) return null;
    var container = colorHead.parentElement, hops = 0;
    while (container && hops < 5) {
      var imgs = container.querySelectorAll('img');
      var matches = [];
      for (var j = 0; j < imgs.length; j++) {
        var src = imgs[j].currentSrc || imgs[j].src || '';
        if (!src || src.indexOf('http') !== 0) continue;
        var r = imgs[j].getBoundingClientRect();
        if (r.width < 28 || r.width > 220 || r.height < 28 || r.height > 220) continue;
        var alt = temuCleanText(imgs[j].getAttribute('alt') || imgs[j].getAttribute('title') || '').toLowerCase();
        var parentEl = imgs[j].parentElement || imgs[j];
        if (temuOptionUnavailable(parentEl)) continue;
        var ptxt = temuCleanText(parentEl.textContent).toLowerCase();
        if ((alt && alt.length >= 2 && (alt === lowName || alt.indexOf(lowName) >= 0 || lowName.indexOf(alt) >= 0))
          || (ptxt && ptxt.length <= 50 && ptxt.indexOf(lowName) >= 0)) { matches.push(parentEl); }
      }
      if (imgs.length >= 1) return matches.length === 1 ? matches[0] : null;
      container = container.parentElement; hops++;
    }
    return null;
  }
  // كرت اللون المختار افتراضياً (بلا نقرة الزبون ولا اسم نصي مطابق) — شبكة
  // أمان أخيرة لمنتجات كروت الصور المجرّدة (حقائب/ملابس بلا "اللون: X" ولا
  // alt نصي). الكرت المختار مُعلَّم بحدّ غامق فقط (نفحص الصورة وحاضنَيها
  // المباشرَين لاختلاف هيكلية القوالب). تطابق واحد بالضبط وإلا فارغ.
  function temuDefaultSelectedColorCard() {
    var nodes = document.querySelectorAll('div, span, h2, h3, p, strong');
    var colorHead = null;
    for (var i = 0; i < nodes.length; i++) {
      if (temuIsColorHeadText((nodes[i].textContent || '').trim())) { colorHead = nodes[i]; break; }
    }
    if (!colorHead) { window.__otlobliTemuColorDiag = 'لا رأس قسم لون'; return null; }
    var container = colorHead.parentElement, hops = 0;
    while (container && hops < 5) {
      var imgs = container.querySelectorAll('img');
      var cards = [], parentEls = [], grandEls = [];
      for (var j = 0; j < imgs.length; j++) {
        var src = imgs[j].currentSrc || imgs[j].src || '';
        if (!src || src.indexOf('http') !== 0) continue;
        var r = imgs[j].getBoundingClientRect();
        if (r.width < 28 || r.width > 220 || r.height < 28 || r.height > 220) continue;
        var parentEl = imgs[j].parentElement || imgs[j];
        var grandEl = parentEl.parentElement || parentEl;
        if (temuOptionUnavailable(parentEl) || temuOptionUnavailable(grandEl)) continue;
        cards.push({ img: imgs[j], src: src, parentEl: parentEl, grandEl: grandEl });
        parentEls.push(parentEl);
        grandEls.push(grandEl);
      }
      if (cards.length >= 1) {
        // نجرّب الكاشف متعدد الإشارات على مستوى الحاضن المباشر أولاً، ثم
        // الجدّ إن فشل (اختلاف هيكلية القوالب أين تُوضع علامة "المختار").
        var pickedEl = temuPickSingleSelected(parentEls) || temuPickSingleSelected(grandEls);
        if (pickedEl) {
          var pickedCard = null;
          for (var c = 0; c < cards.length; c++) {
            if (cards[c].parentEl === pickedEl || cards[c].grandEl === pickedEl) { pickedCard = cards[c]; break; }
          }
          if (pickedCard) {
            window.__otlobliTemuColorDiag = 'كروت=' + cards.length + ' نجاح';
            var altName = temuCleanText(pickedCard.img.getAttribute('alt') || pickedCard.img.getAttribute('title') || '');
            return { name: altName, image: pickedCard.src };
          }
        }
        var dbgBordered = 0;
        for (var db = 0; db < parentEls.length; db++) { if (temuHasDarkBorder(parentEls[db])) dbgBordered++; }
        window.__otlobliTemuColorDiag = 'كروت=' + cards.length + ' حدّغامق=' + dbgBordered;
        return null; // صفّ موجود لكن لا تطابق واحد واضح — لا تخمين
      }
      container = container.parentElement; hops++;
    }
    window.__otlobliTemuColorDiag = 'رأس موجود، صفر كروت صور (h' + hops + ')';
    return null;
  }
  // جدولة التقاط هيرو اللون (بعد إغلاق الشيت) — مشتركة بين فرعَي الالتقاط.
  function temuScheduleHeroCapture(gid) {
    function captureHero2() {
      if (window.__otlobliTemuColorGid !== gid) return;
      var himgs = document.querySelectorAll('img');
      var hbest = '', hbestA = 0;
      var vpH2 = viewportSize().height;
      for (var hi = 0; hi < himgs.length; hi++) {
        var hsrc = himgs[hi].currentSrc || himgs[hi].src || '';
        if (!/kwcdn|temu/i.test(hsrc)) continue;
        var hr = himgs[hi].getBoundingClientRect();
        if (hr.width < 200 || hr.height < 200) continue;
        // المعرض الرئيسي أعلى الصفحة فقط — لا صور الشيت المفتوح.
        if (hr.top > vpH2 * 0.5) continue;
        var ha = hr.width * hr.height;
        if (ha > hbestA) { hbestA = ha; hbest = hsrc; }
      }
      if (hbest) window.__otlobliTemuColorImg = hbest;
    }
    setTimeout(captureHero2, 700);
    setTimeout(captureHero2, 1600);
  }
  // مستمع نقر يسجّل آخر زر مقاس ضغطه الزبون فعلاً (المصدر الأوثق للمقاس).
  if (IS_TEMU && !window.__otlobliTemuClickBound) {
    window.__otlobliTemuClickBound = true;
    document.addEventListener('click', function (e) {
      // مسجّل نقرات تشخيصي (نسخة اختبار): يحسم "النقر مش راضي يُسجّل" — هل
      // النقرة تصل خيار [role=radio]، وهل Temu تقلب aria-checked بعدها؟
      try {
        var tEl0 = e.target;
        var inRadio0 = (tEl0 && tEl0.closest) ? tEl0.closest('[role="radio"]') : null;
        var inSku0 = (tEl0 && tEl0.closest) ? tEl0.closest('[class*="skuSelector"]') : null;
        window.__otlobliLastTap = {
          tag: (tEl0 && tEl0.tagName) || '?',
          radio: !!inRadio0, sku: !!inSku0,
          before: inRadio0 ? (inRadio0.getAttribute('aria-checked') || '?') : '-',
          after: '?'
        };
        if (inRadio0 && temuOptionUnavailable(inRadio0)) {
          window.__otlobliLastTap.disabled = 'yes';
          otlobliTemuMarkUnavailableTap();
        }
        if (inRadio0) {
          setTimeout(function () {
            try { if (window.__otlobliLastTap) window.__otlobliLastTap.after = inRadio0.getAttribute('aria-checked') || '?'; } catch (e2) {}
          }, 450);
          (function (radioEl, gidAtClick) {
            setTimeout(function () {
              try {
                if (temuOptionUnavailable(radioEl)) {
                  if (window.__otlobliLastTap) window.__otlobliLastTap.disabled = 'yes';
                  return;
                }
                window.__otlobliTemuUnavailableTapTs = 0;
                var groupName = otlobliTemuSkuOptionGroupName(radioEl);
                var optionText = otlobliTemuSkuOptionValue(radioEl, false);
                var hasImage = !!(radioEl.querySelector && radioEl.querySelector('img'));
                var colorGroup = /\u0627\u0644\u0644\u0648\u0646|\u0644\u0648\u0646|colou?r/i.test(groupName) || (hasImage && !/\u0645\u0648\u062f\u064a\u0644|\u0645\u0642\u0627\u0633|size|model|iphone|\u0622\u064a\u0641\u0648\u0646|\u0627\u064a\u0641\u0648\u0646/i.test(groupName));
                if (!colorGroup && optionText && optionText.length <= 40
                    && !/\u0623\u0636\u0641|\u0627\u0644\u0633\u0644\u0629|\u0627\u0644\u0643\u0645\u064a\u0629|quantity|shipping|\u062e\u0635\u0645|\u0639\u0631\u0636/i.test(optionText)) {
                  window.__otlobliTemuSize = optionText;
                  window.__otlobliTemuSizeGid = gidAtClick;
                }
              } catch (e3) {}
            }, 120);
          })(inRadio0, temuGoodsId());
        }
      } catch (eTap) {}
      // توجيه نقرات شريط otlobli السفلي: تيمو تضيف طبقات بنفس z-index الأقصى
      // بعد شريطنا في DOM فتبتلع نقراته حتى يُعاد ترتيبه (كل ثانيتين). نحن
      // مسجّلون أول مستمع capture على document (السكريبت يعمل documentStart)
      // فنستقبل النقرة قبل أي طبقة دخيلة ونوجّهها للتبويب الصحيح يدوياً.
      try {
        var navEl2 = document.getElementById('otlobli-nav');
        if (navEl2 && typeof e.clientY === 'number') {
          var nr2 = navEl2.getBoundingClientRect();
          if (nr2.height > 0 && e.clientY >= nr2.top && e.clientY <= nr2.bottom
              && e.clientX >= nr2.left && e.clientX <= nr2.right) {
            var inNav2 = false, tn2 = e.target, th2 = 0;
            while (tn2 && th2 < 8) {
              if (tn2.id && String(tn2.id).indexOf('otlobli') === 0) { inNav2 = true; break; }
              tn2 = tn2.parentElement; th2++;
            }
            if (!inNav2) {
              e.preventDefault();
              e.stopPropagation();
              // direction:rtl → التبويب الأول (الرئيسية) في أقصى اليمين
              var relX2 = (e.clientX - nr2.left) / Math.max(1, nr2.width);
              var idx2 = Math.floor((1 - relX2) * 4);
              if (idx2 < 0) idx2 = 0; if (idx2 > 3) idx2 = 3;
              var types2 = ['openHome', 'openOrders', 'openCart', 'openProfile'];
              if (types2[idx2] && window.mobileApp && window.mobileApp.postMessage) {
                if (types2[idx2] === 'openHome') {
                  try {
                    var homePath2 = sessionStorage.getItem('__otlobliHomePath') || (location.hostname.indexOf('temu.') >= 0 ? '/sa/' : '/ar/');
                    location.assign(location.origin + homePath2);
                  } catch (homeError2) {}
                  return;
                }
                var nativeTarget2 = types2[idx2] === 'openOrders' ? 'orders' : (types2[idx2] === 'openCart' ? 'cart' : 'profile');
                if (typeof window.mobileApp.navigate === 'function') {
                  window.mobileApp.navigate(nativeTarget2);
                } else {
                  window.mobileApp.postMessage({ detail: { type: types2[idx2] } });
                  if (typeof window.mobileApp.hide === 'function') window.mobileApp.hide();
                }
              }
              // نعيد شريطنا لآخر الـDOM فوراً ليستعيد أولوية الرسم
              try { (document.documentElement || document.body).appendChild(navEl2); } catch (err2) {}
              return;
            }
          }
        }
      } catch (errNav) {}
      try {
        // التقاط احتياطي للّون بعد أي نقرة: تيمو تُحدّث عنوان "اللون: X" بعد
        // الاختيار — يغطي كروت الألوان النصية (ساعات/إكسسوارات) التي لا
        // يلتقطها فرع (ب) لأنها بلا صور.
        if (!window.__otlobliTemuHeadingTimer) {
          window.__otlobliTemuHeadingTimer = setTimeout(function () {
            window.__otlobliTemuHeadingTimer = null;
            try {
              var hc = temuColorFromHeading();
              var gidH = temuGoodsId();
              // نقرة كرت لون حديثة (<1.2ث) على نفس المنتج = مصدر أوثق من
              // العنوان الذي قد لا يكون تحدّث بعد — لا نستبدلها.
              var recentCardClick = window.__otlobliTemuColorGid === gidH
                && window.__otlobliTemuColorTs && (Date.now() - window.__otlobliTemuColorTs) < 1200;
              if (hc && !recentCardClick && (window.__otlobliTemuColorGid !== gidH || window.__otlobliTemuColor !== hc)) {
                // منتج مختلف → الـswatch القديم لا يخصّه؛ نفس المنتج → نُبقيه
                // (نقرة كرت الصورة التقطته للتو وقد يسمّي العنوان اللون باسم آخر).
                if (window.__otlobliTemuColorGid !== gidH) window.__otlobliTemuColorSwatch = '';
                window.__otlobliTemuColor = hc;
                window.__otlobliTemuColorGid = gidH;
                window.__otlobliTemuColorImg = '';
                temuScheduleHeroCapture(gidH);
              }
            } catch (errH) {}
          }, 450);
        }
      } catch (errH2) {}
      try {
        // (أ) نقرة على زر مقاس.
        var pills = temuSizePills();
        var node = e.target, hops = 0;
        while (node && hops < 4 && pills.length) {
          var matched = false;
          for (var i = 0; i < pills.length; i++) {
            if (pills[i] === node) {
              var t = temuCleanText(node.textContent);
              if (t && t.length <= 24) {
                window.__otlobliTemuUnavailableTapTs = 0;
                window.__otlobliTemuSize = t;
                window.__otlobliTemuSizeGid = temuGoodsId();
              }
              matched = true; break;
            }
          }
          if (matched) return;
          node = node.parentElement; hops++;
        }
        // (ب) نقرة على كرت لون.
        // المنطق: نتحقق من حجم العنصر (كرت فردي ≠ شبكة كاملة)، وندّعم
        // فقط الحالات التي يحوي فيها العنصر 1-4 صور. نأخذ اسم اللون من
        // alt الصورة أولاً، ثم آخر عنصر نصي ظاهر (نتجنب script/style/img).
        // نرفض أي قيمة تبدأ برقم أو تحتوي كود JS (يحلّ مشكلة script tag).
        if (temuHasColorSection()) {
          var isOkColorName = function(s) {
            return s.length >= 2 && s.length <= 50
              && /^[a-zA-Z\\u0600-\\u06FF]/.test(s)
              && !/^(color|image|select|add|qty|free|shipping|size)$/i.test(s)
              && !/[{};]|\\bvar\\b|\\bfor\\b|\\bfunction\\b/.test(s);
          };
          var cnode = e.target, ch = 0;
          while (cnode && ch < 6) {
            var cr3 = cnode.getBoundingClientRect ? cnode.getBoundingClientRect() : null;
            var cnodeUnavailable = temuOptionUnavailable(cnode);
            if (cnodeUnavailable) otlobliTemuMarkUnavailableTap();
            // حجم معقول لكرت لون فردي (يستبعد الشبكة الكاملة)
            if (!cnodeUnavailable && cr3 && cr3.width > 20 && cr3.width < 300 && cr3.height > 20 && cr3.height < 420) {
              var cImgs = cnode.querySelectorAll ? cnode.querySelectorAll('img') : [];
              if (cImgs.length >= 1 && cImgs.length <= 4) {
                var cardImg2 = cImgs[0];
                // مصدر 1: alt الصورة
                var altN2 = temuCleanText(cardImg2.getAttribute('alt') || cardImg2.getAttribute('title') || '');
                var colorName2 = isOkColorName(altN2) ? altN2 : '';
                if (!colorName2) {
                  // مصدر 2: آخر عنصر ابن مرئي (من الآخر للأول — العنوان عادةً آخر ابن)
                  var cKids = cnode.children ? cnode.children : [];
                  for (var ck = cKids.length - 1; ck >= 0 && !colorName2; ck--) {
                    var ckTag = (cKids[ck].tagName || '').toLowerCase();
                    if (ckTag === 'img' || ckTag === 'script' || ckTag === 'style'
                        || ckTag === 'picture' || ckTag === 'source'
                        || ckTag === 'canvas' || ckTag === 'svg') continue;
                    var ckTxt = (cKids[ck].textContent || '')
                      .replace(/[^\\w\\u0600-\\u06FF\\s().\\-]/g, ' ')
                      .replace(/\\s+/g, ' ').trim();
                    if (isOkColorName(ckTxt)) colorName2 = ckTxt;
                  }
                }
                colorName2 = temuStripQuantity(colorName2);
                if (colorName2) {
                  var gidNow = temuGoodsId();
                  window.__otlobliTemuUnavailableTapTs = 0;
                  window.__otlobliTemuColor = colorName2;
                  window.__otlobliTemuColorGid = gidNow;
                  // طابع زمني: يمنع مؤقّت قراءة العنوان (450ms) من استبدال
                  // هذا اللون بقيمة عنوان لم تتحدّث بعد (سباق زمني).
                  window.__otlobliTemuColorTs = Date.now();
                  // الكرت الصغير = صورة اللون للعرض في السلة (colorImage).
                  // نقبل أي URL مطلق (http/https) لأن Temu قد تعتمد CDN مختلفة.
                  var cSrc = cardImg2.currentSrc || cardImg2.src || '';
                  window.__otlobliTemuColorSwatch = (cSrc && cSrc.indexOf('http') === 0) ? cSrc : '';
                  // امسح الهيرو القديم — سيُحدَّث بعد 250ms حين تُحدّث تيمو صورة الهيرو
                  window.__otlobliTemuColorImg = '';
                  // نحاول التقاط صورة الهيرو مرتين: 300ms و 600ms بعد النقر
                  // (تيمو قد تتأخر في تحديث الهيرو، والمحاولة الثانية هي الأدق)
                  ;(function(gid) {
                    function captureHero() {
                      if (window.__otlobliTemuColorGid !== gid) return;
                      var himgs = document.querySelectorAll('img');
                      var hbest = '', hbestA = 0;
                      var vpH0 = viewportSize().height;
                      for (var hi = 0; hi < himgs.length; hi++) {
                        var hsrc = himgs[hi].currentSrc || himgs[hi].src || '';
                        if (!/kwcdn|temu/i.test(hsrc)) continue;
                        var hr = himgs[hi].getBoundingClientRect();
                        if (hr.width < 200 || hr.height < 200) continue;
                        // المعرض الرئيسي أعلى الصفحة فقط — صور الشيت المفتوح
                        // (النصف السفلي) قد تكون للون قديم.
                        if (hr.top > vpH0 * 0.5) continue;
                        var ha = hr.width * hr.height;
                        if (ha > hbestA) { hbestA = ha; hbest = hsrc; }
                      }
                      if (hbest) window.__otlobliTemuColorImg = hbest;
                    }
                    // نُطيل الانتظار: الشيت قد يبقى مفتوحاً 400-700ms فيلتقط الـtimeout
                  // صورة لون قديمة من داخله بدل الهيرو الصحيح بعد إغلاقه.
                  setTimeout(captureHero, 700);
                  setTimeout(captureHero, 1600);
                  })(gidNow);
                  return;
                }
                // كرت لون بلا اسم (صورة فقط، بلا alt ولا نص — شائع بالفساتين):
                // نسجّل صورته على الأقل، والاسم سيأتي من عنوان "اللون: X" عبر
                // مؤقّت القراءة بعد النقرة. شرط أمان: الكرت قريب عمودياً من
                // رأس قسم اللون (يستبعد كروت المنتجات المقترحة أسفل الصفحة).
                var headNode3 = null;
                var hnScan = document.querySelectorAll('div, span, h2, h3, p, strong');
                for (var hn = 0; hn < hnScan.length; hn++) {
                  if (temuIsColorHeadText((hnScan[hn].textContent || '').trim())) { headNode3 = hnScan[hn]; break; }
                }
                if (headNode3) {
                  var hr3 = headNode3.getBoundingClientRect();
                  var cr4 = cnode.getBoundingClientRect();
                  if (hr3.height > 0 && cr4.top >= hr3.top - 60 && cr4.top - hr3.top < 300) {
                    var cSrc2 = cardImg2.currentSrc || cardImg2.src || '';
                    if (cSrc2 && cSrc2.indexOf('http') === 0) {
                      var gidNow2 = temuGoodsId();
                      window.__otlobliTemuUnavailableTapTs = 0;
                      if (window.__otlobliTemuColorGid !== gidNow2) window.__otlobliTemuColor = '';
                      window.__otlobliTemuColorGid = gidNow2;
                      window.__otlobliTemuColorSwatch = cSrc2;
                      window.__otlobliTemuColorImg = '';
                      temuScheduleHeroCapture(gidNow2);
                      return;
                    }
                  }
                }
              }
            }
            cnode = cnode.parentElement; ch++;
          }
        }
      } catch (err) {}
    }, true);
  }

  // منتج تخصيص (نقش اسم): نظام إشارات صارم بطبقتين — خربطة صفر.
  // الطبقة 1: عنوان المنتج نفسه يذكر تخصيصاً صريحاً (نقش اسم/محفور/engrav).
  //   لا نمسح كروت "منتجات مقترحة" (كانت تُفعّل جوارب بسبب سوارة مقترحة).
  // الطبقة 2: حقل إدخال هو فعلاً حقل تخصيص — نفحص سياقه (placeholder/label)
  //   لا مجرد وجوده: حقل الكمية "1" وحقل البحث كانا يُفعّلان كل المنتجات!
  var TEMU_PERSO_STRONG = /personaliz|engrav|محفور|محفورة|حفر\\s*اسم|نقش\\s*اسم|نقش\\s*الاسم|نقش\\s*نص|custom\\s*text|custom\\s*name|customiz|اكتب\\s*اسم|اسم\\s*مخصص|نص\\s*مخصص|اكتب\\s*نص|باسمك|بأسمك/i;
  // كلمات تدل أن الحقل حقل تخصيص (في placeholder/aria-label/name/id أو التسمية المجاورة)
  var TEMU_PERSO_INPUT = /نقش|اسم|نص\\s*مخصص|[أإا]دخ[اآ]?ل\\s*(?:النص|الاسم)|اكتب\\s*(?:النص|الاسم)|personaliz|engrav|custom|your\\s*(?:name|text)|enter\\s*(?:name|text)/i;
  // كلمات تنفي أن الحقل حقل تخصيص (كمية/بحث/كوبون/هاتف/بريد/عنوان)
  var TEMU_PERSO_ANTI = /كمية|كميه|qty|quantit|بحث|search|coupon|promo|كوبون|رمز|code|zip|postal|هاتف|phone|جوال|بريد|email|عنوان|address|password|كلمة/i;
  function temuPersoInputHint(inp) {
    var hint = (inp.getAttribute('placeholder') || '') + ' ' +
      (inp.getAttribute('aria-label') || '') + ' ' +
      (inp.getAttribute('name') || '') + ' ' + (inp.id || '');
    // التسمية المجاورة: نص الأب المباشر (قصير فقط — حتى لا نجرّ نص الصفحة كله)
    var par = inp.parentElement;
    for (var h = 0; par && h < 2; h++) {
      var pt = (par.textContent || '').trim();
      if (pt.length <= 90) hint += ' ' + pt;
      par = par.parentElement;
    }
    return hint;
  }
  function temuPersonalization() {
    // الطبقة 1: عنوان المنتج (المصدر الحاسم — لا يتأثر بالمنتجات المقترحة)
    var titleTxt = (temuTitle() || '') + ' ' + (document.title || '');
    var hasStrong = TEMU_PERSO_STRONG.test(titleTxt);
    // الطبقة 2: حقل تخصيص حقيقي مرئي (سياقه يؤكد أنه لإدخال اسم/نص)
    var inputs = document.querySelectorAll('input:not([type="hidden"]):not([type="checkbox"]):not([type="radio"]):not([type="submit"]):not([type="button"]):not([type="number"]):not([type="tel"]):not([type="email"]):not([type="search"]):not([type="file"]), textarea');
    for (var k = 0; k < inputs.length; k++) {
      var inp = inputs[k];
      var im = (inp.getAttribute('inputmode') || '').toLowerCase();
      if (im === 'numeric' || im === 'decimal' || im === 'search' || im === 'tel' || im === 'email') continue;
      var rp = inp.getBoundingClientRect();
      if (rp.width <= 20 || rp.height <= 10) continue;
      var hint = temuPersoInputHint(inp);
      if (TEMU_PERSO_ANTI.test(hint)) continue;           // كمية/بحث/كوبون → ليس تخصيصاً
      if (!TEMU_PERSO_INPUT.test(hint)) continue;          // لا دليل أنه حقل تخصيص → نتجاهله
      var v = (inp.value || '').trim();
      if (/^\\d+$/.test(v)) v = '';                        // قيمة رقمية بحتة = ليست نص نقش
      // (v58) حد أحرف النقش: من خاصية maxlength للحقل نفسه، وإلا من نص
      // التلميح المجاور ("بحد أقصى 10 أحرف" / "max 12 characters").
      var lim = parseInt(inp.getAttribute('maxlength') || '', 10);
      if (!(lim > 0 && lim <= 80)) {
        var lm = hint.match(/(\\d{1,2})\\s*(?:حرف|أحرف|حروف|characters?|chars?|letters?)/i);
        lim = lm ? parseInt(lm[1], 10) : 0;
      }
      return { has: true, text: v, inputVisible: true, textLimit: (lim > 0 && lim <= 80) ? lim : 0 };
    }
    // مؤشر قوي بالعنوان بدون حقل مرئي → التخصيص داخل الشيت، الاسم يُكتب في السلة
    if (hasStrong) return { has: true, text: '', inputVisible: false, textLimit: 0 };
    return { has: false, text: '', textLimit: 0 };
  }
  // (v58) بادج "التخصيص" الذي تضعه تيمو على صورة المنتج — نص قصير مطابق حرفياً.
  // نقيّده بأعلى الصفحة (أول ~900px من المستند) لأن كروت "قد يعجبك أيضاً"
  // أسفل الصفحة تحمل البادج نفسه على منتجات أخرى وكانت ستفعّل كل الصفحات.
  function temuCustomBadgeVisible() {
    var els = document.querySelectorAll('div, span, a, button, label');
    var scrollY = window.pageYOffset || 0;
    for (var i = 0; i < els.length; i++) {
      var t = temuCleanText(els[i].textContent);
      if (!t || t.length > 20) continue;
      if (!/^(?:التخصيص|تخصيص|قابل\\s*للتخصيص|customi[sz]ed?|personali[sz]ed?)$/i.test(t)) continue;
      var r = els[i].getBoundingClientRect();
      if (r.width <= 0 || r.height <= 0) continue;
      if (r.top + scrollY > 900) continue;
      return true;
    }
    return false;
  }
  // (v58) عنصر تحكم فعلي لرفع صورة: حقل ملف يقبل صوراً، أو زر نصّه حرفياً
  // "أضف/ارفع/تحميل صورة". يُستدعى فقط بعد ثبوت أن المنتج مخصص — "أضف صورة"
  // في قسم المراجعات مثلاً كانت تجعل كل المنتجات "تطلب صورة".
  function temuPhotoUploadControl() {
    if (document.querySelector('input[type="file"][accept*="image"], input[type="file"]:not([accept])')) return true;
    var els = document.querySelectorAll('button, a, div, span, label');
    for (var i = 0; i < els.length; i++) {
      var t = temuCleanText(els[i].textContent);
      if (!t || t.length > 22) continue;
      if (!/^(?:أضف|إضافة|ارفع|رفع|تحميل|حمّل)\\s*(?:ال)?صورة(?:\\s*هنا)?$|^(?:add|upload)\\s*(?:a\\s*|your\\s*)?(?:photo|image|picture)s?$/i.test(t)) continue;
      var r = els[i].getBoundingClientRect();
      if (r.width > 0 && r.height > 0) return true;
    }
    return false;
  }
  // أبعاد/وصف الصورة المخصصة المطلوبة — يبحث عن نصوص تذكر قياسات الصورة
  // مثل "800×800 بكسل" أو "photo size: 3:4 ratio" في صفحة المنتج.
  function temuCustomPhotoNote() {
    var els = document.querySelectorAll('div, span, p, li, strong, td, th');
    for (var i = 0; i < els.length; i++) {
      var t = (els[i].textContent || '').trim();
      if (!t || t.length < 4 || t.length > 120) continue;
      if (/\\d+\\s*[*x×]\\s*\\d+\\s*(?:px|pixel|بكسل)?/i.test(t)
       || /photo.*size|size.*photo|صورة.*حجم|حجم.*صورة|image.*size|size.*image/i.test(t)
       || /ratio|aspect|نسبة.*صورة|صورة.*نسبة/i.test(t)) {
        return t.slice(0, 100);
      }
    }
    return '';
  }

  // إشارات التخصيص الصارمة (تُطبَّق على العنوان/نص تحكم قصير فقط): بلا كلمات
  // عامة مفردة (اسم/نص/صورة/رفع) لأنها بكل صفحة وكانت تفعّل منتجات عادية كمخصصة.
  // "نقش" وحدها ممنوعة (بنقشة/منقوش = طبعة جاهزة) — فقط بسياق صريح: "نقش اسم".
  function otlobliCustomTextSignal(text) {
    return /custom\\s*(?:text|name)|personali[sz]|engrav|monogram|name\\s*plate|your\\s*(?:name|text)|enter\\s*(?:name|text)|نقش\\s*(?:اسم|الاسم|نص|النص|حسب)|قابل\\s*للنقش|انقش|محفور(?:ة)?\\s*(?:باسم|بالاسم|باسمك)|حفر\\s*(?:اسم|الاسم|نص)|بالاسم|باسمك|بأسمك|اسم\\s*مخصص|نص\\s*مخصص|اكتب\\s*(?:اسم|الاسم|نص|النص)/i.test(text || '');
  }

  function otlobliCustomPhotoSignal(text) {
    return /custom\\s*(?:photo|image|picture)|(?:upload|add)\\s*(?:a\\s*|your\\s*)?(?:photo|image|picture)|photo\\s*upload|image\\s*upload|with\\s*your\\s*(?:photo|picture)|صورة\\s*مخصصة|بصورتك|صورتك|بالصور|(?:أضف|إضافة|ارفع|رفع|تحميل|حمّل)\\s*(?:ال)?صورة/i.test(text || '');
  }

  function otlobliCustomGenericSignal(text) {
    return /customi[sz]|\\bcustom\\b|personali[sz]|مخصص|التخصيص|تخصيص|بتصميمك|حسب\\s*الطلب|\\bDIY\\b/i.test(text || '');
  }

  function otlobliVisibleCustomText() {
    var out = [];
    var nodes = document.querySelectorAll('h1, h2, h3, p, span, div, button, label, li');
    for (var i = 0; i < nodes.length && out.join(' ').length < 5000; i++) {
      var el = nodes[i];
      var r = el.getBoundingClientRect();
      if (r.width <= 0 || r.height <= 0) continue;
      var t = (el.textContent || '').replace(/\\s+/g, ' ').trim();
      if (!t || t.length > 180) continue;
      if (otlobliCustomGenericSignal(t) || otlobliCustomTextSignal(t) || otlobliCustomPhotoSignal(t) || /\\d+\\s*[*x×]\\s*\\d+/.test(t)) {
        out.push(t);
      }
    }
    return out.join(' ');
  }

  function otlobliCustomPhotoNoteFallback() {
    var pageText = otlobliVisibleCustomText();
    var sizeMatch = pageText.match(/\\d+\\s*[*x×]\\s*\\d+\\s*(?:px|pixel|بكسل)?/i);
    if (sizeMatch) return sizeMatch[0];
    if (otlobliCustomPhotoSignal(pageText)) return 'يرجى إرفاق الصورة المطلوبة لهذا المنتج المخصص';
    return '';
  }

  // (v58) قرار التخصيص لتيمو — طبقتان صارمتان:
  // 1) هل المنتج مخصص أصلاً؟ يُحسم من عنوان المنتج نفسه، أو بادج "التخصيص"
  //    أعلى الصفحة، أو حقل نقش حقيقي مرئي (perso). لا مسح نصي للصفحة كلها —
  //    كروت المنتجات المقترحة والمراجعات كانت تلوّث القرار.
  // 2) ماذا يحتاج (نص/صورة/كلاهما)؟ يُفحص فقط بعد ثبوت (1)، من العنوان
  //    وعناصر تحكم قصيرة مؤكدة. عند الغموض: الافتراض نص، والمستخدم يعدّل
  //    من السلة (أزرار +نص/+صورة و"ليس مخصصاً").
  function temuCustomRequirements(perso) {
    var titleTxt = (temuTitle() || '') + ' ' + (document.title || '');
    var isCustom = otlobliCustomGenericSignal(titleTxt)
      || otlobliCustomTextSignal(titleTxt)
      || otlobliCustomPhotoSignal(titleTxt)
      || !!(perso && perso.has)
      || temuCustomBadgeVisible();
    if (!isCustom) return { needsText: false, needsPhoto: false, photoNote: '', textLimit: 0 };
    var needsText = !!(perso && perso.has) || otlobliCustomTextSignal(titleTxt);
    var needsPhoto = otlobliCustomPhotoSignal(titleTxt) || temuPhotoUploadControl();
    // منتج مخصص وعنوانه يذكر عيوناً/وجهاً/حبيباً بالصورة (أساور نقش العين
    // الرائجة) → صورة، حتى لو لم يقل "صورة" صراحة.
    if (!needsPhoto && /(?:^|[\\s،:])(?:عين|عيون|للعينين|بالعين|وجه|وجهك|بورتريه)|\\bface\\b|\\beyes?\\b|\\bportrait\\b/i.test(titleTxt)) needsPhoto = true;
    // جراب/كفر مخصص بلا ذكر نقش = طباعة صورة عادةً.
    if (!needsText && !needsPhoto && /(phone|case|cover|جراب|كفر|حافظة)/i.test(titleTxt)) needsPhoto = true;
    // مخصص مؤكد والنوع غامض → نص (الأشيَع)، والمستخدم يستطيع التعديل بالسلة.
    if (!needsText && !needsPhoto) needsText = true;
    return {
      needsText: needsText,
      needsPhoto: needsPhoto,
      photoNote: needsPhoto ? (temuCustomPhotoNote() || otlobliCustomPhotoNoteFallback()) : '',
      textLimit: (perso && perso.textLimit) || 0,
    };
  }

  // (v58) نفس مبدأ تيمو: العنوان يحسم "هل هو مخصص"، وحقل الملف يُحتسب فقط
  // بعد ثبوت ذلك (شي إن فيها حقول رفع للمراجعات أيضاً).
  function sheinCustomRequirements() {
    var titleTxt = (getTitle(false) || '') + ' ' + (document.title || '');
    var isCustom = otlobliCustomGenericSignal(titleTxt)
      || otlobliCustomTextSignal(titleTxt)
      || otlobliCustomPhotoSignal(titleTxt);
    if (!isCustom) return { needsText: false, needsPhoto: false, photoNote: '', textLimit: 0 };
    var hasFile = !!document.querySelector('input[type="file"][accept*="image"]');
    var needsText = otlobliCustomTextSignal(titleTxt);
    var needsPhoto = hasFile || otlobliCustomPhotoSignal(titleTxt);
    if (!needsText && !needsPhoto) needsText = true;
    return {
      needsText: needsText,
      needsPhoto: needsPhoto,
      photoNote: needsPhoto ? otlobliCustomPhotoNoteFallback() : '',
      textLimit: 0,
    };
  }

  // هل توجد قائمة مقاسات؟ (عنوان "Size"/"المقاس"/"موديل متوافق")
  function temuHasSizeSection() { return !!temuSizeHeadEl(); }
  // A Temu SKU picker is a real product form, even though its full-screen
  // dialog repeats promotional copy such as "discount".  Both the document-
  // start Gecko guard and the slower shared cleanup use this structural test
  // so neither can collapse the picker while the customer chooses a size.
  function temuProductOptionDialog(node) {
    if (!IS_TEMU || !looksLikeProductPage() || !node || !node.querySelectorAll) return false;
    var dialog = node.matches && node.matches('[role="dialog"]')
      ? node
      : (node.closest && node.closest('[role="dialog"]'));
    if (!dialog || dialog.querySelectorAll('[role="radio"]').length < 2) return false;
    return !!dialog.querySelector('[class*="sku" i],[class*="spec" i]');
  }
  function temuHasSelectableSecondOption() {
    var pills = temuSizePills();
    if (pills.length > 0) return true;
    var counts = temuVariantCounts();
    return counts.sizes > 1;
  }
  // صفحة المنتج المغلقة تعرض ملخّصاً مثل "7 Color, 3 Size" أو "5 اللون, 20 موديل"
  // قبل اكتمال الاختيار — هذا الزر يفتح لوحة الخيارات عند النقر عليه.
  function temuVariantSummaryEl() {
    var els = document.querySelectorAll('div, button, a, span');
    for (var i = 0; i < els.length; i++) {
      var t = temuCleanText(els[i].textContent);
      if (t.length > 65) continue;
      var hasClr = !!temuVariantColorCountMatch(t);
      var hasSz  = !!temuVariantSecondOptionCountMatch(t);
      if (hasClr && hasSz) return els[i];
    }
    return null;
  }

  function otlobliTemuCollapsedVariantRow() {
    try {
      var triggers = document.querySelectorAll('button, [role="button"], a, div, span');
      for (var i = 0; i < triggers.length; i++) {
        var trigger = triggers[i];
        if (trigger.id && trigger.id.indexOf('otlobli') === 0) continue;
        var triggerText = temuCleanText((trigger.getAttribute && (trigger.getAttribute('aria-label') || trigger.getAttribute('title'))) || trigger.textContent || '');
        if (!/^(?:\u062d\u062f\u062f|select|choose)$/i.test(triggerText) && !/(?:\u062d\u062f\u062f|select|choose)/i.test(triggerText)) continue;
        var tr = trigger.getBoundingClientRect ? trigger.getBoundingClientRect() : null;
        if (tr && (tr.width <= 0 || tr.height <= 0)) continue;
        var node = trigger, depth = 0;
        while (node && node !== document.body && depth < 6) {
          var r = node.getBoundingClientRect ? node.getBoundingClientRect() : null;
          if (r && (r.width <= 0 || r.height <= 0)) { node = node.parentElement; depth++; continue; }
          var txt = temuCleanText((node.getAttribute && (node.getAttribute('aria-label') || node.getAttribute('title'))) || node.textContent || '');
          if (txt.length >= 8 && txt.length <= 220 && /(?:\u062d\u062f\u062f|select|choose)/i.test(txt) && !temuContainsPrice(node)) {
            var colorMatch = temuVariantColorCountMatch(txt);
            var sizeMatch = temuVariantSecondOptionCountMatch(txt);
            var colorCount = colorMatch ? (parseInt(colorMatch[1], 10) || 0) : 0;
            var sizeCount = sizeMatch ? (parseInt(sizeMatch[1], 10) || 0) : 0;
            if (colorCount > 0 || sizeCount > 0) {
              var sizeName = temuVariantSecondOptionName(txt);
              return { el: trigger, text: txt, colors: colorCount, sizes: sizeCount, sizeName: sizeName };
            }
          }
          node = node.parentElement; depth++;
        }
      }
    } catch (e) {}
    return null;
  }

  // كاشف الخيارات البنيوي (v85.8.40): يقرأ عنصر skuSelector الفعلي فقط، بدل
  // بنية SKU تيمو (بلا مسح نصي للصفحة الذي كان يلتقط شحناً كرأس مقاس):
  //  - مطوي: div.skuSelector-* [role=button] > .info-* ("N اللون, M مقاس").
  //  - مفرود: .specListWrap-*؛ رأسه .type-*[aria-label]، خياراته [role=radio]،
  //    المختار aria-checked="true" (الكمية منفصلة .specTypeName-*).
  function otlobliTemuSkuOptionGroupName(opt) {
    try {
      var optRect = opt && opt.getBoundingClientRect ? opt.getBoundingClientRect() : null;
      var node = opt, depth = 0;
      while (node && depth < 7) {
        var heads = node.querySelectorAll ? node.querySelectorAll('[class*="type-"][aria-label], [class*="specTypeName"], [class*="type-"]') : [];
        var best = '', bestDy = 999999, fallback = '';
        for (var h = 0; h < heads.length; h++) {
          var ht = temuCleanText((heads[h].getAttribute && heads[h].getAttribute('aria-label')) || heads[h].textContent || '');
          if (!ht || ht.length > 80 || /\u0627\u0644\u0643\u0645\u064a\u0629|\u0643\u0645\u064a\u0629|quantity/i.test(ht)) continue;
          if (!fallback) fallback = ht;
          if (!optRect || !heads[h].getBoundingClientRect) continue;
          var hr = heads[h].getBoundingClientRect();
          if (hr.height <= 0 || hr.bottom > optRect.bottom + 8) continue;
          var dy = Math.abs(optRect.top - hr.bottom);
          if (dy < bestDy) { bestDy = dy; best = ht; }
        }
        if (best) return best;
        if (fallback && depth < 3) return fallback;
        node = node.parentElement; depth++;
      }
    } catch (e) {}
    return '';
  }

  function otlobliTemuSkuOptionValue(opt, isColor) {
    try {
      if (!opt) return '';
      var im = opt.querySelector && opt.querySelector('img');
      var imgTxt = im ? temuCleanText((im.getAttribute && (im.getAttribute('alt') || im.getAttribute('title'))) || '') : '';
      var txt = temuCleanText(opt.textContent || '');
      if (isColor && imgTxt) return imgTxt;
      if (txt && txt.length <= 50) return txt;
      return imgTxt || 'selected';
    } catch (e) {}
    return '';
  }

  function otlobliTemuSku() {
    var out = { hasSelector: false, single: false, dims: [], collapsedEl: null };
    try {
      var sels = document.querySelectorAll('[class*="skuSelector"]');
      var collapsed = null;
      for (var i = 0; i < sels.length; i++) {
        if (!/skuSelector-/.test((sels[i].className || '') + '')) continue;
        if (sels[i].getAttribute('role') === 'button') { collapsed = sels[i]; break; }
      }
      if (collapsed) {
        out.hasSelector = true; out.collapsedEl = collapsed;
        var infoEl = collapsed.querySelector('[class*="info-"]');
        var infoTxt = temuCleanText(infoEl ? infoEl.textContent : (collapsed.getAttribute('aria-label') || ''));
        if (/singleOnsale/.test((collapsed.className || '') + '') ||
            /خيار واحد فقط|يتوفر خيار واحد|only one option/i.test(infoTxt)) {
          out.single = true;
        }
        var cM = temuVariantColorCountMatch(infoTxt);
        var sM = temuVariantSecondOptionCountMatch(infoTxt);
        if (cM) out.dims.push({ kind: 'color', name: 'اللون', count: parseInt(cM[1], 10), selected: null, source: 'collapsed' });
        if (sM) out.dims.push({ kind: 'size', name: temuVariantSecondOptionName(infoTxt), count: parseInt(sM[1], 10), selected: null, source: 'collapsed' });
      }
      if (!collapsed) {
        var looseCollapsed = otlobliTemuCollapsedVariantRow();
        if (looseCollapsed) {
          out.hasSelector = true; out.collapsedEl = looseCollapsed.el;
          if (looseCollapsed.colors > 0) out.dims.push({ kind: 'color', name: '\u0627\u0644\u0644\u0648\u0646', count: looseCollapsed.colors, selected: null, source: 'collapsed' });
          if (looseCollapsed.sizes > 0) out.dims.push({ kind: 'size', name: looseCollapsed.sizeName || '\u0645\u0642\u0627\u0633', count: looseCollapsed.sizes, selected: null, source: 'collapsed' });
        }
      }
      // Temu currently ships both the old specListWrap-* group and the newer
      // specTypes-* group. Missing the latter left four-size products with an
      // empty sku.dims array and allowed capture without a customer selection.
      var groups = document.querySelectorAll('[class*="specListWrap"],[class*="specTypes-"]');
      for (var g = 0; g < groups.length; g++) {
        var head = groups[g].querySelector('[class*="type-"][aria-label], [class*="specTypeName"], [class*="type-"]');
        var nm = head ? temuCleanText((head.getAttribute && head.getAttribute('aria-label')) || head.textContent || '') : '';
        if (!nm || /الكمية|كمية|quantity/i.test(nm)) continue;
        var isColor = /اللون|لون|colou?r/i.test(nm);
        var opts = groups[g].querySelectorAll('[role="radio"], [aria-checked], [aria-selected]');
        var availableOpts = [];
        for (var av = 0; av < opts.length; av++) {
          if (!temuOptionUnavailable(opts[av])) availableOpts.push(opts[av]);
        }
        var sel = null;
        for (var o = 0; o < availableOpts.length; o++) {
          if (availableOpts[o].getAttribute('aria-checked') === 'true' || availableOpts[o].getAttribute('aria-selected') === 'true') {
            var im = availableOpts[o].querySelector('img');
            // اسم اللون من alt الصورة؛ المقاس من نص الزر ("L") — لا "محدد".
            sel = (im && im.getAttribute('alt')) || temuCleanText(availableOpts[o].textContent) || 'محدد';
          }
        }
        // مهم (v85.8.41): لا نعتمد .specValue لتحديد "مُختار" للمقاس — رأس المقاس
        // يعرض نظام المقاس "(SA)" لا القيمة المختارة، فكان يُحسب اختياراً زائفاً
        // فيمرّ المنتج بلا اختيار مقاس. الاختيار = aria-checked فقط. للّون فقط
        // نقبل specValue اسماً مساعداً (اللون الافتراضي يظهر بالرأس ": أخضر").
        // Temu قد تحدد اللون الافتراضي بصرياً فقط، لذا يبقى الاحتياط البصري
        // للون. المقاس المتعدد لا يُقبل إلا من aria الصريحة أعلاه أو نقرة
        // العميل المسجلة لنفس المنتج في temuSelectedSize().
        if (!sel && isColor && opts.length) {
          var optList = [];
          for (var oo = 0; oo < availableOpts.length; oo++) optList.push(availableOpts[oo]);
          var pickedOpt = temuPickSingleSelected(optList);
          if (pickedOpt) sel = otlobliTemuSkuOptionValue(pickedOpt, isColor);
        }
        if (!sel && isColor) {
          var sv = groups[g].querySelector('[class*="specValue"]');
          if (sv) { var svt = temuCleanText(sv.textContent).replace(/^[:：]\\s*/, ''); if (svt && svt.length <= 24) sel = svt; }
        }
        out.hasSelector = true;
        // When Temu's option drawer is open, its radios are authoritative. The
        // collapsed summary remains in the DOM behind the drawer and otherwise
        // creates a duplicate unselected dimension after a real radio was picked.
        for (var cd = out.dims.length - 1; cd >= 0; cd--) {
          if (out.dims[cd].source === 'collapsed' && out.dims[cd].kind === (isColor ? 'color' : 'size')) {
            out.dims.splice(cd, 1);
          }
        }
        var unavailableOnly = opts.length > 0 && availableOpts.length === 0;
        out.dims.push({ kind: isColor ? 'color' : 'size', name: nm, count: unavailableOnly ? 2 : (availableOpts.length || 1), selected: sel || null, unavailableOnly: unavailableOnly, source: 'expanded' });
      }
    } catch (e) {}
    return out;
  }
  // البُعد المطلوب أول (مقاس/لون) غير المُرضى: عدد>1 وبلا اختيار. عدد 1 أو غير
  // موجود = مُرضى تلقائياً. يعيد null إذا كل شيء جاهز أو المنتج بلا خيارات.
  function otlobliTemuUnmetDim(sku, kind) {
    if (sku.single) return null;
    for (var i = 0; i < sku.dims.length; i++) {
      var d = sku.dims[i];
      if (kind && d.kind !== kind) continue;
      if (d.count > 1 && !d.selected) return d;
    }
    return null;
  }

  function otlobliTemuCurrentColorPicked() {
    try {
      return !!((window.__otlobliTemuColor || window.__otlobliTemuColorSwatch) &&
        window.__otlobliTemuColorGid === temuGoodsId());
    } catch (e) {}
    return false;
  }

  function otlobliTemuUnmetDimResolved(sku, kind) {
    var unmet = otlobliTemuUnmetDim(sku, kind);
    if (!unmet) return null;
    if (unmet.unavailableOnly) return unmet;
    if (unmet.kind === 'color' && otlobliTemuCurrentColorPicked()) {
      if (kind) return null;
      return otlobliTemuUnmetDimResolved(sku, 'size');
    }
    if (unmet.kind === 'size' && temuSelectedSize()) {
      if (kind) return null;
      return otlobliTemuUnmetDimResolved(sku, 'color');
    }
    return unmet;
  }

  function sheinStoreVariant() {
    try {
      var el = document.getElementById('app');
      var comp = el && el._vnode && el._vnode.component;
      var store = comp && comp.proxy && comp.proxy.$store;
      var pd = store && store.state && store.state.productDetail;
      if (!pd) return null;
      var cold = pd.coldModules || {}, hot = pd.hotModules || {};
      var gid = String((cold.productInfo || {}).goods_id || '');
      var color = '', image = '';
      var msa = (cold.saleAttr && cold.saleAttr.mainSaleAttribute) ||
        (hot.saleAttr && hot.saleAttr.mainSaleAttribute);
      var mArr = (msa && msa.info && msa.info.length !== undefined) ? msa.info : [];
      for (var i = 0; i < mArr.length; i++) {
        if (String(mArr[i].goods_id) === gid) {
          color = normalizedOptionText(mArr[i].attr_value || '');
          image = normalizeImageUrl(mArr[i].goods_image || mArr[i].goods_color_image || mArr[i].attrImg || '');
          break;
        }
      }
      if (!color && mArr.length === 1) {
        color = normalizedOptionText(mArr[0].attr_value || '');
        image = normalizeImageUrl(mArr[0].goods_image || '');
      }
      try {
        var drs = document.querySelectorAll('.sui-drawer');
        for (var dd = 0; dd < drs.length; dd++) {
          if (!sheinElementIsVisible(drs[dd])) continue;
          var cis = drs[dd].querySelectorAll('.bs-color-square-image__item,[class*="color__item" i]');
          var dcol = '';
          for (var ci = 0; ci < cis.length; ci++) {
            if (!(/(?:^|\\s)active/.test(cis[ci].className) || cis[ci].getAttribute('aria-checked') === 'true')) continue;
            var cim = cis[ci].querySelector('img');
            dcol = normalizedOptionText(cis[ci].getAttribute('aria-label') || (cim && cim.getAttribute('alt')) || '');
            if (dcol) break;
          }
          if (dcol) {
            color = dcol;
            for (var mj = 0; mj < mArr.length; mj++) {
              if (normalizedOptionText(mArr[mj].attr_value || '') === dcol) {
                image = normalizeImageUrl(mArr[mj].goods_image || mArr[mj].goods_color_image || mArr[mj].attrImg || '') || image;
                break;
              }
            }
            break;
          }
        }
      } catch (e) {}
      var selVals = [];
      var domSel = document.querySelectorAll('[data-attr_value_id][aria-checked="true"],[data-attr_value_id].size-active');
      for (var d = 0; d < domSel.length; d++) {
        var sv = normalizedOptionText(domSel[d].getAttribute('data-attr_value') || '');
        if (sv) selVals.push(sv);
      }
      var ml = (hot.saleAttr && hot.saleAttr.multiLevelSaleAttribute) ||
        (cold.saleAttr && cold.saleAttr.multiLevelSaleAttribute);
      var skuList = (ml && ml.sku_list && ml.sku_list.length !== undefined) ? ml.sku_list : [];
      var matched = null;
      for (var s = 0; s < skuList.length; s++) {
        var names = (skuList[s].sku_sale_attr || []).map(function (a) { return normalizedOptionText(a.attr_value_name || ''); });
        var all = selVals.length > 0;
        for (var w = 0; w < selVals.length; w++) { if (names.indexOf(selVals[w]) < 0) { all = false; break; } }
        if (all) { matched = skuList[s]; break; }
      }
      if (!matched && skuList.length === 1) matched = skuList[0];
      var size = '', skuCode = '', priceUsd = 0;
      if (matched) {
        skuCode = String(matched.sku_code || '');
        var parts = [], attrs = matched.sku_sale_attr || [];
        for (var b = 0; b < attrs.length; b++) {
          var an = normalizedOptionText(attrs[b].attr_name || '');
          var vn = normalizedOptionText(attrs[b].attr_value_name || '');
          if (!vn) continue;
          if (/^ال?لون$/.test(an) || (color && vn === color)) { if (!color) color = vn; continue; }
          parts.push(vn);
        }
        size = parts.join(' / ');
        var sp = matched.priceInfo && matched.priceInfo.salePrice;
        if (sp) priceUsd = parseFloat(sp.usdAmount || sp.amount || 0) || 0;
      }
      if (!color && !size && !(priceUsd > 0)) return null;
      return { skuCode: skuCode, color: color, image: image, size: size, priceUsd: priceUsd };
    } catch (e) { return null; }
  }

  function sheinSizeUnselected(scope) {
    try {
      // A Curvy quick-add sheet is a separate product form painted over the
      // PDP.  Never let its required-size gate inspect the still-visible
      // background form: that made a selected 5XL look unselected and turned
      // the floating Otlobli button into an apparent no-op.
      var host = scope && scope.querySelectorAll ? scope : document;
      var o = host.querySelectorAll('[data-attr_value][data-attr_value_id]');
      var tot = 0, sel = 0, first = null;
      for (var i = 0; i < o.length; i++) {
        var h = normalizedOptionText(sheinGroupHeading(o[i]));
        if (!/مقاس|الحجم/.test(h) && h.toLowerCase() !== 'size') continue;
        tot++;
        if (!first) first = o[i];
        if (o[i].getAttribute('aria-checked') === 'true' || /size-active/.test(o[i].className)) sel++;
      }
      if (tot >= 2 && !sel) {
        try { if (first && first.scrollIntoView) first.scrollIntoView({ block: 'center' }); } catch (e) {}
        return true;
      }
      return false;
    } catch (e) { return false; }
  }

  function sheinActiveQuickAddDrawer() {
    var drawers = document.querySelectorAll('.bsc-quick-add-cart');
    for (var i = drawers.length - 1; i >= 0; i--) {
      if (sheinElementIsPainted(drawers[i]) && drawers[i].querySelector('.quickAddName__name')) return drawers[i];
    }
    return null;
  }

  function sheinQuickSizeBox(root) {
    var groups = root.querySelectorAll('.goods-size__wrapper > div');
    for (var i = 0; i < groups.length; i++) {
      var label = normalizedOptionText((groups[i].querySelector('.goods-size__title') || {}).textContent || '');
      if (/\u0645\u0642\u0627\u0633|\u062d\u062c\u0645|size/i.test(label)) return groups[i];
    }
    return root.querySelector('.goods-size');
  }

  function sheinQuickBundleCount(size) {
    var count = (String(size || '').match(/\\+/g) || []).length;
    return count ? count + 1 : 1;
  }

  function sheinQuickAddSelectionState() {
    var root = sheinActiveQuickAddDrawer();
    if (!root) return null;
    var sizeBox = sheinQuickSizeBox(root);
    if (!sizeBox) {
      var candidates = root.querySelectorAll('[class*="size" i]');
      for (var i = 0; i < candidates.length; i++) {
        var options = getSizeOptions(candidates[i]);
        if (options.available.length + options.unavailable.length >= 2) {
          sizeBox = candidates[i];
          break;
        }
      }
    }
    var sizeOptions = getSizeOptions(sizeBox);
    var sizePick = sizeBox && sizeBox.querySelector('.goods-size__sizes-item.size-active,[data-attr_value][aria-checked="true"],.size-active');
    var size = normalizedOptionText((sizePick && (sizePick.getAttribute('data-attr_value') || sizePick.textContent)) || getSelectedWithin(sizeBox));
    var colorBox = root.querySelector('.bs-main-sales-attr');
    var colorPick = colorBox && colorBox.querySelector('.bs-color__item.active,.bs-color__item[aria-checked="true"]');
    var colorText = normalizedOptionText((root.querySelector('.bs-main-sales-attr__header-title') || {}).textContent || '')
      .replace(/^[^:：]+[:：]\s*/, '').trim() || getSelectedWithin(colorBox);
    var colorOptions = colorBox ? colorBox.querySelectorAll('.bs-color__item,[role="radio"],[data-attr_value]') : [];
    return {
      root: root,
      sizeBox: sizeBox,
      color: { exists: colorOptions.length > 1, selected: colorText, image: swatchImageFrom(colorPick) },
      size: { exists: !!sizeBox && sizeOptions.available.length + sizeOptions.unavailable.length >= 2,
        selected: size, available: sizeOptions.available || [], unavailable: sizeOptions.unavailable || [] }
    };
  }

  function sheinQuickAddProductLink(root,info){
    var id=String(info&&info.goods_id||'').replace(/\D/g,'');
    if(!id)return location.href;
    var suffix='-p-'+id+'.html';
    try{var a=root.querySelector('a[href*="'+suffix+'"]');if(a&&a.href)return a.href}catch(e){}
    return location.origin+'/ar/product-p-'+id+'.html';
  }

  function sheinQuickAddPayload() {
    var root = sheinActiveQuickAddDrawer();
    if (!root) return null;
    var info = {}, node = root, app, comp;
    for (var hop = 0; node && hop < 9 && !info.goods_id; node = node.parentElement, hop++) try {
      app = node.__vue_app__; comp = app && app._container && app._container._vnode && app._container._vnode.component;
      info = (comp && comp.setupState && comp.setupState.productInfo) || info;
    } catch (e) {}
    var title = cleanTitle((root.querySelector('.quickAddName__name') || {}).textContent || info.goods_name || '');
    var active = root.querySelector('.bsc-gallery__swiper-slide-active');
    var image = realImgSrc(active && active.querySelector('img.crop-image-container__real-image,img:not([aria-hidden])')) ||
      realImgSrc(root.querySelector('.crop-image-container__real-image')) || normalizeImageUrl(info.goods_img || '');
    var colorHead = root.querySelector('.bs-main-sales-attr__header-title');
    var color = normalizedOptionText((colorHead && colorHead.textContent) || '').replace(/^[^:：]+[:：]\s*/, '').trim();
    var colorPick = root.querySelector('.bs-color__item.active,.bs-color__item[aria-checked="true"]');
    var colorImage = swatchImageFrom(colorPick);
    var sizeBox = sheinQuickSizeBox(root);
    var sizePick = sizeBox && sizeBox.querySelector('.goods-size__sizes-item.size-active,[data-attr_value][aria-checked="true"]');
    var size = normalizedOptionText((sizePick && (sizePick.getAttribute('data-attr_value') || sizePick.textContent)) || '');
    var quantityOption = sheinSelectedQuantityOption(root);
    var sizes = getSizeOptions(sizeBox);
    var price = sheinUsdValue((root.querySelector('.quickPrice__main') || {}).textContent || '') || sheinPriceFromChangedRoot(root);
    var link = sheinQuickAddProductLink(root, info);
    if (!title || !(price > 0) || !image) return null;
    return { title: title, priceUsd: price, priceSource: 'quick-add', image: image, colorImage: colorImage,
      colorImageFound: !!colorImage, color: color, size: size, quantityOption: quantityOption, skuCode: '', sizesAvailable: sizes.available || [],
      bundleCount: sheinQuickBundleCount(size),
      sizesUnavailable: sizes.unavailable || [], link: otlobliNormalizeSheinUrl(link), needsCustomPhoto: false,
      customPhotoNote: '', needsCustomText: false, customText: '', customTextLimit: 0 };
  }

  function captureProductPayload(colorState, sizeState, allowGenericTitle) {
    if (IS_TEMU) {
      var perso = temuPersonalization();
      var customReq = temuCustomRequirements(perso);
      // منتج التخصيص: نضع النص المطلوب مكان المقاس ليصل للمالك بوضوح.
      // حارس مزدوج: قيمة رقمية بحتة (حقل كمية التقط خطأً) لا تكون نص نقش أبداً.
      var persoTxt = (perso.text && !/^\\d+$/.test(perso.text)) ? perso.text : '';
      var temuSizeVal = (perso.has && persoTxt) ? ('نقش: ' + persoTxt) : temuSelectedSize();
      var temuColorSwatch = (window.__otlobliTemuColorSwatch && window.__otlobliTemuColorGid === temuGoodsId())
        ? window.__otlobliTemuColorSwatch : '';
      // شبكة أمان: لا swatch مخزّن (اختيار داخل الشيت/لون افتراضي) → نبحث
      // وقت الجذب عن كرت اللون المطابق للاسم المختار ونأخذ صورته.
      var temuColorVal = temuColor();
      if (!temuColorSwatch && temuColorVal) {
        temuColorSwatch = temuSelectedColorCardImg(temuColorVal) || '';
      }
      // شبكة أمان أخيرة: ما زالت الصورة مفقودة (كروت بلا اسم/alt نصي، أو
      // بلا عنوان "اللون: X" أصلاً - شائع بالحقائب/الملابس) → الكرت الوحيد
      // بحدّ غامق ضمن صفّ الألوان = المختار افتراضياً بصرياً.
      if (!temuColorSwatch) {
        var defCard = temuDefaultSelectedColorCard();
        if (defCard) {
          temuColorSwatch = defCard.image;
          if (!temuColorVal && defCard.name) temuColorVal = defCard.name;
        }
      }
      // اختيار بكرت صورة بلا اسم (أحذية/أجهزة): الصورة هي المرجع للمالك.
      if (!temuColorVal && temuColorSwatch) temuColorVal = 'حسب الصورة المرفقة';
      temuColorVal = temuStripQuantity(temuColorVal);
      temuSizeVal = temuStripQuantity(temuSizeVal);
      // صورة المنتج بالسلة: عند اختيار لون، صورة كرت اللون مضمونة 100%؛
      // temuImage() احتياط (وهو نفسه يفضّل الـswatch الآن).
      return {
        title: temuTitle(),
        priceUsd: temuPriceUsd(),
        image: temuColorSwatch || temuImage(),
        colorImage: temuColorSwatch,
        colorImageFound: !!temuColorSwatch,
        color: temuColorVal,
        size: temuSizeVal,
        sizesAvailable: [],
        sizesUnavailable: [],
        // نُرفق اللون/المقاس المختارين كمعاملات otlobli_* بالرابط المحفوظ -
        // تيمو تتجاهلها (معاملات مجهولة بلا تأثير) لكن هذا التطبيق يقرأها
        // عند إعادة فتح الرابط لاحقاً (من السلة/الطلبات) ليُعيد اختيار نفس
        // اللون والمقاس تلقائياً بدل صفحة افتراضية بلا اختيار.
        link: otlobliBuildDeepLink(location.href, temuColorVal, temuSizeVal),
        needsCustomPhoto: customReq.needsPhoto,
        customPhotoNote: customReq.photoNote,
        needsCustomText: customReq.needsText,
        customText: persoTxt,
        customTextLimit: customReq.textLimit || 0,
      };
    }
    var sheinQuick = sheinQuickAddPayload();
    if (sheinQuick) return sheinQuick;
    var sheinCustomReq = sheinCustomRequirements();
    // Resolve price + its source before the payload so the source describes THIS read.
    var sheinPriceUsd = getPrice();
    var sheinPriceSource = __otlobliSkuPriceSource;
    var sheinColorSel = colorState.selected;
    var sheinColorImg = colorState.image;
    var sheinSizeSel = sizeState.selected;
    var sheinQuantityOption = sheinSelectedQuantityOption();
    var sheinSizesAvail = sizeState.available || [];
    var sheinSizesUnavail = sizeState.unavailable || [];
    // A tapped swatch is more precise than the general product image, even
    // when every icon is labelled "متعدد الألوان".
    if (__otlobliSelectedSkuPricePath === location.pathname &&
        Date.now() - __otlobliSelectedSkuPriceAt < 1800000) {
      if (__otlobliSelectedSkuColorImage) sheinColorImg = __otlobliSelectedSkuColorImage;
      // Drawer products (jewelry tray p-534350565): the SKU sheet closes at
      // add-time, so retain the rest of the committed variant too.
      if (__otlobliSheinDrawerPath === location.pathname) {
        if (__otlobliSelectedSkuColor) sheinColorSel = __otlobliSelectedSkuColor;
        var kSize = String(__otlobliSelectedSkuPriceKey || '').split('|')[1];
        if (kSize) sheinSizeSel = kSize;
      }
    }
    // The structured store fills missing facts but never replaces a selected icon.
    var sheinStoreV = sheinStoreVariant();
    var sheinSkuCode = '';
    if (sheinStoreV) {
      sheinSkuCode = sheinStoreV.skuCode;
      if (sheinStoreV.color) sheinColorSel = sheinStoreV.color;
      if (sheinStoreV.image && !sheinColorImg) sheinColorImg = sheinStoreV.image;
      if (sheinStoreV.size) {
        sheinSizeSel = sheinStoreV.size;
        sheinSizesAvail = []; sheinSizesUnavail = [];
      }
      // The matched SKU's real salePrice replaces a range-blocked / DOM-missed read.
      if (sheinStoreV.priceUsd > 0) {
        sheinPriceUsd = sheinStoreV.priceUsd;
        sheinPriceSource = 'store-sku';
      }
    }
    // Swan tray p-517537202: one sales attr under a "مقاس" heading whose values are
    // colour names => color === size. Ship once as the colour (it holds the image).
    if (sheinSizeSel && sheinColorSel && sheinSizeSel === sheinColorSel) {
      sheinSizeSel = '';
      sheinSizesAvail = [];
      sheinSizesUnavail = [];
    }
    return {
      title: getTitle(allowGenericTitle),
      priceUsd: sheinPriceUsd,
      priceSource: sheinPriceSource,
      image: getMainImage() || sheinColorImg,
      colorImage: sheinColorImg || '',
      colorImageFound: !!sheinColorImg,
      color: sheinColorSel,
      size: sheinSizeSel,
      quantityOption: sheinQuantityOption,
      skuCode: sheinSkuCode,
      sizesAvailable: sheinSizesAvail,
      sizesUnavailable: sheinSizesUnavail,
      link: otlobliNormalizeSheinUrl(location.href),
      needsCustomPhoto: sheinCustomReq.needsPhoto,
      customPhotoNote: sheinCustomReq.photoNote,
      needsCustomText: sheinCustomReq.needsText,
      customText: '',
      customTextLimit: sheinCustomReq.textLimit || 0,
    };
  }

  function addToCartFlow(colorState, sizeState) {
    if (document.getElementById('otlobli-overlay')) return;
    var quickPayload = null;
    if (IS_SHEIN) {
      __otlobliCartToastGuardUntil = Date.now() + 7000;
      var addBtn = document.getElementById('otlobli-add-btn');
      // Browsing never reopens an exhausted automatic region cascade on each
      // PDP. The customer's explicit Add action is the one safe place to grant
      // a fresh native repair attempt while the purchase gate remains closed.
      if (!ensureSheinSaudiStore(true)) {
        showMessage(addBtn, 'نثبت منطقة الشحن المختارة والدولار... حاول بعد لحظة');
        return;
      }
      var quickAddState = sheinQuickAddSelectionState();
      if (quickAddState) {
        // The picker has its own independent selections.  Using the background
        // state here is what broke Curvy sizes after the first product page.
        colorState = quickAddState.color;
        sizeState = quickAddState.size;
        quickPayload = sheinQuickAddPayload();
        if (!quickPayload) {
          showMessage(addBtn, 'تعذّر قراءة خيار المنتج — حاول مرة ثانية');
          return;
        }
      } else if (sheinOpenSkuDrawer()) {
        return;
      }
      if (colorState && colorState.exists && !colorState.selected) {
        showMessage(addBtn, 'حدد اللون أولاً');
        return;
      }
      if (sizeState && sizeState.exists && !sizeState.selected) {
        if (quickAddState && quickAddState.sizeBox && quickAddState.sizeBox.scrollIntoView) {
          try { quickAddState.sizeBox.scrollIntoView({ block: 'center' }); } catch (e) {}
        } else {
          sheinRevealSizeOptions();
        }
        showMessage(addBtn, 'حدد المقاس أولاً');
        return;
      }
      // Authoritative gate on top of the heuristic above: never add a sized
      // product with no size chosen (quick-add products slipped through before).
      if (sheinSizeUnselected(quickAddState && quickAddState.root)) {
        showMessage(addBtn, 'الرجاء تحديد المقاس أولاً');
        return;
      }
    }
    var payload = quickPayload || captureProductPayload(colorState, sizeState);
    showAddingOverlay(payload);
    clearAddSafetyTimer();
    // Start the guard as soon as the blocking overlay appears. Previously it
    // started only after postMessage(), so a product-specific parsing error
    // before that point could leave the spinner and scroll lock up forever.
    window.__otlobliAddSafetyTimer = setTimeout(function () {
      if (document.getElementById('otlobli-overlay')) failAddFlow();
    }, 5000);

    var attempts = 0;
    var priceWaits = 0;
    // Temu تكون بياناتها مرسومة قبل ظهور زر Otlobli. ثلاث قراءات قصيرة تكفي
    // لأي تحديث متأخر، بدلاً من انتظار خمس ثوانٍ على جهاز ضعيف.
    var maxAttempts = IS_TEMU ? 3 : 10;
    var intervalMs = IS_TEMU ? 150 : 500;
    function isComplete(p, cs) {
      if (IS_TEMU) {
        // إذا اختار الزبون لوناً ننتظر حتى يُلتقط هيرو اللون (300ms بعد النقر)
        // حتى لا تدخل صورة اللون الافتراضي (الأسود) بدل اللون المختار (الأحمر مثلاً).
        var colorPicked = !!(window.__otlobliTemuColor && window.__otlobliTemuColorGid === temuGoodsId());
        // الـswatch يكفي (هو المصدر المضمون) — لا ننتظر الهيرو إن وُجد.
        var colorImgReady = !colorPicked || !!window.__otlobliTemuColorSwatch || !!window.__otlobliTemuColorImg;
        return !!p.title && !!p.image && p.priceUsd > 0 && colorImgReady;
      }
      return !!p.title && !!p.image && p.priceUsd > 0 && (!cs.exists || !!p.color);
    }

    function finalize(p) {
      if (IS_SHEIN) {
        sheinRegionDiag('selected-sku-price-capture', {
          captured: p.priceUsd,
          source: __otlobliSkuPriceSource,
          spaRoute: sheinSpaCaptureRoute(),
          before: __otlobliSelectedSkuPriceBefore,
          priceWaits: priceWaits,
          tracked: __otlobliSelectedSkuPrice,
          trackedKey: __otlobliSelectedSkuPriceKey,
          currentKey: sheinCurrentSelectionKey()
        }, [p.priceUsd, __otlobliSkuPriceSource, __otlobliSelectedSkuPrice,
          __otlobliSelectedSkuPriceKey, sheinCurrentSelectionKey()].join('|'));
      }
      if (!p.title || !p.image || !(p.priceUsd > 0)) {
        clearAddSafetyTimer();
        removeOverlay(0);
        var ab = document.getElementById('otlobli-add-btn');
        if (ab) showMessage(ab, 'تعذّر قراءة بيانات المنتج — حاول مرة ثانية');
        return;
      }
      updateOverlayContent(p, 'جاري إضافة المنتج لسلة otlobli...');
      function postProduct() {
        try {
          if (window.mobileApp && window.mobileApp.postMessage) {
            window.mobileApp.postMessage({ detail: { type: 'addToCart', product: p } });
          }
        } catch (e) {}
      }
      // صورة Temu مأخوذة من عنصر مرسوم فعلاً في الصفحة، فلا نوقف الإضافة على
      // تحميل شبكي ثانٍ لنفس الرابط. هذا كان يضيف حتى 2.5 ثانية بلا فائدة.
      if (IS_TEMU) {
        postProduct();
        return;
      }
      preloadImage(p.image, 2500).then(function (ok) {
        if (!ok) p.image = getMainImage() || p.image;
        postProduct();
      });
    }

    function attempt() {
      try {
        if (quickPayload) {
          finalize(quickPayload);
          return;
        }
        if (IS_SHEIN && sheinSelectedSkuPricePending() && priceWaits++ < 16) {
          updateOverlayContent(payload, 'جاري تثبيت سعر الخيار المختار...');
          setTimeout(attempt, 120);
          return;
        }
        attempts++;
        var exhausted = attempts >= maxAttempts;
        var freshColor = getColorState();
        var freshSize = getSizeState();
        payload = captureProductPayload(freshColor, freshSize, exhausted);
        if (isComplete(payload, freshColor) || exhausted) {
          finalize(payload);
          return;
        }
        updateOverlayContent(payload, 'جاري التأكد من بيانات المنتج... (' + attempts + ')');
        setTimeout(attempt, intervalMs);
      } catch (e) {
        failAddFlow();
      }
    }

    attempt();
  }

  function requestOpenOtlobliCart() {
    try {
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: 'openCart' } });
      }
    } catch (e) {}
  }

  window.addEventListener('messageFromNative', function (event) {
    var detail = event && event.detail;
    if (detail && detail.type === '__resize') {
      window.dispatchEvent(new Event('resize'));
      tick();
      return;
    }
    if (detail && detail.type === '__backTarget') {
      __otlobliBackTarget = detail.target === 'cart' ? 'cart' : 'home';
      if (otlobliScriptEnabled('navigationBack')) ensureBackButton();
      return;
    }
    if (detail && detail.type === 'addToCartAck') {
      clearAddSafetyTimer();
      var overlay = document.getElementById('otlobli-overlay');
      if (overlay) {
        var shownAt = parseInt(overlay.getAttribute('data-shown-at') || '0', 10);
        var elapsed = Date.now() - shownAt;
        var wait = Math.max(0, 550 - elapsed);
        setTimeout(function () {
          markOverlaySuccess();
          removeOverlay(700);
        }, wait);
      }
      return;
    }
    if (detail && detail.type === 'addToCartNack') {
      failAddFlow();
    }
  });

  function showMessage(btn, text, durationMs) {
    ensureShakeStyle();
    var msg = document.getElementById('otlobli-msg');
    if (!msg) {
      msg = document.createElement('div');
      msg.id = 'otlobli-msg';
      msg.style.cssText = 'position:fixed;left:22px;right:22px;bottom:calc(env(safe-area-inset-bottom,0px) + 98px);z-index:2147483647;' +
        'background:rgba(23,29,36,.92);color:#fff;border:0;border-radius:14px;' +
        'padding:10px 14px;font-size:13px;font-weight:700;line-height:1.45;text-align:center;' +
        'box-shadow:0 12px 28px rgba(15,22,32,.24);font-family:Cairo,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;' +
        'backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);animation:otlobli-slide-up .16s ease-out;direction:rtl;';
      document.body.appendChild(msg);
    }
    msg.textContent = text;
    msg.style.display = 'block';
    clearTimeout(window.__otlobliMsgTimer);
    // رسائل التشخيص (تحوي "[" — قوس السبب) تبقى أطول لإتاحة وقت للتصوير.
    var showFor = durationMs || (text.indexOf('[') >= 0 ? 6000 : 2500);
    window.__otlobliMsgTimer = setTimeout(function () { msg.style.display = 'none'; }, showFor);

    if (btn) {
      btn.style.animation = 'none';
      requestAnimationFrame(function () {
        btn.style.animation = 'otlobli-shake 0.4s';
      });
    }
  }

  // مؤشر تحميل خفيف يظهر فوراً عند الضغط على "أضف للسلة" في تيمو، طوال
  // مهلة التحقق (حتى 5 ثوانٍ) - قبل ظهور الطبقة الكاملة أو رسالة الحجب.
  // بلا هذا، الفاصل الصامت كان يبدو كأن التطبيق تجمّد (شكوى مستخدم حقيقية).
  function otlobliShowGateSpinner() {
    ensureOverlayStyle();
    ensureShakeStyle();
    if (document.getElementById('otlobli-gate-spinner')) return;
    var wrap = document.createElement('div');
    wrap.id = 'otlobli-gate-spinner';
    wrap.style.cssText = 'position:fixed;left:22px;right:22px;bottom:calc(env(safe-area-inset-bottom,0px) + 98px);z-index:2147483647;' +
      'background:rgba(23,29,36,.92);color:#fff;border:0;border-radius:14px;' +
      'padding:10px 14px;font-size:13px;font-weight:700;line-height:1.45;text-align:center;box-shadow:0 12px 28px rgba(15,22,32,.24);' +
      'font-family:Cairo,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);animation:otlobli-slide-up .16s ease-out;' +
      'display:flex;align-items:center;justify-content:center;gap:8px;direction:rtl;';
    var spin = document.createElement('span');
    spin.style.cssText = 'width:15px;height:15px;border-radius:50%;border:2px solid rgba(255,255,255,.28);' +
      'border-top-color:#fff;animation:otlobli-spin .8s linear infinite;flex-shrink:0;';
    wrap.appendChild(spin);
    var label = document.createElement('span');
    label.textContent = 'جاري التحقق من المنتج...';
    wrap.appendChild(label);
    document.body.appendChild(wrap);
  }
  function otlobliRemoveGateSpinner() {
    var el = document.getElementById('otlobli-gate-spinner');
    if (el) el.remove();
  }


`
