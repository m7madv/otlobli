function cleanTitle(raw = '') {
  return raw
    .replace(/<[^>]*>/g, '')
    .replace(/&#39;/g, "'").replace(/&amp;/g, '&').replace(/&quot;/g, '"')
    .replace(/\s*\|\s*SHEIN.*/i, '').replace(/\s*-\s*SHEIN.*/i, '')
    .trim()
}

export function isProductImage(url) {
  if (!url || typeof url !== 'string') return false
  if (url.endsWith('.svg')) return false
  if (url.includes('svgicons') || url.includes('bg-logo') || url.includes('pwa_dist')) return false
  return url.includes('ltwebstatic') || url.includes('img.shein')
}

function parsePrice(val) {
  if (typeof val === 'number') return val
  if (!val) return 0
  return parseFloat(String(val).replace(/[^0-9.]/g, '')) || 0
}

function extractImages(info) {
  const imgs = []
  const main = info?.goods_imgs?.main_image_list || []
  for (const img of main) {
    const u = typeof img === 'string' ? img : (img?.origin_image || img?.url || '')
    if (isProductImage(u)) imgs.push(u)
  }
  // fallback: goods_img array
  const arr = info?.goods_img || []
  for (const img of arr) {
    const u = typeof img === 'string' ? img : (img?.url || '')
    if (isProductImage(u) && !imgs.includes(u)) imgs.push(u)
  }
  return imgs.slice(0, 10)
}

function extractSku(info) {
  // sku_list is the full variant matrix
  const rawSkus = info?.sku_list || info?.multiPropertyList || []

  const colors = new Map()
  const sizes = new Map()
  const variants = []

  // color images from color_image or color_imgs
  const colorImgMap = {}
  const colorImgList = info?.color_image || info?.color_imgs || []
  for (const c of colorImgList) {
    const name = c?.color_name || c?.name || ''
    const img = c?.color_image || c?.image || ''
    if (name) colorImgMap[name] = img
  }

  for (const sku of rawSkus) {
    const attrs = sku?.sku_sale_attr || sku?.sale_attr || []
    let colorId = '', colorName = '', sizeId = '', sizeName = ''
    let variantPrice = 0
    let stock = parseInt(sku?.stock ?? sku?.stockNum ?? '0') || 0
    const mallPrice = sku?.mall_price?.[0] || sku?.price || {}
    variantPrice = parsePrice(mallPrice?.price || mallPrice?.amount || 0)

    for (const attr of attrs) {
      const attrName = (attr?.attr_name || '').toLowerCase()
      const rawAttrId = attr?.attr_id
      const attrId = String(attr?.attr_value_id || rawAttrId || '')
      const attrVal = attr?.attr_value || attr?.attr_value_name || attr?.attrValue || ''
      // attr_id 87 = color, 85 = size (numeric or string)
      const isColor = attrName === 'color' || attrName === 'colour' || rawAttrId == 87
      const isSize = attrName === 'size' || rawAttrId == 85
      if (isColor) {
        colorId = attrId
        colorName = attrVal
      } else if (isSize) {
        sizeId = attrId
        sizeName = attrVal
      }
    }

    if (colorName && !colors.has(colorId)) {
      colors.set(colorId, {
        id: colorId || colorName,
        name: colorName,
        image: colorImgMap[colorName] || '',
        available: false,
      })
    }
    if (sizeName && !sizes.has(sizeId)) {
      sizes.set(sizeId, {
        id: sizeId || sizeName,
        name: sizeName,
        available: false,
      })
    }

    const available = stock > 0
    if (available) {
      if (colorName) { const c = colors.get(colorId); if (c) c.available = true }
      if (sizeName) { const s = sizes.get(sizeId); if (s) s.available = true }
    }

    variants.push({
      id: sku?.goods_sn || sku?.sku_code || `${colorId}-${sizeId}`,
      sku: sku?.goods_sn || sku?.sku_code,
      colorId: colorId || null,
      colorName: colorName || null,
      sizeId: sizeId || null,
      sizeName: sizeName || null,
      available,
      stock: stock || undefined,
      priceUsd: variantPrice || undefined,
    })
  }

  return {
    colors: [...colors.values()],
    sizes: [...sizes.values()],
    variants,
  }
}

export function parseSheinApiResponse(json) {
  const info = json?.info || json?.data?.info || json?.data?.detail || json?.data
  if (!info) return null

  const title = cleanTitle(info.goods_name || info.title || info.goodsName || '')
  if (!title) return null

  // Check currency — reject non-USD API responses (regional pricing)
  const currency = info.sale_price?.currency || info.salePrice?.currency ||
    info.retailPrice?.currency || info.currency || 'USD'
  if (currency && currency !== 'USD') {
    console.log(`  → API returned ${currency} price — rejecting (regional pricing)`)
    return null
  }

  // priceInfo is used in inline-script SKU data (get_goods_detail_realtime_data style)
  const retailPriceAmt = info.retailPrice?.amount
    || info.priceInfo?.retailPrice?.amount || 0
  const priceUsd = parsePrice(
    info.sale_price?.amount || info.salePrice?.amount ||
    info.sell_price || retailPriceAmt || info.price || 0
  )

  const images = extractImages(info)
  const { colors, sizes, variants } = extractSku(info)
  const description = info.goods_desc || info.description || ''

  return { title, priceUsd, images, colors, sizes, variants, description }
}

export function parseSheinPageMeta(html) {
  const get = (prop) =>
    html.match(new RegExp(`<meta[^>]+property=["']${prop}["'][^>]+content=["']([^"']+)["']`))?.[1] ||
    html.match(new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+property=["']${prop}["']`))?.[1] || ''

  const title = cleanTitle(get('og:title'))
  const priceStr = get('product:price:amount')
  const priceUsd = parseFloat(priceStr) || 0
  const image = get('og:image')
  const imgMatches = [...html.matchAll(/["'](https:\/\/img\.ltwebstatic\.com\/[^"']+\.(?:jpg|webp)[^"']*)['"]/g)]
  const images = [...new Set([image, ...imgMatches.map(m => m[1])].filter(isProductImage))].slice(0, 8)

  if (!title) return null
  return { title, priceUsd, images, colors: [], sizes: [], variants: [], description: '' }
}
