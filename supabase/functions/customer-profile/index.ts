import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-customer-phone, x-customer-session',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })

  const headerPhone = (req.headers.get('x-customer-phone') ?? '').trim()
  const sessionToken = (req.headers.get('x-customer-session') ?? '').trim()
  if (!headerPhone) return json({ error: 'missing phone' }, 400)
  if (!sessionToken) return json({ error: 'missing customer session' }, 401)

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // حظر المستخدم: يُرفض المحظور فوراً من الدخول/الملف (والطلب يُرفض مركزياً في
  // ensure_customer). نطابق الرقم بعد إزالة المسافات كما يُخزَّن.
  const cleanedPhone = headerPhone.replace(/\s+/g, '')
  const { data: blockRow } = await supabase
    .from('customers')
    .select('blocked')
    .eq('phone', cleanedPhone)
    .maybeSingle()
  if (blockRow?.blocked === true) {
    return json({ blocked: true, error: 'account_blocked', message: 'تم إيقاف حسابك. للاستفسار تواصل مع الدعم.' }, 403)
  }

  if (req.method === 'GET') {
    const { data, error } = await supabase.rpc('get_customer_account', {
      p_phone: headerPhone,
      p_session_token: sessionToken,
    })
    if (error) return json({ name: '', governorate: 'دمشق', orders: [], warning: error.message })

    const profile = (data as { profile?: Record<string, unknown> } | null)?.profile ?? null
    return json({
      ...(data as Record<string, unknown>),
      name: typeof profile?.name === 'string' ? profile.name : '',
      governorate: typeof profile?.governorate === 'string' ? profile.governorate : 'دمشق',
      qadmousBranch: typeof profile?.qadmousBranch === 'string' ? profile.qadmousBranch : '',
      pickupLabel: typeof profile?.pickupLabel === 'string' ? profile.pickupLabel : '',
      city: typeof profile?.city === 'string' ? profile.city : '',
      details: typeof profile?.details === 'string' ? profile.details : '',
      notificationPrefs: profile?.notificationPrefs && typeof profile.notificationPrefs === 'object' ? profile.notificationPrefs : {},
    })
  }

  if (req.method === 'POST') {
    const body = (await req.json()) as {
      phone?: string
      name?: string
      governorate?: string
      qadmousBranch?: string
      pickupLabel?: string
      city?: string
      details?: string
      notificationPrefs?: Record<string, unknown>
    }

    if (!body.name?.trim()) return json({ error: 'missing name' }, 400)

    const { data, error } = await supabase.rpc('upsert_customer_profile', {
      p_phone: headerPhone,
      p_name: body.name.trim(),
      p_governorate: (body.governorate || 'دمشق').trim(),
      p_qadmous_branch: (body.qadmousBranch ?? '').trim(),
      p_city: (body.city ?? '').trim(),
      p_details: (body.details ?? '').trim(),
      p_session_token: sessionToken,
    })

    if (error) return json({ ok: false, error: error.message }, 500)

    const { data: prefsData, error: prefsError } = await supabase.rpc('update_customer_preferences', {
      p_phone: headerPhone,
      p_pickup_label: (body.pickupLabel ?? '').trim(),
      p_notification_prefs: body.notificationPrefs && typeof body.notificationPrefs === 'object' ? body.notificationPrefs : {},
      p_session_token: sessionToken,
    })

    if (prefsError) return json({ ok: false, error: prefsError.message }, 500)
    return json({ ok: true, ...((prefsData ?? data) as Record<string, unknown>) })
  }

  return new Response('Method not allowed', { status: 405, headers: corsHeaders })
})
