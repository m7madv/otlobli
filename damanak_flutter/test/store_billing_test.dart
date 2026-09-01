import 'dart:async';

import 'package:damanak/data/demo_repository.dart';
import 'package:damanak/models/store_billing.dart';
import 'package:damanak/services/store_billing_service.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

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

  group('سجل اشتراكات Google', () {
    test('يفلتر بالحساب ويختار أحدث اشتراك مطابق فقط', () {
      final response = _googlePurchasesResponse([
        _googlePurchase(
          productId: 'com.damanak.subscription.starter',
          purchaseTime: 100,
          accountId: 'account-a',
          storeId: 'store-a',
        ),
        _googlePurchase(
          productId: 'com.damanak.subscription.growth',
          purchaseTime: 300,
          accountId: 'account-a',
          storeId: 'store-a',
        ),
        _googlePurchase(
          productId: 'com.example.unrelated',
          purchaseTime: 500,
          accountId: 'account-b',
        ),
      ]);

      final snapshot = selectGoogleSubscriptionPurchases(
        response: response,
        accountId: 'account-a',
      );

      expect(snapshot.accountMismatchDetected, isFalse);
      expect(snapshot.purchased, hasLength(2));
      expect(
        snapshot.latestPurchase?.productID,
        'com.damanak.subscription.growth',
      );
      expect(
        snapshot.latestPurchase?.billingClientPurchase.obfuscatedProfileId,
        'store-a',
      );
    });

    test('يرفض ضمنياً سجل ضمانك المرتبط بحساب آخر أو بلا حساب', () {
      final response = _googlePurchasesResponse([
        _googlePurchase(
          productId: 'com.damanak.subscription.starter',
          purchaseTime: 100,
          accountId: 'account-b',
        ),
        _googlePurchase(
          productId: 'com.damanak.subscription.growth',
          purchaseTime: 200,
        ),
      ]);

      final snapshot = selectGoogleSubscriptionPurchases(
        response: response,
        accountId: 'account-a',
      );

      expect(snapshot.purchased, isEmpty);
      expect(snapshot.accountMismatchDetected, isTrue);
    });

    test('يمرر مرشح Google غير المربوط فقط في مسار الاستعادة', () {
      final response = _googlePurchasesResponse([
        _googlePurchase(
          productId: 'com.damanak.subscription.growth',
          purchaseTime: 200,
        ),
      ]);

      final strict = selectGoogleSubscriptionPurchases(
        response: response,
        accountId: 'account-a',
      );
      final restoring = selectGoogleSubscriptionPurchases(
        response: response,
        accountId: 'account-a',
        recoveryRequested: true,
      );

      expect(strict.purchased, isEmpty);
      expect(strict.accountMismatchDetected, isTrue);
      expect(restoring.purchased, hasLength(1));
      expect(restoring.accountMismatchDetected, isTrue);
    });

    test('يمرر ربط Google القديم فقط عند طلب الاسترداد الصريح', () {
      final response = _googlePurchasesResponse([
        _googlePurchase(
          productId: 'com.damanak.subscription.scale',
          purchaseTime: 300,
          accountId: 'deleted-account',
          storeId: 'deleted-store',
        ),
      ]);

      final strict = selectGoogleSubscriptionPurchases(
        response: response,
        accountId: 'account-a',
        includeUnboundForRestore: true,
      );
      final recovery = selectGoogleSubscriptionPurchases(
        response: response,
        accountId: 'account-a',
        includeUnboundForRestore: true,
        recoveryRequested: true,
      );
      final restored = validatedGoogleSubscriptionsForRestore(
        recovery,
        storeId: 'store-a',
        recoveryRequested: true,
      );

      expect(strict.purchased, isEmpty);
      expect(strict.accountMismatchDetected, isTrue);
      expect(restored, hasLength(1));
      expect(
        restored.single.billingClientPurchase.obfuscatedProfileId,
        'deleted-store',
      );
    });

    test('تختار الاستعادة اشتراك المتجر المفتوح من حساب متعدد المتاجر', () {
      final snapshot = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-a',
            storeId: 'store-a',
          ),
          _googlePurchase(
            productId: 'com.damanak.subscription.growth',
            purchaseTime: 200,
            accountId: 'account-a',
            storeId: 'store-b',
          ),
        ]),
        accountId: 'account-a',
        recoveryRequested: true,
      );

      final restored = validatedGoogleSubscriptionsForRestore(
        snapshot,
        storeId: 'store-a',
      );

      expect(restored, hasLength(1));
      expect(
        restored.single.billingClientPurchase.obfuscatedProfileId,
        'store-a',
      );
    });

    test('تفضل الاستعادة الربط الدقيق على مرشح legacy غير مربوط', () {
      final snapshot = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-a',
            storeId: 'store-a',
          ),
          _googlePurchase(
            productId: 'com.damanak.subscription.growth',
            purchaseTime: 200,
            accountId: 'account-a',
          ),
        ]),
        accountId: 'account-a',
        recoveryRequested: true,
      );

      final restored = validatedGoogleSubscriptionsForRestore(
        snapshot,
        storeId: 'store-a',
      );

      expect(restored, hasLength(1));
      expect(
        restored.single.billingClientPurchase.obfuscatedProfileId,
        'store-a',
      );
    });

    test('يرفض تعدد مرشحي Google حتى أثناء الاستعادة', () {
      final snapshot = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
          ),
          _googlePurchase(
            productId: 'com.damanak.subscription.growth',
            purchaseTime: 200,
          ),
        ]),
        accountId: 'account-a',
        recoveryRequested: true,
      );

      expect(
        () => validatedGoogleSubscriptionsForRestore(
          snapshot,
          storeId: 'store-a',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_MULTIPLE_SUBSCRIPTIONS',
          ),
        ),
      );
    });

    test('يفصل الدفعة المعلقة عن الاشتراك المشترى', () {
      final response = _googlePurchasesResponse([
        _googlePurchase(
          productId: 'com.damanak.subscription.scale',
          purchaseTime: 400,
          accountId: 'account-a',
          state: PurchaseStateWrapper.pending,
        ),
      ]);

      final snapshot = selectGoogleSubscriptionPurchases(
        response: response,
        accountId: 'account-a',
      );

      expect(snapshot.purchased, isEmpty);
      expect(snapshot.pending, hasLength(1));
    });

    test('يبقي تغيير Google غير الملتزم معلقًا ويمنع تغييرًا آخر', () {
      final snapshot = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.scale',
            purchaseTime: 200,
            accountId: 'account-a',
            storeId: 'store-a',
            pendingPurchaseUpdate: const PendingPurchaseUpdateWrapper(
              purchaseToken: 'pending-token-with-enough-length',
              products: ['com.damanak.subscription.growth'],
            ),
          ),
        ]),
        accountId: 'account-a',
      );

      expect(snapshot.pendingReplacementCount, 1);
      expect(
        storePurchaseEventStatus(snapshot.purchased.single, restoring: false),
        StorePurchaseStatus.pending,
      );
      expect(
        () => validatedGoogleSubscriptionForPurchase(
          snapshot: snapshot,
          storeId: 'store-a',
          requireExistingSubscription: true,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_SUBSCRIPTION_PENDING',
          ),
        ),
      );
    });

    test('يرفض اختيار اشتراك Google اعتباطيًا عند تعدد المشتريات', () {
      final snapshot = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-a',
            storeId: 'store-a',
          ),
          _googlePurchase(
            productId: 'com.damanak.subscription.growth',
            purchaseTime: 200,
            accountId: 'account-a',
            storeId: 'store-a',
          ),
        ]),
        accountId: 'account-a',
      );

      expect(
        () => validatedGoogleSubscriptionForPurchase(
          snapshot: snapshot,
          storeId: 'store-a',
          requireExistingSubscription: true,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_MULTIPLE_SUBSCRIPTIONS',
          ),
        ),
      );
    });

    test('يربط إلغاء Google ذي المنتج الفارغ بعملية الشراء النشطة فقط', () {
      const activeProductId = 'com.damanak.subscription.starter';

      expect(
        resolveStorePurchaseProductId(
          productId: '',
          status: PurchaseStatus.canceled,
          activeProductId: activeProductId,
        ),
        activeProductId,
      );
      expect(
        resolveStorePurchaseProductId(
          productId: '',
          status: PurchaseStatus.error,
          activeProductId: activeProductId,
        ),
        activeProductId,
      );
      expect(
        resolveStorePurchaseProductId(
          productId: '',
          status: PurchaseStatus.purchased,
          activeProductId: activeProductId,
        ),
        isEmpty,
      );
      expect(
        resolveStorePurchaseProductId(
          productId: '  $activeProductId  ',
          status: PurchaseStatus.purchased,
          activeProductId: 'com.damanak.subscription.growth',
        ),
        activeProductId,
      );
    });

    test('يمنع الاستبدال عند فقد الاشتراك الذي يؤكده الخادم', () {
      final snapshot = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse(const []),
        accountId: 'account-a',
      );

      expect(
        () => validatedGoogleSubscriptionForPurchase(
          snapshot: snapshot,
          storeId: 'store-a',
          requireExistingSubscription: true,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_EXISTING_SUBSCRIPTION_NOT_FOUND',
          ),
        ),
      );
      expect(
        validatedGoogleSubscriptionForPurchase(
          snapshot: snapshot,
          storeId: 'store-a',
          requireExistingSubscription: false,
        ),
        isNull,
      );
    });

    test('يمنع نقل اشتراك حساب أو متجر آخر قبل فتح الدفع', () {
      final accountConflict = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-b',
            storeId: 'store-a',
          ),
        ]),
        accountId: 'account-a',
      );
      final storeConflict = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-a',
            storeId: 'store-b',
          ),
        ]),
        accountId: 'account-a',
      );

      expect(
        () => validatedGoogleSubscriptionForPurchase(
          snapshot: accountConflict,
          storeId: 'store-a',
          requireExistingSubscription: false,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_SUBSCRIPTION_ACCOUNT_CONFLICT',
          ),
        ),
      );
      expect(
        () => validatedGoogleSubscriptionForPurchase(
          snapshot: storeConflict,
          storeId: 'store-a',
          requireExistingSubscription: true,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_SUBSCRIPTION_STORE_CONFLICT',
          ),
        ),
      );
    });

    test('يقبل توكن الاستبدال المربوط صراحةً بالمتجر نفسه', () {
      final sameStore = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-a',
            storeId: 'store-a',
          ),
        ]),
        accountId: 'account-a',
      );

      expect(
        validatedGoogleSubscriptionForPurchase(
          snapshot: sameStore,
          storeId: 'store-a',
          requireExistingSubscription: true,
        ),
        same(sameStore.purchased.single),
      );
    });

    test('يغيّر اشتراك المتجر المطابق ويتجاهل متجر الحساب الآخر', () {
      final multiStore = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-a',
            storeId: 'store-a',
          ),
          _googlePurchase(
            productId: 'com.damanak.subscription.growth',
            purchaseTime: 200,
            accountId: 'account-a',
            storeId: 'store-b',
          ),
        ]),
        accountId: 'account-a',
      );

      final existing = validatedGoogleSubscriptionForPurchase(
        snapshot: multiStore,
        storeId: 'store-a',
        requireExistingSubscription: true,
      );

      expect(existing, isNotNull);
      expect(existing!.billingClientPurchase.obfuscatedProfileId, 'store-a');
    });

    test('لا تمنع دفعة متجر آخر تغيير اشتراك المتجر المطابق', () {
      for (final otherStorePurchase in [
        _googlePurchase(
          productId: 'com.damanak.subscription.growth',
          purchaseTime: 200,
          accountId: 'account-a',
          storeId: 'store-b',
          state: PurchaseStateWrapper.pending,
        ),
        _googlePurchase(
          productId: 'com.damanak.subscription.growth',
          purchaseTime: 300,
          accountId: 'account-a',
          storeId: 'store-b',
          pendingPurchaseUpdate: const PendingPurchaseUpdateWrapper(
            purchaseToken: 'pending-store-b-token-with-enough-length',
            products: ['com.damanak.subscription.scale'],
          ),
        ),
      ]) {
        final snapshot = selectGoogleSubscriptionPurchases(
          response: _googlePurchasesResponse([
            _googlePurchase(
              productId: 'com.damanak.subscription.starter',
              purchaseTime: 100,
              accountId: 'account-a',
              storeId: 'store-a',
            ),
            otherStorePurchase,
          ]),
          accountId: 'account-a',
        );

        final existing = validatedGoogleSubscriptionForPurchase(
          snapshot: snapshot,
          storeId: 'store-a',
          requireExistingSubscription: true,
        );

        expect(existing, isNotNull);
        expect(existing!.billingClientPurchase.obfuscatedProfileId, 'store-a');
      }
    });

    test('يوجه شراء المتجر غير المتصالح إلى الاستعادة قبل فتح الدفع', () {
      final outOfApp = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-a',
            storeId: 'store-a',
          ),
        ]),
        accountId: 'account-a',
      );

      expect(
        () => validatedGoogleSubscriptionForPurchase(
          snapshot: outOfApp,
          storeId: 'store-a',
          requireExistingSubscription: false,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_EXISTING_SUBSCRIPTION_RESTORE_REQUIRED',
          ),
        ),
      );
    });

    test('يرفض الاستبدال عند اجتماع ربط دقيق مع توكن legacy مبهم', () {
      final ambiguous = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-a',
            storeId: 'store-a',
          ),
          _googlePurchase(
            productId: 'com.damanak.subscription.growth',
            purchaseTime: 200,
            accountId: 'account-a',
          ),
        ]),
        accountId: 'account-a',
      );

      expect(
        () => validatedGoogleSubscriptionForPurchase(
          snapshot: ambiguous,
          storeId: 'store-a',
          requireExistingSubscription: true,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_SUBSCRIPTION_STORE_CONFLICT',
          ),
        ),
      );
    });

    test('لا يستخدم شراءً قديماً بلا storeId كتوكن استبدال أبداً', () {
      final legacy = selectGoogleSubscriptionPurchases(
        response: _googlePurchasesResponse([
          _googlePurchase(
            productId: 'com.damanak.subscription.starter',
            purchaseTime: 100,
            accountId: 'account-a',
          ),
        ]),
        accountId: 'account-a',
      );

      expect(
        () => validatedGoogleSubscriptionForPurchase(
          snapshot: legacy,
          storeId: 'store-a',
          requireExistingSubscription: false,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_SUBSCRIPTION_STORE_CONFLICT',
          ),
        ),
      );
      expect(
        () => validatedGoogleSubscriptionForPurchase(
          snapshot: legacy,
          storeId: 'store-a',
          requireExistingSubscription: true,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_SUBSCRIPTION_STORE_CONFLICT',
          ),
        ),
      );
    });

    test('يفشل عند خطأ BillingClient الحقيقي ولو كان الحقل القديم OK', () {
      final response = PurchasesResultWrapper(
        responseCode: BillingResponse.ok,
        billingResult: const BillingResultWrapper(
          responseCode: BillingResponse.serviceUnavailable,
        ),
        purchasesList: const [],
      );

      expect(
        () => selectGoogleSubscriptionPurchases(
          response: response,
          accountId: 'account-a',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('GOOGLE_SUBSCRIPTION_LOOKUP_FAILED'),
          ),
        ),
      );
    });
  });

  group('إكمال معاملة Google بعد التحقق', () {
    test('يستدعي الإكمال المحلي ثم يحذف المعاملة', () async {
      final native = GooglePlayPurchaseDetails.fromPurchase(
        _googlePurchase(
          productId: 'com.damanak.subscription.growth',
          purchaseTime: 400,
          accountId: 'account-a',
          storeId: 'store-a',
        ),
      ).single;
      final purchases = <String, PurchaseDetails>{'verified-google': native};
      var completionCalls = 0;

      await completeTrackedNativePurchase(
        purchases: purchases,
        eventKey: 'verified-google',
        completePurchase: (purchase) async {
          completionCalls += 1;
          expect(purchase, same(native));
          await completeGooglePlayPurchaseWithResultCheck(
            purchase: purchase as GooglePlayPurchaseDetails,
            completePurchase: (_) async =>
                const BillingResultWrapper(responseCode: BillingResponse.ok),
          );
        },
      );

      expect(completionCalls, 1);
      expect(purchases, isEmpty);
    });

    test('يبقي معاملة Google بعد فشل الإكمال ويعيد محاولتها', () async {
      final native = GooglePlayPurchaseDetails.fromPurchase(
        _googlePurchase(
          productId: 'com.damanak.subscription.scale',
          purchaseTime: 500,
          accountId: 'account-a',
          storeId: 'store-a',
        ),
      ).single;
      final purchases = <String, PurchaseDetails>{'retry-google': native};
      var completionCalls = 0;
      var completionResponse = BillingResponse.serviceUnavailable;

      Future<void> complete(PurchaseDetails purchase) async {
        completionCalls += 1;
        await completeGooglePlayPurchaseWithResultCheck(
          purchase: purchase as GooglePlayPurchaseDetails,
          completePurchase: (_) async =>
              BillingResultWrapper(responseCode: completionResponse),
        );
      }

      await expectLater(
        completeTrackedNativePurchase(
          purchases: purchases,
          eventKey: 'retry-google',
          completePurchase: complete,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('serviceUnavailable'),
          ),
        ),
      );
      expect(purchases['retry-google'], same(native));

      completionResponse = BillingResponse.ok;
      await completeTrackedNativePurchase(
        purchases: purchases,
        eventKey: 'retry-google',
        completePurchase: complete,
      );

      expect(completionCalls, 2);
      expect(purchases, isEmpty);
    });
  });

  group('تصنيف انتقال الاشتراك', () {
    test('يميز البدء والخطة الحالية وتغيير دورة الفوترة', () {
      final monthly = _googleOffer('growth', BillingCycle.monthly);
      final yearly = _googleOffer('growth', BillingCycle.yearly);

      expect(
        DamanakStoreCatalog.subscriptionTransition(
          hasActiveStoreSubscription: false,
          currentPlanId: 'growth',
          currentBillingCycle: 'monthly',
          targetPlanId: monthly.planId,
          targetCycle: monthly.cycle,
        ),
        StoreSubscriptionTransitionKind.start,
      );
      expect(
        DamanakStoreCatalog.subscriptionTransition(
          hasActiveStoreSubscription: true,
          currentPlanId: 'growth',
          currentBillingCycle: 'monthly',
          targetPlanId: monthly.planId,
          targetCycle: monthly.cycle,
        ),
        StoreSubscriptionTransitionKind.current,
      );
      expect(
        DamanakStoreCatalog.subscriptionTransition(
          hasActiveStoreSubscription: true,
          currentPlanId: 'growth',
          currentBillingCycle: 'monthly',
          targetPlanId: yearly.planId,
          targetCycle: yearly.cycle,
        ),
        StoreSubscriptionTransitionKind.billingCycleChange,
      );
    });

    test('يصنف كل انتقال بين بداية ونمو وتوسع حسب ترتيب الباقة', () {
      const plans = ['starter', 'growth', 'scale'];
      for (final current in plans) {
        for (final target in plans) {
          final result = DamanakStoreCatalog.subscriptionTransition(
            hasActiveStoreSubscription: true,
            currentPlanId: current,
            currentBillingCycle: 'monthly',
            targetPlanId: target,
            targetCycle: BillingCycle.monthly,
          );
          final expected = current == target
              ? StoreSubscriptionTransitionKind.current
              : DamanakStoreCatalog.planRank(target) >
                    DamanakStoreCatalog.planRank(current)
              ? StoreSubscriptionTransitionKind.upgrade
              : StoreSubscriptionTransitionKind.downgrade;
          expect(result, expected, reason: '$current → $target');
        }
      }
    });
  });

  group('تغيير اشتراك Google', () {
    test('يستخدم مصفوفة صريحة للترقية والتخفيض وتغيير الدورة', () {
      expect(
        googleSubscriptionReplacementMode(
          existingProductId: 'com.damanak.subscription.starter',
          existingCycle: BillingCycle.monthly,
          replacement: _googleOffer('growth', BillingCycle.monthly),
        ),
        ReplacementMode.chargeProratedPrice,
      );
      expect(
        googleSubscriptionReplacementMode(
          existingProductId: 'com.damanak.subscription.starter',
          existingCycle: BillingCycle.monthly,
          replacement: _googleOffer('growth', BillingCycle.yearly),
        ),
        ReplacementMode.chargeFullPrice,
      );
      expect(
        googleSubscriptionReplacementMode(
          existingProductId: 'com.damanak.subscription.starter',
          existingCycle: BillingCycle.yearly,
          replacement: _googleOffer('growth', BillingCycle.monthly),
        ),
        ReplacementMode.chargeFullPrice,
      );
      expect(
        googleSubscriptionReplacementMode(
          existingProductId: 'com.damanak.subscription.scale',
          existingCycle: BillingCycle.yearly,
          replacement: _googleOffer('growth', BillingCycle.monthly),
        ),
        ReplacementMode.deferred,
      );
      expect(
        googleSubscriptionReplacementMode(
          existingProductId: 'com.damanak.subscription.starter',
          existingCycle: BillingCycle.monthly,
          replacement: _googleOffer('starter', BillingCycle.yearly),
        ),
        ReplacementMode.chargeFullPrice,
      );
      expect(
        googleSubscriptionReplacementMode(
          existingProductId: 'com.damanak.subscription.starter',
          existingCycle: BillingCycle.yearly,
          replacement: _googleOffer('starter', BillingCycle.monthly),
        ),
        ReplacementMode.withoutProration,
      );
    });

    test('يمنع إعادة شراء الدورة نفسها أو تغيير دورة مجهولة', () {
      expect(
        () => googleSubscriptionReplacementMode(
          existingProductId: 'com.damanak.subscription.starter',
          existingCycle: BillingCycle.monthly,
          replacement: _googleOffer('starter', BillingCycle.monthly),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_SUBSCRIPTION_ALREADY_ACTIVE',
          ),
        ),
      );
      expect(
        () => googleSubscriptionReplacementMode(
          existingProductId: 'com.damanak.subscription.starter',
          existingCycle: null,
          replacement: _googleOffer('starter', BillingCycle.yearly),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'GOOGLE_EXISTING_CYCLE_UNKNOWN',
          ),
        ),
      );
    });
  });

  test('قناة أحداث الشراء تحفظ الحدث المبكر وتسمح بمستمع واحد', () async {
    final controller = createBufferedStorePurchaseController();
    addTearDown(controller.close);
    const event = StorePurchaseEvent(
      key: 'buffered',
      status: StorePurchaseStatus.pending,
      platform: StoreBillingPlatform.googlePlay,
      productId: 'com.damanak.subscription.starter',
      verificationData: 'token',
      verificationSource: 'google_play',
      needsCompletion: false,
      accountId: 'account-a',
      storeId: 'store-a',
    );

    controller.add(const [event]);
    expect(await controller.stream.first, const [event]);
    expect(() => controller.stream.listen((_) {}), throwsStateError);
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
      expect(controller.storeBillingMessage, contains('لم نجد مشتريات'));
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

PurchasesResultWrapper _googlePurchasesResponse(
  List<PurchaseWrapper> purchases,
) => PurchasesResultWrapper(
  responseCode: BillingResponse.ok,
  billingResult: const BillingResultWrapper(responseCode: BillingResponse.ok),
  purchasesList: purchases,
);

PurchaseWrapper _googlePurchase({
  required String productId,
  required int purchaseTime,
  String? accountId,
  String? storeId,
  PurchaseStateWrapper state = PurchaseStateWrapper.purchased,
  PendingPurchaseUpdateWrapper? pendingPurchaseUpdate,
}) => PurchaseWrapper(
  orderId: 'order-$purchaseTime',
  packageName: DamanakStoreCatalog.packageName,
  purchaseTime: purchaseTime,
  purchaseToken: 'token-$purchaseTime',
  signature: 'signature-$purchaseTime',
  products: [productId],
  isAutoRenewing: true,
  originalJson: '{}',
  isAcknowledged: false,
  purchaseState: state,
  obfuscatedAccountId: accountId,
  obfuscatedProfileId: storeId,
  pendingPurchaseUpdate: pendingPurchaseUpdate,
);

StoreProductOffer _googleOffer(String planId, BillingCycle cycle) =>
    StoreProductOffer(
      key: '$planId:${cycle.value}',
      planId: planId,
      cycle: cycle,
      productId: DamanakStoreCatalog.googleProductId(planId),
      basePlanId: cycle.value,
      title: planId,
      description: cycle.value,
      localizedPrice: '39.99 QAR',
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
  Future<StoreProductLoadResult> loadProducts({
    required String accountId,
  }) async => const StoreProductLoadResult(
    available: true,
    platform: StoreBillingPlatform.appStore,
    offers: [_testOffer],
  );

  @override
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
    required BillingCycle? currentCycle,
    required bool requireExistingSubscription,
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
  Future<StoreRestoreResult> restorePurchases({
    required String accountId,
    required String storeId,
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
  }) async => false;

  @override
  Future<void> dispose() => _updates.close();
}

class _HangingStoreBillingService implements StoreBillingService {
  @override
  Stream<List<StorePurchaseEvent>> get purchaseUpdates => const Stream.empty();

  @override
  Future<StoreProductLoadResult> loadProducts({required String accountId}) =>
      Completer<StoreProductLoadResult>().future;

  @override
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
    required BillingCycle? currentCycle,
    required bool requireExistingSubscription,
  }) async {}

  @override
  Future<StoreRestoreResult> restorePurchases({
    required String accountId,
    required String storeId,
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
  }) async => false;

  @override
  Future<void> dispose() async {}
}
