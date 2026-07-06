import { useEffect, useState } from 'react'

// يمسح البيانات التجريبية القديمة مرة واحدة عند أول تشغيل للنسخة الحقيقية
const CLEAN_VERSION = 'v2-real'
if (typeof window !== 'undefined' && window.localStorage.getItem('talabieh.cleanVersion') !== CLEAN_VERSION) {
  const DEMO_ORDERS = ['ORD-10482', 'ORD-10483']
  try {
    const stored = window.localStorage.getItem('talabieh.orders')
    if (stored) {
      const parsed = JSON.parse(stored) as Array<{ id: string }>
      const real = parsed.filter(o => !DEMO_ORDERS.includes(o.id))
      window.localStorage.setItem('talabieh.orders', JSON.stringify(real))
    }
    window.localStorage.removeItem('talabieh.addresses')
    window.localStorage.removeItem('talabieh.currentOrderId')
  } catch {
    // Ignore corrupted legacy demo data; the next write stores the clean state.
  }
  window.localStorage.setItem('talabieh.cleanVersion', CLEAN_VERSION)
}

export const storageKeys = {
  savedProduct: 'talabieh.savedProduct',
  cart: 'talabieh.cart',
  cartItems: 'talabieh.cartItems',
  orders: 'talabieh.orders',
  addresses: 'talabieh.addresses',
  currentOrderId: 'talabieh.currentOrderId',
  recipient: 'talabieh.recipient',
  pendingWhatsappAuth: 'talabieh.pendingWhatsappAuth',
  sessionToken: 'talabieh.sessionToken',
  userProfile: 'talabieh.userProfile',
  exchangeRate: 'talabieh.exchangeRate',
  paymentCurrency: 'talabieh.paymentCurrency',
  pendingPayment: 'talabieh.pendingPayment',
  pendingWalletTopUp: 'talabieh.pendingWalletTopUp',
  notifications: 'talabieh.notifications',
  notificationPrefs: 'talabieh.notificationPrefs',
  selectedStore: 'talabieh.selectedStore',
  cartsByStore: 'talabieh.cartsByStore',
  cartGroup: 'talabieh.cartGroup',
} as const

export function getDeviceId(): string {
  if (typeof window === 'undefined') {
    return ''
  }

  try {
    const key = 'talabieh.deviceId'
    let value = window.localStorage.getItem(key) || ''
    if (!value) {
      value = typeof crypto !== 'undefined' && 'randomUUID' in crypto
        ? crypto.randomUUID()
        : `dev-${Math.random().toString(36).slice(2)}${Date.now().toString(36)}`
      window.localStorage.setItem(key, value)
    }
    return value
  } catch {
    return ''
  }
}

export function readStoredJson<T>(key: string, fallback: T) {
  if (typeof window === 'undefined') {
    return fallback
  }

  try {
    const stored = window.localStorage.getItem(key)
    return stored ? (JSON.parse(stored) as T) : fallback
  } catch {
    return fallback
  }
}

function writeStoredJson<T>(key: string, value: T) {
  if (typeof window === 'undefined') {
    return
  }

  try {
    window.localStorage.setItem(key, JSON.stringify(value))
  } catch {
    // The UI stays usable even if the browser blocks storage.
  }
}

export function useStoredState<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => readStoredJson(key, initialValue))

  useEffect(() => {
    writeStoredJson(key, value)
  }, [key, value])

  return [value, setValue] as const
}
