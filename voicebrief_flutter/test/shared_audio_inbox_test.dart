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
        'result': <String, Object?>{
          'id': '3a7ee21d-fbc0-4a2d-9d44-4c117e6b5857',
          'detectedLanguage': 'ar',
          'title': 'موعد التصوير',
          'transcript': 'موعدنا غدًا.',
          'summary': 'موعد مستقل للغد.',
          'keyPoints': <Object?>[],
          'actionItems': <Object?>[],
          'importantDates': <Object?>[],
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
      final result = await resultFuture;
      expect(result.title, 'موعد التصوير');
      expect(result.audioDurationSeconds, 12);
    },
  );
}
