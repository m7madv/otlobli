import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-driver-code',
  'Access-Control-Allow-Methods': 'GET, PATCH, OPTIONS',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const loginCode = req.headers.get('x-driver-code') ?? ''
  if (!loginCode) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  const { data: driver, error: driverError } = await supabase
    .from('drivers')
    .select('id, name, is_active')
    .eq('login_code', loginCode)
    .eq('is_active', true)
    .maybeSingle()

  if (driverError || !driver) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // GET — جلب طلبات هذا السواق فقط
  if (req.method === 'GET') {
    const { data, error } = await supabase
      .from('orders')
      .select('*, order_items(*)')
      .eq('assigned_driver_id', driver.id)
      .order('assigned_at', { ascending: false })

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const orders = (data || []).map((row: any) => ({
      id: row.id,
      customer: row.customer_name || row.customer || '',
      phone: row.phone,
      city: row.city,
      address: row.address,
      items: (row.order_items || []).map((item: any) => ({
        id: item.id,
        title: item.title,
        image: item.image,
        color: item.color,
        size: item.size,
        quantity: item.quantity,
        priceSyp: item.price_syp,
        sourceLink: item.source_link,
      })),
      total: row.total_syp ?? row.total ?? 0,
      paymentStatus: row.payment_status,
      statusIndex: row.status_index ?? 0,
      qadmousNumber: row.qadmous_number || '',
      createdAt: row.created_at,
      assignedAt: row.assigned_at,
    }))

    return new Response(JSON.stringify({ driverName: driver.name, orders }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // PATCH — تحديث رقم القدموس أو الحالة، فقط على طلب مكلَّف لهذا السواق
  if (req.method === 'PATCH') {
    const { orderId, patch } = await req.json() as {
      orderId: string
      patch: { statusIndex?: number; qadmousNumber?: string }
    }

    if (!orderId || !patch) {
      return new Response(JSON.stringify({ error: 'missing_fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const dbPatch: Record<string, unknown> = {}
    if (patch.statusIndex !== undefined) dbPatch.status_index = patch.statusIndex
    if (patch.qadmousNumber !== undefined) dbPatch.qadmous_number = patch.qadmousNumber

    const { data, error } = await supabase
      .from('orders')
      .update(dbPatch)
      .eq('id', orderId)
      .eq('assigned_driver_id', driver.id)
      .select('id')
      .maybeSingle()

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    if (!data) {
      return new Response(JSON.stringify({ error: 'not_found' }), {
        status: 404,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ error: 'method not allowed' }), {
    status: 405,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })
})
