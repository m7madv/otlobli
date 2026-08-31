import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
import '../models/subscription.dart';
import '../models/store_billing.dart';
import '../models/supplier.dart';
import '../models/warranty.dart';
import '../services/native_identity_token_service.dart';
import '../services/trial_device_claim_service.dart';
import 'damanak_repository.dart';

const _fallbackStoreVerificationError = 'STORE_VERIFICATION_FAILED';
const _publicStoreVerificationErrors = <String>{
  'AUTH_REQUIRED',
  'INVALID_PURCHASE_PAYLOAD',
  'METHOD_NOT_ALLOWED',
  'STORE_OWNER_REQUIRED',
  'STORE_PURCHASE_PENDING',
  'STORE_PURCHASE_PENDING_CANCELED',
  'STORE_VERIFICATION_RATE_LIMITED',
  _fallbackStoreVerificationError,
  'PURCHASE_NOT_VALID',
  'PURCHASE_CONFLICT',
  'SANDBOX_NOT_AVAILABLE',
  'PURCHASE_PROVIDER_UNAVAILABLE',
  'PURCHASE_VERIFICATION_UNAVAILABLE',
};
const _retryableStoreVerificationErrors = <String>{
  'STORE_PURCHASE_PENDING',
  'STORE_VERIFICATION_RATE_LIMITED',
  'STORE_VERIFICATION_FAILED',
  'PURCHASE_PROVIDER_UNAVAILABLE',
  'PURCHASE_VERIFICATION_UNAVAILABLE',
};

@immutable
class StoreVerificationException implements Exception {
  const StoreVerificationException({
    required this.code,
    required this.statusCode,
    required this.isRetryable,
    this.retryAfterSeconds,
    this.traceId,
  });

  final String code;
  final int statusCode;
  final bool isRetryable;
  final int? retryAfterSeconds;
  final String? traceId;

  @override
  String toString() {
    final fields = <String>[
      'code: $code',
      'statusCode: $statusCode',
      'isRetryable: $isRetryable',
      if (retryAfterSeconds != null) 'retryAfterSeconds: $retryAfterSeconds',
      if (traceId != null) 'traceId: $traceId',
    ];
    return 'StoreVerificationException(${fields.join(', ')})';
  }
}

@visibleForTesting
StoreVerificationException storeVerificationExceptionFromPayload({
  required int statusCode,
  Object? details,
}) {
  final payload = _storeVerificationErrorPayload(details);
  final rawCode = payload?['error'];
  final code =
      rawCode is String &&
          _publicStoreVerificationErrors.contains(rawCode.trim())
      ? rawCode.trim()
      : _fallbackStoreVerificationError;
  final retryAfterSeconds = code == 'STORE_VERIFICATION_RATE_LIMITED'
      ? _safeRetryAfterSeconds(payload?['retryAfterSeconds'])
      : null;
  final traceId = _safeStoreVerificationTraceId(payload?['traceId']);
  return StoreVerificationException(
    code: code,
    statusCode: statusCode,
    isRetryable:
        _retryableStoreVerificationErrors.contains(code) &&
        payload?['retryable'] != false,
    retryAfterSeconds: retryAfterSeconds,
    traceId: traceId,
  );
}

Map<String, Object?>? _storeVerificationErrorPayload(Object? details) {
  Object? decoded = details;
  if (details is String && details.length <= 4096) {
    try {
      decoded = jsonDecode(details);
    } on FormatException {
      return null;
    }
  }
  if (decoded is! Map) return null;
  return <String, Object?>{
    for (final entry in decoded.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

int? _safeRetryAfterSeconds(Object? value) {
  final int? parsed = switch (value) {
    int seconds => seconds,
    num seconds when seconds.isFinite && seconds == seconds.truncate() =>
      seconds.toInt(),
    String seconds => int.tryParse(seconds.trim()),
    _ => null,
  };
  if (parsed == null || parsed < 1 || parsed > 86400) return null;
  return parsed;
}

String? _safeStoreVerificationTraceId(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  if (normalized.length < 8 || normalized.length > 128) return null;
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(normalized)) return null;
  return normalized;
}

class SupabaseDamanakRepository implements DamanakRepository {
  SupabaseDamanakRepository(
    this._client, {
    NativeIdentityTokenProvider? nativeIdentityTokens,
    TrialDeviceClaimProvider? trialDeviceClaims,
  }) : _nativeIdentityTokens = nativeIdentityTokens,
       _trialDeviceClaims = trialDeviceClaims;

  final SupabaseClient _client;
  final NativeIdentityTokenProvider? _nativeIdentityTokens;
  final TrialDeviceClaimProvider? _trialDeviceClaims;

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
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> signInWithSocial(SocialAuthProvider provider) async {
    final nativeIdentityTokens = _nativeIdentityTokens;
    if (nativeIdentityTokens != null &&
        supportsNativeSocialAuth(
          provider: provider,
          isWeb: kIsWeb,
          platform: defaultTargetPlatform,
        )) {
      final tokens = await nativeIdentityTokens.authenticate(provider);
      try {
        await _client.auth.signInWithIdToken(
          provider: provider == SocialAuthProvider.google
              ? OAuthProvider.google
              : OAuthProvider.apple,
          idToken: tokens.idToken,
          accessToken: tokens.accessToken,
          nonce: tokens.nonce,
        );
      } on AuthException {
        throw StateError('AUTH_FAILED');
      }
      return;
    }

    final launched = await _client.auth.signInWithOAuth(
      provider == SocialAuthProvider.google
          ? OAuthProvider.google
          : OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'com.damanak.damanak://login-callback',
    );
    if (!launched) throw StateError('AUTH_WINDOW_NOT_OPENED');
  }

  @override
  Future<void> deleteAccount() async {
    await _client.rpc('delete_current_account');
    await _client.auth.signOut();
  }

  AccountIdentity _identityFromUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName =
        [metadata['full_name'], metadata['name'], metadata['user_name']]
            .whereType<String>()
            .map((value) => value.trim())
            .firstWhere(
              (value) => value.isNotEmpty,
              orElse: () => 'مستخدم ضمانك',
            );
    return AccountIdentity(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName,
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
    if (membership.role == MemberRole.owner && _trialDeviceClaims != null) {
      // Protect future trial attempts without adding a serial network request
      // to the sign-in/startup path. New-store creation remains blocking.
      unawaited(_registerTrialDevice(membership.storeId));
    }
    return _loadSnapshot(membership);
  }

  Future<void> _registerTrialDevice(String storeId) async {
    try {
      await _client.rpc(
        'register_trial_device',
        params: {
          'target_store_id': storeId,
          'device_claim': await _trialDeviceClaims!.loadOrCreateClaim(),
        },
      );
    } on Object {
      // Registration protects future trials, but a collision or unavailable
      // secure store must never lock an existing paid owner out of their data.
    }
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
    final usage = (results[2] as num?)?.toInt() ?? 0;
    return WorkspaceSnapshot(
      store: store,
      membership: membership,
      subscription: _subscriptionFromJson(subscriptionJson, usage),
    );
  }

  SubscriptionInfo _subscriptionFromJson(
    Map<String, dynamic> subscriptionJson,
    int usage,
  ) {
    final plan = PlanInfo.fromJson(
      Map<String, dynamic>.from(subscriptionJson['plans'] as Map),
    );
    return SubscriptionInfo(
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
    );
  }

  Future<SubscriptionInfo> _loadSubscriptionForStore(String storeId) async {
    final results = await Future.wait<Object?>([
      _client
          .from('store_members')
          .select('store_id')
          .eq('store_id', storeId)
          .eq('user_id', _user.id)
          .eq('status', 'active')
          .maybeSingle(),
      _client
          .from('subscriptions')
          .select('*, plans(*)')
          .eq('store_id', storeId)
          .single(),
      _client.rpc(
        'current_warranty_usage',
        params: {'target_store_id': storeId},
      ),
    ]);
    if (results[0] == null) throw StateError('WORKSPACE_NOT_FOUND');
    final subscriptionJson = Map<String, dynamic>.from(results[1] as Map);
    final usage = (results[2] as num?)?.toInt() ?? 0;
    return _subscriptionFromJson(subscriptionJson, usage);
  }

  @override
  Future<WorkspaceSnapshot> createStore({
    required String name,
    required String phone,
    required String city,
    required String countryCode,
  }) async {
    final trialDeviceClaims = _trialDeviceClaims;
    if (trialDeviceClaims == null) {
      throw StateError('TRIAL_DEVICE_SECURITY_UNAVAILABLE');
    }
    final value = await _client.rpc(
      'create_store_with_subscription',
      params: {
        'store_name': name.trim(),
        'store_phone': phone.trim(),
        'store_city': city.trim(),
        'store_country_code': countryCode,
        'device_claim': await trialDeviceClaims.loadOrCreateClaim(),
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
    final error = membershipJson['error'];
    if (error is String && error.isNotEmpty) {
      throw StateError(error);
    }
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
    required String logoUrl,
    required String brandColor,
    required String customerPortalTitle,
    required String warrantyPolicy,
    required String warrantyExclusions,
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
          'logo_url': logoUrl.trim(),
          'brand_color': brandColor,
          'customer_portal_title': customerPortalTitle.trim(),
          'warranty_policy': warrantyPolicy.trim(),
          'warranty_exclusions': warrantyExclusions.trim(),
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
    required String warrantyPolicy,
    required String warrantyExclusions,
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
          'warranty_policy': warrantyPolicy.trim(),
          'warranty_exclusions': warrantyExclusions.trim(),
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
    required String warrantyPolicy,
    required String warrantyExclusions,
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
          'warranty_policy': warrantyPolicy.trim(),
          'warranty_exclusions': warrantyExclusions.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', productId)
        .eq('store_id', storeId)
        .select()
        .single();
    return Product.fromJson(row);
  }

  @override
  Future<AiProductImportResult> analyzeProductDocument({
    required String storeId,
    required ProductDocumentInput document,
  }) async {
    final response = await _client.functions.invoke(
      'import-products-ai',
      body: {'storeId': storeId},
      files: [
        http.MultipartFile.fromBytes(
          'file',
          document.bytes,
          filename: document.filename,
          contentType: MediaType.parse(document.mimeType),
        ),
      ],
    );
    if (response.status != 200 || response.data is! Map) {
      final data = response.data;
      final code = data is Map ? data['error'] : null;
      throw StateError(code is String ? code : 'AI_IMPORT_FAILED');
    }
    return AiProductImportResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
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
  Future<List<Warranty>> loadWarranties(
    String storeId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final safeLimit = limit.clamp(1, 100).toInt();
    final safeOffset = offset < 0 ? 0 : offset;
    final rows = await _client
        .from('warranties')
        .select()
        .eq('store_id', storeId)
        .filter('voided_at', 'is', null)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(safeOffset, safeOffset + safeLimit - 1);
    return rows.map(Warranty.fromJson).toList();
  }

  @override
  Future<List<Warranty>> loadWarrantiesForInvoice(
    String storeId,
    String invoiceNumber,
  ) async {
    final normalizedInvoice = invoiceNumber.trim();
    if (normalizedInvoice.isEmpty) return const [];
    final rows = await _client
        .from('warranties')
        .select()
        .eq('store_id', storeId)
        .eq('invoice_number', normalizedInvoice)
        .filter('voided_at', 'is', null)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(500);
    return rows.map(Warranty.fromJson).toList();
  }

  @override
  Future<Warranty?> findWarrantyBySerial(
    String storeId,
    String serialNumber,
  ) async {
    try {
      final value = await _client.rpc(
        'find_warranty_by_serial',
        params: {
          'target_store_id': storeId,
          'target_serial': serialNumber.trim(),
        },
      );
      if (value == null) return null;
      return Warranty.fromJson(Map<String, dynamic>.from(value as Map));
    } on PostgrestException catch (error) {
      final missingRpc =
          error.code == 'PGRST202' ||
          error.message.contains('find_warranty_by_serial');
      if (!missingRpc) rethrow;
      final row = await _client
          .from('warranties')
          .select()
          .eq('store_id', storeId)
          .eq('serial_number', serialNumber.trim())
          .isFilter('voided_at', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : Warranty.fromJson(row);
    }
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
  Future<Uri?> createWarrantyShareLink(String warrantyId) async {
    final response = await _client.functions.invoke(
      'warranty-card',
      body: {'warrantyId': warrantyId},
    );
    if (response.status != 200 || response.data is! Map) {
      throw StateError('WARRANTY_SHARE_LINK_UNAVAILABLE');
    }
    final value = Map<String, dynamic>.from(response.data as Map)['url'];
    if (value is! String) {
      throw StateError('WARRANTY_SHARE_LINK_UNAVAILABLE');
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isScheme('https')) {
      throw StateError('WARRANTY_SHARE_LINK_INVALID');
    }
    return uri;
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
    ClaimCategory category = ClaimCategory.other,
    ClaimPriority priority = ClaimPriority.normal,
  }) async {
    final value = await _client.rpc(
      'create_maintenance_request',
      params: {
        'target_store_id': storeId,
        'target_warranty_id': warrantyId,
        'claim_issue': issue.trim(),
        'claim_category': category.databaseValue,
        'claim_priority': priority.name,
      },
    );
    return MaintenanceRequest.fromJson(Map<String, dynamic>.from(value as Map));
  }

  @override
  Future<MaintenanceRequest> updateRequest(MaintenanceRequest request) async {
    final value = await _client.rpc(
      'update_maintenance_request',
      params: {
        'target_request_id': request.id,
        'expected_version': request.version,
        'patch': {
          'status': request.status.databaseValue,
          'category': request.category.databaseValue,
          'priority': request.priority.name,
          'resolution': request.resolution.databaseValue,
          'customer_notes': request.customerNotes.trim(),
          'internal_notes': request.internalNotes.trim(),
          'diagnosis': request.diagnosis.trim(),
          'resolution_notes': request.resolutionNotes.trim(),
          'decision_reason': request.decisionReason.trim(),
          'assigned_to': request.assignedTo,
          'service_branch_id': request.serviceBranchId,
          'sla_due_at': request.slaDueAt?.toIso8601String(),
        },
      },
    );
    return MaintenanceRequest.fromJson(Map<String, dynamic>.from(value as Map));
  }

  @override
  Future<List<ClaimAttachment>> loadRequestAttachments(String requestId) async {
    final rows = await _client
        .from('maintenance_request_attachments')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: false);
    return rows.map(ClaimAttachment.fromJson).toList();
  }

  @override
  Future<Uri> createRequestAttachmentLink(String storagePath) async {
    final value = await _client.storage
        .from('claim-attachments')
        .createSignedUrl(storagePath, 600);
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isScheme('https')) {
      throw StateError('CLAIM_ATTACHMENT_LINK_INVALID');
    }
    return uri;
  }

  @override
  Future<ClaimAiReview> analyzeClaim({
    required String storeId,
    required String requestId,
    required bool includeAttachments,
  }) async {
    final response = await _client.functions.invoke(
      'analyze-claim-ai',
      body: {
        'storeId': storeId,
        'requestId': requestId,
        'includeAttachments': includeAttachments,
      },
    );
    if (response.status != 200 || response.data is! Map) {
      final code = response.data is Map
          ? (response.data as Map)['error']?.toString()
          : null;
      throw StateError(code ?? 'CLAIM_AI_FAILED');
    }
    return ClaimAiReview.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<List<AppNotification>> loadNotifications(String storeId) async {
    await _client.rpc(
      'enqueue_overdue_claim_notifications',
      params: {'target_store_id': storeId},
    );
    final rows = await _client
        .from('notifications')
        .select()
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(AppNotification.fromJson).toList();
  }

  @override
  Future<NotificationPreferences> loadNotificationPreferences(
    String storeId,
  ) async {
    final row = await _client
        .from('notification_preferences')
        .select()
        .eq('store_id', storeId)
        .eq('user_id', _user.id)
        .maybeSingle();
    return row == null
        ? const NotificationPreferences()
        : NotificationPreferences.fromJson(row);
  }

  @override
  Future<NotificationPreferences> saveNotificationPreferences({
    required String storeId,
    required NotificationPreferences preferences,
  }) async {
    final row = await _client
        .from('notification_preferences')
        .upsert({
          'store_id': storeId,
          'user_id': _user.id,
          'claim_created': preferences.claimCreated,
          'claim_assigned': preferences.claimAssigned,
          'claim_overdue': preferences.claimOverdue,
          'ready_for_pickup': preferences.readyForPickup,
          'marketing': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return NotificationPreferences.fromJson(row);
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  @override
  Future<List<ApiKeyInfo>> loadApiKeys(String storeId) async {
    final value = await _client.rpc(
      'list_store_api_keys',
      params: {'target_store_id': storeId},
    );
    return (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => ApiKeyInfo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<CreatedApiKey> createApiKey({
    required String storeId,
    required String name,
    required List<String> scopes,
  }) async {
    final value = await _client.rpc(
      'create_store_api_key',
      params: {
        'target_store_id': storeId,
        'key_name': name.trim(),
        'requested_scopes': scopes,
      },
    );
    return CreatedApiKey.fromJson(Map<String, dynamic>.from(value as Map));
  }

  @override
  Future<void> revokeApiKey(String keyId) async {
    await _client.rpc('revoke_store_api_key', params: {'target_key_id': keyId});
  }

  @override
  Future<List<WebhookInfo>> loadWebhooks(String storeId) async {
    final value = await _client.rpc(
      'list_store_webhooks',
      params: {'target_store_id': storeId},
    );
    return (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => WebhookInfo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<CreatedWebhook> createWebhook({
    required String storeId,
    required String endpointUrl,
    required List<String> events,
  }) async {
    final value = await _client.rpc(
      'create_store_webhook',
      params: {
        'target_store_id': storeId,
        'target_url': endpointUrl.trim(),
        'target_events': events,
      },
    );
    return CreatedWebhook.fromJson(Map<String, dynamic>.from(value as Map));
  }

  @override
  Future<void> setWebhookActive(String webhookId, bool active) async {
    await _client.rpc(
      'set_store_webhook_active',
      params: {'target_webhook_id': webhookId, 'target_active': active},
    );
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
    await _invokeStoreVerification({
      'storeId': storeId,
      'platform': receipt.platform.value,
      'productId': receipt.productId,
      'basePlanId': receipt.basePlanId,
      'purchaseId': receipt.purchaseId,
      'transactionDate': receipt.transactionDate,
      'verificationData': receipt.verificationData,
      'verificationSource': receipt.verificationSource,
      if (receipt.platform == StoreBillingPlatform.googlePlay)
        'acknowledgeOnServer': true,
    });
    return _loadSubscriptionForStore(storeId);
  }

  @override
  Future<SubscriptionInfo> refreshStoreSubscription(String storeId) async {
    await _invokeStoreVerification({'storeId': storeId, 'refresh': true});
    return _loadSubscriptionForStore(storeId);
  }

  Future<void> _invokeStoreVerification(Map<String, Object?> body) async {
    try {
      final response = await _client.functions.invoke(
        'verify-store-purchase',
        body: body,
      );
      if (response.status < 200 || response.status >= 300) {
        throw storeVerificationExceptionFromPayload(
          statusCode: response.status,
          details: response.data,
        );
      }
    } on FunctionsHttpException catch (error) {
      throw storeVerificationExceptionFromPayload(
        statusCode: error.status,
        details: error.details,
      );
    } on FunctionException catch (error) {
      throw StoreVerificationException(
        code: _fallbackStoreVerificationError,
        statusCode: error.status,
        isRetryable: true,
      );
    }
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
