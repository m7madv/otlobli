# Setup

## Completed in this repository

- Flutter application, generated Android/iOS projects, dependencies, localization, icons, splash assets, tests, native share receivers, Supabase migration, and Edge Functions.
- Toolchain observed on 2026-08-24: Flutter 3.41.6 stable, Dart 3.11.4, Windows 11, JDK 21, Android SDK/API 36.1, and emulator `Pixel_7_API_35_Test`.
- Xcode, CocoaPods, iOS Simulator, and Apple signing cannot run on this Windows host. The iOS target is source-complete but must be compiled on macOS.

## Local mock run

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run --dart-define-from-file=dart-defines.example.json
```

The checked-in example uses mocks. It does not contact Supabase, OpenAI, RevenueCat, Apple, or Google.

## Production owner actions

1. Confirm the production-candidate IDs in Apple and Google before the first store upload; legal URLs are already live at `https://voicebrief-legal.vercel.app`.
2. Supabase and Vercel are live. Create the remaining Apple Developer, Google Cloud OAuth, RevenueCat, App Store Connect, and Google Play records.
3. The three migrations and four Edge Functions are already deployed to the VoiceBrief Supabase project. Apply future migrations in timestamp order.
4. Server secrets must remain in Supabase; never copy them into mobile configuration. OpenAI is already configured, while the RevenueCat webhook secret waits for the RevenueCat project.
5. The ignored production Dart-define file already contains public Supabase values and `USE_MOCK_SERVICES=false`; add only public RevenueCat/OAuth identifiers after dashboard creation.
6. Android upload signing is configured locally. Back it up, add the documented SHA fingerprints to Google, configure Apple App Group/signing, and run dashboard-specific verification.

## Common failures

- **App stays in demo mode:** `USE_MOCK_SERVICES` is missing or true.
- **Configuration failure:** Supabase URL/key or the platform RevenueCat public key is empty.
- **OAuth returns to the browser:** add `voicebrief://auth/callback` and `voicebrief://auth/reset` to Supabase redirect allowlists and platform URL schemes.
- **iOS Share Extension is absent:** enable the same App Group for Runner and `VoiceBriefShare`, select a valid team, and confirm the extension is embedded in Runner.
- **Store prices are unavailable:** publish/test the products, attach them to RevenueCat offering `default`, and use the correct public SDK key.
- **Release build stops before Gradle work:** run the private signing script documented in `docs/ANDROID_RELEASE_SIGNING.md`; this fail-closed behavior is intentional.

Run `flutter doctor -v` again on the release machine and resolve only errors relevant to Android/iOS. Visual Studio is not required for this mobile-only project.
