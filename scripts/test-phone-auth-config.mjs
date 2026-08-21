import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { dirname, resolve as resolvePath } from 'node:path'
import { fileURLToPath } from 'node:url'
import { runInNewContext } from 'node:vm'
import ts from 'typescript'

const root = resolvePath(dirname(fileURLToPath(import.meta.url)), '..')

const source = readFileSync(resolvePath(root, 'src/services/phoneAuthMode.ts'), 'utf8')
const compiled = ts.transpileModule(source, {
  compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
}).outputText
const module = { exports: {} }
runInNewContext(`(function(exports,module){${compiled}\n})(module.exports,module)`, {
  module,
  exports: module.exports,
})

const { resolvePhoneAuthBackend } = module.exports

const selectBackend = (mode, isDevelopment, localMockExplicitlyEnabled) =>
  resolvePhoneAuthBackend({ mode, isDevelopment, localMockExplicitlyEnabled })

assert.equal(selectBackend('real', false, false), 'whatsapp-api')
assert.equal(selectBackend('inbound', false, false), 'unavailable', 'Incomplete inbound mode must fail closed')
assert.equal(selectBackend(' REAL ', false, false), 'whatsapp-api')
assert.equal(selectBackend('', false, false), 'unavailable')
assert.equal(selectBackend('typo', false, false), 'unavailable')
assert.equal(selectBackend('mock', false, true), 'unavailable', 'Production must reject an explicit mock request')
assert.equal(selectBackend('mock', true, false), 'unavailable', 'Development mock requires the explicit flag')
assert.equal(selectBackend('mock', true, true), 'local-mock')
assert.equal(selectBackend('real', true, true), 'whatsapp-api', 'A configured real backend always wins')

for (const path of ['src/services/index.ts', 'src/services/supabaseAppApi.ts']) {
  const integration = readFileSync(resolvePath(root, path), 'utf8')
  assert.ok(integration.includes('auth: phoneAuthApi'), `${path} must use the centralized phone auth selector`)
  assert.ok(!integration.includes('auth: isWhatsappApiAuthEnabled ? whatsappAuthApi : localAppApi.auth'), `${path} still silently falls back to local auth`)
}

const provider = readFileSync(resolvePath(root, 'src/services/phoneAuthApi.ts'), 'utf8')
for (const marker of [
  'import.meta.env.DEV',
  'VITE_LOCAL_AUTH_MOCK_ENABLED',
  "phoneAuthBackend === 'local-mock'",
  ': unavailablePhoneAuthApi',
]) {
  assert.ok(provider.includes(marker), `Phone auth provider is missing fail-closed marker: ${marker}`)
}

console.log('Phone auth configuration tests passed (real only in production; incomplete inbound fails closed; mock development-only).')
