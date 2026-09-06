# VoiceBrief localization — 0.1.2 (21)

## Coverage and behavior

Eleven UI locales: `ar`, `en`, `zh` (Simplified), `hi`, `es`, `fr`, `bn`, `pt`, `ru`, `ur`, `id`. English was already present, so this provides ten non-Arabic choices by completing nine new translations. Each ARB has 266 messages and matching interpolation metadata. Arabic and Urdu use RTL.

Settings → App language uses native language names. The device preference is saved independently of the account, quota and theme, including across sign-out. System mode respects device language order with English fallback; Traditional Chinese falls back rather than claiming a Simplified translation is Traditional. iOS shares the saved language through its existing App Group for extension text; the operating system controls permission-dialog localization. Android declares its supported locales for system per-app language settings.

UI language is not audio language. Neither the Flutter upload nor iOS Share Extension now guesses a recording's language from the device. The backend preserves the spoken language and summarizes in it, unless the existing English-translation option is requested. Historic results are not retranslated. Arabic date safeguards remain. Legal/support pages remain Arabic/English and are disclosed as such in localized store copy; they are not claimed to be translated into eleven languages.

Native strings live in `ios/Localization`, compiled into both Runner and ShareExtension. No new runtime package or font was added. Translation completeness, interpolation, persistence, RTL, and main-screen layout at narrow width/large text are tested; this is not professional native-speaker certification or physical-device acceptance.

## Regeneration and checks

From `voicebrief_flutter`:

```powershell
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze --no-pub
flutter test --exclude-tags golden
flutter test test/golden_screens_test.dart
flutter test test/store_screenshots_test.dart --dart-define=GENERATE_STORE_SCREENSHOTS=true
node scripts/prepare_store_localizations.mjs
```

The opt-in screenshot renderer uses Windows font resources (Arial, Nirmala UI, Microsoft YaHei; existing Roboto otherwise) only for marketing export. It does not alter the shipped fonts. There are four screenshots per device and language: import/home, brief, date actions, and history. These are actual production Flutter widgets with explicit synthetic localized sample content, rendered off-device. They must not be described as physical iPad captures. Never put customer recordings or accounts in this data.

## Store draft and artifacts

`store_assets/localized/{language}/{iphone|ipad}/0{1..4}_*.png`: 88 files total. iPhone is 1284×2778 (`APP_IPHONE_65`), iPad is 2064×2752 (`APP_IPAD_PRO_3GEN_129`). `manifest.json` includes dimensions, byte sizes, SHA-256 and localized version metadata. `sample_content.json` and `release_copy.json` are the editable source data.

Apple locale mapping: ar-SA, en-US, zh-Hans, hi, es-ES, fr-FR, bn-BD, pt-BR, ru, ur-PK, id. Reference: [Apple localizations](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations), [API locale shortcodes](https://developer.apple.com/documentation/appstoreconnectapi/managing-metadata-in-your-app-by-using-locale-shortcodes), [screenshot dimensions](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

Apple chooses storefront localization according to available localizations, the customer's language settings and storefront; an in-app language override cannot control the App Store page. The application's device-language fallback is English, but the existing App Store primary localization remains Arabic and was not changed. A store fallback is not a promise that every region will display a specific language.

`voicebrief-localize-store.yml` has two explicit modes. `inspect` only reads versions (also the automatic push mode). `prepare` may create/edit VoiceBrief app 6805194629 version 0.1.2 only in an editable draft, then upload and verify four screenshots per locale/device. It never selects a build, submits review, changes territories or publishes. Existing screenshots in the currently public version are untouched; inherited draft images are replaced only after the new images are COMPLETE, with before-state reports saved as a workflow artifact. Unexpected pre-existing draft images stop the script for review. Credentials are read from existing GitHub secrets only and never printed.

Before release: require full CI including Xcode, native iPhone/iPad language switching/share/permission smoke tests, and native-speaker review of important payment/alarm wording. Version 21 must be built/uploaded and selected separately. A prepared store draft is not a published update.
