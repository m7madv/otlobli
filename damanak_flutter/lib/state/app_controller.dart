import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/damanak_repository.dart';
import '../data/demo_repository.dart';
import '../features/subscriptions/domain/subscription_flow.dart';
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
  static const String _billingVerificationInProgressMessage =
      'جارٍ التحقق من إيصال متجر سابق. انتظر اكتمال التحقق قبل بدء شراء أو استعادة أخرى.';
  static const String _billingStateChangedDuringPreflightMessage =
      'تغيّرت حالة الاشتراك أثناء الفحص. لم نفتح الدفع؛ أعد المحاولة لتأكيد الحالة الجديدة أولاً.';

  AppController.withRepository(
    DamanakRepository repository, {
    StoreBillingService? billingService,
    Duration storeProductLoadTimeout = const Duration(seconds: 24),
    Duration storeRestoreTimeout = const Duration(seconds: 12),
    Duration storePurchaseVerificationTimeout = const Duration(seconds: 65),
    Duration storeRestoreVerificationTimeout = const Duration(seconds: 75),
    Duration storeRestoreVerificationSettleTimeout = const Duration(
      seconds: 35,
    ),
    Duration storeRestoreEventQuietPeriod = const Duration(milliseconds: 200),
    Duration initialActivationWorkspaceTimeout = const Duration(seconds: 20),
    Duration purchaseEventTimeout = const Duration(minutes: 2),
    Duration purchaseResumeGracePeriod = const Duration(seconds: 12),
  }) : _repository = repository,
       _billingService =
           billingService ?? const UnavailableStoreBillingService(),
       _storeProductLoadTimeout = storeProductLoadTimeout,
       _storeRestoreTimeout = storeRestoreTimeout,
       _storePurchaseVerificationTimeout = storePurchaseVerificationTimeout,
       _storeRestoreVerificationTimeout = storeRestoreVerificationTimeout,
       _storeRestoreVerificationSettleTimeout =
           storeRestoreVerificationSettleTimeout,
       _storeRestoreEventQuietPeriod = storeRestoreEventQuietPeriod,
       _initialActivationWorkspaceTimeout = initialActivationWorkspaceTimeout,
       _purchaseEventTimeout = purchaseEventTimeout,
       _purchaseResumeGracePeriod = purchaseResumeGracePeriod {
    _listenToStoreBilling();
  }

  AppController.unconfigured({
    StoreBillingService? billingService,
    Duration storeProductLoadTimeout = const Duration(seconds: 24),
    Duration storeRestoreTimeout = const Duration(seconds: 12),
    Duration storePurchaseVerificationTimeout = const Duration(seconds: 65),
    Duration storeRestoreVerificationTimeout = const Duration(seconds: 75),
    Duration storeRestoreVerificationSettleTimeout = const Duration(
      seconds: 35,
    ),
    Duration storeRestoreEventQuietPeriod = const Duration(milliseconds: 200),
    Duration initialActivationWorkspaceTimeout = const Duration(seconds: 20),
    Duration purchaseEventTimeout = const Duration(minutes: 2),
    Duration purchaseResumeGracePeriod = const Duration(seconds: 12),
  }) : _billingService =
           billingService ?? const UnavailableStoreBillingService(),
       _storeProductLoadTimeout = storeProductLoadTimeout,
       _storeRestoreTimeout = storeRestoreTimeout,
       _storePurchaseVerificationTimeout = storePurchaseVerificationTimeout,
       _storeRestoreVerificationTimeout = storeRestoreVerificationTimeout,
       _storeRestoreVerificationSettleTimeout =
           storeRestoreVerificationSettleTimeout,
       _storeRestoreEventQuietPeriod = storeRestoreEventQuietPeriod,
       _initialActivationWorkspaceTimeout = initialActivationWorkspaceTimeout,
       _purchaseEventTimeout = purchaseEventTimeout,
       _purchaseResumeGracePeriod = purchaseResumeGracePeriod {
    _listenToStoreBilling();
  }

  DamanakRepository? _repository;
  final StoreBillingService _billingService;
  final Duration _storeProductLoadTimeout;
  final Duration _storeRestoreTimeout;
  final Duration _storePurchaseVerificationTimeout;
  final Duration _storeRestoreVerificationTimeout;
  final Duration _storeRestoreVerificationSettleTimeout;
  final Duration _storeRestoreEventQuietPeriod;
  final Duration _initialActivationWorkspaceTimeout;
  final Duration _purchaseEventTimeout;
  final Duration _purchaseResumeGracePeriod;
  StreamSubscription<List<StorePurchaseEvent>>? _billingSubscription;
  Future<void> _purchaseEventSerial = Future<void>.value();
  int _purchaseEventEnqueueRevision = 0;
  Timer? _purchaseWatchdog;
  final List<StorePurchaseEvent> _queuedStorePurchaseEvents = [];
  _StorePurchaseIntent? _activePurchaseIntent;
  _StoreRestoreSession? _activeRestoreSession;
  int _billingSessionEpoch = 0;
  int _billingOperationGeneration = 0;
  int _billingReconciliationSerial = 0;
  int _storeSubscriptionRefreshSerial = 0;
  BillingScope? _storeSubscriptionRefreshScope;
  Future<SubscriptionInfo>? _storeSubscriptionRefreshInFlight;
  DateTime? _lastBillingReconciliationAt;
  DateTime? _lastStoreCatalogRefreshAt;
  DateTime? _lastGooglePurchaseDiscoveryAt;
  bool _didAttemptInitialGoogleReconciliation = false;
  bool _reconcileAfterSubscriptionManagement = false;
  AppStage _stage = AppStage.configuring;
  AccountIdentity? _account;
  StoreWorkspace? _store;
  StoreMembership? _membership;
  final SubscriptionFlowMachine _subscriptionFlow = SubscriptionFlowMachine();
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
  final Set<String> _processingPurchases = {};
  final Set<String> _verifiedPurchaseEvents = {};
  int _storeProductRefreshSerial = 0;
  bool _disposed = false;
  bool _busy = false;
  bool _hasMoreWarranties = false;
  bool _loadingMoreWarranties = false;
  String? _errorMessageValue;
  int _errorMessageRevision = 0;
  int? _storeBillingErrorRevision;
  String? _noticeMessage;
  String? _activeBranchId;
  String? _pendingInvitationCode;
  MemberRole? _pendingInvitationRole;

  AppStage get stage => _stage;
  AccountIdentity? get account => _account;
  StoreWorkspace? get store => _store;
  StoreMembership? get membership => _membership;
  SubscriptionInfo? get subscription => _subscriptionFlow.state.entitlement;
  SubscriptionFlowState get subscriptionFlow => _subscriptionFlow.state;
  bool get requiresInitialSubscriptionActivation {
    final current = subscription;
    return current?.isAwaitingSubscription == true ||
        (current != null && !current.isUsable && _branches.isEmpty);
  }

  bool get busy => _busy;
  bool get isDemo => _repository?.isDemo ?? false;
  bool get backendConfigured => _repository != null;
  set _errorMessage(String? value) {
    _errorMessageValue = value;
    _errorMessageRevision += 1;
  }

  String? get errorMessage => _errorMessageValue;
  String? get noticeMessage => _noticeMessage;
  String? get pendingInvitationCode => _pendingInvitationCode;
  MemberRole? get pendingInvitationRole => _pendingInvitationRole;
  StoreBillingState get storeBillingState {
    final state = _subscriptionFlow.state;
    final operation = state.operation;
    if (operation != null) {
      return switch (operation.kind) {
        BillingOperationKind.pending => StoreBillingState.pending,
        BillingOperationKind.restoring => StoreBillingState.restoring,
        BillingOperationKind.reconciling => _catalogBillingState(state.catalog),
        BillingOperationKind.preflighting ||
        BillingOperationKind.awaitingStore ||
        BillingOperationKind.verifying ||
        BillingOperationKind.provisioning =>
          operation.origin == BillingOperationOrigin.purchase
              ? StoreBillingState.purchasing
              : _activeRestoreSession == null
              ? _catalogBillingState(state.catalog)
              : StoreBillingState.restoring,
      };
    }
    return _catalogBillingState(state.catalog);
  }

  StoreBillingPlatform get storeBillingPlatform =>
      _subscriptionFlow.state.catalog.platform;
  String? get storeBillingMessage =>
      _subscriptionFlow.state.message ??
      _subscriptionFlow.state.catalog.message;
  bool get storeBillingOperationInProgress =>
      _subscriptionFlow.state.operationInProgress ||
      _activePurchaseIntent != null ||
      _activeRestoreSession != null ||
      _processingPurchases.isNotEmpty;
  StoreBillingPlatform? get currentSubscriptionPlatform =>
      StoreBillingPlatformText.fromValue(subscription?.billingProvider);
  UnmodifiableListView<StoreProductOffer> get storeOffers =>
      UnmodifiableListView(_subscriptionFlow.state.catalog.offers);
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

  SubscriptionInfo? get _subscription => _subscriptionFlow.state.entitlement;

  BillingScope? get _currentBillingScope {
    final account = _account;
    final store = _store;
    if (account == null || store == null) return null;
    return BillingScope(
      accountId: account.id,
      storeId: store.id,
      epoch: _billingSessionEpoch,
    );
  }

  bool _attachSubscriptionScope(SubscriptionInfo? entitlement) {
    _storeSubscriptionRefreshSerial += 1;
    final scope = _currentBillingScope;
    if (scope == null) return false;
    if (_subscriptionFlow.state.scope == scope) {
      return _subscriptionFlow.updateEntitlement(
        scope: scope,
        entitlement: entitlement,
      );
    }
    return _subscriptionFlow.attach(scope: scope, entitlement: entitlement);
  }

  bool _updateSubscription(
    SubscriptionInfo? entitlement, {
    String? operationId,
  }) {
    _storeSubscriptionRefreshSerial += 1;
    final scope = _currentBillingScope;
    if (scope == null) return false;
    return _subscriptionFlow.updateEntitlement(
      scope: scope,
      entitlement: entitlement,
      operationId: operationId,
    );
  }

  String _nextBillingOperationId(String purpose) =>
      '$_billingSessionEpoch:${++_billingOperationGeneration}:$purpose';

  StoreProductOffer? storeOffer(String planId, BillingCycle cycle) {
    return _subscriptionFlow.state.catalog.offer(planId, cycle);
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
            'الخطة المجانية مستخدمة لهذا الحساب أو التثبيت. يمكنك الاشتراك في باقة مدفوعة للبدء.';
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
        _updateSubscription(
          current.withUsedWarranties(current.usedWarranties + 1),
          operationId: _subscriptionFlow.state.operation?.operationId,
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
        _purchaseEventEnqueueRevision += 1;
        _purchaseEventSerial = _purchaseEventSerial
            .then((_) => _handleStorePurchaseUpdates(events))
            .catchError((Object error, StackTrace _) {
              _recordStoreBillingFailure(error);
              notifyListeners();
            });
      },
      onError: (Object error) {
        _purchaseEventEnqueueRevision += 1;
        _recordStoreBillingFailure(error);
        notifyListeners();
      },
    );
  }

  Future<void> refreshStoreProducts() async {
    final account = _account;
    final scope = _currentBillingScope;
    if (_stage != AppStage.ready || account == null || scope == null) return;
    if (_subscriptionFlow.state.operationInProgress) return;
    final refreshSerial = ++_storeProductRefreshSerial;
    final sessionEpoch = _billingSessionEpoch;
    final accountId = account.id;
    final requestId = '$sessionEpoch:$refreshSerial:catalog';
    final previousPlatform = _subscriptionFlow.state.catalog.platform;
    // لا تبقِ سعراً قديماً قابلاً للشراء بعد تغيّر الحساب أو بلد المتجر.
    if (!_subscriptionFlow.beginCatalog(scope: scope, requestId: requestId)) {
      return;
    }
    _subscriptionFlow.setMessage(scope: scope, message: null);
    notifyListeners();
    try {
      final result = await _billingService
          .loadProducts(accountId: accountId)
          .timeout(_storeProductLoadTimeout);
      if (refreshSerial != _storeProductRefreshSerial ||
          !_billingContextMatches(sessionEpoch, accountId: accountId)) {
        return;
      }
      final missingProductsMessage = result.missingProductIds.isEmpty
          ? null
          : _missingStoreProductsMessage(
              result.platform,
              result.missingProductIds,
            );
      final message = switch ((result.errorMessage, missingProductsMessage)) {
        (final String error, final String missing) => '$error $missing',
        (final String error, null) => error,
        (null, final String missing) => missing,
        (null, null) when result.offers.isEmpty =>
          'لم يُرجع المتجر خططاً متاحة لهذا الحساب.',
        _ => null,
      };
      final completed = _subscriptionFlow.completeCatalog(
        scope: scope,
        requestId: requestId,
        platform: result.platform,
        offers: result.available ? result.offers : const [],
        message: message,
      );
      if (!completed) return;
      if (_subscriptionFlow.state.catalog.status == CatalogStatus.ready) {
        _lastStoreCatalogRefreshAt = DateTime.now();
        unawaited(
          _reconcileGooglePurchasesAfterCatalogOnce(
            sessionEpoch: sessionEpoch,
            accountId: accountId,
          ),
        );
      }
    } on TimeoutException {
      if (refreshSerial != _storeProductRefreshSerial ||
          !_billingContextMatches(sessionEpoch, accountId: accountId)) {
        return;
      }
      _subscriptionFlow.failCatalog(
        scope: scope,
        requestId: requestId,
        platform: previousPlatform,
        message:
            'استغرق متجر التطبيقات وقتاً طويلاً. تحقق من الاتصال ثم أعد المحاولة.',
      );
    } catch (error) {
      if (refreshSerial != _storeProductRefreshSerial ||
          !_billingContextMatches(sessionEpoch, accountId: accountId)) {
        return;
      }
      _subscriptionFlow.failCatalog(
        scope: scope,
        requestId: requestId,
        platform: previousPlatform,
        message: _friendlyError(error),
      );
    }
    notifyListeners();
  }

  String _missingStoreProductsMessage(
    StoreBillingPlatform platform,
    List<String> productIds,
  ) {
    final labels = productIds
        .map((productId) {
          final planId = DamanakStoreCatalog.planIdFromProduct(productId);
          final planName = switch (planId) {
            'starter' => 'بداية',
            'growth' => 'نمو',
            'scale' => 'توسع',
            _ => 'منتج اشتراك',
          };
          final cycle = switch (platform) {
            StoreBillingPlatform.appStore when productId.endsWith('.monthly') =>
              'شهري',
            StoreBillingPlatform.appStore when productId.endsWith('.yearly') =>
              'سنوي',
            StoreBillingPlatform.googlePlay => 'شهري وسنوي',
            _ => 'دورة غير معروفة',
          };
          return '$planName — $cycle';
        })
        .join('، ');
    return 'لم يُرجع ${platform.label} المنتجات التالية: $labels. يمكنك اختيار المنتجات الظاهرة أو إعادة المحاولة.';
  }

  Future<void> purchaseSubscription(StoreProductOffer offer) async {
    if (_membership?.role.canManageSubscription != true) {
      _setStoreBillingError('إدارة الاشتراك متاحة لمالك المتجر فقط.');
      notifyListeners();
      return;
    }
    if (isDemo || _repository == null || _account == null || _store == null) {
      _setStoreBillingError(
        'الشراء الحقيقي يحتاج نسخة مرتبطة بقاعدة ضمانك ومنشورة من المتجر.',
      );
      notifyListeners();
      return;
    }
    if (storeBillingOperationInProgress) {
      _setStoreBillingError(_billingVerificationInProgressMessage);
      notifyListeners();
      return;
    }
    final catalog = _subscriptionFlow.state.catalog;
    if (catalog.status != CatalogStatus.ready ||
        !catalog.offers.any(
          (item) =>
              item.key == offer.key &&
              item.productId == offer.productId &&
              item.basePlanId == offer.basePlanId,
        )) {
      _setStoreBillingError('حدّث أسعار متجر التطبيقات قبل متابعة الاشتراك.');
      notifyListeners();
      return;
    }
    final account = _account!;
    final store = _store!;
    final scope = _currentBillingScope!;
    final operationId = _nextBillingOperationId('purchase');
    final billingGenerationBeforePreflight = _billingOperationGeneration;
    final started = _subscriptionFlow.beginOperation(
      BillingOperation(
        kind: BillingOperationKind.preflighting,
        origin: BillingOperationOrigin.purchase,
        operationId: operationId,
        scope: scope,
        productId: offer.productId,
      ),
    );
    if (!started) {
      _setStoreBillingError(_billingVerificationInProgressMessage);
      notifyListeners();
      return;
    }
    _errorMessage = null;
    _noticeMessage = null;
    _subscriptionFlow.setMessage(
      scope: scope,
      operationId: operationId,
      message: 'جارٍ تأكيد حالة الاشتراك قبل فتح الدفع…',
    );
    SubscriptionInfo? subscription;
    notifyListeners();
    final sessionEpoch = _billingSessionEpoch;
    try {
      subscription = await _repository!
          .loadCurrentSubscription(store.id)
          .timeout(const Duration(seconds: 20));
      if (!_billingContextMatches(
            sessionEpoch,
            accountId: account.id,
            storeId: store.id,
          ) ||
          _subscriptionFlow.state.operation?.operationId != operationId ||
          _subscriptionFlow.state.operation?.scope != scope ||
          _billingOperationGeneration != billingGenerationBeforePreflight) {
        _subscriptionFlow.finishOperation(
          scope: scope,
          operationId: operationId,
        );
        _setStoreBillingError(_billingStateChangedDuringPreflightMessage);
        notifyListeners();
        return;
      }
      if (!_updateSubscription(subscription, operationId: operationId)) {
        throw StateError('STORE_SUBSCRIPTION_STATE_CHANGED');
      }

      final hiddenStoreBillingLineage =
          !subscription.isStoreSubscription &&
          subscription.hasStoreBillingLineage;
      if (subscription.canRefreshStoreBilling &&
          (hiddenStoreBillingLineage ||
              !storeSubscriptionVerificationIsFresh(
                subscription,
                now: DateTime.now(),
              ))) {
        final refreshed = await _refreshStoreSubscriptionShared(
          scope,
        ).timeout(const Duration(seconds: 35));
        if (!_billingContextMatches(
          sessionEpoch,
          accountId: account.id,
          storeId: store.id,
        )) {
          return;
        }
        final currentOperation = _subscriptionFlow.state.operation;
        if (currentOperation?.operationId != operationId ||
            currentOperation?.scope != scope ||
            _billingOperationGeneration != billingGenerationBeforePreflight) {
          _subscriptionFlow.finishOperation(
            scope: scope,
            operationId: operationId,
          );
          _setStoreBillingError(
            currentOperation != null &&
                    currentOperation.operationId != operationId
                ? _billingVerificationInProgressMessage
                : _billingStateChangedDuringPreflightMessage,
          );
          notifyListeners();
          return;
        }
        if (!_updateSubscription(refreshed, operationId: operationId)) {
          throw StateError('STORE_SUBSCRIPTION_STATE_CHANGED');
        }
        subscription = refreshed;
      }
    } catch (error) {
      if (_billingContextMatches(
        sessionEpoch,
        accountId: account.id,
        storeId: store.id,
      )) {
        _subscriptionFlow.finishOperation(
          scope: scope,
          operationId: operationId,
        );
        final friendly = _friendlyError(error);
        _setStoreBillingError(
          friendly == 'تعذّر إكمال العملية. تحقق من الاتصال وحاول مرة أخرى.'
              ? 'تعذر تأكيد حالة الاشتراك الحالية قبل فتح الدفع. لم يبدأ أي اشتراك جديد؛ حاول الاستعادة أو أعد المحاولة لاحقاً.'
              : friendly,
        );
        notifyListeners();
      }
      return;
    }
    // قد تصل معاملة متأخرة أو تبدأ مصالحة Google أثناء انتظار فحص الاشتراك
    // الخادمي أعلاه. أعد الحراسة قبل إنشاء intent وفتح واجهة الدفع.
    final operationStillCurrent =
        _subscriptionFlow.state.operation?.operationId == operationId &&
        _subscriptionFlow.state.operation?.scope == scope;
    if (!operationStillCurrent ||
        _activePurchaseIntent != null ||
        _activeRestoreSession != null ||
        _processingPurchases.isNotEmpty) {
      _subscriptionFlow.finishOperation(scope: scope, operationId: operationId);
      _setStoreBillingError(
        operationStillCurrent
            ? _billingVerificationInProgressMessage
            : _billingStateChangedDuringPreflightMessage,
      );
      notifyListeners();
      return;
    }
    final decision = SubscriptionPolicy.evaluate(
      current: subscription,
      target: offer,
      devicePlatform: catalog.platform,
    );
    if (!decision.allowed) {
      _subscriptionFlow.finishOperation(scope: scope, operationId: operationId);
      _setStoreBillingError(switch (decision.blockedReason) {
        SubscriptionBlockReason.alreadyActive =>
          'هذه الخطة ودورة الفوترة فعّالتان بالفعل.',
        SubscriptionBlockReason.downgrade =>
          'لا يمكن الانتقال إلى باقة أقل ما دام اشتراكك الحالي سارياً. يمكنك الترقية أو تغيير دورة الفوترة فقط.',
        SubscriptionBlockReason.providerConflict =>
          'اشتراك المتجر ما زال سارياً عبر ${StoreBillingPlatformText.fromValue(subscription.billingProvider)?.label ?? 'متجر آخر'}. أدره هناك أولاً لتجنب اشتراكين مدفوعين.',
        SubscriptionBlockReason.stateUnknown || null =>
          'حالة الاشتراك الحالية غير مكتملة. لم نفتح الدفع؛ استخدم استعادة المشتريات أو أعد المحاولة.',
      });
      notifyListeners();
      return;
    }
    final currentPlanId = subscription.hasUnexpiredStorePeriod
        ? subscription.plan.id
        : null;
    final currentProductId = subscription.hasUnexpiredStorePeriod
        ? subscription.storeProductId
        : null;
    final currentOriginalTransactionId = subscription.hasUnexpiredStorePeriod
        ? subscription.originalTransactionId
        : null;
    final currentCycle = switch (subscription.billingCycle) {
      'monthly' when subscription.hasUnexpiredStorePeriod =>
        BillingCycle.monthly,
      'yearly' when subscription.hasUnexpiredStorePeriod => BillingCycle.yearly,
      _ => null,
    };
    final requireExistingSubscription =
        subscription.hasUnexpiredStorePeriod &&
        StoreBillingPlatformText.fromValue(subscription.billingProvider) ==
            StoreBillingPlatform.googlePlay &&
        catalog.platform == StoreBillingPlatform.googlePlay;
    if (!_subscriptionFlow.advanceOperation(
      scope: scope,
      operationId: operationId,
      kind: BillingOperationKind.awaitingStore,
    )) {
      _setStoreBillingError(_billingStateChangedDuringPreflightMessage);
      notifyListeners();
      return;
    }
    final intent = _StorePurchaseIntent(
      operationId: operationId,
      sessionEpoch: _billingSessionEpoch,
      accountId: account.id,
      storeId: store.id,
      platform: catalog.platform,
      productId: offer.productId,
      planId: offer.planId,
      cycle: offer.cycle,
      startedAt: DateTime.now(),
    );
    _activePurchaseIntent = intent;
    _subscriptionFlow.setMessage(
      scope: scope,
      operationId: operationId,
      message: 'أكمل العملية في نافذة المتجر الآمنة.',
    );
    _startPurchaseWatchdog(intent);
    notifyListeners();
    try {
      await _billingService.purchase(
        offer,
        accountId: account.id,
        storeId: store.id,
        currentPlanId: currentPlanId,
        currentProductId: currentProductId,
        currentOriginalTransactionId: currentOriginalTransactionId,
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
        _setStoreBillingError(_friendlyError(error));
        notifyListeners();
      }
    }
  }

  Future<void> restoreStorePurchases() async {
    if (_membership?.role.canManageSubscription != true) {
      _setStoreBillingError('استعادة المشتريات متاحة لمالك المتجر فقط.');
      notifyListeners();
      return;
    }
    if (isDemo || _repository == null || _account == null || _store == null) {
      _setStoreBillingError(
        'الاستعادة تحتاج نسخة مرتبطة بقاعدة ضمانك ومنشورة من المتجر.',
      );
      notifyListeners();
      return;
    }
    final currentProvider = StoreBillingPlatformText.fromValue(
      _subscription?.billingProvider,
    );
    if (_subscription?.hasUnexpiredStorePeriod == true &&
        currentProvider != null &&
        storeBillingPlatform != StoreBillingPlatform.unavailable &&
        currentProvider != storeBillingPlatform) {
      _setStoreBillingError(
        'الاشتراك الحالي مرتبط بـ${currentProvider.label}. نفّذ الاستعادة من جهاز يستخدم المتجر نفسه.',
      );
      notifyListeners();
      return;
    }
    if (storeBillingOperationInProgress) {
      _setStoreBillingError(_billingVerificationInProgressMessage);
      notifyListeners();
      return;
    }
    final account = _account!;
    final store = _store!;
    final scope = _currentBillingScope!;
    final operationId = _nextBillingOperationId('restore');
    final session = _StoreRestoreSession(
      operationId: operationId,
      sessionEpoch: _billingSessionEpoch,
      accountId: account.id,
      storeId: store.id,
      silent: false,
    );
    final started = _subscriptionFlow.beginOperation(
      BillingOperation(
        kind: BillingOperationKind.restoring,
        origin: BillingOperationOrigin.explicitRestore,
        operationId: operationId,
        scope: scope,
      ),
    );
    if (!started) {
      _setStoreBillingError(_billingVerificationInProgressMessage);
      notifyListeners();
      return;
    }
    _activeRestoreSession = session;
    _purchaseWatchdog?.cancel();
    _subscriptionFlow.setMessage(
      scope: scope,
      operationId: operationId,
      message: 'جارٍ طلب مشترياتك السابقة من المتجر…',
    );
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
    try {
      late final StoreRestoreResult result;
      try {
        result = await _billingService
            .restorePurchases(
              accountId: account.id,
              storeId: store.id,
              currentOriginalTransactionId:
                  _subscription?.originalTransactionId,
              recoveryRequested: true,
            )
            .timeout(_storeRestoreTimeout);
      } on TimeoutException {
        if (storeBillingPlatform != StoreBillingPlatform.appStore ||
            !_restoreSessionMatches(session)) {
          rethrow;
        }
        _subscriptionFlow.setMessage(
          scope: scope,
          operationId: operationId,
          message: 'استغرق طلب App Store وقتاً أطول. ننتظر وصول الإيصال بأمان…',
        );
        session.restoreResultUnknown = true;
        notifyListeners();
        final outcome = await _waitForRestoreVerificationOutcome(session);
        if (!_restoreSessionMatches(session)) return;
        // A single StoreKit restore batch can contain multiple unfinished
        // transactions. The first active result completes the outcome future,
        // but every remaining event must retain the explicit-recovery scope
        // until it is verified and finished as well.
        await _drainRestorePurchaseEvents(session);
        if (!_restoreSessionMatches(session)) return;
        await _applyRestoreVerificationOutcome(
          session,
          session.outcomeAfterDrain(outcome),
        );
        return;
      }
      if (!_restoreSessionMatches(session)) return;
      session.expectedStorePurchases = result.restoredPurchases ?? 0;
      session.remainingStorePurchases = result.remainingPurchases;
      session.unfinishedLookupFailed = result.unfinishedLookupFailed;
      session.officialRestoreFailed = result.officialRestoreFailed;
      if (result.accountMismatchDetected &&
          (result.restoredPurchases ?? 0) == 0 &&
          result.pendingPurchases == 0) {
        throw StateError('STORE_ACCOUNT_MISMATCH');
      }
      if (result.pendingPurchases > 0 && (result.restoredPurchases ?? 0) == 0) {
        _subscriptionFlow.markPending(
          scope: scope,
          operationId: operationId,
          message:
              'وجد المتجر دفعة معلّقة. لن تتفعّل الخطة قبل أن يؤكدها المتجر.',
        );
        return;
      }
      if (result.officialRestoreFailed &&
          (result.restoredPurchases ?? 0) == 0) {
        final firstOutcome = await _waitForRestoreVerificationOutcome(session);
        if (!_restoreSessionMatches(session)) return;
        await _drainRestorePurchaseEvents(session);
        if (!_restoreSessionMatches(session)) return;
        await _applyRestoreVerificationOutcome(
          session,
          session.outcomeAfterDrain(firstOutcome),
        );
        return;
      }
      if (result.restoredPurchases == 0) {
        // Google يرسل عناصر الاستعادة عبر stream منفصل. أعطِ stream دورة
        // event loop ثم صرّف كل الأحداث التي سبق أن أرسلها قبل اعتبار النتيجة
        // فارغة، كي لا يتنافس fallback خادمي مع تحقق إيصال أحدث.
        await Future<void>.delayed(Duration.zero);
        await _drainRestorePurchaseEvents(session);
        if (!_restoreSessionMatches(session)) return;
        if (session.completer.isCompleted) {
          await _applyRestoreVerificationOutcome(
            session,
            session.outcomeAfterDrain(await session.completer.future),
          );
          return;
        }
        if (session.sawInactivePurchase || session.verificationFailed) {
          await _applyRestoreVerificationOutcome(
            session,
            session.timeoutOutcome,
          );
          return;
        }
        await _finishRestoreWithoutStoreEvents(session);
        return;
      }

      final firstOutcome = await _waitForRestoreVerificationOutcome(session);
      if (!_restoreSessionMatches(session)) return;
      await _drainRestorePurchaseEvents(session);
      if (!_restoreSessionMatches(session)) return;
      await _applyRestoreVerificationOutcome(
        session,
        session.outcomeAfterDrain(firstOutcome),
      );
    } catch (error) {
      if (_restoreSessionMatches(session)) {
        _setStoreBillingError(_friendlyError(error));
        _subscriptionFlow.setMessage(
          scope: scope,
          operationId: operationId,
          message: 'تعذر التحقق من المشتريات السابقة على حساب المتجر الحالي.',
        );
      }
    } finally {
      if (_restoreSessionMatches(session)) {
        _activeRestoreSession = null;
        final operation = _subscriptionFlow.state.operation;
        if (operation?.operationId == operationId &&
            operation?.kind == BillingOperationKind.restoring) {
          _subscriptionFlow.finishOperation(
            scope: scope,
            operationId: operationId,
            message: _subscriptionFlow.state.message,
          );
        }
        notifyListeners();
      }
    }
  }

  void _setStoreBillingError(String message) {
    _errorMessage = message;
    _storeBillingErrorRevision = _errorMessageRevision;
  }

  void _clearStoreBillingErrorAfterReceiptSuccess() {
    final billingRevision = _storeBillingErrorRevision;
    if (billingRevision != null && billingRevision == _errorMessageRevision) {
      _errorMessage = null;
    }
    _storeBillingErrorRevision = null;
  }

  Future<void> _applyRestoreVerificationOutcome(
    _StoreRestoreSession session,
    _RestoreVerificationOutcome outcome,
  ) async {
    final scope = BillingScope(
      accountId: session.accountId,
      storeId: session.storeId,
      epoch: session.sessionEpoch,
    );
    switch (outcome) {
      case _RestoreVerificationOutcome.active:
        if (session.remainingStorePurchases > 0) {
          _noticeMessage =
              'تمت معالجة دفعة من معاملات App Store القديمة بأمان. اضغط استعادة المشتريات مرة أخرى لإكمال الباقي قبل اختيار الباقة.';
        } else if (session.officialRestoreFailed) {
          _noticeMessage =
              'تمت معالجة معاملات App Store القديمة، لكن تعذرت الاستعادة الرسمية الحالية. أعد الاستعادة قبل اختيار الباقة.';
        } else if (session.restoreResultUnknown) {
          _noticeMessage =
              'تم التحقق من دفعة وصلت من App Store، لكن نتيجة طلب الاستعادة لم تكتمل. أعد الاستعادة قبل اختيار الباقة.';
        } else if (session.unfinishedLookupFailed) {
          _noticeMessage =
              'تمت استعادة الاشتراك الحالي، لكن تعذر فحص معاملات App Store القديمة. أعد الاستعادة لاحقاً قبل إعادة الشراء.';
        } else {
          _noticeMessage = 'تمت استعادة الاشتراك والتحقق منه بأمان.';
        }
        _subscriptionFlow.setMessage(
          scope: scope,
          operationId: session.operationId,
          message: session.remainingStorePurchases > 0
              ? 'بقيت ${session.remainingStorePurchases} معاملة قديمة. أكملها باستعادة إضافية قبل الشراء.'
              : session.officialRestoreFailed
              ? 'تعذرت الاستعادة الرسمية الحالية بعد معالجة المعاملات القديمة. أعد الاستعادة قبل الشراء.'
              : session.restoreResultUnknown
              ? 'لم تكتمل نتيجة طلب الاستعادة. أعد الاستعادة قبل الشراء.'
              : session.unfinishedLookupFailed
              ? 'تعذر فحص معاملات App Store القديمة؛ أعد الاستعادة لاحقاً قبل الشراء.'
              : null,
        );
      case _RestoreVerificationOutcome.inactive:
        if (session.remainingStorePurchases > 0) {
          _noticeMessage =
              'تمت معالجة دفعة قديمة غير فعالة، وبقيت ${session.remainingStorePurchases} معاملة. أعد استعادة المشتريات قبل اختيار باقة.';
        }
        _subscriptionFlow.setMessage(
          scope: scope,
          operationId: session.operationId,
          message: session.remainingStorePurchases > 0
              ? 'وجد المتجر اشتراكاً سابقاً غير فعال، وبقيت ${session.remainingStorePurchases} معاملة قديمة. أعد الاستعادة قبل الشراء.'
              : session.officialRestoreFailed
              ? 'عولجت المعاملات القديمة غير الفعالة، لكن تعذرت الاستعادة الرسمية الحالية. أعد الاستعادة قبل الشراء.'
              : session.restoreResultUnknown
              ? 'تحققت دفعة قديمة غير فعالة، لكن نتيجة الاستعادة لم تكتمل. أعد الاستعادة قبل الشراء.'
              : session.unfinishedLookupFailed
              ? 'وجد المتجر اشتراكاً سابقاً غير فعال، وتعذر فحص معاملات App Store القديمة. أعد الاستعادة لاحقاً قبل الشراء.'
              : 'وجد المتجر اشتراكاً سابقاً، لكنه لا يمنح فترة فعّالة الآن.',
        );
      case _RestoreVerificationOutcome.failed:
        if (_errorMessageValue == null) {
          _setStoreBillingError(
            'لم تكتمل معالجة كل معاملات المتجر بأمان. لا تدفع مرة أخرى؛ أعد استعادة المشتريات بعد قليل.',
          );
        }
        _subscriptionFlow.setMessage(
          scope: scope,
          operationId: session.operationId,
          message:
              'لم تكتمل معالجة معاملات المتجر. لا تدفع مرة أخرى؛ أعد الاستعادة بعد قليل.',
        );
      case _RestoreVerificationOutcome.notFound:
        await _finishRestoreWithoutStoreEvents(session);
    }
    final operation = _subscriptionFlow.state.operation;
    if (operation?.operationId == session.operationId) {
      _subscriptionFlow.finishOperation(
        scope: scope,
        operationId: session.operationId,
        message: _subscriptionFlow.state.message,
      );
    }
  }

  Future<_RestoreVerificationOutcome> _waitForRestoreVerificationOutcome(
    _StoreRestoreSession session,
  ) => session.completer.future.timeout(
    _storeRestoreVerificationTimeout,
    onTimeout: () async {
      if (session.verificationInProgress) {
        await session.waitForVerificationToSettle().timeout(
          _storeRestoreVerificationSettleTimeout,
          onTimeout: () => throw StateError('STORE_VERIFICATION_TIMEOUT'),
        );
        if (session.completer.isCompleted) {
          return session.completer.future;
        }
      }
      return session.timeoutOutcome;
    },
  );

  Future<void> _drainRestorePurchaseEvents(_StoreRestoreSession session) async {
    if (storeBillingPlatform != StoreBillingPlatform.appStore) {
      await _purchaseEventSerial;
      if (session.verificationInProgress) {
        await session.waitForVerificationToSettle().timeout(
          _storeRestoreVerificationSettleTimeout,
          onTimeout: () => throw StateError('STORE_VERIFICATION_TIMEOUT'),
        );
      }
      return;
    }
    // StoreKit 2's native restore method can return before its MainActor task
    // publishes currentEntitlements to Flutter. Keep the explicit restore
    // session alive until the serialized stream stays quiet for a bounded
    // period; this also waits for every verification already in flight.
    for (var round = 0; round < 4; round += 1) {
      await Future<void>.delayed(Duration.zero);
      await _purchaseEventSerial;
      if (!_restoreSessionMatches(session)) return;
      if (session.verificationInProgress) {
        await session.waitForVerificationToSettle().timeout(
          _storeRestoreVerificationSettleTimeout,
          onTimeout: () => throw StateError('STORE_VERIFICATION_TIMEOUT'),
        );
      }
      final sessionRevision = session.eventRevision;
      final enqueueRevision = _purchaseEventEnqueueRevision;
      await Future<void>.delayed(_storeRestoreEventQuietPeriod);
      await Future<void>.delayed(Duration.zero);
      final latestSerial = _purchaseEventSerial;
      await latestSerial;
      if (!_restoreSessionMatches(session)) return;
      if (!session.verificationInProgress &&
          session.eventRevision == sessionRevision &&
          _purchaseEventEnqueueRevision == enqueueRevision &&
          identical(latestSerial, _purchaseEventSerial)) {
        return;
      }
    }
    throw StateError('STORE_RESTORE_STREAM_NOT_SETTLED');
  }

  void _startPurchaseWatchdog(
    _StorePurchaseIntent intent, {
    Duration? timeout,
  }) {
    _purchaseWatchdog?.cancel();
    final requestedTimeout = timeout ?? _purchaseEventTimeout;
    final effectiveTimeout = requestedTimeout < _purchaseEventTimeout
        ? requestedTimeout
        : _purchaseEventTimeout;
    _purchaseWatchdog = Timer(effectiveTimeout, () {
      if (!identical(_activePurchaseIntent, intent) ||
          _subscriptionFlow.state.operation?.operationId !=
              intent.operationId) {
        return;
      }
      _finishPurchaseIntent(
        intent,
        message:
            'لم يصل تأكيد من المتجر، ولم تُفعّل أي خطة. استخدم استعادة المشتريات قبل إعادة المحاولة.',
      );
      notifyListeners();
    });
  }

  Future<void> openStoreSubscriptionManagement() async {
    if (_membership?.role.canManageSubscription != true) {
      _setStoreBillingError('إدارة الاشتراك متاحة لمالك المتجر فقط.');
      notifyListeners();
      return;
    }
    final subscription = _subscription;
    final provider = StoreBillingPlatformText.fromValue(
      subscription?.billingProvider,
    );
    if (subscription == null || provider == null) {
      _setStoreBillingError('لا يوجد اشتراك متجري يمكن إدارته حالياً.');
      notifyListeners();
      return;
    }
    try {
      final opened = await _billingService.openSubscriptionManagement(
        provider,
        productId: subscription.storeProductId,
      );
      if (!opened) {
        _setStoreBillingError(
          'تعذر فتح صفحة إدارة الاشتراك في ${provider.label}.',
        );
      } else {
        _reconcileAfterSubscriptionManagement = true;
      }
    } catch (error) {
      _setStoreBillingError(_friendlyError(error));
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
      final currentScope = _currentBillingScope;
      final pendingOperation = _subscriptionFlow.state.operation;
      final matchesPendingExplicitRestore =
          intent == null &&
          restoreSession == null &&
          currentScope != null &&
          pendingOperation?.scope == currentScope &&
          pendingOperation?.origin == BillingOperationOrigin.explicitRestore &&
          pendingOperation?.kind == BillingOperationKind.pending;
      final explicitRecovery =
          (matchesRestore && restoreSession.recoveryRequested) ||
          matchesPendingExplicitRestore;
      final conflictsWithActiveAppleIntent =
          intent != null &&
          identical(_activePurchaseIntent, intent) &&
          intent.platform == StoreBillingPlatform.appStore &&
          event.platform == StoreBillingPlatform.appStore &&
          !matchesIntent;
      if (conflictsWithActiveAppleIntent) {
        _finishPurchaseIntent(intent);
        _setStoreBillingError(
          'وجد App Store اشتراكاً أو معاملة سابقة لا تطابق اختيارك الحالي. لم يبدأ ضمانك دفعة أخرى؛ استخدم استعادة المشتريات أولاً.',
        );
        continue;
      }
      final matchesBillingOperation =
          matchesIntent || matchesRestore || matchesPendingExplicitRestore;
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
        allowLegacyBindingRecovery: explicitRecovery,
      )) {
        if (matchesIntent && intent != null) {
          _finishPurchaseIntent(intent);
          _setStoreBillingError(
            _friendlyError(StateError('STORE_ACCOUNT_MISMATCH')),
          );
        }
        if (matchesRestore) {
          restoreSession.markFailure(event.key);
          if (!restoreSession.silent) {
            _setStoreBillingError(
              _friendlyError(StateError('STORE_ACCOUNT_MISMATCH')),
            );
          }
        }
        continue;
      }
      switch (event.status) {
        case StorePurchaseStatus.pending:
          if (matchesBillingOperation) {
            if (matchesIntent && intent != null) {
              _purchaseWatchdog?.cancel();
            }
            final operationId =
                intent?.operationId ??
                restoreSession?.operationId ??
                pendingOperation?.operationId;
            final scope = currentScope;
            if (operationId != null && scope != null) {
              _subscriptionFlow.markPending(
                scope: scope,
                operationId: operationId,
                message:
                    'الدفعة معلّقة لدى المتجر. لن تتفعّل الخطة قبل تأكيدها.',
              );
            }
          }
        case StorePurchaseStatus.canceled:
          if (matchesIntent && intent != null) {
            _finishPurchaseIntent(intent);
            _noticeMessage = 'أُغلقت عملية الشراء من دون تأكيد اشتراك.';
          }
          if (matchesRestore) {
            restoreSession.markFailure(event.key);
            if (!restoreSession.silent) {
              _setStoreBillingError(
                'أُغلقت استعادة المشتريات من المتجر من دون تأكيد اشتراك.',
              );
            }
          }
          if (matchesPendingExplicitRestore && pendingOperation != null) {
            _subscriptionFlow.finishOperation(
              scope: currentScope,
              operationId: pendingOperation.operationId,
              message: 'أُغلقت الاستعادة من دون تأكيد اشتراك.',
            );
            _noticeMessage = 'أُغلقت الاستعادة من دون تأكيد اشتراك.';
          }
        case StorePurchaseStatus.error:
          if (matchesIntent && intent != null) {
            _finishPurchaseIntent(intent);
            _setStoreBillingError(_friendlyStoreEventError(event));
          }
          if (matchesRestore) {
            restoreSession.markFailure(event.key);
            if (!restoreSession.silent) {
              _setStoreBillingError(_friendlyStoreEventError(event));
            }
          }
          if (matchesPendingExplicitRestore && pendingOperation != null) {
            final message = _friendlyStoreEventError(event);
            _subscriptionFlow.finishOperation(
              scope: currentScope,
              operationId: pendingOperation.operationId,
              message: message,
            );
            _setStoreBillingError(message);
          }
        case StorePurchaseStatus.purchased:
        case StorePurchaseStatus.restored:
          if (matchesRestore) restoreSession.observe(event.key);
          if (matchesIntent && intent != null) {
            _cancelPurchaseWatchdog(intent);
          }
          await _verifyAndCompleteStorePurchase(
            event,
            intent: matchesIntent ? intent : null,
            restoreSession: matchesRestore ? restoreSession : null,
            recoveryRequested: explicitRecovery,
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
    bool recoveryRequested = false,
    required bool displayProgress,
  }) async {
    final sessionEpoch = _billingSessionEpoch;
    final eventKey = '$sessionEpoch:${event.key}';
    if (_verifiedPurchaseEvents.contains(eventKey)) {
      if (event.needsCompletion) {
        try {
          await _billingService
              .completePurchase(event)
              .timeout(const Duration(seconds: 20));
          if (restoreSession?.verificationFailed != true) {
            _clearStoreBillingErrorAfterReceiptSuccess();
          }
        } catch (_) {
          if (intent != null && identical(_activePurchaseIntent, intent)) {
            _finishPurchaseIntent(intent);
          }
          if (restoreSession != null &&
              _restoreSessionMatches(restoreSession)) {
            restoreSession.markFailure(event.key);
          }
          _setStoreBillingError(
            'سبق التحقق من الاشتراك، لكن تعذر إغلاق معاملة المتجر. لا تدفع مرة أخرى؛ استخدم الاستعادة لإكمالها.',
          );
          return;
        }
      }
      if (intent != null && identical(_activePurchaseIntent, intent)) {
        _finishPurchaseIntent(intent);
        _noticeMessage = 'سبق التحقق من هذه العملية بأمان.';
      }
      if (restoreSession != null && _restoreSessionMatches(restoreSession)) {
        restoreSession.markVerified(
          event.key,
          usable: _subscription?.isUsable == true,
          settled: true,
        );
      }
      return;
    }
    if (!_processingPurchases.add(eventKey)) return;
    _billingOperationGeneration += 1;
    if (!displayProgress && !_disposed) notifyListeners();
    final tracksRestoreVerification =
        restoreSession != null && _restoreSessionMatches(restoreSession);
    if (tracksRestoreVerification) restoreSession.beginVerification();
    final account = _account;
    final store = _store;
    final currentScope = _currentBillingScope;
    final pendingOperation = _subscriptionFlow.state.operation;
    final operationId =
        intent?.operationId ??
        restoreSession?.operationId ??
        (intent == null &&
                restoreSession == null &&
                pendingOperation?.scope == currentScope
            ? pendingOperation?.operationId
            : null);
    if (currentScope != null && operationId != null) {
      final kind = _subscriptionFlow.state.operation?.kind;
      if (kind != BillingOperationKind.verifying &&
          kind != BillingOperationKind.provisioning) {
        _subscriptionFlow.advanceOperation(
          scope: currentScope,
          operationId: operationId,
          kind: BillingOperationKind.verifying,
        );
      }
    }
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
        allowUnboundGoogle:
            intent != null || restoreSession != null || recoveryRequested,
        allowLegacyBindingRecovery: recoveryRequested,
      )) {
        throw StateError('STORE_ACCOUNT_MISMATCH');
      }
      if (displayProgress) {
        if (currentScope != null && operationId != null) {
          _subscriptionFlow.setMessage(
            scope: currentScope,
            operationId: operationId,
            message: 'جارٍ التحقق من إيصال المتجر بأمان…',
          );
        }
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
              recoveryRequested: recoveryRequested,
            ),
          )
          .timeout(
            _storePurchaseVerificationTimeout,
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
            if (currentScope != null && operationId != null) {
              _subscriptionFlow.advanceOperation(
                scope: currentScope,
                operationId: operationId,
                kind: BillingOperationKind.provisioning,
              );
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
            if (!_updateSubscription(
              verifiedSubscription,
              operationId: operationId,
            )) {
              throw StateError('STORE_SUBSCRIPTION_STATE_CHANGED');
            }
            _rememberVerifiedPurchaseEvent(eventKey);
          }
          final operationMatches =
              completionContextMatches &&
              (intent == null || identical(_activePurchaseIntent, intent)) &&
              (restoreSession == null ||
                  _restoreSessionMatches(restoreSession));
          if (operationMatches) {
            if (intent != null) _finishPurchaseIntent(intent);
            if (restoreSession != null) {
              restoreSession.markVerified(
                event.key,
                usable: verifiedSubscription.isUsable,
                settled: false,
              );
              restoreSession.markFailure(event.key);
            }
            if (intent == null &&
                restoreSession == null &&
                currentScope != null &&
                operationId != null) {
              _subscriptionFlow.finishOperation(
                scope: currentScope,
                operationId: operationId,
              );
            }
            _setStoreBillingError(
              'تم التحقق من الاشتراك، لكن تعذر إغلاق معاملة المتجر. لا تدفع مرة أخرى؛ استخدم الاستعادة لإكمالها.',
            );
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
      if (currentScope != null && operationId != null) {
        _subscriptionFlow.advanceOperation(
          scope: currentScope,
          operationId: operationId,
          kind: BillingOperationKind.provisioning,
        );
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
      if (!_updateSubscription(
        verifiedSubscription,
        operationId: operationId,
      )) {
        throw StateError('STORE_SUBSCRIPTION_STATE_CHANGED');
      }
      _rememberVerifiedPurchaseEvent(eventKey);
      if (restoreSession?.verificationFailed != true) {
        _clearStoreBillingErrorAfterReceiptSuccess();
      }
      final operationMatches =
          (intent == null || identical(_activePurchaseIntent, intent)) &&
          (restoreSession == null || _restoreSessionMatches(restoreSession));
      if (operationMatches && intent != null) _finishPurchaseIntent(intent);
      if (operationMatches && restoreSession != null) {
        restoreSession.markVerified(
          event.key,
          usable: verifiedSubscription.isUsable,
          settled: true,
        );
      }
      final canResolveOrphanOperation =
          intent == null &&
          _activePurchaseIntent == null &&
          _activeRestoreSession == null &&
          operationId != null &&
          (restoreSession == null || !_restoreSessionMatches(restoreSession));
      if (canResolveOrphanOperation &&
          currentScope != null &&
          _subscriptionFlow.state.operation?.operationId == operationId) {
        _subscriptionFlow.finishOperation(
          scope: currentScope,
          operationId: operationId,
          message: verifiedSubscription.isUsable
              ? null
              : 'تحققنا من العملية، لكنها لا تمنح فترة اشتراك فعّالة الآن.',
        );
      }
      if (operationMatches && intent != null) {
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
          restoreSession.markFailure(event.key);
        }
        if (intent == null &&
            restoreSession == null &&
            currentScope != null &&
            operationId != null) {
          _subscriptionFlow.finishOperation(
            scope: currentScope,
            operationId: operationId,
          );
        }
        final reportFailure =
            intent != null ||
            (restoreSession != null && !restoreSession.silent) ||
            (intent == null &&
                restoreSession == null &&
                _activePurchaseIntent == null &&
                _activeRestoreSession == null);
        if (reportFailure) {
          _setStoreBillingError(_friendlyError(error));
        }
      }
    } finally {
      if (tracksRestoreVerification) restoreSession.endVerification();
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
    final scope = BillingScope(
      accountId: accountId,
      storeId: storeId,
      epoch: sessionEpoch,
    );
    final operationId = _subscriptionFlow.state.operation?.operationId;
    _subscriptionFlow.setMessage(
      scope: scope,
      operationId: operationId,
      message: 'تم التحقق من الاشتراك. جارٍ تهيئة المتجر…',
    );
    notifyListeners();
    try {
      final loaded =
          await _loadWorkspaceData(
            expectedBillingSessionEpoch: sessionEpoch,
            expectedAccountId: accountId,
            expectedStoreId: storeId,
          ).timeout(
            _initialActivationWorkspaceTimeout,
            onTimeout: () => throw StateError('INITIAL_WORKSPACE_TIMEOUT'),
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
        if (operationId != null) {
          _subscriptionFlow.finishOperation(
            scope: scope,
            operationId: operationId,
          );
        }
        _setStoreBillingError(
          'تم التحقق من الاشتراك، لكن تعذّر تهيئة بيانات المتجر. أغلق التطبيق وافتحه مجدداً؛ لا تدف مرة أخرى.',
        );
        notifyListeners();
      }
      return false;
    }
  }

  void _finishBillingOperationAfterWorkspacePreparationFailure({
    _StorePurchaseIntent? intent,
    _StoreRestoreSession? restoreSession,
  }) {
    if (intent != null && identical(_activePurchaseIntent, intent)) {
      _finishPurchaseIntent(intent);
    }
    if (restoreSession != null && _restoreSessionMatches(restoreSession)) {
      restoreSession.markFailure();
    }
  }

  void handleAppResumed() {
    final intent = _activePurchaseIntent;
    if (intent != null &&
        intent.platform == StoreBillingPlatform.appStore &&
        storeBillingState == StoreBillingState.purchasing) {
      _startPurchaseWatchdog(intent, timeout: _purchaseResumeGracePeriod);
    }
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
    if (storeBillingPlatform != StoreBillingPlatform.googlePlay ||
        _subscriptionFlow.state.operationInProgress ||
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
    final scope = BillingScope(
      accountId: accountId,
      storeId: storeId,
      epoch: sessionEpoch,
    );
    final operationId = _nextBillingOperationId('reconcile');
    final session = _StoreRestoreSession(
      operationId: operationId,
      sessionEpoch: sessionEpoch,
      accountId: accountId,
      storeId: storeId,
      silent: true,
    );
    if (!_subscriptionFlow.beginOperation(
      BillingOperation(
        kind: BillingOperationKind.reconciling,
        origin: BillingOperationOrigin.backgroundReconciliation,
        operationId: operationId,
        scope: scope,
      ),
    )) {
      return;
    }
    _activeRestoreSession = session;
    if (!_disposed) notifyListeners();
    try {
      final result = await _billingService
          .restorePurchases(
            accountId: accountId,
            storeId: storeId,
            recoveryRequested: false,
          )
          .timeout(_storeRestoreTimeout);
      if (!_restoreSessionMatches(session) ||
          (result.restoredPurchases ?? 0) == 0) {
        return;
      }
      await _waitForRestoreVerificationOutcome(session);
    } catch (_) {
      // Reconciliation is opportunistic. The explicit restore action remains
      // available with a visible, actionable error if this background pass
      // cannot contact Google Play or the verification backend.
    } finally {
      if (_restoreSessionMatches(session)) {
        _activeRestoreSession = null;
        if (_subscriptionFlow.state.operation?.operationId == operationId) {
          _subscriptionFlow.finishOperation(
            scope: scope,
            operationId: operationId,
          );
        }
        if (!_disposed) notifyListeners();
      }
    }
  }

  Future<void> _reconcileGooglePurchasesAfterCatalogOnce({
    required int sessionEpoch,
    required String accountId,
  }) async {
    final store = _store;
    if (_didAttemptInitialGoogleReconciliation ||
        storeBillingPlatform != StoreBillingPlatform.googlePlay ||
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
    final subscriptionSerialBeforeRefresh = _storeSubscriptionRefreshSerial;
    final current = _subscription;
    final requiresInitialWorkspaceReload =
        requiresInitialSubscriptionActivation;
    final scope = BillingScope(
      accountId: session.accountId,
      storeId: session.storeId,
      epoch: session.sessionEpoch,
    );
    if (current?.canRefreshStoreBilling == true) {
      try {
        final refreshed = await _refreshStoreSubscriptionShared(scope);
        await Future<void>.delayed(Duration.zero);
        await _drainRestorePurchaseEvents(session);
        if (!_restoreSessionMatches(session)) return;
        if (session.completer.isCompleted) {
          await _applyRestoreVerificationOutcome(
            session,
            session.outcomeAfterDrain(await session.completer.future),
          );
          return;
        }
        if (session.sawInactivePurchase) {
          await _applyRestoreVerificationOutcome(
            session,
            _RestoreVerificationOutcome.inactive,
          );
          return;
        }
        if (subscriptionSerialBeforeRefresh !=
            _storeSubscriptionRefreshSerial) {
          return;
        }
        if (refreshed.hasUnexpiredStorePeriod) {
          final workspaceReady = await _prepareInitialActivationWorkspace(
            verifiedSubscription: refreshed,
            requiresReload: requiresInitialWorkspaceReload,
            sessionEpoch: session.sessionEpoch,
            accountId: session.accountId,
            storeId: session.storeId,
          );
          if (!workspaceReady || !_restoreSessionMatches(session)) return;
          _updateSubscription(refreshed, operationId: session.operationId);
          _noticeMessage = session.unfinishedLookupFailed
              ? 'تم تحديث الاشتراك الحالي من الخادم، لكن تعذر فحص معاملات App Store القديمة. أعد الاستعادة لاحقاً قبل الشراء.'
              : 'لم يرسل المتجر عملية جديدة، وتم تحديث حالة الاشتراك الحالي من الخادم.';
          _subscriptionFlow.setMessage(
            scope: scope,
            operationId: session.operationId,
            message: session.unfinishedLookupFailed
                ? 'تعذر فحص معاملات App Store القديمة؛ أعد الاستعادة لاحقاً قبل الشراء.'
                : null,
          );
          return;
        }
        _updateSubscription(refreshed, operationId: session.operationId);
      } catch (error) {
        if (!_restoreSessionMatches(session)) return;
        _subscriptionFlow.setMessage(
          scope: scope,
          operationId: session.operationId,
          message: _friendlyError(error),
        );
        return;
      }
    }
    _subscriptionFlow.setMessage(
      scope: scope,
      operationId: session.operationId,
      message: session.unfinishedLookupFailed
          ? 'لم نجد اشتراكاً حالياً، وتعذر فحص معاملات App Store القديمة. تحقق من الاتصال ثم أعد الاستعادة.'
          : 'لم نجد مشتريات قابلة للاستعادة على حساب المتجر الحالي.',
    );
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
    bool allowLegacyBindingRecovery = false,
  }) {
    final account = _account;
    final store = _store;
    if (account == null || store == null) return false;
    if (!allowLegacyBindingRecovery &&
        event.accountId != null &&
        event.accountId != account.id) {
      return false;
    }
    if (!allowLegacyBindingRecovery &&
        event.storeId != null &&
        event.storeId != store.id) {
      return false;
    }
    if (event.platform == StoreBillingPlatform.googlePlay &&
        !allowUnboundGoogle &&
        (event.accountId == null || event.storeId == null)) {
      return false;
    }
    if (event.platform == StoreBillingPlatform.appStore) {
      final token = _normalizedAppleBindingId(event.appAccountToken);
      if (!allowLegacyBindingRecovery &&
          token != null &&
          token != _normalizedAppleBindingId(account.id) &&
          token != _normalizedAppleBindingId(store.id)) {
        return false;
      }
    }
    return true;
  }

  void _finishPurchaseIntent(_StorePurchaseIntent intent, {String? message}) {
    if (!identical(_activePurchaseIntent, intent)) return;
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = null;
    _activePurchaseIntent = null;
    final scope = BillingScope(
      accountId: intent.accountId,
      storeId: intent.storeId,
      epoch: intent.sessionEpoch,
    );
    _subscriptionFlow.finishOperation(
      scope: scope,
      operationId: intent.operationId,
      message: message,
    );
  }

  void _cancelPurchaseWatchdog(_StorePurchaseIntent intent) {
    if (!identical(_activePurchaseIntent, intent)) return;
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = null;
  }

  void _recordStoreBillingFailure(Object error) {
    final message = _friendlyError(error);
    // قد يرسل المتجر خطأً عاماً على stream بينما تحقق إيصال موثوق جارٍ
    // بالفعل. لا تُلغِ العملية هنا، لأن نتيجة الخادم هي صاحبة القرار النهائي؛
    // وإلا قد ينجح التحقق لاحقاً بعد أن فُك ارتباطه بعملية الواجهة.
    if (_processingPurchases.isNotEmpty) {
      final scope = _currentBillingScope;
      final operation = _subscriptionFlow.state.operation;
      if (scope != null && operation != null) {
        _subscriptionFlow.setMessage(
          scope: scope,
          operationId: operation.operationId,
          message:
              'وصل تنبيه من متجر التطبيقات، وما زال التحقق من الإيصال جارياً…',
        );
      }
      return;
    }
    final intent = _activePurchaseIntent;
    if (intent != null) {
      _finishPurchaseIntent(intent, message: message);
      return;
    }
    final restore = _activeRestoreSession;
    if (restore != null && _restoreSessionMatches(restore)) {
      final scope = BillingScope(
        accountId: restore.accountId,
        storeId: restore.storeId,
        epoch: restore.sessionEpoch,
      );
      _subscriptionFlow.setMessage(
        scope: scope,
        operationId: restore.operationId,
        message: message,
      );
      restore.markFailure();
      return;
    }
    final scope = _currentBillingScope;
    if (scope != null) {
      final operation = _subscriptionFlow.state.operation;
      if (operation != null) {
        _subscriptionFlow.finishOperation(
          scope: scope,
          operationId: operation.operationId,
          message: message,
        );
      } else {
        _subscriptionFlow.setMessage(scope: scope, message: message);
      }
    }
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
        !subscription.canRefreshStoreBilling ||
        _membership?.role.canManageSubscription != true ||
        _subscriptionFlow.state.operationInProgress) {
      return;
    }
    if (!force &&
        storeSubscriptionVerificationIsFresh(
          subscription,
          now: DateTime.now(),
          maxAge: maxAge,
        )) {
      return;
    }
    final sessionEpoch = _billingSessionEpoch;
    final refreshSerial = ++_storeSubscriptionRefreshSerial;
    final operationGeneration = _billingOperationGeneration;
    try {
      final scope = _currentBillingScope;
      if (scope == null) return;
      final refreshed = await _refreshStoreSubscriptionShared(scope);
      if (refreshSerial != _storeSubscriptionRefreshSerial ||
          operationGeneration != _billingOperationGeneration ||
          _subscriptionFlow.state.operationInProgress ||
          !_billingContextMatches(
            sessionEpoch,
            accountId: account.id,
            storeId: store.id,
          )) {
        return;
      }
      _updateSubscription(refreshed);
      notifyListeners();
    } catch (_) {
      // Keep the last server-known entitlement. A failed background refresh
      // never grants access and should not interrupt the owner's sign-in.
    }
  }

  Future<SubscriptionInfo> _refreshStoreSubscriptionShared(BillingScope scope) {
    final active = _storeSubscriptionRefreshInFlight;
    if (active != null && _storeSubscriptionRefreshScope == scope) {
      return active;
    }
    late final Future<SubscriptionInfo> shared;
    shared = _repository!
        .refreshStoreSubscription(scope.storeId)
        .timeout(const Duration(seconds: 35))
        .whenComplete(() {
          if (identical(_storeSubscriptionRefreshInFlight, shared)) {
            _storeSubscriptionRefreshInFlight = null;
            _storeSubscriptionRefreshScope = null;
          }
        });
    _storeSubscriptionRefreshScope = scope;
    _storeSubscriptionRefreshInFlight = shared;
    return shared;
  }

  void clearMessages() {
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
  }

  Future<void> _loadWorkspace() async {
    final scopeBeforeLoad = _currentBillingScope;
    final billingGenerationBeforeLoad = _billingOperationGeneration;
    final subscriptionSerialBeforeLoad = _storeSubscriptionRefreshSerial;
    final snapshot = await _repository!.loadWorkspace();
    if (snapshot == null) {
      _stage = AppStage.onboarding;
      return;
    }
    if (scopeBeforeLoad != null && _currentBillingScope != scopeBeforeLoad) {
      return;
    }
    final preserveNewerSubscription =
        scopeBeforeLoad != null &&
        snapshot.store.id == scopeBeforeLoad.storeId &&
        (_billingOperationGeneration != billingGenerationBeforeLoad ||
            _storeSubscriptionRefreshSerial != subscriptionSerialBeforeLoad);
    _applySnapshot(snapshot, applySubscription: !preserveNewerSubscription);
    await _loadWorkspaceData();
    _stage = AppStage.ready;
    unawaited(_drainQueuedStorePurchaseEvents());
  }

  void _applySnapshot(
    WorkspaceSnapshot snapshot, {
    bool applySubscription = true,
  }) {
    if (_store != null && _store!.id != snapshot.store.id) {
      _invalidateBillingSession(clearQueuedEvents: true);
    }
    _store = snapshot.store;
    _membership = snapshot.membership;
    if (applySubscription || _subscriptionFlow.state.scope == null) {
      _attachSubscriptionScope(snapshot.subscription);
    }
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
      return 'استُخدمت الخطة المجانية سابقاً على هذا الحساب أو التثبيت. يمكنك الانضمام إلى متجر بدعوة أو اختيار اشتراك مدفوع.';
    }
    if (value.contains('app_update_required_for_trial')) {
      return 'حدّث ضمانك إلى آخر نسخة لحماية الخطة المجانية ثم حاول مجدداً.';
    }
    if (value.contains('trial_device') || value.contains('free_device')) {
      return 'تعذّر ربط الخطة المجانية بهذا التثبيت. حدّث التطبيق ثم حاول مجدداً.';
    }
    if (value.contains('free_session_required')) {
      return 'انتهت جلسة حماية الخطة المجانية. سجّل الدخول مجدداً ثم حاول.';
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
    if (value.contains('apple_existing_subscription_restore_required')) {
      return 'وجد App Store اشتراك ضمانك فعالاً، بينما لا توجد حالة مرتبطة بهذا المتجر. لم نفتح الدفع؛ استخدم استعادة المشتريات لربطه بأمان.';
    }
    if (value.contains('apple_subscription_account_mismatch')) {
      return 'اشتراك هذا المتجر مرتبط بحساب App Store آخر. لم نفتح الدفع لتجنب اشتراكين؛ سجّل الدخول إلى حساب الوسائط والمشتريات الذي اشتركت منه ثم أعد المحاولة.';
    }
    if (value.contains('apple_subscription_state_changed') ||
        value.contains('apple_subscription_state_invalid')) {
      return 'تغيّرت حالة اشتراك App Store أو تعذر مطابقتها بأمان. لم نفتح الدفع؛ حدّث الحالة ثم أعد المحاولة.';
    }
    if (value.contains('apple_subscription_lookup_timeout') ||
        value.contains('apple_subscription_lookup_failed')) {
      return 'تعذر التأكد من اشتراكات App Store الحالية. لم نفتح الدفع لتجنب عملية مكررة؛ تحقق من الاتصال ثم استخدم الاستعادة أو أعد المحاولة.';
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
    if (value.contains('store_subscription_downgrade_not_allowed') ||
        value.contains('google_subscription_downgrade_not_allowed')) {
      return 'لا يمكن الانتقال إلى باقة أقل ما دام اشتراكك الحالي سارياً. يمكنك الترقية أو تغيير دورة الفوترة فقط.';
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
        value.contains('store_subscription_history_unavailable') ||
        value.contains('store_subscription_state_invalid')) {
      return 'تعذر تأكيد الاشتراك الحالي قبل تغييره. لم يبدأ ضمانك اشتراكاً جديداً؛ تحقق من حساب المتجر ثم حاول مجدداً.';
    }
    if (value.contains('item_already_owned') ||
        value.contains('itemalreadyowned') ||
        value.contains('already_owned') ||
        value.contains('already subscribed') ||
        value.contains('storekit_duplicate_product_object') ||
        value.contains('storekitduplicateproductobject') ||
        value.contains('unfinished_transaction') ||
        value.contains('unfinished transaction')) {
      return 'وجد App Store معاملة سابقة غير منتهية لهذه الباقة. لا تدفع مرة أخرى؛ اضغط استعادة المشتريات، وانتظر نتيجتها، ثم أعد اختيار الباقة.';
    }
    if (value.contains('store_rate_limited') ||
        value.contains('store_verification_rate_limited') ||
        value.contains('status: 429')) {
      return 'تكررت محاولات التحقق خلال وقت قصير. انتظر قليلاً ثم استخدم الاستعادة مرة واحدة.';
    }
    if (value.contains('purchase_conflict')) {
      return 'هذه المشتريات مرتبطة مسبقاً بحساب أو متجر ضمانك آخر، ولا يمكن نقلها تلقائياً.';
    }
    if (value.contains('purchase_recovery_not_allowed')) {
      return 'الاشتراك ما زال مرتبطاً بحساب أو متجر ضمانك قائم، لذلك لا يمكن نقله إلى هذا المتجر.';
    }
    if (value.contains('purchase_recovery_proof_invalid')) {
      return 'تعذر إثبات أن عملية المتجر تخص الاشتراك القديم لهذا الحساب. تحقق من حساب المتجر ثم حاول الاستعادة مجدداً.';
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
    _storeSubscriptionRefreshSerial += 1;
    _storeSubscriptionRefreshInFlight = null;
    _storeSubscriptionRefreshScope = null;
    final attachedScope = _subscriptionFlow.state.scope;
    if (attachedScope != null) {
      _subscriptionFlow.detach(scope: attachedScope);
    }
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
    _processingPurchases.clear();
    _verifiedPurchaseEvents.clear();
    _activeBranchId = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _purchaseWatchdog?.cancel();
    unawaited(_billingSubscription?.cancel());
    unawaited(_billingService.dispose());
    super.dispose();
  }
}

StoreBillingState _catalogBillingState(CatalogSnapshot catalog) =>
    switch (catalog.status) {
      CatalogStatus.idle => StoreBillingState.idle,
      CatalogStatus.loading => StoreBillingState.loading,
      CatalogStatus.ready => StoreBillingState.ready,
      CatalogStatus.unavailable => StoreBillingState.unavailable,
    };

String? _normalizedAppleBindingId(String? value) {
  final normalized = value?.trim().toLowerCase();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

class _StorePurchaseIntent {
  const _StorePurchaseIntent({
    required this.operationId,
    required this.sessionEpoch,
    required this.accountId,
    required this.storeId,
    required this.platform,
    required this.productId,
    required this.planId,
    required this.cycle,
    required this.startedAt,
  });

  final String operationId;
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
    required this.operationId,
    required this.sessionEpoch,
    required this.accountId,
    required this.storeId,
    required this.silent,
  });

  final String operationId;
  final int sessionEpoch;
  final String accountId;
  final String storeId;
  final bool silent;
  bool get recoveryRequested => !silent;
  final Completer<_RestoreVerificationOutcome> completer = Completer();
  bool sawInactivePurchase = false;
  bool verificationFailed = false;
  int expectedStorePurchases = 0;
  int remainingStorePurchases = 0;
  bool unfinishedLookupFailed = false;
  bool officialRestoreFailed = false;
  bool restoreResultUnknown = false;
  final Set<String> _observedEventKeys = <String>{};
  final Set<String> _verifiedEventKeys = <String>{};
  final Set<String> _activeEventKeys = <String>{};
  final Set<String> _settledEventKeys = <String>{};
  final Set<String> _failedEventKeys = <String>{};
  int _eventRevision = 0;
  int _verificationsInProgress = 0;
  Completer<void>? _verificationSettled;

  bool get verificationInProgress => _verificationsInProgress > 0;
  int get eventRevision => _eventRevision;

  void beginVerification() {
    if (_verificationsInProgress == 0) {
      _verificationSettled = Completer<void>();
    }
    _verificationsInProgress += 1;
  }

  void endVerification() {
    if (_verificationsInProgress == 0) return;
    _verificationsInProgress -= 1;
    if (_verificationsInProgress == 0) {
      _verificationSettled?.complete();
      _verificationSettled = null;
    }
  }

  Future<void> waitForVerificationToSettle() => verificationInProgress
      ? _verificationSettled!.future
      : Future<void>.value();

  void observe(String eventKey) {
    _eventRevision += 1;
    _observedEventKeys.add(eventKey);
  }

  void markVerified(
    String eventKey, {
    required bool usable,
    required bool settled,
  }) {
    observe(eventKey);
    _verifiedEventKeys.add(eventKey);
    if (settled) _settledEventKeys.add(eventKey);
    if (usable) {
      _activeEventKeys.add(eventKey);
      complete(_RestoreVerificationOutcome.active);
    } else {
      sawInactivePurchase = true;
      complete(_RestoreVerificationOutcome.inactive);
    }
  }

  void markFailure([String? eventKey]) {
    verificationFailed = true;
    if (eventKey != null) {
      observe(eventKey);
      _failedEventKeys.add(eventKey);
    }
    complete(_RestoreVerificationOutcome.failed);
  }

  _RestoreVerificationOutcome outcomeAfterDrain(
    _RestoreVerificationOutcome firstOutcome,
  ) {
    final expectedEventsMissing =
        expectedStorePurchases > 0 &&
        _observedEventKeys.length < expectedStorePurchases;
    if (verificationFailed ||
        _failedEventKeys.isNotEmpty ||
        expectedEventsMissing) {
      return _RestoreVerificationOutcome.failed;
    }
    if (_verifiedEventKeys.isNotEmpty) {
      if (_settledEventKeys.length < _verifiedEventKeys.length) {
        return _RestoreVerificationOutcome.failed;
      }
      if (_activeEventKeys.isNotEmpty) {
        return _RestoreVerificationOutcome.active;
      }
    }
    if (sawInactivePurchase) return _RestoreVerificationOutcome.inactive;
    if (unfinishedLookupFailed || officialRestoreFailed) {
      return _RestoreVerificationOutcome.failed;
    }
    return firstOutcome;
  }

  _RestoreVerificationOutcome get timeoutOutcome {
    if (verificationFailed ||
        unfinishedLookupFailed ||
        officialRestoreFailed ||
        restoreResultUnknown) {
      return _RestoreVerificationOutcome.failed;
    }
    if (sawInactivePurchase) return _RestoreVerificationOutcome.inactive;
    return _RestoreVerificationOutcome.notFound;
  }

  void complete(_RestoreVerificationOutcome outcome) {
    if (!completer.isCompleted) completer.complete(outcome);
  }
}
