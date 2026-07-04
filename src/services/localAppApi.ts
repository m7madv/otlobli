import { product } from '../domain/fixtures'
import { today } from '../domain/orders'
import type { TalabiehApi } from './appApi'

const LOCAL_USD_TO_SYP_RATE = 13000

function wait(ms: number) {
  return new Promise((resolve) => window.setTimeout(resolve, ms))
}

function normalizeSheinLink(link: string) {
  const value = link.trim()
  return value || product.link
}

export const localAppApi: TalabiehApi = {
  auth: {
    async startWhatsappLogin() {
      await wait(240)
      return {
        mode: 'local-mock',
        otpExpiresInSeconds: 42,
      }
    },
    async verifyOtp() {
      await wait(220)
      return {
        mode: 'local-mock',
        sessionToken: 'local-demo-session',
      }
    },
  },
  users: {
    async heartbeat() {
      return { blocked: false }
    },
  },
  wallet: {
    async getBalance() { return 0 },
    async spend() { return { ok: false, spentUsd: 0, balanceUsd: 0 } },
  },
  catalog: {
    async fetchSheinProduct(link) {
      await wait(850)

      return {
        mode: 'local-mock',
        product,
        normalizedLink: normalizeSheinLink(link),
      }
    },
  },
  payments: {
    // لا يوجد باكند حقيقي بهذا الوضع المحلي، فما فيه إشعار شام كاش فعلي
    // ممكن يوصل - نحاكي "وصلت الحوالة" بعد أول فحص حتى تبقى تجربة الديمو
    // قابلة للتجربة كاملة بدون Supabase.
    async checkPaymentStatus() {
      await wait(900)
      return {
        mode: 'local-mock',
        status: 'مدفوع',
        paidAt: today(),
      }
    },
  },
  orders: {
    async createPendingOrder(order, currency) {
      await wait(180)
      const paymentAmount = currency === 'USD'
        ? Math.round((order.total / LOCAL_USD_TO_SYP_RATE) * 100) / 100
        : order.total

      return {
        mode: 'local-mock',
        orderId: order.id,
        paymentAmount,
        paymentCurrency: currency,
        paymentExpiresAt: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
      }
    },

    // لا قاعدة بيانات حقيقية بالوضع المحلي لتُستعلَم.
    async pollOrderStatus() {
      return null
    },

    // بالوضع المحلي نقبل أي كود غير فارغ كمحاكاة لتجربة الخصم.
    async validateReferralCode(code) {
      await wait(220)
      return code.trim().length > 0
    },

    // بالوضع المحلي لا خلفية لأكواد الخصم — نُعيد رفضاً آمناً بلا خصم.
    async redeemCoupon() {
      await wait(200)
      return { valid: false, discountSyp: 0, reason: 'local' }
    },

    // لا قاعدة بيانات حقيقية بالوضع المحلي لتُخزَّن فيها.
    async submitOrderRating() {
      await wait(220)
      return true
    },
  },
}
