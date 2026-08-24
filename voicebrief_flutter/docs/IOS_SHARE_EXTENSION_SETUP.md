# iOS Share Extension setup

## Implemented

`VoiceBriefShare` is a real application-extension target embedded in Runner. `ShareViewController.swift` accepts the first `public.audio` attachment, obtains a temporary file representation, enforces 25 MB, copies it into the shared `Incoming` directory, writes a small payload to App Group defaults, and opens `voicebrief://shared-audio` through `NSExtensionContext.open`. It never calls `UIApplication.shared`.

Runner consumes the payload through `VoiceBriefShareBridge`, copies it again into app-private temporary storage, and removes the handoff value. Cold launch leaves the value pending until Dart asks; warm launch emits it after Dart has declared readiness.

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

This Windows implementation cannot claim Xcode compilation, signing, simulator, or device acceptance.
