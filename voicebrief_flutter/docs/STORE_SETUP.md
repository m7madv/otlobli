# Store preparation

## Metadata draft

- Name: VoiceBrief
- Subtitle: Voice messages, made clear
- Short description: Transcribe voice messages, create summaries, extract tasks, and generate ready-to-send replies.
- Version: `0.1.0+1` (increase before submission)

Icons, adaptive icon, iOS icon set, launch assets, microphone descriptions, URL scheme, Android share filter, iOS Share Extension, and subscription IDs exist in source.

## Completed preparation

- Public bilingual Privacy, Terms, and Support pages are deployed at `https://voicebrief-legal.vercel.app`; the support form writes through the public `legal` Edge Function into a service-role-only table with input limits, a honeypot, and a five-requests-per-network/day limit.
- Android upload signing is private, repeatable, and fail-closed. Signed APK/AAB paths, hashes, and certificate fingerprints are in `RELEASE_CHECKLIST.md` and `ANDROID_RELEASE_SIGNING.md`.
- The production-signed APK cold-launched on the API 35 emulator in about 5.46 seconds, remained the resumed activity, and produced no fatal Android runtime entry.

## Owner work before release

- Confirm `app.voicebrief.mobile` and its App Group are available before first store registration; change every identity together if unavailable.
- Have the owner/legal reviewer approve the published policy/terms and complete Apple App Privacy and Google Data Safety using `PRIVACY_DATA_MAP.md`.
- Create subscription products and reviewer sandbox account. Add review notes explaining shared audio, temporary processing, calendar confirmation, and where Restore Purchases/Delete Account appear.
- Back up the Android upload keystore and password separately before the first Play upload.
- On macOS, run `pod install`, build Runner plus `VoiceBriefShare`, archive, validate entitlements, and test TestFlight.
- Capture store screenshots from real release-mode builds; golden test images are QA artifacts, not store marketing assets.

## Release verification

Test clean install, upgrade, cold/warm launch, offline state, deep links, email verification/reset, provider sign-in, audio import/share/record/playback, quota exhaustion/refund, both purchases, restore, cancellation disclosure, account deletion, large text, TalkBack/VoiceOver, background/resume, and privacy cleanup.

Nothing in this repository publishes or submits an application automatically.
