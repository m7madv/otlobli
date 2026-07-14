# Otlobli AI Handoff

Read `CURRENT_STATE.md` first, then `AGENTS.md`.

## Current Baseline

- Active branch: `codex/customer-wallet-group-orders`
- Stable SHEIN baseline: v85 commit `2f24954`.
- Current candidate: v85.5 commit `a064739`, version `2026.07.14-v85.5-shein-native-sa-address-no-otp-test`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.5-shein-native-sa-no-otp-test.ipa`; SHA-256 `99F2E6311880607AC63E6B2AA5D50797317A29D5AEC1F26377AADBBEB14D2F8F`; run `29319264525`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`.
- v85.4 IPA exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v85.4-shein-sa-no-otp-test.ipa`, but device testing failed: SHEIN still selected Bahrain. Its native initial-cookie preload has been removed.
- v85.5 reads SHEIN's authoritative signed `addressCookie` and completes SHEIN's own exact native cascade: Saudi Arabia -> Riyadh Province -> Riyadh -> Al Olaya. It supports both observed native drawer structures and adds no CSS, storage purge, address fabrication, or reload loop.
- App OTP screens are bypassed for this test IPA only. Set `TEST_ONLY_AUTH_BYPASS = false` before any production build.

## Real-Device Evidence

- v85 was the most stable tested version on iPhone 6 and iPhone 16 Pro Max.
- v87 fixed none of the user's reported problems.
- v88 caused SHEIN entry to close/crash the WebView or app.
- v85.2 real-device evidence: Saudi VPN + fresh install could select Saudi; US VPN changed the persisted WebView session to Bahrain; returning to Saudi VPN without reinstall stayed Bahrain. The shipping selector, not VPN alone, must update the authoritative session.
- v85.3 real-device evidence: first install could initialize Saudi or Bahrain and then persist it; native picker automation did not reliably correct Bahrain.
- v85.4 real-device evidence: preloading `localcountry=SA` did not correct Bahrain.
- Android emulator root evidence: URL/cookies/storage said SA while SHEIN's server returned Qatar. The authoritative signed `addressCookie` and product API both returned Qatar. A full native selection generated a signed Saudi address even while `ipCountry` stayed QA.
- v85.5 emulator test started from signed `Qatar / Doha / Al Jasra / Zone 1`, automatically completed the four Saudi levels in about 9 seconds, persisted across reload, and the product API returned `shipping_countryname = Saudi Arabia`.
- Treat v86-v88 artifacts as failed archives, not bases for new work.

## Next Work

Install v85.5 on both target iPhones from a persisted foreign address, then reload, switch stores, and switch VPNs. Cold entry/category taps remain a separate check. Do not claim iPhone success before device evidence.

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
- Native patch parse: passed; obsolete initial-cookie hunks are removed and relay secrets remain placeholders in Git.
- Android Capacitor sync and debug APK assembly: passed.
- Live Android WebView signed-address persistence and product API country validation: passed.
- v85.5 Xcode workflow run `29319264525` passed; artifact payload contains the expected v85.5 version marker. Real-device testing is pending.

## Main Files

- App/WebView lifecycle: `src/App.tsx`
- Injected SHEIN/Temu script: `src/services/sheinBrowserScript.ts`
- Version/config: `src/config.ts`
- Customer styles: `src/styles.css`
- iOS plugin diagnostics patch: `patches/@capgo+capacitor-inappbrowser+8.6.25.patch`

Use Git history for old v69-v88 details; do not expand this file with release chronology.
