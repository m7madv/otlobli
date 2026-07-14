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
- v85.1 category-touch test commit: `8282091`.
- v85.1 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.1-shein-category-touch-test.ipa`
- v85.1 SHA-256: `9AB2149845E43E81D120E169CD7C85DF9DAE0F022B23DE86C38BF4ADB73A03B0`
- v85.1 GitHub Actions run: `29300495130`.
- v85.1 narrows header/menu blocking to icon-only controls and removes v85's broad category layout restyling loop. It does not change the hidden WebView flow or region logic.
- v85.2 candidate commit: `294dd78`.
- v85.2 test IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.2-shein-saudi-auth-test.ipa`
- v85.2 SHA-256: `CC1751C86EDD2BD98C92E77AA200E0759678AE6F276A3CDF46D3F032E6977A5B`
- v85.2 GitHub Actions run: `29302214134`.
- v85.2 preserves SHEIN auth forms, removes the destructive visible region reset/reload, accepts only shipping-labelled region evidence, and seeds SHEIN's evidenced `localcountry=SA` once per document.

v85 itself inherits the older hidden `FAKE_VISIBLE` flow and a limited exact-key storage guard. Do not alter those while establishing the baseline; first collect and isolate the user's real-device issues.

## Failed Paths

- v86, v87, and v88 are failed/archived paths. Do not continue from them.
- v87 did not fix the reported SHEIN issues.
- v88 regressed opening SHEIN: the WebView/app closed or crashed on entry.
- Do not reuse their broad region/storage intervention, extra reload/setUrl behavior, blocker heuristics, or warm-up close/reopen flow.
- Do not claim any SHEIN issue is fixed without real-device testing on iPhone 6 and iPhone 16 Pro Max.

## Current Task

- Test v85.2 on iPhone 6 and iPhone 16 Pro Max.
- Verify cold entry/category taps, the previously broken Continue/auth page, and product-level shipping country.
- Do not claim Bahrain or first-load interaction fixed before both device results.
- Add-to-Cart placement remains separate and unchanged.

## Scope Guard

- Do not change payment, wallet, completed orders, coupons, group checkout, or Temu during the SHEIN pass.
- No broad CSS, viewport-width hacks, white shields, or hiding SHEIN sections/options.
- Designs come from Figma only.
- Prefer targeted `rg` and Git diffs; old version history stays in Git, not in these handoff files.

## Last Validation

- `npm run build` passed.
- Runtime evaluation and syntax parse of `SHEIN_CAPTURE_SCRIPT` passed.
- `git diff --check` passed.
- v85.2 unsigned IPA built successfully from commit `294dd78`.

## Production References

- Customer: `https://talabieh.vercel.app`
- Admin: `https://talabieh-admin.vercel.app`
- Supabase project: `dcicqdprtyhwmhegabay`
