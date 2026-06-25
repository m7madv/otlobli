import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const WHATSAPP_SERVER_URL = Deno.env.get('WHATSAPP_SERVER_URL') ?? ''
const DRIVER_URL = Deno.env.get('DRIVER_URL') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
}

function generateLoginCode(): string {
  return String(Math.floor(100000 + Math.random() * 900000))
}

async function notifyDriverWelcome(name: string, phone: string, loginCode: string) {
  if (!WHATSAPP_SERVER_URL || !phone) return
  const text = [
    `🚚 *أهلاً ${name} — انضممت كسواق على otlobli*`,
    `رمز دخول بوابتك الخاصة: *${loginCode}*`,
    DRIVER_URL ? `افتح بوابتك: ${DRIVER_URL}` : '',
  ].filter(Boolean).join('\n')

  try {
    await fetch(`${WHATSAPP_SERVER_URL}/api/notify/whatsapp`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ phone, text }),
      signal: AbortSignal.timeout(8000),
    })
  } catch (err) {
    console.error('driver welcome whatsapp failed:', (err as Error).message)
  }
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

  // GET — جلب كل السواقين
  if (req.method === 'GET') {
    const { data, error } = await supabase
      .from('drivers')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const drivers = (data || []).map((row: any) => ({
      id: row.id,
      name: row.name,
      phone: row.phone,
      loginCode: row.login_code,
      isActive: row.is_active,
      createdAt: row.created_at,
    }))

    return new Response(JSON.stringify({ drivers }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // POST — إضافة سواق جديد
  if (req.method === 'POST') {
    const body = await req.json() as { name?: string; phone?: string; loginCode?: string }
    const name = (body.name ?? '').trim()
    const phone = (body.phone ?? '').trim()
    const loginCode = (body.loginCode ?? '').trim() || generateLoginCode()

    if (!name) {
      return new Response(JSON.stringify({ error: 'missing_fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const { data, error } = await supabase
      .from('drivers')
      .insert({ name, phone, login_code: loginCode })
      .select('*')
      .single()

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    await notifyDriverWelcome(name, phone, loginCode)

    return new Response(JSON.stringify({
      driver: {
        id: data.id,
        name: data.name,
        phone: data.phone,
        loginCode: data.login_code,
        isActive: data.is_active,
        createdAt: data.created_at,
      },
    }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  // PATCH — تفعيل/تعطيل سواق
  if (req.method === 'PATCH') {
    const { driverId, patch } = await req.json() as { driverId?: string; patch?: { isActive?: boolean } }

    if (!driverId || !patch) {
      return new Response(JSON.stringify({ error: 'missing_fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      })
    }

    const dbPatch: Record<string, unknown> = {}
    if (patch.isActive !== undefined) dbPatch.is_active = patch.isActive

    const { error } = await supabase.from('drivers').update(dbPatch).eq('id', driverId)

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
