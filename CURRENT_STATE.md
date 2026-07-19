# Otlobli Current State

Last updated: 2026-07-19

## v85.8.61 Temu Disabled Child SKU Options

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.61 / `APP_VERSION = 2026.07.19-v85.8.61-temu-disabled-child-sku-no-otp-test`.
- User pasted DOM after tapping an unavailable Temu option on a luggage product. The unavailable options are `role="radio"` shells whose inner SKU card has a class like `disabled-8sgMU`; the radio shell itself can still look selectable to the previous detector.
- Scope: Temu SKU/variant availability only. No bottom nav placement, header forcing, blockers, payment, wallet, orders logic, or account route changes.
- Fix: `temuOptionUnavailable()` now treats a radio/ARIA choice shell as unavailable if it contains disabled/sold-out/out-of-stock child markers, so unavailable colors/options are excluded from selected-option detection and cannot satisfy the add-to-cart gate.
- Also keeps the v85.8.60 behavior: unavailable Temu options are filtered from SKU availability checks, unavailable taps are remembered briefly, and add shows `هذا الخيار غير متوفر حالياً` instead of treating the unavailable choice as selected.
- GitHub iOS build `29668801470` succeeded from code commit `480b2b1`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.61-temu-disabled-child-sku.ipa`.
- v85.8.61 IPA SHA-256: `7EAECBC0F233250E4379859CA581EB13099660FD4836E059FD93905ACECCC5D5`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, `npm run build`, injected-script parse, pasted-DOM radio/disabled-child extraction, `git diff --check`, GitHub build, and embedded bundle marker check passed. Real-device acceptance is still required.

## v85.8.60 Temu Ignore Unavailable SKU Options

- Superseded by v85.8.61 before delivery. v85.8.60 added generic Temu unavailable-option filtering and built successfully (`29668648639`, commit `cb7563d`), but the user's pasted DOM showed the disabled marker can live inside the radio shell, so v85.8.61 extended the detector before producing the final IPA.

## v85.8.58 Temu Bottom Nav Raised Slightly

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.58 / `APP_VERSION = 2026.07.18-v85.8.58-temu-nav-bottom-offset-18-no-otp-test`.
- User report after v85.8.57: Temu bottom nav needs to be raised a tiny bit.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: raise the Temu nav container from `bottom:-22px` to `bottom:-18px`, a 4px upward correction, and bump the injected nav style version.
- GitHub iOS build `29658975318` succeeded from code commit `6cd9aa6`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.58-temu-nav-bottom-offset-18.ipa`.
- v85.8.58 IPA SHA-256: `6D1D060D03404F9546AC513B2AD85993A347D2A5938A6B378EA1050028AC0401`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse plus `bottom:-18px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.58 marker/offset checks passed. Real-device acceptance is still required.

## v85.8.57 Temu Bottom Nav Position Matched From Screenshots

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.57 / `APP_VERSION = 2026.07.18-v85.8.57-temu-nav-bottom-offset-22-no-otp-test`.
- User provided side-by-side real-device screenshots for Temu product page and React Orders nav. Image measurement showed Temu's nav top/indicator band around 9-10px higher than Orders.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: lower the Temu nav container from `bottom:-12px` to `bottom:-22px`, preserving the accepted fixed WebView/no-gap behavior and normal `translate3d(-50%,0,0)` transform.
- GitHub iOS build `29658557163` succeeded from code commit `a0d4b0d`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.57-temu-nav-bottom-offset-22.ipa`.
- v85.8.57 IPA SHA-256: `00C83CA2EB2BCB2F506525C5B7AF63BC3D1F697E88358BD690B4E301124AF209`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse plus `bottom:-22px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.57 marker/offset checks passed. Real-device acceptance is still required.

## v85.8.56 Temu Bottom Nav Lowered Slightly More

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.56 / `APP_VERSION = 2026.07.18-v85.8.56-temu-nav-bottom-offset-12-no-otp-test`.
- User report after v85.8.55: Temu bottom nav is closer but still needs to move down a little more.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: lower the Temu nav container from `bottom:-8px` to `bottom:-12px` and bump the injected nav style version so the WebView refreshes the inline style.
- GitHub iOS build `29657864109` succeeded from code commit `9674808`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.56-temu-nav-bottom-offset-12.ipa`.
- v85.8.56 IPA SHA-256: `D916588CFE9C45E2C0B5764F18179AE65216EF4DF6D8854770F47E2CD0ED378A`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse plus `bottom:-12px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.56 marker/offset checks passed. Real-device acceptance is still required.

## v85.8.55 Temu Bottom Nav Bottom Offset

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.55 / `APP_VERSION = 2026.07.18-v85.8.55-temu-nav-bottom-offset-no-otp-test`.
- User rejected v85.8.54 on real iPhone: Temu bottom nav still looked slightly higher than the React nav in Orders/Cart.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: remove the v85.8.54 Y-transform offset and instead lower the Temu nav container itself with `bottom:-8px`, while keeping `transform:translate3d(-50%,0,0)` so the existing stability CSS no longer fights the alignment.
- GitHub iOS build `29657616560` succeeded from code commit `eb7b0ca`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.55-temu-nav-bottom-offset.ipa`.
- v85.8.55 IPA SHA-256: `52ED888B77AF294970B6CC7E19557131CDC848B3A29D79E4C40B3D3E93FF1F16`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse plus `bottom:-8px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.55 marker/offset checks passed. Real-device acceptance is still required.

## v85.8.54 Temu Bottom Nav Bar Alignment

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.54 / `APP_VERSION = 2026.07.18-v85.8.54-temu-nav-bar-lower-no-otp-test`.
- User report after v85.8.53: the whole Temu injected bottom nav still sits slightly higher than the React nav in Cart/Orders, not just the icon/label content.
- Scope: Temu injected bottom-nav vertical placement only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: remove the v85.8.53 per-icon/per-label downward offset and instead apply one Temu-only `translate3d(-50%,4px,0)` to `#otlobli-nav`, moving the bar, active indicator, icons, labels, and hit area together.
- GitHub iOS build `29657282400` succeeded from code commit `d0c13f4`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.54-temu-nav-bar-lower.ipa`.
- v85.8.54 IPA SHA-256: `00127450AE6E228DE3A07DFDADF71B2788E48071149C44357DF220D21FA0003D`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.54 marker check passed. Real-device acceptance is still required.

## v85.8.53 Temu Bottom Nav Content Alignment

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.53 / `APP_VERSION = 2026.07.18-v85.8.53-temu-nav-content-lower-no-otp-test`.
- User confirmed v85.8.52 fixed the disappearing/blank strip under Temu's bottom nav. Remaining issue: Temu's injected nav content sits slightly higher than the React nav in Orders/Cart.
- Scope: visual alignment of Temu injected bottom-nav content only. No WebView show/hide changes, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- Fix: apply a Temu-only 3px visual downward offset to the injected nav SVG icons and labels, leaving the nav container height, safe-area math, active indicator, and hit targets unchanged.
- GitHub iOS build `29656814832` succeeded from code commit `0009f24`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.53-temu-nav-content-lower.ipa`.
- v85.8.53 IPA SHA-256: `089DE99FED0E44E278CB443323A3C486E5212E0F5A276594B84413D2FD44A8E9`.
- Validation: targeted ESLint for `src/services/sheinBrowserScript.ts` and `src/config.ts`, injected-script parse, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.53 marker check passed. Real-device acceptance is still required.

## v85.8.52 Temu Bottom Nav Preserve Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.52 / `APP_VERSION = 2026.07.18-v85.8.52-temu-preserve-webview-nav-no-otp-test`.
- User report after v85.8.51: Temu's bottom navigation still gained a blank/grey strip underneath after navigating to React Orders and back to Home, while the React Orders nav itself looked correct.
- Scope: Temu iOS WebView show/hide + bottom navigation stability only. No Temu header forcing, product/SKU capture, blockers, payment, wallet, orders logic, or account route changes.
- Fix: Temu on iOS now uses the existing native `otlobliPreserveAttachedWhenHidden` path, like SHEIN, so the WKWebView is not detached to a 1x1 hidden container when the user opens Orders/Cart/Profile. This preserves the WebView viewport and `env(safe-area-inset-bottom)` value across Orders -> Home.
- Fix: removed the v85.8.51 Temu-only delayed `__resize` posts after returning home, reducing layout movement/flicker.
- GitHub iOS build `29656122048` succeeded from code commit `92461f2`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.52-temu-preserve-webview-nav.ipa`.
- v85.8.52 IPA SHA-256: `26FC0A8B5C288EE11D7A877A4EB1DABC6DCFB945089EC09398E8F844340E429A`.
- Validation: `npm run build`, `git diff --check`, GitHub build, and embedded v85.8.52 marker check passed. Targeted ESLint against `App.tsx` still reports pre-existing unrelated App lint errors; no new build error was introduced. Real-device acceptance is still required.

## v85.8.51 Temu Native Header Rollback Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.51 / `APP_VERSION = 2026.07.18-v85.8.51-temu-native-header-resume-gap-no-otp-test`.
- User rejected v85.8.50 on real iPhone: Temu top bar became laggy/stuttery and loading slowed.
- Scope: Temu header rollback + app resume gap only. No payment, wallet, orders logic, account route, SKU/product capture, or blocker redesign changes.
- Change: removed execution and code for the v85.8.49/v85.8.50 Temu header interventions: no header pinning, no category-row forcing/wake, no download-shell collapse, and no empty-gap DOM scan inside Temu.
- Change: on returning from React tabs to Temu home, native posts two delayed `__resize` messages so WKWebView can recalculate layout without touching Temu's header DOM.
- GitHub iOS build `29655425599` succeeded from code commit `aa2f287`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.51-temu-native-header-resume-gap.ipa`.
- v85.8.51 IPA SHA-256: `EEE8BA63452CDACB03AC8FB6502C3DEB97258FDBB9C99BECC9297EB87503FFA6`.
- Validation: targeted ESLint for injected script/config, injected-script parse, `npm run build`, GitHub build, and embedded v85.8.51 marker check passed. Real-device acceptance is still required.

## v85.8.50 Temu Category Header Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.50 / `APP_VERSION = 2026.07.18-v85.8.50-temu-category-header-stable-no-otp-test`.
- Scope: Temu home header/category only. No payment, wallet, orders, account route, SKU/product capture, or blocker redesign changes.
- Fix: normalize only the verified top Temu home category row and wake its horizontal scroller without vertical pull/scroll nudges, so categories can appear from first entry.
- Fix: collapse only empty top header gaps on Temu home and self-restore them if content later appears, avoiding stuck 0px wrappers.
- Performance: category/gap scans are throttled for low-end iPhones.
- GitHub iOS build `29654853138` succeeded from code commit `471809a`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.50-temu-category-header-stable.ipa`.
- v85.8.50 IPA SHA-256: `F66B240EDCB94EFA278C2C6E611428343BAFABC76A23A678E5E5E4031A6FE8EC`.
- Validation: targeted ESLint, injected-script parse, `git diff --check`, `npm run build`, WebKit fixture for hidden categories + empty header gap, GitHub build, and embedded v85.8.50 marker check passed. Real-device acceptance is still required.

## v85.8.49 Temu SHEIN-Like Header Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.49 / `APP_VERSION = 2026.07.18-v85.8.49-temu-shein-like-header-no-otp-test`.
- Scope: Temu header only. No payment, wallet, orders, account route, SKU/product capture, or blocker redesign changes.
- Fix: collapse Temu's app-download banner shell and its banner-only ancestors when they do not contain search chrome, so the hidden banner cannot leave the empty white top strip.
- Fix: re-enable only the narrow existing Temu search/header stabilizer to zero the fixed header's Y transform outside active search, matching SHEIN's stable top-bar behavior without broad CSS.
- Validation so far: targeted ESLint, injected-script parse, `git diff --check`, `npm run build`, and WebKit mobile DOM checks for collapsed download shell and unclipped top search. Final acceptance still requires the real iPhone install.

## v85.8.48 Temu Emergency Rollback

- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.48 / `APP_VERSION = 2026.07.18-v85.8.48-temu-rollback-47-no-otp-test`.
- User rejected v85.8.47 on real iPhone: Temu product pages became blank white again and the header issue was still not fixed.
- Action: reverted the v85.8.47 SKU-capture changes only, restoring the Temu runtime behavior from v85.8.46, then bumped the app version so the rollback IPA is identifiable.
- Scope: no payment, wallet, orders, account route, header, or blocker redesign changes in this emergency rollback.
- Next real-device check: install v85.8.48 first and confirm product pages no longer become blank white. Do not continue with SKU/header work until this rollback is confirmed.

## Active Baseline

- Branch: `claude/ios6-cover-fix`.
- Stable tested reference: v85.8.5 / `a914d81`.
- Reference IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.5-nav-cairo-font-match-no-otp-test.ipa`.
- Last real-device Temu IPA tested: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.30-temu-no-false-size-gate.ipa`.
- Last tested commit: `dcc2bb5` (`fix: v85.8.30 avoid false Temu size gate`) - no false size gate improved, but some product pages could turn white and text-only color could still be blocked.
- Current local candidate: v85.8.31 / `APP_VERSION = 2026.07.17-v85.8.31-temu-product-panel-color-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.31-temu-product-panel-color.ipa`.
- v85.8.31 build run: `29589915204` (success), built from code commit `81426c7`.
- v85.8.31 IPA SHA-256: `C6E8DA038BC4CB9E7363222E17452F24678B169B6FB729675C5CACFBD937CBCC`.
- Previous iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.30-temu-no-false-size-gate.ipa`.
- v85.8.30 build run: `29587915183` (success), built from code commit `dcc2bb5`.
- v85.8.30 IPA SHA-256: `4804EB86912DAD859BC389819C351ABD74A58795E957286BE36E6FAD4C6DF747`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.29-temu-ram-variant-gate.ipa`.
- v85.8.29 build run: `29586606771` (success), built from code commit `74e2c0f`.
- v85.8.29 IPA SHA-256: `6EB037D772BD6FBF6BB0E2264A61AA323A13E6177FA431EE238CD73A548847C5`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.28-temu-search-preserve-query.ipa`.
- v85.8.28 build run: `29584752961` (success), built from code commit `c7c49d5`.
- v85.8.28 IPA SHA-256: `2AFC1C27164E1023493632323B0F1F7992ACC16B3C6294BB9E7CFE54B97C8BCB`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.27-temu-search-light-blockers.ipa`.
- v85.8.27 build run: `29583256531` (success), built from code commit `d9368b4`.
- v85.8.27 IPA SHA-256: `9B706F650718BA25A7D3E9B61CACB54AAAC873DA492FD5F11CA81866EE2A3826`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.26-temu-clean-blockers.ipa`.
- v85.8.26 build run: `29581021125` (success), built from code commit `e3984fd`.
- v85.8.26 IPA SHA-256: `DD22DFD3CE658E056F652F140B6AEA5FEAC8A5CA1193DDAEEEDE557BA0864C2B`.
- v85.8.19 did not fix Temu: header still has empty white space, search typing is slow/unstable, and the account/login panel can appear over search.
- SHEIN is mostly considered previously stabilized; current work is Temu only unless the user explicitly asks otherwise.

## v85.8.31 Local Temu Changes

- Fixes the real-device report after v85.8.30: some Temu product detail pages could render as a blank white page while Otlobli back/add buttons remained visible.
- Removes the early static hide rule for live Temu `panel/adaptPad`/sign-in/guide classes; those account surfaces are now hidden by the dynamic account-panel cleaner only after geometry/text checks.
- Adds a product-content guard so product panels with price, product text, or large Temu images are never hidden by the account-surface cleaner.
- Allows a clearly selected text-only Temu color such as `اللون: اسود و ابيض` to add without requiring a swatch image; product image fallback still supplies the cart image.
- Validated with targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized fixtures for product-panel visibility, account-panel hiding, and text-only color add, GitHub iOS build `29589915204`, and embedded v85.8.31 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

## v85.8.30 Local Temu Changes

- Fixes the real-device report after v85.8.29: some Temu products have color/quantity only and no size/RAM/model options, but Otlobli could still show "select size".
- The Temu add gate now blocks on a second option only when real option pills exist or the Temu variant summary explicitly reports more than one second-option choice.
- Text-only single-color products such as `اللون: لون فضي` now pass and capture the color text without requiring a color swatch image.
- Verified v80 (`db7dfb8`) for comparison; it did not include the RAM/memory gate and still used the older broad size-section block, so no v80 code was restored.
- Validated with targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized fixtures for no-size product, text-only color product, and RAM summary gate, GitHub iOS build `29587915183`, and embedded v85.8.30 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

## v85.8.29 Local Temu Changes

- Keeps the accepted v85.8.28 Temu search behavior unchanged.
- Fixes the product capture gate for Temu products whose option summary includes RAM/memory/storage wording, such as `3 اللون, 1 ذاكرة الوصول العشوائي`.
- The Otlobli add button now treats these summaries as multi-option products and opens/clicks the `حدد` variant row instead of adding directly to the Otlobli cart.
- Extends Temu variant section detection to Arabic/English memory, storage, capacity, RAM, and ROM labels without broad product-page blocking.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit iPhone-sized product fixture proving add does not post before variant selection, GitHub iOS build `29586606771`, and embedded v85.8.29 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

## v85.8.28 Local Temu Changes

- Addresses the v85.8.27 real-device report: account/cart/menu and Temu's bottom nav were visible on the search/results screen, and tapping Otlobli back while a query existed could clear the text.
- Adds a narrow search-only visual cleanup that hides compact top account/cart/menu controls and the fixed Temu bottom nav while Temu search mode or a search URL is active.
- Keeps Temu's native search back button and search suggestion text visible; the broad JS text/geometry blocker still skips active search.
- Changes Otlobli search exit so a focused or populated search input is blurred without clearing the query.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit iPhone-sized search/results fixture for visible native back/suggestions plus hidden account/cart/nav and preserved query, GitHub iOS build `29584752961`, and embedded v85.8.28 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

## v85.8.27 Local Temu Changes

- Lightens the v85.8.26 Temu blocker while search is active.
- Stops calling the old native-search-back hiding function, so Temu's search back button remains visible.
- Skips the JS text/geometry blocker sweep during active Temu search, so search suggestions/letters containing words like offer/deal/cart/bag are not hidden.
- Keeps the static CSS blocker active, so blockers hidden before search stay hidden.
- Validated with targeted ESLint, injected-script parse, `npm run build`, a WebKit search-mode fixture for visible back/suggestions, GitHub iOS build `29583256531`, and embedded v85.8.27 marker check.
- Final judgment still requires the real iPhone install; no simulator was used.

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
