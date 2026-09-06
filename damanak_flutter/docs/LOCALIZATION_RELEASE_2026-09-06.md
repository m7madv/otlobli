# Damanak 4.6.0 (32) — localization release

## Scope and source

- Branch: `codex/damanak-simple-pos`, original checkout under `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- App source and initial assets: `8f1327b`; subsequent commits adjust automation/docs and add en-GB store assets without runtime changes. Store variant source: `f3d184f`.
- Ten bundled locales: Arabic, English, Spanish, French, German, Portuguese, Simplified Chinese, Hindi, Japanese and Russian. Each has 1205 translation keys with preserved placeholders.
- Device language resolution, manual preference, RTL/LTR, locale-aware dates and native iOS display-name/camera permission resources. Customer-entered data and store currency remain unchanged.
- No translation model, Python runtime or translation service is shipped. Draft translation received targeted editorial corrections, not comprehensive native-speaker approval.
- Apple Design review and limitations: `DESIGN_AUDIT.md`.

## Validation

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --concurrency=1`: **299/299** passed, including **53** localization/layout tests with 320px width and 150% text scale.
- Both localization verification scripts passed: complete catalog keys/placeholders, metadata field limits, 110 correctly-sized screenshots. The additional en-GB screenshot harness run passed 5/5 tests (two sizes each).
- Final web release passed in 75.1s; not deployed as a website.
- iOS run `34039342937` succeeded: dependency analysis/tests, native compilation, signing, IPA checks and upload. Apple reported `UPLOAD SUCCEEDED` at 2026-09-06 14:39:47 UTC, delivery `7848f16a-97f9-4315-93bd-daea14024fc2`.
- IPA: `output/github-run-34039342937/ضمانك.ipa`, **24,965,730 bytes**, SHA-256 **E4728DFE2289CEC91FD9449AB057A514593F682BE1815B543F2F2DEF6CBBA1A7**. The ten native InfoPlist.strings resources were verified inside the downloaded IPA.
- No new real-device, VoiceOver/TalkBack, weak-phone or purchase/restoration acceptance is claimed.

## App Store state

- Follow-up inspect `34040072308` confirmed Build32 **VALID**, ID `7848f16a-97f9-4315-93bd-daea14024fc2`, included in the existing `Damanak Internal` group. Minimum iOS15; non-exempt encryption false. No testers were added or removed.
- Additional **en-GB** metadata and screenshots completed in runs `34040227259` and `34040273515`. This is an English regional variant for the Gulf's documented default store locale, not an eleventh in-app language or a binary change. Final result: **11 store localizations, 110 COMPLETE screenshots**, with every reported SHA-256 matching the local file.

- Live version remains **4.5.0** pending approval/release. Version **4.6.0** (`af5f3581-d237-476d-b8c4-a42c73f7cc19`) is now **Waiting for Review**, linked to Build32. Following the user's explicit publish request, submission `e80028ff-2ee6-48d6-b414-6172d31b2c3a` was sent on **2026-09-06 at 18:13 Asia/Riyadh**. The App Store Connect receipt confirms one submitted item, **4.6.0 (32)**, Waiting for Review.
- Saved release option: **Automatically release this version (AFTER_APPROVAL)**, release to all users immediately, keep existing ratings. No new binary upload, subscription/account mutation or tester change. Review notes now describe ten languages, native provider sign-in and the eligible free 20-warranty monthly allowance instead of the obsolete Starter trial.
- Submission receipt: https://appstoreconnect.apple.com/apps/6804792494/distribution/reviewsubmissions/details/e80028ff-2ee6-48d6-b414-6172d31b2c3a . Do not cancel or duplicate the submission without a new user release decision.
- Initial metadata run `34039402544` succeeded for ten locales; `34040227259` verified all eleven including en-GB.
- All **110 screenshots** reached Apple delivery state **COMPLETE**; all reported SHA-256 values matched the local source PNGs.
- Assets: `app_store_assets/ios/localized/<store-locale>/`, five iPhone 1284×2778 and five iPad 2048×2732 PNGs per locale.

| App Store locale | Screenshot run |
| --- | --- |
| ar-SA | 34039473534 |
| en-US | 34039476125 |
| en-GB | 34040273515 |
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

- Upload, IPA hash, Build32 VALID and internal-group inclusion are confirmed by `34040072308`. The earlier immediate read `34039915098` had not yet seen it; no duplicate upload was performed. Internal group `18666e73-e100-42a5-a223-f3620e97bf04` has access to all builds and one tester.
- Build32 is linked and review submission was sent after the user's renewed explicit publication request. This does **not** close the documented Sandbox access issue: the latest Supabase CLI read did not include `exxayzlklvgeyqhvtzgi` (two other projects only), and project-owner access is still needed for that separate verification. No new purchase/restoration acceptance is claimed. This follow-up changed only Apple release metadata and documentation; it did not change runtime code or rerun binary tests.
- Comprehensive linguistic/device acceptance is unperformed. External legal/warranty pages and native store product metadata were not localized in this batch.
- Storefront availability remains the existing six Gulf countries; adding languages does not expand distribution or change regional billing checks. An optional user question about expansion remains unanswered.
- The previously documented Sandbox access restriction is unchanged; see `BILLING_REVIEW_2026-09-05.md`. Do not claim that localization fixed purchases or that a new payment was tested.
- Do not submit or release by silently reusing the old hardcoded 4.5.0/Build23 setup path. Never delete accounts, change product identifiers or fabricate fallback prices as part of localization.
