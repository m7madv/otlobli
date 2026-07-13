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
- v66 feature commit: `f7b4456`
- v66 docs commit: `c733c72`
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

v70 local Android debug fix is built and installed on the emulator:

- `src/App.tsx` adds a SHEIN close-loop guard: if the native WebView closes during/shortly after SHEIN opening/security challenge, it pauses automatic reopen and shows retry instead of looping/crashing out.
- Emulator diagnostics showed SHEIN can emit many `pageLoadError` events while the page is visibly working; do not treat those as fatal during normal SHEIN browsing.
- `src/config.ts` version: `2026.07.13-store-polish-v70`.
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
- SHEIN black security verification should stay visible with otlobli bottom nav and should not close the app after two seconds. If native WebView closes anyway, v70 should keep the app open and show retry.
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

Known gap:

- Repo-wide `npm run lint` had old failures before v66.
- Real-device SHEIN/Temu verification is still required.

## Keep This File Short

Long historical details were removed from current handoff files to reduce token spend. Use git history only when needed.
