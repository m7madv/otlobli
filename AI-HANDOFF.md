# Otlobli AI Handoff

Read `CURRENT_STATE.md` first, then `AGENTS.md`.

## Current Baseline

- Active branch: `codex/customer-wallet-group-orders`
- Stable SHEIN baseline: v85 commit `2f24954`.
- Current test: v85.3 commit `6f80823`, version `2026.07.14-v85.3-shein-native-sa-picker-test`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.3-shein-saudi-picker-test.ipa`.
- v85.3 detects an explicit foreign shipping label, opens SHEIN's verified native country picker, and clicks only the exact Saudi Arabia row through SHEIN's own handler. No CSS, storage deletion, or reload was added.
- SHA-256: `BEDD2A0F6E42C7547BE43A5B3C2373E099171B98CCFB8679CE596577973AB356`; run `29303217368`.

## Real-Device Evidence

- v85 was the most stable tested version on iPhone 6 and iPhone 16 Pro Max.
- v87 fixed none of the user's reported problems.
- v88 caused SHEIN entry to close/crash the WebView or app.
- v85.2 real-device evidence: Saudi VPN + fresh install could select Saudi; US VPN changed the persisted WebView session to Bahrain; returning to Saudi VPN without reinstall stayed Bahrain. The shipping selector, not VPN alone, must update the authoritative session.
- Treat v86-v88 artifacts as failed archives, not bases for new work.

## Next Work

Test v85.3 on both target iPhones. On a product showing Bahrain, verify native picker navigation and exact Saudi Arabia selection, then repeat after US VPN -> Saudi VPN without reinstall. Cold entry/category taps and the Continue screen remain separate checks. Do not claim success before device evidence.

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
- Shipping signal/picker tests: passed, including rejecting the Saudi +966 auth form.
- v85.3 workflow run `29303217368`: passed; artifact source commit `6f80823`.

## Main Files

- App/WebView lifecycle: `src/App.tsx`
- Injected SHEIN/Temu script: `src/services/sheinBrowserScript.ts`
- Version/config: `src/config.ts`
- Customer styles: `src/styles.css`
- iOS plugin diagnostics patch: `patches/@capgo+capacitor-inappbrowser+8.6.25.patch`

Use Git history for old v69-v88 details; do not expand this file with release chronology.
