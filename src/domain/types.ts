export type UserProfile = {
  name: string
  governorate: string
  phone?: string
  city?: string
  qadmousBranch?: string
  pickupLabel?: string
  details?: string
  notificationPrefs?: NotificationPrefs
  walletBalanceSyp?: number
}

export type Screen =
  | 'login'
  | 'otp'
  | 'onboarding'
  | 'home'
  | 'loading'
  | 'product'
  | 'cart'
  | 'checkout'
  | 'payment'
  | 'success'
  | 'orders'
  | 'tracking'
  | 'profile'
  | 'addresses'
  | 'payment-methods'
  | 'blocked-policy'
  | 'terms'
  | 'support'
  | 'notifications'
  | 'notification-settings'
  | 'store-select'

export type NotificationPrefs = {
  orderUpdates: boolean
  paymentUpdates: boolean
  productIssues: boolean
  walletUpdates: boolean
  groupOrderUpdates: boolean
  promotions: boolean
  whatsapp: boolean
}

export type AppNotification = {
  id: string
  type: 'order_update' | 'payment' | 'payment_issue' | 'wallet' | 'group_order' | 'system'
  title: string
  body: string
  orderId?: string
  createdAt: string
  read: boolean
}

export type StatusTone = 'success' | 'pending' | 'neutral' | 'danger'
export type PaymentStatus =
  | 'بانتظار الدفع'
  | 'مدفوع'
  | 'فشل المطابقة'
  | 'ط¨ط§ظ†طھط¸ط§ط± ط§ظ„ط¯ظپط¹'
  | 'ظ…ط¯ظپظˆط¹'
  | 'ظپط´ظ„ ط§ظ„ظ…ط·ط§ط¨ظ‚ط©'

export type ProductColor = {
  id?: string
  name: string
  image: string
  available?: boolean
}

export type ProductSize = {
  id?: string
  name: string
  available?: boolean
}

export type ProductVariant = {
  id: string
  sku?: string
  colorId?: string | null
  colorName?: string | null
  sizeId?: string | null
  sizeName?: string | null
  available: boolean
  stock?: number
  priceUsd?: number
  image?: string
}

export type Product = {
  id: string
  title: string
  source: string
  link: string
  priceUsd: number
  priceSyp: number
  weight: string
  deliveryWindow: string
  images: string[]
  colors: ProductColor[]
  sizes: string[]
  sizeObjects?: ProductSize[]
  variants?: ProductVariant[]
  availability?: 'in_stock' | 'out_of_stock' | 'partial' | 'unknown'
}

export type ImportedSheinProduct = {
  id: string
  source: 'shein'
  sourceProductId: string
  originalUrl: string
  normalizedUrl: string
  title: string
  description?: string
  images: string[]
  price: {
    usd: number
    syp: number
    currency: 'USD'
    exchangeRate: number
  }
  colors: Array<{ id: string; name: string; image?: string; available: boolean }>
  sizes: Array<{ id: string; name: string; available: boolean }>
  variants: ProductVariant[]
  availability: 'in_stock' | 'out_of_stock' | 'partial' | 'unknown'
  temporary: true
  importedAt: string
  expiresAt: string
}

export type CartItem = {
  id: string
  title: string
  image: string
  colorImage?: string
  color: string
  size: string
  sizesAvailable?: string[]
  sizesUnavailable?: string[]
  quantity: number
  priceUsd: number
  priceSyp: number
  sourceLink: string
  needsCustomPhoto?: boolean
  customPhotoNote?: string
  customPhotoDataUrl?: string
  needsCustomText?: boolean
  customText?: string
}

export type WalletTransaction = {
  id: string
  amountSyp: number
  kind: string
  note: string
  orderId?: string
  createdAt: string
}

export type CartGroupMember = {
  phone: string
  name: string
  role: 'host' | 'member'
}

export type CartGroupLine = {
  ownerPhone: string
  ownerName: string
  item: CartItem
}

export type CartGroupSnapshot = {
  id: string
  code: string
  status: 'open' | 'locked' | 'ordered' | 'cancelled' | string
  minTotalUsd: number
  totalUsd: number
  members: CartGroupMember[]
  items: CartGroupLine[]
}

export type Address = {
  id: string
  label: string
  name: string
  phone: string
  governorate: string
  qadmousBranch?: string
  city: string
  details: string
  notes: string
  isDefault: boolean
}

export type Recipient = Omit<Address, 'id' | 'label' | 'isDefault'> & {
  pickupLabel?: string
}

export type Order = {
  id: string
  customer: string
  phone: string
  city: string
  address: string
  items: CartItem[]
  total: number
  paymentStatus: PaymentStatus
  statusIndex: number
  qadmousNumber: string
  createdAt: string
  paidAt?: string
  rating?: number
  ratingNote?: string
  paymentIssue?: boolean
  paymentIssueNote?: string
  extraAmountUsd?: number
  groupId?: string
  groupCode?: string
}

export type PriceLine = {
  label: string
  value: number
}
