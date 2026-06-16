import type { Order } from './types'

export function today() {
  return new Date().toISOString().slice(0, 10)
}

export function makeOrderId(orders: Order[]) {
  const date = new Date().toISOString().slice(0, 10).replaceAll('-', '')
  const entropy = Math.random().toString(36).slice(2, 7).toUpperCase()
  const sequence = (orders.length + 1).toString().padStart(3, '0')

  return `ORD-${date}-${sequence}${entropy}`
}

export function nextOrderStatusIndex(statusIndex: number, statusCount: number) {
  return Math.min(statusIndex + 1, statusCount - 1)
}
