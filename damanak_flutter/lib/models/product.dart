class Product {
  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.brand,
    this.category = '',
    required this.barcode,
    required this.sku,
    required this.warrantyMonths,
    required this.salePrice,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String storeId;
  final String name;
  final String brand;
  final String category;
  final String barcode;
  final String sku;
  final int warrantyMonths;
  final num? salePrice;
  final bool isActive;
  final DateTime createdAt;

  bool matches(String query) {
    final value = query.trim().toLowerCase();
    return value.isEmpty ||
        name.toLowerCase().contains(value) ||
        brand.toLowerCase().contains(value) ||
        category.toLowerCase().contains(value) ||
        barcode.toLowerCase().contains(value) ||
        sku.toLowerCase().contains(value);
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      warrantyMonths: json['warranty_months'] as int? ?? 12,
      salePrice: json['sale_price'] as num?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
