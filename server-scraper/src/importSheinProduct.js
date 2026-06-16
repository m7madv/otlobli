import { SheinImportError } from './sheinErrors.js'
import { normalizeSheinUrl, isSheinUrl } from './normalizeSheinUrl.js'
import { extractSheinProductId } from './extractSheinProductId.js'
import { warmUpBrowser, fetchViaApi, fetchViaContextRequest, fetchViaApiWithCookies, fetchViaHttp, fetchViaBrowser, fetchViaApify, fetchViaScraperApi, resolveShareUrl, resetBrowserToUsd, restartBrowser, rotateProxyAndRestart } from './fetchSheinData.js'
import { saveTempProduct, cleanupExpiredTempProducts } from './tempProductStore.js'

// Simple in-memory cache (productId → parsed data, TTL 30 min)
const cache = new Map()
const CACHE_TTL = 30 * 60 * 1000

function cacheGet(key) {
  const e = cache.get(key)
  if (!e) return null
  if (Date.now() - e.ts > CACHE_TTL) { cache.delete(key); return null }
  return e.data
}
function cacheSet(key, data) { cache.set(key, { data, ts: Date.now() }) }

function isSharingUrl(url) {
  return url.includes('api-shein.shein.com') || url.includes('/sharejump/') || url.includes('/h5/share')
}

export async function importSheinProduct(rawUrl) {
  console.log(`\n📦 Import request: ${rawUrl}`)

  // 1. Validate
  if (!rawUrl || !rawUrl.includes('shein')) {
    throw new SheinImportError('INVALID_SHEIN_URL', { url: rawUrl })
  }

  // 2. Validate it's a Shein URL
  if (!isSheinUrl(rawUrl.trim())) {
    throw new SheinImportError('INVALID_SHEIN_URL', { url: rawUrl })
  }

  // 3. Resolve sharing URLs BEFORE normalizing (they need their query params)
  let resolvedUrl = rawUrl.trim()
  let normalizedUrl = rawUrl.trim()
  let sharingRegionCode = ''  // e.g. "QA" from localcountry=QA

  if (isSharingUrl(rawUrl)) {
    // Extract regional hint from sharing URL (e.g. localcountry=QA)
    try {
      const sharingParsed = new URL(rawUrl.trim())
      sharingRegionCode = (sharingParsed.searchParams.get('localcountry') || '').toUpperCase()
    } catch {}

    await warmUpBrowser()
    const resolved = await resolveShareUrl(normalizedUrl).catch((e) => {
      console.log(`⚠️ Share resolve failed: ${e.message}`)
      return null
    })
    if (resolved) {
      resolvedUrl = resolved
      console.log(`🔗 Resolved share to: ${resolvedUrl}`)
    }
    // Restart browser: sharing pages trigger SHEIN anti-bot (captcha_type=909).
    // A fresh session avoids the risk/challenge redirect on the product page.
    await restartBrowser()
  } else {
    // Normalize non-sharing product URLs (remove tracking params)
    try { normalizedUrl = normalizeSheinUrl(rawUrl) } catch {}
    resolvedUrl = normalizedUrl
  }

  console.log(`🔗 Resolved URL: ${resolvedUrl}`)

  // 4. Extract product ID (try raw URL, resolved URL, and decoded)
  const productId = extractSheinProductId(resolvedUrl) ||
    extractSheinProductId(decodeURIComponent(resolvedUrl)) ||
    extractSheinProductId(rawUrl)
  if (!productId) {
    throw new SheinImportError('PRODUCT_ID_NOT_FOUND', { url: resolvedUrl })
  }
  console.log(`🆔 Product ID: ${productId}`)

  // 5. Cache check
  const cached = cacheGet(productId)
  if (cached) {
    console.log(`⚡ Cache hit for ${productId}`)
    cleanupExpiredTempProducts()
    return saveTempProduct(cached)
  }

  // 6. Choose regional store based on sharing URL country (affects price + availability)
  const regionStores = {
    QA: 'ar', AE: 'ar', SA: 'ar', KW: 'ar', BH: 'ar', OM: 'ar',
    JO: 'ar', SY: 'ar', IQ: 'ar', LB: 'ar', EG: 'ar', MA: 'ar',
    DZ: 'ar', TN: 'ar', LY: 'ar', YE: 'ar', SD: 'ar',
    TR: 'tr', DE: 'de', FR: 'fr', GB: 'uk', AU: 'au', NZ: 'au',
  }
  const regionSub = sharingRegionCode ? (regionStores[sharingRegionCode] || null) : null
  const productUrl = regionSub
    ? `https://${regionSub}.shein.com/product-p-${productId}.html`
    : `https://m.shein.com/us/product-p-${productId}.html?ref=m&rep=dir&ret=mus`
  console.log(`🌍 Store: ${regionSub ? regionSub + '.shein.com' : 'm.shein.com/us'} (region=${sharingRegionCode || 'US'})`)

  // 7. Fetch data: API first → context.request → Browser
  await warmUpBrowser()

  let parsed = null

  // Fast path: proxy-based methods (return in ~5-10s when IP is fresh)
  console.log(`🔌 Trying API for goods_id=${productId}...`)
  parsed = await fetchViaApi(productId)

  if (!parsed) {
    console.log(`🔌 Trying context.request (proxy + cf_clearance)...`)
    parsed = await fetchViaContextRequest(productId, productUrl)
  }

  if (!parsed) {
    console.log(`🔌 Trying API with browser cookies...`)
    parsed = await fetchViaApiWithCookies(productId)
  }

  // Slow path: full browser (30-40s but extracts sizes/colors)
  if (!parsed) {
    console.log(`🖥️ Trying browser fetch...`)
    parsed = await fetchViaBrowser(productUrl)
  }

  // Last resort: ScraperAPI (30s timeout, might be blocked by SHEIN)
  if (!parsed) {
    console.log(`🕷️ Trying ScraperAPI...`)
    parsed = await fetchViaScraperApi(productUrl, productId)
  }

  // If m.shein.com/us is blocked or product not in US store, try alternatives
  if (!parsed && !rawUrl.includes('m.shein.com/us')) {
    if (isSharingUrl(rawUrl)) {
      // Sharing URLs may be from regional stores (Qatar, etc.) — try global and regional
      const globalUrl = `https://m.shein.com/product-p-${productId}.html`
      console.log(`🖥️ Retrying browser on global URL: ${globalUrl}`)
      parsed = await fetchViaBrowser(globalUrl)

      if (!parsed && sharingRegionCode) {
        // Map common country codes to SHEIN store subdomains
        const regionStores = { QA: 'ar', AE: 'ar', SA: 'ar', KW: 'ar', BH: 'ar', OM: 'ar',
          TR: 'tr', DE: 'de', FR: 'fr', GB: 'uk', AU: 'au', NZ: 'au' }
        const sub = regionStores[sharingRegionCode]
        if (sub) {
          const regionalUrl = `https://${sub}.shein.com/product-p-${productId}.html`
          console.log(`🖥️ Retrying browser on regional URL (${sharingRegionCode}): ${regionalUrl}`)
          parsed = await fetchViaBrowser(regionalUrl)
        }
      }
    } else {
      console.log(`🖥️ Retrying browser on original URL: ${resolvedUrl}`)
      parsed = await fetchViaBrowser(resolvedUrl)
    }
  }

  // Final fallback: Apify (managed browser, residential IPs)
  if (!parsed) {
    console.log(`🤖 All local methods failed — trying Apify...`)
    parsed = await fetchViaApify(productUrl)
  }

  if (!parsed) {
    throw new SheinImportError('FETCH_FAILED', { productId, url: productUrl })
  }

  if (!parsed.title) {
    throw new SheinImportError('PRODUCT_PARSE_FAILED', { productId })
  }

  if (!parsed.priceUsd || parsed.priceUsd <= 0) {
    throw new SheinImportError('PRICE_NOT_FOUND', { productId, title: parsed.title })
  }

  console.log(`📊 title="${parsed.title}" price=$${parsed.priceUsd} colors=${parsed.colors.length} sizes=${parsed.sizes.length} variants=${parsed.variants.length}`)

  // 8. Map to ImportedSheinProduct (exchange rate applied by frontend)
  const product = {
    id: `shein-${productId}`,
    source: 'shein',
    sourceProductId: productId,
    originalUrl: rawUrl,
    normalizedUrl: normalizedUrl,
    title: parsed.title,
    description: parsed.description || undefined,
    images: parsed.images,
    price: {
      usd: parsed.priceUsd,
      syp: 0, // frontend will compute with live rate
      currency: 'USD',
      exchangeRate: 0, // frontend fills this
    },
    colors: parsed.colors.length > 0 ? parsed.colors : [],
    sizes: parsed.sizes.length > 0 ? normalizeSizes(parsed.sizes) : [],
    variants: parsed.variants,
    availability: computeAvailability(parsed),
    temporary: true,
    importedAt: new Date().toISOString(),
  }

  cacheSet(productId, product)
  cleanupExpiredTempProducts()

  const saved = saveTempProduct(product)
  console.log(`✅ Done: ${product.title}`)
  return saved
}

function computeAvailability(parsed) {
  if (parsed.variants.length === 0) return 'unknown'
  const hasAvailable = parsed.variants.some(v => v.available)
  const allAvailable = parsed.variants.every(v => v.available)
  if (allAvailable) return 'in_stock'
  if (hasAvailable) return 'partial'
  return 'out_of_stock'
}

// Standard clothing size order
const SIZE_ORDER = ['XXXS','XXS','XS','S','M','L','XL','XXL','2XL','3XL','XXXL','4XL','5XL','6XL',
  'ONE SIZE','OS','FREE SIZE', '34','35','36','37','38','39','40','41','42','43','44','45','46',
  '0','2','4','6','8','10','12','14','16','18','20','22','24','26','28','30','32']

// Category names and other non-size labels to filter out
const NON_SIZE_RE = /^(men|women|kids|baby|girls|boys|plus|petite|regular|tall|curve|maternity)\b/i
const NON_SIZE_STARTS = ['size:', 'color:', 'colour:', 'size guide', 'chart', 'fit:']

function cleanSizeName(raw) {
  // Strip "Size: US " or "Size: " prefix that SHEIN uses in aria-labels
  return raw.trim()
    .replace(/^size:\s*(us\s*)?/i, '')
    .replace(/\s*\(.*?\)$/, '') // remove suffix like "(S)" or "(XL)"
    .trim()
}

function normalizeSizes(sizes) {
  // Filter obvious non-sizes
  const seen = new Set()
  const filtered = sizes.reduce((acc, s) => {
    const rawName = typeof s === 'string' ? s : s.name
    if (!rawName) return acc
    const name = cleanSizeName(rawName)
    if (!name || name.length > 10) return acc
    const lower = name.toLowerCase()
    if (NON_SIZE_STARTS.some(p => lower.startsWith(p))) return acc
    if (NON_SIZE_RE.test(lower)) return acc
    if (/^[a-z\s]{6,}$/.test(lower)) return acc // long lowercase-only = label
    if (seen.has(name)) return acc
    seen.add(name)
    const obj = typeof s === 'string' ? { id: name, name, available: true } : { ...s, name }
    acc.push(obj)
    return acc
  }, [])

  // Sort by standard order
  const orderOf = (s) => {
    const name = (typeof s === 'string' ? s : s.name).toUpperCase().trim()
    const idx = SIZE_ORDER.indexOf(name)
    return idx >= 0 ? idx : 999
  }
  return filtered.sort((a, b) => orderOf(a) - orderOf(b))
}
