# Session Summary

Last updated: 2026-07-15

- Restored and verified the user-provided v85.8.5 line as the working base (`a914d81`).
- Diagnosed iPhone 6's false VPN failure as a 13-second readiness timeout racing its observed ~14-second preparation.
- v85.8.6 testing showed the early five-tab SHEIN bar still visible on iPhone 6, slow entry, an overlapping SHEIN success toast, and an iPhone 16 safe-area color strip.
- v85.8.8 device testing exposed an old-WKWebView Grid collapse and a one-time first-launch exit.
- Implemented v85.8.9 in `917bfb7`: four legacy-safe 25% Flex nav cells and removal of the new first-session geometry scan, while retaining hidden cart-product preparation.
- Implemented v85.8.10 in `6138b23`: one canonical nav paint state from document-start through hydration, with DOM reclaim only after actual occlusion.
- Kept payment, wallet, orders, Temu, and cart design out of scope.
- Build/script/patch/diff checks passed.
- iOS run `29411837856` succeeded.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.10.ipa`.
- SHA-256: `519EA5D2A7946548B55632D934B2CB438E39580357E6AE5432F6F19F4F368C18`.
- Real-device testing on iPhone 6 and iPhone 16 Pro Max is still required; no fix claim yet.
