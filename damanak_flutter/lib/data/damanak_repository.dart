import '../models/account.dart';
import '../models/audit_event.dart';
import '../models/branch.dart';
import '../models/customer.dart';
import '../models/maintenance_request.dart';
import '../models/product.dart';
import '../models/subscription.dart';
import '../models/warranty.dart';

class SignUpResult {
  const SignUpResult({required this.account, required this.needsConfirmation});

  final AccountIdentity account;
  final bool needsConfirmation;
}

class WorkspaceSnapshot {
  const WorkspaceSnapshot({
    required this.store,
    required this.membership,
    required this.subscription,
  });

  final StoreWorkspace store;
  final StoreMembership membership;
  final SubscriptionInfo subscription;
}

abstract interface class DamanakRepository {
  bool get isDemo;

  Future<AccountIdentity?> restoreAccount();
  Future<AccountIdentity> signIn({
    required String email,
    required String password,
  });
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);

  Future<WorkspaceSnapshot?> loadWorkspace();
  Future<WorkspaceSnapshot> createStore({
    required String name,
    required String phone,
    required String city,
    required String countryCode,
  });

  Future<List<StoreBranch>> loadBranches(String storeId);
  Future<StoreBranch> saveBranch({
    required String storeId,
    String? branchId,
    required String name,
    required String code,
    required String city,
    required String address,
    required String phone,
    required bool isMain,
  });

  Future<List<CustomerProfile>> loadCustomers(String storeId);
  Future<CustomerProfile> saveCustomer({
    required String storeId,
    String? customerId,
    required String name,
    required String phone,
    required String email,
    required String notes,
  });
  Future<WorkspaceSnapshot> joinStore(String invitationCode);
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
  });

  Future<List<Product>> loadProducts(String storeId);
  Future<Product> createProduct({
    required String storeId,
    required String name,
    required String brand,
    required String category,
    required String barcode,
    required String sku,
    required int warrantyMonths,
    required num? salePrice,
  });
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
    required bool isActive,
  });

  Future<List<Warranty>> loadWarranties(String storeId);
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
  });
  Future<void> deleteWarranty(String id);

  Future<List<MaintenanceRequest>> loadRequests(String storeId);
  Future<MaintenanceRequest> createRequest({
    required String storeId,
    required String warrantyId,
    required String issue,
  });
  Future<void> updateRequestStatus(String requestId, MaintenanceStatus status);

  Future<List<TeamMember>> loadTeam(String storeId);
  Future<StoreInvite> createInvite({
    required String storeId,
    required MemberRole role,
    required int maxUses,
  });
  Future<void> updateMember({
    required String storeId,
    required String userId,
    required MemberRole role,
    required bool active,
  });

  Future<List<AuditEvent>> loadAuditLogs(String storeId);

  Future<List<PlanInfo>> loadPlans();
  Future<void> requestSubscription({
    required String storeId,
    required String planId,
    required String billingCycle,
    required String contactPhone,
  });
  Future<SubscriptionInfo> redeemSubscriptionCode({
    required String storeId,
    required String code,
  });
}
