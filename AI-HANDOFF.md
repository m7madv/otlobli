# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `codex/customer-wallet-group-orders`.
- Code: `4989f25` (`fix: v85.8.6 stabilize slow SHEIN iOS navigation`).
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.6.ipa`.
- SHA-256: `F718B401A4FEB16991BC2C17DEB8648C19AA151C390FF4F80005F9B3B1EEBF1E`.
- Build run: `29402834663`.
- Rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- Device testing is pending; never call v85.8.6 proven until both iPhones pass.

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

## Next Step

Install v85.8.6 on iPhone 6 and iPhone 16 Pro Max and execute the checklist in `CURRENT_STATE.md`. Fix only one confirmed remaining issue at a time from this candidate. Do not touch Temu, payment, wallet, completed orders, or design without explicit scope/Figma.
