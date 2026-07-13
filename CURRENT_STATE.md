# Otlobli Current State

Last updated: 2026-07-13

This is the short source of truth for the app work. Keep it compact so Codex/Claude do not burn context on old history.

## Active Repo

- Path: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`
- Branch: `codex/customer-wallet-group-orders`
- Latest pushed docs commit before this cleanup: `c733c72`
- Latest feature commit: `f7b4456` (`feat: ship v66 shared orders and store recovery`)

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
- v66 iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v66.ipa`
- v66 IPA SHA-256: `6724eb9d147e780aac7d868853d341cb3a416e2d7c856300f6acc3db6372e6b1`
- No new Android build was requested for v66.

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

- Local v68 fix is implemented but not deployed or built as IPA yet: `APP_VERSION = 2026.07.13-shein-temu-stability-v68`.
- v68 changes: Temu starts on Saudi `/sa/` with USD and no longer redirects product URLs just because currency params are absent; Temu WebView writes exact Saudi/USD session keys; Temu hide filters skip any price-looking elements; SHEIN no longer clears cookies/cache on every store switch; SHEIN page-load errors no longer close the WebView after the page/challenge is already active; wallet balance RPC errors no longer display a false zero.
- SHEIN still needs real-device verification. Latest user report: SHEIN can open, but switching Temu -> SHEIN may intermittently flicker the bottom bar and exit.
- Temu still needs real-device verification for Saudi/USD display, product back/forward stability, price visibility while scrolling, and VPN/load-failure cases.
- Figma requires reauthentication before formal design review. Do not invent new designs outside Figma.
- The unavailable-item refund/wallet policy is not implemented yet. Suggested direction: instant wallet credit plus optional original-payment refund after several days, but wait for explicit approval before changing money logic.
- WhatsApp relink decision is still pending and untouched.

## Next Best Focus

1. Build/install/test the local v68 build on a real device.
2. Verify SHEIN after this exact flow: fresh open -> switch to Temu -> switch back to SHEIN -> security check if shown -> normal browsing.
3. Verify Temu region is Saudi and currency is USD.
4. Do not bypass SHEIN security verification; keep it clickable and avoid breaking it.

## Context Discipline

- Read `AI-HANDOFF.md` for implementation details.
- Read `CLAUDE.md` when using Claude Code.
- Avoid old history unless a task explicitly needs it. Git history contains the long v58-v66 details.
