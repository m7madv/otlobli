# Otlobli Current State

Last updated: 2026-07-14

## Start Here

Repository: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`

Branch: `codex/customer-wallet-group-orders`

Before any edit:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

Read `AI-HANDOFF.md` and `AGENTS.md`. Preserve any existing user/other-AI changes.

## Active Store Baseline

- SHEIN/store baseline is v85 commit `2f24954` (`fix: v85 polish iOS nav and selection behavior`).
- v85 artifact: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.ipa`
- v85 SHA-256: `F4524E816E6243A039BD52D34E7A9AB59E3C5597DBF0515862BA5F9461B90ED4`
- v85 GitHub Actions run: `29293816845`
- `APP_VERSION = 2026.07.14-nav-polish-no-select-v85`.
- Local rollback commits `4854d5f` and `875220c` restore the store files to v85. They are not pushed because pushing this branch automatically builds iOS.
- These files match `2f24954` byte-for-byte:
  - `src/App.tsx`
  - `src/services/sheinBrowserScript.ts`
  - `src/config.ts`
  - `src/styles.css`

v85 itself inherits the older hidden `FAKE_VISIBLE` flow and a limited exact-key storage guard. Do not alter those while establishing the baseline; first collect and isolate the user's real-device issues.

## Failed Paths

- v86, v87, and v88 are failed/archived paths. Do not continue from them.
- v87 did not fix the reported SHEIN issues.
- v88 regressed opening SHEIN: the WebView/app closed or crashed on entry.
- Do not reuse their broad region/storage intervention, extra reload/setUrl behavior, blocker heuristics, or warm-up close/reopen flow.
- Do not claim any SHEIN issue is fixed without real-device testing on iPhone 6 and iPhone 16 Pro Max.

## Current Task

- No new store fix is active.
- Next step is to receive the complete SHEIN issue inventory from the user, group related symptoms, then fix one root cause at a time from v85.
- Do not build an IPA until the proposed single change and its exact diff are explained.

## Scope Guard

- Do not change payment, wallet, completed orders, coupons, group checkout, or Temu during the SHEIN pass.
- No broad CSS, viewport-width hacks, white shields, or hiding SHEIN sections/options.
- Designs come from Figma only.
- Prefer targeted `rg` and Git diffs; old version history stays in Git, not in these handoff files.

## Last Validation

- `npm run build` passed.
- Injected `SHEIN_CAPTURE_SCRIPT` syntax parse passed.
- `git diff --check` passed.
- No rollback IPA was built.

## Production References

- Customer: `https://talabieh.vercel.app`
- Admin: `https://talabieh-admin.vercel.app`
- Supabase project: `dcicqdprtyhwmhegabay`
