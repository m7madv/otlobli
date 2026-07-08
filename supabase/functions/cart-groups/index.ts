import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
const CODE_LENGTH = 7
const MIN_TOTAL_USD = 40
const MAX_MEMBERS = 2

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

function getItemNumber(item: unknown, key: string, fallback = 0) {
  if (!item || typeof item !== 'object') return fallback
  const value = (item as Record<string, unknown>)[key]
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : fallback
}

function getItemId(item: unknown, index: number, customerId: string) {
  if (item && typeof item === 'object') {
    const row = item as Record<string, unknown>
    const value = row.id ?? row.localItemId
    if (value) return String(value)
  }
  return `${customerId}-${index}`
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  try {
    const body = await req.json() as {
      action?: string
      phone?: string
      name?: string
      store?: string
      code?: string
      groupId?: string
      items?: unknown[]
    }
    const action = (body.action ?? 'create').trim().toLowerCase()
    const phone = (body.phone ?? '').replace(/\s+/g, '')
    const name = (body.name ?? '').trim() || 'Customer'
    const store = (body.store ?? 'shein').trim() || 'shein'
    const items = Array.isArray(body.items) ? body.items : []

    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return json({ error: 'not_configured' }, 500)
    if (!phone) return json({ error: 'missing_phone' }, 400)

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
    const { data: customerId, error: customerError } = await supabase.rpc('ensure_customer', {
      p_phone: phone,
      p_name: name,
      p_governorate: 'Damascus',
      p_city: '',
      p_details: '',
      p_qadmous_branch: '',
    })
    if (customerError || !customerId) return json({ error: 'customer_failed' }, 500)

    let groupId = ''
    let role = 'member'

    if (action === 'create') {
      role = 'host'
      const { data: existing } = await supabase
        .from('cart_groups')
        .select('id')
        .eq('host_customer_id', customerId)
        .eq('source_store', store)
        .eq('status', 'open')
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (existing?.id) groupId = existing.id

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
    } else if (action === 'join') {
      const code = cleanCode(body.code ?? '')
      if (!code) return json({ error: 'missing_code' }, 400)

      const { data: foundGroup, error: findError } = await supabase
        .from('cart_groups')
        .select('id, host_customer_id')
        .eq('code', code)
        .eq('status', 'open')
        .maybeSingle()
      if (findError || !foundGroup?.id) return json({ error: 'group_not_found' }, 404)
      if (foundGroup.host_customer_id === customerId) {
        return json({ error: 'same_customer', message: 'افتح الرابط من حساب واتساب آخر حتى ينضم صديقك للسلة' }, 400)
      }
      groupId = foundGroup.id

      const { count: memberCount } = await supabase
        .from('cart_group_members')
        .select('*', { count: 'exact', head: true })
        .eq('group_id', groupId)
      const { data: alreadyMember } = await supabase
        .from('cart_group_members')
        .select('customer_id')
        .eq('group_id', groupId)
        .eq('customer_id', customerId)
        .maybeSingle()
      if (!alreadyMember && (memberCount ?? 0) >= MAX_MEMBERS) {
        return json({ error: 'group_full', message: 'المجموعة ممتلئة — شخصين فقط' }, 400)
      }
    } else if (action === 'sync') {
      groupId = (body.groupId ?? '').trim()
      if (!groupId) return json({ error: 'missing_group' }, 400)

      const { data: membership } = await supabase
        .from('cart_group_members')
        .select('group_id, role')
        .eq('group_id', groupId)
        .eq('customer_id', customerId)
        .maybeSingle()
      if (!membership?.group_id) return json({ error: 'not_member' }, 403)
      role = membership.role || 'member'
    } else {
      return json({ error: 'bad_action' }, 400)
    }

    if (!groupId) return json({ error: 'create_failed' }, 500)

    const { error: memberError } = await supabase
      .from('cart_group_members')
      .upsert({
        group_id: groupId,
        customer_id: customerId,
        phone,
        display_name: name,
        role,
      }, { onConflict: 'group_id,customer_id' })
    if (memberError) return json({ error: 'member_failed' }, 500)

    const { error: deleteError } = await supabase
      .from('cart_group_items')
      .delete()
      .eq('group_id', groupId)
      .eq('customer_id', customerId)
    if (deleteError) return json({ error: 'items_failed' }, 500)

    const rows = items.map((item, index) => {
      const quantity = Math.max(1, getItemNumber(item, 'quantity', 1))
      return {
        group_id: groupId,
        customer_id: customerId,
        local_item_id: getItemId(item, index, customerId),
        payload: item,
        price_usd: getItemNumber(item, 'priceUsd'),
        price_syp: getItemNumber(item, 'priceSyp'),
        quantity,
      }
    })

    if (rows.length) {
      const { error: insertError } = await supabase
        .from('cart_group_items')
        .insert(rows)
      if (insertError) return json({ error: 'items_failed' }, 500)
    }

    const { data: group, error: groupError } = await supabase
      .from('cart_groups')
      .select('id, code, status, source_store')
      .eq('id', groupId)
      .single()
    if (groupError || !group) return json({ error: 'snapshot_failed' }, 500)

    const { data: members, error: membersError } = await supabase
      .from('cart_group_members')
      .select('customer_id, phone, display_name, role')
      .eq('group_id', groupId)
      .order('joined_at', { ascending: true })
    if (membersError) return json({ error: 'snapshot_failed' }, 500)

    const { data: groupItems, error: itemsError } = await supabase
      .from('cart_group_items')
      .select('payload, price_usd, quantity, customer_id')
      .eq('group_id', groupId)
    if (itemsError) return json({ error: 'snapshot_failed' }, 500)

    const memberByCustomer = new Map<string, { phone: string; name: string }>()
    for (const member of members ?? []) {
      memberByCustomer.set(String(member.customer_id), {
        phone: String(member.phone ?? ''),
        name: String(member.display_name ?? ''),
      })
    }

    return json({
      id: group.id,
      code: group.code,
      sourceStore: group.source_store,
      status: group.status,
      minTotalUsd: MIN_TOTAL_USD,
      totalUsd: (groupItems ?? []).reduce((sum, entry) => {
        return sum + Number(entry.price_usd ?? 0) * Math.max(1, Number(entry.quantity ?? 1) || 1)
      }, 0),
      members: (members ?? []).map((member) => ({
        phone: member.phone ?? '',
        name: member.display_name ?? '',
        role: member.role === 'host' ? 'host' : 'member',
      })),
      items: (groupItems ?? []).map((entry) => {
        const owner = memberByCustomer.get(String(entry.customer_id))
        return {
          ownerPhone: owner?.phone ?? '',
          ownerName: owner?.name ?? '',
          item: entry.payload,
        }
      }),
    })
  } catch {
    return json({ error: 'create_failed' }, 500)
  }
})
