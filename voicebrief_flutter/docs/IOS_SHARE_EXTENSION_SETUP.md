# iOS Share Extension setup

## Implemented

`VoiceBriefShare` is a real application-extension target embedded in Runner. `ShareViewController.swift` accepts the first `public.audio` attachment, obtains a temporary file representation, enforces 25 MB, copies it into the shared `Incoming` directory, and writes an atomic manifest in the App Group container. It then makes a best-effort request to open `voicebrief://shared-audio` through the public `NSExtensionContext.open` API. It never calls `UIApplication.shared` or walks the responder chain.

Runner consumes the payload through `VoiceBriefShareBridge`, copies it again into app-private temporary storage, and removes the handoff value. Cold launch leaves the value pending until Dart asks; warm launch emits it after Dart has declared readiness.

iOS does not guarantee that a Share Extension may launch its containing app. If the system rejects the automatic request, the extension keeps the imported file intact and exposes a localized `Open VoiceBrief` retry action. This fallback is deliberate and App Store-safe; do not replace it with private `UIApplication` access.

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
- Verify both outcomes of the best-effort app-open request: direct transition when allowed, and the labelled retry fallback when iOS refuses it.

This Windows implementation cannot claim Xcode compilation, signing, simulator, or device acceptance.
