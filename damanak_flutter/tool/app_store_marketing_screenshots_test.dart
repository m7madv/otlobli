import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:damanak/core/app_theme.dart';
import 'package:damanak/models/store_billing.dart';
import 'package:damanak/screens/requests_screen.dart';
import 'package:damanak/screens/shell_screen.dart';
import 'package:damanak/screens/subscription_screen.dart';
import 'package:damanak/screens/team_screen.dart';
import 'package:damanak/screens/warranty_form_screen.dart';
import 'package:damanak/services/store_billing_service.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:damanak/state/app_scope.dart';
import 'package:damanak/widgets/brand_mark.dart';

const _outputRoot = 'app_store_assets/ios';

void main() {
  setUpAll(() async {
    await Future.wait([
      _loadFont('StoreArabic', 'C:/Windows/Fonts/segoeui.ttf'),
      _loadFont('MaterialIcons', _materialIconsPath()),
    ]);
  });

  for (final shot in _shots) {
    testWidgets('generates ${shot.slug} App Store screenshots', (tester) async {
      await _renderShot(tester, shot, _CanvasKind.iPhone);
      await _renderShot(tester, shot, _CanvasKind.iPad);
    });
  }
}

const _shots = <_ShotSpec>[
  _ShotSpec(
    order: '01',
    slug: 'issue-warranty',
    title: 'إصدار ضمان',
    subtitle: 'ابدأ بالمنتج والعميل، ثم أصدر الضمان في مسار واضح.',
    screen: _ScreenKind.home,
  ),
  _ShotSpec(
    order: '02',
    slug: 'scan-barcode-serial',
    title: 'مسح باركود أو تسلسلي',
    subtitle: 'امسحه بالكاميرا أو أدخله يدويًا عند الحاجة.',
    screen: _ScreenKind.warrantyForm,
  ),
  _ShotSpec(
    order: '03',
    slug: 'track-claims',
    title: 'متابعة المطالبات',
    subtitle: 'راجع الحالة وحدد المسؤول والإجراء التالي.',
    screen: _ScreenKind.claims,
  ),
  _ShotSpec(
    order: '04',
    slug: 'invite-team',
    title: 'دعوة الفريق',
    subtitle: 'رابط واحد وصلاحيات واضحة لكل عضو.',
    screen: _ScreenKind.teamInvite,
  ),
  _ShotSpec(
    order: '05',
    slug: 'manage-subscription',
    title: 'إدارة الاشتراك',
    subtitle: 'خطط واضحة وأسعار مباشرة من متجر جهازك.',
    screen: _ScreenKind.subscription,
  ),
];

Future<void> _renderShot(
  WidgetTester tester,
  _ShotSpec shot,
  _CanvasKind canvas,
) async {
  final metrics = _CanvasMetrics.forKind(canvas);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = metrics.logicalSize;

  final controller = _MarketingController(_MarketingBillingService());
  await controller.startDemo();
  await controller.refreshStoreProducts();

  final screenshotKey = GlobalKey();
  await tester.pumpWidget(
    AppScope(
      controller: controller,
      child: MaterialApp(
        key: ValueKey('${shot.slug}-${canvas.name}'),
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: _marketingTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(
            key: screenshotKey,
            child: _MarketingCanvas(
              metrics: metrics,
              shot: shot,
              child: _screenFor(shot.screen, canvas),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 800));

  if (shot.screen == _ScreenKind.teamInvite) {
    await tester.tap(find.text('دعوة عضو').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء رابط الدعوة').last);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  }

  await tester.pump(const Duration(milliseconds: 250));
  final exception = tester.takeException();
  expect(exception, isNull);

  final outputDirectory = canvas == _CanvasKind.iPhone
      ? '$_outputRoot/iphone-1284x2778'
      : '$_outputRoot/ipad-2048x2732';
  final output = File(
    '$outputDirectory/${shot.order}-${shot.slug}-${metrics.pixelWidth}x${metrics.pixelHeight}.png',
  );
  await _capturePng(
    tester,
    screenshotKey,
    output,
    pixelRatio: metrics.captureScale,
    expectedWidth: metrics.pixelWidth,
    expectedHeight: metrics.pixelHeight,
  );

  controller.dispose();
  tester.view.resetDevicePixelRatio();
  tester.view.resetPhysicalSize();
}

Widget _screenFor(_ScreenKind screen, _CanvasKind canvas) {
  return switch (screen) {
    _ScreenKind.home => const ShellScreen(),
    _ScreenKind.warrantyForm => const WarrantyFormScreen(),
    _ScreenKind.claims => const Scaffold(body: RequestsScreen()),
    _ScreenKind.teamInvite => Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => const TeamScreen()),
    ),
    _ScreenKind.subscription => const SubscriptionScreen(),
  };
}

class _MarketingCanvas extends StatelessWidget {
  const _MarketingCanvas({
    required this.metrics,
    required this.shot,
    required this.child,
  });

  final _CanvasMetrics metrics;
  final _ShotSpec shot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF3F7F5);
    const primary = Color(0xFF08795C);
    const primarySoft = Color(0xFFDDEFE8);
    const label = Color(0xFF10211B);
    const secondaryLabel = Color(0xFF36564B);
    final isPhone = metrics.kind == _CanvasKind.iPhone;

    return Material(
      color: background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: isPhone ? -88 : -180,
            left: isPhone ? -92 : -210,
            child: _SoftCircle(
              size: isPhone ? 240 : 520,
              color: primarySoft.withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            top: isPhone ? 92 : 80,
            right: isPhone ? -108 : -180,
            child: _SoftCircle(
              size: isPhone ? 210 : 420,
              color: const Color(0xFFE7F4EF).withValues(alpha: 0.9),
            ),
          ),
          PositionedDirectional(
            top: isPhone ? 28 : 42,
            start: isPhone ? 34 : 92,
            end: isPhone ? 34 : 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(compact: true),
                SizedBox(height: isPhone ? 12 : 18),
                Text(
                  shot.title,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: label,
                    fontFamily: 'StoreArabic',
                    fontSize: isPhone ? (shot.title.length > 18 ? 30 : 36) : 64,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: isPhone ? 6 : 10),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isPhone ? 350 : 760),
                  child: Text(
                    shot.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: secondaryLabel,
                      fontFamily: 'StoreArabic',
                      fontSize: isPhone ? 15.5 : 28,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                SizedBox(height: isPhone ? 10 : 15),
                Container(
                  width: isPhone ? 54 : 96,
                  height: isPhone ? 5 : 8,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: metrics.previewTop,
            left: metrics.previewHorizontalInset,
            right: metrics.previewHorizontalInset,
            bottom: metrics.previewBottom,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(metrics.previewRadius),
                border: Border.all(
                  color: const Color(0xFFD3DEDA),
                  width: isPhone ? 1.5 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF153F34).withValues(alpha: 0.13),
                    blurRadius: isPhone ? 30 : 52,
                    offset: Offset(0, isPhone ? 12 : 20),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isPhone ? 4 : 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    metrics.previewRadius - (isPhone ? 5 : 7),
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                      viewInsets: EdgeInsets.zero,
                      textScaler: TextScaler.noScaling,
                    ),
                    child: Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
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

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ShotSpec {
  const _ShotSpec({
    required this.order,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.screen,
  });

  final String order;
  final String slug;
  final String title;
  final String subtitle;
  final _ScreenKind screen;
}

enum _ScreenKind { home, warrantyForm, claims, teamInvite, subscription }

enum _CanvasKind { iPhone, iPad }

class _CanvasMetrics {
  const _CanvasMetrics({
    required this.kind,
    required this.logicalSize,
    required this.captureScale,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.previewTop,
    required this.previewBottom,
    required this.previewHorizontalInset,
    required this.previewRadius,
  });

  factory _CanvasMetrics.forKind(_CanvasKind kind) {
    return switch (kind) {
      _CanvasKind.iPhone => const _CanvasMetrics(
        kind: _CanvasKind.iPhone,
        logicalSize: Size(428, 926),
        captureScale: 3,
        pixelWidth: 1284,
        pixelHeight: 2778,
        previewTop: 205,
        previewBottom: 18,
        previewHorizontalInset: 43,
        previewRadius: 38,
      ),
      _CanvasKind.iPad => const _CanvasMetrics(
        kind: _CanvasKind.iPad,
        logicalSize: Size(1024, 1366),
        captureScale: 2,
        pixelWidth: 2048,
        pixelHeight: 2732,
        previewTop: 250,
        previewBottom: 42,
        previewHorizontalInset: 109,
        previewRadius: 48,
      ),
    };
  }

  final _CanvasKind kind;
  final Size logicalSize;
  final double captureScale;
  final int pixelWidth;
  final int pixelHeight;
  final double previewTop;
  final double previewBottom;
  final double previewHorizontalInset;
  final double previewRadius;
}

Future<void> _capturePng(
  WidgetTester tester,
  GlobalKey screenshotKey,
  File output, {
  required double pixelRatio,
  required int expectedWidth,
  required int expectedHeight,
}) async {
  final boundary =
      screenshotKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final rendered = await boundary.toImage(pixelRatio: pixelRatio);
  expect(rendered.width, expectedWidth);
  expect(rendered.height, expectedHeight);

  await tester.runAsync(() async {
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  });
}

Future<void> _loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  await loader.load();
}

String _materialIconsPath() {
  var directory = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 10; depth++) {
    final candidate = File(
      '${directory.path}/bin/cache/artifacts/material_fonts/'
      'materialicons-regular.otf',
    );
    if (candidate.existsSync()) return candidate.path;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Unable to locate the Flutter Material Icons font.');
}

ThemeData _marketingTheme() {
  final theme = buildAppTheme(Brightness.light);
  final textTheme = theme.textTheme.apply(fontFamily: 'StoreArabic');
  final buttonTextStyle = WidgetStatePropertyAll<TextStyle?>(
    textTheme.labelLarge,
  );
  return theme.copyWith(
    textTheme: textTheme,
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'StoreArabic'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'StoreArabic',
      ),
      toolbarTextStyle: theme.appBarTheme.toolbarTextStyle?.copyWith(
        fontFamily: 'StoreArabic',
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style?.copyWith(
        textStyle: buttonTextStyle,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style?.copyWith(
        textStyle: buttonTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: theme.textButtonTheme.style?.copyWith(textStyle: buttonTextStyle),
    ),
    floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
      shape: const StadiumBorder(side: BorderSide.none),
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
    ),
    bottomSheetTheme: theme.bottomSheetTheme.copyWith(
      constraints: const BoxConstraints(maxWidth: double.infinity),
    ),
  );
}

class _MarketingController extends AppController {
  _MarketingController(StoreBillingService billingService)
    : super.unconfigured(billingService: billingService);

  @override
  bool get isDemo => false;
}

class _MarketingBillingService implements StoreBillingService {
  static const _prices = <String, double>{
    'starter:monthly': 39.99,
    'starter:yearly': 399.99,
    'growth:monthly': 79.99,
    'growth:yearly': 799.99,
    'scale:monthly': 199.99,
    'scale:yearly': 1999.99,
  };

  @override
  Stream<List<StorePurchaseEvent>> get purchaseUpdates => const Stream.empty();

  @override
  Future<StoreProductLoadResult> loadProducts({
    required String accountId,
  }) async {
    final offers = _prices.entries.map((entry) {
      final parts = entry.key.split(':');
      final planId = parts.first;
      final cycle = parts.last == 'monthly'
          ? BillingCycle.monthly
          : BillingCycle.yearly;
      return StoreProductOffer(
        key: entry.key,
        planId: planId,
        cycle: cycle,
        productId: DamanakStoreCatalog.appleProductId(planId, cycle),
        title: planId,
        description: '',
        localizedPrice: '${entry.value.toStringAsFixed(2)} ر.ق',
        rawPrice: entry.value,
        currencyCode: 'QAR',
      );
    }).toList();
    return StoreProductLoadResult(
      available: true,
      platform: StoreBillingPlatform.appStore,
      offers: offers,
    );
  }

  @override
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
    required String? currentPlanId,
    required String? currentProductId,
    required String? currentOriginalTransactionId,
    required BillingCycle? currentCycle,
    required bool requireExistingSubscription,
  }) async {}

  @override
  Future<StoreRestoreResult> restorePurchases({
    required String accountId,
    required String storeId,
    String? currentOriginalTransactionId,
    bool recoveryRequested = false,
  }) async => const StoreRestoreResult(
    platform: StoreBillingPlatform.appStore,
    restoredPurchases: 0,
  );

  @override
  Future<void> completePurchase(StorePurchaseEvent event) async {}

  @override
  Future<bool> openSubscriptionManagement(
    StoreBillingPlatform provider, {
    String? productId,
  }) async => true;

  @override
  Future<void> dispose() async {}
}
