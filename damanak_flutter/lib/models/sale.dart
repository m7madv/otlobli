import 'warranty.dart';

enum SaleStatus { completed, partiallyReturned, returned, voided }

extension SaleStatusText on SaleStatus {
  String get label => switch (this) {
    SaleStatus.completed => 'مكتملة',
    SaleStatus.partiallyReturned => 'مرتجع جزئي',
    SaleStatus.returned => 'مرتجعة',
    SaleStatus.voided => 'ملغاة',
  };

  String get databaseValue => switch (this) {
    SaleStatus.completed => 'completed',
    SaleStatus.partiallyReturned => 'partially_returned',
    SaleStatus.returned => 'returned',
    SaleStatus.voided => 'voided',
  };

  static SaleStatus fromValue(String? value) => switch (value) {
    'partially_returned' => SaleStatus.partiallyReturned,
    'returned' => SaleStatus.returned,
    'voided' => SaleStatus.voided,
    _ => SaleStatus.completed,
  };
}

class SaleLine {
  const SaleLine({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.barcode,
    required this.quantity,
    required this.returnedQuantity,
    required this.unitPrice,
    required this.unitCost,
    required this.discountAmount,
    required this.taxAmount,
    required this.lineTotal,
    required this.warrantyMonths,
    this.serialNumbers = const [],
  });

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final String barcode;
  final num quantity;
  final num returnedQuantity;
  final num unitPrice;
  final num unitCost;
  final num discountAmount;
  final num taxAmount;
  final num lineTotal;
  final int warrantyMonths;
  final List<String> serialNumbers;

  num get returnableQuantity => quantity - returnedQuantity;

  factory SaleLine.fromJson(Map<String, dynamic> json) => SaleLine(
    id: json['id'] as String? ?? '',
    productId: json['product_id'] as String,
    productName: json['product_name'] as String,
    sku: json['sku'] as String? ?? '',
    barcode: json['barcode'] as String? ?? '',
    quantity: json['quantity'] as num? ?? 1,
    returnedQuantity: json['returned_quantity'] as num? ?? 0,
    unitPrice: json['unit_price'] as num? ?? 0,
    unitCost: json['unit_cost'] as num? ?? 0,
    discountAmount: json['discount_amount'] as num? ?? 0,
    taxAmount: json['tax_amount'] as num? ?? 0,
    lineTotal: json['line_total'] as num? ?? 0,
    warrantyMonths: json['warranty_months'] as int? ?? 0,
    serialNumbers: List<String>.from(
      json['serial_numbers'] as List? ?? const <String>[],
    ),
  );
}

class SalePayment {
  const SalePayment({
    required this.id,
    required this.method,
    required this.amount,
    required this.reference,
  });

  final String id;
  final PaymentMethod method;
  final num amount;
  final String reference;

  factory SalePayment.fromJson(Map<String, dynamic> json) => SalePayment(
    id: json['id'] as String? ?? '',
    method: PaymentMethodText.fromValue(json['payment_method'] as String?),
    amount: json['amount'] as num? ?? 0,
    reference: json['reference'] as String? ?? '',
  );
}

class SaleTransaction {
  const SaleTransaction({
    required this.id,
    required this.storeId,
    required this.branchId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.invoiceNumber,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.refundedAmount,
    required this.currencyCode,
    required this.taxRate,
    required this.pricesIncludeTax,
    required this.notes,
    required this.cashierId,
    required this.createdAt,
    this.lines = const [],
    this.payments = const [],
  });

  final String id;
  final String storeId;
  final String branchId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String invoiceNumber;
  final SaleStatus status;
  final num subtotal;
  final num discountAmount;
  final num taxAmount;
  final num total;
  final num refundedAmount;
  final String currencyCode;
  final num taxRate;
  final bool pricesIncludeTax;
  final String notes;
  final String cashierId;
  final DateTime createdAt;
  final List<SaleLine> lines;
  final List<SalePayment> payments;

  num get netTotal => total - refundedAmount;

  factory SaleTransaction.fromJson(Map<String, dynamic> json) =>
      SaleTransaction(
        id: json['id'] as String,
        storeId: json['store_id'] as String,
        branchId: json['branch_id'] as String? ?? '',
        customerId: json['customer_id'] as String? ?? '',
        customerName: json['customer_name'] as String? ?? 'عميل نقدي',
        customerPhone: json['customer_phone'] as String? ?? '',
        invoiceNumber: json['invoice_number'] as String,
        status: SaleStatusText.fromValue(json['status'] as String?),
        subtotal: json['subtotal'] as num? ?? 0,
        discountAmount: json['discount_amount'] as num? ?? 0,
        taxAmount: json['tax_amount'] as num? ?? 0,
        total: json['total'] as num? ?? 0,
        refundedAmount: json['refunded_amount'] as num? ?? 0,
        currencyCode: json['currency_code'] as String? ?? 'SAR',
        taxRate: json['tax_rate'] as num? ?? 0,
        pricesIncludeTax: json['prices_include_tax'] as bool? ?? true,
        notes: json['notes'] as String? ?? '',
        cashierId: json['cashier_id'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        lines: (json['sale_lines'] as List? ?? const [])
            .map((item) => SaleLine.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        payments: (json['sale_payments'] as List? ?? const [])
            .map(
              (item) => SalePayment.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
      );
}

class SaleLineInput {
  const SaleLineInput({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    this.serialNumbers = const [],
  });

  final String productId;
  final num quantity;
  final num unitPrice;
  final num discountAmount;
  final List<String> serialNumbers;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
    'unit_price': unitPrice,
    'discount_amount': discountAmount,
    'serial_numbers': serialNumbers,
  };
}
