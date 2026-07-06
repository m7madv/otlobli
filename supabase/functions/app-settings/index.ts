import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}

// القيم الافتراضية — تُستخدم إذا جدول app_settings غير موجود بعد
const DEFAULTS: Record<string, string> = {
  shipping_cost_shein_syp: '90000',
  shipping_cost_temu_syp: '90000',
  usd_to_syp_rate: '13000',
  shamcash_qr_shein_data_url: '',
  shamcash_qr_temu_data_url: '',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // GET: يُرجع كل الإعدادات (عام، بدون مصادقة)
  if (req.method === 'GET') {
    const { data, error } = await supabase
      .from('app_settings')
      .select('key, value')

    if (error) {
      return new Response(JSON.stringify(DEFAULTS), {
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const settings = { ...DEFAULTS }
    for (const row of data ?? []) {
      settings[row.key as string] = row.value as string
    }

    return new Response(JSON.stringify(settings), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // POST: يُعدّل إعداداً واحداً (يتطلب رمز الإدارة)
  if (req.method === 'POST') {
    const pin = req.headers.get('x-admin-pin')
    if (!ADMIN_PIN || pin !== ADMIN_PIN) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const body = (await req.json()) as { key?: string; value?: string }
    if (!body.key || body.value === undefined) {
      return new Response(JSON.stringify({ error: 'missing key/value' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const { error } = await supabase
      .from('app_settings')
      .upsert({ key: body.key, value: String(body.value) }, { onConflict: 'key' })

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

  return new Response('Method not allowed', { status: 405, headers: corsHeaders })
})
