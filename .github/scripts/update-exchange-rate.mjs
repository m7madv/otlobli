// تحديث سعر صرف الدولار → الليرة السورية من sp-today.com وتخزينه في Supabase.
// يعمل مجاناً عبر GitHub Actions (cron) بدلاً من سيرفر Railway. لا اعتماديات:
// يستخدم fetch المدمج في Node 20+ و REST API الخاص بـ Supabase (PostgREST).
//
// أسرار مطلوبة (Settings → Secrets → Actions):
//   SUPABASE_URL                 مثل https://xxxx.supabase.co
//   SUPABASE_SERVICE_ROLE_KEY    مفتاح service_role (سرّي، لا تكشفه)
//
// نفس منطق السحب الموجود في server/src/routes.js حتى تبقى النتيجة مطابقة.

const SUPABASE_URL = (process.env.SUPABASE_URL || '').replace(/\/+$/, '')
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || ''

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('مفقود: SUPABASE_URL أو SUPABASE_SERVICE_ROLE_KEY')
  process.exit(1)
}

async function fetchLiveRate() {
  const res = await fetch('https://sp-today.com/en', {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    },
    signal: AbortSignal.timeout(15000),
  })
  if (!res.ok) throw new Error(`sp-today returned ${res.status}`)
  const html = await res.text()

  // نرتكز على رابط بطاقة الدولار نفسها لا أول ظهور لكلمة USD (تظهر في meta أولاً).
  const anchorIndex = html.indexOf('/currency/us-dollar')
  const usdBlock = anchorIndex === -1 ? '' : html.slice(anchorIndex, anchorIndex + 3000)
  // الفاصلة إلزامية لتجنّب التقاط أكواد ألوان hex (مثل D80027).
  const nums = [...usdBlock.matchAll(/\d{1,3},\d{3}/g)]
    .map((m) => parseInt(m[0].replace(/,/g, ''), 10))
    .filter((n) => n >= 10000 && n <= 100000)

  if (nums.length >= 2) return nums[1] // سعر المبيع (الأعلى) هو المعتمد
  if (nums.length === 1) return nums[0]
  throw new Error('تعذّر استخراج سعر الدولار من sp-today.com')
}

async function persistRate(rate) {
  const normalized = Math.round(Number(rate))
  if (!Number.isFinite(normalized) || normalized < 1000 || normalized > 100000) {
    throw new Error(`سعر خارج المجال المقبول: ${rate}`)
  }
  // upsert عبر PostgREST على مفتاح key.
  const res = await fetch(`${SUPABASE_URL}/rest/v1/app_settings?on_conflict=key`, {
    method: 'POST',
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'resolution=merge-duplicates,return=minimal',
    },
    body: JSON.stringify({ key: 'usd_to_syp_rate', value: String(normalized) }),
  })
  if (!res.ok) {
    const body = await res.text().catch(() => '')
    throw new Error(`فشل حفظ السعر في Supabase (${res.status}): ${body}`)
  }
  return normalized
}

try {
  const rate = await fetchLiveRate()
  const saved = await persistRate(rate)
  console.log(`💱 تم تحديث سعر الصرف: ${saved} ل.س لكل دولار`)
} catch (err) {
  console.error('فشل تحديث سعر الصرف:', err?.message || err)
  process.exit(1)
}
