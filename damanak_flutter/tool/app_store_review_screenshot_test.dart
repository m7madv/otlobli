import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_codec;

import 'package:damanak/core/app_theme.dart';
import 'package:damanak/models/store_billing.dart';
import 'package:damanak/screens/subscription_screen.dart';
import 'package:damanak/services/store_billing_service.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:damanak/state/app_scope.dart';

void main() {
  setUpAll(() async {
    await Future.wait([
      _loadFont('ReviewArabic', 'C:/Windows/Fonts/segoeui.ttf'),
      _loadFont('MaterialIcons', _materialIconsPath()),
    ]);
  });

  testWidgets('renders the App Store subscription review screenshot', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _ReviewController(_ReviewBillingService());
    await controller.startDemo();
    await controller.refreshStoreProducts();
    addTearDown(controller.dispose);

    final screenshotKey = GlobalKey();
    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: _reviewTheme(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: RepaintBoundary(
              key: screenshotKey,
              child: const SubscriptionScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    final boundary =
        screenshotKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    expect(image.width, 1024);
    expect(image.height, 768);

    await tester.runAsync(() async {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final decoded = image_codec.decodePng(bytes!.buffer.asUint8List())!;
      final output = File('app_store_assets/subscription-review-1024x768.jpg');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(
        image_codec.encodeJpg(decoded, quality: 95),
        flush: true,
      );
    });
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

ThemeData _reviewTheme() {
  final theme = buildAppTheme();
  final textTheme = theme.textTheme.apply(fontFamily: 'ReviewArabic');
  final buttonTextStyle = WidgetStatePropertyAll<TextStyle?>(
    textTheme.labelLarge,
  );
  return theme.copyWith(
    textTheme: textTheme,
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'ReviewArabic'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'ReviewArabic',
      ),
      toolbarTextStyle: theme.appBarTheme.toolbarTextStyle?.copyWith(
        fontFamily: 'ReviewArabic',
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
  );
}

class _ReviewController extends AppController {
  _ReviewController(StoreBillingService billingService)
    : super.unconfigured(billingService: billingService);

  @override
  bool get isDemo => false;
}

class _ReviewBillingService implements StoreBillingService {
  static const _prices = <String, double>{
    'starter:monthly': 39,
    'starter:yearly': 390,
    'growth:monthly': 99,
    'growth:yearly': 990,
    'scale:monthly': 199,
    'scale:yearly': 1989.99,
  };

  @override
  Stream<List<StorePurchaseEvent>> get purchaseUpdates => const Stream.empty();

  @override
  Future<StoreProductLoadResult> loadProducts() async {
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
        localizedPrice: '${entry.value.toStringAsFixed(2)} ر.س',
        rawPrice: entry.value,
        currencyCode: 'SAR',
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
  }) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> completePurchase(StorePurchaseEvent event) async {}

  @override
  Future<bool> openSubscriptionManagement() async => true;

  @override
  Future<void> dispose() async {}
}
