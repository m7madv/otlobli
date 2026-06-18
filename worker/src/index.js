/**
 * Cloudflare Worker — SHEIN Product Fetcher
 * Replaces Railway scraper for HTTP-based fetching (no browser needed).
 * Runs at Cloudflare edge: ~1-3s response vs 25s with Playwright.
 */

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
}

const MOBILE_UA = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.76 Mobile Safari/537.36'
const FB_UA = 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)'

// ──────────────────────────────────────────────
// URL helpers
// ──────────────────────────────────────────────

function isSheinUrl(url) {
  try { return new URL(url).hostname.includes('shein') } catch { return false }
}

function extractProductId(url) {
  const patterns = [
    /-p-(\d{6,12})(?:[-.]|$)/i,
    /[?&]goods_id=(\d{6,12})/i,
    /[?&]product_id=(\d{6,12})/i,
    /\/(\d{6,12})\.html/i,
    /\/p\/(\d{6,12})/i,
    /-(\d{8,12})(?:-cat|-p|\.html)/i,
  ]
  for (const src of [url, decodeURIComponent(url)]) {
    for (const p of patterns) {
      const m = src.match(p)
      if (m?.[1]) return m[1]
    }
  }
  return null
}

function isSharingUrl(url) {
  return url.includes('api-shein.shein.com') || url.includes('/sharejump/') || url.includes('/h5/share')
}

// ──────────────────────────────────────────────
// Parsers
// ──────────────────────────────────────────────

function cleanTitle(raw = '') {
  return raw
    .replace(/<[^>]*>/g, '')
    .replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&quot;/g, '"')
    .replace(/\s*\|\s*SHEIN.*/i, '').replace(/\s*-\s*SHEIN.*/i, '')
    .trim()
}

function parsePrice(val) {
  if (typeof val === 'number') return val
  return parseFloat(String(val || '').replace(/[^0-9.]/g, '')) || 0
}

function isProductImage(url) {
  if (!url || typeof url !== 'string') return false
  if (url.endsWith('.svg')) return false
  if (url.includes('svgicons') || url.includes('bg-logo') || url.includes('pwa_dist')) return false
  return url.includes('ltwebstatic') || url.includes('img.shein')
}

function parseApiJson(json) {
  const info = json?.info || json?.data?.info || json?.data?.detail || json?.data
  if (!info) return null

  const title = cleanTitle(info.goods_name || info.title || '')
  if (!title) return null

  // Reject non-USD prices (regional pricing)
  const currency = info.sale_price?.currency || info.salePrice?.currency ||
    info.retailPrice?.currency || info.currency || 'USD'
  if (currency && currency !== 'USD') return null

  const priceUsd = parsePrice(
    info.sale_price?.amount || info.salePrice?.amount ||
    info.sell_price || info.retailPrice?.amount || info.price || 0
  )

  // Images
  const imgs = []
  for (const img of (info.goods_imgs?.main_image_list || [])) {
    const u = typeof img === 'string' ? img : (img?.origin_image || img?.url || '')
    if (isProductImage(u)) imgs.push(u)
  }

  // SKU variants → colors + sizes
  const colorImgMap = {}
  for (const c of (info.color_image || info.color_imgs || [])) {
    if (c?.color_name) colorImgMap[c.color_name] = c.color_image || c.image || ''
  }

  const colorsMap = new Map()
  const sizesMap = new Map()
  const variants = []

  for (const sku of (info.sku_list || info.multiPropertyList || [])) {
    const attrs = sku?.sku_sale_attr || sku?.sale_attr || []
    let colorId = '', colorName = '', sizeId = '', sizeName = ''
    const stock = parseInt(sku?.stock ?? sku?.stockNum ?? '0') || 0

    for (const attr of attrs) {
      const name = (attr?.attr_name || '').toLowerCase()
      const id = String(attr?.attr_value_id || attr?.attr_id || '')
      const val = attr?.attr_value || attr?.attr_value_name || ''
      if (name === 'color' || attr?.attr_id === 87) { colorId = id; colorName = val }
      else if (name === 'size' || attr?.attr_id === 85) { sizeId = id; sizeName = val }
    }

    if (colorName && !colorsMap.has(colorId)) {
      colorsMap.set(colorId, { id: colorId || colorName, name: colorName, image: colorImgMap[colorName] || '', available: false })
    }
    if (sizeName && !sizesMap.has(sizeId)) {
      sizesMap.set(sizeId, { id: sizeId || sizeName, name: sizeName, available: false })
    }
    if (stock > 0) {
      if (colorName) { const c = colorsMap.get(colorId); if (c) c.available = true }
      if (sizeName) { const s = sizesMap.get(sizeId); if (s) s.available = true }
    }
    variants.push({
      colorId: colorId || null, colorName: colorName || null,
      sizeId: sizeId || null, sizeName: sizeName || null,
      available: stock > 0, stock: stock || undefined,
    })
  }

  return {
    title, priceUsd, images: imgs.slice(0, 10),
    colors: [...colorsMap.values()],
    sizes: [...sizesMap.values()],
    variants,
  }
}

function parseHtml(html) {
  const og = (prop) => {
    const m = html.match(new RegExp(`<meta[^>]+property=["']${prop}["'][^>]+content=["']([^"']+)["']`)) ||
              html.match(new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+property=["']${prop}["']`))
    return m?.[1] || ''
  }
  const title = cleanTitle(og('og:title'))
  if (!title) return null

  const priceStr = og('product:price:amount')
  const currency = og('product:price:currency') || 'USD'
  const rawPrice = parsePrice(priceStr)

  // Convert non-USD prices to USD so frontend can work with them
  const USD_RATES = { AED: 0.2723, SAR: 0.2667, QAR: 0.2747, KWD: 3.26, EGP: 0.0204, GBP: 1.27, EUR: 1.09 }
  const priceUsd = currency === 'USD' ? rawPrice
    : (USD_RATES[currency] ? Math.round(rawPrice * USD_RATES[currency] * 100) / 100 : 0)

  const ogImage = og('og:image')
  const imgMatches = [...html.matchAll(/["'](https:\/\/img\.ltwebstatic\.com\/[^"']+\.(?:jpg|webp)[^"']*)['"]/g)]
  const images = [...new Set([ogImage, ...imgMatches.map(m => m[1])].filter(isProductImage))].slice(0, 10)

  return { title, priceUsd, currency, images, colors: [], sizes: [], variants: [] }
}

// Standard clothing size sort order
const SIZE_ORDER = ['XXXS','XXS','XS','S','M','L','XL','XXL','2XL','3XL','XXXL','4XL','5XL','6XL',
  'ONE SIZE','OS','FREE SIZE','34','35','36','37','38','39','40','41','42','43','44','45','46',
  '0','2','4','6','8','10','12','14','16','18','20','22','24','26','28','30','32']
const NON_SIZE_RE = /^(men|women|kids|baby|girls|boys|plus|petite|regular|tall|curve|maternity)\b/i

function normalizeSizes(sizes) {
  const filtered = sizes.filter(s => {
    const n = s.name || s
    return n && n.length <= 12 && !NON_SIZE_RE.test(n.trim())
  })
  return filtered.sort((a, b) => {
    const ai = SIZE_ORDER.indexOf((a.name || a).toUpperCase().trim())
    const bi = SIZE_ORDER.indexOf((b.name || b).toUpperCase().trim())
    return (ai === -1 ? 999 : ai) - (bi === -1 ? 999 : bi)
  })
}

// ──────────────────────────────────────────────
// Fetch methods
// ──────────────────────────────────────────────

async function fetchViaApi(goodsId) {
  const endpoints = [
    `https://m.shein.com/us/product/index.json?goods_id=${goodsId}&cat_id=0&currency=USD`,
    `https://us.shein.com/product/index.json?goods_id=${goodsId}&cat_id=0`,
  ]
  const headers = {
    'User-Agent': MOBILE_UA,
    'Accept': 'application/json',
    'Referer': 'https://m.shein.com/us/',
    'Cookie': 'currency=USD; cookieCurrency=USD',
  }
  for (const url of endpoints) {
    try {
      const res = await fetch(url, { headers })
      if (!res.ok) continue
      const json = await res.json()
      const parsed = parseApiJson(json)
      if (parsed?.title && parsed.priceUsd > 0) return parsed
    } catch {}
  }
  return null
}

async function fetchViaHtml(productUrl) {
  const attempts = [
    { ua: FB_UA, cookie: 'currency=USD; cookieCurrency=USD' },
    { ua: 'Googlebot/2.1 (+http://www.google.com/bot.html)', cookie: 'currency=USD' },
    { ua: MOBILE_UA, cookie: 'currency=USD; cookieCurrency=USD; region=US' },
  ]
  for (const { ua, cookie } of attempts) {
    try {
      const res = await fetch(productUrl, {
        headers: {
          'User-Agent': ua,
          'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate',
          'Cookie': cookie,
          'Referer': 'https://www.google.com/',
          'Cache-Control': 'no-cache',
        },
      })
      if (!res.ok) continue
      const html = await res.text()
      if (html.length < 500) continue // blocked/empty response
      const parsed = parseHtml(html)
      if (parsed?.title) return parsed
    } catch {}
  }
  return null
}

// Resolve sharing URL by following redirect chain
async function resolveShareUrl(shareUrl) {
  try {
    const res = await fetch(shareUrl, {
      headers: { 'User-Agent': MOBILE_UA },
      redirect: 'follow',
    })
    return res.url !== shareUrl ? res.url : null
  } catch {
    return null
  }
}

// ──────────────────────────────────────────────
// Main handler
// ──────────────────────────────────────────────

async function handleImport(rawUrl) {
  if (!rawUrl || !isSheinUrl(rawUrl.trim())) {
    return { error: 'INVALID_SHEIN_URL', message: 'الرابط ليس رابط Shein صحيح' }
  }

  let resolvedUrl = rawUrl.trim()

  // Sharing URLs need redirect resolution first
  if (isSharingUrl(rawUrl)) {
    const resolved = await resolveShareUrl(rawUrl)
    if (resolved) resolvedUrl = resolved
  }

  const productId = extractProductId(resolvedUrl) || extractProductId(rawUrl)
  if (!productId) {
    return { error: 'PRODUCT_ID_NOT_FOUND', message: 'لم نتمكن من استخراج معرّف المنتج من الرابط' }
  }

  // Always fetch from m.shein.com/us for USD pricing
  const productUrl = `https://m.shein.com/us/product-p-${productId}.html?ref=m&rep=dir&ret=mus`

  // Try API first (has full variant data), then HTML fallback
  let parsed = await fetchViaApi(productId)
  if (!parsed) parsed = await fetchViaHtml(productUrl)

  if (!parsed?.title) {
    return { error: 'FETCH_FAILED', message: 'فشل جلب بيانات المنتج من Shein' }
  }

  const product = {
    id: `shein-${productId}`,
    source: 'shein',
    sourceProductId: productId,
    originalUrl: rawUrl,
    title: parsed.title,
    images: parsed.images,
    price: { usd: parsed.priceUsd, syp: 0, currency: 'USD', exchangeRate: 0 },
    colors: parsed.colors,
    sizes: normalizeSizes(parsed.sizes),
    variants: parsed.variants,
    availability: parsed.variants.length === 0 ? 'unknown'
      : parsed.variants.every(v => v.available) ? 'in_stock'
      : parsed.variants.some(v => v.available) ? 'partial'
      : 'out_of_stock',
    temporary: true,
    importedAt: new Date().toISOString(),
    tempId: `tmp-${productId}-${Date.now()}`,
  }

  return { product }
}

// ──────────────────────────────────────────────
// Live-browsing relay (lets the in-app browser reach shein.com from
// Cloudflare's network instead of the device's own — the device's IP is
// what gets geo-blocked, not Cloudflare's). Forwards the request as-is and
// streams the response back unmodified; no content rewriting.
// ──────────────────────────────────────────────

const RELAY_REQUEST_HEADER_BLOCKLIST = new Set(['host', 'x-relay-key', 'x-relay-url', 'cf-connecting-ip', 'cf-ray', 'cf-visitor'])

async function handleRelay(request, env) {
  const relayKey = request.headers.get('X-Relay-Key')
  if (!env.RELAY_SECRET || relayKey !== env.RELAY_SECRET) {
    return new Response('Forbidden', { status: 403 })
  }

  // Not restricted to shein.com hostnames: the page pulls sub-resources
  // (images, fonts, analytics) from CDN domains that don't contain "shein"
  // in the name. The shared secret above is the actual access control here.
  const targetUrl = request.headers.get('X-Relay-Url')
  let parsedTarget
  try {
    parsedTarget = new URL(targetUrl)
    if (parsedTarget.protocol !== 'https:' && parsedTarget.protocol !== 'http:') throw new Error('bad scheme')
  } catch {
    return new Response('Bad target', { status: 400 })
  }

  const forwardHeaders = new Headers()
  for (const [name, value] of request.headers) {
    if (!RELAY_REQUEST_HEADER_BLOCKLIST.has(name.toLowerCase())) forwardHeaders.set(name, value)
  }

  const hasBody = request.method !== 'GET' && request.method !== 'HEAD'
  // Buffered (not streamed) only because a retry needs to resend it - bodies
  // on these calls are small (form posts/JSON), never image/page-sized.
  const bodyBuffer = hasBody ? await request.arrayBuffer() : undefined

  const fetchUpstream = () =>
    fetch(parsedTarget.toString(), {
      method: request.method,
      headers: forwardHeaders,
      body: bodyBuffer,
      // Resolve redirects ourselves: the client needs the real absolute
      // shein.com Location to keep following the chain in its own origin,
      // not have Cloudflare quietly follow it and hand back unrelated content.
      redirect: 'manual',
    })

  // shein.com's own WAF occasionally 403s a request that would otherwise
  // succeed (observed in testing: same URL, same headers, succeeds on the
  // very next attempt) - this is what otlobli's bottom nav rendered over a
  // "GSRM Security" block page instead of the real homepage. Cloudflare
  // Workers' egress isn't a single fixed IP, so a fresh attempt plausibly
  // routes differently. Retry a couple of times before giving up.
  const MAX_ATTEMPTS = 3
  let upstreamResponse
  let consumedBodyText // set only when we had to read the body to decide whether to retry
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    upstreamResponse = await fetchUpstream()
    if (upstreamResponse.status !== 403) {
      consumedBodyText = undefined
      break
    }
    consumedBodyText = await upstreamResponse.text()
    if (!/gsrm|security/i.test(consumedBodyText) || attempt === MAX_ATTEMPTS) break
    await new Promise((resolve) => setTimeout(resolve, 250 * attempt))
  }

  const responseHeaders = new Headers(upstreamResponse.headers)
  responseHeaders.delete('content-security-policy')
  responseHeaders.delete('content-security-policy-report-only')

  const location = responseHeaders.get('location')
  if (location) {
    try {
      responseHeaders.set('location', new URL(location, parsedTarget).toString())
    } catch { /* leave as-is if unparseable */ }
  }

  // consumedBodyText is set when the body was already read to decide whether
  // to retry (the underlying stream is spent at that point) - reuse the text
  // instead of trying to read upstreamResponse.body again.
  const responseBody = consumedBodyText !== undefined ? consumedBodyText : upstreamResponse.body
  return new Response(responseBody, { status: upstreamResponse.status, headers: responseHeaders })
}

// ──────────────────────────────────────────────
// Worker entry point
// ──────────────────────────────────────────────

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url)

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS })
    }

    // Health check
    if (url.pathname === '/health' || url.pathname === '/') {
      return Response.json({ status: 'ok', service: 'talabieh-shein-worker' }, { headers: CORS_HEADERS })
    }

    if (url.pathname === '/relay') {
      return handleRelay(request, env)
    }

    // Main import endpoint
    if (url.pathname === '/api/shein/import' && request.method === 'POST') {
      try {
        const body = await request.json()
        const result = await handleImport(body?.url || '')

        if (result.error) {
          return Response.json({ success: false, error: result }, { status: 422, headers: CORS_HEADERS })
        }
        return Response.json({ success: true, product: result.product }, { headers: CORS_HEADERS })
      } catch (e) {
        return Response.json(
          { success: false, error: { code: 'INTERNAL_ERROR', message: e.message } },
          { status: 500, headers: CORS_HEADERS }
        )
      }
    }

    return new Response('Not Found', { status: 404, headers: CORS_HEADERS })
  },
}
