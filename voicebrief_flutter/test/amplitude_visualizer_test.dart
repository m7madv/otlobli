import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/recorder/domain/amplitude_visualizer.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';

import 'helpers/test_harness.dart';

void main() {
  test('dBFS levels stay bounded and preserve audible differences', () {
    final silence = AmplitudeVisualizer.levelFromDbfs(-80);
    final speech = AmplitudeVisualizer.levelFromDbfs(-24);
    final loud = AmplitudeVisualizer.levelFromDbfs(-6);

    expect(silence, AmplitudeVisualizer.restingLevel);
    expect(speech, greaterThan(silence));
    expect(loud, greaterThan(speech));
    expect(loud, lessThanOrEqualTo(1));
  });

  test('meter attacks faster than it releases', () {
    final attack = AmplitudeVisualizer.smooth(previous: 0.1, next: 0.9);
    final release = AmplitudeVisualizer.smooth(previous: 0.9, next: 0.1);

    expect(attack - 0.1, greaterThan(0.9 - release));
  });

  testWidgets('waveform repaints for new samples and mirrors in Arabic', (
    tester,
  ) async {
    Future<CustomPainter> pump(List<double> levels) async {
      await tester.pumpWidget(
        testApp(
          controller: createTestController(),
          locale: const Locale('ar'),
          home: Scaffold(
            body: AudioWaveform(levels: levels, activeFraction: 1, live: true),
          ),
        ),
      );
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
      return paint.painter!;
    }

    final first = await pump(const [0.08, 0.2, 0.4]);
    final second = await pump(const [0.2, 0.4, 0.8]);

    expect(second.shouldRepaint(first), isTrue);
    expect(
      Directionality.of(tester.element(find.byType(AudioWaveform))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
