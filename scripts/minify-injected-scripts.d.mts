import type { Plugin } from 'vite'

export const INJECTED_SCRIPT_SOURCE: string
export const protectedScriptModules: ReadonlySet<string>

export function minifyInjectedScriptExports(relativePath?: string): Promise<{
  exports: Record<string, string>
  metrics: Record<string, { originalBytes: number; minifiedBytes: number }>
}>

export function minifyInjectedScripts(): Plugin
