import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const MAX_GROUP_ITEMS = 200
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })
}

function cleanCode(value: string) {
  try {
    const url = new URL(value)
    return (url.searchParams.get('group') || url.searchParams.get('code') || value)
      .trim()
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, '')
  } catch {
    return value.trim().toUpperCase().replace(/[^A-Z0-9]/g, '')
  }
}

function databaseErrorText(error: { message?: string; details?: string; hint?: string } | null) {
  return [error?.message, error?.details, error?.hint].filter(Boolean).join(' ')
}

function databaseErrorResponse(
  error: { code?: string; message?: string; details?: string; hint?: string },
  action: string,
) {
  const errorText = databaseErrorText(error)
  if (/invalid_session/i.test(errorText)) return json({ error: 'invalid_session' }, 401)
  if (/group_not_open/i.test(errorText)) return json({ error: 'group_closed' }, 409)
  if (/not_group_member/i.test(errorText)) return json({ error: 'not_member' }, 403)
  if (/invalid_group_items|invalid input syntax|out of range/i.test(errorText)) {
    return json({ error: 'invalid_group_items' }, 400)
  }
  if (
    action === 'join' &&
    error.code === '23505' &&
    /cart_group_members_one_friend_per_group_idx/i.test(errorText)
  ) {
    return json({ error: 'group_full', message: 'المجموعة ممتلئة — شخصان فقط' }, 409)
  }
  return json({ error: action === 'create' ? 'create_failed' : 'member_failed' }, 500)
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  try {
    const body = await req.json() as {
      action?: string
      store?: string
      code?: string
      groupId?: string
      sessionToken?: string
      items?: unknown
    }
    const action = (body.action ?? 'create').trim().toLowerCase()
    if (!['create', 'join', 'sync', 'cancel'].includes(action)) {
      return json({ error: 'bad_action' }, 400)
    }
    let phone = ''
    let name = 'عضو'
    const store = body.store?.trim().toLowerCase() === 'temu' ? 'temu' : 'shein'
    const sessionToken = (body.sessionToken ?? '').trim()

    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return json({ error: 'not_configured' }, 500)
    if (!sessionToken || sessionToken.length > 512) return json({ error: 'invalid_session' }, 401)
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
    const { data: sessionCustomerId, error: sessionError } = await supabase.rpc('require_customer_session', {
      p_session_token: sessionToken,
      p_phone: null,
    })
    if (sessionError || !sessionCustomerId) return json({ error: 'invalid_session' }, 401)
    const customerId = String(sessionCustomerId)

    const { data: customer, error: customerError } = await supabase
      .from('customers')
      .select('phone, name')
      .eq('id', customerId)
      .single()
    if (customerError || !customer?.phone) return json({ error: 'customer_failed' }, 500)
    phone = String(customer.phone).replace(/\s+/g, '')
    name = String(customer.name || '').trim() || 'عضو'

    if (action === 'cancel') {
      const groupId = (body.groupId ?? '').trim()
      if (!groupId) return json({ error: 'missing_group' }, 400)
      if (!UUID_PATTERN.test(groupId)) return json({ error: 'invalid_group' }, 400)

      const { data: leaveState, error: leaveError } = await supabase.rpc('leave_cart_group_authenticated', {
        p_session_token: sessionToken,
        p_group_id: groupId,
      })
      if (leaveError) return databaseErrorResponse(leaveError, action)
      if (typeof leaveState === 'string' && leaveState.startsWith('closed:')) {
        return json({ error: 'group_closed' }, 409)
      }
      return json({ ok: true })
    }

    if (!Array.isArray(body.items) || body.items.length > MAX_GROUP_ITEMS) {
      return json({ error: 'invalid_group_items' }, 400)
    }
    const items = body.items

    if (action === 'create') {
      const { data: snapshot, error: createError } = await supabase.rpc('create_cart_group_authenticated', {
        p_session_token: sessionToken,
        p_store: store,
        p_phone: phone,
        p_name: name,
        p_items: items,
      })
      if (createError) return databaseErrorResponse(createError, action)
      if (!snapshot || typeof snapshot !== 'object' || Array.isArray(snapshot)) {
        return json({ error: 'snapshot_failed' }, 500)
      }
      return json(snapshot)
    }

    let groupId = ''
    let role = 'member'
    if (action === 'join') {
      const code = cleanCode(body.code ?? '')
      if (!code) return json({ error: 'missing_code' }, 400)

      const { data: foundGroup, error: findError } = await supabase
        .from('cart_groups')
        .select('id, host_customer_id, expires_at')
        .eq('code', code)
        .eq('status', 'open')
        .gt('expires_at', new Date().toISOString())
        .maybeSingle()
      if (findError || !foundGroup?.id) return json({ error: 'group_not_found' }, 404)
      if (String(foundGroup.host_customer_id) === customerId) return json({ error: 'same_customer' }, 400)
      groupId = foundGroup.id

      role = 'member'
    } else {
      groupId = (body.groupId ?? '').trim()
      if (!groupId) return json({ error: 'missing_group' }, 400)
      if (!UUID_PATTERN.test(groupId)) return json({ error: 'invalid_group' }, 400)
    }

    const { data: snapshot, error: saveError } = await supabase.rpc('save_cart_group_member_authenticated', {
      p_session_token: sessionToken,
      p_group_id: groupId,
      p_phone: phone,
      p_name: name,
      p_role: role,
      p_allow_insert: action === 'join',
      p_items: items,
    })
    if (saveError) return databaseErrorResponse(saveError, action)
    if (!snapshot || typeof snapshot !== 'object' || Array.isArray(snapshot)) {
      return json({ error: 'snapshot_failed' }, 500)
    }
    return json(snapshot)
  } catch {
    return json({ error: 'create_failed' }, 500)
  }
})
