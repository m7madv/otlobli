import { chromium } from 'playwright'
import { rmSync } from 'fs'
import { parseSheinApiResponse, isProductImage } from './parseSheinProduct.js'

const USER_AGENT = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.76 Mobile Safari/537.36'
const USER_DATA_DIR = '/tmp/shein-session'

const STEALTH_SCRIPT = `
  Object.defineProperty(navigator, 'webdriver', { get: () => undefined })
  Object.defineProperty(navigator, 'plugins', { get: () => [
    { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer' },
    { name: 'Native Client', filename: 'internal-nacl-plugin' },
  ]})
  Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] })
  Object.defineProperty(navigator, 'hardwareConcurrency', { get: () => 4 })
  window.chrome = { runtime: {}, loadTimes: () => {}, csi: () => {}, app: {} }
`

// Clear localStorage/sessionStorage before page load so SHEIN treats us as a new visitor
// and serves full SSR HTML (with sizes) instead of SPA mode
const CLEAR_STORAGE_SCRIPT = `
  try { localStorage.clear() } catch {}
  try { sessionStorage.clear() } catch {}
`

const BROWSER_ARGS = [
  '--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage',
  '--single-process', '--no-zygote', '--disable-gpu', '--memory-pressure-off',
  '--disable-blink-features=AutomationControlled',
  '--lang=en-US', '--accept-lang=en-US',
]

const USD_COOKIES = [
  { name: 'currency', value: 'USD', domain: '.shein.com', path: '/' },
  { name: 'cookieCurrency', value: 'USD', domain: '.shein.com', path: '/' },
  { name: 'shein_webp', value: '1', domain: '.shein.com', path: '/' },
]

let _context = null
let _ready = false

// Proxy pool — reads PROXY_LIST (comma-separated IP:PORT) or falls back to PROXY_SERVER.
// All proxies share the same PROXY_USERNAME / PROXY_PASSWORD credentials.
const _proxyList = (() => {
  const username = process.env.PROXY_USERNAME || ''
  const password = process.env.PROXY_PASSWORD || ''
  const list = process.env.PROXY_LIST
  if (list) {
    const proxies = list.split(',').map(s => s.trim()).filter(Boolean).map(s => ({
      server: `http://${s}`,
      username,
      password,
    }))
    if (proxies.length) return proxies
  }
  const single = process.env.PROXY_SERVER
  if (!single) return []
  return [{ server: single.startsWith('http') ? single : `http://${single}`, username, password }]
})()

let _proxyIndex = 0

// Track when each proxy last got a 909 captcha (to avoid hammering burned proxies)
const _proxyCaptchaAt = new Array(Math.max(_proxyList.length, 1)).fill(0)
// 45-minute cooldown: SHEIN's per-IP rate limit typically resets within 30-60 min
const PROXY_COOLDOWN_MS = 45 * 60 * 1000

function markProxyCaptcha() {
  if (_proxyList.length > 0) _proxyCaptchaAt[_proxyIndex] = Date.now()
}

function isProxyCoolingDown(idx) {
  return Date.now() - (_proxyCaptchaAt[idx] || 0) < PROXY_COOLDOWN_MS
}

function findAvailableProxyIndex() {
  for (let i = 0; i < _proxyList.length; i++) {
    const idx = (_proxyIndex + i) % _proxyList.length
    if (!isProxyCoolingDown(idx)) return idx
  }
  return -1 // all cooling down
}

function getCurrentProxy() {
  return _proxyList.length > 0 ? _proxyList[_proxyIndex] : undefined
}

function clearOldSession() {
  try {
    rmSync(USER_DATA_DIR, { recursive: true, force: true })
  } catch {}
}

async function getContext() {
  if (_context) {
    try { await _context.pages(); return _context } catch { _context = null; _ready = false }
  }
  clearOldSession()
  const proxy = getCurrentProxy()
  console.log(proxy
    ? `🌐 Starting browser (proxy: ${proxy.server} — ${_proxyIndex + 1}/${_proxyList.length})...`
    : '🌐 Starting browser...')
  _context = await chromium.launchPersistentContext(USER_DATA_DIR, {
    headless: true, args: BROWSER_ARGS,
    userAgent: USER_AGENT,
    viewport: { width: 390, height: 844 },
    locale: 'en-US',
    timezoneId: 'America/New_York',
    geolocation: { longitude: -74.006, latitude: 40.7128 },
    permissions: ['geolocation'],
    extraHTTPHeaders: { 'Accept-Language': 'en-US,en;q=0.9', 'Accept-Currency': 'USD' },
    serviceWorkers: 'block',
    ...(proxy ? { proxy } : {}),
  })
  _context.addInitScript(STEALTH_SCRIPT).catch(() => {})
  return _context
}

// Prepare context to look like a fresh visitor: clear SHEIN session cookies while preserving
// Cloudflare cookies (cf_clearance). This forces SHEIN SSR mode without re-triggering CF challenges.
async function resetToFreshVisitor(ctx) {
  const all = await ctx.cookies().catch(() => [])
  const cfCookies = all.filter(c => c.name.startsWith('cf_') || c.name === '__cf_bm')
  await ctx.clearCookies().catch(() => {})
  if (cfCookies.length) await ctx.addCookies(cfCookies).catch(() => {})
  await ctx.addCookies(USD_COOKIES).catch(() => {})
}

export async function resetBrowserToUsd() {
  if (!_context) return
  await resetToFreshVisitor(_context).catch(() => {})
}

// Restart the browser with a completely fresh profile.
export async function restartBrowser() {
  console.log('🔄 Restarting browser for clean session...')
  if (_context) {
    await _context.close().catch(() => {})
    _context = null
    _ready = false
  }
  await warmUpBrowser()
}

// Rotate to the next proxy in the pool and restart browser.
// Called automatically when SHEIN blocks the current IP (captcha_type=909).
export async function rotateProxyAndRestart() {
  if (_proxyList.length <= 1) {
    console.log('⚠️ No more proxies to rotate to')
    return false
  }
  markProxyCaptcha() // mark current proxy as recently burned
  const nextIdx = findAvailableProxyIndex()
  if (nextIdx === -1) {
    const cooldownMin = Math.ceil(PROXY_COOLDOWN_MS / 60000)
    console.log(`⏳ All ${_proxyList.length} proxies are cooling down (${cooldownMin}min cooldown). Waiting for next available...`)
    return false
  }
  _proxyIndex = nextIdx
  const p = _proxyList[_proxyIndex]
  console.log(`🔄 Proxy rotated → ${p.server} (${_proxyIndex + 1}/${_proxyList.length})`)
  if (_context) {
    await _context.close().catch(() => {})
    _context = null
    _ready = false
  }
  await warmUpBrowser()
  return true
}

export async function warmUpBrowser() {
  if (_ready) return
  try {
    const ctx = await getContext()
    // Visit SHEIN homepage to solve Cloudflare JS challenge and get cf_clearance cookie.
    // Without this, every product request gets a Cloudflare challenge page instead of the product.
    const warmPage = await ctx.newPage()
    await warmPage.addInitScript(STEALTH_SCRIPT)
    console.log('🌐 Warming up — solving Cloudflare challenge...')
    await warmPage.goto('https://m.shein.com/us/', { waitUntil: 'domcontentloaded', timeout: 20000 }).catch(() => {})
    await warmPage.waitForTimeout(4000).catch(() => {})
    await warmPage.close().catch(() => {})
    _ready = true
    console.log('✅ Browser ready')
  } catch (e) {
    console.log('⚠️ Browser start failed:', e.message)
  }
}

// Method 1: SHEIN JSON API via HTTP (fastest — ~1-2s)
export async function fetchViaApi(goodsId) {
  const endpoints = [
    `https://us.shein.com/product/index.json?goods_id=${goodsId}&cat_id=0`,
    `https://m.shein.com/api/product/detail?goods_id=${goodsId}&cat_id=0`,
    `https://shein.com/product/index.json?goods_id=${goodsId}`,
  ]
  const headers = {
    'User-Agent': USER_AGENT,
    'Accept': 'application/json, */*',
    'Referer': 'https://m.shein.com/us/',
    'Origin': 'https://m.shein.com',
    'X-Currency': 'USD',
  }
  for (const url of endpoints) {
    try {
      const res = await fetch(url, { headers, signal: AbortSignal.timeout(8000) })
      if (!res.ok) continue
      const json = await res.json()
      const parsed = parseSheinApiResponse(json)
      if (parsed?.title && parsed.priceUsd > 0) {
        console.log(`✅ API: ${parsed.title} | $${parsed.priceUsd} | colors:${parsed.colors.length} sizes:${parsed.sizes.length}`)
        return parsed
      }
    } catch {}
  }
  return null
}

// Method 1b: SHEIN API with cf_clearance from warmed browser (bypasses Cloudflare challenge).
// Uses Node.js fetch with browser cookies — avoids page-load anti-bot (captcha_type=909)
// because it calls the JSON API directly, not the product HTML page.
export async function fetchViaApiWithCookies(goodsId) {
  if (!_context) return null
  let cookieStr = ''
  try {
    const cookies = await _context.cookies()
    if (!cookies.some(c => c.name === 'cf_clearance')) return null
    cookieStr = cookies.map(c => `${c.name}=${c.value}`).join('; ')
  } catch { return null }

  const endpoints = [
    `https://m.shein.com/us/product/index.json?goods_id=${goodsId}&cat_id=0&currency=USD`,
    `https://us.shein.com/product/index.json?goods_id=${goodsId}&cat_id=0`,
  ]
  for (const url of endpoints) {
    try {
      const res = await fetch(url, {
        headers: {
          'User-Agent': USER_AGENT,
          'Cookie': cookieStr,
          'Accept': 'application/json, */*',
          'Referer': 'https://m.shein.com/us/',
          'Origin': 'https://m.shein.com',
          'X-Currency': 'USD',
        },
        signal: AbortSignal.timeout(10000),
      })
      if (!res.ok) continue
      const ct = res.headers.get('content-type') || ''
      if (!ct.includes('json')) continue
      const json = await res.json()
      const parsed = parseSheinApiResponse(json)
      if (parsed?.title && parsed.priceUsd > 0) {
        console.log(`✅ API+cookies: ${parsed.title} | $${parsed.priceUsd} | colors:${parsed.colors.length} sizes:${parsed.sizes.length}`)
        return parsed
      }
    } catch {}
  }
  return null
}

// Method 1c: XHR from within browser context (same-origin, has cf_clearance + session cookies).
// Navigates to SHEIN homepage (low suspicion), then makes a same-origin fetch to the product API.
// Avoids loading the product PAGE — captcha_type=909 is triggered only on product page loads.
export async function fetchViaBrowserXhr(goodsId) {
  if (!_ready) await warmUpBrowser()
  const ctx = await getContext()
  const page = await ctx.newPage()
  try {
    await page.addInitScript(STEALTH_SCRIPT)
    // Establish same-origin context without loading a product page
    await page.goto('https://m.shein.com/us/', { waitUntil: 'domcontentloaded', timeout: 12000 }).catch(() => {})
    if (page.isClosed()) return null

    // Try multiple SHEIN API endpoints from within the browser (same-origin, cookies auto-attached)
    const apiUrls = [
      `https://m.shein.com/us/product/index.json?goods_id=${goodsId}&cat_id=0&currency=USD`,
      `https://m.shein.com/us/get_goods_detail_realtime_data.html?goods_id=${goodsId}&currency=USD`,
    ]

    for (const apiUrl of apiUrls) {
      const json = await page.evaluate(async (url) => {
        try {
          const res = await fetch(url, {
            headers: { 'Accept': 'application/json', 'X-Currency': 'USD' },
            credentials: 'include',
          })
          if (!res.ok) return null
          const ct = res.headers.get('content-type') || ''
          if (!ct.includes('json')) return null
          return await res.json()
        } catch { return null }
      }, apiUrl).catch(() => null)

      if (json) {
        const parsed = parseSheinApiResponse(json)
        if (parsed?.title && parsed.priceUsd > 0) {
          console.log(`✅ Browser XHR: ${parsed.title} | $${parsed.priceUsd} | colors:${parsed.colors.length} sizes:${parsed.sizes.length}`)
          return parsed
        }
      }
    }
  } finally {
    await page.close().catch(() => {})
  }
  return null
}

// Method 1d: context.request — makes HTTP request through the same proxy + cookies as the browser context.
// Unlike fetchViaApiWithCookies (which uses Railway's own IP), this goes through the WebShare proxy,
// so cf_clearance is valid. Never loads the product PAGE → no captcha_type=909.
// productUrl: optional regional URL (e.g. ar.shein.com). Falls back to US store.
export async function fetchViaContextRequest(goodsId, productUrl = null) {
  if (!_ready) await warmUpBrowser()
  const ctx = await getContext()
  if (!ctx) return null

  const htmlUrl = productUrl || `https://m.shein.com/us/product-p-${goodsId}.html?ref=m&rep=dir&ret=mus`
  const baseOrigin = new URL(htmlUrl).origin
  const commonHeaders = {
    'User-Agent': USER_AGENT,
    'Accept': 'text/html,application/json,*/*;q=0.9',
    'Referer': baseOrigin + '/',
    'Accept-Language': 'en-US,en;q=0.9',
    'X-Currency': 'USD',
  }

  // 1. Try the product HTML page via HTTP (proxy + cf_clearance, no JS/browser engine)
  try {
    const res = await ctx.request.get(htmlUrl, { headers: commonHeaders, timeout: 15000 })
    const finalUrl = res.url()
    const status = res.status()
    const ct = res.headers()['content-type'] || '?'
    console.log(`  → context.request HTML ${status} (final=${finalUrl.substring(0,70)}) ${ct.substring(0,30)}`)
    if (finalUrl.includes('captcha_type=')) {
      console.log(`  → context.request: IP blocked (captcha), skip`)
    } else if (res.ok() && ct.includes('html')) {
      const html = await res.text().catch(() => '')
      const getOg = (prop) =>
        html.match(new RegExp(`<meta[^>]+property=["']${prop}["'][^>]+content=["']([^"']+)["']`))?.[1] ||
        html.match(new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+property=["']${prop}["']`))?.[1] || ''
      const title = cleanTitle(getOg('og:title'))
      const priceStr = getOg('product:price:amount')
      const currency = getOg('product:price:currency') || 'USD'
      if (title) {
        const priceUsd = currency === 'USD' ? parseFloat(priceStr) || 0 : 0
        const image = getOg('og:image')
        const imgMatches = [...html.matchAll(/["'](https:\/\/img\.ltwebstatic\.com\/[^"']+\.(?:jpg|webp)[^"']*)['"]/g)]
        const images = [...new Set([image, ...imgMatches.map(m => m[1])].filter(isProductImage))].slice(0, 8)
        // Extract sizes/colors from SSR JSON embedded in the HTML
        let colors = [], sizes = [], variants = []
        const ssrData = extractSkuListFromHtml(html, String(goodsId))
        if (ssrData) {
          const full = parseSheinApiResponse({ info: ssrData })
          if (full) { colors = full.colors || []; sizes = full.sizes || []; variants = full.variants || [] }
        }
        console.log(`✅ Context HTML: ${title} | $${priceUsd} | colors:${colors.length} sizes:${sizes.length}`)
        return { title, priceUsd, images, colors, sizes, variants, description: '' }
      }
    }
  } catch (e) {
    console.log(`  → context.request HTML error: ${e.message}`)
  }

  // 2. Try JSON API endpoints (regional + US)
  const host = new URL(htmlUrl).hostname
  const jsonEndpoints = [
    `https://${host}/product/index.json?goods_id=${goodsId}&cat_id=0&currency=USD`,
    `https://m.shein.com/us/product/index.json?goods_id=${goodsId}&cat_id=0&currency=USD`,
    `https://us.shein.com/product/index.json?goods_id=${goodsId}&cat_id=0`,
  ]
  for (const url of jsonEndpoints) {
    try {
      const res = await ctx.request.get(url, { headers: { ...commonHeaders, 'Accept': 'application/json, */*' }, timeout: 12000 })
      const status = res.status()
      const ct = res.headers()['content-type'] || '?'
      console.log(`  → context.request JSON ${status} ${ct.substring(0,30)} (${url.substring(0,60)})`)
      if (!res.ok()) continue
      const text = await res.text().catch(() => '')
      let json = null
      try { json = JSON.parse(text) } catch {}
      if (!json) continue
      const parsed = parseSheinApiResponse(json)
      if (parsed?.title && parsed.priceUsd > 0) {
        console.log(`✅ Context API JSON: ${parsed.title} | $${parsed.priceUsd}`)
        return parsed
      }
      console.log(`  → JSON no title/price: ${JSON.stringify(json).substring(0,100)}`)
    } catch (e) {
      console.log(`  → context.request JSON error: ${e.message}`)
    }
  }
  return null
}

// Method 1e: ScraperAPI — managed residential proxy, handles Cloudflare automatically
export async function fetchViaScraperApi(productUrl, goodsId) {
  const apiKey = process.env.SCRAPERAPI_KEY
  if (!apiKey) return null

  console.log(`🕷️ Trying ScraperAPI for ${productUrl}`)
  const scraperUrl = `http://api.scraperapi.com?api_key=${apiKey}&url=${encodeURIComponent(productUrl)}&country_code=us`

  try {
    const res = await fetch(scraperUrl, { signal: AbortSignal.timeout(30000) })
    if (!res.ok) { console.log(`  → ScraperAPI: HTTP ${res.status}`); return null }
    const html = await res.text()

    if (html.includes('captcha_type=') || html.includes('captcha-challenge')) {
      console.log(`  → ScraperAPI: got captcha page`); return null
    }

    const getOg = (prop) =>
      html.match(new RegExp(`<meta[^>]+property=["']${prop}["'][^>]+content=["']([^"']+)["']`))?.[1] ||
      html.match(new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+property=["']${prop}["']`))?.[1] || ''

    const title = cleanTitle(getOg('og:title'))
    if (!title) { console.log(`  → ScraperAPI: no og:title (len=${html.length})`); return null }

    const priceStr = getOg('product:price:amount')
    const currency = getOg('product:price:currency') || 'USD'
    const priceUsd = currency === 'USD' ? parseFloat(priceStr) || 0 : 0
    const image = getOg('og:image')
    const imgMatches = [...html.matchAll(/["'](https:\/\/img\.ltwebstatic\.com\/[^"']+\.(?:jpg|webp)[^"']*)['"]/g)]
    const images = [...new Set([image, ...imgMatches.map(m => m[1])].filter(isProductImage))].slice(0, 8)

    // Try to extract sizes/colors from embedded JSON
    let colors = [], sizes = [], variants = []
    if (goodsId) {
      const ssrData = extractSkuListFromHtml(html, goodsId)
      if (ssrData) {
        const full = parseSheinApiResponse({ info: ssrData })
        if (full) { colors = full.colors || []; sizes = full.sizes || []; variants = full.variants || [] }
      }
    }

    console.log(`✅ ScraperAPI: ${title} | $${priceUsd} | colors:${colors.length} sizes:${sizes.length}`)
    return { title, priceUsd, images, colors, sizes, variants, description: '' }
  } catch (e) {
    console.log(`  → ScraperAPI error: ${e.message}`)
    return null
  }
}

// Method 2: HTTP fetch with Facebook crawl UA (no JS, fast — ~2-3s)
export async function fetchViaHttp(productUrl) {
  const headers = {
    'User-Agent': 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
    'Accept': 'text/html,*/*;q=0.9',
    'Accept-Language': 'en-US,en;q=0.9',
  }
  try {
    const res = await fetch(productUrl, { headers, signal: AbortSignal.timeout(10000) })
    const finalUrl = res.url
    console.log(`  → HTTP ${res.status} final=${(finalUrl || productUrl).substring(0,70)}`)
    if (!res.ok) return null
    const html = await res.text()
    const getOg = (prop) =>
      html.match(new RegExp(`<meta[^>]+property=["']${prop}["'][^>]+content=["']([^"']+)["']`))?.[1] ||
      html.match(new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+property=["']${prop}["']`))?.[1] || ''
    const title = cleanTitle(getOg('og:title'))
    const priceStr = getOg('product:price:amount')
    const currency = getOg('product:price:currency') || 'USD'
    if (!title) { console.log(`  → HTTP: no og:title in response (len=${html.length})`); return null }
    const priceUsd = currency === 'USD' ? parseFloat(priceStr) || 0 : 0
    const image = getOg('og:image')
    const imgMatches = [...html.matchAll(/["'](https:\/\/img\.ltwebstatic\.com\/[^"']+\.(?:jpg|webp)[^"']*)['"]/g)]
    const images = [...new Set([image, ...imgMatches.map(m => m[1])].filter(isProductImage))].slice(0, 8)
    console.log(`✅ HTTP: ${title} | $${priceUsd} (${currency})`)
    return { title, priceUsd, images, colors: [], sizes: [], variants: [], description: '' }
  } catch (e) {
    console.log(`  → HTTP error: ${e.message}`)
    return null
  }
}

function cleanTitle(raw = '') {
  return raw
    .replace(/<[^>]*>/g, '').replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&quot;/g, '"')
    .replace(/\s*\|\s*SHEIN.*/i, '').replace(/\s*-\s*SHEIN.*/i, '').trim()
}

// Extract product SKU data embedded in SSR HTML by balanced JSON parsing.
// SHEIN embeds full product data (goods_id, goods_name, sku_list with sizes) in the initial HTML.
function extractSkuListFromHtml(html, goodsId) {
  if (!html || !html.includes('sku_list')) return null

  // goods_id may be a string "goods_id":"12345" or number "goods_id":12345
  const idx = html.indexOf('"goods_id":"' + goodsId + '"') !== -1
    ? html.indexOf('"goods_id":"' + goodsId + '"')
    : html.indexOf('"goods_id":' + goodsId)
  if (idx === -1) return null

  // Walk backwards to find the JSON object start
  let depth = 0, objStart = -1
  for (let i = idx - 1; i >= Math.max(0, idx - 50000); i--) {
    const c = html[i]
    if (c === '}') depth++
    else if (c === '{') {
      if (depth === 0) { objStart = i; break }
      depth--
    }
  }
  if (objStart === -1) return null

  // Walk forwards to find matching end
  depth = 0
  let objEnd = -1
  for (let i = objStart; i < Math.min(html.length, objStart + 500000); i++) {
    const c = html[i]
    if (c === '{') depth++
    else if (c === '}') { depth--; if (depth === 0) { objEnd = i; break } }
  }
  if (objEnd === -1) return null

  try {
    const json = JSON.parse(html.slice(objStart, objEnd + 1))
    if (json.goods_id && json.sku_list) return json
    if (json.info?.goods_id && json.info?.sku_list) return json.info
  } catch {}
  return null
}

// Method 3: Browser — uses persistent context with cleared client state to force SHEIN SSR mode.
// Auto-rotates proxy when SHEIN returns captcha_type=909 (IP rate-limited).
export async function fetchViaBrowser(productUrl, _rotationCount = 0) {
  console.log(`🔍 Browser: ${productUrl}`)
  if (!_ready) await warmUpBrowser()
  const ctx = await getContext()

  const productId = productUrl.match(/-p-(\d{6,12})/)?.[1] ||
    productUrl.match(/goods_id=(\d{6,12})/)?.[1] || ''

  // Reset session to new-visitor state → SHEIN serves full SSR HTML with all product data
  await resetToFreshVisitor(ctx)

  const page = await ctx.newPage()

  try {
    // Clear localStorage before page load so SHEIN serves SSR (not SPA returning-visitor mode)
    await page.addInitScript(CLEAR_STORAGE_SCRIPT)
    await page.addInitScript(STEALTH_SCRIPT)
    await page.route(/analytics|facebook\.com\/tr|doubleclick|google-analytics|gtag\.js|googletagmanager/, r => r.abort())

    // Capture SSR HTML from the initial page HTTP response (contains full product JSON)
    let rawServerHtml = ''
    page.on('response', async (response) => {
      const url = response.url()
      if (url.includes('/product-p-') || url.includes(`-p-${productId}`)) {
        const ct = response.headers()['content-type'] || ''
        if (ct.includes('html') && response.status() === 200) {
          rawServerHtml = await response.text().catch(() => '')
        }
      }
    })

    // XHR intercept — catch complete product data if available via API call
    let xhrParsed = null
    page.on('response', async (response) => {
      if (xhrParsed) return
      const url = response.url()
      if (!url.includes('shein.com')) return
      if (!(response.headers()['content-type'] || '').includes('json')) return
      try {
        const json = await response.json()
        const parsed = parseSheinApiResponse(json)
        if (parsed?.title && parsed.priceUsd > 0 && parsed.sizes.length > 0) {
          console.log(`  → XHR API hit: ${url.substring(0, 120)}`)
          xhrParsed = parsed
        }
      } catch {}
    })

    await page.goto(productUrl, { waitUntil: 'load', timeout: 35000 }).catch(() => {})
    if (page.isClosed()) return null

    await page.waitForTimeout(xhrParsed ? 500 : 2000).catch(() => {})

    // Best case: XHR gave us complete data with sizes
    if (xhrParsed) {
      console.log(`✅ Browser XHR: ${xhrParsed.title} | $${xhrParsed.priceUsd} | colors:${xhrParsed.colors.length} sizes:${xhrParsed.sizes.length}`)
      return xhrParsed
    }

    // Primary: parse SSR HTML (populated when client-side state is cleared)
    if (rawServerHtml) {
      // Fast path: regex OG tags from SSR HTML (same approach as fetchViaContextRequest)
      const getOg = (prop) =>
        rawServerHtml.match(new RegExp(`<meta[^>]+property=["']${prop}["'][^>]+content=["']([^"']+)["']`))?.[1] ||
        rawServerHtml.match(new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+property=["']${prop}["']`))?.[1] || ''
      const ssrTitle = cleanTitle(getOg('og:title'))
      if (ssrTitle) {
        const ssrPriceStr = getOg('product:price:amount')
        const ssrCurrency = getOg('product:price:currency') || 'USD'
        const priceUsd = ssrCurrency === 'USD' ? parseFloat(ssrPriceStr) || 0 : 0
        const ssrImage = getOg('og:image')
        const imgMatches = [...rawServerHtml.matchAll(/["'](https:\/\/img\.ltwebstatic\.com\/[^"']+\.(?:jpg|webp)[^"']*)['"]/g)]
        const images = [...new Set([ssrImage, ...imgMatches.map(m => m[1])].filter(isProductImage))].slice(0, 8)
        // Try to also get sizes/colors from embedded JSON
        if (productId) {
          const ssrData = extractSkuListFromHtml(rawServerHtml, productId)
          if (ssrData) {
            const full = parseSheinApiResponse({ info: ssrData })
            if (full?.title) {
              console.log(`✅ Browser SSR full: ${full.title} | $${full.priceUsd} | colors:${full.colors.length} sizes:${full.sizes.length}`)
              return full
            }
          }
        }
        console.log(`✅ Browser SSR OG: ${ssrTitle} | $${priceUsd}`)
        return { title: ssrTitle, priceUsd, images, colors: [], sizes: [], variants: [], description: '' }
      }

      // Slow path: embedded JSON sku_list
      if (productId) {
        const ssrData = extractSkuListFromHtml(rawServerHtml, productId)
        if (ssrData) {
          const parsed = parseSheinApiResponse({ info: ssrData })
          if (parsed?.title) {
            console.log(`✅ Browser SSR JSON: ${parsed.title} | $${parsed.priceUsd} | colors:${parsed.colors.length} sizes:${parsed.sizes.length}`)
            return parsed
          }
        }
      }
    }

    // Window globals (populated during React hydration from SSR state)
    const windowData = await page.evaluate((gId) => {
      const globals = ['__NUXT__', '__INITIAL_STATE__', '__STORE_STATE__', 'gbProductData',
        'productDetailInfo', 'goodsDetailInfo', 'SHEIN_PRODUCT', '__GB_PRODUCT_INFO__']
      for (const g of globals) {
        try {
          const val = window[g]
          if (val && JSON.stringify(val).includes(gId)) return val
        } catch {}
      }
      return null
    }, productId).catch(() => null)

    if (windowData) {
      const parsed = parseSheinApiResponse(windowData)
      if (parsed?.title && parsed.sizes.length > 0) {
        console.log(`  → Window global: sizes:${parsed.sizes.length}`)
        return parsed
      }
    }

    // Wait a bit longer for JS hydration before DOM scraping
    await page.waitForSelector('h1', { timeout: 4000 }).catch(() => {})

    // DOM scraping (last resort)
    const raw = await page.evaluate(() => {
      const og = (n) => document.querySelector(`meta[property="${n}"]`)?.getAttribute('content') || ''
      const ogTitle = og('og:title')
      const ogPrice = og('product:price:amount')
      const ogCurrency = og('product:price:currency') || 'USD'
      const ogImage = og('og:image')

      // JSON-LD structured data (SHEIN embeds Product schema)
      let ldTitle = '', ldPrice = '', ldCurrency = 'USD', ldImage = ''
      for (const el of document.querySelectorAll('script[type="application/ld+json"]')) {
        try {
          const data = JSON.parse(el.textContent)
          const arr = Array.isArray(data) ? data : [data]
          const product = arr.find(d => d['@type'] === 'Product')
          if (product) {
            ldTitle = product.name || ''
            ldPrice = String(product.offers?.price || '')
            ldCurrency = product.offers?.priceCurrency || 'USD'
            ldImage = typeof product.image === 'string' ? product.image : (product.image?.[0] || '')
            break
          }
        } catch {}
      }

      // document.title fallback (SHEIN always puts product name in page title)
      const docTitle = document.title || ''

      const h1 = document.querySelector('h1,[class*="goods-name"],[class*="goodsName"],[class*="product-name"],[class*="ProductName"],[class*="detail-name"],[class*="detailName"]')?.textContent?.trim() || ''

      const imgs = [...document.querySelectorAll('img[src*="ltwebstatic"],img[src*="img.shein"],img[data-src*="ltwebstatic"]')]
        .map(i => i.src || i.getAttribute('data-src'))
        .filter(u => u && !u.includes('pwa_dist') && !u.includes('bg-logo') && !u.includes('svgicons'))

      const DATA_SIZE_PAT = /^(xxxs|xxs|xs|s|m|l|xl|2xl|3xl|4xl|5xl|6xl|7xl|xxl|xxxl|one\s*size|os|free\s*size|\d{1,3})$/i
      const sizeSet = new Set()
      for (const el of document.querySelectorAll('[data-attr-id="85"] *, [data-attr-name="size"] *')) {
        let txt = (el.getAttribute('data-attr-value') || el.getAttribute('aria-label') || el.textContent || '').trim()
        txt = txt.replace(/^size:\s*(us\s*)?/i, '').trim()
        if (DATA_SIZE_PAT.test(txt)) sizeSet.add(txt)
      }
      if (sizeSet.size === 0) {
        const LETTER_SIZE_PAT = /^(xxxs|xxs|xs|s|m|l|xl|2xl|3xl|4xl|5xl|6xl|7xl|xxl|xxxl|one\s*size|os|free\s*size)$/i
        const parentMap = new Map()
        for (const el of document.querySelectorAll('button,li,span,div,[role="button"],[tabindex="0"]')) {
          let txt = (el.getAttribute('aria-label') || el.textContent || '').trim()
          txt = txt.replace(/^size:\s*(us\s*)?/i, '').trim()
          if (!txt || txt.length > 10 || !LETTER_SIZE_PAT.test(txt)) continue
          const par = el.parentElement
          if (!par) continue
          if (!parentMap.has(par)) parentMap.set(par, [])
          if (!parentMap.get(par).includes(txt)) parentMap.get(par).push(txt)
        }
        let bestGroup = []
        for (const [, items] of parentMap) if (items.length > bestGroup.length) bestGroup = items
        if (bestGroup.length >= 2) bestGroup.forEach(s => sizeSet.add(s))
        if (sizeSet.size === 0) {
          for (const [, items] of parentMap) {
            if (items.length === 1 && /one\s*size|free\s*size|^os$/i.test(items[0])) {
              sizeSet.add(items[0]); break
            }
          }
        }
      }

      const colorSelectors = [
        '[data-attr-id="87"] [data-attr-value-id]', '[data-attr-name="color"] [data-attr-value]',
        '[class*="ColorItem"]', '[class*="colorItem"]', '[class*="color-item"]',
        '[class*="ColorSwatch"]', '[class*="colorSwatch"]', '[class*="colorBtn"]',
        '[class*="product-intro__color"] [class*="item"]', '[class*="Color"] li',
      ]
      const colorMap = new Map()
      for (const sel of colorSelectors) {
        try {
          for (const el of document.querySelectorAll(sel)) {
            const name = (el.getAttribute('aria-label') || el.getAttribute('data-color') || el.getAttribute('data-attr-value') || el.getAttribute('title') || '').trim()
            const img = el.querySelector('img')?.src || el.querySelector('img')?.getAttribute('data-src') || ''
            if (name && name.length > 0 && name.length < 30 && !colorMap.has(name)) colorMap.set(name, { name, image: img })
          }
        } catch {}
        if (colorMap.size >= 2) break
      }

      return { ogTitle, ogPrice, ogCurrency, ogImage, ldTitle, ldPrice, ldCurrency, ldImage, docTitle, h1, imgs, sizeItems: [...sizeSet], colorItems: [...colorMap.values()] }
    })

    const title = cleanTitle(raw.ogTitle || raw.ldTitle || raw.h1 || raw.docTitle)
    if (!title) {
      const finalUrl = page.url()
      const pageTitle = await page.title().catch(() => '?')
      console.log(`⚠️ No product data found in browser (url=${finalUrl.substring(0,80)} title="${pageTitle}")`)
      // captcha_type=909 or chrome-error = IP blocked → rotate to next proxy and retry
      const maxRotations = Math.max(1, _proxyList.length - 1)
      const isBlocked = finalUrl.includes('captcha_type=909') || finalUrl.startsWith('chrome-error://')
      if (isBlocked && _rotationCount < maxRotations) {
        await page.close().catch(() => {})
        const rotated = await rotateProxyAndRestart()
        if (rotated) return fetchViaBrowser(productUrl, _rotationCount + 1)
      }
      return null
    }

    const priceStr = raw.ogPrice || raw.ldPrice || ''
    const currency = (raw.ogPrice ? raw.ogCurrency : raw.ldCurrency) || 'USD'
    const priceUsd = currency === 'USD' ? parseFloat(priceStr) || 0 : 0
    const images = [...new Set([raw.ogImage, raw.ldImage, ...raw.imgs].filter(isProductImage))].slice(0, 8)
    const colors = raw.colorItems.map(c => ({ id: c.name, name: c.name, image: c.image, available: true }))
    const sizes = raw.sizeItems.map(s => ({ id: s, name: s, available: true }))

    console.log(`✅ Browser DOM: ${title} | $${priceUsd} | colors:${colors.length} sizes:${sizes.length}`)
    return { title, priceUsd, images, colors, sizes, variants: [], description: '' }
  } finally {
    await page.close().catch(() => {})
  }
}

// Method 4: Apify seamless_coffer/shein-product-scraper (final fallback)
// Accepts a direct product URL and returns title, USD price, sizes, colors, images.
export async function fetchViaApify(productUrl) {
  const token = process.env.APIFY_TOKEN
  if (!token) return null

  console.log(`🤖 Trying Apify for ${productUrl}`)
  const actorId = process.env.APIFY_ACTOR || 'seamless_coffer~shein-product-scraper'

  try {
    const res = await fetch(
      `https://api.apify.com/v2/acts/${actorId}/run-sync-get-dataset-items?token=${token}&timeout=60`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          urls: [productUrl],
          useProxy: true,
          country: 'US',
          maxRetries: 3,
          timeout: 30,
        }),
        signal: AbortSignal.timeout(90000),
      }
    )

    if (!res.ok) {
      const errText = await res.text().catch(() => '')
      console.log(`  → Apify API error: ${res.status} ${errText.slice(0, 120)}`)
      return null
    }

    const items = await res.json()
    const item = Array.isArray(items) ? items[0] : null
    if (!item?.title) { console.log(`  → Apify: no data returned`); return null }

    const title = cleanTitle(item.title)
    if (!title) return null

    // Use USD sale price, fall back to retail price
    const priceUsd = item.sale_price?.usd_amount || item.retail_price?.usd_amount || 0

    const allImages = [item.main_image, ...(item.images || [])].filter(Boolean).filter(isProductImage)
    const uniqueImages = [...new Set(allImages)].slice(0, 8)

    const sizes = (item.sizes || []).map(s => ({
      id: s.attr_value_name || s.name || '',
      name: s.attr_value_name || s.name || '',
      available: !s.is_sold_out,
    })).filter(s => s.name)

    const colors = item.color
      ? [{ id: item.color, name: item.color, image: '', available: true }]
      : []

    console.log(`✅ Apify: ${title} | $${priceUsd} | sizes:${sizes.length} colors:${colors.length}`)
    return { title, priceUsd, images: uniqueImages, colors, sizes, variants: [], description: '' }
  } catch (e) {
    console.log(`  → Apify error: ${e.message}`)
    return null
  }
}

// Resolve sharing URL — tries HTTP first (fast), browser as fallback
export async function resolveShareUrl(shareUrl) {
  console.log('🔗 Resolving share URL...')

  // Step 1: HTTP fetch — follow redirects and also scan HTML for goods_id
  try {
    const res = await fetch(shareUrl, {
      headers: { 'User-Agent': USER_AGENT, 'Accept': 'text/html,*/*' },
      redirect: 'follow',
      signal: AbortSignal.timeout(8000),
    })
    const finalUrl = res.url
    if (finalUrl !== shareUrl && (/-p-\d{6,12}/.test(finalUrl) || /goods_id=\d{6,12}/.test(finalUrl))) {
      console.log(`✅ Resolved via HTTP redirect: ${finalUrl.substring(0, 80)}`)
      return finalUrl
    }
    try {
      const parsed = new URL(finalUrl)
      const urlParam = parsed.searchParams.get('url') || parsed.searchParams.get('productUrl')
      if (urlParam) {
        const decoded = decodeURIComponent(urlParam)
        if (/-p-\d{6,12}/.test(decoded) || /goods_id=\d{6,12}/.test(decoded)) {
          console.log(`✅ Resolved from URL param: ${decoded.substring(0, 80)}`)
          return decoded
        }
      }
    } catch {}
    // Also scan the HTML body — H5 sharing pages embed goods_id in script tags
    try {
      const html = await res.text()
      const m = html.match(/"goods_id"\s*[:\s"]+(\d{6,12})/) ||
                html.match(/goods_id[=:](\d{6,12})/) ||
                html.match(/"goodsId"\s*[:\s"]+(\d{6,12})/)
      if (m) {
        const found = `https://m.shein.com/us/product-p-${m[1]}.html`
        console.log(`✅ Resolved from HTTP HTML (goods_id=${m[1]})`)
        return found
      }
    } catch {}
  } catch (e) {
    console.log(`  → HTTP resolve failed: ${e.message}`)
  }

  // Step 2: Browser fallback — load sharing page and capture navigation
  // IMPORTANT: We abort any navigation to m.shein.com/product pages to prevent SHEIN's
  // anti-bot (captcha_type=909) from flagging our IP. We only need the goods_id, not the page.
  if (!_ready) await warmUpBrowser()
  const ctx = await getContext()
  const page = await ctx.newPage()
  let handlersDone = false

  try {
    await page.addInitScript(STEALTH_SCRIPT)

    let resolved = null
    const captureUrl = (u) => {
      if (resolved || handlersDone || !u) return
      const m = u.match(/goods_id[=:](\d{6,12})/) || u.match(/-p-(\d{6,12})/)
      if (m) resolved = `https://m.shein.com/us/product-p-${m[1]}.html`
    }

    // Block navigation to product pages — we only want the goods_id, not the actual product page.
    // Loading m.shein.com/product in the same session as the share page triggers anti-bot.
    await page.route('**', async (route) => {
      const url = route.request().url()
      const type = route.request().resourceType()

      // Abort heavy/unnecessary resources
      if (['image', 'media', 'font', 'stylesheet'].includes(type)) {
        await route.abort(); return
      }
      // Abort navigation to product pages (we only need goods_id, not to load the page)
      if (url.match(/m\.shein\.com.*\/product-p-/) || url.match(/shein\.com.*-p-\d{6,12}/)) {
        captureUrl(url)
        await route.abort(); return
      }
      await route.continue()
    })

    page.on('request', req => captureUrl(req.url()))
    page.on('framenavigated', frame => captureUrl(frame.url()))

    // Parse any SHEIN response (JSON or HTML) for goods_id
    page.on('response', async (response) => {
      if (resolved || handlersDone) return
      const u = response.url()
      if (!u.includes('shein')) return
      const ct = response.headers()['content-type'] || ''
      if (!ct.includes('json') && !ct.includes('html') && !ct.includes('text')) return
      try {
        const text = await response.text()
        if (handlersDone) return
        const m = text.match(/"goods_id"\s*[:\s"]+(\d{6,12})/) ||
                  text.match(/goods_id[=:](\d{6,12})/) ||
                  text.match(/"goodsId"\s*[:\s"]+(\d{6,12})/)
        if (m) resolved = `https://m.shein.com/us/product-p-${m[1]}.html`
      } catch {}
    })

    await page.goto(shareUrl, { waitUntil: 'commit', timeout: 12000 }).catch(() => {})
    await page.waitForTimeout(4000).catch(() => {})
    if (!resolved) captureUrl(page.url())

    // Final attempt: scan full page HTML for goods_id
    if (!resolved) {
      try {
        const html = await page.content()
        const m = html.match(/"goods_id"\s*[:\s"]+(\d{6,12})/) ||
                  html.match(/goods_id[=:](\d{6,12})/) ||
                  html.match(/"goodsId"\s*[:\s"]+(\d{6,12})/)
        if (m) resolved = `https://m.shein.com/us/product-p-${m[1]}.html`
      } catch {}
    }

    const found = resolved
    if (found) {
      console.log(`✅ Resolved via browser: ${found.substring(0, 80)}`)
      return found
    }
    return null
  } catch (e) {
    console.log(`  → Browser resolve failed: ${e.message}`)
    return null
  } finally {
    handlersDone = true
    await page.close().catch(() => {})
  }
}
