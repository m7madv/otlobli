import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import 'product_form_screen.dart';
import 'warranty_form_screen.dart';

enum _ScanAction { warranty, addProduct, cancel }

enum ScannerMode { productBarcode, serialNumber }

extension on ScannerMode {
  bool get isSerialNumber => this == ScannerMode.serialNumber;

  String get screenTitle => isSerialNumber
      ? L10n.current.msg95475323890f
      : L10n.current.msgeef242e5f60a;

  String get scanInstruction => isSerialNumber
      ? L10n.current.msg3a4e66889236
      : L10n.current.msg694c78c1743d;

  String get fallbackInstruction => isSerialNumber
      ? L10n.current.msge1f1a8206c6c
      : L10n.current.msg4722ca18bc62;

  String get manualDialogTitle => isSerialNumber
      ? L10n.current.msg8cfd61170f97
      : L10n.current.msg495059d04864;

  String get manualFieldLabel => isSerialNumber
      ? L10n.current.msg5789f0fed61c
      : L10n.current.msg89120753f66e;

  String get manualActionLabel => isSerialNumber
      ? L10n.current.msg0f60e04c50eb
      : L10n.current.msgd0f6edcf6d65;
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    this.returnBarcode = false,
    this.mode = ScannerMode.productBarcode,
    super.key,
  }) : assert(
         returnBarcode || mode == ScannerMode.productBarcode,
         'Serial scanning must return the scanned value.',
       );

  final bool returnBarcode;
  final ScannerMode mode;

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
    if (widget.returnBarcode) {
      Navigator.of(context).pop(code);
      return;
    }
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
        title: Text(widget.mode.manualDialogTitle),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: widget.mode.isSerialNumber
              ? TextInputType.visiblePassword
              : TextInputType.number,
          autocorrect: false,
          enableSuggestions: false,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
          decoration: InputDecoration(
            labelText: widget.mode.manualFieldLabel,
            prefixIcon: const Icon(Icons.qr_code_2_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.current.msg9a30dc2a96b8),
          ),
          FilledButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                Navigator.of(context).pop(input.text.trim());
              }
            },
            child: Text(widget.mode.manualActionLabel),
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
    L10n.watch(context);
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
            errorBuilder: (context, error) => ColoredBox(
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
                        L10n.current.msgd65b17f41a7f,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        L10n.current.msgce22a010407c,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mode.screenTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              widget.mode.scanInstruction,
                              style: const TextStyle(
                                color: Color(0xFFCBD8D5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RoundControl(
                        tooltip: _torchEnabled
                            ? L10n.current.msg738b82a27754
                            : L10n.current.msgd7050d12fdbb,
                        onPressed: _toggleTorch,
                        icon: _torchEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        active: _torchEnabled,
                      ),
                      const SizedBox(width: 8),
                      _RoundControl(
                        tooltip: L10n.current.msg22d515581ae2,
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
                      Expanded(
                        child: Text(
                          widget.mode.fallbackInstruction,
                          style: const TextStyle(
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
                        label: Text(L10n.current.msg3e8f9b9cc74e),
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
    L10n.watch(context);
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
    L10n.watch(context);
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
            found ? L10n.current.msg5961abc0e384 : L10n.current.msg9efb15a0be65,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),
          Text(
            found
                ? L10n.current.msg0c85a84d5f42(
                    product!.name,
                    product!.warrantyMonths,
                  )
                : L10n.current.msgbefe82928c8b,
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
                    ? L10n.current.msg59af482d0dba
                    : canManageCatalog
                    ? L10n.current.msg8a171a40773a
                    : L10n.current.msgaa03d5cb4d42,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(_ScanAction.cancel),
              child: Text(L10n.current.msgfd6dbd8625c7),
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
