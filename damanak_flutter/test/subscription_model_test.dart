import 'package:damanak/models/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

const _plan = PlanInfo(
  id: 'starter',
  name: 'بداية',
  monthlyPrice: 39,
  yearlyPrice: 390,
  maxMembers: 2,
  monthlyWarranties: 100,
  maxBranches: 1,
  monthlyAiImports: 1,
  monthlyAiClaimReviews: 0,
  apiAccess: false,
  webhookAccess: false,
  customBranding: false,
);

SubscriptionInfo _subscription({
  required String status,
  required String source,
  DateTime? trialEndsAt,
  DateTime? periodEndsAt,
  DateTime? lastVerifiedAt,
}) => SubscriptionInfo(
  id: 'subscription',
  status: status,
  plan: _plan,
  trialEndsAt: trialEndsAt,
  periodEndsAt: periodEndsAt,
  usedWarranties: 0,
  source: source,
  lastVerifiedAt: lastVerifiedAt,
);

void main() {
  test('الخطة المجانية تمنح 20 ضماناً بلا هامش مدفوع أو دورة متجر', () {
    const freePlan = PlanInfo(
      id: 'free',
      name: 'مجانية',
      monthlyPrice: 0,
      yearlyPrice: 0,
      maxMembers: 1,
      monthlyWarranties: 20,
      maxBranches: 1,
    );
    const subscription = SubscriptionInfo(
      id: 'free-grant',
      status: 'active',
      plan: freePlan,
      trialEndsAt: null,
      periodEndsAt: null,
      usedWarranties: 7,
      source: 'free',
    );

    expect(subscription.isFreeAccess, isTrue);
    expect(subscription.isStoreSubscription, isFalse);
    expect(subscription.isUsable, isTrue);
    expect(subscription.remainingWarranties, 13);
    expect(subscription.warrantyGraceAllowance, 0);
    expect(
      subscription.plan.features,
      contains('20 ضماناً تتجدد تلقائياً كل شهر'),
    );
  });

  test('تحديث الاستهلاك لا يفقد سجل فوترة المتجر المخفي', () {
    final verifiedAt = DateTime.utc(2026, 9, 1, 12);
    final subscription = SubscriptionInfo(
      id: 'free-grant',
      status: 'active',
      plan: const PlanInfo(
        id: 'free',
        name: 'مجانية',
        monthlyPrice: 0,
        yearlyPrice: 0,
        maxMembers: 1,
        monthlyWarranties: 20,
      ),
      trialEndsAt: null,
      periodEndsAt: null,
      usedWarranties: 3,
      source: 'free',
      hasStoreBillingLineage: true,
      storeBillingLineageVerifiedAt: verifiedAt,
    );

    final updated = subscription.withUsedWarranties(4);
    expect(updated.usedWarranties, 4);
    expect(updated.canRefreshStoreBilling, isTrue);
    expect(updated.storeBillingLineageVerifiedAt, verifiedAt);
  });

  test('لا يحاول تحديث اشتراك متجر منتهٍ بلا مدة سارية', () {
    final subscription = _subscription(
      status: 'canceled',
      source: 'store',
      periodEndsAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    expect(subscription.canRefreshStoreBilling, isFalse);
  });

  test('المتجر غير المشترك لا يحصل على حصة الخطة الاسمية', () {
    final subscription = _subscription(
      status: 'canceled',
      source: 'trial',
      trialEndsAt: null,
      periodEndsAt: null,
    );

    expect(subscription.isAwaitingSubscription, isTrue);
    expect(subscription.isUsable, isFalse);
    expect(subscription.remainingWarranties, 0);
  });

  test('لا يخلط بوابة الدفع الأول بتجربة منتهية أو اشتراك يدوي', () {
    final expiredTrial = _subscription(
      status: 'canceled',
      source: 'trial',
      trialEndsAt: DateTime.now().subtract(const Duration(days: 1)),
      periodEndsAt: null,
    );
    final manualSubscription = _subscription(
      status: 'canceled',
      source: 'manual',
      trialEndsAt: null,
      periodEndsAt: null,
    );

    expect(expiredTrial.isAwaitingSubscription, isFalse);
    expect(manualSubscription.isAwaitingSubscription, isFalse);
  });

  test('اشتراك المتجر لا يصبح مفتوح المدة عند غياب نهاية الفترة', () {
    expect(_subscription(status: 'active', source: 'store').isUsable, isFalse);
  });

  test('اشتراك المتجر المنتهي لا يبقى صالحًا في الواجهة', () {
    expect(
      _subscription(
        status: 'active',
        source: 'store',
        periodEndsAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ).isUsable,
      isFalse,
    );
  });

  test('الفترة التجريبية الصالحة والاشتراك المدفوع الحالي يعملان', () {
    expect(
      _subscription(
        status: 'trialing',
        source: 'trial',
        trialEndsAt: DateTime.now().add(const Duration(days: 1)),
      ).isUsable,
      isTrue,
    );
    expect(
      _subscription(
        status: 'active',
        source: 'store',
        periodEndsAt: DateTime.now().add(const Duration(days: 1)),
      ).isUsable,
      isTrue,
    );
  });

  test('حارس مزود الدفع يستخدم زمن الخادم والحالة لا ساعة الجهاز وحدها', () {
    final verifiedAt = DateTime.utc(2026, 8, 31, 12);
    expect(
      _subscription(
        status: 'active',
        source: 'store',
        periodEndsAt: verifiedAt.add(const Duration(days: 1)),
        lastVerifiedAt: verifiedAt,
      ).hasUnexpiredStorePeriod,
      isTrue,
    );
    expect(
      _subscription(
        status: 'canceled',
        source: 'store',
        periodEndsAt: verifiedAt.add(const Duration(days: 30)),
        lastVerifiedAt: verifiedAt,
      ).hasUnexpiredStorePeriod,
      isFalse,
    );
    expect(
      _subscription(
        status: 'active',
        source: 'store',
        periodEndsAt: verifiedAt.subtract(const Duration(seconds: 1)),
        lastVerifiedAt: verifiedAt,
      ).hasUnexpiredStorePeriod,
      isFalse,
    );
    expect(
      _subscription(
        status: 'active',
        source: 'store',
        periodEndsAt: verifiedAt.add(const Duration(days: 1)),
      ).hasUnexpiredStorePeriod,
      isTrue,
      reason: 'غياب زمن تحقق الخادم يجب أن يمنع فتح مزود ثانٍ احتياطياً',
    );
  });
}
