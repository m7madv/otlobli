import 'package:damanak/models/account.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('نظام المتجر التجريبي', () {
    late AppController controller;

    setUp(() async {
      controller = AppController.unconfigured();
      await controller.startDemo();
    });

    test('يفتح مساحة متجر كاملة بخطة وفريق ومنتجات', () {
      expect(controller.stage, AppStage.ready);
      expect(controller.store, isNotNull);
      expect(controller.subscription, isNotNull);
      expect(controller.team.length, 2);
      expect(controller.products.length, 3);
    });

    test('يعثر على المنتج بالباركود', () {
      final barcode = controller.products.first.barcode;
      expect(
        controller.productByBarcode(barcode)?.id,
        controller.products.first.id,
      );
      expect(controller.productByBarcode('000000'), isNull);
    });

    test('يضيف منتجاً ثم يصدر له ضماناً ويحتسب الاستخدام', () async {
      final beforeUsage = controller.subscription!.usedWarranties;
      final product = await controller.addProduct(
        name: 'شاشة مكتبية',
        brand: 'ViewMax',
        barcode: '6289990000111',
        sku: 'MON-27',
        warrantyMonths: 24,
        salePrice: 799,
      );

      expect(product, isNotNull);
      expect(controller.productByBarcode('6289990000111'), isNotNull);

      final warranty = await controller.addWarranty(
        productId: product!.id,
        customerName: 'عميل الاختبار',
        customerPhone: '0501234567',
        productName: product.name,
        barcode: product.barcode,
        serialNumber: 'TEST-SERIAL',
        purchaseDate: DateTime(2026, 8, 24),
        expiryDate: DateTime(2028, 8, 24),
        notes: '',
      );

      expect(warranty, isNotNull);
      expect(controller.warranties.first.id, warranty!.id);
      expect(controller.subscription!.usedWarranties, beforeUsage + 1);
    });

    test('ينشئ دعوة بصلاحية مستقلة', () async {
      final invite = await controller.createInvite(MemberRole.staff, 3);
      expect(invite, isNotNull);
      expect(invite!.role, MemberRole.staff);
      expect(invite.maxUses, 3);
      expect(invite.code, startsWith('DMN-'));
    });
  });
}
