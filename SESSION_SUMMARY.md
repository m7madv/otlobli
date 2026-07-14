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
- Current candidate: v85.9 / `86f15be` / `2026.07.14-v85.9-shein-progressive-entry-warm-cache-no-otp-test`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.9-shein-progressive-entry-warm-cache-no-otp-test.ipa`; SHA-256 `F8F61473E4B6FD8D08F2D9667408070B59E6C882F59F3E95FC80E98EBCC53A59`; run `29326728706`.
- v86-v88 are failed paths. v87 fixed nothing; v88 closed/crashed SHEIN on entry.
- Root cause: SHEIN product APIs use a signed `addressCookie`; URL parameters, VPN, and `localcountry` are not authoritative. Country-only selection also does not persist.
- v85.5 completes SHEIN's exact native Saudi address cascade. Android emulator validation converted a signed Qatar address to signed Saudi in about 9 seconds, persisted after reload with QA IP, and the product API returned Saudi Arabia.
- v85.6 removes the hidden/offscreen `FAKE_VISIBLE` first-open lifecycle, keeps one attached interactive WebView behind a bounded native cover during Saudi repair, reveals human verification, and narrowly locks verified customer shipping-region controls.
- v85.6 device result: first entry and Saudi correction worked, but the second entry could still be partial and untappable until a Temu round-trip.
- v85.7 removes app `hide/show` reuse for SHEIN, rebuilds on every app-screen return/background resume, requires actual DOM/content readiness, retries once with a fresh instance, and shows explicit preparation/Saudi status text.
- v85.7 failed on iPhone: the same second-entry partial/untappable state remained.
- v85.8 adds the one missing action from the user-proven Temu round-trip: clear only WebKit memory/disk cache before each SHEIN open, preserving cookies/localStorage and the signed Saudi address.
- v85.8 device result: normal on iPhone 16 Pro Max, but failed on iPhone 6 with raw SHEIN/no Otlobli bar, missing products, and a false VPN-server instruction.
- v85.9 preserves warm SHEIN cache/Service Workers on healthy entries, injects Otlobli at document start, keeps the existing preparation surface and nav until real product hydration, and clears native cache only for one bounded stuck-session recovery.
- OTP screens are bypassed in this test candidate only and must be restored before production. Build, runtime script parse, diff check, native patch parse, Capacitor sync, and Android assembly pass.

## Next Step

Test v85.9 repeated entry and background/resume on iPhone 6 and iPhone 16 Pro Max without the Temu round trip. Verify the preparation surface/bar never exposes raw SHEIN, then verify taps, region lock, and Saudi persistence. Do not claim success until both results are known. Add-to-Cart placement remains separate.

Do not touch Temu, payment, wallet, orders, coupons, or group checkout. Do not use broad CSS, viewport hacks, aggressive storage cleanup, or reload loops. Designs only from Figma.
