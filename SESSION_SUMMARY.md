# Session Summary

Last updated: 2026-07-15

- Restored and verified the user-provided v85.8.5 line as the working base (`a914d81`).
- Diagnosed iPhone 6's false VPN failure as a 13-second readiness timeout racing its observed ~14-second preparation.
- v85.8.6 testing showed the early five-tab SHEIN bar still visible on iPhone 6, slow entry, an overlapping SHEIN success toast, and an iPhone 16 safe-area color strip.
- Implemented v85.8.7 in `97c656f`: early semantic visual-stack tab detection, exact toast suppression, warm-cache fast path with bounded clean recovery, and full-bottom iOS WebView layout.
- Kept payment, wallet, orders, Temu, and cart design out of scope.
- Build/script/patch/diff checks passed.
- iOS run `29408007214` succeeded.
- Test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.7.ipa`.
- SHA-256: `5039D8037183926DB1D68E81F5EB5F52BA0A805A0122CB8A2021476DB9594F7E`.
- Real-device testing on iPhone 6 and iPhone 16 Pro Max is still required; no fix claim yet.
