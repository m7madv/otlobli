import type { PriceLine } from './types'

export function formatMoney(value: number) {
  return `${value.toLocaleString('ar-SY')} ل.س`
}

export function formatUsd(value: number) {
  return `$${value.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
}

export type PaymentCurrency = 'SYP' | 'USD'

export function formatPriceSyp(syp: number, currency: PaymentCurrency, exchangeRate: number) {
  return currency === 'USD' ? formatUsd(syp / exchangeRate) : formatMoney(syp)
}

export function buildPriceBreakdown({
  label,
  productPriceSyp,
  quantity,
  fees,
}: {
  label: string
  productPriceSyp: number
  quantity: number
  fees: PriceLine[]
}) {
  return [{ label, value: productPriceSyp * quantity }, ...fees]
}

export function sumPriceLines(items: PriceLine[]) {
  return items.reduce((sum, item) => sum + item.value, 0)
}
