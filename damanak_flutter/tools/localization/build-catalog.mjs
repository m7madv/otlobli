import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
const catalog = JSON.parse(readFileSync('catalog.json','utf8'));
const overrides = JSON.parse(readFileSync('overrides.json','utf8'));
const languages = ['ar','en','es','fr','de','pt','zh','hi','ja','ru'];
for (const language of languages) {
  const editorialPath = `editorial/${language}.json`;
  if (!existsSync(editorialPath)) continue;
  for (const [source, translation] of Object.entries(JSON.parse(readFileSync(editorialPath,'utf8')))) {
    overrides[source] = {...overrides[source], [language]: translation};
  }
}
const freePlan = {ar:'خطة مجانية',en:'Free plan',es:'Plan gratuito',fr:'Offre gratuite',de:'Kostenloser Tarif',pt:'Plano gratuito',zh:'免费方案',hi:'निःशुल्क प्लान',ja:'無料プラン',ru:'Бесплатный план'};
const sourceVersion = readFileSync('../../pubspec.yaml','utf8').match(/^version:\s*([^+\s]+)/m)?.[1];
if (!sourceVersion) throw new Error('Missing source version.');
mkdirSync('../../lib/l10n/arb',{recursive:true});
const escapeIcu = text => text.replaceAll("'", "''").replace(/\{(?!p\d+\})/g, "'{'").replace(/(?<!\{p\d+)\}/g,"'}'");
for (const language of languages) {
  const path = `translation-cache/${language}.json`;
  const cache = language === 'ar' ? Object.fromEntries(Object.entries(catalog).map(([k,v])=>[k,v.text])) : existsSync(path) ? JSON.parse(readFileSync(path,'utf8')) : {};
  const arb = {'@@locale':language};
  cache.msgce66eb05d98d = freePlan[language];
  cache.msge9a85ff0e478 = `${language==='ar'?'ضمانك للأعمال':'Damanak'} ${sourceVersion}`;
  const missing=[];
  for (const [key,entry] of Object.entries(catalog)) {
    if (overrides[entry.text]?.[language]) cache[key] = overrides[entry.text][language];
    if (!cache[key] && !/[\u0621-\u064a]/.test(entry.text)) cache[key] = entry.text.replaceAll('،', ',');
    if (!cache[key]) {missing.push(key); continue;}
    arb[key] = escapeIcu(cache[key]);
    if (language==='ar') {
      arb['@'+key] = {description:`UI copy: ${entry.file.replace(/^.*lib\//,'')}`, placeholders:Object.fromEntries(entry.arguments.map((_,i)=>['p'+i,{type:'Object'}]))};
    }
  }
  if (missing.length && process.argv.includes('--strict')) throw new Error(`${language}: ${missing.length} translations missing`);
  if (language==='ar' || Object.keys(arb).length>1) writeFileSync(`../../lib/l10n/arb/app_${language}.arb`,JSON.stringify(arb,null,2)+'\n');
  console.log(`${language}: ${Object.keys(catalog).length-missing.length}/${Object.keys(catalog).length}`);
}
// Only explicitly-owned presentation labels use this helper. Never apply it
// to customer-entered names or arbitrary persisted content.
let cases='';
for (const [key,entry] of Object.entries(catalog)) if (!entry.arguments.length) cases+=`    ${JSON.stringify(entry.text).replaceAll('$','\\$')} => L10n.current.${key},\n`;
writeFileSync('../../lib/l10n/known_labels.dart',`part of 'l10n.dart';\n\nString _knownLabel(String value) => switch (value) {\n${cases}    _ => value,\n};\n`);
