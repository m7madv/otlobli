import { readFileSync, statSync } from 'node:fs'
import { resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const STORE_SCRIPT_SOURCE_FILES = [
  'src/services/sheinBrowserScript.ts',
  'src/services/sheinNavigationScript.ts',
  'src/services/sheinPrivacyCompatScript.ts',
  'src/services/sheinSessionScript.ts',
  'src/services/storeProductCaptureScript.ts',
  'src/services/storeBlockingScript.ts',
  'src/services/temuBrowserScript.ts',
  'src/services/storeRuntimeCoordinator.ts',
  'src/services/storeScriptDiagnostics.ts',
]

const rootPath = (root) => root instanceof URL ? fileURLToPath(root) : root

export const readStoreScriptSources = (root) => STORE_SCRIPT_SOURCE_FILES
  .map((file) => readFileSync(resolve(rootPath(root), file), 'utf8'))
  .join('\n')

export const storeScriptSourceBytes = (root) => STORE_SCRIPT_SOURCE_FILES
  .reduce((total, file) => total + statSync(resolve(rootPath(root), file)).size, 0)
