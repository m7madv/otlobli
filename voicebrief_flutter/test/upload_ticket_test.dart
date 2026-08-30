import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/transcription/data/upload_ticket.dart';

void main() {
  const path =
      '22222222-2222-4222-8222-222222222222/'
      '33333333-3333-4333-8333-333333333333/input.m4a';

  test('requires a token when the audio still needs upload', () {
    final ticket = AudioUploadTicket.fromJson({
      'storagePath': path,
      'uploadToken': 'signed-token',
      'uploadedAlready': false,
    }, expectedStoragePath: path);

    expect(ticket.uploadedAlready, isFalse);
    expect(ticket.uploadToken, 'signed-token');
  });

  test('allows a missing token only for a verified existing upload', () {
    final ticket = AudioUploadTicket.fromJson({
      'storagePath': path,
      'uploadedAlready': true,
    }, expectedStoragePath: path);

    expect(ticket.uploadedAlready, isTrue);
    expect(ticket.uploadToken, isEmpty);
  });

  test('rejects a different path and a missing required token', () {
    expect(
      () => AudioUploadTicket.fromJson({
        'storagePath': '$path.other',
        'uploadedAlready': true,
      }, expectedStoragePath: path),
      throwsFormatException,
    );
    expect(
      () => AudioUploadTicket.fromJson({
        'storagePath': path,
        'uploadedAlready': false,
      }, expectedStoragePath: path),
      throwsFormatException,
    );
  });
}
