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
- v85.4 IPA failed device testing; preloading `localcountry=SA` did not prevent Bahrain and that implementation is removed.
- Current candidate: v85.5 / `a064739` / `2026.07.14-v85.5-shein-native-sa-address-no-otp-test`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.5-shein-native-sa-no-otp-test.ipa`; SHA-256 `99F2E6311880607AC63E6B2AA5D50797317A29D5AEC1F26377AADBBEB14D2F8F`; run `29319264525`.
- v86-v88 are failed paths. v87 fixed nothing; v88 closed/crashed SHEIN on entry.
- Root cause: SHEIN product APIs use a signed `addressCookie`; URL parameters, VPN, and `localcountry` are not authoritative. Country-only selection also does not persist.
- v85.5 completes SHEIN's exact native Saudi address cascade. Android emulator validation converted a signed Qatar address to signed Saudi in about 9 seconds, persisted after reload with QA IP, and the product API returned Saudi Arabia.
- OTP screens are bypassed in this test candidate only and must be restored before production. Build, runtime script parse, diff check, native patch parse, Capacitor sync, and Android assembly pass.

## Next Step

Test signed Saudi persistence on iPhone 6 and iPhone 16 Pro Max, including reload, store switch, and VPN switch. Recheck cold entry/category taps separately. Do not claim iPhone success until both results are known. Add-to-Cart placement remains separate.

Do not touch Temu, payment, wallet, orders, coupons, or group checkout. Do not use broad CSS, viewport hacks, aggressive storage cleanup, or reload loops. Designs only from Figma.
