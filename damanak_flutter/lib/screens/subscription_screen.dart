import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../features/subscriptions/domain/subscription_flow.dart';
import '../models/account.dart';
import '../models/store_billing.dart';
import '../models/subscription.dart';
import '../state/app_scope.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({this.requiredActivation = false, super.key});

  final bool requiredActivation;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  BillingCycle _cycle = BillingCycle.monthly;
  String? _selectedPlanId;
  String? _selectionSignature;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    final subscription = controller.subscription;
    if (subscription == null) return;
    final paidPlans =
        controller.plans
            .where((plan) => plan.id != 'free')
            .toList(growable: false)
          ..sort(
            (left, right) => DamanakStoreCatalog.planRank(
              left.id,
            ).compareTo(DamanakStoreCatalog.planRank(right.id)),
          );
    final signature = [
      subscription.id,
      subscription.plan.id,
      subscription.status,
      subscription.billingCycle,
      subscription.billingProvider,
      subscription.periodEndsAt?.toIso8601String(),
      paidPlans.map((plan) => plan.id).join(','),
    ].join(':');
    if (_selectionSignature == signature) return;
    _selectionSignature = signature;
    _selectedPlanId = subscription.hasUnexpiredStorePeriod
        ? subscription.plan.id
        : 'starter';
    _cycle = switch (subscription.billingCycle) {
      'monthly' when subscription.hasUnexpiredStorePeriod =>
        BillingCycle.monthly,
      'yearly' when subscription.hasUnexpiredStorePeriod => BillingCycle.yearly,
      _ => BillingCycle.monthly,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final subscription = controller.subscription;
    final membership = controller.membership;
    if (subscription == null || membership == null) {
      return _SubscriptionLoadingScaffold(
        requiredActivation: widget.requiredActivation,
      );
    }

    final plans =
        controller.plans
            .where((plan) => plan.id != 'free')
            .toList(growable: false)
          ..sort(
            (left, right) => DamanakStoreCatalog.planRank(
              left.id,
            ).compareTo(DamanakStoreCatalog.planRank(right.id)),
          );
    final hasCurrentPlan = subscription.hasUnexpiredStorePeriod;
    final selectedPlanId = plans.any((plan) => plan.id == _selectedPlanId)
        ? _selectedPlanId
        : plans.any((plan) => hasCurrentPlan && plan.id == subscription.plan.id)
        ? subscription.plan.id
        : plans.any((plan) => plan.id == 'starter')
        ? 'starter'
        : plans.isEmpty
        ? null
        : plans.first.id;
    final selectedPlan = selectedPlanId == null
        ? null
        : plans.firstWhere((plan) => plan.id == selectedPlanId);
    final selectedOffer = selectedPlan == null
        ? null
        : controller.storeOffer(selectedPlan.id, _cycle);
    final selectedDecision = selectedPlan == null
        ? null
        : _subscriptionDecision(
            subscription: subscription,
            offer: selectedOffer,
            platform: controller.storeBillingPlatform,
          );
    final canManage = membership.role.canManageSubscription;
    final currentProvider = StoreBillingPlatformText.fromValue(
      subscription.billingProvider,
    );
    final providerConflict =
        subscription.hasUnexpiredStorePeriod &&
        currentProvider != null &&
        controller.storeBillingPlatform != StoreBillingPlatform.unavailable &&
        currentProvider != controller.storeBillingPlatform;
    final billingOperationInProgress =
        controller.storeBillingOperationInProgress;
    final storeBusy =
        const {
          StoreBillingState.loading,
          StoreBillingState.purchasing,
          StoreBillingState.restoring,
          StoreBillingState.pending,
        }.contains(controller.storeBillingState) ||
        billingOperationInProgress;
    final restoreBusy =
        const {
          StoreBillingState.loading,
          StoreBillingState.purchasing,
          StoreBillingState.restoring,
        }.contains(controller.storeBillingState) ||
        billingOperationInProgress;
    final primaryEnabled =
        selectedPlan != null &&
        selectedOffer != null &&
        selectedDecision?.allowed == true &&
        canManage &&
        !storeBusy &&
        !providerConflict &&
        !controller.isDemo &&
        controller.storeBillingState == StoreBillingState.ready;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.requiredActivation ? 'تفعيل المتجر' : 'الاشتراك'),
        actions: [
          if (widget.requiredActivation)
            IconButton(
              onPressed: controller.busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _InitialPaymentAccountScreen(),
                      ),
                    ),
              tooltip: 'الحساب',
              icon: const Icon(Icons.account_circle_outlined),
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 28),
            children: [
              _SubscriptionSummary(
                subscription: subscription,
                activationRequired: widget.requiredActivation,
                canManage: canManage,
                platform: currentProvider,
              ),
              _SubscriptionStatusNotice(
                state: controller.storeBillingState,
                platform: controller.storeBillingPlatform,
                billingMessage: controller.storeBillingMessage,
                errorMessage: controller.errorMessage,
                noticeMessage: controller.noticeMessage,
                providerConflict: providerConflict,
                currentProvider: currentProvider,
                onDismiss: controller.clearMessages,
                onRetry: storeBusy
                    ? null
                    : () {
                        controller.clearMessages();
                        controller.refreshStoreProducts();
                      },
              ),
              const SizedBox(height: 22),
              Text(
                hasCurrentPlan ? 'الباقات والترقية' : 'اختر الباقة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'الأسعار والعملات من ${controller.storeBillingPlatform.label}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              _BillingCyclePicker(
                cycle: _cycle,
                onChanged: (cycle) => setState(() => _cycle = cycle),
              ),
              const SizedBox(height: 14),
              if (plans.isEmpty)
                const _EmptyPlansNotice()
              else
                _PlanChoiceList(
                  plans: plans,
                  subscription: subscription,
                  platform: controller.storeBillingPlatform,
                  cycle: _cycle,
                  selectedPlanId: selectedPlanId,
                  offerForPlan: (planId) =>
                      controller.storeOffer(planId, _cycle),
                  onSelected: (planId) =>
                      setState(() => _selectedPlanId = planId),
                ),
              const SizedBox(height: 18),
              const _BillingTerms(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _SubscriptionActionBar(
        primaryLabel: _primaryActionLabel(
          plan: selectedPlan,
          offer: selectedOffer,
          decision: selectedDecision,
          state: controller.storeBillingState,
          canManage: canManage,
          providerConflict: providerConflict,
        ),
        primaryBusy:
            controller.storeBillingState == StoreBillingState.purchasing,
        primaryEnabled: primaryEnabled,
        onPrimary: primaryEnabled
            ? () => _startPurchase(
                context,
                subscription: subscription,
                targetPlan: selectedPlan,
                offer: selectedOffer,
                decision: selectedDecision!,
                platform: controller.storeBillingPlatform,
                onConfirmed: controller.purchaseSubscription,
              )
            : null,
        restoreBusy:
            controller.storeBillingState == StoreBillingState.restoring,
        onRestore:
            canManage && !restoreBusy && !providerConflict && !controller.isDemo
            ? controller.restoreStorePurchases
            : null,
        onManage: canManage && subscription.isStoreSubscription
            ? controller.openStoreSubscriptionManagement
            : null,
      ),
    );
  }

  String _primaryActionLabel({
    required PlanInfo? plan,
    required StoreProductOffer? offer,
    required SubscriptionDecision? decision,
    required StoreBillingState state,
    required bool canManage,
    required bool providerConflict,
  }) {
    if (!canManage) return 'متاح لمالك المتجر فقط';
    if (providerConflict) return 'أدر الاشتراك من متجره الحالي';
    if (state == StoreBillingState.purchasing) {
      return 'جارٍ فتح متجر التطبيقات…';
    }
    if (state == StoreBillingState.pending) return 'بانتظار تأكيد المتجر';
    if (plan == null) return 'اختر باقة';
    if (offer == null) return 'السعر غير متاح';
    if (decision == null) return 'اختر باقة';
    return switch (decision.kind) {
      SubscriptionDecisionKind.start => 'الاشتراك في ${plan.name}',
      SubscriptionDecisionKind.upgrade => 'الترقية إلى ${plan.name}',
      SubscriptionDecisionKind.cycleChange =>
        'التغيير إلى ${offer.cycle.label}',
      SubscriptionDecisionKind.blocked => switch (decision.blockedReason) {
        SubscriptionBlockReason.alreadyActive => 'باقتك الحالية',
        SubscriptionBlockReason.downgrade => 'الباقة غير متاحة',
        SubscriptionBlockReason.providerConflict =>
          'أدر الاشتراك من متجره الحالي',
        SubscriptionBlockReason.stateUnknown || null => 'تعذر التحقق من الباقة',
      },
    };
  }

  Future<void> _startPurchase(
    BuildContext context, {
    required SubscriptionInfo subscription,
    required PlanInfo targetPlan,
    required StoreProductOffer offer,
    required SubscriptionDecision decision,
    required StoreBillingPlatform platform,
    required ValueChanged<StoreProductOffer> onConfirmed,
  }) async {
    if (!decision.allowed) return;
    if (decision.kind == SubscriptionDecisionKind.start) {
      onConfirmed(offer);
      return;
    }
    final confirmed = await _showTransitionSheet(
      context,
      subscription: subscription,
      targetPlan: targetPlan,
      offer: offer,
      decision: decision,
      platform: platform,
    );
    if (confirmed == true && context.mounted) onConfirmed(offer);
  }

  Future<bool?> _showTransitionSheet(
    BuildContext context, {
    required SubscriptionInfo subscription,
    required PlanInfo targetPlan,
    required StoreProductOffer offer,
    required SubscriptionDecision decision,
    required StoreBillingPlatform platform,
  }) {
    final remainingAfterUpgrade =
        (targetPlan.monthlyWarranties - subscription.usedWarranties).clamp(
          0,
          targetPlan.monthlyWarranties,
        );
    final title = switch (decision.kind) {
      SubscriptionDecisionKind.upgrade => 'تأكيد الترقية',
      SubscriptionDecisionKind.cycleChange => 'تأكيد تغيير الفوترة',
      _ => 'تأكيد الاشتراك',
    };
    final description = switch (decision.kind) {
      SubscriptionDecisionKind.upgrade =>
        'يرتفع حد هذا الشهر من ${subscription.plan.monthlyWarranties} إلى '
            '${targetPlan.monthlyWarranties} ضماناً. استخدمت '
            '${subscription.usedWarranties}، فيصبح المتاح '
            '$remainingAfterUpgrade. لا تُجمع حصص الباقات.',
      SubscriptionDecisionKind.cycleChange =>
        'تتغير دورة فوترة باقة ${targetPlan.name} إلى ${offer.cycle.label}. '
            'تبقى الحصة واستخدام هذا الشهر كما هما، ويحدد المتجر موعد تطبيق '
            'التغيير النهائي.',
      _ => 'سيعرض المتجر تفاصيل الاشتراك النهائية قبل التأكيد.',
    };
    final actionLabel = switch (decision.kind) {
      SubscriptionDecisionKind.upgrade => 'المتابعة للترقية',
      SubscriptionDecisionKind.cycleChange => 'متابعة تغيير الفوترة',
      _ => 'المتابعة للاشتراك',
    };
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(description),
            const SizedBox(height: 10),
            Text(
              '${offer.localizedPrice} من ${platform.label}. '
              'ستظهر الرسوم وموعد التطبيق النهائي في نافذة المتجر.',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: Text(actionLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }
}

SubscriptionDecision _subscriptionDecision({
  required SubscriptionInfo subscription,
  required StoreProductOffer? offer,
  required StoreBillingPlatform platform,
}) {
  if (offer == null) {
    return const BlockedSubscriptionDecision(
      SubscriptionBlockReason.stateUnknown,
    );
  }
  return SubscriptionPolicy.evaluate(
    current: subscription,
    target: offer,
    devicePlatform: platform,
  );
}

class _SubscriptionLoadingScaffold extends StatelessWidget {
  const _SubscriptionLoadingScaffold({required this.requiredActivation});

  final bool requiredActivation;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(requiredActivation ? 'تفعيل المتجر' : 'الاشتراك'),
    ),
    body: const SafeArea(
      child: Center(
        key: ValueKey('subscription-state-loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('جارٍ تحميل حالة الاشتراك…'),
          ],
        ),
      ),
    ),
  );
}

class _SubscriptionSummary extends StatelessWidget {
  const _SubscriptionSummary({
    required this.subscription,
    required this.activationRequired,
    required this.canManage,
    required this.platform,
  });

  final SubscriptionInfo subscription;
  final bool activationRequired;
  final bool canManage;
  final StoreBillingPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasCurrentPlan =
        subscription.isUsable || subscription.hasUnexpiredStorePeriod;
    if (!hasCurrentPlan) {
      final title = activationRequired && canManage
          ? 'ابدأ باشتراك مدفوع'
          : 'لا يوجد اشتراك فعّال';
      final hasPreviousRecord = !subscription.isAwaitingSubscription;
      return Semantics(
        key: const ValueKey('subscription-current-summary'),
        container: true,
        label: [
          title,
          'لا توجد باقة مفعّلة',
          if (hasPreviousRecord)
            'ضماناتك السابقة محفوظة، ويتوقف إصدار ضمانات جديدة فقط',
        ].join('. '),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'لا توجد باقة مفعّلة',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 3),
              Text(
                canManage
                    ? 'اختر باقة أدناه، أو استعد مشترياتك إذا سبق أن اشتركت.'
                    : 'يمكن لمالك المتجر اختيار باقة أو استعادة المشتريات.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (hasPreviousRecord) ...[
                const SizedBox(height: 9),
                Text(
                  'ضماناتك السابقة محفوظة؛ يتوقف إصدار ضمانات جديدة فقط.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final cycleLabel = switch (subscription.billingCycle) {
      _ when !subscription.isStoreSubscription => null,
      'monthly' => 'شهري',
      'yearly' => 'سنوي',
      _ => null,
    };
    final statusLabel = switch (subscription.status) {
      _ when subscription.isFreeAccess => 'مفعّلة',
      'trialing' => 'مفعّل مؤقتاً',
      'active' => subscription.autoRenews ? 'فعّال ويتجدد' : 'فعّال',
      'past_due' => 'تحتاج الفوترة إلى مراجعة',
      _ => 'غير فعّال',
    };
    final periodLabel = subscription.autoRenews ? 'التجديد' : 'الانتهاء';
    final usageRatio = subscription.plan.monthlyWarranties == 0
        ? 0.0
        : (subscription.usedWarranties / subscription.plan.monthlyWarranties)
              .clamp(0.0, 1.0);
    final metadata = [
      if (subscription.isFreeAccess) ...[
        '${subscription.plan.monthlyWarranties} ضماناً شهرياً',
        'تثبيت محمي واحد',
      ],
      if (subscription.isStoreSubscription) ?cycleLabel,
      if (subscription.isStoreSubscription) ?platform?.label,
      if (subscription.isStoreSubscription && subscription.periodEndsAt != null)
        '$periodLabel ${formatDate(subscription.periodEndsAt!)}',
    ];
    return Semantics(
      key: const ValueKey('subscription-current-summary'),
      container: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subscription.isFreeAccess ? 'خطتك المجانية' : 'باقتك الحالية',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  subscription.plan.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                metadata.join(' • '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (subscription.isUsable &&
                subscription.plan.monthlyWarranties > 0) ...[
              const SizedBox(height: 16),
              Text(
                '${subscription.remainingWarranties} ضماناً متبقياً من '
                '${subscription.plan.monthlyWarranties}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: usageRatio,
                  minHeight: 7,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              if (subscription.isFreeAccess) ...[
                const SizedBox(height: 9),
                Text(
                  'تبدأ الحصة من جديد تلقائياً مع بداية كل شهر، من دون اشتراك في App Store أو Google Play.',
                  key: const ValueKey('free-plan-monthly-reset'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                for (final feature in subscription.plan.features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SubscriptionStatusNotice extends StatelessWidget {
  const _SubscriptionStatusNotice({
    required this.state,
    required this.platform,
    required this.billingMessage,
    required this.errorMessage,
    required this.noticeMessage,
    required this.providerConflict,
    required this.currentProvider,
    required this.onDismiss,
    required this.onRetry,
  });

  final StoreBillingState state;
  final StoreBillingPlatform platform;
  final String? billingMessage;
  final String? errorMessage;
  final String? noticeMessage;
  final bool providerConflict;
  final StoreBillingPlatform? currentProvider;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final content = _content();
    if (content == null) return const SizedBox.shrink();
    final colors = context.colors;
    final foreground = content.error
        ? colors.onErrorContainer
        : content.success
        ? colors.onPrimaryContainer
        : colors.onSurface;
    final background = content.error
        ? colors.errorContainer
        : content.success
        ? colors.primaryContainer
        : colors.surfaceContainer;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: foreground.withValues(alpha: 0.14)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (content.loading)
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                Icon(content.icon, color: foreground, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (content.detail != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        content.detail!,
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.86),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (content.retry && onRetry != null) ...[
                      const SizedBox(height: 3),
                      TextButton(
                        key: const ValueKey('subscription-error-retry'),
                        onPressed: onRetry,
                        style: TextButton.styleFrom(
                          foregroundColor: foreground,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ],
                ),
              ),
              if (content.dismissible)
                IconButton(
                  onPressed: onDismiss,
                  tooltip: 'إغلاق الرسالة',
                  icon: Icon(Icons.close_rounded, color: foreground, size: 19),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusContent? _content() {
    if (errorMessage != null) {
      return _StatusContent(
        title: 'تعذر إكمال العملية',
        detail: _safeMessage(
          errorMessage!,
          'لم تبدأ دفعة جديدة. تحقق من حساب المتجر ثم أعد المحاولة.',
        ),
        icon: Icons.error_outline_rounded,
        error: true,
        dismissible: true,
      );
    }
    if (noticeMessage != null) {
      return _StatusContent(
        title: 'تم تحديث الاشتراك',
        detail: _safeMessage(noticeMessage!, 'اكتملت العملية بنجاح.'),
        icon: Icons.check_circle_outline_rounded,
        success: true,
        dismissible: true,
      );
    }
    if (providerConflict) {
      return _StatusContent(
        title: 'اشتراكك عبر ${currentProvider?.label ?? 'متجر آخر'}',
        detail:
            'استخدم المتجر نفسه لإدارة الاشتراك أو استعادته، كي لا تبدأ اشتراكاً ثانياً.',
        icon: Icons.storefront_outlined,
      );
    }
    if (state == StoreBillingState.ready && billingMessage != null) {
      final detail = _safeMessageOrNull(billingMessage!);
      if (detail != null) {
        return _StatusContent(
          title: 'حالة الاشتراك',
          detail: detail,
          icon: Icons.info_outline_rounded,
        );
      }
    }
    return switch (state) {
      StoreBillingState.ready => null,
      StoreBillingState.loading => const _StatusContent(
        title: 'جارٍ تحميل أسعار المتجر…',
        icon: Icons.storefront_outlined,
        loading: true,
      ),
      StoreBillingState.purchasing => const _StatusContent(
        title: 'أكمل العملية في نافذة المتجر',
        detail: 'لن تتفعّل الباقة قبل وصول تأكيد موثّق.',
        icon: Icons.storefront_outlined,
        loading: true,
      ),
      StoreBillingState.restoring => const _StatusContent(
        title: 'جارٍ استعادة مشترياتك…',
        detail: 'قد يستغرق التحقق لحظات.',
        icon: Icons.restore_rounded,
        loading: true,
      ),
      StoreBillingState.pending => const _StatusContent(
        title: 'بانتظار تأكيد المتجر',
        detail: 'لن تتفعّل الباقة قبل أن يؤكد المتجر الدفعة.',
        icon: Icons.schedule_rounded,
      ),
      StoreBillingState.unavailable => _StatusContent(
        title: 'تعذر تحميل أسعار ${platform.label}',
        detail: 'تحقق من اتصالك وحساب المتجر ثم أعد المحاولة.',
        icon: Icons.error_outline_rounded,
        error: true,
        retry: true,
      ),
      StoreBillingState.idle => const _StatusContent(
        title: 'أسعار المتجر غير محمّلة',
        detail: 'حمّل الأسعار قبل اختيار الاشتراك.',
        icon: Icons.storefront_outlined,
        retry: true,
      ),
    };
  }

  String _safeMessage(String message, String fallback) {
    return _safeMessageOrNull(message) ?? fallback;
  }

  String? _safeMessageOrNull(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty ||
        normalized.length > 220 ||
        normalized.contains('com.damanak.') ||
        normalized.contains('StateError') ||
        normalized.contains('Exception')) {
      return null;
    }
    return normalized;
  }
}

class _StatusContent {
  const _StatusContent({
    required this.title,
    required this.icon,
    this.detail,
    this.loading = false,
    this.error = false,
    this.success = false,
    this.retry = false,
    this.dismissible = false,
  });

  final String title;
  final String? detail;
  final IconData icon;
  final bool loading;
  final bool error;
  final bool success;
  final bool retry;
  final bool dismissible;
}

class _BillingCyclePicker extends StatelessWidget {
  const _BillingCyclePicker({required this.cycle, required this.onChanged});

  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<BillingCycle>(
    key: const ValueKey('subscription-cycle-picker'),
    segments: const [
      ButtonSegment(value: BillingCycle.monthly, label: Text('شهري')),
      ButtonSegment(value: BillingCycle.yearly, label: Text('سنوي')),
    ],
    selected: {cycle},
    onSelectionChanged: (selection) => onChanged(selection.first),
    showSelectedIcon: false,
    expandedInsets: EdgeInsets.zero,
  );
}

class _PlanChoiceList extends StatelessWidget {
  const _PlanChoiceList({
    required this.plans,
    required this.subscription,
    required this.platform,
    required this.cycle,
    required this.selectedPlanId,
    required this.offerForPlan,
    required this.onSelected,
  });

  final List<PlanInfo> plans;
  final SubscriptionInfo subscription;
  final StoreBillingPlatform platform;
  final BillingCycle cycle;
  final String? selectedPlanId;
  final StoreProductOffer? Function(String planId) offerForPlan;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < plans.length; index++) {
      final plan = plans[index];
      final offer = offerForPlan(plan.id);
      children.add(
        _PlanChoiceTile(
          key: ValueKey('subscription-plan-${plan.id}'),
          plan: plan,
          offer: offer,
          cycle: cycle,
          selected: selectedPlanId == plan.id,
          decision: _subscriptionDecision(
            subscription: subscription,
            offer: offer,
            platform: platform,
          ),
          onSelected: () => onSelected(plan.id),
        ),
      );
      if (index != plans.length - 1) {
        children.add(const SizedBox(height: 9));
      }
    }
    return Column(
      key: const ValueKey('subscription-plan-picker'),
      children: children,
    );
  }
}

class _PlanChoiceTile extends StatelessWidget {
  const _PlanChoiceTile({
    super.key,
    required this.plan,
    required this.offer,
    required this.cycle,
    required this.selected,
    required this.decision,
    required this.onSelected,
  });

  final PlanInfo plan;
  final StoreProductOffer? offer;
  final BillingCycle cycle;
  final bool selected;
  final SubscriptionDecision decision;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final blocked = !decision.allowed;
    final blockedReason = decision.blockedReason;
    final current = blockedReason == SubscriptionBlockReason.alreadyActive;
    final downgrade = blockedReason == SubscriptionBlockReason.downgrade;
    final canSelect = decision.allowed && offer != null;
    final statusLabel = switch (decision.kind) {
      SubscriptionDecisionKind.start => selected ? 'مختارة' : null,
      SubscriptionDecisionKind.upgrade => 'ترقية',
      SubscriptionDecisionKind.cycleChange => 'تغيير الدورة',
      SubscriptionDecisionKind.blocked => switch (blockedReason) {
        SubscriptionBlockReason.alreadyActive => 'الحالية',
        SubscriptionBlockReason.providerConflict => 'من متجر آخر',
        SubscriptionBlockReason.downgrade ||
        SubscriptionBlockReason.stateUnknown ||
        null => 'غير متاحة',
      },
    };
    final price = offer?.localizedPrice ?? 'السعر غير متاح';
    final visibleFeatures = plan.features;
    final semanticStatus = switch (decision.kind) {
      SubscriptionDecisionKind.start => selected ? 'مختارة' : 'متاحة',
      SubscriptionDecisionKind.upgrade => 'متاحة للترقية',
      SubscriptionDecisionKind.cycleChange => 'متاحة لتغيير دورة الفوترة',
      SubscriptionDecisionKind.blocked => switch (blockedReason) {
        SubscriptionBlockReason.alreadyActive => 'الباقة الحالية',
        SubscriptionBlockReason.downgrade =>
          'غير متاحة لأنها أقل من باقتك الحالية',
        SubscriptionBlockReason.providerConflict =>
          'غير متاحة على متجر التطبيقات الحالي',
        SubscriptionBlockReason.stateUnknown ||
        null => 'غير متاحة لتعذر التحقق من حالة الاشتراك',
      },
    };
    return Semantics(
      container: true,
      button: canSelect,
      selected: selected,
      enabled: canSelect,
      label:
          '${plan.name}. $price، ${cycle.label}. '
          '${plan.monthlyWarranties} ضمان شهرياً، حتى '
          '${plan.maxMembers} للفريق. ${visibleFeatures.join('. ')}. '
          '$semanticStatus.',
      child: ExcludeSemantics(
        child: Material(
          color: selected ? colors.primaryContainer : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: canSelect ? onSelected : null,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlanSelectionIcon(
                    selected: selected,
                    blocked: blocked,
                    color: colors.primary,
                    mutedColor: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              plan.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (statusLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: blocked
                                      ? colors.surfaceContainerHigh
                                      : colors.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: blocked
                                            ? colors.onSurfaceVariant
                                            : colors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              price,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: offer == null
                                        ? colors.onSurfaceVariant
                                        : colors.onSurface,
                                  ),
                            ),
                            Text(
                              '• ${cycle.label}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          children: [
                            _PlanFact(
                              text: '${plan.monthlyWarranties} ضمان شهرياً',
                            ),
                            _PlanFact(text: 'حتى ${plan.maxMembers} للفريق'),
                            _PlanFact(text: plan.branchLabel),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plan.audience,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (visibleFeatures.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Column(
                            key: ValueKey('plan-features-${plan.id}'),
                            children: [
                              for (final feature in visibleFeatures)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (blocked && !current) ...[
                          const SizedBox(height: 7),
                          Text(
                            downgrade
                                ? 'لا يمكن اختيار باقة أقل أثناء سريان اشتراكك.'
                                : 'تعذر إتاحة هذه الباقة بأمان حالياً.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanSelectionIcon extends StatelessWidget {
  const _PlanSelectionIcon({
    required this.selected,
    required this.blocked,
    required this.color,
    required this.mutedColor,
  });

  final bool selected;
  final bool blocked;
  final Color color;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    if (blocked) {
      return SizedBox.square(
        dimension: 44,
        child: Icon(Icons.lock_outline_rounded, color: mutedColor, size: 22),
      );
    }
    return SizedBox.square(
      dimension: 44,
      child: Center(
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? color : Colors.transparent,
            border: Border.all(
              color: selected ? color : mutedColor,
              width: 1.5,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: context.colors.onPrimary,
                )
              : null,
        ),
      ),
    );
  }
}

class _PlanFact extends StatelessWidget {
  const _PlanFact({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
  );
}

class _EmptyPlansNotice extends StatelessWidget {
  const _EmptyPlansNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.colors.outlineVariant),
    ),
    child: const Text('تعذر تحميل الباقات. أعد المحاولة بعد قليل.'),
  );
}

class _SubscriptionActionBar extends StatelessWidget {
  const _SubscriptionActionBar({
    required this.primaryLabel,
    required this.primaryBusy,
    required this.primaryEnabled,
    required this.onPrimary,
    required this.restoreBusy,
    required this.onRestore,
    required this.onManage,
  });

  final String primaryLabel;
  final bool primaryBusy;
  final bool primaryEnabled;
  final Future<void> Function()? onPrimary;
  final bool restoreBusy;
  final Future<void> Function()? onRestore;
  final Future<void> Function()? onManage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('subscription-primary-action'),
                  onPressed: primaryEnabled && !primaryBusy
                      ? () => onPrimary?.call()
                      : null,
                  child: _BusyButtonLabel(
                    busy: primaryBusy,
                    label: primaryLabel,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const ValueKey('subscription-restore-action'),
                  onPressed: restoreBusy ? null : onRestore,
                  icon: restoreBusy
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_rounded, size: 19),
                  label: Text(
                    restoreBusy ? 'جارٍ الاستعادة…' : 'استعادة المشتريات',
                  ),
                ),
              ),
              if (onManage != null)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.settings_outlined, size: 19),
                    label: const Text('إدارة الاشتراك'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusyButtonLabel extends StatelessWidget {
  const _BusyButtonLabel({required this.busy, required this.label});

  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (busy) ...[
        const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 9),
      ],
      Flexible(child: Text(label, textAlign: TextAlign.center)),
    ],
  );
}

class _InitialPaymentAccountScreen extends StatelessWidget {
  const _InitialPaymentAccountScreen();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final account = controller.account;
    final store = controller.store;
    final membership = controller.membership;
    if (account == null || store == null || membership == null) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    final displayName = account.fullName.trim().isEmpty
        ? 'مستخدم ضمانك'
        : account.fullName.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('بيانات الحساب')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: Text(
                        displayName.characters.first,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (account.email.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              account.email.trim(),
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          Text(
                            '${membership.role.label} • ${store.name}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'لحماية بيانات المتجر، تقتصر هذه الصفحة على إدارة الحساب حتى تفعيل الاشتراك.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: controller.busy
                    ? null
                    : () => _signOutAndClearRoutes(context),
                style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل الخروج'),
              ),
              if (!controller.isDemo) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () => _confirmDelete(context),
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('حذف الحساب نهائياً'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOutAndClearRoutes(BuildContext context) async {
    final controller = AppScope.of(context);
    _removeAccountRoute(context);
    await controller.signOut();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final controller = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('حذف الحساب نهائياً؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إذا كنت المالك الوحيد فسيُحذف المتجر وبياناته. وإذا وُجد عضو آخر فستُنقل الملكية إليه قبل حذف حسابك. لا يمكن التراجع عن هذا الإجراء.',
            ),
            const SizedBox(height: 12),
            Text(
              'تنبيه: حذف حساب ضمانك لا يلغي أي اشتراك قائم أو يوقف الفوترة لدى App Store أو Google Play. ألغِ التجديد من المتجر لتجنب رسوم لاحقة.',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
                fontWeight: FontWeight.w700,
                height: 1.5,
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    _removeAccountRoute(context);
    await controller.deleteAccount();
  }

  void _removeAccountRoute(BuildContext context) {
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    if (route != null && !route.isFirst) {
      navigator.removeRoute(route);
      return;
    }
    navigator.popUntil((candidate) => candidate.isFirst);
  }
}

class _BillingTerms extends StatelessWidget {
  const _BillingTerms();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'يعرض متجر التطبيقات السعر والعملة وموعد التطبيق النهائي قبل التأكيد. يتجدد الاشتراك تلقائياً حتى الإلغاء.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 0,
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
