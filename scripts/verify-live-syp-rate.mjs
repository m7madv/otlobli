import fs from 'node:fs'

const sourceUrl = process.env.SYP_RATE_SOURCE_URL || 'https://sp-today.com/en'
const oracleUrl = process.env.SYP_RATE_ORACLE_URL || 'https://84-8-100-128.sslip.io/api/exchange-rate'

function readLocalEnv() {
  const values = {}
  // Match Vite precedence: .env.local overrides .env. Secrets are used only
  // as request headers and are never included in output.
  for (const relative of ['../.env', '../.env.local']) {
    const path = new URL(relative, import.meta.url)
    if (!fs.existsSync(path)) continue
    for (const line of fs.readFileSync(path, 'utf8').split(/\r?\n/)) {
      const match = /^\s*([^#=\s]+)\s*=\s*(.*?)\s*$/.exec(line)
      if (match) values[match[1]] = match[2].replace(/^['"]|['"]$/g, '')
    }
  }
  return values
}

function flattenUsdBlock(html) {
  const anchorIndex = html.indexOf('/currency/us-dollar')
  if (anchorIndex < 0) throw new Error('USD card was not found in sp-today HTML')
  return html.slice(anchorIndex, anchorIndex + 3000).replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ')
}

function readPair(text, label) {
  const asNew = new RegExp(`${label}\\s+(\\d{1,4}(?:\\.\\d{1,2})?)\\b(?!\\s*,)`, 'i').exec(text)
  if (asNew) return Number(asNew[1])
  const asOld = new RegExp(`${label}\\s+(\\d{1,3}(?:,\\d{3})+)`, 'i').exec(text)
  return asOld ? Number(asOld[1].replace(/,/g, '')) / 100 : 0
}

const localEnv = readLocalEnv()
const supabaseUrl = process.env.SYP_RATE_SUPABASE_URL || localEnv.VITE_SUPABASE_URL
const supabaseAnonKey = process.env.SYP_RATE_SUPABASE_ANON_KEY || localEnv.VITE_SUPABASE_ANON_KEY
if (!supabaseUrl || !supabaseAnonKey) throw new Error('Supabase verification configuration is missing')

const [sourceResponse, oracleResponse, settingsResponse] = await Promise.all([
  fetch(sourceUrl, { signal: AbortSignal.timeout(15_000) }),
  fetch(oracleUrl, { signal: AbortSignal.timeout(15_000) }),
  fetch(`${supabaseUrl.replace(/\/$/, '')}/functions/v1/app-settings`, {
    headers: { apikey: supabaseAnonKey, authorization: `Bearer ${supabaseAnonKey}` },
    signal: AbortSignal.timeout(15_000),
  }),
])
if (!sourceResponse.ok) throw new Error(`sp-today returned ${sourceResponse.status}`)
if (!oracleResponse.ok) throw new Error(`Oracle returned ${oracleResponse.status}`)
if (!settingsResponse.ok) throw new Error(`Supabase settings returned ${settingsResponse.status}`)

const sourceText = flattenUsdBlock(await sourceResponse.text())
const sourceBuy = readPair(sourceText, 'Buy')
const sourceSell = readPair(sourceText, 'Sell')
const oracle = await oracleResponse.json()
const settings = await settingsResponse.json()
if (!(sourceBuy > 0 && sourceSell > 0 && sourceSell < 1000)) {
  throw new Error(`Invalid new-lira source pair ${sourceBuy}/${sourceSell}`)
}
if (Number(oracle.rate) !== sourceSell || Number(oracle.sell) !== sourceSell) {
  throw new Error(`Oracle ${oracle.rate}/${oracle.sell} differs from source sell ${sourceSell}`)
}
if (Number(settings.usd_to_syp_rate) !== sourceSell || settings.syp_denomination !== 'new') {
  throw new Error(`Supabase rate/unit ${settings.usd_to_syp_rate}/${settings.syp_denomination} differs from live source`)
}

// The <1000 rule applies only to one-dollar FX rates, never to order totals.
const largeOrderUsd = 1000
const largeOrderSyp = Math.round(largeOrderUsd * sourceSell)
if (largeOrderSyp <= 1000) {
  throw new Error(`Large-order conversion failed: $${largeOrderUsd} -> ${largeOrderSyp}`)
}

const appSource = fs.readFileSync(new URL('../src/App.tsx', import.meta.url), 'utf8')
if (!appSource.includes('data.rate > 0 && data.rate < OLD_LIRA_RATE_FLOOR')) {
  throw new Error('Client Oracle guard is missing')
}
if (!appSource.includes("parseFloat(data.usd_to_syp_rate ?? '0')")) {
  throw new Error('Client Supabase decimal-rate reader is missing')
}

console.log(JSON.stringify({
  source: { buy: sourceBuy, sell: sourceSell },
  oracle: { rate: Number(oracle.rate), source: oracle.source },
  supabase: { rate: Number(settings.usd_to_syp_rate), denomination: settings.syp_denomination },
  orderTest: { usd: largeOrderUsd, syp: largeOrderSyp },
}))
