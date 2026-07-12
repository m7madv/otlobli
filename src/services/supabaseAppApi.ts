import { product } from '../domain/fixtures'
import { today } from '../domain/orders'
import { FULL_NAME_ERROR_MESSAGE, getFullNameValidationError, normalizeFullName } from '../domain/profile'
import type { PaymentCurrency } from '../domain/pricing'
import type { CartGroupSnapshot, CartItem, Order, PaymentStatus, Product, UserProfile, WalletTransaction } from '../domain/types'
import type { ProductFetchResult, TalabiehApi } from './appApi'
import { localAppApi } from './localAppApi'
import { supabase } from './supabaseClient'
import { isWhatsappApiAuthEnabled, whatsappAuthApi } from './whatsappAuthApi'
import { cleanEnvValue } from '../config'
import { readStoredJson, storageKeys } from '../infrastructure/localStorage'

const DISPLAY_USD_RATE = Number(cleanEnvValue(import.meta.env.VITE_USD_TO_SYP_RATE)) || 13000
const SUPABASE_URL = cleanEnvValue(import.meta.env.VITE_SUPABASE_URL)
const SUPABASE_ANON_KEY = cleanEnvValue(import.meta.env.VITE_SUPABASE_ANON_KEY)
const CART_GROUPS_URL = SUPABASE_URL ? `${SUPABASE_URL}/functions/v1/cart-groups` : ''

function requireCustomerSessionToken() {
  const token = readStoredJson<string>(storageKeys.sessionToken, '')
  if (!token || /^\d+$/.test(token)) {
    throw new Error('انتهت جلسة الدخول. سجّل الدخول برقم واتساب من جديد.')
  }
  return token
}

// Cloudflare Worker (fast, edge-based) with Railway as fallback
const SHEIN_WORKER_URL = cleanEnvValue(import.meta.env.VITE_SHEIN_WORKER_URL) || 'https://talabieh-shein.talabieh.workers.dev'
const SHEIN_SCRAPER_URL = cleanEnvValue(import.meta.env.VITE_SHEIN_SCRAPER_URL) || 'https://shein-scraper-production.up.railway.app'

type CatalogProductRow = {
  payload: unknown
  source_link: string | null
}

function normalizeSheinLink(link: string) {
  const value = link.trim() || product.link
  try {
    const url = new URL(value)
    if (!/shein/i.test(url.hostname)) return value
    const path = url.pathname
      .replace(/^\/(?:[a-z]{2}(?:en)?|ar-en)(?=\/|$)/i, '') || '/'
    url.protocol = 'https:'
    url.hostname = 'ar.shein.com'
    url.pathname = path
    url.searchParams.set('currency', 'USD')
    url.searchParams.set('country', 'SA')
    url.searchParams.set('lang', 'ar')
    return url.toString()
  } catch {
    return value
  }
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

function toOrderPayload(order: Order, store = '') {
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
    groupId: order.groupId ?? null,
    groupCode: order.groupCode ?? null,
    deliveryMemberKey: order.deliveryMemberKey ?? null,
    deliveryOwnerPhone: order.deliveryOwnerPhone ?? null,
    deliveryOwnerName: order.deliveryOwnerName ?? null,
    store,
  }
}

function normalizeOrder(value: unknown): Order | null {
  if (!value || typeof value !== 'object') return null
  const row = value as Record<string, unknown>
  const items = Array.isArray(row.items) ? row.items.filter((item): item is CartItem => !!item && typeof item === 'object') : []
  if (typeof row.id !== 'string') return null
  return {
    id: row.id,
    customer: typeof row.customer === 'string' ? row.customer : '',
    phone: typeof row.phone === 'string' ? row.phone : '',
    city: typeof row.city === 'string' ? row.city : '',
    address: typeof row.address === 'string' ? row.address : '',
    items,
    total: typeof row.total === 'number' ? row.total : Number(row.total ?? 0),
    paymentStatus: row.paymentStatus as PaymentStatus,
    statusIndex: typeof row.statusIndex === 'number' ? row.statusIndex : Number(row.statusIndex ?? 0),
    qadmousNumber: typeof row.qadmousNumber === 'string' ? row.qadmousNumber : '',
    createdAt: typeof row.createdAt === 'string' ? row.createdAt : today(),
    paidAt: typeof row.paidAt === 'string' ? row.paidAt : undefined,
    rating: typeof row.rating === 'number' ? row.rating : undefined,
    ratingNote: typeof row.ratingNote === 'string' ? row.ratingNote : undefined,
    paymentIssue: Boolean(row.paymentIssue),
    paymentIssueNote: typeof row.paymentIssueNote === 'string' ? row.paymentIssueNote : '',
    extraAmountUsd: typeof row.extraAmountUsd === 'number' ? row.extraAmountUsd : Number(row.extraAmountUsd ?? 0),
    invoice: Array.isArray(row.invoice)
      ? row.invoice
        .map((line) => {
          const rec = (line && typeof line === 'object' ? line : {}) as Record<string, unknown>
          return { label: String(rec.label ?? ''), amountUsd: Number(rec.amountUsd) || 0 }
        })
        .filter((line) => line.label.trim() !== '')
      : undefined,
    issues: Array.isArray(row.issues)
      ? row.issues
        .filter((it): it is Record<string, unknown> => !!it && typeof it === 'object' && typeof (it as Record<string, unknown>).id === 'string')
        .map((it) => it as unknown as import('../domain/types').OrderIssue)
      : undefined,
    groupId: typeof row.groupId === 'string' ? row.groupId : undefined,
    groupCode: typeof row.groupCode === 'string' ? row.groupCode : undefined,
    groupMembers: Array.isArray(row.groupMembers)
      ? row.groupMembers.map((member) => {
        const value = (member && typeof member === 'object' ? member : {}) as Record<string, unknown>
        return {
          memberKey: typeof value.memberKey === 'string' ? value.memberKey : undefined,
          phone: String(value.phone ?? ''),
          name: String(value.name ?? ''),
          role: value.role === 'host' ? 'host' as const : 'member' as const,
        }
      })
      : undefined,
    deliveryMemberKey: typeof row.deliveryMemberKey === 'string' ? row.deliveryMemberKey : undefined,
    deliveryOwnerPhone: typeof row.deliveryOwnerPhone === 'string' ? row.deliveryOwnerPhone : undefined,
    deliveryOwnerName: typeof row.deliveryOwnerName === 'string' ? row.deliveryOwnerName : undefined,
  }
}

function normalizeCustomerAccount(data: unknown) {
  const row = (data && typeof data === 'object' ? data : {}) as Record<string, unknown>
  const profile = row.profile && typeof row.profile === 'object'
    ? row.profile as UserProfile
    : null
  const orders = Array.isArray(row.orders)
    ? row.orders.map(normalizeOrder).filter((order): order is Order => !!order)
    : []
  const walletTransactions = Array.isArray(row.walletTransactions)
    ? row.walletTransactions
      .filter((item): item is WalletTransaction => !!item && typeof item === 'object')
      .map((item) => ({
        ...item,
        amountSyp: Number(item.amountSyp) || 0,
        amountUsd: Number.isFinite(Number(item.amountUsd)) ? Number(item.amountUsd) : undefined,
      }))
    : []
  return {
    mode: 'external' as const,
    profile,
    orders,
    walletBalanceSyp: typeof row.walletBalanceSyp === 'number' ? row.walletBalanceSyp : Number(row.walletBalanceSyp ?? 0),
    walletTransactions,
  }
}

function normalizeCartGroup(data: unknown): CartGroupSnapshot {
  const row = (data && typeof data === 'object' ? data : {}) as Record<string, unknown>
  return {
    id: String(row.id ?? ''),
    code: String(row.code ?? ''),
    sourceStore: typeof row.sourceStore === 'string' ? row.sourceStore : undefined,
    status: String(row.status ?? 'open'),
    minTotalUsd: Number(row.minTotalUsd ?? 40),
    totalUsd: Number(row.totalUsd ?? 0),
    members: Array.isArray(row.members)
      ? row.members.map((member) => {
        const m = (member && typeof member === 'object' ? member : {}) as Record<string, unknown>
        return {
          memberKey: typeof m.memberKey === 'string' ? m.memberKey : undefined,
          phone: String(m.phone ?? ''),
          name: String(m.name ?? ''),
          role: m.role === 'host' ? 'host' : 'member',
        }
      })
      : [],
    items: Array.isArray(row.items)
      ? row.items.map((entry) => {
        const line = (entry && typeof entry === 'object' ? entry : {}) as Record<string, unknown>
        return {
          ownerMemberKey: typeof line.ownerMemberKey === 'string' ? line.ownerMemberKey : undefined,
          ownerPhone: String(line.ownerPhone ?? ''),
          ownerName: String(line.ownerName ?? ''),
          item: line.item as CartItem,
        }
      }).filter((entry) => !!entry.item)
      : [],
  }
}

function extractCartGroupCode(value: string) {
  const raw = value.trim()
  try {
    const url = new URL(raw)
    return (url.searchParams.get('group') || url.searchParams.get('code') || raw)
      .trim()
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, '')
  } catch {
    return raw.toUpperCase().replace(/[^A-Z0-9]/g, '')
  }
}

async function postCartGroup(body: Record<string, unknown>) {
  if (!CART_GROUPS_URL) throw new Error('تعذر الوصول إلى خدمة الطلب المشترك حالياً. حاول مرة أخرى.')

  const response = await fetch(CART_GROUPS_URL, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_ANON_KEY,
      authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(body),
  })
  const data = await response.json().catch(() => null)
  if (!response.ok || !data) {
    const error = (data && typeof data === 'object' ? (data as { error?: string }).error : '') || ''
    if (error === 'group_not_found') throw new Error('كود الصديق غير صحيح أو انتهت صلاحيته.')
    if (error === 'missing_code') throw new Error('أدخل كود أو رابط الصديق أولاً.')
    if (error === 'same_customer') throw new Error('لا يمكن الانضمام لنفس السلة بنفس رقم واتساب. افتح الرابط من حساب صديقك أو سجّل دخول برقم مختلف.')
    if (error === 'group_full') throw new Error('هذه السلة مرتبطة بشخصين بالفعل.')
    throw new Error('تعذر تحديث الطلب المشترك حالياً. حاول مرة أخرى.')
  }
  return normalizeCartGroup(data)
}

function getPublicDbError(prefix: string, message?: string) {
  const raw = message || 'خطأ غير معروف'
  if (/schema cache|Could not find the function|PGRST202|function public\\./i.test(raw)) {
    return `${prefix}: تحديث قاعدة البيانات لم يصل بعد. أعد فتح التطبيق بعد دقيقة أو تواصل مع الإدارة إذا استمر الخطأ.`
  }
  return `${prefix}: ${raw}`
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
    async checkPaymentStatus(orderId) {
      if (!supabase) {
        return localAppApi.payments.checkPaymentStatus(orderId)
      }

      const { data, error } = await supabase.rpc('get_order_payment_status', {
        target_order_id: orderId,
        p_session_token: requireCustomerSessionToken(),
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
  wallet: {
    async createTopUp(phone, name, amountUsd) {
      if (!supabase) {
        return localAppApi.wallet.createTopUp(phone, name, amountUsd)
      }

      const { data, error } = await supabase.rpc('create_wallet_topup', {
        p_phone: phone.trim(),
        p_name: name.trim(),
        p_amount_usd: Math.round(amountUsd * 100) / 100,
        p_session_token: requireCustomerSessionToken(),
      })

      if (error || !data) {
        throw new Error(getPublicDbError('تعذّر إنشاء شحن المحفظة', error?.message))
      }

      const result = data as {
        topUpId: string
        paymentAmount: number
        paymentCurrency: PaymentCurrency
        paymentExpiresAt: string
        creditAmountSyp?: number
      }

      return {
        mode: 'external',
        topUpId: result.topUpId,
        paymentAmount: Number(result.paymentAmount),
        paymentCurrency: result.paymentCurrency,
        paymentExpiresAt: result.paymentExpiresAt,
        creditAmountSyp: Number(result.creditAmountSyp ?? result.paymentAmount),
      }
    },

    async checkTopUpStatus(topUpId) {
      if (!supabase) {
        return localAppApi.wallet.checkTopUpStatus(topUpId)
      }

      const { data, error } = await supabase.rpc('get_wallet_topup_status', {
        target_topup_id: topUpId,
        p_session_token: requireCustomerSessionToken(),
      })

      if (error || !data || !(data as { found?: boolean }).found) {
        return {
          mode: 'external',
          status: 'بانتظار الدفع',
          creditAmountSyp: 0,
          walletBalanceSyp: 0,
        }
      }

      const result = data as {
        status: 'بانتظار الدفع' | 'مدفوع' | 'منتهي' | 'فشل المطابقة'
        paidAt?: string
        creditAmountSyp?: number
        walletBalanceSyp?: number
      }

      return {
        mode: 'external',
        status: result.status,
        paidAt: result.paidAt,
        creditAmountSyp: Number(result.creditAmountSyp ?? 0),
        walletBalanceSyp: Number(result.walletBalanceSyp ?? 0),
      }
    },

    async getBalance(phone) {
      if (!supabase) return localAppApi.wallet.getBalance(phone)
      const { data, error } = await supabase.rpc('get_wallet_balance_usd', {
        p_phone: phone.trim(),
        p_session_token: requireCustomerSessionToken(),
      })
      if (error) return 0
      return Number(data ?? 0)
    },

    async spend(phone, amountUsd, orderId) {
      if (!supabase) return localAppApi.wallet.spend(phone, amountUsd, orderId)
      void phone
      void amountUsd
      void orderId
      throw new Error('خصم المحفظة يتم الآن ذرياً داخل إنشاء الطلب.')
    },
  },
  customers: {
    async getAccount(phone) {
      if (!supabase) {
        return localAppApi.customers.getAccount(phone)
      }

      const { data, error } = await supabase.rpc('get_customer_account', {
        p_phone: phone.trim(),
        p_session_token: requireCustomerSessionToken(),
      })

      if (error) {
        return {
          mode: 'external',
          profile: null,
          orders: [],
          walletBalanceSyp: 0,
          walletTransactions: [],
        }
      }

      return normalizeCustomerAccount(data)
    },

    async saveProfile(phone, profile) {
      if (!supabase) {
        return localAppApi.customers.saveProfile(phone, profile)
      }

      const name = normalizeFullName(profile.name)
      if (getFullNameValidationError(name)) {
        throw new Error(FULL_NAME_ERROR_MESSAGE)
      }

      const { data, error } = await supabase.rpc('upsert_customer_profile', {
        p_phone: (profile.phone || phone).trim(),
        p_name: name,
        p_governorate: profile.governorate || '\u062F\u0645\u0634\u0642',
        p_qadmous_branch: profile.qadmousBranch ?? '',
        p_city: profile.city ?? '',
        p_details: profile.details ?? '',
        p_session_token: requireCustomerSessionToken(),
      })

      if (error) throw new Error(getPublicDbError('\u062A\u0639\u0630\u0631 \u062D\u0641\u0638 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645', error.message))

      const baseAccount = normalizeCustomerAccount(data)
      const nextPickupLabel =
        typeof profile.pickupLabel === 'string'
          ? profile.pickupLabel
          : (baseAccount.profile?.pickupLabel ?? '')
      const nextNotificationPrefs =
        profile.notificationPrefs && typeof profile.notificationPrefs === 'object'
          ? profile.notificationPrefs
          : (baseAccount.profile?.notificationPrefs ?? {})

      const { data: prefsData, error: prefsError } = await supabase.rpc('update_customer_preferences', {
        p_phone: (profile.phone || phone).trim(),
        p_pickup_label: nextPickupLabel,
        p_notification_prefs: nextNotificationPrefs,
        p_session_token: requireCustomerSessionToken(),
      })

      if (prefsError) {
        throw new Error(getPublicDbError('\u062A\u0639\u0630\u0631 \u062D\u0641\u0638 \u062A\u0641\u0636\u064A\u0644\u0627\u062A \u0627\u0644\u0639\u0645\u064A\u0644', prefsError.message))
      }

      return normalizeCustomerAccount(prefsData ?? data)
    },
  },
  cartGroups: {
    async create(phone, name, store, items, memberKey) {
      if (!supabase || !CART_GROUPS_URL) return localAppApi.cartGroups.create(phone, name, store, items)

      return postCartGroup({
        action: 'create',
        phone: phone.trim(),
        name: name.trim(),
        memberKey,
        store,
        items,
      })
    },

    async join(phone, name, code, items, memberKey) {
      const inviteCode = extractCartGroupCode(code)
      if (!supabase || !CART_GROUPS_URL) return localAppApi.cartGroups.join(phone, name, inviteCode, items)
      return postCartGroup({
        action: 'join',
        phone: phone.trim(),
        name: name.trim(),
        memberKey,
        code: inviteCode,
        items,
      })
    },

    async syncItems(phone, groupId, items, memberKey) {
      if (!supabase || !CART_GROUPS_URL) return localAppApi.cartGroups.syncItems(phone, groupId, items)
      return postCartGroup({
        action: 'sync',
        phone: phone.trim(),
        memberKey,
        groupId,
        items,
      })
    },

    async cancel(_phone, groupId) {
      if (!supabase || !CART_GROUPS_URL) { await localAppApi.cartGroups.cancel(_phone, groupId); return }
      const response = await fetch(CART_GROUPS_URL, {
        method: 'POST',
        headers: {
          apikey: SUPABASE_ANON_KEY,
          authorization: `Bearer ${SUPABASE_ANON_KEY}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({ action: 'cancel', groupId }),
      })
      if (!response.ok) throw new Error('تعذر إلغاء المجموعة')
    },
  },
  orders: {
    async createPendingOrder(order, currency, walletSpendUsd = 0, store = '') {
      if (!supabase) {
        throw new Error('قاعدة البيانات غير متصلة. تأكد من إعدادات Supabase.')
      }

      const { data, error } = await supabase.rpc('create_pending_order_v2', {
        order_payload: toOrderPayload(order, store),
        currency,
        p_session_token: requireCustomerSessionToken(),
        p_wallet_spend_usd: Math.max(0, Number(walletSpendUsd) || 0),
      })
      if (error || !data) {
        throw new Error(getPublicDbError('تعذّر إنشاء الطلب', error?.message))
      }

      const result = data as {
        orderId: string
        paymentAmount: number
        paymentCurrency: PaymentCurrency
        paymentExpiresAt: string
        paymentStatus?: PaymentStatus
        walletBalanceUsd?: number
      }
      notifyNewOrder({
        ...toOrderPayload(order, store),
        id: result.orderId,
        paymentAmount: result.paymentAmount,
        paymentCurrency: result.paymentCurrency,
        paymentExpiresAt: result.paymentExpiresAt,
        paymentStatus: result.paymentStatus,
      })

      return {
        mode: 'external',
        orderId: result.orderId,
        paymentAmount: Number(result.paymentAmount),
        paymentCurrency: result.paymentCurrency,
        paymentExpiresAt: result.paymentExpiresAt,
        paymentStatus: result.paymentStatus,
        walletBalanceUsd: Number(result.walletBalanceUsd ?? 0),
      }
    },

    // يستعلم دائماً عن قاعدة البيانات الحقيقية (بعكس checkPaymentStatus التي
    // تتجاوز الاستعلام في وضع 'auto') - شاشة التتبع تحتاج تقدّم المرحلة
    // الحقيقي (قيد الشراء، الشحن...) بغض النظر عن وضع الدفع. لا يستعلم
    // الجدول orders مباشرة لأنه محمي بـRLS بدون policy عامة للقراءة؛ يستخدم
    // نفس RPC الضيقة get_order_payment_status المسموحة لـanon.
    async createIssuePayment(orderId, amountUsd, currency) {
      if (!supabase) {
        throw new Error('قاعدة البيانات غير متصلة. تأكد من إعدادات Supabase.')
      }
      const { data, error } = await supabase.rpc('create_order_issue_payment', {
        p_order_id: orderId,
        p_amount_usd: amountUsd,
        p_currency: currency,
        p_session_token: requireCustomerSessionToken(),
      })
      if (error || !data) {
        throw new Error(getPublicDbError('تعذر إنشاء طلب الدفع', error?.message))
      }
      const result = data as {
        issuePaymentId: string
        orderId: string
        paymentAmount: number
        paymentCurrency: PaymentCurrency
        paymentExpiresAt: string
      }
      return {
        mode: 'external',
        issuePaymentId: result.issuePaymentId,
        orderId: result.orderId,
        paymentAmount: result.paymentAmount,
        paymentCurrency: result.paymentCurrency,
        paymentExpiresAt: result.paymentExpiresAt,
      }
    },

    async pollOrderStatus(orderId) {
      if (!supabase) return null

      const { data, error } = await supabase.rpc('get_order_payment_status', {
        target_order_id: orderId,
        p_session_token: requireCustomerSessionToken(),
      })

      if (error || !data || !(data as { found?: boolean }).found) return null

      const result = data as {
        statusIndex: number
        paymentStatus: PaymentStatus
        paidAt?: string
        qadmousNumber?: string
        paymentIssue?: boolean
        paymentIssueNote?: string
        extraAmountUsd?: number
      }

      return {
        statusIndex: result.statusIndex,
        paymentStatus: result.paymentStatus,
        paidAt: result.paidAt,
        qadmousNumber: result.qadmousNumber ?? '',
        paymentIssue: result.paymentIssue ?? false,
        paymentIssueNote: result.paymentIssueNote ?? '',
        extraAmountUsd: result.extraAmountUsd ?? 0,
      }
    },

    // يتحقق من قاعدة البيانات أن كود الإحالة هو رقم هاتف عميل سابق فعلاً، لا
    // أي نص عشوائي - الجدول orders محمي بـRLS فيستخدم RPC ضيقة مخصصة لهذا.
    async validateReferralCode(code) {
      if (!supabase) return false
      const { data, error } = await supabase.rpc('check_referral_code', { ref_phone: code.trim() })
      if (error) return false
      return Boolean(data)
    },

    async redeemCoupon(input) {
      if (!supabase) return { valid: false, discountSyp: 0, reason: 'offline' as const }
      const { data, error } = await supabase.rpc('redeem_coupon', {
        p_code: input.code.trim(),
        p_phone: input.phone.trim(),
        p_device_id: input.deviceId || '',
        p_store: input.store || 'all',
        p_subtotal_syp: Math.max(0, Math.round(input.subtotalSyp)),
        p_usd_rate: DISPLAY_USD_RATE,
        p_session_token: requireCustomerSessionToken(),
      })
      if (error || !data) return { valid: false, discountSyp: 0, reason: 'error' as const }

      const row = data as { valid?: boolean; discountSyp?: number; code?: string; reason?: string }
      return {
        valid: Boolean(row.valid),
        discountSyp: Math.max(0, Number(row.discountSyp) || 0),
        code: row.code,
        reason: row.reason,
      }
    },

    // يحفظ التقييم عبر RPC ضيقة تتحقق إنه الطلب مُسلَّم وغير مُقيَّم سابقاً
    // قبل الكتابة - بلا ذلك ما في طريقة عامة لتعديل صفوف orders من العميل.
    async submitOrderRating(orderId, stars, note) {
      if (!supabase) return false
      const { data, error } = await supabase.rpc('submit_order_rating', {
        target_order_id: orderId,
        p_stars: stars,
        p_note: note.trim(),
        p_session_token: requireCustomerSessionToken(),
      })
      if (error) return false
      return Boolean(data)
    },

    // تصحيح تخصيص عنصر في طلب قائم (صورة مقصوصة و/أو نص) — يحدّث حقول
    // التخصيص فقط في order_items ويظهر فوراً للوحة الإدارة.
    async submitCustomFix(orderId, productId, photoDataUrl, customText) {
      if (!supabase) return false
      const { data, error } = await supabase.rpc('submit_order_custom_fix', {
        target_order_id: orderId,
        p_product_id: productId,
        p_custom_photo: photoDataUrl || '',
        p_custom_text: (customText || '').trim(),
        p_session_token: requireCustomerSessionToken(),
      })
      if (error) return false
      return Boolean(data)
    },

    // اختيار الزبون من «الخيارات المتاحة» في مشكلة الطلب (مقاس/لون) —
    // يحدّث عنصر الطلب مباشرة عبر الغلاف الموقّع بالجلسة.
    async submitOptionFix(orderId, productId, field, value) {
      if (!supabase) return false
      const { data, error } = await supabase.rpc('submit_order_option_fix', {
        target_order_id: orderId,
        p_product_id: productId,
        p_field: field,
        p_value: value,
        p_session_token: requireCustomerSessionToken(),
      })
      if (error) return false
      return Boolean(data)
    },

    // يعلّم مشكلة منظمة كمحلولة (بعد أن يحلها الزبون فعلياً عبر RPC المختصة).
    async submitIssueResolve(orderId, issueId, resolvedValue, resolvedPhotoDataUrl = '') {
      if (!supabase) return false
      const { data, error } = await supabase.rpc('submit_order_issue_resolve', {
        target_order_id: orderId,
        p_issue_id: issueId,
        p_resolved_value: resolvedValue || '',
        p_resolved_photo_data_url: resolvedPhotoDataUrl || '',
        p_session_token: requireCustomerSessionToken(),
      })
      if (error) return false
      return Boolean(data)
    },
  },
}

// The client must never be able to trigger operator notifications directly.
// The signed payment webhook sends the notification after a real match.
function notifyNewOrder(orderPayload: Record<string, unknown>) {
  void orderPayload
}

