import { paymentSettings, product } from '../domain/fixtures'
import { today } from '../domain/orders'
import type { TalabiehApi } from './appApi'

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
    async verifyB2BShamCashPayment(amountSyp) {
      await wait(1100)

      return {
        mode: 'local-mock',
        status: amountSyp > 0 && paymentSettings.provider ? 'matched' : 'failed',
        amountSyp,
        matchedAt: today(),
      }
    },
  },
  orders: {
    async createOrder(order) {
      await wait(180)

      return {
        mode: 'local-mock',
        orderId: order.id,
        persisted: false,
      }
    },
  },
}
