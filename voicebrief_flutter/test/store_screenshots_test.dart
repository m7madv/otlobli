@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/home/presentation/shell_screen.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';
import 'package:voicebrief/features/transcription/presentation/result_screen.dart';
import 'package:voicebrief/l10n/app_localizations.dart';

import 'helpers/test_harness.dart';

// Opt-in asset renderer, never contacts a backend and never runs in normal CI.
// Renders production Flutter screens with disclosed fictional sample content.
void main() {
  if (!const bool.fromEnvironment('GENERATE_STORE_SCREENSHOTS')) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  final sample =
      jsonDecode(
            File(
              'store_assets/localized/sample_content.json',
            ).readAsStringSync(),
          )
          as Map;
  setUpAll(() async {
    await loadTestFonts();
    final windows = Platform.environment['WINDIR'];
    if (windows == null) {
      throw StateError(
        'This renderer needs the documented Windows system fonts.',
      );
    }
    for (final entry in {
      'StoreIndic': 'Nirmala.ttc',
      'StoreChinese': 'msyh.ttc',
    }.entries) {
      final bytes = await File('$windows/Fonts/${entry.value}').readAsBytes();
      await (FontLoader(
        entry.key,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });

  for (final locale in AppLocalizations.supportedLocales) {
    for (final tablet in [false, true]) {
      for (var page = 0; page < 4; page++) {
        testWidgets(
          '${locale.languageCode} ${tablet ? 'ipad' : 'iphone'} ${page + 1}',
          (tester) async {
            debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
            addTearDown(() => debugDefaultTargetPlatformOverride = null);
            final canvas = tablet
                ? const Size(1032, 1376)
                : const Size(428, 926);
            await tester.binding.setSurfaceSize(canvas);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final code = locale.languageCode;
            final text = (sample[code] as List).cast<String>();
            final controller = createTestController(pro: true);
            await controller.signInWithProvider(IdentityProvider.google);
            final result = sampleResult().copyWith(
              detectedLanguage: code,
              title: text[0],
              transcript: text[1],
              summary: text[1],
              keyPoints: [text[2]],
              actionItems: [],
              importantDates: [
                BriefImportantDate(
                  label: text[0],
                  dateIso: '2026-09-08T17:00:00+03:00',
                  originalPhrase: text[3],
                  confidence: 0.95,
                  requiresConfirmation: false,
                ),
              ],
              suggestedReplies: SuggestedReplies(
                short: text[4],
                friendly: '',
                professional: '',
              ),
              processedAt: DateTime.utc(2026, 9, 7, 10),
            );
            controller.openResult(result);
            await controller.saveActiveResult();
            if (page == 3) controller.setNavigationIndex(1);
            final font = switch (code) {
              'ar' || 'ur' => 'Arial',
              'bn' || 'hi' => 'StoreIndic',
              'zh' => 'StoreChinese',
              _ => 'Roboto',
            };
            const boundaryKey = ValueKey('store-canvas');
            await tester.pumpWidget(
              RepaintBoundary(
                key: boundaryKey,
                child: testApp(
                  controller: controller,
                  home: page == 0 || page == 3
                      ? const ShellScreen()
                      : const ResultScreen(),
                  locale: locale,
                  fontFamily: font,
                  frameBuilder: (context, child) =>
                      _StoreFrame(tablet: tablet, page: page, child: child),
                ),
              ),
            );
            await tester.pumpAndSettle();
            if (page == 2) {
              final strings = await AppLocalizations.delegate.load(locale);
              await tester.ensureVisible(find.text(strings.importantDates));
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull);
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(boundaryKey),
            );
            final directory =
                'store_assets/localized/$code/${tablet ? 'ipad' : 'iphone'}';
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: tablet ? 2 : 3);
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              await Directory(directory).create(recursive: true);
              await File(
                '$directory/0${page + 1}_${['home', 'brief', 'dates', 'history'][page]}.png',
              ).writeAsBytes(png!.buffer.asUint8List());
            });
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            debugDefaultTargetPlatformOverride = null;
          },
        );
      }
    }
  }
}

class _StoreFrame extends StatelessWidget {
  const _StoreFrame({
    required this.tablet,
    required this.page,
    required this.child,
  });
  final bool tablet;
  final int page;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = [
      l.homeHeadline,
      l.summaryAndKeyPoints,
      l.actionItemsAndDates,
      l.historyLocalOnly,
    ][page];
    final supporting = [
      l.homeSupporting,
      l.fullTranscript,
      l.needsConfirmation,
      l.searchBriefs,
    ][page];
    final inner = tablet ? const Size(820, 1050) : const Size(360, 706);
    return Material(
      color: const Color(0xFFF3F6FC),
      child: Column(
        children: [
          SizedBox(height: tablet ? 42 : 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.graphic_eq, color: Color(0xFF007AFF), size: 22),
              const SizedBox(width: 8),
              Text(
                'VoiceBrief',
                style: TextStyle(
                  fontSize: tablet ? 25 : 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF007AFF),
                ),
              ),
            ],
          ),
          SizedBox(height: tablet ? 22 : 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tablet ? 95 : 25),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: tablet ? 42 : 27,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tablet ? 100 : 28),
            child: Text(
              supporting,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: tablet ? 21 : 13,
                height: 1.4,
                color: const Color(0xFF536174),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                tablet ? 72 : 24,
                0,
                tablet ? 72 : 24,
                tablet ? 36 : 20,
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: Container(
                  width: inner.width + 12,
                  height: inner.height + 12,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF172234),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: inner,
                        padding: EdgeInsets.zero,
                        viewPadding: EdgeInsets.zero,
                        viewInsets: EdgeInsets.zero,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
