import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...corsHeaders, 'content-type': 'application/json' } })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  const pin = req.headers.get('x-admin-pin')
  if (!ADMIN_PIN || pin !== ADMIN_PIN) return json({ error: 'unauthorized' }, 401)
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // GET ?phone= — رصيد المحفظة + آخر المعاملات
  if (req.method === 'GET') {
    const url = new URL(req.url)
    const phone = (url.searchParams.get('phone') ?? '').trim()
    if (!phone) return json({ error: 'missing_phone' }, 400)
    const [w, tx] = await Promise.all([
      supabase.from('wallets').select('balance_usd').eq('phone', phone).maybeSingle(),
      supabase.from('wallet_transactions').select('*').eq('phone', phone).order('created_at', { ascending: false }).limit(50),
    ])
    if (w.error || tx.error) return json({ error: (w.error || tx.error)?.message }, 500)
    return json({
      balanceUsd: Number(w.data?.balance_usd ?? 0),
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      transactions: (tx.data || []).map((r: any) => ({
        id: r.id, amountUsd: Number(r.amount_usd), kind: r.kind, note: r.note, orderId: r.order_id, createdAt: r.created_at,
      })),
    })
  }

  // POST { phone, amountUsd, note } — شحن/تعديل الرصيد (amountUsd موجب=إضافة، سالب=خصم)
  if (req.method === 'POST') {
    const body = await req.json() as { phone?: string; amountUsd?: number; note?: string }
    const phone = (body.phone ?? '').trim()
    const amount = Number(body.amountUsd)
    if (!phone || !Number.isFinite(amount) || amount === 0) return json({ error: 'invalid' }, 400)

    const cur = await supabase.from('wallets').select('balance_usd').eq('phone', phone).maybeSingle()
    if (cur.error) return json({ error: cur.error.message }, 500)
    const currentBal = Number(cur.data?.balance_usd ?? 0)
    const newBal = Math.max(0, Math.round((currentBal + amount) * 100) / 100)
    // التغيير الفعلي بعد القصّ إلى ≥0 — نسجّله في المعاملة كي يطابق السجلُّ الرصيدَ
    // (خصم 10$ من رصيد 5$ يسجّل -5$ لا -10$).
    const actualChange = Math.round((newBal - currentBal) * 100) / 100

    const up = await supabase.from('wallets').upsert({ phone, balance_usd: newBal, updated_at: new Date().toISOString() }, { onConflict: 'phone' })
    if (up.error) return json({ error: up.error.message }, 500)
    if (actualChange !== 0) {
      await supabase.from('wallet_transactions').insert({
        phone, amount_usd: actualChange, kind: actualChange > 0 ? 'topup' : 'adjust', note: (body.note ?? '').trim(),
      })
    }
    return json({ ok: true, balanceUsd: newBal })
  }

  return json({ error: 'method not allowed' }, 405)
})
