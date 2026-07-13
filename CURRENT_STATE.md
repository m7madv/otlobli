# Otlobli Current State

Last updated: 2026-07-14

This is the short source of truth for the app work. Keep it compact so Codex/Claude do not burn context on old history.

## Active Repo

- Path: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`
- Branch: `codex/customer-wallet-group-orders`
- Latest feature commit: `aa5e81f` (`fix: v82 legacy iPhone SHEIN nav`)

Before any code change:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

If there are existing changes, treat them as user/other-AI work. Do not reset or overwrite them.

## Production State

- Customer app: `https://talabieh.vercel.app`
- Admin app: `https://talabieh-admin.vercel.app`
- Supabase project ref: `dcicqdprtyhwmhegabay`
- v69 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v69.ipa`
- v69 IPA SHA-256: `B4EE4E92D2F7AA383309120AE514515C37055576EFCA67F8E92A2B20900E04A0`
- v69 GitHub Actions run: `29268560648`
- v70 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v70.ipa`
- v70 IPA SHA-256: `C9A3F5BA4146E1FF1F4F88E289F64EE13CBDA6AF55B8361F06723BEFF52453DC`
- v70 GitHub Actions run: `29273940532`
- v70 Android debug artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v70.apk`
- v70 APK SHA-256: `8D1AA3F46D3CA3FE3F83BE881A7FBB487EF0D54DEE35E218910C35C5F32A731A`
- v71 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v71.ipa`
- v71 IPA SHA-256: `6A68B89F6CFBD9DF40D94795693A61A0AFE24A2EA9CCC91272D0E1B2ED19E6A6`
- v71 GitHub Actions run: `29277541189`
- v72 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v72.ipa`
- v72 IPA SHA-256: `4D57D8D98E12F52743B905C15D5469E850D8FE2EF19EB2703F60439A40D12933`
- v72 GitHub Actions run: `29278990511`
- v73 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v73.ipa`
- v73 IPA SHA-256: `18C022FB0D207BB87E496DF67FDA4D8BC42F942922597B4C36ECE0B4D547D5F3`
- v73 GitHub Actions run: `29279855967`
- v74 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v74.ipa`
- v74 IPA SHA-256: `68EC10E14E8F1D0E9D40009B577BD6B5D68AFAB451DA1FEC5D08D6B709030E06`
- v74 GitHub Actions run: `29280481341`
- v75 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v75.ipa`
- v75 IPA SHA-256: `6D9FFE5F8B99611A73DB020D9B24F144F120B8048B2C2AB677297EA82B0F5DE1`
- v75 GitHub Actions run: `29281360380`
- v76 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v76.ipa`
- v76 IPA SHA-256: `2F9581087DC884F7A432CE41DDB868C142885C68E6566EFC4F9AEAA732D1995C`
- v76 GitHub Actions run: `29282623302`
- v77 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v77.ipa`
- v77 IPA SHA-256: `0EF63774AC0D7753C3DA088D1026BC63EF6228578A38006040C4B62BC907BDA2`
- v77 GitHub Actions run: `29283834227`
- v78 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v78.ipa`
- v78 IPA SHA-256: `8EF9E6A4ABFF327C0E34A2AB7DD905EA9059BB35C346FC393C8EDAC3F053FD2F`
- v78 GitHub Actions run: `29285536824`
- v79 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v79.ipa`
- v79 IPA SHA-256: `3A3A6D705317D57EB9C4AC88019884B3DBCB81366930878F9D45672B18243ADF`
- v79 GitHub Actions run: `29286393316`
- v80 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v80.ipa`
- v80 IPA SHA-256: `DBED4F281A7A24597668B25EE1CB31F9A01EE6459696601A9A3D13BA94F65070`
- v80 GitHub Actions run: `29287735934`
- v81 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v81.ipa`
- v81 IPA SHA-256: `F4DC6785BD3811FB21ACC54FFC6224622DEE4EA3FD08377B3A656EBF35128760`
- v81 GitHub Actions run: `29288517907`
- v82 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v82.ipa`
- v82 IPA SHA-256: `62F1D8A2EE9A68459FD5DBE5E417F30D331EFD187DDFE0A2C9FF115F4A6984A1`
- v82 GitHub Actions run: `29290104486`
- No new Android build was requested for v82.

## v66 Completed

- Shared-cart invite links can link even when the recipient cart is empty.
- Group-cart controls remain visible in the empty cart.
- Shared orders are visible to group members.
- Order items carry owner/member metadata.
- Product issue actions/notifications are scoped to the product owner.
- Checkout can choose the Qadmous pickup recipient from group members.
- My Orders can resolve size/color/text/photo issues without WhatsApp.
- Admin order rows select inline and show details below.
- Admin issue options use dynamic add-option fields and can request a customer photo.
- `admin-orders` was deployed and the shared-order ownership migration was applied.
- Customer/admin production deployments were updated and verified with HTTP 200.
- Root and admin production builds passed during v66.

## Current Known Issues

- v82 iOS build is ready: `APP_VERSION = 2026.07.14-legacy-iphone6-nav-v82`.
- v82 change: on compact legacy iPhones, SHEIN gets viewport width 430 and otlobli's injected bottom nav uses old-WebKit-safe CSS without CSS `min()`/`max()`.
- v82 change: adds a bottom white shield under otlobli's nav on compact iPhones to cover SHEIN's native bottom bar without hiding page content above the nav.
- v82 change: back button uses a plain text `›` glyph with system font so the icon is visible on old iPhones.
- v81 iOS build remains available: `APP_VERSION = 2026.07.14-iphone6-shein-chrome-v81`.
- v81 change: keeps the v80 base, then narrowly targets iPhone 6 SHEIN chrome: bottom SHEIN tab bar is detected by its real nav text/links and hidden, not by broad geometry.
- v81 change: on narrow screens only, SHEIN hero gender/category tabs are made horizontally stable so labels like all/women/kids/men are not clipped.
- v80 iOS build remains available: `APP_VERSION = 2026.07.14-v77-ui-v78-vpn-v80`.
- v80 change: SHEIN/UI script was restored to the v77 behavior that worked well on iPhone 16 Pro Max.
- v80 change: `src/App.tsx` keeps the v78 VPN probing improvements that made iPhone 6 work with more VPN servers.
- Do not use v79 for testing; it over-hid real SHEIN options/categories and did not fix the iPhone 6 SHEIN bottom bar.
- v79 iOS build remains archived only: `APP_VERSION = 2026.07.14-legacy-shein-bottom-v79`.
- v78 iOS build remains available: `APP_VERSION = 2026.07.14-old-iphone-vpn-v78`.
- v78 change: VPN geo probing is old-WKWebView-safe, returns on the first successful geo provider, and no longer waits for slow store image probes when geo already confirms a non-Syria VPN.
- v78 change: SHEIN header/bottom chrome collision zones are hidden more aggressively for old iPhones, especially iPhone 6 where SHEIN icons could cover otlobli's back button and SHEIN's bottom tab bar could appear above otlobli's nav.
- v77 iOS build remains available: `APP_VERSION = 2026.07.13-store-polish-v77`.
- v77 change: SHEIN ready WebViews are not forcibly closed/rechecked on normal app foreground, reducing store reload when returning from background.
- v77 change: SHEIN app-install banners and login/sign-in prompts are hidden in the injected store script.
- v77 change: Temu spin/wheel reward popup is hidden without re-enabling the broad Temu popup killer that caused white-screen/search issues.
- v76 iOS build remains available: `APP_VERSION = 2026.07.13-hidden-shein-check-v76`.
- v76 change: SHEIN now opens hidden first on iOS/native WebView, with only a tiny post-load probe. Otlobli no longer injects the large SHEIN script at documentStart before security verification.
- v76 change: SHEIN security/challenge pages remain hidden from the customer. If they do not turn into a normal page quickly, the app closes that WebView and shows VPN/server recovery advice instead of the black verification screen or app exit.
- v76 change: SHEIN is revealed only after a non-challenge page is detected, then the otlobli capture/nav script is injected and the WebView is shown.
- v75 change remains: SHEIN is rechecked when the app returns from background or launches on the home screen; stale native SHEIN WebViews are closed before being shown again.
- v75 change: SHEIN is rechecked when the app returns from background or launches on the home screen; stale native SHEIN WebViews are closed before being shown again. This targets the real-device issue where turning VPN off while SHEIN was the active store made the app open then exit.
- v75 change: VPN geo probing now uses four endpoints in parallel to reduce false "turn on VPN" results, such as Turkish VPN working in Safari but being rejected in-app.
- v75 change: non-blocked geo such as Turkey/USA is allowed even when the SHEIN image probe is flaky; store failures still show recovery/VPN advice instead of exiting.
- v74 change remains: VPN-off / unknown-geo startup is conservative. If probes cannot confirm a safe VPN while the device is online, the app shows the VPN-required state instead of opening the native store WebView.
- v74 change: VPN-off / unknown-geo startup is conservative. If probes cannot confirm a safe VPN while the device is online, the app shows the VPN-required state instead of opening the native store WebView.
- v74 change: unexpected SHEIN/Temu native WebView close on the home screen no longer auto-reopens into a crash loop; it pauses auto-open, refreshes VPN diagnosis, and shows store/VPN recovery UI.
- v74 change: iOS network/WebKit failures `-1001`, `-1004`, `-1005`, and `-1009` are treated as recoverable store failures even after a page was previously ready.
- v73 change remains: SHEIN/Temu store-open failures show clear VPN advice. If VPN is confirmed, the message says to change VPN server/app; if not confirmed, it says to turn VPN on.
- v73 change: SHEIN native bottom navigation is hidden more aggressively for older iPhones (e.g. iPhone 6) while preserving otlobli's own nav.
- v72 change remains: VPN gate is permissive for any non-Syria/unknown VPN instead of blocking on failed store/geo probes; SHEIN visible foreign shipping (e.g. Qatar) now attempts an automatic Saudi/USD reset before falling back to the manual guard.
- v71 change remains: iOS `pageLoadError` now carries WebKit details; SHEIN `-1005` / WebContent termination closes the stuck WebView and shows retry instead of leaving a white screen or exiting the app.
- v70 SHEIN-only change remains: if the native SHEIN WebView closes itself during/just after the security challenge, the app pauses automatic reopen and shows retry instead of entering an open/close loop.
- Emulator diagnostics: SHEIN opens after force-stop and after background/foreground; SHEIN emits many `pageLoadError` events even while working, so those must continue to be ignored during normal SHEIN browsing.
- v69 changes: Temu no longer reloads whole page after product back just because URL params are missing; SHEIN page-load errors are ignored during normal SHEIN opening; SHEIN challenge detection covers more routes/text; SHEIN writes Saudi shipping/currency keys even during challenge; store switching no longer clears all cookies automatically.
- SHEIN still needs real-device verification with VPN on Qatar: initial app open on SHEIN should not exit; if native WebView closes, app should stay open and show retry.
- SHEIN shipping still needs real-device verification; user reported VPN Qatar can still make SHEIN shipping show Qatar.
- Temu still needs real-device verification for product open/back stability and price visibility.
- Figma requires reauthentication before formal design review. Do not invent new designs outside Figma.
- The unavailable-item refund/wallet policy is not implemented yet. Suggested direction: instant wallet credit plus optional original-payment refund after several days, but wait for explicit approval before changing money logic.
- WhatsApp relink decision is still pending and untouched.

## Next Best Focus

1. Test `C:\Users\MOHAMMAD\Desktop\otlobli-v82.ipa` on iPhone 6 and iPhone 16 Pro Max. On iPhone 6 verify otlobli's own nav is visible, SHEIN's native bottom bar is covered, top SHEIN tabs are usable, and product back button icon is visible.
2. Test `C:\Users\MOHAMMAD\Desktop\otlobli-v70.apk` on Android / emulator and verify SHEIN does not exit the app.
3. Verify SHEIN after this exact flow: fresh open -> switch to Temu -> switch back to SHEIN -> security check if shown -> normal browsing.
4. Verify Temu region is Saudi and currency is USD.
4. Do not bypass SHEIN security verification; keep it clickable and avoid breaking it.

## Context Discipline

- Read `AI-HANDOFF.md` for implementation details.
- Read `CLAUDE.md` when using Claude Code.
- Avoid old history unless a task explicitly needs it. Git history contains the long v58-v66 details.
