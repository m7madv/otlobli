# iOS Share Extension setup

## Implemented

Runner declares `CFBundleDocumentTypes` for `public.audio` plus explicit MP3, MPEG-4 audio, and WAV types. When iOS offers VoiceBrief as a file-opening destination, selecting it launches the containing app and delivers a file URL. `SceneDelegate` handles cold and warm scene delivery, while `AppDelegate` keeps a non-scene fallback. `VoiceBriefShareBridge` validates the audio extension and 25 MB limit, retains security-scoped access while copying on a serial user-initiated queue, writes the atomic App Group manifest, and notifies Flutter when ready.

`VoiceBriefShare` is named `VoiceBrief` and handles sources that expose only an `NSItemProvider`. It accepts the first audio attachment, obtains a temporary file representation, enforces 25 MB, copies it into `Incoming`, and writes an atomic fallback manifest. Runner synchronizes the current Supabase URL, public key, access/refresh tokens, user ID, and expiry into App Group defaults; the extension refreshes an expiring session, uploads to the user's private `audio-temp` path, and invokes `process-audio` while its UI remains open.

On success the extension atomically replaces the audio manifest with a processed-result manifest, deletes local audio, schedules a one-second local `Brief ready` notification, and closes automatically. Runner requests alert/sound/badge authorization after sign-in. Notification selection sets `openResult`, launches Runner, lets Flutter deep-normalize and save the result to account-scoped local history, refreshes quota, and routes directly to `/result`; a fallback `openSharedResult` event covers a result already imported while Runner stayed alive. No second upload or charge occurs. A refreshed extension token is restored into Supabase before Runner re-synchronizes the session. No token, transcript, file name, or identity is logged.

iOS Share Extensions cannot launch their containing app. Apple documents `NSExtensionContext.open` support on iOS only for Today and iMessage extension points; build 9 failed both automatic and button-triggered calls, and build 10 confirmed WhatsApp did not offer Runner's document destination. Build 12 processes inside the extension and relies on the user's supported notification tap to launch Runner after completion. Never restore the open call or replace it with private `UIApplication`/responder-chain access.

Source applications differ: some expose audio as an openable document, while others expose only an `NSItemProvider` to Share Extensions. The two targets cover both supported delivery shapes, but iOS does not provide a public way to force the containing app to launch from the second shape. Do not register Runner for generic `public.data`; that would advertise VoiceBrief for unrelated files.

## Owner/Xcode work

1. Replace IDs consistently if needed: Runner, `.share`, and `group.app.voicebrief.mobile`.
2. Select the same Apple team for Runner and `VoiceBriefShare`.
3. Create/enable the App Group in the Developer portal and both target Signing & Capabilities tabs.
4. Confirm Runner embeds `VoiceBriefShare.appex` and both entitlements resolve in the signed products.
5. Run `pod install`, then build through `Runner.xcworkspace` on macOS.

## Device verification

- Share supported M4A/MP3/WAV from Files, Messages, Voice Memos, and another provider to cold and warm VoiceBrief.
- Cancel the extension, send an unsupported/multiple attachment, exceed 25 MB, repeat the same share, force-quit the host, and verify no duplicate result or orphaned App Group file.
- Open Runner once after installation/sign-in and verify session synchronization without exposing values in logs.
- From WhatsApp and other providers, allow VoiceBrief notifications, keep the share window open through upload/transcription/summary, verify it closes automatically, then tap `Brief ready`. Confirm Runner opens directly on the matching result, dated items and calendar buttons are present, history contains it, and no second charge occurs.
- Test notification denial/re-enable, cold/warm/terminated Runner taps, access-token refresh, sign-out clearing, no network, exhausted quota, cancellation before completion, retry, large/invalid audio, VoiceOver, Dynamic Type, and extension termination. Direct Runner opening remains a separate source-dependent document-open path and is not expected before a user taps the ready notification.

This Windows implementation cannot claim Xcode compilation, signing, simulator, or device acceptance.
