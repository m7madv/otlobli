import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/account.dart';
import '../models/claim_attachment.dart';
import '../models/claim_ai_review.dart';
import '../models/maintenance_request.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/status_chip.dart';
import 'warranty_detail_screen.dart';

class ClaimDetailScreen extends StatelessWidget {
  const ClaimDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final request = controller.requestById(requestId);
    final warranty = request == null
        ? null
        : controller.warrantyById(request.warrantyId);
    if (request == null || warranty == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: Text('لم تعد المطالبة موجودة.'))),
      );
    }

    final assignee = controller.teamMemberById(request.assignedTo);
    final branch = controller.branches
        .where((item) => item.id == request.serviceBranchId)
        .firstOrNull;
    final canDecide = controller.membership?.role.canManageTeam ?? false;
    final aiReview = controller.claimAiReview(request.id);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(request.displayNumber),
          actions: [
            IconButton(
              tooltip: 'تعديل تفاصيل المطالبة',
              onPressed: controller.busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ClaimEditScreen(requestId: request.id),
                      ),
                    ),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ClaimHeader(request: request),
                    const SizedBox(height: 12),
                    _WorkflowCard(
                      request: request,
                      canDecide: canDecide,
                      onMove: (status) => _moveTo(context, request, status),
                    ),
                    const SizedBox(height: 12),
                    _ContactCard(
                      busy: controller.busy,
                      onWhatsApp: () =>
                          _sendCustomerUpdate(context, request, warranty),
                      onCall: () => _callCustomer(context, warranty),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'العميل والمنتج',
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                WarrantyDetailScreen(warrantyId: warranty.id),
                          ),
                        ),
                        child: const Text('فتح الضمان'),
                      ),
                      children: [
                        _DetailLine(
                          label: 'المنتج',
                          value: warranty.productName,
                        ),
                        _DetailLine(
                          label: 'العميل',
                          value: warranty.customerName,
                        ),
                        _DetailLine(
                          label: 'الهاتف',
                          value: warranty.customerPhone,
                          ltr: true,
                        ),
                        if (warranty.serialNumber.isNotEmpty)
                          _DetailLine(
                            label: 'الرقم التسلسلي',
                            value: warranty.serialNumber,
                            ltr: true,
                          ),
                        _DetailLine(
                          label: 'نهاية الضمان',
                          value: formatDate(warranty.expiryDate),
                          ltr: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'تفاصيل المطالبة',
                      children: [
                        _DetailLine(label: 'المشكلة', value: request.issue),
                        _DetailLine(
                          label: 'الفئة',
                          value: request.category.label,
                        ),
                        _DetailLine(
                          label: 'الأولوية',
                          value: request.priority.label,
                        ),
                        _DetailLine(
                          label: 'المصدر',
                          value: request.channel.label,
                        ),
                        _DetailLine(
                          label: 'المسؤول',
                          value: assignee?.fullName ?? 'غير معيّن',
                        ),
                        _DetailLine(
                          label: 'فرع الخدمة',
                          value: branch?.name ?? 'غير محدد',
                        ),
                        _DetailLine(
                          label: 'موعد الاستجابة',
                          value: request.slaDueAt == null
                              ? 'غير محدد'
                              : formatDate(request.slaDueAt!),
                          ltr: request.slaDueAt != null,
                        ),
                      ],
                    ),
                    if (canDecide) ...[
                      const SizedBox(height: 12),
                      _AiReviewCard(
                        review: aiReview,
                        busy: controller.busy,
                        onAnalyze: () => _runAiReview(context, request),
                        onApply: aiReview == null
                            ? null
                            : () => _applyAiSuggestions(
                                context,
                                request,
                                aiReview,
                              ),
                      ),
                    ],
                    _AttachmentsSection(requestId: request.id),
                    if (_hasServiceDetails(request)) ...[
                      const SizedBox(height: 12),
                      _Section(
                        title: 'المعالجة والقرار',
                        children: [
                          if (request.diagnosis.isNotEmpty)
                            _DetailLine(
                              label: 'التشخيص',
                              value: request.diagnosis,
                            ),
                          if (request.resolution != ClaimResolution.none)
                            _DetailLine(
                              label: 'القرار',
                              value: request.resolution.label,
                            ),
                          if (request.resolutionNotes.isNotEmpty)
                            _DetailLine(
                              label: 'تفاصيل التنفيذ',
                              value: request.resolutionNotes,
                            ),
                          if (request.decisionReason.isNotEmpty)
                            _DetailLine(
                              label: 'سبب القرار',
                              value: request.decisionReason,
                            ),
                          if (request.customerNotes.isNotEmpty)
                            _DetailLine(
                              label: 'ظاهر للعميل',
                              value: request.customerNotes,
                            ),
                          if (request.internalNotes.isNotEmpty)
                            _PrivateNote(value: request.internalNotes),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _Section(
                      title: 'السجل',
                      children: [
                        _TimelineItem(
                          title: 'تم تسجيل المطالبة',
                          date: request.createdAt,
                          active: true,
                        ),
                        if (request.approvedAt != null)
                          _TimelineItem(
                            title: 'تم قبول المطالبة',
                            date: request.approvedAt!,
                            active: true,
                          ),
                        if (request.completedAt != null)
                          _TimelineItem(
                            title: 'تم إكمال المطالبة',
                            date: request.completedAt!,
                            active: true,
                          ),
                        _TimelineItem(
                          title: 'آخر تحديث: ${request.status.label}',
                          date: request.updatedAt,
                          active: !request.status.isClosed,
                        ),
                      ],
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

  bool _hasServiceDetails(MaintenanceRequest request) =>
      request.diagnosis.isNotEmpty ||
      request.resolution != ClaimResolution.none ||
      request.resolutionNotes.isNotEmpty ||
      request.decisionReason.isNotEmpty ||
      request.customerNotes.isNotEmpty ||
      request.internalNotes.isNotEmpty;

  Future<void> _runAiReview(
    BuildContext context,
    MaintenanceRequest request,
  ) async {
    var includeAttachments = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('مساعد فرز المطالبة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'سيُرسل وصف المشكلة واسم المنتج إلى OpenAI دون اسم العميل أو هاتفه. النتيجة اقتراح للموظف ولا تقبل المطالبة أو ترفضها.',
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: includeAttachments,
                onChanged: (value) =>
                    setDialogState(() => includeAttachments = value),
                title: const Text('تحليل أول ملفين أيضاً'),
                subtitle: const Text(
                  'قد تحتوي الملفات على بيانات شخصية وتزيد التكلفة. اتركه مغلقاً إن لم تكن الصور ضرورية.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تحليل الآن'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await AppScope.of(context).analyzeClaim(
      requestId: request.id,
      includeAttachments: includeAttachments,
    );
    if (!context.mounted || result != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppScope.of(context).errorMessage ?? 'تعذر تحليل المطالبة الآن.',
        ),
      ),
    );
  }

  Future<void> _applyAiSuggestions(
    BuildContext context,
    MaintenanceRequest request,
    ClaimAiReview review,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استخدام الاقتراح؟'),
        content: Text(
          'سيُحدّث التصنيف إلى «${review.suggestedCategory.label}» والأولوية إلى «${review.suggestedPriority.label}». لن تتغير حالة المطالبة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تطبيق بعد المراجعة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AppScope.of(context).saveMaintenanceRequest(
      request.copyWith(
        category: review.suggestedCategory,
        priority: review.suggestedPriority,
      ),
    );
  }

  Future<void> _sendCustomerUpdate(
    BuildContext context,
    MaintenanceRequest request,
    Warranty warranty,
  ) async {
    final controller = AppScope.of(context);
    final link = controller.isDemo
        ? null
        : await controller.createWarrantyShareLink(warranty.id);
    if (!context.mounted) return;
    final message = _customerMessage(request, warranty, link);
    final phone = _internationalPhone(
      warranty.customerPhone,
      controller.store?.countryCode ?? 'QA',
    );
    final whatsapp = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {if (phone.isNotEmpty) 'phone': phone, 'text': message},
    );
    final opened = await launchUrl(
      whatsapp,
      mode: LaunchMode.externalApplication,
    );
    if (opened || !context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'تحديث المطالبة ${request.displayNumber}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _callCustomer(BuildContext context, Warranty warranty) async {
    final phone = warranty.customerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رقم هاتف مسجل لهذا العميل.')),
      );
      return;
    }
    final opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح تطبيق الاتصال.')));
    }
  }

  String _customerMessage(
    MaintenanceRequest request,
    Warranty warranty,
    Uri? link,
  ) {
    final nextLine = switch (request.status) {
      MaintenanceStatus.waitingForCustomer =>
        request.customerNotes.isEmpty
            ? 'نحتاج منك معلومات إضافية لإكمال المعالجة.'
            : 'نحتاج منك: ${request.customerNotes}',
      MaintenanceStatus.readyForPickup =>
        'المنتج جاهز للاستلام. تواصل مع المحل لتأكيد الموعد.',
      MaintenanceStatus.completed => 'اكتملت معالجة المطالبة.',
      MaintenanceStatus.rejected =>
        request.decisionReason.isEmpty
            ? 'تم اتخاذ قرار بشأن المطالبة. راجع الرابط للتفاصيل.'
            : 'القرار: ${request.decisionReason}',
      _ => 'سنبلغك عند انتقال المطالبة إلى الخطوة التالية.',
    };
    return [
      'مرحباً ${warranty.customerName}،',
      'تحديث المطالبة ${request.displayNumber} للمنتج ${warranty.productName}.',
      'الحالة: ${request.status.label}',
      nextLine,
      if (link != null) 'تابع المطالبة وأرسل الملفات من هنا:\n$link',
    ].join('\n\n');
  }

  String _internationalPhone(String raw, String countryCode) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.isEmpty) return '';
    final dialCode = switch (countryCode.toUpperCase()) {
      'QA' => '974',
      'SA' => '966',
      'AE' => '971',
      'KW' => '965',
      'BH' => '973',
      'OM' => '968',
      _ => '',
    };
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (dialCode.isNotEmpty && !digits.startsWith(dialCode)) {
      digits = '$dialCode$digits';
    }
    return digits;
  }

  Future<void> _moveTo(
    BuildContext context,
    MaintenanceRequest request,
    MaintenanceStatus next,
  ) async {
    var updated = request.copyWith(status: next);
    if (next == MaintenanceStatus.rejected) {
      final reason = await _askForText(
        context,
        title: 'رفض المطالبة',
        label: 'سبب الرفض الظاهر في السجل',
        action: 'تأكيد الرفض',
      );
      if (reason == null || !context.mounted) return;
      updated = updated.copyWith(
        decisionReason: reason,
        resolution: ClaimResolution.rejected,
      );
    }
    if (next == MaintenanceStatus.completed &&
        request.resolution == ClaimResolution.none) {
      final resolution = await _chooseResolution(context);
      if (resolution == null || !context.mounted) return;
      updated = updated.copyWith(resolution: resolution);
    }
    await AppScope.of(context).saveMaintenanceRequest(updated);
    if (!context.mounted) return;
    final error = AppScope.of(context).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'تم نقل المطالبة إلى «${next.label}».')),
    );
  }

  Future<String?> _askForText(
    BuildContext context, {
    required String title,
    required String label,
    required String action,
  }) async {
    var text = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            onChanged: (value) => setDialogState(() => text = value.trim()),
            decoration: InputDecoration(labelText: label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: text.length < 3
                  ? null
                  : () => Navigator.pop(dialogContext, text),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }

  Future<ClaimResolution?> _chooseResolution(BuildContext context) {
    return showModalBottomSheet<ClaimResolution>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'كيف أُغلقت المطالبة؟',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...ClaimResolution.values
                  .where(
                    (item) =>
                        item != ClaimResolution.none &&
                        item != ClaimResolution.rejected,
                  )
                  .map(
                    (item) => ListTile(
                      minTileHeight: 52,
                      leading: const Icon(Icons.check_circle_outline_rounded),
                      title: Text(item.label),
                      onTap: () => Navigator.pop(sheetContext, item),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClaimEditScreen extends StatefulWidget {
  const ClaimEditScreen({required this.requestId, super.key});

  final String requestId;

  @override
  State<ClaimEditScreen> createState() => _ClaimEditScreenState();
}

class _ClaimEditScreenState extends State<ClaimEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _diagnosis;
  late final TextEditingController _customerNotes;
  late final TextEditingController _internalNotes;
  late final TextEditingController _resolutionNotes;
  ClaimCategory? _category;
  ClaimPriority? _priority;
  ClaimResolution? _resolution;
  String? _assignedTo;
  String? _branchId;
  DateTime? _slaDueAt;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _diagnosis = TextEditingController();
    _customerNotes = TextEditingController();
    _internalNotes = TextEditingController();
    _resolutionNotes = TextEditingController();
  }

  void _initialize(MaintenanceRequest request) {
    if (_initialized) return;
    _initialized = true;
    _category = request.category;
    _priority = request.priority;
    _resolution = request.resolution;
    _assignedTo = request.assignedTo;
    _branchId = request.serviceBranchId;
    _slaDueAt = request.slaDueAt;
    _diagnosis.text = request.diagnosis;
    _customerNotes.text = request.customerNotes;
    _internalNotes.text = request.internalNotes;
    _resolutionNotes.text = request.resolutionNotes;
  }

  @override
  void dispose() {
    _diagnosis.dispose();
    _customerNotes.dispose();
    _internalNotes.dispose();
    _resolutionNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final request = controller.requestById(widget.requestId);
    if (request == null) {
      return const Scaffold(
        body: Center(child: Text('لم تعد المطالبة موجودة.')),
      );
    }
    _initialize(request);
    final activeTeam = controller.team
        .where((member) => member.status == 'active')
        .toList();
    final serviceBranches = controller.branches
        .where((branch) => branch.handlesService)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المطالبة'),
          actions: [
            TextButton(
              onPressed: controller.busy ? null : () => _save(request),
              child: const Text('حفظ'),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
              children: [
                Text(
                  'التصنيف والمسؤول',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ClaimCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'فئة المشكلة'),
                  items: ClaimCategory.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ClaimPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'الأولوية'),
                  items: ClaimPriority.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _priority = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      activeTeam.any((member) => member.userId == _assignedTo)
                      ? _assignedTo!
                      : '',
                  decoration: const InputDecoration(
                    labelText: 'الموظف المسؤول',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('غير معيّن'),
                    ),
                    ...activeTeam.map(
                      (member) => DropdownMenuItem<String>(
                        value: member.userId,
                        child: Text(member.fullName),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(
                    () => _assignedTo = value == null || value.isEmpty
                        ? null
                        : value,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      serviceBranches.any((branch) => branch.id == _branchId)
                      ? _branchId!
                      : '',
                  decoration: const InputDecoration(labelText: 'فرع الخدمة'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('غير محدد'),
                    ),
                    ...serviceBranches.map(
                      (branch) => DropdownMenuItem<String>(
                        value: branch.id,
                        child: Text(branch.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(
                    () => _branchId = value == null || value.isEmpty
                        ? null
                        : value,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickSlaDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _slaDueAt == null
                        ? 'تحديد موعد الاستجابة'
                        : 'موعد الاستجابة: ${formatDate(_slaDueAt!)}',
                  ),
                ),
                const SizedBox(height: 28),
                Text('المعالجة', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diagnosis,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'التشخيص',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ClaimResolution>(
                  initialValue: _resolution,
                  decoration: const InputDecoration(labelText: 'القرار'),
                  items: ClaimResolution.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _resolution = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _resolutionNotes,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'تفاصيل الإصلاح أو الاستبدال',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerNotes,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة تظهر للعميل',
                    helperText: 'لا تكتب هنا معلومات داخلية أو حساسة.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _internalNotes,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة داخلية للفريق',
                    helperText: 'لن تظهر للعميل في البوابة أو الرسائل.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: controller.busy ? null : () => _save(request),
                  icon: controller.busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('حفظ تفاصيل المطالبة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickSlaDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _slaDueAt ?? now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _slaDueAt = selected);
  }

  Future<void> _save(MaintenanceRequest request) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = request.copyWith(
      category: _category,
      priority: _priority,
      resolution: _resolution,
      assignedTo: _assignedTo,
      serviceBranchId: _branchId,
      slaDueAt: _slaDueAt,
      diagnosis: _diagnosis.text.trim(),
      customerNotes: _customerNotes.text.trim(),
      internalNotes: _internalNotes.text.trim(),
      resolutionNotes: _resolutionNotes.text.trim(),
    );
    final controller = AppScope.of(context);
    await controller.saveMaintenanceRequest(updated);
    if (!mounted) return;
    if (controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
      return;
    }
    Navigator.pop(context);
  }
}

class _ClaimHeader extends StatelessWidget {
  const _ClaimHeader({required this.request});

  final MaintenanceRequest request;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  request.issue,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                MaintenanceStatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(
                  icon: Icons.flag_outlined,
                  label: 'أولوية ${request.priority.label}',
                ),
                _MetaPill(
                  icon: Icons.category_outlined,
                  label: request.category.label,
                ),
                if (request.isOverdue)
                  _MetaPill(
                    icon: Icons.warning_amber_rounded,
                    label: 'متأخرة عن الموعد',
                    foreground: colors.error,
                    background: colors.errorContainer,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.request,
    required this.canDecide,
    required this.onMove,
  });

  final MaintenanceRequest request;
  final bool canDecide;
  final ValueChanged<MaintenanceStatus> onMove;

  @override
  Widget build(BuildContext context) {
    final actions = _actions();
    if (actions.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الإجراء التالي',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'حدّث الحالة فور تنفيذ الإجراء ليعرف الفريق أين وصلت المطالبة.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            ...actions.indexed.map((entry) {
              final index = entry.$1;
              final action = entry.$2;
              final button = index == 0
                  ? FilledButton.icon(
                      onPressed: () => onMove(action.$1),
                      icon: Icon(action.$3),
                      label: Text(action.$2),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => onMove(action.$1),
                      icon: Icon(action.$3),
                      label: Text(action.$2),
                    );
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == actions.length - 1 ? 0 : 8,
                ),
                child: button,
              );
            }),
          ],
        ),
      ),
    );
  }

  List<(MaintenanceStatus, String, IconData)> _actions() => switch (request
      .status) {
    MaintenanceStatus.newRequest => [
      (
        MaintenanceStatus.needsReview,
        'بدء مراجعة المطالبة',
        Icons.fact_check_outlined,
      ),
      if (canDecide)
        (MaintenanceStatus.approved, 'قبول المطالبة', Icons.verified_outlined),
    ],
    MaintenanceStatus.needsReview => [
      if (canDecide)
        (MaintenanceStatus.approved, 'قبول المطالبة', Icons.verified_outlined),
      (
        MaintenanceStatus.waitingForCustomer,
        'طلب معلومات من العميل',
        Icons.question_answer_outlined,
      ),
      if (canDecide)
        (MaintenanceStatus.rejected, 'رفض المطالبة', Icons.block_outlined),
    ],
    MaintenanceStatus.approved => [
      (MaintenanceStatus.inProgress, 'بدء المعالجة', Icons.build_outlined),
      (
        MaintenanceStatus.waitingForCustomer,
        'بانتظار العميل',
        Icons.hourglass_top_rounded,
      ),
    ],
    MaintenanceStatus.inProgress => [
      (
        MaintenanceStatus.readyForPickup,
        'تجهيزها للاستلام',
        Icons.inventory_2_outlined,
      ),
      (
        MaintenanceStatus.waitingForCustomer,
        'بانتظار العميل',
        Icons.hourglass_top_rounded,
      ),
      (MaintenanceStatus.completed, 'إكمال المطالبة', Icons.task_alt_rounded),
    ],
    MaintenanceStatus.waitingForCustomer => [
      (
        MaintenanceStatus.inProgress,
        'استئناف المعالجة',
        Icons.play_arrow_rounded,
      ),
    ],
    MaintenanceStatus.readyForPickup => [
      (
        MaintenanceStatus.completed,
        'تأكيد التسليم والإكمال',
        Icons.task_alt_rounded,
      ),
      (MaintenanceStatus.inProgress, 'إعادتها للمعالجة', Icons.build_outlined),
    ],
    MaintenanceStatus.completed => [
      if (canDecide)
        (
          MaintenanceStatus.inProgress,
          'إعادة فتح المطالبة',
          Icons.replay_rounded,
        ),
    ],
    MaintenanceStatus.rejected || MaintenanceStatus.cancelled => [
      if (canDecide)
        (
          MaintenanceStatus.needsReview,
          'إعادة فتح للمراجعة',
          Icons.replay_rounded,
        ),
    ],
  };
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.busy,
    required this.onWhatsApp,
    required this.onCall,
  });

  final bool busy;
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تواصل مع العميل',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'يرسل ضمانك حالة المطالبة ورابط المتابعة بصياغة جاهزة.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onWhatsApp,
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('إرسال عبر واتساب'),
                ),
                OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('اتصال'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AiReviewCard extends StatelessWidget {
  const _AiReviewCard({
    required this.review,
    required this.busy,
    required this.onAnalyze,
    required this.onApply,
  });

  final ClaimAiReview? review;
  final bool busy;
  final VoidCallback onAnalyze;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final value = review;
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'مساعد فرز المطالبة',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: busy ? null : onAnalyze,
              child: Text(value == null ? 'تحليل' : 'إعادة التحليل'),
            ),
            const SizedBox(height: 10),
            if (value == null)
              Text(
                'يلخص وصف العميل ويقترح فئة وأولوية وأسئلة ناقصة. لا يتخذ قراراً ولا يغيّر المطالبة تلقائياً.',
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            else ...[
              Text(value.summary, style: const TextStyle(height: 1.55)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('فئة: ${value.suggestedCategory.label}')),
                  Chip(label: Text('أولوية: ${value.suggestedPriority.label}')),
                  Chip(label: Text('ثقة ${(value.confidence * 100).round()}%')),
                ],
              ),
              if (value.missingInformation.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'معلومات يُفضّل طلبها',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                for (final item in value.missingInformation)
                  Text('• $item', style: const TextStyle(height: 1.5)),
              ],
              if (value.signals.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'إشارات في الوصف: ${value.signals.join('، ')}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                [
                  value.disclaimer,
                  if (value.usage.estimatedCostUsd != null)
                    'التكلفة التقريبية: \$${value.usage.estimatedCostUsd!.toStringAsFixed(4)}',
                  '${value.usage.monthlyUsed}/${value.usage.monthlyLimit} هذا الشهر',
                  if (value.includedAttachments) 'شمل أول ملفين',
                ].join(' • '),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : onApply,
                icon: const Icon(Icons.check_rounded),
                label: const Text('استخدام التصنيف والأولوية بعد المراجعة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (trailing != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: trailing!,
              ),
            ],
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AttachmentsSection extends StatefulWidget {
  const _AttachmentsSection({required this.requestId});

  final String requestId;

  @override
  State<_AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends State<_AttachmentsSection> {
  late Future<List<ClaimAttachment>> _attachments;
  bool _loaded = false;
  String? _openingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _attachments = AppScope.of(
      context,
    ).loadRequestAttachments(widget.requestId);
  }

  @override
  void didUpdateWidget(covariant _AttachmentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestId != widget.requestId) {
      _loaded = true;
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _attachments = AppScope.of(
        context,
      ).loadRequestAttachments(widget.requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClaimAttachment>>(
      future: _attachments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _Section(
              title: 'ملفات العميل',
              children: [
                Semantics(
                  label: 'جاري تحميل ملفات المطالبة',
                  child: const LinearProgressIndicator(),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _Section(
              title: 'ملفات العميل',
              children: [
                Text(
                  'تعذر عرض الملفات الآن. بيانات المطالبة ما زالت محفوظة.',
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ),
              ],
            ),
          );
        }
        final attachments = snapshot.data ?? const <ClaimAttachment>[];
        if (attachments.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _Section(
            title: 'ملفات العميل (${attachments.length})',
            children: [
              for (var index = 0; index < attachments.length; index++) ...[
                _AttachmentTile(
                  attachment: attachments[index],
                  opening: _openingId == attachments[index].id,
                  onOpen: () => _openAttachment(attachments[index]),
                ),
                if (index != attachments.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAttachment(ClaimAttachment attachment) async {
    if (_openingId != null) return;
    setState(() => _openingId = attachment.id);
    try {
      final controller = AppScope.of(context);
      final uri = await controller.createRequestAttachmentLink(
        attachment.storagePath,
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('CLAIM_ATTACHMENT_OPEN_FAILED');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الملف. تحقق من الاتصال ثم حاول مرة أخرى.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.opening,
    required this.onOpen,
  });

  final ClaimAttachment attachment;
  final bool opening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final source = attachment.uploadedByType == 'customer'
        ? 'أرسله العميل'
        : 'أضافه الفريق';
    return Semantics(
      button: true,
      label: 'فتح ${attachment.originalName}، ${attachment.sizeLabel}، $source',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 10,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            attachment.isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.image_outlined,
            color: colors.onPrimaryContainer,
          ),
        ),
        title: Text(
          attachment.originalName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$source · ${attachment.sizeLabel}'),
        trailing: opening
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.open_in_new_rounded),
        onTap: opening ? null : onOpen,
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.ltr = false,
  });

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
          final valueText = Text(
            value,
            textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
            textAlign: ltr ? TextAlign.end : TextAlign.start,
            style: const TextStyle(fontWeight: FontWeight.w600),
          );
          final labelText = Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
          if (constraints.maxWidth < 360 || largeText) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [labelText, const SizedBox(height: 3), valueText],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 112, child: labelText),
              Expanded(child: valueText),
            ],
          );
        },
      ),
    );
  }
}

class _PrivateNote extends StatelessWidget {
  const _PrivateNote({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('ملاحظة داخلية\n$value')),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.date,
    required this.active,
  });

  final String title;
  final DateTime date;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                active ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: active ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 28),
            child: Text(
              formatDate(date),
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.foreground,
    this.background,
  });

  final IconData icon;
  final String label;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = foreground ?? colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background ?? colors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 92,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
