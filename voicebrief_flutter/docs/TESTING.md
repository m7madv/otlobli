# Testing

## Automated coverage

- Unit: quota rounding, annual saving, file validation and signature detection, strict nested result JSON, fake authentication/subscription, memory history, optimistic result deletion, optimistic clear-all with failure recovery, and account deletion.
- Widget: primary action semantics, email and Apple/Google authentication paths, Arabic RTL provider visibility, home/usage/empty state, immediate History dismissal with Undo, explanatory transcript disclosure, paywall selection/prices, empty saved-text action feedback, and dark large-text error.
- Golden: light/dark authentication, Arabic RTL authentication, light/dark home, processing, result, paywall, 1.6× text, and Arabic RTL Settings/Recorder views at 390×844.
- Integration source: onboarding → mock sign-in → home → settings/account deletion without paid services.

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test --exclude-tags golden
flutter test test/golden_screens_test.dart
flutter test integration_test/app_flow_test.dart -d DEVICE_ID
```

Regenerate goldens only after intentional review:

```bash
flutter test test/golden_screens_test.dart --update-goldens
```

Test-only Roboto files under `test/fonts` make desktop golden glyphs deterministic and include their Apache license. They are not declared as Flutter runtime assets; production continues to use platform system typography.

## Results on 2026-08-25

- `dart format`: 69 Dart files, zero changes required.
- `flutter analyze`: no issues.
- Unit/widget suite: 28 passed, including visible Apple/Google actions in English and Arabic RTL, dBFS normalization, fast-attack/slow-release meter response, immutable waveform repainting, extensionless MP3 signature detection, optimistic deletion and clear-all recovery before delayed storage completion, History Undo, empty saved-text feedback, Arabic mirroring, the centered narrow Arabic History empty state, and the default `10/10` free allowance.
- Golden suite: eleven passed after intentional regeneration and visual inspection, including the localized Apple/Google section in English light/dark and Arabic RTL; Material Icons, deterministic Roboto glyphs, and an Arabic-capable Windows test font are loaded by the harness.
- Installed-emulator integration: one onboarding → mock email sign-in → home → settings → local account deletion flow passed on `Pixel_7_API_35_Test` (API 35).
- Supabase functions: the original three entry points passed local Deno checks; the fourth `legal` function compiled and deployed successfully, then passed live GET, invalid POST, valid POST, rate-control/CORS, and cleanup probes.
- Android UI: onboarding, authentication, home, and audio preparation were inspected at 1080×2400. Logcat contained no `FATAL EXCEPTION` or `E/flutter` finding in the verified flows.
- Android handoff: a real exported test sender supplied a granted `content://` Ogg/Opus URI through the Android share sheet. Warm and force-stopped/cold flows passed on API 35 and physical `SM_N950F` Android 9; the provider package was removed afterward.
- Physical Note 8 UI/recording: the installed live-config debug build automatically selected Arabic from the device `ar-AE` locale, rendered the redesigned Home screen and the centered History empty state without overflow at 1080x2220, showed `10` of `10` free minutes, requested Android microphone permission in Arabic only after the record control was pressed, then recorded with a progressing timer and a waveform that changed between consecutive physical-device captures without VoiceBrief/Flutter errors. The newly created test recording was canceled and removed; pre-existing app cache/user state was preserved.
- Physical Note 8 audio editing: a 2:46 extensionless MP3 from an Android document provider imported successfully without a redundant private-file copy, its real waveform completed asynchronously, slider seek reached 1:34, waveform tap reached 2:29, and range selection 0:42–1:11 exported a real 0:29 AAC/M4A and reached Result within the 15-second acceptance wait. A single Back after picker import returned to Home; the former duplicate preparation route was eliminated.
- Physical Note 8 deletion: swiping the saved result in Arabic RTL removed it immediately, displayed `تم حذف الملخص` plus `تراجع`, and Undo restored the exact item. This verifies that local persistence latency no longer blocks the visible deletion.
- Latest local source verification for `0.1.0+3`: `dart format` required no changes, `flutter analyze` passed, all 28 non-golden tests passed, all eleven golden tests passed, and `flutter build apk --debug` completed. The earlier scoped `:app:connectedDebugAndroidTest` still passed its real shared Opus intent test on `SM_N950F`; the unscoped aggregate Gradle task is not used because it also tries to instrument plugin library modules with incompatible test-app minimum SDK declarations.
- GitHub Actions run `32882383216` passed from commit `f240e28`: Linux completed format, analyze, all 28 non-golden tests, and the Android debug APK; Windows completed all eleven golden tests; macOS completed `pod install`, a live-config release iOS build with `USE_MOCK_SERVICES=false`, source checks for Apple sign-in and App Group entitlements, bundle-ID/Share Extension checks, version/build parity checks, IPA packaging, and artifact upload. Both built plists and the independently inspected IPA report `0.1.0 (3)` for the app and extension.
- The prior sideloaded build used the example configuration with `USE_MOCK_SERVICES=true`, which explains its repeated default transcript/summary. Build 2 requires the live Supabase values from GitHub Secrets and cannot silently fall back to mock services.
- Production release: the rebuilt owned-key APK passed v2 verification and the AAB passed JAR verification after the waveform/seek/trim/navigation/deletion changes. Earlier same-certificate production installation passed on API 35; this source-equivalent final behavior was physically exercised with the live-config debug build on Note 8.
- Public pages: Prettier and `html-validate` passed; Arabic RTL/dark mode was visually inspected locally at 1280×720. A live support request returned 201 and its row was deleted immediately.

## Platform checklist

Android remaining device checks: duplicate delivery timing, hostile/oversize provider, microphone denial/pause/resume, playback conflict/interruption, process death, background/resume, extreme font/display scaling, and TalkBack on the production-signed build. File picker import, real playback/seek/waveform/trim, Back, deletion/Undo, microphone allow/start/cancel, and the default Note 8 viewport have passed on physical hardware.

iOS/macOS remaining: signed App Group cold/warm handoff from WhatsApp, extension cancel/error on-device, Apple/Google redirect, microphone interruption/call/Bluetooth, sandbox monthly/annual/restore, VoiceOver/Dynamic Type, and a signed device/App Store archive. Runner/extension compilation and the no-codesign device-target build pass on GitHub macOS.

## Honest environment record

This Windows host has Android tooling and the `Pixel_7_API_35_Test` emulator. It has no local Xcode/CocoaPods/iOS Simulator/signing. The checked-in GitHub Actions workflow successfully compiled and packaged the unsigned iOS app on macOS, but signing, simulator interaction, and physical-iPhone acceptance remain unperformed.
