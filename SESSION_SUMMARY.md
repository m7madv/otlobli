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
- Current test: v85.2 / `294dd78`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.2-shein-saudi-auth-test.ipa`.
- SHA-256: `CC1751C86EDD2BD98C92E77AA200E0759678AE6F276A3CDF46D3F032E6977A5B`; run `29302214134`.
- v86-v88 are failed paths. v87 fixed nothing; v88 closed/crashed SHEIN on entry.
- v85.2 keeps auth forms interactive, removes destructive region reset/reload, tightens shipping-region detection, and seeds the official `localcountry=SA` signal. Build, runtime script parse, and diff checks pass.

## Next Step

Test cold entry, category taps, auth/Continue, and product shipping in v85.2 on iPhone 6 and iPhone 16 Pro Max. Do not claim success until both results are known. Add-to-Cart placement remains separate.

Do not touch Temu, payment, wallet, orders, coupons, or group checkout. Do not use broad CSS, viewport hacks, aggressive storage cleanup, or reload loops. Designs only from Figma.
