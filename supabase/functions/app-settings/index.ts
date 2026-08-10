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
  // الليرة السورية الجديدة (حذف صفرين، 2026): 100 قديمة = 1 جديدة.
  shipping_cost_shein_syp: '900',
  shipping_cost_temu_syp: '900',
  usd_to_syp_rate: '131.7',
  shamcash_qr_shein_data_url: '',
  shamcash_qr_temu_data_url: '',
  shamcash_code_shein: '',
  shamcash_code_temu: '',
  referral_discount_syp: '0',
  product_profit_percent: '0',
  admin_session_version: '1',
  feature_group_orders: 'true',
  feature_wallet: 'true',
  feature_coupons: 'true',
  // Each store has an independent browsing region. Pricing remains USD so
  // cart totals and invoices keep their existing currency contract.
  store_region_shein: '{"countryCode":"SA","currency":"USD","language":"ar","addressPath":["Riyadh Province","Riyadh","Al Olaya"]}',
  store_region_temu: '{"countryCode":"SA","currency":"USD","language":"ar","addressPath":[]}',
  brand_name: 'otlobli',
  brand_logo_data_url: '',
  // رقم واتساب الدعم/المساعدة الذي يفتحه التطبيق — يُعدَّل من لوحة الإدارة.
  support_whatsapp_phone: '',
}

const STORE_REGION_COUNTRIES = new Set(['JO', 'AE', 'QA', 'SA'])
const SAUDI_ADDRESS_PATH = ['Riyadh Province', 'Riyadh', 'Al Olaya']

function isAllowedStoreRegion(value: unknown) {
  try {
    const region = JSON.parse(String(value)) as {
      countryCode?: unknown
      currency?: unknown
      language?: unknown
      addressPath?: unknown
    }
    const countryCode = String(region.countryCode ?? '').toUpperCase()
    if (!STORE_REGION_COUNTRIES.has(countryCode) || region.currency !== 'USD' || region.language !== 'ar' || !Array.isArray(region.addressPath)) return false
    const addressPath = region.addressPath.map((part) => String(part).trim()).filter(Boolean)
    return countryCode === 'SA'
      ? addressPath.length === SAUDI_ADDRESS_PATH.length && addressPath.every((part, index) => part === SAUDI_ADDRESS_PATH[index])
      : addressPath.length === 0
  } catch {
    return false
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // GET: يُرجع كل الإعدادات (عام، بدون مصادقة)
  if (req.method === 'GET') {
    const requestedKeys = (new URL(req.url).searchParams.get('keys') ?? '')
      .split(',')
      .map((key) => key.trim())
      .filter((key) => /^[a-z0-9_]{1,64}$/.test(key))
    let query = supabase
      .from('app_settings')
      .select('key, value')
    if (requestedKeys.length > 0) query = query.in('key', requestedKeys)
    const { data, error } = await query

    const settings = requestedKeys.length > 0
      ? Object.fromEntries(requestedKeys.map((key) => [key, DEFAULTS[key] ?? '']))
      : { ...DEFAULTS }

    if (error) {
      return new Response(JSON.stringify(settings), {
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

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

    if ((body.key === 'store_region_shein' || body.key === 'store_region_temu') && !isAllowedStoreRegion(body.value)) {
      return new Response(JSON.stringify({ error: 'unsupported store region' }), {
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
