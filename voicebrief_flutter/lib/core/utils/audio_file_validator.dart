import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/features/audio_import/domain/audio_input.dart';

abstract final class AudioFileValidator {
  /// A deliberately conservative VoiceBrief product limit. Keep it aligned
  /// with `MAX_AUDIO_BYTES` in the server function.
  static const maxBytes = 25 * 1024 * 1024;

  static const supportedExtensions = {
    '.flac',
    '.mp3',
    '.mp4',
    '.mpeg',
    '.mpga',
    '.m4a',
    '.ogg',
    '.wav',
    '.webm',
  };

  static Future<void> validate(AudioInput input) async {
    if (!supportedExtensions.contains(
      path.extension(input.displayName).toLowerCase(),
    )) {
      throw const AppFailure(AppFailureCode.unsupportedAudio);
    }
    if (input.sizeBytes <= 0 || input.sizeBytes > maxBytes) {
      throw AppFailure(
        input.sizeBytes > maxBytes
            ? AppFailureCode.fileTooLarge
            : AppFailureCode.unreadableAudio,
      );
    }
    final file = File(input.path);
    if (!await file.exists() || await file.length() <= 0) {
      throw const AppFailure(AppFailureCode.unreadableAudio);
    }
  }
}
