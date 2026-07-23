# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `claude/ios6-cover-fix`.
- Current candidate: v85.8.89 / `APP_VERSION = 2026.07.23-v85.8.89-shein-ios-modal-lifecycle-no-otp-test`.
- iPhone 16 Pro Max evidence: the failed reopen used new app/WebContent processes, then stopped after one 705-byte HTTP 200 response without normal resource fan-out, challenge, 429, renderer termination, or jetsam. Two older crash reports independently show `didFinish -> presentView -> UIViewController.present -> SIGABRT`.
- Root native defect: Capgo InAppBrowser 8.6.25 predates its official safe-presentation, touch-blocking `UITransitionView`, and double-resolve fixes. The old hide path left modal transition layers above the app, matching the image-like untappable UI.
- Fix: SHEIN-only opt-in dismisses the modal while preserving the same sized `WKWebView`; a transient flag prevents `viewDidDisappear` cleanup during visibility hide; React serializes SHEIN `hide/show`; presentation is guarded; and SHEIN `openWebView` resolves once. Temu remains on its old path.
- Scope protected: no Saudi/passive handling, product capture, add-to-cart payload, color/size parsing, cart math, payment, wallet, completed orders, or Temu behavior changed.
- Code commit: `35913c1`, pushed to `origin/claude/ios6-cover-fix`. GitHub iOS run `30012069056` passed.
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.89-shein-ios-modal-lifecycle.ipa`; SHA-256 `38568CD56DDAB5E042443A60E8EBA7F5BE9C68A139FE8D4BE12BF70A8330664C`.
- Validation: clean patch apply, web build, targeted lint, independent native review, Xcode build, and embedded version/native-guard marker checks passed. App-wide lint still has old unrelated errors.
- Device acceptance remains mandatory on iPhone 16 and iPhone 6: repeated Home ↔ Cart, rapid transition during first load, background/resume, then cold reopen. Do not claim the separate 705-byte cold-load path fixed solely from this native build.
- Old IPAs installed over the same bundle ID preserved `Library/WebKit/WebsiteData`; they were not clean tests. If cold reopen still fails, reconnect/unlock the iPhone 16 and pull `Library/WebKit` plus `Library/Caches/WebKit` read-only after force-closing Otlobli, or perform one Delete App + reboot + reinstall test with fixed VPN/IP.

## Previous Candidate

- Previous candidate: v85.8.88 / `APP_VERSION = 2026.07.23-v85.8.88-shein-passive-saudi-no-otp-test`.
- v85.8.88 made SHEIN Saudi handling passive and remains the code baseline beneath the native v85.8.89 lifecycle fix.
- User result: it opened once on iPhone 16 Pro Max, then failed after leaving/reopening. iPhone 6 continued to work better.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.87 / `APP_VERSION = 2026.07.23-v85.8.87-shein-cookie-reset-no-otp-test`.
- User rejected v85.8.86 on iPhone 16 Pro Max: SHEIN still showed the blocked/frozen behavior even after removing SHEIN document-start injection and avoiding challenge-page writes.
- Fix attempted: bounded SHEIN-only cookie/cache reset for `m.shein.com`, `www.shein.com`, and `shein.com` before first SHEIN open and after confirmed stuck/blocked paths.
- User rejected v85.8.87 too, so cookie-only cleanup is not the root fix for the current iPhone 16 case.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.86 / `APP_VERSION = 2026.07.23-v85.8.86-shein-no-docstart-challenge-no-otp-test`.
- User rejected v85.8.85 on iPhone 16 Pro Max: SHEIN was still blocked.
- Change: removed SHEIN's `otlobliDocumentStartScript` bootstrap entirely. SHEIN now gets no Otlobli DOM/nav injection at document start; the full script is injected only after page load.
- Change: added early loaded-document challenge detection before any Saudi cookie/storage write. This catches same-URL challenge pages, removes all Otlobli nodes, posts `humanCheck`, and returns without touching the challenge.
- Scope protected: no product capture, add-to-cart, color/size parsing, product URL normalization, cart math, payment, wallet, completed-order, or Temu logic changed.
- GitHub iOS build `29970160713` succeeded from code commit `d92b777`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.86-shein-no-docstart-challenge.ipa`; SHA-256 `4BE352FDDCC5FFBAB5EE4707D210E204FC75CB4AFA48B3A3A7DB85B7702FC9FA`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; GitHub iOS build passed; embedded IPA marker check found v85.8.86 and no `otlobliDocumentStartScript` marker. Targeted `src/App.tsx` lint still reports pre-existing unrelated App errors; full build passes.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.85 / `APP_VERSION = 2026.07.23-v85.8.85-shein-ios-gentle-challenge-no-otp-test`.
- New user evidence: SHEIN works normally on iPhone 6, but iPhone 16 Pro Max is challenged/blocked after first entry even after reinstall. The issue is device/session/anti-bot sensitive, not a universal SHEIN break.
- Change: when a SHEIN human/security challenge is detected, the full injected script no longer writes Saudi cookies/storage and no longer mounts the Otlobli nav inside the challenge document. It only removes Otlobli nodes, releases scroll lock, posts `humanCheck`, and leaves the challenge untouched.
- Change: all iOS SHEIN WebViews now use the gentler low-end polling cadence, reducing script pressure on modern iPhones while preserving the existing iPhone 6 behavior.
- Scope protected: no product capture, add-to-cart, color/size parsing, product URL normalization, cart math, payment, wallet, completed-order, or Temu logic changed.
- GitHub iOS build `29969344175` succeeded from code commit `e363db1`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.85-shein-ios-gentle-challenge.ipa`; SHA-256 `0DB95F793C7E74108595C0E16708303B99512B3388305B2C69C235B545FAAF0A`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; GitHub iOS build passed; embedded IPA marker check found v85.8.85 and `OTLOBLI_SHEIN_GENTLE_TIMERS`.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.84 / `APP_VERSION = 2026.07.22-v85.8.84-rollback-v83-shein-stable-saudi-no-otp-test`.
- User rejected v85.8.83 on real iPhone: Saudi locking broke, first open worked only once, then returning to the app left SHEIN as a frozen image. Treat v85.8.83 as failed.
- What v85.8.83 changed and why it failed: it closed SHEIN on leaving home/background/resume, reset volatile WebView state, and forced a fresh VPN/Saudi check. On the real device that made lifecycle timing worse and destabilized the Saudi setup instead of fixing the freeze.
- Response: revert the v85.8.83 fresh-session policy and restore the v85.8.82/v85.8.79 behavior: preserved SHEIN WebView, old page heartbeat, and old post-ready recovery path. Keep v85.8.82's narrow Saudi `addressCookie` recovery and cart back-target behavior.
- Scope protected: no color/size, product capture, add-to-cart, product link normalization, nav/icon sizing, payment, wallet, completed-order, or Temu capture logic changes.
- GitHub iOS build `29957413860` succeeded from code commit `81ac13c`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.84-rollback-v83-shein-stable-saudi.ipa`; SHA-256 `36C2A08AFB95DAA88D97916DCFB1B6E595664111E59BEEBC7F6D3341E803CB10`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; `git diff --check` only reports Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found v85.8.84.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.83 / `APP_VERSION = 2026.07.22-v85.8.83-shein-fresh-session-no-heartbeat-no-otp-test`.
- Rejected on real iPhone: Saudi locking broke and SHEIN froze after app background/resume. Do not reuse the close-on-resume fresh-session policy.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.82 / `APP_VERSION = 2026.07.22-v85.8.82-shein-stable-saudi-back-no-otp-test`.
- User rejected v85.8.81 as worse: first entry could show SHEIN on Bahrain and fail Saudi locking, so capture/add was blocked; after leaving/re-entering the app, SHEIN could freeze without cart/product.
- Response: v85.8.82 rolls back the failed v85.8.80/81 SHEIN experiment. SHEIN cart products again use the v85.8.79 native `InAppBrowser.setUrl()` path; in-page cart navigation remains Temu-only. Restored the old SHEIN hot interval timings and the SHEIN heartbeat/recovery path from v85.8.79.
- Kept only the useful back-target fix: repeated `sheinPageInteractive` no longer resets a cart-opened product back button from `cart` to `home`; reset happens only when the user actually leaves through Otlobli cart/orders/profile.
- Added narrow Saudi recovery: if SHEIN has `addressCookie` saved with an explicit non-Saudi country such as Bahrain, remove only that one key before seeding Saudi/USD. Signed Saudi addresses are preserved.
- Scope protected: no color/size, product capture, add-to-cart, product link normalization, nav/icon sizing, payment, wallet, or order logic changes.
- GitHub iOS build `29952878400` succeeded from code commit `394bcae`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.82-shein-stable-saudi-back.ipa`; SHA-256 `20763A568A3E399CA59C98A4AF622C2059A62469F8D14893E77A51F1736297E3`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; `git diff --check` only reports Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found v85.8.82. User reported freeze still remained, but Saudi was not broken like v85.8.83.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.81 / `APP_VERSION = 2026.07.22-v85.8.81-shein-cart-back-target-no-otp-test`.
- User tested v85.8.80 and the same issue remained: SHEIN cart product opens correctly, but Otlobli back returns inside SHEIN to a home/categories page with no product grid below it and the page becomes stuck.
- Corrected root cause: repeated `sheinPageInteractive` messages were overwriting the cart-product back target. After reveal, React initially sent `__backTarget = cart`, then a later readiness message called `markStoreWebviewReady()` again, reset/sent `__backTarget = home`, and the back button used SHEIN `history.back()` instead of returning to Otlobli cart.
- Change: `markStoreWebviewReady()` and the home-show effect no longer reset `pendingBackTargetRef` after posting it. The target resets to `home` only when the customer actually leaves the WebView through Otlobli cart/orders/profile messages. This keeps cart-opened SHEIN products bound to Otlobli cart and avoids SHEIN's broken in-page back state.
- Scope protected: no color/size detection, capture, add-to-cart, deep-link, product opening, nav/icon sizing, payment, wallet, or order changes beyond the back-target fix.
- GitHub iOS build `29946868465` succeeded from code commit `505db9d`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.81-shein-cart-back-target.ipa`; SHA-256 `3A418030C59499B76611B59E0102C72909686954879185E7A9258CCF5E3B7A84`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; GitHub iOS build passed; embedded IPA marker check found v85.8.81. Needs real-device check.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.80 / `APP_VERSION = 2026.07.22-v85.8.80-shein-cart-light-nav-no-otp-test`.
- User rejected v85.8.79 because it was a recovery-after-freeze approach and the SHEIN cart-product freeze still reproduced. Do not continue with heartbeat/rebuild-after-freeze workarounds unless the user explicitly asks.
- Root-cause direction for v85.8.80: SHEIN cart products were still using native `InAppBrowser.setUrl()` deep product loads from the cart/hidden preserved WebView. Switching Temu -> SHEIN recovered because it rebuilt the WebView, which points to the cart-origin native deep load poisoning the preserved SHEIN iOS WebView session.
- Change: SHEIN cart products now open through the live store document, like the confirmed Temu cart fix. Cold cart open loads SHEIN home first, keeps the pending URL queued, then `markStoreWebviewReady()` runs in-page navigation with `window.location.assign()` through `executeScript`. Warm SHEIN cart open shows the WebView before running the same in-page navigation. The pending URL is not cleared before the home-ready handoff.
- Removed the v85.8.79 SHEIN heartbeat/page heartbeat watchdog. `restartStuckSheinWebview()` is back to the conservative pre-ready-only recovery guard.
- Low-end change: widened `OTLOBLI_LOW_END` to include small iPhone-6-sized viewports, low CPU, and low memory, then relaxed SHEIN hot scan intervals on those devices. Modern phones keep fast timings.
- Scope protected: no changes to color/size detection, product payload capture, add-to-cart flow, deep-link building, add validation, or nav/icon sizing.
- Added visible browser harness `scripts/shein-cart-browser-harness.mjs`. It injects the real SHEIN script and compares full load vs in-page navigation. It has `--keep-open=1` for manual CAPTCHA, but Playwright Chromium is bot-flagged by SHEIN, so a failed CAPTCHA answer there is not evidence the user selected wrong images.
- Browser evidence with the user's product URL: SHEIN home became interactive and the long URL was preserved; both desktop automation paths reached SHEIN `/risk/challenge` with `humanCheck`. This proves URL shape is valid and desktop automation cannot be trusted for CAPTCHA completion.
- GitHub iOS build `29944509509` succeeded from code commit `71a3f13`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.80-shein-cart-light-nav.ipa`; SHA-256 `67D53FD87BCFECF606DAFD641CB2AAB657C2EB1084C8401C248432BF150C8AAD`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; `git diff --check` only reports Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found v85.8.80 and no old SHEIN heartbeat markers. `npx eslint src/App.tsx ...` still reports pre-existing unrelated App lint errors.
- Next real-device check for v85.8.80 was failed by user; use v85.8.81 instead.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.79 / `APP_VERSION = 2026.07.22-v85.8.79-shein-ready-freeze-recovery-no-otp-test`.
- User report: SHEIN freezes after opening a product from Otlobli cart and backing out to SHEIN home; category taps stop working. Switching to Temu and back recovers because it rebuilds the WebView; killing/reopening the app does not reliably recover.
- Root cause in v85.8.78: heartbeat recovery was logically blocked. The watchdog required `sheinReadyRef.current === true`, then called `restartStuckSheinWebview()`, whose guard returned immediately when `sheinReadyRef.current` was true. Result: no rebuild ever happened for the exact post-ready freeze case.
- Change: `restartStuckSheinWebview(sessionId, allowReadyRecovery = false)` keeps the old pre-ready behavior by default, but the SHEIN heartbeat watchdog calls it with `true`, allowing the proven WebView rebuild recovery after an already-ready SHEIN page stops heartbeating for >15s. Also added a narrow fallback in `dismissSheinProductLoginPrompt()` to hide an unsolicited product-page auth dialog when SHEIN provides no reliable close button, and release scroll lock. Real login routes are still skipped.
- Scope: SHEIN post-ready freeze recovery + first-product auth prompt hiding only. No Temu, payment, wallet, completed orders, SKU capture, cart pricing, or order logic changed.
- GitHub iOS build `29928244012` succeeded from code commit `377f6d5`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.79-shein-ready-freeze-recovery.ipa`; SHA-256 `89677EFA17882DFB02C893FF16447323829A074141DC0C5E937A68771F2A120A`.
- Validation: `npm run build` clean; injected bootstrap/capture scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; `git diff --check` only reports Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker checks found v85.8.79 and the SHEIN login-prompt fallback marker. `npx eslint src/App.tsx ...` still fails on pre-existing unrelated App lint errors.
- Next real-device check: install v85.8.79 on iPhone 6 and iPhone 16 Pro Max. Reproduce: SHEIN cart item -> product -> back to SHEIN home -> tap categories/search/products. If SHEIN freezes, expect automatic WebView rebuild after about 15-19s instead of permanent freeze. Also verify first product for a fresh user never leaves a SHEIN login dialog visible.

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.74 / `APP_VERSION = 2026.07.21-v85.8.74-temu-cart-inpage-nav-no-otp-test`.
- Change (v85.8.74): open Temu cart products via an IN-PAGE navigation (`navigateStoreWebviewInPage` → `window.location.assign` through `executeScript`) inside the warm Temu page, so the request carries a temu.com referrer like a real card tap — instead of a refererless `InAppBrowser.setUrl` that Temu 302s to `/login.html`. Applied in `openStoreProductFromCart` (warm) and `markStoreWebviewReady` (queued). Cold open loads Temu HOME first then in-page-navigates to the queued product. SHEIN unchanged. Keeps v85.8.73 login recovery + `temuLoginBlocked` graceful fallback + probe. Built clean (tsc+vite); referrer hypothesis NOT device-verified (test browser is bot-flagged). If device still shows /login.html, next step is driving Temu's SPA router.
- Previous candidate below (v85.8.73):
- Current local code candidate: v85.8.73 / `APP_VERSION = 2026.07.21-v85.8.73-temu-login-redirect-recover-no-otp-test`.
- ROOT CAUSE (v85.8.72 URL probe, real device): Temu cart-product white screen IS Temu's own `/login.html?from=<product>`. Cold full-navigation to a deep Temu PDP for a logged-out user gets 302'd to login; SPA in-app browsing does not. Not our blocking (img=0/0).
- Change (v85.8.73): `otlobliTemuRecoverFromLoginRedirect()` navigates once to the `from` product URL (guest cookie now set) guarded by sessionStorage (one retry per target, no loop). On failure the script posts `temuLoginBlocked`; App.tsx aborts the cart-product prep, returns to cart, shows a Temu-login notice — never reveals the white login page. Keeps v85.8.71 900ms stable gate + v85.8.72 top URL probe. Built clean; NOT real-device tested.
- Previous candidate below (v85.8.71):
- Current local code candidate: v85.8.71 / `APP_VERSION = 2026.07.21-v85.8.71-temu-cart-stable-gate-urlprobe-no-otp-test`.
- Change (v85.8.71): confirmed via capgo InAppBrowser Swift source that `preShowScript`+`documentStart` is a persistent WKUserScript, so the script runs on every setUrl navigation — the cart-open white screen is NOT a missing-script problem. Real cause: reveal gate posted `temuProductVisible` on the first transient PDP paint, then Temu bounced the cart-origin direct load to login → blank. Fix: reveal now requires product content continuously visible for `OTLOBLI_TEMU_STABLE_MS=900`ms (timer resets on any non-PDP/login/no-content tick). Added `otlobliTemuUrlProbe()`, a permanent bottom diagnostic bar (test build) that stays on the white screen showing PDP/ACCT/LOGIN flags + img counts + URL path — READ IT if white persists. Built clean; NOT real-device tested.
- Previous candidate below (v85.8.70):
- Current local code candidate: v85.8.70 / `APP_VERSION = 2026.07.21-v85.8.70-temu-cart-login-sheet-gate-no-otp-test`.
- Change (v85.8.70): the Temu cart-product reveal gate now also blocks reveal while a login sheet is visible. New `otlobliTemuLoginSheetVisible()` flags a large visible centered surface with a sign-in/continue phrase + a phone/email/password input or social button; `otlobliPostTemuProductVisibleIfReady` returns early on it. Reveal gate only — hides nothing. Fixes: cart product → brief Temu login → white screen. Built clean; NOT yet real-device tested.
- Previous candidate below (v85.8.69):
- Current local code candidate: v85.8.69 / `APP_VERSION = 2026.07.20-v85.8.69-temu-cart-product-visible-gate-no-otp-test`.
- Code commit: `b9d6d14` (`fix: v85.8.69 gate Temu cart product reveal`).
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.69-temu-cart-product-visible-gate.ipa`.
- GitHub iOS build `29735372870` succeeded from code commit `b9d6d14`.
- v85.8.69 IPA SHA-256: `C66EF04310F50891BA1D1A127E587DBC9A1FF94153CAA5C6E85307F890FCBF4F`.
- Latest user report after v85.8.68: ordinary Temu product opens work again, but tapping a product from Otlobli cart briefly shows Temu login/account UI and then a white product screen.
- Change: Temu pending cart-product reveal no longer trusts native `browserPageLoaded` alone. The injected page script posts `temuProductVisible` only after visible product content exists (large product image or visible price) and no visible account/login surface remains. React verifies the visible URL against the pending cart URL before switching from cart to home.
- Includes v85.8.68 underneath: no opaque Temu product-entry cover and large product-flow containers protected from account/promo hiding.
- Scope: Temu cart-product reveal timing only. No SKU capture, add-to-cart logic, header, bottom nav placement, payment, wallet, orders logic, or real account route changes.
- Validation: targeted ESLint for script/config, `npm run build`, `git diff --check`, injected-script parse, GitHub build, and embedded IPA marker checks passed (`v85.8.69`, `temuProductVisible`, and `otlobliPostTemuProductVisibleIfReady` present).
- Do not reapply the v85.8.47 visible-SKU/group-dims approach until the white-page regression is understood from real-device evidence or a DOM fixture that reproduces it.
- Next real-device checks: install v85.8.69, add a Temu item to cart, open it from Otlobli cart, and confirm the cart remains visible until the actual Temu product content appears with no login flash -> white page.

## Previous Candidate (v85.8.68)

- v85.8.68 / commit `091a35f` removed the full-page white Temu product-entry cover and protected large non-floating product-flow containers from account/promo hiding on product URLs.
- GitHub iOS build `29733534914` produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.68-temu-product-white-screen-guard.ipa` with SHA-256 `C26CC0F9EB31B01D105F1F004305E2F16B7F8F47DABF6C89DF5F0B499613337B`.

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
