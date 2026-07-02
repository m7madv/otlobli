// دالة مؤقتة لإنشاء الجداول الجديدة — تُستدعى مرة واحدة ثم تُترك
// محمية بـ x-migrate-secret لمنع الاستدعاء العشوائي
import postgres from 'npm:postgres@3'

const MIGRATE_SECRET = Deno.env.get('MIGRATE_SECRET') ?? ''
const DATABASE_URL   = Deno.env.get('DATABASE_URL') ?? ''  // postgresql://...

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'content-type, x-migrate-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers: corsHeaders })
  }

  const secret = req.headers.get('x-migrate-secret') ?? ''
  if (!MIGRATE_SECRET || secret !== MIGRATE_SECRET) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  if (!DATABASE_URL) {
    return new Response(JSON.stringify({ error: 'DATABASE_URL not set' }), {
      status: 500,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  }

  const sql = postgres(DATABASE_URL, { ssl: 'require' })
  const results: string[] = []

  try {
    // جدول app_settings: يخزن إعدادات التطبيق (تكلفة الشحن، سعر الصرف...)
    await sql.unsafe(`
      CREATE TABLE IF NOT EXISTS app_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `)
    results.push('app_settings: OK')

    // القيم الافتراضية إذا لم تكن موجودة
    await sql.unsafe(`
      INSERT INTO app_settings (key, value) VALUES
        ('shipping_cost_shein_syp', '90000'),
        ('shipping_cost_temu_syp',  '90000'),
        ('usd_to_syp_rate',         '13000')
      ON CONFLICT (key) DO NOTHING
    `)
    results.push('app_settings defaults: OK')

    // جدول customer_profiles: يحفظ اسم الزبون ومحافظته للتسجيل السريع
    await sql.unsafe(`
      CREATE TABLE IF NOT EXISTS customer_profiles (
        phone       TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        governorate TEXT NOT NULL DEFAULT '',
        created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `)
    results.push('customer_profiles: OK')

  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    return new Response(JSON.stringify({ error: msg, partial: results }), {
      status: 500,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    })
  } finally {
    await sql.end()
  }

  return new Response(JSON.stringify({ ok: true, results }), {
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })
})
