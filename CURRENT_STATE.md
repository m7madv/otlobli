# Otlobli Current State

Last updated: 2026-07-17

## Active Baseline

- Branch: `claude/ios6-cover-fix`.
- Stable tested reference: v85.8.5 / `a914d81`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.5-nav-cairo-font-match-no-otp-test.ipa`.
- Last real-device Temu IPA tested: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.25-temu-search-no-motion.ipa`.
- Last tested commit: `806b7d7` (`fix: v85.8.25 stop Temu search layout motion`) - rejected as still too heavy/unstable.
- Current local candidate: v85.8.26 / `APP_VERSION = 2026.07.17-v85.8.26-temu-clean-blockers-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.26-temu-clean-blockers.ipa`.
- v85.8.26 build run: `29581021125` (success), built from code commit `e3984fd`.
- v85.8.26 IPA SHA-256: `DD22DFD3CE658E056F652F140B6AEA5FEAC8A5CA1193DDAEEEDE557BA0864C2B`.
- Previous iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.25-temu-search-no-motion.ipa`.
- v85.8.25 build run: `29578629966` (success), built from code commit `806b7d7`.
- v85.8.25 IPA SHA-256: `75C0A98B98B504EFFCB409AE432A56E689A1E5911198C5B7F0BCF7029E6CEC41`.
- v85.8.19 did not fix Temu: header still has empty white space, search typing is slow/unstable, and the account/login panel can appear over search.
- SHEIN is mostly considered previously stabilized; current work is Temu only unless the user explicitly asks otherwise.

## v85.8.26 Local Temu Changes

- Rebuilds the active Temu blocker path around one lightweight cleaner: account/login, cart/basket, app-download/open-app, and promo/offer/coupon sheets only.
- Stops calling the old Temu header/search/category forcing stack in the active Temu tick path: no active pinning, restoring, category forcing, logo forcing, broad customer chrome hiding, or login-popup clicking.
- Keeps search inputs, search triggers, category/filter rows, product grids, prices, and image-heavy product content protected from the blocker.
- Fixes a blocker-guard bug where the old "near search input" check climbed to `<body>` and protected unrelated floating offer sheets.
- Removes the old generic distraction list from promo detection so category/nav/menu hints do not hide the category strip.
- Slows the Temu-only cleanup interval to `1200ms` / `1800ms` on low-end devices to reduce heat and layout churn.
- Validated with targeted ESLint, injected-script parse, `npm run build`, an iPhone-6-sized WebKit blocker harness, GitHub iOS build `29581021125`, and embedded v85.8.26 marker check.
- Live Temu in headless browsers redirected to a download, so final judgment still requires the real iPhone install.

## v85.8.25 Local Temu Changes

- Treats v85.8.24 as rejected on real device: search needed multiple taps, the search bar moved while typing, the category strip was half-hidden during search, and the header size broke after exiting.
- Removes the v85.8.24 active search shell/frame marking path and all search-mode CSS that changed `min-height`, `padding-bottom`, `transform`, or `margin-top`.
- Stops restoring/forcing the Temu category strip while Temu search mode is active; category-strip CSS now applies only outside search mode.
- Makes Otlobli search-back robust when tapping the back button steals focus from the input, using a short search-back grace window that is cleared immediately on exit.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit browser harness for single tap -> type without motion -> Otlobli back -> home, GitHub iOS build `29578629966`, and embedded v85.8.25 marker check.

## v85.8.24 Local Temu Changes

- Rejected on real device. It moved/expanded the search layout and caused multiple-tap search entry, moving search bar while typing, hidden category strip, and broken home size after exit.
- Fixes the latest real-device report after v85.8.23: entering Temu search cut the lower part of the search bar, and returning home could leave the header/category strip compressed or shifted.
- Replaces the previous search-mode `margin-top:18px` with a scoped active search shell/frame: only the nearest search frame gets temporary `overflow:visible`/minimum height, while the search shell is visually lowered with `transform`.
- Adds active-element and last-search-input fallbacks so the active search shell is marked reliably without broad guessing or page-wide CSS.
- On search exit, clears both active shell and active frame markers, restarts a bounded home-header wake window even when the URL did not change, and adds one delayed low-end reset for slower iPhones.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit iPhone 6-sized clipped-search -> Otlobli-back -> home fixture, GitHub iOS build `29577463207`, and embedded v85.8.24 marker check.

## v85.8.23 Local Temu Changes

- Fixes the real-device report that Temu home looks correct on first entry but the home header/layout breaks after entering search and backing out.
- On Otlobli search-back, the search input is found even after focus moves to the back button, then cleared with `input/search/change` events and blurred.
- Adds a short explicit search-exit suppress window so leftover suggestion overlays cannot keep the page in search mode after returning home.
- Hides only search suggestion/recent/trending overlays created by the search session, and marks them so search/category restoration cannot revive them as category strips.
- Tightens category-strip detection so search/suggest/trending text is never treated as a category strip even if it contains words like women/kids.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit iPhone-sized home -> search -> back fixture, and GitHub iOS build `29554026083`.

## v85.8.22 Local Temu Changes

- Restores the Temu category strip from first entry by marking verified category containers and applying targeted `display:flex`, instead of relying only on a tiny scroll wake.
- Treats a focused top searchbox as active Temu search even if Temu only opened the keyboard and did not switch route/overlay yet.
- Marks the active search shell and lowers it by 18px during search so it is not pressed against the status/header area.
- Hides Temu's native search back control while search is active; Otlobli back now blurs/cleans search instead of tapping Temu's arrow that opened "Available offers".
- Hides account/login and service-offer distraction sheets on non-account routes, while preserving real Temu account routes when opened intentionally.
- Replaced the iOS splash PNGs with a blank white splash to avoid the blue logo showing in the app switcher/background preview.
- Validated with targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized fixtures for home/search/back/account-route behavior, and GitHub iOS build `29553022990`.

## v85.8.21 Local Temu Changes

- Fixed a WebKit document-start crash where Cairo font injection assumed `document.head` or `documentElement` already existed.
- Deferred the full-script `MutationObserver` until a real document root exists, so Temu protections cannot abort before intervals start.
- Added a first-entry Temu home wake nudge: if the category strip is not visible, dispatch the same tiny scroll/resize path that makes Temu reveal it, then return to top.
- Hid Temu account/login surfaces by observed live classes (`panel/adaptPad`, sign-in rows, account bottom strip) on non-account routes, including redraws during search.
- Kept login hiding targeted and lightweight; no broad 90ms page-wide text scan remains, so search typing should stay responsive.
- Validated with WebKit iPhone-sized Playwright, including a routed Temu fixture that reproduces hidden categories and recreated account panels without using the simulator.
- No payment, wallet, completed-order, or real account-route logic was intentionally changed.

## v85.8.20 Local Temu Changes

- Broadened Temu search input detection to include the live top text field when Temu omits `type="search"`/placeholder metadata.
- Cached expensive Temu search-mode DOM probing for a very short window so typing does not repeatedly scan the whole page.
- Search chrome restoration now avoids walking into account/login panel containers.
- Login/account panel hiding is reapplied while search is active if Temu redraws the same visible panel.
- Home-header forcing no longer scrolls the page back to top and no longer raises the category strip with forced transform/background/z-index.
- No payment, wallet, completed-order, or account-route logic was intentionally changed.

## v85.8.6 Scope

- Keeps v85.8.5 store/VPN/Saudi-address behavior as the base.
- Defers first iOS WebView presentation until its first live page while React's nav remains mounted.
- Uses bundled Cairo in both React and the injected SHEIN nav; no Google Fonts timing shift.
- Shows the native loading cover for every iOS main-frame navigation while leaving Otlobli's nav uncovered.
- Gives slow devices 35 seconds for SHEIN readiness instead of falsely blaming the VPN at 13 seconds.
- Passive security checks remain covered briefly; genuinely interactive verification is revealed after a bounded wait and is never bypassed.
- Hides only a verified SHEIN bottom tab bar. The old generic fixed-bottom hiding path is no longer called.
- Raises only an exact cookie-consent action that would overlap Otlobli's nav.
- Retries only SHEIN's exact feed-error retry action, at most four times, without reload or `setUrl` loops.
- Improves round/HOT swatch capture by ranking nested images and CSS backgrounds while rejecting small badge layers.
- Runtime Service Worker/cache cleanup runs once per SHEIN WebView session, not on every product/back navigation.

## v85.8.7 Changes

- v85.8.6 device result: iPhone 6 still showed SHEIN's five-tab bar under Otlobli's nav during preparation and remained slow; iPhone 16 showed a differently colored safe-area strip below the home nav.
- The document-start bootstrap now finds obfuscated plain-div SHEIN tabs through the visual element stack plus exact tab semantics; no broad DOM/CSS scan was added.
- Only SHEIN's exact compact "added to cart successfully" toast is hidden when it overlaps the app nav.
- Healthy WebKit cache is preserved for the fast path. Cache clearing remains limited to bounded stuck-session recovery and explicit Temu -> SHEIN switching.
- iOS WKWebView now fills the controller bottom; the injected safe-area-aware nav paints the whole inset. Android keeps its native safe-bottom margin.

## v85.8.8 Changes

- Real-device v85.8.7 result: iPhone 16 navigation appearance improved, but the injected home icons sat lower than the React cart/orders/profile icons; iPhone 6 could expose icon-only SHEIN tabs on first entry.
- The injected nav now mirrors React's grid row, direct SVG/label structure, normal line height, and natural content-box height instead of a separate flex/fixed-height layout.
- Document-start hiding adds one narrow fallback: exactly five evenly spaced children inside a fixed/sticky bottom row. It does not hide arbitrary bottom elements.
- A cart product is loaded inside the preserved hidden SHEIN WebView while the React cart stays visible. It is revealed only after the target page load and a blocker-ready message.
- SHEIN readiness is posted only after header/cart/listing/bottom-nav/cookie/toast/install blockers have run for that tick.

## v85.8.9 Changes

- v85.8.8 device result: the injected nav collapsed to content width on an older iPhone WKWebView, stacking all four tabs at the right; the first fresh launch also exited once and the second launch was smooth.
- The injected nav uses legacy-safe Flex again, with four explicit 25% cells and direct icon/label content stretched through the same 73px content row as React.
- The v85.8.8 first-session geometry scan was removed; the proven v85.8.7 semantic tab detector remains. Hidden cart-product readiness remains unchanged.
- Browser layout checks at 375px and 430px confirmed four equal cells across the full width.

## v85.8.10 Changes

- v85.8.9 device result: the fixed nav briefly flashed/brightened once while SHEIN opened.
- Bootstrap, challenge, and hydrated SHEIN navigation now share one canonical CSS string, including safe-area padding, font, background, and blur from the first frame.
- The hydrated script no longer rewrites `cssText` every tick. Reclaiming the nav to the end of `<body>` happens only when four hit-tests prove another layer actually covers it.
- `viewport-fit=cover` is established during document-start so safe-area geometry settles before the native WebView is presented.

## v85.8.11 Changes

- v85.8.10 device result: the user accepted the normal iPhone 16 navigation behavior. On iPhone 6, SHEIN could inject either a compact `15% + Register` strip or a larger email-newsletter registration panel above the app nav after cookie consent.
- Both registration surfaces are now matched by compound semantics plus exact structure. Product discounts and SHEIN's real sign-in/Google form are explicitly excluded; no generic promo CSS was added.
- The exact registration check runs at document start and before the next SPA paint. The newsletter form is found from its email input while still off-screen.
- In SHEIN's full-screen product-photo viewer, Otlobli's add button is hidden and a transparent lower-letterbox guard prevents taps from falling through to an add action.
- The viewer is recognized only as a fixed near-full-screen layer with a large image and `current/total` counter. On opening it, the existing nav and back button reclaim paint order once so old WKWebView cannot paint the viewer over them while leaving their hit targets active.
- v85.8.10 nav CSS, sizing, font, and ordinary-page behavior are unchanged.

## v85.8.12 Changes

- v85.8.11 device result: cookie Accept could sit below Otlobli's nav, the Saudi address surface could remain open after success, gallery/image taps could still capture the product, and the new pre-paint signup scan made iPhone 6 noticeably heavier.
- Cookie consent remains the customer's decision. The exact Accept/Reject action row is raised together above the nav; Otlobli does not silently accept tracking consent.
- A resolved Saudi shipping surface is closed only after SHEIN writes a fully signed Saudi address. Existing URL/storage/address guards continue to detect and repair a later foreign-region change.
- Only an unsolicited login dialog over a product is dismissed. Real login/account routes remain untouched.
- Gallery detection now walks from a few painted points to a nested fixed viewer root. Gallery taps cannot reach native or Otlobli add/cart/wishlist actions; nav/back reclaim paint order on the viewer transition.
- Removed v85.8.11's MutationObserver-to-requestAnimationFrame whole-page signup inspection. Cookie/signup scans are throttled and use six targeted points instead of fifteen, reducing layout work on old WKWebView.
- Fixed srcset whitespace parsing inside the injected script. Temu, payment, wallet, orders, and cart design are unchanged.

## Failed Paths / Guardrails

- v86-v88 are failed paths. v87 fixed none of the reported issues; v88 closed/crashed SHEIN on entry.
- v85.9-v85.11 rejected the user's working VPN. Do not reuse their full document-start capture path.
- Do not reintroduce hidden/offscreen `FAKE_VISIBLE`, broad CSS, viewport-width hacks, wide storage resets, or reload loops.
- Do not change payment, wallet, completed orders, Temu, coupons, or group checkout during this SHEIN pass.
- Designs come only from Figma.
- `TEST_ONLY_AUTH_BYPASS = true` only for rapid device testing; restore OTP before production.

## Acceptance Test

Test on iPhone 6 and iPhone 16 Pro Max:

1. Otlobli nav is visible from launch and never changes font/size.
2. No raw SHEIN tab bar appears during initial load, product open, back, or app-tab return.
3. Turkey/Germany VPN is not rejected merely because iPhone 6 prepares slowly.
4. SHEIN feed becomes usable without repeated manual retry taps.
5. Cookie consent is tappable above the nav and does not open Orders.
6. Product from cart leaves the React cart visible until ready; no raw product reload/chrome appears; back is smooth.
7. Round/HOT selected color produces the actual color thumbnail in cart.
8. Saudi shipping remains authoritative.
9. After accepting cookies, neither the 15% registration strip nor the email-newsletter panel appears above the nav; real SHEIN sign-in remains usable.
10. In a product photo viewer, add-to-cart is absent, the black lower band cannot add an item, and nav/back remain visibly painted on both phones.
11. Cookie Accept and Reject are both reachable above the nav; rejecting does not leave a forced product-login popup.
12. After Saudi setup completes, the address surface closes; a later foreign-region state is detected and repaired without broad storage clearing or reload loops.
13. On iPhone 6, product images and scrolling remain responsive after cookie consent and repeated product/gallery opens.

## Validation

- Clean `patch-package` reinstall passed; tracked relay keys remain placeholders.
- `npm run build` passed.
- Runtime syntax parse of both injected scripts passed.
- `git diff --check` passed.
- Targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts` passed.
- Full-project lint still has pre-existing unrelated errors in `App.tsx`, Admin, and the payment webhook; this SHEIN change introduced no build error.
- Xcode unsigned build and packaging passed in run `29414121203`.
- Embedded v85.8.11 marker and desktop IPA SHA-256 were verified.
- Xcode unsigned build and packaging passed in run `29416945278`; the embedded v85.8.12 marker and desktop IPA SHA-256 were verified.
