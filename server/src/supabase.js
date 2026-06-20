import { createClient } from '@supabase/supabase-js'
import ws from 'ws'

const url = process.env.SUPABASE_URL || ''
const key = process.env.SUPABASE_SERVICE_ROLE_KEY || ''

export const supabase = url && key
  ? createClient(url, key, { realtime: { transport: ws } })
  : null

export function isSupabaseConfigured() {
  return !!supabase
}
