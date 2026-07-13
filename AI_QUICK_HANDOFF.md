# Otlobli Quick Handoff

Minimal context for Codex/Claude.

- Repo: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`
- Branch: `codex/customer-wallet-group-orders`
- Customer: `https://talabieh.vercel.app`
- Admin: `https://talabieh-admin.vercel.app`
- Latest feature commit: `f7b4456`
- Latest docs commit before cleanup: `c733c72`
- iPhone artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v68.ipa`
- v68 IPA SHA-256: `9C4CCBE67057D3A924E27DDE93772C180073230025689D4F52299ECADBE74937`

Before edits:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

Read `CURRENT_STATE.md` and `AI-HANDOFF.md`. Use git history only when needed.

## Open Priority

v68 fix is pushed and the iPhone IPA is built.

- Temu is forced to `/sa/` with USD without reloading product URLs only because currency params are absent.
- Temu writes exact Saudi/USD session keys and protects price-looking elements from hide filters.
- SHEIN challenge pages keep otlobli bottom nav.
- SHEIN challenge/ready mode ignores load errors that previously closed the WebView.
- Switching back to SHEIN no longer clears cookies/cache automatically.
- Wallet balance RPC errors no longer show false zero.

Test on a real device: SHEIN -> Temu -> SHEIN, Temu product open/back, Temu USD price visibility, wallet balance. Do not bypass SHEIN security verification.

## Already Done In v66

- Empty-cart group invite linking.
- Shared order visibility and owner-scoped item issues.
- Qadmous recipient selection from group members.
- My Orders issue resolution with options/text/photo.
- Admin inline order selection and dynamic issue options/photo request.
- VPN/load-failure fallback improvements.
- Temu search shell stabilization.

## Hard Rules

- Figma only for design.
- Do not change money logic unless explicitly asked.
- Treat existing git changes as user/other-AI work.
