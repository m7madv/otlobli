# Otlobli AI Handoff

Read `CURRENT_STATE.md` first, then `AGENTS.md`.

## Current Baseline

- Active branch: `codex/customer-wallet-group-orders`
- Stable SHEIN baseline: v85 commit `2f24954`.
- Version: `2026.07.14-nav-polish-no-select-v85`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`.
- Local commits `4854d5f` and `875220c` reverse v88/v87/v86 and are intentionally not pushed yet.
- `src/App.tsx`, `src/services/sheinBrowserScript.ts`, `src/config.ts`, and `src/styles.css` match v85 byte-for-byte.

## Real-Device Evidence

- v85 was the most stable tested version on iPhone 6 and iPhone 16 Pro Max.
- v87 fixed none of the user's reported problems.
- v88 caused SHEIN entry to close/crash the WebView or app.
- Treat v86-v88 artifacts as failed archives, not bases for new work.

## Next Work

Receive the user's full SHEIN issue list before editing. Build a symptom-to-code map, identify shared root causes, and implement only one narrowly scoped change at a time. Explain the exact diff before any iOS build.

Important baseline nuance: v85 contains the inherited hidden `FAKE_VISIBLE` opening flow and an exact-key storage guard. Do not casually remove or expand them. The current goal is observation and isolation, not another all-at-once region/WebView rewrite.

## Forbidden During SHEIN Pass

- No payment, wallet, completed-order, coupon, group-checkout, or Temu changes.
- No broad CSS selectors, viewport hacks, white shields, or hiding SHEIN content/options.
- No global storage deletion or aggressive `setUrl`/reload loops.
- No claim of success before testing both target iPhones.
- No IPA until the single proposed change is reviewed.
- Designs only from Figma.

## Validation Baseline

- Root `npm run build`: passed.
- `SHEIN_CAPTURE_SCRIPT` syntax parse: passed.
- `git diff --check`: passed.
- No rollback IPA built.

## Main Files

- App/WebView lifecycle: `src/App.tsx`
- Injected SHEIN/Temu script: `src/services/sheinBrowserScript.ts`
- Version/config: `src/config.ts`
- Customer styles: `src/styles.css`
- iOS plugin diagnostics patch: `patches/@capgo+capacitor-inappbrowser+8.6.25.patch`

Use Git history for old v69-v88 details; do not expand this file with release chronology.
