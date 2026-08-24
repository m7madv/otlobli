import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/core/utils/audio_file_validator.dart';
import 'package:voicebrief/features/audio_import/data/audio_import_service.dart';
import 'package:voicebrief/features/audio_import/domain/audio_input.dart';

void main() {
  test('normalizes WhatsApp-style Opus names to an OGG upload', () {
    expect(
      AudioImportService.normalizeAudioName(
        'PTT-20260824-WA0001.opus',
        'audio/ogg',
      ),
      'PTT-20260824-WA0001.ogg',
    );
    expect(
      AudioImportService.normalizeAudioName(
        'shared-audio',
        'audio/opus; codecs=opus',
      ),
      'shared-audio.ogg',
    );
  });

  test('accepts a supported private audio file', () async {
    final directory = await Directory.systemTemp.createTemp('voicebrief-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}sample.mp3');
    await file.writeAsBytes([1, 2, 3]);
    final input = AudioInput(
      path: file.path,
      displayName: 'sample.mp3',
      mimeType: 'audio/mpeg',
      sizeBytes: 3,
      durationSeconds: 1,
      source: AudioSourceKind.picker,
    );
    await expectLater(AudioFileValidator.validate(input), completes);
  });

  test('rejects unsupported extensions before processing', () async {
    final input = AudioInput(
      path: 'unsafe.exe',
      displayName: 'unsafe.exe',
      mimeType: 'application/octet-stream',
      sizeBytes: 3,
      durationSeconds: 1,
      source: AudioSourceKind.picker,
    );
    await expectLater(
      AudioFileValidator.validate(input),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          AppFailureCode.unsupportedAudio,
        ),
      ),
    );
  });

  test('recognizes MP3 when Android omits its extension', () async {
    final directory = await Directory.systemTemp.createTemp(
      'voicebrief-signature-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}voice-note');
    await file.writeAsBytes(<int>[...'ID3'.codeUnits, 4, 0, 0, 0, 0, 0, 0, 0]);

    expect(
      await AudioImportService.detectMimeTypeForFile(file.path),
      'audio/mpeg',
    );
    expect(
      AudioImportService.normalizeAudioName('voice-note', 'audio/mpeg'),
      'voice-note.mp3',
    );
  });
}
