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
  Future<void> _purchaseEventSerial = Future<void>.value();
  Timer? _purchaseWatchdog;
  final List<StorePurchaseEvent> _queuedStorePurchaseEvents = [];
  _StorePurchaseIntent? _activePurchaseIntent;
  _StoreRestoreSession? _activeRestoreSession;
  int _billingSessionEpoch = 0;
  int _billingReconciliationSerial = 0;
  DateTime? _lastBillingReconciliationAt;
  DateTime? _lastStoreCatalogRefreshAt;
  DateTime? _lastGooglePurchaseDiscoveryAt;
  bool _didAttemptInitialGoogleReconciliation = false;
  bool _reconcileAfterSubscriptionManagement = false;
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
  final Set<String> _verifiedPurchaseEvents = {};
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
  bool get requiresInitialSubscriptionActivation {
    final current = _subscription;
    return current?.isAwaitingSubscription == true ||
        (current != null && !current.isUsable && _branches.isEmpty);
  }

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
  StoreBillingPlatform? get currentSubscriptionPlatform =>
      StoreBillingPlatformText.fromValue(_subscription?.billingProvider);
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
      final restoredAccount = await _repository!.restoreAccount();
      if (_account?.id != restoredAccount?.id) {
        final coldStart = _account == null && _stage == AppStage.configuring;
        _invalidateBillingSession(clearQueuedEvents: !coldStart);
      }
      _account = restoredAccount;
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
      if (snapshot.subscription.isAwaitingSubscription) {
        _noticeMessage =
            'تم إنشاء المتجر من دون تجربة مجانية. اختر اشتراكاً مدفوعاً للبدء.';
      }
      _stage = AppStage.ready;
      unawaited(_drainQueuedStorePurchaseEvents());
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
      unawaited(_drainQueuedStorePurchaseEvents());
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
      (events) {
        _purchaseEventSerial = _purchaseEventSerial
            .then((_) => _handleStorePurchaseUpdates(events))
            .catchError((Object error, StackTrace _) {
              _storeBillingState = StoreBillingState.unavailable;
              _storeBillingMessage = _friendlyError(error);
              notifyListeners();
            });
      },
      onError: (Object error) {
        _storeBillingState = StoreBillingState.unavailable;
        _storeBillingMessage = _friendlyError(error);
        notifyListeners();
      },
    );
  }

  Future<void> refreshStoreProducts() async {
    final account = _account;
    if (_stage != AppStage.ready || account == null) return;
    if (_storeBillingState == StoreBillingState.purchasing ||
        _storeBillingState == StoreBillingState.restoring ||
        _storeBillingState == StoreBillingState.pending) {
      return;
    }
    final refreshSerial = ++_storeProductRefreshSerial;
    final sessionEpoch = _billingSessionEpoch;
    final accountId = account.id;
    // لا تبقِ سعراً قديماً قابلاً للشراء بعد تغيّر الحساب أو بلد المتجر.
    _storeOffers.clear();
    _storeBillingState = StoreBillingState.loading;
    _storeBillingMessage = null;
    notifyListeners();
    try {
      final result = await _billingService
          .loadProducts(accountId: accountId)
          .timeout(_storeProductLoadTimeout);
      if (refreshSerial != _storeProductRefreshSerial ||
          !_billingContextMatches(sessionEpoch, accountId: accountId)) {
        return;
      }
      _storeBillingPlatform = result.platform;
      _storeOffers
        ..clear()
        ..addAll(
          result.offers.where(
            (offer) =>
                DamanakStoreCatalog.contains(result.platform, offer.productId),
          ),
        );
      _storeBillingState = result.available && _storeOffers.isNotEmpty
          ? StoreBillingState.ready
          : StoreBillingState.unavailable;
      if (_storeBillingState == StoreBillingState.ready) {
        _lastStoreCatalogRefreshAt = DateTime.now();
        unawaited(
          _reconcileGooglePurchasesAfterCatalogOnce(
            sessionEpoch: sessionEpoch,
            accountId: accountId,
          ),
        );
      }
      if (result.errorMessage != null) {
        _storeBillingMessage = result.errorMessage;
      } else if (result.missingProductIds.isNotEmpty) {
        _storeBillingMessage =
            'بعض منتجات الاشتراك لم تُنشأ أو تُفعّل في المتجر بعد.';
      } else if (result.offers.isEmpty) {
        _storeBillingMessage = 'لم يُرجع المتجر خططاً متاحة لهذا الحساب.';
      }
    } on TimeoutException {
      if (refreshSerial != _storeProductRefreshSerial ||
          !_billingContextMatches(sessionEpoch, accountId: accountId)) {
        return;
      }
      _storeOffers.clear();
      _storeBillingState = StoreBillingState.unavailable;
      _storeBillingMessage =
          'استغرق متجر التطبيقات وقتاً طويلاً. تحقق من الاتصال ثم أعد المحاولة.';
    } catch (error) {
      if (refreshSerial != _storeProductRefreshSerial ||
          !_billingContextMatches(sessionEpoch, accountId: accountId)) {
        return;
      }
      _storeOffers.clear();
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
    if (_storeBillingState != StoreBillingState.ready ||
        !_storeOffers.any(
          (item) =>
              item.key == offer.key &&
              item.productId == offer.productId &&
              item.basePlanId == offer.basePlanId,
        )) {
      _errorMessage = 'حدّث أسعار متجر التطبيقات قبل متابعة الاشتراك.';
      notifyListeners();
      return;
    }
    final account = _account!;
    final store = _store!;
    var subscription = _subscription;
    if (subscription?.isStoreSubscription == true) {
      final sessionEpoch = _billingSessionEpoch;
      _storeBillingState = StoreBillingState.purchasing;
      _storeBillingMessage =
          'جارٍ تأكيد حالة الاشتراك الحالية مع المتجر قبل فتح الدفع…';
      _errorMessage = null;
      notifyListeners();
      try {
        final refreshed = await _repository!
            .refreshStoreSubscription(store.id)
            .timeout(const Duration(seconds: 35));
        if (!_billingContextMatches(
          sessionEpoch,
          accountId: account.id,
          storeId: store.id,
        )) {
          return;
        }
        _subscription = refreshed;
        subscription = refreshed;
      } catch (error) {
        if (_billingContextMatches(
          sessionEpoch,
          accountId: account.id,
          storeId: store.id,
        )) {
          _storeBillingState = _idleStoreBillingState;
          _storeBillingMessage = null;
          _errorMessage =
              'تعذر تأكيد حالة الاشتراك الحالية قبل فتح الدفع. لم يبدأ أي اشتراك جديد؛ حاول الاستعادة أو أعد المحاولة لاحقاً.';
          notifyListeners();
        }
        return;
      }
    }
    final currentProvider = StoreBillingPlatformText.fromValue(
      subscription?.billingProvider,
    );
    if (subscription?.hasUnexpiredStorePeriod == true &&
        currentProvider != null &&
        currentProvider != _storeBillingPlatform) {
      _storeBillingState = _idleStoreBillingState;
      _storeBillingMessage = null;
      _errorMessage =
          'اشتراك المتجر ما زال سارياً عبر ${currentProvider.label}. أدره هناك أولاً لتجنب اشتراكين مدفوعين.';
      notifyListeners();
      return;
    }
    final currentCycle = switch (subscription?.billingCycle) {
      'monthly' when subscription?.hasUnexpiredStorePeriod == true =>
        BillingCycle.monthly,
      'yearly' when subscription?.hasUnexpiredStorePeriod == true =>
        BillingCycle.yearly,
      _ => null,
    };
    final requireExistingSubscription =
        subscription?.hasUnexpiredStorePeriod == true &&
        currentProvider == StoreBillingPlatform.googlePlay &&
        _storeBillingPlatform == StoreBillingPlatform.googlePlay;
    final intent = _StorePurchaseIntent(
      sessionEpoch: _billingSessionEpoch,
      accountId: account.id,
      storeId: store.id,
      platform: _storeBillingPlatform,
      productId: offer.productId,
      planId: offer.planId,
      cycle: offer.cycle,
      startedAt: DateTime.now(),
    );
    _activePurchaseIntent = intent;
    _storeBillingState = StoreBillingState.purchasing;
    _storeBillingMessage = 'أكمل العملية في نافذة المتجر الآمنة.';
    _startPurchaseWatchdog(intent);
    notifyListeners();
    try {
      await _billingService.purchase(
        offer,
        accountId: account.id,
        storeId: store.id,
        currentCycle: currentCycle,
        requireExistingSubscription: requireExistingSubscription,
      );
    } catch (error) {
      if (identical(_activePurchaseIntent, intent) &&
          _billingContextMatches(
            intent.sessionEpoch,
            accountId: intent.accountId,
            storeId: intent.storeId,
          )) {
        _finishPurchaseIntent(intent);
        _storeBillingState = _idleStoreBillingState;
        _errorMessage = _friendlyError(error);
        notifyListeners();
      }
    }
  }

  Future<void> restoreStorePurchases() async {
    if (_membership?.role.canManageSubscription != true) {
      _errorMessage = 'استعادة المشتريات متاحة لمالك المتجر فقط.';
      notifyListeners();
      return;
    }
    if (isDemo || _repository == null || _account == null || _store == null) {
      _errorMessage =
          'الاستعادة تحتاج نسخة مرتبطة بقاعدة ضمانك ومنشورة من المتجر.';
      notifyListeners();
      return;
    }
    final currentProvider = StoreBillingPlatformText.fromValue(
      _subscription?.billingProvider,
    );
    if (_subscription?.hasUnexpiredStorePeriod == true &&
        currentProvider != null &&
        _storeBillingPlatform != StoreBillingPlatform.unavailable &&
        currentProvider != _storeBillingPlatform) {
      _errorMessage =
          'الاشتراك الحالي مرتبط بـ${currentProvider.label}. نفّذ الاستعادة من جهاز يستخدم المتجر نفسه.';
      notifyListeners();
      return;
    }
    if (_storeBillingState == StoreBillingState.purchasing ||
        _storeBillingState == StoreBillingState.restoring) {
      return;
    }
    final account = _account!;
    final store = _store!;
    final session = _StoreRestoreSession(
      sessionEpoch: _billingSessionEpoch,
      accountId: account.id,
      storeId: store.id,
      silent: false,
    );
    _activeRestoreSession = session;
    _purchaseWatchdog?.cancel();
    _storeBillingState = StoreBillingState.restoring;
    _storeBillingMessage = 'جارٍ طلب مشترياتك السابقة من المتجر…';
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
    try {
      final result = await _billingService
          .restorePurchases(accountId: account.id, storeId: store.id)
          .timeout(_storeRestoreTimeout);
      if (!_restoreSessionMatches(session)) return;
      if (result.accountMismatchDetected &&
          (result.restoredPurchases ?? 0) == 0 &&
          result.pendingPurchases == 0) {
        throw StateError('STORE_ACCOUNT_MISMATCH');
      }
      if (result.pendingPurchases > 0 && (result.restoredPurchases ?? 0) == 0) {
        _storeBillingState = StoreBillingState.pending;
        _storeBillingMessage =
            'وجد المتجر دفعة معلّقة. لن تتفعّل الخطة قبل أن يؤكدها المتجر.';
        return;
      }
      if (result.restoredPurchases == 0) {
        await _finishRestoreWithoutStoreEvents(session);
        return;
      }

      final outcome = await session.completer.future.timeout(
        _storeRestoreTimeout,
        onTimeout: () => session.timeoutOutcome,
      );
      if (!_restoreSessionMatches(session)) return;
      switch (outcome) {
        case _RestoreVerificationOutcome.active:
          _noticeMessage = 'تمت استعادة الاشتراك والتحقق منه بأمان.';
          _storeBillingMessage = null;
        case _RestoreVerificationOutcome.inactive:
          _storeBillingMessage =
              'وجد المتجر اشتراكاً سابقاً، لكنه لا يمنح فترة فعّالة الآن.';
        case _RestoreVerificationOutcome.failed:
        // رسالة الخطأ التفصيلية عُرضت من مسار التحقق.
        case _RestoreVerificationOutcome.notFound:
          await _finishRestoreWithoutStoreEvents(session);
      }
    } catch (error) {
      if (_restoreSessionMatches(session)) {
        _errorMessage = _friendlyError(error);
        _storeBillingMessage =
            'تعذر التحقق من المشتريات السابقة على حساب المتجر الحالي.';
      }
    } finally {
      if (_restoreSessionMatches(session)) {
        _activeRestoreSession = null;
        if (_storeBillingState == StoreBillingState.restoring) {
          _storeBillingState = _idleStoreBillingState;
        }
        notifyListeners();
      }
    }
  }

  StoreBillingState get _idleStoreBillingState => _storeOffers.isEmpty
      ? StoreBillingState.unavailable
      : StoreBillingState.ready;

  void _startPurchaseWatchdog(_StorePurchaseIntent intent) {
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = Timer(_purchaseEventTimeout, () {
      if (!identical(_activePurchaseIntent, intent) ||
          _storeBillingState != StoreBillingState.purchasing) {
        return;
      }
      _finishPurchaseIntent(intent);
      _storeBillingState = _idleStoreBillingState;
      _storeBillingMessage =
          'لم يصل تأكيد من المتجر، ولم تُفعّل أي خطة. استخدم استعادة المشتريات قبل إعادة المحاولة.';
      notifyListeners();
    });
  }

  Future<void> openStoreSubscriptionManagement() async {
    if (_membership?.role.canManageSubscription != true) {
      _errorMessage = 'إدارة الاشتراك متاحة لمالك المتجر فقط.';
      notifyListeners();
      return;
    }
    final subscription = _subscription;
    final provider = StoreBillingPlatformText.fromValue(
      subscription?.billingProvider,
    );
    if (subscription == null || provider == null) {
      _errorMessage = 'لا يوجد اشتراك متجري يمكن إدارته حالياً.';
      notifyListeners();
      return;
    }
    try {
      final opened = await _billingService.openSubscriptionManagement(
        provider,
        productId: subscription.storeProductId,
      );
      if (!opened) {
        _errorMessage = 'تعذر فتح صفحة إدارة الاشتراك في ${provider.label}.';
      } else {
        _reconcileAfterSubscriptionManagement = true;
      }
    } catch (error) {
      _errorMessage = _friendlyError(error);
    }
    notifyListeners();
  }

  Future<void> _handleStorePurchaseUpdates(
    List<StorePurchaseEvent> events,
  ) async {
    if (_stage != AppStage.ready ||
        _repository == null ||
        _store == null ||
        _account == null) {
      _queuedStorePurchaseEvents.addAll(
        events.where(
          (event) =>
              event.status == StorePurchaseStatus.pending ||
              event.status == StorePurchaseStatus.purchased ||
              event.status == StorePurchaseStatus.restored,
        ),
      );
      return;
    }
    for (final event in events) {
      if (!DamanakStoreCatalog.contains(event.platform, event.productId)) {
        continue;
      }
      final intent = _activePurchaseIntent;
      final matchesIntent = intent?.matches(event) ?? false;
      final restoreSession = _activeRestoreSession;
      final matchesRestore =
          restoreSession != null && _restoreSessionMatches(restoreSession);
      final matchesBillingOperation = matchesIntent || matchesRestore;
      final appleAccountToken = _normalizedAppleBindingId(
        event.appAccountToken,
      );
      final matchesTrustedLateAppleTransaction =
          event.platform == StoreBillingPlatform.appStore &&
          !matchesBillingOperation &&
          appleAccountToken != null &&
          appleAccountToken.isNotEmpty &&
          appleAccountToken == _normalizedAppleBindingId(_store!.id);
      // Build 24 writes the immutable store id into StoreKit's appAccountToken.
      // This lets a transaction delivered after a crash or an Ask to Buy delay
      // finish safely without a live intent. Legacy account-bound or unbound
      // Apple transactions still require an explicit restore session so they
      // cannot attach to whichever workspace happens to be open.
      if (event.platform == StoreBillingPlatform.appStore &&
          !matchesBillingOperation &&
          !matchesTrustedLateAppleTransaction) {
        continue;
      }
      if (!_eventMatchesCurrentBillingContext(
        event,
        allowUnboundGoogle: matchesBillingOperation,
      )) {
        if (matchesIntent && intent != null) {
          _finishPurchaseIntent(intent);
          _storeBillingState = _idleStoreBillingState;
          _errorMessage = _friendlyError(StateError('STORE_ACCOUNT_MISMATCH'));
        }
        if (matchesRestore) {
          restoreSession.complete(_RestoreVerificationOutcome.failed);
          _errorMessage = _friendlyError(StateError('STORE_ACCOUNT_MISMATCH'));
        }
        continue;
      }
      switch (event.status) {
        case StorePurchaseStatus.pending:
          if (matchesIntent || matchesRestore) {
            if (matchesIntent && intent != null) {
              _purchaseWatchdog?.cancel();
            }
            _storeBillingState = StoreBillingState.pending;
            _storeBillingMessage =
                'الدفعة معلّقة لدى المتجر. لن تتفعّل الخطة قبل تأكيدها.';
          }
        case StorePurchaseStatus.canceled:
          if (matchesIntent && intent != null) {
            _finishPurchaseIntent(intent);
            _storeBillingState = _idleStoreBillingState;
            _storeBillingMessage = null;
            _noticeMessage = 'أُغلقت عملية الشراء من دون تأكيد اشتراك.';
          }
        case StorePurchaseStatus.error:
          if (matchesIntent && intent != null) {
            _finishPurchaseIntent(intent);
            _storeBillingState = _idleStoreBillingState;
            _errorMessage = _friendlyStoreEventError(event);
          }
        case StorePurchaseStatus.purchased:
        case StorePurchaseStatus.restored:
          await _verifyAndCompleteStorePurchase(
            event,
            intent: matchesIntent ? intent : null,
            restoreSession: matchesRestore ? restoreSession : null,
            displayProgress:
                matchesIntent || (matchesRestore && !restoreSession.silent),
          );
      }
    }
    notifyListeners();
  }

  Future<void> _verifyAndCompleteStorePurchase(
    StorePurchaseEvent event, {
    _StorePurchaseIntent? intent,
    _StoreRestoreSession? restoreSession,
    required bool displayProgress,
  }) async {
    final sessionEpoch = _billingSessionEpoch;
    final eventKey = '$sessionEpoch:${event.key}';
    if (_verifiedPurchaseEvents.contains(eventKey)) {
      if (intent != null && identical(_activePurchaseIntent, intent)) {
        _finishPurchaseIntent(intent);
        _storeBillingState = _idleStoreBillingState;
        _storeBillingMessage = null;
        _noticeMessage = 'سبق التحقق من هذه العملية بأمان.';
      }
      if (restoreSession != null && _restoreSessionMatches(restoreSession)) {
        if (_subscription?.isUsable == true) {
          restoreSession.complete(_RestoreVerificationOutcome.active);
        } else {
          restoreSession.sawInactivePurchase = true;
        }
      }
      return;
    }
    if (!_processingPurchases.add(eventKey)) return;
    final account = _account;
    final store = _store;
    final requiresInitialWorkspaceReload =
        requiresInitialSubscriptionActivation;
    try {
      if (_repository == null || store == null || account == null) {
        throw StateError('STORE_VERIFICATION_REQUIRES_CLOUD');
      }
      if (_membership?.role.canManageSubscription != true) {
        throw StateError('STORE_OWNER_REQUIRED');
      }
      if (!_eventMatchesCurrentBillingContext(
        event,
        allowUnboundGoogle: intent != null || restoreSession != null,
      )) {
        throw StateError('STORE_ACCOUNT_MISMATCH');
      }
      if (displayProgress) {
        _storeBillingState = restoreSession == null
            ? StoreBillingState.purchasing
            : StoreBillingState.restoring;
        _storeBillingMessage = 'جارٍ التحقق من إيصال المتجر بأمان…';
        notifyListeners();
      }
      final verifiedSubscription = await _repository!
          .verifyStorePurchase(
            storeId: store.id,
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
        try {
          await _billingService
              .completePurchase(event)
              .timeout(const Duration(seconds: 20));
        } catch (_) {
          final completionContextMatches = _billingContextMatches(
            sessionEpoch,
            accountId: account.id,
            storeId: store.id,
          );
          if (completionContextMatches) {
            final workspaceReady = await _prepareInitialActivationWorkspace(
              verifiedSubscription: verifiedSubscription,
              requiresReload: requiresInitialWorkspaceReload,
              sessionEpoch: sessionEpoch,
              accountId: account.id,
              storeId: store.id,
            );
            if (!workspaceReady) {
              _finishBillingOperationAfterWorkspacePreparationFailure(
                intent: intent,
                restoreSession: restoreSession,
                displayProgress: displayProgress,
              );
              return;
            }
            if (!_billingContextMatches(
              sessionEpoch,
              accountId: account.id,
              storeId: store.id,
            )) {
              return;
            }
            _subscription = verifiedSubscription;
          }
          final operationMatches =
              completionContextMatches &&
              (intent == null || identical(_activePurchaseIntent, intent)) &&
              (restoreSession == null ||
                  _restoreSessionMatches(restoreSession));
          if (operationMatches) {
            if (intent != null) _finishPurchaseIntent(intent);
            if (restoreSession != null) {
              if (verifiedSubscription.isUsable) {
                restoreSession.complete(_RestoreVerificationOutcome.active);
              } else {
                restoreSession.sawInactivePurchase = true;
              }
            }
            if (displayProgress) {
              _storeBillingState = _idleStoreBillingState;
              _storeBillingMessage = null;
            }
            _errorMessage =
                'تم التحقق من الاشتراك، لكن تعذر إغلاق معاملة المتجر. لا تدفع مرة أخرى؛ استخدم الاستعادة لإكمالها.';
          }
          return;
        }
      }
      if (!_billingContextMatches(
        sessionEpoch,
        accountId: account.id,
        storeId: store.id,
      )) {
        return;
      }
      final workspaceReady = await _prepareInitialActivationWorkspace(
        verifiedSubscription: verifiedSubscription,
        requiresReload: requiresInitialWorkspaceReload,
        sessionEpoch: sessionEpoch,
        accountId: account.id,
        storeId: store.id,
      );
      if (!workspaceReady) {
        _finishBillingOperationAfterWorkspacePreparationFailure(
          intent: intent,
          restoreSession: restoreSession,
          displayProgress: displayProgress,
        );
        return;
      }
      if (!_billingContextMatches(
        sessionEpoch,
        accountId: account.id,
        storeId: store.id,
      )) {
        return;
      }
      _rememberVerifiedPurchaseEvent(eventKey);
      _subscription = verifiedSubscription;
      final operationMatches =
          (intent == null || identical(_activePurchaseIntent, intent)) &&
          (restoreSession == null || _restoreSessionMatches(restoreSession));
      if (operationMatches && intent != null) _finishPurchaseIntent(intent);
      if (operationMatches && restoreSession != null) {
        if (verifiedSubscription.isUsable) {
          restoreSession.complete(_RestoreVerificationOutcome.active);
        } else {
          restoreSession.sawInactivePurchase = true;
        }
      }
      final canResolveLatePending =
          intent == null &&
          restoreSession == null &&
          _activePurchaseIntent == null &&
          _activeRestoreSession == null &&
          _storeBillingState == StoreBillingState.pending;
      if ((displayProgress && operationMatches) || canResolveLatePending) {
        _storeBillingState = _idleStoreBillingState;
        _storeBillingMessage = verifiedSubscription.isUsable
            ? null
            : 'تحققنا من العملية، لكنها لا تمنح فترة اشتراك فعّالة الآن.';
      }
      if (operationMatches && restoreSession != null) {
        if (!restoreSession.silent && verifiedSubscription.isUsable) {
          _noticeMessage = 'تمت استعادة الاشتراك والتحقق منه بأمان.';
        }
      } else if (operationMatches && intent != null) {
        final changeDeferred =
            verifiedSubscription.plan.id != intent.planId ||
            verifiedSubscription.billingCycle != intent.cycle.value;
        _noticeMessage = changeDeferred
            ? 'قبل المتجر طلب التغيير. ستظهر الخطة الجديدة عند موعد تطبيقها الذي حدده المتجر.'
            : 'تم التحقق من الاشتراك وتحديث حالته من ${event.platform.label}.';
      } else if (_activePurchaseIntent == null &&
          _activeRestoreSession == null &&
          event.status == StorePurchaseStatus.restored &&
          verifiedSubscription.isUsable) {
        _noticeMessage = 'وصلت الاستعادة وتحققنا من الاشتراك بأمان.';
      }
    } catch (error) {
      final contextMatches =
          account != null &&
          store != null &&
          _billingContextMatches(
            sessionEpoch,
            accountId: account.id,
            storeId: store.id,
          );
      if (contextMatches) {
        final operationMatches =
            (intent == null || identical(_activePurchaseIntent, intent)) &&
            (restoreSession == null || _restoreSessionMatches(restoreSession));
        if (operationMatches && intent != null) _finishPurchaseIntent(intent);
        if (operationMatches && restoreSession != null) {
          restoreSession.verificationFailed = true;
        }
        if (displayProgress && operationMatches) {
          _storeBillingState = _idleStoreBillingState;
          _storeBillingMessage = null;
        }
        final reportFailure =
            intent != null ||
            (restoreSession != null && !restoreSession.silent) ||
            (intent == null &&
                restoreSession == null &&
                _activePurchaseIntent == null &&
                _activeRestoreSession == null);
        if (reportFailure) {
          _errorMessage = _friendlyError(error);
        }
      }
    } finally {
      _processingPurchases.remove(eventKey);
    }
  }

  void _rememberVerifiedPurchaseEvent(String eventKey) {
    _verifiedPurchaseEvents.add(eventKey);
    while (_verifiedPurchaseEvents.length > 256) {
      _verifiedPurchaseEvents.remove(_verifiedPurchaseEvents.first);
    }
  }

  Future<bool> _prepareInitialActivationWorkspace({
    required SubscriptionInfo verifiedSubscription,
    required bool requiresReload,
    required int sessionEpoch,
    required String accountId,
    required String storeId,
  }) async {
    if (!requiresReload || !verifiedSubscription.isUsable) return true;
    if (!_billingContextMatches(
      sessionEpoch,
      accountId: accountId,
      storeId: storeId,
    )) {
      return false;
    }
    _storeBillingMessage = 'تم التحقق من الاشتراك. جارٍ تهيئة المتجر…';
    notifyListeners();
    try {
      final loaded = await _loadWorkspaceData(
        expectedBillingSessionEpoch: sessionEpoch,
        expectedAccountId: accountId,
        expectedStoreId: storeId,
      );
      if (!loaded) return false;
      if (!_branches.any((branch) => branch.isMain && branch.isActive)) {
        throw StateError('INITIAL_BRANCH_MISSING');
      }
      return true;
    } catch (_) {
      if (_billingContextMatches(
        sessionEpoch,
        accountId: accountId,
        storeId: storeId,
      )) {
        _storeBillingState = _idleStoreBillingState;
        _storeBillingMessage = null;
        _errorMessage =
            'تم التحقق من الاشتراك، لكن تعذّر تهيئة بيانات المتجر. أغلق التطبيق وافتحه مجدداً؛ لا تدف مرة أخرى.';
        notifyListeners();
      }
      return false;
    }
  }

  void _finishBillingOperationAfterWorkspacePreparationFailure({
    _StorePurchaseIntent? intent,
    _StoreRestoreSession? restoreSession,
    required bool displayProgress,
  }) {
    if (intent != null && identical(_activePurchaseIntent, intent)) {
      _finishPurchaseIntent(intent);
    }
    if (restoreSession != null && _restoreSessionMatches(restoreSession)) {
      restoreSession.verificationFailed = true;
      restoreSession.complete(_RestoreVerificationOutcome.failed);
    }
    if (displayProgress) {
      _storeBillingState = _idleStoreBillingState;
      _storeBillingMessage = null;
    }
  }

  void handleAppResumed() {
    unawaited(_reconcileStoreBillingAfterResume());
  }

  void cancelStoreBillingReconciliation() {
    _billingReconciliationSerial += 1;
  }

  Future<void> _reconcileStoreBillingAfterResume() async {
    if (_stage != AppStage.ready ||
        _repository == null ||
        _account == null ||
        _store == null ||
        _membership?.role.canManageSubscription != true ||
        isDemo) {
      return;
    }
    final now = DateTime.now();
    final force = _reconcileAfterSubscriptionManagement;
    final last = _lastBillingReconciliationAt;
    if (!force &&
        last != null &&
        now.difference(last) < const Duration(minutes: 2)) {
      return;
    }
    _reconcileAfterSubscriptionManagement = false;
    _lastBillingReconciliationAt = now;
    final serial = ++_billingReconciliationSerial;
    final sessionEpoch = _billingSessionEpoch;
    final accountId = _account!.id;
    final storeId = _store!.id;

    await _refreshStoreSubscriptionIfStale(
      force: force,
      maxAge: const Duration(minutes: 15),
    );
    if (serial != _billingReconciliationSerial ||
        !_billingContextMatches(
          sessionEpoch,
          accountId: accountId,
          storeId: storeId,
        )) {
      return;
    }
    await _reconcileGooglePurchasesSilently(
      sessionEpoch: sessionEpoch,
      accountId: accountId,
      storeId: storeId,
      force: force,
    );
    if (serial != _billingReconciliationSerial ||
        !_billingContextMatches(
          sessionEpoch,
          accountId: accountId,
          storeId: storeId,
        )) {
      return;
    }
    final catalogAge = _lastStoreCatalogRefreshAt == null
        ? null
        : now.difference(_lastStoreCatalogRefreshAt!);
    if (force ||
        catalogAge == null ||
        catalogAge >= const Duration(minutes: 30)) {
      await refreshStoreProducts();
    }
  }

  Future<void> _reconcileGooglePurchasesSilently({
    required int sessionEpoch,
    required String accountId,
    required String storeId,
    bool force = false,
  }) async {
    if (_storeBillingPlatform != StoreBillingPlatform.googlePlay ||
        _activePurchaseIntent != null ||
        _activeRestoreSession != null) {
      return;
    }
    final now = DateTime.now();
    final lastDiscovery = _lastGooglePurchaseDiscoveryAt;
    if (!force &&
        lastDiscovery != null &&
        now.difference(lastDiscovery) < const Duration(minutes: 15)) {
      return;
    }
    final currentProvider = StoreBillingPlatformText.fromValue(
      _subscription?.billingProvider,
    );
    if (_subscription?.hasUnexpiredStorePeriod == true &&
        currentProvider != null &&
        currentProvider != StoreBillingPlatform.googlePlay) {
      return;
    }
    _lastGooglePurchaseDiscoveryAt = now;
    final session = _StoreRestoreSession(
      sessionEpoch: sessionEpoch,
      accountId: accountId,
      storeId: storeId,
      silent: true,
    );
    _activeRestoreSession = session;
    try {
      final result = await _billingService
          .restorePurchases(accountId: accountId, storeId: storeId)
          .timeout(const Duration(seconds: 12));
      if (!_restoreSessionMatches(session) ||
          (result.restoredPurchases ?? 0) == 0) {
        return;
      }
      await session.completer.future.timeout(
        const Duration(seconds: 35),
        onTimeout: () => session.timeoutOutcome,
      );
    } catch (_) {
      // Reconciliation is opportunistic. The explicit restore action remains
      // available with a visible, actionable error if this background pass
      // cannot contact Google Play or the verification backend.
    } finally {
      if (_restoreSessionMatches(session)) _activeRestoreSession = null;
    }
  }

  Future<void> _reconcileGooglePurchasesAfterCatalogOnce({
    required int sessionEpoch,
    required String accountId,
  }) async {
    final store = _store;
    if (_didAttemptInitialGoogleReconciliation ||
        _storeBillingPlatform != StoreBillingPlatform.googlePlay ||
        store == null ||
        _membership?.role.canManageSubscription != true ||
        isDemo ||
        !_billingContextMatches(
          sessionEpoch,
          accountId: accountId,
          storeId: store.id,
        )) {
      return;
    }
    if (_activeRestoreSession?.silent == true) {
      _didAttemptInitialGoogleReconciliation = true;
      return;
    }
    if (_activePurchaseIntent != null || _activeRestoreSession != null) return;

    _didAttemptInitialGoogleReconciliation = true;
    await _reconcileGooglePurchasesSilently(
      sessionEpoch: sessionEpoch,
      accountId: accountId,
      storeId: store.id,
    );
  }

  Future<void> _finishRestoreWithoutStoreEvents(
    _StoreRestoreSession session,
  ) async {
    if (!_restoreSessionMatches(session)) return;
    final current = _subscription;
    final requiresInitialWorkspaceReload =
        requiresInitialSubscriptionActivation;
    if (current?.isStoreSubscription == true ||
        requiresInitialWorkspaceReload) {
      try {
        final refreshed = await _repository!
            .refreshStoreSubscription(session.storeId)
            .timeout(const Duration(seconds: 35));
        if (!_restoreSessionMatches(session)) return;
        if (refreshed.isUsable) {
          final workspaceReady = await _prepareInitialActivationWorkspace(
            verifiedSubscription: refreshed,
            requiresReload: requiresInitialWorkspaceReload,
            sessionEpoch: session.sessionEpoch,
            accountId: session.accountId,
            storeId: session.storeId,
          );
          if (!workspaceReady || !_restoreSessionMatches(session)) return;
          _subscription = refreshed;
          _noticeMessage =
              'لم يرسل المتجر عملية جديدة، وتم تحديث حالة الاشتراك الحالي من الخادم.';
          _storeBillingMessage = null;
          return;
        }
        _subscription = refreshed;
      } catch (_) {
        if (!_restoreSessionMatches(session)) return;
      }
    }
    _storeBillingMessage =
        'لم نجد مشتريات قابلة للاستعادة على حساب المتجر الحالي.';
  }

  bool _restoreSessionMatches(_StoreRestoreSession session) =>
      identical(_activeRestoreSession, session) &&
      _billingContextMatches(
        session.sessionEpoch,
        accountId: session.accountId,
        storeId: session.storeId,
      );

  bool _billingContextMatches(
    int sessionEpoch, {
    required String accountId,
    String? storeId,
  }) =>
      sessionEpoch == _billingSessionEpoch &&
      _account?.id == accountId &&
      (storeId == null || _store?.id == storeId);

  bool _eventMatchesCurrentBillingContext(
    StorePurchaseEvent event, {
    bool allowUnboundGoogle = false,
  }) {
    final account = _account;
    final store = _store;
    if (account == null || store == null) return false;
    if (event.accountId != null && event.accountId != account.id) return false;
    if (event.storeId != null && event.storeId != store.id) return false;
    if (event.platform == StoreBillingPlatform.googlePlay &&
        !allowUnboundGoogle &&
        (event.accountId == null || event.storeId == null)) {
      return false;
    }
    if (event.platform == StoreBillingPlatform.appStore) {
      final token = _normalizedAppleBindingId(event.appAccountToken);
      if (token != null &&
          token != _normalizedAppleBindingId(account.id) &&
          token != _normalizedAppleBindingId(store.id)) {
        return false;
      }
    }
    return true;
  }

  void _finishPurchaseIntent(_StorePurchaseIntent intent) {
    if (!identical(_activePurchaseIntent, intent)) return;
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = null;
    _activePurchaseIntent = null;
  }

  Future<void> _drainQueuedStorePurchaseEvents() async {
    if (_queuedStorePurchaseEvents.isEmpty || _stage != AppStage.ready) return;
    final byKey = <String, StorePurchaseEvent>{
      for (final event in _queuedStorePurchaseEvents) event.key: event,
    };
    _queuedStorePurchaseEvents.clear();
    await _handleStorePurchaseUpdates(byKey.values.toList(growable: false));
  }

  String _friendlyStoreEventError(StorePurchaseEvent event) {
    final code = event.errorCode?.trim();
    final message = event.errorMessage?.trim();
    return _friendlyError(
      StateError(
        [
          if (code != null && code.isNotEmpty) code,
          if (message != null && message.isNotEmpty) message,
          if ((code == null || code.isEmpty) &&
              (message == null || message.isEmpty))
            'STORE_PURCHASE_FAILED',
        ].join(' '),
      ),
    );
  }

  Future<void> _refreshStoreSubscriptionIfStale({
    bool force = false,
    Duration maxAge = const Duration(hours: 6),
  }) async {
    final subscription = _subscription;
    final store = _store;
    final account = _account;
    if (_repository == null ||
        account == null ||
        store == null ||
        subscription == null ||
        !subscription.isStoreSubscription ||
        _membership?.role.canManageSubscription != true) {
      return;
    }
    final verifiedAt = subscription.lastVerifiedAt;
    if (!force &&
        verifiedAt != null &&
        DateTime.now().difference(verifiedAt.toLocal()) < maxAge) {
      return;
    }
    final sessionEpoch = _billingSessionEpoch;
    try {
      final refreshed = await _repository!.refreshStoreSubscription(store.id);
      if (!_billingContextMatches(
        sessionEpoch,
        accountId: account.id,
        storeId: store.id,
      )) {
        return;
      }
      _subscription = refreshed;
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
    unawaited(_drainQueuedStorePurchaseEvents());
  }

  void _applySnapshot(WorkspaceSnapshot snapshot) {
    if (_store != null && _store!.id != snapshot.store.id) {
      _invalidateBillingSession(clearQueuedEvents: true);
    }
    _store = snapshot.store;
    _membership = snapshot.membership;
    _subscription = snapshot.subscription;
  }

  Future<bool> _loadWorkspaceData({
    int? expectedBillingSessionEpoch,
    String? expectedAccountId,
    String? expectedStoreId,
  }) async {
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
    if (expectedBillingSessionEpoch != null &&
        !_billingContextMatches(
          expectedBillingSessionEpoch,
          accountId: expectedAccountId!,
          storeId: expectedStoreId!,
        )) {
      return false;
    }
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
    return true;
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
    if (value.contains('store_purchase_in_progress')) {
      return 'توجد عملية شراء مفتوحة بالفعل. أكملها أو أغلق نافذة المتجر أولاً.';
    }
    if (value.contains('google_subscription_lookup_timeout') ||
        value.contains('google_subscription_lookup_failed')) {
      return 'تعذر تأكيد اشتراك Google Play الحالي. لم يبدأ ضمانك اشتراكاً جديداً؛ تحقق من الاتصال ثم حاول مجدداً.';
    }
    if (value.contains('google_subscription_account_conflict')) {
      return 'وجد Google Play اشتراك ضمانك لحساب آخر. استخدم حساب ضمانك الأصلي أو غيّر حساب Google Play.';
    }
    if (value.contains('google_subscription_store_conflict')) {
      return 'هذا اشتراك Google Play مرتبط بمتجر ضمانك آخر، ولا يمكن نقله تلقائياً.';
    }
    if (value.contains('google_subscription_pending')) {
      return 'توجد دفعة Google Play معلّقة. انتظر قرار المتجر قبل بدء تغيير آخر.';
    }
    if (value.contains('store_purchase_pending_canceled')) {
      return 'ألغى Google Play العملية المعلّقة ولم تتغير خطتك. استخدم استعادة المشتريات لتحديث الاشتراك الحالي.';
    }
    if (value.contains('store_purchase_pending')) {
      return 'ما زالت العملية معلّقة لدى المتجر. لم تتغير خطتك؛ انتظر تأكيد المتجر ثم استخدم الاستعادة.';
    }
    if (value.contains('google_multiple_subscriptions')) {
      return 'وجد Google Play أكثر من اشتراك ضمانك على الحساب نفسه. أوقف الاشتراك الزائد من Google Play ثم استخدم الاستعادة.';
    }
    if (value.contains('google_existing_subscription_not_found')) {
      return 'لم يعثر Google Play على الاشتراك الحالي المطلوب تغييره. تأكد من حساب المتجر ثم استخدم الاستعادة.';
    }
    if (value.contains('google_existing_subscription_restore_required')) {
      return 'وجد Google Play اشتراكاً لهذا المتجر لم يكتمل ربطه بعد. لم يبدأ شراء جديد؛ استخدم استعادة المشتريات أولاً.';
    }
    if (value.contains('google_existing_cycle_unknown') ||
        value.contains('google_subscription_transition_invalid')) {
      return 'تعذر تحديد انتقال الاشتراك بأمان. حدّث حالة الاشتراك ثم حاول مجدداً.';
    }
    if (value.contains('google_subscription_already_active')) {
      return 'هذه الخطة ودورة الفوترة فعّالتان بالفعل.';
    }
    if (value.contains('store_account_mismatch') ||
        value.contains('apple_account_mismatch') ||
        value.contains('google_account_mismatch') ||
        value.contains('subscription_account_mismatch')) {
      return 'هذه المشتريات مرتبطة بحساب ضمانك آخر. سجّل الدخول إلى الحساب الأصلي ثم استخدم الاستعادة.';
    }
    if (value.contains('store_purchase_already_linked') ||
        value.contains('receipt_already_linked')) {
      return 'هذا الاشتراك مرتبط بمتجر ضمانك آخر، ولا يمكن نقله تلقائياً لحماية الفوترة.';
    }
    if (value.contains('store_provider_conflict') ||
        value.contains('billing_provider_conflict')) {
      return 'يوجد اشتراك سارٍ عبر متجر آخر. أوقف تجديده هناك أولاً لتجنب فوترة مزدوجة.';
    }
    if (value.contains('store_existing_subscription_required') ||
        value.contains('store_subscription_lookup_failed') ||
        value.contains('store_subscription_history_unavailable')) {
      return 'تعذر تأكيد الاشتراك الحالي قبل تغييره. لم يبدأ ضمانك اشتراكاً جديداً؛ تحقق من حساب المتجر ثم حاول مجدداً.';
    }
    if (value.contains('item_already_owned') ||
        value.contains('itemalreadyowned')) {
      return 'الاشتراك مملوك بالفعل على حساب المتجر الحالي. استخدم استعادة المشتريات بدلاً من الدفع مرة أخرى.';
    }
    if (value.contains('store_rate_limited') ||
        value.contains('store_verification_rate_limited') ||
        value.contains('status: 429')) {
      return 'تكررت محاولات التحقق خلال وقت قصير. انتظر قليلاً ثم استخدم الاستعادة مرة واحدة.';
    }
    if (value.contains('purchase_conflict')) {
      return 'هذه المشتريات مرتبطة مسبقاً بحساب أو متجر ضمانك آخر، ولا يمكن نقلها تلقائياً.';
    }
    if (value.contains('purchase_not_valid')) {
      return 'لم يؤكد المتجر صلاحية هذه العملية. راجع حساب المتجر ثم استخدم الاستعادة.';
    }
    if (value.contains('sandbox_not_available')) {
      return 'تعذر التحقق من عملية نسخة الاختبار. لا تدفع مرة أخرى، وحاول الاستعادة بعد قليل.';
    }
    if (value.contains('purchase_provider_unavailable') ||
        value.contains('purchase_verification_unavailable')) {
      return 'خدمة التحقق لدى المتجر غير متاحة مؤقتاً. الدفع محفوظ؛ لا تكرر الشراء واستخدم الاستعادة لاحقاً.';
    }
    if (value.contains('sandbox_tester_not_allowed')) {
      return 'تعذر تفعيل شراء نسخة الاختبار. لا تدفع مرة أخرى، وأرسل تفاصيل المحاولة إلى دعم ضمانك.';
    }
    if (value.contains('billing_unavailable') ||
        value.contains('service_unavailable') ||
        value.contains('network_error')) {
      return 'تعذر الاتصال بمتجر التطبيقات. تحقق من الاتصال وحساب المتجر ثم حاول مجدداً.';
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

  void _invalidateBillingSession({bool clearQueuedEvents = false}) {
    _billingSessionEpoch += 1;
    _billingReconciliationSerial += 1;
    _storeProductRefreshSerial += 1;
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = null;
    _activePurchaseIntent = null;
    _activeRestoreSession?.complete(_RestoreVerificationOutcome.failed);
    _activeRestoreSession = null;
    _reconcileAfterSubscriptionManagement = false;
    _lastBillingReconciliationAt = null;
    _lastStoreCatalogRefreshAt = null;
    _lastGooglePurchaseDiscoveryAt = null;
    _didAttemptInitialGoogleReconciliation = false;
    _verifiedPurchaseEvents.clear();
    if (clearQueuedEvents) _queuedStorePurchaseEvents.clear();
  }

  void _clearData() {
    _invalidateBillingSession(clearQueuedEvents: true);
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
    _verifiedPurchaseEvents.clear();
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

String? _normalizedAppleBindingId(String? value) {
  final normalized = value?.trim().toLowerCase();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

class _StorePurchaseIntent {
  const _StorePurchaseIntent({
    required this.sessionEpoch,
    required this.accountId,
    required this.storeId,
    required this.platform,
    required this.productId,
    required this.planId,
    required this.cycle,
    required this.startedAt,
  });

  final int sessionEpoch;
  final String accountId;
  final String storeId;
  final StoreBillingPlatform platform;
  final String productId;
  final String planId;
  final BillingCycle cycle;
  final DateTime startedAt;

  bool matches(StorePurchaseEvent event) {
    if (event.platform != platform) return false;
    // عند التخفيض المؤجل قد يعيد Google التوكن الجديد مع product القديم حتى
    // موعد التجديد. الربط الدقيق بالحساب والمتجر هو الحارس المحلي هنا، ثم
    // يحسم الخادم المنتج الفعلي من Google Play.
    if (platform == StoreBillingPlatform.googlePlay) {
      if (event.accountId != accountId || event.storeId != storeId) {
        return false;
      }
      if (event.productId != productId &&
          !event.pendingProductIds.contains(productId)) {
        return false;
      }
    } else {
      if (event.productId != productId) return false;
      final token = _normalizedAppleBindingId(event.appAccountToken);
      if (token != null &&
          token != _normalizedAppleBindingId(accountId) &&
          token != _normalizedAppleBindingId(storeId)) {
        return false;
      }
    }
    if (event.accountId != null && event.accountId != accountId) return false;
    if (event.storeId != null && event.storeId != storeId) return false;
    final timestamp = int.tryParse(event.transactionDate ?? '');
    if (timestamp == null) return true;
    final transactionAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return !transactionAt.isBefore(
      startedAt.subtract(const Duration(minutes: 2)),
    );
  }
}

enum _RestoreVerificationOutcome { active, inactive, failed, notFound }

class _StoreRestoreSession {
  _StoreRestoreSession({
    required this.sessionEpoch,
    required this.accountId,
    required this.storeId,
    required this.silent,
  });

  final int sessionEpoch;
  final String accountId;
  final String storeId;
  final bool silent;
  final Completer<_RestoreVerificationOutcome> completer = Completer();
  bool sawInactivePurchase = false;
  bool verificationFailed = false;

  _RestoreVerificationOutcome get timeoutOutcome {
    if (sawInactivePurchase) return _RestoreVerificationOutcome.inactive;
    if (verificationFailed) return _RestoreVerificationOutcome.failed;
    return _RestoreVerificationOutcome.notFound;
  }

  void complete(_RestoreVerificationOutcome outcome) {
    if (!completer.isCompleted) completer.complete(outcome);
  }
}
