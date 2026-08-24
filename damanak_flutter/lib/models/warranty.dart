import '../core/date_utils.dart';

enum WarrantyStatus { active, expiringSoon, expired }

extension WarrantyStatusText on WarrantyStatus {
  String get label => switch (this) {
    WarrantyStatus.active => 'ساري',
    WarrantyStatus.expiringSoon => 'قارب على الانتهاء',
    WarrantyStatus.expired => 'منتهي',
  };
}

class Warranty {
  const Warranty({
    required this.id,
    this.warrantyNumber = '',
    this.storeId = '',
    this.productId,
    required this.customerName,
    required this.customerPhone,
    required this.productName,
    this.barcode = '',
    required this.serialNumber,
    required this.purchaseDate,
    required this.expiryDate,
    required this.createdAt,
    required this.notes,
    this.createdBy = '',
  });

  final String id;
  final String warrantyNumber;
  final String storeId;
  final String? productId;
  final String customerName;
  final String customerPhone;
  final String productName;
  final String barcode;
  final String serialNumber;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final DateTime createdAt;
  final String notes;
  final String createdBy;

  String get displayNumber => warrantyNumber.isEmpty ? id : warrantyNumber;

  WarrantyStatus statusAt([DateTime? now]) {
    final days = dateOnly(
      expiryDate,
    ).difference(dateOnly(now ?? DateTime.now())).inDays;
    if (days < 0) return WarrantyStatus.expired;
    if (days <= 30) return WarrantyStatus.expiringSoon;
    return WarrantyStatus.active;
  }

  bool matches(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return true;
    return customerName.toLowerCase().contains(value) ||
        customerPhone.toLowerCase().contains(value) ||
        productName.toLowerCase().contains(value) ||
        barcode.toLowerCase().contains(value) ||
        serialNumber.toLowerCase().contains(value) ||
        id.toLowerCase().contains(value) ||
        warrantyNumber.toLowerCase().contains(value);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'warrantyNumber': warrantyNumber,
    'storeId': storeId,
    'productId': productId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'productName': productName,
    'barcode': barcode,
    'serialNumber': serialNumber,
    'purchaseDate': purchaseDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
    'createdBy': createdBy,
  };

  factory Warranty.fromJson(Map<String, dynamic> json) {
    return Warranty(
      id: json['id'] as String,
      warrantyNumber:
          json['warranty_number'] as String? ??
          json['warrantyNumber'] as String? ??
          '',
      storeId: json['store_id'] as String? ?? json['storeId'] as String? ?? '',
      productId: json['product_id'] as String? ?? json['productId'] as String?,
      customerName:
          json['customer_name'] as String? ??
          json['customerName'] as String? ??
          '',
      customerPhone:
          json['customer_phone'] as String? ??
          json['customerPhone'] as String? ??
          '',
      productName:
          json['product_name'] as String? ??
          json['productName'] as String? ??
          '',
      barcode: json['barcode'] as String? ?? '',
      serialNumber:
          json['serial_number'] as String? ??
          json['serialNumber'] as String? ??
          '',
      purchaseDate: DateTime.parse(
        json['purchase_date'] as String? ?? json['purchaseDate'] as String,
      ),
      expiryDate: DateTime.parse(
        json['expiry_date'] as String? ?? json['expiryDate'] as String,
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
      notes: json['notes'] as String? ?? '',
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String? ?? '',
    );
  }
}
