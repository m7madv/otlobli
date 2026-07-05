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
  customers: {
    async getAccount(_phone) {
      void _phone
      await wait(120)
      return {
        mode: 'local-mock',
        profile: null,
        orders: [],
        walletBalanceSyp: 0,
        walletTransactions: [],
      }
    },

    async saveProfile(phone, profile) {
      await wait(120)
      return {
        mode: 'local-mock',
        profile: { ...profile, phone },
        orders: [],
        walletBalanceSyp: 0,
        walletTransactions: [],
      }
    },
  },
  cartGroups: {
    async create(phone, name, _store, items) {
      await wait(120)
      return {
        id: `local-${Date.now()}`,
        code: Math.random().toString(36).slice(2, 8).toUpperCase(),
        status: 'open',
        minTotalUsd: 40,
        totalUsd: items.reduce((sum, item) => sum + item.priceUsd * item.quantity, 0),
        members: [{ phone, name, role: 'host' }],
        items: items.map((item) => ({ ownerPhone: phone, ownerName: name, item })),
      }
    },

    async join(phone, name, code, items) {
      await wait(120)
      return {
        id: `local-${code}`,
        code: code.trim().toUpperCase(),
        status: 'open',
        minTotalUsd: 40,
        totalUsd: items.reduce((sum, item) => sum + item.priceUsd * item.quantity, 0),
        members: [{ phone, name, role: 'member' }],
        items: items.map((item) => ({ ownerPhone: phone, ownerName: name, item })),
      }
    },

    async syncItems(phone, groupId, items) {
      await wait(120)
      return {
        id: groupId,
        code: groupId.replace(/^local-/, '').slice(0, 8).toUpperCase(),
        status: 'open',
        minTotalUsd: 40,
        totalUsd: items.reduce((sum, item) => sum + item.priceUsd * item.quantity, 0),
        members: [{ phone, name: 'local', role: 'host' }],
        items: items.map((item) => ({ ownerPhone: phone, ownerName: 'local', item })),
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

    // لا قاعدة بيانات حقيقية بالوضع المحلي لتُخزَّن فيها.
    async submitOrderRating() {
      await wait(220)
      return true
    },
  },
}
