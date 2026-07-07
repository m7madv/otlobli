import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
const CODE_LENGTH = 7

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

function makeInviteCode() {
  const bytes = new Uint8Array(CODE_LENGTH)
  crypto.getRandomValues(bytes)
  let code = ''
  for (const byte of bytes) code += CODE_ALPHABET[byte % CODE_ALPHABET.length]
  return code
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  try {
    const body = await req.json() as {
      phone?: string
      name?: string
      store?: string
      items?: unknown[]
    }
    const phone = (body.phone ?? '').replace(/\s+/g, '')
    const name = (body.name ?? '').trim() || 'صاحب الطلب'
    const store = (body.store ?? 'shein').trim() || 'shein'
    const items = Array.isArray(body.items) ? body.items : []

    if (!phone) return json({ error: 'missing_phone' }, 400)

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
    const { data: customerId, error: customerError } = await supabase.rpc('ensure_customer', {
      p_phone: phone,
      p_name: name,
      p_governorate: 'دمشق',
      p_city: '',
      p_details: '',
      p_qadmous_branch: '',
    })
    if (customerError || !customerId) return json({ error: 'create_failed' }, 500)

    let groupId = ''
    for (let attempt = 0; attempt < 16 && !groupId; attempt += 1) {
      const code = makeInviteCode()
      const { data, error } = await supabase
        .from('cart_groups')
        .insert({ code, host_customer_id: customerId, source_store: store })
        .select('id')
        .single()

      if (!error && data?.id) groupId = data.id
      else if (error && error.code !== '23505') return json({ error: 'create_failed' }, 500)
    }

    if (!groupId) return json({ error: 'create_failed' }, 500)

    const { error: memberError } = await supabase
      .from('cart_group_members')
      .upsert({
        group_id: groupId,
        customer_id: customerId,
        phone,
        display_name: name,
        role: 'host',
      }, { onConflict: 'group_id,customer_id' })
    if (memberError) return json({ error: 'create_failed' }, 500)

    const { error: replaceError } = await supabase.rpc('replace_cart_group_items', {
      p_group_id: groupId,
      p_customer_id: customerId,
      p_items: items,
    })
    if (replaceError) return json({ error: 'create_failed' }, 500)

    const { data: snapshot, error: snapshotError } = await supabase.rpc('cart_group_snapshot', {
      p_group_id: groupId,
    })
    if (snapshotError || !snapshot) return json({ error: 'create_failed' }, 500)

    return json(snapshot)
  } catch {
    return json({ error: 'create_failed' }, 500)
  }
})
