import fs from 'node:fs'
import path from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import ts from 'typescript'
import { stripInjectedComments } from './strip-injected-comments.mjs'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const entry = path.join(root, 'src/services/sheinBrowserScript.ts')
const tempDir = path.join(root, 'android/app/build/temu-gecko-script')
const extensionDir = path.join(root, 'android/app/src/temuPersonal/assets/temu_extension')

fs.rmSync(tempDir, { recursive: true, force: true })
fs.mkdirSync(tempDir, { recursive: true })
fs.writeFileSync(path.join(tempDir, 'package.json'), '{"type":"commonjs"}\n')

const program = ts.createProgram({
  rootNames: [entry],
  options: {
    module: ts.ModuleKind.CommonJS,
    target: ts.ScriptTarget.ES2020,
    moduleResolution: ts.ModuleResolutionKind.Node10,
    outDir: tempDir,
    rootDir: path.join(root, 'src'),
    skipLibCheck: true,
    esModuleInterop: true,
    ignoreDeprecations: '6.0',
  },
})
const emit = program.emit()
const diagnostics = ts.getPreEmitDiagnostics(program).concat(emit.diagnostics)
if (diagnostics.length) {
  const formatted = ts.formatDiagnosticsWithColorAndContext(diagnostics, {
    getCurrentDirectory: () => root,
    getCanonicalFileName: (name) => name,
    getNewLine: () => '\n',
  })
  throw new Error(`Unable to generate the Temu Gecko content script:\n${formatted}`)
}

const require = createRequire(import.meta.url)
const built = require(path.join(tempDir, 'services/sheinBrowserScript.js'))
let capture = stripInjectedComments(String(built.SHEIN_CAPTURE_SCRIPT || ''))
if (!capture) throw new Error('SHEIN_CAPTURE_SCRIPT was empty')

// MainActivity owns the real Otlobli navigation bar. Keep every blocker and
// product-capture routine from the proven script, but prevent the page from
// creating a duplicate navigation or back button inside GeckoView.
capture = capture
  .replace('function ensureOtlobliNav() {', 'function ensureOtlobliNav() { return;')
  .replace('function ensureBackButton() {', 'function ensureBackButton() { return;')

const legacyProductCheck = 'if (/goods/i.test(location.pathname)) return true;'
if (!capture.includes(legacyProductCheck)) {
  throw new Error('Unable to extend Temu product-route detection for Gecko')
}
capture = capture.replace(
  legacyProductCheck,
  'if (/goods/i.test(location.pathname) || /(?:^|-)g-\\d+\\.html$/i.test(location.pathname)) return true;',
)

const bridge = `
(() => {
  const post = (payload) => {
    try {
      const sent = browser.runtime.sendNativeMessage('otlobli', payload)
      if (payload && payload.detail && payload.detail.type === 'addToCart') {
        void sent.then(() => {
          window.dispatchEvent(new CustomEvent('messageFromNative', {
            detail: { type: 'addToCartAck' },
          }))
        }).catch(() => undefined)
      } else {
        void sent.catch(() => undefined)
      }
    } catch (_) {}
  }
  window.mobileApp = { postMessage: post }
})();
`

fs.mkdirSync(extensionDir, { recursive: true })
const captureGuard = `
if (/^(?:www\\.)?temu\\.com$/i.test(location.hostname) &&
    (/\\/goods\\.html$/i.test(location.pathname) || /(?:^|-)g-\\d+\\.html$/i.test(location.pathname) ||
     /[?&]goods_id=\\d+/i.test(location.search))) {
${capture}
}
`
fs.writeFileSync(path.join(extensionDir, 'content-capture.js'), `${bridge}\n;\n${captureGuard}\n`)
console.log(`Temu Gecko capture script: ${Buffer.byteLength(capture)} bytes`)
