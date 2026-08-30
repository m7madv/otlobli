import 'dart:async';

import 'package:damanak/data/demo_repository.dart';
import 'package:damanak/models/account.dart';
import 'package:damanak/models/sale.dart';
import 'package:damanak/models/warranty.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ينقل تسجيل الخروج إلى شاشة الدخول من دون انتظار الشبكة', () async {
    final repository = _DelayedSignOutRepository();
    final controller = AppController.withRepository(repository);
    addTearDown(controller.dispose);
    await controller.initialize();

    expect(controller.stage, AppStage.ready);
    await controller.signOut();

    expect(repository.signOutStarted, isTrue);
    expect(controller.stage, AppStage.signedOut);
    expect(controller.busy, isFalse);
    expect(controller.account, isNull);
    repository.finishSignOut();
  });

  group('نظام المتجر التجريبي', () {
    late AppController controller;
    late _CountingDemoRepository repository;

    setUp(() async {
      repository = _CountingDemoRepository();
      controller = AppController.withRepository(repository);
      await controller.initialize();
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

    test('يكشف الرقم التسلسلي المسجل رغم اختلاف الشرطات والحروف', () async {
      final warranty = controller.warranties.first;
      final alternate = warranty.serialNumber.replaceAll('-', '').toLowerCase();

      final match = await controller.findWarrantyBySerial(alternate);

      expect(match?.id, warranty.id);
      expect(await controller.findWarrantyBySerial('SERIAL-NOT-FOUND'), isNull);
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

    test('يحفظ العملة ويلغي إعدادات الضريبة ويضيف فرعاً', () async {
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
      expect(controller.store!.taxRate, 0);
      expect(controller.store!.pricesIncludeTax, isTrue);
      expect(controller.store!.taxNumber, isEmpty);
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

    test('يحمّل الضمانات على صفحات من 100 من دون تكرار', () async {
      final store = controller.store!;
      final branch = controller.branches.first;
      final customer = controller.customers.first;
      for (var index = 0; index < 102; index++) {
        await repository.createWarranty(
          storeId: store.id,
          productId: null,
          customerId: customer.id,
          branchId: branch.id,
          customerName: customer.name,
          customerPhone: customer.phone,
          productName: 'منتج الصفحة $index',
          barcode: '',
          serialNumber: 'PAGE-SERIAL-$index',
          purchaseDate: DateTime(2026, 8, 27),
          expiryDate: DateTime(2027, 8, 27),
          notes: '',
          invoiceNumber: 'PAGE-INVOICE-$index',
          saleSubtotal: 0,
          discountAmount: 0,
          taxAmount: 0,
          saleTotal: 0,
          taxRate: 0,
          currencyCode: 'QAR',
          paymentMethod: PaymentMethod.card,
        );
      }

      await controller.refresh();

      expect(controller.warranties, hasLength(100));
      expect(controller.hasMoreWarranties, isTrue);

      await Future.wait([
        controller.loadMoreWarranties(),
        controller.loadMoreWarranties(),
      ]);

      expect(controller.warranties.length, greaterThan(100));
      expect(controller.hasMoreWarranties, isFalse);
      expect(
        controller.warranties.map((item) => item.id).toSet(),
        hasLength(controller.warranties.length),
      );
      expect(repository.warrantyOffsets.last, 100);
      expect(repository.warrantyOffsets.where((offset) => offset == 100), [
        100,
      ]);
    });

    test('ينفذ بيعاً ويخصم المخزون وينشئ الضمان ثم يعيد القطعة', () async {
      final product = controller.products.first;
      final customer = controller.customers.first;
      final branch = controller.branches.first;
      final stockBefore = controller
          .inventoryLevel(product.id, branch.id)!
          .onHand;
      final warrantiesBefore = controller.warranties.length;
      final fullWarrantyLoadsBefore = repository.fullWarrantyLoads;
      final invoiceWarrantyLoadsBefore = repository.invoiceWarrantyLoads;

      final sale = await controller.createSale(
        branchId: branch.id,
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        lines: [
          SaleLineInput(
            productId: product.id,
            quantity: 1,
            unitPrice: product.salePrice!,
            discountAmount: 0,
            serialNumbers: const ['TEST-POS-SERIAL-1'],
          ),
        ],
        payments: [
          SalePayment(
            id: '',
            method: PaymentMethod.card,
            amount: product.salePrice!,
            reference: 'TEST-PAYMENT',
          ),
        ],
      );

      expect(sale, isNotNull);
      expect(
        controller.inventoryLevel(product.id, branch.id)!.onHand,
        stockBefore - 1,
      );
      expect(controller.warranties.length, warrantiesBefore + 1);
      expect(controller.sales.first.id, sale!.id);
      expect(repository.fullWarrantyLoads, fullWarrantyLoadsBefore);
      expect(repository.invoiceWarrantyLoads, invoiceWarrantyLoadsBefore + 1);

      await controller.returnSale(
        saleId: sale.id,
        lineQuantities: {sale.lines.first.id: 1},
        refundMethod: PaymentMethod.card,
        reason: 'اختبار مرتجع كامل',
      );

      expect(
        controller.inventoryLevel(product.id, branch.id)!.onHand,
        stockBefore,
      );
      expect(controller.sales.first.status, SaleStatus.returned);
    });
  });
}

class _DelayedSignOutRepository extends DemoDamanakRepository {
  final Completer<void> _signOutCompleter = Completer<void>();
  bool signOutStarted = false;

  @override
  bool get isDemo => false;

  @override
  Future<void> signOut() {
    signOutStarted = true;
    return _signOutCompleter.future;
  }

  void finishSignOut() {
    if (!_signOutCompleter.isCompleted) _signOutCompleter.complete();
  }
}

class _CountingDemoRepository extends DemoDamanakRepository {
  int fullWarrantyLoads = 0;
  int invoiceWarrantyLoads = 0;
  final List<int> warrantyOffsets = [];

  @override
  Future<List<Warranty>> loadWarranties(
    String storeId, {
    int limit = 100,
    int offset = 0,
  }) {
    fullWarrantyLoads++;
    warrantyOffsets.add(offset);
    return super.loadWarranties(storeId, limit: limit, offset: offset);
  }

  @override
  Future<List<Warranty>> loadWarrantiesForInvoice(
    String storeId,
    String invoiceNumber,
  ) {
    invoiceWarrantyLoads++;
    return super.loadWarrantiesForInvoice(storeId, invoiceNumber);
  }
}
