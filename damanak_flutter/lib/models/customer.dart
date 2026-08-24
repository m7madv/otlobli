class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.storeId,
    required this.name,
    required this.phone,
    required this.email,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String storeId;
  final String name;
  final String phone;
  final String email;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool matches(String query) {
    final value = query.trim().toLowerCase();
    return value.isEmpty ||
        name.toLowerCase().contains(value) ||
        phone.toLowerCase().contains(value) ||
        email.toLowerCase().contains(value);
  }

  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      CustomerProfile(
        id: json['id'] as String,
        storeId: json['store_id'] as String? ?? '',
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
