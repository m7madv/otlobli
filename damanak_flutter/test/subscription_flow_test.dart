import 'package:damanak/features/subscriptions/domain/subscription_flow.dart';
import 'package:damanak/models/store_billing.dart';
import 'package:damanak/models/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionFlowMachine', () {
    test('يعزل نطاق الحساب والمتجر ويرفض النطاق القديم بعد الفصل', () {
      final machine = SubscriptionFlowMachine();
      const first = BillingScope(
        accountId: 'account-a',
        storeId: 'store-a',
        epoch: 1,
      );
      const sameValue = BillingScope(
        accountId: 'account-a',
        storeId: 'store-a',
        epoch: 1,
      );
      const next = BillingScope(
        accountId: 'account-b',
        storeId: 'store-b',
        epoch: 2,
      );

      expect(first, sameValue);
      expect(machine.attach(scope: first, entitlement: _trial()), isTrue);
      expect(machine.state.scope, first);
      expect(machine.state.revision, 1);
      expect(machine.detach(scope: next), isFalse);
      expect(machine.state.revision, 1);
      expect(machine.detach(scope: sameValue), isTrue);
      expect(machine.attach(scope: first), isFalse);
      expect(machine.attach(scope: next), isTrue);
      expect(machine.state.scope, next);
      expect(machine.state.catalog.status, CatalogStatus.idle);
    });

    test('لا تقبل نتيجة كتالوج قديمة وتمسح الأسعار عند الفشل', () {
      final machine = SubscriptionFlowMachine();
      const scope = BillingScope(
        accountId: 'account-a',
        storeId: 'store-a',
        epoch: 3,
      );
      machine.attach(scope: scope, entitlement: _trial());
      expect(
        machine.beginCatalog(scope: scope, requestId: 'catalog-1'),
        isTrue,
      );
      final loadingRevision = machine.state.revision;

      expect(
        machine.completeCatalog(
          scope: scope,
          requestId: 'catalog-old',
          platform: StoreBillingPlatform.appStore,
          offers: [_appleOffer('starter', BillingCycle.monthly)],
        ),
        isFalse,
      );
      expect(machine.state.revision, loadingRevision);
      expect(
        machine.completeCatalog(
          scope: scope,
          requestId: 'catalog-1',
          platform: StoreBillingPlatform.appStore,
          offers: [
            _appleOffer('starter', BillingCycle.monthly),
            _invalidAppleOffer(),
          ],
        ),
        isTrue,
      );
      expect(machine.state.catalog.status, CatalogStatus.ready);
      expect(machine.state.catalog.offers, hasLength(1));

      machine.beginCatalog(scope: scope, requestId: 'catalog-2');
      expect(
        machine.failCatalog(
          scope: scope,
          requestId: 'catalog-2',
          platform: StoreBillingPlatform.appStore,
          message: 'تعذر جلب الأسعار.',
        ),
        isTrue,
      );
      expect(machine.state.catalog.status, CatalogStatus.unavailable);
      expect(machine.state.catalog.offers, isEmpty);
      expect(machine.state.catalog.message, 'تعذر جلب الأسعار.');
    });

    test('يسمح بعملية واحدة ويرفض token قديم والانتقال غير القانوني', () {
      final machine = SubscriptionFlowMachine();
      const scope = BillingScope(
        accountId: 'account-a',
        storeId: 'store-a',
        epoch: 4,
      );
      final entitlement = _trial();
      final offer = _appleOffer('growth', BillingCycle.monthly);
      machine.attach(scope: scope, entitlement: entitlement);
      machine.beginCatalog(scope: scope, requestId: 'catalog');
      machine.completeCatalog(
        scope: scope,
        requestId: 'catalog',
        platform: StoreBillingPlatform.appStore,
        offers: [offer],
      );
      const operation = BillingOperation(
        kind: BillingOperationKind.preflighting,
        origin: BillingOperationOrigin.purchase,
        operationId: 'purchase-1',
        scope: scope,
        productId: 'com.damanak.subscription.growth.monthly',
      );

      expect(machine.beginOperation(operation), isTrue);
      expect(machine.beginOperation(operation), isFalse);
      final operationRevision = machine.state.revision;
      expect(
        machine.advanceOperation(
          scope: scope,
          operationId: 'purchase-old',
          kind: BillingOperationKind.awaitingStore,
        ),
        isFalse,
      );
      expect(
        machine.advanceOperation(
          scope: scope,
          operationId: 'purchase-1',
          kind: BillingOperationKind.provisioning,
        ),
        isFalse,
      );
      expect(machine.state.revision, operationRevision);
      expect(
        machine.advanceOperation(
          scope: scope,
          operationId: 'purchase-1',
          kind: BillingOperationKind.awaitingStore,
        ),
        isTrue,
      );
      expect(
        machine.markPending(
          scope: scope,
          operationId: 'purchase-1',
          message: 'الدفعة معلّقة.',
        ),
        isTrue,
      );
      expect(machine.state.operation!.kind, BillingOperationKind.pending);
      expect(machine.state.message, 'الدفعة معلّقة.');
      expect(
        machine.advanceOperation(
          scope: scope,
          operationId: 'purchase-1',
          kind: BillingOperationKind.verifying,
        ),
        isTrue,
      );
      expect(
        machine.updateEntitlement(
          scope: scope,
          entitlement: _storeSubscription(
            planId: 'growth',
            cycle: BillingCycle.monthly,
          ),
          operationId: 'purchase-old',
        ),
        isFalse,
      );
      expect(machine.state.entitlement, same(entitlement));
      expect(
        machine.updateEntitlement(
          scope: scope,
          entitlement: _storeSubscription(
            planId: 'growth',
            cycle: BillingCycle.monthly,
          ),
          operationId: 'purchase-1',
        ),
        isTrue,
      );
      expect(
        machine.finishOperation(
          scope: scope,
          operationId: 'purchase-1',
          message: 'تم التفعيل.',
        ),
        isTrue,
      );
      expect(machine.state.operation, isNull);
      expect(machine.state.message, 'تم التفعيل.');

      const second = BillingOperation(
        kind: BillingOperationKind.restoring,
        origin: BillingOperationOrigin.explicitRestore,
        operationId: 'restore-2',
        scope: scope,
      );
      expect(machine.beginOperation(second), isTrue);
      final secondRevision = machine.state.revision;
      expect(
        machine.finishOperation(scope: scope, operationId: 'purchase-1'),
        isFalse,
      );
      expect(
        machine.setMessage(
          scope: scope,
          operationId: 'purchase-1',
          message: 'رسالة قديمة',
        ),
        isFalse,
      );
      expect(machine.state.revision, secondRevision);
      expect(machine.state.operation!.operationId, 'restore-2');
    });
  });

  group('SubscriptionPolicy', () {
    test('يسمح بالبدء من دون استحقاق أو من مصدر غير متجري', () {
      final target = _appleOffer('starter', BillingCycle.monthly);
      expect(
        SubscriptionPolicy.evaluate(
          current: null,
          target: target,
          devicePlatform: StoreBillingPlatform.appStore,
        ),
        isA<StartSubscriptionDecision>(),
      );
      expect(
        SubscriptionPolicy.evaluate(
          current: _trial(),
          target: target,
          devicePlatform: StoreBillingPlatform.appStore,
        ),
        isA<StartSubscriptionDecision>(),
      );
    });

    test('يميّز الخطة الحالية والترقية وتغيير الدورة والخفض', () {
      final starter = _storeSubscription(
        planId: 'starter',
        cycle: BillingCycle.monthly,
      );
      final scale = _storeSubscription(
        planId: 'scale',
        cycle: BillingCycle.monthly,
      );

      expect(
        _decision(starter, 'starter', BillingCycle.monthly),
        isA<BlockedSubscriptionDecision>().having(
          (decision) => decision.reason,
          'reason',
          SubscriptionBlockReason.alreadyActive,
        ),
      );
      expect(
        _decision(starter, 'growth', BillingCycle.monthly),
        isA<UpgradeSubscriptionDecision>(),
      );
      expect(
        _decision(starter, 'starter', BillingCycle.yearly),
        isA<ChangeBillingCycleDecision>(),
      );
      expect(
        _decision(scale, 'growth', BillingCycle.monthly),
        isA<BlockedSubscriptionDecision>().having(
          (decision) => decision.reason,
          'reason',
          SubscriptionBlockReason.downgrade,
        ),
      );
    });

    test('يمنع مزوداً ثانياً ويفشل مغلقاً عند حالة أو منتج مجهول', () {
      final current = _storeSubscription(
        planId: 'starter',
        cycle: BillingCycle.monthly,
      );
      expect(
        SubscriptionPolicy.evaluate(
          current: current,
          target: _googleOffer('growth', BillingCycle.monthly),
          devicePlatform: StoreBillingPlatform.googlePlay,
        ),
        isA<BlockedSubscriptionDecision>().having(
          (decision) => decision.reason,
          'reason',
          SubscriptionBlockReason.providerConflict,
        ),
      );

      final incomplete = SubscriptionInfo(
        id: 'subscription-incomplete',
        status: 'active',
        plan: _plan('starter'),
        trialEndsAt: null,
        periodEndsAt: DateTime.utc(2099),
        usedWarranties: 0,
        source: 'store',
        billingProvider: 'app_store',
        storeProductId: 'com.damanak.subscription.starter.monthly',
        originalTransactionId: 'original-1',
        billingCycle: null,
        autoRenews: true,
        lastVerifiedAt: DateTime.utc(2026),
      );
      expect(
        _decision(incomplete, 'growth', BillingCycle.monthly),
        isA<BlockedSubscriptionDecision>().having(
          (decision) => decision.reason,
          'reason',
          SubscriptionBlockReason.stateUnknown,
        ),
      );
      expect(
        SubscriptionPolicy.evaluate(
          current: current,
          target: _invalidAppleOffer(),
          devicePlatform: StoreBillingPlatform.appStore,
        ),
        isA<BlockedSubscriptionDecision>().having(
          (decision) => decision.reason,
          'reason',
          SubscriptionBlockReason.stateUnknown,
        ),
      );
    });
  });
}

SubscriptionDecision _decision(
  SubscriptionInfo current,
  String targetPlanId,
  BillingCycle cycle,
) => SubscriptionPolicy.evaluate(
  current: current,
  target: _appleOffer(targetPlanId, cycle),
  devicePlatform: StoreBillingPlatform.appStore,
);

SubscriptionInfo _trial() => SubscriptionInfo(
  id: 'subscription-trial',
  status: 'trialing',
  plan: _plan('starter'),
  trialEndsAt: DateTime.utc(2099),
  periodEndsAt: null,
  usedWarranties: 0,
);

SubscriptionInfo _storeSubscription({
  required String planId,
  required BillingCycle cycle,
}) => SubscriptionInfo(
  id: 'subscription-$planId-${cycle.value}',
  status: 'active',
  plan: _plan(planId),
  trialEndsAt: null,
  periodEndsAt: DateTime.utc(2099),
  usedWarranties: 12,
  source: 'store',
  billingProvider: 'app_store',
  storeProductId: DamanakStoreCatalog.appleProductId(planId, cycle),
  originalTransactionId: 'original-$planId',
  billingCycle: cycle.value,
  autoRenews: true,
  lastVerifiedAt: DateTime.utc(2026),
);

PlanInfo _plan(String id) => PlanInfo(
  id: id,
  name: switch (id) {
    'starter' => 'بداية',
    'growth' => 'نمو',
    'scale' => 'توسع',
    _ => 'مجهولة',
  },
  monthlyPrice: 0,
  yearlyPrice: 0,
  maxMembers: 2,
  monthlyWarranties: 100,
);

StoreProductOffer _appleOffer(String planId, BillingCycle cycle) =>
    StoreProductOffer(
      key: '$planId:${cycle.value}',
      planId: planId,
      cycle: cycle,
      productId: DamanakStoreCatalog.appleProductId(planId, cycle),
      title: planId,
      description: '',
      localizedPrice: 'QAR 10',
      rawPrice: 10,
      currencyCode: 'QAR',
    );

StoreProductOffer _googleOffer(String planId, BillingCycle cycle) =>
    StoreProductOffer(
      key: '$planId:${cycle.value}',
      planId: planId,
      cycle: cycle,
      productId: DamanakStoreCatalog.googleProductId(planId),
      basePlanId: cycle.value,
      title: planId,
      description: '',
      localizedPrice: 'QAR 10',
      rawPrice: 10,
      currencyCode: 'QAR',
    );

StoreProductOffer _invalidAppleOffer() => const StoreProductOffer(
  key: 'growth:monthly:invalid',
  planId: 'growth',
  cycle: BillingCycle.monthly,
  productId: 'com.damanak.subscription.starter.monthly',
  title: 'invalid',
  description: '',
  localizedPrice: 'QAR 10',
  rawPrice: 10,
  currencyCode: 'QAR',
);
