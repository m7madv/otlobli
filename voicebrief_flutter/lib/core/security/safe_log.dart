import 'package:flutter/foundation.dart';

/// Minimal diagnostic logger. Never pass transcript text, audio paths, email
/// addresses, tokens, or raw server responses to this API.
abstract final class SafeLog {
  static void event(String name, {Map<String, Object?> metadata = const {}}) {
    if (!kDebugMode) return;
    final sanitized = <String, Object?>{
      for (final entry in metadata.entries)
        if (_allowedKeys.contains(entry.key)) entry.key: entry.value,
    };
    debugPrint('[VoiceBrief] $name $sanitized');
  }

  static const _allowedKeys = {
    'code',
    'durationSeconds',
    'fileBytes',
    'jobId',
    'route',
    'stage',
  };
}
