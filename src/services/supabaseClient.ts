import { createClient } from '@supabase/supabase-js'

function stripBom(s: string | undefined): string | undefined {
  return s?.replace(/^﻿/, '').trim()
}

const supabaseUrl = stripBom(import.meta.env.VITE_SUPABASE_URL)
const supabaseAnonKey = stripBom(import.meta.env.VITE_SUPABASE_ANON_KEY)

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseAnonKey)

export const supabase = isSupabaseConfigured
  ? createClient(supabaseUrl!, supabaseAnonKey!, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    })
  : null
