import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/audio_import/data/audio_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('voicebrief/share');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'processed share result is emitted without importing audio again',
    () async {
      final payload = <String, Object?>{
        'kind': 'processed',
        'openResult': true,
        'result': <String, Object?>{
          'id': '3a7ee21d-fbc0-4a2d-9d44-4c117e6b5857',
          'detectedLanguage': 'ar',
          'title': 'موعد التصوير',
          'transcript': 'موعدنا غدًا.',
          'summary': 'موعد مستقل للغد.',
          'keyPoints': <Object?>[],
          'actionItems': <Object?>[],
          'importantDates': <Object?>[
            <String, Object?>{
              'label': 'موعد التصوير',
              'dateIso': '2026-08-31',
              'originalPhrase': 'غدًا الساعة خمسة',
              'confidence': 0.93,
              'requiresConfirmation': true,
            },
          ],
          'suggestedReplies': <String, Object?>{
            'short': 'تمام.',
            'friendly': '',
            'professional': '',
          },
          'audioDurationSeconds': 12,
          'processedAt': '2026-08-30T00:00:00.000Z',
          'savedLocally': false,
        },
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'takePendingShare');
            return payload;
          });

      final inbox = SharedAudioInbox();
      addTearDown(inbox.dispose);
      final resultFuture = inbox.processed.first;

      expect(await inbox.takePending(), isNull);
      final event = await resultFuture;
      expect(event.openResult, isTrue);
      expect(event.result.title, 'موعد التصوير');
      expect(event.result.audioDurationSeconds, 12);
      expect(event.result.importantDates.single.dateIso, '2026-08-31');
      expect(
        event.result.importantDates.single.originalPhrase,
        'غدًا الساعة خمسة',
      );
    },
  );
}
