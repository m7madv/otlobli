# Otlobli AI Handoff

Read `CURRENT_STATE.md` first, then `AGENTS.md`.

## Current Baseline

- Active branch: `codex/customer-wallet-group-orders`
- Stable SHEIN baseline: v85 commit `2f24954`.
- Current candidate: v85.9 commit `86f15be`, version `2026.07.14-v85.9-shein-progressive-entry-warm-cache-no-otp-test`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.9-shein-progressive-entry-warm-cache-no-otp-test.ipa`; SHA-256 `F8F61473E4B6FD8D08F2D9667408070B59E6C882F59F3E95FC80E98EBCC53A59`; run `29326728706`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`.
- v85.4 IPA exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v85.4-shein-sa-no-otp-test.ipa`, but device testing failed: SHEIN still selected Bahrain. Its native initial-cookie preload has been removed.
- v85.5 reads SHEIN's authoritative signed `addressCookie` and completes SHEIN's own exact native cascade: Saudi Arabia -> Riyadh Province -> Riyadh -> Al Olaya. It supports both observed native drawer structures and adds no CSS, storage purge, address fabrication, or reload loop.
- v85.6 keeps the same WebView attached and interactive from first open, removes hidden/offscreen `FAKE_VISIBLE`, and uses a bounded native cover only while the exact Saudi cascade runs. Human challenges reveal immediately. Verified shipping controls are customer-locked narrowly; the internal exact automation remains allowed.
- v85.6 device result: first entry worked and Saudi correction worked, but the second entry could be a partial untappable page; the Temu round-trip still recovered it.
- v85.7 never parks SHEIN through plugin `hide/show`. It closes on app-screen exit and after meaningful background time, then creates a fresh WebView with the same website data. It requires DOM/content readiness, performs at most one fresh-instance retry, and displays explicit native preparation/Saudi status text.
- v85.7 failed on the real iPhone: the second-entry partial/untappable state remained exactly as before.
- v85.8 matches the missing part of the user-proven Temu round-trip: before every SHEIN open it clears only WebKit memory/disk cache. Capgo's iOS implementation preserves cookies/localStorage, including the signed Saudi address.
- v85.8 device result: iPhone 16 Pro Max opened normally, but iPhone 6 showed raw SHEIN without the Otlobli bar, did not hydrate products, and then showed a false change-server instruction.
- v85.9 removes per-entry cache clearing and the injected script's per-load Service Worker/Cache Storage purge. It injects at document start, keeps the existing Otlobli nav plus preparation surface until a loaded product card proves hydration, and uses one cache-clearing recovery only after a 35-second preparation failure. Preparation failure is no longer labeled as VPN failure.
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

Install v85.9 on both target iPhones. Test repeated store entry, app background/resume, category/product taps, preparation status/bar continuity, region-control lock, and Saudi persistence. Do not claim iPhone success before device evidence.

The inherited hidden/offscreen `FAKE_VISIBLE` path was removed deliberately after local plugin inspection showed it reparents and disables interaction on the first WebView. Do not reintroduce it.

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
- v85.6 Android validation confirmed an attached `visible=true` first WebView, working native cover messages, and visible human verification without closing. The challenge was not bypassed.
- v85.7 live Android validation confirmed a fresh page target on second entry and after resume; the second page loaded products and accepted a category tap. Android assembly passed.
- v85.7 failed real-device testing despite passing Android lifecycle validation.
- v85.8 failed the iPhone 6 slow-entry acceptance test despite working on iPhone 16 Pro Max.
- v85.9 Xcode workflow run `29326728706` passed; artifact payload contains the expected v85.9 marker and the copied IPA hash matches. Real-device testing is pending.

## Main Files

- App/WebView lifecycle: `src/App.tsx`
- Injected SHEIN/Temu script: `src/services/sheinBrowserScript.ts`
- Version/config: `src/config.ts`
- Customer styles: `src/styles.css`
- iOS plugin diagnostics patch: `patches/@capgo+capacitor-inappbrowser+8.6.25.patch`

Use Git history for old v69-v88 details; do not expand this file with release chronology.
