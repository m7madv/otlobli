# Otlobli Current State

Last updated: 2026-07-13

## Claude: the ACTUAL root cause — window.close() hijack, iOS only (2026-07-13, session 3)

User retested the session-2 IPA (the pageLoadError/humanChallengeSeenRef fix
below) on the real iPhone: **exact same problem, no change.** That fix was
reasoned entirely from the ANDROID native plugin source
(`WebViewDialog.java`'s `onReceivedError` firing per sub-resource). The user
has only ever been testing **iOS**. Re-investigated `WKWebViewController.swift`
specifically and found the fix targeted a mechanism that doesn't even apply
on iOS the same way (confirmed: `WKNavigationDelegate`'s `didFail`/
`didFailProvisionalNavigation` are main-frame/document-navigation-scoped
only - WKWebView has no delegate visibility into sub-resource failures at
all, unlike Android's `WebViewClient`).

**The real mechanism, found by reading the iOS plugin source directly:**
`WKWebViewController.swift` injects a `WKUserScript` at `.atDocumentStart`
that unconditionally overrides the page's own `window.close`:
```js
window.close = function() {
    window.webkit.messageHandlers.close.postMessage(null);
};
```
The `close` message handler calls `closeView()` with **zero gating** -
`dismiss(animated: true)` on the whole native browser, instantly. A second,
equally unconditional path exists via `WKUIDelegate.webViewDidClose`. Neither
of these goes through `pageLoadError`, `humanCheck`, or any JS the app
controls - this is a pure native interception the app-level JS/React code
cannot see or prevent at all.

**Why this is almost certainly it:** Cloudflare's bot-mitigation/"Just a
moment" challenge script is well known to call `window.close()` defensively
when its environment fingerprinting flags an atypical/automated embedding
context (no real tab history, WKWebView-specific window/navigator features)
- exactly this app's situation (SHEIN reached via VPN, inside a bare
WKWebView). This explains the ~2-second timing (roughly how long CF's
fingerprinting script takes to run and decide), why it's "SHEIN never
works" (the challenge fires essentially every time now per v62's diagnosis),
and why the previous fix had literally zero effect (it gated a completely
different, Android-only code path).

**Fix:** patched `WKWebViewController.swift` + `InAppBrowserPlugin.swift` +
`dist/esm/definitions.d.ts` in
`patches/@capgo+capacitor-inappbrowser+8.6.25.patch` to add a new
`ignorePageWindowClose` option (mirrors the existing
`disableGoBackOnNativeApplication` pattern). When true, both the `window.close`
message handler and `webViewDidClose` become no-ops. Wired
`ignorePageWindowClose: true` into the single `InAppBrowser.openWebView({...})`
call in `src/App.tsx` (`browseShein()`), applies to both stores. Android has
no equivalent override at all (confirmed: no `window.close` hijack exists in
`WebViewDialog.java`), so this is iOS-only by construction - no Android
behavior change.

**Verification limits, stated plainly:** there is no Mac/Xcode in this
environment - Swift cannot be compiled locally. Verification here is limited
to: `npm run build` (TypeScript typecheck of the new option passes) and the
GitHub Actions `ios-unsigned-build.yml` workflow actually compiling the
patched Swift successfully (real compiler, not just typechecking). If that
workflow fails, the patch has a Swift syntax/API error that needs fixing
before anything else. If it succeeds, that only proves the code compiles -
NOT that this is the actual fix; that still requires the user's real-device
test, same as every fix in this file so far.

## Claude: real root cause found — pageLoadError tears down mid-Cloudflare-challenge (2026-07-13, session 2)

User tested the first APK/IPA from this session on a real iPhone and sent
screenshots + a detailed description. This is the ACTUAL root cause of
"SHEIN breaks after switching stores" - stronger and more concrete than the
session-1 cache/cookie gaps (those were still real bugs, now both sessions'
fixes are combined):

**What the user saw:** switch Temu -> SHEIN. The Cloudflare "Just a moment"
challenge appears - but as an Arabic-localized page ("إجراء التحقق من
الأمان"), not the English one. otlobli's own bottom nav bar is gone (expected
- v62's challenge-safe mode strips our own elements during a detected
challenge). Within about 2 seconds the user gets kicked all the way back to
otlobli's own home screen (blank white content area, the `humanCheck` toast
still lingering: "المتجر يطلب تحققاً بسيطاً..."). Sometimes it does open, but
"as an image" (unresponsive).

**Root cause, confirmed by reading the native plugin source
(`WebViewDialog.java`):** the `pageLoadError` JS event is wired to Android's
`onReceivedError` callback, which fires for ANY failed sub-resource load
(script/font/image/xhr) - not just the main document - and carries no
main-frame/sub-resource distinction in its payload. SHEIN's Cloudflare
challenge page loads its own verification script from
`challenges.cloudflare.com`, a different domain than `shein.com` - over a VPN
tunnel that's specifically routing around a Syria geo-block, it's entirely
plausible for that second domain to fail intermittently even while shein.com
itself is reachable. The v66 "store recovery" feature added a `pageLoadError`
handler that arms a 1800ms timer and, if not cancelled, tears the whole
webview down and bounces back to the VPN-check gate
(`src/App.tsx`, in the `InAppBrowser.addListener('pageLoadError', ...)`
effect) - 1800ms matches "kicked out within ~2 seconds" exactly. v62's
`humanCheck` message handler already cancels *that one* pending timer, but
nothing stopped a *later* `pageLoadError` (from another failed challenge
sub-resource) from arming a fresh, uncancelled one - and v62's own English-
only `otlobliIsHumanChallenge()` title check (`/just a moment/i`) doesn't
match the Arabic-localized challenge title, so detection may not even have
fired at all in this case.

**Fixed:**
1. Added `humanChallengeSeenRef` (`src/App.tsx`) - set once `humanCheck` ever
   fires for this webview session, reset only on a fresh `browseShein()`
   open. The `pageLoadError` handler now refuses to arm (or fire, checked
   again inside the timeout callback) its teardown-to-VPN-gate timer while
   this ref is true. A stray sub-resource failure during/after a detected
   challenge no longer nukes the session.
2. Broadened `otlobliIsHumanChallenge()` (`src/services/sheinBrowserScript.ts`)
   with a language-agnostic signal: Cloudflare always prints "Ray ID: xxxx"
   in Latin script on its challenge/block pages regardless of the page's
   language (confirmed in the user's own screenshot). Also added "attention
   required" to the title check. A normal shopping page can never contain
   "Ray ID:", so this is a safe, reliable signal with no plausible false
   positive.
3. This does NOT fix the "first race" (a `pageLoadError` whose 1800ms timer
   elapses before `otlobliIsHumanChallenge()` ever gets a chance to fire
   `humanCheck` at all, e.g. if detection itself still misses some challenge
   variant). If the user still sees the ~2-second kick-out after this build,
   the next step is a temporary breadcrumb: post `document.title` +
   `document.body.innerText.slice(0,200)` back to the app the moment
   `pageLoadError` fires, to see exactly what the page looked like at that
   instant.

Committed as `0caa23e` on `claude/competent-nash-557dc5` (pushed). GitHub iOS
unsigned build run `https://github.com/m7madv/otlobli/actions/runs/29257970710`
succeeded against this commit. Artifact `otlobli-unsigned.ipa`:
- SHA-256: `f9ae91e7cef2d811ab86c84d1ed88adafb6ec803b7bc85124ce3bcc826a55184`

## Temu: switched from Jordan to Saudi Arabia (2026-07-13, session 2)

User asked to switch Temu's forced region from Jordan (`/jo/`) to Saudi
Arabia (`/sa/`). Changed the base store URL and the non-Arabic-locale
redirect target in `src/App.tsx` (`STORES` array + the `urlChangeEvent`
redirect in the Temu-locale-guard effect). `/sa/` was already accepted as a
valid "already Arabic" destination by the existing `ARABIC_TEMU_RE` guard, so
no other logic needed to change.

**Currency caveat - could not deliver "force USD" as literally asked:** this
exact file already documents (see the `STORES` comment, now updated) that
Temu was previously tested and confirmed to reject any URL-based
locale/currency override - it bounces back to Canada. Temu ties currency to
the region's native storefront currency, with no independent override; there
is no live access to Temu in this environment to re-test that. So Saudi
Arabia will very likely show Temu's own pages in Saudi Riyal (SAR), the same
way Jordan showed Jordanian Dinar (JOD) before - not USD. This is NOT a new
problem: `temuPriceUsd()` in `src/services/sheinBrowserScript.ts` already has
a correct, fixed SAR->USD conversion rate (`0.267`) alongside JOD/AED/etc., so
otlobli's own cart/checkout pricing is accurate in USD/SYP regardless of what
currency Temu's own page visually displays while browsing. If the user needs
Temu's own displayed prices (not otlobli's cart total) to visually read
"$", that would require Temu's US/international storefront specifically,
which is very unlikely to render Arabic - a real tradeoff, not a bug to fix.

## Claude: SHEIN-breaks-after-store-switch investigation (2026-07-13)

Branch note: this worktree (`claude/competent-nash-557dc5`) started 40 commits
behind `codex/customer-wallet-group-orders` (stuck at v52, missing v53-v66.3
entirely, including the v62 Cloudflare challenge-safe mode and the v66.3
WebView-state-cleanup fix). Merged `origin/codex/customer-wallet-group-orders`
(tip `b5586d2`) in cleanly, no conflicts, before touching any code. If you are
reading this on a different branch, check `git log --oneline --all --decorate`
first - this repo currently has several stale AI worktree branches sitting at
different points behind the real tip.

User's reported symptom (still happening as of this session, tested after
v66.3): SHEIN works on a fresh install, but breaks (page paints but looks
"like a static image" - taps don't register, or only register after rapid
repeated tapping) after switching Temu -> SHEIN. v66.3 (`b5586d2`) already
attempted a fix (clear cookies + unregister service workers + clear Cache
Storage between store switches). Found two concrete, code-verified gaps in
that fix and closed them:

1. **`InAppBrowser.clearAllCookies()` raced its own native call.** The
   patched plugin's `CapgoInAppBrowserPlugin.clearAllCookies` (Android) called
   `CookieManager.removeAllCookies(null)` - an asynchronous API - then called
   `call.resolve()` immediately, without waiting for the actual removal to
   finish. `switchStore` in `src/App.tsx` reopens the new WebView right after
   that promise resolves, so on a slow/busy device the new page could start
   loading while the old cookies (including a stale `cf_clearance` from
   Cloudflare) were still technically present. Fixed in
   `patches/@capgo+capacitor-inappbrowser+8.6.25.patch`: now waits for the
   real `ValueCallback` before resolving.
2. **The native HTTP cache was never cleared.** v66.3 only cleared the
   Service-Worker-visible Cache Storage API from JS (`caches.delete(...)`) -
   a completely different cache namespace from the WebView engine's own HTTP
   disk/memory cache. The plugin exposes a separate native `clearCache()`
   method (`WebView.clearCache(true)`) that was never called anywhere in the
   store-switch flow. Added a call to it in `switchStore` (`src/App.tsx`),
   **before** `InAppBrowser.close()` - `clearCache()` targets currently-open
   WebView dialogs by id, and falls back to clearing otlobli's *own* app
   webview if none are open, so it must run before the old store dialog is
   torn down, not after.
3. Also cleared IndexedDB alongside Cache Storage in the injected script
   (`src/services/sheinBrowserScript.ts`) for symmetry - same storage class
   as Cache Storage (structural, hydration-adjacent), not the same class of
   risk as the documented localStorage lesson.

Verified in this session: `npm run build` (tsc + vite) passes, `npx cap sync
android` passes, `./gradlew assembleDebug` succeeds and produces a real
`android/app/build/outputs/apk/debug/app-debug.apk` (confirms the Java patch
actually compiles). **Not verified: real-device behavior.** This environment
has no Syria-network/VPN/Cloudflare-challenge condition to reproduce the bug
against, so these two fixes are honestly-reported as "closed real gaps in the
existing cleanup logic", not a confirmed root-cause fix. If the user tests
this build and SHEIN still breaks after a Temu->SHEIN switch, the next thing
to check is whatever `otlobliIsHumanChallenge()` sees at the exact moment it
breaks (title/`#challenge-form`/challenge script presence) - add a temporary
`messageFromWebview` breadcrumb reporting that state rather than guessing
further blind.

Committed as `26d5507` on branch `claude/competent-nash-557dc5` (pushed to
`origin/claude/competent-nash-557dc5` - NOT merged into
`codex/customer-wallet-group-orders`, to avoid touching the shared branch
before the user confirms the fix on-device). GitHub iOS unsigned build run
`https://github.com/m7madv/otlobli/actions/runs/29255893655` succeeded
against this branch (57s). Artifact `otlobli-unsigned.ipa`:
- size: `1943447` bytes
- SHA-256: `f6ce7b93696f2994cf5d9ee88d29ee0f8821386ce6daf6a9baf5b10bd6850d06`

## Codex store/group-link fixes in progress (2026-07-12)

- `src/App.tsx` now auto-joins a valid shared-cart invite and keeps the group-order
  controls visible even when the recipient cart is empty.
- A native `pageLoadError` after the store was shown (including a failed 404 after
  "open anyway" or a dropped VPN) now tears down the failed WebView and returns to
  the VPN/connection check instead of leaving a blank white screen.
- Native SHEIN URL normalization now leaves Cloudflare/captcha/security challenge
  routes untouched so verification is not restarted by the Saudi `/ar` redirect.
- `npm run build` passes. Real-device SHEIN/Temu verification is still required.
- Figma writes are currently blocked because the connected Figma account requires
  reauthentication; do not invent visual changes until that connection is restored.
- The shared-orders/admin task was submitted to Claude in worktree
  `.claude/worktrees/brave-gould-c49b60`, but Claude hit its usage limit during
  inspection. The worktree is clean at `cf4b53c`; no Claude code exists to merge.
- Full follow-up implementation is now in progress on the active branch:
  - shared-order lines persist server-validated owner identity;
  - every group member can load the order, while item issues/actions are scoped
    to the owner of that product;
  - checkout selects the Qadmous recipient from group members and persists it;
  - tracking groups products by owner;
  - issue responses support options, text, and requested screenshots/photos from
    My Orders without requiring WhatsApp;
  - admin order rows select inline and dynamic issue options/request-photo are implemented;
  - Temu search chrome is stabilized and SHEIN challenge/menu click guards are narrowed.
- Forward migration `20260712033000_shared_order_ownership.sql` is applied to production,
  and `admin-orders` was deployed successfully.
- Customer Vercel deployment `dpl_Du4Rwp3kdyRNqqrPs36ELWv6pRfo` is READY at
  `https://talabieh.vercel.app`; admin deployment
  `dpl_4Zdxn8VqEssPPW5NwhS4EKKCtGK5` is READY at
  `https://talabieh-admin.vercel.app`.
- Both public URLs return HTTP 200 and customer production JS contains v66.
- Root and admin production builds pass locally. Real-device store verification remains.
- Release commit `f7b4456` is pushed. GitHub iOS unsigned build run `29175819975`
  succeeded for that exact SHA; `otlobli-v66.ipa` is on the Desktop.
  - size: `1942781` bytes
  - SHA-256: `6724eb9d147e780aac7d868853d341cb3a416e2d7c856300f6acc3db6372e6b1`

## Claude v65 app handoff confirmed (2026-07-12)

- Claude's detailed v58→v65 handoff is recorded at the top of `SESSION_SUMMARY.md` and
  committed in `cf4b53c`; v65 APK/IPA artifacts are reported on the user's Desktop.
- App/UI scope includes structured order issues, invoice and wallet updates, support number,
  VPN checks, SHEIN/Temu WebView fixes, and WhatsApp message/prekey handling. SHEIN/Temu
  still require real-device verification.
- The Note 8 hardware/firmware problem remains a separate scope and is intentionally excluded
  from this app handoff.

## Codex Note 8 / ShamCash payment work in progress (2026-07-11)

This scope is intentionally separate from Claude's concurrent customer/admin UI work.
Do not revert or fold the UI commits into it.

- Supabase production project `dcicqdprtyhwmhegabay` now has both forward repairs:
  - `20260712020000_payment_hardening_hotfix.sql`
  - `20260712021000_fix_profile_wrapper_overload.sql`
- `payment-webhook` version 9 is `ACTIVE` with `verify_jwt=false`. The endpoint is
  protected by exact-body HMAC-SHA256, a five-minute timestamp window, fixed package
  identity, durable event IDs, and transactional database matching.
- The old webhook secret was rotated. The replacement is not in the repository and is
  stored locally in Windows Credential Manager as `Otlobli/ShamCashWebhookSecret`.
- Production probes passed: missing/invalid signature -> 401, valid signed OTP rejection
  -> 200, replay -> 200 duplicate without repeated processing.
- Financial migrations `20260712022000` and `20260712023000` are also applied:
  lower collision amounts are rejected (exact-only), one customer cannot ladder active
  wallet top-ups, and a recent unmatched event can reconcile for two minutes without
  allowing an older event to drift into a new intent.
- Railway deployment `32116896-5c2c-4088-b8d5-40c7a058ba44` is `SUCCESS/RUNNING`
  from commits `d0ac78f` and `9f42cf5`. `/api/exchange-rate` now persists the live rate before
  replying, revalidates cached responses against `app_settings`, uses a local single-flight,
  fails closed if no persisted fallback can be established, and sends `Cache-Control:
  no-store`. Production API and SQL source of truth both returned `13050 SYP/USD`.
- The Android listener no longer sends `x-payment-secret`; the secret remains only in
  Android Keystore and signs the request. The release has no synthetic ADB notification
  action, ignores group summaries, keeps an OS-stable event ID across notification
  updates, safely recovers recent active notifications, and caps WorkManager data by
  UTF-8 bytes. Unit tests are 16/16 and Deno webhook tests are 13/13. Release lint has
  no errors (one pre-existing missing-icon warning).
- Latest signed listener APK:
  - `android/shamcash-listener/build/outputs/apk/release/shamcash-listener-release.apk`
  - APK SHA-256: `343f0213d837410b0a4069a67ece69a2cc65b8aba3c3140f65d0663ecfb226b5`
  - signer certificate SHA-256: `44ed0b43a41924ca67dfa44c6815e5b9286f843b7879b1f1d2c7e4ee5b1f827b`
- Structured order-issue payment hardening is applied in migrations `20260712031000`
  and `20260712032000`: confirmed issue payments resolve `issues[]` atomically, a
  customer cannot self-resolve a payment issue, admin issue saves derive only from
  unresolved entries, item IDs match `product_id`, and wallet history returns the
  stored USD amount instead of recalculating old transactions at today's rate.
- `admin-orders` also merges stale issue drafts against the current order and never
  reopens or erases a customer-resolved issue during a late admin save.
- The Note 8 is now authorized as serial `988e16384e4f51395230`, model `SM-N950F`.
  ShamCash must still be tested only on this Syrian-network phone, never on the PC.
- Remaining payment trust debt is explicit: product prices/totals still originate in the
  client because the vendor pages have no server-authoritative quote. Do not call pricing
  fully tamper-proof or group payment fully secured until server-issued price quotes and
  authenticated group snapshots are implemented and tested.
- Battery safety is physically blocked. A fresh six-sample sysfs capture while USB was
  connected reported `capacity=0`, `health=Cold`, `temp=-20 C`, ADC `3950..3986`,
  voltage `3.386..3.387 V`, current `0`, and `Not charging`. This proves the replacement
  battery/NTC/connector/board-temperature path must be repaired or reseated before any
  reset or flash. `/data/adb/service.d/fakebattery.sh` (SHA-256
  `9575a5e9dd37e4f1d6a738a3b83b5159816d9eb254f825fcd98c1c895a526e95`) is the only
  Magisk service/module found; it masks BatteryService as AC/100%/25 C every 15 seconds
  so Android can stay alive on USB. Do not disable it, force charging, flash an 80%
  kernel, or enable factory/slate mode until raw sysfs is plausibly `Good/Charging`.
- The intended post-repair state is stock Samsung firmware, no Magisk/root, and no custom
  charge-limit kernel. Captured restore identity is `XSG`, `N950FXXUGDVG7`, baseband
  `N950FXXSGDUG6`. Root is unnecessary for ShamCash/listener/remote control and is the
  wrong security trade-off for a payment terminal. Exact 80% must not be obtained by
  weakening verified boot; use external power control or a newer Samsung with native
  battery protection after the hardware path is valid.
- TeamViewer Host and AnyDesk were installed for evaluation. Samsung Knox EULA/account
  assignment requires the user personally; test full unattended control and remove the
  losing app after the phone reconnects.

## أحدث تعديل (Claude — تيمو: إخفاء أزرار الهيدر + منع صفحة الدخول)

غير ملتزم بعد. الملفان: `src/services/sheinBrowserScript.ts` و `src/App.tsx`.

- إخفاء أزرار هيدر تيمو (عربة التسوق/الحساب/الفئات) + بانر "تسوّق مثل الملياردير"
  مع إبقاء البحث والشعار: عبر `injectTemuHeaderHideCSS()` الذي يحقن CSS يستهدف
  `[class*="tab-d3nPD"]` و`[class*="downloadsWrapper"]`/`[class*="downloadUI"]`
  و aria الدقيق. السبب المكتشف: العناصر داخل حاوية `display:none` فأبعادها `0x0`
  وأسماؤها في `aria-label` فقط، لهذا فشلت الطرق السابقة المعتمدة على الموقع/النص.
- إصلاح الوميض (FOUC): الـ CSS يُحقن الآن فوراً عند `documentStart` (قبل الرسم)
  ويُعاد حقنه لو أُزيل — فلا تظهر العناصر المخفية أبداً حتى عند الدخول/الرجوع.
- منع صفحة `login.html` في تيمو نهائياً عبر `urlChangeEvent` في `App.tsx`
  (`TEMU_LOGIN_RE` → إعادة التوجيه إلى `temu.com/jo/`). مُختبَر بصرياً + بالسجل.
- التفاصيل الكاملة في `SESSION_SUMMARY.md`.

## Use this file first

If any AI continues work on this repo, use this file and `AI-HANDOFF.md` first.
Do not trust older context files before checking these two files.
Also read `AGENTS.md` and, when using Claude Code, `CLAUDE.md`.

## AI handoff discipline

- This project is shared between Codex, Claude Code, and possibly other AI sessions.
- Every AI must run `git status --short`, `git rev-parse --abbrev-ref HEAD`, and `git log -5 --oneline` before changing code.
- Existing modified/staged/untracked files are not automatically wrong; they may be user or other-agent work.
- Do not commit/push staged changes you did not create unless the user explicitly asks.
- After every stable change, update `CURRENT_STATE.md`, `AI-HANDOFF.md`, and `SESSION_SUMMARY.md`.
- AI usually cannot know the user's real billing limit. If the session is long or the user mentions billing/context, produce a chat summary early instead of waiting.

## Active source of truth

- Branch: `codex/customer-wallet-group-orders`
- Latest feature deployment commit: `83a43f0`
- Customer app source:
  - `src/App.tsx`
  - `src/services/supabaseAppApi.ts`
  - `src/infrastructure/localStorage.ts`
- Admin source:
  - `admin/src/AdminApp.tsx`
  - `admin/src/styles.css`
- Supabase source:
  - `supabase/schema.sql`
  - `supabase/functions/admin-orders/index.ts`
  - `supabase/functions/admin-drivers/index.ts`
  - `supabase/functions/admin-coupons/index.ts`
  - `supabase/functions/app-settings/index.ts`

## Latest production update in this handoff

This handoff includes the admin/product-issue/mobile-operations update. Treat the files in this commit as newer than all older summaries and older branches.

Latest customer app fix after that handoff:

- Latest SHEIN product-page fix commit:
  - `acbbed7` (`Fix SHEIN product page country guard`)
  - Removes the custom SHEIN User-Agent spoofing and keeps only `Accept-Language: ar-SA`
  - Restricts the Saudi guard to shipping/delivery country text, not arbitrary country names inside product titles/descriptions
- Group cart / "Order with a friend":
  - invite codes are still generated securely by the `cart-groups` Edge Function
  - WhatsApp sharing now sends real app links with store and host metadata
  - Android handles `otlobli://...` and `https://otlobli.app/group?...`
  - Android also handles `https://talabieh.vercel.app/group?...`, matching the current production invite link origin
  - iOS registers the `otlobli://` URL scheme
  - recipient sees a confirmation card before linking their cart
  - opening an invite now clears only a different locally-saved cart group so stale "waiting for friend" state cannot hide the incoming invite
  - latest behavior uses a per-device `memberKey` for group-cart membership/items, so two devices can join the same group even if they are testing with the same WhatsApp phone; each create action generates a fresh group code/link
  - group totals and each person's share are displayed with the app's selected currency formatter, based on SYP totals/exchange rate instead of a hard-coded `$ current / $40` line
- SHEIN browsing:
  - customer SHEIN URLs are normalized to `https://m.shein.com/ar/?currency=USD&country=SA&countryCode=SA&lang=ar&language=ar&ship_to=SA&shipToCountry=SA&shippingCountry=SA`
  - the in-app browser passes `Accept-Language: ar-SA` but does not spoof a custom User-Agent; spoofing made the WebView look less natural and can increase SHEIN human verification
  - injected browser script continually reasserts Saudi Arabia + USD + Arabic state and blocks foreign paths/countries
  - `site_uid` must stay `pwar` on mobile SHEIN; do not broadly overwrite SHEIN storage keys, because that leaves product/list pages stuck on skeleton loading
  - the Saudi guard must only treat explicit shipping/delivery-to-country text as a foreign region; do not scan arbitrary product titles/descriptions for country names, because product titles can mention countries and trigger false reload/lock loops
  - add-to-cart fails closed and re-normalizes the page if SHEIN is not on Saudi/USD

- Admin order issue handling:
  - admin can select a specific product inside an order
  - issue types cover price, size, color, custom photo, custom text, unavailable item, quantity, bad link, and other
  - customer WhatsApp copy now says the order needs an action, not only a payment issue
- Admin order list behavior:
  - no order opens automatically unless opened from a deep link
  - tapping an order opens it
  - long press / context selection supports bulk delete
- Admin mobile operations cleanup:
  - driver creation form is collapsed behind "add driver"
  - coupon creation form is collapsed behind "create coupon"
- Product profit setting:
  - `product_profit_percent` is stored in `app_settings`
  - app applies it to product prices only
  - it is not shown as a separate line to customers
- Customer app updates:
  - order cards show a small store badge for SHEIN/Temu
  - tracking shows compact product rows
  - tracking timeline is smaller
- Notifications/deployment behavior:
  - new-order Telegram notification now tries the Railway/WhatsApp server `/api/orders/notify` first
  - Supabase `telegram-notify` remains only a fallback
- Android:
  - default Capacitor splash image was removed from the launch theme
  - Android launch background now uses app colors

## What is restored and working

- SHEIN opens in Arabic through `m.shein.com/ar` with Saudi Arabia + USD forced in the URL, cookies, storage, and navigation guard
- customer profile is tied to phone number
- previous orders return after login with same number
- wallet flow exists in current branch
- group order flow exists in current branch
- coupon system is restored:
  - admin coupons tab
  - `admin-coupons` edge function
  - `redeem_coupon(...)` RPC path in app/backend
- admin mobile layout was tightened
- driver deletion was restored
- obsolete "open customer app" admin link was removed

## Where admin is connected

Admin frontend calls Supabase Edge Functions directly using:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `x-admin-pin`

Functions used by admin:

- `admin-orders`
- `admin-drivers`
- `admin-coupons`
- `app-settings`

## Why old admin/features came back before

Because two lines of work existed:

1. `codex/customer-wallet-group-orders`
2. `claude/brave-gould-c49b60`

The current branch had newer wallet/group-order work.
The other branch had newer coupon/admin work.
If someone reads only one old context file or assumes `main` is newest, old UI/features can reappear.

## Rules for any future AI

1. Do not assume `main` is latest.
2. Read `CURRENT_STATE.md` first.
3. Read `AI-HANDOFF.md` second.
4. Before saying a feature was "deleted", search current branch and branch history.
5. Before changing admin UI, inspect `admin/src/AdminApp.tsx` on the active branch.
6. Do not use old context files as source of truth if they conflict with this file.
7. Before deploying or building, confirm the active branch is `codex/customer-wallet-group-orders` and that these latest admin/product-issue/profit changes are present.
8. Do not restore admin UI from older branches unless manually cherry-picking only reviewed changes.

## Deployment state

- Latest AI guardrail / cleanup commit:
  - `5ce98a0` (`Add AI handoff guardrails`)
- Latest successful GitHub iOS unsigned build after guardrails:
  - Run: `https://github.com/m7madv/otlobli/actions/runs/28971384749`
  - Head SHA: `5ce98a0878d3dab12eeec24170505f08901e432b`
- Customer-data reset helper:
  - `supabase/RESET_CUSTOMER_DATA.sql`
  - This file clears customer/order/wallet/group-cart runtime data while keeping settings, coupons, catalog, and drivers.
  - It was not executed automatically because local env files do not contain a usable Supabase service role/database password.
- Latest deployed feature commit:
  - `6d5988d` (`Add admin issue workflow and mobile polish`)
- Customer production URL:
  - `https://talabieh.vercel.app`
- Admin production URL:
  - `https://talabieh-admin.vercel.app`
- Customer production project:
  - Vercel project `talabieh`
- Admin production project:
  - Vercel project `talabieh-admin`
- Supabase project ref:
  - `dcicqdprtyhwmhegabay`
- Supabase functions deployed in latest update:
  - `cart-groups`
  - `admin-orders`
  - `app-settings`
- Supabase setting applied:
  - `product_profit_percent = 0`
- Latest successful GitHub iOS unsigned build:
  - Run: `https://github.com/m7madv/otlobli/actions/runs/28935943927`
  - Head SHA: `acbbed7998e0fce339c5ab7281872240a58854dd`
  - Artifact: `otlobli-ios`
- Previous successful iPhone unsigned build run:
  - `https://github.com/m7madv/otlobli/actions/runs/28792148789`

## Short chat summary

- restored coupon system into current branch
- restored admin coupons tab
- deployed `admin-coupons` and `admin-drivers`
- redeployed admin dashboard
- pushed branch updates to GitHub
- documented why old admin state had returned
- added admin product/order issue workflow with WhatsApp action messages
- added bulk order selection/delete and stopped automatic order opening
- collapsed driver/coupon creation forms for phone-friendly admin work
- added hidden product-profit setting
- added store badges and compact tracking products in customer app
- fixed Telegram notify path preference and Android launch splash background
- fixed group cart deep links for WhatsApp/app opening
- fixed incoming group-cart invites being hidden by a stale local cart group on the recipient device
- switched group cart membership from phone-only identity to per-device member keys and verified same-phone/two-device joining in production
- locked SHEIN customer browsing to Saudi Arabia + USD before product capture/add-to-cart
