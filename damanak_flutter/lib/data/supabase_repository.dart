import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  @override
  Future<void> signInWithSocial(SocialAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider == SocialAuthProvider.google
          ? OAuthProvider.google
          : OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'com.damanak.damanak://login-callback',
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _client.rpc('delete_current_account');
    await _client.auth.signOut();
  }

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
        source: subscriptionJson['source'] as String? ?? 'trial',
        billingProvider: subscriptionJson['billing_provider'] as String?,
        storeProductId: subscriptionJson['store_product_id'] as String?,
        billingCycle: subscriptionJson['billing_cycle'] as String?,
        autoRenews: subscriptionJson['auto_renews'] as bool? ?? false,
        lastVerifiedAt: _dateOrNull(subscriptionJson['last_store_verified_at']),
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
    required String currencyCode,
    required num taxRate,
    required bool pricesIncludeTax,
    required String taxNumber,
    required String commercialRegistration,
    required String address,
    required String invoicePrefix,
    required int defaultWarrantyMonths,
  }) async {
    final row = await _client
        .from('stores')
        .update({
          'name': name.trim(),
          'phone': phone.trim(),
          'city': city.trim(),
          'country_code': countryCode,
          'currency_code': currencyCode,
          'tax_rate': taxRate,
          'prices_include_tax': pricesIncludeTax,
          'tax_number': taxNumber.trim(),
          'commercial_registration': commercialRegistration.trim(),
          'address': address.trim(),
          'invoice_prefix': invoicePrefix.trim().toUpperCase(),
          'default_warranty_months': defaultWarrantyMonths,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', storeId)
        .select()
        .single();
    return StoreWorkspace.fromJson(row);
  }

  @override
  Future<List<StoreBranch>> loadBranches(String storeId) async {
    final rows = await _client
        .from('branches')
        .select()
        .eq('store_id', storeId)
        .eq('is_active', true)
        .order('is_main', ascending: false)
        .order('name');
    return rows.map(StoreBranch.fromJson).toList();
  }

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
    if (isMain) {
      await _client
          .from('branches')
          .update({'is_main': false})
          .eq('store_id', storeId);
    }
    final values = <String, dynamic>{
      'store_id': storeId,
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'city': city.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
      'is_main': isMain,
      'email': _nullable(email),
      'manager_name': managerName.trim(),
      'receipt_prefix': receiptPrefix.trim().toUpperCase(),
      'timezone': timezone.trim(),
      'opens_at': opensAt,
      'closes_at': closesAt,
      'branch_type': type.databaseValue,
      'accepts_sales': acceptsSales,
      'handles_service': handlesService,
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final row = branchId == null
        ? await _client.from('branches').insert(values).select().single()
        : await _client
              .from('branches')
              .update(values)
              .eq('id', branchId)
              .eq('store_id', storeId)
              .select()
              .single();
    return StoreBranch.fromJson(row);
  }

  @override
  Future<List<CustomerProfile>> loadCustomers(String storeId) async {
    final rows = await _client
        .from('customers')
        .select()
        .eq('store_id', storeId)
        .order('updated_at', ascending: false);
    return rows.map(CustomerProfile.fromJson).toList();
  }

  @override
  Future<CustomerProfile> saveCustomer({
    required String storeId,
    String? customerId,
    required String name,
    required String phone,
    required String email,
    required String notes,
  }) async {
    final values = <String, dynamic>{
      'store_id': storeId,
      'name': name.trim(),
      'phone': phone.trim(),
      'email': _nullable(email),
      'notes': notes.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (customerId != null) {
      final row = await _client
          .from('customers')
          .update(values)
          .eq('id', customerId)
          .eq('store_id', storeId)
          .select()
          .single();
      return CustomerProfile.fromJson(row);
    }
    final existing = await _client
        .from('customers')
        .select('id')
        .eq('store_id', storeId)
        .eq('phone', phone.trim())
        .maybeSingle();
    if (existing != null) {
      final row = await _client
          .from('customers')
          .update(values)
          .eq('id', existing['id'] as String)
          .select()
          .single();
      return CustomerProfile.fromJson(row);
    }
    final row = await _client
        .from('customers')
        .insert({...values, 'created_by': _user.id})
        .select()
        .single();
    return CustomerProfile.fromJson(row);
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
    final row = await _client
        .from('products')
        .insert({
          'store_id': storeId,
          'name': name.trim(),
          'brand': brand.trim(),
          'category': category.trim(),
          'barcode': _nullable(barcode),
          'sku': _nullable(sku),
          'warranty_months': warrantyMonths,
          'sale_price': salePrice,
          'cost_price': costPrice,
          'track_inventory': trackInventory,
          'is_serialized': isSerialized,
          'reorder_point': reorderPoint,
          'created_by': _user.id,
        })
        .select()
        .single();
    return Product.fromJson(row);
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
    final row = await _client
        .from('products')
        .update({
          'name': name.trim(),
          'brand': brand.trim(),
          'category': category.trim(),
          'barcode': _nullable(barcode),
          'sku': _nullable(sku),
          'warranty_months': warrantyMonths,
          'sale_price': salePrice,
          'cost_price': costPrice,
          'track_inventory': trackInventory,
          'is_serialized': isSerialized,
          'reorder_point': reorderPoint,
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productId)
        .eq('store_id', storeId)
        .select()
        .single();
    return Product.fromJson(row);
  }

  @override
  Future<List<InventoryLevel>> loadInventory(String storeId) async {
    final rows = await _client
        .from('inventory_levels')
        .select()
        .eq('store_id', storeId)
        .order('updated_at', ascending: false);
    return rows.map(InventoryLevel.fromJson).toList();
  }

  @override
  Future<List<StockMovement>> loadStockMovements(String storeId) async {
    final rows = await _client
        .from('stock_movements')
        .select()
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(250);
    return rows.map(StockMovement.fromJson).toList();
  }

  @override
  Future<InventoryLevel> adjustInventory({
    required String storeId,
    required String branchId,
    required String productId,
    required num newQuantity,
    required num unitCost,
    required String note,
  }) async {
    final value = await _client.rpc(
      'adjust_inventory',
      params: {
        'target_store_id': storeId,
        'target_branch_id': branchId,
        'target_product_id': productId,
        'new_quantity': newQuantity,
        'target_unit_cost': unitCost,
        'target_note': note.trim(),
      },
    );
    return InventoryLevel.fromJson(Map<String, dynamic>.from(value as Map));
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
    await _client.rpc(
      'transfer_inventory',
      params: {
        'target_store_id': storeId,
        'target_product_id': productId,
        'source_branch_id': fromBranchId,
        'destination_branch_id': toBranchId,
        'target_quantity': quantity,
        'target_note': note.trim(),
      },
    );
  }

  @override
  Future<List<SaleTransaction>> loadSales(String storeId) async {
    final rows = await _client
        .from('sales')
        .select('*, sale_lines(*), sale_payments(*)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(250);
    return rows.map(SaleTransaction.fromJson).toList();
  }

  Future<SaleTransaction> _loadSale(String saleId) async {
    final row = await _client
        .from('sales')
        .select('*, sale_lines(*), sale_payments(*)')
        .eq('id', saleId)
        .single();
    return SaleTransaction.fromJson(row);
  }

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
    final value = await _client.rpc(
      'create_sale',
      params: {
        'target_store_id': storeId,
        'target_branch_id': branchId,
        'target_customer_id': customerId,
        'target_customer_name': customerName.trim(),
        'target_customer_phone': customerPhone.trim(),
        'sale_lines_input': lines.map((item) => item.toJson()).toList(),
        'sale_payments_input': payments
            .map(
              (item) => {
                'payment_method': item.method.databaseValue,
                'amount': item.amount,
                'reference': item.reference.trim(),
              },
            )
            .toList(),
        'order_discount': orderDiscount,
        'target_notes': notes.trim(),
      },
    );
    return _loadSale(value as String);
  }

  @override
  Future<SaleTransaction> returnSale({
    required String storeId,
    required String saleId,
    required Map<String, num> lineQuantities,
    required PaymentMethod refundMethod,
    required String reason,
  }) async {
    await _client.rpc(
      'return_sale',
      params: {
        'target_store_id': storeId,
        'target_sale_id': saleId,
        'returned_lines': lineQuantities.entries
            .map((item) => {'sale_line_id': item.key, 'quantity': item.value})
            .toList(),
        'refund_method': refundMethod.databaseValue,
        'return_reason': reason.trim(),
      },
    );
    return _loadSale(saleId);
  }

  @override
  Future<List<CashRegisterSession>> loadRegisterSessions(String storeId) async {
    final rows = await _client
        .from('register_sessions')
        .select()
        .eq('store_id', storeId)
        .order('opened_at', ascending: false)
        .limit(100);
    return rows.map(CashRegisterSession.fromJson).toList();
  }

  @override
  Future<CashRegisterSession> openRegister({
    required String storeId,
    required String branchId,
    required num openingCash,
    required String notes,
  }) async {
    final value = await _client.rpc(
      'open_register',
      params: {
        'target_store_id': storeId,
        'target_branch_id': branchId,
        'target_opening_cash': openingCash,
        'target_notes': notes.trim(),
      },
    );
    return CashRegisterSession.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
  }

  @override
  Future<CashRegisterSession> closeRegister({
    required String sessionId,
    required num closingCash,
    required String notes,
  }) async {
    final value = await _client.rpc(
      'close_register',
      params: {
        'target_session_id': sessionId,
        'target_closing_cash': closingCash,
        'target_notes': notes.trim(),
      },
    );
    return CashRegisterSession.fromJson(
      Map<String, dynamic>.from(value as Map),
    );
  }

  @override
  Future<List<Supplier>> loadSuppliers(String storeId) async {
    final rows = await _client
        .from('suppliers')
        .select()
        .eq('store_id', storeId)
        .eq('is_active', true)
        .order('name');
    return rows.map(Supplier.fromJson).toList();
  }

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
    final values = <String, dynamic>{
      'store_id': storeId,
      'name': name.trim(),
      'contact_name': contactName.trim(),
      'phone': phone.trim(),
      'email': _nullable(email),
      'tax_number': taxNumber.trim(),
      'address': address.trim(),
      'notes': notes.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    final row = supplierId == null
        ? await _client.from('suppliers').insert(values).select().single()
        : await _client
              .from('suppliers')
              .update(values)
              .eq('id', supplierId)
              .eq('store_id', storeId)
              .select()
              .single();
    return Supplier.fromJson(row);
  }

  @override
  Future<List<PurchaseOrder>> loadPurchaseOrders(String storeId) async {
    final rows = await _client
        .from('purchase_orders')
        .select('*, purchase_order_lines(*)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
    return rows.map(PurchaseOrder.fromJson).toList();
  }

  @override
  Future<PurchaseOrder> createPurchaseOrder({
    required String storeId,
    required String branchId,
    required String supplierId,
    required DateTime? expectedAt,
    required String notes,
    required List<PurchaseOrderLineInput> lines,
  }) async {
    final value = await _client.rpc(
      'create_purchase_order',
      params: {
        'target_store_id': storeId,
        'target_branch_id': branchId,
        'target_supplier_id': supplierId,
        'target_expected_at': expectedAt?.toIso8601String(),
        'target_notes': notes.trim(),
        'purchase_lines_input': lines.map((item) => item.toJson()).toList(),
      },
    );
    return _loadPurchaseOrder(value as String);
  }

  Future<PurchaseOrder> _loadPurchaseOrder(String id) async {
    final row = await _client
        .from('purchase_orders')
        .select('*, purchase_order_lines(*)')
        .eq('id', id)
        .single();
    return PurchaseOrder.fromJson(row);
  }

  @override
  Future<PurchaseOrder> receivePurchaseOrder(String purchaseOrderId) async {
    await _client.rpc(
      'receive_purchase_order',
      params: {'target_purchase_order_id': purchaseOrderId},
    );
    return _loadPurchaseOrder(purchaseOrderId);
  }

  @override
  Future<List<Warranty>> loadWarranties(String storeId) async {
    final rows = await _client
        .from('warranties')
        .select()
        .eq('store_id', storeId)
        .filter('voided_at', 'is', null)
        .order('created_at', ascending: false);
    return rows.map(Warranty.fromJson).toList();
  }

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
    final row = await _client
        .from('warranties')
        .insert({
          'store_id': storeId,
          'product_id': productId,
          'customer_id': customerId,
          'branch_id': branchId,
          'customer_name': customerName.trim(),
          'customer_phone': customerPhone.trim(),
          'product_name': productName.trim(),
          'barcode': _nullable(barcode),
          'serial_number': _nullable(serialNumber),
          'purchase_date': _date(purchaseDate),
          'expiry_date': _date(expiryDate),
          'notes': notes.trim(),
          'invoice_number': _nullable(invoiceNumber),
          'sale_subtotal': saleSubtotal,
          'discount_amount': discountAmount,
          'tax_amount': taxAmount,
          'sale_total': saleTotal,
          'tax_rate': taxRate,
          'currency_code': currencyCode,
          'payment_method': paymentMethod.databaseValue,
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
  Future<List<AuditEvent>> loadAuditLogs(String storeId) async {
    final rows = await _client
        .from('audit_logs')
        .select()
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(AuditEvent.fromJson).toList();
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
  Future<SubscriptionInfo> verifyStorePurchase({
    required String storeId,
    required StorePurchaseReceipt receipt,
  }) async {
    final response = await _client.functions.invoke(
      'verify-store-purchase',
      body: {
        'storeId': storeId,
        'platform': receipt.platform.value,
        'productId': receipt.productId,
        'basePlanId': receipt.basePlanId,
        'purchaseId': receipt.purchaseId,
        'transactionDate': receipt.transactionDate,
        'verificationData': receipt.verificationData,
        'verificationSource': receipt.verificationSource,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('STORE_VERIFICATION_FAILED');
    }
    final snapshot = await loadWorkspace();
    if (snapshot == null) throw StateError('WORKSPACE_NOT_FOUND');
    return snapshot.subscription;
  }

  @override
  Future<SubscriptionInfo> refreshStoreSubscription(String storeId) async {
    final response = await _client.functions.invoke(
      'verify-store-purchase',
      body: {'storeId': storeId, 'refresh': true},
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('STORE_VERIFICATION_FAILED');
    }
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
