# Android sharing

## Implemented

The exported single-top `MainActivity` declares `ACTION_SEND` for `audio/*`. Kotlin supports cold `intent` and warm `onNewIntent`, reads `content://` through `ContentResolver`, copies at most 25 MB to private cache, closes cursor/streams, hashes a non-content fingerprint for duplicate suppression, and communicates only a private path/name/MIME/source record over `voicebrief/share`. A failed URI copy deletes any partial file and sends only a generic safe error to Flutter; it never logs the URI, filename, or platform exception.

No broad storage permission is requested. The app requests microphone access only when recording starts. Calendar uses an external insert intent.

## Verification commands

With an emulator/device and an audio fixture already on the device:

```bash
adb shell am force-stop app.voicebrief.mobile
adb shell am start -a android.intent.action.SEND -t audio/mpeg \
  --eu android.intent.extra.STREAM content://YOUR_PROVIDER/AUDIO

adb shell am start -a android.intent.action.SEND -t audio/mpeg \
  --eu android.intent.extra.STREAM content://YOUR_PROVIDER/AUDIO
adb logcat -d | grep -iE "voicebrief|flutter|AndroidRuntime"
```

Use a real content provider or system share sheet; a `file://` URI is not representative. Validate cold, warm, duplicate, process-death, unsupported MIME, unreadable URI, and oversize input. The Dart preparation screen must show the copied file and allow play/remove/replace.

The local API 35 emulator validated warm/cold handoff with an app-private `file://` fixture and validated the generic error path with an unreadable `content://` URI. The ADB shell cannot grant DocumentsProvider access on this image, so a successful `content://` share must still be checked from a real sender app/share sheet.

If the app does not appear in the share sheet, confirm the installed manifest contains the `audio/*` filter and the source app reports an audio MIME type.
