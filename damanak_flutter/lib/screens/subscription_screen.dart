import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/account.dart';
import '../models/store_billing.dart';
import '../models/subscription.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  BillingCycle _cycle = BillingCycle.yearly;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = context.colors;
    final subscription = controller.subscription!;
    final canManage = controller.membership!.role.canManageSubscription;
    final storeBusy = const {
      StoreBillingState.loading,
      StoreBillingState.purchasing,
      StoreBillingState.pending,
    }.contains(controller.storeBillingState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراك والفوترة'),
        actions: [
          IconButton(
            tooltip: 'استعادة المشتريات',
            onPressed: !canManage || storeBusy
                ? null
                : controller.restoreStorePurchases,
            icon: const Icon(Icons.restore_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              const MessageBanner(),
              _CurrentPlan(
                subscription: subscription,
                platform: controller.storeBillingPlatform,
                onManage: subscription.isStoreSubscription
                    ? controller.openStoreSubscriptionManagement
                    : null,
              ),
              const SizedBox(height: 14),
              _StoreStatus(
                state: controller.storeBillingState,
                platform: controller.storeBillingPlatform,
                message: controller.storeBillingMessage,
                onRetry: storeBusy ? null : controller.refreshStoreProducts,
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر الخطة',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'السعر والعملة يظهران مباشرةً من متجر جهازك.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                  final cyclePicker = SegmentedButton<BillingCycle>(
                    segments: const [
                      ButtonSegment(
                        value: BillingCycle.monthly,
                        label: Text('شهري'),
                      ),
                      ButtonSegment(
                        value: BillingCycle.yearly,
                        label: Text('سنوي'),
                      ),
                    ],
                    selected: {_cycle},
                    onSelectionChanged: (value) =>
                        setState(() => _cycle = value.first),
                    showSelectedIcon: false,
                  );
                  if (constraints.maxWidth < 440) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        heading,
                        const SizedBox(height: 12),
                        cyclePicker,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: 12),
                      cyclePicker,
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
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
                              offer: controller.storeOffer(plan.id, _cycle),
                              current: plan.id == subscription.plan.id,
                              sameStoreSelection:
                                  subscription.isStoreSubscription &&
                                  subscription.isUsable &&
                                  plan.id == subscription.plan.id &&
                                  subscription.billingCycle == _cycle.value,
                              canBuy:
                                  canManage && !storeBusy && !controller.isDemo,
                              onBuy: controller.purchaseSubscription,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 18),
              _PurchasePath(platform: controller.storeBillingPlatform),
              const SizedBox(height: 12),
              const _BillingTerms(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPlan extends StatelessWidget {
  const _CurrentPlan({
    required this.subscription,
    required this.platform,
    required this.onManage,
  });

  final SubscriptionInfo subscription;
  final StoreBillingPlatform platform;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final ratio = subscription.plan.monthlyWarranties == 0
        ? 0.0
        : (subscription.usedWarranties / subscription.plan.monthlyWarranties)
              .clamp(0.0, 1.0);
    final statusLabel = switch (subscription.status) {
      'trialing' => 'فترة تجريبية',
      'active' => subscription.autoRenews ? 'فعّال ويتجدد' : 'فعّال',
      'past_due' => 'مشكلة في التجديد',
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
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${subscription.remainingWarranties}',
            style: const TextStyle(
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
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${subscription.usedWarranties}/${subscription.plan.monthlyWarranties} مستخدم',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              Text(
                '${subscription.plan.maxMembers} أعضاء كحد أقصى',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              if (subscription.periodEndsAt != null)
                Text(
                  'الفترة حتى ${formatDate(subscription.periodEndsAt!)}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (onManage != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text('إدارة الاشتراك في ${platform.label}'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoreStatus extends StatelessWidget {
  const _StoreStatus({
    required this.state,
    required this.platform,
    required this.message,
    required this.onRetry,
  });

  final StoreBillingState state;
  final StoreBillingPlatform platform;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loading =
        state == StoreBillingState.loading ||
        state == StoreBillingState.purchasing;
    final title = switch (state) {
      StoreBillingState.ready => '${platform.label} متصل',
      StoreBillingState.pending => 'الدفعة قيد المعالجة',
      StoreBillingState.loading => 'جارٍ جلب أسعار المتجر',
      StoreBillingState.purchasing => 'نافذة المتجر مفتوحة',
      _ => 'الفوترة غير متاحة الآن',
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                state == StoreBillingState.ready
                    ? Icons.verified_user_outlined
                    : Icons.storefront_outlined,
                color: colors.primary,
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      message!,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRetry != null && state == StoreBillingState.unavailable)
              TextButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.offer,
    required this.current,
    required this.sameStoreSelection,
    required this.canBuy,
    required this.onBuy,
  });

  final PlanInfo plan;
  final StoreProductOffer? offer;
  final bool current;
  final bool sameStoreSelection;
  final bool canBuy;
  final ValueChanged<StoreProductOffer> onBuy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final available = offer != null;
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
              offer?.localizedPrice ?? 'غير متاح',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            Text(
              offer == null
                  ? 'فعّل المنتج في لوحة المتجر'
                  : 'تجديد ${offer!.cycle.label.toLowerCase()} تلقائي',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 14),
            _PlanFeature(text: '${plan.monthlyWarranties} ضماناً كل شهر'),
            _PlanFeature(text: '${plan.maxMembers} حسابات للفريق'),
            const _PlanFeature(text: 'كل الفروع والمخزون ونقطة البيع'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: current
                  ? OutlinedButton(
                      onPressed: available && canBuy && !sameStoreSelection
                          ? () => onBuy(offer!)
                          : null,
                      child: Text(
                        sameStoreSelection
                            ? 'الخطة الحالية'
                            : 'تغيير دورة الخطة',
                      ),
                    )
                  : FilledButton(
                      onPressed: available && canBuy
                          ? () => onBuy(offer!)
                          : null,
                      child: const Text('اشترك من المتجر'),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Icon(Icons.check_rounded, size: 17, color: context.colors.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _PurchasePath extends StatelessWidget {
  const _PurchasePath({required this.platform});

  final StoreBillingPlatform platform;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const steps = [
      ('1', 'المتجر', 'يعرض السعر ويستلم موافقتك'),
      ('2', 'التحقق', 'الخادم يتحقق من الإيصال'),
      ('3', 'التفعيل', 'تُفتح الخطة بعد نجاح التحقق'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مسار دفع واحد وواضح',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 3),
          Text(
            'لا يستقبل ضمانك بيانات بطاقتك؛ تتم الفوترة داخل ${platform.label}.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      step.$1,
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 58,
                    child: Text(
                      step.$2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step.$3,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingTerms extends StatelessWidget {
  const _BillingTerms();

  @override
  Widget build(BuildContext context) => Text(
    'بالاشتراك توافق على أن يتجدد الاشتراك تلقائياً وفق السعر والفترة المعروضين في نافذة المتجر. يمكنك الإلغاء أو تغيير وسيلة الدفع من إعدادات اشتراكات App Store أو Google Play. لا تُفعّل الدفعات المعلّقة، ويمكنك استخدام «استعادة المشتريات» عند تغيير الجهاز.',
    style: TextStyle(
      color: context.colors.onSurfaceVariant,
      fontSize: 11,
      height: 1.55,
    ),
  );
}
