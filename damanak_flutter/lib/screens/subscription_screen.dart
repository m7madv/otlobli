import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _selectedPlanId;
  String? _selectionSignature;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final subscription = AppScope.of(context).subscription;
    if (subscription == null) return;
    final signature = [
      subscription.id,
      subscription.plan.id,
      subscription.billingCycle,
      subscription.billingProvider,
      subscription.periodEndsAt?.toIso8601String(),
    ].join(':');
    if (_selectionSignature == signature) return;
    _selectionSignature = signature;
    _selectedPlanId = subscription.plan.id;
    _cycle = switch (subscription.billingCycle) {
      'monthly' => BillingCycle.monthly,
      'yearly' => BillingCycle.yearly,
      _ => BillingCycle.yearly,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = context.colors;
    final subscription = controller.subscription!;
    final plans = controller.plans;
    final selectedPlanId = plans.any((plan) => plan.id == _selectedPlanId)
        ? _selectedPlanId!
        : plans.any((plan) => plan.id == subscription.plan.id)
        ? subscription.plan.id
        : plans.isEmpty
        ? null
        : plans.first.id;
    final selectedPlan = selectedPlanId == null
        ? null
        : plans.firstWhere((plan) => plan.id == selectedPlanId);
    final canManage = controller.membership!.role.canManageSubscription;
    final currentProvider = StoreBillingPlatformText.fromValue(
      subscription.billingProvider,
    );
    final providerConflict =
        subscription.hasUnexpiredStorePeriod &&
        currentProvider != null &&
        controller.storeBillingPlatform != StoreBillingPlatform.unavailable &&
        currentProvider != controller.storeBillingPlatform;
    final storeBusy = const {
      StoreBillingState.loading,
      StoreBillingState.purchasing,
      StoreBillingState.restoring,
      StoreBillingState.pending,
    }.contains(controller.storeBillingState);
    final restoreBusy = const {
      StoreBillingState.loading,
      StoreBillingState.purchasing,
      StoreBillingState.restoring,
    }.contains(controller.storeBillingState);

    return Scaffold(
      appBar: AppBar(title: const Text('الاشتراك والفوترة')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              const MessageBanner(),
              _CurrentPlan(
                subscription: subscription,
                platform: currentProvider ?? controller.storeBillingPlatform,
                onManage: canManage && subscription.isStoreSubscription
                    ? controller.openStoreSubscriptionManagement
                    : null,
                onRestore:
                    canManage &&
                        !restoreBusy &&
                        !providerConflict &&
                        !controller.isDemo
                    ? controller.restoreStorePurchases
                    : null,
                canManage: canManage,
              ),
              if (providerConflict) ...[
                const SizedBox(height: 12),
                _ProviderConflictNotice(provider: currentProvider),
              ],
              const SizedBox(height: 12),
              const _RecordContinuityNotice(),
              const SizedBox(height: 12),
              _StoreStatus(
                state: controller.storeBillingState,
                platform: controller.storeBillingPlatform,
                message: controller.storeBillingMessage,
                onRetry: storeBusy ? null : controller.refreshStoreProducts,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قارن الباقات',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'السعر والعملة النهائيان يأتيان من متجر جهازك، وليس من قيم محفوظة داخل التطبيق.',
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
              if (selectedPlan != null) ...[
                SegmentedButton<String>(
                  key: const ValueKey('subscription-plan-picker'),
                  segments: [
                    for (final plan in plans)
                      ButtonSegment<String>(
                        value: plan.id,
                        label: Text(plan.name),
                        icon: plan.id == subscription.plan.id
                            ? const Icon(Icons.check_rounded, size: 17)
                            : null,
                      ),
                  ],
                  selected: {selectedPlan.id},
                  onSelectionChanged: (value) =>
                      setState(() => _selectedPlanId = value.first),
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                _PlanCard(
                  key: ValueKey('subscription-plan-${selectedPlan.id}'),
                  plan: selectedPlan,
                  offer: controller.storeOffer(selectedPlan.id, _cycle),
                  current: selectedPlan.id == subscription.plan.id,
                  sameStoreSelection:
                      subscription.isStoreSubscription &&
                      subscription.isUsable &&
                      currentProvider == controller.storeBillingPlatform &&
                      selectedPlan.id == subscription.plan.id &&
                      subscription.billingCycle == _cycle.value,
                  canBuy:
                      canManage &&
                      !storeBusy &&
                      !providerConflict &&
                      !controller.isDemo &&
                      controller.storeBillingState == StoreBillingState.ready,
                  onBuy: (offer) => _confirmPurchase(
                    context,
                    controller.purchaseSubscription,
                    subscription,
                    offer,
                  ),
                ),
              ] else
                const _MissingPlansNotice(),
              const SizedBox(height: 12),
              const _BillingTerms(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPurchase(
    BuildContext context,
    ValueChanged<StoreProductOffer> onConfirmed,
    SubscriptionInfo current,
    StoreProductOffer offer,
  ) async {
    final isDowngrade =
        DamanakStoreCatalog.planRank(offer.planId) <
        DamanakStoreCatalog.planRank(current.plan.id);
    final changesCycle =
        current.billingCycle != null &&
        current.billingCycle != offer.cycle.value;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('تأكيد اختيار الاشتراك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'من ${current.plan.name} إلى ${_planName(offer.planId)} • '
              '${offer.cycle.label}',
              style: Theme.of(dialogContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '${offer.localizedPrice} حسب متجر التطبيقات. '
              'يعرض المتجر السعر والعملة وموعد تطبيق التغيير النهائي قبل التأكيد.',
            ),
            if (isDowngrade) ...[
              const SizedBox(height: 10),
              const Text(
                'تنبيه: خفض الباقة يقلل حدود الضمانات والفريق والفروع، وقد يوقف مزايا الباقة الأعلى بعد تطبيق التغيير.',
              ),
            ] else if (changesCycle) ...[
              const SizedBox(height: 10),
              const Text(
                'ستتغير دورة الفوترة. راجع تاريخ التجديد الظاهر في نافذة المتجر قبل الإقرار.',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('المتابعة إلى المتجر'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) onConfirmed(offer);
  }

  String _planName(String id) => switch (id) {
    'starter' => 'بداية',
    'growth' => 'نمو',
    'scale' => 'توسع',
    _ => id,
  };
}

class _ProviderConflictNotice extends StatelessWidget {
  const _ProviderConflictNotice({required this.provider});

  final StoreBillingPlatform? provider;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.colors.primaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      'الاشتراك الحالي مرتبط بـ${provider?.label ?? 'متجر آخر'}. '
      'أدره أو أوقف تجديده هناك أولاً؛ يمنع ضمانك بدء اشتراك ثانٍ من متجر هذا الجهاز أثناء بقاء الفترة الحالية.',
      style: TextStyle(color: context.colors.onPrimaryContainer, height: 1.5),
    ),
  );
}

class _MissingPlansNotice extends StatelessWidget {
  const _MissingPlansNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.colors.outlineVariant),
    ),
    child: const Text(
      'تعذر تحميل بيانات الباقات. ارجع إلى الحساب ثم افتح الاشتراك مجدداً.',
    ),
  );
}

class _CurrentPlan extends StatelessWidget {
  const _CurrentPlan({
    required this.subscription,
    required this.platform,
    required this.onManage,
    required this.onRestore,
    required this.canManage,
  });

  final SubscriptionInfo subscription;
  final StoreBillingPlatform platform;
  final VoidCallback? onManage;
  final VoidCallback? onRestore;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final ratio = subscription.plan.monthlyWarranties == 0
        ? 0.0
        : (subscription.usedWarranties / subscription.plan.monthlyWarranties)
              .clamp(0.0, 1.0);
    final statusLabel = switch (subscription.status) {
      'trialing' => 'تجربة مجانية',
      'active' => subscription.autoRenews ? 'فعّال ويتجدد' : 'فعّال',
      'past_due' => 'مشكلة في التجديد',
      _ => 'متوقف',
    };
    final cycleLabel = switch (subscription.billingCycle) {
      'monthly' => 'شهري',
      'yearly' => 'سنوي',
      _ => null,
    };
    final periodLabel = subscription.status == 'trialing'
        ? 'تنتهي التجربة في'
        : subscription.autoRenews
        ? 'يتجدد في'
        : 'ينتهي في';
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'خطة ${subscription.plan.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
            ],
          ),
          if (subscription.status == 'trialing') ...[
            const SizedBox(height: 10),
            Text(
              'تطبق التجربة حدود باقة ${subscription.plan.name}: '
              '${subscription.plan.monthlyWarranties} ضمان شهرياً و'
              '${subscription.plan.maxMembers} حسابات للفريق.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
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
              Text(
                subscription.plan.branchLabel,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              if (subscription.isStoreSubscription)
                Text(
                  [?cycleLabel, platform.label].join(' • '),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              if (subscription.periodEndsAt != null)
                Text(
                  '$periodLabel ${formatDate(subscription.periodEndsAt!)}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions = constraints.maxWidth < 470;
              final actions = <Widget>[
                if (onManage != null)
                  OutlinedButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text('إدارة الاشتراك في ${platform.label}'),
                  ),
                OutlinedButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('استعادة المشتريات'),
                ),
              ];
              if (stackActions) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      actions[index],
                      if (index != actions.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                );
              }
              return Wrap(spacing: 8, runSpacing: 8, children: actions);
            },
          ),
          if (!canManage) ...[
            const SizedBox(height: 8),
            Text(
              'الشراء والاستعادة وإدارة الاشتراك متاحة لمالك المتجر.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordContinuityNotice extends StatelessWidget {
  const _RecordContinuityNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          'سجل الضمانات محفوظ. بعد انتهاء الاشتراك تبقى الضمانات السابقة متاحة للعرض والمتابعة، ويتوقف إصدار ضمانات جديدة.',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.inventory_2_outlined, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سجل ضماناتك يبقى محفوظاً',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'بعد انتهاء الاشتراك تبقى الضمانات السابقة متاحة للعرض والمتابعة؛ يتوقف إصدار ضمانات جديدة فقط.',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        state == StoreBillingState.purchasing ||
        state == StoreBillingState.restoring;
    final title = switch (state) {
      StoreBillingState.ready => '${platform.label} متصل',
      StoreBillingState.pending => 'الدفعة قيد المعالجة',
      StoreBillingState.loading => 'جارٍ جلب أسعار المتجر',
      StoreBillingState.purchasing => 'نافذة المتجر مفتوحة',
      StoreBillingState.restoring => 'جارٍ التحقق من المشتريات السابقة',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              ],
            ),
            if (onRetry != null && state == StoreBillingState.unavailable)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: onRetry,
                    child: const Text('إعادة المحاولة'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    super.key,
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
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: current || plan.isRecommended
              ? colors.primary
              : colors.outlineVariant,
          width: current || plan.isRecommended ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
                if (plan.isRecommended)
                  _PlanBadge(label: 'موصى بها', emphasized: true),
                if (current)
                  const _PlanBadge(
                    label: 'الخطة الحالية',
                    icon: Icons.check_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.audience,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Text(
              offer?.localizedPrice ?? 'بانتظار سعر المتجر',
              style: TextStyle(
                color: available ? colors.onSurface : colors.onSurfaceVariant,
                fontSize: available ? 24 : 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              offer == null
                  ? 'لا يُعرض أي سعر محلي بديل.'
                  : '${offer!.cycle.label} • السعر والعملة من المتجر',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _PlanMetric(
                  icon: Icons.verified_user_outlined,
                  text: '${plan.monthlyWarranties} ضمان/شهر',
                ),
                _PlanMetric(
                  icon: Icons.group_outlined,
                  text: '${plan.maxMembers} أعضاء',
                ),
                _PlanMetric(icon: Icons.store_outlined, text: plan.branchLabel),
                _PlanMetric(
                  icon: Icons.auto_awesome_outlined,
                  text: '${plan.monthlyAiImports} تحليل ملف/شهر',
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text('تشمل', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...plan.features.map((feature) => _PlanFeature(text: feature)),
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
                            : available
                            ? 'اختيار الفوترة ${offer!.cycle.label.toLowerCase()}'
                            : 'سعر المتجر غير متاح',
                      ),
                    )
                  : FilledButton(
                      onPressed: available && canBuy
                          ? () => onBuy(offer!)
                          : null,
                      child: Text(
                        available
                            ? 'اختيار ${plan.name}'
                            : 'سعر المتجر غير متاح',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.label, this.icon, this.emphasized = false});

  final String label;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = emphasized ? colors.onPrimary : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized ? colors.primary : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 14, color: foreground),
            ),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: colors.primary),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.check_rounded,
            size: 17,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, height: 1.45)),
        ),
      ],
    ),
  );
}

class _BillingTerms extends StatelessWidget {
  const _BillingTerms();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'تعرض نافذة المتجر السعر والعملة والفترة النهائية قبل التأكيد. يتجدد الاشتراك تلقائياً ويمكنك إدارته أو إلغاؤه من App Store أو Google Play. لا تُفعّل الدفعات المعلّقة. الحصة الشهرية هي الأساس، وقد يتيح النظام هامش تشغيل تلقائياً حتى 10% لتجنب توقف العمل المفاجئ.',
        style: TextStyle(
          color: context.colors.onSurfaceVariant,
          fontSize: 11,
          height: 1.55,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 2,
        children: [
          TextButton(
            onPressed: () => _openLegalPage(context, _termsUri),
            child: const Text('شروط الاستخدام'),
          ),
          TextButton(
            onPressed: () => _openLegalPage(context, _privacyUri),
            child: const Text('سياسة الخصوصية'),
          ),
        ],
      ),
    ],
  );

  static final Uri _termsUri = Uri.parse(
    'https://exxayzlklvgeyqhvtzgi.supabase.co/functions/v1/legal/terms',
  );
  static final Uri _privacyUri = Uri.parse(
    'https://exxayzlklvgeyqhvtzgi.supabase.co/functions/v1/legal/privacy',
  );

  Future<void> _openLegalPage(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الصفحة. حاول مرة أخرى.')),
      );
    }
  }
}
