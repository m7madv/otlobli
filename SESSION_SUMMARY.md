# Session Summary

Last updated: 2026-07-15

- Restored and verified the user-provided v85.8.5 line as the working base (`a914d81`).
- Diagnosed iPhone 6's false VPN failure as a 13-second readiness timeout racing its observed ~14-second preparation.
- v85.8.6 testing showed the early five-tab SHEIN bar still visible on iPhone 6, slow entry, an overlapping SHEIN success toast, and an iPhone 16 safe-area color strip.
- v85.8.8 device testing exposed an old-WKWebView Grid collapse and a one-time first-launch exit.
- Implemented v85.8.9 in `917bfb7`: four legacy-safe 25% Flex nav cells and removal of the new first-session geometry scan, while retaining hidden cart-product preparation.
- Kept payment, wallet, orders, Temu, and cart design out of scope.
- Build/script/patch/diff checks passed.
- iOS run `29410938651` succeeded.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.9.ipa`.
- SHA-256: `F5FB938AC9B6C67D1964916BF9F49B2ECB13C4C56D865C2B1D13CE8B35ED5D3E`.
- Real-device testing on iPhone 6 and iPhone 16 Pro Max is still required; no fix claim yet.
