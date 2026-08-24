import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/damanak_repository.dart';
import '../data/demo_repository.dart';
import '../models/account.dart';
import '../models/maintenance_request.dart';
import '../models/product.dart';
import '../models/store_profile.dart';
import '../models/subscription.dart';
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
  final List<Warranty> _warranties = [];
  final List<MaintenanceRequest> _requests = [];
  final List<TeamMember> _team = [];
  final List<PlanInfo> _plans = [];
  bool _busy = false;
  String? _errorMessage;
  String? _noticeMessage;

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
  );
  UnmodifiableListView<Product> get products => UnmodifiableListView(_products);
  UnmodifiableListView<Warranty> get warranties =>
      UnmodifiableListView(_warranties);
  UnmodifiableListView<MaintenanceRequest> get requests =>
      UnmodifiableListView(_requests);
  UnmodifiableListView<TeamMember> get team => UnmodifiableListView(_team);
  UnmodifiableListView<PlanInfo> get plans => UnmodifiableListView(_plans);

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
  }) async {
    await _guard(() async {
      _store = await _repository!.updateStore(
        storeId: _store!.id,
        name: name,
        phone: phone,
        city: city,
        countryCode: countryCode,
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

  Future<Product?> addProduct({
    required String name,
    required String brand,
    required String barcode,
    required String sku,
    required int warrantyMonths,
    required num? salePrice,
  }) async {
    Product? created;
    await _guard(() async {
      created = await _repository!.createProduct(
        storeId: _store!.id,
        name: name,
        brand: brand,
        barcode: barcode,
        sku: sku,
        warrantyMonths: warrantyMonths,
        salePrice: salePrice,
      );
      _products.insert(0, created!);
    });
    return created;
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
    String? productId,
    required String customerName,
    required String customerPhone,
    required String productName,
    String barcode = '',
    required String serialNumber,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required String notes,
  }) async {
    Warranty? created;
    await _guard(() async {
      created = await _repository!.createWarranty(
        storeId: _store!.id,
        productId: productId,
        customerName: customerName,
        customerPhone: customerPhone,
        productName: productName,
        barcode: barcode,
        serialNumber: serialNumber,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        notes: notes,
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
      _repository!.loadWarranties(storeId),
      _repository!.loadRequests(storeId),
      _repository!.loadTeam(storeId),
      _repository!.loadPlans(),
    ]);
    _products
      ..clear()
      ..addAll(results[0] as List<Product>);
    _warranties
      ..clear()
      ..addAll(results[1] as List<Warranty>);
    _requests
      ..clear()
      ..addAll(results[2] as List<MaintenanceRequest>);
    _team
      ..clear()
      ..addAll(results[3] as List<TeamMember>);
    _plans
      ..clear()
      ..addAll(results[4] as List<PlanInfo>);
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
    _warranties.clear();
    _requests.clear();
    _team.clear();
    _plans.clear();
  }
}
