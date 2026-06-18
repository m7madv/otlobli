export const SHEIN_CAPTURE_SCRIPT = `
(function () {
  // SHEIN's Jordan site defaults to English ("language=joen"); "jo" renders Arabic.
  // Force it once via cookie + a single reload, then it sticks for future loads.
  var hasArabic = /(?:^|; )language=jo(?:;|$)/.test(document.cookie);
  var hasEnglish = /(?:^|; )language=joen(?:;|$)/.test(document.cookie);
  if (!hasArabic || hasEnglish) {
    document.cookie = 'language=jo; path=/; max-age=31536000';
    if (!sessionStorage.getItem('__otlobliArLoaded')) {
      sessionStorage.setItem('__otlobliArLoaded', '1');
      location.reload();
      return;
    }
  }

  if (window.__otlobliInjected) return;
  window.__otlobliInjected = true;

  // Remembers the very first page this webview session landed on (the
  // SHEIN home root), persisted in sessionStorage since this whole script
  // re-runs fresh on every navigation. Used to tell "the user is at the
  // top, nothing to go back to" apart from "the user navigated somewhere
  // and there's a real previous page" - relying on history.length for that
  // is unsafe because the language-redirect reload above (and SHEIN's own
  // Cloudflare verification redirect before that) can leave extra entries
  // in history that aren't real user navigation, so a plain history.back()
  // from the home root can land back on a half-finished verification page
  // instead of just doing nothing.
  if (!sessionStorage.getItem('__otlobliHomePath')) {
    sessionStorage.setItem('__otlobliHomePath', location.pathname);
  }
  function looksLikeHomeRoot() {
    var homePath = (sessionStorage.getItem('__otlobliHomePath') || '').replace(/\\/+$/, '');
    return location.pathname.replace(/\\/+$/, '') === homePath;
  }

  // This WebView (hosted inside a native Dialog) reports window.innerWidth/innerHeight
  // as 0, which breaks "position:fixed; left/right/bottom" math for our overlays
  // (they render collapsed, off-screen). document.documentElement.clientWidth/Height
  // stay correct, so compute pixel positions from those instead of CSS viewport units.
  function viewportSize() {
    return {
      width: document.documentElement.clientWidth || window.innerWidth || 360,
      height: document.documentElement.clientHeight || window.innerHeight || 640,
    };
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

  // SHEIN (like most e-commerce sites) embeds a Schema.org Product block as
  // <script type="application/ld+json">. It's server-rendered into the initial
  // HTML for SEO, so unlike CSS-class-based scraping it doesn't depend on
  // guessing SHEIN's current class names (which break silently whenever they
  // ship a redesign) and it's available even very early in the page load.
  // This is the primary, most reliable source for name/image/price.
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

  // SHEIN's <title> tag briefly (or sometimes permanently, on this site) holds
  // a generic site-wide tagline rather than the product name - "Women's and
  // men's clothing, shop fashion on the site | SHEIN" rather than the actual
  // item. Treat that as "no title yet" so retries keep trying the real
  // sources instead of locking onto the generic tagline on the first attempt.
  function looksGenericTitle(t) {
    if (!t) return true;
    return /شي\\s*إن|shein/i.test(t) && /(تسوق|fashion|shop|الموضة)/i.test(t);
  }

  function getTitle(allowGenericFallback) {
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

  function getPrice() {
    var ld = getProductJsonLd();
    if (ld && ld.offers) {
      var offers = Array.isArray(ld.offers) ? ld.offers[0] : ld.offers;
      var ldPrice = offers && parseFloat(offers.price || offers.lowPrice);
      if (ldPrice > 0) return ldPrice;
    }
    var metaPrice = parseFloat(getMeta('product:price:amount'));
    if (metaPrice > 0) return metaPrice;
    var el = document.querySelector('.product-price .price-content, .product-intro__head-price, [class*="price" i]');
    var text = el ? (el.textContent || '') : '';
    var match = text.match(/[0-9]+\\.?[0-9]*/);
    return match ? parseFloat(match[0]) : 0;
  }

  // Lazy-loaded SHEIN images often keep a tiny placeholder/blank gif in "src"
  // until they scroll into view, with the real photo sitting in a data-* attr.
  // Reading "src" directly grabs the placeholder, so we check those first.
  // ".src"/".currentSrc" are DOM properties the browser already resolves to a
  // full absolute URL. The raw data-* attributes are NOT resolved though -
  // sites very commonly write protocol-relative image URLs ("//img.cdn.com/x.jpg")
  // which work fine rendered inside SHEIN's own page (inherits SHEIN's https:
  // protocol) but can come back broken once handed to a *different* app/page
  // context downstream, so make sure every URL we hand off is fully absolute.
  function normalizeImageUrl(url) {
    if (!url) return '';
    url = url.trim();
    if (url.indexOf('//') === 0) return 'https:' + url;
    if (url.indexOf('/') === 0) return location.origin + url;
    return url;
  }

  function realImgSrc(img) {
    if (!img) return '';
    var candidates = [
      img.getAttribute && img.getAttribute('data-src'),
      img.getAttribute && img.getAttribute('data-original'),
      img.getAttribute && img.getAttribute('data-lazy-src'),
      img.currentSrc,
      img.src,
    ];
    for (var i = 0; i < candidates.length; i++) {
      var v = candidates[i];
      if (v && !/^data:image\\/gif/i.test(v) && !/blank\\.gif|placeholder/i.test(v)) return normalizeImageUrl(v);
    }
    return '';
  }

  // SHEIN product pages often carry promo banners ("install our app", ad
  // strips, etc.) with their own logo/icon <img> - those can be larger or
  // load faster than the actual product photo, so any heuristic that just
  // grabs "an image on the page" risks grabbing the wrong one. Walk up from
  // each candidate image and skip it entirely if an ancestor's class/id
  // hints it's a banner/ad/app-download widget rather than the product
  // gallery.
  // Confirmed via real captured page data: a generic "banner"/"ad"/"popup"
  // blocklist false-positives on the actual product photo carousel itself
  // (SHEIN's gallery wrapper class chain apparently includes a generic
  // "banner"-ish name used for ANY image carousel, not just promo ones) -
  // that single overly-broad match was excluding every real gallery photo.
  // Scope this down to only the exact "install our app" widget signature.
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

  // A real product photo gallery is a cluster of 3+ same-ish SHEIN-hosted
  // <img> siblings sharing a close common ancestor (the swipeable carousel +
  // its thumbnail strip). That structural shape is a far more reliable
  // fingerprint than "biggest image on the page", which can accidentally
  // match a single oversized promo banner instead.
  // Confirmed from a real captured page: SHEIN's gallery photos each sit in
  // their OWN individual <li> wrapper (so grouping by a shared parent/
  // grandparent ELEMENT always produces one-image "groups" of size 1 and
  // never finds anything). What they DO share is the exact same wrapper
  // *className* string (e.g. every photo's direct parent is independently
  // class="crop-image-container"). Group by that className text instead.
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
      var pCls = img.parentElement ? (img.parentElement.className || '').trim() : '';
      if (!pCls) continue;
      if (!byParentClass[pCls]) { byParentClass[pCls] = []; order.push(pCls); }
      byParentClass[pCls].push(img);
    }
    var bestKey = null;
    for (var k = 0; k < order.length; k++) {
      var key = order[k];
      if (byParentClass[key].length >= 3 && (!bestKey || byParentClass[key].length > byParentClass[bestKey].length)) {
        bestKey = key;
      }
    }
    if (!bestKey) return '';
    // Picking items[0] (first in DOM order) is unreliable, and so is picking
    // the largest on-screen rect: this carousel is an infinite-loop slider
    // that prepends a clone of the LAST slide and appends a clone of the
    // FIRST slide so it can wrap around, and every clone renders at the same
    // size as a real slide (confirmed via logcat: 12 slides in the group,
    // but only 10 unique src hashes - N0 duplicates N10, N11 duplicates N1).
    // The clones sit parked off to the sides of the viewport; only the slide
    // actually visible right now has a bounding rect left close to 0. So
    // pick whichever loaded slide's left is closest to 0 instead.
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

  // Last-resort fallback: scan every non-promo SHEIN-hosted <img> on the page
  // and pick the one with the largest rendered/declared area.
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
      var w = imgs[i].naturalWidth || imgs[i].clientWidth || parseInt(imgs[i].getAttribute('width') || '0', 10) || 0;
      var h = imgs[i].naturalHeight || imgs[i].clientHeight || parseInt(imgs[i].getAttribute('height') || '0', 10) || 0;
      var area = w * h;
      if (area >= bestArea) { bestArea = area; best = src; }
    }
    return best;
  }

  function getMainImage() {
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

  function findOptionContainer(keyword, labelWords) {
    var all = document.querySelectorAll('[class*="' + keyword + '" i]');
    for (var i = 0; i < all.length; i++) {
      var el = all[i];
      var opts = el.querySelectorAll('li, button, [class*="item" i]');
      if (opts.length >= 2) return el;
    }
    // Fallback for products where the attribute section's class doesn't
    // literally contain "color"/"size" (SHEIN's internal naming isn't
    // consistent across every product template): find a short text node
    // matching the attribute's visible label (e.g. "اللون") and walk up from
    // there looking for a nearby list of 2+ selectable options.
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
          if (opts2.length >= 2) return scope;
          scope = scope.parentElement;
        }
      }
    }
    return null;
  }

  // Covers every common way a UI marks "this is the chosen option": aria
  // state, a "selected/active/..." class, or an actually-checked radio /
  // checkbox input nested inside the swatch (checked is a live DOM property,
  // not always reflected back onto the HTML attribute, so element.checked
  // has to be read directly rather than via getAttribute).
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

  // Rejects captured text that's clearly not a real color/size value - e.g.
  // a clock-formatted string like "1:52". Confirmed from a user report: a
  // flash-sale countdown timer elsewhere on the page got mistaken for the
  // size value by the generic "nearby short text" fallback heuristics
  // below, so the cart ended up showing a time instead of S/M/L/XL.
  function looksLikeJunkValue(text) {
    if (!text) return true;
    return /^\\d{1,2}:\\d{2}(:\\d{2})?$/.test(text);
  }

  function getSelectedWithin(container) {
    if (!container) return '';
    var nodes = container.querySelectorAll('*');
    for (var j = 0; j < nodes.length; j++) {
      var el = nodes[j];
      if (isSelectedSwatchEl(el)) {
        var label = el.getAttribute('aria-label') || el.getAttribute('title') ||
          el.getAttribute('data-color') || el.getAttribute('data-name') || el.getAttribute('data-value') ||
          el.getAttribute('data-attr-value') || '';
        label = (label || '').trim();
        if (!label) {
          var innerImg = el.tagName === 'IMG' ? el : el.querySelector('img');
          if (innerImg) label = (innerImg.getAttribute('alt') || innerImg.getAttribute('title') || '').trim();
        }
        if (!label) label = (el.textContent || '').trim();
        if (label && label.length < 60 && !looksLikeJunkValue(label)) return label;
      }
    }
    return '';
  }

  // The most reliable, class-name-agnostic way to read "which color is
  // currently selected": almost every shopping site prints it as plain text
  // next to the attribute's own label, e.g. "اللون: Apricot" or "Color: Black"
  // - look for any short text node containing one of those label words and
  // take whatever follows the separator (":" / "(" / "-"). This depends only
  // on the visible wording, not on guessing SHEIN's current CSS classes.
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

  // SHEIN often shows a generic swatch badge ("multicolor" thumbnail, a plain
  // dot, etc.) but prints the actual precise color name as a separate text
  // label next to/above the swatch row (e.g. "اللون: Apricot"), outside the
  // swatch list itself. When that label exists it's far more accurate than
  // anything we can infer from the swatch element, so prefer it.
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

  // The color swatch the user picked is the single most reliable source for a
  // "this is exactly the color they chose" photo - SHEIN renders each swatch
  // as either a small cropped <img> or a CSS background-image of the actual
  // colorway. The big hero photo can lag a tick behind the swatch click (it
  // fades/lazy-loads in), so prefer the swatch's own image over it.
  function getSelectedColorSwatchImage(container) {
    if (!container) return '';
    var nodes = container.querySelectorAll('*');
    for (var j = 0; j < nodes.length; j++) {
      var el = nodes[j];
      if (!isSelectedSwatchEl(el)) continue;
      var img = el.tagName === 'IMG' ? el : el.querySelector('img');
      var fromImg = realImgSrc(img);
      if (fromImg) return fromImg;
      var bg = window.getComputedStyle(el).backgroundImage;
      var match = bg && bg.match(/url\\(["']?(.*?)["']?\\)/);
      if (match && match[1] && !/blank|placeholder/i.test(match[1])) return match[1];
      // The swatch sometimes wraps a small <li>/<button> whose own background
      // is on a CHILD div instead of itself - check one level of children too.
      var children = el.children;
      for (var c = 0; c < (children ? children.length : 0); c++) {
        var childBg = window.getComputedStyle(children[c]).backgroundImage;
        var childMatch = childBg && childBg.match(/url\\(["']?(.*?)["']?\\)/);
        if (childMatch && childMatch[1] && !/blank|placeholder/i.test(childMatch[1])) return childMatch[1];
      }
    }
    return '';
  }

  function getColorState() {
    var container = findOptionContainer('color', ['اللون', 'Color']);
    var selected = getAttrLabelValue(container, ['اللون', 'Color', 'color']) ||
      getColorHeadingLabel(container) || getSelectedWithin(container);
    return { exists: !!container, selected: selected, image: getSelectedColorSwatchImage(container) };
  }

  // Walks every option inside the size container and splits it into
  // available vs unavailable based on the common ways sites mark a sold-out
  // option: aria-disabled, or a class hinting "disabled/soldout/out-of-stock".
  // Heuristic (SHEIN's exact class names aren't guaranteed), but degrades
  // safely - worst case an option lands in "available" when unsure.
  function getSizeOptions(container) {
    var available = [];
    var unavailable = [];
    if (!container) return { available: available, unavailable: unavailable };
    var opts = container.querySelectorAll('li, button, [class*="item" i]');
    for (var i = 0; i < opts.length; i++) {
      var el = opts[i];
      var label = (el.getAttribute('aria-label') || el.getAttribute('title') || el.textContent || '').trim();
      if (!label || label.length > 12 || looksLikeJunkValue(label)) continue;
      var cls = ' ' + (el.className || '') + ' ';
      var isDisabled = el.getAttribute('aria-disabled') === 'true' ||
        /\\s(disable|disabled|soldout|sold-out|out-of-stock|unavailable)\\s/i.test(cls);
      var bucket = isDisabled ? unavailable : available;
      if (bucket.indexOf(label) === -1) bucket.push(label);
    }
    return { available: available, unavailable: unavailable };
  }

  function getSizeState() {
    var container = findOptionContainer('size', ['المقاس', 'Size']);
    var opts = getSizeOptions(container);
    return {
      exists: !!container,
      selected: getSelectedWithin(container),
      available: opts.available,
      unavailable: opts.unavailable,
    };
  }

  function looksLikeProductPage() {
    // SHEIN product detail pages always have a "-p-<id>" segment in the URL
    // (e.g. /ar/some-name-p-12345678-cat-1727.html). The home/category/deals
    // pages don't, so the URL is the reliable PDP signal on its own.
    // IMPORTANT: this used to also require title/price/image to all be
    // truthy before counting as a PDP - but that conflated "is this a
    // product page" with "did our scraping succeed". Any single field
    // failing (e.g. price selector not matching) made the button silently
    // treat a real product page as "not a product page" and just open the
    // (empty) cart instead of attempting to add anything - a totally silent
    // dead end with no error. Now we only gate on the URL, and let
    // addToCartFlow run regardless; its diagnostics chips show exactly
    // which field(s) failed instead of hiding the failure entirely.
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
    overlay.style.cssText = 'position:fixed;left:0;top:0;width:' + vp.width + 'px;height:' + vp.height + 'px;' +
      'background:rgba(10,20,16,.55);z-index:2147483647;display:flex;align-items:center;justify-content:center;';
    overlay.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });
    overlay.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); }, true);

    var card = document.createElement('div');
    card.style.cssText = 'background:#fff;border-radius:16px;padding:20px;width:min(78vw,290px);' +
      'display:flex;flex-direction:column;align-items:center;gap:10px;animation:otlobli-pop .22s ease-out;' +
      'box-shadow:0 14px 32px rgba(0,0,0,.32);';

    var thumbWrap = document.createElement('div');
    thumbWrap.style.cssText = 'width:84px;height:84px;border-radius:12px;overflow:hidden;background:#f2f4f6;' +
      'border:1px solid #e6e8ea;position:relative;';
    var thumb = document.createElement('img');
    thumb.id = 'otlobli-overlay-thumb';
    thumb.style.cssText = 'width:100%;height:100%;object-fit:cover;display:block;';
    thumbWrap.appendChild(thumb);
    var spinner = document.createElement('div');
    spinner.id = 'otlobli-overlay-spinner';
    spinner.style.cssText = 'position:absolute;inset:-3px;border-radius:14px;border:3px solid rgba(0,105,72,.2);' +
      'border-top-color:#006948;animation:otlobli-spin .8s linear infinite;';
    thumbWrap.appendChild(spinner);

    var title = document.createElement('div');
    title.id = 'otlobli-overlay-title';
    title.style.cssText = 'font-size:13px;font-weight:700;color:#191c1e;text-align:center;direction:rtl;line-height:1.4;';

    card.appendChild(thumbWrap);
    card.appendChild(title);

    var meta = document.createElement('div');
    meta.id = 'otlobli-overlay-meta';
    meta.style.cssText = 'font-size:12px;color:#3d4a42;direction:rtl;';
    card.appendChild(meta);

    var status = document.createElement('div');
    status.id = 'otlobli-overlay-status';
    status.style.cssText = 'font-size:12px;color:#006948;font-weight:700;text-align:center;direction:rtl;margin-top:4px;';
    card.appendChild(status);

    // Temporary visible diagnostics: shows exactly which fields were actually
    // found vs missing, so failures can be screenshotted and fixed from real
    // data instead of guessing blind at SHEIN's markup.
    var diag = document.createElement('div');
    diag.id = 'otlobli-overlay-diag';
    diag.style.cssText = 'display:flex;flex-wrap:wrap;gap:5px;justify-content:center;margin-top:2px;';
    card.appendChild(diag);

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

    var diag = document.getElementById('otlobli-overlay-diag');
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
    if (status) status.textContent = '✓ تمت الإضافة لسلة otlobli';
    var spinner = document.getElementById('otlobli-overlay-spinner');
    if (spinner) {
      spinner.style.animation = 'none';
      spinner.style.borderColor = '#1aab6f';
    }
  }

  function removeOverlay(delay) {
    setTimeout(function () {
      var overlay = document.getElementById('otlobli-overlay');
      if (overlay) {
        overlay.style.animation = 'otlobli-fade-out .25s ease-in forwards';
        setTimeout(function () { overlay.remove(); }, 250);
      }
      document.body.style.overflow = '';
    }, delay || 0);
  }

  function captureProductPayload(colorState, sizeState, allowGenericTitle) {
    return {
      title: getTitle(allowGenericTitle),
      priceUsd: getPrice(),
      // Main product photo - always the gallery/hero image, never swapped
      // for the (much smaller) color swatch crop. The swatch travels
      // separately as colorImage so the app can show both.
      image: getMainImage(),
      colorImage: colorState.image || '',
      colorImageFound: !!colorState.image,
      color: colorState.selected,
      size: sizeState.selected,
      sizesAvailable: sizeState.available || [],
      sizesUnavailable: sizeState.unavailable || [],
      link: location.href,
    };
  }

  // Dumps real ground-truth data about the current page to the JS console -
  // Android WebView forwards console.log to logcat (tag "chromium"), so this
  // can be read directly with "adb logcat" instead of guessing blind at
  // SHEIN's markup or depending on a perfectly-timed screenshot.
  // logcat truncates long single log entries hard, so log many SHORT lines
  // instead of one big JSON blob - and log what our OWN extraction functions
  // actually return right now, not just raw page data, so the real bug is
  // visible directly instead of needing to re-derive it by hand.
  function debugSnapshot(colorState, sizeState) {
    try {
      console.log('OTLOBLI_DBG A url=' + location.href.slice(0, 140));
      console.log('OTLOBLI_DBG B mainImage()=' + (getMainImage() || 'EMPTY').slice(0, 160));
      console.log('OTLOBLI_DBG C galleryImage()=' + (getGalleryImage() || 'EMPTY').slice(0, 160));

      (function debugGalleryGroup() {
        var imgs2 = document.querySelectorAll('img[src*="ltwebstatic"], img[src*="img.shein"], img[data-src*="ltwebstatic"], img[data-src*="img.shein"]');
        var byCls = {};
        var ord = [];
        for (var i2 = 0; i2 < imgs2.length; i2++) {
          var im = imgs2[i2];
          if (isInPromoWidget(im)) continue;
          var s2 = realImgSrc(im);
          if (!s2) continue;
          var pc = im.parentElement ? (im.parentElement.className || '').trim() : '';
          if (!pc) continue;
          if (!byCls[pc]) { byCls[pc] = []; ord.push(pc); }
          byCls[pc].push(im);
        }
        var bk = null;
        for (var k2 = 0; k2 < ord.length; k2++) {
          if (byCls[ord[k2]].length >= 3 && (!bk || byCls[ord[k2]].length > byCls[bk].length)) bk = ord[k2];
        }
        console.log('OTLOBLI_DBG M bestGroupKey=[' + (bk || 'NONE') + '] size=' + (bk ? byCls[bk].length : 0));
        if (bk) {
          var grp = byCls[bk];
          for (var g2 = 0; g2 < grp.length && g2 < 12; g2++) {
            var r = grp[g2].getBoundingClientRect();
            console.log('OTLOBLI_DBG N' + g2 + ' w=' + Math.round(r.width) + ' h=' + Math.round(r.height) + ' top=' + Math.round(r.top) + ' left=' + Math.round(r.left) + ' src=' + (realImgSrc(grp[g2]) || '').slice(-60));
          }
        }
      })();
      console.log('OTLOBLI_DBG D largestImage()=' + (getLargestSheinImage() || 'EMPTY').slice(0, 160));
      console.log('OTLOBLI_DBG E ogImage=' + (getMeta('og:image') || 'EMPTY').slice(0, 140));
      console.log('OTLOBLI_DBG F capturedColor=[' + colorState.selected + '] capturedSize=[' + sizeState.selected + '] colorImg=' + (colorState.image || 'EMPTY').slice(0, 140));

      var colorContainer = findOptionContainer('color', ['اللون', 'Color']);
      var sizeContainer = findOptionContainer('size', ['المقاس', 'Size']);
      console.log('OTLOBLI_DBG H colorContainerFound=' + !!colorContainer + ' cls=[' + (colorContainer ? colorContainer.className.slice(0, 80) : '') + ']');
      console.log('OTLOBLI_DBG I sizeContainerFound=' + !!sizeContainer + ' cls=[' + (sizeContainer ? sizeContainer.className.slice(0, 80) : '') + ']');
      if (colorContainer) console.log('OTLOBLI_DBG J colorHTML=' + colorContainer.outerHTML.slice(0, 150));
      if (sizeContainer) console.log('OTLOBLI_DBG K sizeHTML=' + sizeContainer.outerHTML.slice(0, 150));

      var byClassColor = document.querySelectorAll('[class*="color" i]');
      console.log('OTLOBLI_DBG L byClassColorCount=' + byClassColor.length);
      for (var bc = 0; bc < byClassColor.length && bc < 5; bc++) {
        console.log('OTLOBLI_DBG L' + bc + ' cls=[' + (byClassColor[bc].className || '').slice(0, 70) + '] kids=' + byClassColor[bc].children.length);
      }

      var imgs = document.querySelectorAll('img[src*="ltwebstatic"], img[src*="img.shein"], img[data-src*="ltwebstatic"], img[data-src*="img.shein"]');
      console.log('OTLOBLI_DBG G imgCount=' + imgs.length);
      for (var i = 0; i < imgs.length && i < 10; i++) {
        var img = imgs[i];
        var pCls = img.parentElement ? (img.parentElement.className || '') : '';
        console.log('OTLOBLI_DBG IMG' + i + ' promo=' + isInPromoWidget(img) + ' parentCls=[' + pCls.slice(0, 50) + '] realSrc=' + (realImgSrc(img) || 'EMPTY').slice(0, 120));
      }
    } catch (e) {
      console.log('OTLOBLI_DBG ERROR ' + e);
    }
  }

  // Shared by both add-to-cart entry points (our floating button, and
  // intercepting SHEIN's own "Add to bag" button): show the freeze/loading
  // modal, then RETRY scraping the page for up to ~5s. SHEIN is a heavy SPA -
  // on first tap the hero photo/title can still be mid-render, so a single
  // immediate read often comes back empty. Polling gives the page time to
  // finish rendering before we give up on any field, and the overlay updates
  // live so the user can see it's actively working, not stuck.
  function addToCartFlow(colorState, sizeState) {
    if (document.getElementById('otlobli-overlay')) return;
    debugSnapshot(colorState, sizeState);
    var payload = captureProductPayload(colorState, sizeState);
    showAddingOverlay(payload);

    var attempts = 0;
    var maxAttempts = 10;
    var intervalMs = 500;

    function isComplete(p, cs) {
      return !!p.title && !!p.image && (!cs.exists || !!p.color);
    }

    function finalize(p) {
      updateOverlayContent(p, 'جاري إضافة المنتج لسلة otlobli...');
      preloadImage(p.image, 2500).then(function (ok) {
        if (!ok) p.image = getMainImage() || p.image;
        try {
          if (window.mobileApp && window.mobileApp.postMessage) {
            window.mobileApp.postMessage({ detail: { type: 'addToCart', product: p } });
          }
        } catch (e) {}
        // Safety net: if the native side never acks (e.g. app backgrounded),
        // don't leave the user stuck behind a frozen overlay forever.
        setTimeout(function () {
          if (document.getElementById('otlobli-overlay')) removeOverlay(0);
        }, 4000);
      });
    }

    function attempt() {
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
      ensureBackButton();
      return;
    }
    if (detail && detail.type === 'addToCartAck') {
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
    }
  });

  function showMessage(btn, text) {
    var msg = document.getElementById('otlobli-msg');
    if (!msg) {
      var vp = viewportSize();
      msg = document.createElement('div');
      msg.id = 'otlobli-msg';
      msg.style.cssText = 'position:fixed;left:16px;top:' + (vp.height - 122) + 'px;width:' + (vp.width - 32) + 'px;z-index:2147483647;' +
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
      '40%,60%{transform:translateX(4px)}}' +
      '@keyframes otlobli-slide-up{from{transform:translateY(120%);opacity:0}to{transform:translateY(0);opacity:1}}' +
      '@keyframes otlobli-pop2{from{transform:scale(.5);opacity:0}to{transform:scale(1);opacity:1}}' +
      '@keyframes otlobli-badge-pop{0%{transform:scale(0)}60%{transform:scale(1.35)}100%{transform:scale(1)}}';
    document.head.appendChild(style);
  }

  // Covers the whole page with an opaque, untappable overlay from the very
  // first tick() until SHEIN's UI has had a few polling cycles to actually
  // get hidden/blocked. Without this, there's a real (if short) window
  // right after a page loads where SHEIN's own buttons are rendered but our
  // hide/block pass hasn't reached them yet - confirmed by a user managing
  // to add a product to SHEIN's real cart from that exact window. Better to
  // make the user wait a beat than ever expose anything unprocessed.
  var __otlobliLoadingDone = false;
  function ensureLoadingOverlay() {
    if (__otlobliLoadingDone || document.getElementById('otlobli-loading')) return;
    ensureOverlayStyle();
    var vp = viewportSize();
    var overlay = document.createElement('div');
    overlay.id = 'otlobli-loading';
    overlay.style.cssText = 'position:fixed;left:0;top:0;width:' + vp.width + 'px;height:' + vp.height + 'px;' +
      'background:#ffffff;z-index:2147483647;display:flex;align-items:center;justify-content:center;';
    overlay.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });
    overlay.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); }, true);
    var spinner = document.createElement('div');
    spinner.style.cssText = 'width:38px;height:38px;border-radius:50%;border:4px solid #d8efe4;' +
      'border-top-color:#006948;animation:otlobli-spin .8s linear infinite;';
    overlay.appendChild(spinner);
    document.body.appendChild(overlay);
    window.setTimeout(function () {
      __otlobliLoadingDone = true;
      var el = document.getElementById('otlobli-loading');
      if (el) el.remove();
    }, 1100);
  }

  // Dedicated "add to cart" action. Used to share a corner with a floating
  // cart-icon button, but that button was dropped entirely - the bottom nav
  // (see ensureOtlobliNav) already has its own "السلة" tab that does the
  // exact same thing, so the floating icon was pure redundancy. Placed
  // bottom-right (thumb reach, doesn't cover the header or SHEIN's own
  // price/title block), and only visible while looking at an actual
  // product page.
  function ensureAddToCartButton() {
    var btn = document.getElementById('otlobli-add-btn');
    if (!btn) {
      ensureShakeStyle();
      btn = document.createElement('button');
      btn.id = 'otlobli-add-btn';
      btn.setAttribute('aria-label', 'إضافة إلى سلة otlobli');
      // Cleared above ensureOtlobliNav's bar (~64px + safe-area) instead of
      // sitting flush with the screen edge, so the two never overlap.
      btn.style.cssText = 'position:fixed;right:14px;bottom:calc(78px + env(safe-area-inset-bottom, 0px));' +
        'min-width:128px;height:48px;z-index:2147483647;' +
        'background:#006948;color:#fff;border:none;border-radius:24px;display:none;align-items:center;' +
        'justify-content:center;gap:6px;font-size:14px;font-weight:800;line-height:1;direction:rtl;' +
        'box-shadow:0 6px 16px rgba(0,0,0,.32);padding:0 18px;animation:otlobli-pop2 .25s ease-out;';
      btn.textContent = '🛍 أضف للسلة';
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
        addToCartFlow(colorState, sizeState);
      }, true);
      document.body.appendChild(btn);
    }
    btn.style.display = looksLikeProductPage() ? 'flex' : 'none';
  }

  // otlobli's own bottom navigation bar, drawn as part of this page instead
  // of relying on a separately-sized native layer underneath to line up with
  // it pixel-for-pixel (that cross-layer alignment is what went wrong on
  // iOS - the webview and otlobli's React nav drifted out of sync and left a
  // black gap where the nav should be). Since this bar lives inside the same
  // webview as everything else here, env(safe-area-inset-bottom) handles the
  // home-indicator inset correctly with zero native-side math.
  // Plain inline-SVG outline icons instead of emoji - emoji glyphs render
  // inconsistently across platforms/fonts, while these always look the same
  // regardless of what page/font context they're injected into.
  var OTLOBLI_NAV_ICONS = {
    home: '<path d="M4 11.5 12 4l8 7.5"/><path d="M6 10v9h12v-9"/><path d="M10 19v-5h4v5"/>',
    orders: '<rect x="4" y="7" width="16" height="13" rx="1.3"/><path d="M4 7l8-4 8 4"/><path d="M12 11v9"/>',
    cart: '<circle cx="9" cy="20" r="1.3"/><circle cx="18" cy="20" r="1.3"/>' +
      '<path d="M3 4h2l2.2 11.5a2 2 0 0 0 2 1.6h8.6a2 2 0 0 0 2-1.6L21 8H6"/>',
    profile: '<circle cx="12" cy="8" r="3.6"/><path d="M5 20c0-3.8 3.1-6.4 7-6.4s7 2.6 7 6.4"/>',
  };

  function ensureOtlobliNav() {
    if (document.getElementById('otlobli-nav')) return;
    ensureShakeStyle();
    var nav = document.createElement('div');
    nav.id = 'otlobli-nav';
    // Max z-index (tied with the other otlobli overlays, and appended last
    // so it wins paint order among ties) - guarantees this sits above any
    // bottom bar SHEIN's own page might render now that the webview is
    // full-screen, rather than hoping ours happens to be on top.
    // Matches otlobli's real .bottom-nav as closely as a separate webview
    // can: same colors (--primary #006948 / --muted #3d4a42), same ~74px
    // min-height, same 4px top indicator bar on the active tab, and the
    // same 440px max-width/centering (matters on tablets - on a phone-width
    // screen this is identical to full width).
    nav.style.cssText = 'position:fixed;left:50%;bottom:0;transform:translateX(-50%);' +
      'width:min(100%, 440px);z-index:2147483647;display:flex;' +
      'min-height:74px;background:rgba(255,255,255,.97);border-top:1px solid #bccac0;' +
      'padding-bottom:env(safe-area-inset-bottom, 0px);';
    var items = [
      { label: 'الرئيسية', icon: OTLOBLI_NAV_ICONS.home, type: '' },
      { label: 'طلباتي', icon: OTLOBLI_NAV_ICONS.orders, type: 'openOrders' },
      { label: 'السلة', icon: OTLOBLI_NAV_ICONS.cart, type: 'openCart' },
      { label: 'حسابي', icon: OTLOBLI_NAV_ICONS.profile, type: 'openProfile' },
    ];
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var tab = document.createElement('button');
      var isActiveTab = !item.type;
      tab.style.cssText = 'position:relative;flex:1;border:0;background:transparent;display:flex;' +
        'flex-direction:column;align-items:center;justify-content:center;gap:4px;padding:6px 0;' +
        'font-size:0.76rem;font-weight:700;font-family:inherit;color:' + (isActiveTab ? '#006948' : '#3d4a42') + ';';
      if (isActiveTab) {
        var indicator = document.createElement('span');
        indicator.style.cssText = 'position:absolute;top:0;width:32px;height:4px;border-radius:999px;background:#006948;';
        tab.appendChild(indicator);
      }
      var iconLabelWrap = document.createElement('span');
      iconLabelWrap.style.cssText = 'display:flex;flex-direction:column;align-items:center;gap:4px;';
      iconLabelWrap.innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
        'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + item.icon + '</svg>' +
        '<span>' + item.label + '</span>';
      tab.appendChild(iconLabelWrap);
      if (item.type) {
        (function (messageType) {
          tab.addEventListener('click', function (event) {
            event.preventDefault();
            event.stopPropagation();
            try {
              if (window.mobileApp && window.mobileApp.postMessage) {
                window.mobileApp.postMessage({ detail: { type: messageType } });
              }
            } catch (e) {}
          }, true);
        })(item.type);
      }
      nav.appendChild(tab);
    }
    document.body.appendChild(nav);
  }

  // Lets the user always get back out of wherever they navigated to inside
  // SHEIN. Two modes depending on how this view was entered:
  // - "cart": this webview was opened from a cart item tap; tapping back
  //   asks the app to switch back to the otlobli cart screen.
  // - "home" (default): normal browsing from the home tab; tapping back just
  //   walks the webview's own in-page history, same as a browser back button.
  var __otlobliBackTarget = 'home';

  function ensureBackButton() {
    var btn = document.getElementById('otlobli-back-btn');
    if (!btn) {
      ensureShakeStyle();
      btn = document.createElement('button');
      btn.id = 'otlobli-back-btn';
      btn.setAttribute('aria-label', 'رجوع');
      // Top-right corner, mirroring the cart button's top-left spot, so the
      // two don't crowd into the same corner.
      btn.style.cssText = 'position:fixed;right:10px;top:12px;width:42px;height:42px;z-index:2147483647;' +
        'background:rgba(20,24,22,.6);color:#fff;border:none;border-radius:11px;display:none;' +
        'align-items:center;justify-content:center;font-size:20px;line-height:1;' +
        'box-shadow:0 4px 12px rgba(0,0,0,.32);animation:otlobli-pop2 .25s ease-out;';
      // Right-pointing arrow reads as "back" in this RTL UI, matching the
      // app's own header back button convention (arrow_forward icon).
      btn.innerHTML = '&#8594;';
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
        // Only ever go back while we're actually somewhere other than the
        // SHEIN home root - history.length isn't a safe proxy for that (the
        // language-redirect reload and SHEIN's own verification redirect
        // both add entries that were never real user navigation, so a back()
        // from the root could land back on a half-finished verification
        // page instead of doing nothing).
        if (!looksLikeHomeRoot()) history.back();
      }, true);
      document.body.appendChild(btn);
    }
    var shouldShow = __otlobliBackTarget === 'cart' || !looksLikeHomeRoot();
    btn.style.display = shouldShow ? 'flex' : 'none';
  }

  function isAddToCartButton(el) {
    var text = (el.textContent || '').trim();
    if (!text || text.length > 60) return false;
    // The Arabic-only regex below is what was actually missing - SHEIN's
    // Jordan site (forced to Arabic above) labels this "أضف إلى عربة
    // التسوق"/"أضف للسلة", never the English text this previously only
    // matched, so the click interceptor never caught it and SHEIN's real
    // add-to-cart fired untouched (confirmed by a user screenshot showing
    // SHEIN's own "أضف إلى عربة التسوق بنجاح" success bar).
    return /add to (bag|cart)/i.test(text) || /أضف.*(عربة|السلة|الحقيبة|التسوق)/.test(text);
  }

  // SHEIN's "quick add" popup (opened from a listing card, without ever
  // visiting the real product page) doesn't necessarily reuse the same
  // wording as the real product page's button - a user confirmed the exact
  // isAddToCartButton text match above still let one through. This is a
  // deliberately looser net: ANY short button-ish text while we're not on a
  // real product page that even loosely reads like a submit/confirm/add
  // action gets caught too, since the consequence of a false positive here
  // (blocking some unrelated short label) is far cheaper than letting a
  // real add-to-SHEIN's-cart action slip through.
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

  // Blocks wishlist/favorite anywhere it shows up - header, product page,
  // or inside SHEIN's own quick-add bottom sheet (the heart icon sitting
  // right next to its add-to-cart button). Matched on text/class/aria-label
  // rather than position, so it's caught no matter which of those places it
  // appears in, instead of needing a separate point-probe per location.
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

  document.addEventListener('click', function (event) {
    var el = event.target;
    var depth = 0;
    while (el && depth < 6) {
      if (el.id && el.id.indexOf('otlobli') === 0) return;
      if (el.getAttribute && el.getAttribute('data-otlobli-blocked') === '1') {
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
        event.preventDefault();
        event.stopPropagation();
        showMessage(null, 'افتح المنتج كاملاً أولاً لإضافته إلى السلة');
        return;
      }
      if (isAddToCartButton(el)) {
        // Block SHEIN's own click handler from ever firing - otherwise it adds
        // the item to SHEIN's real bag and shows its own "added to bag" toast
        // alongside ours, which is exactly the native-cart usage we're trying
        // to prevent entirely.
        event.preventDefault();
        event.stopPropagation();
        if (!looksLikeProductPage()) {
          // This is SHEIN's "quick add" button on a listing card, which opens
          // a stripped-down popup instead of the real product page - that
          // popup's markup doesn't match what our scraping functions expect
          // (built around the full product page), so capture from it is
          // unreliable. Require opening the real product page instead, every
          // time, so capture always runs against the same known layout.
          showMessage(null, 'افتح المنتج كاملاً أولاً لإضافته إلى السلة');
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

  // Hide every SHEIN header icon except search (wishlist heart, inbox, hamburger
  // menu, etc.) - same point-probing + "walk up to the nearest small clickable
  // element" pattern as hideStrayFixedBottomBars below, deliberately avoiding a
  // blind document-wide querySelectorAll('a,button') like the earlier cart-icon
  // lockout used: that one matched an oversized wrapping element once and tore
  // a transparent hole in SHEIN's header. Capping at icon-sized elements (and
  // skipping anything that contains/looks like the search input) keeps this
  // safe even if SHEIN's markup doesn't match our assumptions.
  // Point-probing (hideExtraHeaderIcons below) can miss a small icon
  // outright if it just happens to sit between two sample points - a user
  // reported the wishlist heart and hamburger menu sometimes taking
  // minutes to disappear, purely down to probe-grid luck. This is a direct,
  // grid-independent pass: query for the hamburger/wishlist by name instead
  // of by position, so it gets caught on literally the first tick
  // regardless of exactly where it sits. The hamburger is a real risk
  // beyond clutter too - it can lead to SHEIN's own account/region/currency
  // settings, and a currency switch there would silently break price
  // capture (which assumes USD).
  function hideKnownHeaderIconsByHint() {
    var candidates = document.querySelectorAll(
      '[class*="menu" i], [aria-label*="menu" i], [class*="hamburger" i], [class*="nav-toggle" i], ' +
      '[class*="wishlist" i], [class*="favorite" i], [aria-label*="favorite" i], [aria-label*="wishlist" i]'
    );
    for (var i = 0; i < candidates.length; i++) {
      var el = candidates[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      var rect = el.getBoundingClientRect();
      if (rect.top < -10 || rect.top > 120) continue;
      if (rect.width <= 0 || rect.width > 64 || rect.height <= 0 || rect.height > 64) continue;
      el.setAttribute('data-otlobli-blocked', '1');
      el.style.setProperty('visibility', 'hidden', 'important');
      el.style.setProperty('pointer-events', 'none', 'important');
    }
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
            var hasInput = !!el.querySelector('input');
            var hint = ((el.className || '') + ' ' + (el.getAttribute('aria-label') || '') + ' ' + (el.textContent || '')).toLowerCase();
            var isSearchish = hasInput || /search|بحث|camera|كاميرا/.test(hint);
            if (elIconSized && !isSearchish) {
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

  // Now that the webview is full-screen (see browseShein in App.tsx),
  // SHEIN's own page can render its own persistent bottom tab bar AND its
  // sticky product-page action bar (wishlist + add-to-cart), both of which
  // used to be clipped off-screen in the old height-constrained webview -
  // a user screenshot showed the action bar peeking out from behind
  // otlobli's own floating buttons. Find and remove any of these outright
  // instead of just hoping otlobli's own overlays paint above them.
  function hideForeignBottomNav() {
    var vp = viewportSize();
    var candidates = document.querySelectorAll(
      'nav, footer, [class*="tab-bar" i], [class*="tabbar" i], [class*="bottom-nav" i], ' +
      '[class*="footer-nav" i], [class*="nav-bar" i], [class*="navbar" i], ' +
      '[class*="add-to-bag" i], [class*="addtobag" i], [class*="addtocart" i], ' +
      '[class*="action-bar" i], [class*="fixed-bottom" i], [class*="sticky-bottom" i], ' +
      '[class*="bottom-bar" i], [class*="buy-bar" i]'
    );
    for (var i = 0; i < candidates.length; i++) {
      var el = candidates[i];
      if (el.id && el.id.indexOf('otlobli') === 0) continue;
      var style = window.getComputedStyle(el);
      if (style.position !== 'fixed' && style.position !== 'sticky') continue;
      var rect = el.getBoundingClientRect();
      if (rect.width < vp.width * 0.5) continue;
      if (rect.height <= 0 || rect.height > 180) continue;
      if (rect.bottom < vp.height - 200) continue;
      el.style.setProperty('display', 'none', 'important');
    }
  }

  // SHEIN pins its own promo bars (e.g. "free shipping over $X") to the bottom
  // of its page with position:fixed/sticky. Those were designed to sit above
  // SHEIN's own bottom tab bar, but our webview's viewport ends right where
  // otlobli's bottom nav begins (we don't show SHEIN's tab bar at all), so
  // SHEIN's banner now renders flush against otlobli's nav and looks like a
  // glitchy stacked bar. Hide any such stray fixed/sticky bottom element that
  // isn't one of ours.
  function hideStrayFixedBottomBars() {
    var vp = viewportSize();
    var probeY = vp.height - 3;
    var probeXs = [Math.round(vp.width * 0.15), Math.round(vp.width * 0.5), Math.round(vp.width * 0.85)];
    for (var p = 0; p < probeXs.length; p++) {
      var el = document.elementFromPoint(probeXs[p], probeY);
      var depth = 0;
      while (el && el !== document.body && el !== document.documentElement && depth < 10) {
        if (el.id && el.id.indexOf('otlobli') === 0) break;
        var style = window.getComputedStyle(el);
        if (style.position === 'fixed' || style.position === 'sticky') {
          var rect = el.getBoundingClientRect();
          if (rect.height > 0 && rect.height < 160 && rect.bottom >= vp.height - 6) {
            el.style.setProperty('display', 'none', 'important');
          }
          break;
        }
        el = el.parentElement;
        depth++;
      }
    }
  }

  // shein.com's own anti-bot system occasionally serves a branded "GSRM
  // Security"/"server's gone missing" block page instead of the real page -
  // observed tied to the session's cookies (clearing them and reloading
  // fixes it immediately). Detected here and handled by the app, since only
  // native code can clear HttpOnly cookies. Reset on navigation so a block
  // on one route doesn't suppress detecting it again on the next.
  var sheinBlockReported = false;
  function checkForSheinSecurityBlock() {
    if (sheinBlockReported) return;
    var bodyText = document.body && document.body.innerText;
    if (bodyText && bodyText.length < 2000 && /GSRM|gone missing/i.test(bodyText)) {
      sheinBlockReported = true;
      if (window.mobileApp && window.mobileApp.postMessage) {
        window.mobileApp.postMessage({ detail: { type: 'sheinBlocked' } });
      }
    }
  }

  function tick() {
    checkForSheinSecurityBlock();
    ensureLoadingOverlay();
    blockCartNavigation();
    ensureAddToCartButton();
    ensureBackButton();
    ensureOtlobliNav();
    hideKnownHeaderIconsByHint();
    hideExtraHeaderIcons();
    hideSheinCartIcons();
    hideForeignBottomNav();
    hideStrayFixedBottomBars();
  }

  // Kept tight on purpose - every visible millisecond here is a window where
  // a SHEIN button/icon that's supposed to be hidden or blocked is instead
  // tappable, which is exactly the "nothing should ever be reachable, not
  // even briefly" requirement this whole hide/block system exists for.
  var tickScheduled = false;
  function scheduleTick() {
    sheinBlockReported = false;
    if (tickScheduled) return;
    tickScheduled = true;
    setTimeout(function () {
      tickScheduled = false;
      tick();
    }, 80);
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
  observer.observe(document.body, { childList: true, subtree: true });

  setInterval(tick, 300);
  // hideKnownHeaderIconsByHint specifically needs to win what looks like an
  // ongoing fight against SHEIN periodically re-rendering its own header (a
  // user found the hamburger/wishlist icons could stay reachable for
  // several minutes on the home page even though the same code hid them
  // instantly elsewhere) - run it on its own much tighter interval so any
  // freshly re-created icon gets caught within ~120ms instead of waiting
  // for the next general tick.
  setInterval(hideKnownHeaderIconsByHint, 120);
  tick();
})();
`
