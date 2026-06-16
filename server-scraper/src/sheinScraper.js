import { chromium } from 'playwright'

// ─── In-memory cache (URL → product, TTL 30 min) ──────────────────────────
const cache = new Map()
const CACHE_TTL = 30 * 60 * 1000
function cacheGet(url) {
  const entry = cache.get(url)
  if (!entry) return null
  if (Date.now() - entry.ts > CACHE_TTL) { cache.delete(url); return null }
  return entry.data
}
function cacheSet(url, data) { cache.set(url, { data, ts: Date.now() }) }

// ─── Extract goods ID from any SHEIN URL ──────────────────────────────────
function extractGoodsId(url) {
  return url.match(/[_-]p[_-]?(\d{6,12})/i)?.[1] ||
    url.match(/goods_id=(\d+)/)?.[1] ||
    url.match(/\/(\d{6,12})\.html/)?.[1] ||
    ''
}

function cleanTitle(raw = '') {
  return raw
    .replace(/<[^>]*>/g, '')
    .replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&quot;/g, '"')
    .replace(/\s*\|\s*SHEIN.*/i, '').replace(/\s*-\s*SHEIN.*/i, '')
    .trim()
}

function isProductImage(url) {
  if (!url || url.endsWith('.svg')) return false
  if (url.includes('svgicons') || url.includes('bg-logo') || url.includes('pwa_dist')) return false
  return true
}

function isSharingUrl(url) {
  return url.includes('api-shein.shein.com') || url.includes('/sharejump/') || url.includes('/h5/share')
}

// ─── Stealth script to bypass bot detection ───────────────────────────────
const STEALTH_SCRIPT = `
  Object.defineProperty(navigator, 'webdriver', { get: () => undefined })
  Object.defineProperty(navigator, 'plugins', { get: () => [
    { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer' },
    { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai' },
    { name: 'Native Client', filename: 'internal-nacl-plugin' },
  ]})
  Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en', 'ar'] })
  Object.defineProperty(navigator, 'hardwareConcurrency', { get: () => 4 })
  Object.defineProperty(screen, 'colorDepth', { get: () => 24 })
  window.chrome = { runtime: {}, loadTimes: () => {}, csi: () => {}, app: {} }
  const originalQuery = window.navigator.permissions.query
  window.navigator.permissions.query = (params) =>
    params.name === 'notifications' ? Promise.resolve({ state: Notification.permission }) : originalQuery(params)
`

// ─── Persistent browser (one instance for all requests) ───────────────────
const USER_DATA_DIR = '/tmp/shein-session'
const BROWSER_ARGS = [
  '--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage',
  '--single-process', '--no-zygote', '--disable-gpu', '--memory-pressure-off',
  '--disable-blink-features=AutomationControlled',
  '--disable-features=IsolateOrigins,site-per-process',
  '--lang=en-US',
]

let _context = null
let _initDone = false

async function getContext() {
  if (_context) {
    try {
      // Verify context is still alive
      await _context.pages()
      return _context
    } catch {
      _context = null
    }
  }
  console.log('🌐 Starting persistent browser session...')
  _context = await chromium.launchPersistentContext(USER_DATA_DIR, {
    headless: true,
    args: BROWSER_ARGS,
    userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.76 Mobile Safari/537.36',
    viewport: { width: 390, height: 844 },
    locale: 'en-US',
    timezoneId: 'America/New_York',
    geolocation: { longitude: -74.0060, latitude: 40.7128 },
    permissions: ['geolocation'],
    extraHTTPHeaders: {
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
    },
  })
  _context.addInitScript(STEALTH_SCRIPT).catch(() => {})
  return _context
}

// Warm up the browser by visiting shein.com once
async function warmUpBrowser() {
  if (_initDone) return
  _initDone = true
  try {
    const ctx = await getContext()
    const page = await ctx.newPage()
    await page.addInitScript(STEALTH_SCRIPT)
    await page.goto('https://m.shein.com/us/', { waitUntil: 'domcontentloaded', timeout: 20000 }).catch(() => {})
    await page.waitForTimeout(2000)
    await page.close()
    console.log('✅ Browser warmed up at m.shein.com/us/')
  } catch (e) {
    console.log('⚠️ Warm-up failed:', e.message)
    _initDone = false
  }
}

// ─── Browse to a page and extract product data ────────────────────────────
async function browserFetch(productUrl) {
  const ctx = await getContext()
  const page = await ctx.newPage()
  try {
    await page.addInitScript(STEALTH_SCRIPT)
    await page.route(/analytics|facebook|doubleclick|google-analytics|gtag|cdn\.ampproject/, route => route.abort())

    console.log(`🔍 Navigating to ${productUrl}`)
    await page.goto(productUrl, { waitUntil: 'domcontentloaded', timeout: 40000 }).catch(() => {})
    await page.waitForTimeout(3000)

    const goodsId = extractGoodsId(page.url()) || extractGoodsId(productUrl)

    // Try to intercept XHR/fetch product API responses
    // Try __NUXT__ or __INITIAL_STATE__
    let nuxtData = null
    try {
      nuxtData = await page.evaluate(() => {
        for (const key of ['__NUXT__', '__INITIAL_STATE__', '__NEXT_DATA__', 'gbData']) {
          try { if (window[key]) return JSON.parse(JSON.stringify(window[key])) } catch {}
        }
        return null
      })
    } catch {}

    if (nuxtData) {
      const info = nuxtData?.data?.info || nuxtData?.info || nuxtData?.props?.pageProps?.product ||
        nuxtData?.productDetail || nuxtData?.goodsDetail
      if (info?.goods_name) {
        const title = cleanTitle(info.goods_name)
        const price = parseFloat(info.sale_price?.amount || info.salePrice?.amount || info.sell_price || info.price || '0')
        const rawImgs = (info.goods_imgs?.main_image_list || info.goods_img || [])
          .map(i => typeof i === 'string' ? i : (i?.url || i?.origin_image || ''))
        const images = rawImgs.filter(isProductImage)
        if (title) {
          console.log(`✅ __NUXT__: ${title} | $${price}`)
          return { goodsId, title, price, images, colors: [], sizes: [], url: productUrl }
        }
      }
    }

    // Fallback: OG tags + visible images
    const meta = await page.evaluate(() => {
      const og = (n) => document.querySelector(`meta[property="${n}"]`)?.getAttribute('content') || ''
      const h1 = document.querySelector('h1,.product-intro__head-name,.goods-name')?.textContent?.trim() || ''
      const priceEl = document.querySelector('.product-price .price-content,.product-intro__head-price')?.textContent?.trim() || ''
      const allImgs = [...document.querySelectorAll('img[src*="ltwebstatic"],img[src*="img.shein"]')]
        .map(i => i.src || i.getAttribute('data-src')).filter(Boolean)
      return {
        title: og('og:title') || h1,
        price: og('product:price:amount') || priceEl.replace(/[^0-9.]/g, ''),
        image: og('og:image'),
        images: allImgs,
      }
    })

    const title = cleanTitle(meta.title)
    const price = parseFloat(meta.price) || 0
    const images = [...new Set([meta.image, ...meta.images].filter(isProductImage))].slice(0, 8)

    if (title) {
      console.log(`✅ OG/DOM: ${title} | $${price}`)
      return { goodsId, title, price, images, colors: [], sizes: [], url: productUrl }
    }

    console.log(`⚠️ No data found at ${productUrl}`)
    return null
  } finally {
    await page.close().catch(() => {})
  }
}

// ─── Method 1: SHEIN internal JSON API (fast, ~1s) ────────────────────────
async function fetchViaApi(goodsId) {
  if (!goodsId) return null
  const endpoints = [
    `https://us.shein.com/product/index.json?goods_id=${goodsId}&cat_id=0`,
    `https://m.shein.com/api/product/detail?goods_id=${goodsId}`,
  ]
  const headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.76 Mobile Safari/537.36',
    'Accept': 'application/json, */*',
    'Referer': 'https://m.shein.com/',
    'Origin': 'https://m.shein.com',
  }
  for (const endpoint of endpoints) {
    try {
      const res = await fetch(endpoint, { headers, signal: AbortSignal.timeout(8000) })
      if (!res.ok) continue
      const json = await res.json()
      const info = json?.info || json?.data?.info || json?.data?.detail
      if (!info) continue
      const title = cleanTitle(info.goods_name || '')
      const price = parseFloat(info.sale_price?.amount || info.salePrice?.amount || info.sell_price || '0')
      const rawImgs = (info.goods_imgs?.main_image_list || info.goods_img || [])
        .map(i => typeof i === 'string' ? i : (i?.url || i?.origin_image || ''))
      const images = rawImgs.filter(isProductImage)
      if (title && price > 0) {
        console.log(`✅ API: ${title} | $${price}`)
        return { goodsId, title, price, images, colors: [], sizes: [], url: `https://m.shein.com/us/product-p-${goodsId}.html` }
      }
    } catch (e) { console.log(`⚠️ API endpoint failed: ${e.message}`) }
  }
  return null
}

// ─── Method 2: HTTP fetch + OG tags (no JS needed) ───────────────────────
async function fetchViaHttp(productUrl) {
  const headers = {
    'User-Agent': 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
    'Accept': 'text/html,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  }
  try {
    const res = await fetch(productUrl, { headers, signal: AbortSignal.timeout(12000) })
    if (!res.ok) return null
    const html = await res.text()
    const getOg = (prop) =>
      html.match(new RegExp(`<meta[^>]+property=["\']${prop}["\'][^>]+content=["\']([^"\']+)["\']`))?.[1] ||
      html.match(new RegExp(`<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']${prop}["\']`))?.[1] || ''
    const title = cleanTitle(getOg('og:title'))
    const priceStr = getOg('product:price:amount')
    const image = getOg('og:image')
    const goodsId = extractGoodsId(productUrl)
    const imgMatches = [...html.matchAll(/["'](https:\/\/img\.ltwebstatic\.com\/[^"']+\.(?:jpg|webp)[^"']*)['"]/g)]
    const images = [...new Set([image, ...imgMatches.map(m => m[1])].filter(isProductImage))].slice(0, 8)
    if (title) {
      console.log(`✅ HTTP/OG: ${title} | $${priceStr || 0}`)
      return { goodsId, title, price: parseFloat(priceStr) || 0, images, colors: [], sizes: [], url: productUrl }
    }
  } catch (e) { console.log(`⚠️ HTTP fetch failed: ${e.message}`) }
  return null
}

// ─── Resolve sharing URL to actual product URL ────────────────────────────
async function resolveShareUrl(shareUrl) {
  console.log('🔗 Resolving share URL...')
  const ctx = await getContext()
  const page = await ctx.newPage()
  try {
    await page.addInitScript(STEALTH_SCRIPT)
    let resolvedUrl = null
    page.on('request', req => {
      const u = req.url()
      if (extractGoodsId(u) && u.includes('shein.com') && !u.includes('sharejump')) resolvedUrl = u
    })
    page.on('framenavigated', frame => {
      const u = frame.url()
      if (extractGoodsId(u) && u !== shareUrl) resolvedUrl = u
    })
    await page.goto(shareUrl, { waitUntil: 'domcontentloaded', timeout: 20000 }).catch(() => {})
    await page.waitForTimeout(4000)
    const finalUrl = page.url()
    const candidate = resolvedUrl || (extractGoodsId(finalUrl) ? finalUrl : null)
    if (candidate && candidate !== shareUrl) {
      console.log(`✅ Resolved: ${candidate}`)
      return candidate
    }
    return null
  } finally {
    await page.close().catch(() => {})
  }
}

// ─── Main export ──────────────────────────────────────────────────────────
export async function fetchSheinProduct(productUrl) {
  console.log(`\n📦 Fetching: ${productUrl}`)

  // Cache check
  const cached = cacheGet(productUrl)
  if (cached) { console.log('⚡ Cache hit'); return cached }

  // Ensure browser is warmed up
  await warmUpBrowser()

  let url = productUrl

  // Resolve sharing URLs
  if (isSharingUrl(productUrl)) {
    const resolved = await resolveShareUrl(productUrl).catch(() => null)
    if (resolved) url = resolved
  }

  // Extract goodsId and try JSON API first (fastest, no browser needed)
  const goodsId = extractGoodsId(url)
  if (goodsId) {
    const apiResult = await fetchViaApi(goodsId)
    if (apiResult?.title && apiResult.price > 0) { cacheSet(productUrl, apiResult); return apiResult }
  }

  // Normalize regional URLs to m.shein.com/us for browser access
  if (goodsId && !url.includes('m.shein.com/us')) {
    url = `https://m.shein.com/us/product-p-${goodsId}.html?ref=m&rep=dir&ret=mus`
    console.log(`🔄 Normalized to: ${url}`)
  }

  // HTTP fetch with bot-friendly user agent
  const httpResult = await fetchViaHttp(url)
  if (httpResult?.title && httpResult.price > 0) { cacheSet(productUrl, httpResult); return httpResult }

  // Full browser scraping (persistent session)
  const browserResult = await browserFetch(url)
  if (browserResult?.title) { cacheSet(productUrl, browserResult); return browserResult }

  // Return partial data if at least title was found
  const partial = httpResult?.title ? httpResult : null
  if (partial) { cacheSet(productUrl, partial); return partial }

  throw new Error('تعذر جلب بيانات المنتج من SHEIN. جرب رابط المنتج المباشر من موقع SHEIN أو رابط المشاركة من التطبيق.')
}

export default { fetchSheinProduct }
