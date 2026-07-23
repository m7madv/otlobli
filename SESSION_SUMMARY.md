# SESSION_SUMMARY.md

## 2026-07-23 SHEIN v85.8.85 iOS Gentle Challenge

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.85 / `APP_VERSION = 2026.07.23-v85.8.85-shein-ios-gentle-challenge-no-otp-test`.
- New real-device evidence: SHEIN works on iPhone 6, but iPhone 16 Pro Max gets challenged/blocked after first entry even after reinstall. This points to SHEIN anti-bot/session sensitivity on that device, not a universal broken build.
- Fix: during SHEIN human/security challenge pages, the injected script no longer writes Saudi storage/cookies and no longer mounts Otlobli nav into the challenge page. It removes Otlobli nodes, releases scroll lock, posts `humanCheck`, and leaves the challenge itself untouched.
- Load reduction: all iOS SHEIN pages now use the gentler low-end polling cadence instead of the modern-device 80ms/120ms hot path, reducing automation-like pressure while keeping the working iPhone 6 behavior.
- Scope stayed narrow: no product capture, add-to-cart, color, size, cart math, payment, wallet, completed orders, or Temu logic changed.
- Validation passed: `npm run build`; injected-script syntax parse for `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` and `SHEIN_CAPTURE_SCRIPT`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts`.
- No IPA has been built from this candidate yet.

## 2026-07-22 SHEIN v85.8.84 Roll Back Failed Fresh Session

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.84 / `APP_VERSION = 2026.07.22-v85.8.84-rollback-v83-shein-stable-saudi-no-otp-test`.
- User rejected v85.8.83 on real iPhone: Saudi locking broke, first open worked only once, and app background/resume left SHEIN frozen as a still image.
- Explanation for the failure: v85.8.83 closed SHEIN on leaving Otlobli home/background/resume and forced a fresh VPN/Saudi check. That was intended to avoid stale `WKWebView` memory, but on the real device it killed/reopened the browser at fragile moments and destabilized Saudi setup.
- Response: reverted v85.8.83's fresh-session policy, close/open queue, and heartbeat removal. Restored v85.8.82/v85.8.79 preserved-session behavior with the old SHEIN page heartbeat/recovery path.
- Scope stayed narrow: no color, size, capture, add-to-cart, product link normalization, icon sizing, payment, wallet, completed orders, or Temu logic changed.
- GitHub iOS build `29957413860` succeeded from code commit `81ac13c`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.84-rollback-v83-shein-stable-saudi.ipa`.
- v85.8.84 IPA SHA-256: `36C2A08AFB95DAA88D97916DCFB1B6E595664111E59BEEBC7F6D3341E803CB10`.
- Validation: `npm run build`, injected-script parse, `npx eslint src/services/sheinBrowserScript.ts src/config.ts`, `git diff --check`, GitHub iOS build, and embedded IPA marker check passed aside from Windows LF/CRLF warnings.

## 2026-07-22 SHEIN v85.8.82 Stable Saudi + Cart Back Target

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.82 / `APP_VERSION = 2026.07.22-v85.8.82-shein-stable-saudi-back-no-otp-test`.
- User tested v85.8.81 and rejected it: SHEIN opened on Bahrain instead of Saudi, product capture failed because Saudi locking failed, and the page could freeze again after exiting/re-entering without even opening a cart product.
- Decision: v85.8.80/v85.8.81 SHEIN cart-product navigation experiment is rolled back. SHEIN cart products are again opened through the older stable native `InAppBrowser.setUrl()` path from v85.8.79.
- Kept one proven fix only: the Otlobli back target for a SHEIN product opened from cart is no longer overwritten by repeated page-ready messages, so the back button stays bound to Otlobli cart instead of SHEIN history/home.
- Restored v85.8.79 SHEIN stability behavior: page heartbeat, post-ready recovery watchdog, app visibility resets, and the old low-end scan intervals.
- Added a narrow Saudi recovery: if SHEIN local storage contains an explicit non-Saudi `addressCookie` such as Bahrain, only that key is cleared so the existing Saudi seed can take effect again. Signed Saudi address data is not cleared.
- Scope stayed narrow: no color, size, capture, add-to-cart, product parsing, icon sizing, payment, wallet, completed-order, or Temu logic changed.
- GitHub iOS build `29952878400` succeeded from code commit `394bcae`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.82-shein-stable-saudi-back.ipa`.
- v85.8.82 IPA SHA-256: `20763A568A3E399CA59C98A4AF622C2059A62469F8D14893E77A51F1736297E3`.
- Validation: `npm run build`, injected-script parse, `npx eslint src/services/sheinBrowserScript.ts src/config.ts`, targeted `git diff --check`, GitHub iOS build, and embedded IPA marker check passed aside from Windows LF/CRLF warnings.

## 2026-07-22 SHEIN v85.8.81 Cart Back Target Fix

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.81 / `APP_VERSION = 2026.07.22-v85.8.81-shein-cart-back-target-no-otp-test`.
- User tested v85.8.80 and clarified the exact failure: SHEIN cart product opens correctly, but pressing Otlobli back returns inside SHEIN to a categories/home page where products do not render and the page is stuck.
- Corrected root cause: repeated `sheinPageInteractive` messages overwrote the cart-product back target. The product initially set the injected back button to `cart`, but a later readiness message reset/sent `home`, so the button ran SHEIN `history.back()` and landed on SHEIN's broken half-rendered categories state.
- Fix: back target is no longer reset after posting to the WebView. It resets only when the user actually leaves the WebView via Otlobli cart/orders/profile. Cart-opened SHEIN products therefore keep back bound to Otlobli cart.
- Scope stayed narrow: no color, size, capture, add-to-cart, product link, nav/icon sizing, payment, wallet, or order logic changed.
- GitHub iOS build `29946868465` succeeded from code commit `505db9d`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.81-shein-cart-back-target.ipa`.
- v85.8.81 IPA SHA-256: `3A418030C59499B76611B59E0102C72909686954879185E7A9258CCF5E3B7A84`.
- Validation: `npm run build`, injected-script parse, `npx eslint src/services/sheinBrowserScript.ts src/config.ts`, GitHub iOS build, and embedded IPA marker check passed.

## 2026-07-22 SHEIN v85.8.80 Cart Light In-Page Navigation

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.80 / `APP_VERSION = 2026.07.22-v85.8.80-shein-cart-light-nav-no-otp-test`.
- User rejected v85.8.79: the freeze remained and a recovery watchdog was the wrong style of fix. The goal became a cleaner source fix plus lighter behavior on weak phones.
- Root-cause direction: SHEIN cart products were still opened by native `InAppBrowser.setUrl()` deep loads from the cart/hidden preserved WebView. Switching Temu -> SHEIN fixed the freeze by rebuilding the WebView, so the fragile part is the cart-origin native deep product load into the preserved SHEIN session.
- Fix: SHEIN cart products now open like a real in-store tap. If the WebView is cold, load SHEIN home first, keep the pending product URL, then navigate inside the live document with `window.location.assign()` through `executeScript`. Warm cart opens show SHEIN first, then run the same in-page navigation. The v85.8.79 heartbeat watchdog/page heartbeat was removed.
- Low-end adjustment: weak/small devices get slower SHEIN hot scan intervals through a broader `OTLOBLI_LOW_END` detector. Product capture, color, size, add-to-cart, deep links, add validation, and nav/icon sizing were not changed.
- Added `scripts/shein-cart-browser-harness.mjs` for visible browser checks. With the user's SHEIN product URL, desktop automation preserved the URL and got SHEIN home interactive, then SHEIN redirected product navigation to `/risk/challenge` with `humanCheck`. Playwright Chromium is bot-flagged, so CAPTCHA answers there can fail even when the user solves them correctly.
- GitHub iOS build `29944509509` succeeded from code commit `71a3f13`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.80-shein-cart-light-nav.ipa`.
- v85.8.80 IPA SHA-256: `67D53FD87BCFECF606DAFD641CB2AAB657C2EB1084C8401C248432BF150C8AAD`.
- Validation: `npm run build`, injected-script parse, `npx eslint src/services/sheinBrowserScript.ts src/config.ts`, `git diff --check`, GitHub iOS build, and embedded IPA marker checks passed aside from Windows LF/CRLF warnings. Targeted lint including `src/App.tsx` still reports pre-existing unrelated App lint errors.

## 2026-07-22 SHEIN v85.8.79 Ready-Freeze Recovery

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.79 / `APP_VERSION = 2026.07.22-v85.8.79-shein-ready-freeze-recovery-no-otp-test`.
- User report: after opening a SHEIN product from Otlobli cart and backing out to SHEIN home, the page can become visible but untappable. Switching to Temu and back fixes it by rebuilding the WebView.
- Root cause: v85.8.78's heartbeat watchdog called the existing stuck-WebView restart while `sheinReadyRef.current` was true, but that restart function returned immediately for any ready page. The recovery path for post-ready freezes was therefore disabled.
- Fix: `restartStuckSheinWebview()` now accepts `allowReadyRecovery`; the heartbeat watchdog passes `true` so an already-ready frozen SHEIN WebView can be rebuilt after the heartbeat stops. Added a narrow fallback to hide unsolicited product-page SHEIN login dialogs that have no detectable close button, without touching real login routes.
- Scope stayed narrow: SHEIN freeze recovery and SHEIN product auth prompt only. No Temu, payment, wallet, completed orders, SKU capture, cart pricing, or order logic changed.
- GitHub iOS build `29928244012` succeeded from code commit `377f6d5`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.79-shein-ready-freeze-recovery.ipa`.
- v85.8.79 IPA SHA-256: `89677EFA17882DFB02C893FF16447323829A074141DC0C5E937A68771F2A120A`.
- Validation: `npm run build`, injected-script syntax parse, `npx eslint src/services/sheinBrowserScript.ts src/config.ts`, `git diff --check`, GitHub iOS build, and embedded IPA marker checks passed aside from Windows LF/CRLF warnings. Full targeted lint including `src/App.tsx` still reports pre-existing unrelated App lint errors.

## 2026-07-20 Temu v85.8.69 Cart Product Visible Gate

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current iOS candidate: v85.8.69 / `APP_VERSION = 2026.07.20-v85.8.69-temu-cart-product-visible-gate-no-otp-test`.
- Code commit: `b9d6d14` (`fix: v85.8.69 gate Temu cart product reveal`).
- User confirmed ordinary Temu product opens are working again, but tapping a product from Otlobli cart can briefly show Temu login/account UI and then a white screen.
- Fix: the cart-product reveal gate now waits for a `temuProductVisible` message from the injected Temu script instead of trusting native `browserPageLoaded` alone. The script sends that message only when visible product content exists and no visible account/login surface remains; React verifies the visible URL against the pending cart URL before revealing the WebView.
- Scope stayed narrow: Temu cart-product reveal timing only. No SKU capture, add-to-cart logic, header, bottom nav placement, payment, wallet, orders, or real account-route logic changed.
- GitHub iOS build `29735372870` succeeded from code commit `b9d6d14`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.69-temu-cart-product-visible-gate.ipa`.
- v85.8.69 IPA SHA-256: `C66EF04310F50891BA1D1A127E587DBC9A1FF94153CAA5C6E85307F890FCBF4F`.
- Validation: targeted ESLint for script/config, `npm run build`, `git diff --check`, injected-script parse, GitHub build, and embedded IPA marker checks passed.

## 2026-07-20 Temu v85.8.68 Product White-Screen Guard

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current iOS candidate: v85.8.68 / `APP_VERSION = 2026.07.20-v85.8.68-temu-product-white-screen-guard-no-otp-test`.
- Code commit: `091a35f` (`fix: v85.8.68 prevent Temu product white screen`).
- User clarified the failing installed version was v85.8.67: several Temu products opened first, then a later product showed login briefly and became a white page with only the Otlobli back button. v85.8.68 was not installed yet at the time of that report.
- Fix: removed the opaque full-page Temu product-entry cover, while keeping immediate cleanup waves, and added a product-page guard so large non-floating product-flow containers are not hidden as account/promo surfaces during early SPA rendering.
- Scope stayed narrow: Temu product white-screen guard only; no SKU capture, cart flow, header, payment, wallet, orders, or real account-route logic changed. v85.8.67 iPhone 6/iPhone 16 nav logic remains included.
- GitHub iOS build `29733534914` succeeded from code commit `091a35f`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.68-temu-product-white-screen-guard.ipa`.
- v85.8.68 IPA SHA-256: `C26CC0F9EB31B01D105F1F004305E2F16B7F8F47DABF6C89DF5F0B499613337B`.
- Validation: targeted ESLint for script/config, `npm run build`, `git diff --check`, GitHub build, and embedded IPA marker checks passed.

## 2026-07-20 Temu v85.8.67 Modern iPhone Nav Offset

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current iOS candidate: v85.8.67 / `APP_VERSION = 2026.07.20-v85.8.67-temu-modern-iphone-nav-offset-no-otp-test`.
- Code commit: `3a4e2dc` (`fix: v85.8.67 keep modern iPhone Temu nav offset`).
- User report: the iPhone 6 nav fix worked, but Temu bottom nav placement broke on iPhone 16 Pro Max.
- Root cause: inside Temu WKWebView, `env(safe-area-inset-bottom)` can return `0` on iPhone 16 Pro Max, so the v85.8.65 adaptive logic chose the legacy iPhone 6 path.
- Fix: keep `bottom:-18px` when safe-area is present; if safe-area is zero, classify legacy no-home-indicator phones by viewport (`<=414x736` CSS px) and use `0px`; modern tall iPhones fall back to `-18px`.
- Scope stayed narrow: Temu injected bottom-nav vertical placement only. No cart flow, notices, header, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29704696750` succeeded from code commit `3a4e2dc`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.67-temu-modern-iphone-nav-offset.ipa`.
- v85.8.67 IPA SHA-256: `1A9CF7A06D25ADF48A91EF71C0F037A09187AA49511348F41ACBCCD1C7E16451`.
- Validation: targeted ESLint for script/config, viewport logic check, `npm run build`, `git diff --check`, GitHub build, and embedded IPA marker checks passed.

## 2026-07-19 Temu v85.8.66 Cart Product Open + Notice Polish

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current iOS candidate: v85.8.66 / `APP_VERSION = 2026.07.19-v85.8.66-cart-product-open-notice-polish-no-otp-test`.
- Code commit: `3648898` (`fix: v85.8.66 open cart products and polish notices`).
- User report: from Otlobli cart, tapping a product did not open it; also product/add notices looked too framed/heavy.
- Fix: pending product URLs loaded as the initial hidden WebView page now mark navigation requested for all stores, not only SHEIN, and the open promise no longer hides a fast-revealed cart product.
- Polish: React toast and injected browser messages now use lighter dark snackbar text surfaces with Cairo/system font, safe-area bottom positioning, and no old yellow border. The product verification overlay is text-only instead of a white framed card.
- Scope stayed narrow: cart-product open flow and notice visuals only. No payment, wallet, orders logic, account route, Temu header, bottom nav placement, or SKU gate changes.
- GitHub iOS build `29700181145` succeeded from code commit `3648898`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.66-cart-product-open-notice-polish.ipa`.
- v85.8.66 IPA SHA-256: `943C7862779CA9284855C3DD717CC93BA9B1229C87D8D799CC768CF3F435953D`.
- Validation: targeted ESLint for script/config, `npm run build`, `git diff --check`, GitHub build, and embedded IPA marker checks passed. Targeted `src/App.tsx` lint still reports pre-existing unrelated project lint issues; full build passes.

## 2026-07-19 Temu v85.8.65 Legacy Safe-Area Nav

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current iOS candidate: v85.8.65 / `APP_VERSION = 2026.07.19-v85.8.65-temu-legacy-safe-area-nav-no-otp-test`.
- Code commit: `d3b2be2` (`fix: v85.8.65 align Temu nav on legacy iPhones`).
- User tested v85.8.64 on iPhone 16 Pro Max and iPhone 6. iPhone 16 nav alignment was good, but on iPhone 6 the Temu bottom nav sat differently than the React Orders nav.
- Screenshot measurement found a 36 physical pixel / 18 CSS px vertical difference on iPhone 6, matching the old universal Temu `bottom:-18px` offset.
- Fix: Temu nav placement now depends on actual `env(safe-area-inset-bottom)`: modern iPhones with bottom safe area keep `-18px`, legacy iPhones with no bottom safe area use `0px`, and Android keeps the previous `-18px` behavior.
- Scope stayed narrow: Temu injected bottom-nav vertical placement only. No header, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29697979381` succeeded from code commit `d3b2be2`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.65-temu-legacy-safe-area-nav.ipa`.
- v85.8.65 IPA SHA-256: `FDBA2940D03E7962193C416CCB11F93B7838D5F157DBC3BDBE78BAEE3F21CECF`.
- Validation: screenshot pixel comparison, targeted ESLint for script/config, injected-script parse, safe-area logic check, `git diff --check`, `npm run build`, GitHub build, and embedded IPA marker checks passed. Final acceptance still requires the real iPhone 6 and iPhone 16 check.

## 2026-07-19 Temu v85.8.64 Items Selector Row + Cart Product Open

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current iOS candidate: v85.8.64 / `APP_VERSION = 2026.07.19-v85.8.64-temu-items-row-cart-open-no-otp-test`.
- Code commit: `d7cd70f` (`fix: v85.8.64 detect Temu items selector row`).
- User-provided Temu DOM showed a smart-watch selector as `skuSelector-* role="button" aria-label="7 أغراض:حدد"`. The existing structural parser saw the selector shell but did not count `أغراض`, so the product could be treated like it had no required options.
- Fix: centralized Temu counted-variant label detection and reused it in the summary, collapsed-row, and structural `skuSelector-*` paths. Second-option labels now include size/model/style/type/RAM/storage plus `أغراض/اغراض/غرض/عناصر/عنصر/قطع/قطعة/items/pieces/pcs`.
- Includes v85.8.63 underneath: Temu products opened from Otlobli cart now reveal after WebView page load instead of staying white.
- Scope stayed narrow: Temu SKU/variant detection and cart product reveal only. No header, bottom nav, blocker, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29672118803` succeeded from code commit `d7cd70f`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.64-temu-items-row-cart-open.ipa`.
- v85.8.64 IPA SHA-256: `81C48D748AB0A5C219BA585FF84A46E1219AAAB6C349EA3BF53BBF340C0882C7`.
- Validation: pasted-DOM check extracts `7 أغراض` as `secondCount=7`, targeted ESLint for script/config, injected-script parse, `git diff --check`, `npm run build`, GitHub build, and embedded IPA marker checks passed. Final acceptance still requires the real iPhone.

## 2026-07-19 Temu v85.8.62 Single Model Selector Row

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.62 / `APP_VERSION = 2026.07.19-v85.8.62-temu-single-model-row-no-otp-test`.
- User screenshot showed a WEEME Temu product with `4 الموديل: ...` and `حدد`, while the diagnostic overlay reported `sku: لا خيارات`.
- Fix: added a narrow collapsed-row detector for visible `حدد/select/choose` rows with counted variant labels, so model-only selectors are opened and required before add-to-cart.
- Scope stayed narrow: Temu SKU detection only. No bottom nav, header, blockers, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29670967272` succeeded from code commit `0e7882c`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.62-temu-single-model-row.ipa`.
- v85.8.62 IPA SHA-256: `5A23674D464277D424C6D961A3190179638FF86D4B22A45804B8A6939B3D4B5B`.
- Validation: targeted ESLint for script/config, `npm run build`, screenshot-pattern regex check, injected-script parse, `git diff --check`, GitHub build, and embedded marker check passed. Final acceptance still requires the real iPhone.

## 2026-07-19 Temu v85.8.61 Disabled Child SKU Options

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.61 / `APP_VERSION = 2026.07.19-v85.8.61-temu-disabled-child-sku-no-otp-test`.
- User pasted DOM after pressing an unavailable Temu option. The real marker is inside the radio option: inner class `disabled-*` while the `role="radio"` shell remains present.
- Fix: `temuOptionUnavailable()` now checks disabled/sold-out/out-of-stock child markers inside radio/ARIA choice shells, so unavailable options are not captured as selected and do not satisfy add-to-cart validation.
- Scope stayed narrow: Temu SKU availability only. No bottom nav placement, header forcing, blockers, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29668801470` succeeded from code commit `480b2b1`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.61-temu-disabled-child-sku.ipa`.
- v85.8.61 IPA SHA-256: `7EAECBC0F233250E4379859CA581EB13099660FD4836E059FD93905ACECCC5D5`.
- Validation: targeted ESLint for script/config, `npm run build`, injected-script parse, pasted-DOM radio extraction, `git diff --check`, GitHub build, and embedded marker check passed. Final acceptance still requires the real iPhone.

## 2026-07-18 Temu v85.8.58 Nav Raised Slightly

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.58 / `APP_VERSION = 2026.07.18-v85.8.58-temu-nav-bottom-offset-18-no-otp-test`.
- User report after v85.8.57: Temu bottom nav needs to be raised a tiny bit.
- Fix: changed only the Temu nav container offset from `bottom:-22px` to `bottom:-18px`.
- Scope stayed narrow: no WebView show/hide change, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29658975318` succeeded from code commit `6cd9aa6`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.58-temu-nav-bottom-offset-18.ipa`.
- v85.8.58 IPA SHA-256: `6D1D060D03404F9546AC513B2AD85993A347D2A5938A6B378EA1050028AC0401`.
- Validation: targeted ESLint for script/config, injected-script parse plus `bottom:-18px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.58 marker/offset checks passed. Final acceptance still requires the real iPhone.

## 2026-07-18 Temu v85.8.57 Nav Matched From Screenshots

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.57 / `APP_VERSION = 2026.07.18-v85.8.57-temu-nav-bottom-offset-22-no-otp-test`.
- User provided side-by-side real-device screenshots for Temu product page and React Orders nav. Pixel measurement showed the Temu nav top/indicator band around 9-10px higher than Orders.
- Fix: changed only the Temu nav container offset from `bottom:-12px` to `bottom:-22px`.
- Scope stayed narrow: no WebView show/hide change, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29658557163` succeeded from code commit `a0d4b0d`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.57-temu-nav-bottom-offset-22.ipa`.
- v85.8.57 IPA SHA-256: `00C83CA2EB2BCB2F506525C5B7AF63BC3D1F697E88358BD690B4E301124AF209`.
- Validation: targeted ESLint for script/config, injected-script parse plus `bottom:-22px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.57 marker/offset checks passed. Final acceptance still requires the real iPhone.

## 2026-07-18 Temu v85.8.56 Nav Lowered Slightly More

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.56 / `APP_VERSION = 2026.07.18-v85.8.56-temu-nav-bottom-offset-12-no-otp-test`.
- User report after v85.8.55: Temu bottom nav is closer but still needs to move down a little more.
- Fix: changed only the Temu nav container offset from `bottom:-8px` to `bottom:-12px` and bumped the injected nav style version.
- Scope stayed narrow: no WebView show/hide change, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29657864109` succeeded from code commit `9674808`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.56-temu-nav-bottom-offset-12.ipa`.
- v85.8.56 IPA SHA-256: `D916588CFE9C45E2C0B5764F18179AE65216EF4DF6D8854770F47E2CD0ED378A`.
- Validation: targeted ESLint for script/config, injected-script parse plus `bottom:-12px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.56 marker/offset checks passed. Final acceptance still requires the real iPhone.

## 2026-07-18 Temu v85.8.55 Nav Bottom Offset

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.55 / `APP_VERSION = 2026.07.18-v85.8.55-temu-nav-bottom-offset-no-otp-test`.
- User rejected v85.8.54 on real iPhone: the Temu injected nav still sits higher than the React nav in Orders/Cart.
- Fix: removed the Temu-only `translate3d(-50%,4px,0)` offset and lowered the actual Temu nav container with `bottom:-8px`, while keeping the normal `translate3d(-50%,0,0)` transform so the stability CSS is no longer fighting the position.
- Scope stayed narrow: no WebView show/hide change, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29657616560` succeeded from code commit `eb7b0ca`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.55-temu-nav-bottom-offset.ipa`.
- v85.8.55 IPA SHA-256: `52ED888B77AF294970B6CC7E19557131CDC848B3A29D79E4C40B3D3E93FF1F16`.
- Validation: targeted ESLint for script/config, injected-script parse plus `bottom:-8px` marker check, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.55 marker/offset checks passed. Final acceptance still requires the real iPhone.

## 2026-07-18 Temu v85.8.54 Nav Bar Alignment

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.54 / `APP_VERSION = 2026.07.18-v85.8.54-temu-nav-bar-lower-no-otp-test`.
- User report after v85.8.53: the whole Temu injected bottom nav, including the active indicator/icons/labels, sits slightly higher than the React nav in Orders/Cart.
- Fix: removed the v85.8.53 icon/label-only offset and applied a single Temu-only `translate3d(-50%,4px,0)` to `#otlobli-nav`, moving the entire injected bar together.
- Scope stayed narrow: no WebView show/hide change, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29657282400` succeeded from code commit `d0c13f4`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.54-temu-nav-bar-lower.ipa`.
- v85.8.54 IPA SHA-256: `00127450AE6E228DE3A07DFDADF71B2788E48071149C44357DF220D21FA0003D`.
- Validation: targeted ESLint for script/config, injected-script parse, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.54 marker check passed. Final acceptance still requires the real iPhone.

## 2026-07-18 Temu v85.8.53 Nav Content Alignment

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.53 / `APP_VERSION = 2026.07.18-v85.8.53-temu-nav-content-lower-no-otp-test`.
- User confirmed v85.8.52 fixed the blank/grey strip under Temu's bottom nav. New narrow report: the injected Temu nav content is slightly higher than the React nav in Orders/Cart.
- Fix: added a Temu-only 3px visual downward offset for injected nav SVG icons and labels. The nav container, safe-area height, active indicator, and hit targets are unchanged.
- Scope stayed narrow: no WebView show/hide change, Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29656814832` succeeded from code commit `0009f24`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.53-temu-nav-content-lower.ipa`.
- v85.8.53 IPA SHA-256: `089DE99FED0E44E278CB443323A3C486E5212E0F5A276594B84413D2FD44A8E9`.
- Validation: targeted ESLint for script/config, injected-script parse, `git diff --check`, `npm run build`, GitHub build, and embedded v85.8.53 marker check passed. Final acceptance still requires the real iPhone.

## 2026-07-18 Temu v85.8.52 Bottom Nav Preserve

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.52 / `APP_VERSION = 2026.07.18-v85.8.52-temu-preserve-webview-nav-no-otp-test`.
- User report after v85.8.51: the Temu bottom nav still showed a blank/grey strip underneath after navigating to Orders and returning Home; Orders itself had the correct React nav spacing.
- Fix: Temu on iOS now keeps the WKWebView attached while hidden using the existing native `otlobliPreserveAttachedWhenHidden` path, avoiding the 1x1 detach/reattach cycle that can disturb viewport/safe-area sizing.
- Fix: removed the Temu-only delayed resume `__resize` messages from v85.8.51 to avoid layout motion/flicker after returning Home.
- Scope stayed narrow: no Temu header forcing, blockers, product/SKU capture, payment, wallet, orders logic, or account route changes.
- GitHub iOS build `29656122048` succeeded from code commit `92461f2`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.52-temu-preserve-webview-nav.ipa`.
- v85.8.52 IPA SHA-256: `26FC0A8B5C288EE11D7A877A4EB1DABC6DCFB945089EC09398E8F844340E429A`.
- Validation: `npm run build`, `git diff --check`, GitHub build, and embedded v85.8.52 marker check passed. Targeted ESLint against `App.tsx` still reports old unrelated App lint errors. Final acceptance still requires the real iPhone.

## 2026-07-18 Temu v85.8.51 Native Header Rollback

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.51 / `APP_VERSION = 2026.07.18-v85.8.51-temu-native-header-resume-gap-no-otp-test`.
- User rejected v85.8.50 on real iPhone: the Temu top bar became laggy/stuttery and load felt slower.
- Action: removed execution and code for the v85.8.49/v85.8.50 Temu header interventions: no header pinning, no category wake/forcing, no download-shell collapse, and no empty-gap DOM scan inside Temu.
- Fix attempt for remaining gap: when returning from React tabs to Temu home, native posts two delayed `__resize` messages so WKWebView recalculates layout without touching Temu's header DOM.
- Scope stayed narrow: no product capture/SKU logic, payment, wallet, orders logic, account route, or blocker redesign.
- GitHub iOS build `29655425599` succeeded from code commit `aa2f287`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.51-temu-native-header-resume-gap.ipa`.
- v85.8.51 IPA SHA-256: `EEE8BA63452CDACB03AC8FB6502C3DEB97258FDBB9C99BECC9297EB87503FFA6`.
- Validation: targeted ESLint for injected script/config, injected-script parse, `npm run build`, GitHub build, and embedded v85.8.51 marker check passed. Real-device acceptance is still pending.

## 2026-07-18 Temu v85.8.50 Category Header Stabilization

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.50 / `APP_VERSION = 2026.07.18-v85.8.50-temu-category-header-stable-no-otp-test`.
- User report after v85.8.49: Temu search row is better, but categories can stay hidden until a sideways/pull gesture; after product/back an empty gap can appear below the header.
- Fix: normalize only the verified top Temu category row and wake its horizontal scroller without vertical pull/scroll nudges.
- Fix: collapse only empty top header gaps on Temu home and restore them automatically if content later appears.
- Scope stayed narrow: no product capture/SKU logic, payment, wallet, orders, account route, or blocker redesign.
- GitHub iOS build `29654853138` succeeded from code commit `471809a`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.50-temu-category-header-stable.ipa`.
- v85.8.50 IPA SHA-256: `F66B240EDCB94EFA278C2C6E611428343BAFABC76A23A678E5E5E4031A6FE8EC`.
- Validation: targeted ESLint, injected-script parse, `git diff --check`, `npm run build`, WebKit fixture for hidden categories + empty header gap, GitHub build, and embedded v85.8.50 marker check passed. Real-device acceptance is still pending.

## 2026-07-18 Temu v85.8.49 SHEIN-Like Header

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.49 / `APP_VERSION = 2026.07.18-v85.8.49-temu-shein-like-header-no-otp-test`.
- User asked to start with one issue: make Temu's top bar match SHEIN's stable bar.
- Fix: collapse only Temu app-download banner shells/ancestors that do not contain search chrome, removing the blank white top strip after the banner is hidden.
- Fix: call the narrow existing Temu header stabilizer so the fixed header keeps Y=0 outside active search and releases during active search.
- Scope stayed narrow: no product capture/SKU logic, payment, wallet, orders, account route, or broad blocker redesign.
- Validation: targeted ESLint, injected-script parse, `git diff --check`, `npm run build`, and WebKit mobile DOM checks. Real-device acceptance is still required.

## 2026-07-18 Temu v85.8.48 Emergency Rollback

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- User rejected v85.8.47 on a real iPhone: Temu product pages became blank white again and the header issue remained unresolved.
- Action: reverted commit `ae51ae8` (`fix: v85.8.47 capture Temu single style option`) and bumped the version to `2026.07.18-v85.8.48-temu-rollback-47-no-otp-test`.
- Runtime goal: return Temu product behavior to v85.8.46 before doing any new SKU/header work.
- Scope stayed narrow: no payment, wallet, orders, account route, header, or blocker redesign change was added in this rollback.
- Next real-device check: install v85.8.48 and verify product pages are not blank white. Treat v85.8.47 as rejected until a true reproduction explains the regression.

## 2026-07-17 Temu v85.8.31 Product Panel And Text Color

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.31 / `APP_VERSION = 2026.07.17-v85.8.31-temu-product-panel-color-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.31-temu-product-panel-color.ipa`.
- Build run: `29589915204` (success), built from code commit `81426c7`.
- IPA SHA-256: `C6E8DA038BC4CB9E7363222E17452F24678B169B6FB729675C5CACFBD937CBCC`.
- User report after v85.8.30: some Temu product pages could become blank white while Otlobli back/add buttons remained, and a product with text-only color `اللون: اسود و ابيض` was blocked by "select color".
- Fix: removed early static hiding of live Temu `panel/adaptPad`/sign-in/guide classes; login/account panels are still hidden by the dynamic cleaner after checks.
- Guard: dynamic account hiding now skips clear product content with price, product text, or large Temu images.
- Fix: a selected text-only color can pass the add gate without requiring a swatch image; product image fallback remains used for the cart image.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit fixtures for product-panel visibility, dynamic account-panel hiding, and text-only color add, GitHub unsigned iOS build, embedded v85.8.31 marker check.
- No simulator was used. Final acceptance is still real-device only.

## 2026-07-17 Temu v85.8.30 No False Size Gate

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.30 / `APP_VERSION = 2026.07.17-v85.8.30-temu-no-false-size-gate-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.30-temu-no-false-size-gate.ipa`.
- Build run: `29587915183` (success), built from code commit `dcc2bb5`.
- IPA SHA-256: `4804EB86912DAD859BC389819C351ABD74A58795E957286BE36E6FAD4C6DF747`.
- User report after v85.8.29: some Temu products have no size options, only color/quantity, but Otlobli still asked to select size.
- Fix: the second-option block now requires real option pills or a variant summary count greater than one; a suspicious heading alone is not enough.
- Fix: text-only single-color products such as `اللون: لون فضي` pass and capture the color text without requiring a swatch image.
- Checked v80 (`db7dfb8`): it does not include RAM/memory support and still uses the older broad size-section gate, so it was not restored.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit fixtures for no-size, text-only color, and RAM summary gating, GitHub unsigned iOS build, embedded v85.8.30 marker check.
- No simulator was used. Final acceptance is still real-device only.

## 2026-07-17 Temu v85.8.29 RAM Variant Gate

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.29 / `APP_VERSION = 2026.07.17-v85.8.29-temu-ram-variant-gate-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.29-temu-ram-variant-gate.ipa`.
- Build run: `29586606771` (success), built from code commit `74e2c0f`.
- IPA SHA-256: `6EB037D772BD6FBF6BB0E2264A61AA323A13E6177FA431EE238CD73A548847C5`.
- User report after v85.8.28: Temu search is now good, but product capture/add-to-cart could add directly even when required options like color and RAM/memory existed.
- Fix: Temu variant summary detection now treats RAM/memory/storage/capacity labels, including Arabic `ذاكرة الوصول العشوائي`, as a required second option dimension.
- Guard: pressing Otlobli add on a product summary such as `3 اللون, 1 ذاكرة الوصول العشوائي` opens/clicks the `حدد` variant row and does not post `addToCart` before selection.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized product fixture, GitHub unsigned iOS build, embedded v85.8.29 marker check.
- No simulator was used. Final acceptance is still real-device only.

## 2026-07-17 Temu v85.8.28 Search Preserve Query

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.28 / `APP_VERSION = 2026.07.17-v85.8.28-temu-search-preserve-query-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.28-temu-search-preserve-query.ipa`.
- Build run: `29584752961` (success), built from code commit `c7c49d5`.
- IPA SHA-256: `2AFC1C27164E1023493632323B0F1F7992ACC16B3C6294BB9E7CFE54B97C8BCB`.
- User report after v85.8.27: in Temu search/results, account/cart/menu and Temu bottom nav were visible; tapping Otlobli back while a query existed could clear the text.
- Fix: added a narrow search-only cleanup that hides compact top account/cart/menu controls and Temu's fixed bottom nav during search/results.
- Guard: Temu's native search back button and suggestion/search text stay visible; the broad JS text/geometry blocker still skips active search.
- Fix: Otlobli search exit preserves a focused or populated search query instead of clearing it.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized search/results fixture, GitHub unsigned iOS build, embedded v85.8.28 marker check.
- No simulator was used. Final acceptance is still real-device only.

## 2026-07-17 Temu v85.8.27 Search Light Blockers

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.27 / `APP_VERSION = 2026.07.17-v85.8.27-temu-search-light-blockers-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.27-temu-search-light-blockers.ipa`.
- Build run: `29583256531` (success), built from code commit `d9368b4`.
- IPA SHA-256: `9B706F650718BA25A7D3E9B61CACB54AAAC873DA492FD5F11CA81866EE2A3826`.
- User report after v85.8.26: Temu search sometimes hid words/letters, and the search back button was hidden.
- Fix: removed active calls to `restoreTemuSearchBackControls`, including Otlobli search exit, so Temu's native search back button stays visible.
- Fix: `otlobliCleanTemuBlockers` now returns immediately while Temu search mode is active, preventing text/geometry blocker matches from hiding suggestions containing words like offer/deal/cart/bag.
- Static CSS blockers remain active, so account/cart/app/offers already hidden before search stay hidden.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit search-mode fixture for visible back/suggestions, GitHub unsigned iOS build, embedded v85.8.27 marker check.
- No simulator was used. Final acceptance is still real-device only.

## 2026-07-17 Temu v85.8.26 Clean Blockers Reset

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.26 / `APP_VERSION = 2026.07.17-v85.8.26-temu-clean-blockers-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.26-temu-clean-blockers.ipa`.
- Build run: `29581021125` (success), built from code commit `e3984fd`.
- IPA SHA-256: `DD22DFD3CE658E056F652F140B6AEA5FEAC8A5CA1193DDAEEEDE557BA0864C2B`.
- v85.8.25 was still rejected: Temu was too heavy/unstable, category row could gap/hide, and old blocker/header/search interventions were still risky.
- Fix: active Temu now uses one cleaner that hides only account/login, cart/basket, app-download/open-app, and promo/offer/coupon sheets.
- Removed from active Temu path: header/search/category pinning/restoring/forcing, broad customer chrome hiding, broad account/sheet scans, and login-popup clicking.
- Guard fixes: search inputs/triggers, category rows, product grids, prices, and image-heavy product content are protected; the old broad `near search input` guard no longer protects unrelated floating offer sheets; generic `category/nav/menu` matching is no longer used as promo detection.
- Performance: Temu cleanup interval is relaxed to `1200ms` / `1800ms` on low-end devices.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, iPhone-6-sized WebKit blocker harness, GitHub unsigned iOS build, embedded v85.8.26 marker check.
- Live Temu headless redirected to a download, so final acceptance still requires installing on the real iPhone. No simulator was used.

## 2026-07-17 Temu v85.8.25 Search No-Motion Fix

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.25 / `APP_VERSION = 2026.07.17-v85.8.25-temu-search-no-motion-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.25-temu-search-no-motion.ipa`.
- Build run: `29578629966` (success), built from code commit `806b7d7`.
- IPA SHA-256: `75C0A98B98B504EFFCB409AE432A56E689A1E5911198C5B7F0BCF7029E6CEC41`.
- v85.8.24 was rejected on real device: search sometimes needed multiple taps, the search bar moved while typing, the category strip was half-hidden during search, and home size broke after exit.
- Fix: removed the v85.8.24 active search shell/frame marking path and all search-mode `transform`/`min-height`/`margin-top` CSS; category-strip forcing is now disabled while search mode is active.
- Back handling: Otlobli back now uses a short focus-loss grace window so tapping the back button still exits search even if focus leaves the input first, then clears that grace immediately on exit.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit browser harness for one-tap search -> stable typing -> Otlobli back -> home, GitHub unsigned iOS build, embedded v85.8.25 marker check.
- Live Temu in headless WebKit was attempted but Temu redirected to a download, so it was not used as proof.

## 2026-07-17 Temu v85.8.24 Search Layout Fix

- Rejected on real device. Kept for history only.
- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.24 / `APP_VERSION = 2026.07.17-v85.8.24-temu-search-layout-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.24-temu-search-layout.ipa`.
- Build run: `29577463207` (success), built from code commit `b061da5`.
- IPA SHA-256: `15A3FD16D00F8BB04316D05A70F55FA54DCB90EDABF21AF5B96249E4637E9426`.
- Scope: only the follow-up Temu search layout issues after v85.8.23: search bar clipped from the bottom on entry, and home header/category shape breaking after backing out.
- Fix: active Temu search now marks a scoped search shell plus nearest frame, expands only that frame temporarily, and lowers the shell with `transform` instead of the old layout-changing `margin-top`.
- Home return: Otlobli search-back clears active search shell/frame markers and restarts a bounded home-header wake window even when the URL stays the same, with one extra delayed reset for low-end iPhones.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone 6-sized clipped-search -> Otlobli-back -> home fixture, GitHub unsigned iOS build, embedded v85.8.24 marker check.
- Next real-device check: install v85.8.24 and verify only this loop before moving to any next issue.

## 2026-07-17 Temu v85.8.23 Search Exit Home Fix

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.23 / `APP_VERSION = 2026.07.17-v85.8.23-temu-search-exit-home-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.23-temu-search-exit-home.ipa`.
- Build run: `29554026083` (success), built from code commit `47bdfaa`.
- IPA SHA-256: `119DA708BE544BD2AF2CA74F0EE1C33F482A4A969ACFD66BAA025B3A67F87857`.
- Scope: only the first new issue, where Temu home looked correct on first entry but broke after entering search and returning home.
- Fix: Otlobli back from Temu search remembers/falls back to the last search input, clears it, dispatches `input/search/change`, briefly suppresses stale search-mode, and hides only search suggestion/recent/trending overlays from that session.
- Guard: search suggestion overlays are marked so Temu search/category restoration cannot revive them as category strips; category detection now excludes search/suggest/trending text.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized home -> search -> back fixture, GitHub unsigned iOS build, embedded v85.8.23 marker check.
- Next real-device check: install v85.8.23 and verify only home -> search -> back returns to the same clean home layout before moving to the second issue.

## 2026-07-17 Temu v85.8.22 GitHub Build

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.22 / `APP_VERSION = 2026.07.17-v85.8.22-temu-focused-search-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.22-temu-focused-search.ipa`.
- Build run: `29553022990` (success), built from code commit `8b665ed`.
- IPA SHA-256: `1233327C658582DA8D4B11EFF5D621CC4728B13C132CEC93D3AF52391B14CEB5`.
- Temu focus: category strip visible from first entry, cleaner header/search state, faster focused search path, no login/account or available-offers interruption during search/back.
- Implementation is targeted: verified category strips get `display:flex`; focused searchboxes count as Temu search mode; the active search shell is lowered 18px; Temu native search back is hidden; Otlobli back exits search without opening Temu offer sheets.
- Real Temu account routes are preserved when opened intentionally; account-route WebKit fixture passed.
- iOS splash PNGs are blank white so the blue splash logo should not show in the app switcher/background preview.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized home/search/back fixture, WebKit account-route fixture, GitHub unsigned iOS build, embedded v85.8.22 marker check.
- Do not use the simulator for final judgment; install on the real iPhone 6/iPhone 16. Do not touch payment, wallet, completed orders, or account-route logic unless explicitly requested.

## 2026-07-17 Temu v85.8.21 Local Update

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.21 / `APP_VERSION = 2026.07.17-v85.8.21-temu-category-search-account-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.21-temu-category-search-account.ipa`.
- Build run: `29551174390` (success), built from code commit `603c902`.
- IPA SHA-256: `E42467AD3BB2F13E6F82E0638AB8AE04846C9036514E94B497E4B2018E53CA1E`.
- Focus stayed Temu-only: first-entry category strip, header startup stability, search typing/focus, and login/account panel removal outside real account routes.
- Fixed early WebKit document-start aborts by guarding Cairo font injection and deferring the MutationObserver until a root node exists.
- Added a bounded Temu home wake nudge that triggers the same tiny scroll/resize path needed to reveal categories, then returns to top.
- Hid Temu account/login surfaces by observed live WebKit/iPhone classes and removed the heavy 90ms full-page account text scan to keep typing responsive.
- Validation passed: `git diff --check`, targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized live smoke, and a routed Temu fixture reproducing hidden categories plus recreated account panels.
- Do not use the simulator for final judgment; install the GitHub-built IPA on the real iPhone. Do not touch payment, wallet, completed orders, or real account routes unless explicitly requested.

## 2026-07-17 Temu v85.8.20 Local Update

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Last real-device Temu IPA tested: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.19-temu-search-keyboard.ipa`.
- Last tested commit: `0426529` (`fix: v85.8.19 keep Temu search keyboard open`).
- v85.8.19 is not fixed: Temu still shows an empty/white header band, search typing is slow/unstable, and the login/account panel can appear over search and keyboard.
- Current local candidate: v85.8.20 / `APP_VERSION = 2026.07.17-v85.8.20-temu-header-search-login-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.20-temu-header-search-login.ipa`.
- Build run: `29543466932` (success), built from code commit `5a5b0c6`.
- IPA SHA-256: `16EFD9C2C1C38FE88C87404CF24BD157A1DC7DED4B265CF914BCE5FC4C9BEEC5`.
- Local changes are limited to Temu in `src/services/sheinBrowserScript.ts`: broader live search-input detection, short search-mode probe cache, safer search chrome restoration that avoids account panel ancestors, search-only login panel re-hide, and less aggressive home-header forcing.
- Do not use the simulator for final judgment; test on the real iPhone. Do not touch payment, wallet, completed orders, or account route logic unless explicitly requested.

انسخ هذا لأي شات جديد قبل المتابعة. آخر تحديث: 2026-07-16.

## المسار والفرع والبناء

```text
C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA
```

- الفرع النشط: `claude/ios6-cover-fix` — قاعدة نظيفة على commit `e8842d8`.
- الأساس المستقر: **v85.8.12** (commit `129630e`). نُسخ احتياطية: فرع `backup-v85.8.14-state` + تاجات `backup-before-8.12-revert` و`backup-v85.8.20-broken`.
- **iOS**: يُبنى عبر GitHub Actions فقط: `gh workflow run ios-unsigned-build.yml --ref claude/ios6-cover-fix` ثم تنزيل artifact `otlobli-ios` ووضعه على سطح المكتب. لا Mac محلي.
- **Android (للاختبار الحي)**: متوفّر ويعمل! `emulator` في `C:\Users\MOHAMMAD\AppData\Local\Android\Sdk\emulator`، AVD اسمه `Pixel_7_API_35_Test`، الحزمة `com.otlobli.app`. البناء: `npm run build && npx cap sync android && cd android && ./gradlew assembleDebug` ثم `adb install -r ...`. الاختبار: `adb shell input tap/text` + `adb exec-out screencap`.
- **مفتاح الـ relay السري**: في `.env.relay.local` (gitignored). قبل بناء Android محلياً شغّل `node scripts/inject-relay-key.cjs` (يقرأه تلقائياً) ثم `npx cap sync android`. **ممنوع** إعادة توليد الباتش بعد الحقن (يسرّب المفتاح). الباتش المُلتزَم يجب أن يبقى فيه `OTLOBLI_RELAY_KEY_PLACEHOLDER`.
- OTP معطّل في نسخ الاختبار (`no-otp-test`) — يُستعاد قبل الإنتاج.

## أهم درس تشغيلي

الشات صار طويلاً جداً وجودة العمل تدهورت (تغييرات كسرت ثم تراجعات). **ابدأ من هنا بشات نظيف.** واختبر على محاكي أندرويد الحي قبل ادعاء الإصلاح — لا تخمين.

## ما تأكّد إصلاحه (على iOS، نُسخ محفوظة على سطح المكتب)

1. رجوع المشروع من v85.8.20 المكسور إلى v85.8.12.
2. قبول كوكيز شي إن تلقائياً (`otlobliForceAcceptCookies` + `sheinSkuSelectionPending`) — تأكّد.
3. إكمال اختيار منطقة السعودية على iPhone 6 حتى الخيار الأخير.
4. تسريع تحقّق أمان شي إن (`otlobliChallengeActive` يوقف فحوصاتنا أثناء تحدي Cloudflare).
5. غطاء تحميل ذكي: iPhone 16 (safe-area>0) يبقى الشريط ظاهراً؛ iPhone 6 (safe-area=0) غطاء كامل.
6. تخفيف الفحوصات على الأجهزة الضعيفة (`OTLOBLI_LOW_END`).
7. إصلاح جذب المتغيّر: `getSizeOptions` رفع حد الطول 12→40 + كشف «انقر للشراء».
8. الشريط السفلي يتوقف عن سرقة النقر عند فتح درج شي إن (`otlobliApplyNavYield`).
9. تيمو: mojibake «بحث» أُصلح؛ حارس VPN لتيمو (`temuContentLoadedRef` يمنع بوابة كاذبة على أخطاء الموارد الفرعية).

## مشاكل تيمو المعلّقة (من اختبار المستخدم + المحاكي الحي)

كلها في `src/services/sheinBrowserScript.ts` (كتلة `if (IS_TEMU)` داخل `tick()`، ودوال `otlobliTemuSearchMode`/`stabilizeTemuSearchChrome`/`ensureBackButton`/`ensureOtlobliNav`).

1. **الكتابة تغلق البحث**: عند كتابة أي حرف في بحث تيمو، تُغلق شاشة البحث وترجع للرئيسية. مؤكّد على المحاكي (adb text و keyevent كلاهما). **لا يوجد تنقّل/إعادة تحميل** (logcat). السبب من كودنا لكن لم يُحدَّد بعد. مرشّحون: `ensureViewportFitCover` (logcat يسبّم ViewportFitCover)، أو `ensureOtlobliNav` إعادة إلحاق النود، أو تدخّل على الحقل يفقده التركيز. **الأولوية القصوى** (بلا كتابة البحث عديم الفائدة).
2. **زر الرجوع غير مستقر**: يظهر/يختفي بتكرار على تيمو. سببه `otlobliTemuSearchMode` يتذبذب (تركيز/قيمة) + `ensureBackButton` كل tick.
3. **عمليات البحث الأخيرة + الاقتراحات تُحجب**: دوال إخفاء كروم تيمو تبتلعها لمّا الحقل فارغ/غير مركّز. جرّبتُ حلاً (`otlobliTemuHasProductGrid`: علّق الحجب لمّا لا توجد شبكة منتجات) ونجح لإظهارها لكن يُشتبه بأنه فاقم الكتابة — **أُلغي** ويحتاج إعادة تطبيق بحذر مع اختبار الكتابة.
4. **وميض الحجب**: عناصر تيمو تظهر ثم تُحجب بعد ~ثانية (الحجب على tick تدريجي).
5. **شريط البحث العلوي غير ثابت**: يتحرك بالتمرير وأحياناً يستقر لحظة ثم يتحرك. `stabilizeTemuSearchChrome` يُشتبه أنه يزيحه لمنتصف الشاشة أحياناً. محاولة تثبيت الهيدر بـ `transform:translateY(0)!important` **كسرت التخطيط أفقياً** (أُلغيت). ملاحظة DOM: الشريط داخل هيدر `position:fixed` (`._2UbxPzJy`) يخفي نفسه بالنزول عبر transform إنلاين (سلوك موبايل).
6. **الشريط السفلي (شريط التطبيق) يتحرك عند overscroll**: عند السحب لأقصى أعلى/أسفل، الشريط السفلي وكلماته (الرئيسية/طلباتي/السلة/حسابي) تُسحب لأسفل. يحتاج تثبيت أقوى (overscroll-behavior / native inset).
7. **الشريط السفلي يجب أن يكون «ذكياً» حسب نظام تنقّل الهاتف**: يكتشف إن كان الهاتف بأزرار تنقّل (Android buttons) أو إيماءات (iPhone-like)، ويحجز الـ inset الحقيقي ويأخذ الحجم المناسب لكل شاشة (يعتمد على مقاس الشاشة و safe-area الفعلي). حالياً يعتمد على `max(env(safe-area-inset-bottom),16px)`.

## حقائق DOM لبحث تيمو (من فحص حيّ — www.temu.com/sa/)

- حقل البحث: `input[type="search"]` (class مولّدة مثل `_7H3Q1N2_`، بلا placeholder).
- صفوف الاقتراحات: `.nTJ9YZso`، داخل overlay `._3KC0yZ4V` (position:absolute, z-index:999).
- **البحث overlay وليس مساراً** — الـ URL لا يتغيّر، فـ `history.back` لا ينفع (لهذا زر الرجوع يفرّغ الحقل بدلها).
- تفريغ قيمة الحقل + إطلاق `input` event يُخفي الاقتراحات (تأكّد حياً: 20→0 صف).
- الهيدر العلوي `._2UbxPzJy` (fixed) يحوي البحث ويخفي نفسه بالنزول.

## مناطق حسّاسة

- شي إن: `m.shein.com/ar` + السعودية + USD + عربي + `site_uid=pwar`. لا User-Agent مخصص، لا كتابة storage عريضة.
- تحدي Cloudflare «أنا إنسان»: لا نتجاوزه ولا نعيد تحميله.
- تيمو: لا نحجب البحث. الشريط السفلي داخل WebView حسّاس (z-index/position/__resize). `killStorePopups` معطّلة نهائياً لتيمو (سبّبت وميضاً).
- الدفع/المحفظة/الكوبونات/الطلب الجماعي: لا تُلمس إلا بطلب صريح.
- بوابة VPN غير مستقرة أحياناً (probe يفشل عابراً فيظهر «شغّل VPN» رغم أن الموقع يعمل) — أُضيف retry جزئي؛ يحتاج مراجعة.

## بروتوكول التسليم

بعد كل تغيير مستقر: حدّث `CURRENT_STATE.md` و`AI-HANDOFF.md` و`SESSION_SUMMARY.md`، واختم بملخص عربي قابل للنسخ.
