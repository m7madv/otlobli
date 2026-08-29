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
- Unit/widget suite: 29 passed, including completion of a redirected Supabase auth session, visible Apple/Google actions in English and Arabic RTL, dBFS normalization, fast-attack/slow-release meter response, immutable waveform repainting, extensionless MP3 signature detection, optimistic deletion and clear-all recovery before delayed storage completion, History Undo, empty saved-text feedback, Arabic mirroring, the centered narrow Arabic History empty state, and the default `10/10` free allowance.
- Golden suite: eleven passed after intentional regeneration and visual inspection, including the localized Apple/Google section in English light/dark and Arabic RTL; Material Icons, deterministic Roboto glyphs, and an Arabic-capable Windows test font are loaded by the harness.
- Installed-emulator integration: one onboarding → mock email sign-in → home → settings → local account deletion flow passed on `Pixel_7_API_35_Test` (API 35).
- Supabase functions: the original three entry points passed local Deno checks; the fourth `legal` function compiled and deployed successfully, then passed live GET, invalid POST, valid POST, rate-control/CORS, and cleanup probes.
- Android UI: onboarding, authentication, home, and audio preparation were inspected at 1080×2400. Logcat contained no `FATAL EXCEPTION` or `E/flutter` finding in the verified flows.
- Android handoff: a real exported test sender supplied a granted `content://` Ogg/Opus URI through the Android share sheet. Warm and force-stopped/cold flows passed on API 35 and physical `SM_N950F` Android 9; the provider package was removed afterward.
- Physical Note 8 UI/recording: the installed live-config debug build automatically selected Arabic from the device `ar-AE` locale, rendered the redesigned Home screen and the centered History empty state without overflow at 1080x2220, showed `10` of `10` free minutes, requested Android microphone permission in Arabic only after the record control was pressed, then recorded with a progressing timer and a waveform that changed between consecutive physical-device captures without VoiceBrief/Flutter errors. The newly created test recording was canceled and removed; pre-existing app cache/user state was preserved.
- Physical Note 8 audio editing: a 2:46 extensionless MP3 from an Android document provider imported successfully without a redundant private-file copy, its real waveform completed asynchronously, slider seek reached 1:34, waveform tap reached 2:29, and range selection 0:42–1:11 exported a real 0:29 AAC/M4A and reached Result within the 15-second acceptance wait. A single Back after picker import returned to Home; the former duplicate preparation route was eliminated.
- Physical Note 8 deletion: swiping the saved result in Arabic RTL removed it immediately, displayed `تم حذف الملخص` plus `تراجع`, and Undo restored the exact item. This verifies that local persistence latency no longer blocks the visible deletion.
- Latest local source verification for `0.1.0+4`: `dart format` required no changes, `flutter analyze` passed, all 29 non-golden tests passed, all eleven golden tests passed, and `flutter build apk --debug` completed. The earlier scoped `:app:connectedDebugAndroidTest` still passed its real shared Opus intent test on `SM_N950F`; the unscoped aggregate Gradle task is not used because it also tries to instrument plugin library modules with incompatible test-app minimum SDK declarations.
- GitHub Actions run `32888914885` passed from commit `116efb3`: Linux completed format, analyze, all 29 non-golden tests, and the Android debug APK; Windows completed all eleven golden tests; macOS completed `pod install`, a live-config release iOS build with `USE_MOCK_SERVICES=false`, source checks for Apple sign-in and App Group entitlements, bundle-ID/Share Extension checks, version/build parity checks, IPA packaging, and artifact upload. The added auth regression test covers a pending Supabase OAuth launch, completion through `onAuthStateChange`, and account activation after the deep-link callback. Both built plists and the independently inspected IPA report `0.1.0 (4)` for the app and extension.
- GitHub Actions run `32893325708` passed from commit `0bd5518`: macOS repeated format, analysis, 29 non-golden tests and the live iOS source build, fetched the exact App Store profiles for both bundle IDs, installed the owned Apple Distribution identity, archived and exported `0.1.0 (5)`, verified the signatures, embedded profiles, App Group and Apple sign-in entitlements, validated the IPA with Apple, and uploaded it to App Store Connect. The resulting 34,384,042-byte IPA has SHA-256 `C162AD0D8BDD9BF6513BCBBACC1AB60DA855A150EE4900CDCB632F488E185A63`.
- App Store Connect completed processing build `0.1.0 (5)` and reports `Ready to Submit`. Automatic distribution attached it to `VoiceBrief Internal`; the group reports one build, one internal tester, and `mhm1981dx@gmail.com` as `Invited`.
- The prior sideloaded build used the example configuration with `USE_MOCK_SERVICES=true`, which explains its repeated default transcript/summary. Build 2 requires the live Supabase values from GitHub Secrets and cannot silently fall back to mock services.
- Production release: the rebuilt owned-key APK passed v2 verification and the AAB passed JAR verification after the waveform/seek/trim/navigation/deletion changes. Earlier same-certificate production installation passed on API 35; this source-equivalent final behavior was physically exercised with the live-config debug build on Note 8.
- Public pages: Prettier and `html-validate` passed; Arabic RTL/dark mode was visually inspected locally at 1280×720. A live support request returned 201 and its row was deleted immediately.

## VoiceBrief build 9 verification — 2026-08-30

- GitHub CI run `33031413075` passed Android build/analyze/tests, Windows golden tests, iOS no-codesign, and Deno format/test/check.
- TestFlight run `33031418401` passed archive/export, app/extension profile and entitlement checks, App Store validation, and upload. Apple delivery UUID: `d3788d62-0ca7-423f-b234-425a325012f7`. App Store Connect processing remains unverified.
- Local Deno verification passed format, five Arabic date-normalization tests, and `deno check` with the function config.
- Current Flutter verification passed format across 70 files with no changes, analysis with no issues, 30 non-golden tests, and all eleven golden tests.
- The deployed Arabic live smoke returned HTTP 200, detected Arabic, preserved both relative and explicit day/month markers, and returned two separate dates: `2026-08-31` and `2026-09-05`. Both require confirmation; the second remained date-only. The temporary user, uploaded object, and test entitlement were removed.
- After setting the GPT-5.6 summary request to low reasoning effort and low verbosity, the same sample measured `1,330ms` download, `1,460ms` transcription, `7,177ms` summary, and `11,282ms` total inside the function; client elapsed time was `14,431ms`.

## Platform checklist

Android remaining device checks: duplicate delivery timing, hostile/oversize provider, microphone denial/pause/resume, playback conflict/interruption, process death, background/resume, extreme font/display scaling, and TalkBack on the production-signed build. File picker import, real playback/seek/waveform/trim, Back, deletion/Undo, microphone allow/start/cancel, and the default Note 8 viewport have passed on physical hardware.

iOS/macOS remaining: signed App Group cold/warm handoff from WhatsApp, extension cancel/error on-device, Apple/Google redirect, microphone interruption/call/Bluetooth, sandbox monthly/annual/restore, and VoiceOver/Dynamic Type. Runner/extension compilation, signed archive/export, entitlement verification, and App Store validation/upload pass on GitHub macOS.

## Honest environment record

This Windows host has Android tooling and the `Pixel_7_API_35_Test` emulator. It has no local Xcode/CocoaPods/iOS Simulator/signing. GitHub Actions on macOS successfully compiled, signed, verified, validated, and uploaded the iOS app plus Share Extension; simulator interaction and physical-iPhone acceptance remain unperformed.
