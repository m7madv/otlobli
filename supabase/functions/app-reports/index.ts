import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const ADMIN_PIN = Deno.env.get('ADMIN_PIN') ?? ''
const BUCKET = 'app-issue-reports'
const MAX_SCREENSHOT_BYTES = 1_500_000

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-pin',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
}

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, 'content-type': 'application/json' },
})

const clean = (value: unknown, max: number) => String(value ?? '').replace(/\s+/g, ' ').trim().slice(0, max)

function decodeScreenshot(value: unknown) {
  const match = String(value ?? '').match(/^data:(image\/(?:jpeg|png|webp));base64,([A-Za-z0-9+/=]+)$/i)
  if (!match) throw new Error('invalid_screenshot')
  const binary = atob(match[2])
  if (!binary.length || binary.length > MAX_SCREENSHOT_BYTES) throw new Error('invalid_screenshot_size')
  const bytes = new Uint8Array(binary.length)
  for (let index = 0; index < binary.length; index += 1) bytes[index] = binary.charCodeAt(index)
  const mime = match[1].toLowerCase()
  const extension = mime === 'image/png' ? 'png' : mime === 'image/webp' ? 'webp' : 'jpg'
  return { bytes, mime, extension }
}

function mapReport(row: Record<string, unknown>, screenshotUrl = '') {
  return {
    id: row.id,
    note: row.note,
    screenshotUrl,
    deviceId: row.device_id,
    customerPhone: row.customer_phone,
    customerName: row.customer_name,
    screen: row.screen,
    store: row.store,
    appVersion: row.app_version,
    platform: row.platform,
    deviceModel: row.device_model,
    status: row.status,
    adminNote: row.admin_note,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) return json({ error: 'server_not_configured' }, 503)
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  if (req.method === 'POST') {
    try {
      const body = await req.json() as Record<string, unknown>
      const note = clean(body.note, 800)
      const deviceId = clean(body.deviceId, 120)
      if (note.length < 3) return json({ error: 'note_too_short' }, 400)
      const screenshot = decodeScreenshot(body.screenshotDataUrl)

      if (deviceId) {
        const cutoff = new Date(Date.now() - 20_000).toISOString()
        const { count } = await supabase
          .from('app_issue_reports')
          .select('id', { count: 'exact', head: true })
          .eq('device_id', deviceId)
          .gte('created_at', cutoff)
        if ((count ?? 0) > 0) return json({ error: 'report_rate_limited' }, 429)
      }

      const id = crypto.randomUUID()
      const now = new Date()
      const path = `${now.getUTCFullYear()}/${String(now.getUTCMonth() + 1).padStart(2, '0')}/${id}.${screenshot.extension}`
      const { error: uploadError } = await supabase.storage
        .from(BUCKET)
        .upload(path, screenshot.bytes, { contentType: screenshot.mime, upsert: false, cacheControl: '3600' })
      if (uploadError) return json({ error: uploadError.message }, 500)

      const { error: insertError } = await supabase.from('app_issue_reports').insert({
        id,
        note,
        screenshot_path: path,
        device_id: deviceId,
        customer_phone: clean(body.customerPhone, 32),
        customer_name: clean(body.customerName, 120),
        screen: clean(body.screen, 80),
        store: clean(body.store, 24),
        app_version: clean(body.appVersion, 100),
        platform: clean(body.platform, 32),
        device_model: clean(body.deviceModel, 120),
      })
      if (insertError) {
        await supabase.storage.from(BUCKET).remove([path])
        return json({ error: insertError.message }, 500)
      }
      return json({ ok: true, reportId: id }, 201)
    } catch (error) {
      const message = error instanceof Error ? error.message : 'invalid_report'
      return json({ error: message }, 400)
    }
  }

  const pin = req.headers.get('x-admin-pin') ?? ''
  if (!ADMIN_PIN || pin !== ADMIN_PIN) return json({ error: 'unauthorized' }, 401)

  if (req.method === 'GET') {
    const requestedStatus = clean(new URL(req.url).searchParams.get('status'), 20)
    let query = supabase.from('app_issue_reports').select('*').order('created_at', { ascending: false }).limit(100)
    if (['new', 'in_review', 'resolved'].includes(requestedStatus)) query = query.eq('status', requestedStatus)
    const { data, error } = await query
    if (error) return json({ error: error.message }, 500)
    const rows = (data ?? []) as Record<string, unknown>[]
    const paths = rows.map((row) => String(row.screenshot_path ?? '')).filter(Boolean)
    const { data: signed } = paths.length
      ? await supabase.storage.from(BUCKET).createSignedUrls(paths, 60 * 60)
      : { data: [] as { path: string; signedUrl: string }[] }
    const urls = new Map((signed ?? []).map((item) => [item.path, item.signedUrl]))
    return json({ reports: rows.map((row) => mapReport(row, urls.get(String(row.screenshot_path ?? '')) ?? '')) })
  }

  if (req.method === 'PATCH') {
    const body = await req.json() as { reportId?: unknown; status?: unknown; adminNote?: unknown }
    const reportId = clean(body.reportId, 80)
    const status = clean(body.status, 20)
    if (!/^[0-9a-f-]{36}$/i.test(reportId) || !['new', 'in_review', 'resolved'].includes(status)) {
      return json({ error: 'invalid_report_update' }, 400)
    }
    const { error } = await supabase
      .from('app_issue_reports')
      .update({ status, admin_note: clean(body.adminNote, 800), updated_at: new Date().toISOString() })
      .eq('id', reportId)
    if (error) return json({ error: error.message }, 500)
    return json({ ok: true })
  }

  return json({ error: 'method_not_allowed' }, 405)
})

