import 'package:damanak/models/product_ai_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('يقرأ اقتراحات المنتجات والاستخدام من استجابة آمنة', () {
    final result = AiProductImportResult.fromJson({
      'jobId': 'job-1',
      'currency': 'QAR',
      'products': [
        {
          'name': 'هاتف تجريبي',
          'brand': 'Example',
          'category': 'هواتف',
          'barcode': '1234567890123',
          'sku': 'PHONE-1',
          'warrantyMonths': 24,
          'salePrice': 1299.5,
          'costPrice': 900,
          'quantity': 3,
          'confidence': 0.93,
          'sourceText': 'السطر 4',
        },
      ],
      'usage': {
        'inputTokens': 8000,
        'outputTokens': 450,
        'estimatedCostUsd': 0.008025,
        'provider': 'gemini',
        'pricingTier': 'free',
        'fallbackUsed': false,
        'monthlyUsed': 3,
        'monthlyLimit': 100,
        'model': 'gpt-5.4-mini',
      },
    });

    expect(result.jobId, 'job-1');
    expect(result.currency, 'QAR');
    expect(result.products, hasLength(1));
    expect(result.products.single.warrantyMonths, 24);
    expect(result.products.single.quantity, 3);
    expect(result.products.single.confidence, 0.93);
    expect(result.usage.inputTokens, 8000);
    expect(result.usage.estimatedCostUsd, closeTo(0.008025, 0.000001));
    expect(result.usage.providerLabel, 'Gemini');
    expect(result.usage.isFreeProvider, isTrue);
    expect(result.usage.monthlyUsed, 3);
    expect(result.usage.monthlyLimit, 100);
  });

  test('يتعامل مع الحقول الاختيارية الناقصة دون انهيار', () {
    final result = AiProductImportResult.fromJson({
      'products': [
        {'name': 'منتج غير مكتمل'},
        'صف غير صالح',
      ],
    });

    expect(result.products, hasLength(1));
    expect(result.products.single.name, 'منتج غير مكتمل');
    expect(result.products.single.warrantyMonths, 12);
    expect(result.products.single.quantity, 1);
    expect(result.usage.inputTokens, 0);
  });
}
