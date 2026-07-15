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
- v85.8.12 device report accepted most iPhone-16 behavior, but found exact consent overlap; iPhone 6 could lose nav paint during Saudi repair, show a one-time product auth screen, and keep the gallery back target invisible.
- Implemented the uncommitted v85.8.13 functional candidate: documentStart nav continuity, exact bounded cookie auto-accept, recent-product auth recovery, old-WK gallery-back paint isolation, stricter size detection/final capture guard, and nav-aware fading size feedback.
- Latest device diagnosis isolated the painted/non-clickable page to the router-VPN + phone-VPN case; disabling the router tunnel made the same iPhone 16 path fast. Routine Temu -> SHEIN cache clearing was removed, readiness now includes hit-testing, and one trusted dead tap can trigger one cache-preserving WebView recreation.
- Passive black security frames remain covered without the ordinary 45-second reveal timeout until a real interactive verification control exists. The pictured multi-choice product now ignores SHEIN's automatic `ملعقة` default and requires a trusted customer selection.
- No cart visual redesign was made because the project has no exact Figma frame URL. Temu, payment, wallet, and orders remain unchanged.
- Committed v85.8.13 as `b9cbb8e`; iOS run `29422476203` succeeded and produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.13.ipa` with SHA-256 `D1AEEF4A3ACA77DA1D8A216BBD457DD58E48830F9A48AFDE3D84A73A4700A109`. The embedded version marker was verified.
- Latest v85.8.13 device report reproduced a painted/non-clickable SHEIN page, visible consent UI, iPhone-6 gallery chrome loss, and `DE` captured as a size. The uncommitted v85.8.14 candidate fixes the readiness ancestor-hit false positive with four stable checks, coordinates hidden exact consent auto-accept retries, rejects sizing-system labels/removes single-option auto-selection, and expands only the exact-counter full-screen gallery detector. Build/script/lint/patch/diff validation passed; no IPA was built yet.
- Committed v85.8.14 as `855b6eb`; iOS run `29426638388` succeeded and produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.14.ipa` with SHA-256 `0A9EFB370E718A9FFD8E157694ECC4A335F362F0E85B9DD40A97685A55D868AB`. The embedded version marker was verified.
- v85.8.14 failed device testing with visible/unaccepted consent, slower repeated Saudi preparation, rejected trusted size selection, nav loss during repair, and the iPhone-6 center SHEIN icon. The uncommitted v85.8.15 candidate removes the new multi-pass wait, restores the v85.8.13 Saudi-ready path and size discovery, makes exact Accept-all independent of sheet geometry, rejects DE/EU/US only at final size state, and adds a tight center-icon guard. Local build/script/lint/patch/diff checks passed; no IPA built yet.
- Committed v85.8.15 as `9ba6a7f`; iOS run `29428880011` succeeded and produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.15.ipa` with SHA-256 `0BDEEC053CCAC3AEAA0944DFA360C0C8CE17742D783830B4326553527D277D4E`. The embedded version marker was verified.
- v85.8.15 device testing was faster but still left Qatar, misclassified old-iPhone WebKit preparation as a bad Germany VPN, exposed consent/raw SHEIN tabs, and allowed `DE` to cross the capture boundary. v85.8.16 (`ccf08aa`) fixes the bounded native Saudi cascade/full-page picker, exact all-frame consent, preparation classification, nav paint ownership, and two-layer size-system rejection. Run `29432951413` produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.16.ipa`; SHA-256 `F25EEBAAB50991CDAEFE373202EEE5A7BABF3F889ACEE9B09D2D0F6E232C370D`; embedded marker verified.
- v85.8.16 device testing reported severe overall SHEIN degradation. v85.8.17 replaces permanent 300/120/1000/250ms SHEIN and bootstrap polling with bounded lifecycle bursts, isolates nav remounting from full DOM scans, deduplicates same-document injection, and limits Saudi follow-up to its active 15-second repair state. Temu and business logic are unchanged; local build and runtime script parse passed, device acceptance and IPA pending.
