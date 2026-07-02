import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-customer-phone',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })

  const phone = (req.headers.get('x-customer-phone') ?? '').trim()
  if (!phone) {
    return new Response(JSON.stringify({ error: 'missing phone' }), {
      status: 400,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // GET: جلب ملف الزبون (يحاول customer_profiles أولاً ثم orders كـfallback)
  if (req.method === 'GET') {
    // 1) جدول customer_profiles (إذا وُجد)
    const { data: profileData, error: profileError } = await supabase
      .from('customer_profiles')
      .select('name, governorate')
      .eq('phone', phone)
      .maybeSingle()

    if (!profileError && profileData?.name) {
      return new Response(
        JSON.stringify({ name: profileData.name, governorate: profileData.governorate ?? '' }),
        { headers: { ...corsHeaders, 'content-type': 'application/json' } },
      )
    }

    // 2) fallback: أحدث طلب للرقم (يستخرج الاسم/المدينة من جدول orders)
    const { data: orderData } = await supabase
      .from('orders')
      .select('customer_name, city')
      .eq('phone', phone)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (orderData?.customer_name) {
      return new Response(
        JSON.stringify({ name: orderData.customer_name as string, governorate: (orderData.city as string) ?? '' }),
        { headers: { ...corsHeaders, 'content-type': 'application/json' } },
      )
    }

    return new Response(JSON.stringify({ name: '', governorate: '' }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // POST: حفظ/تحديث ملف الزبون في customer_profiles
  if (req.method === 'POST') {
    const body = (await req.json()) as { name?: string; governorate?: string }
    if (!body.name?.trim()) {
      return new Response(JSON.stringify({ error: 'missing name' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const { error } = await supabase
      .from('customer_profiles')
      .upsert(
        {
          phone,
          name: body.name.trim(),
          governorate: (body.governorate ?? '').trim(),
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'phone' },
      )

    // إذا كان الجدول غير موجود بعد (قبل تطبيق migration-v2) → أُرجع ok بدون خطأ
    return new Response(JSON.stringify({ ok: true, warning: error?.message }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  return new Response('Method not allowed', { status: 405, headers: corsHeaders })
})
