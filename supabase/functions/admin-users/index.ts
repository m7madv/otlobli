import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
}
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...corsHeaders, 'content-type': 'application/json' } })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  const pin = req.headers.get('x-admin-pin')
  if (!ADMIN_PIN || pin !== ADMIN_PIN) return json({ error: 'unauthorized' }, 401)
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // GET — نشاط العملاء (آخر ظهور) + قائمة المحظورين
  if (req.method === 'GET') {
    const [act, blk] = await Promise.all([
      supabase.from('customer_activity').select('*').order('last_seen', { ascending: false }).limit(1000),
      supabase.from('blocked_users').select('*').order('created_at', { ascending: false }),
    ])
    if (act.error || blk.error) return json({ error: (act.error || blk.error)?.message }, 500)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const activity = (act.data || []).map((r: any) => ({
      phone: r.phone, name: r.name, city: r.city, deviceId: r.device_id, lastSeen: r.last_seen, firstSeen: r.first_seen,
    }))
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const blocked = (blk.data || []).map((r: any) => ({
      id: r.id, phone: r.phone, deviceId: r.device_id, reason: r.reason, createdAt: r.created_at,
    }))
    return json({ activity, blocked })
  }

  // POST — حظر (بالرقم و/أو الجهاز). لو الرقم مُدخل نحظره، ولو الجهاز مُدخل نحظره.
  if (req.method === 'POST') {
    const body = await req.json() as { phone?: string; deviceId?: string; reason?: string }
    const phone = (body.phone ?? '').trim()
    const deviceId = (body.deviceId ?? '').trim()
    const reason = (body.reason ?? '').trim()
    if (!phone && !deviceId) return json({ error: 'missing_target' }, 400)
    const { error } = await supabase.from('blocked_users').insert({
      phone: phone || null, device_id: deviceId || null, reason,
    })
    if (error) {
      const dup = /duplicate|unique/i.test(error.message)
      return json({ error: dup ? 'already_blocked' : error.message }, dup ? 409 : 500)
    }
    return json({ ok: true })
  }

  // DELETE — فك الحظر (بمعرّف الحظر، أو بالرقم/الجهاز)
  if (req.method === 'DELETE') {
    const body = await req.json() as { id?: string; phone?: string; deviceId?: string }
    let qb = supabase.from('blocked_users').delete()
    if (body.id) qb = qb.eq('id', body.id)
    else if (body.phone) qb = qb.eq('phone', body.phone.trim())
    else if (body.deviceId) qb = qb.eq('device_id', body.deviceId.trim())
    else return json({ error: 'missing_target' }, 400)
    const { error } = await qb
    if (error) return json({ error: error.message }, 500)
    return json({ ok: true })
  }

  return json({ error: 'method not allowed' }, 405)
})
