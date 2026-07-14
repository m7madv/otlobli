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
- Active store code: restore `ce865a0`, exactly matching v85.8 / `585a28a` / `2026.07.14-v85.8-shein-cache-clean-entry-sa-status-no-otp-test`.
- Working reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8-shein-cache-clean-entry-sa-status-no-otp-test.ipa`; SHA-256 `689EE2D978269FB2ECB2EB4A3AA1B8436335ABC700C6B6C28B588508B636EF05`; run `29325121680`.
- v86-v88 are failed paths. v87 fixed nothing; v88 closed/crashed SHEIN on entry.
- Root cause: SHEIN product APIs use a signed `addressCookie`; URL parameters, VPN, and `localcountry` are not authoritative. Country-only selection also does not persist.
- v85.5 completes SHEIN's exact native Saudi address cascade. Android emulator validation converted a signed Qatar address to signed Saudi in about 9 seconds, persisted after reload with QA IP, and the product API returned Saudi Arabia.
- v85.6 removes the hidden/offscreen `FAKE_VISIBLE` first-open lifecycle, keeps one attached interactive WebView behind a bounded native cover during Saudi repair, reveals human verification, and narrowly locks verified customer shipping-region controls.
- v85.6 device result: first entry and Saudi correction worked, but the second entry could still be partial and untappable until a Temu round-trip.
- v85.7 removes app `hide/show` reuse for SHEIN, rebuilds on every app-screen return/background resume, requires actual DOM/content readiness, retries once with a fresh instance, and shows explicit preparation/Saudi status text.
- v85.7 failed on iPhone: the same second-entry partial/untappable state remained.
- v85.8 adds the one missing action from the user-proven Temu round-trip: clear only WebKit memory/disk cache before each SHEIN open, preserving cookies/localStorage and the signed Saudi address.
- v85.8 corrected device result: last build that accepted the user's VPN and opened SHEIN in the latest round; it still temporarily exposes raw SHEIN before processing completes.
- v85.9 preserves warm SHEIN cache/Service Workers on healthy entries, injects Otlobli at document start, keeps the existing preparation surface and nav until real product hydration, and clears native cache only for one bounded stuck-session recovery.
- v85.9-v85.11 device result: all rejected the user's working VPN and never entered successfully. Their code path is reverted.
- v85.10 keeps the native cover through all intermediate bodies/region repair and reveals only after 650ms of stable signed-Saudi product readiness with Otlobli nav attached.
- v85.10 device result: raw SHEIN was covered, but Otlobli nav disappeared during the later loading/reload phase.
- v85.11 hands off from the native cover to the existing in-page preparation layer only after Otlobli nav is attached, keeping the nav visible above blocked SHEIN content.
- OTP screens are bypassed in this test candidate only and must be restored before production. Build, runtime script parse, diff check, native patch parse, Capacitor sync, and Android assembly pass.

## Next Step

Use v85.8 as the working reference. Isolate the temporary raw-SHEIN transition next without changing its VPN/cache/script timing. Do not build another mixed candidate until that single change is reviewed.

Do not touch Temu, payment, wallet, orders, coupons, or group checkout. Do not use broad CSS, viewport hacks, aggressive storage cleanup, or reload loops. Designs only from Figma.
