import { createClient } from '@supabase/supabase-js'
import { ApiError } from './http.js'

export function getEnv(name) {
  return process.env[name]?.trim() || ''
}

export function getOptionalEnv(name, fallback) {
  return getEnv(name) || fallback
}

export function createServerSupabaseClient() {
  const supabaseUrl = getEnv('SUPABASE_URL') || getEnv('VITE_SUPABASE_URL')
  const serviceRoleKey = getEnv('SUPABASE_SERVICE_ROLE_KEY')

  if (!supabaseUrl || !serviceRoleKey) {
    throw new ApiError(
      'supabase_not_configured',
      503,
      'قاعدة البيانات غير مجهزة لحفظ رموز واتساب بعد.',
    )
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  })
}
