import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_input.freezed.dart';
part 'audio_input.g.dart';

enum AudioSourceKind { picker, recording, androidShare, iosShare }

@freezed
sealed class AudioInput with _$AudioInput {
  const factory AudioInput({
    required String path,
    required String displayName,
    required String mimeType,
    required int sizeBytes,
    required int durationSeconds,
    required AudioSourceKind source,
  }) = _AudioInput;

  factory AudioInput.fromJson(Map<String, Object?> json) =>
      _$AudioInputFromJson(json);
}
