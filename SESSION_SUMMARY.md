# Session Summary

Last updated: 2026-07-14

## Resume Checklist

1. Open `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
2. Read `CURRENT_STATE.md`, `AI-HANDOFF.md`, and `AGENTS.md`.
3. Run `git status --short`, branch check, and recent log.

## Current State

- Branch: `codex/customer-wallet-group-orders`.
- Stable store baseline: v85 / `2f24954`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`.
- Current test: v85.1 / `8282091`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.1-shein-category-touch-test.ipa`.
- v86-v88 are failed paths. v87 fixed nothing; v88 closed/crashed SHEIN on entry.
- v85.1 limits menu/header blocking to icon-only controls and removes broad category restyling. Build, runtime script parse, and diff checks pass.

## Next Step

Test category taps in v85.1 on iPhone 6 and iPhone 16 Pro Max. Do not claim the issue fixed until both results are known. Region/feed/button issues remain separate and unchanged.

Do not touch Temu, payment, wallet, orders, coupons, or group checkout. Do not use broad CSS, viewport hacks, aggressive storage cleanup, or reload loops. Designs only from Figma.
