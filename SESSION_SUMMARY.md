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
- Current test: v85.4 / `6a29b77`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.4-shein-sa-no-otp-test.ipa`.
- SHA-256: `30290F292574363CBC9594C765D6FE88C86A1E35869F17F85742636556FF2FFD`; run `29304645602`.
- v86-v88 are failed paths. v87 fixed nothing; v88 closed/crashed SHEIN on entry.
- v85.2/v85.3 testing proved first-session country selection persists and the native picker automation did not reliably correct Bahrain. v85.4 now writes only `localcountry=SA` to the native WK cookie store before SHEIN's first request. OTP screens are bypassed in this test IPA only and must be restored before production. Build, runtime script parse, diff check, native patch checks, and iOS workflow pass.

## Next Step

Delete the old app and test v85.4 on iPhone 6 and iPhone 16 Pro Max, first under a non-Saudi VPN, then after reinstall under a Saudi VPN, and finally after changing VPNs without reinstalling. Recheck cold entry/category taps separately. Do not claim success until both results are known. Add-to-Cart placement remains separate.

Do not touch Temu, payment, wallet, orders, coupons, or group checkout. Do not use broad CSS, viewport hacks, aggressive storage cleanup, or reload loops. Designs only from Figma.
