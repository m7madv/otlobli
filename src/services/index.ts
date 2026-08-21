import { supabaseAppApi } from './supabaseAppApi'
import { isSupabaseConfigured } from './supabaseClient'
import { phoneAuthApi } from './phoneAuthApi'
import type { TalabiehApi } from './appApi'

export const appApi: TalabiehApi = {
  auth: phoneAuthApi,
  catalog: supabaseAppApi.catalog,
  // ممنوع الـ fallback الصامت لـ localAppApi: الطلبات والمدفوعات تمرّ دائماً عبر
  // Supabase. إن لم يكن مُعدّاً (مفاتيح مفقودة في البناء)، يرمي supabaseAppApi
  // خطأً واضحاً يراه المستخدم بدل أن "يُحفظ" الطلب محلياً ولا يصل أبداً.
  payments: supabaseAppApi.payments,
  wallet: supabaseAppApi.wallet,
  customers: supabaseAppApi.customers,
  cartGroups: supabaseAppApi.cartGroups,
  orders: supabaseAppApi.orders,
}

export { isSupabaseConfigured }
