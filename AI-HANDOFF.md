# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `codex/customer-wallet-group-orders`.
- Code: `97c656f` (`fix: v85.8.7 speed up and mask iPhone 6 SHEIN tabs`).
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.7.ipa`.
- SHA-256: `5039D8037183926DB1D68E81F5EB5F52BA0A805A0122CB8A2021476DB9594F7E`.
- Build run: `29408007214`.
- Rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- v85.8.6 still exposed SHEIN's tab bar during slow iPhone 6 preparation and showed an iPhone 16 safe-area color strip. v85.8.7 device testing is pending; never call it proven until both iPhones pass.

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

## Next Step

Install v85.8.7 on iPhone 6 and iPhone 16 Pro Max and execute the checklist in `CURRENT_STATE.md`. Fix only one confirmed remaining issue at a time from this candidate. Do not touch Temu, payment, wallet, completed orders, or design without explicit scope/Figma.
