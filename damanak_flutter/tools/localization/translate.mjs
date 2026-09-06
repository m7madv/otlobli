// Build-time translation of public UI templates only. No customer values,
// tokens, receipts or runtime network dependencies are sent or introduced.
// Disabled after the public provider rejected automated requests. Do not retry
// or bypass that restriction. Use reviewed ARB edits or the offline tool.
throw new Error('Public automated translation is disabled; use the offline workflow.');
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
const execFileAsync = promisify(execFile);

const langs = ['en', 'es', 'fr', 'de', 'pt', 'zh', 'hi', 'ja', 'ru'];
const entries = JSON.parse(readFileSync('extraction.json', 'utf8'));
const unique = new Map(entries.filter(e => !e.file.includes('/data/')).map(e => [e.id, e.text]));
const manual = {
  'ضمانك': 'Damanak', 'ضمانك للأعمال': 'Damanak for Business',
  'إصدار ضمان': 'Issue a warranty', 'أصدر الضمان': 'Issue warranty',
  'الضمانات': 'Warranties', 'الضمان': 'Warranty', 'مطالبات الضمان': 'Warranty claims',
  'المطالبات': 'Claims', 'المطالبة': 'Claim', 'الرئيسية': 'Home', 'الإدارة': 'Management',
  'بداية': 'Starter', 'نمو': 'Growth', 'توسع': 'Scale',
  'المنتجات': 'Products', 'العملاء': 'Customers', 'الفروع': 'Branches',
  'الفريق': 'Team', 'الإعدادات': 'Settings', 'استعادة المشتريات': 'Restore purchases',
  'شهري': 'Monthly', 'سنوي': 'Annual', 'خطة مجانية': 'Free plan',
};
mkdirSync('translation-cache', { recursive: true });

async function translate(batch, lang) {
  const text = batch.map(([id, value], i) => `[DMN${i}] ${value.replaceAll('ضمانك','Damanak').replaceAll('\n', ' __NL__ ')}`).join('\n');
  const url = new URL('https://translate.googleapis.com/translate_a/single');
  for (const [key,value] of Object.entries({client:'gtx',sl:'ar',tl:lang === 'zh' ? 'zh-CN' : lang,dt:'t',q:text})) url.searchParams.set(key,value);
  const { stdout } = await execFileAsync('pwsh', ['-NoProfile', '-File', 'translate-request.ps1', '-Url', url.href], { timeout: 35000, maxBuffer: 1024*1024 });
  const json = JSON.parse(stdout.replace(/^\uFEFF/, ''));
  const translated = json[0].map(part => part[0] ?? '').join('');
  const matches = [...translated.matchAll(/\[\s*DMN\s*(\d+)\s*\]\s*([\s\S]*?)(?=\[\s*DMN\s*\d+\s*\]|$)/g)];
  if (matches.length !== batch.length) throw new Error('Translation marker count mismatch');
  return matches.map((m,i) => {
    if (+m[1] !== i) throw new Error('Translation marker order mismatch');
    let value = m[2].trim().replace(/\s*__NL__\s*/g, '\n');
    value = value.replace(/\{\s*[pP]\s*(\d+)\s*\}/g, '{p$1}');
    const originalPlaceholders = batch[i][1].match(/\{p\d+\}/g) ?? [];
    const actualPlaceholders = value.match(/\{p\d+\}/g) ?? [];
    if (originalPlaceholders.sort().join() !== actualPlaceholders.sort().join()) throw new Error(`Placeholder mismatch ${batch[i][0]}`);
    if (lang === 'en') value = manual[batch[i][1]] ?? value.replace(/guarantees/gi, 'warranties').replace(/guarantee/gi, 'warranty');
    return [batch[i][0], value];
  });
}

async function run(lang) {
  const path = `translation-cache/${lang}.json`;
  const cache = existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : {};
  const missing = [...unique].filter(([key,value]) => !cache[key] || (value.includes('ضمانك') && !cache[key].includes('Damanak')));
  let batch = [];
  async function flush() {
    if (!batch.length) return;
    let translated;
    try { translated = await translate(batch,lang); }
    catch (error) {
      if (batch.length === 1) throw error;
      translated = [];
      for (const item of batch) translated.push(...await translate([item],lang));
    }
    for (const [key,value] of translated) cache[key] = value;
    writeFileSync(path, JSON.stringify(cache,null,2)+'\n');
    console.log(`${lang}: ${Object.keys(cache).length}/${unique.size}`);
    batch = [];
  }
  for (const item of missing) {
    if (batch.length >= 20 || encodeURIComponent(batch.map(x=>x[1]).join('\n')+item[1]).length > 6500) await flush();
    batch.push(item);
  }
  await flush();
}

// Limit parallel traffic and checkpoint each completed batch.
const requested = process.argv.slice(2);
for (let i=0; i<(requested.length ? requested : langs).length; i+=2) {
  await Promise.all((requested.length ? requested : langs).slice(i,i+2).map(run));
}
