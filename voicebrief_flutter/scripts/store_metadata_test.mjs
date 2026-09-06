import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {storeNames} from './store_names.mjs';
import {storeKeywords} from './store_keywords.mjs';

const manifest=JSON.parse(readFileSync(new URL('../store_assets/localized/manifest.json',import.meta.url),'utf8'));
test('All eleven locales have valid approved brand-preserving names',()=>{
  assert.equal(Object.keys(storeNames).length,11);
  assert.equal(storeNames['ar-SA'],'VoiceBrief');
  assert.equal(storeNames['en-US'],'VoiceBrief: Audio Summaries');
  for(const local of manifest.localizations){
    const name=storeNames[local.attributes.locale];
    assert.ok(name.startsWith('VoiceBrief'));
    assert.ok([...name].length<=30);
  }
});
test('Every release locale includes nonempty keywords under the Apple limit',()=>{
  assert.equal(Object.keys(storeKeywords).length,11);
  for(const local of manifest.localizations){
    const keywords=local.attributes.keywords;
    assert.equal(keywords,storeKeywords[local.language]);
    assert.ok(keywords.trim());
    assert.ok([...keywords].length<=100);
    assert.ok(keywords.split(',').every(k=>k.trim()));
  }
});
test('The release manifest is scoped to build21 with four images per device',()=>{
  assert.equal(manifest.version,'0.1.2');assert.equal(manifest.build,21);
  assert.equal(manifest.localizations.length,11);
  for(const local of manifest.localizations){
    assert.equal(local.screenshots.length,8);
    assert.equal(local.screenshots.filter(s=>s.type==='APP_IPHONE_65').length,4);
    assert.equal(local.screenshots.filter(s=>s.type==='APP_IPAD_PRO_3GEN_129').length,4);
  }
});
