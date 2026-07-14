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
- Store code/config/styles match v85 byte-for-byte.
- Local rollback commits are not pushed; a push would automatically trigger the iOS workflow.
- v86-v88 are failed paths. v87 fixed nothing; v88 closed/crashed SHEIN on entry.
- Build, injected-script parse, and diff checks pass. No new IPA was built.

## Next Step

Collect the user's complete SHEIN issue inventory. Do not edit while receiving it. Group symptoms, choose one root cause, explain one narrow change, then test on iPhone 6 and iPhone 16 Pro Max.

Do not touch Temu, payment, wallet, orders, coupons, or group checkout. Do not use broad CSS, viewport hacks, aggressive storage cleanup, or reload loops. Designs only from Figma.
