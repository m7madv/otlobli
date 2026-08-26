import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(fileURLToPath(new URL('..', import.meta.url)))
const read = (path) => readFileSync(resolve(root, path), 'utf8')
const app = read('src/App.tsx')
const api = read('src/services/supabaseAppApi.ts')
const edge = read('supabase/functions/cart-groups/index.ts')
const schema = read('supabase/schema.sql')
const migration = read('supabase/migrations/20260826123000_group_order_single_friend.sql')
const bridge = read('public/group/index.html')

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
  "window.location.href = appUrl",
]) requireText(bridge, marker, 'invite bridge')
if (/params\.get\(['"](?:from|host)|\b(?:from|host):\s*(?:from|host)|style="display:none"|setTimeout\(/.test(bridge)) {
  throw new Error('invite bridge: manual open must be visible immediately and identity must stay out of the URL')
}

console.log('Group-order link, session, one-friend, cancel, and compact-UI guards passed.')
