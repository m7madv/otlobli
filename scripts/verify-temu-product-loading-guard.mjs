import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { readStoreScriptSources } from './store-script-sources.mjs'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const source = readStoreScriptSources(root)

const requiredMarkers = [
  "var __otlobliTemuConfirmedProductIdentity = '';",
  "var __otlobliTemuConfirmedProductKey = '';",
  "var __otlobliTemuReadinessRouteKey = '';",
  'var identity = temuGoodsId() || location.pathname;',
  'function otlobliTemuInvalidateConfirmedProduct()',
  'function otlobliTemuCurrentProductConfirmed()',
  '__otlobliTemuConfirmedProductKey === key',
  '__otlobliTemuReadinessRouteKey !== key',
  "__otlobliTemuVisibleSinceKey = '';",
  '__otlobliTemuConfirmedProductIdentity = identity;',
  '__otlobliTemuConfirmedProductKey = key;',
  '!otlobliTemuCurrentProductConfirmed() && !v.domHasContent;',
]

for (const marker of requiredMarkers) {
  if (!source.includes(marker)) throw new Error(`Missing Temu product-loading guard: ${marker}`)
}

const shouldShowNotice = ({ product, searching, identity, key, confirmedIdentity, confirmedKey, domHasContent }) => {
  const confirmed = product && confirmedIdentity === identity && confirmedKey === key
  return product && !searching && !confirmed && !domHasContent
}

const cases = [
  ['new product with an actually empty DOM', true, {
    product: true, searching: false, identity: 'p1', key: 'p1|url-1', confirmedIdentity: '', confirmedKey: '', domHasContent: false,
  }],
  ['loaded product whose hero/price left the viewport', false, {
    product: true, searching: false, identity: 'p1', key: 'p1|url-1', confirmedIdentity: '', confirmedKey: '', domHasContent: true,
  }],
  ['confirmed product during a later transient DOM replacement', false, {
    product: true, searching: false, identity: 'p1', key: 'p1|url-1', confirmedIdentity: 'p1', confirmedKey: 'p1|url-1', domHasContent: false,
  }],
  ['same product id after a fresh SPA route lifetime', true, {
    product: true, searching: false, identity: 'p1', key: 'p1|url-2', confirmedIdentity: 'p1', confirmedKey: 'p1|url-1', domHasContent: false,
  }],
  ['a different new product with an empty DOM', true, {
    product: true, searching: false, identity: 'p2', key: 'p2|url-2', confirmedIdentity: 'p1', confirmedKey: 'p1|url-1', domHasContent: false,
  }],
]

for (const [label, expected, input] of cases) {
  const actual = shouldShowNotice(input)
  if (actual !== expected) throw new Error(`${label}: expected ${expected}, received ${actual}`)
}

console.log('Temu product-loading guard: OK')
