import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/app_notification.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
import 'claim_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final items = controller.notifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            tooltip: 'تفضيلات الإشعارات',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationPreferencesScreen(),
              ),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshNotifications,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            const MessageBanner(),
            if (items.isEmpty)
              const _EmptyNotifications()
            else
              for (final item in items) ...[
                _NotificationTile(
                  item: item,
                  onTap: () => _openNotification(context, item),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    AppNotification item,
  ) async {
    final controller = AppScope.of(context);
    await controller.markNotificationRead(item.id);
    if (!context.mounted || item.requestId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClaimDetailScreen(requestId: item.requestId!),
      ),
    );
  }
}

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late bool _claimCreated;
  late bool _claimAssigned;
  late bool _claimOverdue;
  late bool _readyForPickup;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final value = AppScope.of(context).notificationPreferences;
    _claimCreated = value.claimCreated;
    _claimAssigned = value.claimAssigned;
    _claimOverdue = value.claimOverdue;
    _readyForPickup = value.readyForPickup;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('تفضيلات الإشعارات')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              const MessageBanner(),
              Text(
                'تنبيهات العمل فقط',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'هذه التفضيلات تخص مركز الإشعارات داخل ضمانك. لن نرسل عروضاً تسويقية، ولن نطلب إذن إشعارات النظام قبل تهيئة الإرسال الآمن.',
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    _PreferenceSwitch(
                      title: 'مطالبة جديدة',
                      subtitle: 'عندما يرسل عميل مطالبة أو يسجلها الموظف.',
                      value: _claimCreated,
                      onChanged: (value) =>
                          setState(() => _claimCreated = value),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _PreferenceSwitch(
                      title: 'إسناد مطالبة إليّ',
                      subtitle: 'عندما يحدد المدير أنك المسؤول عنها.',
                      value: _claimAssigned,
                      onChanged: (value) =>
                          setState(() => _claimAssigned = value),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _PreferenceSwitch(
                      title: 'تجاوز وقت الخدمة',
                      subtitle: 'للمطالبات المفتوحة التي تجاوزت موعد المتابعة.',
                      value: _claimOverdue,
                      onChanged: (value) =>
                          setState(() => _claimOverdue = value),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _PreferenceSwitch(
                      title: 'جاهزة للاستلام',
                      subtitle: 'لتذكير الفريق بالتواصل مع العميل.',
                      value: _readyForPickup,
                      onChanged: (value) =>
                          setState(() => _readyForPickup = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: controller.busy ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(controller.busy ? 'جارٍ الحفظ…' : 'حفظ التفضيلات'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    await AppScope.of(context).saveNotificationPreferences(
      NotificationPreferences(
        claimCreated: _claimCreated,
        claimAssigned: _claimAssigned,
        claimOverdue: _claimOverdue,
        readyForPickup: _readyForPickup,
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      color: item.isUnread ? colors.primaryContainer : colors.surface,
      child: ListTile(
        minTileHeight: 76,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: item.isUnread
              ? colors.primary
              : colors.surfaceContainerHighest,
          foregroundColor: item.isUnread
              ? colors.onPrimary
              : colors.onSurfaceVariant,
          child: Icon(_eventIcon(item.type)),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isUnread ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            if (item.body.isNotEmpty) item.body,
            _relativeTime(item.createdAt),
          ].join('\n'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: item.requestId == null
            ? null
            : const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    minTileHeight: 68,
    value: value,
    onChanged: onChanged,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
    child: Column(
      children: [
        Icon(
          Icons.notifications_none_rounded,
          size: 52,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(height: 14),
        Text(
          'لا توجد تنبيهات الآن',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'ستظهر هنا المطالبات الجديدة وما أُسند إليك وما أصبح جاهزاً للاستلام.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
      ],
    ),
  );
}

IconData _eventIcon(NotificationEventType type) => switch (type) {
  NotificationEventType.claimCreated => Icons.add_task_rounded,
  NotificationEventType.claimAssigned => Icons.assignment_ind_outlined,
  NotificationEventType.claimOverdue => Icons.schedule_rounded,
  NotificationEventType.readyForPickup => Icons.inventory_rounded,
  NotificationEventType.system => Icons.info_outline_rounded,
};

String _relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) return 'الآن';
  if (difference.inHours < 1) return 'منذ ${difference.inMinutes} دقيقة';
  if (difference.inDays < 1) return 'منذ ${difference.inHours} ساعة';
  if (difference.inDays < 7) return 'منذ ${difference.inDays} يوم';
  return '${value.toLocal().day}/${value.toLocal().month}/${value.toLocal().year}';
}
