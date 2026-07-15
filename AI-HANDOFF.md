# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `codex/customer-wallet-group-orders`.
- Working tree: v85.8.13 functional candidate, uncommitted and without an IPA.
- Last code/IPA: `4e12ef5` / `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.12.ipa`.
- SHA-256: `67D59C6CE34075198CAA1000008515EAC5B0B2EA0C4F97B84C7764DE3210D047`.
- Build run: `29416945278`.
- Rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- v85.8.12 was very good on iPhone 16, but its device report still found consent overlap and iPhone-6 nav/auth/gallery paint issues. v85.8.13 addresses those reports and size fail-closed behavior; never call it proven until both iPhones pass.

## Confirmed Diagnosis

- iPhone 6 needed about 14 seconds, but the v85.8.5 readiness watchdog killed the valid WebView at 13 seconds and then showed a false VPN-server error.
- Cairo was fetched independently from Google in React and SHEIN, causing delayed nav appearance and font/size shifts.
- The full script hid generic fixed/sticky bottom elements, which could affect cookie/action UI.
- Swatches can store the real color in a nested CSS background while HOT is a smaller overlay image.

## Implementation Notes

- First iOS presentation uses `isPresentAfterPageLoad`; no hidden/`FAKE_VISIBLE` path.
- The native cover reappears at every `didStartProvisionalNavigation` and stops above the exact nav height.
- Interactive security verification is revealed after six seconds; it is not bypassed.
- Readiness is 35 seconds; preparation failure is distinct from network/VPN failure.
- Bottom-tab hiding requires verified tab semantics. Cookie adjustment and feed retry are exact and bounded.
- Cairo is self-hosted through `@fontsource-variable/cairo` and embedded into the document-start script.
- Product navigation keeps the same WebView and now gets a native loading cover.
- OTP bypass is test-only.
- v85.8.7 adds semantic visual-stack detection for SHEIN's obfuscated early five-tab div, exact success-toast suppression, warm-cache fast path with bounded clean recovery, and full-bottom iOS WebView layout.
- v85.8.8 makes the injected nav DOM/grid match React, recognizes only exact five-control fixed tab geometry before labels appear, and keeps cart products hidden until both page-load and post-blocker readiness arrive.
- v85.8.9 replaces the incompatible injected Grid with four explicit Flex cells and removes the new first-session geometry scan. The v85.8.7 semantic detector and v85.8.8 product readiness gate remain.
- v85.8.10 gives all injected nav phases one CSS source and only reclaims the DOM node after actual occlusion hit-tests.
- v85.8.11 hides only the confirmed 15%-signup strip or the email-newsletter panel, with explicit real-auth exclusion.
- A SHEIN photo viewer must be fixed, near-full-screen, contain a large image, and expose a numeric image counter before viewer handling activates. Its add button is suppressed, its lower black band is guarded, and nav/back reclaim paint order only on viewer transition.
- v85.8.12 detects nested fixed viewers from targeted painted points, blocks gallery click-through at the event boundary, raises the full cookie action row without auto-consent, closes only a signed-Saudi address surface, and throttles signup/cookie scans. MutationObserver now schedules the normal coalesced tick only.
- v85.8.13 mounts the existing nav before `<body>`, starts Saudi repair only after nav paint, auto-accepts only an exact cookie consent, recovers only recent-product auth interstitials, forces gallery-back paint on old WKWebView, and blocks late-detected size products before final capture.
- It also preserves WebKit cache on routine Temu -> SHEIN switches, requires real hit-testable controls for readiness, performs at most one cache-preserving recovery after a trusted dead tap, and keeps passive security frames covered without a timeout until a real verification control exists.
- Multi-choice descriptive variants (for example `ملعقة`) require a trusted customer tap; SHEIN's automatic first-option highlight is ignored.
- Cart swatch/quantity visual changes are pending an exact Figma frame URL. Do not invent them.

## Next Step

After approval, build v85.8.13 for iOS. Test exact consent auto-accept, persistent nav during Saudi repair, first product entry without auth interruption, visible gallery back on iPhone 6, strict size selection on both phones, a weak single-VPN Temu -> SHEIN return, and the pictured descriptive-option product.
