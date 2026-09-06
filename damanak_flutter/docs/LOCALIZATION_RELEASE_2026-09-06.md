# Damanak 4.6.0 (32) — localization release

## Scope and source

- Branch: `codex/damanak-simple-pos`, original checkout under `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- App source and assets: `8f1327b`; subsequent commits adjust publishing automation only. Current automation: `c28b650`.
- Ten bundled locales: Arabic, English, Spanish, French, German, Portuguese, Simplified Chinese, Hindi, Japanese and Russian. Each has 1205 translation keys with preserved placeholders.
- Device language resolution, manual preference, RTL/LTR, locale-aware dates and native iOS display-name/camera permission resources. Customer-entered data and store currency remain unchanged.
- No translation model, Python runtime or translation service is shipped. Draft translation received targeted editorial corrections, not comprehensive native-speaker approval.
- Apple Design review and limitations: `DESIGN_AUDIT.md`.

## Validation

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --concurrency=1`: **299/299** passed, including **53** localization/layout tests with 320px width and 150% text scale.
- Both localization verification scripts passed: complete catalog keys/placeholders, metadata field limits, 100 correctly-sized screenshots.
- Final web release passed in 75.1s; not deployed as a website.
- iOS run `34039342937` succeeded: dependency analysis/tests, native compilation, signing, IPA checks and upload. Apple reported `UPLOAD SUCCEEDED` at 2026-09-06 14:39:47 UTC, delivery `7848f16a-97f9-4315-93bd-daea14024fc2`.
- IPA: `output/github-run-34039342937/ضمانك.ipa`, **24,965,730 bytes**, SHA-256 **E4728DFE2289CEC91FD9449AB057A514593F682BE1815B543F2F2DEF6CBBA1A7**. The ten native InfoPlist.strings resources were verified inside the downloaded IPA.
- No new real-device, VoiceOver/TalkBack, weak-phone or purchase/restoration acceptance is claimed.

## App Store state

- Live version remains **4.5.0**. New **4.6.0** draft: `af5f3581-d237-476d-b8c4-a42c73f7cc19`, `PREPARE_FOR_SUBMISSION`, manual release.
- Metadata run `34039402544` succeeded for all ten locales.
- All **100 screenshots** reached Apple delivery state **COMPLETE**; all reported SHA-256 values matched the local source PNGs.
- Assets: `app_store_assets/ios/localized/<store-locale>/`, five iPhone 1284×2778 and five iPad 2048×2732 PNGs per locale.

| App Store locale | Screenshot run |
| --- | --- |
| ar-SA | 34039473534 |
| en-US | 34039476125 |
| es-ES | 34039477707 |
| fr-FR | 34039479341 |
| de-DE | 34039481618 |
| pt-BR | 34039483376 |
| zh-Hans | 34039485315 |
| hi | 34039487165 |
| ja | 34039489331 |
| ru | 34039491289 |

Reports were downloaded under `output/github-run-<id>/` (ignored local artifacts).
Language selection on the App Store depends on supported localizations and Apple's device/storefront fallback rules, not only the device language.

## Automation and recovered failures

- GitHub's registered workflow is `damanak-apple-setup.yml` (`341412875`). Use `asset_kind=metadata` or `screenshots`, explicit `version=4.6.0` and locale. These branches bypass legacy setup, pricing and subscription mutations. Do not use `asset_kind=setup` to publish this version.
- New standalone metadata/screenshot workflows were not registered on the default branch (404). No default-branch changes were made.
- First iOS run `34039168233` stopped before compilation because the standalone authoring package dependencies were absent. The workflow now installs and analyzes that separate package; no application dependency was added.
- Metadata run `34039292196` created the draft and partially updated locales, then encountered an App Info locale automatically created by Apple. The script now refreshes App Info after each version-locale mutation. Retry `34039402544` completed without deleting locales or the draft.
- The signed build source is `24e6f9b`; app/runtime code and ARB assets are unchanged from `8f1327b`.

## Remaining release checks

- Upload and IPA hash are confirmed. The immediate post-upload inspect run `34039915098` still returned Build31 as newest; do not claim Build32 VALID or available in TestFlight until a later Apple read confirms it. The internal group `18666e73-e100-42a5-a223-f3620e97bf04` has access to all builds and one tester; no tester changes were made.
- No new review submission was sent and no build was linked to the 4.6.0 draft in this batch. Before public review, verify the documented Sandbox access requirement with project-owner access. A fresh read of current Supabase CLI access still did not include `exxayzlklvgeyqhvtzgi` (two other projects only); the user was asked to sign in as its owner, without sharing credentials.
- Comprehensive linguistic/device acceptance is unperformed. External legal/warranty pages and native store product metadata were not localized in this batch.
- Storefront availability remains the existing six Gulf countries; adding languages does not expand distribution or change regional billing checks. An optional user question about expansion remains unanswered.
- The previously documented Sandbox access restriction is unchanged; see `BILLING_REVIEW_2026-09-05.md`. Do not claim that localization fixed purchases or that a new payment was tested.
- Do not submit or release by silently reusing the old hardcoded 4.5.0/Build23 setup path. Never delete accounts, change product identifiers or fabricate fallback prices as part of localization.
