import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { test } from 'node:test';

const root = resolve(import.meta.dirname, '..');
const site = join(root, 'legal_site');
const origin = 'https://voicebrief-legal.vercel.app';
const paths = ['/', '/ar', '/guides/whatsapp-voice-notes', '/ar/guides/whatsapp-voice-notes', '/press', '/ar/press'];
const fileFor = path => join(site, path === '/' ? 'index.html' : `${path.slice(1)}.html`);
const config = JSON.parse(readFileSync(join(site, 'vercel.json'), 'utf8'));
const csp = config.headers.flatMap(h => h.headers).find(h => h.key === 'Content-Security-Policy').value;

for (const path of paths) test(`Static, localized and linked: ${path}`, () => {
  const html = readFileSync(fileFor(path), 'utf8');
  const ar = path === '/ar' || path.startsWith('/ar/');
  assert.ok(html.includes(`<html lang="${ar ? 'ar' : 'en'}" dir="${ar ? 'rtl' : 'ltr'}">`));
  assert.equal((html.match(/<h1>/g) ?? []).length, 1);
  assert.ok(html.includes(`<link rel="canonical" href="${origin + path}">`));
  for (const lang of ['en', 'ar', 'x-default']) assert.ok(html.includes(`hreflang="${lang}"`));
  assert.ok(html.includes('app-id=6805194629'));
  assert.ok(html.includes('https://apps.apple.com/app/id6805194629'));
  assert.ok(html.includes('mohammad alzouabi') || html.includes('MOHAMMAD ALZOUABI'));
  assert.ok(!html.includes('noindex'));
  const scripts = [...html.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/g)];
  assert.equal(scripts.length, 1, 'No executable marketing JavaScript');
  assert.ok(scripts[0][1].includes('application/ld+json'));
  const structured = JSON.parse(scripts[0][2]);
  assert.equal(structured['@graph'][0].identifier, '6805194629');
  assert.equal(structured['@graph'][0].offers.price, '0');
  assert.ok(structured['@graph'][0].offers.description.includes('optional'));
  assert.ok(!JSON.stringify(structured).includes('aggregateRating'), 'No invented ratings');
  const hash = createHash('sha256').update(scripts[0][2]).digest('base64');
  assert.ok(csp.includes(`'sha256-${hash}'`));
  for (const match of html.matchAll(/(?:href|src)="([^"]+)"/g)) {
    const url = new URL(match[1].replaceAll('&amp;', '&'), origin);
    if (url.origin !== origin) continue;
    const local = join(site, url.pathname.slice(1));
    const candidate = url.pathname === '/' ? fileFor('/') : existsSync(local) && statSync(local).isFile() ? local : `${local}.html`;
    assert.ok(existsSync(candidate), `Missing target ${url.pathname}`);
    if (url.hash && candidate.endsWith('.html')) assert.ok(readFileSync(candidate, 'utf8').includes(`id="${url.hash.slice(1)}"`), `Missing fragment ${url.href}`);
  }
  for (const img of html.matchAll(/<img [^>]+>/g)) for (const attr of ['alt=', 'width=', 'height=']) assert.ok(img[0].includes(attr));
  assert.ok(Buffer.byteLength(html) < 24000, 'HTML must stay lightweight');
});

test('Sitemap, crawlers, identity and ownership key are consistent', () => {
  const sitemap = readFileSync(join(site, 'sitemap.xml'), 'utf8');
  assert.equal((sitemap.match(/<url>/g) ?? []).length, paths.length);
  for (const path of paths) assert.ok(sitemap.includes(`<loc>${origin + path}</loc>`));
  const robots = readFileSync(join(site, 'robots.txt'), 'utf8');
  assert.ok(robots.includes('User-agent: *\nAllow: /'));
  assert.ok(robots.includes(`${origin}/sitemap.xml`));
  assert.match(readFileSync(join(site, 'indexnow-key.txt'), 'utf8').trim(), /^[a-f0-9]{32}$/);
  const facts = JSON.parse(readFileSync(join(site, 'app-facts.json'), 'utf8'));
  assert.equal(facts.application.identifier, '6805194629');
  assert.equal(facts.application.inLanguage.length, 11);
  assert.equal(config.cleanUrls, true);
  assert.ok(!config.redirects.some(r => r.source === '/'));
  for (const directive of ["object-src 'none'", "frame-ancestors 'none'", "base-uri 'self'", 'form-action https://jyehqpdbayslhzebdycj.supabase.co']) assert.ok(csp.includes(directive));
  assert.ok(!csp.includes('unsafe-inline'));
});

test('Marketing assets are byte-identical to approved app assets', () => {
  const hash = path => createHash('sha256').update(readFileSync(path)).digest('hex');
  assert.equal(hash(join(site, 'assets/app-icon.png')), hash(join(root, 'assets/brand/voicebrief_icon.png')));
  for (const lang of ['en', 'ar']) for (const name of ['01_home', '02_brief', '03_dates', '04_history']) {
    assert.equal(hash(join(site, `assets/${lang}-${name}.png`)), hash(join(root, `store_assets/localized/${lang}/iphone/${name}.png`)));
  }
});

test('Bilingual guidance discloses limitations and account requirements', () => {
  for (const lang of ['en', 'ar']) {
    const html = readFileSync(fileFor(lang === 'en' ? '/' : '/ar'), 'utf8');
    for (const term of ['Pro', 'Google', 'Apple', '24', '26.1', '6805194629']) assert.ok(html.includes(term));
    assert.ok(html.includes(lang === 'en' ? 'not an offline' : 'وليست محلية'));
  }
});
