import 'package:damanak/models/account.dart';
import 'package:damanak/models/warranty.dart';
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
      expect(controller.customers.length, 2);
      expect(controller.branches.single.isMain, isTrue);
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
        category: 'شاشات',
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
        customerEmail: 'customer@example.com',
        customerNotes: 'عميل اختبار',
        branchId: controller.branches.first.id,
        invoiceNumber: 'TEST-1001',
        saleSubtotal: 799,
        discountAmount: 49,
        taxAmount: 97.83,
        saleTotal: 750,
        taxRate: 15,
        currencyCode: 'SAR',
        paymentMethod: PaymentMethod.card,
      );

      expect(warranty, isNotNull);
      expect(controller.warranties.first.id, warranty!.id);
      expect(controller.subscription!.usedWarranties, beforeUsage + 1);
      expect(controller.customers.first.phone, '0501234567');
      expect(warranty.invoiceNumber, 'TEST-1001');
      expect(warranty.saleTotal, 750);
      expect(warranty.paymentMethod, PaymentMethod.card);
      expect(controller.totalSales, greaterThanOrEqualTo(750));
    });

    test('يحفظ إعدادات العملة والضريبة ويضيف فرعاً', () async {
      await controller.updateStore(
        name: controller.store!.name,
        phone: controller.store!.phone,
        city: 'دبي',
        countryCode: 'AE',
        currencyCode: 'AED',
        taxRate: 5,
        pricesIncludeTax: false,
        taxNumber: '100200300',
        commercialRegistration: 'CN-900',
        address: 'شارع الاختبار',
        invoicePrefix: 'DXB',
        defaultWarrantyMonths: 24,
      );
      final branch = await controller.saveBranch(
        name: 'فرع دبي',
        code: 'DXB-01',
        city: 'دبي',
        address: 'وسط المدينة',
        phone: '0500000001',
        isMain: true,
      );

      expect(controller.store!.currencyCode, 'AED');
      expect(controller.store!.taxRate, 5);
      expect(controller.store!.pricesIncludeTax, isFalse);
      expect(branch?.isMain, isTrue);
      expect(controller.branches.where((item) => item.isMain).length, 1);
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
