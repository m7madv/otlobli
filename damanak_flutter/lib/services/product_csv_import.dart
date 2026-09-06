import 'package:damanak/l10n/l10n.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

class ProductImportRow {
  const ProductImportRow({
    required this.rowNumber,
    required this.name,
    required this.brand,
    required this.category,
    required this.barcode,
    required this.sku,
    required this.warrantyMonths,
    required this.salePrice,
    required this.costPrice,
    required this.isSerialized,
    required this.errors,
    this.quantity = 1,
    this.confidence,
    this.sourceText = '',
  });

  final int rowNumber;
  final String name;
  final String brand;
  final String category;
  final String barcode;
  final String sku;
  final int warrantyMonths;
  final num? salePrice;
  final num? costPrice;
  final bool isSerialized;
  final List<String> errors;
  final int quantity;
  final double? confidence;
  final String sourceText;

  bool get isValid => errors.isEmpty;
}

class ProductCsvPreview {
  const ProductCsvPreview({required this.rows});

  final List<ProductImportRow> rows;

  List<ProductImportRow> get validRows =>
      rows.where((row) => row.isValid).toList();
  int get invalidCount => rows.where((row) => !row.isValid).length;
}

ProductCsvPreview parseProductCsv(
  Uint8List bytes, {
  Set<String> existingBarcodes = const {},
}) {
  if (bytes.length > 2 * 1024 * 1024) {
    throw const FormatException('CSV_FILE_TOO_LARGE');
  }
  final content = utf8.decode(bytes).replaceFirst('\ufeff', '');
  final decoded = csv.decode(content);
  if (decoded.isEmpty) throw const FormatException('CSV_EMPTY');
  if (decoded.length > 501) throw const FormatException('CSV_TOO_MANY_ROWS');

  final header = decoded.first.map((value) => '$value').toList();
  final columns = <String, int>{};
  for (var index = 0; index < header.length; index++) {
    final canonical = _canonicalHeader(header[index]);
    if (canonical != null) columns.putIfAbsent(canonical, () => index);
  }
  if (!columns.containsKey('name')) {
    throw const FormatException('CSV_NAME_HEADER_REQUIRED');
  }

  final existing = existingBarcodes
      .map(_normalizeBarcode)
      .where((value) => value.isNotEmpty)
      .toSet();
  final seen = <String>{};
  final rows = <ProductImportRow>[];
  for (var index = 1; index < decoded.length; index++) {
    final source = decoded[index];
    if (source.every((value) => '$value'.trim().isEmpty)) continue;
    String cell(String key) {
      final cellIndex = columns[key];
      if (cellIndex == null || cellIndex >= source.length) return '';
      return '${source[cellIndex]}'.trim();
    }

    final errors = <String>[];
    final name = cell('name');
    final barcode = cell('barcode');
    final normalizedBarcode = _normalizeBarcode(barcode);
    final monthsText = cell('warrantyMonths');
    final warrantyMonths = monthsText.isEmpty
        ? 12
        : int.tryParse(monthsText) ?? -1;
    final salePrice = _optionalNumber(cell('salePrice'));
    final costPrice = _optionalNumber(cell('costPrice'));
    if (name.isEmpty) errors.add(L10n.current.msge88e67ff95f7);
    if (name.length > 140) errors.add(L10n.current.msg9f9208e398ce);
    if (warrantyMonths < 1 || warrantyMonths > 120) {
      errors.add(L10n.current.msg01c3eee9c8fe);
    }
    if (_invalidNumber(cell('salePrice'), salePrice)) {
      errors.add(L10n.current.msg2544f3725f52);
    }
    if (_invalidNumber(cell('costPrice'), costPrice)) {
      errors.add(L10n.current.msgbe9c2cb8f873);
    }
    if (salePrice != null && salePrice < 0) {
      errors.add(L10n.current.msg9f13bc06c709);
    }
    if (costPrice != null && costPrice < 0) {
      errors.add(L10n.current.msgceea9cb81b41);
    }
    if (normalizedBarcode.isNotEmpty) {
      if (existing.contains(normalizedBarcode)) {
        errors.add(L10n.current.msg05ffcc50bae0);
      } else if (!seen.add(normalizedBarcode)) {
        errors.add(L10n.current.msg30d74a964ec1);
      }
    }

    rows.add(
      ProductImportRow(
        rowNumber: index + 1,
        name: name,
        brand: cell('brand'),
        category: cell('category'),
        barcode: barcode,
        sku: cell('sku'),
        warrantyMonths: warrantyMonths,
        salePrice: salePrice,
        costPrice: costPrice,
        isSerialized: _parseBoolean(cell('isSerialized')),
        errors: errors,
      ),
    );
  }
  if (rows.isEmpty) throw const FormatException('CSV_NO_DATA_ROWS');
  return ProductCsvPreview(rows: rows);
}

String? _canonicalHeader(String source) {
  final value = source.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
  return switch (value) {
    'name' || 'product' || 'productname' || 'المنتج' || 'اسمالمنتج' => 'name',
    'brand' ||
    'company' ||
    'الشركة' ||
    'العلامة' ||
    'العلامةالتجارية' => 'brand',
    'category' || 'الفئة' || 'التصنيف' => 'category',
    'barcode' || 'الباركود' => 'barcode',
    'sku' || 'stockcode' || 'رمزالمخزون' => 'sku',
    'warrantymonths' ||
    'warranty' ||
    'مدةالضمان' ||
    'أشهرالضمان' => 'warrantyMonths',
    'saleprice' || 'price' || 'سعرالبيع' || 'السعر' => 'salePrice',
    'costprice' || 'cost' || 'سعرالتكلفة' || 'التكلفة' => 'costPrice',
    'serialized' ||
    'isserialized' ||
    'تسلسلي' ||
    'لهرقمتسلسلي' => 'isSerialized',
    _ => null,
  };
}

num? _optionalNumber(String value) {
  if (value.isEmpty) return null;
  return num.tryParse(value.replaceAll(' ', ''));
}

bool _invalidNumber(String source, num? parsed) =>
    source.isNotEmpty && parsed == null;

bool _parseBoolean(String value) => switch (value.trim().toLowerCase()) {
  '1' || 'true' || 'yes' || 'نعم' || 'صح' => true,
  _ => false,
};

String _normalizeBarcode(String value) =>
    value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
