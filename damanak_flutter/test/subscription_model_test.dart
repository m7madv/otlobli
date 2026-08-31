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
