// Substitutes the real relay key into the patched capacitor-inappbrowser
// source after patch-package applies the placeholder version (see
// patches/@capgo+capacitor-inappbrowser+*.patch and CHAT_SUMMARY.md
// section 9). Keeps the live secret out of git history while every local
// build still ends up with a working binary.
//
// Requires OTLOBLI_RELAY_KEY in the environment. Without it this is a
// no-op (web-only `npm install` on a machine that never builds the native
// apps shouldn't fail just because the secret isn't set).
const fs = require('fs')
const path = require('path')

function loadRelayKey() {
  if (process.env.OTLOBLI_RELAY_KEY) return process.env.OTLOBLI_RELAY_KEY
  // Local dev fallback: .env.relay.local (gitignored, see .gitignore's
  // `.env.*` rule) holds `OTLOBLI_RELAY_KEY=...` so the secret never needs
  // to be typed on a command line. CI sets the real env var instead.
  const localEnvPath = path.join(__dirname, '..', '.env.relay.local')
  if (!fs.existsSync(localEnvPath)) return undefined
  const match = fs.readFileSync(localEnvPath, 'utf8').match(/^OTLOBLI_RELAY_KEY=(.+)$/m)
  return match?.[1]?.trim()
}

const RELAY_KEY = loadRelayKey()
if (!RELAY_KEY) {
  console.warn('[inject-relay-key] OTLOBLI_RELAY_KEY not set - skipping (native SHEIN browsing will use the placeholder and get 403s from the relay until this is set and `npm install` is re-run)')
  process.exit(0)
}

const targets = [
  'node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/ProxySchemeHandler.swift',
  'node_modules/@capgo/capacitor-inappbrowser/android/src/main/java/ee/forgr/capacitor_inappbrowser/WebViewDialog.java',
]

for (const relativePath of targets) {
  const filePath = path.join(__dirname, '..', relativePath)
  if (!fs.existsSync(filePath)) continue
  const content = fs.readFileSync(filePath, 'utf8')
  const replaced = content.replaceAll('OTLOBLI_RELAY_KEY_PLACEHOLDER', RELAY_KEY)
  if (replaced !== content) {
    fs.writeFileSync(filePath, replaced)
    console.log(`[inject-relay-key] injected into ${relativePath}`)
  }
}
