// The store scripts in src/services/sheinBrowserScript.ts are template literals
// that get injected into the SHEIN/Temu page as source text. Every byte of that
// file — comments included — is shipped to the device and tokenised by
// JavaScriptCore at documentStart, before the store page can paint. Measured on
// v86.124: 17% of the emitted scripts were comment bytes (92,969 of 546,397),
// pure cost on an iPhone 6 with two cores.
//
// This strips whole-line comments only. A line is removed when its trimmed form
// starts with `//`, which cannot alter a string value: no line in this file
// begins with a protocol-relative URL or any other `//` token that is not a
// comment, and the freeze guard re-parses every emitted script after stripping,
// so a mistake here fails the build instead of shipping.
//
// Deliberately NOT removed: trailing comments after code, block comments, and
// blank lines. Those need real tokenising to handle safely, and line-comments
// already account for nearly all of the weight.
export const stripInjectedComments = (source) =>
  source
    .split('\n')
    .filter((line) => !line.trim().startsWith('//'))
    .join('\n')

export const INJECTED_SCRIPT_SOURCE = 'src/services/sheinBrowserScript.ts'
