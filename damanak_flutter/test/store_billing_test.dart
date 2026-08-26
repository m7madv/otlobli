import 'dart:async';

import 'package:damanak/models/store_billing.dart';
import 'package:damanak/services/store_billing_service.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  group('تهيئة متجر Apple', () {
    test('يختار StoreKit 1 على iPhone قبل إنشاء عميل الشراء', () async {
      var calls = 0;

      await configureAppleStoreKit(
        isWeb: false,
        platform: TargetPlatform.iOS,
        enableStoreKit1: () async {
          calls += 1;
          return false;
        },
      );

      expect(calls, 1);
    });

    test('لا يغيّر مسار Android أو الويب', () async {
      var calls = 0;
      Future<bool> enableStoreKit1() async {
        calls += 1;
        return false;
      }

      await configureAppleStoreKit(
        isWeb: false,
        platform: TargetPlatform.android,
        enableStoreKit1: enableStoreKit1,
      );
      await configureAppleStoreKit(
        isWeb: true,
        platform: TargetPlatform.iOS,
        enableStoreKit1: enableStoreKit1,
      );

      expect(calls, 0);
    });
  });

  group('كتالوج اشتراكات المتجر', () {
    test('يربط منتجات Apple بالخطة والدورة', () {
      final product = DamanakStoreCatalog.appleProductId(
        'growth',
        BillingCycle.yearly,
      );

      expect(product, 'com.damanak.subscription.growth.yearly');
      expect(DamanakStoreCatalog.planIdFromProduct(product), 'growth');
      expect(
        DamanakStoreCatalog.cycleFromAppleProduct(product),
        BillingCycle.yearly,
      );
    });

    test('يربط خطط Google الأساسية بالدورة', () {
      expect(
        DamanakStoreCatalog.googleProductId('starter'),
        'com.damanak.subscription.starter',
      );
      expect(
        DamanakStoreCatalog.cycleFromGoogleBasePlan('monthly'),
        BillingCycle.monthly,
      );
      expect(
        DamanakStoreCatalog.cycleFromGoogleBasePlan('yearly'),
        BillingCycle.yearly,
      );
    });

    test('يرفض المعرفات والدورات غير المدرجة', () {
      expect(
        DamanakStoreCatalog.planIdFromProduct('com.example.subscription'),
        isNull,
      );
      expect(DamanakStoreCatalog.cycleFromGoogleBasePlan('weekly'), isNull);
    });
  });

  group('جلب أسعار المتجر', () {
    test('ينتقل إلى StoreKit 1 إذا بقي StoreKit 2 معلقاً', () async {
      var fallbackCalls = 0;
      final fallbackResponse = ProductDetailsResponse(
        productDetails: [
          ProductDetails(
            id: 'com.damanak.subscription.starter.monthly',
            title: 'البداية',
            description: 'الخطة الشهرية',
            price: '39.99 QAR',
            rawPrice: 39.99,
            currencyCode: 'QAR',
          ),
        ],
        notFoundIDs: const [],
      );

      final response = await queryAppleStoreProducts(
        productIds: DamanakStoreCatalog.appleProductIds,
        storeKit2Query: (_) => Completer<ProductDetailsResponse>().future,
        storeKit1Query: (_) async {
          fallbackCalls += 1;
          return fallbackResponse;
        },
        timeout: const Duration(milliseconds: 5),
      );

      expect(response, same(fallbackResponse));
      expect(fallbackCalls, 1);
    });

    test('يوقف حالة التحميل المعلقة ويتيح إعادة المحاولة', () async {
      final controller = AppController.unconfigured(
        billingService: _HangingStoreBillingService(),
        storeProductLoadTimeout: const Duration(milliseconds: 5),
      );
      addTearDown(controller.dispose);

      await controller.startDemo();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.storeBillingState, StoreBillingState.unavailable);
      expect(controller.storeBillingMessage, contains('أعد المحاولة'));
    });
  });
}

class _HangingStoreBillingService implements StoreBillingService {
  @override
  Stream<List<StorePurchaseEvent>> get purchaseUpdates => const Stream.empty();

  @override
  Future<StoreProductLoadResult> loadProducts() =>
      Completer<StoreProductLoadResult>().future;

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
  Future<bool> openSubscriptionManagement() async => false;

  @override
  Future<void> dispose() async {}
}
