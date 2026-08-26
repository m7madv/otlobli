import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { isDeepStrictEqual } from 'node:util'

const root = resolve(fileURLToPath(new URL('..', import.meta.url)))
const read = (path) => readFileSync(resolve(root, path), 'utf8')
const app = read('src/App.tsx')
const api = read('src/services/supabaseAppApi.ts')
const edge = read('supabase/functions/cart-groups/index.ts')
const schema = read('supabase/schema.sql')
const migration = read('supabase/migrations/20260826123000_group_order_single_friend.sql')
const bridge = read('public/group/index.html')
const assetLinks = JSON.parse(read('public/.well-known/assetlinks.json'))
const appleAssociation = JSON.parse(read('public/.well-known/apple-app-site-association'))
const vercel = JSON.parse(read('vercel.json'))
const iosEntitlements = read('ios/App/App/App.entitlements')
const androidManifest = read('android/app/src/main/AndroidManifest.xml')

function requireText(source, marker, label) {
  if (!source.includes(marker)) throw new Error(`${label}: missing ${marker}`)
}

const linkBuilder = app.slice(
  app.indexOf('function buildGroupInviteLink('),
  app.indexOf('function getOrderStore(', app.indexOf('function buildGroupInviteLink(')),
)
for (const marker of ['code, group: code, store', 'GROUP_INVITE_WEB_ORIGIN']) {
  requireText(linkBuilder, marker, 'invite link')
}
if (/\bfrom\b|\bhost\b|memberKey|device/i.test(linkBuilder)) {
  throw new Error('invite link: private host/member/device identity must not be exposed')
}

for (const marker of [
  'const groupCustomerPhone = normalizePhoneForCompare(userProfile?.phone || phone).length >= 8',
  "showNotice('تم إنشاء الرابط — أرسله الآن لصديق واحد')",
  'https://wa.me/?text=',
  'إنشاء رابط واتساب',
  'إرساله عبر واتساب',
  'شخصان فقط',
  'لدي رابط أو كود من صديقي',
  'لن تُرسل المنتجات قبل موافقتك',
  'const operationEpoch = groupOperationEpochRef.current',
  'clearMatchingCartGroup(newOrder.groupId)',
  'clearMatchingCartGroup(pendingPayment.groupId)',
  'itemIds: newOrder.items.map((item) => item.id)',
  'setCartItemsForStore(pendingPayment.store ?? selectedStoreRef.current',
  "errorCode === 'group_closed' || errorCode === 'not_member'",
]) requireText(app, marker, 'group-order UI')
if (/autoJoinInviteRef|setCartGroup\(\(current\).*invite\.code/.test(app)) {
  throw new Error('group-order consent: opening an invite must not auto-join or clear the active group')
}

for (const marker of [
  'sessionToken: requireCustomerSessionToken()',
  "await postCartGroup({ action: 'cancel', groupId })",
  "error === 'group_closed' || error === 'not_member'",
  'cartGroupError.code = error',
]) requireText(api, marker, 'group-order client')
const remoteGroupClient = api.slice(api.indexOf('cartGroups: {'), api.indexOf('orders: {'))
if (/memberKey,|phone:\s*phone\.trim\(\)|name:\s*name\.trim\(\)/.test(remoteGroupClient)) {
  throw new Error('group-order client: phone/name/memberKey must not be trusted as remote identity')
}

for (const marker of [
  "supabase.rpc('require_customer_session'",
  "if (!sessionToken || sessionToken.length > 512)",
  ".gt('expires_at', new Date().toISOString())",
  "String(foundGroup.host_customer_id) === customerId",
  "action === 'cancel'",
  "supabase.rpc('create_cart_group_authenticated'",
  "supabase.rpc('save_cart_group_member_authenticated'",
  "supabase.rpc('leave_cart_group_authenticated'",
  'cart_group_members_one_friend_per_group_idx',
  'MAX_GROUP_ITEMS = 200',
  'UUID_PATTERN.test(groupId)',
  'data: snapshot',
  "error: 'group_full'",
]) requireText(edge, marker, 'group-order service')
for (const forbidden of [
  "supabase.rpc('ensure_customer'",
  ".from('cart_group_members')\n      .upsert",
  ".from('cart_group_items')\n      .delete",
  ".from('cart_group_members')\n      .select",
  ".from('cart_group_items')\n      .select",
  'cleanMemberKey(',
]) {
  if (edge.includes(forbidden)) throw new Error(`group-order service: forbidden legacy mutation ${forbidden}`)
}

for (const source of [schema, migration]) {
  requireText(source, 'cart_group_members_one_host_per_group_idx', 'group-order database guard')
  requireText(source, 'cart_group_members_one_friend_per_group_idx', 'group-order database guard')
  requireText(source, "where role = 'member'", 'group-order database guard')
  requireText(source, 'save_cart_group_member_authenticated', 'group-order atomic save')
  requireText(source, 'create_cart_group_authenticated', 'group-order atomic create')
  requireText(source, 'leave_cart_group_authenticated', 'group-order atomic leave')
  requireText(source, 'returns jsonb', 'group-order snapshot return')
  requireText(source, "jsonb_array_length(coalesce(p_items, '[]'::jsonb)) > 200", 'group-order item bound')
  requireText(source, 'for update', 'group-order serialization')
  requireText(source, 'set default gen_random_uuid()::text', 'group-scoped random member key')
  requireText(source, 'from public, anon, authenticated, service_role', 'legacy RPC revocation')
}
if (schema.includes('cart_group_members_one_customer_per_group_idx') || migration.includes('cart_group_members_one_customer_per_group_idx')) {
  throw new Error('group-order database guard: historical duplicate customers must not be rewritten by a new global index')
}

for (const marker of [
  'فتح في تطبيق otlobli',
  'صديق واحد فقط',
  'اضغط الزر الأخضر لفتح الدعوة في التطبيق.',
  'btn.href = appUrl',
]) requireText(bridge, marker, 'invite bridge')
if (/params\.get\(['"](?:from|host)|\b(?:from|host):\s*(?:from|host)|style="display:none"|setTimeout\(|(?:window\.)?location\.(?:href\s*=|assign\s*\(|replace\s*\()|window\.open\s*\(|\.click\s*\(\)/.test(bridge)) {
  throw new Error('invite bridge: opening must stay manual and visible, and identity must stay out of the URL')
}

const expectedFingerprint = 'E0:B0:F4:4C:C6:77:88:8F:95:35:C0:1C:91:25:07:7E:09:B0:14:BD:B9:09:6D:C2:81:3E:3B:D0:6F:17:F7:84'
const expectedAssetLinks = [{
  relation: ['delegate_permission/common.handle_all_urls'],
  target: {
    namespace: 'android_app',
    package_name: 'com.otlobli.app',
    sha256_cert_fingerprints: [expectedFingerprint],
  },
}]
if (!isDeepStrictEqual(assetLinks, expectedAssetLinks)) {
  throw new Error('installed links: assetlinks must bind the live Android package to the release certificate only')
}

const expectedAppleAssociation = {
  applinks: {
    apps: [],
    details: [{
      appID: '36D743K87T.com.otlobli.app',
      paths: ['/group', '/group/*'],
    }],
  },
}
if (!isDeepStrictEqual(appleAssociation, expectedAppleAssociation)) {
  throw new Error('installed links: AASA must bind the production iOS app to group paths only')
}

for (const source of [
  '/.well-known/assetlinks.json',
  '/.well-known/apple-app-site-association',
]) {
  const matches = (vercel.headers || []).filter((entry) => entry.source === source)
  if (matches.length !== 1) throw new Error(`installed links: ${source} must have one explicit Vercel header rule`)
  const headers = Object.fromEntries(matches[0].headers.map(({ key, value }) => [key.toLowerCase(), value]))
  for (const [key, value] of [
    ['content-type', 'application/json'],
    ['cache-control', 'public, max-age=3600'],
    ['x-content-type-options', 'nosniff'],
  ]) {
    if (headers[key] !== value) throw new Error(`installed links: ${source} must set ${key}=${value}`)
  }
}

if (!/<key>com\.apple\.developer\.associated-domains<\/key>\s*<array>\s*<string>applinks:talabieh\.vercel\.app<\/string>\s*<\/array>/.test(iosEntitlements)) {
  throw new Error('installed links: iOS entitlement must contain the live talabieh applinks domain')
}
if (/applinks:otlobli\.app/.test(iosEntitlements)) {
  throw new Error('installed links: iOS entitlement must not contain the dead otlobli.app domain')
}

const verifiedFilters = androidManifest.match(/<intent-filter android:autoVerify="true">[\s\S]*?<\/intent-filter>/g) || []
const talabiehGroupFilter = verifiedFilters.find((filter) => filter.includes('android:host="talabieh.vercel.app"')) || ''
for (const marker of [
  'android:name="android.intent.action.VIEW"',
  'android:name="android.intent.category.DEFAULT"',
  'android:name="android.intent.category.BROWSABLE"',
  'android:scheme="https"',
  'android:pathPrefix="/group"',
]) requireText(talabiehGroupFilter, marker, 'installed links: Android talabieh group filter')
if (/android:host="otlobli\.app"/.test(androidManifest)) {
  throw new Error('installed links: Android manifest must not verify the dead otlobli.app domain')
}

console.log('Group-order link, installed-link, session, one-friend, cancel, and compact-UI guards passed.')
