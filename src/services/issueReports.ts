import { cleanEnvValue } from '../config'

const SUPABASE_URL = cleanEnvValue(import.meta.env.VITE_SUPABASE_URL)
const SUPABASE_ANON_KEY = cleanEnvValue(import.meta.env.VITE_SUPABASE_ANON_KEY)
const APP_REPORTS_URL = SUPABASE_URL ? `${SUPABASE_URL}/functions/v1/app-reports` : ''

export type AppIssueReportInput = {
  note: string
  screenshotDataUrl: string
  deviceId: string
  customerPhone: string
  customerName: string
  screen: string
  store: string
  appVersion: string
  platform: string
  deviceModel: string
}

export async function submitAppIssueReport(input: AppIssueReportInput) {
  if (!APP_REPORTS_URL || !SUPABASE_ANON_KEY) throw new Error('report_service_unavailable')
  const controller = new AbortController()
  const timeout = window.setTimeout(() => controller.abort(), 20_000)
  try {
    const response = await fetch(APP_REPORTS_URL, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        apikey: SUPABASE_ANON_KEY,
        authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      },
      body: JSON.stringify(input),
      signal: controller.signal,
    })
    const payload = await response.json().catch(() => ({})) as { reportId?: string; error?: string }
    if (!response.ok || !payload.reportId) throw new Error(payload.error || 'report_submit_failed')
    return payload.reportId
  } finally {
    window.clearTimeout(timeout)
  }
}

export function reportDeviceLabel() {
  const userAgent = navigator.userAgent || ''
  const android = userAgent.match(/Android\s+([^;\)]+)(?:;\s*([^;\)]+))?/i)
  if (android) return [android[2], `Android ${android[1]}`].filter(Boolean).join(' · ').slice(0, 120)
  if (/iPhone/i.test(userAgent)) return 'iPhone'
  if (/iPad/i.test(userAgent)) return 'iPad'
  return navigator.platform || 'unknown'
}

