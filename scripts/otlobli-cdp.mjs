// Minimal CDP client for debugging the in-app SHEIN/Temu WebView on a real
// device over ADB. This is THE fast path for capture/color/size bugs - it
// ended days of blind guessing (see docs/AI_FASTPATH.md).
//
// Setup (once):
//   adb -s <serial> forward tcp:9222 localabstract:webview_devtools_remote_<pid>
//   # find <pid>: adb -s <serial> shell cat /proc/net/unix | tr -d '\000' | grep -o 'webview_devtools_remote_[0-9]*'
//   # list pages + their ws URLs: curl -s http://127.0.0.1:9222/json
//
// Usage:
//   node scripts/otlobli-cdp.mjs <wsUrl> nav <url>        -> Page.navigate + wait for load
//   node scripts/otlobli-cdp.mjs <wsUrl> eval <exprFile>  -> Runtime.evaluate (returnByValue), prints result
//
// The capture script publishes window.__otlobliDiag = {price,source,color,size,
// key,find,skuEntry,openDrawer,pending,saved}. An eval file that JSON.stringifies
// D.color()/D.size()/D.key() gives the exact captured variant without a rebuild.
// Node 18+ (global WebSocket) required; no npm deps.
const [, , wsUrl, mode, arg] = process.argv;
if (!wsUrl || !mode) { console.error('usage: otlobli-cdp.mjs <wsUrl> nav|eval <arg>'); process.exit(2); }
const ws = new WebSocket(wsUrl);
let id = 0;
const pending = new Map();
function send(method, params) {
  const mid = ++id;
  ws.send(JSON.stringify({ id: mid, method, params: params || {} }));
  return new Promise((res) => pending.set(mid, res));
}
ws.onmessage = (ev) => {
  const m = JSON.parse(ev.data);
  if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
};
ws.onerror = (e) => { console.error('WS error', e.message || e); process.exit(1); };
ws.onopen = async () => {
  await send('Runtime.enable');
  await send('Page.enable');
  if (mode === 'nav') {
    await send('Page.navigate', { url: arg });
    const deadline = Date.now() + 25000;
    while (Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, 1200));
      const r = await send('Runtime.evaluate', { expression: 'document.readyState', returnByValue: true });
      if (r.result && r.result.result && r.result.result.value === 'complete') break;
    }
    console.log('navigated:', arg);
  } else if (mode === 'eval') {
    const fs = await import('node:fs');
    const expr = fs.readFileSync(arg, 'utf8');
    const r = await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
    if (r.result && r.result.exceptionDetails) {
      console.log('EXCEPTION:', JSON.stringify(r.result.exceptionDetails).slice(0, 500));
    } else {
      const v = r.result && r.result.result ? r.result.result.value : undefined;
      console.log(typeof v === 'string' ? v : JSON.stringify(v));
    }
  }
  ws.close();
  process.exit(0);
};
