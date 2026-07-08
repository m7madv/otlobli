# Otlobli System Handoff

Read `CURRENT_STATE.md` first.
If this file conflicts with older context files, prefer `CURRENT_STATE.md` and the active branch code.

## AI continuity protocol

This repo is shared between Codex, Claude Code, and possibly other agents. Before changing code, every agent must:

1. Read `AGENTS.md`.
2. Read `CURRENT_STATE.md`.
3. Read this file.
4. Run `git status --short`, `git rev-parse --abbrev-ref HEAD`, and `git log -5 --oneline`.
5. Treat existing modified/staged/untracked files as user or other-agent work. Do not revert or overwrite them.

If the session gets long, or the user mentions billing/context limits, update `SESSION_SUMMARY.md` and include a copyable chat summary in the final response. Agents usually cannot know the user's real billing limit, so do not claim certainty about it.

Current known Claude/Codex failure mode:

- reading old docs or old branches
- assuming `main` is current
- replacing current admin/customer files with older copies
- reintroducing old SHEIN WebView assumptions such as broad storage overwrites, custom User-Agent spoofing, or country-name scanning inside product titles

Prevent this by updating `CURRENT_STATE.md`, `AI-HANDOFF.md`, and `SESSION_SUMMARY.md` after every stable change.

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
