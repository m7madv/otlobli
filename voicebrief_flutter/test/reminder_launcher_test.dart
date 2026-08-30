import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/core/platform/reminder_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('voicebrief/reminders');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('schedules a reminder through the native bridge', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return true;
        });
    final fireAt = DateTime(2026, 9, 5, 17);

    final scheduled = await ReminderLauncher.schedule(
      identifier: 'brief-1',
      title: 'تذكير: موعد التصوير',
      body: 'من VoiceBrief: «يوم خمسة تسعة»',
      fireAt: fireAt,
    );

    expect(scheduled, isTrue);
    expect(received?.method, 'schedule');
    expect(received?.arguments, {
      'identifier': 'brief-1',
      'title': 'تذكير: موعد التصوير',
      'body': 'من VoiceBrief: «يوم خمسة تسعة»',
      'fireMillis': fireAt.millisecondsSinceEpoch,
    });
  });
}
