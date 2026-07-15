# Otlobli Current State

Last updated: 2026-07-15

## Active Baseline

- Branch: `codex/customer-wallet-group-orders`.
- Stable tested reference: v85.8.5 / `a914d81`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.5-nav-cairo-font-match-no-otp-test.ipa`.
- Active local candidate: v85.8.17 (event-driven SHEIN runtime; device acceptance pending).
- Last built IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.16.ipa`.
- Last built code: `ccf08aa`; run `29432951413`; SHA-256 `F25EEBAAB50991CDAEFE373202EEE5A7BABF3F889ACEE9B09D2D0F6E232C370D`.
- `APP_VERSION = 2026.07.15-v85.8.17-shein-event-driven-runtime-no-otp-test`.
- Do not claim SHEIN is fixed before testing iPhone 6 and iPhone 16 Pro Max.

## Confirmed Runtime Diagnosis

- The current SHEIN path had accumulated a full `tick()` every 300ms, header/listing scans every 120ms, nav maintenance every 120ms, a body-text security scan every second, and a whole-document MutationObserver that scheduled more ticks.
- Cookie/bootstrap code also scanned every 250ms for up to 45 seconds.
- On old WKWebView this creates sustained layout/text/DOM work while SHEIN is hydrating and decoding images. That matches the reported slowness, delayed blockers, and painted-but-unresponsive behavior.
- Reinjecting the full script into the same live SPA document could duplicate observers and listeners.

## v85.8.17 Changes

- Removed all permanent SHEIN full-page/header/security/nav polling.
- SHEIN maintenance now runs in finite, replaceable bursts only on initial load, SPA navigation, customer interaction, foreground return, reconnect, or an explicit reinjection request.
- The SHEIN MutationObserver repairs only a missing Otlobli nav; ordinary product mutations never start a full-page scan.
- Duplicate full-script injection into one live document is rejected and converted to one bounded maintenance request.
- Saudi address repair has its own state-bound loop. It runs only while the native repair cover is active and stops on signed Saudi success, timeout, or cooldown.
- Exact cookie auto-accept and early nav protection use fixed hydration checkpoints plus bounded mutation wakeups instead of 250ms polling.
- Temu, payment, wallet, orders, and cart logic were not changed.
- No broad CSS, viewport hack, storage reset, reload loop, `hidden + FAKE_VISIBLE`, or full document-start SHEIN capture was added.

## Guardrails

- v86-v88 are failed paths. v87 fixed none of the reported issues; v88 crashed/closed SHEIN.
- v85.9-v85.11 rejected working VPNs. Do not restore their full document-start capture path.
- Do not replace whole project files from an older branch.
- Designs come only from Figma.
- `TEST_ONLY_AUTH_BYPASS = true` is test-only; restore OTP before production.

## Device Acceptance

Test fresh install and repeated entry on iPhone 6 and iPhone 16 Pro Max:

1. Otlobli nav is visible and stable from the first frame.
2. SHEIN becomes tappable without switching to Temu or repeated taps.
3. No raw SHEIN tab/header/consent/signup surface appears over Otlobli controls.
4. Germany/Turkey/US/Saudi working VPNs are not falsely rejected.
5. Signed Saudi shipping persists across products and later VPN changes.
6. Product open, back, cart entry, gallery, images, and scrolling remain responsive after several minutes.
7. Size/color capture remains fail-closed and never records `DE/EU/US` as a size.
8. Temu behavior remains unchanged.

## Local Validation

- `npm run build` passed.
- Runtime syntax parse passed for `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT`.
- Actual generated script sizes: bootstrap `29,938` bytes; full capture `374,046` bytes.
- `git diff --check` passed before documentation/version finalization; rerun before commit.
- IPA build is pending the final clean diff/commit.
