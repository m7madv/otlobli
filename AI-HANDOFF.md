# Otlobli System Handoff

Read `CURRENT_STATE.md` first.
If this file conflicts with older context files, prefer `CURRENT_STATE.md` and the active branch code.

## Claude: the fix below (session 2) did NOT work - real cause was iOS window.close() (2026-07-13, session 3)

**Important meta-lesson, not just a bug fix:** the session-2 fix was reasoned
entirely from Android's native plugin source. The user has only ever tested
iOS. Retesting showed zero change. Before reasoning about native WebView
behavior in this plugin again, **check the platform the user is actually
testing on and read that platform's native source specifically** - Android's
`WebViewClient` and iOS's `WKNavigationDelegate` do NOT expose the same
error/event surface (confirmed: Android's `onReceivedError` fires per failed
sub-resource; iOS's `didFail`/`didFailProvisionalNavigation` are main-frame-
navigation-only, with zero visibility into sub-resource failures).

Real cause, found in `WKWebViewController.swift`: the plugin unconditionally
wires the page's own `window.close()` to a native `dismiss()`, no gating,
never touching any JS the app controls. Cloudflare's challenge script is
known to call `window.close()` defensively against embedded/atypical
browser contexts. Fixed via a new `ignorePageWindowClose` plugin option
(patch file + `src/App.tsx`). Full detail in `CURRENT_STATE.md`'s session-3
entry - read it before touching `WKWebViewController.swift`,
`InAppBrowserPlugin.swift`, or anything close/dismiss-related again.

No Mac/Xcode here - Swift verified only via `npm run build` typecheck and the
GitHub Actions iOS workflow actually compiling it. Real-device confirmation
is still pending.

## Claude: real root cause of the SHEIN switch-bug (2026-07-13, session 2)

The session-1 cache/cookie fixes below were real but not the main cause.
User tested on a real iPhone: Cloudflare's challenge shows (Arabic-
localized), then ~2 seconds later the user is kicked back to otlobli's blank
home screen. Traced to `pageLoadError` in `src/App.tsx`: that event fires for
ANY failed sub-resource (confirmed by reading the native plugin's
`onReceivedError` wiring, not just theorized), and SHEIN's challenge loads a
script from a different domain (`challenges.cloudflare.com`) that can fail
transiently over the VPN. v66's "store recovery" treats that as fatal and
tears the session down via a 1800ms timer - matches the ~2s report exactly.
Fixed with a `humanChallengeSeenRef` gate plus a language-agnostic "Ray ID:"
detection signal (English-only "just a moment" title check missed the
Arabic-localized page). Full detail in `CURRENT_STATE.md`'s 2026-07-13
"session 2" entry - read it before touching `pageLoadError`, `humanCheck`, or
`otlobliIsHumanChallenge` again.

Also switched Temu's forced region from Jordan to Saudi Arabia per user
request (`STORES` array + the locale-redirect target in `src/App.tsx`).
Currency stays tied to the region's native storefront (SAR now, was JOD) -
already-documented prior testing in this repo found Temu rejects URL-based
currency overrides, so "force USD" independent of region isn't possible
without an English (non-Arabic) Temu storefront.

## Claude: branch was stale, now synced + SHEIN switch-bug fixes (2026-07-13)

This worktree (`claude/competent-nash-557dc5`) started 40 commits behind
`codex/customer-wallet-group-orders` - stuck at v52, missing v53 through
v66.3 entirely. Merged `origin/codex/customer-wallet-group-orders` in first
(clean, no conflicts) before changing anything. **Check
`git log --oneline --all --decorate` on any fresh worktree in this repo
before trusting its files** - there are several stale AI branches parked at
different old points, exactly the failure mode `AGENTS.md` warns about.

Fixed two concrete gaps in v66.3's SHEIN-store-switch WebView cleanup (full
detail in `CURRENT_STATE.md`'s 2026-07-13 entry):
- `clearAllCookies()` raced its own native async removal in the patched
  `@capgo/capacitor-inappbrowser` plugin - fixed in the patch file to await
  the real callback.
- The native HTTP cache was never cleared (only the JS Cache Storage API
  was) - added a `clearCache()` call in `switchStore`, before `close()`.
- IndexedDB now clears alongside Cache Storage in the injected script, for
  symmetry.

`npm run build`, `npx cap sync android`, and `./gradlew assembleDebug` all
pass; a real debug APK was produced. **Not verified on a real device** - this
environment has no way to reproduce the Syria/VPN/Cloudflare condition the
bug needs. Treat this as "closed two real gaps", not "confirmed root-cause
fix", until the user tests it.

## Active Codex/Claude split (2026-07-12)

- Codex owns SHEIN/Temu/VPN/WebView and shared-cart invite-link behavior.
- Claude received the shared-order ownership, issue routing, pickup recipient,
  structured issue options/photo responses, and admin order-selection task, but hit
  its usage limit before editing. Branch `claude/otlobli-shared-orders-issues-0eeae1`
  and its worktree remain clean at `cf4b53c`; there is nothing to cherry-pick.
- Current Codex changes in `src/App.tsx`: auto-join invite links even with empty carts,
  show group-order controls in an empty cart, recheck VPN after native page-load failure,
  and avoid rewriting SHEIN verification URLs. Root build passes.
- Do not implement new visual styling until Figma is reauthenticated; Figma remains
  the only design source.

Current integrated work after Claude/Codex agents hit usage limits:

- Codex took over and completed the shared-order/admin/store implementation locally.
- Root/admin builds pass; `git diff --check` passes.
- Migration `20260712033000_shared_order_ownership.sql` is applied to production and
  `admin-orders` is deployed.
- Ownership/delivery values are resolved against server-side `cart_group_members` and
  `cart_group_items`, not trusted from client phone/name fields.
- Customer/admin Vercel production deployments are READY and aliases return HTTP 200;
  customer production JS was verified to contain v66.
- Release commit `f7b4456` is pushed and GitHub iOS run `29175819975` succeeded.
  Desktop artifact `otlobli-v66.ipa` SHA-256 is
  `6724eb9d147e780aac7d868853d341cb3a416e2d7c856300f6acc3db6372e6b1`.

## AI continuity protocol

This repo is shared between Codex, Claude Code, and possibly other agents. Before changing code, every agent must:

1. Read `AGENTS.md`.
2. Read `CURRENT_STATE.md`.
3. Read this file.
4. Run `git status --short`, `git rev-parse --abbrev-ref HEAD`, and `git log -5 --oneline`.
5. Treat existing modified/staged/untracked files as user or other-agent work. Do not revert or overwrite them.

If the session gets long, or the user mentions billing/context limits, update `SESSION_SUMMARY.md` and include a copyable chat summary in the final response. Agents usually cannot know the user's real billing limit, so do not claim certainty about it.

## Latest Claude v65 app handoff (2026-07-12)

Claude's v58→v65 implementation summary is recorded at the top of `SESSION_SUMMARY.md`
and committed as `cf4b53c`. Treat it as the current app/UI handoff: v65 APK/IPA artifacts,
structured order issues, invoice/wallet/support updates, VPN checks, SHEIN/Temu fixes, and
WhatsApp message/prekey changes are documented there. Real-device verification is still needed
for SHEIN/Temu. Keep Note 8 hardware/firmware work separate from this app scope.

Current known Claude/Codex failure mode:

- reading old docs or old branches
- assuming `main` is current
- replacing current admin/customer files with older copies
- reintroducing old SHEIN WebView assumptions such as broad storage overwrites, custom User-Agent spoofing, or country-name scanning inside product titles

Prevent this by updating `CURRENT_STATE.md`, `AI-HANDOFF.md`, and `SESSION_SUMMARY.md` after every stable change.

## Active Codex scope: Note 8 / ShamCash / payment security (2026-07-11)

- Claude is working concurrently on UI/store behavior. Preserve its commits and do not
  edit customer/admin UI for this scope.
- Production migrations `20260712020000` and `20260712021000` are applied. The latter
  removes an overload ambiguity in the authenticated profile wrapper found by remote lint.
- `payment-webhook` v9 is deployed `ACTIVE`, `verify_jwt=false`, and uses HMAC rather
  than Supabase JWT. Never re-enable the old plaintext `x-payment-secret` header.
- The rotated HMAC value is intentionally absent from git. Retrieve it from Windows
  Credential Manager target `Otlobli/ShamCashWebhookSecret` only while provisioning the
  protected ADB receiver; never print it in logs or responses.
- Signed APK ready at
  `android/shamcash-listener/build/outputs/apk/release/shamcash-listener-release.apk`.
  SHA-256 is `343f0213d837410b0a4069a67ece69a2cc65b8aba3c3140f65d0663ecfb226b5`.
- `20260712022000` blocks the exploitable descending unique-amount ladder and limits
  each customer to one active wallet top-up; `20260712023000` safely retries only recent
  unmatched events for two minutes. Both are applied to production.
- Exchange-rate synchronization is deployed from commits `d0ac78f` and `9f42cf5` as Railway deployment
  `32116896-5c2c-4088-b8d5-40c7a058ba44` (`SUCCESS/RUNNING`). The public endpoint and
  `app_settings.usd_to_syp_rate` both verified at `13050`; cached responses are DB-
  revalidated and marked `Cache-Control: no-store`. Railway currently has one replica,
  so the in-process single-flight covers the active topology.
- Release code contains no `TEST_NOTIFICATION` action and no `x-payment-secret` header.
  Do not reintroduce either. A genuine ShamCash notification capture remains a release
  gate because the provider transaction/reference layout is not yet known.
- Migrations `20260712031000_sync_structured_payment_issues.sql` and
  `20260712032000_include_wallet_usd_history.sql` are applied. The first prevents
  duplicate structured payment-issue charges and blocks customer-side payment-issue
  resolution; `admin-orders` version 28 derives issue totals from unresolved entries
  and uses `order_items.product_id`. The second preserves historical wallet USD values.
  The admin function also preserves resolved issue entries when an old browser draft
  is saved after a newer customer action.
- ADB now sees serial `988e16384e4f51395230` as authorized `device` (`SM-N950F`). Do not
  replace the installed debug listener yet: the user requested a stock reset, and the
  physical battery-temperature fault must be repaired before a reset/flash. After the
  stock restore, install the signed release, provision via the
  `android.permission.DUMP`-protected receiver, re-enable notification-listener access,
  and battery-whitelist it.
- Do not run ShamCash on the PC. End-to-end ShamCash notification testing must happen on
  the Note 8 while it has the Syrian network.
- Battery blocker is reconfirmed, not hypothetical: six USB-powered samples were 0%,
  `Cold`, -20 C, ADC `3950..3986`, `3.386..3.387 V`, current 0, `Not charging`. Reseat or
  replace the compatible battery/flex first; if ADC remains near 3950, repair the NTC/
  connector/board trace. Never bridge the thermistor or force charging. The only Magisk
  service/module found is `/data/adb/service.d/fakebattery.sh`, SHA-256
  `9575a5e9dd37e4f1d6a738a3b83b5159816d9eb254f825fcd98c1c895a526e95`; it only fakes
  BatteryService every 15 seconds to keep Android alive and must remain until raw sysfs is
  sane. Restore target after repair: stock/no-root `XSG` `N950FXXUGDVG7`, baseband
  `N950FXXSGDUG6`. Do not pursue exact 80% via root or a custom kernel on a payment device.
- Remote control is not finished: TeamViewer Host and AnyDesk are installed for testing;
  the user must personally accept Samsung Knox terms and assign their own account/password.
  Prefer TeamViewer Host if full control activates, then remove AnyDesk; otherwise verify
  AnyDesk's official Samsung plugin/accessibility flow and remove TeamViewer.
- Pricing/group trust is still incomplete: order totals and item prices originate from
  client/WebView data, and group snapshots are not yet authoritative. Exact-amount and
  webhook integrity are hardened, but server-issued price quotes and authenticated group
  checkout must be completed before describing the entire commerce path as tamper-proof.

## أحدث تعديل (Claude — تيمو: إخفاء أزرار الهيدر + منع صفحة الدخول)

غير ملتزم بعد (2026-07-09). التفاصيل الكاملة في `SESSION_SUMMARY.md`.

- أزرار هيدر تيمو (عربة/حساب/فئات) = `DIV.tab-d3nPD` داخل حاوية `display:none`
  (أبعاد `0x0`، أسماء في `aria-label` فقط). حُجبت عبر CSS محقون في
  `injectTemuHeaderHideCSS()` بـ `[class*="tab-d3nPD"]` — يبقى البحث والشعار فقط.
- صفحة `login.html` في تيمو تُمنع عبر `urlChangeEvent` في `App.tsx` وتُعاد للرئيسية.
- لا تُعِد المنطق القديم المعتمد على موقع/أبعاد/نص لأزرار تيمو — كان يفشل لأن
  الأزرار `0x0` وبلا نص. استعمل الـ class/`aria-label`.

## Latest cleanup note

- Commit `5ce98a0` adds guardrail docs for future AI sessions.
- The active branch `codex/customer-wallet-group-orders` was pushed back to GitHub and should be used for iOS builds.
- iOS unsigned build succeeded at `https://github.com/m7madv/otlobli/actions/runs/28971384749`.
- A dangerous uncommitted WIP was found and backed up locally before removal. It reverted SHEIN to older `/jo` assumptions and removed group/wallet schema from `supabase/schema.sql`.
- Supabase customer data was not deleted automatically because no usable service role/database password was present locally. Use `supabase/RESET_CUSTOMER_DATA.sql` from Supabase SQL Editor after backup.

## Current working branch

- Branch: `codex/customer-wallet-group-orders`
- Important: this branch contains the latest admin/product-issue/profit/mobile-admin update. Do not replace it with older admin code from `main` or `claude/brave-gould-c49b60`.
- Base divergence point from older mainline: `df394fb`
- Recent branch-only commits:
  - `c5d0831` customer wallet/group ordering foundation
  - `bc62ebc` Arabic SHEIN + live group ordering
  - `bf7f171` lint/build cleanup
  - `7478034` wallet/profile/ShamCash/admin updates
  - `2154036` ShamCash checkout/admin session/referral settings updates

## Why the admin panel looked "old"

There were two separate development lines:

1. `codex/customer-wallet-group-orders`
   - focused on customer profile, wallet top-up flow, group orders, Arabic SHEIN, ShamCash by store, admin session persistence

2. `claude/brave-gould-c49b60`
   - carried the richer admin/coupon line after `df394fb`
   - important commits on that line:
     - `a96d176` full coupon system in app/backend
     - `f4e846d` admin coupons tab + `admin-coupons` edge function
     - `1f49308` richer customer/admin documentation
     - `f92bccb` admin store filter
     - `194691e` blocked users + old ShamCash barcode settings + profit margin
     - `9450884` USD-wallet line

The current branch had the newer wallet/group-order work, but it did **not** contain the coupon/admin branch history. That is why coupon UI and the admin coupon section disappeared even though they existed elsewhere in repo history.

## What was restored in this cleanup

Restored from the newer admin/coupon line into the current branch:

- Full coupon backend schema:
  - `supabase/schema.sql`
  - tables: `coupons`, `coupon_redemptions`
  - RPC: `redeem_coupon(...)`
- Admin coupon management edge function:
  - `supabase/functions/admin-coupons/index.ts`
- Customer app coupon wiring:
  - `src/infrastructure/localStorage.ts` adds stable `getDeviceId()`
  - `src/services/appApi.ts` adds `redeemCoupon`
  - `src/services/localAppApi.ts` safe local fallback
  - `src/services/supabaseAppApi.ts` RPC call to `redeem_coupon`
  - `src/App.tsx` adds coupon input + applied discount in checkout
- Admin dashboard coupon tab:
  - `admin/src/AdminApp.tsx`
  - `admin/src/styles.css`

Also clarified naming:

- `referral_discount_syp` is now treated as **referral discount**
- coupon codes are now a separate feature again, not mixed into referral settings

## Current feature map

### Customer app

- Main shell: `src/App.tsx`
- Full-name validation: `src/domain/profile.ts`
- Pricing helpers: `src/domain/pricing.ts`
- Local persisted state: `src/infrastructure/localStorage.ts`
- Supabase app API: `src/services/supabaseAppApi.ts`

### Admin dashboard

- Main app: `admin/src/AdminApp.tsx`
- Styles: `admin/src/styles.css`
- Latest admin behavior:
  - orders do not auto-open by default
  - tapping an order opens it
  - long press/context selection supports bulk delete
  - product/order issue form can target a specific item and issue type
  - driver and coupon creation forms are collapsed behind explicit action buttons
  - settings include hidden `product_profit_percent`
- Runtime wiring:
  - `VITE_SUPABASE_URL` -> builds the function endpoints
  - `x-admin-pin` -> authenticates admin requests
  - functions used by admin:
    - `admin-orders`
    - `admin-drivers`
    - `admin-coupons`
    - `app-settings`
- Orders/customers/wallet adjustments still use current-branch admin flow
- Coupon management now lives in the `coupons` tab

### Supabase

- Canonical schema: `supabase/schema.sql`
- Customer profile edge function: `supabase/functions/customer-profile/index.ts`
- Admin orders edge function: `supabase/functions/admin-orders/index.ts`
- Admin coupons edge function: `supabase/functions/admin-coupons/index.ts`
- App settings edge function: `supabase/functions/app-settings/index.ts`
- Telegram notifications: `supabase/functions/telegram-notify/index.ts`
- Latest backend notes:
  - `admin-orders` sends a generic customer action-needed WhatsApp message for product/order issues
  - `app-settings` default includes `product_profit_percent`
  - `schema.sql` inserts `product_profit_percent` into `app_settings`

## Important behavioral notes

- Coupon redemption is consumed at apply time by `redeem_coupon(...)`, matching the historical coupon implementation that existed on the other branch.
- Referral discount is separate from coupons and still uses `check_referral_code(...)`.
- Group ordering stays on the current branch implementation and was intentionally not replaced by the other branch.
- Latest group invite fix: when an invite URL is opened, `src/App.tsx` clears only a different locally-saved `cartGroup` before showing the recipient confirmation card. This prevents a stale one-person group from hiding the incoming WhatsApp invite and showing "waiting for friend" instead.
- Android now registers `https://talabieh.vercel.app/group` in addition to `otlobli://` and `https://otlobli.app/group`, matching the current invite link origin from `buildGroupInviteLink`.
- Latest group-cart architecture fix: membership/items now use a per-device `memberKey` instead of phone-only identity. This allows two devices using the same WhatsApp phone during testing to still become two group members, and production Supabase was verified with same phone + different member keys returning `members=2` and both owners' products. Each create action now creates a new group code/link.
- Group totals and per-person shares are shown through the app currency formatter from SYP totals/exchange rate, not as a hard-coded dollar-only `$current / $40` line.
- The current customer wallet/top-up path remains the current-branch one. I did **not** switch the app onto the older USD-wallet branch to avoid breaking the newer wallet/top-up flow.
- New-order Telegram notification should go through the Railway/WhatsApp server `/api/orders/notify` first. The Supabase `telegram-notify` function is fallback only.
- Product profit is intentionally hidden from customers and applied into product price calculations, not as a visible checkout line.
- Android launch theme must not use the default Capacitor `@drawable/splash` image.

## Deployment checklist after this cleanup

1. Apply `supabase/schema.sql`
2. Deploy edge function:
   - `supabase/functions/admin-coupons`
   - `supabase/functions/admin-orders`
   - `supabase/functions/app-settings`
3. Build and verify:
   - root app
   - admin dashboard
4. Deploy Vercel projects:
   - root app -> `talabieh`
   - admin -> `talabieh-admin`
5. Test manually:
   - create coupon from admin
   - apply coupon in checkout
   - verify referral discount still works
   - verify group order checkout still works
   - mark product/order issue and confirm WhatsApp/action banner behavior
   - confirm admin order list does not auto-open the first order

## If another AI continues from here

Treat this branch as the active source of truth, with these caveats:

- coupon/admin functionality was backfilled from `claude/brave-gould-c49b60`
- wallet/group-order/ShamCash-by-store behavior comes from `codex/customer-wallet-group-orders`
- do not assume `main` contains the latest admin features
- when auditing missing features, search both:
  - current branch history
  - branch `claude/brave-gould-c49b60`

## Short answer: why did the old admin come back?

- because this branch had the wallet/group-order work
- while another branch had the newer admin/coupon work
- so editing only this branch without backfilling the newer admin commits made the dashboard look older again

## Source of truth to use from now on

- customer app: current branch `codex/customer-wallet-group-orders`
- admin dashboard on this branch after this cleanup:
  - `admin/src/AdminApp.tsx`
  - `admin/src/styles.css`
- first-read docs:
  - `CURRENT_STATE.md`
  - `AI-HANDOFF.md`
- remote admin deployment:
  - `https://talabieh-admin.vercel.app`
- remote app deployment:
  - `https://talabieh.vercel.app`
  - Vercel project `talabieh`
- remote data/backend:
  - Supabase project `dcicqdprtyhwmhegabay`
- latest deployed feature commit:
  - `6d5988d`
- latest iOS unsigned GitHub build:
  - `https://github.com/m7madv/otlobli/actions/runs/28813650154`
  - artifact: `otlobli-ios`
