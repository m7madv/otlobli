import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../models/subscription.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  Future<void> _redeem(BuildContext context) async {
    final code = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل رمز اشتراك'),
        content: TextField(
          controller: code,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
          decoration: const InputDecoration(
            labelText: 'رمز التفعيل',
            hintText: 'DMN-PLUS-XXXX',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (code.text.trim().isNotEmpty) {
                Navigator.of(context).pop(code.text.trim());
              }
            },
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );
    code.dispose();
    if (value != null && context.mounted) {
      await AppScope.of(context).redeemSubscriptionCode(value);
    }
  }

  Future<void> _requestPlan(BuildContext context, PlanInfo plan) async {
    final phone = TextEditingController(
      text: AppScope.of(context).store!.phone,
    );
    var cycle = 'yearly';
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'طلب خطة ${plan.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              Text(
                'هذه الخطوة تسجّل طلبك؛ لا تخصم أي مبلغ من داخل التطبيق.',
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'monthly', label: Text('شهري')),
                  ButtonSegment(value: 'yearly', label: Text('سنوي')),
                ],
                selected: {cycle},
                onSelectionChanged: (value) =>
                    setModalState(() => cycle = value.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'رقم التواصل'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (phone.text.trim().length >= 7) {
                      Navigator.of(context).pop((cycle, phone.text.trim()));
                    }
                  },
                  child: const Text('إرسال طلب الاشتراك'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    phone.dispose();
    if (result != null && context.mounted) {
      await AppScope.of(context).requestSubscription(
        planId: plan.id,
        billingCycle: result.$1,
        contactPhone: result.$2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = context.colors;
    final subscription = controller.subscription!;
    final canManage = controller.membership!.role.canManageSubscription;
    return Scaffold(
      appBar: AppBar(title: const Text('الاشتراك والاستخدام')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              const MessageBanner(),
              _CurrentPlan(subscription: subscription),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'الخطط المتاحة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (canManage)
                    TextButton.icon(
                      onPressed: controller.busy
                          ? null
                          : () => _redeem(context),
                      icon: const Icon(Icons.key_rounded, size: 18),
                      label: const Text('رمز تفعيل'),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'الأسعار أدناه تُدار من قاعدة النظام ويمكن تعديلها قبل الإطلاق التجاري.',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth >= 760
                      ? (constraints.maxWidth - 20) / 3
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: controller.plans
                        .map(
                          (plan) => SizedBox(
                            width: width,
                            child: _PlanCard(
                              plan: plan,
                              current: plan.id == subscription.plan.id,
                              canManage: canManage,
                              onRequest: () => _requestPlan(context, plan),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 18),
              const _BillingNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPlan extends StatelessWidget {
  const _CurrentPlan({required this.subscription});

  final SubscriptionInfo subscription;

  @override
  Widget build(BuildContext context) {
    final ratio = subscription.plan.monthlyWarranties == 0
        ? 0.0
        : (subscription.usedWarranties / subscription.plan.monthlyWarranties)
              .clamp(0.0, 1.0);
    final statusLabel = switch (subscription.status) {
      'trialing' => 'فترة تجريبية',
      'active' => 'فعّال',
      'past_due' => 'بانتظار التجديد',
      _ => 'متوقف',
    };
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'خطة ${subscription.plan.name}',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${subscription.remainingWarranties}',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'ضماناً متبقياً هذا الشهر',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${subscription.usedWarranties}/${subscription.plan.monthlyWarranties} مستخدم',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${subscription.plan.maxMembers} أعضاء كحد أقصى',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.current,
    required this.canManage,
    required this.onRequest,
  });

  final PlanInfo plan;
  final bool current;
  final bool canManage;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      color: current ? colors.primaryContainer : colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (current)
                  Icon(Icons.check_circle_rounded, color: colors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${plan.monthlyPrice} ر.س',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            Text(
              'شهرياً',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 14),
            _PlanFeature(text: '${plan.monthlyWarranties} ضماناً كل شهر'),
            _PlanFeature(text: '${plan.maxMembers} حسابات للفريق'),
            const _PlanFeature(text: 'المنتجات والصيانة وسجل العمليات'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: !canManage || current ? null : onRequest,
                child: Text(current ? 'الخطة الحالية' : 'طلب هذه الخطة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(Icons.check_rounded, size: 17, color: colors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _BillingNote extends StatelessWidget {
  const _BillingNote();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'حالياً يعمل التفعيل برمز اشتراك أو بطلب تواصل. الدفع الإلكتروني يحتاج حساب تاجر واختيار بوابة مناسبة للدولة قبل ربطه؛ التطبيق لا يعرض عملية دفع وهمية.',
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
