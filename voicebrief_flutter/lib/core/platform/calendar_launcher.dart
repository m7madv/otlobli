import 'package:flutter/services.dart';

abstract final class CalendarLauncher {
  static const _channel = MethodChannel('voicebrief/calendar');

  static Future<bool> openEvent({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
  }) async {
    return await _channel.invokeMethod<bool>('openEvent', {
          'title': title,
          'description': description,
          'startMillis': start.millisecondsSinceEpoch,
          'endMillis': end.millisecondsSinceEpoch,
        }) ??
        false;
  }
}
