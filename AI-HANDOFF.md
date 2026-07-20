# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.68 / `APP_VERSION = 2026.07.20-v85.8.68-temu-product-white-screen-guard-no-otp-test`.
- Code commit: `091a35f` (`fix: v85.8.68 prevent Temu product white screen`).
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.68-temu-product-white-screen-guard.ipa`.
- GitHub iOS build `29733534914` succeeded from code commit `091a35f`.
- v85.8.68 IPA SHA-256: `C26CC0F9EB31B01D105F1F004305E2F16B7F8F47DABF6C89DF5F0B499613337B`.
- Latest user clarification: the white-screen product issue happened on installed v85.8.67, not v85.8.68. v85.8.67 could open a few Temu products, then a later product briefly showed login/account UI and became a white page with only Otlobli back visible. v85.8.68 has not been installed yet.
- Change: remove the full-page white Temu product-entry cover while keeping immediate cleanup waves, and protect large non-floating Temu product-flow containers from account/promo hiding on product URLs.
- Includes v85.8.67/v85.8.66 underneath: adaptive iPhone 6/iPhone 16 bottom-nav offset, cart product open flow, notice polish, counted selector rows, and Temu cart-product reveal.
- Scope: Temu product white-screen guard only. No SKU capture, cart flow, header, payment, wallet, orders logic, or real account route changes.
- Validation: targeted ESLint for script/config, `npm run build`, `git diff --check`, GitHub build, and embedded IPA marker checks passed (`NoCoverElement=true`, product-flow guard present, modern/legacy nav markers still present).
- Do not reapply the v85.8.47 visible-SKU/group-dims approach until the white-page regression is understood from real-device evidence or a DOM fixture that reproduces it.
- Next real-device checks: install v85.8.68. Repeat the exact v85.8.67 failure path by opening several Temu products in a row from listing/back; confirm no login flash turns into a white page. Also compare Temu bottom nav on iPhone 6 and iPhone 16 Pro Max.

## Previous Candidate (v85.8.67)

- v85.8.67 / commit `3a4e2dc` fixed Temu bottom-nav placement for modern iPhones when `env(safe-area-inset-bottom)` reports zero, while keeping legacy iPhone 6 on the `0px` path.
- GitHub iOS build `29704696750` produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.67-temu-modern-iphone-nav-offset.ipa` with SHA-256 `1A9CF7A06D25ADF48A91EF71C0F037A09187AA49511348F41ACBCCD1C7E16451`.

## Previous Candidate (v85.8.66)

- v85.8.66 / commit `3648898` fixed opening Temu products from the cart and polished notice surfaces.
- GitHub iOS build `29700181145` produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.66-cart-product-open-notice-polish.ipa` with SHA-256 `943C7862779CA9284855C3DD717CC93BA9B1229C87D8D799CC768CF3F435953D`.

## Previous Candidate (v85.8.65)

- v85.8.65 / commit `d3b2be2` fixed Temu bottom-nav vertical alignment on legacy iPhones by reading real `env(safe-area-inset-bottom)`: no-safe-area iPhones use `bottom:0px`, home-indicator iPhones keep `bottom:-18px`, Android unchanged.
- GitHub iOS build `29697979381` produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.65-temu-legacy-safe-area-nav.ipa` with SHA-256 `FDBA2940D03E7962193C416CCB11F93B7838D5F157DBC3BDBE78BAEE3F21CECF`.

## Previous Candidate (v85.8.64)

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.64 / `APP_VERSION = 2026.07.19-v85.8.64-temu-items-row-cart-open-no-otp-test`.
- Code commit: `d7cd70f` (`fix: v85.8.64 detect Temu items selector row`).
- Previous iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.64-temu-items-row-cart-open.ipa`.
- GitHub iOS build `29672118803` succeeded from code commit `d7cd70f`.
- v85.8.64 IPA SHA-256: `81C48D748AB0A5C219BA585FF84A46E1219AAAB6C349EA3BF53BBF340C0882C7`.
- Latest user DOM/screenshot: Temu smart-watch product has structural row `skuSelector-* role="button" aria-label="7 أغراض:حدد"`. The old structural parser detected the selector shell but did not count `أغراض`, so Otlobli could treat the product as if it had no required options.
- Change: centralized Temu counted-variant label detection and reused it across `temuVariantCounts()`, `temuVariantSummaryEl()`, `otlobliTemuCollapsedVariantRow()`, and the structural `skuSelector-*` parser. The second-option family now includes size/model/style/type/RAM/storage plus `أغراض/اغراض/غرض/عناصر/عنصر/قطع/قطعة/items/pieces/pcs`.
- Includes v85.8.63 underneath: opening Temu products from Otlobli cart now reveals the prepared product after WebView page load instead of leaving a white screen.
- Scope: Temu SKU/variant detection and Temu cart-product reveal only. No header, bottom nav, blocker, payment, wallet, orders logic, or account route changes.
- Validation: pasted-DOM check extracts `7 أغراض` as `secondCount=7`, targeted ESLint for script/config, `npm run build`, injected-script parse, `git diff --check`, GitHub build, and embedded IPA marker checks passed. Real-device acceptance is still pending.
- Do not reapply the v85.8.47 visible-SKU/group-dims approach until the white-page regression is understood from real-device evidence or a DOM fixture that reproduces it.
- Next real-device checks: install v85.8.64, open a Temu product from Otlobli cart and confirm no white screen; on the smart-watch product, pressing Otlobli add should open the `7 أغراض` options sheet and capture after selecting one item. Recheck older `4 الموديل`, unavailable option, and normal color/size products.

## Previous Candidate (v85.8.62)

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.62 / `APP_VERSION = 2026.07.19-v85.8.62-temu-single-model-row-no-otp-test`.
- Latest user screenshot: Temu product with collapsed row `4 الموديل: ...` and `حدد`, while diagnostic overlay reads `sku: لا خيارات`. The row is model-only, so old summary detection missed it.
- Scope: Temu SKU/variant detection only. No bottom nav placement, header forcing, blockers, payment, wallet, orders logic, or account route changes.
- Change: added `otlobliTemuCollapsedVariantRow()` to detect visible `حدد/select/choose` rows with counted variant labels (`4 الموديل`, color/model/size/style/type/RAM/storage). It sets `collapsedEl` so add opens the sheet and waits for the customer selection.
- v85.8.61 remains the unavailable-option fix and is included underneath this change.
- GitHub iOS build `29670967272` succeeded from code commit `0e7882c`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.62-temu-single-model-row.ipa`.
- v85.8.62 IPA SHA-256: `5A23674D464277D424C6D961A3190179638FF86D4B22A45804B8A6939B3D4B5B`.
- Validation: targeted ESLint for script/config, `npm run build`, regex check for `4 الموديل`, injected-script parse, `git diff --check`, GitHub build, and embedded bundle marker check passed. Real-device acceptance is still pending.
- Do not reapply the v85.8.47 visible-SKU/group-dims approach until the white-page regression is understood from real-device evidence or a DOM fixture that reproduces it.
- Next step: install v85.8.62 on the real iPhone. On the WEEME product, pressing Otlobli add should open the `4 الموديل` options sheet instead of treating the product as `لا خيارات`; after selecting a model, it should capture/add normally.

<!-- Older handoff content below may be stale. -->

## Current Candidate

- Branch: `claude/ios6-cover-fix`.
- Last tested IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.30-temu-no-false-size-gate.ipa`.
- Last tested code: `dcc2bb5` (`fix: v85.8.30 avoid false Temu size gate`) - user reported occasional blank white product pages and a text-only color product still blocked by "select color".
- Current local code candidate: v85.8.31 / `APP_VERSION = 2026.07.17-v85.8.31-temu-product-panel-color-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.31-temu-product-panel-color.ipa`.
- Build run: `29589915204` (success), built from code commit `81426c7`.
- IPA SHA-256: `C6E8DA038BC4CB9E7363222E17452F24678B169B6FB729675C5CACFBD937CBCC`.
- Previous iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.30-temu-no-false-size-gate.ipa`.
- Previous build run: `29587915183` (success), built from code commit `dcc2bb5`.
- Previous IPA SHA-256: `4804EB86912DAD859BC389819C351ABD74A58795E957286BE36E6FAD4C6DF747`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.29-temu-ram-variant-gate.ipa`.
- Older build run: `29586606771` (success), built from code commit `74e2c0f`.
- Older IPA SHA-256: `6EB037D772BD6FBF6BB0E2264A61AA323A13E6177FA431EE238CD73A548847C5`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.28-temu-search-preserve-query.ipa`.
- Older build run: `29584752961` (success), built from code commit `c7c49d5`.
- Older IPA SHA-256: `2AFC1C27164E1023493632323B0F1F7992ACC16B3C6294BB9E7CFE54B97C8BCB`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.27-temu-search-light-blockers.ipa`.
- Older build run: `29583256531` (success), built from code commit `d9368b4`.
- Older IPA SHA-256: `9B706F650718BA25A7D3E9B61CACB54AAAC873DA492FD5F11CA81866EE2A3826`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.26-temu-clean-blockers.ipa`.
- v85.8.26 build run: `29581021125` (success), built from code commit `e3984fd`.
- v85.8.26 IPA SHA-256: `DD22DFD3CE658E056F652F140B6AEA5FEAC8A5CA1193DDAEEEDE557BA0864C2B`.
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
- v85.8.27 lightens blockers during active Temu search: it no longer hides Temu's native search back button, and the JS text/geometry cleaner returns immediately while search is active so suggestion words/letters are preserved. Static CSS blockers still apply.
- v85.8.28 adds a narrow search-only cleanup that hides compact top account/cart/menu controls and the fixed Temu bottom nav during search/results without touching suggestion text or Temu's native search back. Otlobli search exit now preserves a focused/populated query instead of clearing it.
- v85.8.29 fixes Temu product option gating for summaries that include RAM/memory/storage, including Arabic `ذاكرة الوصول العشوائي`. Otlobli add now opens the `حدد` variant row instead of adding directly when color plus memory/storage options are present.
- v85.8.30 fixes false Temu size/color gates: products with no size/RAM/model options no longer show "select size"; text-only single-color products such as `اللون: لون فضي` can add and capture the color text. v80 (`db7dfb8`) was checked and not reused because it lacks RAM/memory support and still uses the broad size-section block.

- v85.8.31 fixes two Temu product-page regressions after v85.8.30: removes early static hiding of live `panel/adaptPad` account classes so product templates cannot be blanked, adds a product-content guard to the dynamic account cleaner, and allows a selected text-only color like `اللون: اسود و ابيض` to add without a swatch image.

## Next Step

Install v85.8.31 on the real iPhone. Verify the previously white product pages first, then verify the GENBOLT text-only color product adds with `اسود و ابيض` and empty size. Also recheck that a color+RAM summary product still opens `حدد` before adding. Temu search behavior should remain like accepted v85.8.28.
