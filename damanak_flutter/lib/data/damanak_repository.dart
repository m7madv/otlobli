import '../models/account.dart';
import '../models/audit_event.dart';
import '../models/branch.dart';
import '../models/customer.dart';
import '../models/maintenance_request.dart';
import '../models/inventory.dart';
import '../models/product.dart';
import '../models/register.dart';
import '../models/sale.dart';
import '../models/subscription.dart';
import '../models/store_billing.dart';
import '../models/supplier.dart';
import '../models/warranty.dart';

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
  Future<void> signOut();
  Future<void> signInWithSocial(SocialAuthProvider provider);
  Future<void> deleteAccount();

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
    required String email,
    required String managerName,
    required String receiptPrefix,
    required String timezone,
    required String opensAt,
    required String closesAt,
    required BranchType type,
    required bool acceptsSales,
    required bool handlesService,
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
    required num? costPrice,
    required bool trackInventory,
    required bool isSerialized,
    required num reorderPoint,
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
    required num? costPrice,
    required bool trackInventory,
    required bool isSerialized,
    required num reorderPoint,
    required bool isActive,
  });

  Future<List<InventoryLevel>> loadInventory(String storeId);
  Future<List<StockMovement>> loadStockMovements(String storeId);
  Future<InventoryLevel> adjustInventory({
    required String storeId,
    required String branchId,
    required String productId,
    required num newQuantity,
    required num unitCost,
    required String note,
  });
  Future<void> transferInventory({
    required String storeId,
    required String productId,
    required String fromBranchId,
    required String toBranchId,
    required num quantity,
    required String note,
  });

  Future<List<SaleTransaction>> loadSales(String storeId);
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
  });
  Future<SaleTransaction> returnSale({
    required String storeId,
    required String saleId,
    required Map<String, num> lineQuantities,
    required PaymentMethod refundMethod,
    required String reason,
  });

  Future<List<CashRegisterSession>> loadRegisterSessions(String storeId);
  Future<CashRegisterSession> openRegister({
    required String storeId,
    required String branchId,
    required num openingCash,
    required String notes,
  });
  Future<CashRegisterSession> closeRegister({
    required String sessionId,
    required num closingCash,
    required String notes,
  });

  Future<List<Supplier>> loadSuppliers(String storeId);
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
  });
  Future<List<PurchaseOrder>> loadPurchaseOrders(String storeId);
  Future<PurchaseOrder> createPurchaseOrder({
    required String storeId,
    required String branchId,
    required String supplierId,
    required DateTime? expectedAt,
    required String notes,
    required List<PurchaseOrderLineInput> lines,
  });
  Future<PurchaseOrder> receivePurchaseOrder(String purchaseOrderId);

  Future<List<Warranty>> loadWarranties(
    String storeId, {
    int limit = 100,
    int offset = 0,
  });
  Future<List<Warranty>> loadWarrantiesForInvoice(
    String storeId,
    String invoiceNumber,
  );
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
  Future<Uri?> createWarrantyShareLink(String warrantyId);

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
  Future<SubscriptionInfo> verifyStorePurchase({
    required String storeId,
    required StorePurchaseReceipt receipt,
  });
  Future<SubscriptionInfo> refreshStoreSubscription(String storeId);
}
