import 'package:uuid/uuid.dart';

import '../core/currency.dart';
import '../core/date_utils.dart';
import '../models/account.dart';
import '../models/audit_event.dart';
import '../models/branch.dart';
import '../models/customer.dart';
import '../models/inventory.dart';
import '../models/maintenance_request.dart';
import '../models/product.dart';
import '../models/register.dart';
import '../models/sale.dart';
import '../models/subscription.dart';
import '../models/store_billing.dart';
import '../models/supplier.dart';
import '../models/warranty.dart';
import 'damanak_repository.dart';

class DemoDamanakRepository implements DamanakRepository {
  DemoDamanakRepository() {
    final now = DateTime.now();
    _products.addAll([
      Product(
        id: _uuid.v4(),
        storeId: _store.id,
        name: 'ماكينة قهوة منزلية',
        brand: 'Brew House',
        category: 'أجهزة المطبخ',
        barcode: '6281000000142',
        sku: 'COF-440',
        warrantyMonths: 24,
        salePrice: 649,
        costPrice: 410,
        reorderPoint: 4,
        isSerialized: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Product(
        id: _uuid.v4(),
        storeId: _store.id,
        name: 'سماعة لاسلكية',
        brand: 'NOVA',
        category: 'صوتيات',
        barcode: '6281000000296',
        sku: 'AUD-210',
        warrantyMonths: 12,
        salePrice: 219,
        costPrice: 125,
        reorderPoint: 6,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Product(
        id: _uuid.v4(),
        storeId: _store.id,
        name: 'مكنسة ذكية',
        brand: 'HomePilot',
        category: 'أجهزة منزلية',
        barcode: '6281000000333',
        sku: 'VAC-330',
        warrantyMonths: 24,
        salePrice: 1290,
        costPrice: 870,
        reorderPoint: 3,
        isSerialized: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);
    _branches.add(
      StoreBranch(
        id: 'demo-main-branch',
        storeId: _store.id,
        name: 'الفرع الرئيسي',
        code: 'MAIN',
        city: 'الرياض',
        address: 'طريق الملك فهد، حي العليا',
        phone: '0500000000',
        email: 'riyadh@demo.damanak.app',
        managerName: 'نورة المبيعات',
        receiptPrefix: 'RUH',
        type: BranchType.hybrid,
        acceptsSales: true,
        handlesService: true,
        isMain: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    );
    _customers.addAll([
      CustomerProfile(
        id: 'demo-customer-sara',
        storeId: _store.id,
        name: 'سارة العتيبي',
        phone: '0500001122',
        email: 'sara@example.com',
        notes: '',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      CustomerProfile(
        id: 'demo-customer-ahmad',
        storeId: _store.id,
        name: 'أحمد خالد',
        phone: '0550007788',
        email: '',
        notes: 'يفضل التواصل عبر واتساب.',
        createdAt: now.subtract(const Duration(days: 18)),
        updatedAt: now.subtract(const Duration(days: 18)),
      ),
    ]);
    _warranties.addAll([
      _demoWarranty(
        product: _products[0],
        customerName: 'سارة العتيبي',
        customerPhone: '0500001122',
        daysAgo: 6,
      ),
      _demoWarranty(
        product: _products[1],
        customerName: 'أحمد خالد',
        customerPhone: '0550007788',
        daysAgo: 18,
      ),
    ]);
    _members.addAll([
      TeamMember(
        userId: _account.id,
        fullName: _account.fullName,
        email: _account.email,
        role: MemberRole.owner,
        status: 'active',
        joinedAt: now.subtract(const Duration(days: 30)),
      ),
      TeamMember(
        userId: _uuid.v4(),
        fullName: 'نورة المبيعات',
        email: 'noura@example.com',
        role: MemberRole.staff,
        status: 'active',
        joinedAt: now.subtract(const Duration(days: 9)),
      ),
    ]);
    for (var index = 0; index < _products.length; index++) {
      _inventory.add(
        InventoryLevel(
          id: _uuid.v4(),
          storeId: _store.id,
          branchId: _branches.first.id,
          productId: _products[index].id,
          onHand: [12, 4, 2][index],
          reserved: 0,
          reorderPoint: _products[index].reorderPoint,
          averageCost: _products[index].costPrice ?? 0,
          updatedAt: now.subtract(Duration(hours: index + 1)),
        ),
      );
    }
    _sales.addAll([
      _demoSale(product: _products[0], customer: _customers[0], daysAgo: 6),
      _demoSale(product: _products[1], customer: _customers[1], daysAgo: 18),
    ]);
    _suppliers.add(
      Supplier(
        id: 'demo-supplier',
        storeId: _store.id,
        name: 'شركة التوريد الخليجية',
        contactName: 'خالد المورّد',
        phone: '0551234567',
        email: 'supply@example.com',
        taxNumber: '310000000000003',
        address: 'الرياض',
        notes: 'توريد أسبوعي للأجهزة المنزلية.',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
    );
    _registerSessions.add(
      CashRegisterSession(
        id: 'demo-register',
        storeId: _store.id,
        branchId: _branches.first.id,
        openedBy: _account.id,
        closedBy: '',
        openingCash: 500,
        cashSales: 0,
        cashRefunds: 0,
        cashIn: 0,
        cashOut: 0,
        closingCash: 0,
        status: RegisterStatus.open,
        openedAt: now.subtract(const Duration(hours: 3)),
        closedAt: null,
        notes: 'وردية صباحية',
      ),
    );
  }

  static const _uuid = Uuid();
  static const _account = AccountIdentity(
    id: 'demo-owner',
    email: 'owner@demo.damanak.app',
    fullName: 'محمد صاحب المتجر',
  );
  StoreWorkspace _store = const StoreWorkspace(
    id: 'demo-store',
    name: 'متجر الخليج للإلكترونيات',
    phone: '0500000000',
    city: 'الرياض',
    countryCode: 'SA',
    currencyCode: 'SAR',
    taxRate: 15,
    pricesIncludeTax: true,
    taxNumber: '310123456700003',
    commercialRegistration: '1010123456',
    address: 'طريق الملك فهد، حي العليا',
    invoicePrefix: 'GLF',
    defaultWarrantyMonths: 12,
  );
  static const _plan = PlanInfo(
    id: 'growth',
    name: 'نمو',
    monthlyPrice: 99,
    yearlyPrice: 990,
    maxMembers: 5,
    monthlyWarranties: 250,
  );

  final List<Product> _products = [];
  final List<StoreBranch> _branches = [];
  final List<CustomerProfile> _customers = [];
  final List<Warranty> _warranties = [];
  final List<MaintenanceRequest> _requests = [];
  final List<TeamMember> _members = [];
  final List<AuditEvent> _auditLogs = [];
  final List<InventoryLevel> _inventory = [];
  final List<StockMovement> _stockMovements = [];
  final List<SaleTransaction> _sales = [];
  final List<CashRegisterSession> _registerSessions = [];
  final List<Supplier> _suppliers = [];
  final List<PurchaseOrder> _purchaseOrders = [];

  SubscriptionInfo _subscription = SubscriptionInfo(
    id: 'demo-subscription',
    status: 'trialing',
    plan: _plan,
    trialEndsAt: DateTime.now().add(const Duration(days: 11)),
    periodEndsAt: null,
    usedWarranties: 2,
  );

  @override
  bool get isDemo => true;

  Warranty _demoWarranty({
    required Product product,
    required String customerName,
    required String customerPhone,
    required int daysAgo,
  }) {
    final purchased = DateTime.now().subtract(Duration(days: daysAgo));
    final id = _uuid.v4();
    return Warranty(
      id: id,
      warrantyNumber: 'DMN-${id.substring(0, 6).toUpperCase()}',
      storeId: _store.id,
      productId: product.id,
      customerId: customerPhone == '0500001122'
          ? 'demo-customer-sara'
          : 'demo-customer-ahmad',
      branchId: 'demo-main-branch',
      customerName: customerName,
      customerPhone: customerPhone,
      productName: product.name,
      barcode: product.barcode,
      serialNumber: 'SN-${id.substring(0, 8).toUpperCase()}',
      purchaseDate: purchased,
      expiryDate: addMonths(purchased, product.warrantyMonths),
      createdAt: purchased,
      notes: '',
      createdBy: _account.id,
      invoiceNumber: 'GLF-${id.substring(0, 6).toUpperCase()}',
      saleSubtotal: product.salePrice ?? 0,
      taxAmount: ((product.salePrice ?? 0) * 15 / 115),
      saleTotal: product.salePrice ?? 0,
      taxRate: 15,
      currencyCode: 'SAR',
      paymentMethod: PaymentMethod.card,
    );
  }

  SaleTransaction _demoSale({
    required Product product,
    required CustomerProfile customer,
    required int daysAgo,
  }) {
    final id = _uuid.v4();
    final total = product.salePrice ?? 0;
    final tax = total * 15 / 115;
    return SaleTransaction(
      id: id,
      storeId: _store.id,
      branchId: _branches.first.id,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      invoiceNumber: 'GLF-${id.substring(0, 6).toUpperCase()}',
      status: SaleStatus.completed,
      subtotal: total,
      discountAmount: 0,
      taxAmount: tax,
      total: total,
      refundedAmount: 0,
      currencyCode: _store.currencyCode,
      taxRate: _store.taxRate,
      pricesIncludeTax: _store.pricesIncludeTax,
      notes: '',
      cashierId: _account.id,
      createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
      lines: [
        SaleLine(
          id: _uuid.v4(),
          productId: product.id,
          productName: product.name,
          sku: product.sku,
          barcode: product.barcode,
          quantity: 1,
          returnedQuantity: 0,
          unitPrice: total,
          unitCost: product.costPrice ?? 0,
          discountAmount: 0,
          taxAmount: tax,
          lineTotal: total,
          warrantyMonths: product.warrantyMonths,
          serialNumbers: product.isSerialized
              ? ['SN-${id.substring(0, 8).toUpperCase()}']
              : const [],
        ),
      ],
      payments: [
        SalePayment(
          id: _uuid.v4(),
          method: PaymentMethod.card,
          amount: total,
          reference: '',
        ),
      ],
    );
  }

  WorkspaceSnapshot get _snapshot => WorkspaceSnapshot(
    store: _store,
    membership: const StoreMembership(
      storeId: 'demo-store',
      userId: 'demo-owner',
      role: MemberRole.owner,
      status: 'active',
    ),
    subscription: _subscription,
  );

  @override
  Future<AccountIdentity?> restoreAccount() async => _account;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signInWithSocial(SocialAuthProvider provider) async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<WorkspaceSnapshot?> loadWorkspace() async => _snapshot;

  @override
  Future<WorkspaceSnapshot> createStore({
    required String name,
    required String phone,
    required String city,
    required String countryCode,
  }) async => _snapshot;

  @override
  Future<WorkspaceSnapshot> joinStore(String invitationCode) async => _snapshot;

  @override
  Future<StoreWorkspace> updateStore({
    required String storeId,
    required String name,
    required String phone,
    required String city,
    required String countryCode,
    required String currencyCode,
    required num taxRate,
    required bool pricesIncludeTax,
    required String taxNumber,
    required String commercialRegistration,
    required String address,
    required String invoicePrefix,
    required int defaultWarrantyMonths,
  }) async {
    _store = StoreWorkspace(
      id: storeId,
      name: name.trim(),
      phone: phone.trim(),
      city: city.trim(),
      countryCode: countryCode,
      currencyCode: currencyCode,
      taxRate: taxRate,
      pricesIncludeTax: pricesIncludeTax,
      taxNumber: taxNumber.trim(),
      commercialRegistration: commercialRegistration.trim(),
      address: address.trim(),
      invoicePrefix: invoicePrefix.trim().toUpperCase(),
      defaultWarrantyMonths: defaultWarrantyMonths,
    );
    return _store;
  }

  @override
  Future<List<StoreBranch>> loadBranches(String storeId) async => [
    ..._branches,
  ];

  @override
  Future<StoreBranch> saveBranch({
    required String storeId,
    String? branchId,
    required String name,
    required String code,
    required String city,
    required String address,
    required String phone,
    required bool isMain,
    required String email,
    required String managerName,
    required String receiptPrefix,
    required String timezone,
    required String opensAt,
    required String closesAt,
    required BranchType type,
    required bool acceptsSales,
    required bool handlesService,
  }) async {
    final index = branchId == null
        ? -1
        : _branches.indexWhere((item) => item.id == branchId);
    final branch = StoreBranch(
      id: branchId ?? _uuid.v4(),
      storeId: storeId,
      name: name.trim(),
      code: code.trim().toUpperCase(),
      city: city.trim(),
      address: address.trim(),
      phone: phone.trim(),
      email: email.trim(),
      managerName: managerName.trim(),
      receiptPrefix: receiptPrefix.trim().toUpperCase(),
      timezone: timezone,
      opensAt: opensAt,
      closesAt: closesAt,
      type: type,
      acceptsSales: acceptsSales,
      handlesService: handlesService,
      isMain: isMain,
      isActive: true,
      createdAt: index >= 0 ? _branches[index].createdAt : DateTime.now(),
    );
    if (isMain) {
      for (var i = 0; i < _branches.length; i++) {
        final item = _branches[i];
        _branches[i] = StoreBranch(
          id: item.id,
          storeId: item.storeId,
          name: item.name,
          code: item.code,
          city: item.city,
          address: item.address,
          phone: item.phone,
          email: item.email,
          managerName: item.managerName,
          receiptPrefix: item.receiptPrefix,
          timezone: item.timezone,
          opensAt: item.opensAt,
          closesAt: item.closesAt,
          type: item.type,
          acceptsSales: item.acceptsSales,
          handlesService: item.handlesService,
          isMain: false,
          isActive: item.isActive,
          createdAt: item.createdAt,
        );
      }
    }
    if (index >= 0) {
      _branches[index] = branch;
    } else {
      _branches.add(branch);
    }
    return branch;
  }

  @override
  Future<List<CustomerProfile>> loadCustomers(String storeId) async => [
    ..._customers,
  ];

  @override
  Future<CustomerProfile> saveCustomer({
    required String storeId,
    String? customerId,
    required String name,
    required String phone,
    required String email,
    required String notes,
  }) async {
    final byId = customerId == null
        ? -1
        : _customers.indexWhere((item) => item.id == customerId);
    final byPhone = _customers.indexWhere(
      (item) => item.phone.trim() == phone.trim(),
    );
    final index = byId >= 0 ? byId : byPhone;
    final now = DateTime.now();
    final customer = CustomerProfile(
      id: index >= 0 ? _customers[index].id : _uuid.v4(),
      storeId: storeId,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
      notes: notes.trim(),
      createdAt: index >= 0 ? _customers[index].createdAt : now,
      updatedAt: now,
    );
    if (index >= 0) {
      _customers[index] = customer;
    } else {
      _customers.insert(0, customer);
    }
    return customer;
  }

  @override
  Future<List<Product>> loadProducts(String storeId) async => [..._products];

  @override
  Future<Product> createProduct({
    required String storeId,
    required String name,
    required String brand,
    required String category,
    required String barcode,
    required String sku,
    required int warrantyMonths,
    required num? salePrice,
    required num? costPrice,
    required bool trackInventory,
    required bool isSerialized,
    required num reorderPoint,
  }) async {
    final product = Product(
      id: _uuid.v4(),
      storeId: storeId,
      name: name.trim(),
      brand: brand.trim(),
      category: category.trim(),
      barcode: barcode.trim(),
      sku: sku.trim(),
      warrantyMonths: warrantyMonths,
      salePrice: salePrice,
      costPrice: costPrice,
      trackInventory: trackInventory,
      isSerialized: isSerialized,
      reorderPoint: reorderPoint,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _products.insert(0, product);
    for (final branch in _branches) {
      _inventory.add(
        InventoryLevel(
          id: _uuid.v4(),
          storeId: storeId,
          branchId: branch.id,
          productId: product.id,
          onHand: 0,
          reserved: 0,
          reorderPoint: reorderPoint,
          averageCost: costPrice ?? 0,
          updatedAt: DateTime.now(),
        ),
      );
    }
    return product;
  }

  @override
  Future<Product> updateProduct({
    required String productId,
    required String storeId,
    required String name,
    required String brand,
    required String category,
    required String barcode,
    required String sku,
    required int warrantyMonths,
    required num? salePrice,
    required num? costPrice,
    required bool trackInventory,
    required bool isSerialized,
    required num reorderPoint,
    required bool isActive,
  }) async {
    final index = _products.indexWhere((item) => item.id == productId);
    if (index < 0) throw StateError('PRODUCT_NOT_FOUND');
    final current = _products[index];
    final product = Product(
      id: productId,
      storeId: storeId,
      name: name.trim(),
      brand: brand.trim(),
      category: category.trim(),
      barcode: barcode.trim(),
      sku: sku.trim(),
      warrantyMonths: warrantyMonths,
      salePrice: salePrice,
      costPrice: costPrice,
      trackInventory: trackInventory,
      isSerialized: isSerialized,
      reorderPoint: reorderPoint,
      isActive: isActive,
      createdAt: current.createdAt,
    );
    _products[index] = product;
    return product;
  }

  @override
  Future<List<InventoryLevel>> loadInventory(String storeId) async => [
    ..._inventory,
  ];

  @override
  Future<List<StockMovement>> loadStockMovements(String storeId) async => [
    ..._stockMovements,
  ];

  @override
  Future<InventoryLevel> adjustInventory({
    required String storeId,
    required String branchId,
    required String productId,
    required num newQuantity,
    required num unitCost,
    required String note,
  }) async {
    if (newQuantity < 0) throw StateError('NEGATIVE_STOCK');
    final index = _inventory.indexWhere(
      (item) => item.branchId == branchId && item.productId == productId,
    );
    final current = index >= 0 ? _inventory[index] : null;
    final updated = InventoryLevel(
      id: current?.id ?? _uuid.v4(),
      storeId: storeId,
      branchId: branchId,
      productId: productId,
      onHand: newQuantity,
      reserved: current?.reserved ?? 0,
      reorderPoint:
          current?.reorderPoint ??
          _products.firstWhere((item) => item.id == productId).reorderPoint,
      averageCost: unitCost > 0 ? unitCost : current?.averageCost ?? 0,
      updatedAt: DateTime.now(),
    );
    if (index >= 0) {
      _inventory[index] = updated;
    } else {
      _inventory.add(updated);
    }
    final delta = newQuantity - (current?.onHand ?? 0);
    _recordMovement(
      storeId: storeId,
      productId: productId,
      branchId: branchId,
      type: current == null
          ? StockMovementType.opening
          : StockMovementType.adjustment,
      quantity: delta,
      unitCost: updated.averageCost,
      note: note,
    );
    return updated;
  }

  @override
  Future<void> transferInventory({
    required String storeId,
    required String productId,
    required String fromBranchId,
    required String toBranchId,
    required num quantity,
    required String note,
  }) async {
    if (quantity <= 0 || fromBranchId == toBranchId) {
      throw StateError('INVALID_TRANSFER');
    }
    final fromIndex = _inventory.indexWhere(
      (item) => item.branchId == fromBranchId && item.productId == productId,
    );
    if (fromIndex < 0 || _inventory[fromIndex].available < quantity) {
      throw StateError('INSUFFICIENT_STOCK');
    }
    var toIndex = _inventory.indexWhere(
      (item) => item.branchId == toBranchId && item.productId == productId,
    );
    final from = _inventory[fromIndex];
    final product = _products.firstWhere((item) => item.id == productId);
    if (toIndex < 0) {
      _inventory.add(
        InventoryLevel(
          id: _uuid.v4(),
          storeId: storeId,
          branchId: toBranchId,
          productId: productId,
          onHand: 0,
          reserved: 0,
          reorderPoint: product.reorderPoint,
          averageCost: from.averageCost,
          updatedAt: DateTime.now(),
        ),
      );
      toIndex = _inventory.length - 1;
    }
    final to = _inventory[toIndex];
    _inventory[fromIndex] = from.copyWith(
      onHand: from.onHand - quantity,
      updatedAt: DateTime.now(),
    );
    _inventory[toIndex] = to.copyWith(
      onHand: to.onHand + quantity,
      averageCost: from.averageCost,
      updatedAt: DateTime.now(),
    );
    final reference = _uuid.v4();
    _recordMovement(
      storeId: storeId,
      productId: productId,
      branchId: fromBranchId,
      type: StockMovementType.transferOut,
      quantity: -quantity,
      unitCost: from.averageCost,
      note: note,
      referenceId: reference,
    );
    _recordMovement(
      storeId: storeId,
      productId: productId,
      branchId: toBranchId,
      type: StockMovementType.transferIn,
      quantity: quantity,
      unitCost: from.averageCost,
      note: note,
      referenceId: reference,
    );
  }

  void _recordMovement({
    required String storeId,
    required String productId,
    required String branchId,
    required StockMovementType type,
    required num quantity,
    required num unitCost,
    required String note,
    String referenceType = '',
    String referenceId = '',
  }) {
    _stockMovements.insert(
      0,
      StockMovement(
        id: _uuid.v4(),
        storeId: storeId,
        productId: productId,
        branchId: branchId,
        type: type,
        quantity: quantity,
        unitCost: unitCost,
        referenceType: referenceType,
        referenceId: referenceId,
        note: note.trim(),
        createdBy: _account.id,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<SaleTransaction>> loadSales(String storeId) async => [..._sales];

  @override
  Future<SaleTransaction> createSale({
    required String storeId,
    required String branchId,
    required String? customerId,
    required String customerName,
    required String customerPhone,
    required List<SaleLineInput> lines,
    required List<SalePayment> payments,
    required num orderDiscount,
    required String notes,
  }) async {
    if (lines.isEmpty) throw StateError('EMPTY_CART');
    final branch = _branches.firstWhere((item) => item.id == branchId);
    if (!branch.acceptsSales) throw StateError('BRANCH_SALES_DISABLED');
    final currency = _store.currencyCode;
    final rawSubtotal = lines.fold<num>(
      0,
      (total, line) => total + line.unitPrice * line.quantity,
    );
    final lineDiscounts = lines.fold<num>(
      0,
      (total, line) => total + line.discountAmount,
    );
    final afterLineDiscount = rawSubtotal - lineDiscounts;
    if (orderDiscount < 0 || orderDiscount > afterLineDiscount) {
      throw StateError('INVALID_DISCOUNT');
    }
    final taxable = afterLineDiscount - orderDiscount;
    final tax = _store.pricesIncludeTax
        ? taxable * _store.taxRate / (100 + _store.taxRate)
        : taxable * _store.taxRate / 100;
    final total = roundMoney(
      _store.pricesIncludeTax ? taxable : taxable + tax,
      currency,
    );
    final paid = payments.fold<num>(0, (sum, item) => sum + item.amount);
    if ((paid - total).abs() > 0.01) throw StateError('PAYMENT_MISMATCH');

    for (final input in lines) {
      final product = _products.firstWhere(
        (item) => item.id == input.productId,
      );
      if (!product.trackInventory) continue;
      final inventory = _inventory.firstWhere(
        (item) =>
            item.branchId == branchId && item.productId == input.productId,
        orElse: () => throw StateError('INSUFFICIENT_STOCK'),
      );
      if (inventory.available < input.quantity) {
        throw StateError('INSUFFICIENT_STOCK');
      }
      if (product.isSerialized &&
          input.serialNumbers.length != input.quantity.toInt()) {
        throw StateError('SERIALS_REQUIRED');
      }
    }

    final saleId = _uuid.v4();
    final invoiceNumber =
        '${branch.receiptPrefix.isEmpty ? _store.invoicePrefix : branch.receiptPrefix}-${saleId.substring(0, 6).toUpperCase()}';
    final saleLines = <SaleLine>[];
    for (final input in lines) {
      final product = _products.firstWhere(
        (item) => item.id == input.productId,
      );
      final netBeforeOrder =
          input.unitPrice * input.quantity - input.discountAmount;
      final share = afterLineDiscount == 0
          ? 0
          : orderDiscount * netBeforeOrder / afterLineDiscount;
      final net = netBeforeOrder - share;
      final lineTax = _store.pricesIncludeTax
          ? net * _store.taxRate / (100 + _store.taxRate)
          : net * _store.taxRate / 100;
      final lineTotal = roundMoney(
        _store.pricesIncludeTax ? net : net + lineTax,
        currency,
      );
      final line = SaleLine(
        id: _uuid.v4(),
        productId: product.id,
        productName: product.name,
        sku: product.sku,
        barcode: product.barcode,
        quantity: input.quantity,
        returnedQuantity: 0,
        unitPrice: input.unitPrice,
        unitCost: product.costPrice ?? 0,
        discountAmount: roundMoney(input.discountAmount + share, currency),
        taxAmount: roundMoney(lineTax, currency),
        lineTotal: lineTotal,
        warrantyMonths: product.warrantyMonths,
        serialNumbers: input.serialNumbers,
      );
      saleLines.add(line);
      if (product.trackInventory) {
        final inventoryIndex = _inventory.indexWhere(
          (item) => item.branchId == branchId && item.productId == product.id,
        );
        final inventory = _inventory[inventoryIndex];
        _inventory[inventoryIndex] = inventory.copyWith(
          onHand: inventory.onHand - input.quantity,
          updatedAt: DateTime.now(),
        );
        _recordMovement(
          storeId: storeId,
          productId: product.id,
          branchId: branchId,
          type: StockMovementType.sale,
          quantity: -input.quantity,
          unitCost: inventory.averageCost,
          note: invoiceNumber,
          referenceType: 'sale',
          referenceId: saleId,
        );
      }
      if (product.warrantyMonths > 0 && customerPhone.trim().isNotEmpty) {
        for (var unit = 0; unit < input.quantity.toInt(); unit++) {
          final warrantyId = _uuid.v4();
          final createdAt = DateTime.now();
          _warranties.insert(
            0,
            Warranty(
              id: warrantyId,
              warrantyNumber: 'DMN-${warrantyId.substring(0, 6).toUpperCase()}',
              storeId: storeId,
              productId: product.id,
              customerId: customerId,
              branchId: branchId,
              customerName: customerName.trim(),
              customerPhone: customerPhone.trim(),
              productName: product.name,
              barcode: product.barcode,
              serialNumber: unit < input.serialNumbers.length
                  ? input.serialNumbers[unit]
                  : '',
              purchaseDate: createdAt,
              expiryDate: addMonths(createdAt, product.warrantyMonths),
              createdAt: createdAt,
              notes: notes.trim(),
              createdBy: _account.id,
              invoiceNumber: invoiceNumber,
              saleSubtotal: input.unitPrice,
              discountAmount: line.discountAmount / input.quantity,
              taxAmount: line.taxAmount / input.quantity,
              saleTotal: line.lineTotal / input.quantity,
              taxRate: _store.taxRate,
              currencyCode: currency,
              paymentMethod: payments.first.method,
            ),
          );
        }
      }
    }
    final sale = SaleTransaction(
      id: saleId,
      storeId: storeId,
      branchId: branchId,
      customerId: customerId ?? '',
      customerName: customerName.trim().isEmpty
          ? 'عميل نقدي'
          : customerName.trim(),
      customerPhone: customerPhone.trim(),
      invoiceNumber: invoiceNumber,
      status: SaleStatus.completed,
      subtotal: roundMoney(rawSubtotal, currency),
      discountAmount: roundMoney(lineDiscounts + orderDiscount, currency),
      taxAmount: roundMoney(tax, currency),
      total: total,
      refundedAmount: 0,
      currencyCode: currency,
      taxRate: _store.taxRate,
      pricesIncludeTax: _store.pricesIncludeTax,
      notes: notes.trim(),
      cashierId: _account.id,
      createdAt: DateTime.now(),
      lines: saleLines,
      payments: payments
          .map(
            (item) => SalePayment(
              id: _uuid.v4(),
              method: item.method,
              amount: item.amount,
              reference: item.reference,
            ),
          )
          .toList(),
    );
    _sales.insert(0, sale);
    return sale;
  }

  @override
  Future<SaleTransaction> returnSale({
    required String storeId,
    required String saleId,
    required Map<String, num> lineQuantities,
    required PaymentMethod refundMethod,
    required String reason,
  }) async {
    final saleIndex = _sales.indexWhere((item) => item.id == saleId);
    if (saleIndex < 0) throw StateError('SALE_NOT_FOUND');
    final current = _sales[saleIndex];
    var refund = 0.0;
    final updatedLines = <SaleLine>[];
    for (final line in current.lines) {
      final quantity = lineQuantities[line.id] ?? 0;
      if (quantity < 0 || quantity > line.returnableQuantity) {
        throw StateError('INVALID_RETURN_QUANTITY');
      }
      if (quantity > 0) {
        refund += (line.lineTotal / line.quantity * quantity).toDouble();
        final inventoryIndex = _inventory.indexWhere(
          (item) =>
              item.branchId == current.branchId &&
              item.productId == line.productId,
        );
        if (inventoryIndex >= 0) {
          final inventory = _inventory[inventoryIndex];
          _inventory[inventoryIndex] = inventory.copyWith(
            onHand: inventory.onHand + quantity,
            updatedAt: DateTime.now(),
          );
          _recordMovement(
            storeId: storeId,
            productId: line.productId,
            branchId: current.branchId,
            type: StockMovementType.returnIn,
            quantity: quantity,
            unitCost: line.unitCost,
            note: reason,
            referenceType: 'sale_return',
            referenceId: saleId,
          );
        }
      }
      updatedLines.add(
        SaleLine(
          id: line.id,
          productId: line.productId,
          productName: line.productName,
          sku: line.sku,
          barcode: line.barcode,
          quantity: line.quantity,
          returnedQuantity: line.returnedQuantity + quantity,
          unitPrice: line.unitPrice,
          unitCost: line.unitCost,
          discountAmount: line.discountAmount,
          taxAmount: line.taxAmount,
          lineTotal: line.lineTotal,
          warrantyMonths: line.warrantyMonths,
          serialNumbers: line.serialNumbers,
        ),
      );
    }
    if (refund <= 0) throw StateError('EMPTY_RETURN');
    final allReturned = updatedLines.every(
      (line) => line.returnedQuantity >= line.quantity,
    );
    final updated = SaleTransaction(
      id: current.id,
      storeId: current.storeId,
      branchId: current.branchId,
      customerId: current.customerId,
      customerName: current.customerName,
      customerPhone: current.customerPhone,
      invoiceNumber: current.invoiceNumber,
      status: allReturned ? SaleStatus.returned : SaleStatus.partiallyReturned,
      subtotal: current.subtotal,
      discountAmount: current.discountAmount,
      taxAmount: current.taxAmount,
      total: current.total,
      refundedAmount: roundMoney(
        current.refundedAmount + refund,
        current.currencyCode,
      ),
      currencyCode: current.currencyCode,
      taxRate: current.taxRate,
      pricesIncludeTax: current.pricesIncludeTax,
      notes: current.notes,
      cashierId: current.cashierId,
      createdAt: current.createdAt,
      lines: updatedLines,
      payments: current.payments,
    );
    _sales[saleIndex] = updated;
    if (allReturned) {
      _warranties.removeWhere(
        (item) => item.invoiceNumber == current.invoiceNumber,
      );
    }
    return updated;
  }

  @override
  Future<List<CashRegisterSession>> loadRegisterSessions(
    String storeId,
  ) async => [..._registerSessions];

  @override
  Future<CashRegisterSession> openRegister({
    required String storeId,
    required String branchId,
    required num openingCash,
    required String notes,
  }) async {
    if (_registerSessions.any(
      (item) => item.branchId == branchId && item.status == RegisterStatus.open,
    )) {
      throw StateError('REGISTER_ALREADY_OPEN');
    }
    final session = CashRegisterSession(
      id: _uuid.v4(),
      storeId: storeId,
      branchId: branchId,
      openedBy: _account.id,
      closedBy: '',
      openingCash: openingCash,
      cashSales: 0,
      cashRefunds: 0,
      cashIn: 0,
      cashOut: 0,
      closingCash: 0,
      status: RegisterStatus.open,
      openedAt: DateTime.now(),
      closedAt: null,
      notes: notes.trim(),
    );
    _registerSessions.insert(0, session);
    return session;
  }

  @override
  Future<CashRegisterSession> closeRegister({
    required String sessionId,
    required num closingCash,
    required String notes,
  }) async {
    final index = _registerSessions.indexWhere((item) => item.id == sessionId);
    if (index < 0) throw StateError('REGISTER_NOT_FOUND');
    final current = _registerSessions[index];
    final cashSales = _sales
        .where(
          (sale) =>
              sale.branchId == current.branchId &&
              sale.createdAt.isAfter(current.openedAt),
        )
        .expand((sale) => sale.payments)
        .where((payment) => payment.method == PaymentMethod.cash)
        .fold<num>(0, (sum, payment) => sum + payment.amount);
    final closed = CashRegisterSession(
      id: current.id,
      storeId: current.storeId,
      branchId: current.branchId,
      openedBy: current.openedBy,
      closedBy: _account.id,
      openingCash: current.openingCash,
      cashSales: cashSales,
      cashRefunds: current.cashRefunds,
      cashIn: current.cashIn,
      cashOut: current.cashOut,
      closingCash: closingCash,
      status: RegisterStatus.closed,
      openedAt: current.openedAt,
      closedAt: DateTime.now(),
      notes: notes.trim().isEmpty ? current.notes : notes.trim(),
    );
    _registerSessions[index] = closed;
    return closed;
  }

  @override
  Future<List<Supplier>> loadSuppliers(String storeId) async => [..._suppliers];

  @override
  Future<Supplier> saveSupplier({
    required String storeId,
    String? supplierId,
    required String name,
    required String contactName,
    required String phone,
    required String email,
    required String taxNumber,
    required String address,
    required String notes,
  }) async {
    final index = supplierId == null
        ? -1
        : _suppliers.indexWhere((item) => item.id == supplierId);
    final supplier = Supplier(
      id: supplierId ?? _uuid.v4(),
      storeId: storeId,
      name: name.trim(),
      contactName: contactName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      taxNumber: taxNumber.trim(),
      address: address.trim(),
      notes: notes.trim(),
      isActive: true,
      createdAt: index >= 0 ? _suppliers[index].createdAt : DateTime.now(),
    );
    if (index >= 0) {
      _suppliers[index] = supplier;
    } else {
      _suppliers.insert(0, supplier);
    }
    return supplier;
  }

  @override
  Future<List<PurchaseOrder>> loadPurchaseOrders(String storeId) async => [
    ..._purchaseOrders,
  ];

  @override
  Future<PurchaseOrder> createPurchaseOrder({
    required String storeId,
    required String branchId,
    required String supplierId,
    required DateTime? expectedAt,
    required String notes,
    required List<PurchaseOrderLineInput> lines,
  }) async {
    if (lines.isEmpty) throw StateError('EMPTY_PURCHASE_ORDER');
    final id = _uuid.v4();
    final order = PurchaseOrder(
      id: id,
      storeId: storeId,
      branchId: branchId,
      supplierId: supplierId,
      orderNumber: 'PO-${id.substring(0, 6).toUpperCase()}',
      status: PurchaseOrderStatus.ordered,
      expectedAt: expectedAt,
      notes: notes.trim(),
      totalCost: lines.fold<num>(
        0,
        (sum, item) => sum + item.quantity * item.unitCost,
      ),
      createdAt: DateTime.now(),
      lines: lines
          .map(
            (item) => PurchaseOrderLine(
              id: _uuid.v4(),
              productId: item.productId,
              productName: _products
                  .firstWhere((product) => product.id == item.productId)
                  .name,
              quantity: item.quantity,
              receivedQuantity: 0,
              unitCost: item.unitCost,
            ),
          )
          .toList(),
    );
    _purchaseOrders.insert(0, order);
    return order;
  }

  @override
  Future<PurchaseOrder> receivePurchaseOrder(String purchaseOrderId) async {
    final index = _purchaseOrders.indexWhere(
      (item) => item.id == purchaseOrderId,
    );
    if (index < 0) throw StateError('PURCHASE_ORDER_NOT_FOUND');
    final current = _purchaseOrders[index];
    final receivedLines = <PurchaseOrderLine>[];
    for (final line in current.lines) {
      final remaining = line.quantity - line.receivedQuantity;
      if (remaining > 0) {
        final inventoryIndex = _inventory.indexWhere(
          (item) =>
              item.branchId == current.branchId &&
              item.productId == line.productId,
        );
        if (inventoryIndex >= 0) {
          final inventory = _inventory[inventoryIndex];
          final newOnHand = inventory.onHand + remaining;
          final weightedCost = newOnHand == 0
              ? line.unitCost
              : ((inventory.onHand * inventory.averageCost) +
                        (remaining * line.unitCost)) /
                    newOnHand;
          _inventory[inventoryIndex] = inventory.copyWith(
            onHand: newOnHand,
            averageCost: weightedCost,
            updatedAt: DateTime.now(),
          );
        }
        _recordMovement(
          storeId: current.storeId,
          productId: line.productId,
          branchId: current.branchId,
          type: StockMovementType.purchase,
          quantity: remaining,
          unitCost: line.unitCost,
          note: current.orderNumber,
          referenceType: 'purchase_order',
          referenceId: current.id,
        );
      }
      receivedLines.add(
        PurchaseOrderLine(
          id: line.id,
          productId: line.productId,
          productName: line.productName,
          quantity: line.quantity,
          receivedQuantity: line.quantity,
          unitCost: line.unitCost,
        ),
      );
    }
    final received = PurchaseOrder(
      id: current.id,
      storeId: current.storeId,
      branchId: current.branchId,
      supplierId: current.supplierId,
      orderNumber: current.orderNumber,
      status: PurchaseOrderStatus.received,
      expectedAt: current.expectedAt,
      notes: current.notes,
      totalCost: current.totalCost,
      createdAt: current.createdAt,
      lines: receivedLines,
    );
    _purchaseOrders[index] = received;
    return received;
  }

  @override
  Future<List<Warranty>> loadWarranties(String storeId) async => [
    ..._warranties,
  ];

  @override
  Future<Warranty> createWarranty({
    required String storeId,
    required String? productId,
    required String customerId,
    required String? branchId,
    required String customerName,
    required String customerPhone,
    required String productName,
    required String barcode,
    required String serialNumber,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required String notes,
    required String invoiceNumber,
    required num saleSubtotal,
    required num discountAmount,
    required num taxAmount,
    required num saleTotal,
    required num taxRate,
    required String currencyCode,
    required PaymentMethod paymentMethod,
  }) async {
    final id = _uuid.v4();
    final warranty = Warranty(
      id: id,
      warrantyNumber: 'DMN-${id.substring(0, 6).toUpperCase()}',
      storeId: storeId,
      productId: productId,
      customerId: customerId,
      branchId: branchId,
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      productName: productName.trim(),
      barcode: barcode.trim(),
      serialNumber: serialNumber.trim(),
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      createdAt: DateTime.now(),
      notes: notes.trim(),
      createdBy: _account.id,
      invoiceNumber: invoiceNumber.trim().isEmpty
          ? '${_store.invoicePrefix}-${id.substring(0, 6).toUpperCase()}'
          : invoiceNumber.trim(),
      saleSubtotal: saleSubtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      saleTotal: saleTotal,
      taxRate: taxRate,
      currencyCode: currencyCode,
      paymentMethod: paymentMethod,
    );
    _warranties.insert(0, warranty);
    _subscription = SubscriptionInfo(
      id: _subscription.id,
      status: _subscription.status,
      plan: _subscription.plan,
      trialEndsAt: _subscription.trialEndsAt,
      periodEndsAt: _subscription.periodEndsAt,
      usedWarranties: _subscription.usedWarranties + 1,
      source: _subscription.source,
      billingProvider: _subscription.billingProvider,
      storeProductId: _subscription.storeProductId,
      billingCycle: _subscription.billingCycle,
      autoRenews: _subscription.autoRenews,
      lastVerifiedAt: _subscription.lastVerifiedAt,
    );
    return warranty;
  }

  @override
  Future<void> deleteWarranty(String id) async {
    _warranties.removeWhere((item) => item.id == id);
    _requests.removeWhere((item) => item.warrantyId == id);
  }

  @override
  Future<List<MaintenanceRequest>> loadRequests(String storeId) async => [
    ..._requests,
  ];

  @override
  Future<MaintenanceRequest> createRequest({
    required String storeId,
    required String warrantyId,
    required String issue,
  }) async {
    final request = MaintenanceRequest(
      id: _uuid.v4(),
      storeId: storeId,
      warrantyId: warrantyId,
      issue: issue.trim(),
      status: MaintenanceStatus.newRequest,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: _account.id,
    );
    _requests.insert(0, request);
    return request;
  }

  @override
  Future<void> updateRequestStatus(
    String requestId,
    MaintenanceStatus status,
  ) async {
    final index = _requests.indexWhere((item) => item.id == requestId);
    if (index >= 0) {
      _requests[index] = _requests[index].copyWith(status: status);
    }
  }

  @override
  Future<List<TeamMember>> loadTeam(String storeId) async => [..._members];

  @override
  Future<StoreInvite> createInvite({
    required String storeId,
    required MemberRole role,
    required int maxUses,
  }) async {
    return StoreInvite(
      code:
          'DMN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      role: role,
      expiresAt: DateTime.now().add(const Duration(days: 2)),
      maxUses: maxUses,
    );
  }

  @override
  Future<void> updateMember({
    required String storeId,
    required String userId,
    required MemberRole role,
    required bool active,
  }) async {
    final index = _members.indexWhere((item) => item.userId == userId);
    if (index < 0) {
      return;
    }
    final member = _members[index];
    _members[index] = TeamMember(
      userId: member.userId,
      fullName: member.fullName,
      email: member.email,
      role: role,
      status: active ? 'active' : 'suspended',
      joinedAt: member.joinedAt,
    );
  }

  @override
  Future<List<AuditEvent>> loadAuditLogs(String storeId) async => [
    ..._auditLogs,
  ];

  @override
  Future<List<PlanInfo>> loadPlans() async => const [
    PlanInfo(
      id: 'starter',
      name: 'بداية',
      monthlyPrice: 39,
      yearlyPrice: 390,
      maxMembers: 2,
      monthlyWarranties: 60,
    ),
    _plan,
    PlanInfo(
      id: 'scale',
      name: 'توسع',
      monthlyPrice: 199,
      yearlyPrice: 1990,
      maxMembers: 15,
      monthlyWarranties: 1200,
    ),
  ];

  @override
  Future<SubscriptionInfo> verifyStorePurchase({
    required String storeId,
    required StorePurchaseReceipt receipt,
  }) => throw StateError('STORE_VERIFICATION_REQUIRES_CLOUD');

  @override
  Future<SubscriptionInfo> refreshStoreSubscription(String storeId) =>
      throw StateError('STORE_VERIFICATION_REQUIRES_CLOUD');
}
