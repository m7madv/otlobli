#!/usr/bin/env node

// Targeted operator-only push smoke test. Dry-run is the default and this tool
// intentionally has no broadcast option. Secrets are accepted only through the
// process environment and are never printed.
const args = new Map()
for (let index = 2; index < process.argv.length; index++) {
  const key = process.argv[index]
  if (!key.startsWith('--')) throw new Error(`Unexpected argument: ${key}`)
  if (key === '--send') { args.set(key, true); continue }
  const value = process.argv[++index]
  if (!value || value.startsWith('--')) throw new Error(`Missing value for ${key}`)
  args.set(key, value)
}

const endpoint = String(process.env.OTLOBLI_PUSH_ENDPOINT ?? '').trim()
const secret = String(process.env.OTLOBLI_PUSH_TRIGGER_SECRET ?? '').trim()
const installationId = String(args.get('--installation-id') ?? '').trim()
const customerId = String(args.get('--customer-id') ?? '').trim()
const shouldSend = args.get('--send') === true

if (!endpoint || !/^https:\/\/[^/]+\/functions\/v1\/send-push$/i.test(endpoint)) {
  throw new Error('Set OTLOBLI_PUSH_ENDPOINT to the exact HTTPS send-push Edge Function URL.')
}
if (!secret) throw new Error('Set OTLOBLI_PUSH_TRIGGER_SECRET in the environment.')
if ((installationId ? 1 : 0) + (customerId ? 1 : 0) !== 1) {
  throw new Error('Provide exactly one --installation-id or --customer-id target.')
}

const response = await fetch(endpoint, {
  method: 'POST',
  headers: { 'content-type': 'application/json', 'x-push-secret': secret },
  body: JSON.stringify({
    ...(installationId ? { installationId } : { customerId }),
    dryRun: !shouldSend,
    title: 'اختبار إشعارات اطلبلي',
    body: shouldSend ? 'هذا اختبار موجّه من بيئة الإصدار الداخلية.' : 'dry-run',
    data: { version: '1', type: 'system', route: 'notifications' },
  }),
})

let payload
try { payload = await response.json() } catch { payload = { error: 'non_json_response' } }
if (!response.ok) throw new Error(`Push test failed with HTTP ${response.status}: ${String(payload?.error ?? 'unknown_error')}`)
console.log(JSON.stringify({ mode: shouldSend ? 'targeted-send' : 'dry-run', status: response.status, result: payload }, null, 2))
