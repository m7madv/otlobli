# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `codex/customer-wallet-group-orders`.
- Code: `c4738fb` (`fix: v85.8.8 align nav and prepare cart products`).
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.8.ipa`.
- SHA-256: `A2F6D1E8B3F41D96D0B94A346542BA15B88BED80188F9A553643B1C0333A1149`.
- Build run: `29409886905`.
- Rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- v85.8.7 improved the iPhone 16 safe-area appearance and iPhone 6 speed, but left injected nav icons vertically lower, a first-install icon-only SHEIN tab flash, and a visible product reload before blockers. v85.8.8 device testing is pending; never call it proven until both iPhones pass.

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

## Next Step

Install v85.8.8 on iPhone 6 and iPhone 16 Pro Max and execute the checklist in `CURRENT_STATE.md`. Focus on nav vertical parity, first-install icon flash, and cart-product reveal timing. Do not touch Temu, payment, wallet, completed orders, or design without explicit scope/Figma.
