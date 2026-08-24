class StoreProfile {
  const StoreProfile({
    required this.name,
    required this.phone,
    required this.city,
  });

  const StoreProfile.initial() : name = 'متجر ضمانك', phone = '', city = '';

  final String name;
  final String phone;
  final String city;

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'city': city};

  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    return StoreProfile(
      name: json['name'] as String? ?? 'متجر ضمانك',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }
}
