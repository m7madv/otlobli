# Otlobli AI Handoff

Read `CURRENT_STATE.md` first. This file is intentionally short to reduce token use.

## Start Checklist

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

Rules:

- Do not assume `main` is latest.
- Do not restore files from old branches without comparing the exact needed lines.
- Do not reset, checkout, or overwrite existing user/other-AI changes.
- Do not change payment, wallet, completed-order, coupon, or group-checkout logic unless the user clearly asks.
- Designs must come from Figma. If Figma asks for reauthentication, tell the user the minimum reconnect step.

## Important Context

- Active branch: `codex/customer-wallet-group-orders`
- Latest feature commit: `65f7e64` (`fix: v84 hide SHEIN bottom nav by hit test`)
- Claude old account may have worked after Codex. Always inspect current git state before editing.
- Claude new account may not have the same skills/connectors authenticated. Check available skills/tools, especially Figma.

## Current Production

- Customer: `https://talabieh.vercel.app`
- Admin: `https://talabieh-admin.vercel.app`
- Supabase project: `dcicqdprtyhwmhegabay`
- Desktop iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v69.ipa`
- v69 IPA SHA-256: `B4EE4E92D2F7AA383309120AE514515C37055576EFCA67F8E92A2B20900E04A0`
- v69 GitHub Actions run: `29268560648`
- Desktop v70 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v70.ipa`
- v70 IPA SHA-256: `C9A3F5BA4146E1FF1F4F88E289F64EE13CBDA6AF55B8361F06723BEFF52453DC`
- v70 GitHub Actions run: `29273940532`
- Desktop Android debug artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v70.apk`
- v70 APK SHA-256: `8D1AA3F46D3CA3FE3F83BE881A7FBB487EF0D54DEE35E218910C35C5F32A731A`
- Desktop v71 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v71.ipa`
- v71 IPA SHA-256: `6A68B89F6CFBD9DF40D94795693A61A0AFE24A2EA9CCC91272D0E1B2ED19E6A6`
- v71 GitHub Actions run: `29277541189`
- Desktop v72 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v72.ipa`
- v72 IPA SHA-256: `4D57D8D98E12F52743B905C15D5469E850D8FE2EF19EB2703F60439A40D12933`
- v72 GitHub Actions run: `29278990511`
- Desktop v73 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v73.ipa`
- v73 IPA SHA-256: `18C022FB0D207BB87E496DF67FDA4D8BC42F942922597B4C36ECE0B4D547D5F3`
- v73 GitHub Actions run: `29279855967`
- Desktop v74 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v74.ipa`
- v74 IPA SHA-256: `68EC10E14E8F1D0E9D40009B577BD6B5D68AFAB451DA1FEC5D08D6B709030E06`
- v74 GitHub Actions run: `29280481341`
- Desktop v75 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v75.ipa`
- v75 IPA SHA-256: `6D9FFE5F8B99611A73DB020D9B24F144F120B8048B2C2AB677297EA82B0F5DE1`
- v75 GitHub Actions run: `29281360380`
- Desktop v76 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v76.ipa`
- v76 IPA SHA-256: `2F9581087DC884F7A432CE41DDB868C142885C68E6566EFC4F9AEAA732D1995C`
- v76 GitHub Actions run: `29282623302`
- Desktop v77 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v77.ipa`
- v77 IPA SHA-256: `0EF63774AC0D7753C3DA088D1026BC63EF6228578A38006040C4B62BC907BDA2`
- v77 GitHub Actions run: `29283834227`
- Desktop v78 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v78.ipa`
- v78 IPA SHA-256: `8EF9E6A4ABFF327C0E34A2AB7DD905EA9059BB35C346FC393C8EDAC3F053FD2F`
- v78 GitHub Actions run: `29285536824`
- Desktop v79 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v79.ipa`
- v79 IPA SHA-256: `3A3A6D705317D57EB9C4AC88019884B3DBCB81366930878F9D45672B18243ADF`
- v79 GitHub Actions run: `29286393316`
- Desktop v80 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v80.ipa`
- v80 IPA SHA-256: `DBED4F281A7A24597668B25EE1CB31F9A01EE6459696601A9A3D13BA94F65070`
- v80 GitHub Actions run: `29287735934`
- Desktop v81 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v81.ipa`
- v81 IPA SHA-256: `F4DC6785BD3811FB21ACC54FFC6224622DEE4EA3FD08377B3A656EBF35128760`
- v81 GitHub Actions run: `29288517907`
- Desktop v82 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v82.ipa`
- v82 IPA SHA-256: `62F1D8A2EE9A68459FD5DBE5E417F30D331EFD187DDFE0A2C9FF115F4A6984A1`
- v82 GitHub Actions run: `29290104486`
- Desktop v83 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v83.ipa`
- v83 IPA SHA-256: `8504DF389BAF1303C0F5BAAC89F1BDFCA8796C746848E9ED240FA56F48C3DB9C`
- v83 GitHub Actions run: `29291593555`
- Desktop v84 iOS artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v84.ipa`
- v84 IPA SHA-256: `8065DF95F2F44272C0D74BEB6A389EA86B9D3947A64014486AF21240739AA872`
- v84 GitHub Actions run: `29292808196`

## Main Files

- Customer shell: `src/App.tsx`
- SHEIN/Temu WebView script: `src/services/sheinBrowserScript.ts`
- App APIs: `src/services/appApi.ts`, `src/services/supabaseAppApi.ts`, `src/services/localAppApi.ts`
- Local storage/session helpers: `src/infrastructure/localStorage.ts`
- Types: `src/domain/types.ts`
- Admin shell: `admin/src/AdminApp.tsx`
- Admin styles: `admin/src/styles.css`
- Supabase schema: `supabase/schema.sql`
- Supabase functions: `supabase/functions/cart-groups`, `supabase/functions/admin-orders`, `supabase/functions/admin-coupons`, `supabase/functions/admin-drivers`, `supabase/functions/app-settings`

## v66 Behavior Already Implemented

- Empty-cart invite links and visible group-cart controls.
- Shared-order owner/member metadata.
- Group-member order visibility.
- Owner-scoped product issue notifications/actions.
- Qadmous pickup recipient selection from group members.
- My Orders issue resolution with options/text/photo.
- Admin inline order selection and dynamic issue options.
- VPN/load-failure fallback returns to the VPN check instead of leaving a blank page.
- Temu search shell was stabilized.
- SHEIN challenge URLs are left alone by URL normalization.

## Current Highest Priority

v84 iPhone build is ready:

- This keeps the v83/v80 layout and does not change the SHEIN viewport.
- `src/services/sheinBrowserScript.ts` now adds old-WebKit-safe fallback width/height/padding for otlobli's injected nav before modern `min()/max()/env()` declarations.
- SHEIN's native bottom tab bar is hidden by bottom-of-screen hit testing and exact nav-text scoring (`أنا`, `حقيبة التسوق`, `ترندات`, `الفئات`, `متجر`) instead of broad CSS or viewport changes.
- The script logs a small `[otlobli] hid store bottom nav ...` payload for the first few hides to aid diagnostics.
- `src/config.ts` version: `2026.07.14-shein-bottom-hit-test-v84`.
- v84 iPhone unsigned IPA was built by GitHub Actions run `29292808196` and copied to the desktop.
- Do not repeat the failed v82 viewport/shield approach.

v83 iPhone build remains available:

- This is a clean rollback of the unstable v81/v82 SHEIN script work.
- `src/services/sheinBrowserScript.ts` is back to the v80/v77-style SHEIN UI behavior that looked good on iPhone 16 Pro Max.
- `src/App.tsx` was not changed; it keeps the v78 VPN behavior that helped iPhone 6 work with more VPN servers.
- `src/config.ts` version: `2026.07.14-clean-v80-rollback-v83`.
- v83 iPhone unsigned IPA was built by GitHub Actions run `29291593555` and copied to the desktop.
- Do not use v82 for testing; user reported horizontal page movement, invisible otlobli nav, missing top SHEIN tabs, and messy iPhone 6 layout.
- If iPhone 6 still shows SHEIN's native bottom bar on v83, gather diagnostics before adding more CSS hiders.

v82 iPhone build is archived only:

- This keeps the v80/v81 base and specifically targets the old iPhone 6 WebKit behavior reported by the user.
- On compact legacy iPhones, `ensureViewportFitCover()` sets SHEIN viewport width to `430` so SHEIN uses the wider layout closer to iPhone 16 Pro Max.
- `legacyOtlobliNavCss()` avoids CSS `min()`/`max()` for otlobli's injected bottom nav on compact legacy iPhones; these modern CSS functions likely made the injected nav collapse or fail on iPhone 6.
- `ensureOtlobliBottomShield()` adds a white layer under otlobli's nav only on compact SHEIN iPhones, covering SHEIN's native bottom bar without hiding product/categories above the nav.
- Back button now uses a plain text `›` glyph in a system font so the icon appears on old iPhone product pages.
- `src/config.ts` version: `2026.07.14-legacy-iphone6-nav-v82`.
- v82 iPhone unsigned IPA was built by GitHub Actions run `29290104486` and copied to the desktop.

v81 iPhone build remains available:

- This keeps the v80 base: v77-like SHEIN/UI behavior plus v78 VPN behavior.
- `src/services/sheinBrowserScript.ts` now detects SHEIN's native bottom tab bar by actual nav text/links (`أنا`, `حقيبة التسوق`, `ترندات`, `الفئات`, `متجر` / cart/category/profile/store) and point-probed ancestors near otlobli's nav. It avoids the broad v79 geometry hider.
- On narrow screens only (`<=400px` CSS width, e.g. iPhone 6), SHEIN's hero category/gender tabs are stabilized to prevent clipping while leaving iPhone 16 Pro Max untouched.
- SHEIN cleanup calls are individually guarded so old WebKit selector failures do not stop later cleanup steps.
- `src/config.ts` version: `2026.07.14-iphone6-shein-chrome-v81`.
- v81 iPhone unsigned IPA was built by GitHub Actions run `29288517907` and copied to the desktop.

v80 iPhone build remains available:

- This is the preferred test build after the user's correction.
- `src/services/sheinBrowserScript.ts` is restored to the v77 SHEIN/UI behavior that worked well on iPhone 16 Pro Max.
- `src/App.tsx` remains at the v78 VPN behavior that made iPhone 6 work with more VPN servers.
- `src/config.ts` version: `2026.07.14-v77-ui-v78-vpn-v80`.
- v80 iPhone unsigned IPA was built by GitHub Actions run `29287735934` and copied to the desktop.

v79 iPhone build is archived only and should not be used:

- `src/services/sheinBrowserScript.ts` adds a geometry-only hider for iPhone 6/SHEIN legacy bottom chrome: any non-otlobli fixed/interactive/wide bottom strip immediately above `#otlobli-nav` is hard-hidden.
- SHEIN cleanup ticks are wrapped defensively so one old-WKWebView failure cannot stop the remaining banner/header/bottom-nav cleanup.
- `src/config.ts` version: `2026.07.14-legacy-shein-bottom-v79`.
- v79 iPhone unsigned IPA was built by GitHub Actions run `29286393316` and copied to the desktop.
- User reported v79 over-hid real SHEIN options/categories on iPhone 16 Pro Max and still did not solve the iPhone 6 bottom bar, so do not continue from v79's broad geometry hider.

v78 iPhone build remains available:

- `src/App.tsx` no longer relies on `AbortSignal.timeout()` for VPN geo probes; it uses an older-WebView-safe timeout helper.
- VPN geo probing now resolves on the first successful provider and lets a confirmed non-Syria geo open the store without waiting for slow store image probes.
- `src/services/sheinBrowserScript.ts` reclaims otlobli's back button layer and hides SHEIN chrome collision zones around the top-right back button and bottom nav area.
- `src/config.ts` version: `2026.07.14-old-iphone-vpn-v78`.
- v78 iPhone unsigned IPA was built by GitHub Actions run `29285536824` and copied to the desktop.

v77 iPhone build is ready:

- `src/App.tsx` no longer forces a SHEIN close/recheck on normal foreground when the SHEIN WebView is already open and ready.
- `src/services/sheinBrowserScript.ts` hides SHEIN app-install banners, SHEIN login/sign-in prompts, and Temu spin/wheel reward popups.
- `src/config.ts` version: `2026.07.13-store-polish-v77`.
- v77 iPhone unsigned IPA was built by GitHub Actions run `29283834227` and copied to the desktop.

v76 iPhone build is ready:

- `src/App.tsx` now opens SHEIN hidden first (`hidden: true`, `InvisibilityMode.FAKE_VISIBLE`) and runs only a tiny post-load probe instead of injecting the full otlobli script at `documentStart`.
- If the hidden page is a SHEIN/Cloudflare/security challenge, it is not shown to the customer. After a short wait, the WebView is closed and the app shows VPN/server recovery advice.
- If the hidden page is a normal SHEIN page, the full `SHEIN_CAPTURE_SCRIPT` is injected with `executeScript`, then the WebView is shown.
- This is based on the observed Safari-vs-WKWebView difference and Cloudflare guidance that WebView challenges are sensitive to environment consistency, storage, and core browser behavior changes.
- `src/config.ts` version: `2026.07.13-hidden-shein-check-v76`.
- v76 iPhone unsigned IPA was built by GitHub Actions run `29282623302` and copied to the desktop.

v75 iPhone build is ready:

- `src/App.tsx` now closes any stale SHEIN native WebView and re-runs the VPN gate when the app returns from background or launches on the home screen. This targets the real-device case where VPN was turned off while SHEIN was active, then the app opened SHEIN and exited.
- `probeVpnGeo()` now checks four geo services in parallel (`ipwho.is`, `ipapi.co`, `api.country.is`, `geojs`) to reduce false no-VPN results.
- Non-blocked geo such as Turkey/USA is allowed even if the SHEIN image probe is flaky. If the store itself later fails, the app shows the existing recovery/VPN advice instead of exiting.
- `browseShein()` now has its own internal guard and refuses to open unless the current VPN state is `ok`, so direct retry paths cannot bypass the gate.
- `src/config.ts` version: `2026.07.13-shein-resume-vpn-v75`.
- v75 iPhone unsigned IPA was built by GitHub Actions run `29281360380` and copied to the desktop.

v74 iPhone build is ready:

- `src/App.tsx` now treats VPN-off / unknown-geo startup conservatively: if the device is online but the app cannot confirm a safe VPN, it shows the VPN-required state instead of opening SHEIN/Temu.
- Unexpected native WebView close on the home screen no longer auto-reopens into a close/crash loop. It pauses auto-open, refreshes VPN diagnosis, and shows store/VPN recovery UI.
- iOS network/WebKit failures `-1001`, `-1004`, `-1005`, and `-1009` are treated as recoverable store failures even after a page was previously ready.
- `src/config.ts` version: `2026.07.13-vpn-off-guard-v74`.
- v74 iPhone unsigned IPA was built by GitHub Actions run `29280481341` and copied to the desktop.

v73 iPhone build is ready:

- `src/App.tsx` now routes SHEIN/Temu open failures through one store-failure flow: close stuck WebView, pause auto-open, refresh VPN diagnosis, then show a clear VPN action.
- If VPN is confirmed (`vpnState=ok` with non-Syria `vpnGeo`), the failure message says only to change VPN server/app and retry "إعادة الدخول إلى المتجر".
- If VPN is not confirmed, the failure message says to turn VPN on first.
- Timed-out store loading uses the same VPN advice instead of the old generic internet message.
- `src/services/sheinBrowserScript.ts` hides SHEIN's native bottom nav more aggressively by detecting wide bottom tab bars on older devices such as iPhone 6.
- `src/config.ts` version: `2026.07.13-store-failure-vpn-v73`.
- v73 iPhone unsigned IPA was built by GitHub Actions run `29279855967` and copied to the desktop.

v72 iPhone build is ready:

- `src/App.tsx` now uses a permissive VPN gate: if geo/store probes fail on a VPN, it still opens the store unless the exit country is explicitly blocked (`SY`) or the device reports offline.
- `checkStoreReachable` now waits for all image probes and accepts any successful one instead of letting the first failed probe decide.
- `src/services/sheinBrowserScript.ts` now auto-clears foreign SHEIN region state and reloads normalized Saudi/USD URL up to two times if the page visibly opens on another shipping country such as Qatar.
- `src/config.ts` version: `2026.07.13-vpn-permissive-v72`.
- v72 iPhone unsigned IPA was built by GitHub Actions run `29278990511` and copied to the desktop.

v71 iPhone build is ready:

- `src/App.tsx` treats detailed iOS SHEIN WebKit failures (`code=-1005`, WebContent termination, and early no-network/timeouts) as fatal for that native WebView instance, closes it, pauses auto-open, and shows retry instead of leaving a white screen/app exit.
- `patches/@capgo+capacitor-inappbrowser+8.6.25.patch` now makes iOS `pageLoadError` include `phase`, `code`, `domain`, `description`, and failing URL, and emits on `webViewWebContentProcessDidTerminate`.
- v71 iPhone unsigned IPA was built by GitHub Actions run `29277541189` and copied to the desktop.
- The patch file intentionally keeps `OTLOBLI_RELAY_KEY_PLACEHOLDER`; `scripts/inject-relay-key.cjs` injects the local/CI secret after `patch-package`.

v70 local Android debug fix is built and installed on the emulator:

- `src/App.tsx` adds a SHEIN close-loop guard: if the native WebView closes during/shortly after SHEIN opening/security challenge, it pauses automatic reopen and shows retry instead of looping/crashing out.
- Emulator diagnostics showed SHEIN can emit many `pageLoadError` events while the page is visibly working; do not treat those as fatal during normal SHEIN browsing.
- v70 iPhone unsigned IPA was built by GitHub Actions run `29273940532` and copied to the desktop.

v69 fix is pushed and the iPhone IPA is built:

- `src/App.tsx` starts Temu on `/sa/` with `currency=USD&currencyCode=USD`, but no longer redirects Temu root/product-back URLs just because params are absent.
- `src/App.tsx` ignores SHEIN `pageLoadError` during normal opening so the black security check does not close the WebView.
- `src/App.tsx` no longer clears all cookies on store switch; it only clears cache when opening SHEIN.
- `src/App.tsx` keeps wallet USD balance from becoming false zero on transient RPC failure and clears wallet state on logout.
- `src/services/supabaseAppApi.ts` now throws on wallet balance RPC error instead of returning `0`.
- `src/services/sheinBrowserScript.ts` renders the otlobli bottom nav on SHEIN challenge pages, writes exact Temu Saudi/USD session keys, avoids hiding Temu price-looking elements, detects Arabic SHEIN challenge text, and writes Saudi shipping/currency keys even during challenge.
- v69 `src/config.ts` version was `2026.07.13-store-stability-v69`.

Still verify on a real device:

- SHEIN fresh open -> Temu -> SHEIN, with VPN set to Qatar; shipping must stay Saudi.
- SHEIN black security verification should stay visible with otlobli bottom nav and should not close the app after two seconds. If iOS WebKit returns network/WebKit errors or kills WebContent, v74 should keep the app open and show recovery/VPN advice.
- Try several VPN countries; the app should not show the old "bad region" gate for non-Syria VPNs merely because probes fail.
- On iPhone 6, SHEIN's own bottom tab bar should not appear above otlobli's nav.
- Temu should land on Saudi region and USD, keep product/back navigation stable, and keep prices visible while scrolling.
- Do not bypass captcha/security pages. The goal is to avoid breaking them and avoid app exit/white-screen loops.

## Validation Baseline

Previously passed during v66:

- Root `npm run build`
- Admin `npm run build`
- `git diff --check`
- Supabase migration push and `admin-orders` deploy
- Vercel customer/admin deployments
- GitHub iOS unsigned build

Passed after local v70 Android changes:

- Root `npm run build`
- `git diff --check`
- `npx cap sync android`
- `android\gradlew.bat -p android :app:assembleDebug`
- `adb install -r android\app\build\outputs\apk\debug\app-debug.apk`
- Emulator force-stop/open/background/return test: SHEIN stayed visible; no app crash; repeated SHEIN `pageLoadError` events observed and ignored.

Passed after v71 iOS WebKit guard:

- Root `npm run build`
- `patches/@capgo+capacitor-inappbrowser+8.6.25.patch` applies cleanly to a clean `@capgo/capacitor-inappbrowser@8.6.25` package.
- GitHub iOS unsigned build run `29277541189` passed and produced `otlobli-v71.ipa`.

Passed after v72 VPN permissive gate:

- Root `npm run build`
- GitHub iOS unsigned build run `29278990511` passed and produced `otlobli-v72.ipa`.

Passed after v73 store-failure VPN advice:

- Root `npm run build`
- GitHub iOS unsigned build run `29279855967` passed and produced `otlobli-v73.ipa`.

Passed after v74 VPN-off crash guard:

- Root `npm run build`
- GitHub iOS unsigned build run `29280481341` passed and produced `otlobli-v74.ipa`.

Passed after v75 SHEIN resume VPN recheck:

- Root `npm run build`
- GitHub iOS unsigned build run `29281360380` passed and produced `otlobli-v75.ipa`.

Passed after v76 hidden SHEIN security check:

- Root `npm run build`
- GitHub iOS unsigned build run `29282623302` passed and produced `otlobli-v76.ipa`.

Passed after v77 store popup/resume polish:

- Root `npm run build`
- `git diff --check`
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29283834227` passed and produced `otlobli-v77.ipa`.

Passed after v78 old iPhone compatibility:

- Root `npm run build`
- `git diff --check`
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29285536824` passed and produced `otlobli-v78.ipa`.

Passed after v79 legacy SHEIN bottom bar hider:

- Root `npm run build`
- `git diff --check`
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29286393316` passed and produced `otlobli-v79.ipa`.

Passed after v80 v77-UI/v78-VPN combination:

- Root `npm run build`
- `git diff --check`
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29287735934` passed and produced `otlobli-v80.ipa`.

Passed after v81 iPhone 6 SHEIN chrome fix:

- Root `npm run build`
- `git diff --check`
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29288517907` passed and produced `otlobli-v81.ipa`.

Passed after v82 legacy iPhone SHEIN nav fix:

- Root `npm run build`
- `git diff --check`
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29290104486` passed and produced `otlobli-v82.ipa`.

Passed after v83 clean rollback:

- Root `npm run build`
- `git diff --check`
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29291593555` passed and produced `otlobli-v83.ipa`.

Passed after v84 SHEIN bottom hit-test fix:

- Root `npm run build`
- `git diff --check`
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29292808196` passed and produced `otlobli-v84.ipa`.

Known gap:

- Repo-wide `npm run lint` had old failures before v66.
- Real-device SHEIN/Temu verification is still required.

## Keep This File Short

Long historical details were removed from current handoff files to reduce token spend. Use git history only when needed.
