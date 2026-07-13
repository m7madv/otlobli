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
- iPhone artifact exists at `C:\Users\MOHAMMAD\Desktop\otlobli-v68.ipa`
- IPA SHA-256: `9C4CCBE67057D3A924E27DDE93772C180073230025689D4F52299ECADBE74937`
- GitHub Actions run: `29267376196`
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

- v68 fix is pushed and the iPhone IPA is built.
- v68 changes: Temu `/sa/` + USD without reloading product URLs, exact Temu Saudi/USD session keys, Temu price-protection guards, SHEIN challenge keeps otlobli nav, SHEIN no longer clears cookies/cache on every switch, SHEIN `pageLoadError` no longer closes an already-active page/challenge, wallet RPC errors no longer show false zero.
- SHEIN still needs real-device verification for the flow: SHEIN -> Temu -> SHEIN, especially intermittent bottom-nav flicker/exit.
- Temu needs real-device verification for Saudi/USD display, product/back stability, price visibility while scrolling, and VPN/load-failure cases.
- Figma needs reauthentication before design review. Do not design independently.
- Unavailable-item refund policy is undecided and not implemented.
- WhatsApp relink decision is pending and untouched.

## Cleanup Done On 2026-07-13

- Current handoff docs were shortened to reduce Codex/Claude token spend.
- Old long context was removed from active first-read docs. Git history keeps the details if needed.
- `CLAUDE.md` was rewritten for a new Claude Code account and includes skills/authentication guidance.
- Unused root debug artifacts and old local build output were removed from the repo root.

## Validation After v68 Local Fix

- `npm run build` passed.
- `new Function(SHEIN_CAPTURE_SCRIPT)` parse check passed.
- `git diff --check` passed.

## Guidance For Claude New Account

- Same computer does not guarantee the same authenticated connectors.
- Check available skills/tools before relying on them.
- Figma may require reconnect/reauth.
- Use browser/WebView/testing tools if available.
- Keep responses and exploration compact; do not read old docs unless the task requires it.
