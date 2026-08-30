import 'dart:async';

import 'package:damanak/data/demo_repository.dart';
import 'package:damanak/models/store_billing.dart';
import 'package:damanak/services/store_billing_service.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

void main() {
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

    test('يحوّل استجابة اشتراكات Google دون طلب منتجات عادية', () {
      const productId = 'com.damanak.subscription.starter';
      final response = googleSubscriptionProductResponse(
        productIds: const {productId},
        response: const ProductDetailsResponseWrapper(
          billingResult: BillingResultWrapper(responseCode: BillingResponse.ok),
          productDetailsList: [
            ProductDetailsWrapper(
              description: 'الخطة الشهرية',
              name: 'بداية',
              productId: productId,
              productType: ProductType.subs,
              title: 'خطة بداية',
              subscriptionOfferDetails: [
                SubscriptionOfferDetailsWrapper(
                  basePlanId: 'monthly',
                  offerTags: [],
                  offerIdToken: 'monthly-token',
                  pricingPhases: [
                    PricingPhaseWrapper(
                      billingCycleCount: 0,
                      billingPeriod: 'P1M',
                      formattedPrice: '39.99 ر.ق',
                      priceAmountMicros: 39990000,
                      priceCurrencyCode: 'QAR',
                      recurrenceMode: RecurrenceMode.infiniteRecurring,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      expect(response.error, isNull);
      expect(response.notFoundIDs, isEmpty);
      expect(response.productDetails.single.id, productId);
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
        productDetails: DamanakStoreCatalog.appleProductIds
            .map(_appleProduct)
            .toList(growable: false),
        notFoundIDs: const [],
      );

      final response = await queryAppleStoreProducts(
        productIds: DamanakStoreCatalog.appleProductIds,
        storeKit2Query: (_) => Completer<ProductDetailsResponse>().future,
        storeKit1Query: (_) async {
          fallbackCalls += 1;
          return fallbackResponse;
        },
        timeout: const Duration(milliseconds: 50),
      );

      expect(response.productDetails, hasLength(6));
      expect(response.notFoundIDs, isEmpty);
      expect(fallbackCalls, 1);
    });

    test('يمزج استجابة StoreKit 2 الجزئية مع StoreKit 1', () async {
      final sortedIds = DamanakStoreCatalog.appleProductIds.toList()..sort();
      final primaryId = sortedIds.first;
      final fallbackRequests = <Set<String>>[];

      final response = await queryAppleStoreProducts(
        productIds: DamanakStoreCatalog.appleProductIds,
        storeKit2Query: (ids) async => ProductDetailsResponse(
          productDetails: [_appleProduct(primaryId)],
          notFoundIDs: ids.difference({primaryId}).toList(),
        ),
        storeKit1Query: (ids) async {
          fallbackRequests.add(ids);
          return ProductDetailsResponse(
            productDetails: ids.map(_appleProduct).toList(growable: false),
            notFoundIDs: const [],
          );
        },
        timeout: const Duration(milliseconds: 100),
      );

      expect(response.productDetails, hasLength(6));
      expect(response.notFoundIDs, isEmpty);
      expect(fallbackRequests, hasLength(1));
      expect(fallbackRequests.single, isNot(contains(primaryId)));
    });

    test('يستخدم طلب StoreKit 1 واحداً عند رجوع StoreKit 2 فارغاً', () async {
      final requestedBatches = <Set<String>>[];
      final starterMonthly = DamanakStoreCatalog.appleProductId(
        'starter',
        BillingCycle.monthly,
      );
      final response = await queryAppleStoreProducts(
        productIds: DamanakStoreCatalog.appleProductIds,
        storeKit2Query: (ids) async => ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: ids.toList(growable: false),
        ),
        storeKit1Query: (ids) async {
          requestedBatches.add(ids);
          final products = ids.contains(starterMonthly)
              ? [
                  ProductDetails(
                    id: starterMonthly,
                    title: 'البداية',
                    description: 'الخطة الشهرية',
                    price: '39.00 QAR',
                    rawPrice: 39,
                    currencyCode: 'QAR',
                  ),
                ]
              : <ProductDetails>[];
          return ProductDetailsResponse(
            productDetails: products,
            notFoundIDs: ids.difference({starterMonthly}).toList(),
          );
        },
        timeout: const Duration(milliseconds: 50),
      );

      expect(requestedBatches, hasLength(1));
      expect(requestedBatches.first, DamanakStoreCatalog.appleProductIds);
      expect(response.productDetails.single.id, starterMonthly);
      expect(response.notFoundIDs, hasLength(5));
    });

    test('لا يعرض storekit_no_response بدل تشخيص الكتالوج الفارغ', () async {
      final response = await queryAppleStoreProducts(
        productIds: DamanakStoreCatalog.appleProductIds,
        storeKit2Query: (ids) async => ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: ids.toList(growable: false),
          error: IAPError(
            source: 'app_store',
            code: 'storekit_no_response',
            message: 'No products returned.',
          ),
        ),
        storeKit1Query: (ids) async => ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: ids.toList(growable: false),
        ),
        timeout: const Duration(milliseconds: 100),
      );

      expect(response.productDetails, isEmpty);
      expect(response.notFoundIDs, hasLength(6));
      expect(response.error, isNull);
    });

    test('يوضح متجر Apple الفعلي عند غياب المنتجات', () {
      expect(
        appleCatalogUnavailableMessage('USA'),
        allOf(contains('USA'), contains('دول الخليج')),
      );
      expect(
        appleCatalogUnavailableMessage('QAT'),
        contains('APPLE-CATALOG-0-QAT'),
      );
      expect(
        appleCatalogUnavailableMessage(null),
        contains('APPLE-STOREFRONT-UNKNOWN'),
      );
    });

    test('يلتزم استعلام Apple بمهلة إجمالية واحدة', () async {
      final stopwatch = Stopwatch()..start();

      await expectLater(
        queryAppleStoreProducts(
          productIds: DamanakStoreCatalog.appleProductIds,
          storeKit2Query: (_) => Completer<ProductDetailsResponse>().future,
          storeKit1Query: (_) => Completer<ProductDetailsResponse>().future,
          timeout: const Duration(milliseconds: 30),
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 200)));
    });

    test('لا يحجب تعليق سجل مشتريات Google بقية الكتالوج', () async {
      final stopwatch = Stopwatch()..start();
      final result = await waitForOptionalStoreResult<int>(
        query: () => Completer<int>().future,
        timeout: const Duration(milliseconds: 5),
      );

      expect(result, isNull);
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 100)));
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

    test('تنتهي الاستعادة بلا مشتريات من دون إبقاء التحميل', () async {
      final billing = _ControlledStoreBillingService();
      final controller = AppController.withRepository(
        _CloudLikeDemoRepository(),
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await controller.restoreStorePurchases();

      expect(controller.storeBillingState, StoreBillingState.ready);
      expect(controller.noticeMessage, contains('لاستعادة'));
    });

    test('يعيد مراقب الشراء الواجهة إذا لم يصل أي حدث', () async {
      final billing = _ControlledStoreBillingService();
      final controller = AppController.withRepository(
        _CloudLikeDemoRepository(),
        billingService: billing,
        purchaseEventTimeout: const Duration(milliseconds: 5),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await controller.purchaseSubscription(controller.storeOffers.single);
      expect(controller.storeBillingState, StoreBillingState.purchasing);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.storeBillingState, StoreBillingState.ready);
      expect(controller.storeBillingMessage, contains('لم يصل تأكيد'));
    });

    test('لا يلغي مراقب الشراء حالة الدفعة المعلقة', () async {
      final billing = _ControlledStoreBillingService(emitPending: true);
      final controller = AppController.withRepository(
        _CloudLikeDemoRepository(),
        billingService: billing,
        purchaseEventTimeout: const Duration(milliseconds: 5),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await controller.purchaseSubscription(controller.storeOffers.single);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.storeBillingState, StoreBillingState.pending);
      expect(controller.storeBillingMessage, contains('معلّقة'));
    });
  });
}

ProductDetails _appleProduct(String id) => ProductDetails(
  id: id,
  title: 'خطة ضمانك',
  description: 'اشتراك ضمانك',
  price: '39.99 QAR',
  rawPrice: 39.99,
  currencyCode: 'QAR',
);

const _testOffer = StoreProductOffer(
  key: 'starter:monthly',
  planId: 'starter',
  cycle: BillingCycle.monthly,
  productId: 'com.damanak.subscription.starter.monthly',
  title: 'بداية',
  description: 'الخطة الشهرية',
  localizedPrice: '39.99 QAR',
  rawPrice: 39.99,
  currencyCode: 'QAR',
);

class _CloudLikeDemoRepository extends DemoDamanakRepository {
  @override
  bool get isDemo => false;
}

class _ControlledStoreBillingService implements StoreBillingService {
  _ControlledStoreBillingService({this.emitPending = false});

  final bool emitPending;
  final StreamController<List<StorePurchaseEvent>> _updates =
      StreamController<List<StorePurchaseEvent>>.broadcast();

  @override
  Stream<List<StorePurchaseEvent>> get purchaseUpdates => _updates.stream;

  @override
  Future<StoreProductLoadResult> loadProducts() async =>
      const StoreProductLoadResult(
        available: true,
        platform: StoreBillingPlatform.appStore,
        offers: [_testOffer],
      );

  @override
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
  }) async {
    if (!emitPending) return;
    scheduleMicrotask(() {
      _updates.add([
        const StorePurchaseEvent(
          key: 'pending-test',
          status: StorePurchaseStatus.pending,
          platform: StoreBillingPlatform.appStore,
          productId: 'com.damanak.subscription.starter.monthly',
          verificationData: '',
          verificationSource: 'app_store',
          needsCompletion: false,
        ),
      ]);
    });
  }

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> completePurchase(StorePurchaseEvent event) async {}

  @override
  Future<bool> openSubscriptionManagement() async => false;

  @override
  Future<void> dispose() => _updates.close();
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
