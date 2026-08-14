import { readFileSync } from 'node:fs'
import { dirname, extname, relative, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import ts from 'typescript'
import { minify } from 'terser'
import { INJECTED_SCRIPT_SOURCE, stripInjectedComments } from './strip-injected-comments.mjs'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')

// These modules export JavaScript source that is injected into a remote store
// page. A normal Vite minifier treats that source as an opaque string, leaving
// its internal function names and control flow readable in the APK/IPA. Load
// only these pure string modules at build time, assemble their interpolations,
// then minify the resulting scripts as JavaScript before Vite packages them.
const protectedScriptModules = new Set([
  INJECTED_SCRIPT_SOURCE,
  'src/services/sheinFreezeDiagnostics.ts',
  'src/services/sheinRegionDiagnostics.ts',
])

const normalizedRelativePath = (path) => relative(projectRoot, path).replace(/\\/g, '/')

const resolveTypeScriptImport = (fromFile, specifier) => {
  if (!specifier.startsWith('.')) {
    throw new Error(`Injected-script modules may only import local pure modules: ${specifier}`)
  }
  const candidate = resolve(dirname(fromFile), specifier)
  return extname(candidate) ? candidate : `${candidate}.ts`
}

const evaluatePureStringModule = (absolutePath, cache = new Map()) => {
  if (cache.has(absolutePath)) return cache.get(absolutePath).exports

  const module = { exports: {} }
  cache.set(absolutePath, module)
  const source = stripInjectedComments(readFileSync(absolutePath, 'utf8'))
  const output = ts.transpileModule(source, {
    fileName: absolutePath,
    compilerOptions: {
      esModuleInterop: true,
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
    },
  }).outputText

  const localRequire = (specifier) =>
    evaluatePureStringModule(resolveTypeScriptImport(absolutePath, specifier), cache)
  new Function('exports', 'require', 'module', output)(module.exports, localRequire, module)
  return module.exports
}

const minifyStoreScript = async (name, source) => {
  const result = await minify(source, {
    compress: {
      passes: 2,
      unsafe: false,
    },
    ecma: 2017,
    format: {
      ascii_only: true,
      comments: false,
      semicolons: true,
    },
    mangle: {
      keep_classnames: false,
      keep_fnames: false,
      safari10: true,
      toplevel: true,
    },
    module: false,
    sourceMap: false,
    toplevel: true,
  })
  if (!result.code) throw new Error(`Terser emitted no code for ${name}`)
  new Function(result.code)
  return result.code
}

export const minifyInjectedScriptExports = async (relativePath = INJECTED_SCRIPT_SOURCE) => {
  if (!protectedScriptModules.has(relativePath)) {
    throw new Error(`Unregistered injected-script module: ${relativePath}`)
  }

  const original = evaluatePureStringModule(resolve(projectRoot, relativePath))
  const minified = {}
  const metrics = {}
  for (const [name, value] of Object.entries(original)) {
    if (typeof value !== 'string') {
      throw new Error(`${relativePath} export ${name} must be a string`)
    }
    minified[name] = await minifyStoreScript(`${relativePath}:${name}`, value)
    metrics[name] = {
      originalBytes: Buffer.byteLength(value, 'utf8'),
      minifiedBytes: Buffer.byteLength(minified[name], 'utf8'),
    }
  }
  return { exports: minified, metrics }
}

const emitProtectedModule = async (relativePath) => {
  const { exports } = await minifyInjectedScriptExports(relativePath)
  return Object.entries(exports)
    .map(([name, value]) => `export const ${name}=${JSON.stringify(value)};`)
    .join('\n')
}

export const minifyInjectedScripts = () => ({
  name: 'otlobli-minify-injected-scripts',
  apply: 'build',
  enforce: 'pre',
  async load(id) {
    const cleanId = id.split('?', 1)[0]
    const relativePath = normalizedRelativePath(cleanId)
    if (!protectedScriptModules.has(relativePath)) return null
    return { code: await emitProtectedModule(relativePath), map: null }
  },
})

export { INJECTED_SCRIPT_SOURCE, protectedScriptModules }
