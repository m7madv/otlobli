import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account.dart';
import '../models/maintenance_request.dart';
import '../models/product.dart';
import '../models/subscription.dart';
import '../models/warranty.dart';
import 'damanak_repository.dart';

class SupabaseDamanakRepository implements DamanakRepository {
  SupabaseDamanakRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isDemo => false;

  User get _user {
    final value = _client.auth.currentUser;
    if (value == null) throw StateError('AUTH_REQUIRED');
    return value;
  }

  @override
  Future<AccountIdentity?> restoreAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _identityFromUser(user);
  }

  @override
  Future<AccountIdentity> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) throw StateError('AUTH_FAILED');
    return _identityFromUser(user);
  }

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
    final user = response.user;
    if (user == null) throw StateError('AUTH_FAILED');
    return SignUpResult(
      account: _identityFromUser(user),
      needsConfirmation: response.session == null,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  AccountIdentity _identityFromUser(User user) {
    return AccountIdentity(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'] as String? ?? 'مستخدم ضمانك',
    );
  }

  @override
  Future<WorkspaceSnapshot?> loadWorkspace() async {
    final membershipJson = await _client
        .from('store_members')
        .select()
        .eq('user_id', _user.id)
        .eq('status', 'active')
        .order('joined_at')
        .limit(1)
        .maybeSingle();
    if (membershipJson == null) return null;
    final membership = StoreMembership.fromJson(membershipJson);
    return _loadSnapshot(membership);
  }

  Future<WorkspaceSnapshot> _loadSnapshot(StoreMembership membership) async {
    final results = await Future.wait<Object>([
      _client.from('stores').select().eq('id', membership.storeId).single(),
      _client
          .from('subscriptions')
          .select('*, plans(*)')
          .eq('store_id', membership.storeId)
          .single(),
      _client.rpc(
        'current_warranty_usage',
        params: {'target_store_id': membership.storeId},
      ),
    ]);
    final store = StoreWorkspace.fromJson(
      Map<String, dynamic>.from(results[0] as Map),
    );
    final subscriptionJson = Map<String, dynamic>.from(results[1] as Map);
    final plan = PlanInfo.fromJson(
      Map<String, dynamic>.from(subscriptionJson['plans'] as Map),
    );
    final usage = (results[2] as num?)?.toInt() ?? 0;
    return WorkspaceSnapshot(
      store: store,
      membership: membership,
      subscription: SubscriptionInfo(
        id: subscriptionJson['id'] as String,
        status: subscriptionJson['status'] as String,
        plan: plan,
        trialEndsAt: _dateOrNull(subscriptionJson['trial_ends_at']),
        periodEndsAt: _dateOrNull(subscriptionJson['current_period_end']),
        usedWarranties: usage,
      ),
    );
  }

  @override
  Future<WorkspaceSnapshot> createStore({
    required String name,
    required String phone,
    required String city,
    required String countryCode,
  }) async {
    final value = await _client.rpc(
      'create_store_with_trial',
      params: {
        'store_name': name.trim(),
        'store_phone': phone.trim(),
        'store_city': city.trim(),
        'store_country_code': countryCode,
      },
    );
    final membership = StoreMembership(
      storeId: value as String,
      userId: _user.id,
      role: MemberRole.owner,
      status: 'active',
    );
    return _loadSnapshot(membership);
  }

  @override
  Future<WorkspaceSnapshot> joinStore(String invitationCode) async {
    final value = await _client.rpc(
      'join_store_by_code',
      params: {'invitation_code': invitationCode.trim().toUpperCase()},
    );
    final membershipJson = Map<String, dynamic>.from(value as Map);
    return _loadSnapshot(StoreMembership.fromJson(membershipJson));
  }

  @override
  Future<StoreWorkspace> updateStore({
    required String storeId,
    required String name,
    required String phone,
    required String city,
    required String countryCode,
  }) async {
    final row = await _client
        .from('stores')
        .update({
          'name': name.trim(),
          'phone': phone.trim(),
          'city': city.trim(),
          'country_code': countryCode,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', storeId)
        .select()
        .single();
    return StoreWorkspace.fromJson(row);
  }

  @override
  Future<List<Product>> loadProducts(String storeId) async {
    final rows = await _client
        .from('products')
        .select()
        .eq('store_id', storeId)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return rows.map(Product.fromJson).toList();
  }

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
    final row = await _client
        .from('products')
        .insert({
          'store_id': storeId,
          'name': name.trim(),
          'brand': brand.trim(),
          'barcode': _nullable(barcode),
          'sku': _nullable(sku),
          'warranty_months': warrantyMonths,
          'sale_price': salePrice,
          'created_by': _user.id,
        })
        .select()
        .single();
    return Product.fromJson(row);
  }

  @override
  Future<List<Warranty>> loadWarranties(String storeId) async {
    final rows = await _client
        .from('warranties')
        .select()
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
    return rows.map(Warranty.fromJson).toList();
  }

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
    final row = await _client
        .from('warranties')
        .insert({
          'store_id': storeId,
          'product_id': productId,
          'customer_name': customerName.trim(),
          'customer_phone': customerPhone.trim(),
          'product_name': productName.trim(),
          'barcode': _nullable(barcode),
          'serial_number': _nullable(serialNumber),
          'purchase_date': _date(purchaseDate),
          'expiry_date': _date(expiryDate),
          'notes': notes.trim(),
          'created_by': _user.id,
        })
        .select()
        .single();
    return Warranty.fromJson(row);
  }

  @override
  Future<void> deleteWarranty(String id) async {
    await _client.from('warranties').delete().eq('id', id);
  }

  @override
  Future<List<MaintenanceRequest>> loadRequests(String storeId) async {
    final rows = await _client
        .from('maintenance_requests')
        .select()
        .eq('store_id', storeId)
        .order('updated_at', ascending: false);
    return rows.map(MaintenanceRequest.fromJson).toList();
  }

  @override
  Future<MaintenanceRequest> createRequest({
    required String storeId,
    required String warrantyId,
    required String issue,
  }) async {
    final row = await _client
        .from('maintenance_requests')
        .insert({
          'store_id': storeId,
          'warranty_id': warrantyId,
          'issue': issue.trim(),
          'created_by': _user.id,
        })
        .select()
        .single();
    return MaintenanceRequest.fromJson(row);
  }

  @override
  Future<void> updateRequestStatus(
    String requestId,
    MaintenanceStatus status,
  ) async {
    final value = switch (status) {
      MaintenanceStatus.newRequest => 'new',
      MaintenanceStatus.inProgress => 'in_progress',
      MaintenanceStatus.completed => 'completed',
    };
    await _client
        .from('maintenance_requests')
        .update({
          'status': value,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  @override
  Future<List<TeamMember>> loadTeam(String storeId) async {
    final rows = await _client
        .from('store_member_directory')
        .select()
        .eq('store_id', storeId)
        .order('joined_at');
    return rows.map(TeamMember.fromJson).toList();
  }

  @override
  Future<StoreInvite> createInvite({
    required String storeId,
    required MemberRole role,
    required int maxUses,
  }) async {
    final value = await _client.rpc(
      'create_store_invite',
      params: {
        'target_store_id': storeId,
        'target_role': role.name,
        'allowed_uses': maxUses,
      },
    );
    final row = Map<String, dynamic>.from(value as Map);
    return StoreInvite(
      code: row['code'] as String,
      role: MemberRoleText.fromValue(row['role'] as String?),
      expiresAt: DateTime.parse(row['expires_at'] as String),
      maxUses: row['max_uses'] as int,
    );
  }

  @override
  Future<void> updateMember({
    required String storeId,
    required String userId,
    required MemberRole role,
    required bool active,
  }) async {
    await _client.rpc(
      'update_store_member',
      params: {
        'target_store_id': storeId,
        'target_user_id': userId,
        'target_role': role.name,
        'target_status': active ? 'active' : 'suspended',
      },
    );
  }

  @override
  Future<List<PlanInfo>> loadPlans() async {
    final rows = await _client
        .from('plans')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return rows.map(PlanInfo.fromJson).toList();
  }

  @override
  Future<void> requestSubscription({
    required String storeId,
    required String planId,
    required String billingCycle,
    required String contactPhone,
  }) async {
    await _client.from('subscription_requests').insert({
      'store_id': storeId,
      'requested_plan_id': planId,
      'billing_cycle': billingCycle,
      'contact_phone': contactPhone.trim(),
      'requested_by': _user.id,
    });
  }

  @override
  Future<SubscriptionInfo> redeemSubscriptionCode({
    required String storeId,
    required String code,
  }) async {
    await _client.rpc(
      'redeem_subscription_code',
      params: {
        'target_store_id': storeId,
        'activation_code': code.trim().toUpperCase(),
      },
    );
    final snapshot = await loadWorkspace();
    if (snapshot == null) throw StateError('WORKSPACE_NOT_FOUND');
    return snapshot.subscription;
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  DateTime? _dateOrNull(Object? value) {
    return value == null ? null : DateTime.tryParse(value as String);
  }
}
