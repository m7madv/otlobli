import { SheinImportError } from './sheinErrors.js'

const TRACKING_PARAMS = [
  'utm_source', 'utm_medium', 'utm_campaign', 'utm_content', 'utm_term',
  'src_identifier', 'src_content', 'src_tab_page_id', 'src_module',
  'ref', 'referral', 'mallCode', 'main_attr', 'main_attr_name',
  'imgRatio', 'pricingTier', 'ici', 'ctype', 'ctime',
  'share_from', 'url_from', 'shc', 'cdn_rsite',
  'adp', 'adevent', 'adfp', 'adflow',
]

const SHEIN_HOSTNAMES = [
  'shein.com', 'm.shein.com', 'us.shein.com', 'uk.shein.com',
  'de.shein.com', 'fr.shein.com', 'ar.shein.com', 'jo.shein.com',
  'sa.shein.com', 'ae.shein.com', 'api-shein.shein.com',
  'euqs.shein.com', 'in.shein.com',
]

export function isSheinUrl(url) {
  try {
    const parsed = new URL(url)
    return SHEIN_HOSTNAMES.some(h => parsed.hostname === h || parsed.hostname.endsWith('.' + h.split('.').slice(-2).join('.')))
  } catch {
    return false
  }
}

export function normalizeSheinUrl(rawUrl) {
  let url
  try {
    url = new URL(rawUrl.trim())
  } catch {
    throw new SheinImportError('INVALID_SHEIN_URL', { raw: rawUrl })
  }

  if (!isSheinUrl(url.href)) {
    throw new SheinImportError('INVALID_SHEIN_URL', { hostname: url.hostname })
  }

  TRACKING_PARAMS.forEach(p => url.searchParams.delete(p))

  // Keep only goods_id if present in query, drop the rest
  const goodsId = url.searchParams.get('goods_id')
  const cat = url.searchParams.get('cat_id')
  for (const key of [...url.searchParams.keys()]) {
    if (key !== 'goods_id' && key !== 'cat_id') url.searchParams.delete(key)
  }
  if (!goodsId && cat) url.searchParams.delete('cat_id')

  return url.href
}
