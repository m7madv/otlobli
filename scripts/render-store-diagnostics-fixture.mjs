import { mkdirSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { evaluateInjectedScriptExports } from './minify-injected-scripts.mjs'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const outputDir = resolve(projectRoot, 'output/playwright')
const outputPath = resolve(outputDir, 'store-script-diagnostics-fixture.html')
const { STORE_SCRIPT_DIAGNOSTICS_PANEL_SCRIPT } = evaluateInjectedScriptExports(
  'src/services/storeScriptDiagnostics.ts',
)

mkdirSync(outputDir, { recursive: true })
writeFileSync(outputPath, `<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
  <title>Store diagnostics fixture</title>
  <style>
    *{box-sizing:border-box}body{margin:0;background:#fff;color:#222;font-family:Arial,sans-serif}
    header{position:sticky;top:0;padding:16px;background:#fff;border-bottom:1px solid #ddd;font-weight:800}
    main{padding:14px;display:grid;grid-template-columns:1fr 1fr;gap:12px}
    article{min-height:190px;border-radius:12px;background:#f1f1f1;padding:10px;display:flex;align-items:flex-end}
  </style>
</head>
<body>
  <header>SHEIN — صفحة متجر تجريبية</header>
  <main>${Array.from({ length: 8 }, (_, index) => `<article>منتج ${index + 1}</article>`).join('')}</main>
  <script>
    window.__OTLOBLI_SCRIPT_FLAGS__={runtime:true,navigation:true,blocking:true,capture:true,session:true};
    window.mobileApp={postMessage:function(message){window.__lastDiagnosticMessage=message;}};
    ${STORE_SCRIPT_DIAGNOSTICS_PANEL_SCRIPT}
  </script>
</body>
</html>`, 'utf8')

console.log(outputPath)
