import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/core/utils/audio_file_validator.dart';
import 'package:voicebrief/features/audio_import/domain/audio_input.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';

class AudioImportService {
  const AudioImportService();

  static const _uuid = Uuid();
  static const _audioEditChannel = MethodChannel('voicebrief/audio_edit');

  Future<AudioInput?> pick() async {
    final selected = await FilePicker.pickFile(type: FileType.audio);
    if (selected == null) return null;
    final selectedPath = selected.path;
    if (selectedPath == null) {
      throw const AppFailure(AppFailureCode.unreadableAudio);
    }
    var displayName = selected.name;
    var mimeType = _mimeForName(displayName);
    if (path.extension(displayName).isEmpty) {
      final sourceExtension = path.extension(selectedPath).toLowerCase();
      if (AudioFileValidator.supportedExtensions.contains(sourceExtension)) {
        displayName = '$displayName$sourceExtension';
        mimeType = _mimeForName(displayName);
      } else {
        mimeType = await detectMimeTypeForFile(selectedPath);
        displayName = normalizeAudioName(displayName, mimeType);
      }
    }
    return importPrivateCopy(
      sourcePath: selectedPath,
      displayName: displayName,
      mimeType: mimeType,
      source: AudioSourceKind.picker,
    );
  }

  Future<AudioInput> importPrivateCopy({
    required String sourcePath,
    required String displayName,
    required String mimeType,
    required AudioSourceKind source,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw const AppFailure(AppFailureCode.unreadableAudio);
    }
    final normalizedName = normalizeAudioName(displayName, mimeType);
    final tempDirectory = await getTemporaryDirectory();
    final extension = path.extension(normalizedName).toLowerCase();
    final privatePath = path.join(
      tempDirectory.path,
      'voicebrief_${_uuid.v4()}$extension',
    );
    File privateFile;
    if (sourcePath == privatePath) {
      privateFile = sourceFile;
    } else if (path.isWithin(tempDirectory.path, sourcePath)) {
      try {
        privateFile = await sourceFile.rename(privatePath);
      } on FileSystemException {
        privateFile = await sourceFile.copy(privatePath);
      }
    } else {
      privateFile = await sourceFile.copy(privatePath);
    }
    try {
      return await _validatedInput(
        file: privateFile,
        displayName: normalizedName,
        mimeType: mimeType,
        source: source,
      );
    } on Object {
      await privateFile.delete().catchError((_) => privateFile);
      rethrow;
    }
  }

  /// Adopts a file already copied into VoiceBrief-owned private storage by a
  /// share extension/activity. Avoiding a second full-file copy makes the
  /// WhatsApp handoff noticeably faster, especially on older devices.
  Future<AudioInput> importOwnedPrivateFile({
    required String sourcePath,
    required String displayName,
    required String mimeType,
    required AudioSourceKind source,
    int? knownSizeBytes,
    int? knownDurationSeconds,
  }) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw const AppFailure(AppFailureCode.unreadableAudio);
    }
    return _validatedInput(
      file: file,
      displayName: normalizeAudioName(displayName, mimeType),
      mimeType: mimeType,
      source: source,
      knownSizeBytes: knownSizeBytes,
      knownDurationSeconds: knownDurationSeconds,
    );
  }

  Future<AudioInput> trim(
    AudioInput input, {
    required Duration start,
    required Duration end,
  }) async {
    if (start < Duration.zero || end <= start) {
      throw const AppFailure(AppFailureCode.audioEditing);
    }
    final tempDirectory = await getTemporaryDirectory();
    final outputPath = path.join(
      tempDirectory.path,
      'voicebrief_trim_${_uuid.v4()}.m4a',
    );
    final outputFile = File(outputPath);
    try {
      final completed = await _audioEditChannel.invokeMethod<bool>('trim', {
        'inputPath': input.path,
        'outputPath': outputPath,
        'startMs': start.inMilliseconds,
        'endMs': end.inMilliseconds,
      });
      if (completed != true || !await outputFile.exists()) {
        throw const AppFailure(AppFailureCode.audioEditing);
      }
      final stem = path.basenameWithoutExtension(input.displayName).trim();
      return await _validatedInput(
        file: outputFile,
        displayName: '${stem.isEmpty ? 'voice-note' : stem}-trimmed.m4a',
        mimeType: 'audio/mp4',
        source: input.source,
      );
    } on AppFailure {
      if (await outputFile.exists()) await outputFile.delete();
      rethrow;
    } on Object {
      if (await outputFile.exists()) await outputFile.delete();
      throw const AppFailure(AppFailureCode.audioEditing);
    }
  }

  Future<AudioInput> _validatedInput({
    required File file,
    required String displayName,
    required String mimeType,
    required AudioSourceKind source,
    int? knownSizeBytes,
    int? knownDurationSeconds,
  }) async {
    final size = knownSizeBytes != null && knownSizeBytes > 0
        ? knownSizeBytes
        : await file.length();
    final durationSeconds =
        knownDurationSeconds != null && knownDurationSeconds > 0
        ? knownDurationSeconds
        : await _durationSeconds(file.path);
    final input = AudioInput(
      path: file.path,
      displayName: displayName,
      mimeType: _canonicalMime(displayName, mimeType),
      sizeBytes: size,
      durationSeconds: durationSeconds,
      source: source,
    );
    await AudioFileValidator.validate(input);
    if (durationSeconds <= 0) {
      throw const AppFailure(AppFailureCode.unreadableAudio);
    }
    return input;
  }

  Future<int> _durationSeconds(String filePath) async {
    final player = AudioPlayer();
    try {
      final duration = await player.setFilePath(filePath);
      return duration?.inSeconds ?? 0;
    } on Object {
      throw const AppFailure(AppFailureCode.unreadableAudio);
    } finally {
      await player.dispose();
    }
  }

  Future<void> discard(AudioInput input) async {
    final file = File(input.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> discardSourcePath(String sourcePath) async {
    try {
      final file = File(sourcePath);
      if (await file.exists()) await file.delete();
    } on Object {
      // Best-effort cleanup. Source paths and errors are intentionally not logged.
    }
  }

  String _mimeForName(String name) =>
      switch (path.extension(name).toLowerCase()) {
        '.mp3' || '.mpeg' || '.mpga' => 'audio/mpeg',
        '.m4a' || '.mp4' => 'audio/mp4',
        '.wav' => 'audio/wav',
        '.ogg' => 'audio/ogg',
        '.flac' => 'audio/flac',
        '.webm' => 'audio/webm',
        _ => 'application/octet-stream',
      };

  /// Some Android document providers omit both the filename extension and
  /// MIME type. A small signature check keeps valid audio selectable without
  /// reading the whole file or trusting an arbitrary filename.
  static Future<String> detectMimeTypeForFile(String filePath) async {
    final randomAccessFile = await File(filePath).open();
    late final List<int> bytes;
    try {
      bytes = await randomAccessFile.read(16);
    } finally {
      await randomAccessFile.close();
    }
    bool hasAscii(int offset, String value) {
      if (bytes.length < offset + value.length) return false;
      for (var index = 0; index < value.length; index++) {
        if (bytes[offset + index] != value.codeUnitAt(index)) return false;
      }
      return true;
    }

    if (hasAscii(0, 'ID3') ||
        (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] & 0xe0 == 0xe0)) {
      return 'audio/mpeg';
    }
    if (hasAscii(0, 'RIFF') && hasAscii(8, 'WAVE')) return 'audio/wav';
    if (hasAscii(0, 'OggS')) return 'audio/ogg';
    if (hasAscii(0, 'fLaC')) return 'audio/flac';
    if (hasAscii(4, 'ftyp')) return 'audio/mp4';
    if (bytes.length >= 4 &&
        bytes[0] == 0x1a &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xdf &&
        bytes[3] == 0xa3) {
      return 'audio/webm';
    }
    return 'application/octet-stream';
  }

  static String normalizeAudioName(String name, String suppliedMime) {
    final trimmedName = path.basename(
      name.trim().isEmpty ? 'shared-audio' : name.trim(),
    );
    final extension = path.extension(trimmedName).toLowerCase();
    final mime = suppliedMime.split(';').first.trim().toLowerCase();
    final canonicalExtension = switch ((extension, mime)) {
      ('.opus', _) => '.ogg',
      (
        _,
        'audio/ogg' || 'audio/opus' || 'audio/x-opus+ogg' || 'application/ogg',
      )
          when extension.isEmpty || extension == '.bin' =>
        '.ogg',
      (_, 'audio/mp4' || 'audio/x-m4a')
          when extension.isEmpty || extension == '.bin' =>
        '.m4a',
      (_, 'audio/mpeg' || 'audio/mp3')
          when extension.isEmpty || extension == '.bin' =>
        '.mp3',
      (_, 'audio/wav' || 'audio/x-wav')
          when extension.isEmpty || extension == '.bin' =>
        '.wav',
      (_, 'audio/flac') when extension.isEmpty || extension == '.bin' =>
        '.flac',
      (_, 'audio/webm') when extension.isEmpty || extension == '.bin' =>
        '.webm',
      _ => extension,
    };
    if (canonicalExtension == extension) return trimmedName;
    final stem = extension.isEmpty
        ? trimmedName
        : path.basenameWithoutExtension(trimmedName);
    return '$stem$canonicalExtension';
  }

  String _canonicalMime(String name, String supplied) {
    final inferred = _mimeForName(name);
    return inferred == 'application/octet-stream' ? supplied : inferred;
  }
}

class SharedAudioInbox {
  SharedAudioInbox() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shareError') {
        _received.addError(const AppFailure(AppFailureCode.shareHandoff));
        return;
      }
      if (call.method == 'shareProcessed' && call.arguments is Map) {
        final envelope = Map<Object?, Object?>.from(call.arguments as Map);
        final rawResult = envelope['result'];
        final result = _parseProcessed(
          rawResult is Map ? Map<Object?, Object?>.from(rawResult) : envelope,
        );
        if (result != null) {
          _processed.add((
            result: result,
            openResult: envelope['openResult'] == true,
            ownerUserId: envelope['ownerUserId'] as String? ?? '',
          ));
        }
        return;
      }
      if (call.method == 'openSharedResult') {
        _openProcessed.add(null);
        return;
      }
      if (call.method != 'shareReceived' || call.arguments is! Map) return;
      final payload = _parse(Map<Object?, Object?>.from(call.arguments as Map));
      if (payload != null) _received.add(payload);
    });
  }

  static const _channel = MethodChannel('voicebrief/share');
  final _received = StreamController<SharedAudioPayload>.broadcast();
  final _processed = StreamController<SharedProcessedResult>.broadcast();
  final _openProcessed = StreamController<void>.broadcast();

  Stream<SharedAudioPayload> get received => _received.stream;
  Stream<SharedProcessedResult> get processed => _processed.stream;
  Stream<void> get openProcessed => _openProcessed.stream;

  Future<void> invalidateSharedSession() async {
    try {
      await _channel.invokeMethod<void>('syncShareSession');
    } on MissingPluginException {
      // Non-iOS platforms and tests do not install the share bridge.
    } on PlatformException {
      // Local sign-out must still proceed if the optional bridge is absent.
    }
  }

  Future<SharedAudioPayload?> takePending() async {
    final value = await _channel.invokeMapMethod<String, Object?>(
      'takePendingShare',
    );
    if (value?['error'] != null) {
      throw const AppFailure(AppFailureCode.shareHandoff);
    }
    if (value?['kind'] == 'processed' && value?['result'] is Map) {
      final result = _parseProcessed(
        Map<Object?, Object?>.from(value!['result']! as Map),
      );
      if (result != null) {
        _processed.add((
          result: result,
          openResult: value['openResult'] == true,
          ownerUserId: value['ownerUserId'] as String? ?? '',
        ));
      }
      return null;
    }
    return value == null ? null : _parse(value);
  }

  BriefResult? _parseProcessed(Map<Object?, Object?> value) {
    try {
      return BriefResult.fromJson(_normalizeMap(value));
    } on Object {
      _processed.addError(const AppFailure(AppFailureCode.invalidResponse));
      return null;
    }
  }

  Map<String, Object?> _normalizeMap(Map<Object?, Object?> value) =>
      value.map((key, item) => MapEntry(key.toString(), _normalizeValue(item)));

  Object? _normalizeValue(Object? value) {
    if (value is Map) {
      return _normalizeMap(Map<Object?, Object?>.from(value));
    }
    if (value is List) return value.map(_normalizeValue).toList();
    return value;
  }

  SharedAudioPayload? _parse(Map<Object?, Object?> value) {
    final sharedPath = value['path'] as String?;
    if (sharedPath == null || sharedPath.isEmpty) return null;
    return (
      path: sharedPath,
      name: (value['name'] as String?) ?? path.basename(sharedPath),
      mime: (value['mime'] as String?) ?? 'application/octet-stream',
      source: (value['source'] as String?) ?? 'unknown',
      sizeBytes: (value['sizeBytes'] as num?)?.toInt(),
      durationSeconds: (value['durationSeconds'] as num?)?.toInt(),
    );
  }

  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _received.close();
    await _processed.close();
    await _openProcessed.close();
  }
}

typedef SharedProcessedResult = ({
  BriefResult result,
  bool openResult,
  String ownerUserId,
});

typedef SharedAudioPayload = ({
  String path,
  String name,
  String mime,
  String source,
  int? sizeBytes,
  int? durationSeconds,
});
