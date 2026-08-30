import 'package:flutter/services.dart';

abstract final class ReminderLauncher {
  static const _channel = MethodChannel('voicebrief/reminders');

  static Future<bool> schedule({
    required String identifier,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    return await _channel.invokeMethod<bool>('schedule', {
          'identifier': identifier,
          'title': title,
          'body': body,
          'fireMillis': fireAt.millisecondsSinceEpoch,
        }) ??
        false;
  }
}
