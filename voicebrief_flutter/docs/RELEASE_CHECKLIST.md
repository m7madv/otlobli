# Release checklist

## Source and local QA

- [x] Feature-first Flutter application, mocks, themes, localization foundation, design components.
- [x] Independent live Supabase project, three migrations, RLS probes, and four Edge Functions deployed.
- [x] Server-only usage mutation and conservative 500-audio-minute monthly launch budget implemented for the initial `$10` OpenAI balance.
- [x] Android receiver and iOS `VoiceBriefShare` source/target, including WhatsApp Opus normalization.
- [x] Icons and native splash generated.
- [x] Formatting, static analysis, 30 unit/widget tests, and eleven reviewed golden baselines, including provider-only Arabic RTL authentication, Settings, and Recorder views.
- [x] Complete Arabic/English UI selected from the system locale, including RTL semantics and localized dates/errors/actions.
- [x] Physical Note 8 Arabic visual acceptance at 1080x2220, centered Home/History empty states, correct initial `10/10` free allowance, just-in-time microphone permission, sound-reactive dBFS waveform, and cleanup of the newly canceled test recording.
- [x] Physical Note 8 imported-audio acceptance: extensionless MP3 detection, asynchronous real waveform, slider and waveform seeking, range selection, native trim to M4A, one-step Back navigation, optimistic History deletion, and Undo restore.
- [x] Integration test passed on the installed API 35 emulator.
- [x] Production-signed Android APK and AAB built and recorded with SHA-256 below.
- [x] Real granted `content://` Ogg/Opus cold/warm share handoff on API 35 and physical `SM_N950F` Android 9; temporary test provider removed afterward.
- [x] Time-zone-aware date extraction request, review banner, and native calendar-editor actions for dated tasks and important dates.
- [x] Dedicated OpenAI service-account key stored only in Supabase; 14-second live transcription/summary/date smoke test passed and temporary account/audio cleaned.
- [x] Bilingual public Privacy, Terms, and Support pages deployed; valid support POST smoke-tested and its test row deleted.
- [x] Google Auth Platform configured with web, Android release/debug, and iOS clients; its audience is External/In production and Supabase Google is enabled with iOS-compatible nonce handling.
- [x] Native Google exchange supplies the required ID and access tokens on Android and iOS, and the iOS source declares the Apple sign-in entitlement while keeping the App Group entitlement.
- [x] Hosted email/password auth is disabled and the shipped application contains only Apple and Google entry points.

## Production-signed Android artifacts — 2026-08-25

- AAB: `output/voicebrief/VoiceBrief-0.1.0-build1-production-signed.aab`, 58,905,864 bytes, SHA-256 `08FE3948C581BCCA2D0C52AF781E4299C69EC9F09BA9D1FC7EDEF4165954EB44`.
- APK: `output/voicebrief/VoiceBrief-0.1.0-build1-production-signed.apk`, 68,643,138 bytes, SHA-256 `7A9DB99D12781D0CC3AD8AD178CEB2118A1D53531230DAF71726FFCF2D54CD03`.
- Package metadata: `app.voicebrief.mobile`, version `0.1.0+1`, minimum SDK 24, target/compile SDK 36.
- APK Signature Scheme v2 verification and AAB JAR verification passed. Both use the owned RSA-4096 upload certificate SHA-256 `81:AA:4D:A6:E4:25:79:4E:88:0C:8D:DE:0A:75:68:F6:8C:EE:77:4A:3C:18:89:17:02:21:AD:04:46:EE:8F:D9`.
- A release build without the private signing environment exits nonzero with the required fail-closed message. An earlier same-certificate signed APK installed and resumed on API 35 with no fatal Android runtime entry; Google opened the native account flow and cancellation returned cleanly. The final waveform/seek/trim/navigation/deletion rebuild is signature-verified, while its source-equivalent live-config debug build is the one physically checked on Note 8 in this batch.
- Merged APK permissions contain internet, network state, microphone, biometric/fingerprint, billing, and Android's non-exported dynamic-receiver permission. No broad storage permission or advertising-ID permission is present.
- Evidence files are under `build/verification/` and are intentionally build-local.

## GitHub unsigned live iOS artifact — 2026-08-25

- Branch `codex/voicebrief-ios`, commit `116efb336d4f418c698dc6928180a83305836450`, run [32888914885](https://github.com/m7madv/otlobli/actions/runs/32888914885) passed all three jobs: Android analysis/29 tests/debug build, eleven golden tests on Windows, and the macOS iOS build.
- IPA: `output/github-run-32888914885/VoiceBrief-0.1.0-build4-live-unsigned.ipa`, 17,099,175 bytes, SHA-256 `82762E74DAC25F320214A7B63428023492C4938332D76F7367B452204C193D00`.
- The macOS job generated a temporary production configuration from GitHub Secrets, required non-empty Supabase values, fixed `USE_MOCK_SERVICES=false`, deleted the temporary config on exit, and passed `pod install` plus `flutter build ios --release --no-codesign`. This replaces build 1, which had accidentally used the mock example configuration and therefore returned static content.
- The same job verified the source Apple sign-in and App Group entitlements, bundle IDs `app.voicebrief.mobile` and `app.voicebrief.mobile.share`, Share Extension presence, and exact app/extension version parity. Independent archive inspection found 311 entries, the `voicebrief` callback scheme, and `0.1.0 (4)` for both bundles.
- On iOS, Google now uses Supabase OAuth with PKCE in the external system browser and completes through `voicebrief://auth/callback`; this avoids depending on a sideload signer preserving the native Google bundle association. The account still has to be allowed by the Google OAuth audience while the project is in Testing.
- The Share Extension now accepts WhatsApp-style audio/Opus representations, writes an atomic App Group manifest, and shows localized success or actionable failure instead of relying on unsupported automatic parent-app launch. After success the user taps Done and opens VoiceBrief manually.
- The IPA has no provisioning and remains intentionally unsigned. The signing path must provision the app and extension together with `group.app.voicebrief.mobile`; otherwise the extension now reports an App Group error. The public Supabase settings still report Apple disabled, so Apple sign-in is not release-ready until the provider, Apple App ID, and signed entitlement are configured by an account with project access. Compilation and packaging do not replace a signed physical-iPhone handoff/authentication test or App Store archive validation.

## Signed TestFlight build — 2026-08-25

- App Store Connect app `VoiceBrief` was created with Apple ID `6805194629`, primary language Arabic, SKU `VOICEBRIEF_IOS_001`, and bundle ID `app.voicebrief.mobile`.
- Apple identifiers `app.voicebrief.mobile` and `app.voicebrief.mobile.share` are registered under team `36D743K87T`. Both use App Group `group.app.voicebrief.mobile`; the Runner identifier also has Sign in with Apple enabled.
- App Store profiles `VoiceBrief App Store 2026` and `VoiceBrief Share App Store 2026` were created for the Runner and Share Extension respectively. Both expire on 2027-08-22.
- Branch `codex/voicebrief-ios`, commit `0bd55182db150b07b07546e1b4591f68a11dd87e`, run [32893325708](https://github.com/m7madv/otlobli/actions/runs/32893325708) passed format, analysis, 29 tests, live no-codesign compilation, profile entitlement checks, signed archive/export, embedded profile and entitlement verification, App Store validation, and upload.
- Signed IPA: `VoiceBrief-0.1.0-build5-AppStore.ipa`, 34,384,042 bytes, SHA-256 `C162AD0D8BDD9BF6513BCBBACC1AB60DA855A150EE4900CDCB632F488E185A63`. GitHub artifact: `voicebrief-ios-0.1.0-build5-appstore`; local download: `artifacts/voicebrief-ios-0.1.0-build5-appstore/ios/signed/`.
- Apple finished processing build `0.1.0 (5)` and reports it as `Ready to Submit`, expiring in 90 days. Internal TestFlight group `VoiceBrief Internal` has automatic distribution enabled, contains one build and one tester, and reports `mhm1981dx@gmail.com` as `Invited`.

## Provider-only TestFlight build — 2026-08-26

- Branch `codex/voicebrief-ios`, commit `1ddfd5d`, run [32901316058](https://github.com/m7madv/otlobli/actions/runs/32901316058) signed, verified, and uploaded `0.1.0 (7)`; run [32901316077](https://github.com/m7madv/otlobli/actions/runs/32901316077) passed Android, eleven golden tests, and iOS no-codesign.
- Signed IPA: `VoiceBrief-0.1.0-build7-AppStore.ipa`, 34,368,348 bytes, SHA-256 `15950D4EC8FDD54649126BC1473D37849D46B569F7E4DB2BE40E7AC65FD48FCD`.
- Apple completed processing, attached build 7 to `VoiceBrief Internal`, and App Store Connect reports `mhm1981dx@gmail.com` installed `0.1.0 (7)` on `iPhone 16 Pro Max / iOS 27.0`.
- Live Auth logs identified the post-consent Google failure as a nonce mismatch and the Apple failure as `provider_disabled`. Google nonce compatibility and production audience were enabled; Apple client IDs were corrected from Damanak to `app.voicebrief.mobile`, key `N4FK6753YL` and a 180-day client secret were configured, and hosted email auth was disabled. The same signed physical iPhone then produced successful Google and Apple `Login / INFO` events at `01:06:16` and `01:08:42` Asia/Riyadh respectively.

## RevenueCat-enabled candidate — 2026-08-26

- Source version is `0.1.0+8`. GitHub Actions now holds both platform-specific RevenueCat public SDK keys; Runner and Share Extension use build `8`, and the signed plus unsigned iOS workflows verify/package that number consistently.
- RevenueCat has both store apps, all four monthly/annual products attached to entitlement `pro`, and both cross-platform packages in offering `default`.
- Local verification passed: `dart format --set-exit-if-changed .`, `flutter analyze`, 30 non-golden tests, eleven golden tests, and `flutter build apk --debug`.
- The signed TestFlight upload, Apple sandbox purchase/restore, webhook delivery, and real-device acceptance are not complete yet. Android purchase acceptance also waits for Google Play to save and activate both base plans.

## Owner/external configuration

- [x] Public legal/support URLs and Android upload signing.
- [x] Confirm final application IDs/App Group availability and increment the iOS store build to `0.1.0+7`.
- [x] Supabase migrations/functions deployed to `jyehqpdbayslhzebdycj`; anonymous server-RPC access denied and service cap live.
- [x] OpenAI balance displays `$10.00`, automatic recharge is disabled, the dedicated service-account key is active, and the live smoke consumed one rounded service-ledger minute with zero reservation left behind.
- [x] Google dashboard clients, branding/legal URLs, Supabase provider, production audience, and iOS nonce compatibility configured.
- [ ] Add Google Play App Signing SHA after first Play setup and complete a post-fix Google exchange on Play-signed Android; signed-iPhone Google acceptance passed.
- [x] Enable the Apple provider in the VoiceBrief Supabase project, configure native client ID `app.voicebrief.mobile`, key `N4FK6753YL`, and a client secret expiring `2027-02-21T22:07:34Z`.
- [x] Complete a post-fix Apple exchange on the signed physical iPhone.
- [ ] Rotate the VoiceBrief Apple client secret before `2027-02-21T22:07:34Z`.
- [x] App Store subscription group and monthly/annual products created, localized, priced, and made available regionally; first-version submission and review screenshots remain.
- [x] Google Play app, internal-release draft, and monthly/annual subscription products created under developer account `8441225038702199576`.
- [x] VoiceBrief-only service-account access granted for financial viewing, order/subscription management, and store-presence/product management; subscription reads now return `200`.
- [ ] Google Play monthly/annual base plans saved and activated. A final owner-session retry selected all 177 regions and converted Qatar to the exact `29.00 QAR`, but Save still returned `تعذَّر حفظ التغييرات.`; service-account price conversion/writes also return `The caller does not have permission`. This is an unresolved Google account-side monetization/save condition, not invalid product data. The idempotent activation script and local reports are ready under `scripts/` and `build/google-play-subscriptions/`; retry after permission propagation, then escalate to Play Support if the owner-session failure persists.
- [x] RevenueCat project `VoiceBrief` (`59213dad`), entitlement `pro`, offering `default`, App Store connection `app85cd86a950`, and Google Play connection `appa60d40b8c1` are created. Four production products are attached to `pro`; the iOS/Android monthly products map to `$rc_monthly` and the annual products map to `$rc_annual`. Both public SDK keys are stored in GitHub Actions secrets for build `0.1.0+8`.
- [ ] Configure the RevenueCat webhook authorization secret in RevenueCat and Supabase, confirm the RevenueCat account email, and complete sandbox purchase/restore checks. Google purchase acceptance additionally waits for Google to save and activate the missing `monthly` and `annual` base plans.
- [x] Production Android upload signing configured privately; owner still must back it up before first upload.
- [x] Apple signing/provisioning configured privately and the signed Runner plus Share Extension passed App Store validation/upload.
- [x] Privacy policy, Terms, and Support pages published; owner/legal approval plus Apple Privacy, Google Data Safety, and reviewer notes remain.

## Device acceptance

- [ ] Weak/old Android extended acceptance: TalkBack, 200% font/display size, microphone denial/pause/resume, playback interruption, and background/process-death behavior. Normal playback, seek, waveform, trim, Back, delete, and Undo passed on Note 8.
- [x] Granted `content://` share plus cold/warm behavior on a physical Android 9 device.
- [x] Arabic system-locale layout plus microphone allow/start/cancel on a physical `SM_N950F` Android 9 device; no temporary audio remained.
- [ ] Duplicate-suppression timing and hostile/oversize provider acceptance on a physical Android device.
- [x] macOS `pod install`, device-target no-codesign build, bundle-ID validation, Share Extension embedding, and unsigned IPA packaging through GitHub Actions.
- [x] Signed App Store archive/export, embedded provisioning and entitlement verification, App Store validation, and TestFlight upload through GitHub Actions.
- [ ] Signed physical-iPhone Share Extension/App Group handoff, playback/seek/trim, and App Store archive acceptance.
- [ ] VoiceOver, all accessibility text sizes, recording interruptions, Apple sign-in, and full Google token exchange. Google picker/cancel passed on API 35 and physical Android 9; Note 8 currently has `mhm1981d@gmail.com`, not the configured test account `mhm1981x@gmail.com`.
- [ ] Monthly/annual purchase, renewal/cancellation, restore, reinstall/device change.
- [ ] Account deletion removes Auth/database/Storage/local data while explaining store cancellation.

Never upload a build signed with the debug Android key. Back up the owned upload key before the first store upload. Never mark device-only checks complete based on source, analyzer, emulator, or golden results.
