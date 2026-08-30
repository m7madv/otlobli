import 'dart:typed_data';

class ProductDocumentInput {
  const ProductDocumentInput({
    required this.filename,
    required this.mimeType,
    required this.bytes,
  });

  final String filename;
  final String mimeType;
  final Uint8List bytes;
}

class AiProductSuggestion {
  const AiProductSuggestion({
    required this.name,
    required this.brand,
    required this.category,
    required this.barcode,
    required this.sku,
    required this.warrantyMonths,
    required this.salePrice,
    required this.costPrice,
    required this.quantity,
    required this.confidence,
    required this.sourceText,
  });

  final String name;
  final String brand;
  final String category;
  final String barcode;
  final String sku;
  final int warrantyMonths;
  final num? salePrice;
  final num? costPrice;
  final int quantity;
  final double confidence;
  final String sourceText;

  factory AiProductSuggestion.fromJson(Map<String, dynamic> json) {
    return AiProductSuggestion(
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      warrantyMonths: (json['warrantyMonths'] as num? ?? 12).toInt(),
      salePrice: json['salePrice'] as num?,
      costPrice: json['costPrice'] as num?,
      quantity: (json['quantity'] as num? ?? 1).toInt(),
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
      sourceText: json['sourceText'] as String? ?? '',
    );
  }
}

class AiImportUsage {
  const AiImportUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.estimatedCostUsd,
    required this.model,
  });

  final int inputTokens;
  final int outputTokens;
  final double? estimatedCostUsd;
  final String model;

  factory AiImportUsage.fromJson(Map<String, dynamic> json) => AiImportUsage(
    inputTokens: (json['inputTokens'] as num? ?? 0).toInt(),
    outputTokens: (json['outputTokens'] as num? ?? 0).toInt(),
    estimatedCostUsd: (json['estimatedCostUsd'] as num?)?.toDouble(),
    model: json['model'] as String? ?? '',
  );
}

class AiProductImportResult {
  const AiProductImportResult({
    required this.jobId,
    required this.currency,
    required this.products,
    required this.usage,
  });

  final String jobId;
  final String? currency;
  final List<AiProductSuggestion> products;
  final AiImportUsage usage;

  factory AiProductImportResult.fromJson(Map<String, dynamic> json) {
    final productRows = json['products'] as List? ?? const [];
    return AiProductImportResult(
      jobId: json['jobId'] as String? ?? '',
      currency: json['currency'] as String?,
      products: productRows
          .whereType<Map>()
          .map(
            (item) =>
                AiProductSuggestion.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      usage: AiImportUsage.fromJson(
        Map<String, dynamic>.from(json['usage'] as Map? ?? const {}),
      ),
    );
  }
}
