# Otlobli AI Handoff

Read `CURRENT_STATE.md` first, then `AGENTS.md`.

## Current Baseline

- Active branch: `codex/customer-wallet-group-orders`
- Stable SHEIN baseline: v85 commit `2f24954`.
- Current test: v85.4 head `6a29b77`, version `2026.07.14-v85.4-shein-preload-sa-cookie-no-otp-test`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.4-shein-sa-no-otp-test.ipa`.
- v85.4 seeds only `localcountry=SA` in `WKWebsiteDataStore` before the first SHEIN request. It preserves unrelated auth/cart/session cookies and adds no CSS, storage purge, picker loop, or reload.
- App OTP screens are bypassed for this test IPA only. Set `TEST_ONLY_AUTH_BYPASS = false` before any production build.
- SHA-256: `30290F292574363CBC9594C765D6FE88C86A1E35869F17F85742636556FF2FFD`; run `29304645602`.

## Real-Device Evidence

- v85 was the most stable tested version on iPhone 6 and iPhone 16 Pro Max.
- v87 fixed none of the user's reported problems.
- v88 caused SHEIN entry to close/crash the WebView or app.
- v85.2 real-device evidence: Saudi VPN + fresh install could select Saudi; US VPN changed the persisted WebView session to Bahrain; returning to Saudi VPN without reinstall stayed Bahrain. The shipping selector, not VPN alone, must update the authoritative session.
- v85.3 real-device evidence: first install could initialize Saudi or Bahrain and then persist it; native picker automation did not reliably correct Bahrain.
- Treat v86-v88 artifacts as failed archives, not bases for new work.

## Next Work

Delete the previous app and test v85.4 on both target iPhones. First install/open under a non-Saudi VPN and verify the first product's shipping country, then repeat under a Saudi VPN and change VPNs without reinstalling. Cold entry/category taps remain a separate check. Do not claim success before device evidence.

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
- Native patch parse/reverse checks: passed; relay secrets remain placeholders in Git.
- v85.4 workflow run `29304645602`: passed, including Xcode; artifact head `6a29b77`.

## Main Files

- App/WebView lifecycle: `src/App.tsx`
- Injected SHEIN/Temu script: `src/services/sheinBrowserScript.ts`
- Version/config: `src/config.ts`
- Customer styles: `src/styles.css`
- iOS plugin diagnostics patch: `patches/@capgo+capacitor-inappbrowser+8.6.25.patch`

Use Git history for old v69-v88 details; do not expand this file with release chronology.
