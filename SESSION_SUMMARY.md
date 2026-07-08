# SESSION_SUMMARY.md

Copy this into a new AI chat before continuing work.

## Start here

Project path:

```text
C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA
```

Active branch:

```text
codex/customer-wallet-group-orders
```

Before editing, read:

1. `AGENTS.md`
2. `CURRENT_STATE.md`
3. `AI-HANDOFF.md`
4. `CLAUDE.md` if using Claude Code

Then run:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

## Critical rule

Do not assume `main` is latest. Do not restore old code from another branch unless manually comparing and cherry-picking only the needed pieces.

Existing staged/untracked files may be work from another AI or the user. Do not revert them.

## Current fragile areas

- SHEIN mobile browsing:
  - must stay on `m.shein.com/ar`
  - country Saudi Arabia
  - currency USD
  - language Arabic
  - `site_uid=pwar`
  - no custom User-Agent spoofing
  - do not broadly overwrite SHEIN storage keys
  - do not treat random country names inside product titles/descriptions as wrong region
- Temu WebView:
  - bottom otlobli nav must remain fixed and visible
  - search must remain visible
  - hide only confirmed Temu account/cart/login distractions, not product content
- Group cart:
  - invite links must work from WhatsApp
  - recipient should confirm linking before joining
  - carts should sync quickly and unlink after order
- Admin:
  - do not auto-open the first order
  - mobile layout is important
  - coupons, drivers, product issues, wallet/order actions are current features
- Payments/wallet:
  - do not change payment/wallet logic unless explicitly requested

## Last confirmed Codex state

- Android APK was built and installed on emulator.
- SHEIN home opened Arabic/Saudi/USD.
- SHEIN product page opened successfully after fixing the Saudi guard.
- AI guardrail files were added so Claude/Codex/other models read current state before editing.
- Dangerous uncommitted Claude WIP that reverted SHEIN to older `/jo` behavior and removed group/wallet schema was backed up to Temp and removed from the working tree.
- Customer/admin builds passed after cleanup.
- Latest iOS unsigned GitHub workflow succeeded:
  - `https://github.com/m7madv/otlobli/actions/runs/28971384749`
- Previous iOS unsigned workflow succeeded:
  - `https://github.com/m7madv/otlobli/actions/runs/28935943927`
- Supabase customer reset helper exists:
  - `supabase/RESET_CUSTOMER_DATA.sql`
  - Not executed automatically because local env files do not contain a usable Supabase service role/database password.

## Handoff habit

At the end of every long session, update:

- `CURRENT_STATE.md`
- `AI-HANDOFF.md`
- `SESSION_SUMMARY.md`

Then give the user a short Arabic summary with:

- what changed
- what was tested
- what was pushed/built
- what the next AI must read first
