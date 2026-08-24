enum PurchaseOrderStatus {
  draft,
  ordered,
  partiallyReceived,
  received,
  cancelled,
}

extension PurchaseOrderStatusText on PurchaseOrderStatus {
  String get label => switch (this) {
    PurchaseOrderStatus.draft => 'مسودة',
    PurchaseOrderStatus.ordered => 'مرسل للمورد',
    PurchaseOrderStatus.partiallyReceived => 'مستلم جزئياً',
    PurchaseOrderStatus.received => 'مستلم',
    PurchaseOrderStatus.cancelled => 'ملغي',
  };

  static PurchaseOrderStatus fromValue(String? value) => switch (value) {
    'ordered' => PurchaseOrderStatus.ordered,
    'partially_received' => PurchaseOrderStatus.partiallyReceived,
    'received' => PurchaseOrderStatus.received,
    'cancelled' => PurchaseOrderStatus.cancelled,
    _ => PurchaseOrderStatus.draft,
  };
}

class Supplier {
  const Supplier({
    required this.id,
    required this.storeId,
    required this.name,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.taxNumber,
    required this.address,
    required this.notes,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String storeId;
  final String name;
  final String contactName;
  final String phone;
  final String email;
  final String taxNumber;
  final String address;
  final String notes;
  final bool isActive;
  final DateTime createdAt;

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id'] as String,
    storeId: json['store_id'] as String,
    name: json['name'] as String,
    contactName: json['contact_name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    taxNumber: json['tax_number'] as String? ?? '',
    address: json['address'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.receivedQuantity,
    required this.unitCost,
  });

  final String id;
  final String productId;
  final String productName;
  final num quantity;
  final num receivedQuantity;
  final num unitCost;

  factory PurchaseOrderLine.fromJson(Map<String, dynamic> json) =>
      PurchaseOrderLine(
        id: json['id'] as String? ?? '',
        productId: json['product_id'] as String,
        productName: json['product_name'] as String? ?? '',
        quantity: json['quantity'] as num? ?? 0,
        receivedQuantity: json['received_quantity'] as num? ?? 0,
        unitCost: json['unit_cost'] as num? ?? 0,
      );
}

class PurchaseOrderLineInput {
  const PurchaseOrderLineInput({
    required this.productId,
    required this.quantity,
    required this.unitCost,
  });

  final String productId;
  final num quantity;
  final num unitCost;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
    'unit_cost': unitCost,
  };
}

class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.storeId,
    required this.branchId,
    required this.supplierId,
    required this.orderNumber,
    required this.status,
    required this.expectedAt,
    required this.notes,
    required this.totalCost,
    required this.createdAt,
    this.lines = const [],
  });

  final String id;
  final String storeId;
  final String branchId;
  final String supplierId;
  final String orderNumber;
  final PurchaseOrderStatus status;
  final DateTime? expectedAt;
  final String notes;
  final num totalCost;
  final DateTime createdAt;
  final List<PurchaseOrderLine> lines;

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => PurchaseOrder(
    id: json['id'] as String,
    storeId: json['store_id'] as String,
    branchId: json['branch_id'] as String,
    supplierId: json['supplier_id'] as String,
    orderNumber: json['order_number'] as String,
    status: PurchaseOrderStatusText.fromValue(json['status'] as String?),
    expectedAt: json['expected_at'] == null
        ? null
        : DateTime.parse(json['expected_at'] as String),
    notes: json['notes'] as String? ?? '',
    totalCost: json['total_cost'] as num? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
    lines: (json['purchase_order_lines'] as List? ?? const [])
        .map(
          (item) => PurchaseOrderLine.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
  );
}
