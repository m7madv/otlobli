# Otlobli Current State

Last updated: 2026-07-06

## Use this file first

If any AI continues work on this repo, use this file and `AI-HANDOFF.md` first.
Do not trust older context files before checking these two files.

## Active source of truth

- Branch: `codex/customer-wallet-group-orders`
- Latest feature deployment commit: `6d5988d`
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

- SHEIN opens in Arabic through `ar.shein.com`
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
  - `admin-orders`
  - `app-settings`
- Supabase setting applied:
  - `product_profit_percent = 0`
- Latest successful GitHub iOS unsigned build:
  - Run: `https://github.com/m7madv/otlobli/actions/runs/28813650154`
  - Head SHA: `6d5988d9f15592fcb3a3eec049da66ae32a79eb2`
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
