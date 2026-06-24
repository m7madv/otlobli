import { product } from '../domain/fixtures'
import { today } from '../domain/orders'
import type { PaymentCurrency } from '../domain/pricing'
import type { Order, PaymentStatus, Product } from '../domain/types'
import type { ProductFetchResult, TalabiehApi } from './appApi'
import { localAppApi } from './localAppApi'
import { supabase } from './supabaseClient'
import { isWhatsappApiAuthEnabled, whatsappAuthApi } from './whatsappAuthApi'
import { PAYMENT_MODE } from '../config'

const DISPLAY_USD_RATE = Number(import.meta.env.VITE_USD_TO_SYP_RATE ?? 13000) || 13000

// Cloudflare Worker (fast, edge-based) with Railway as fallback
const SHEIN_WORKER_URL = import.meta.env.VITE_SHEIN_WORKER_URL || 'https://talabieh-shein.talabieh.workers.dev'
const SHEIN_SCRAPER_URL = import.meta.env.VITE_SHEIN_SCRAPER_URL || 'https://shein-scraper-production.up.railway.app'

type CatalogProductRow = {
  payload: unknown
  source_link: string | null
}

function normalizeSheinLink(link: string) {
  return link.trim() || product.link
}

// السكرايبر قد يرجّع وصف SHEIN.com العام (صفحة محجوبة) بدل عنوان المنتج الحقيقي — نرفضه دوماً
function isUsableScrapedTitle(title?: string): title is string {
  if (!title) return false
  return !/shein\.com is mainly design and produce fashion clothing/i.test(title)
}

function isStringArray(value: unknown): value is string[] {
  return Array.isArray(value) && value.every((item) => typeof item === 'string')
}

function isProduct(value: unknown): value is Product {
  if (!value || typeof value !== 'object') {
    return false
  }

  const record = value as Record<string, unknown>
  return (
    typeof record.id === 'string' &&
    typeof record.title === 'string' &&
    typeof record.source === 'string' &&
    typeof record.link === 'string' &&
    typeof record.priceUsd === 'number' &&
    typeof record.priceSyp === 'number' &&
    typeof record.weight === 'string' &&
    typeof record.deliveryWindow === 'string' &&
    isStringArray(record.images) &&
    isStringArray(record.sizes) &&
    Array.isArray(record.colors)
  )
}

function toOrderPayload(order: Order) {
  return {
    id: order.id,
    customer: order.customer,
    phone: order.phone,
    city: order.city,
    address: order.address,
    items: order.items,
    total: order.total,
    paymentStatus: order.paymentStatus,
    statusIndex: order.statusIndex,
    qadmousNumber: order.qadmousNumber,
    createdAt: order.createdAt,
    paidAt: order.paidAt ?? null,
  }
}

async function fetchProductFromSupabase(link: string): Promise<ProductFetchResult | null> {
  if (!supabase) {
    return null
  }

  const normalizedLink = normalizeSheinLink(link)
  const byLink = await supabase
    .from('catalog_products')
    .select('payload, source_link')
    .eq('is_active', true)
    .eq('source_link', normalizedLink)
    .limit(1)
    .maybeSingle<CatalogProductRow>()

  if (byLink.error || !byLink.data || !isProduct(byLink.data.payload)) {
    return null
  }

  return {
    mode: 'external',
    product: byLink.data.payload,
    normalizedLink: byLink.data.source_link ?? normalizedLink,
  }
}

export const supabaseAppApi: TalabiehApi = {
  auth: isWhatsappApiAuthEnabled ? whatsappAuthApi : localAppApi.auth,
  catalog: {
    async fetchSheinProduct(link, fallbackTitle) {
      // 1. نحاول من Supabase أولاً
      const fromDb = await fetchProductFromSupabase(link)
      if (fromDb) return fromDb

      const normalizedLink = normalizeSheinLink(link)

      // رابط ليس من SHEIN أصلاً — لا يوجد رابط منتج نفتحه يدوياً، هذا فقط خطأ صريح
      if (!/shein/i.test(normalizedLink)) {
        throw new Error('الرابط غير صالح. تأكد أنه رابط منتج من SHEIN.')
      }

      // منتج "إدخال يدوي": يُستخدم كل ما تعذّر السحب التلقائي بدل قطع المستخدم بخطأ نهائي.
      // المستخدم يفتح الرابط على جواله (تصفّح طبيعي، لا يُحجب أبداً) ويكمل السعر/الألوان/المقاسات بنفسه.
      const buildManualProduct = (partial?: Partial<Product>): ProductFetchResult => ({
        mode: 'external',
        product: {
          id: partial?.id || `manual-${Date.now()}`,
          title: fallbackTitle?.trim() || partial?.title || 'منتج SHEIN',
          source: 'SHEIN',
          link: normalizedLink,
          priceUsd: partial?.priceUsd || 0,
          priceSyp: 0,
          weight: '500g',
          deliveryWindow: '14-21 يوم',
          images: partial?.images?.length ? partial.images : [],
          sizes: partial?.sizes?.length ? partial.sizes : [],
          colors: partial?.colors?.length ? partial.colors : [],
          availability: partial?.availability || 'unknown',
        },
        normalizedLink,
      })

      // 2. Try Cloudflare Worker first (fast ~1-3s), fallback to Railway (~10-25s)
      const IMPORT_ENDPOINT = '/api/shein/import'
      let res: Response | null = null

      // Try Worker
      try {
        res = await fetch(`${SHEIN_WORKER_URL}${IMPORT_ENDPOINT}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ url: normalizedLink }),
          signal: AbortSignal.timeout(15000),
        })
        // If worker says price not found or fetch failed, try Railway (browser fallback)
        if (res.ok) {
          const workerJson = await res.clone().json() as Record<string, unknown>
          const workerErr = (workerJson.error as Record<string, unknown> | undefined)?.code as string | undefined
          if (workerErr === 'FETCH_FAILED' || workerErr === 'PRICE_NOT_FOUND') {
            res = null // trigger Railway fallback
          }
        } else if (res.status === 422) {
          // INVALID_SHEIN_URL = hard error, pass through
          // PRODUCT_ID_NOT_FOUND = sharing URL that needs browser resolution → try Railway
          const errJson = await res.clone().json() as Record<string, unknown>
          const errCode = (errJson.error as Record<string, unknown> | undefined)?.code as string
          if (errCode !== 'INVALID_SHEIN_URL') res = null
        } else {
          res = null // trigger Railway fallback
        }
      } catch {
        res = null // timeout or network error → try Railway
      }

      // Fallback to Railway scraper (Playwright browser)
      if (!res) {
        try {
          res = await fetch(`${SHEIN_SCRAPER_URL}${IMPORT_ENDPOINT}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ url: normalizedLink }),
            signal: AbortSignal.timeout(40000),
          })
        } catch {
          // كلا السيرفرين غير متاحَين الآن — لا نقطع المستخدم، ندخل وضع الإدخال اليدوي
          return buildManualProduct()
        }
      }

      let json: Record<string, unknown>
      try {
        json = await res.json() as Record<string, unknown>
      } catch {
        return buildManualProduct()
      }

      if (!res.ok || !json.success) {
        const err = json.error as Record<string, unknown> | undefined
        const code = err?.code as string | undefined
        if (code === 'INVALID_SHEIN_URL') {
          throw new Error('الرابط غير صالح. تأكد أنه رابط منتج من SHEIN.')
        }
        // كل أخطاء السحب الأخرى (FETCH_FAILED, PRICE_NOT_FOUND, PRODUCT_PARSE_FAILED, FETCH_TIMEOUT...)
        // تتحول لوضع إدخال يدوي بدل رسالة خطأ نهائية. details.title قد يحوي عنواناً حقيقياً
        // استُخرج بنجاح حتى لو فشل السعر فقط — لكن قد يكون وصف SHEIN.com العام من صفحة محجوبة، نتحقق منه.
        const details = err?.details as Record<string, unknown> | undefined
        const detailsTitle = details?.title ? String(details.title) : undefined
        return buildManualProduct({ title: isUsableScrapedTitle(detailsTitle) ? detailsTitle : undefined })
      }

      const s = json.product as Record<string, unknown>
      if (!s) return buildManualProduct()

      const priceInfo = s.price as Record<string, unknown> | undefined
      const priceUsd = typeof priceInfo?.usd === 'number' ? priceInfo.usd : 0

      const rawColors = (s.colors as Array<Record<string, unknown>>) || []
      const rawSizes = (s.sizes as Array<Record<string, unknown>>) || []
      const rawVariants = (s.variants as Array<Record<string, unknown>>) || []

      const productFromScraper: Product = {
        id: String(s.id || s.sourceProductId || Math.random().toString(36).slice(2)),
        // نص المشاركة من تطبيق SHEIN نفسه أدق من العنوان المستخرج بالسحب (قد يكون صفحة محجوبة)
        title: fallbackTitle?.trim() || (isUsableScrapedTitle(s.title as string) ? String(s.title) : 'منتج SHEIN'),
        source: 'SHEIN',
        link: String(s.normalizedUrl || s.originalUrl || normalizedLink),
        priceUsd,
        priceSyp: 0,
        weight: '500g',
        deliveryWindow: '14-21 يوم',
        images: Array.isArray(s.images) ? (s.images as string[]) : [],
        sizes: rawSizes.map(sz => String(sz.name || sz)).filter(Boolean),
        colors: rawColors.length > 0
          ? rawColors.map(c => ({ id: String(c.id || c.name || ''), name: String(c.name || ''), image: String(c.image || ''), available: c.available !== false }))
          : [],
        sizeObjects: rawSizes.map(sz => ({ id: String(sz.id || sz.name || ''), name: String(sz.name || ''), available: sz.available !== false })),
        variants: rawVariants.map(v => ({
          id: String(v.id || ''),
          sku: v.sku ? String(v.sku) : undefined,
          colorId: v.colorId ? String(v.colorId) : null,
          colorName: v.colorName ? String(v.colorName) : null,
          sizeId: v.sizeId ? String(v.sizeId) : null,
          sizeName: v.sizeName ? String(v.sizeName) : null,
          available: v.available === true,
          stock: typeof v.stock === 'number' ? v.stock : undefined,
          priceUsd: typeof v.priceUsd === 'number' ? v.priceUsd : undefined,
        })),
        availability: (s.availability as Product['availability']) || 'unknown',
      }

      return {
        mode: 'external',
        product: productFromScraper,
        normalizedLink,
      }
    },
  },
  payments: {
    // وضع 'auto': الطلب مدفوع منذ إنشائه، فالحالة دائماً "مدفوع".
    // وضع 'shamcash': يستعلم عن الحالة الحقيقية المخزنة بـSupabase - تتحول
    // لـ"مدفوع" فقط لما webhook شام كاش يؤكّدها.
    async checkPaymentStatus(orderId) {
      if (PAYMENT_MODE === 'auto') {
        return { mode: 'external', status: 'مدفوع', paidAt: today() }
      }

      if (!supabase) {
        return localAppApi.payments.checkPaymentStatus(orderId)
      }

      const { data, error } = await supabase.rpc('get_order_payment_status', {
        target_order_id: orderId,
      })

      if (error || !data || !(data as { found?: boolean }).found) {
        return { mode: 'external', status: 'بانتظار الدفع' }
      }

      const result = data as { paymentStatus: PaymentStatus; paidAt?: string }
      return {
        mode: 'external',
        status: result.paymentStatus,
        paidAt: result.paidAt,
      }
    },
  },
  orders: {
    async createPendingOrder(order, currency) {
      if (!supabase) {
        throw new Error('قاعدة البيانات غير متصلة. تأكد من إعدادات Supabase.')
      }

      if (PAYMENT_MODE === 'shamcash') {
        // المسار الكامل: مبلغ دفع فريد + مطابقة تلقائية (يتطلب schema.sql المطبّق)
        const { data, error } = await supabase.rpc('create_pending_order', {
          order_payload: toOrderPayload(order),
          currency,
        })
        if (error || !data) {
          throw new Error(`تعذّر إنشاء الطلب: ${error?.message ?? 'خطأ غير معروف'}`)
        }
        const result = data as { orderId: string; paymentAmount: number; paymentCurrency: PaymentCurrency; paymentExpiresAt: string }
        notifyNewOrder({ ...toOrderPayload(order), id: result.orderId })
        return {
          mode: 'external',
          orderId: result.orderId,
          paymentAmount: result.paymentAmount,
          paymentCurrency: result.paymentCurrency,
          paymentExpiresAt: result.paymentExpiresAt,
        }
      }

      // وضع 'auto': الطلب يُحفظ مباشرة بحالة "مدفوع" عبر submit_order العاملة.
      const paidOrder: Order = {
        ...order,
        paymentStatus: 'مدفوع',
        statusIndex: 1,
        paidAt: today(),
      }

      const { data, error } = await supabase.rpc('submit_order', {
        order_payload: toOrderPayload(paidOrder),
      })

      if (error || !data) {
        const isNetworkError = error?.message?.toLowerCase().includes('type error') || error?.message?.toLowerCase().includes('failed to fetch')
        const userMsg = isNetworkError
          ? 'تعذّر الاتصال بقاعدة البيانات. تحقق من اتصالك بالإنترنت وأعد المحاولة.'
          : `تعذّر حفظ الطلب في قاعدة البيانات: ${error?.message ?? 'خطأ غير معروف'}`
        throw new Error(userMsg)
      }

      const orderId = data as string
      notifyNewOrder({ ...toOrderPayload(paidOrder), id: orderId })

      const paymentAmount = currency === 'USD'
        ? Math.round((order.total / DISPLAY_USD_RATE) * 100) / 100
        : order.total

      return {
        mode: 'external',
        orderId,
        paymentAmount,
        paymentCurrency: currency,
        paymentExpiresAt: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
      }
    },
  },
}

// إشعار Telegram للمشرف عند وصول طلب جديد (fire-and-forget، غير حيوي).
// كان يستخدم سابقاً دالة Supabase Edge (telegram-notify) لكنها ترفض كل
// الطلبات بـ401 لأنها تتطلب x-admin-pin ولم يكن يُرسَل عند إنشاء طلب جديد -
// هذا هو السبب الحقيقي لعدم وصول إشعارات الطلبات الجديدة. مسار سيرفر
// Railway الحالي (/api/orders/notify) لا يتطلب أي pin ويستخدم نفس متغيرات
// TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID المُعدّة مسبقاً هناك.
function notifyNewOrder(orderPayload: Record<string, unknown>) {
  try {
    const apiBase = import.meta.env.VITE_WHATSAPP_API_URL as string | undefined
    if (apiBase) {
      void fetch(`${apiBase}/api/orders/notify`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ order: orderPayload }),
      }).catch(() => undefined)
    }
  } catch { /* إشعار غير حيوي */ }
}
