# Session Summary

Last updated: 2026-07-15

- Restored and verified the user-provided v85.8.5 line as the working base (`a914d81`).
- Diagnosed iPhone 6's false VPN failure as a 13-second readiness timeout racing its observed ~14-second preparation.
- v85.8.6 testing showed the early five-tab SHEIN bar still visible on iPhone 6, slow entry, an overlapping SHEIN success toast, and an iPhone 16 safe-area color strip.
- v85.8.8 device testing exposed an old-WKWebView Grid collapse and a one-time first-launch exit.
- Implemented v85.8.9 in `917bfb7`: four legacy-safe 25% Flex nav cells and removal of the new first-session geometry scan, while retaining hidden cart-product preparation.
- Implemented v85.8.10 in `6138b23`: one canonical nav paint state from document-start through hydration, with DOM reclaim only after actual occlusion.
- v85.8.10 device testing accepted normal iPhone 16 navigation, but exposed two iPhone-6 SHEIN registration surfaces and a full-screen photo-viewer paint/hit-test conflict.
- Implemented v85.8.11 in `13585b6`: exact 15%-strip/newsletter suppression with real-auth exclusion; photo-viewer add suppression, click-through guard, and one-time nav/back paint-order reclaim.
- v85.8.11 device testing found four remaining issues: hidden cookie Accept, Saudi UI left open, gallery/image taps still capturing, and iPhone-6 jank after the pre-paint signup scan.
- Implemented the uncommitted v85.8.12 candidate: full consent-row clearance without auto-accept, signed-Saudi UI close plus ongoing foreign-region guards, narrow product-login dismissal, nested-viewer detection and event-level click-through blocking, throttled scans, and removal of MutationObserver pre-paint geometry work.
- Kept payment, wallet, orders, Temu, and cart design out of scope.
- Build/script/targeted-lint/diff checks passed for v85.8.12.
- iOS run `29414121203` succeeded.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.11.ipa`.
- SHA-256: `EB4019D410D58FB7DE720F12BAE88FF015E6160CA0AC0C8870584E1715271539`.
- Real-device testing on iPhone 6 and iPhone 16 Pro Max is still required; no fix claim yet.
- iOS run `29416945278` succeeded for commit `4e12ef5`.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.12.ipa`.
- SHA-256: `67D59C6CE34075198CAA1000008515EAC5B0B2EA0C4F97B84C7764DE3210D047`.
