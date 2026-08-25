import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:voicebrief/core/errors/app_failure.dart';

class RecorderService {
  RecorderService({AudioRecorder? recorder}) : _recorder = recorder;

  AudioRecorder? _recorder;
  static const _uuid = Uuid();
  static const _microphoneChannel = MethodChannel('voicebrief/microphone');

  AudioRecorder get _activeRecorder => _recorder ??= AudioRecorder();

  Stream<Amplitude> amplitudeStream() =>
      _activeRecorder.onAmplitudeChanged(const Duration(milliseconds: 120));

  Future<void> start() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      throw const AppFailure(AppFailureCode.microphoneDenied);
    }
    final directory = await getTemporaryDirectory();
    final target = path.join(
      directory.path,
      'voicebrief_recording_${_uuid.v4()}.m4a',
    );
    await _activeRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: target,
    );
  }

  Future<bool> _requestPermission() async {
    try {
      if (Platform.isAndroid) {
        return await _microphoneChannel.invokeMethod<bool>(
              'requestPermission',
            ) ??
            false;
      }
      return _activeRecorder.hasPermission();
    } on PlatformException catch (error) {
      throw AppFailure(
        AppFailureCode.microphoneDenied,
        debugContext: error.code,
      );
    }
  }

  Future<void> pause() => _activeRecorder.pause();
  Future<void> resume() => _activeRecorder.resume();
  Future<String?> stop() => _activeRecorder.stop();
  Future<void> cancel() => _activeRecorder.cancel();

  Future<void> dispose() async {
    await _recorder?.dispose();
    _recorder = null;
  }

  Future<int> sizeOf(String filePath) => File(filePath).length();
}
