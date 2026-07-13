# Otlobli AI Quick Handoff

Use this file to continue work with minimal context. Do not spend tokens re-discovering old history unless the task requires it.

## Start Here

Repository:

```text
C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA
```

Active branch:

```text
codex/customer-wallet-group-orders
```

Before editing, run:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

Then read, in this order:

1. `AGENTS.md`
2. `CURRENT_STATE.md`
3. `AI-HANDOFF.md`
4. `CLAUDE.md` if using Claude Code

## Golden Rules

- Do not assume `main` is latest.
- Do not restore code from old branches unless explicitly comparing and cherry-picking only the needed lines.
- Treat existing modified/staged/untracked files as possible user or other-agent work. Do not revert them blindly.
- Do not change payment, wallet, completed-order, coupon, or group-cart logic unless the user explicitly asks.
- After every stable change, update `CURRENT_STATE.md`, `AI-HANDOFF.md`, and `SESSION_SUMMARY.md`.
- Designs must come from Figma. Do not invent visual redesigns outside Figma.

## Main Files

- Customer app: `src/App.tsx`
- Browser injection for SHEIN/Temu: `src/services/sheinBrowserScript.ts`
- App API: `src/services/appApi.ts`, `src/services/supabaseAppApi.ts`, `src/services/localAppApi.ts`
- Storage/device/session helpers: `src/infrastructure/localStorage.ts`
- Types: `src/domain/types.ts`
- Admin app: `admin/src/AdminApp.tsx`
- Admin CSS: `admin/src/styles.css`
- Database schema: `supabase/schema.sql`
- Supabase functions:
  - `supabase/functions/cart-groups`
  - `supabase/functions/admin-orders`
  - `supabase/functions/admin-coupons`
  - `supabase/functions/admin-drivers`
  - `supabase/functions/app-settings`

## Current Stable Behavior

- Customer app and admin app build successfully.
- Android debug APK has been built and installed on emulator `emulator-5554`.
- Latest iOS unsigned GitHub build succeeded:
  - `https://github.com/m7madv/otlobli/actions/runs/28971714444`
- Active branch is pushed to GitHub:
  - `origin/codex/customer-wallet-group-orders`
- `supabase/RESET_CUSTOMER_DATA.sql` exists for clearing customer/order/wallet/group-cart runtime data, but it was not executed automatically because no usable admin DB/service-role secret was available locally.

## Fragile Areas

### SHEIN

SHEIN must stay on:

```text
https://m.shein.com/ar/
```

Required state:

- Country: Saudi Arabia / `SA`
- Currency: `USD`
- Language: Arabic
- Mobile `site_uid`: `pwar`
- Headers: keep `Accept-Language: ar-SA`; do not spoof a custom User-Agent

Do not:

- Switch SHEIN back to `/jo`, `/lb`, `/ar-en`, or desktop URLs.
- Broadly overwrite storage keys containing `country`, `currency`, `lang`, etc.
- Treat arbitrary country names inside product titles/descriptions as wrong region.
- Bypass human verification. If SHEIN shows “I am human”, keep it clickable.

### Temu

- Keep otlobli bottom nav fixed and visible inside the WebView.
- Keep Temu search visible.
- Hide only confirmed Temu account/cart/login distractions.
- Do not hide product content or block product images.

### Group Cart / Order With a Friend

- Invite links must work from WhatsApp.
- Recipient confirms before linking cart.
- Cart sync should be quick.
- Link should stop being useful after checkout/order completion.

### Admin

- Do not auto-open the first order.
- Mobile admin layout matters.
- Existing current features include: coupons, drivers, product issue handling, wallet/order actions, order selection/delete.

## Build Commands

Customer app:

```bash
npm run build
```

Admin:

```bash
cd admin
npm run build
```

Android:

```bash
npm run build
npx cap sync android
cd android
./gradlew assembleDebug
```

APK path:

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

iOS unsigned GitHub build:

```bash
gh workflow run ios-unsigned-build.yml --ref codex/customer-wallet-group-orders
```

## Known Cleanup Notes

- A dangerous uncommitted Claude WIP was previously backed up and removed because it reverted SHEIN to older `/jo` behavior and removed important group/wallet schema.
- Local untracked clutter was archived to Temp during cleanup.
- If a new AI sees old docs, it must prefer `AGENTS.md`, `CURRENT_STATE.md`, `AI-HANDOFF.md`, and this file.

## Response Style For The User

User prefers Arabic status updates. Keep them short, direct, and practical.

