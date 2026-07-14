# Otlobli AI Handoff

Read `CURRENT_STATE.md` first, then `AGENTS.md`.

## Current Baseline

- Active branch: `codex/customer-wallet-group-orders`
- Stable SHEIN baseline: v85 commit `2f24954`.
- Current test: v85.1 commit `8282091`, version `2026.07.14-v85.1-shein-category-touch-test`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.1-shein-category-touch-test.ipa`.
- v85.1 only narrows SHEIN menu/header interception to icon-only controls and removes the broad category restyling loop.

## Real-Device Evidence

- v85 was the most stable tested version on iPhone 6 and iPhone 16 Pro Max.
- v87 fixed none of the user's reported problems.
- v88 caused SHEIN entry to close/crash the WebView or app.
- Treat v86-v88 artifacts as failed archives, not bases for new work.

## Next Work

Test v85.1 category interactions on both target iPhones. Bahrain/SA region, first-load `For You`, and Add-to-Cart placement remain unresolved; do not mix them into the category-touch result.

Important baseline nuance: v85 contains the inherited hidden `FAKE_VISIBLE` opening flow and an exact-key storage guard. Do not casually remove or expand them. The current goal is observation and isolation, not another all-at-once region/WebView rewrite.

## Forbidden During SHEIN Pass

- No payment, wallet, completed-order, coupon, group-checkout, or Temu changes.
- No broad CSS selectors, viewport hacks, white shields, or hiding SHEIN content/options.
- No global storage deletion or aggressive `setUrl`/reload loops.
- No claim of success before testing both target iPhones.
- Designs only from Figma.

## Validation Baseline

- Root `npm run build`: passed.
- `SHEIN_CAPTURE_SCRIPT` syntax parse: passed.
- `git diff --check`: passed.
- v85.1 workflow run `29300495130`: passed; artifact source commit `8282091`.

## Main Files

- App/WebView lifecycle: `src/App.tsx`
- Injected SHEIN/Temu script: `src/services/sheinBrowserScript.ts`
- Version/config: `src/config.ts`
- Customer styles: `src/styles.css`
- iOS plugin diagnostics patch: `patches/@capgo+capacitor-inappbrowser+8.6.25.patch`

Use Git history for old v69-v88 details; do not expand this file with release chronology.
