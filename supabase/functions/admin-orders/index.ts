import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'GET, PATCH, DELETE, OPTIONS',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const pin = req.headers.get('x-admin-pin')
  if (!ADMIN_PIN || pin !== ADMIN_PIN) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // GET — جلب الطلبات
  if (req.method === 'GET') {
    const { data, error } = await supabase
      .from('orders')
      .select('*, order_items(*)')
      .order('created_at', { ascending: false })
      .limit(500)

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
      paidAt: row.paid_at,
    }))

    return new Response(JSON.stringify({ orders }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // PATCH — تحديث طلب
  if (req.method === 'PATCH') {
    const { orderId, patch } = await req.json() as {
      orderId: string
      patch: Record<string, unknown>
    }

    if (!orderId || !patch) {
      return new Response(JSON.stringify({ error: 'missing_fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    // ملاحظة: جدول orders لا يحتوي على عمود updated_at، فلا نضيفه هنا
    const dbPatch: Record<string, unknown> = {}
    if (patch.paymentStatus !== undefined) dbPatch.payment_status = patch.paymentStatus
    if (patch.statusIndex !== undefined) dbPatch.status_index = patch.statusIndex
    if (patch.qadmousNumber !== undefined) dbPatch.qadmous_number = patch.qadmousNumber
    if (patch.paidAt !== undefined) dbPatch.paid_at = patch.paidAt

    const { error } = await supabase.from('orders').update(dbPatch).eq('id', orderId)

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // DELETE — حذف طلب (وبنوده عبر ON DELETE CASCADE)
  if (req.method === 'DELETE') {
    const { orderId } = await req.json() as { orderId: string }

    if (!orderId) {
      return new Response(JSON.stringify({ error: 'missing_order_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const { error } = await supabase.from('orders').delete().eq('id', orderId)

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
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
