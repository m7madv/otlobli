# Session Summary

Last updated: 2026-07-13

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

- v66 feature commit: `f7b4456`
- v66 docs commit: `c733c72`
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
- No new Android build was requested for v66.

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

## Guidance For Claude New Account

- Same computer does not guarantee the same authenticated connectors.
- Check available skills/tools before relying on them.
- Figma may require reconnect/reauth.
- Use browser/WebView/testing tools if available.
- Keep responses and exploration compact; do not read old docs unless the task requires it.
