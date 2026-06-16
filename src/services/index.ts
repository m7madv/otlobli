import { localAppApi } from './localAppApi'
import { supabaseAppApi } from './supabaseAppApi'
import { isSupabaseConfigured } from './supabaseClient'
import { isWhatsappApiAuthEnabled, whatsappAuthApi } from './whatsappAuthApi'
import type { TalabiehApi } from './appApi'

// السكرايبر يعمل دائماً بغض النظر عن Supabase
// Auth: WhatsApp server إذا مفعّل، وإلا mock
// catalog: supabaseAppApi دائماً (يجرب السكرايبر ثم يرجع للـ mock)
// payments/orders: Supabase إذا مكوّن، وإلا mock محلي
export const appApi: TalabiehApi = {
  auth: isWhatsappApiAuthEnabled ? whatsappAuthApi : localAppApi.auth,
  catalog: supabaseAppApi.catalog,
  payments: isSupabaseConfigured ? supabaseAppApi.payments : localAppApi.payments,
  orders: isSupabaseConfigured ? supabaseAppApi.orders : localAppApi.orders,
}

export { isSupabaseConfigured }
