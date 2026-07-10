import type { CartGroupSnapshot, CartItem, Order, PaymentStatus, Product, UserProfile, WalletTransaction } from '../domain/types'
import type { PaymentCurrency } from '../domain/pricing'

export type ApiMode = 'local-mock' | 'external'

export type StartLoginResult = {
  mode: ApiMode
  otpExpiresInSeconds: number
  whatsappUrl?: string
  supportPhone?: string
  verificationMessage?: string
  requiresInboundWhatsapp?: boolean
  telegramOtp?: string
}

export type VerifyOtpResult = {
  mode: ApiMode
  sessionToken: string
}

export type ProductFetchResult = {
  mode: ApiMode
  product: Product
  normalizedLink: string
}

export type PendingOrderResult = {
  mode: ApiMode
  orderId: string
  paymentAmount: number
  paymentCurrency: PaymentCurrency
  paymentExpiresAt: string
}

export type PaymentStatusResult = {
  mode: ApiMode
  status: PaymentStatus
  paidAt?: string
}

export type WalletTopUpStatus = PaymentStatus | 'منتهي' | 'ظ…ظ†طھظ‡ظٹ'

export type WalletTopUpResult = {
  mode: ApiMode
  topUpId: string
  paymentAmount: number
  paymentCurrency: PaymentCurrency
  paymentExpiresAt: string
  creditAmountSyp: number
}

export type WalletTopUpStatusResult = {
  mode: ApiMode
  status: WalletTopUpStatus
  paidAt?: string
  creditAmountSyp: number
  walletBalanceSyp: number
}

export type OrderStatusResult = {
  statusIndex: number
  paymentStatus: PaymentStatus
  paidAt?: string
  qadmousNumber: string
  paymentIssue: boolean
  paymentIssueNote: string
  extraAmountUsd: number
}

export type OrderIssuePaymentResult = {
  mode: ApiMode
  issuePaymentId: string
  orderId: string
  paymentAmount: number
  paymentCurrency: PaymentCurrency
  paymentExpiresAt: string
}

export type CustomerAccountResult = {
  mode: ApiMode
  profile: UserProfile | null
  orders: Order[]
  walletBalanceSyp: number
  walletTransactions: WalletTransaction[]
}

export type RedeemCouponInput = {
  code: string
  phone: string
  deviceId: string
  store: string
  subtotalSyp: number
}

export type RedeemCouponResult = {
  valid: boolean
  discountSyp: number
  code?: string
  reason?: string
}

export type TalabiehApi = {
  auth: {
    startWhatsappLogin: (phone: string) => Promise<StartLoginResult>
    verifyOtp: (phone: string, code: string) => Promise<VerifyOtpResult>
  }
  catalog: {
    fetchSheinProduct: (link: string, fallbackTitle?: string) => Promise<ProductFetchResult>
  }
  payments: {
    checkPaymentStatus: (orderId: string) => Promise<PaymentStatusResult>
  }
  wallet: {
    createTopUp: (phone: string, name: string, amountUsd: number) => Promise<WalletTopUpResult>
    checkTopUpStatus: (topUpId: string) => Promise<WalletTopUpStatusResult>
    getBalance: (phone: string) => Promise<number>
    spend: (phone: string, amountUsd: number, orderId: string) => Promise<number>
  }
  customers: {
    getAccount: (phone: string) => Promise<CustomerAccountResult>
    saveProfile: (phone: string, profile: UserProfile) => Promise<CustomerAccountResult>
  }
  cartGroups: {
    create: (phone: string, name: string, store: string, items: CartItem[], memberKey?: string) => Promise<CartGroupSnapshot>
    join: (phone: string, name: string, code: string, items: CartItem[], memberKey?: string) => Promise<CartGroupSnapshot>
    syncItems: (phone: string, groupId: string, items: CartItem[], memberKey?: string) => Promise<CartGroupSnapshot>
    cancel: (phone: string, groupId: string) => Promise<void>
  }
  orders: {
    // ظٹظ†ط´ط¦ ط§ظ„ط·ظ„ط¨ ط¨ط­ط§ظ„ط© "ط¨ط§ظ†طھط¸ط§ط± ط§ظ„ط¯ظپط¹" ظ…ط¹ ظ…ط¨ظ„ط؛ ط¯ظپط¹ ظپط±ظٹط¯طŒ ظ‚ط¨ظ„ ط¹ط±ط¶ ط´ط§ط´ط© ط§ظ„ط¯ظپط¹ -
    // ط§ظ„ط·ظ„ط¨ ظ„ط§ ظٹطµط¨ط­ "ظ…ط¯ظپظˆط¹" ط¥ظ„ط§ ظ„ظ…ط§ ظٹظˆطµظ„ طھط£ظƒظٹط¯ ط­ظ‚ظٹظ‚ظٹ ظ…ظ† webhook ط´ط§ظ… ظƒط§ط´.
    createPendingOrder: (order: Order, currency: PaymentCurrency) => Promise<PendingOrderResult>
    createIssuePayment: (orderId: string, amountUsd: number, currency: PaymentCurrency) => Promise<OrderIssuePaymentResult>
    // ظٹط³طھط¹ظ„ظ… ط¹ظ† ط­ط§ظ„ط© ط§ظ„ط·ظ„ط¨ ط§ظ„ط­ط§ظ„ظٹط© (ط§ظ„ظ…ط±ط­ظ„ط©طŒ ط±ظ‚ظ… ط§ظ„ظ‚ط¯ظ…ظˆط³...) ظ„طھط­ط¯ظٹط« ط´ط§ط´ط©
    // ط§ظ„طھطھط¨ط¹ - ظٹط±ط¬ط¹ null ط¥ط°ط§ ط§ظ„ط·ظ„ط¨ ط؛ظٹط± ظ…ظˆط¬ظˆط¯ ط£ظˆ ط§ظ„ظ‚ط§ط¹ط¯ط© ط؛ظٹط± ظ…طھط§ط­ط©.
    pollOrderStatus: (orderId: string) => Promise<OrderStatusResult | null>
    // ظٹطھط­ظ‚ظ‚ ط£ظ† ظƒظˆط¯ ط§ظ„ط¥ط­ط§ظ„ط© (ط±ظ‚ظ… ظ‡ط§طھظپ ط¹ظ…ظٹظ„ ط³ط§ط¨ظ‚) ط­ظ‚ظٹظ‚ظٹ ظ‚ط¨ظ„ طھط·ط¨ظٹظ‚ ط®طµظ… ط§ظ„ط¥ط­ط§ظ„ط©.
    validateReferralCode: (code: string) => Promise<boolean>
    redeemCoupon: (input: RedeemCouponInput) => Promise<RedeemCouponResult>
    // ظٹط­ظپط¸ طھظ‚ظٹظٹظ… ط§ظ„ط¹ظ…ظٹظ„ (ظ†ط¬ظˆظ… + ظ…ظ„ط§ط­ط¸ط© ط§ط®طھظٹط§ط±ظٹط©) ط¨ط¹ط¯ طھط³ظ„ظٹظ… ط§ظ„ط·ظ„ط¨ - ظ…ط±ط© ظˆط§ط­ط¯ط© ظپظ‚ط· ظ„ظƒظ„ ط·ظ„ط¨.
    submitOrderRating: (orderId: string, stars: number, note: string) => Promise<boolean>
    // يرسل تصحيح تخصيص (صورة مقصوصة/نص) لعنصر في طلب قائم — تدفق
    // "مشكلة قياس الصورة" الذي يفتحه المشرف من لوحة الإدارة.
    submitCustomFix: (orderId: string, productId: string, photoDataUrl: string, customText: string) => Promise<boolean>
  }
}
