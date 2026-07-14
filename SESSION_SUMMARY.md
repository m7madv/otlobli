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
- Current test: v85.3 / `6f80823`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.3-shein-saudi-picker-test.ipa`.
- SHA-256: `BEDD2A0F6E42C7547BE43A5B3C2373E099171B98CCFB8679CE596577973AB356`; run `29303217368`.
- v86-v88 are failed paths. v87 fixed nothing; v88 closed/crashed SHEIN on entry.
- v85.2 testing proved the WebView persists Bahrain across VPN changes; VPN/seed state alone is insufficient. v85.3 uses SHEIN's native shipping picker and exact Saudi Arabia row, while bypassing the old country/region click guard only for those verified controls. Build, runtime script parse, signal tests, diff check, and iOS workflow pass.

## Next Step

Test product shipping in v85.3 on iPhone 6 and iPhone 16 Pro Max, especially US VPN -> Saudi VPN without reinstall. Recheck cold entry/category taps and auth/Continue separately. Do not claim success until both results are known. Add-to-Cart placement remains separate.

Do not touch Temu, payment, wallet, orders, coupons, or group checkout. Do not use broad CSS, viewport hacks, aggressive storage cleanup, or reload loops. Designs only from Figma.
