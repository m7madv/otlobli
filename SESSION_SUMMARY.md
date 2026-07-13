# Session Summary

Last updated: 2026-07-14

This file is the copyable short summary for a fresh AI session. Keep it brief.

## Current App State

Project path:

```text
C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA
```

Active branch:

```text
codex/customer-wallet-group-orders
```

Before changing anything:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

Read:

1. `CURRENT_STATE.md`
2. `AI-HANDOFF.md`
3. `AGENTS.md`
4. `CLAUDE.md` if using Claude Code

## Latest Stable Release

- Latest feature commit: `2f24954` (`fix: v85 polish iOS nav and selection behavior`)
- Customer deployed to `https://talabieh.vercel.app`
- Admin deployed to `https://talabieh-admin.vercel.app`
- Supabase migration `20260712033000_shared_order_ownership.sql` applied.
- Supabase `admin-orders` deployed.
- iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v69.ipa`
- IPA SHA-256: `B4EE4E92D2F7AA383309120AE514515C37055576EFCA67F8E92A2B20900E04A0`
- GitHub Actions run: `29268560648`
- v70 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v70.ipa`
- v70 IPA SHA-256: `C9A3F5BA4146E1FF1F4F88E289F64EE13CBDA6AF55B8361F06723BEFF52453DC`
- v70 GitHub Actions run: `29273940532`
- Android debug artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v70.apk`
- APK SHA-256: `8D1AA3F46D3CA3FE3F83BE881A7FBB487EF0D54DEE35E218910C35C5F32A731A`
- v71 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v71.ipa`
- v71 IPA SHA-256: `6A68B89F6CFBD9DF40D94795693A61A0AFE24A2EA9CCC91272D0E1B2ED19E6A6`
- v71 GitHub Actions run: `29277541189`
- v72 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v72.ipa`
- v72 IPA SHA-256: `4D57D8D98E12F52743B905C15D5469E850D8FE2EF19EB2703F60439A40D12933`
- v72 GitHub Actions run: `29278990511`
- v73 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v73.ipa`
- v73 IPA SHA-256: `18C022FB0D207BB87E496DF67FDA4D8BC42F942922597B4C36ECE0B4D547D5F3`
- v73 GitHub Actions run: `29279855967`
- v74 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v74.ipa`
- v74 IPA SHA-256: `68EC10E14E8F1D0E9D40009B577BD6B5D68AFAB451DA1FEC5D08D6B709030E06`
- v74 GitHub Actions run: `29280481341`
- v75 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v75.ipa`
- v75 IPA SHA-256: `6D9FFE5F8B99611A73DB020D9B24F144F120B8048B2C2AB677297EA82B0F5DE1`
- v75 GitHub Actions run: `29281360380`
- v76 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v76.ipa`
- v76 IPA SHA-256: `2F9581087DC884F7A432CE41DDB868C142885C68E6566EFC4F9AEAA732D1995C`
- v76 GitHub Actions run: `29282623302`
- v77 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v77.ipa`
- v77 IPA SHA-256: `0EF63774AC0D7753C3DA088D1026BC63EF6228578A38006040C4B62BC907BDA2`
- v77 GitHub Actions run: `29283834227`
- v78 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v78.ipa`
- v78 IPA SHA-256: `8EF9E6A4ABFF327C0E34A2AB7DD905EA9059BB35C346FC393C8EDAC3F053FD2F`
- v78 GitHub Actions run: `29285536824`
- v79 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v79.ipa`
- v79 IPA SHA-256: `3A3A6D705317D57EB9C4AC88019884B3DBCB81366930878F9D45672B18243ADF`
- v79 GitHub Actions run: `29286393316`
- v80 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v80.ipa`
- v80 IPA SHA-256: `DBED4F281A7A24597668B25EE1CB31F9A01EE6459696601A9A3D13BA94F65070`
- v80 GitHub Actions run: `29287735934`
- v81 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v81.ipa`
- v81 IPA SHA-256: `F4DC6785BD3811FB21ACC54FFC6224622DEE4EA3FD08377B3A656EBF35128760`
- v81 GitHub Actions run: `29288517907`
- v82 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v82.ipa`
- v82 IPA SHA-256: `62F1D8A2EE9A68459FD5DBE5E417F30D331EFD187DDFE0A2C9FF115F4A6984A1`
- v82 GitHub Actions run: `29290104486`
- v83 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v83.ipa`
- v83 IPA SHA-256: `8504DF389BAF1303C0F5BAAC89F1BDFCA8796C746848E9ED240FA56F48C3DB9C`
- v83 GitHub Actions run: `29291593555`
- v84 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v84.ipa`
- v84 IPA SHA-256: `8065DF95F2F44272C0D74BEB6A389EA86B9D3947A64014486AF21240739AA872`
- v84 GitHub Actions run: `29292808196`
- v85 iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`
- v85 IPA SHA-256: `F4524E816E6243A039BD52D34E7A9AB59E3C5597DBF0515862BA5F9461B90ED4`
- v85 GitHub Actions run: `29293816845`
- No new Android build was requested for v85.

## v66 Implemented

- Shared-cart invite link works even when recipient cart is empty.
- Group-cart entry stays visible in an empty cart.
- Shared order shows to group members.
- Items are grouped/scoped by owner.
- Product issue notification goes only to the product owner.
- Qadmous pickup recipient can be selected from group members.
- My Orders can resolve option/text/photo issues without WhatsApp.
- Admin can add issue options with separate dynamic fields.
- Admin can request a customer photo for a product issue.
- Admin order selection is inline; selected order details appear below.
- VPN/load failure can return to VPN check instead of blank white screen.
- Temu search shell was stabilized.
- SHEIN security/challenge URLs are no longer rewritten by the Saudi URL guard.

## Still Open

- v85 SHEIN/iOS polish fix is pushed and built.
- v85 change: keeps v84 bottom-nav hit-test hiding, aligns the injected store nav with the real app nav, disables text selection/callouts while preserving inputs, lowers the SHEIN back button on compact iPhones, and restores/whitelists SHEIN top category tabs.
- v84 SHEIN bottom hit-test fix is pushed and built.
- v84 change: keeps v83/v80 layout, adds old-WebKit-safe fallback CSS for otlobli's nav, and hides SHEIN's native bottom bar by bottom-of-screen hit-testing/text detection instead of changing viewport width.
- v84 avoids the failed v82 approach: no `width=430`, no white shield, no broad hiding of real SHEIN sections.
- v83 clean rollback is available as fallback.
- v83 change: reverted the unstable v81/v82 SHEIN script changes and returned to the v80/v77-style SHEIN UI behavior while keeping v78 VPN logic in `src/App.tsx`.
- Do not use v82 for testing; user reported horizontal page movement, invisible otlobli nav, missing top SHEIN tabs, and messy iPhone 6 layout.
- v81/v82 CSS should not be continued without fresh diagnostics; v81 did not solve the iPhone 6 SHEIN bottom bar and v82 made the layout worse.
- v82 legacy iPhone SHEIN nav fix is archived only.
- v82 change: on compact legacy iPhones, SHEIN viewport is widened to 430, otlobli nav uses old-WebKit-safe CSS without CSS `min()`/`max()`, a bottom shield covers SHEIN's native bar, and back button uses visible text glyph `›`.
- v81 iPhone 6 SHEIN chrome fix is pushed and built.
- v81 change: keeps v80 base, hides SHEIN's native bottom tab bar by its actual nav text/links, and stabilizes top SHEIN hero tabs only on narrow screens.
- v80 v77-UI/v78-VPN combination is pushed and built.
- v80 change: SHEIN/UI script is restored to v77 behavior that worked well on iPhone 16 Pro Max, while keeping v78 VPN probing behavior for iPhone 6.
- v79 should not be used for testing; user reported it over-hid SHEIN options/categories and still did not solve the iPhone 6 bottom bar.
- v79 legacy SHEIN bottom bar hider is archived only.
- v78 old iPhone compatibility is pushed and built.
- v78 change: VPN geo probing is safer/faster on old WKWebView and SHEIN chrome collision zones are hidden more aggressively for iPhone 6 back-button/bottom-nav overlap.
- v77 store popup/resume polish is pushed and built.
- v77 change: SHEIN ready WebViews are not forcibly closed/rechecked on normal app foreground. SHEIN app-install/login prompts are hidden. Temu spin/wheel reward popup is hidden.
- v76 hidden SHEIN security check is pushed and built.
- v76 change: SHEIN opens hidden first with a tiny post-load probe. The full otlobli script is injected only after a normal non-challenge SHEIN page is detected. Security/challenge pages are not shown to the customer; they become VPN/server recovery advice instead.
- v75 SHEIN resume VPN recheck is pushed and built.
- v75 change: when returning to the app on SHEIN, stale native WebViews are closed and the VPN gate runs again before showing SHEIN. Geo probing uses four endpoints to avoid false no-VPN results, e.g. Turkish VPN working in Safari but rejected in-app. Non-blocked geo can open even if SHEIN image probes are flaky.
- v74 VPN-off crash guard is pushed and built.
- v74 change: when VPN/geo cannot be confirmed and the device is online, the app shows the VPN-required state instead of opening the native store WebView. Unexpected native WebView close on home shows recovery/VPN UI instead of auto-reopening into a crash loop. iOS `-1001`, `-1004`, `-1005`, and `-1009` are handled as recoverable store failures.
- v73 store-failure VPN advice is pushed and built.
- v73 change: SHEIN/Temu failures now show "غيّر سيرفر الـ VPN" when VPN is confirmed, or "شغّل الـ VPN أولاً" when it is not confirmed; timed-out loading uses the same advice. SHEIN native bottom nav is hidden more aggressively for iPhone 6.
- v72 VPN permissive gate is pushed and built.
- v72 change: non-Syria/unknown VPNs are allowed through even if store/geo probes fail; SHEIN auto-fixes visible foreign shipping regions back to Saudi/USD before falling back to manual guard.
- v71 iOS WebKit guard is pushed and built.
- v71 change: iOS `pageLoadError` now includes WebKit details; SHEIN `-1005` / WebContent termination closes the stuck native WebView and shows retry instead of a white screen/app exit.
- v70 Android debug fix is local, built, and installed on the emulator.
- v70 change: SHEIN native WebView close-loop guard. If SHEIN closes during/after security challenge, the app pauses auto-reopen and shows retry instead of repeatedly opening/closing or exiting.
- Emulator diagnostics: SHEIN opens after force-stop and after background/foreground. SHEIN emits repeated `pageLoadError` events while still working, so they are ignored for normal SHEIN browsing.
- v70 iPhone unsigned IPA has been created via GitHub Actions and copied to the desktop.
- v69 fix is pushed and the iPhone IPA is built.
- v69 changes: Temu no longer reloads whole page after product back due missing params; SHEIN normal opening ignores `pageLoadError`; SHEIN challenge detection covers more routes/text; Saudi shipping/currency keys are written even during challenge; store switch no longer clears all cookies automatically.
- SHEIN still needs real-device verification for fresh open on SHEIN with VPN Qatar; it should not exit and shipping should stay Saudi.
- User reported SHEIN shipping can still follow VPN Qatar; Saudi shipping lock still needs real-device work.
- Temu needs real-device verification for product open/back stability and price visibility while scrolling.
- Figma needs reauthentication before design review. Do not design independently.
- Unavailable-item refund policy is undecided and not implemented.
- WhatsApp relink decision is pending and untouched.

## Cleanup Done On 2026-07-13

- Current handoff docs were shortened to reduce Codex/Claude token spend.
- Old long context was removed from active first-read docs. Git history keeps the details if needed.
- `CLAUDE.md` was rewritten for a new Claude Code account and includes skills/authentication guidance.
- Unused root debug artifacts and old local build output were removed from the repo root.

## Validation After v70 Android Fix

- `npm run build` passed.
- `git diff --check` passed.
- `npx cap sync android` passed.
- `android\gradlew.bat -p android :app:assembleDebug` passed.
- `adb install -r android\app\build\outputs\apk\debug\app-debug.apk` passed.
- Emulator force-stop/open/background/return test passed: SHEIN stayed visible; no app crash.
- GitHub iOS unsigned build run `29273940532` passed and produced `otlobli-v70.ipa`.

## Validation After v71 iOS WebKit Guard

- `npm run build` passed.
- Patch-package patch applies cleanly to a clean `@capgo/capacitor-inappbrowser@8.6.25` package.
- GitHub iOS unsigned build run `29277541189` passed and produced `otlobli-v71.ipa`.

## Validation After v72 VPN Permissive Gate

- `npm run build` passed.
- GitHub iOS unsigned build run `29278990511` passed and produced `otlobli-v72.ipa`.

## Validation After v73 Store Failure VPN Advice

- `npm run build` passed.
- GitHub iOS unsigned build run `29279855967` passed and produced `otlobli-v73.ipa`.

## Validation After v74 VPN-Off Crash Guard

- `npm run build` passed.
- GitHub iOS unsigned build run `29280481341` passed and produced `otlobli-v74.ipa`.

## Validation After v75 SHEIN Resume VPN Recheck

- `npm run build` passed.
- GitHub iOS unsigned build run `29281360380` passed and produced `otlobli-v75.ipa`.

## Validation After v76 Hidden SHEIN Security Check

- `npm run build` passed.
- GitHub iOS unsigned build run `29282623302` passed and produced `otlobli-v76.ipa`.

## Validation After v77 Store Popup/Resume Polish

- `npm run build` passed.
- `git diff --check` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29283834227` passed and produced `otlobli-v77.ipa`.

## Validation After v78 Old iPhone Compatibility

- `npm run build` passed.
- `git diff --check` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29285536824` passed and produced `otlobli-v78.ipa`.

## Validation After v79 Legacy SHEIN Bottom Bar Hider

- `npm run build` passed.
- `git diff --check` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29286393316` passed and produced `otlobli-v79.ipa`.

## Validation After v80 v77-UI/v78-VPN Combination

- `npm run build` passed.
- `git diff --check` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29287735934` passed and produced `otlobli-v80.ipa`.

## Validation After v81 iPhone 6 SHEIN Chrome Fix

- `npm run build` passed.
- `git diff --check` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29288517907` passed and produced `otlobli-v81.ipa`.

## Validation After v82 Legacy iPhone SHEIN Nav Fix

- `npm run build` passed.
- `git diff --check` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29290104486` passed and produced `otlobli-v82.ipa`.

## Validation After v83 Clean Rollback

- `npm run build` passed.
- `git diff --check` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29291593555` passed and produced `otlobli-v83.ipa`.

## Validation After v84 SHEIN Bottom Hit-Test Fix

- `npm run build` passed.
- `git diff --check` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29292808196` passed and produced `otlobli-v84.ipa`.

## Validation After v85 iOS Nav/Text Polish

- `npm run build` passed.
- `git diff --check` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- GitHub iOS unsigned build run `29293816845` passed and produced `otlobli-v85.ipa`.

## Guidance For Claude New Account

- Same computer does not guarantee the same authenticated connectors.
- Check available skills/tools before relying on them.
- Figma may require reconnect/reauth.
- Use browser/WebView/testing tools if available.
- Keep responses and exploration compact; do not read old docs unless the task requires it.
