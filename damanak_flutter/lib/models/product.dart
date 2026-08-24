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
    this.costPrice,
    this.trackInventory = true,
    this.isSerialized = false,
    this.reorderPoint = 2,
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
  final num? costPrice;
  final bool trackInventory;
  final bool isSerialized;
  final num reorderPoint;
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
      costPrice: json['cost_price'] as num?,
      trackInventory: json['track_inventory'] as bool? ?? true,
      isSerialized: json['is_serialized'] as bool? ?? false,
      reorderPoint: json['reorder_point'] as num? ?? 2,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
