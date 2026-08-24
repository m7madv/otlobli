class StoreBranch {
  const StoreBranch({
    required this.id,
    required this.storeId,
    required this.name,
    required this.code,
    required this.city,
    required this.address,
    required this.phone,
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
    isMain: json['is_main'] as bool? ?? false,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
