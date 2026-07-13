# Claude Code Notes

Use this file when working in Claude Code on this project.

## First Steps

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

Then read:

1. `CURRENT_STATE.md`
2. `AI-HANDOFF.md`
3. `AGENTS.md`

Do not start from `main`. The active branch is usually:

```text
codex/customer-wallet-group-orders
```

## New Claude Account Warning

The user has a new Claude Code account on the same computer. Do not assume every connector/skill is authenticated.

- Check available skills/tools before using them.
- Figma is required for design work and may need reauthentication.
- If Figma is unavailable, say that clearly and ask the user to reconnect Figma; do not invent a design.
- Use any available browser/WebView/testing skills for SHEIN/Temu debugging.
- Keep context usage low. Read the short handoff files first and avoid old history unless needed.

## Current Main Issue

v69 fix is pushed and the iPhone IPA is built:

- Temu opens/redirects to Saudi `/sa/` with USD params, but no longer reloads product-back/root URLs only because currency params are absent.
- Temu writes exact Saudi/USD session keys and hide filters skip price-looking elements.
- SHEIN security challenge pages keep a minimal otlobli bottom nav.
- App ignores page-load errors during normal SHEIN opening so the black security challenge does not close the WebView.
- Store switch no longer clears all cookies automatically; SHEIN writes Saudi shipping/currency keys during challenge.
- Wallet balance RPC errors no longer show false zero.
- App version is `2026.07.13-store-stability-v69`.
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v69.ipa`
- IPA SHA-256: `B4EE4E92D2F7AA383309120AE514515C37055576EFCA67F8E92A2B20900E04A0`

Symptoms reported before this fix:

- SHEIN page behaves like a static image.
- Taps are unreliable.
- Black `m.shein.com` security verification can appear.
- App may exit or reopen into the same verification flow.
- VPN/load failure can degrade to a blank page if not handled.

Investigate store-switch lifecycle:

- WebView remount/key behavior.
- Store-specific script injection separation.
- Temu CSS/JS leaking into SHEIN.
- SHEIN session persistence after switching.
- Whether failed challenge/load URLs are reused.
- Whether a failed SHEIN WebView should be torn down and rebuilt.

Do not bypass captcha/security pages. Keep them usable and avoid breaking the WebView.

## Fragile Areas

- SHEIN should stay on mobile Arabic/Saudi/USD behavior.
- Keep `site_uid` as `pwar` on mobile SHEIN.
- Do not spoof a custom User-Agent; use `Accept-Language: ar-SA` only if needed.
- Do not broadly overwrite every storage key with `country`, `currency`, or `lang`.
- Do not treat country names inside product titles/descriptions as wrong-region signals.
- Temu search must remain visible and stable.
- Do not change payment, wallet, completed-order, coupon, or group-checkout logic unless explicitly asked.

## Main Files

- `src/App.tsx`
- `src/services/sheinBrowserScript.ts`
- `src/services/appApi.ts`
- `src/services/supabaseAppApi.ts`
- `src/infrastructure/localStorage.ts`
- `src/domain/types.ts`
- `admin/src/AdminApp.tsx`
- `admin/src/styles.css`
- `supabase/schema.sql`
- `supabase/functions/admin-orders/index.ts`

## Build Commands

Customer:

```bash
npm run build
```

Admin:

```bash
cd admin
npm run build
```

iOS unsigned GitHub build:

```bash
gh workflow run ios-unsigned-build.yml --ref codex/customer-wallet-group-orders
```

Do not publish or build artifacts unless the user asks or a fix is ready for release.
