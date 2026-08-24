import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/damanak_repository.dart';
import '../data/demo_repository.dart';
import '../models/account.dart';
import '../models/audit_event.dart';
import '../models/branch.dart';
import '../models/customer.dart';
import '../models/inventory.dart';
import '../models/maintenance_request.dart';
import '../models/product.dart';
import '../models/register.dart';
import '../models/sale.dart';
import '../models/store_profile.dart';
import '../models/subscription.dart';
import '../models/supplier.dart';
import '../models/warranty.dart';

class AppController extends ChangeNotifier {
  AppController.withRepository(DamanakRepository repository)
    : _repository = repository;

  AppController.unconfigured();

  DamanakRepository? _repository;
  AppStage _stage = AppStage.configuring;
  AccountIdentity? _account;
  StoreWorkspace? _store;
  StoreMembership? _membership;
  SubscriptionInfo? _subscription;
  final List<Product> _products = [];
  final List<StoreBranch> _branches = [];
  final List<CustomerProfile> _customers = [];
  final List<InventoryLevel> _inventory = [];
  final List<StockMovement> _stockMovements = [];
  final List<SaleTransaction> _sales = [];
  final List<CashRegisterSession> _registerSessions = [];
  final List<Supplier> _suppliers = [];
  final List<PurchaseOrder> _purchaseOrders = [];
  final List<Warranty> _warranties = [];
  final List<MaintenanceRequest> _requests = [];
  final List<TeamMember> _team = [];
  final List<PlanInfo> _plans = [];
  final List<AuditEvent> _auditLogs = [];
  bool _busy = false;
  String? _errorMessage;
  String? _noticeMessage;
  String? _activeBranchId;

  AppStage get stage => _stage;
  AccountIdentity? get account => _account;
  StoreWorkspace? get store => _store;
  StoreMembership? get membership => _membership;
  SubscriptionInfo? get subscription => _subscription;
  bool get busy => _busy;
  bool get isDemo => _repository?.isDemo ?? false;
  bool get backendConfigured => _repository != null;
  String? get errorMessage => _errorMessage;
  String? get noticeMessage => _noticeMessage;
  StoreProfile get profile => StoreProfile(
    name: _store?.name ?? 'متجر ضمانك',
    phone: _store?.phone ?? '',
    city: _store?.city ?? '',
    address: _store?.address ?? '',
    countryCode: _store?.countryCode ?? 'SA',
    currencyCode: _store?.currencyCode ?? 'SAR',
    taxRate: _store?.taxRate ?? 15,
    pricesIncludeTax: _store?.pricesIncludeTax ?? true,
    taxNumber: _store?.taxNumber ?? '',
    commercialRegistration: _store?.commercialRegistration ?? '',
    invoicePrefix: _store?.invoicePrefix ?? 'INV',
  );
  UnmodifiableListView<Product> get products => UnmodifiableListView(_products);
  UnmodifiableListView<StoreBranch> get branches =>
      UnmodifiableListView(_branches);
  UnmodifiableListView<CustomerProfile> get customers =>
      UnmodifiableListView(_customers);
  UnmodifiableListView<InventoryLevel> get inventory =>
      UnmodifiableListView(_inventory);
  UnmodifiableListView<StockMovement> get stockMovements =>
      UnmodifiableListView(_stockMovements);
  UnmodifiableListView<SaleTransaction> get sales =>
      UnmodifiableListView(_sales);
  UnmodifiableListView<CashRegisterSession> get registerSessions =>
      UnmodifiableListView(_registerSessions);
  UnmodifiableListView<Supplier> get suppliers =>
      UnmodifiableListView(_suppliers);
  UnmodifiableListView<PurchaseOrder> get purchaseOrders =>
      UnmodifiableListView(_purchaseOrders);
  UnmodifiableListView<Warranty> get warranties =>
      UnmodifiableListView(_warranties);
  UnmodifiableListView<MaintenanceRequest> get requests =>
      UnmodifiableListView(_requests);
  UnmodifiableListView<TeamMember> get team => UnmodifiableListView(_team);
  UnmodifiableListView<PlanInfo> get plans => UnmodifiableListView(_plans);
  UnmodifiableListView<AuditEvent> get auditLogs =>
      UnmodifiableListView(_auditLogs);

  StoreBranch? get activeBranch {
    final preferred = _activeBranchId;
    if (preferred != null) {
      for (final branch in _branches) {
        if (branch.id == preferred) return branch;
      }
    }
    for (final branch in _branches) {
      if (branch.isMain) return branch;
    }
    return _branches.firstOrNull;
  }

  num get totalSales => _sales.isNotEmpty
      ? _sales.fold<num>(0, (total, sale) => total + sale.netTotal)
      : _warranties.fold<num>(
          0,
          (total, warranty) => total + warranty.saleTotal,
        );
  num get totalTax => _sales.isNotEmpty
      ? _sales.fold<num>(0, (total, sale) => total + sale.taxAmount)
      : _warranties.fold<num>(
          0,
          (total, warranty) => total + warranty.taxAmount,
        );
  num get currentMonthSales {
    final now = DateTime.now();
    if (_sales.isNotEmpty) {
      return _sales
          .where(
            (item) =>
                item.createdAt.year == now.year &&
                item.createdAt.month == now.month,
          )
          .fold<num>(0, (total, item) => total + item.netTotal);
    }
    return _warranties
        .where(
          (item) =>
              item.createdAt.year == now.year &&
              item.createdAt.month == now.month,
        )
        .fold<num>(0, (total, item) => total + item.saleTotal);
  }

  Future<void> initialize() async {
    if (_repository == null) {
      _stage = AppStage.configuring;
      notifyListeners();
      return;
    }
    await _guard(() async {
      _account = await _repository!.restoreAccount();
      if (_account == null) {
        _stage = AppStage.signedOut;
        return;
      }
      await _loadWorkspace();
    });
  }

  Future<void> startDemo() async {
    _repository = DemoDamanakRepository();
    _clearData();
    await initialize();
  }

  Future<void> signIn({required String email, required String password}) async {
    await _guard(() async {
      _account = await _repository!.signIn(email: email, password: password);
      await _loadWorkspace();
    });
  }

  Future<void> signInWithSocial(SocialAuthProvider provider) async {
    await _guard(() async {
      await _repository!.signInWithSocial(provider);
      _noticeMessage = 'أكمل تسجيل الدخول في النافذة الآمنة ثم عد إلى ضمانك.';
    });
  }

  Future<void> deleteAccount() async {
    await _guard(() async {
      await _repository!.deleteAccount();
      final wasDemo = isDemo;
      _clearData();
      if (wasDemo) {
        _repository = null;
        _stage = AppStage.configuring;
      } else {
        _stage = AppStage.signedOut;
      }
    });
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    var needsConfirmation = false;
    await _guard(() async {
      final result = await _repository!.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      needsConfirmation = result.needsConfirmation;
      if (needsConfirmation) {
        _noticeMessage =
            'أرسلنا رابط تأكيد إلى بريدك. أكّد البريد ثم سجّل الدخول.';
        _stage = AppStage.signedOut;
      } else {
        _account = result.account;
        _stage = AppStage.onboarding;
      }
    });
    return needsConfirmation;
  }

  Future<void> signOut() async {
    await _guard(() async {
      await _repository!.signOut();
      final wasDemo = isDemo;
      _clearData();
      if (wasDemo) {
        _repository = null;
        _stage = AppStage.configuring;
      } else {
        _stage = AppStage.signedOut;
      }
    });
  }

  Future<void> sendPasswordReset(String email) async {
    await _guard(() async {
      await _repository!.sendPasswordReset(email);
      _noticeMessage = 'أرسلنا رابط استعادة كلمة المرور إلى بريدك.';
    });
  }

  Future<void> createStore({
    required String name,
    required String phone,
    required String city,
    required String countryCode,
  }) async {
    await _guard(() async {
      final snapshot = await _repository!.createStore(
        name: name,
        phone: phone,
        city: city,
        countryCode: countryCode,
      );
      _applySnapshot(snapshot);
      await _loadWorkspaceData();
      _stage = AppStage.ready;
    });
  }

  Future<void> joinStore(String code) async {
    await _guard(() async {
      final snapshot = await _repository!.joinStore(code);
      _applySnapshot(snapshot);
      await _loadWorkspaceData();
      _stage = AppStage.ready;
    });
  }

  Future<void> updateStore({
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
    await _guard(() async {
      _store = await _repository!.updateStore(
        storeId: _store!.id,
        name: name,
        phone: phone,
        city: city,
        countryCode: countryCode,
        currencyCode: currencyCode,
        taxRate: taxRate,
        pricesIncludeTax: pricesIncludeTax,
        taxNumber: taxNumber,
        commercialRegistration: commercialRegistration,
        address: address,
        invoicePrefix: invoicePrefix,
        defaultWarrantyMonths: defaultWarrantyMonths,
      );
      _noticeMessage = 'تم حفظ بيانات المتجر.';
    });
  }

  Future<void> refresh() async {
    if (_store == null) return;
    await _guard(_loadWorkspace);
  }

  Product? productByBarcode(String value) {
    final normalized = value.trim();
    for (final item in _products) {
      if (item.barcode == normalized) return item;
    }
    return null;
  }

  Product? productById(String id) {
    for (final item in _products) {
      if (item.id == id) return item;
    }
    return null;
  }

  InventoryLevel? inventoryLevel(String productId, [String? branchId]) {
    final selectedBranchId = branchId ?? activeBranch?.id;
    for (final item in _inventory) {
      if (item.productId == productId && item.branchId == selectedBranchId) {
        return item;
      }
    }
    return null;
  }

  CashRegisterSession? openRegisterForBranch([String? branchId]) {
    final selectedBranchId = branchId ?? activeBranch?.id;
    for (final item in _registerSessions) {
      if (item.branchId == selectedBranchId &&
          item.status == RegisterStatus.open) {
        return item;
      }
    }
    return null;
  }

  void selectBranch(String branchId) {
    if (_activeBranchId == branchId) return;
    _activeBranchId = branchId;
    notifyListeners();
  }

  Future<Product?> addProduct({
    required String name,
    required String brand,
    String category = '',
    required String barcode,
    required String sku,
    required int warrantyMonths,
    required num? salePrice,
    num? costPrice,
    bool trackInventory = true,
    bool isSerialized = false,
    num reorderPoint = 2,
  }) async {
    Product? created;
    await _guard(() async {
      created = await _repository!.createProduct(
        storeId: _store!.id,
        name: name,
        brand: brand,
        category: category,
        barcode: barcode,
        sku: sku,
        warrantyMonths: warrantyMonths,
        salePrice: salePrice,
        costPrice: costPrice,
        trackInventory: trackInventory,
        isSerialized: isSerialized,
        reorderPoint: reorderPoint,
      );
      _products.insert(0, created!);
    });
    return created;
  }

  Future<Product?> updateProduct({
    required String productId,
    required String name,
    required String brand,
    required String category,
    required String barcode,
    required String sku,
    required int warrantyMonths,
    required num? salePrice,
    num? costPrice,
    bool trackInventory = true,
    bool isSerialized = false,
    num reorderPoint = 2,
    bool isActive = true,
  }) async {
    Product? updated;
    await _guard(() async {
      updated = await _repository!.updateProduct(
        productId: productId,
        storeId: _store!.id,
        name: name,
        brand: brand,
        category: category,
        barcode: barcode,
        sku: sku,
        warrantyMonths: warrantyMonths,
        salePrice: salePrice,
        costPrice: costPrice,
        trackInventory: trackInventory,
        isSerialized: isSerialized,
        reorderPoint: reorderPoint,
        isActive: isActive,
      );
      final index = _products.indexWhere((item) => item.id == productId);
      if (!isActive) {
        _products.removeWhere((item) => item.id == productId);
      } else if (index >= 0) {
        _products[index] = updated!;
      }
      _noticeMessage = isActive ? 'تم تحديث المنتج.' : 'تمت أرشفة المنتج.';
    });
    return updated;
  }

  List<Warranty> warrantiesByStatus(WarrantyStatus status) =>
      _warranties.where((item) => item.statusAt() == status).toList();

  Warranty? warrantyById(String id) {
    for (final item in _warranties) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<MaintenanceRequest> requestsForWarranty(String warrantyId) =>
      _requests.where((request) => request.warrantyId == warrantyId).toList();

  Future<Warranty?> addWarranty({
    String? customerId,
    String customerEmail = '',
    String customerNotes = '',
    String? branchId,
    String? productId,
    required String customerName,
    required String customerPhone,
    required String productName,
    String barcode = '',
    required String serialNumber,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required String notes,
    String invoiceNumber = '',
    num saleSubtotal = 0,
    num discountAmount = 0,
    num taxAmount = 0,
    num saleTotal = 0,
    num taxRate = 0,
    String currencyCode = 'SAR',
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    Warranty? created;
    await _guard(() async {
      final customer = await _repository!.saveCustomer(
        storeId: _store!.id,
        customerId: customerId,
        name: customerName,
        phone: customerPhone,
        email: customerEmail,
        notes: customerNotes,
      );
      final customerIndex = _customers.indexWhere(
        (item) => item.id == customer.id,
      );
      if (customerIndex >= 0) {
        _customers[customerIndex] = customer;
      } else {
        _customers.insert(0, customer);
      }
      created = await _repository!.createWarranty(
        storeId: _store!.id,
        productId: productId,
        customerId: customer.id,
        branchId: branchId,
        customerName: customerName,
        customerPhone: customerPhone,
        productName: productName,
        barcode: barcode,
        serialNumber: serialNumber,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        notes: notes,
        invoiceNumber: invoiceNumber,
        saleSubtotal: saleSubtotal,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
        saleTotal: saleTotal,
        taxRate: taxRate,
        currencyCode: currencyCode,
        paymentMethod: paymentMethod,
      );
      _warranties.insert(0, created!);
      final current = _subscription;
      if (current != null) {
        _subscription = SubscriptionInfo(
          id: current.id,
          status: current.status,
          plan: current.plan,
          trialEndsAt: current.trialEndsAt,
          periodEndsAt: current.periodEndsAt,
          usedWarranties: current.usedWarranties + 1,
        );
      }
    });
    return created;
  }

  Future<void> deleteWarranty(String id) async {
    await _guard(() async {
      await _repository!.deleteWarranty(id);
      _warranties.removeWhere((item) => item.id == id);
      _requests.removeWhere((item) => item.warrantyId == id);
    });
  }

  Future<MaintenanceRequest?> addMaintenanceRequest({
    required String warrantyId,
    required String issue,
  }) async {
    MaintenanceRequest? created;
    await _guard(() async {
      created = await _repository!.createRequest(
        storeId: _store!.id,
        warrantyId: warrantyId,
        issue: issue,
      );
      _requests.insert(0, created!);
    });
    return created;
  }

  Future<void> updateMaintenanceStatus(
    String requestId,
    MaintenanceStatus status,
  ) async {
    await _guard(() async {
      await _repository!.updateRequestStatus(requestId, status);
      final index = _requests.indexWhere((item) => item.id == requestId);
      if (index >= 0) {
        _requests[index] = _requests[index].copyWith(status: status);
      }
    });
  }

  Future<StoreInvite?> createInvite(MemberRole role, int maxUses) async {
    StoreInvite? invite;
    await _guard(() async {
      invite = await _repository!.createInvite(
        storeId: _store!.id,
        role: role,
        maxUses: maxUses,
      );
    });
    return invite;
  }

  Future<void> updateMember({
    required String userId,
    required MemberRole role,
    required bool active,
  }) async {
    await _guard(() async {
      await _repository!.updateMember(
        storeId: _store!.id,
        userId: userId,
        role: role,
        active: active,
      );
      _team
        ..clear()
        ..addAll(await _repository!.loadTeam(_store!.id));
    });
  }

  Future<CustomerProfile?> saveCustomer({
    String? customerId,
    required String name,
    required String phone,
    required String email,
    required String notes,
  }) async {
    CustomerProfile? saved;
    await _guard(() async {
      saved = await _repository!.saveCustomer(
        storeId: _store!.id,
        customerId: customerId,
        name: name,
        phone: phone,
        email: email,
        notes: notes,
      );
      final index = _customers.indexWhere((item) => item.id == saved!.id);
      if (index >= 0) {
        _customers[index] = saved!;
      } else {
        _customers.insert(0, saved!);
      }
    });
    return saved;
  }

  Future<StoreBranch?> saveBranch({
    String? branchId,
    required String name,
    required String code,
    required String city,
    required String address,
    required String phone,
    required bool isMain,
    String email = '',
    String managerName = '',
    String receiptPrefix = 'POS',
    String timezone = 'Asia/Riyadh',
    String opensAt = '09:00',
    String closesAt = '23:00',
    BranchType type = BranchType.retail,
    bool acceptsSales = true,
    bool handlesService = true,
  }) async {
    StoreBranch? saved;
    await _guard(() async {
      saved = await _repository!.saveBranch(
        storeId: _store!.id,
        branchId: branchId,
        name: name,
        code: code,
        city: city,
        address: address,
        phone: phone,
        isMain: isMain,
        email: email,
        managerName: managerName,
        receiptPrefix: receiptPrefix,
        timezone: timezone,
        opensAt: opensAt,
        closesAt: closesAt,
        type: type,
        acceptsSales: acceptsSales,
        handlesService: handlesService,
      );
      _branches
        ..clear()
        ..addAll(await _repository!.loadBranches(_store!.id));
    });
    return saved;
  }

  Future<void> adjustInventory({
    required String branchId,
    required String productId,
    required num newQuantity,
    required num unitCost,
    required String note,
  }) async {
    await _guard(() async {
      final level = await _repository!.adjustInventory(
        storeId: _store!.id,
        branchId: branchId,
        productId: productId,
        newQuantity: newQuantity,
        unitCost: unitCost,
        note: note,
      );
      final index = _inventory.indexWhere((item) => item.id == level.id);
      if (index >= 0) {
        _inventory[index] = level;
      } else {
        _inventory.add(level);
      }
      await _reloadMovements();
      _noticeMessage = 'تمت تسوية المخزون وتسجيل الحركة.';
    });
  }

  Future<void> transferInventory({
    required String productId,
    required String fromBranchId,
    required String toBranchId,
    required num quantity,
    required String note,
  }) async {
    await _guard(() async {
      await _repository!.transferInventory(
        storeId: _store!.id,
        productId: productId,
        fromBranchId: fromBranchId,
        toBranchId: toBranchId,
        quantity: quantity,
        note: note,
      );
      await _reloadInventory();
      _noticeMessage = 'اكتمل تحويل المخزون بين الفرعين.';
    });
  }

  Future<SaleTransaction?> createSale({
    required String branchId,
    String? customerId,
    required String customerName,
    required String customerPhone,
    required List<SaleLineInput> lines,
    required List<SalePayment> payments,
    num orderDiscount = 0,
    String notes = '',
  }) async {
    SaleTransaction? sale;
    await _guard(() async {
      sale = await _repository!.createSale(
        storeId: _store!.id,
        branchId: branchId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        lines: lines,
        payments: payments,
        orderDiscount: orderDiscount,
        notes: notes,
      );
      _sales.insert(0, sale!);
      await _reloadInventory();
      _warranties
        ..clear()
        ..addAll(await _repository!.loadWarranties(_store!.id));
      _registerSessions
        ..clear()
        ..addAll(await _repository!.loadRegisterSessions(_store!.id));
      _noticeMessage = 'تم حفظ البيع وتحديث المخزون والضمان.';
    });
    return sale;
  }

  Future<void> returnSale({
    required String saleId,
    required Map<String, num> lineQuantities,
    required PaymentMethod refundMethod,
    required String reason,
  }) async {
    await _guard(() async {
      final updated = await _repository!.returnSale(
        storeId: _store!.id,
        saleId: saleId,
        lineQuantities: lineQuantities,
        refundMethod: refundMethod,
        reason: reason,
      );
      final index = _sales.indexWhere((item) => item.id == saleId);
      if (index >= 0) _sales[index] = updated;
      await _reloadInventory();
      _noticeMessage = 'تم تسجيل المرتجع وإعادة الكمية إلى المخزون.';
    });
  }

  Future<void> openRegister({
    required String branchId,
    required num openingCash,
    String notes = '',
  }) async {
    await _guard(() async {
      final session = await _repository!.openRegister(
        storeId: _store!.id,
        branchId: branchId,
        openingCash: openingCash,
        notes: notes,
      );
      _registerSessions.insert(0, session);
      _noticeMessage = 'تم فتح جلسة الصندوق.';
    });
  }

  Future<void> closeRegister({
    required String sessionId,
    required num closingCash,
    String notes = '',
  }) async {
    await _guard(() async {
      final session = await _repository!.closeRegister(
        sessionId: sessionId,
        closingCash: closingCash,
        notes: notes,
      );
      final index = _registerSessions.indexWhere(
        (item) => item.id == sessionId,
      );
      if (index >= 0) _registerSessions[index] = session;
      _noticeMessage = 'تم إغلاق الصندوق وتثبيت العجز أو الزيادة.';
    });
  }

  Future<Supplier?> saveSupplier({
    String? supplierId,
    required String name,
    String contactName = '',
    String phone = '',
    String email = '',
    String taxNumber = '',
    String address = '',
    String notes = '',
  }) async {
    Supplier? supplier;
    await _guard(() async {
      supplier = await _repository!.saveSupplier(
        storeId: _store!.id,
        supplierId: supplierId,
        name: name,
        contactName: contactName,
        phone: phone,
        email: email,
        taxNumber: taxNumber,
        address: address,
        notes: notes,
      );
      final index = _suppliers.indexWhere((item) => item.id == supplier!.id);
      if (index >= 0) {
        _suppliers[index] = supplier!;
      } else {
        _suppliers.add(supplier!);
      }
    });
    return supplier;
  }

  Future<PurchaseOrder?> createPurchaseOrder({
    required String branchId,
    required String supplierId,
    DateTime? expectedAt,
    String notes = '',
    required List<PurchaseOrderLineInput> lines,
  }) async {
    PurchaseOrder? order;
    await _guard(() async {
      order = await _repository!.createPurchaseOrder(
        storeId: _store!.id,
        branchId: branchId,
        supplierId: supplierId,
        expectedAt: expectedAt,
        notes: notes,
        lines: lines,
      );
      _purchaseOrders.insert(0, order!);
    });
    return order;
  }

  Future<void> receivePurchaseOrder(String purchaseOrderId) async {
    await _guard(() async {
      final updated = await _repository!.receivePurchaseOrder(purchaseOrderId);
      final index = _purchaseOrders.indexWhere(
        (item) => item.id == purchaseOrderId,
      );
      if (index >= 0) _purchaseOrders[index] = updated;
      await _reloadInventory();
      _noticeMessage = 'تم استلام أمر الشراء وتحديث تكلفة المخزون.';
    });
  }

  Future<void> _reloadInventory() async {
    final results = await Future.wait<Object>([
      _repository!.loadInventory(_store!.id),
      _repository!.loadStockMovements(_store!.id),
    ]);
    _inventory
      ..clear()
      ..addAll(results[0] as List<InventoryLevel>);
    _stockMovements
      ..clear()
      ..addAll(results[1] as List<StockMovement>);
  }

  Future<void> _reloadMovements() async {
    _stockMovements
      ..clear()
      ..addAll(await _repository!.loadStockMovements(_store!.id));
  }

  Future<void> requestSubscription({
    required String planId,
    required String billingCycle,
    required String contactPhone,
  }) async {
    await _guard(() async {
      await _repository!.requestSubscription(
        storeId: _store!.id,
        planId: planId,
        billingCycle: billingCycle,
        contactPhone: contactPhone,
      );
      _noticeMessage =
          'سُجّل طلب الاشتراك. سيتواصل معك فريق ضمانك لإتمام التفعيل.';
    });
  }

  Future<void> redeemSubscriptionCode(String code) async {
    await _guard(() async {
      _subscription = await _repository!.redeemSubscriptionCode(
        storeId: _store!.id,
        code: code,
      );
      _noticeMessage = 'تم تفعيل الاشتراك بنجاح.';
    });
  }

  void clearMessages() {
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
  }

  Future<void> _loadWorkspace() async {
    final snapshot = await _repository!.loadWorkspace();
    if (snapshot == null) {
      _stage = AppStage.onboarding;
      return;
    }
    _applySnapshot(snapshot);
    await _loadWorkspaceData();
    _stage = AppStage.ready;
  }

  void _applySnapshot(WorkspaceSnapshot snapshot) {
    _store = snapshot.store;
    _membership = snapshot.membership;
    _subscription = snapshot.subscription;
  }

  Future<void> _loadWorkspaceData() async {
    final storeId = _store!.id;
    final results = await Future.wait<Object>([
      _repository!.loadProducts(storeId),
      _repository!.loadBranches(storeId),
      _repository!.loadCustomers(storeId),
      _repository!.loadInventory(storeId),
      _repository!.loadStockMovements(storeId),
      _repository!.loadSales(storeId),
      _repository!.loadRegisterSessions(storeId),
      _repository!.loadSuppliers(storeId),
      _repository!.loadPurchaseOrders(storeId),
      _repository!.loadWarranties(storeId),
      _repository!.loadRequests(storeId),
      _repository!.loadTeam(storeId),
      _repository!.loadPlans(),
      if (_membership!.role.canManageTeam)
        _repository!.loadAuditLogs(storeId)
      else
        Future.value(<AuditEvent>[]),
    ]);
    _products
      ..clear()
      ..addAll(results[0] as List<Product>);
    _branches
      ..clear()
      ..addAll(results[1] as List<StoreBranch>);
    _customers
      ..clear()
      ..addAll(results[2] as List<CustomerProfile>);
    _inventory
      ..clear()
      ..addAll(results[3] as List<InventoryLevel>);
    _stockMovements
      ..clear()
      ..addAll(results[4] as List<StockMovement>);
    _sales
      ..clear()
      ..addAll(results[5] as List<SaleTransaction>);
    _registerSessions
      ..clear()
      ..addAll(results[6] as List<CashRegisterSession>);
    _suppliers
      ..clear()
      ..addAll(results[7] as List<Supplier>);
    _purchaseOrders
      ..clear()
      ..addAll(results[8] as List<PurchaseOrder>);
    _warranties
      ..clear()
      ..addAll(results[9] as List<Warranty>);
    _requests
      ..clear()
      ..addAll(results[10] as List<MaintenanceRequest>);
    _team
      ..clear()
      ..addAll(results[11] as List<TeamMember>);
    _plans
      ..clear()
      ..addAll(results[12] as List<PlanInfo>);
    _auditLogs
      ..clear()
      ..addAll(results[13] as List<AuditEvent>);
    _activeBranchId ??= activeBranch?.id;
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } on Object catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('invalid login credentials')) {
      return 'البريد أو كلمة المرور غير صحيحة.';
    }
    if (value.contains('email not confirmed')) {
      return 'أكّد بريدك الإلكتروني أولاً ثم حاول مجدداً.';
    }
    if (value.contains('user already registered')) {
      return 'يوجد حساب مسجل بهذا البريد.';
    }
    if (value.contains('invite_invalid')) {
      return 'رمز الدعوة غير صحيح أو انتهت صلاحيته.';
    }
    if (value.contains('seat_limit_reached')) {
      return 'وصل المتجر إلى الحد الأقصى لأعضاء الخطة الحالية.';
    }
    if (value.contains('subscription_inactive')) {
      return 'الاشتراك غير فعّال. افتح صفحة الاشتراك لتجديده.';
    }
    if (value.contains('warranty_limit_reached')) {
      return 'استهلك المتجر حد الضمانات الشهري للخطة.';
    }
    if (value.contains('insufficient_stock')) {
      return 'الكمية المطلوبة أكبر من الرصيد المتاح في هذا الفرع.';
    }
    if (value.contains('serial_numbers_required')) {
      return 'أدخل رقماً تسلسلياً مستقلاً لكل قطعة.';
    }
    if (value.contains('payment_total_mismatch')) {
      return 'مجموع الدفعات لا يساوي إجمالي الفاتورة.';
    }
    if (value.contains('register_already_open')) {
      return 'يوجد صندوق مفتوح لهذا الفرع بالفعل.';
    }
    if (value.contains('invalid_return_quantity')) {
      return 'كمية المرتجع غير صحيحة أو سبق إرجاعها.';
    }
    if (value.contains('duplicate key') || value.contains('23505')) {
      return 'هذه القيمة مسجلة مسبقاً؛ تحقق من الباركود أو الرمز.';
    }
    return 'تعذّر إكمال العملية. تحقق من الاتصال وحاول مرة أخرى.';
  }

  void _clearData() {
    _account = null;
    _store = null;
    _membership = null;
    _subscription = null;
    _products.clear();
    _branches.clear();
    _customers.clear();
    _inventory.clear();
    _stockMovements.clear();
    _sales.clear();
    _registerSessions.clear();
    _suppliers.clear();
    _purchaseOrders.clear();
    _warranties.clear();
    _requests.clear();
    _team.clear();
    _plans.clear();
    _auditLogs.clear();
    _activeBranchId = null;
  }
}
