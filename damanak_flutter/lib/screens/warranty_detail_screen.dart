import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/status_chip.dart';

class WarrantyDetailScreen extends StatefulWidget {
  const WarrantyDetailScreen({
    required this.warrantyId,
    this.justCreated = false,
    super.key,
  });

  final String warrantyId;
  final bool justCreated;

  @override
  State<WarrantyDetailScreen> createState() => _WarrantyDetailScreenState();
}

class _WarrantyDetailScreenState extends State<WarrantyDetailScreen> {
  bool _showQr = false;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final warranty = controller.warrantyById(widget.warrantyId);

    if (warranty == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('لم تعد بطاقة الضمان موجودة.')),
        ),
      );
    }

    final requests = controller.requestsForWarranty(warranty.id);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.justCreated ? 'تم إصدار الضمان' : 'تفاصيل الضمان'),
          actions: [
            IconButton(
              tooltip: 'حذف الضمان',
              onPressed: () => _confirmDelete(warranty),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    if (widget.justCreated) ...[
                      const _CreatedNotice(),
                      const SizedBox(height: 14),
                    ],
                    _WarrantyDocument(warranty: warranty),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _shareWarranty(warranty),
                            icon: const Icon(Icons.ios_share_rounded),
                            label: const Text('مشاركة البطاقة'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Semantics(
                          button: true,
                          label: _showQr
                              ? 'إخفاء رمز التحقق'
                              : 'عرض رمز التحقق',
                          child: Tooltip(
                            message: _showQr
                                ? 'إخفاء رمز التحقق'
                                : 'عرض رمز التحقق',
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _showQr = !_showQr),
                              child: Icon(
                                _showQr
                                    ? Icons.close_rounded
                                    : Icons.qr_code_2_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      crossFadeState: _showQr
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _QrPanel(warranty: warranty),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'طلبات الصيانة',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openMaintenanceDialog(warranty),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('طلب جديد'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (requests.isEmpty)
                      const _NoRequests()
                    else
                      ...requests.map(
                        (request) => Card(
                          margin: const EdgeInsets.only(bottom: 9),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              request.issue,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${request.id} • ${formatDate(request.createdAt)}',
                                textDirection: TextDirection.ltr,
                              ),
                            ),
                            trailing: MaintenanceStatusChip(
                              status: request.status,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareWarranty(Warranty warranty) async {
    final profile = AppScope.of(context).profile;
    final storeLine = [
      profile.name,
      profile.city,
    ].where((value) => value.trim().isNotEmpty).join(' - ');
    final text =
        '''
بطاقة ضمان من $storeLine

المنتج: ${warranty.productName}
العميل: ${warranty.customerName}
رقم الضمان: ${warranty.id}
تاريخ الشراء: ${formatDate(warranty.purchaseDate)}
صالح حتى: ${formatDate(warranty.expiryDate)}
الحالة: ${warranty.statusAt().label}
${warranty.notes.isEmpty ? '' : '\nملاحظات: ${warranty.notes}'}

احتفظ بهذه الرسالة للرجوع إليها عند طلب الصيانة.
'''
            .trim();
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'بطاقة ضمان ${warranty.id}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _openMaintenanceDialog(Warranty warranty) async {
    final issueController = TextEditingController();
    final issue = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('طلب صيانة جديد'),
        content: TextField(
          controller: issueController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'وصف المشكلة',
            hintText: 'مثال: الجهاز لا يعمل بعد التشغيل',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = issueController.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('حفظ الطلب'),
          ),
        ],
      ),
    );
    issueController.dispose();
    if (issue == null || !mounted) return;
    await AppScope.of(
      context,
    ).addMaintenanceRequest(warrantyId: warranty.id, issue: issue);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تسجيل طلب الصيانة.')));
    }
  }

  Future<void> _confirmDelete(Warranty warranty) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف بطاقة الضمان؟'),
        content: const Text(
          'سيتم حذف البطاقة وطلبات الصيانة التابعة لها من هذا الجهاز نهائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AppScope.of(context).deleteWarranty(warranty.id);
    if (mounted) Navigator.of(context).pop();
  }
}

class _WarrantyDocument extends StatelessWidget {
  const _WarrantyDocument({required this.warranty});

  final Warranty warranty;

  @override
  Widget build(BuildContext context) {
    final status = warranty.statusAt();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.gold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وثيقة ضمان رقمية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'مسجلة ومحفوظة على جهاز المتجر',
                        style: TextStyle(
                          color: Color(0xFFB9C3CC),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المنتج المشمول',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            warranty.productName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    WarrantyStatusChip(status: status),
                  ],
                ),
                const SizedBox(height: 22),
                _DetailRow(label: 'اسم العميل', value: warranty.customerName),
                _DetailRow(
                  label: 'رقم الجوال',
                  value: warranty.customerPhone,
                  ltr: true,
                ),
                _DetailRow(label: 'رقم الضمان', value: warranty.id, ltr: true),
                if (warranty.serialNumber.isNotEmpty)
                  _DetailRow(
                    label: 'الرقم التسلسلي',
                    value: warranty.serialNumber,
                    ltr: true,
                  ),
                _DetailRow(
                  label: 'تاريخ الشراء',
                  value: formatDate(warranty.purchaseDate),
                  ltr: true,
                ),
                _DetailRow(
                  label: 'نهاية الضمان',
                  value: formatDate(warranty.expiryDate),
                  ltr: true,
                ),
                if (warranty.notes.isNotEmpty) ...[
                  const Divider(height: 28),
                  const Text(
                    'ملاحظات وشروط',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(warranty.notes),
                ],
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: status == WarrantyStatus.expired
                        ? const Color(0xFFFBEAEA)
                        : AppColors.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    warrantyRemainingLabel(warranty.expiryDate),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: status == WarrantyStatus.expired
                          ? AppColors.danger
                          : AppColors.emeraldDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.ltr = false,
  });

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
              textAlign: ltr ? TextAlign.end : TextAlign.start,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.warranty});

  final Warranty warranty;

  @override
  Widget build(BuildContext context) {
    final qrData =
        'DAMANAK|${warranty.id}|${warranty.productName}|${formatDate(warranty.expiryDate)}|${warranty.statusAt().label}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Semantics(
              label: 'رمز تحقق بطاقة الضمان ${warranty.id}',
              image: true,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 190,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.ink,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'رمز تحقق محلي',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'لا يحتوي الرمز على رقم جوال العميل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatedNotice extends StatelessWidget {
  const _CreatedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.emerald),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'تم إصدار البطاقة وحفظها على هذا الجهاز.',
              style: TextStyle(
                color: AppColors.emeraldDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoRequests extends StatelessWidget {
  const _NoRequests();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.handyman_outlined, color: AppColors.muted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'لا توجد طلبات صيانة لهذه البطاقة.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
