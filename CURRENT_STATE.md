# Otlobli Current State

Last updated: 2026-07-16

## Active Baseline

- Branch: `codex/customer-wallet-group-orders`.
- Stable tested reference: v85.8.5 / `a914d81`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.5-nav-cairo-font-match-no-otp-test.ipa`.
- Active candidate: local v85.8.20 (exact OneTrust acceptance + trusted size binding + one bounded SHEIN block-session recovery; device acceptance pending).
- Last built IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.19.ipa`.
- Build run: `29452454010`; SHA-256 `0CE0C4480D1D60CCD1BC11787A1C6F69293C13B4F0C1EB7521CF309FFD710F03`.
- `APP_VERSION = 2026.07.16-v85.8.20-shein-consent-block-recovery-no-otp-test`.
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

## v85.8.18 Changes

- A fresh SHEIN document is interaction-gated before consent UI can paint; a saved accepted marker skips this preflight on later loads.
- Exact `Accept all` / `قبول الكل` is detected in the owning main document or child frame, clicked automatically, and the gate releases after the click settles.
- Consent mutations are inspected synchronously before the next paint using only the new small node (maximum 12 nodes, two ancestor levels, 80-child cap); no permanent scan or interval was added.
- DOM text checks use `textContent` to avoid layout work on iPhone 6.
- A 12-second consent fail-safe prevents a changed SHEIN consent implementation from trapping the customer.
- The visual state reuses the existing Otlobli store-preparation treatment; no new page design was introduced.

## v85.8.19 Changes

- Confirmed the half-second white frame when opening Notification Center was not a SHEIN/Temu reload: Capgo InAppBrowser added the white launch image over its native controller on every iOS `willResignActive` event.
- Disabled only that upstream privacy overlay, so iOS keeps the already-rendered store frame during temporary inactive transitions.
- No WebView recreation, store script, region, capture, Temu, payment, wallet, order, cart, CSS, or design behavior changed.

## v85.8.20 Changes

- The pictured consent surface is confirmed as OneTrust. The owning frame now clicks the exact `onetrust-accept-btn-handler`; official consent-and-close APIs are fallback only.
- Invisible RTL/bidi marks are stripped before comparing Arabic consent and size labels. OneTrust fallback discovery stays confined to its exact root; no broad page click or permanent polling was added.
- A real trusted SHEIN size tap is now bound to the product independently of the option node SHEIN replaces during hydration. This restores selected-size capture while still rejecting automatic defaults and standalone `DE/EU/US` sizing-system labels.
- A geo-confirmed US/Germany/etc. VPN followed by SHEIN's short WAF/block document gets one existing bounded fresh-WebView/cache recovery. Repeated failure is classified as WebView preparation, not falsely as an unsupported VPN server.
- Temu, region forcing, cart, payment, wallet, and orders were not changed.

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
9. Pulling and dismissing Notification Center over SHEIN and Temu does not show a white frame or reload the store.

## Local Validation

- `npm run build` passed.
- Runtime syntax parse passed for `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT`.
- The v85.8.19 change is native-only; the SHEIN scripts were not modified.
- The patched native diff parses with `git apply --stat`.
- `git diff --check` passed before documentation/version finalization; rerun before commit.
- iOS unsigned build/package passed in run `29446101794`; embedded v85.8.18 marker and desktop IPA SHA-256 were verified.
- iOS unsigned build/package passed in run `29452454010`; embedded v85.8.19 marker and desktop IPA SHA-256 were verified.
- v85.8.20 `npm run build`, focused script/config lint, runtime parsing of both injected scripts, and `git diff --check` passed locally; IPA/device acceptance pending.
