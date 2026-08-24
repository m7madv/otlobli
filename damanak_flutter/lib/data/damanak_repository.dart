import '../models/account.dart';
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

  Future<WorkspaceSnapshot?> loadWorkspace();
  Future<WorkspaceSnapshot> createStore({
    required String name,
    required String phone,
    required String city,
    required String countryCode,
  });
  Future<WorkspaceSnapshot> joinStore(String invitationCode);
  Future<StoreWorkspace> updateStore({
    required String storeId,
    required String name,
    required String phone,
    required String city,
    required String countryCode,
  });

  Future<List<Product>> loadProducts(String storeId);
  Future<Product> createProduct({
    required String storeId,
    required String name,
    required String brand,
    required String barcode,
    required String sku,
    required int warrantyMonths,
    required num? salePrice,
  });

  Future<List<Warranty>> loadWarranties(String storeId);
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
