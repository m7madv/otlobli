import 'package:uuid/uuid.dart';

import '../core/date_utils.dart';
import '../models/account.dart';
import '../models/maintenance_request.dart';
import '../models/product.dart';
import '../models/subscription.dart';
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
        barcode: '6281000000142',
        sku: 'COF-440',
        warrantyMonths: 24,
        salePrice: 649,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Product(
        id: _uuid.v4(),
        storeId: _store.id,
        name: 'سماعة لاسلكية',
        brand: 'NOVA',
        barcode: '6281000000296',
        sku: 'AUD-210',
        warrantyMonths: 12,
        salePrice: 219,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Product(
        id: _uuid.v4(),
        storeId: _store.id,
        name: 'مكنسة ذكية',
        brand: 'HomePilot',
        barcode: '6281000000333',
        sku: 'VAC-330',
        warrantyMonths: 24,
        salePrice: 1290,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 3)),
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
  final List<Warranty> _warranties = [];
  final List<MaintenanceRequest> _requests = [];
  final List<TeamMember> _members = [];

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
  Future<AccountIdentity> signIn({
    required String email,
    required String password,
  }) async => _account;

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async => const SignUpResult(account: _account, needsConfirmation: false);

  @override
  Future<void> signOut() async {}

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
  }) async {
    _store = StoreWorkspace(
      id: storeId,
      name: name.trim(),
      phone: phone.trim(),
      city: city.trim(),
      countryCode: countryCode,
    );
    return _store;
  }

  @override
  Future<List<Product>> loadProducts(String storeId) async => [..._products];

  @override
  Future<Product> createProduct({
    required String storeId,
    required String name,
    required String brand,
    required String barcode,
    required String sku,
    required int warrantyMonths,
    required num? salePrice,
  }) async {
    final product = Product(
      id: _uuid.v4(),
      storeId: storeId,
      name: name.trim(),
      brand: brand.trim(),
      barcode: barcode.trim(),
      sku: sku.trim(),
      warrantyMonths: warrantyMonths,
      salePrice: salePrice,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _products.insert(0, product);
    return product;
  }

  @override
  Future<List<Warranty>> loadWarranties(String storeId) async => [
    ..._warranties,
  ];

  @override
  Future<Warranty> createWarranty({
    required String storeId,
    required String? productId,
    required String customerName,
    required String customerPhone,
    required String productName,
    required String barcode,
    required String serialNumber,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required String notes,
  }) async {
    final id = _uuid.v4();
    final warranty = Warranty(
      id: id,
      warrantyNumber: 'DMN-${id.substring(0, 6).toUpperCase()}',
      storeId: storeId,
      productId: productId,
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
    );
    _warranties.insert(0, warranty);
    _subscription = SubscriptionInfo(
      id: _subscription.id,
      status: _subscription.status,
      plan: _subscription.plan,
      trialEndsAt: _subscription.trialEndsAt,
      periodEndsAt: _subscription.periodEndsAt,
      usedWarranties: _subscription.usedWarranties + 1,
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
  Future<void> requestSubscription({
    required String storeId,
    required String planId,
    required String billingCycle,
    required String contactPhone,
  }) async {}

  @override
  Future<SubscriptionInfo> redeemSubscriptionCode({
    required String storeId,
    required String code,
  }) async {
    _subscription = SubscriptionInfo(
      id: _subscription.id,
      status: 'active',
      plan: _plan,
      trialEndsAt: null,
      periodEndsAt: DateTime.now().add(const Duration(days: 365)),
      usedWarranties: _subscription.usedWarranties,
    );
    return _subscription;
  }
}
