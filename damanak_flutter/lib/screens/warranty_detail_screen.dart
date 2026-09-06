import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../core/date_utils.dart';
import '../models/account.dart';
import '../models/branch.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/status_chip.dart';
import 'claim_detail_screen.dart';

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
  bool _sharing = false;
  Uri? _publicLink;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final warranty = controller.warrantyById(widget.warrantyId);

    if (warranty == null) {
      return Directionality(
        textDirection: Directionality.of(context),
        child: Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(L10n.current.msg9edf4b8f634f)),
        ),
      );
    }

    final requests = controller.requestsForWarranty(warranty.id);
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.justCreated
                ? L10n.current.msgc7a6e0fdfb63
                : L10n.current.msgeaf7dd727edb,
          ),
          actions: controller.membership!.role.canManageTeam
              ? [
                  IconButton(
                    tooltip: L10n.current.msg0d505fe3d181,
                    onPressed: () => _confirmDelete(warranty),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ]
              : null,
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
                            onPressed: _sharing
                                ? null
                                : () => _shareWarranty(warranty),
                            icon: _sharing
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.ios_share_rounded),
                            label: Text(
                              _sharing
                                  ? L10n.current.msgbef58a3f774f
                                  : L10n.current.msgb884b4ed524c,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Semantics(
                          button: true,
                          label: _showQr
                              ? L10n.current.msg6a1ac0e46c80
                              : L10n.current.msg39b324587aad,
                          child: Tooltip(
                            message: _showQr
                                ? L10n.current.msg6a1ac0e46c80
                                : L10n.current.msg39b324587aad,
                            child: OutlinedButton(
                              onPressed: _sharing
                                  ? null
                                  : () => _toggleQr(warranty),
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
                        child: _QrPanel(
                          warranty: warranty,
                          publicLink: _publicLink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            L10n.current.msg0678c3efbff7,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openMaintenanceDialog(warranty),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(L10n.current.msg946f0256003d),
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
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ClaimDetailScreen(requestId: request.id),
                              ),
                            ),
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
                                '${request.displayNumber} • ${formatDate(request.createdAt)}',
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
    setState(() => _sharing = true);
    final controller = AppScope.of(context);
    final link = await _loadPublicLink(warranty);
    if (!mounted) return;
    final profile = controller.profile;
    final storeLine = [
      profile.name,
      profile.city,
    ].where((value) => value.trim().isNotEmpty).join(' - ');
    final text = L10n.current
        .msg7449b113696b(
          storeLine,
          warranty.productName,
          warranty.customerName,
          warranty.displayNumber,
          warranty.invoiceNumber.isEmpty
              ? L10n.current.msgc190381bd30c
              : warranty.invoiceNumber,
          formatDate(warranty.purchaseDate),
          formatDate(warranty.expiryDate),
          warranty.statusAt().label,
          formatMoney(warranty.saleTotal, warranty.currencyCode),
          warranty.paymentMethod.label,
          warranty.notes.isEmpty
              ? ''
              : L10n.current.msg36310b3301dc(warranty.notes),
          link == null ? '' : L10n.current.msg16a4cd7b6137(link),
        )
        .trim();
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: L10n.current.msg328999e4edef(warranty.displayNumber),
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _toggleQr(Warranty warranty) async {
    if (_showQr) {
      setState(() => _showQr = false);
      return;
    }
    setState(() => _sharing = true);
    await _loadPublicLink(warranty);
    if (!mounted) return;
    setState(() {
      _sharing = false;
      _showQr = true;
    });
  }

  Future<Uri?> _loadPublicLink(Warranty warranty) async {
    if (_publicLink != null) return _publicLink;
    final controller = AppScope.of(context);
    if (controller.isDemo) return null;
    final link = await controller.createWarrantyShareLink(warranty.id);
    if (mounted && link != null) setState(() => _publicLink = link);
    return link;
  }

  Future<void> _openMaintenanceDialog(Warranty warranty) async {
    var issueText = '';
    final issue = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(L10n.current.msg961e982ce839),
          content: TextField(
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            onChanged: (value) =>
                setDialogState(() => issueText = value.trim()),
            decoration: InputDecoration(
              labelText: L10n.current.msgcabed10e2a69,
              hintText: L10n.current.msg8a9a1bb9e453,
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(L10n.current.msg9a30dc2a96b8),
            ),
            FilledButton(
              onPressed: issueText.length < 3
                  ? null
                  : () => Navigator.pop(dialogContext, issueText),
              child: Text(L10n.current.msg4ff1d76c66f8),
            ),
          ],
        ),
      ),
    );
    if (issue == null || !mounted) {
      return;
    }
    await AppScope.of(
      context,
    ).addMaintenanceRequest(warrantyId: warranty.id, issue: issue);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L10n.current.msgb10fea1f3532)));
    }
  }

  Future<void> _confirmDelete(Warranty warranty) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(L10n.current.msgb2dd8fca21fc),
        content: Text(L10n.current.msgc7fffa55b3d8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(L10n.current.msg9a30dc2a96b8),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(L10n.current.msg59ca629220a6),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await AppScope.of(context).deleteWarranty(warranty.id);
    if (mounted) Navigator.of(context).pop();
  }
}

class _WarrantyDocument extends StatelessWidget {
  const _WarrantyDocument({required this.warranty});

  final Warranty warranty;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final status = warranty.statusAt();
    final colors = context.colors;
    final controller = AppScope.of(context);
    final profile = controller.profile;
    StoreBranch? branch;
    for (final item in controller.branches) {
      if (item.id == warranty.branchId) {
        branch = item;
        break;
      }
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(23),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.onPrimary.withValues(alpha: 0.72),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    color: colors.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L10n.current.msga46b81c8cb9b,
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        L10n.current.msg5c2168d73c92(profile.name),
                        style: TextStyle(
                          color: colors.onPrimary.withValues(alpha: 0.76),
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
                          Text(
                            L10n.current.msg637134e8ceab,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
                _DetailRow(
                  label: L10n.current.msg70771eb8320f,
                  value: warranty.customerName,
                ),
                _DetailRow(
                  label: L10n.current.msg6dbe8474b01b,
                  value: warranty.customerPhone,
                  ltr: true,
                ),
                _DetailRow(
                  label: L10n.current.msga97505f65ec3,
                  value: warranty.displayNumber,
                  ltr: true,
                ),
                if (warranty.invoiceNumber.isNotEmpty)
                  _DetailRow(
                    label: L10n.current.msg239cb47cd98d,
                    value: warranty.invoiceNumber,
                    ltr: true,
                  ),
                if (branch != null)
                  _DetailRow(
                    label: L10n.current.msg8a706d30e0ed,
                    value: branch.name,
                  ),
                if (warranty.barcode.isNotEmpty)
                  _DetailRow(
                    label: L10n.current.msg501881931acd,
                    value: warranty.barcode,
                    ltr: true,
                  ),
                if (warranty.serialNumber.isNotEmpty)
                  _DetailRow(
                    label: L10n.current.msg5789f0fed61c,
                    value: warranty.serialNumber,
                    ltr: true,
                  ),
                _DetailRow(
                  label: L10n.current.msgdc24afda1b22,
                  value: formatDate(warranty.purchaseDate),
                  ltr: true,
                ),
                _DetailRow(
                  label: L10n.current.msgc246f9ec82e0,
                  value: formatDate(warranty.expiryDate),
                  ltr: true,
                ),
                const Divider(height: 28),
                Text(
                  L10n.current.msg3aa676d8a2e7,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                _DetailRow(
                  label: L10n.current.msg2d37565e6fe3,
                  value: formatMoney(
                    warranty.saleSubtotal,
                    warranty.currencyCode,
                  ),
                ),
                if (warranty.discountAmount > 0)
                  _DetailRow(
                    label: L10n.current.msgb593a6457673,
                    value: formatMoney(
                      warranty.discountAmount,
                      warranty.currencyCode,
                    ),
                  ),
                _DetailRow(
                  label: L10n.current.msgbaed6e999960,
                  value: formatMoney(warranty.saleTotal, warranty.currencyCode),
                ),
                _DetailRow(
                  label: L10n.current.msgae2d60052976,
                  value: warranty.paymentMethod.label,
                ),
                if (warranty.notes.isNotEmpty) ...[
                  const Divider(height: 28),
                  Text(
                    L10n.current.msg90c177abd603,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
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
                        ? colors.errorContainer
                        : colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    warrantyRemainingLabel(warranty.expiryDate),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: status == WarrantyStatus.expired
                          ? colors.onErrorContainer
                          : colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
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
    L10n.watch(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: ltr
                  ? TextDirection.ltr
                  : Directionality.of(context),
              textAlign: ltr ? TextAlign.end : TextAlign.start,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.warranty, required this.publicLink});

  final Warranty warranty;
  final Uri? publicLink;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final colors = context.colors;
    final qrData =
        publicLink?.toString() ??
        'DAMANAK|${warranty.displayNumber}|${warranty.productName}|${formatDate(warranty.expiryDate)}|${warranty.statusAt().label}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Semantics(
              label: L10n.current.msg7229d4c7ae58(warranty.displayNumber),
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
              publicLink == null
                  ? L10n.current.msgae8d0843c053
                  : L10n.current.msg132503af2da2,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              publicLink == null
                  ? L10n.current.msg2dcc255c88be
                  : L10n.current.msg1fd32ccb11f3,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
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
    L10n.watch(context);
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              L10n.current.msg5a5d5c520635,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
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
    L10n.watch(context);
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.handyman_outlined, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                L10n.current.msg6f250c704cee,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
