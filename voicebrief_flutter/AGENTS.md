# VoiceBrief agent instructions

Before changing code, read `PLAN.md`, `README.md`, and the relevant file in `docs/`.

## Non-negotiable security boundaries

- Never add `OPENAI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `REVENUECAT_WEBHOOK_SECRET`, Apple private keys, signing keys, or OAuth client secrets to Flutter, Android resources, iOS plists, Dart defines, fixtures, logs, screenshots, or Git.
- Do not weaken RLS, private Storage policies, job idempotency, atomic minute reservation, webhook replay protection, or audio cleanup to make a test pass.
- Never log transcript, summary, reply, original filename, OAuth token, email, or shared content URI.
- Keep bundle identities and legal URLs centralized in `lib/app/config/app_config.dart`.

## Product invariants

- Audio is temporary; saved history contains generated text only.
- Calendar creation always requires an explicit user confirmation.
- Free/Pro enforcement is server-side; client gating is explanatory only.
- Local history remains separated by authenticated account ID.
- Android sharing must support cold and warm `ACTION_SEND` with `audio/*`.
- iOS sharing must use the App Group and extension-safe APIs—never `UIApplication.shared` hacks.

## Required checks

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test --exclude-tags golden
flutter test test/golden_screens_test.dart
flutter build apk --debug
```

For UI changes, regenerate goldens deliberately with `flutter test test/golden_screens_test.dart --update-goldens`, inspect the PNGs, then rerun without the update flag. Document unperformed iOS/real-device checks honestly.
