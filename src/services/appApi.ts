import type { Order, PaymentStatus, Product } from '../domain/types'
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

export type OrderStatusResult = {
  statusIndex: number
  paymentStatus: PaymentStatus
  paidAt?: string
  qadmousNumber: string
  paymentIssue: boolean
  paymentIssueNote: string
  extraAmountUsd: number
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
  // سبب الرفض: not_found/inactive/expired/not_started/wrong_store/below_min/
  // exhausted/already_used/no_phone/offline/error
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
  orders: {
    // ينشئ الطلب بحالة "بانتظار الدفع" مع مبلغ دفع فريد، قبل عرض شاشة الدفع -
    // الطلب لا يصبح "مدفوع" إلا لما يوصل تأكيد حقيقي من webhook شام كاش.
    createPendingOrder: (order: Order, currency: PaymentCurrency) => Promise<PendingOrderResult>
    // يستعلم عن حالة الطلب الحالية (المرحلة، رقم القدموس...) لتحديث شاشة
    // التتبع - يرجع null إذا الطلب غير موجود أو القاعدة غير متاحة.
    pollOrderStatus: (orderId: string) => Promise<OrderStatusResult | null>
    // يتحقق أن كود الإحالة (رقم هاتف عميل سابق) حقيقي قبل تطبيق خصم الإحالة.
    validateReferralCode: (code: string) => Promise<boolean>
    // يتحقق من كود الخصم ويحسبه ويستهلكه ذرّياً (مرة واحدة لكل هاتف/جهاز).
    // يتدهور بأمان: يُعيد valid=false بلا كسر إن كانت الخلفية غير متاحة.
    redeemCoupon: (input: RedeemCouponInput) => Promise<RedeemCouponResult>
    // يحفظ تقييم العميل (نجوم + ملاحظة اختيارية) بعد تسليم الطلب - مرة واحدة فقط لكل طلب.
    submitOrderRating: (orderId: string, stars: number, note: string) => Promise<boolean>
  }
}
