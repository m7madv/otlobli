import 'package:flutter/services.dart';

enum ReminderSound {
  gentle('gentle'),
  bright('bright'),
  classic('classic');

  const ReminderSound(this.key);

  final String key;

  static ReminderSound fromKey(String? key) => values.firstWhere(
    (sound) => sound.key == key,
    orElse: () => ReminderSound.classic,
  );
}

class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
    required this.sound,
    required this.state,
  });

  final String id;
  final String title;
  final String body;
  final DateTime fireAt;
  final ReminderSound sound;
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
      sound: ReminderSound.fromKey(map['soundKey'] as String?),
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
    required ReminderSound sound,
  }) async {
    final arguments = <String, Object>{
      'identifier': identifier,
      'title': title,
      'body': body,
      'fireMillis': fireAt.millisecondsSinceEpoch,
      'soundKey': sound.key,
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
        sound: sound,
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

  static Future<bool> preview(ReminderSound sound) async {
    return await _channel.invokeMethod<bool>('previewSound', {
          'soundKey': sound.key,
        }) ??
        false;
  }
}
