export type SafePushDestination = {
  screen: 'orders' | 'tracking' | 'notifications' | 'payment-methods'
  entityId?: string
}

export function parseSafePushPayload(data: Record<string, unknown> | undefined): SafePushDestination | null {
  if (!data) return null
  const version = Number(data.version ?? 1)
  if (version !== 1) return null
  const route = String(data.route ?? '').trim().toLowerCase()
  const type = String(data.type ?? '').trim().toLowerCase()
  const entityId = typeof data.entityId === 'string' && data.entityId.length <= 128
    ? data.entityId.trim()
    : undefined

  if (route === 'orders/details' && entityId) return { screen: 'tracking', entityId }
  if (route === 'orders' || type === 'order_update') return { screen: 'orders', entityId }
  if (route === 'wallet' || route === 'payment-methods' || type === 'wallet_update') {
    return { screen: 'payment-methods', entityId }
  }
  if (route === 'notifications' || route === '') return { screen: 'notifications', entityId }
  return null
}
