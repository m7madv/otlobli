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
    required this.customerName,
    required this.customerPhone,
    required this.productName,
    required this.serialNumber,
    required this.purchaseDate,
    required this.expiryDate,
    required this.createdAt,
    required this.notes,
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final String productName;
  final String serialNumber;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final DateTime createdAt;
  final String notes;

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
        serialNumber.toLowerCase().contains(value) ||
        id.toLowerCase().contains(value);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'productName': productName,
    'serialNumber': serialNumber,
    'purchaseDate': purchaseDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
  };

  factory Warranty.fromJson(Map<String, dynamic> json) {
    return Warranty(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      productName: json['productName'] as String,
      serialNumber: json['serialNumber'] as String? ?? '',
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }
}
