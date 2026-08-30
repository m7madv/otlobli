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
}) => SubscriptionInfo(
  id: 'subscription',
  status: status,
  plan: _plan,
  trialEndsAt: trialEndsAt,
  periodEndsAt: periodEndsAt,
  usedWarranties: 0,
  source: source,
);

void main() {
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
}
