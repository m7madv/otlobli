import 'package:damanak/l10n/l10n.dart';
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
    L10n.watch(context);
    final preview = _preview;
    final validCount = preview?.validRows.length ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(L10n.current.msg7da25370ad4d)),
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
                      L10n.current.msgc7132683d675,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      L10n.current.msg2ff93e9e5a5a,
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
                                        ? L10n.current.msg22282be709e3
                                        : L10n.current.msg4f00cfb1a90e,
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: _loading ? null : _pickAiDocument,
                                  icon: const Icon(Icons.auto_awesome_outlined),
                                  label: Text(L10n.current.msgd0be8058de1b),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _shareTemplate,
                                  icon: const Icon(Icons.download_outlined),
                                  label: Text(L10n.current.msg88935eec0c25),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              L10n.current.msgdab883505768,
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
                        L10n.current.msg0a40c58ac7c3,
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
                            L10n.current.msg6c25eb2e88bd,
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
                              ? L10n.current.msg2116a0b32a96
                              : L10n.current.msg961c99a8347a(validCount),
                        ),
                      ),
                      if (_imported + _failed > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          L10n.current.msg40b95a7c5c2c(_imported, _failed),
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
        setState(() => _error = L10n.current.msgafb4d430799e);
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
          errors.add(L10n.current.msgfcd45e8640a7);
        }
        if (barcode.isNotEmpty && existing.contains(barcode)) {
          errors.add(L10n.current.msg05ffcc50bae0);
        } else if (barcode.isNotEmpty && !seen.add(barcode)) {
          errors.add(L10n.current.msgddd221288b42);
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
        setState(() => _error = L10n.current.msgdbd7edea4ea9);
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
      SnackBar(content: Text(L10n.current.msge7ff83434b7d(_imported))),
    );
  }

  Future<void> _shareTemplate() async {
    final template = L10n.current.msg718514128473;
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
        subject: L10n.current.msgf3c60f9cbf5d,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  String _friendlyCsvError(String code) => switch (code) {
    'CSV_FILE_TOO_LARGE' => L10n.current.msg7236f4dda039,
    'CSV_TOO_MANY_ROWS' => L10n.current.msg2e9dd57261c9,
    'CSV_EMPTY' || 'CSV_NO_DATA_ROWS' => L10n.current.msg62bc11b3b73c,
    'CSV_NAME_HEADER_REQUIRED' => L10n.current.msg1a5d40ae08ae,
    _ => L10n.current.msgc64f37dc61c0,
  };

  String _friendlyAiError(String code) {
    final normalized = code.toUpperCase();
    if (normalized.contains('AI_FILE_TOO_LARGE')) {
      return L10n.current.msg99211b25b807;
    }
    if (normalized.contains('AI_IMPORT_DAILY_SAFETY_LIMIT')) {
      return L10n.current.msg42a260cf8095;
    }
    if (normalized.contains('AI_IMPORT_MONTHLY_LIMIT')) {
      return L10n.current.msgad749680dd69;
    }
    if (normalized.contains('AI_IMPORT_DAILY_SAFETY_LIMIT')) {
      return L10n.current.msg72f71bb6d71f;
    }
    if (normalized.contains('AI_IMPORT_NOT_INCLUDED')) {
      return L10n.current.msgf9cecf4ef620;
    }
    if (normalized.contains('AI_PROVIDER_NOT_CONFIGURED')) {
      return L10n.current.msg1b71cdc2146e;
    }
    if (normalized.contains('AI_NO_PRODUCTS')) {
      return L10n.current.msg6bd24b889ef4;
    }
    if (normalized.contains('MANAGER_REQUIRED')) {
      return L10n.current.msg879aa43acd89;
    }
    return L10n.current.msg3d7a16d199ea;
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
    L10n.watch(context);
    final cost = usage.estimatedCostUsd;
    final quota = usage.monthlyLimit > 0
        ? L10n.current.msg08d7e5b813b5(usage.monthlyUsed, usage.monthlyLimit)
        : '';
    final provider = usage.providerLabel;
    final fallback = usage.fallbackUsed ? L10n.current.msg34a42928114a : '';
    final costText = usage.isFreeProvider
        ? L10n.current.msg484a070a0d97
        : cost == null
        ? L10n.current.msgba3ff8cf94fb
        : L10n.current.msg16fa83c9c867(cost.toStringAsFixed(4));
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
              L10n.current.msg3dad50574322(provider, fallback, costText, quota),
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
    L10n.watch(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            Text(
              L10n.current.msg1031703cb9b9(total),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              L10n.current.msg6a210a2d210e(valid),
              style: TextStyle(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              L10n.current.msgbf6ab67c7f6a(invalid),
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
    L10n.watch(context);
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
                    row.name.isEmpty
                        ? L10n.current.msgfc7eba5345b4(row.rowNumber)
                        : row.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (row.brand.isNotEmpty) row.brand,
                      if (row.barcode.isNotEmpty) row.barcode,
                      L10n.current.msgb2f6a21fe6bd(row.warrantyMonths),
                      if (row.quantity > 1)
                        L10n.current.msg894d7bfa79b9(row.quantity),
                      if (row.confidence != null)
                        L10n.current.msg5e7f0a12ab07(
                          (row.confidence! * 100).round(),
                        ),
                    ].join(' • '),
                    textDirection: Directionality.of(context),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  if (row.sourceText.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      L10n.current.msgc35f42fce649(row.sourceText),
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
                      row.errors.join(L10n.current.msg11735aabd336),
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
