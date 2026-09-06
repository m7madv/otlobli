#!/usr/bin/env node
// Offline release gate: untranslated strings may not silently use Arabic.
import {readFileSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
const root = resolve(import.meta.dirname, '..');
const locales = ['ar','en','es','fr','de','pt','zh','hi','ja','ru'];
const readArb = locale => JSON.parse(readFileSync(resolve(root, `lib/l10n/arb/app_${locale}.arb`), 'utf8'));
const reference = readArb('ar');
const keys = Object.keys(reference).filter(key => !key.startsWith('@'));
const variables = text => [...text.matchAll(/\{(p\d+)\}/g)].map(match=>match[1]).sort().join(',');
const errors = [];
for (const locale of locales) {
  const arb = readArb(locale);
  for (const key of keys) {
    if (typeof arb[key] !== 'string' || !arb[key].trim()) {
      errors.push(`${locale}: missing ${key}`);
    } else if (variables(arb[key]) !== variables(reference[key])) {
      errors.push(`${locale}: mismatched placeholders ${key}`);
    }
  }
  const iosLocale = locale === 'zh' ? 'zh-Hans' : locale;
  if (!existsSync(resolve(root, `ios/Runner/${iosLocale}.lproj/InfoPlist.strings`))) {
    errors.push(`${locale}: missing iOS permission localization`);
  }
  console.log(`${locale}: ${keys.filter(key=>typeof arb[key]==='string' && arb[key].trim()).length}/${keys.length}`);
}
if (errors.length) {
  console.error(errors.slice(0, 20).join('\n'));
  console.error(`${errors.length} localization errors. Release blocked.`);
  process.exitCode = 1;
} else {
  console.log('Catalog completeness and placeholder integrity passed. Linguistic and visual review are separate requirements.');
}
