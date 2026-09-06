// Narrow terminology corrections, gated on the original Arabic meaning.
// This does not constitute a full linguistic review of the catalog.
import {readFileSync, writeFileSync} from 'node:fs';
const catalog = JSON.parse(readFileSync('catalog.json','utf8'));
const cache = JSON.parse(readFileSync('translation-cache/en.json','utf8'));
const overrides = JSON.parse(readFileSync('overrides.json','utf8'));
let changed=0;
for (const [key, entry] of Object.entries(catalog)) {
  let text=cache[key];
  if (!text) continue;
  if (/ضمان/.test(entry.text)) {
    text=text.replace(/collateral|safeguards/gi, 'warranties');
  }
  if (/ضمانك/.test(entry.text)) {
    text=text.replace(/your escrow|your warranty/gi, 'Damanak');
  }
  if (/باقة|باقات|باقتك|باقتي|الباقة/.test(entry.text)) {
    text=text.replace(/packages/gi, 'plans').replace(/package/gi, 'plan');
  }
  if (/الصندوق|صندوق/.test(entry.text)) {
    text=text.replace(/fund sessions/gi, 'Register sessions')
      .replace(/fund session/gi, 'register session')
      .replace(/fund/gi, 'cash register').replace(/chest/gi, 'cash register');
  }
  if (/مطالب/.test(entry.text)) text=text.replace(/prompts/gi,'claims').replace(/prompt/gi,'claim');
  if (/استعاد|الاستعادة/.test(entry.text) && !/استرداد|رد الأموال/.test(entry.text)) {
    text=text.replace(/refundable purchases/gi,'purchases available to restore')
      .replace(/use the refund/gi,'restore purchases')
      .replace(/never pay again/gi,'do not pay again');
  }
  text=overrides[entry.text]?.en ?? text;
  if (text!==cache[key]) {cache[key]=text;changed++;}
}
writeFileSync('translation-cache/en.json',JSON.stringify(cache,null,2)+'\n');
console.log(`${changed} English terminology corrections applied.`);
