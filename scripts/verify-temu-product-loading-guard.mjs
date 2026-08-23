import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { readStoreScriptSources } from './store-script-sources.mjs'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const source = readStoreScriptSources(root)

const requiredMarkers = [
  "var __otlobliTemuConfirmedProductIdentity = '';",
  'var identity = temuGoodsId() || location.pathname;',
  'if (__otlobliTemuConfirmedProductIdentity === identity) return;',
  '__otlobliTemuConfirmedProductIdentity = identity;',
  '__otlobliTemuConfirmedProductIdentity !== identity && !v.domHasContent;',
  '__otlobliTemuConfirmedProductIdentity === identity ||',
]

for (const marker of requiredMarkers) {
  if (!source.includes(marker)) throw new Error(`Missing Temu product-loading guard: ${marker}`)
}

const shouldShowNotice = ({ product, searching, identity, confirmedIdentity, domHasContent }) =>
  product && !searching && confirmedIdentity !== identity && !domHasContent

const cases = [
  ['new product with an actually empty DOM', true, {
    product: true, searching: false, identity: 'p1', confirmedIdentity: '', domHasContent: false,
  }],
  ['loaded product whose hero/price left the viewport', false, {
    product: true, searching: false, identity: 'p1', confirmedIdentity: '', domHasContent: true,
  }],
  ['confirmed product during a later transient DOM replacement', false, {
    product: true, searching: false, identity: 'p1', confirmedIdentity: 'p1', domHasContent: false,
  }],
  ['a different new product with an empty DOM', true, {
    product: true, searching: false, identity: 'p2', confirmedIdentity: 'p1', domHasContent: false,
  }],
]

for (const [label, expected, input] of cases) {
  const actual = shouldShowNotice(input)
  if (actual !== expected) throw new Error(`${label}: expected ${expected}, received ${actual}`)
}

console.log('Temu product-loading guard: OK')
