# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `codex/customer-wallet-group-orders`.
- Code: `917bfb7` (`fix: v85.8.9 restore legacy iOS nav compatibility`).
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.9.ipa`.
- SHA-256: `F5FB938AC9B6C67D1964916BF9F49B2ECB13C4C56D865C2B1D13CE8B35ED5D3E`.
- Build run: `29410938651`.
- Rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- v85.8.8 collapsed the injected nav to the right on an older iPhone and exited once on the first fresh launch. v85.8.9 removes those two new startup/layout paths while retaining hidden cart-product preparation. Device testing is pending; never call it proven until both iPhones pass.

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

## Next Step

Install v85.8.9 on iPhone 6 and iPhone 16 Pro Max. Start with a fresh install, confirm the app stays open, then verify full-width nav distribution and cart-product reveal timing. Do not touch Temu, payment, wallet, completed orders, or design without explicit scope/Figma.
