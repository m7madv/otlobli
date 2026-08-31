import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/damanak_repository.dart';
import '../data/demo_repository.dart';
import '../models/account.dart';
import '../models/audit_event.dart';
import '../models/branch.dart';
import '../models/customer.dart';
import '../models/claim_attachment.dart';
import '../models/claim_ai_review.dart';
import '../models/inventory.dart';
import '../models/integration.dart';
import '../models/maintenance_request.dart';
import '../models/app_notification.dart';
import '../models/product.dart';
import '../models/product_ai_import.dart';
import '../models/register.dart';
import '../models/sale.dart';
import '../models/store_profile.dart';
import '../models/subscription.dart';
import '../models/store_billing.dart';
import '../models/supplier.dart';
import '../models/warranty.dart';
import '../services/store_billing_service.dart';

class AppController extends ChangeNotifier {
  static const int _warrantyPageSize = 100;

  AppController.withRepository(
    DamanakRepository repository, {
    StoreBillingService? billingService,
    Duration storeProductLoadTimeout = const Duration(seconds: 24),
    Duration storeRestoreTimeout = const Duration(seconds: 12),
    Duration purchaseEventTimeout = const Duration(minutes: 2),
  }) : _repository = repository,
       _billingService =
           billingService ?? const UnavailableStoreBillingService(),
       _storeProductLoadTimeout = storeProductLoadTimeout,
       _storeRestoreTimeout = storeRestoreTimeout,
       _purchaseEventTimeout = purchaseEventTimeout {
    _listenToStoreBilling();
  }

  AppController.unconfigured({
    StoreBillingService? billingService,
    Duration storeProductLoadTimeout = const Duration(seconds: 24),
    Duration storeRestoreTimeout = const Duration(seconds: 12),
    Duration purchaseEventTimeout = const Duration(minutes: 2),
  }) : _billingService =
           billingService ?? const UnavailableStoreBillingService(),
       _storeProductLoadTimeout = storeProductLoadTimeout,
       _storeRestoreTimeout = storeRestoreTimeout,
       _purchaseEventTimeout = purchaseEventTimeout {
    _listenToStoreBilling();
  }

  DamanakRepository? _repository;
  final StoreBillingService _billingService;
  final Duration _storeProductLoadTimeout;
  final Duration _storeRestoreTimeout;
  final Duration _purchaseEventTimeout;
  StreamSubscription<List<StorePurchaseEvent>>? _billingSubscription;
  Timer? _purchaseWatchdog;
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
  final List<AppNotification> _notifications = [];
  final List<ApiKeyInfo> _apiKeys = [];
  final List<WebhookInfo> _webhooks = [];
  final Map<String, ClaimAiReview> _claimAiReviews = {};
  NotificationPreferences _notificationPreferences =
      const NotificationPreferences();
  final List<StoreProductOffer> _storeOffers = [];
  final Set<String> _processingPurchases = {};
  int _storeProductRefreshSerial = 0;
  StoreBillingState _storeBillingState = StoreBillingState.idle;
  StoreBillingPlatform _storeBillingPlatform = StoreBillingPlatform.unavailable;
  String? _storeBillingMessage;
  bool _busy = false;
  bool _hasMoreWarranties = false;
  bool _loadingMoreWarranties = false;
  String? _errorMessage;
  String? _noticeMessage;
  String? _activeBranchId;
  String? _pendingInvitationCode;
  MemberRole? _pendingInvitationRole;

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
  String? get pendingInvitationCode => _pendingInvitationCode;
  MemberRole? get pendingInvitationRole => _pendingInvitationRole;
  StoreBillingState get storeBillingState => _storeBillingState;
  StoreBillingPlatform get storeBillingPlatform => _storeBillingPlatform;
  String? get storeBillingMessage => _storeBillingMessage;
  UnmodifiableListView<StoreProductOffer> get storeOffers =>
      UnmodifiableListView(_storeOffers);
  StoreProfile get profile => StoreProfile(
    name: _store?.name ?? 'متجر ضمانك',
    phone: _store?.phone ?? '',
    city: _store?.city ?? '',
    address: _store?.address ?? '',
    countryCode: _store?.countryCode ?? 'SA',
    currencyCode: _store?.currencyCode ?? 'SAR',
    taxRate: _store?.taxRate ?? 0,
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
  bool get hasMoreWarranties => _hasMoreWarranties;
  bool get loadingMoreWarranties => _loadingMoreWarranties;
  UnmodifiableListView<MaintenanceRequest> get requests =>
      UnmodifiableListView(_requests);
  UnmodifiableListView<TeamMember> get team => UnmodifiableListView(_team);
  UnmodifiableListView<PlanInfo> get plans => UnmodifiableListView(_plans);
  UnmodifiableListView<AuditEvent> get auditLogs =>
      UnmodifiableListView(_auditLogs);
  UnmodifiableListView<AppNotification> get notifications =>
      UnmodifiableListView(_notifications);
  NotificationPreferences get notificationPreferences =>
      _notificationPreferences;
  int get unreadNotificationCount =>
      _notifications.where((item) => item.isUnread).length;
  UnmodifiableListView<ApiKeyInfo> get apiKeys =>
      UnmodifiableListView(_apiKeys);
  UnmodifiableListView<WebhookInfo> get webhooks =>
      UnmodifiableListView(_webhooks);
  ClaimAiReview? claimAiReview(String requestId) => _claimAiReviews[requestId];

  StoreProductOffer? storeOffer(String planId, BillingCycle cycle) {
    for (final offer in _storeOffers) {
      if (offer.planId == planId && offer.cycle == cycle) return offer;
    }
    return null;
  }

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
      unawaited(refreshStoreProducts());
      unawaited(_refreshStoreSubscriptionIfStale());
    });
  }

  Future<void> startDemo() async {
    _repository = DemoDamanakRepository();
    _clearData();
    await initialize();
  }

  Future<void> signInWithSocial(SocialAuthProvider provider) async {
    await _guard(() async {
      await _repository!.signInWithSocial(provider);
      _noticeMessage = 'تم تسجيل الدخول باستخدام ${provider.label}.';
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

  Future<void> signOut() async {
    await _guard(() async {
      final signOutOperation = _repository!.signOut();
      final wasDemo = isDemo;
      _clearData();
      if (wasDemo) {
        _repository = null;
        _stage = AppStage.configuring;
      } else {
        _stage = AppStage.signedOut;
      }
      // Supabase removes the local session before it contacts the auth server.
      // Move away from private store data immediately instead of leaving the
      // account screen disabled while a slow network request finishes.
      notifyListeners();
      unawaited(signOutOperation.catchError((Object _) {}));
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
      unawaited(refreshStoreProducts());
    });
  }

  Future<void> joinStore(String code) async {
    await _guard(() async {
      final snapshot = await _repository!.joinStore(code);
      _applySnapshot(snapshot);
      await _loadWorkspaceData();
      _pendingInvitationCode = null;
      _pendingInvitationRole = null;
      _stage = AppStage.ready;
      unawaited(refreshStoreProducts());
    });
  }

  bool handleIncomingUri(Uri uri) {
    if (uri.scheme != 'com.damanak.damanak' || uri.host != 'join') {
      return false;
    }
    final code = uri.queryParameters['code']?.trim().toUpperCase();
    if (code == null ||
        !RegExp(
          r'^DMN-(?:[A-F0-9]{10}|[A-F0-9]{16}|[A-F0-9]{32})$',
        ).hasMatch(code)) {
      _errorMessage = 'رابط الدعوة غير مكتمل. اطلب من المدير إرسال دعوة جديدة.';
      notifyListeners();
      return true;
    }
    _pendingInvitationCode = code;
    final role = uri.queryParameters['role'];
    _pendingInvitationRole = role == 'manager' || role == 'staff'
        ? MemberRoleText.fromValue(role)
        : null;
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
    return true;
  }

  void clearPendingInvitation() {
    if (_pendingInvitationCode == null) return;
    _pendingInvitationCode = null;
    _pendingInvitationRole = null;
    notifyListeners();
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
    String? logoUrl,
    String? brandColor,
    String? customerPortalTitle,
    String? warrantyPolicy,
    String? warrantyExclusions,
  }) async {
    await _guard(() async {
      _store = await _repository!.updateStore(
        storeId: _store!.id,
        name: name,
        phone: phone,
        city: city,
        countryCode: countryCode,
        currencyCode: currencyCode,
        taxRate: 0,
        pricesIncludeTax: true,
        taxNumber: '',
        commercialRegistration: commercialRegistration,
        address: address,
        invoicePrefix: invoicePrefix,
        defaultWarrantyMonths: defaultWarrantyMonths,
        logoUrl: logoUrl ?? _store!.logoUrl,
        brandColor: brandColor ?? _store!.brandColor,
        customerPortalTitle: customerPortalTitle ?? _store!.customerPortalTitle,
        warrantyPolicy: warrantyPolicy ?? _store!.warrantyPolicy,
        warrantyExclusions: warrantyExclusions ?? _store!.warrantyExclusions,
      );
      _noticeMessage = 'تم حفظ بيانات المتجر.';
    });
  }

  Future<void> refresh() async {
    if (_store == null) return;
    await _guard(_loadWorkspace);
  }

  Future<void> refreshNotifications() async {
    if (_store == null) return;
    await _guard(() async {
      final items = await _repository!.loadNotifications(_store!.id);
      _notifications
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> markNotificationRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index < 0 || !_notifications[index].isUnread) return;
    await _repository!.markNotificationRead(notificationId);
    final item = _notifications[index];
    _notifications[index] = AppNotification(
      id: item.id,
      storeId: item.storeId,
      type: item.type,
      title: item.title,
      body: item.body,
      requestId: item.requestId,
      createdAt: item.createdAt,
      readAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> saveNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    await _guard(() async {
      _notificationPreferences = await _repository!.saveNotificationPreferences(
        storeId: _store!.id,
        preferences: preferences,
      );
      _noticeMessage = 'تم حفظ تفضيلات الإشعارات.';
    });
  }

  Future<ClaimAiReview?> analyzeClaim({
    required String requestId,
    bool includeAttachments = false,
  }) async {
    ClaimAiReview? result;
    await _guard(() async {
      result = await _repository!.analyzeClaim(
        storeId: _store!.id,
        requestId: requestId,
        includeAttachments: includeAttachments,
      );
      _claimAiReviews[requestId] = result!;
    });
    return result;
  }

  Future<void> loadIntegrations() async {
    if (_store == null || _membership?.role != MemberRole.owner) return;
    await _guard(() async {
      final results = await Future.wait<Object>([
        _repository!.loadApiKeys(_store!.id),
        _repository!.loadWebhooks(_store!.id),
      ]);
      _apiKeys
        ..clear()
        ..addAll(results[0] as List<ApiKeyInfo>);
      _webhooks
        ..clear()
        ..addAll(results[1] as List<WebhookInfo>);
    });
  }

  Future<CreatedApiKey?> createApiKey({
    required String name,
    required List<String> scopes,
  }) async {
    CreatedApiKey? result;
    await _guard(() async {
      result = await _repository!.createApiKey(
        storeId: _store!.id,
        name: name,
        scopes: scopes,
      );
      _apiKeys.insert(0, result!.info);
    });
    return result;
  }

  Future<void> revokeApiKey(String keyId) async {
    await _guard(() async {
      await _repository!.revokeApiKey(keyId);
      await _loadIntegrationsWithoutGuard();
      _noticeMessage = 'تم إلغاء المفتاح فوراً.';
    });
  }

  Future<CreatedWebhook?> createWebhook({
    required String endpointUrl,
    required List<String> events,
  }) async {
    CreatedWebhook? result;
    await _guard(() async {
      result = await _repository!.createWebhook(
        storeId: _store!.id,
        endpointUrl: endpointUrl,
        events: events,
      );
      _webhooks.insert(0, result!.info);
    });
    return result;
  }

  Future<void> setWebhookActive(String webhookId, bool active) async {
    await _guard(() async {
      await _repository!.setWebhookActive(webhookId, active);
      await _loadIntegrationsWithoutGuard();
    });
  }

  Future<void> _loadIntegrationsWithoutGuard() async {
    final results = await Future.wait<Object>([
      _repository!.loadApiKeys(_store!.id),
      _repository!.loadWebhooks(_store!.id),
    ]);
    _apiKeys
      ..clear()
      ..addAll(results[0] as List<ApiKeyInfo>);
    _webhooks
      ..clear()
      ..addAll(results[1] as List<WebhookInfo>);
  }

  Future<void> loadMoreWarranties() async {
    final repository = _repository;
    final store = _store;
    if (repository == null ||
        store == null ||
        !_hasMoreWarranties ||
        _loadingMoreWarranties ||
        _busy) {
      return;
    }

    _loadingMoreWarranties = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await repository.loadWarranties(
        store.id,
        limit: _warrantyPageSize,
        offset: _warranties.length,
      );
      if (_store?.id != store.id) return;
      final added = _mergeWarranties(page);
      _hasMoreWarranties = page.length == _warrantyPageSize && added > 0;
    } on Object catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _loadingMoreWarranties = false;
      notifyListeners();
    }
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
    String warrantyPolicy = '',
    String warrantyExclusions = '',
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
        warrantyPolicy: warrantyPolicy,
        warrantyExclusions: warrantyExclusions,
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
    String warrantyPolicy = '',
    String warrantyExclusions = '',
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
        warrantyPolicy: warrantyPolicy,
        warrantyExclusions: warrantyExclusions,
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

  Future<AiProductImportResult?> analyzeProductDocument(
    ProductDocumentInput document,
  ) async {
    AiProductImportResult? result;
    await _guard(() async {
      result = await _repository!.analyzeProductDocument(
        storeId: _store!.id,
        document: document,
      );
    });
    return result;
  }

  List<Warranty> warrantiesByStatus(WarrantyStatus status) =>
      _warranties.where((item) => item.statusAt() == status).toList();

  Warranty? warrantyById(String id) {
    for (final item in _warranties) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<Warranty?> findWarrantyBySerial(String serialNumber) async {
    final normalized = serialNumber.trim();
    if (normalized.isEmpty || _store == null) return null;
    Warranty? match;
    await _guard(() async {
      match = await _repository!.findWarrantyBySerial(_store!.id, normalized);
    });
    return match;
  }

  List<MaintenanceRequest> requestsForWarranty(String warrantyId) =>
      _requests.where((request) => request.warrantyId == warrantyId).toList();

  MaintenanceRequest? requestById(String id) {
    for (final item in _requests) {
      if (item.id == id) return item;
    }
    return null;
  }

  TeamMember? teamMemberById(String? id) {
    if (id == null) return null;
    for (final item in _team) {
      if (item.userId == id) return item;
    }
    return null;
  }

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
          source: current.source,
          billingProvider: current.billingProvider,
          storeProductId: current.storeProductId,
          billingCycle: current.billingCycle,
          autoRenews: current.autoRenews,
          lastVerifiedAt: current.lastVerifiedAt,
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

  Future<Uri?> createWarrantyShareLink(String warrantyId) async {
    Uri? link;
    await _guard(() async {
      link = await _repository!.createWarrantyShareLink(warrantyId);
    });
    return link;
  }

  Future<MaintenanceRequest?> addMaintenanceRequest({
    required String warrantyId,
    required String issue,
    ClaimCategory category = ClaimCategory.other,
    ClaimPriority priority = ClaimPriority.normal,
  }) async {
    MaintenanceRequest? created;
    await _guard(() async {
      created = await _repository!.createRequest(
        storeId: _store!.id,
        warrantyId: warrantyId,
        issue: issue,
        category: category,
        priority: priority,
      );
      _requests.insert(0, created!);
    });
    return created;
  }

  Future<void> updateMaintenanceStatus(
    String requestId,
    MaintenanceStatus status,
  ) async {
    final request = requestById(requestId);
    if (request == null || request.status == status) return;
    await saveMaintenanceRequest(request.copyWith(status: status));
  }

  Future<void> saveMaintenanceRequest(MaintenanceRequest request) async {
    await _guard(() async {
      final updated = await _repository!.updateRequest(request);
      final index = _requests.indexWhere((item) => item.id == request.id);
      if (index >= 0) {
        _requests[index] = updated;
      }
    });
  }

  Future<List<ClaimAttachment>> loadRequestAttachments(String requestId) {
    final repository = _repository;
    if (repository == null) return Future.value(const []);
    return repository.loadRequestAttachments(requestId);
  }

  Future<Uri> createRequestAttachmentLink(String storagePath) {
    final repository = _repository;
    if (repository == null) {
      return Future.error(StateError('CLAIM_ATTACHMENT_UNAVAILABLE'));
    }
    return repository.createRequestAttachmentLink(storagePath);
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
      final saleWarranties = await _repository!.loadWarrantiesForInvoice(
        _store!.id,
        sale!.invoiceNumber,
      );
      _mergeWarranties(saleWarranties);
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

  void _listenToStoreBilling() {
    _billingSubscription = _billingService.purchaseUpdates.listen(
      _handleStorePurchaseUpdates,
      onError: (Object error) {
        _storeBillingState = StoreBillingState.unavailable;
        _storeBillingMessage = _friendlyError(error);
        notifyListeners();
      },
    );
  }

  Future<void> refreshStoreProducts() async {
    if (_stage != AppStage.ready) return;
    final refreshSerial = ++_storeProductRefreshSerial;
    _storeBillingState = StoreBillingState.loading;
    _storeBillingMessage = null;
    notifyListeners();
    try {
      final result = await _billingService.loadProducts().timeout(
        _storeProductLoadTimeout,
      );
      if (refreshSerial != _storeProductRefreshSerial) return;
      _storeBillingPlatform = result.platform;
      _storeOffers
        ..clear()
        ..addAll(result.offers);
      _storeBillingState = result.available && result.offers.isNotEmpty
          ? StoreBillingState.ready
          : StoreBillingState.unavailable;
      if (result.errorMessage != null) {
        _storeBillingMessage = result.errorMessage;
      } else if (result.missingProductIds.isNotEmpty) {
        _storeBillingMessage =
            'بعض منتجات الاشتراك لم تُنشأ أو تُفعّل في المتجر بعد.';
      } else if (result.offers.isEmpty) {
        _storeBillingMessage = 'لم يُرجع المتجر خططاً متاحة لهذا الحساب.';
      }
    } on TimeoutException {
      if (refreshSerial != _storeProductRefreshSerial) return;
      _storeBillingState = StoreBillingState.unavailable;
      _storeBillingMessage =
          'استغرق متجر التطبيقات وقتاً طويلاً. تحقق من الاتصال ثم أعد المحاولة.';
    } catch (error) {
      if (refreshSerial != _storeProductRefreshSerial) return;
      _storeBillingState = StoreBillingState.unavailable;
      _storeBillingMessage = _friendlyError(error);
    }
    notifyListeners();
  }

  Future<void> purchaseSubscription(StoreProductOffer offer) async {
    if (_membership?.role.canManageSubscription != true) {
      _errorMessage = 'إدارة الاشتراك متاحة لمالك المتجر فقط.';
      notifyListeners();
      return;
    }
    if (isDemo || _repository == null || _account == null || _store == null) {
      _errorMessage =
          'الشراء الحقيقي يحتاج نسخة مرتبطة بقاعدة ضمانك ومنشورة من المتجر.';
      notifyListeners();
      return;
    }
    _storeBillingState = StoreBillingState.purchasing;
    _storeBillingMessage = 'أكمل العملية في نافذة المتجر الآمنة.';
    _startPurchaseWatchdog();
    notifyListeners();
    try {
      await _billingService.purchase(
        offer,
        accountId: _account!.id,
        storeId: _store!.id,
      );
    } catch (error) {
      _purchaseWatchdog?.cancel();
      _storeBillingState = StoreBillingState.ready;
      _errorMessage = _friendlyError(error);
      notifyListeners();
    }
  }

  Future<void> restoreStorePurchases() async {
    _purchaseWatchdog?.cancel();
    _storeBillingState = StoreBillingState.loading;
    _storeBillingMessage = 'جارٍ طلب مشترياتك السابقة من المتجر…';
    notifyListeners();
    try {
      await _billingService.restorePurchases().timeout(_storeRestoreTimeout);
      _noticeMessage =
          'أرسل المتجر المشتريات المتاحة للاستعادة، وسيجري التحقق منها.';
      if (_storeBillingState == StoreBillingState.loading) {
        _storeBillingState = _idleStoreBillingState;
        _storeBillingMessage = _storeOffers.isEmpty
            ? 'لم يُرجع المتجر خططاً متاحة لهذا الحساب.'
            : null;
      }
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _storeBillingState = _idleStoreBillingState;
      _storeBillingMessage = _storeOffers.isEmpty
          ? 'تعذر الاتصال بمتجر التطبيقات لاستعادة المشتريات.'
          : null;
    }
    notifyListeners();
  }

  StoreBillingState get _idleStoreBillingState => _storeOffers.isEmpty
      ? StoreBillingState.unavailable
      : StoreBillingState.ready;

  void _startPurchaseWatchdog() {
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = Timer(_purchaseEventTimeout, () {
      if (_storeBillingState != StoreBillingState.purchasing) return;
      _storeBillingState = _idleStoreBillingState;
      _storeBillingMessage =
          'لم يصل تأكيد من المتجر، ولم تُفعّل أي خطة. استخدم استعادة المشتريات قبل إعادة المحاولة.';
      notifyListeners();
    });
  }

  Future<void> openStoreSubscriptionManagement() async {
    final opened = await _billingService.openSubscriptionManagement();
    if (!opened) {
      _errorMessage = 'تعذر فتح صفحة إدارة الاشتراك في المتجر.';
      notifyListeners();
    }
  }

  Future<void> _handleStorePurchaseUpdates(
    List<StorePurchaseEvent> events,
  ) async {
    if (events.isNotEmpty) _purchaseWatchdog?.cancel();
    for (final event in events) {
      switch (event.status) {
        case StorePurchaseStatus.pending:
          _storeBillingState = StoreBillingState.pending;
          _storeBillingMessage =
              'الدفعة معلّقة لدى المتجر. لن تتفعّل الخطة قبل تأكيدها.';
        case StorePurchaseStatus.canceled:
          _storeBillingState = StoreBillingState.ready;
          _storeBillingMessage = null;
          _noticeMessage = 'أُغلقت عملية الشراء من دون خصم.';
        case StorePurchaseStatus.error:
          _storeBillingState = StoreBillingState.ready;
          _errorMessage = event.errorMessage?.trim().isNotEmpty == true
              ? event.errorMessage
              : 'تعذر إكمال عملية الشراء في المتجر.';
        case StorePurchaseStatus.purchased:
        case StorePurchaseStatus.restored:
          await _verifyAndCompleteStorePurchase(event);
      }
    }
    notifyListeners();
  }

  Future<void> _verifyAndCompleteStorePurchase(StorePurchaseEvent event) async {
    if (!_processingPurchases.add(event.key)) return;
    try {
      if (_repository == null || _store == null || _account == null) {
        throw StateError('STORE_VERIFICATION_REQUIRES_CLOUD');
      }
      if (_membership?.role.canManageSubscription != true) {
        throw StateError('STORE_OWNER_REQUIRED');
      }
      _storeBillingState = StoreBillingState.purchasing;
      _storeBillingMessage = 'جارٍ التحقق من إيصال المتجر بأمان…';
      notifyListeners();
      _subscription = await _repository!
          .verifyStorePurchase(
            storeId: _store!.id,
            receipt: StorePurchaseReceipt(
              platform: event.platform,
              productId: event.productId,
              basePlanId: event.basePlanId,
              purchaseId: event.purchaseId,
              transactionDate: event.transactionDate,
              verificationData: event.verificationData,
              verificationSource: event.verificationSource,
            ),
          )
          .timeout(
            const Duration(seconds: 35),
            onTimeout: () => throw StateError('STORE_VERIFICATION_TIMEOUT'),
          );
      if (event.needsCompletion) {
        await _billingService.completePurchase(event);
      }
      _storeBillingState = StoreBillingState.ready;
      _storeBillingMessage = null;
      _noticeMessage = event.status == StorePurchaseStatus.restored
          ? 'تمت استعادة الاشتراك والتحقق منه.'
          : 'تم الدفع وتفعيل الاشتراك من ${event.platform.label}.';
    } catch (error) {
      _storeBillingState = StoreBillingState.ready;
      _storeBillingMessage = null;
      _errorMessage = _friendlyError(error);
    } finally {
      _processingPurchases.remove(event.key);
    }
  }

  Future<void> _refreshStoreSubscriptionIfStale() async {
    final subscription = _subscription;
    final store = _store;
    if (_repository == null ||
        store == null ||
        subscription == null ||
        !subscription.isStoreSubscription ||
        _membership?.role.canManageSubscription != true) {
      return;
    }
    final verifiedAt = subscription.lastVerifiedAt;
    if (verifiedAt != null &&
        DateTime.now().difference(verifiedAt.toLocal()) <
            const Duration(hours: 6)) {
      return;
    }
    try {
      _subscription = await _repository!.refreshStoreSubscription(store.id);
      notifyListeners();
    } catch (_) {
      // Keep the last server-known entitlement. A failed background refresh
      // never grants access and should not interrupt the owner's sign-in.
    }
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
      _repository!.loadWarranties(storeId, limit: _warrantyPageSize, offset: 0),
      _repository!.loadRequests(storeId),
      _repository!.loadTeam(storeId),
      _repository!.loadPlans(),
      if (_membership!.role.canManageTeam)
        _repository!.loadAuditLogs(storeId)
      else
        Future.value(<AuditEvent>[]),
      _repository!.loadNotifications(storeId),
      _repository!.loadNotificationPreferences(storeId),
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
    _hasMoreWarranties = _warranties.length == _warrantyPageSize;
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
    _notifications
      ..clear()
      ..addAll(results[14] as List<AppNotification>);
    _notificationPreferences = results[15] as NotificationPreferences;
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
      if (!error.toString().toLowerCase().contains('auth_canceled')) {
        _errorMessage = _friendlyError(error);
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  int _mergeWarranties(Iterable<Warranty> incoming) {
    final byId = <String, Warranty>{
      for (final warranty in _warranties) warranty.id: warranty,
    };
    var added = 0;
    for (final warranty in incoming) {
      if (!byId.containsKey(warranty.id)) added++;
      byId[warranty.id] = warranty;
    }
    _warranties
      ..clear()
      ..addAll(byId.values)
      ..sort((left, right) {
        final dateComparison = right.createdAt.compareTo(left.createdAt);
        return dateComparison != 0
            ? dateComparison
            : right.id.compareTo(left.id);
      });
    return added;
  }

  String _friendlyError(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('auth_provider_unavailable')) {
      return 'تسجيل الدخول هذا غير متاح على الجهاز حالياً. تحقق من إعداد الحساب ثم حاول مجدداً.';
    }
    if (value.contains('auth_token_missing')) {
      return 'لم يرسل مزوّد الحساب بيانات الدخول المطلوبة. حاول مجدداً.';
    }
    if (value.contains('auth_window_not_opened')) {
      return 'تعذّر فتح تسجيل الدخول. تحقق من وجود متصفح آمن وحاول مجدداً.';
    }
    if (value.contains('oauth') || value.contains('auth_failed')) {
      return 'لم يكتمل تسجيل الدخول. حاول مجدداً باستخدام Apple أو Google.';
    }
    if (value.contains('invite_rate_limited')) {
      return 'أُوقفت محاولات الدعوة مؤقتاً للحماية. انتظر 15 دقيقة ثم أعد المحاولة.';
    }
    if (value.contains('invite_invalid')) {
      return 'رمز الدعوة غير صحيح أو انتهت صلاحيته.';
    }
    if (value.contains('trial_already_used_by_account') ||
        value.contains('trial_already_used_on_device')) {
      return 'استُخدمت التجربة المجانية سابقاً على هذا الحساب أو الجهاز. يمكنك الانضمام إلى متجر بدعوة أو اختيار اشتراك مدفوع.';
    }
    if (value.contains('app_update_required_for_trial')) {
      return 'حدّث ضمانك إلى آخر نسخة لحماية التجربة المجانية ثم حاول مجدداً.';
    }
    if (value.contains('trial_device')) {
      return 'تعذّر تأمين التجربة المجانية على هذا الجهاز. حدّث التطبيق ثم حاول مجدداً.';
    }
    if (value.contains('seat_limit_reached')) {
      return 'وصل المتجر إلى الحد الأقصى لأعضاء الخطة الحالية.';
    }
    if (value.contains('branch_limit_reached')) {
      return 'وصل المتجر إلى حد الفروع في الباقة الحالية.';
    }
    if (value.contains('plan_api_required') ||
        value.contains('plan_webhook_required')) {
      return 'هذه الميزة متاحة في باقة توسع فقط.';
    }
    if (value.contains('plan_branding_required')) {
      return 'الهوية المخصصة متاحة في باقتي نمو وتوسع.';
    }
    if (value.contains('api_key_limit_reached')) {
      return 'وصل المتجر إلى حد 5 مفاتيح فعالة. ألغِ مفتاحاً قديماً أولاً.';
    }
    if (value.contains('webhook_limit_reached')) {
      return 'وصل المتجر إلى حد 5 روابط فعالة.';
    }
    if (value.contains('claim_ai_monthly_limit')) {
      return 'استهلك المتجر مراجعات المطالبات الذكية لهذا الشهر.';
    }
    if (value.contains('claim_ai_not_included')) {
      return 'مراجعة المطالبات الذكية غير مشمولة في الباقة الحالية.';
    }
    if (value.contains('claim_ai_provider_not_configured')) {
      return 'مساعد المطالبات غير مهيأ على الخادم بعد.';
    }
    if (value.contains('claim_ai_cooldown')) {
      return 'تم تحليل هذه المطالبة قبل قليل. راجع النتيجة الحالية أولاً.';
    }
    if (value.contains('claim_review_manager_required')) {
      return 'مساعد فرز المطالبة متاح للمالك والمدير فقط.';
    }
    if (value.contains('subscription_inactive')) {
      return 'الاشتراك غير فعّال. افتح صفحة الاشتراك لتجديده.';
    }
    if (value.contains('store_product_unavailable')) {
      return 'هذه الخطة غير متاحة في المتجر حالياً.';
    }
    if (value.contains('store_purchase_not_launched')) {
      return 'لم يفتح المتجر نافذة الشراء. تحقق من حساب المتجر وحاول مجدداً.';
    }
    if (value.contains('store_unavailable')) {
      return 'متجر التطبيقات غير متاح على هذا الجهاز حالياً.';
    }
    if (value.contains('store_verification')) {
      return 'الدفع محفوظ لدى المتجر، لكن التحقق لم يكتمل بعد. لا تدفع مرة أخرى؛ استخدم استعادة المشتريات لإكمال التفعيل.';
    }
    if (value.contains('store_owner_required')) {
      return 'لا يمكن ربط الاشتراك إلا من حساب مالك المتجر.';
    }
    if (value.contains('warranty_limit_reached')) {
      return 'استهلك المتجر حد الضمانات الشهري للخطة.';
    }
    if (value.contains('warranty_share_link')) {
      return 'تعذّر تجهيز رابط التحقق من الضمان. حاول مرة أخرى بعد لحظات.';
    }
    if (value.contains('claim_version_conflict')) {
      return 'حدّث موظف آخر هذه المطالبة. أعد تحميلها قبل حفظ تعديلك.';
    }
    if (value.contains('claim_manager_required')) {
      return 'هذا القرار يحتاج إلى حساب المالك أو المدير.';
    }
    if (value.contains('claim_decision_reason_required')) {
      return 'اكتب سبب القرار قبل رفض المطالبة.';
    }
    if (value.contains('claim_status_transition_invalid')) {
      return 'لا يمكن نقل المطالبة مباشرةً إلى هذه الحالة.';
    }
    if (value.contains('claim_assignee_invalid')) {
      return 'اختر موظفاً نشطاً من فريق المتجر.';
    }
    if (value.contains('ai_import_monthly_limit')) {
      return 'استهلك المتجر تحليلات ملفات المنتجات لهذا الشهر.';
    }
    if (value.contains('ai_import_daily_safety_limit')) {
      return 'تم إيقاف تحليل الملفات مؤقتاً لحماية الحساب من الاستخدام غير المعتاد.';
    }
    if (value.contains('ai_import_not_included')) {
      return 'تحليل ملفات المنتجات غير مشمول في الباقة الحالية؛ استخدم CSV.';
    }
    if (value.contains('ai_provider_not_configured')) {
      return 'خدمة تحليل ملفات المنتجات غير مهيأة على الخادم بعد.';
    }
    if (value.contains('import_manager_required')) {
      return 'استيراد المستندات متاح للمالك أو المدير فقط.';
    }
    if (value.contains('ai_import_failed')) {
      return 'تعذر تحليل المستند. جرّب ملفاً أوضح أو استخدم CSV.';
    }
    if (value.contains('claim_ai_failed')) {
      return 'تعذر تحليل المطالبة الآن. راجعها يدوياً أو حاول لاحقاً.';
    }
    if (value.contains('claim_attachment')) {
      return 'تعذر فتح ملف المطالبة. تحقق من الاتصال وحاول مرة أخرى.';
    }
    if (value.contains('insufficient_stock')) {
      return 'الكمية المطلوبة أكبر من الرصيد المتاح في هذا الفرع.';
    }
    if (value.contains('serial_numbers_required')) {
      return 'أدخل رقماً تسلسلياً مستقلاً لكل قطعة.';
    }
    if (value.contains('payment_total_mismatch')) {
      return 'مجموع الدفعات لا يساوي إجمالي الإيصال.';
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
    _purchaseWatchdog?.cancel();
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
    _hasMoreWarranties = false;
    _loadingMoreWarranties = false;
    _requests.clear();
    _team.clear();
    _plans.clear();
    _auditLogs.clear();
    _notifications.clear();
    _apiKeys.clear();
    _webhooks.clear();
    _claimAiReviews.clear();
    _notificationPreferences = const NotificationPreferences();
    _storeOffers.clear();
    _storeBillingState = StoreBillingState.idle;
    _storeBillingPlatform = StoreBillingPlatform.unavailable;
    _storeBillingMessage = null;
    _processingPurchases.clear();
    _activeBranchId = null;
  }

  @override
  void dispose() {
    _purchaseWatchdog?.cancel();
    unawaited(_billingSubscription?.cancel());
    unawaited(_billingService.dispose());
    super.dispose();
  }
}
