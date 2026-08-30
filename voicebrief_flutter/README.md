# VoiceBrief

VoiceBrief is a privacy-conscious Flutter application that turns imported, shared, or recorded audio into a transcript, concise brief, key points, action items, important dates, and suggested replies. Imported audio has a real waveform, direct seeking, and a selectable range that can be trimmed before processing.

The repository is runnable without paid services by default. `USE_MOCK_SERVICES=true` uses deterministic local fakes; production mode uses Supabase Auth/Storage/Edge Functions, server-only OpenAI processing, and RevenueCat.

## Quick start

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run --dart-define-from-file=dart-defines.example.json
```

The sample configuration intentionally enables mocks and contains no private credential. See [docs/SETUP.md](docs/SETUP.md) for production setup.

## Important boundaries

- OpenAI and Supabase service-role credentials exist only in Supabase Edge Function secrets.
- Original audio is copied to private temporary storage and deleted locally and remotely after processing.
- Android shared audio is adopted into the app's private handoff file without a second copy; waveform extraction stays asynchronous so playback and navigation remain responsive.
- Trimming exports a real private AAC/M4A on Android and iOS before upload. The transcript is automatic and displayed as an optional collapsed word-for-word reference, not as a second summary choice.
- Results are stored in Drift only when the user explicitly saves them.
- Server usage reservation and charging are atomic and idempotent by client job ID.
- Android receives `audio/*` through native Kotlin. On iOS, Runner registers as a `public.audio` document opener where source apps support document-open. For apps such as WhatsApp that expose only a Share Extension, `VoiceBriefShare` securely copies, uploads, processes, and displays the brief inside the share window because iOS does not permit launching the containing app.

## Verification

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test --exclude-tags golden
flutter test test/golden_screens_test.dart
npx -y deno fmt --check supabase/functions
npx -y deno lint supabase/functions
npx -y deno check supabase/functions/process-audio/index.ts
flutter build apk --debug
flutter build appbundle --release
```

Local Android verification and artifact hashes are recorded in [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md). Android release builds now fail closed without the private upload key; the repeatable local process is documented in [docs/ANDROID_RELEASE_SIGNING.md](docs/ANDROID_RELEASE_SIGNING.md).

The application ID and bundle ID currently use the production candidate `app.voicebrief.mobile`. Confirm availability when creating the store listings; if it changes, follow [docs/CONFIGURATION.md](docs/CONFIGURATION.md) before the first upload.
