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
- Latest feature commit: `019788b` (`fix: v73 show vpn advice on store failure`)
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
- SHEIN black security verification should stay visible with otlobli bottom nav and should not close the app after two seconds. If iOS WebKit returns `-1005` or kills WebContent, v73 should keep the app open and show retry.
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

Known gap:

- Repo-wide `npm run lint` had old failures before v66.
- Real-device SHEIN/Temu verification is still required.

## Keep This File Short

Long historical details were removed from current handoff files to reduce token spend. Use git history only when needed.
