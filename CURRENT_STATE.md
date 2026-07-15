# Otlobli Current State

Last updated: 2026-07-15

## Active Baseline

- Branch: `codex/customer-wallet-group-orders`.
- Stable tested reference: v85.8.5 / `a914d81`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.5-nav-cairo-font-match-no-otp-test.ipa`.
- Active test candidate: v85.8.6 / `4989f25`.
- Candidate IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.6.ipa`.
- Candidate SHA-256: `F718B401A4FEB16991BC2C17DEB8648C19AA151C390FF4F80005F9B3B1EEBF1E`.
- iOS build run: `29402834663` (success).
- `APP_VERSION = 2026.07.15-v85.8.6-stable-nav-slow-ios-color-no-otp-test`.
- Real-device acceptance is pending; do not claim the SHEIN issues are fixed yet.

## v85.8.6 Scope

- Keeps v85.8.5 store/VPN/Saudi-address behavior as the base.
- Defers first iOS WebView presentation until its first live page while React's nav remains mounted.
- Uses bundled Cairo in both React and the injected SHEIN nav; no Google Fonts timing shift.
- Shows the native loading cover for every iOS main-frame navigation while leaving Otlobli's nav uncovered.
- Gives slow devices 35 seconds for SHEIN readiness instead of falsely blaming the VPN at 13 seconds.
- Passive security checks remain covered briefly; genuinely interactive verification is revealed after a bounded wait and is never bypassed.
- Hides only a verified SHEIN bottom tab bar. The old generic fixed-bottom hiding path is no longer called.
- Raises only an exact cookie-consent action that would overlap Otlobli's nav.
- Retries only SHEIN's exact feed-error retry action, at most four times, without reload or `setUrl` loops.
- Improves round/HOT swatch capture by ranking nested images and CSS backgrounds while rejecting small badge layers.
- Runtime Service Worker/cache cleanup runs once per SHEIN WebView session, not on every product/back navigation.

## Failed Paths / Guardrails

- v86-v88 are failed paths. v87 fixed none of the reported issues; v88 closed/crashed SHEIN on entry.
- v85.9-v85.11 rejected the user's working VPN. Do not reuse their full document-start capture path.
- Do not reintroduce hidden/offscreen `FAKE_VISIBLE`, broad CSS, viewport-width hacks, wide storage resets, or reload loops.
- Do not change payment, wallet, completed orders, Temu, coupons, or group checkout during this SHEIN pass.
- Designs come only from Figma.
- `TEST_ONLY_AUTH_BYPASS = true` only for rapid device testing; restore OTP before production.

## Acceptance Test

Test on iPhone 6 and iPhone 16 Pro Max:

1. Otlobli nav is visible from launch and never changes font/size.
2. No raw SHEIN tab bar appears during initial load, product open, back, or app-tab return.
3. Turkey/Germany VPN is not rejected merely because iPhone 6 prepares slowly.
4. SHEIN feed becomes usable without repeated manual retry taps.
5. Cookie consent is tappable above the nav and does not open Orders.
6. Product from cart stays covered until ready; back is smooth.
7. Round/HOT selected color produces the actual color thumbnail in cart.
8. Saudi shipping remains authoritative.

## Validation

- Clean `patch-package` reinstall passed; tracked relay keys remain placeholders.
- `npm run build` passed.
- Runtime syntax parse of both injected scripts passed.
- `git diff --check` passed.
- Xcode unsigned build and packaging passed in run `29402834663`.
- Embedded v85.8.6 marker and desktop IPA SHA-256 were verified.

