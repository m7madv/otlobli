const store = new Map()
const DEFAULT_TTL_MS = 60 * 60 * 1000 // 60 minutes

export function saveTempProduct(product, ttlMs = DEFAULT_TTL_MS) {
  const id = product.id || `shein-${product.sourceProductId}-${Date.now()}`
  const record = { ...product, id, expiresAt: new Date(Date.now() + ttlMs).toISOString() }
  store.set(id, record)
  console.log(`💾 Saved temp product ${id}, expires: ${record.expiresAt}`)
  return record
}

export function getTempProduct(id) {
  const record = store.get(id)
  if (!record) return null
  if (new Date(record.expiresAt) < new Date()) { store.delete(id); return null }
  return record
}

export function cleanupExpiredTempProducts() {
  const now = new Date()
  let removed = 0
  for (const [id, record] of store.entries()) {
    if (new Date(record.expiresAt) < now) { store.delete(id); removed++ }
  }
  if (removed > 0) console.log(`🧹 Cleaned ${removed} expired temp products`)
}
