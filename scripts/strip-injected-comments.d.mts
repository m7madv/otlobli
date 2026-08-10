// Types for the build-time comment stripper shared by vite.config.ts and the
// two verifier scripts. Kept next to the .mjs so tsc resolves it automatically.
export declare const stripInjectedComments: (source: string) => string
export declare const INJECTED_SCRIPT_SOURCE: string
