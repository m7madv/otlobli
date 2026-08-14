// Lightweight first-paint guard; the generated capture script owns the full
// proven Otlobli blocker and product capture after document-start.
(() => {
  'use strict'

  const viewport = () => ({ width: window.innerWidth || 1, height: window.innerHeight || 1 })
  const textOf = (node) => String(node?.textContent || '').replace(/\s+/g, ' ').trim()
  const isProductRoute = () =>
    /\/goods\.html$/i.test(window.location.pathname) ||
    /(?:^|-)g-\d+\.html$/i.test(window.location.pathname) ||
    /[?&]goods_id=\d+/i.test(window.location.search)
  // The real SKU picker is also a large fixed dialog and repeats the PDP's
  // discount copy.  A discount word alone must never turn that option form
  // into a prize-wheel popup.
  const isProductOptionDialog = (node) => {
    if (!isProductRoute() || !node?.querySelectorAll) return false
    const dialog = node.matches?.('[role="dialog"]')
      ? node
      : node.closest?.('[role="dialog"]')
    if (!dialog || dialog.querySelectorAll('[role="radio"]').length < 2) return false
    return !!dialog.querySelector('[class*="sku" i],[class*="spec" i]')
  }
  const hide = (node) => {
    if (!node || node === document.body || node === document.documentElement) return
    node.dataset.otlobliGeckoHidden = '1'
    node.style.setProperty('display', 'none', 'important')
    node.style.setProperty('visibility', 'hidden', 'important')
    node.style.setProperty('pointer-events', 'none', 'important')
  }

  const style = document.createElement('style')
  style.id = 'otlobli-temu-gecko-guard'
  style.textContent = `
    html,body{max-width:100vw!important;overflow-x:hidden!important;scroll-padding-bottom:20px!important}
    [aria-label*="cart" i],[aria-label*="basket" i],[aria-label*="shopping bag" i],
    [aria-label*="account" i],[aria-label*="profile" i],[aria-label*="sign in" i],
    a[href*="cart" i],a[href*="login" i],a[href*="signin" i],a[href*="account" i],
    [class*="downloadUI" i],[class*="openApp" i]{display:none!important;visibility:hidden!important;pointer-events:none!important}
    #otlobli-add-btn{bottom:16px!important}
  `
  ;(document.head || document.documentElement).appendChild(style)

  const hideSpinWheel = () => {
    const { width, height } = viewport()
    const wheelText = /(spin|wheel|reward|claim|coupon|lucky|chance|prize|free\s*gift|congratulations|SAR\s*\d|حرّ?ك|فرصة|جرب|تحصل|جائزة|مجاني|خصم)/i
    const nodes = document.querySelectorAll(
      '[role="dialog"],[class*="popup" i],[class*="modal" i],[class*="wheel" i],[class*="spin" i],div,section,aside',
    )
    const limit = Math.min(nodes.length, 1800)
    for (let index = 0; index < limit; index += 1) {
      const node = nodes[index]
      if (node.dataset.otlobliGeckoHidden === '1') continue
      const rect = node.getBoundingClientRect()
      if (rect.width < width * 0.45 || rect.height < height * 0.16) continue
      const css = getComputedStyle(node)
      const zIndex = Number.parseInt(css.zIndex, 10) || 0
      if (!['fixed', 'absolute', 'sticky'].includes(css.position) && zIndex < 20) continue
      const text = textOf(node)
      if (text.length > 1100 || !wheelText.test(`${node.className || ''} ${node.id || ''} ${text}`)) continue
      if (node.querySelector('input:not([type="hidden"]),textarea')) continue
      if (isProductOptionDialog(node)) continue

      let target = node
      let parent = node.parentElement
      for (let hops = 0; parent && parent !== document.body && hops < 3; hops += 1, parent = parent.parentElement) {
        const parentRect = parent.getBoundingClientRect()
        const parentCss = getComputedStyle(parent)
        if (textOf(parent).length > 1300) break
        if (['fixed', 'absolute'].includes(parentCss.position) &&
            parentRect.width > width * 0.55 && parentRect.height > height * 0.22 && parentRect.height < height * 0.98) {
          target = parent
        }
      }
      if (isProductOptionDialog(target)) continue
      hide(target)
    }
    document.body.style.overflow = ''
    document.documentElement.style.overflow = ''
  }

  const hideHomePromotionOverlays = () => {
    // Temu sometimes paints the prize wheel as images/canvas, leaving no
    // reliable text for the normal blocker to match. On the store home only,
    // remove any large fixed promotional cover. Product option sheets and the
    // genuine security verification live on other paths and are untouched.
    if (!/^\/(?:sa\/?)?$/.test(window.location.pathname)) return
    const { width, height } = viewport()
    const nodes = document.querySelectorAll('div,section,aside')
    const limit = Math.min(nodes.length, 1800)
    for (let index = 0; index < limit; index += 1) {
      const node = nodes[index]
      if (node.dataset.otlobliGeckoHidden === '1') continue
      const rect = node.getBoundingClientRect()
      if (rect.width < width * 0.82 || rect.height < height * 0.48) continue
      const css = getComputedStyle(node)
      const zIndex = Number.parseInt(css.zIndex, 10) || 0
      if (css.position !== 'fixed' || zIndex < 20) continue
      if (node.querySelector('input:not([type="hidden"]),textarea,select')) continue
      hide(node)
    }
    document.body.style.overflow = ''
    document.documentElement.style.overflow = ''
  }

  const hideHeaderIcons = () => {
    const { width } = viewport()
    const search = document.querySelector('input[type="search"],input[placeholder*="search" i],input[placeholder*="بحث"],[role="searchbox"]')
    const searchRect = search?.getBoundingClientRect()
    const leftLimit = Math.min(width * 0.38, searchRect && searchRect.width > width * 0.25 ? searchRect.left - 6 : width * 0.34)
    if (leftLimit < 70) return

    const raw = document.querySelectorAll('a,button,[role="button"],div,span')
    const candidates = []
    const limit = Math.min(raw.length, 1600)
    for (let index = 0; index < limit; index += 1) {
      const node = raw[index]
      if (node.dataset.otlobliGeckoHidden === '1' || node.querySelector?.('input,textarea,select')) continue
      const rect = node.getBoundingClientRect()
      if (rect.width < 22 || rect.height < 22 || rect.width > 76 || rect.height > 76) continue
      if (rect.top < 20 || rect.top > 230 || rect.left < 0 || rect.left > leftLimit) continue
      const hint = `${node.className || ''} ${node.id || ''} ${node.getAttribute?.('aria-label') || ''} ${textOf(node)}`
      if (/search|بحث|logo|temu/i.test(hint)) continue
      if (!node.querySelector?.('svg,img') && !/(cart|bag|account|profile|menu|سلة|حساب|قائمة)/i.test(hint)) continue
      candidates.push({ node, left: rect.left, area: rect.width * rect.height })
    }
    candidates.sort((left, right) => left.area - right.area)
    const buckets = []
    for (const candidate of candidates) {
      if (buckets.some((left) => Math.abs(left - candidate.left) < 16)) continue
      let target = candidate.node
      let parent = target.parentElement
      for (let hops = 0; parent && hops < 2; hops += 1, parent = parent.parentElement) {
        const rect = parent.getBoundingClientRect()
        if (rect.width > 84 || rect.height > 84 || parent.querySelector?.('input')) break
        target = parent
      }
      hide(target)
      buckets.push(candidate.left)
      if (buckets.length >= 5) break
    }
  }

  const hideProductCartActions = () => {
    if (!/^\/(?:sa\/?|search.*)?$/i.test(window.location.pathname)) return
    const { width } = viewport()
    const controls = document.querySelectorAll('button,[role="button"],a')
    const limit = Math.min(controls.length, 1000)
    for (let index = 0; index < limit; index += 1) {
      const node = controls[index]
      if (node.dataset.otlobliGeckoHidden === '1') continue
      const rect = node.getBoundingClientRect()
      if (rect.top < 230 || rect.width < 24 || rect.width > 92 || rect.height < 24 || rect.height > 76) continue
      const hint = `${node.className || ''} ${node.id || ''} ${node.getAttribute('aria-label') || ''} ${node.getAttribute('title') || ''}`
      if (/(?:add.?to.?cart|shopping.?cart|basket|quick.?add|cart.?add)/i.test(hint)) {
        hide(node)
        continue
      }
      if (!node.querySelector('svg') || textOf(node).length > 3) continue
      let card = node.parentElement
      for (let hops = 0; card && hops < 6; hops += 1, card = card.parentElement) {
        const cardRect = card.getBoundingClientRect()
        if (cardRect.width < width * 0.34 || cardRect.width > width * 0.64) continue
        const cardText = textOf(card)
        const hasProductImage = !!card.querySelector('img')
        const hasPrice = /(?:SAR|\u0631\.\s*\u0633|\d+[.,]\d{2})/i.test(cardText)
        if (hasProductImage && hasPrice) {
          hide(node)
          break
        }
      }
    }
  }

  const hideProductPurchaseActions = () => {
    if (!isProductRoute()) return
    const { width, height } = viewport()
    const actionText = /(?:حدد\s+خيار(?:اً|ا)?|اختر\s+خيار(?:اً|ا)?|أضف\s+(?:إلى\s+)?(?:السلة|سلة\s+التسوق)|اضف\s+(?:إلى\s+)?(?:السلة|سلة\s+التسوق)|add\s+to\s+(?:cart|bag)|select\s+(?:an?\s+)?options?|choose\s+options?|buy\s+now|اشتر(?:ي)?\s+الآن)/i
    const nodes = document.querySelectorAll('button,[role="button"],a,[tabindex="0"],div,span')
    const limit = Math.min(nodes.length, 1800)
    for (let index = 0; index < limit; index += 1) {
      const node = nodes[index]
      if (node.dataset.otlobliGeckoHidden === '1' || node.id?.startsWith('otlobli')) continue
      if (node.closest?.('[id^="otlobli"]') || node.querySelector?.('input,textarea,select')) continue
      const text = textOf(node)
      if (!text || text.length > 60 || !actionText.test(text)) continue
      const rect = node.getBoundingClientRect()
      if (rect.width < width * 0.32 || rect.height < 28 || rect.height > 130) continue

      let target = node
      let parent = node.parentElement
      for (let hops = 0; parent && parent !== document.body && hops < 4; hops += 1, parent = parent.parentElement) {
        const parentRect = parent.getBoundingClientRect()
        if (parentRect.height > 180 || parentRect.width < width * 0.68) break
        const parentStyle = getComputedStyle(parent)
        if (['fixed', 'sticky', 'absolute'].includes(parentStyle.position) && parentRect.bottom > height - 220) {
          target = parent
        }
      }
      hide(target)
    }
  }

  const hideProductHeaderControls = () => {
    if (!isProductRoute()) return
    const { width } = viewport()
    const nodes = document.querySelectorAll('button,[role="button"],a,[tabindex="0"],div,span')
    const limit = Math.min(nodes.length, 900)
    for (let index = 0; index < limit; index += 1) {
      const node = nodes[index]
      if (node.dataset.otlobliGeckoHidden === '1' || node.id?.startsWith('otlobli')) continue
      if (node.closest?.('[id^="otlobli"]') || node.querySelector?.('input,textarea,select')) continue
      const rect = node.getBoundingClientRect()
      if (rect.left < width * 0.82 || rect.top < 12 || rect.top > 150) continue
      if (rect.width < 20 || rect.width > 72 || rect.height < 20 || rect.height > 72) continue
      const hint = `${node.className || ''} ${node.id || ''} ${node.getAttribute?.('aria-label') || ''} ${textOf(node)}`
      if (/search|بحث|logo|temu/i.test(hint)) continue
      if (!node.querySelector?.('svg,img') && !/[<>‹›←→×]/.test(textOf(node))) continue

      let target = node
      let parent = node.parentElement
      for (let hops = 0; parent && hops < 2; hops += 1, parent = parent.parentElement) {
        const parentRect = parent.getBoundingClientRect()
        if (parentRect.width > 78 || parentRect.height > 78 || parent.querySelector?.('input')) break
        target = parent
      }
      hide(target)
    }
  }

  const hideCustomerChrome = () => {
    const { width, height } = viewport()
    const nodes = document.querySelectorAll('div,section,aside,nav,footer')
    const limit = Math.min(nodes.length, 1800)
    for (let index = 0; index < limit; index += 1) {
      const node = nodes[index]
      if (node.dataset.otlobliGeckoHidden === '1' || node.querySelector?.('input[type="search"],[role="searchbox"]')) continue
      const text = textOf(node)
      if (!text || text.length > 180) continue
      const rect = node.getBoundingClientRect()
      if (rect.width < width * 0.45 || rect.height <= 0 || rect.height > 170) continue
      const css = getComputedStyle(node)
      const fixed = ['fixed', 'sticky', 'absolute'].includes(css.position)
      const bottomLogin = rect.bottom > height - 180 && /(سجل الدخول|تسجيل الدخول|الدخول|sign in|login|أفضل تجربة|best experience)/i.test(text)
      const appBanner = rect.top < 170 && /temu/i.test(text) && /(احصل|تنزيل|تطبيق|get|download|app)/i.test(text)
      if (fixed && (bottomLogin || appBanner)) hide(node)
    }
  }

  const hideTemuBottomNavigation = () => {
    const { height } = viewport()
    const candidates = document.querySelectorAll('nav,footer,div,ul')
    for (const node of candidates) {
      if (node.dataset.otlobliGeckoHidden === '1') continue
      const text = textOf(node)
      if (!text || text.length > 90 || !/(?:حسابي|طلباتي|الرئيسية|home|orders|account)/i.test(text)) continue
      const css = getComputedStyle(node)
      if (css.position !== 'fixed') continue
      const rect = node.getBoundingClientRect()
      if (rect.top < height * 0.68 || rect.height > 140) continue
      hide(node)
    }
  }

  let scheduled = false
  let lastCleanAt = 0
  const clean = () => {
    scheduled = false
    if (document.hidden || !document.body) return
    lastCleanAt = Date.now()
    hideHomePromotionOverlays()
    hideSpinWheel()
    hideHeaderIcons()
    hideProductCartActions()
    hideProductPurchaseActions()
    hideProductHeaderControls()
    hideCustomerChrome()
    hideTemuBottomNavigation()
  }
  const schedule = () => {
    if (scheduled) return
    scheduled = true
    setTimeout(clean, Math.max(30, 180 - (Date.now() - lastCleanAt)))
  }
  const observer = new MutationObserver(schedule)
  observer.observe(document.documentElement, { childList: true, subtree: true })
  setTimeout(() => observer.disconnect(), 12000)
  setInterval(schedule, 1200)
  document.addEventListener('visibilitychange', schedule, { passive: true })
  schedule()
})()
