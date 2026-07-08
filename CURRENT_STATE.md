# Otlobli Current State

Last updated: 2026-07-08

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
  - iOS registers the `otlobli://` URL scheme
  - recipient sees a confirmation card before linking their cart
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
- locked SHEIN customer browsing to Saudi Arabia + USD before product capture/add-to-cart
