import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function mapCoupon(row: any) {
  return {
    id: row.id,
    code: row.code,
    kind: row.kind,
    value: Number(row.value),
    appliesTo: row.applies_to,
    active: row.active,
    maxUses: row.max_uses,
    usedCount: row.used_count,
    minSubtotalSyp: row.min_subtotal_syp,
    startsAt: row.starts_at,
    expiresAt: row.expires_at,
    createdAt: row.created_at,
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })

  const pin = req.headers.get('x-admin-pin')
  if (!ADMIN_PIN || pin !== ADMIN_PIN) return json({ error: 'unauthorized' }, 401)

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // GET — كل الأكواد مع عدد مرات الاستخدام
  if (req.method === 'GET') {
    const { data, error } = await supabase
      .from('coupons')
      .select('*')
      .order('created_at', { ascending: false })
    if (error) return json({ error: error.message }, 500)
    return json({ coupons: (data || []).map(mapCoupon) })
  }

  // POST — إنشاء كود خصم جديد
  if (req.method === 'POST') {
    const body = await req.json() as {
      code?: string; kind?: string; value?: number; appliesTo?: string
      maxUses?: number | null; minSubtotalSyp?: number; expiresAt?: string | null
    }
    const code = (body.code ?? '').trim()
    const kind = (body.kind ?? '').trim()
    const value = Number(body.value)
    const appliesTo = (body.appliesTo ?? 'all').trim()

    if (!code || !['percent', 'fixed'].includes(kind) || !(value > 0)) {
      return json({ error: 'missing_or_invalid_fields' }, 400)
    }
    if (!['all', 'shein', 'temu'].includes(appliesTo)) {
      return json({ error: 'invalid_applies_to' }, 400)
    }
    if (kind === 'percent' && value > 100) {
      return json({ error: 'percent_over_100' }, 400)
    }

    const insert: Record<string, unknown> = {
      code,
      kind,
      value,
      applies_to: appliesTo,
      min_subtotal_syp: Math.max(0, Math.round(Number(body.minSubtotalSyp) || 0)),
    }
    if (body.maxUses != null && Number(body.maxUses) > 0) insert.max_uses = Math.round(Number(body.maxUses))
    if (body.expiresAt) insert.expires_at = body.expiresAt

    const { data, error } = await supabase.from('coupons').insert(insert).select('*').single()
    if (error) {
      const dup = /duplicate|unique/i.test(error.message)
      return json({ error: dup ? 'code_exists' : error.message }, dup ? 409 : 500)
    }
    return json({ coupon: mapCoupon(data) })
  }

  // PATCH — تفعيل/تعطيل كود
  if (req.method === 'PATCH') {
    const { couponId, patch } = await req.json() as { couponId?: string; patch?: { active?: boolean } }
    if (!couponId || !patch) return json({ error: 'missing_fields' }, 400)
    const dbPatch: Record<string, unknown> = {}
    if (patch.active !== undefined) dbPatch.active = patch.active
    const { error } = await supabase.from('coupons').update(dbPatch).eq('id', couponId)
    if (error) return json({ error: error.message }, 500)
    return json({ ok: true })
  }

  // DELETE — حذف كود نهائياً (سجل الاستخدام يُحذف تلقائياً عبر ON DELETE CASCADE)
  if (req.method === 'DELETE') {
    const { couponId } = await req.json() as { couponId?: string }
    if (!couponId) return json({ error: 'missing_fields' }, 400)
    const { error } = await supabase.from('coupons').delete().eq('id', couponId)
    if (error) return json({ error: error.message }, 500)
    return json({ ok: true })
  }

  return json({ error: 'method not allowed' }, 405)
})
