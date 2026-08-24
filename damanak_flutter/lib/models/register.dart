enum RegisterStatus { open, closed }

class CashRegisterSession {
  const CashRegisterSession({
    required this.id,
    required this.storeId,
    required this.branchId,
    required this.openedBy,
    required this.closedBy,
    required this.openingCash,
    required this.cashSales,
    required this.cashRefunds,
    required this.cashIn,
    required this.cashOut,
    required this.closingCash,
    required this.status,
    required this.openedAt,
    required this.closedAt,
    required this.notes,
  });

  final String id;
  final String storeId;
  final String branchId;
  final String openedBy;
  final String closedBy;
  final num openingCash;
  final num cashSales;
  final num cashRefunds;
  final num cashIn;
  final num cashOut;
  final num closingCash;
  final RegisterStatus status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String notes;

  num get expectedCash =>
      openingCash + cashSales + cashIn - cashRefunds - cashOut;
  num get variance =>
      status == RegisterStatus.closed ? closingCash - expectedCash : 0;

  factory CashRegisterSession.fromJson(Map<String, dynamic> json) =>
      CashRegisterSession(
        id: json['id'] as String,
        storeId: json['store_id'] as String,
        branchId: json['branch_id'] as String,
        openedBy: json['opened_by'] as String,
        closedBy: json['closed_by'] as String? ?? '',
        openingCash: json['opening_cash'] as num? ?? 0,
        cashSales: json['cash_sales'] as num? ?? 0,
        cashRefunds: json['cash_refunds'] as num? ?? 0,
        cashIn: json['cash_in'] as num? ?? 0,
        cashOut: json['cash_out'] as num? ?? 0,
        closingCash: json['closing_cash'] as num? ?? 0,
        status: json['status'] == 'closed'
            ? RegisterStatus.closed
            : RegisterStatus.open,
        openedAt: DateTime.parse(json['opened_at'] as String),
        closedAt: json['closed_at'] == null
            ? null
            : DateTime.parse(json['closed_at'] as String),
        notes: json['notes'] as String? ?? '',
      );
}
