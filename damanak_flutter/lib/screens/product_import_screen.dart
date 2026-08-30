import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../models/product_ai_import.dart';
import '../services/product_csv_import.dart';
import '../state/app_scope.dart';

class ProductImportScreen extends StatefulWidget {
  const ProductImportScreen({super.key});

  @override
  State<ProductImportScreen> createState() => _ProductImportScreenState();
}

class _ProductImportScreenState extends State<ProductImportScreen> {
  ProductCsvPreview? _preview;
  String? _fileName;
  String? _error;
  bool _loading = false;
  int _imported = 0;
  int _failed = 0;
  AiImportUsage? _aiUsage;

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final validCount = preview?.validRows.length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('استيراد المنتجات')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'أضف الكتالوج دفعة واحدة',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر ملف CSV، راجع الأخطاء، ثم احفظ الصفوف السليمة فقط. لن نحذف أو نعدّل منتجاتك الحالية.',
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _loading ? null : _pickFile,
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: Text(
                                    preview == null
                                        ? 'اختيار ملف CSV'
                                        : 'اختيار ملف آخر',
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: _loading ? null : _pickAiDocument,
                                  icon: const Icon(Icons.auto_awesome_outlined),
                                  label: const Text('تحليل PDF أو صورة'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _shareTemplate,
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('قالب جاهز'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'استخدم التحليل للكتالوجات غير الشخصية فقط. لا ترفع فواتير تحتوي أسماء عملاء أو أرقام هواتف؛ ستراجع كل بند قبل حفظه.',
                              style: TextStyle(
                                color: context.colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            if (_fileName != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _fileName!,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: context.colors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (_aiUsage != null) ...[
                              const SizedBox(height: 12),
                              _AiUsageNote(usage: _aiUsage!),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 14),
                      _ImportSummary(
                        total: preview.rows.length,
                        valid: validCount,
                        invalid: preview.invalidCount,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'المعاينة',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final row in preview.rows.take(50)) ...[
                        _ImportRowCard(row: row),
                        const SizedBox(height: 8),
                      ],
                      if (preview.rows.length > 50)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'تم عرض أول 50 صفاً. سيُفحص الملف كاملاً عند الاستيراد.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        key: const ValueKey('import-valid-products'),
                        onPressed: _loading || validCount == 0
                            ? null
                            : _importProducts,
                        icon: _loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.inventory_2_outlined),
                        label: Text(
                          _loading
                              ? 'جارٍ الاستيراد…'
                              : 'استيراد $validCount منتج',
                        ),
                      ),
                      if (_imported + _failed > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          'تمت إضافة $_imported، وتعذر $_failed.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _error = null;
      _imported = 0;
      _failed = 0;
      _aiUsage = null;
    });
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final controller = AppScope.of(context);
      final preview = parseProductCsv(
        bytes,
        existingBarcodes: controller.products
            .map((product) => product.barcode)
            .toSet(),
      );
      setState(() {
        _fileName = file.name;
        _preview = preview;
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = _friendlyCsvError(error.message));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'تعذر قراءة الملف. اختر ملف CSV محفوظاً بترميز UTF-8.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAiDocument() async {
    setState(() {
      _loading = true;
      _error = null;
      _imported = 0;
      _failed = 0;
      _aiUsage = null;
    });
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 8 * 1024 * 1024) {
        throw const FormatException('AI_FILE_TOO_LARGE');
      }
      final mimeType = _mimeType(file.extension);
      if (mimeType == null) throw const FormatException('AI_FILE_INVALID');
      final controller = AppScope.of(context);
      final result = await controller.analyzeProductDocument(
        ProductDocumentInput(
          filename: file.name,
          mimeType: mimeType,
          bytes: bytes,
        ),
      );
      if (!mounted) return;
      if (result == null) {
        throw FormatException(controller.errorMessage ?? 'AI_IMPORT_FAILED');
      }
      final existing = controller.products
          .map((product) => product.barcode.trim().toUpperCase())
          .where((barcode) => barcode.isNotEmpty)
          .toSet();
      final seen = <String>{};
      final rows = <ProductImportRow>[];
      for (var index = 0; index < result.products.length; index++) {
        final item = result.products[index];
        final errors = <String>[];
        final barcode = item.barcode.trim().toUpperCase();
        if (item.confidence < 0.55) {
          errors.add('الثقة منخفضة؛ راجع هذا البند وأضفه يدوياً');
        }
        if (barcode.isNotEmpty && existing.contains(barcode)) {
          errors.add('الباركود موجود في الكتالوج');
        } else if (barcode.isNotEmpty && !seen.add(barcode)) {
          errors.add('الباركود مكرر في المستند');
        }
        rows.add(
          ProductImportRow(
            rowNumber: index + 1,
            name: item.name,
            brand: item.brand,
            category: item.category,
            barcode: item.barcode,
            sku: item.sku,
            warrantyMonths: item.warrantyMonths,
            salePrice: item.salePrice,
            costPrice: item.costPrice,
            isSerialized: item.barcode.isNotEmpty,
            errors: errors,
            quantity: item.quantity,
            confidence: item.confidence,
            sourceText: item.sourceText,
          ),
        );
      }
      if (rows.isEmpty) throw const FormatException('AI_NO_PRODUCTS');
      setState(() {
        _fileName = file.name;
        _preview = ProductCsvPreview(rows: rows);
        _aiUsage = result.usage;
      });
    } on FormatException catch (error) {
      if (mounted) {
        final message = error.message;
        setState(
          () => _error = RegExp(r'[\u0600-\u06FF]').hasMatch(message)
              ? message
              : _friendlyAiError(message),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'تعذر تحليل المستند الآن. حاول بصورة أوضح أو استخدم CSV.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importProducts() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() {
      _loading = true;
      _imported = 0;
      _failed = 0;
    });
    final controller = AppScope.of(context);
    for (final row in preview.validRows) {
      final created = await controller.addProduct(
        name: row.name,
        brand: row.brand,
        category: row.category,
        barcode: row.barcode,
        sku: row.sku,
        warrantyMonths: row.warrantyMonths,
        salePrice: row.salePrice,
        costPrice: row.costPrice,
        isSerialized: row.isSerialized,
      );
      if (!mounted) return;
      setState(() {
        if (created == null) {
          _failed++;
        } else {
          _imported++;
        }
      });
    }
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت إضافة $_imported منتج إلى الكتالوج.')),
    );
  }

  Future<void> _shareTemplate() async {
    const template =
        '\ufeffاسم المنتج,الشركة,الفئة,الباركود,رمز المخزون,مدة الضمان,سعر البيع,سعر التكلفة,تسلسلي\r\n'
        'هاتف تجريبي,الشركة,هواتف,1234567890123,PHONE-01,12,1000,800,نعم\r\n';
    final bytes = Uint8List.fromList(utf8.encode(template));
    final file = XFile.fromData(
      bytes,
      name: 'damanak-products-template.csv',
      mimeType: 'text/csv',
    );
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [file.name],
        subject: 'قالب استيراد منتجات ضمانك',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  String _friendlyCsvError(String code) => switch (code) {
    'CSV_FILE_TOO_LARGE' => 'حجم الملف أكبر من 2 MB.',
    'CSV_TOO_MANY_ROWS' => 'الملف أكبر من 500 منتج. قسّمه إلى ملفين.',
    'CSV_EMPTY' || 'CSV_NO_DATA_ROWS' => 'الملف لا يحتوي على منتجات.',
    'CSV_NAME_HEADER_REQUIRED' =>
      'أضف عمود «اسم المنتج» أو استخدم القالب الجاهز.',
    _ => 'تعذر فهم الملف. استخدم القالب الجاهز ثم حاول مجدداً.',
  };

  String _friendlyAiError(String code) {
    final normalized = code.toUpperCase();
    if (normalized.contains('AI_FILE_TOO_LARGE')) {
      return 'حجم المستند أكبر من 8 MB.';
    }
    if (normalized.contains('AI_IMPORT_DAILY_SAFETY_LIMIT')) {
      return 'وصل المتجر إلى حد 25 تحليلاً اليوم. أكمل غداً أو استخدم CSV.';
    }
    if (normalized.contains('AI_IMPORT_MONTHLY_LIMIT')) {
      return 'استهلك المتجر تحليلات الذكاء الاصطناعي المشمولة هذا الشهر. استخدم CSV أو انتظر بداية الشهر التالي.';
    }
    if (normalized.contains('AI_IMPORT_DAILY_SAFETY_LIMIT')) {
      return 'تم إيقاف التحليل مؤقتاً لحماية الحساب من الاستخدام غير المعتاد. حاول غداً أو استخدم CSV.';
    }
    if (normalized.contains('AI_IMPORT_NOT_INCLUDED')) {
      return 'تحليل الملفات غير مشمول في الخطة الحالية. ما زال استيراد CSV متاحاً.';
    }
    if (normalized.contains('AI_PROVIDER_NOT_CONFIGURED')) {
      return 'خدمة الذكاء الاصطناعي غير مهيأة على الخادم بعد.';
    }
    if (normalized.contains('AI_NO_PRODUCTS')) {
      return 'لم نعثر على بنود منتجات واضحة في المستند.';
    }
    if (normalized.contains('MANAGER_REQUIRED')) {
      return 'تحليل المستندات متاح للمالك أو المدير فقط.';
    }
    return 'تعذر تحليل المستند. استخدم صورة أو PDF واضحاً ثم حاول مجدداً.';
  }

  String? _mimeType(String? extension) => switch (extension?.toLowerCase()) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => null,
  };
}

class _AiUsageNote extends StatelessWidget {
  const _AiUsageNote({required this.usage});

  final AiImportUsage usage;

  @override
  Widget build(BuildContext context) {
    final cost = usage.estimatedCostUsd;
    final quota = usage.monthlyLimit > 0
        ? ' • ${usage.monthlyUsed}/${usage.monthlyLimit} هذا الشهر'
        : '';
    final provider = usage.providerLabel;
    final fallback = usage.fallbackUsed ? ' بعد التحويل التلقائي' : '';
    final costText = usage.isFreeProvider
        ? 'دون تكلفة مزود حالياً'
        : cost == null
        ? 'التكلفة غير متاحة'
        : 'تكلفة تقريبية \$${cost.toStringAsFixed(4)}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_outlined, color: context.colors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'اقتراح من $provider$fallback — $costText$quota. راجع كل بند قبل الحفظ.',
              style: TextStyle(
                color: context.colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({
    required this.total,
    required this.valid,
    required this.invalid,
  });

  final int total;
  final int valid;
  final int invalid;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            Text(
              '$total صف',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '$valid جاهز',
              style: TextStyle(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$invalid يحتاج مراجعة',
              style: TextStyle(
                color: invalid == 0
                    ? context.colors.onSurfaceVariant
                    : context.colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportRowCard extends StatelessWidget {
  const _ImportRowCard({required this.row});

  final ProductImportRow row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      color: row.isValid ? colors.surface : colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              row.isValid ? Icons.check_circle_outline : Icons.error_outline,
              color: row.isValid ? colors.primary : colors.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name.isEmpty ? 'صف ${row.rowNumber}' : row.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (row.brand.isNotEmpty) row.brand,
                      if (row.barcode.isNotEmpty) row.barcode,
                      '${row.warrantyMonths} شهر',
                      if (row.quantity > 1) 'الكمية ${row.quantity}',
                      if (row.confidence != null)
                        'ثقة ${(row.confidence! * 100).round()}%',
                    ].join(' • '),
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  if (row.sourceText.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'من المستند: ${row.sourceText}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (row.errors.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      row.errors.join('، '),
                      style: TextStyle(
                        color: colors.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
