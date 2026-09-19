import { createServer } from 'node:http';
import { readFileSync, statSync } from 'node:fs';
import { extname, resolve, sep } from 'node:path';

// Loopback-only QA preview. No uploads, forms, remote requests, or application services.
const root = resolve(import.meta.dirname, '../legal_site');
const config = JSON.parse(readFileSync(resolve(root, 'vercel.json'), 'utf8'));
const headers = Object.fromEntries(config.headers.flatMap(g => g.headers.map(h => [h.key, h.value])));
const types = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json', '.png': 'image/png', '.xml': 'application/xml', '.txt': 'text/plain; charset=utf-8' };
createServer((request, response) => {
  if (!['GET', 'HEAD'].includes(request.method)) { response.writeHead(405); response.end(); return; }
  try {
    const path = decodeURIComponent(new URL(request.url, 'http://127.0.0.1').pathname);
    let file = resolve(root, path === '/' ? 'index.html' : `.${path}`);
    if (!file.startsWith(root + sep) || path.includes('/.')) throw new Error('Invalid path');
    if (!extname(file)) file += '.html';
    if (!statSync(file).isFile()) throw new Error('Not a file');
    response.writeHead(200, { ...headers, 'Content-Type': types[extname(file)] ?? 'application/octet-stream' });
    response.end(request.method === 'HEAD' ? undefined : readFileSync(file));
  } catch { response.writeHead(404); response.end('Not found'); }
}).listen(4179, '127.0.0.1', () => console.log('VoiceBrief marketing QA: http://127.0.0.1:4179 (loopback only)'));
