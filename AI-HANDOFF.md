# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `claude/ios6-cover-fix`.
- Last tested IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.25-temu-search-no-motion.ipa`.
- Last tested code: `806b7d7` (`fix: v85.8.25 stop Temu search layout motion`) - rejected as still heavy/unstable on real device.
- Current local code candidate: v85.8.26 / `APP_VERSION = 2026.07.17-v85.8.26-temu-clean-blockers-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.26-temu-clean-blockers.ipa`.
- Build run: `29581021125` (success), built from code commit `e3984fd`.
- IPA SHA-256: `DD22DFD3CE658E056F652F140B6AEA5FEAC8A5CA1193DDAEEEDE557BA0864C2B`.
- Previous iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.25-temu-search-no-motion.ipa`.
- Previous build run: `29578629966` (success), built from code commit `806b7d7`.
- Previous IPA SHA-256: `75C0A98B98B504EFFCB409AE432A56E689A1E5911198C5B7F0BCF7029E6CEC41`.
- Rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- v85.8.19 did not fix Temu. Current focus is Temu only; do not touch payment, wallet, completed orders, or account routes unless explicitly requested.
- v85.8.10's ordinary iPhone 16 SHEIN nav behavior was accepted. Do not call any new Temu change proven until tested on the real iPhone device; do not rely on the simulator.

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
- v85.8.20 local Temu candidate broadens top search-field detection, caches search-mode probing briefly to reduce typing lag, prevents search chrome restoration from re-showing account/login panel ancestors, reapplies search-only login panel hiding if Temu redraws it, and stops home-header forcing from scrolling to top or raising the category strip with forced transform/background/z-index.
- v85.8.21 fixes a WebKit document-start abort in Cairo font injection and defers the MutationObserver until a root node exists. It nudges Temu's first-entry home header only when the category strip is missing, then returns to top. It hides the live Temu account/login surfaces by observed classes on non-account routes, including search redraws, without the previous heavy 90ms full-page text scan.
- v85.8.22 marks verified Temu category strips and forces only those strips to `display:flex`, detects focused searchboxes as search mode, lowers the active search shell by 18px, hides Temu's native search back control, and cleans login/offer sheets on non-account routes while preserving real account routes. The iOS splash PNGs are now blank white to avoid the blue logo in app switcher previews.
- v85.8.23 fixes home layout breaking after entering Temu search and backing out. Otlobli search-back now remembers/clears the search input, dispatches input/search/change, suppresses stale search-mode briefly, hides only search suggestion overlays, and prevents those overlays from being restored as category strips.
- v85.8.24 is rejected on real device. It used active search shell/frame marking plus transform/min-height CSS and caused multiple-tap search entry, moving search bar while typing, half-hidden category strip, and broken home size after exit.
- v85.8.25 removes the v85.8.24 motion/frame path. During search, Otlobli no longer restores/forces the category strip and no longer applies search-mode transform/min-height/margin CSS. Otlobli back uses a short focus-loss grace window so tapping the back button still exits search even if focus leaves the input first.
- v85.8.26 resets the active Temu blocker path: one lightweight cleaner hides only account/login, cart/basket, app-download/open-app, and promo/offer/coupon sheets. The active Temu tick no longer calls the old header/search/category forcing stack. The cleaner protects search inputs/triggers, category rows, product grids, prices, and image-heavy content; it also fixes the old broad `near search input` guard and removes generic `category/nav/menu` distraction matching from promo detection.

## Next Step

Install v85.8.26 on the real iPhone. Verify Temu first-entry home, category row after light horizontal/vertical movement, search open/typing/back, and that account/login, cart, app-download, and offer popups are hidden without header/category resizing or phone heat.
