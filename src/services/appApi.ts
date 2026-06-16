import type { Order, Product } from '../domain/types'

export type ApiMode = 'local-mock' | 'external'

export type StartLoginResult = {
  mode: ApiMode
  otpExpiresInSeconds: number
  whatsappUrl?: string
  supportPhone?: string
  verificationMessage?: string
  requiresInboundWhatsapp?: boolean
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

export type PaymentVerificationResult = {
  mode: ApiMode
  status: 'matched' | 'pending' | 'failed'
  amountSyp: number
  matchedAt?: string
}

export type OrderCreateResult = {
  mode: ApiMode
  orderId: string
  persisted: boolean
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
    verifyB2BShamCashPayment: (amountSyp: number) => Promise<PaymentVerificationResult>
  }
  orders: {
    createOrder: (order: Order) => Promise<OrderCreateResult>
  }
}
