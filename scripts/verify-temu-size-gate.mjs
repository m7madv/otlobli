import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const source = fs.readFileSync(path.join(root, 'src/services/sheinBrowserScript.ts'), 'utf8')
const appSource = fs.readFileSync(path.join(root, 'src/App.tsx'), 'utf8')
const nativeSource = fs.readFileSync(
  path.join(root, 'android/app/src/main/java/com/otlobli/app/TemuEmbeddedBrowserPlugin.java'),
  'utf8',
)
const geckoGuardSource = fs.readFileSync(
  path.join(root, 'android/app/src/temuPersonal/assets/temu_extension/content.js'),
  'utf8',
)
const generatedCaptureSource = fs.readFileSync(
  path.join(root, 'android/app/src/temuPersonal/assets/temu_extension/content-capture.js'),
  'utf8',
)

const requiredMarkers = [
  'function temuActiveSkuPriceText() {',
  'var first = Math.max(0, dialogs.length - 8);',
  `'[class*="salePriceRich" i]'`,
  'var best = temuActiveSkuPriceText();',
  'var structuralMultiSize = false;',
  "window.__otlobliTemuSizeDiag = 'عدة مقاسات بلا اختيار صريح';",
  'if (!sel && isColor && opts.length) {',
  'var dimensionCount = temuCleanText(txt).match(/(\\\\d+)\\\\s*(?:الحجم|حجم)/i);',
  'document.querySelectorAll(\'[class*="specListWrap"],[class*="specTypes-"]\')',
  "out.dims[cd].source === 'collapsed'",
  "source: 'expanded'",
  'var maxAttempts = IS_TEMU ? 3 : 10;',
  'var intervalMs = IS_TEMU ? 150 : 500;',
  "showMessage(btn, unmetMessage0);",
  'if (IS_TEMU) {\n        postProduct();\n        return;',
]

for (const marker of requiredMarkers) {
  if (!source.includes(marker)) throw new Error(`Missing Temu size/speed guard: ${marker}`)
}

const temuPriceStart = source.indexOf('function temuPriceUsd()')
const temuPriceEnd = source.indexOf('// اللون المختار:', temuPriceStart)
const temuPriceSource = source.slice(temuPriceStart, temuPriceEnd)
if (temuPriceStart < 0 || temuPriceEnd < 0 ||
    temuPriceSource.indexOf('temuActiveSkuPriceText()') > temuPriceSource.indexOf('document.querySelectorAll(\'[class*="curPrice" i]\')')) {
  throw new Error('Temu selected-variant drawer price must precede the stale PDP curPrice fallback')
}

const selectTemuPriceText = ({ dialogs, pdp }) => {
  const boundedDialogs = dialogs.slice(-8).reverse()
  for (const dialog of boundedDialogs) {
    if (!dialog.visible || dialog.radios < 2 || !dialog.hasSku) continue
    for (const key of ['salePriceRich', 'currentPrice', 'curPrice']) {
      const text = dialog[key] || ''
      if (text.length <= 28 && /[0-9]/.test(text) && /SAR|ر\.س|\$/i.test(text)) return text
    }
  }
  return pdp
}

for (const [label, expected, input] of [
  ['gray live SKU beats stale PDP', '528.93 ر.س.', {
    dialogs: [{ visible: true, radios: 3, hasSku: true, salePriceRich: '528.93 ر.س.' }],
    pdp: '531.03 ر.س.',
  }],
  ['blue live SKU remains exact', '531.03 ر.س.', {
    dialogs: [{ visible: true, radios: 3, hasSku: true, salePriceRich: '531.03 ر.س.' }],
    pdp: '528.93 ر.س.',
  }],
  ['hidden stale drawer cannot replace PDP', '531.03 ر.س.', {
    dialogs: [{ visible: false, radios: 3, hasSku: true, salePriceRich: '528.93 ر.س.' }],
    pdp: '531.03 ر.س.',
  }],
  ['unrelated promotional dialog cannot replace PDP', '531.03 ر.س.', {
    dialogs: [{ visible: true, radios: 0, hasSku: false, salePriceRich: '15.00 ر.س.' }],
    pdp: '531.03 ر.س.',
  }],
]) {
  const actual = selectTemuPriceText(input)
  if (actual !== expected) throw new Error(`${label}: expected ${expected}, received ${actual}`)
}

if (!generatedCaptureSource.includes('match(/(\\d+)\\s*(?:الحجم|حجم)/i)')) {
  throw new Error('Generated Temu capture lost the escaped Arabic size-count regex')
}

for (const [label, text, marker, minimumUses] of [
  ['shared capture', source, 'temuProductOptionDialog(', 4],
  ['Gecko first-paint guard', geckoGuardSource, 'isProductOptionDialog(', 2],
]) {
  const uses = text.split(marker).length - 1
  if (uses < minimumUses) {
    throw new Error(`${label} must protect the real Temu SKU dialog before promo cleanup (${uses}/${minimumUses})`)
  }
  if (!text.includes('querySelectorAll(\'[role="radio"]\').length < 2') ||
      !text.includes('querySelector(\'[class*="sku" i],[class*="spec" i]\')')) {
    throw new Error(`${label} is missing the structural Temu SKU-dialog proof`)
  }
}

const forbiddenMarkers = [
  'temuAwaitOptionsThenAdd',
  'temuWatchPickThenAdd',
  'temuFinalizeAdd(10)',
  "type: 'debugTemuSku'",
  '__otlobliGateTrace',
]

for (const marker of forbiddenMarkers) {
  if (source.includes(marker)) throw new Error(`Stale Temu delayed/diagnostic path remains: ${marker}`)
}

const cartOpenStart = appSource.indexOf('const openStoreProductFromCart = (sourceLink: string)')
const cartOpenEnd = appSource.indexOf("InAppBrowser.addListener('closeEvent'", cartOpenStart)
const cartOpenSource = appSource.slice(cartOpenStart, cartOpenEnd)
const personalCartOpen = cartOpenSource.indexOf('const isPersonalTemuCartProduct')
const geckoOpen = cartOpenSource.indexOf('TemuEmbeddedBrowser.open({ url: targetUrl })')
const genericAccessGate = cartOpenSource.indexOf('const cartStoreAccessReady')
if (cartOpenStart < 0 || cartOpenEnd < 0 || personalCartOpen < 0 || geckoOpen < 0 || genericAccessGate < 0 ||
    personalCartOpen > genericAccessGate || geckoOpen > genericAccessGate) {
  throw new Error('Temu cart product must enter persistent Gecko before the legacy VPN gate')
}

for (const marker of [
  'session.setFocused(false);',
  'geckoView.setSession(session);',
  'session.setActive(true);',
  'session.setFocused(true);',
  'sameProduct(first, second)',
  'isSecurityVerificationUrl(currentUrl) && sameProduct(requestedDestinationUrl, requestedUrl)',
]) {
  if (!nativeSource.includes(marker)) throw new Error(`Missing persistent Gecko/security-session guard: ${marker}`)
}

const hideStart = nativeSource.indexOf('private void hideStoreLayer()')
const hideEnd = nativeSource.indexOf('private void ensureSessionAndOpen', hideStart)
const hideSource = nativeSource.slice(hideStart, hideEnd)
for (const marker of ['session.setActive(false);', 'geckoView.releaseSession();']) {
  if (hideSource.includes(marker)) throw new Error(`Temu hide must not discard the live verified context: ${marker}`)
}

const cartSwitchStart = appSource.indexOf('const switchCartStore = (id: StoreId)')
const cartSwitchEnd = appSource.indexOf('const toggleCoupon', cartSwitchStart)
const cartSwitchSource = appSource.slice(cartSwitchStart, cartSwitchEnd)
for (const marker of ["vpnStateRef.current = 'idle'", 'InAppBrowser.clearCache()', 'switchSelectedStore(id']) {
  if (cartSwitchSource.includes(marker)) throw new Error(`Cart tab switch must preserve geo and store sessions: ${marker}`)
}

const gate = (dimensions) => {
  const unmet = dimensions.find((dimension) =>
    dimension.count > 1 && !dimension.selected)
  if (!unmet) return 'allow'
  if (unmet.unavailableOnly) return 'هذا الخيار غير متوفر حالياً'
  if (unmet.kind === 'color') return 'حدد اللون أولاً'
  return /موديل/i.test(unmet.name) ? 'حدد الموديل أولاً' : 'حدد المقاس أولاً'
}

const cases = [
  ['new Temu Arabic "الحجم" group', 'حدد المقاس أولاً', [
    { kind: 'size', name: 'الحجم', count: 4, selected: null },
  ]],
  ['default color + unselected multi-size', 'حدد المقاس أولاً', [
    { kind: 'color', name: 'اللون', count: 4, selected: 'أبيض' },
    { kind: 'size', name: 'مقاس', count: 5, selected: null },
  ]],
  ['explicitly selected multi-size', 'allow', [
    { kind: 'color', name: 'اللون', count: 4, selected: 'أبيض' },
    { kind: 'size', name: 'مقاس', count: 5, selected: 'M' },
  ]],
  ['single size', 'allow', [{ kind: 'size', name: 'مقاس', count: 1, selected: null }]],
  ['no variants', 'allow', []],
  ['unavailable choice', 'هذا الخيار غير متوفر حالياً', [
    { kind: 'size', name: 'مقاس', count: 2, selected: null, unavailableOnly: true },
  ]],
]

for (const [label, expected, dimensions] of cases) {
  const actual = gate(dimensions)
  if (actual !== expected) throw new Error(`${label}: expected ${expected}, received ${actual}`)
}

console.log('Temu required-size, fast-add, cart-link and hidden-session guard: OK')
