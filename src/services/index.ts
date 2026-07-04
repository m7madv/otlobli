import { localAppApi } from './localAppApi'
import { supabaseAppApi } from './supabaseAppApi'
import { isSupabaseConfigured } from './supabaseClient'
import { isWhatsappApiAuthEnabled, whatsappAuthApi } from './whatsappAuthApi'
import type { TalabiehApi } from './appApi'

export const appApi: TalabiehApi = {
  auth: isWhatsappApiAuthEnabled ? whatsappAuthApi : localAppApi.auth,
  users: supabaseAppApi.users,
  wallet: supabaseAppApi.wallet,
  catalog: supabaseAppApi.catalog,
  // ممنوع الـ fallback الصامت لـ localAppApi: الطلبات والمدفوعات تمرّ دائماً عبر
  // Supabase. إن لم يكن مُعدّاً (مفاتيح مفقودة في البناء)، يرمي supabaseAppApi
  // خطأً واضحاً يراه المستخدم بدل أن "يُحفظ" الطلب محلياً ولا يصل أبداً.
  payments: supabaseAppApi.payments,
  orders: supabaseAppApi.orders,
}

export { isSupabaseConfigured }
