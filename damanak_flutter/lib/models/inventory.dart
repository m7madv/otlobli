import 'package:damanak/l10n/l10n.dart';

enum StockMovementType {
  opening,
  purchase,
  sale,
  returnIn,
  transferOut,
  transferIn,
  adjustment,
}

extension StockMovementTypeText on StockMovementType {
  String get label => switch (this) {
    StockMovementType.opening => L10n.current.msg998a0190311c,
    StockMovementType.purchase => L10n.current.msgf081df1ea3f0,
    StockMovementType.sale => L10n.current.msg3f938fa02d78,
    StockMovementType.returnIn => L10n.current.msg2070711a2cdb,
    StockMovementType.transferOut => L10n.current.msgbd783117c924,
    StockMovementType.transferIn => L10n.current.msgb1e632423040,
    StockMovementType.adjustment => L10n.current.msg84a79451a197,
  };

  String get databaseValue => switch (this) {
    StockMovementType.opening => 'opening',
    StockMovementType.purchase => 'purchase',
    StockMovementType.sale => 'sale',
    StockMovementType.returnIn => 'return_in',
    StockMovementType.transferOut => 'transfer_out',
    StockMovementType.transferIn => 'transfer_in',
    StockMovementType.adjustment => 'adjustment',
  };

  static StockMovementType fromValue(String? value) => switch (value) {
    'purchase' => StockMovementType.purchase,
    'sale' => StockMovementType.sale,
    'return_in' => StockMovementType.returnIn,
    'transfer_out' => StockMovementType.transferOut,
    'transfer_in' => StockMovementType.transferIn,
    'adjustment' => StockMovementType.adjustment,
    _ => StockMovementType.opening,
  };
}

class InventoryLevel {
  const InventoryLevel({
    required this.id,
    required this.storeId,
    required this.branchId,
    required this.productId,
    required this.onHand,
    required this.reserved,
    required this.reorderPoint,
    required this.averageCost,
    required this.updatedAt,
  });

  final String id;
  final String storeId;
  final String branchId;
  final String productId;
  final num onHand;
  final num reserved;
  final num reorderPoint;
  final num averageCost;
  final DateTime updatedAt;

  num get available => onHand - reserved;
  bool get isLow => available <= reorderPoint;

  InventoryLevel copyWith({
    num? onHand,
    num? reserved,
    num? reorderPoint,
    num? averageCost,
    DateTime? updatedAt,
  }) => InventoryLevel(
    id: id,
    storeId: storeId,
    branchId: branchId,
    productId: productId,
    onHand: onHand ?? this.onHand,
    reserved: reserved ?? this.reserved,
    reorderPoint: reorderPoint ?? this.reorderPoint,
    averageCost: averageCost ?? this.averageCost,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory InventoryLevel.fromJson(Map<String, dynamic> json) => InventoryLevel(
    id: json['id'] as String,
    storeId: json['store_id'] as String,
    branchId: json['branch_id'] as String,
    productId: json['product_id'] as String,
    onHand: json['on_hand'] as num? ?? 0,
    reserved: json['reserved'] as num? ?? 0,
    reorderPoint: json['reorder_point'] as num? ?? 0,
    averageCost: json['average_cost'] as num? ?? 0,
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.branchId,
    required this.type,
    required this.quantity,
    required this.unitCost,
    required this.referenceType,
    required this.referenceId,
    required this.note,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String storeId;
  final String productId;
  final String branchId;
  final StockMovementType type;
  final num quantity;
  final num unitCost;
  final String referenceType;
  final String referenceId;
  final String note;
  final String createdBy;
  final DateTime createdAt;

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
    id: json['id'] as String,
    storeId: json['store_id'] as String,
    productId: json['product_id'] as String,
    branchId: json['branch_id'] as String,
    type: StockMovementTypeText.fromValue(json['movement_type'] as String?),
    quantity: json['quantity'] as num? ?? 0,
    unitCost: json['unit_cost'] as num? ?? 0,
    referenceType: json['reference_type'] as String? ?? '',
    referenceId: json['reference_id'] as String? ?? '',
    note: json['note'] as String? ?? '',
    createdBy: json['created_by'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
