# Otlobli Current State

Last updated: 2026-07-14

## Start Here

Repository: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`

Branch: `codex/customer-wallet-group-orders`

Before any edit:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

Read `AI-HANDOFF.md` and `AGENTS.md`. Preserve any existing user/other-AI changes.

## Active Store Baseline

- SHEIN/store baseline is v85 commit `2f24954` (`fix: v85 polish iOS nav and selection behavior`).
- v85 artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`
- v85 SHA-256: `F4524E816E6243A039BD52D34E7A9AB59E3C5597DBF0515862BA5F9461B90ED4`
- v85 GitHub Actions run: `29293816845`
- `APP_VERSION = 2026.07.14-nav-polish-no-select-v85`.
- v85.1 category-touch test commit: `8282091`.
- v85.1 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.1-shein-category-touch-test.ipa`
- v85.1 SHA-256: `9AB2149845E43E81D120E169CD7C85DF9DAE0F022B23DE86C38BF4ADB73A03B0`
- v85.1 GitHub Actions run: `29300495130`.
- v85.1 narrows header/menu blocking to icon-only controls and removes v85's broad category layout restyling loop. It does not change the hidden WebView flow or region logic.
- v85.2 candidate commit: `294dd78`.
- v85.2 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.2-shein-saudi-auth-test.ipa`
- v85.2 SHA-256: `CC1751C86EDD2BD98C92E77AA200E0759678AE6F276A3CDF46D3F032E6977A5B`
- v85.2 GitHub Actions run: `29302214134`.
- v85.2 preserves SHEIN auth forms, removes the destructive visible region reset/reload, accepts only shipping-labelled region evidence, and seeds SHEIN's evidenced `localcountry=SA` once per document.
- v85.2 device result: fresh install with Saudi VPN can start on Saudi, but switching to a US VPN changes SHEIN to Bahrain and switching back does not restore Saudi. This proves SHEIN persists the shipping choice in its WebView session; VPN/seed values alone are not authoritative.
- v85.3 candidate commit: `6f80823`; version `2026.07.14-v85.3-shein-native-sa-picker-test`.
- v85.3 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.3-shein-saudi-picker-test.ipa`
- v85.3 SHA-256: `BEDD2A0F6E42C7547BE43A5B3C2373E099171B98CCFB8679CE596577973AB356`; run `29303217368`.
- v85.3 uses only SHEIN's native shipping control: on an explicit foreign shipping label it opens the verified country picker, matches the exact Saudi Arabia row, and invokes SHEIN's own click handler. It also exempts only those verified controls from the old country/region click guard. No CSS, storage clearing, or reload was added.
- v85.3 device result: a fresh install can initialize either Saudi Arabia or Bahrain according to the first session/network, then persists that result across VPN and store changes. The native picker automation did not reliably correct Bahrain.
- v85.4 candidate head: `6a29b77`; version `2026.07.14-v85.4-shein-preload-sa-cookie-no-otp-test`.
- v85.4 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.4-shein-sa-no-otp-test.ipa`
- v85.4 SHA-256: `30290F292574363CBC9594C765D6FE88C86A1E35869F17F85742636556FF2FFD`; run `29304645602`.
- v85.4 device result: failed. SHEIN still selected Bahrain. The preload-cookie implementation was removed; `localcountry` is not SHEIN's authoritative shipping address.
- v85.5 candidate commit: `a064739`; version `2026.07.14-v85.5-shein-native-sa-address-no-otp-test`.
- v85.5 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.5-shein-native-sa-no-otp-test.ipa`
- v85.5 SHA-256: `99F2E6311880607AC63E6B2AA5D50797317A29D5AEC1F26377AADBBEB14D2F8F`; run `29319264525`.
- Root cause confirmed in Android WebView: SHEIN product APIs use a signed `addressCookie`, not VPN, URL params, or the `localcountry` cookie. Selecting only `Saudi Arabia` is incomplete; SHEIN persists the address only after country -> province -> city -> district.
- v85.5 uses SHEIN's native visible address drawer with exact targets only: `Saudi Arabia` -> `Riyadh Province` -> `Riyadh` -> `Al Olaya`. It supports both current SHEIN drawer markups and performs no CSS hiding, storage deletion, reload loop, or fabricated address/signature.
- Emulator proof from a signed Qatar address: `Qatar / Doha / Al Jasra / Zone 1` became a signed Saudi address in about 9 seconds, persisted after reload while `ipCountry` remained `QA`, and `get_goods_detail_realtime_data` returned `shipping_countryname = Saudi Arabia`.
- v85.6 candidate commit: `3388071`; version `2026.07.14-v85.6-shein-live-webview-native-cover-sa-lock-no-otp-test`.
- v85.6 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.6-shein-live-cover-sa-lock-no-otp-test.ipa`
- v85.6 SHA-256: `D457E19DF87236D00A3CABBE27F3EFFED8F6C8A4ED6A7B948415DD6111BD20F4`; run `29322372402`.
- v85.6 removes the inherited hidden/offscreen `FAKE_VISIBLE` first-open path. SHEIN stays attached, visible, laid out, and interactive behind a bounded native loading cover while the exact Saudi address flow runs. The cover is removed for human verification and has a native timeout, so it cannot permanently trap the customer.
- Verified shipping-region controls are narrowly locked against customer clicks; only the exact automatic native cascade is allowed. No broad CSS, viewport hack, content hiding, storage purge, or reload loop was added.
- v85.6 device result: Saudi correction worked, but only the first SHEIN entry was healthy; the second entry could return as a partially loaded, untappable page. Switching to Temu and back still rebuilt the WebView and recovered it.
- v85.7 candidate commit: `d2f2038`; version `2026.07.14-v85.7-shein-fresh-entry-health-recovery-sa-status-no-otp-test`.
- v85.7 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.7-shein-fresh-entry-recovery-sa-status-no-otp-test.ipa`
- v85.7 SHA-256: `DE22B0B5BE643BDD7BB03704C45A072550912ED5DF1E9E39656713F482643552`; run `29324148070`.
- v85.7 removes all app use of the plugin's SHEIN `hide/show` path. Leaving SHEIN or resuming after meaningful background time closes the old WKWebView and creates a fresh one while preserving shared website data and the signed Saudi address.
- `browserPageLoaded` is no longer accepted as SHEIN readiness. A bounded 13-second DOM/content health check performs one fresh-instance recovery, then shows a clear store/VPN failure instead of leaving an image-like page. The native cover now says `جاري تجهيز متجر SHEIN…` or `جاري ضبط المتجر على السعودية…`.
- v85.7 device result: failed. The second-entry partial/untappable SHEIN state remained exactly as before. Recreating WKWebView alone was not the missing part of the successful Temu round-trip.
- v85.8 candidate commit: `585a28a`; version `2026.07.14-v85.8-shein-cache-clean-entry-sa-status-no-otp-test`.
- v85.8 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8-shein-cache-clean-entry-sa-status-no-otp-test.ipa`
- v85.8 SHA-256: `689EE2D978269FB2ECB2EB4A3AA1B8436335ABC700C6B6C28B588508B636EF05`; run `29325121680`.
- The proven Temu -> SHEIN recovery closes the old WebView and calls `clearCache`. Capgo iOS source confirms this removes only `WKWebsiteDataTypeDiskCache` and `WKWebsiteDataTypeMemoryCache`, preserving cookies/localStorage and the signed Saudi `addressCookie`. v85.8 now performs that narrow cache cleanup before every SHEIN open.
- v85.8 corrected device result: this is the last build in the latest test round that accepted the user's VPN and opened SHEIN. It still exposes raw SHEIN chrome/content temporarily before the final processed view; that visual lifecycle issue remains separate.
- v85.8.1 candidate commit: `3150a33`; version `2026.07.14-v85.8.1-ios-cover-race-no-otp-test`.
- v85.8.1 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.1-ios-cover-race-no-otp-test.ipa`; SHA-256 `B091413083E4A0684855EBBFA62B89943623F82641F639EFCCB08C8E2DB4C745`; run `29331593635`.
- Root cause of the raw first frame: `WKWebViewController.initWebview()` loads the controller view before `InAppBrowserPlugin` assigns `otlobliLoadingCoverEnabled`, so the old `viewDidLoad` check always saw `false`. v85.8.1 installs the existing native cover synchronously from the option property's `didSet`, before presentation. `App.tsx`, `SHEIN_CAPTURE_SCRIPT`, VPN handling, and cache timing remain exactly v85.8.
- v85.8.1 Xcode/build validation passed; first entry and Temu -> SHEIN real-device testing are pending.
- v85.9 candidate commit: `86f15be`; version `2026.07.14-v85.9-shein-progressive-entry-warm-cache-no-otp-test`.
- v85.9 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.9-shein-progressive-entry-warm-cache-no-otp-test.ipa`
- v85.9 SHA-256: `F8F61473E4B6FD8D08F2D9667408070B59E6C882F59F3E95FC80E98EBCC53A59`; run `29326728706`.
- v85.9 preserves SHEIN Service Workers/cache on healthy entries, injects the existing Otlobli nav at document start, and keeps the existing in-page preparation surface until a real loaded product card proves hydration. One bounded recovery may clear native cache; a second failure is reported as preparation, not VPN. The native cover outlives the 35-second readiness watchdog so raw SHEIN is not exposed first.
- v85.9 device result: failed before usable store entry; it rejected the working VPN. Do not use it as a base. Its full `SHEIN_CAPTURE_SCRIPT` document-start injection and removal of v85.8's per-entry native cache clear have been reverted together.
- v85.10 candidate commit: `f273c80`; version `2026.07.14-v85.10-shein-final-ready-cover-no-otp-test`.
- v85.10 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.10-shein-final-ready-cover-no-otp-test.ipa`
- v85.10 SHA-256: `811FF316CC9CC6677DD7E9E61D3104FA8175CD7D88EFA5F3E0AC7F53B65C874E`; run `29328000485`.
- v85.10 keeps the native preparation cover through intermediate DOM bodies and Saudi repair. It reveals only after the signed Saudi address, a real loaded product, Otlobli nav, and the same final URL remain ready for 650ms. Human verification remains visible; blocked/foreign/raw states remain covered until app recovery/close.
- v85.10 device result: failed like v85.9 by rejecting the working VPN; prior visual observations were from the working v85.8 flow, not proof that v85.10 entered successfully.
- v85.11 candidate commit: `7c3249f`; version `2026.07.14-v85.11-shein-persistent-nav-loading-no-otp-test`.
- v85.11 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.11-shein-persistent-nav-loading-no-otp-test.ipa`
- v85.11 SHA-256: `70826941A97AF7496C602EC49C04C684BD308CC48029C3668A68CA91316AA3AF`; run `29328314651`.
- v85.11 uses the native cover only for the document-start gap, then hands off to the existing in-page preparation surface after Otlobli nav is attached. That surface remains below the nav and blocks SHEIN content/touches while preserving v85.10's signed-Saudi/product/650ms final-readiness gate.
- v85.11 device result: failed like v85.9/v85.10 by rejecting the working VPN.
- Restore commit `ce865a0` deliberately reverses v85.9-v85.11 store-path code and matches v85.8 commit `585a28a` exactly for `src/App.tsx`, `src/services/sheinBrowserScript.ts`, `src/config.ts`, and the Capgo patch.
- OTP screens remain bypassed only for this test candidate; set `TEST_ONLY_AUTH_BYPASS = false` before production.

v85 remains the stable store/UI baseline. The active candidate is v85.8.1: exact working v85.8 store behavior plus one native iOS pre-presentation cover fix. v85.9-v85.11 are failed and must not be continued.

## Failed Paths

- v86, v87, and v88 are failed/archived paths. Do not continue from them.
- v87 did not fix the reported SHEIN issues.
- v88 regressed opening SHEIN: the WebView/app closed or crashed on entry.
- Do not reuse their broad region/storage intervention, extra reload/setUrl behavior, blocker heuristics, or warm-up close/reopen flow.
- Do not claim any SHEIN issue is fixed without real-device testing on iPhone 6 and iPhone 16 Pro Max.

## Current Task

- Test v85.8.1 on first SHEIN entry and after Temu -> SHEIN on both iPhone 6 and iPhone 16 Pro Max. Confirm raw SHEIN never appears while the existing loading cover remains bounded and the final store is interactive.
- Verify the Saudi correction is not shown, the shipping-region control does not open for the customer, and Saudi persists across reload/store/VPN changes.
- Android structural validation is not a claim that either iPhone issue is fixed; both real devices remain the acceptance test.
- OTP bypass is only for faster store testing; customer account/server features and Add-to-Cart placement remain separate and unchanged.

## Scope Guard

- Do not change payment, wallet, completed orders, coupons, group checkout, or Temu during the SHEIN pass.
- No broad CSS, viewport-width hacks, white shields, or hiding SHEIN sections/options.
- Designs come from Figma only.
- Prefer targeted `rg` and Git diffs; old version history stays in Git, not in these handoff files.

## Last Validation

- `npm run build` passed.
- Runtime evaluation and syntax parse of `SHEIN_CAPTURE_SCRIPT` passed.
- `git diff --check` passed.
- Native patch parse passed; obsolete v85.4 initial-cookie additions were removed and tracked relay values remain placeholders.
- Android Capacitor sync and `assembleDebug` passed.
- Live Android WebView validation passed from signed Qatar to signed Saudi, across reload and at the product API response level.
- v85.6 Android validation showed the first SHEIN WebView attached with `visible=true`; native cover show/hide worked, and a SHEIN human challenge remained visible instead of closing the WebView. The challenge was not bypassed.
- v85.7 live Android validation proved that leaving SHEIN removes the old page target, returning creates a different attached `visible=true` WebView, category taps change SHEIN state, and a 3-second background/resume also creates a new target.
- v85.7 failed real-device testing: the second-entry partial/untappable state remained.
- v85.8 real-device result: passed initial opening on iPhone 16 Pro Max but failed slow entry on iPhone 6 with raw SHEIN, missing products, and a false server instruction.
- v85.9 unsigned IPA built successfully from `86f15be` in run `29326728706`; embedded version marker and copied SHA-256 verified. Real-device testing is pending.
- v85.9-v85.11 real-device result: all rejected the user's otherwise working VPN and never reached a usable store.
- v85.10 unsigned IPA built successfully from `f273c80` in run `29328000485`; embedded version marker and copied SHA-256 verified. Real-device testing is pending.
- Restore commit `ce865a0` passes build, runtime script parse, patch-package reinstall, diff checks, and exact v85.8 store-file parity. No duplicate IPA was built.
- v85.11 unsigned IPA built successfully from `7c3249f` in run `29328314651`; embedded version marker and copied SHA-256 verified. Real-device testing is pending.
- v85.8.1 passed clean `patch-package` reinstall, `npm run build`, runtime `SHEIN_CAPTURE_SCRIPT` parse, v85.8 App/script parity, `git diff --check`, Xcode run `29331593635`, and embedded version-marker/hash verification.

## Production References

- Customer: `https://talabieh.vercel.app`
- Admin: `https://talabieh-admin.vercel.app`
- Supabase project: `dcicqdprtyhwmhegabay`
