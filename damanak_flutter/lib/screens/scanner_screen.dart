import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import 'product_form_screen.dart';
import 'warranty_form_screen.dart';

enum _ScanAction { warranty, addProduct, cancel }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _scanner;
  bool _handling = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 700,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.itf14,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.qrCode,
      ],
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final code = capture.barcodes
        .map((item) => item.rawValue?.trim())
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;
    await _handleCode(code);
  }

  Future<void> _handleCode(String code) async {
    if (_handling) return;
    setState(() => _handling = true);
    await _scanner.stop();
    if (!mounted) return;
    final controller = AppScope.of(context);
    final product = controller.productByBarcode(code);
    final action = await showModalBottomSheet<_ScanAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ScanResultSheet(
        code: code,
        product: product,
        canManageCatalog: controller.membership!.role.canManageTeam,
      ),
    );
    if (!mounted) return;
    if (action == _ScanAction.warranty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              WarrantyFormScreen(product: product, scannedBarcode: code),
        ),
      );
    } else if (action == _ScanAction.addProduct) {
      final newProduct = await Navigator.of(context).push<Product>(
        MaterialPageRoute(
          builder: (_) => ProductFormScreen(initialBarcode: code),
        ),
      );
      if (newProduct != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                WarrantyFormScreen(product: newProduct, scannedBarcode: code),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => _handling = false);
    try {
      await _scanner.start();
    } on MobileScannerException {
      // تعرض إضافة الماسح حالة الخطأ هنا، ويبقى الإدخال اليدوي متاحاً.
    }
  }

  Future<void> _manualEntry() async {
    final input = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال الباركود'),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
          decoration: const InputDecoration(
            labelText: 'رقم الباركود',
            prefixIcon: Icon(Icons.qr_code_2_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                Navigator.of(context).pop(input.text.trim());
              }
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
    input.dispose();
    if (code != null && mounted) {
      await _handleCode(code);
    }
  }

  Future<void> _toggleTorch() async {
    await _scanner.toggleTorch();
    if (mounted) {
      setState(() => _torchEnabled = !_torchEnabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
            errorBuilder: (context, error) => const ColoredBox(
              color: AppColors.ink,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.no_photography_outlined,
                        color: AppColors.amber,
                        size: 44,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'الكاميرا غير متاحة حالياً',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'اسمح باستخدام الكاميرا من إعدادات الجهاز، أو استخدم الإدخال اليدوي أدناه.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFBDD0CD),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: CustomPaint(painter: _ScannerFramePainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ماسح ضمانك',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'وجّه الباركود داخل الإطار',
                              style: TextStyle(
                                color: Color(0xFFCBD8D5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RoundControl(
                        tooltip: _torchEnabled
                            ? 'إطفاء الإضاءة'
                            : 'تشغيل الإضاءة',
                        onPressed: _toggleTorch,
                        icon: _torchEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        active: _torchEnabled,
                      ),
                      const SizedBox(width: 8),
                      _RoundControl(
                        tooltip: 'تبديل الكاميرا',
                        onPressed: _scanner.switchCamera,
                        icon: Icons.cameraswitch_outlined,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'إذا تعذّرت القراءة، أدخل الرقم المكتوب تحت الباركود.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _handling ? null : _manualEntry,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          minimumSize: const Size(44, 44),
                        ),
                        icon: const Icon(Icons.keyboard_alt_outlined, size: 19),
                        label: const Text('إدخال'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_handling)
            const ColoredBox(
              color: Color(0x55000000),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.active = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: active ? AppColors.amber : const Color(0xB3102A2E),
        foregroundColor: active ? AppColors.ink : Colors.white,
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({
    required this.code,
    required this.product,
    required this.canManageCatalog,
  });

  final String code;
  final Product? product;
  final bool canManageCatalog;

  @override
  Widget build(BuildContext context) {
    final found = product != null;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: found
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              found
                  ? Icons.check_circle_outline_rounded
                  : Icons.add_box_outlined,
              color: found ? colors.primary : colors.onSurface,
              size: 29,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            found ? 'تمت مطابقة المنتج' : 'باركود جديد على المتجر',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),
          Text(
            found
                ? '${product!.name} • ضمان ${product!.warrantyMonths} شهراً'
                : 'أضف بيانات هذا المنتج مرة واحدة، ثم سيُعرف تلقائياً في كل مسحة لاحقة.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              code,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(
                found || !canManageCatalog
                    ? _ScanAction.warranty
                    : _ScanAction.addProduct,
              ),
              icon: Icon(
                found || !canManageCatalog
                    ? Icons.receipt_long_outlined
                    : Icons.add_rounded,
              ),
              label: Text(
                found
                    ? 'إصدار ضمان لهذا المنتج'
                    : canManageCatalog
                    ? 'إضافة المنتج للكتالوج'
                    : 'إصدار ضمان بإدخال اسم المنتج',
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(_ScanAction.cancel),
              child: const Text('العودة للمسح'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = (size.width - 64).clamp(230.0, 430.0);
    final frameHeight = frameWidth * 0.48;
    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.43),
        width: frameWidth,
        height: frameHeight,
      ),
      const Radius.circular(22),
    );
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(frame);
    canvas.drawPath(shade, Paint()..color = const Color(0x88102A2E));
    canvas.drawRRect(
      frame,
      Paint()
        ..color = AppColors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final scanLine = Rect.fromLTWH(
      frame.left + 22,
      frame.center.dy - 1,
      frame.width - 44,
      2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanLine, const Radius.circular(2)),
      Paint()..color = AppColors.amber.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
