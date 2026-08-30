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

- GitHub CI run `33031413075` passed the build 9 candidate, and final run `33280858741` from performance commit `05d9c3e` passed Android build/analyze/tests/APK, Windows golden tests, iOS no-codesign packaging, and Deno format/test/check.
- TestFlight run `33031418401` passed archive/export, app/extension profile and entitlement checks, App Store validation, and upload. Apple delivery UUID: `d3788d62-0ca7-423f-b234-425a325012f7`.
- Read-only App Store Connect status run `33281554578` confirmed iOS `0.1.0 (9)` is `VALID`, unexpired, and attached to `VoiceBrief Internal`. Its build ID matches the delivery UUID; the safe status artifact is `9723131680` with SHA-256 `15DF660E61DAA9F05FC42A3696CB071A4F7FEF5ED772892131A8717C0EB71C1F`.
- Local Deno verification passed format, five Arabic date-normalization tests, and `deno check` with the function config.
- Current Flutter verification passed format across 70 files with no changes, analysis with no issues, 30 non-golden tests, and all eleven golden tests.
- The deployed Arabic live smoke returned HTTP 200, detected Arabic, preserved both relative and explicit day/month markers, and returned two separate dates: `2026-08-31` and `2026-09-05`. Both require confirmation; the second remained date-only. The temporary user, uploaded object, and test entitlement were removed.
- After setting the GPT-5.6 summary request to low reasoning effort and low verbosity, the same sample measured `1,330ms` download, `1,460ms` transcription, `7,177ms` summary, and `11,282ms` total inside the function; client elapsed time was `14,431ms`.

## VoiceBrief build 10 direct-open candidate — 2026-08-30

- Physical iPhone evidence rejects build 9's containing-app launch: the Share Extension saved the WhatsApp recording, but both its automatic `NSExtensionContext.open` request and visible `Open VoiceBrief` retry failed. This matches Apple's documented extension-point restriction.
- Build 10 registers Runner for general audio plus explicit MP3/MPEG-4/WAV types, handles file URLs through scene and app delegates, performs a bounded security-scoped copy, and preserves the existing Flutter inbox. The save-only fallback is visibly named `VoiceBrief Save`, accepts providers from apps that expose only Share Extension payloads, and no longer contains an impossible open action.
- Local verification passed format across 70 files, analysis with no issues, 30 non-golden tests, all eleven golden tests, and `flutter build apk --debug`. The 177,592,197-byte APK has SHA-256 `3C9B96B65281D140CAF3FEA05DAEBFB6CD636A7E78BD1ABB5803E7A548F97C15`.
- GitHub CI run `33283233763` passed Deno, Android, Windows golden, and macOS iOS no-codesign jobs. TestFlight run `33283233779` compiled, archived, signed, verified, validated, and uploaded app plus extension. The 34,432,164-byte IPA has SHA-256 `81763F19AEE9476F255CA6D117459CD99B29DB07D289E9257D567836FB5FF1FA`; delivery UUID is `d8a16f4a-74ad-4d7f-8368-220ca5ab9152`.
- App Store status run `33283233781` reports build `0.1.0 (10)` as `VALID`, unexpired, and attached to `VoiceBrief Internal`. Direct WhatsApp and cross-app cold/warm acceptance on the physical iPhone remain pending.
- The user then confirmed build 10 was installed and still did not open Runner from WhatsApp. Build 10 is device-rejected for that direct-open path; WhatsApp supplied only the Share Extension route on the tested device.

## VoiceBrief build 11 in-share processing candidate — 2026-08-30

- Build 11 replaces the impossible WhatsApp app-launch expectation with in-extension upload, transcription, summarization, result display, and explicit `Save in VoiceBrief`. Runner and extension synchronize the Supabase session through private App Group defaults; refreshed credentials are restored to Runner, and a saved processed-result handoff enters local history without a second audio upload or charge.
- Local verification passed format across 71 files, analysis with no issues, 31 non-golden tests including processed-result handoff normalization, all eleven golden tests, and `flutter build apk --debug`. The 177,596,157-byte APK has SHA-256 `CF8F63D8CBC22A9AC681A2F51FAED8F7C86CB0B6DA88D6856A84B24657D84E30`.
- GitHub CI run `33304112117` passed Deno, Android, Windows golden, and macOS iOS no-codesign jobs. TestFlight run `33304112113` compiled, archived, signed, verified, validated, and uploaded app plus extension. The 34,462,676-byte IPA has SHA-256 `AACAFA2BADBCA2026B1AF8080B66D0F455E79724E825BF15A8F0F352F04C577D`; delivery UUID is `4fdd86e6-da1e-41d6-820e-48290839548a`; GitHub artifact is `9730071886`.
- App Store status run `33304112131` reports build `0.1.0 (11)` as `VALID`, unexpired, and attached to `VoiceBrief Internal`. Physical WhatsApp live processing, session refresh, result display/save, and later-history acceptance remain pending.

## VoiceBrief build 12 ready-notification candidate — 2026-08-30

- Build 12 removes the manual `Save in VoiceBrief` success step. A successful extension run atomically persists the full processed result, schedules an authorized local notification with `voicebriefTarget=sharedResult`, removes local audio, and completes. Runner requests notification authorization after sign-in; a cold or warm notification tap imports/saves the result and routes directly to `/result`.
- The full result screen—not the former extension summary preview—renders dated action items, important dates, confirmation state, and calendar buttons. The processed-share parser test now carries an Arabic important date and asserts it survives. A controller test asserts the shared dated result is saved and increments the direct-result navigation request.
- Local verification passed format across 71 files, analysis with no issues, 32 non-golden tests, all eleven golden tests, and `flutter build apk --debug`. The 177,599,813-byte APK has SHA-256 `37729DAFEECC45CE66DF870AA167D4E660A7F3167C62E3352C003C3818029FE5`.
- GitHub CI run `33307726051` passed Deno, Android, Windows golden, and macOS iOS no-codesign jobs. TestFlight run `33307726042` compiled, archived, signed, verified, validated, and uploaded app plus extension. The 34,484,969-byte IPA has SHA-256 `12CC57885E1C9CEE4827F36D1B3072DA98CAE8DF254C3D714C44A6AC53DD7C8C`; delivery UUID is `0af3d7d3-a607-4913-9d39-a2429c73b3b0`; GitHub artifact is `9731160573` with ZIP SHA-256 `23A977FF2BECD533E5A2CF608A9E5472045DB8674817E60FCC2E4B5C20B114BE`.
- App Store status run `33307726047` reports build `0.1.0 (12)` as `VALID`, unexpired, and attached to `VoiceBrief Internal`. Status artifact `9731212465` has ZIP SHA-256 `767594E102E4DB43B67B599F7E12517C0C68289BED8DE49442D05CA88D9B7416`. Notification scheduling/tap behavior and physical WhatsApp dated-result acceptance remain pending.

## VoiceBrief build 14 system-alarm candidate — 2026-08-30

- User evidence accepts build 12's WhatsApp processing, manual close, ready notification, and resulting brief. Build 13 changes the processing copy to tell the user they can close the window and will be notified.
- Root cause for the absent appointment was Free-plan post-processing that cleared `importantDates`. Free results now retain dates, and transcript recovery adds relative Arabic dates if structured generation omits them. Seven Deno tests cover the screenshot phrase and the two-date sample.
- Result dates expose alarm and calendar actions. The Flutter channel remains unit-tested, and a widget test proves an ambiguous `الساعة الخامسة` opens date confirmation even if the structured result contains a full datetime. Build 14 changes the native iOS 26.1+ implementation from a local notification to AlarmKit; native compilation and physical-device behavior must be verified separately.
- Build 14 local verification passes format across 73 files, analysis with no issues, 34 non-golden tests, all eleven goldens, and an Android debug build. The `177,608,929`-byte APK has SHA-256 `55E9D3A19A34167B37C49B2D84B485FC21C66B86A787E0379DDF289A87B51986`. The unchanged server suite previously passed Deno format, seven date tests, and Deno check; deployed version 11's smoke returned HTTP 200 in `17,153ms`, kept tomorrow separate from `2026-09-05`, and cleaned its temporary account, object, and entitlement.
- CI run `33310667058` passed all four jobs. TestFlight run `33310667057` passed signing, app/extension/profile/entitlement verification, App Store validation, and upload. The `34,495,012`-byte IPA has SHA-256 `7AF8B0C14248BB40B1D5566362B56C271254385F383C20C0E116153970B6C4DF`; delivery UUID is `0625345c-86d1-495b-adba-430f117da4f7`.
- Build 14 CI run `33312938537` passed Deno, Android, eleven Windows goldens, and the Xcode no-codesign build. TestFlight run `33312941887` compiled AlarmKit with Xcode 26.6, signed, verified, validated, and uploaded the IPA; App Store status run `33313777125` reports `0.1.0 (14)` as `VALID`, unexpired, and attached to `VoiceBrief Internal`. Physical AlarmKit permission/ringing acceptance remains pending.

## VoiceBrief build 15 managed-alarm candidate — 2026-08-30

- Build 15 makes the app-owned nature of AlarmKit visible: tone selection/preview precedes scheduling, the native bridge persists the returned UUID and metadata, `/alarms` intersects persisted records with `AlarmManager.shared.alarms`, and cancellation calls `AlarmManager.cancel`. Three generated WAV tones are embedded in Runner resources and the selected named sound is supplied to AlarmKit.
- Local verification passed format across 74 files, analysis with no issues, 36 non-golden tests, all eleven goldens, and `flutter build apk --debug`. The `177,626,113`-byte APK has SHA-256 `8E0764D5E64C7C98282AF8ECF24E6258E63A3B8E40495F08AF8E18FE24118A9E`.
- Xcode compilation, signed upload, and physical iPhone acceptance for tone preview, selected-tone delivery, silent/Focus override, list refresh after firing, and cancellation are pending.

## Platform checklist

Android remaining device checks: duplicate delivery timing, hostile/oversize provider, microphone denial/pause/resume, playback conflict/interruption, process death, background/resume, extreme font/display scaling, and TalkBack on the production-signed build. File picker import, real playback/seek/waveform/trim, Back, deletion/Undo, microphone allow/start/cancel, and the default Note 8 viewport have passed on physical hardware.

iOS/macOS remaining: build 15 AlarmKit permission and near-future alarm delivery/UI/selected sound under silent and Focus, in-app list and cancellation, ambiguous-time confirmation, cold/warm/terminated notification tap, session refresh/sign-out, permission denial/re-enable, microphone interruption/call/Bluetooth, sandbox monthly/annual/restore, and VoiceOver/Dynamic Type. Build 13's appointment card and calendar action passed by user report, while its local-notification alarm substitute failed product acceptance. Build 12's WhatsApp processing/manual close/ready notification/result flow passed; builds 9 and 10 physically rejected the containing-app/direct-document launch expectation.

## Honest environment record

This Windows host has Android tooling and the `Pixel_7_API_35_Test` emulator. It has no local Xcode/CocoaPods/iOS Simulator/signing. GitHub Xcode 26.6 compiled, signed, verified, validated, and uploaded build 14, and App Store Connect reports it `VALID` in `VoiceBrief Internal`. Build 15 Xcode/upload work remains pending. The physical iPhone rejected builds 9/10 for WhatsApp direct opening, accepted build 12's notification-based flow, and accepted build 13's appointment/calendar path while rejecting its local-notification alarm substitute. Build 15 physical managed-AlarmKit acceptance remains pending.
