import '../core/date_utils.dart';

enum PaymentMethod { cash, card, bankTransfer, digitalWallet, other }

extension PaymentMethodText on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => 'نقداً',
    PaymentMethod.card => 'بطاقة',
    PaymentMethod.bankTransfer => 'تحويل بنكي',
    PaymentMethod.digitalWallet => 'محفظة رقمية',
    PaymentMethod.other => 'أخرى',
  };

  static PaymentMethod fromValue(String? value) => switch (value) {
    'card' => PaymentMethod.card,
    'bank_transfer' || 'bankTransfer' => PaymentMethod.bankTransfer,
    'digital_wallet' || 'digitalWallet' => PaymentMethod.digitalWallet,
    'other' => PaymentMethod.other,
    _ => PaymentMethod.cash,
  };

  String get databaseValue => switch (this) {
    PaymentMethod.bankTransfer => 'bank_transfer',
    PaymentMethod.digitalWallet => 'digital_wallet',
    _ => name,
  };
}

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
    this.customerId,
    this.branchId,
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
    this.invoiceNumber = '',
    this.saleSubtotal = 0,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.saleTotal = 0,
    this.taxRate = 0,
    this.currencyCode = 'SAR',
    this.paymentMethod = PaymentMethod.cash,
  });

  final String id;
  final String warrantyNumber;
  final String storeId;
  final String? productId;
  final String? customerId;
  final String? branchId;
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
  final String invoiceNumber;
  final num saleSubtotal;
  final num discountAmount;
  final num taxAmount;
  final num saleTotal;
  final num taxRate;
  final String currencyCode;
  final PaymentMethod paymentMethod;

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
    'customerId': customerId,
    'branchId': branchId,
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
    'invoiceNumber': invoiceNumber,
    'saleSubtotal': saleSubtotal,
    'discountAmount': discountAmount,
    'taxAmount': taxAmount,
    'saleTotal': saleTotal,
    'taxRate': taxRate,
    'currencyCode': currencyCode,
    'paymentMethod': paymentMethod.databaseValue,
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
      customerId:
          json['customer_id'] as String? ?? json['customerId'] as String?,
      branchId: json['branch_id'] as String? ?? json['branchId'] as String?,
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
      invoiceNumber:
          json['invoice_number'] as String? ??
          json['invoiceNumber'] as String? ??
          '',
      saleSubtotal:
          json['sale_subtotal'] as num? ?? json['saleSubtotal'] as num? ?? 0,
      discountAmount:
          json['discount_amount'] as num? ??
          json['discountAmount'] as num? ??
          0,
      taxAmount: json['tax_amount'] as num? ?? json['taxAmount'] as num? ?? 0,
      saleTotal: json['sale_total'] as num? ?? json['saleTotal'] as num? ?? 0,
      taxRate: json['tax_rate'] as num? ?? json['taxRate'] as num? ?? 0,
      currencyCode:
          json['currency_code'] as String? ??
          json['currencyCode'] as String? ??
          'SAR',
      paymentMethod: PaymentMethodText.fromValue(
        json['payment_method'] as String? ?? json['paymentMethod'] as String?,
      ),
    );
  }
}
