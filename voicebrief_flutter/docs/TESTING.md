# Testing

## Automated coverage

- Unit: quota rounding, annual saving, file validation and signature detection, strict nested result JSON, fake authentication/subscription, memory history, optimistic result deletion, and account deletion.
- Widget: primary action semantics, authentication paths, home/usage/empty state, immediate History dismissal with Undo, explanatory transcript disclosure, paywall selection/prices, and dark large-text error.
- Golden: light/dark authentication and home, processing, result, paywall, and 1.6× text.
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
- Unit/widget suite: 25 passed, including dBFS normalization, fast-attack/slow-release meter response, immutable waveform repainting, extensionless MP3 signature detection, optimistic deletion before delayed storage completion, History Undo, Arabic mirroring, the centered narrow Arabic History empty state, and the default `10/10` free allowance.
- Golden suite: eight passed after intentional regeneration and visual inspection; Material Icons and deterministic Roboto glyphs are loaded by the harness.
- Installed-emulator integration: one onboarding → mock email sign-in → home → settings → local account deletion flow passed on `Pixel_7_API_35_Test` (API 35).
- Supabase functions: the original three entry points passed local Deno checks; the fourth `legal` function compiled and deployed successfully, then passed live GET, invalid POST, valid POST, rate-control/CORS, and cleanup probes.
- Android UI: onboarding, authentication, home, and audio preparation were inspected at 1080×2400. Logcat contained no `FATAL EXCEPTION` or `E/flutter` finding in the verified flows.
- Android handoff: a real exported test sender supplied a granted `content://` Ogg/Opus URI through the Android share sheet. Warm and force-stopped/cold flows passed on API 35 and physical `SM_N950F` Android 9; the provider package was removed afterward.
- Physical Note 8 UI/recording: the installed live-config debug build automatically selected Arabic from the device `ar-AE` locale, rendered the redesigned Home screen and the centered History empty state without overflow at 1080x2220, showed `10` of `10` free minutes, requested Android microphone permission in Arabic only after the record control was pressed, then recorded with a progressing timer and a waveform that changed between consecutive physical-device captures without VoiceBrief/Flutter errors. The newly created test recording was canceled and removed; pre-existing app cache/user state was preserved.
- Physical Note 8 audio editing: a 2:46 extensionless MP3 from an Android document provider imported successfully without a redundant private-file copy, its real waveform completed asynchronously, slider seek reached 1:34, waveform tap reached 2:29, and range selection 0:42–1:11 exported a real 0:29 AAC/M4A and reached Result within the 15-second acceptance wait. A single Back after picker import returned to Home; the former duplicate preparation route was eliminated.
- Physical Note 8 deletion: swiping the saved result in Arabic RTL removed it immediately, displayed `تم حذف الملخص` plus `تراجع`, and Undo restored the exact item. This verifies that local persistence latency no longer blocks the visible deletion.
- Latest local source verification: `flutter analyze` passed, all 25 non-golden tests passed, all eight golden tests passed, and scoped `:app:connectedDebugAndroidTest` passed its real shared Opus intent test on `SM_N950F`. The unscoped aggregate Gradle task is not used because it also tries to instrument plugin library modules with incompatible test-app minimum SDK declarations.
- Production release: the rebuilt owned-key APK passed v2 verification and the AAB passed JAR verification after the waveform/seek/trim/navigation/deletion changes. Earlier same-certificate production installation passed on API 35; this source-equivalent final behavior was physically exercised with the live-config debug build on Note 8.
- Public pages: Prettier and `html-validate` passed; Arabic RTL/dark mode was visually inspected locally at 1280×720. A live support request returned 201 and its row was deleted immediately.

## Platform checklist

Android remaining device checks: duplicate delivery timing, hostile/oversize provider, microphone denial/pause/resume, playback conflict/interruption, process death, background/resume, extreme font/display scaling, and TalkBack on the production-signed build. File picker import, real playback/seek/waveform/trim, Back, deletion/Undo, microphone allow/start/cancel, and the default Note 8 viewport have passed on physical hardware.

iOS/macOS: Runner/extension compile, App Group cold/warm handoff, extension cancel/error, Apple/Google redirect, microphone interruption/call/Bluetooth, sandbox monthly/annual/restore, VoiceOver/Dynamic Type, simulator/no-codesign build, signed device archive.

## Honest environment record

This Windows host has Android tooling and the `Pixel_7_API_35_Test` emulator. It has no Xcode/CocoaPods/iOS Simulator/signing, so iOS compilation/device checks must run on macOS. The checked-in GitHub Actions workflow contains a macOS no-codesign job, but it was not executed from this local task.
