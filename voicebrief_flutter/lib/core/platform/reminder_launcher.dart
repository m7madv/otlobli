import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class ReminderTone {
  const ReminderTone.system()
    : key = 'system',
      fileName = null,
      displayName = null;

  const ReminderTone.custom({required this.fileName, required this.displayName})
    : key = 'custom';

  final String key;
  final String? fileName;
  final String? displayName;

  bool get isCustom => key == 'custom' && fileName != null;

  Map<String, Object> get arguments => <String, Object>{
    'soundKey': key,
    'soundFileName': ?fileName,
    'soundDisplayName': ?displayName,
  };

  factory ReminderTone.fromMap(Map<Object?, Object?> map) {
    final key = map['soundKey'] as String?;
    final fileName = map['soundFileName'] as String?;
    if (key == 'custom' && fileName != null && fileName.isNotEmpty) {
      final suppliedName = (map['soundDisplayName'] as String?)?.trim();
      return ReminderTone.custom(
        fileName: fileName,
        displayName: suppliedName?.isNotEmpty == true
            ? suppliedName!
            : 'Custom sound',
      );
    }
    // Builds 14 and earlier used the system sound. Builds 15's three bundled
    // tone keys intentionally fall back to that original system sound.
    return const ReminderTone.system();
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderTone &&
      other.key == key &&
      other.fileName == fileName &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(key, fileName, displayName);
}

class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
    required this.tone,
    required this.state,
  });

  final String id;
  final String title;
  final String body;
  final DateTime fireAt;
  final ReminderTone tone;
  final String state;

  factory ScheduledReminder.fromMap(Map<Object?, Object?> map) {
    final fireMillis = map['fireMillis'] as num?;
    if (fireMillis == null) {
      throw const FormatException('Missing reminder fire time');
    }
    return ScheduledReminder(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'VoiceBrief',
      body: map['body'] as String? ?? '',
      fireAt: DateTime.fromMillisecondsSinceEpoch(fireMillis.toInt()),
      tone: ReminderTone.fromMap(map),
      state: map['state'] as String? ?? 'scheduled',
    );
  }
}

abstract final class ReminderLauncher {
  static const _channel = MethodChannel('voicebrief/reminders');

  static Future<ScheduledReminder?> schedule({
    required String identifier,
    required String title,
    required String body,
    required DateTime fireAt,
    required ReminderTone tone,
  }) async {
    final arguments = <String, Object>{
      'identifier': identifier,
      'title': title,
      'body': body,
      'fireMillis': fireAt.millisecondsSinceEpoch,
      ...tone.arguments,
    };
    final value = await _channel.invokeMethod<Object?>('schedule', arguments);
    if (value is Map) {
      return ScheduledReminder.fromMap(Map<Object?, Object?>.from(value));
    }
    // Android delegates to the installed clock app and returns only success.
    if (value == true) {
      return ScheduledReminder(
        id: identifier,
        title: title,
        body: body,
        fireAt: fireAt,
        tone: tone,
        state: 'scheduled',
      );
    }
    return null;
  }

  static Future<List<ScheduledReminder>> scheduled() async {
    final values = await _channel.invokeListMethod<Object?>('list');
    if (values == null) return const [];
    return values
        .whereType<Map>()
        .map(
          (value) =>
              ScheduledReminder.fromMap(Map<Object?, Object?>.from(value)),
        )
        .toList(growable: false)
      ..sort((a, b) => a.fireAt.compareTo(b.fireAt));
  }

  static Future<bool> cancel(String id) async {
    return await _channel.invokeMethod<bool>('cancel', {'id': id}) ?? false;
  }

  static Future<bool> preview(ReminderTone tone) async {
    if (!tone.isCustom) return false;
    return await _channel.invokeMethod<bool>('previewSound', tone.arguments) ??
        false;
  }

  static Future<ReminderTone> preferredTone() async {
    final value = await _channel.invokeMapMethod<Object?, Object?>(
      'getPreferredTone',
    );
    return value == null
        ? const ReminderTone.system()
        : ReminderTone.fromMap(value);
  }

  static Future<bool> setPreferredTone(ReminderTone tone) async {
    return await _channel.invokeMethod<bool>(
          'setPreferredTone',
          tone.arguments,
        ) ??
        false;
  }

  static Future<ReminderTone?> importTone({
    required String sourcePath,
    required String displayName,
  }) async {
    final value = await _channel.invokeMapMethod<Object?, Object?>(
      'importSound',
      {'sourcePath': sourcePath, 'displayName': displayName},
    );
    return value == null ? null : ReminderTone.fromMap(value);
  }
}
