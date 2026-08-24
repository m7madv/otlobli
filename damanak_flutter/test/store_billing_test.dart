import 'package:damanak/models/store_billing.dart';
import 'package:flutter_test/flutter_test.dart';

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

    test('يرفض المعرفات والدورات غير المدرجة', () {
      expect(
        DamanakStoreCatalog.planIdFromProduct('com.example.subscription'),
        isNull,
      );
      expect(DamanakStoreCatalog.cycleFromGoogleBasePlan('weekly'), isNull);
    });
  });
}
