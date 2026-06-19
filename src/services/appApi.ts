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
  }
}
