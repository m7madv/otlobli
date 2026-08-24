import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';

import 'helpers/test_harness.dart';

void main() {
  test('strict result models round-trip through JSON', () {
    final original = sampleResult();
    final decoded = BriefResult.fromJson(original.toJson());
    expect(decoded, original);
    expect(decoded.importantDates.single.requiresConfirmation, isTrue);
    expect(decoded.actionItems.single.confidence, closeTo(0.82, 0.001));
  });
}
