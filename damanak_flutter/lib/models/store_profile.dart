class StoreProfile {
  const StoreProfile({
    required this.name,
    required this.phone,
    required this.city,
    this.address = '',
    this.countryCode = 'SA',
    this.currencyCode = 'SAR',
    this.taxRate = 0,
    this.pricesIncludeTax = true,
    this.taxNumber = '',
    this.commercialRegistration = '',
    this.invoicePrefix = 'INV',
  });

  const StoreProfile.initial()
    : name = 'متجر ضمانك',
      phone = '',
      city = '',
      address = '',
      countryCode = 'SA',
      currencyCode = 'SAR',
      taxRate = 0,
      pricesIncludeTax = true,
      taxNumber = '',
      commercialRegistration = '',
      invoicePrefix = 'INV';

  final String name;
  final String phone;
  final String city;
  final String address;
  final String countryCode;
  final String currencyCode;
  final num taxRate;
  final bool pricesIncludeTax;
  final String taxNumber;
  final String commercialRegistration;
  final String invoicePrefix;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'city': city,
    'address': address,
    'countryCode': countryCode,
    'currencyCode': currencyCode,
    'taxRate': taxRate,
    'pricesIncludeTax': pricesIncludeTax,
    'taxNumber': taxNumber,
    'commercialRegistration': commercialRegistration,
    'invoicePrefix': invoicePrefix,
  };

  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    return StoreProfile(
      name: json['name'] as String? ?? 'متجر ضمانك',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? 'SA',
      currencyCode: json['currencyCode'] as String? ?? 'SAR',
      taxRate: json['taxRate'] as num? ?? 0,
      pricesIncludeTax: json['pricesIncludeTax'] as bool? ?? true,
      taxNumber: json['taxNumber'] as String? ?? '',
      commercialRegistration: json['commercialRegistration'] as String? ?? '',
      invoicePrefix: json['invoicePrefix'] as String? ?? 'INV',
    );
  }
}
