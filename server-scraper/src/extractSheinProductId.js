const PATTERNS = [
  /-p-(\d{6,12})(?:[-.]|$)/i,      // -p-43071777.html or -p-43071777-cat
  /[?&]goods_id=(\d{6,12})/i,       // ?goods_id=43071777
  /[?&]product_id=(\d{6,12})/i,     // ?product_id=43071777
  /\/(\d{6,12})\.html/i,            // /43071777.html
  /\/p\/(\d{6,12})/i,               // /p/43071777
  /-(\d{8,12})(?:-cat|-p|\.html)/i, // last resort: 8+ digit number before known separators
]

export function extractSheinProductId(url) {
  // Try on raw URL first, then URL-decoded
  for (const str of [url, decodeURIComponent(url)]) {
    for (const pattern of PATTERNS) {
      const match = str.match(pattern)
      if (match?.[1]) return match[1]
    }
  }
  return null
}
