# Otlobli Current State

Last updated: 2026-07-11

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
- Railway deployment `63fd12de-3c29-4c7b-8646-72600400de85` is `SUCCESS/RUNNING`
  from isolated commit `d0ac78f`. `/api/exchange-rate` now persists the live rate before
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
