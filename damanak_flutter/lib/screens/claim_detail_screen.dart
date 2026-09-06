import 'package:damanak/l10n/l10n.dart';
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
    L10n.watch(context);
    final controller = AppScope.of(context);
    final request = controller.requestById(requestId);
    final warranty = request == null
        ? null
        : controller.warrantyById(request.warrantyId);
    if (request == null || warranty == null) {
      return Directionality(
        textDirection: Directionality.of(context),
        child: Scaffold(
          body: Center(child: Text(L10n.current.msg47609a0036a9)),
        ),
      );
    }

    final assignee = controller.teamMemberById(request.assignedTo);
    final branch = controller.branches
        .where((item) => item.id == request.serviceBranchId)
        .firstOrNull;
    final canDecide = controller.membership?.role.canManageTeam ?? false;
    final aiReview = controller.claimAiReview(request.id);

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(request.displayNumber),
          actions: [
            IconButton(
              tooltip: L10n.current.msg289a4e72f188,
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
                      title: L10n.current.msg5c4fd79b730c,
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                WarrantyDetailScreen(warrantyId: warranty.id),
                          ),
                        ),
                        child: Text(L10n.current.msg45f73d63ecda),
                      ),
                      children: [
                        _DetailLine(
                          label: L10n.current.msga79e304d96a1,
                          value: warranty.productName,
                        ),
                        _DetailLine(
                          label: L10n.current.msga042411e90be,
                          value: warranty.customerName,
                        ),
                        _DetailLine(
                          label: L10n.current.msg94b59a5125fb,
                          value: warranty.customerPhone,
                          ltr: true,
                        ),
                        if (warranty.serialNumber.isNotEmpty)
                          _DetailLine(
                            label: L10n.current.msg5789f0fed61c,
                            value: warranty.serialNumber,
                            ltr: true,
                          ),
                        _DetailLine(
                          label: L10n.current.msgc246f9ec82e0,
                          value: formatDate(warranty.expiryDate),
                          ltr: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: L10n.current.msg3122792d13c3,
                      children: [
                        _DetailLine(
                          label: L10n.current.msg9099527b2932,
                          value: request.issue,
                        ),
                        _DetailLine(
                          label: L10n.current.msgff61fb213ffc,
                          value: request.category.label,
                        ),
                        _DetailLine(
                          label: L10n.current.msg4c3e5a87f1e4,
                          value: request.priority.label,
                        ),
                        _DetailLine(
                          label: L10n.current.msg64660bb87d89,
                          value: request.channel.label,
                        ),
                        _DetailLine(
                          label: L10n.current.msg5087bf126a06,
                          value:
                              assignee?.fullName ??
                              L10n.current.msg3eed0035cf5d,
                        ),
                        _DetailLine(
                          label: L10n.current.msg7a9ca70461f9,
                          value: branch?.name ?? L10n.current.msg5a0374f3ff5a,
                        ),
                        _DetailLine(
                          label: L10n.current.msg25dad1fc33ec,
                          value: request.slaDueAt == null
                              ? L10n.current.msg5a0374f3ff5a
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
                        title: L10n.current.msgf4222866fc4f,
                        children: [
                          if (request.diagnosis.isNotEmpty)
                            _DetailLine(
                              label: L10n.current.msg490dfdf55a4d,
                              value: request.diagnosis,
                            ),
                          if (request.resolution != ClaimResolution.none)
                            _DetailLine(
                              label: L10n.current.msga881a87897ba,
                              value: request.resolution.label,
                            ),
                          if (request.resolutionNotes.isNotEmpty)
                            _DetailLine(
                              label: L10n.current.msg5f7bb20a6096,
                              value: request.resolutionNotes,
                            ),
                          if (request.decisionReason.isNotEmpty)
                            _DetailLine(
                              label: L10n.current.msg3a1f67eb3acd,
                              value: request.decisionReason,
                            ),
                          if (request.customerNotes.isNotEmpty)
                            _DetailLine(
                              label: L10n.current.msg187e287ce6a2,
                              value: request.customerNotes,
                            ),
                          if (request.internalNotes.isNotEmpty)
                            _PrivateNote(value: request.internalNotes),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _Section(
                      title: L10n.current.msg9dca2d96d1fb,
                      children: [
                        _TimelineItem(
                          title: L10n.current.msgff42cb797bed,
                          date: request.createdAt,
                          active: true,
                        ),
                        if (request.approvedAt != null)
                          _TimelineItem(
                            title: L10n.current.msge8b8e1ebd4c9,
                            date: request.approvedAt!,
                            active: true,
                          ),
                        if (request.completedAt != null)
                          _TimelineItem(
                            title: L10n.current.msg87dcc5eac968,
                            date: request.completedAt!,
                            active: true,
                          ),
                        _TimelineItem(
                          title: L10n.current.msg272095a56e1a(
                            request.status.label,
                          ),
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
          title: Text(L10n.current.msg6c8cfd0ad30c),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L10n.current.msg38f2b4b43147),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: includeAttachments,
                onChanged: (value) =>
                    setDialogState(() => includeAttachments = value),
                title: Text(L10n.current.msg37034d66e11b),
                subtitle: Text(L10n.current.msgc27e8c37d669),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(L10n.current.msg9a30dc2a96b8),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(L10n.current.msg925fb72780c9),
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
          AppScope.of(context).errorMessage ?? L10n.current.msg9487432c9fff,
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
        title: Text(L10n.current.msg1e02dc8d7a10),
        content: Text(
          L10n.current.msgd67a5f3bc0a6(
            review.suggestedCategory.label,
            review.suggestedPriority.label,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(L10n.current.msgcb822418a29d),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(L10n.current.msg43db76ef30fb),
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
        subject: L10n.current.msgf1930614c4d7(request.displayNumber),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _callCustomer(BuildContext context, Warranty warranty) async {
    final phone = warranty.customerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L10n.current.msg596ce1253414)));
      return;
    }
    final opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L10n.current.msg25a522457d01)));
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
            ? L10n.current.msgfa1249723b2f
            : L10n.current.msg124a5c699fda(request.customerNotes),
      MaintenanceStatus.readyForPickup => L10n.current.msgeae0b27e6196,
      MaintenanceStatus.completed => L10n.current.msg68816aa17db1,
      MaintenanceStatus.rejected =>
        request.decisionReason.isEmpty
            ? L10n.current.msgb69362a124f3
            : L10n.current.msg7784bea7df92(request.decisionReason),
      _ => L10n.current.msg294f46432382,
    };
    return [
      L10n.current.msg650293d55384(warranty.customerName),
      L10n.current.msg53e7b570927c(request.displayNumber, warranty.productName),
      L10n.current.msge93630401caa(request.status.label),
      nextLine,
      if (link != null) L10n.current.msg8982e1b5df75(link),
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
        title: L10n.current.msgbfd935693039,
        label: L10n.current.msg81821da6baa6,
        action: L10n.current.msgb5170558cd41,
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
      SnackBar(
        content: Text(error ?? L10n.current.msg30b901c9e93a(next.label)),
      ),
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
              child: Text(L10n.current.msg9a30dc2a96b8),
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
                L10n.current.msg5a3aee566b06,
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
    L10n.watch(context);
    final controller = AppScope.of(context);
    final request = controller.requestById(widget.requestId);
    if (request == null) {
      return Scaffold(body: Center(child: Text(L10n.current.msg47609a0036a9)));
    }
    _initialize(request);
    final activeTeam = controller.team
        .where((member) => member.status == 'active')
        .toList();
    final serviceBranches = controller.branches
        .where((branch) => branch.handlesService)
        .toList();

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(L10n.current.msg55c952196d59),
          actions: [
            TextButton(
              onPressed: controller.busy ? null : () => _save(request),
              child: Text(L10n.current.msgddfcaf9d0144),
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
                  L10n.current.msg5e1ee5296293,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ClaimCategory>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: L10n.current.msg4ca027e90eec,
                  ),
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
                  decoration: InputDecoration(
                    labelText: L10n.current.msg4c3e5a87f1e4,
                  ),
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
                  decoration: InputDecoration(
                    labelText: L10n.current.msg998f15a5fe62,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text(L10n.current.msg3eed0035cf5d),
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
                  decoration: InputDecoration(
                    labelText: L10n.current.msg7a9ca70461f9,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text(L10n.current.msg5a0374f3ff5a),
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
                        ? L10n.current.msgffc4a70a2e55
                        : L10n.current.msgcc99d577732a(formatDate(_slaDueAt!)),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  L10n.current.msg6423b630e42d,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diagnosis,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: L10n.current.msg490dfdf55a4d,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ClaimResolution>(
                  initialValue: _resolution,
                  decoration: InputDecoration(
                    labelText: L10n.current.msga881a87897ba,
                  ),
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
                  decoration: InputDecoration(
                    labelText: L10n.current.msg55819d8e482e,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerNotes,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: L10n.current.msgb8b4ea8855db,
                    helperText: L10n.current.msg8a2f45135daa,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _internalNotes,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: L10n.current.msgd314b2cf9e37,
                    helperText: L10n.current.msgfcd7430fe5b8,
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
                  label: Text(L10n.current.msg7946854a61d8),
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
    L10n.watch(context);
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
                  label: L10n.current.msg3faa17b063fb(request.priority.label),
                ),
                _MetaPill(
                  icon: Icons.category_outlined,
                  label: request.category.label,
                ),
                if (request.isOverdue)
                  _MetaPill(
                    icon: Icons.warning_amber_rounded,
                    label: L10n.current.msg7c83012b2845,
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
    L10n.watch(context);
    final actions = _actions();
    if (actions.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              L10n.current.msg1e6f7259e388,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              L10n.current.msg67d310d7fe93,
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

  List<(MaintenanceStatus, String, IconData)> _actions() =>
      switch (request.status) {
        MaintenanceStatus.newRequest => [
          (
            MaintenanceStatus.needsReview,
            L10n.current.msgc21b0e6e74dd,
            Icons.fact_check_outlined,
          ),
          if (canDecide)
            (
              MaintenanceStatus.approved,
              L10n.current.msg338a6e3f6418,
              Icons.verified_outlined,
            ),
        ],
        MaintenanceStatus.needsReview => [
          if (canDecide)
            (
              MaintenanceStatus.approved,
              L10n.current.msg338a6e3f6418,
              Icons.verified_outlined,
            ),
          (
            MaintenanceStatus.waitingForCustomer,
            L10n.current.msgaa54e8581470,
            Icons.question_answer_outlined,
          ),
          if (canDecide)
            (
              MaintenanceStatus.rejected,
              L10n.current.msgbfd935693039,
              Icons.block_outlined,
            ),
        ],
        MaintenanceStatus.approved => [
          (
            MaintenanceStatus.inProgress,
            L10n.current.msg4a80c8f233d4,
            Icons.build_outlined,
          ),
          (
            MaintenanceStatus.waitingForCustomer,
            L10n.current.msg7c4b128da66a,
            Icons.hourglass_top_rounded,
          ),
        ],
        MaintenanceStatus.inProgress => [
          (
            MaintenanceStatus.readyForPickup,
            L10n.current.msg2050aebbb97f,
            Icons.inventory_2_outlined,
          ),
          (
            MaintenanceStatus.waitingForCustomer,
            L10n.current.msg7c4b128da66a,
            Icons.hourglass_top_rounded,
          ),
          (
            MaintenanceStatus.completed,
            L10n.current.msga9d4e8c51205,
            Icons.task_alt_rounded,
          ),
        ],
        MaintenanceStatus.waitingForCustomer => [
          (
            MaintenanceStatus.inProgress,
            L10n.current.msg5fac64e31dbc,
            Icons.play_arrow_rounded,
          ),
        ],
        MaintenanceStatus.readyForPickup => [
          (
            MaintenanceStatus.completed,
            L10n.current.msg9288c5b199d6,
            Icons.task_alt_rounded,
          ),
          (
            MaintenanceStatus.inProgress,
            L10n.current.msg47bddbd85cb4,
            Icons.build_outlined,
          ),
        ],
        MaintenanceStatus.completed => [
          if (canDecide)
            (
              MaintenanceStatus.inProgress,
              L10n.current.msg247abd28fa31,
              Icons.replay_rounded,
            ),
        ],
        MaintenanceStatus.rejected || MaintenanceStatus.cancelled => [
          if (canDecide)
            (
              MaintenanceStatus.needsReview,
              L10n.current.msgca1904f3e709,
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
    L10n.watch(context);
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              L10n.current.msg2e933f0f15e9,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              L10n.current.msg645e646e9931,
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
                  label: Text(L10n.current.msg8378428d3fd2),
                ),
                OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined),
                  label: Text(L10n.current.msg606af07c67cb),
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
    L10n.watch(context);
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
                    L10n.current.msg6c8cfd0ad30c,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: busy ? null : onAnalyze,
              child: Text(
                value == null
                    ? L10n.current.msg698fbdcd6041
                    : L10n.current.msgea3f993611e0,
              ),
            ),
            const SizedBox(height: 10),
            if (value == null)
              Text(
                L10n.current.msg5b26587358fe,
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            else ...[
              Text(value.summary, style: const TextStyle(height: 1.55)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      L10n.current.msg34d6e570eb34(
                        value.suggestedCategory.label,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      L10n.current.msg7d3942248372(
                        value.suggestedPriority.label,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      L10n.current.msg5e7f0a12ab07(
                        (value.confidence * 100).round(),
                      ),
                    ),
                  ),
                ],
              ),
              if (value.missingInformation.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  L10n.current.msg05217dcdcd72,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                for (final item in value.missingInformation)
                  Text('• $item', style: const TextStyle(height: 1.5)),
              ],
              if (value.signals.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  L10n.current.msg81ba469a03ce(
                    value.signals.join(L10n.current.msg11735aabd336),
                  ),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                [
                  value.disclaimer,
                  if (value.usage.estimatedCostUsd != null)
                    L10n.current.msg38874c5d26da(
                      value.usage.estimatedCostUsd!.toStringAsFixed(4),
                    ),
                  L10n.current.msg358b2fe4d59b(
                    value.usage.monthlyUsed,
                    value.usage.monthlyLimit,
                  ),
                  if (value.includedAttachments) L10n.current.msgbe2a9d82914d,
                ].join(' • '),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : onApply,
                icon: const Icon(Icons.check_rounded),
                label: Text(L10n.current.msg34f0233acfe7),
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
    L10n.watch(context);
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
    L10n.watch(context);
    return FutureBuilder<List<ClaimAttachment>>(
      future: _attachments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _Section(
              title: L10n.current.msg5c0e56a68d71,
              children: [
                Semantics(
                  label: L10n.current.msg5a1e4eb1db5e,
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
              title: L10n.current.msg5c0e56a68d71,
              children: [
                Text(
                  L10n.current.msgd449fde59c1b,
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(L10n.current.msg14d5786f2e64),
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
            title: L10n.current.msgd30fcea255a6(attachments.length),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L10n.current.msg63c84e95aaf4)));
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
    L10n.watch(context);
    final colors = context.colors;
    final source = attachment.uploadedByType == 'customer'
        ? L10n.current.msg374c0387e1ae
        : L10n.current.msge06f2fcdb931;
    return Semantics(
      button: true,
      label: L10n.current.msg4470a29e2903(
        attachment.originalName,
        attachment.sizeLabel,
        source,
      ),
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
    L10n.watch(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) >= 20;
          final valueText = Text(
            value,
            textDirection: ltr ? TextDirection.ltr : Directionality.of(context),
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
    L10n.watch(context);
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
          Expanded(child: Text(L10n.current.msg2624f3008a34(value))),
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
    L10n.watch(context);
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
    L10n.watch(context);
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
