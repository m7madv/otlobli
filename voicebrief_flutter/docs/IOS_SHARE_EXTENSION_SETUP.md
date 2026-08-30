# iOS Share Extension setup

## Implemented

Runner declares `CFBundleDocumentTypes` for `public.audio` plus explicit MP3, MPEG-4 audio, and WAV types. When iOS offers VoiceBrief as a file-opening destination, selecting it launches the containing app and delivers a file URL. `SceneDelegate` handles cold and warm scene delivery, while `AppDelegate` keeps a non-scene fallback. `VoiceBriefShareBridge` validates the audio extension and 25 MB limit, retains security-scoped access while copying on a serial user-initiated queue, writes the atomic App Group manifest, and notifies Flutter when ready.

`VoiceBriefShare` remains a real save-only fallback target named `VoiceBrief Save`. `ShareViewController.swift` accepts the first audio attachment, obtains a temporary file representation, enforces 25 MB, copies it into the shared `Incoming` directory, and writes the same atomic manifest. Runner later consumes the payload through `VoiceBriefShareBridge`, copies it into app-private temporary storage, and removes the handoff value.

iOS Share Extensions cannot launch their containing app. Apple documents `NSExtensionContext.open` support on iOS only for Today and iMessage extension points, and build 9 failed both automatic and button-triggered calls on a physical iPhone. Build 10 removes that call and the misleading retry button. Never restore it or replace it with private `UIApplication`/responder-chain access.

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
- Verify the extension success/failure UI, VoiceOver, and App Group behavior on a physical device.
- From WhatsApp, verify that iOS lists the direct VoiceBrief file-opening destination and that selecting it launches Runner and imports the audio on cold and warm app states.
- Verify that the separate `VoiceBrief Save` fallback saves successfully, shows `Done`, and is not mistaken for the direct-launch destination.

This Windows implementation cannot claim Xcode compilation, signing, simulator, or device acceptance.
