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
          return {
            'id': 'alarm-1',
            'title': 'تذكير: موعد التصوير',
            'body': 'من VoiceBrief: «يوم خمسة تسعة»',
            'fireMillis': DateTime(2026, 9, 5, 17).millisecondsSinceEpoch,
            'soundKey': 'custom',
            'soundFileName': 'voicebrief_custom_sample.caf',
            'soundDisplayName': 'موعد التصوير.caf',
            'state': 'scheduled',
          };
        });
    final fireAt = DateTime(2026, 9, 5, 17);
    const tone = ReminderTone.custom(
      fileName: 'voicebrief_custom_sample.caf',
      displayName: 'موعد التصوير.caf',
    );

    final scheduled = await ReminderLauncher.schedule(
      identifier: 'brief-1',
      title: 'تذكير: موعد التصوير',
      body: 'من VoiceBrief: «يوم خمسة تسعة»',
      fireAt: fireAt,
      tone: tone,
    );

    expect(scheduled?.id, 'alarm-1');
    expect(scheduled?.tone, tone);
    expect(received?.method, 'schedule');
    expect(received?.arguments, {
      'identifier': 'brief-1',
      'title': 'تذكير: موعد التصوير',
      'body': 'من VoiceBrief: «يوم خمسة تسعة»',
      'fireMillis': fireAt.millisecondsSinceEpoch,
      'soundKey': 'custom',
      'soundFileName': 'voicebrief_custom_sample.caf',
      'soundDisplayName': 'موعد التصوير.caf',
    });
  });

  test('lists and cancels app-owned alarms', () async {
    final fireAt = DateTime(2026, 9, 6, 8, 30);
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'list') {
            return [
              {
                'id': 'alarm-2',
                'title': 'موعد صباحي',
                'body': '',
                'fireMillis': fireAt.millisecondsSinceEpoch,
                'soundKey': 'gentle',
                'state': 'scheduled',
              },
            ];
          }
          if (call.method == 'cancel') return true;
          return false;
        });

    final reminders = await ReminderLauncher.scheduled();
    final cancelled = await ReminderLauncher.cancel('alarm-2');

    expect(reminders.single.fireAt, fireAt);
    expect(reminders.single.tone, const ReminderTone.system());
    expect(cancelled, isTrue);
    expect(calls.map((call) => call.method), ['list', 'cancel']);
  });

  test('imports and persists a custom alarm sound', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getPreferredTone') {
            return {'soundKey': 'system'};
          }
          if (call.method == 'importSound') {
            return {
              'soundKey': 'custom',
              'soundFileName': 'voicebrief_custom_imported.caf',
              'soundDisplayName': 'من فيديو.mov',
            };
          }
          if (call.method == 'setPreferredTone') return true;
          return false;
        });

    expect(await ReminderLauncher.preferredTone(), const ReminderTone.system());
    final imported = await ReminderLauncher.importTone(
      sourcePath: '/tmp/source.mov',
      displayName: 'من فيديو.mov',
    );
    expect(imported?.isCustom, isTrue);
    expect(imported?.displayName, 'من فيديو.mov');
    expect(await ReminderLauncher.setPreferredTone(imported!), isTrue);
    expect(calls.map((call) => call.method), [
      'getPreferredTone',
      'importSound',
      'setPreferredTone',
    ]);
  });
}
