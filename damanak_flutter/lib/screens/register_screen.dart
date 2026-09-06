import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../core/date_utils.dart';
import '../models/register.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final currency = controller.store!.currencyCode;
    return Scaffold(
      appBar: AppBar(title: Text(L10n.current.msgd127ef29f50d)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                const MessageBanner(),
                Text(
                  L10n.current.msg037b9f8c678c,
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                if (controller.registerSessions.isEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: Text(L10n.current.msg740bccec6c9a)),
                    ),
                  )
                else
                  ...controller.registerSessions.map(
                    (session) =>
                        _RegisterCard(session: session, currency: currency),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({required this.session, required this.currency});
  final CashRegisterSession session;
  final String currency;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final branch = controller.branches
        .where((item) => item.id == session.branchId)
        .firstOrNull;
    final open = session.status == RegisterStatus.open;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: open
                        ? context.colors.primaryContainer
                        : context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    open ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                    color: open
                        ? context.colors.primary
                        : context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch?.name ?? L10n.current.msg28adde4ba2a8,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${L10n.knownLabel(open ? 'مفتوح' : 'مغلق')} • ${formatDate(session.openedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (open)
                  OutlinedButton(
                    onPressed: () => _close(context),
                    child: Text(L10n.current.msgca90c297b099),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _Value(
                  label: L10n.current.msg7123bef9e335,
                  value: formatMoney(session.openingCash, currency),
                ),
                _Value(
                  label: L10n.current.msg5b897d3bb02f,
                  value: formatMoney(session.cashSales, currency),
                ),
                _Value(
                  label: L10n.current.msg8d0a03c36d7f,
                  value: formatMoney(session.expectedCash, currency),
                ),
                if (!open)
                  _Value(
                    label: L10n.current.msg0b5254487af9,
                    value: formatMoney(session.variance, currency),
                    alert: session.variance != 0,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _close(BuildContext context) async {
    final input = TextEditingController(text: '${session.expectedCash}');
    final value = await showDialog<num>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(L10n.current.msg395c4b980330),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: L10n.current.msgafbc17090735,
            helperText: L10n.current.msgcad9e227c5b8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(L10n.current.msg9a30dc2a96b8),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, num.tryParse(input.text)),
            child: Text(L10n.current.msg92f294545557),
          ),
        ],
      ),
    );
    input.dispose();
    if (value != null && context.mounted) {
      await AppScope.of(
        context,
      ).closeRegister(sessionId: session.id, closingCash: value);
    }
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, this.alert = false});
  final String label;
  final String value;
  final bool alert;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
      ),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: alert ? context.colors.error : null,
        ),
      ),
    ],
  );
}
