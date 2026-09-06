import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../models/integration.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
import 'subscription_screen.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadIntegrations();
    });
  }

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final plan = controller.subscription!.plan;
    final isOwner = controller.membership!.role.canManageSubscription;
    return Scaffold(
      appBar: AppBar(title: Text(L10n.current.msgc82e99cb1b8b)),
      body: RefreshIndicator(
        onRefresh: controller.loadIntegrations,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
          children: [
            const MessageBanner(),
            Text(
              L10n.current.msg32e4c4bf1ab4,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              L10n.current.msg2ef89624fb92,
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (!isOwner)
              _AccessCard(text: L10n.current.msg69c475f1bbb5)
            else ...[
              _IntegrationSection(
                title: 'API',
                subtitle: plan.apiAccess
                    ? L10n.current.msgd006819c83d0
                    : L10n.current.msg9aec3e68d086,
                enabled: plan.apiAccess,
                actionLabel: L10n.current.msg13b60161bea7,
                onAction: () => _createApiKey(context),
                child: controller.apiKeys.isEmpty
                    ? _InlineEmpty(text: L10n.current.msg4e1d662db6f8)
                    : Column(
                        children: [
                          for (final key in controller.apiKeys)
                            _ApiKeyTile(
                              value: key,
                              onRevoke: key.isActive
                                  ? () => _revokeApiKey(context, key)
                                  : null,
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 14),
              _IntegrationSection(
                title: 'Webhooks',
                subtitle: plan.webhookAccess
                    ? L10n.current.msgd849a0413238
                    : L10n.current.msg9aec3e68d086,
                enabled: plan.webhookAccess,
                actionLabel: L10n.current.msg93f3c248a561,
                onAction: () => _createWebhook(context),
                child: controller.webhooks.isEmpty
                    ? _InlineEmpty(text: L10n.current.msgdb126e6fa615)
                    : Column(
                        children: [
                          for (final hook in controller.webhooks)
                            _WebhookTile(
                              value: hook,
                              busy: controller.busy,
                              onChanged: (active) =>
                                  controller.setWebhookActive(hook.id, active),
                            ),
                        ],
                      ),
              ),
              if (!plan.apiAccess || !plan.webhookAccess) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: Text(L10n.current.msg7be81ee52e15),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createApiKey(BuildContext context) async {
    final result = await showDialog<_ApiKeyDraft>(
      context: context,
      builder: (_) => const _ApiKeyDialog(),
    );
    if (result == null || !context.mounted) return;
    final created = await AppScope.of(
      context,
    ).createApiKey(name: result.name, scopes: result.scopes);
    if (created != null && context.mounted) {
      await _showSecret(
        context,
        title: L10n.current.msg130e05c33a70,
        secret: created.secret,
        warning: L10n.current.msgc4fed8918459,
      );
    }
  }

  Future<void> _createWebhook(BuildContext context) async {
    final result = await showDialog<_WebhookDraft>(
      context: context,
      builder: (_) => const _WebhookDialog(),
    );
    if (result == null || !context.mounted) return;
    final created = await AppScope.of(
      context,
    ).createWebhook(endpointUrl: result.url, events: result.events);
    if (created != null && context.mounted) {
      await _showSecret(
        context,
        title: L10n.current.msgbd4e16d06de0,
        secret: created.secret,
        warning: L10n.current.msg679e6cf2d464,
      );
    }
  }

  Future<void> _revokeApiKey(BuildContext context, ApiKeyInfo key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(L10n.current.msg5ce7c147d834),
        content: Text(L10n.current.msg3c4870c1d279(key.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(L10n.current.msgcb822418a29d),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(L10n.current.msgfb5485cbbc6e),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AppScope.of(context).revokeApiKey(key.id);
    }
  }

  Future<void> _showSecret(
    BuildContext context, {
    required String title,
    required String secret,
    required String warning,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(warning),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectionArea(
                child: Text(secret, textDirection: TextDirection.ltr),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: secret));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(L10n.current.msg48b2aff2b1a3)),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(L10n.current.msg29a0e2739a92),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(L10n.current.msg28da90313e7e),
          ),
        ],
      ),
    );
  }
}

class _IntegrationSection extends StatelessWidget {
  const _IntegrationSection({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: enabled ? onAction : null,
              icon: Icon(enabled ? Icons.add_rounded : Icons.lock_outline),
              label: Text(actionLabel),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _ApiKeyTile extends StatelessWidget {
  const _ApiKeyTile({required this.value, required this.onRevoke});

  final ApiKeyInfo value;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      value.isActive ? Icons.key_rounded : Icons.key_off_outlined,
      color: value.isActive ? context.colors.primary : context.colors.outline,
    ),
    title: Text(value.name),
    subtitle: Text(
      L10n.current.msg711625369e11(value.keyPrefix, value.scopes.length),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.end,
    ),
    trailing: onRevoke == null
        ? Text(L10n.current.msg616d302cb016)
        : IconButton(
            tooltip: L10n.current.msgfb5485cbbc6e,
            onPressed: onRevoke,
            icon: const Icon(Icons.block_rounded),
          ),
  );
}

class _WebhookTile extends StatelessWidget {
  const _WebhookTile({
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final WebhookInfo value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    value: value.isActive,
    onChanged: busy ? null : onChanged,
    title: Text(
      value.endpointUrl,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(value.events.join(' • ')),
  );
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog();

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _name = TextEditingController();
  bool _warranties = true;
  bool _claimsRead = false;
  bool _claimsWrite = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(L10n.current.msg76526f5838b3),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 80,
            decoration: InputDecoration(
              labelText: L10n.current.msg478eee91c22d,
            ),
          ),
          CheckboxListTile(
            value: _warranties,
            onChanged: (value) => setState(() => _warranties = value ?? false),
            title: Text(L10n.current.msg20e1047902e4),
          ),
          CheckboxListTile(
            value: _claimsRead,
            onChanged: (value) => setState(() => _claimsRead = value ?? false),
            title: Text(L10n.current.msgf60ce278fc14),
          ),
          CheckboxListTile(
            value: _claimsWrite,
            onChanged: (value) => setState(() => _claimsWrite = value ?? false),
            title: Text(L10n.current.msg779a27aba7f5),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(L10n.current.msg9a30dc2a96b8),
      ),
      FilledButton(
        onPressed: () {
          final scopes = [
            if (_warranties) 'warranties:read',
            if (_claimsRead) 'claims:read',
            if (_claimsWrite) 'claims:write',
          ];
          if (_name.text.trim().length < 2 || scopes.isEmpty) return;
          Navigator.pop(context, _ApiKeyDraft(_name.text.trim(), scopes));
        },
        child: Text(L10n.current.msga820f3590d36),
      ),
    ],
  );
}

class _WebhookDialog extends StatefulWidget {
  const _WebhookDialog();

  @override
  State<_WebhookDialog> createState() => _WebhookDialogState();
}

class _WebhookDialogState extends State<_WebhookDialog> {
  final _url = TextEditingController();
  bool _created = true;
  bool _updated = true;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(L10n.current.msge401fff86fca),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _url,
            autofocus: true,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: L10n.current.msgb3895826cf8a,
              hintText: 'https://example.com/damanak',
            ),
          ),
          CheckboxListTile(
            value: _created,
            onChanged: (value) => setState(() => _created = value ?? false),
            title: Text(L10n.current.msg946f0256003d),
          ),
          CheckboxListTile(
            value: _updated,
            onChanged: (value) => setState(() => _updated = value ?? false),
            title: Text(L10n.current.msga8c00baf4c19),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(L10n.current.msg9a30dc2a96b8),
      ),
      FilledButton(
        onPressed: () {
          final uri = Uri.tryParse(_url.text.trim());
          final events = [
            if (_created) 'claim.created',
            if (_updated) 'claim.updated',
          ];
          if (uri?.scheme != 'https' || uri!.host.isEmpty || events.isEmpty) {
            return;
          }
          Navigator.pop(context, _WebhookDraft(_url.text.trim(), events));
        },
        child: Text(L10n.current.msga820f3590d36),
      ),
    ],
  );
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(18), child: Text(text)),
  );
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(text, style: TextStyle(color: context.colors.onSurfaceVariant)),
  );
}

class _ApiKeyDraft {
  const _ApiKeyDraft(this.name, this.scopes);
  final String name;
  final List<String> scopes;
}

class _WebhookDraft {
  const _WebhookDraft(this.url, this.events);
  final String url;
  final List<String> events;
}
