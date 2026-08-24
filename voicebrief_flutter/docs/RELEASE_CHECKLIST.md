# Release checklist

## Source and local QA

- [x] Feature-first Flutter application, mocks, themes, localization foundation, design components.
- [x] Independent live Supabase project, three migrations, RLS probes, and four Edge Functions deployed.
- [x] Server-only usage mutation and conservative 500-audio-minute monthly launch budget implemented for the initial `$10` OpenAI balance.
- [x] Android receiver and iOS `VoiceBriefShare` source/target, including WhatsApp Opus normalization.
- [x] Icons and native splash generated.
- [x] Formatting, static analysis, 25 unit/widget tests, and eight reviewed golden baselines.
- [x] Complete Arabic/English UI selected from the system locale, including RTL semantics and localized dates/errors/actions.
- [x] Physical Note 8 Arabic visual acceptance at 1080x2220, centered Home/History empty states, correct initial `10/10` free allowance, just-in-time microphone permission, sound-reactive dBFS waveform, and cleanup of the newly canceled test recording.
- [x] Physical Note 8 imported-audio acceptance: extensionless MP3 detection, asynchronous real waveform, slider and waveform seeking, range selection, native trim to M4A, one-step Back navigation, optimistic History deletion, and Undo restore.
- [x] Integration test passed on the installed API 35 emulator.
- [x] Production-signed Android APK and AAB built and recorded with SHA-256 below.
- [x] Real granted `content://` Ogg/Opus cold/warm share handoff on API 35 and physical `SM_N950F` Android 9; temporary test provider removed afterward.
- [x] Time-zone-aware date extraction request, review banner, and native calendar-editor actions for dated tasks and important dates.
- [x] Dedicated OpenAI service-account key stored only in Supabase; 14-second live transcription/summary/date smoke test passed and temporary account/audio cleaned.
- [x] Bilingual public Privacy, Terms, and Support pages deployed; valid support POST smoke-tested and its test row deleted.
- [x] Google Auth Platform configured with web, Android release/debug, and iOS clients; Supabase Google provider enabled with its secret stored server-side only.

## Production-signed Android artifacts — 2026-08-25

- AAB: `output/voicebrief/VoiceBrief-0.1.0-build1-production-signed.aab`, 58,905,864 bytes, SHA-256 `08FE3948C581BCCA2D0C52AF781E4299C69EC9F09BA9D1FC7EDEF4165954EB44`.
- APK: `output/voicebrief/VoiceBrief-0.1.0-build1-production-signed.apk`, 68,643,138 bytes, SHA-256 `7A9DB99D12781D0CC3AD8AD178CEB2118A1D53531230DAF71726FFCF2D54CD03`.
- Package metadata: `app.voicebrief.mobile`, version `0.1.0+1`, minimum SDK 24, target/compile SDK 36.
- APK Signature Scheme v2 verification and AAB JAR verification passed. Both use the owned RSA-4096 upload certificate SHA-256 `81:AA:4D:A6:E4:25:79:4E:88:0C:8D:DE:0A:75:68:F6:8C:EE:77:4A:3C:18:89:17:02:21:AD:04:46:EE:8F:D9`.
- A release build without the private signing environment exits nonzero with the required fail-closed message. An earlier same-certificate signed APK installed and resumed on API 35 with no fatal Android runtime entry; Google opened the native account flow and cancellation returned cleanly. The final waveform/seek/trim/navigation/deletion rebuild is signature-verified, while its source-equivalent live-config debug build is the one physically checked on Note 8 in this batch.
- Merged APK permissions contain internet, network state, microphone, biometric/fingerprint, billing, and Android's non-exported dynamic-receiver permission. No broad storage permission or advertising-ID permission is present.
- Evidence files are under `build/verification/` and are intentionally build-local.

## GitHub unsigned iOS artifact — 2026-08-25

- Branch `codex/voicebrief-ios`, commit `67332f42bccc2d79a33489cdc8da35cc2859410a`, run [32788817963](https://github.com/m7madv/otlobli/actions/runs/32788817963) passed all three jobs: Android analysis/tests/debug build, eight golden tests on Windows, and the macOS iOS build.
- IPA: `output/github-run-32788817963/voicebrief-ios-unsigned-3/VoiceBrief-0.1.0-build1-unsigned.ipa`, 16,807,014 bytes, SHA-256 `79064717F6E26FC6DAA9D3CE30BEADB302AA581C82F618C7C2239E45D1AD900C`.
- The macOS job passed `pod install`, `flutter build ios --release --no-codesign`, bundle-ID checks for `app.voicebrief.mobile` and `app.voicebrief.mobile.share`, Share Extension presence, IPA packaging, and Artifact upload.
- Local archive inspection found 311 entries, `Payload/VoiceBrief.app/PlugIns/VoiceBriefShare.appex`, and no `embedded.mobileprovision`. This proves compilation and packaging only; the IPA is intentionally unsigned and cannot be installed normally or submitted to App Store Connect.

## Owner/external configuration

- [x] Public legal/support URLs and Android upload signing.
- [ ] Confirm final application IDs/App Group availability and increment the store version/build when submission begins.
- [x] Supabase migrations/functions deployed to `jyehqpdbayslhzebdycj`; anonymous server-RPC access denied and service cap live.
- [x] OpenAI balance displays `$10.00`, automatic recharge is disabled, the dedicated service-account key is active, and the live smoke consumed one rounded service-ledger minute with zero reservation left behind.
- [x] Google dashboard clients, branding/legal URLs, Supabase provider, and live redirect verified; app remains External/Testing with `mhm1981x@gmail.com` as its test user.
- [ ] Add Google Play App Signing SHA after first Play setup, complete a real `mhm1981x@gmail.com` token exchange, then deliberately publish OAuth beyond Testing.
- [ ] Apple provider dashboard and redirect flow verified.
- [ ] App Store/Play products and RevenueCat offering/webhook/sandbox verified.
- [x] Production Android upload signing configured privately; owner still must back it up before first upload.
- [ ] Apple signing/provisioning configured privately.
- [x] Privacy policy, Terms, and Support pages published; owner/legal approval plus Apple Privacy, Google Data Safety, and reviewer notes remain.

## Device acceptance

- [ ] Weak/old Android extended acceptance: TalkBack, 200% font/display size, microphone denial/pause/resume, playback interruption, and background/process-death behavior. Normal playback, seek, waveform, trim, Back, delete, and Undo passed on Note 8.
- [x] Granted `content://` share plus cold/warm behavior on a physical Android 9 device.
- [x] Arabic system-locale layout plus microphone allow/start/cancel on a physical `SM_N950F` Android 9 device; no temporary audio remained.
- [ ] Duplicate-suppression timing and hostile/oversize provider acceptance on a physical Android device.
- [x] macOS `pod install`, device-target no-codesign build, bundle-ID validation, Share Extension embedding, and unsigned IPA packaging through GitHub Actions.
- [ ] Signed physical-iPhone Share Extension/App Group handoff, playback/seek/trim, and App Store archive acceptance.
- [ ] VoiceOver, all accessibility text sizes, recording interruptions, Apple sign-in, and full Google token exchange. Google picker/cancel passed on API 35 and physical Android 9; Note 8 currently has `mhm1981d@gmail.com`, not the configured test account `mhm1981x@gmail.com`.
- [ ] Monthly/annual purchase, renewal/cancellation, restore, reinstall/device change.
- [ ] Account deletion removes Auth/database/Storage/local data while explaining store cancellation.

Never upload a build signed with the debug Android key. Back up the owned upload key before the first store upload. Never mark device-only checks complete based on source, analyzer, emulator, or golden results.
