import { supabase } from './supabaseClient'
import { signOutNativeIdentityProviders } from './socialLoginNative'
import { cleanEnvValue } from '../config'

const SUPABASE_URL = cleanEnvValue(import.meta.env.VITE_SUPABASE_URL)
const SUPABASE_ANON_KEY = cleanEnvValue(import.meta.env.VITE_SUPABASE_ANON_KEY)

export async function deleteCustomerAccount(sessionToken: string): Promise<void> {
  if (!supabase || !sessionToken) throw new Error('انتهت جلسة الدخول. سجّل الدخول مجدداً.')
  const response = await fetch(`${SUPABASE_URL}/functions/v1/account-lifecycle`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      apikey: SUPABASE_ANON_KEY,
      authorization: `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({ action: 'delete', sessionToken }),
  })
  const result = await response.json().catch(() => ({})) as { deleted?: boolean; message?: string }
  if (!response.ok) throw new Error(result.message || 'تعذر حذف الحساب الآن. حاول مجدداً أو تواصل مع الدعم.')
  if (!result.deleted) throw new Error('تعذر تأكيد حذف الحساب.')
  await signOutNativeIdentityProviders()
}

export { signOutNativeIdentityProviders }
