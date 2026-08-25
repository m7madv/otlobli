export type StoreIdentity = 'shein' | 'temu'

type StoreLinkedCartItem = {
  sourceLink?: string
}

type StandardStoreSessionIdentity = {
  store: StoreIdentity
  sessionId: number
  id?: string
}

const STORE_IDENTITIES: readonly StoreIdentity[] = ['shein', 'temu']

export function storeIdentityFromUrl(rawUrl: string): StoreIdentity | undefined {
  try {
    const host = new URL(rawUrl).hostname.toLowerCase().replace(/\.$/, '')
    if (host === 'temu.com' || host.endsWith('.temu.com')) return 'temu'
    if (host === 'shein.com' || host.endsWith('.shein.com')) return 'shein'
  } catch {
    return undefined
  }
  return undefined
}

export function resolveStoreMessageIdentity(
  sourceStore: StoreIdentity | undefined,
  productUrl: string,
  fallbackStore: StoreIdentity,
): StoreIdentity {
  return storeIdentityFromUrl(productUrl) ?? sourceStore ?? fallbackStore
}

export function canReuseStandardStoreSession(
  requestedStore: StoreIdentity,
  selectedStore: StoreIdentity,
  openStore: StoreIdentity | null,
  hasOpenStandardWebview: boolean,
): boolean {
  if (requestedStore !== selectedStore) return false
  return !hasOpenStandardWebview || openStore === requestedStore
}

export function isCurrentStandardStoreEvent(
  owner: StandardStoreSessionIdentity | null,
  currentSessionId: number,
  eventId: string | undefined,
): boolean {
  return !!owner && owner.sessionId === currentSessionId && !!owner.id && !!eventId && owner.id === eventId
}

export function canAdoptOpeningStandardStoreEvent(
  owner: StandardStoreSessionIdentity | null,
  currentSessionId: number,
  eventId: string | undefined,
  eventStore: StoreIdentity | undefined,
  hasBoundWebviewId: boolean,
  isOpening: boolean,
  isClosing: boolean,
  isIgnoredEvent: boolean,
): boolean {
  return !!owner && owner.sessionId === currentSessionId && !owner.id && !!eventId &&
    owner.store === eventStore && !hasBoundWebviewId && isOpening && !isClosing && !isIgnoredEvent
}

// Older builds could file a captured product under whichever cart tab happened
// to be selected when an asynchronous WebView message arrived. Product hosts
// are authoritative, so repair only rows whose source URL names the other
// supported store. Unknown/legacy links stay exactly where the customer put them.
export function repairStoreCartBuckets<T extends StoreLinkedCartItem>(
  carts: Record<string, T[]>,
): Record<string, T[]> {
  const next: Record<string, T[]> = {
    ...carts,
    shein: [],
    temu: [],
  }
  let changed = false

  for (const sourceStore of STORE_IDENTITIES) {
    for (const item of carts[sourceStore] ?? []) {
      const targetStore = storeIdentityFromUrl(item.sourceLink ?? '') ?? sourceStore
      next[targetStore].push(item)
      if (targetStore !== sourceStore) changed = true
    }
  }

  return changed ? next : carts
}
