enum BranchType { retail, warehouse, serviceCenter, hybrid }

extension BranchTypeText on BranchType {
  String get label => switch (this) {
    BranchType.retail => 'متجر بيع',
    BranchType.warehouse => 'مستودع',
    BranchType.serviceCenter => 'مركز صيانة',
    BranchType.hybrid => 'بيع وصيانة',
  };

  String get databaseValue => switch (this) {
    BranchType.retail => 'retail',
    BranchType.warehouse => 'warehouse',
    BranchType.serviceCenter => 'service_center',
    BranchType.hybrid => 'hybrid',
  };

  static BranchType fromValue(String? value) => switch (value) {
    'warehouse' => BranchType.warehouse,
    'service_center' => BranchType.serviceCenter,
    'hybrid' => BranchType.hybrid,
    _ => BranchType.retail,
  };
}

class StoreBranch {
  const StoreBranch({
    required this.id,
    required this.storeId,
    required this.name,
    required this.code,
    required this.city,
    required this.address,
    required this.phone,
    this.email = '',
    this.managerName = '',
    this.receiptPrefix = '',
    this.timezone = 'Asia/Riyadh',
    this.opensAt = '09:00',
    this.closesAt = '23:00',
    this.type = BranchType.retail,
    this.acceptsSales = true,
    this.handlesService = true,
    required this.isMain,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String storeId;
  final String name;
  final String code;
  final String city;
  final String address;
  final String phone;
  final String email;
  final String managerName;
  final String receiptPrefix;
  final String timezone;
  final String opensAt;
  final String closesAt;
  final BranchType type;
  final bool acceptsSales;
  final bool handlesService;
  final bool isMain;
  final bool isActive;
  final DateTime createdAt;

  factory StoreBranch.fromJson(Map<String, dynamic> json) => StoreBranch(
    id: json['id'] as String,
    storeId: json['store_id'] as String? ?? '',
    name: json['name'] as String,
    code: json['code'] as String? ?? '',
    city: json['city'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    managerName: json['manager_name'] as String? ?? '',
    receiptPrefix: json['receipt_prefix'] as String? ?? '',
    timezone: json['timezone'] as String? ?? 'Asia/Riyadh',
    opensAt: _shortTime(json['opens_at']),
    closesAt: _shortTime(json['closes_at'], fallback: '23:00'),
    type: BranchTypeText.fromValue(json['branch_type'] as String?),
    acceptsSales: json['accepts_sales'] as bool? ?? true,
    handlesService: json['handles_service'] as bool? ?? true,
    isMain: json['is_main'] as bool? ?? false,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

String _shortTime(Object? value, {String fallback = '09:00'}) {
  final time = value?.toString() ?? fallback;
  return time.length >= 5 ? time.substring(0, 5) : fallback;
}
