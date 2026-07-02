import { createClient } from '@supabase/supabase-js'
import { cleanEnvValue } from '../config'

const supabaseUrl = cleanEnvValue(import.meta.env.VITE_SUPABASE_URL)
const supabaseAnonKey = cleanEnvValue(import.meta.env.VITE_SUPABASE_ANON_KEY)

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseAnonKey)

export const supabase = isSupabaseConfigured
  ? createClient(supabaseUrl!, supabaseAnonKey!, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    })
  : null
