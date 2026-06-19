import { localAppApi } from './localAppApi'
import { supabaseAppApi } from './supabaseAppApi'
import { isSupabaseConfigured } from './supabaseClient'
import { isTelegramAuthEnabled, telegramAuthApi } from './telegramAuthApi'
import type { TalabiehApi } from './appApi'

// Auth: Telegram OTP إذا Supabase مكوّن، وإلا mock
// catalog: supabaseAppApi دائماً
// payments/orders: Supabase إذا مكوّن، وإلا mock محلي
export const appApi: TalabiehApi = {
  auth: isTelegramAuthEnabled ? telegramAuthApi : localAppApi.auth,
  catalog: supabaseAppApi.catalog,
  payments: isSupabaseConfigured ? supabaseAppApi.payments : localAppApi.payments,
  orders: isSupabaseConfigured ? supabaseAppApi.orders : localAppApi.orders,
}

export { isSupabaseConfigured }
