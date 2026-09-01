/// معلومات العرض المحلية للباقات.
///
/// لا تُستخدم هذه البيانات لمنح صلاحية أو تجاوز تحقق الخادم؛ الحصص الفعلية
/// تأتي من [PlanInfo] الذي يعيده الخادم. وتصف النصوص وظائف موجودة واقتراح
/// ملاءمة للفروع، ولا تُستخدم كحارس صلاحيات أو حد خادمي للفروع.
class PlanPresentation {
  const PlanPresentation({
    required this.audience,
    required this.branchLabel,
    required this.suggestedBranches,
    required this.features,
    this.recommended = false,
  });

  final String audience;
  final String branchLabel;
  final int? suggestedBranches;
  final List<String> features;
  final bool recommended;

  static const free = PlanPresentation(
    audience: 'للمتجر الفردي الذي يبدأ إصدار ضماناته',
    branchLabel: 'فرع واحد',
    suggestedBranches: 1,
    features: [
      '20 ضماناً تتجدد تلقائياً كل شهر',
      'بطاقة ضمان رقمية برمز QR',
      'رابط مشاركة آمن للضمان',
      'مطالبات وصور ومستندات العميل',
    ],
  );

  static const starter = PlanPresentation(
    audience: 'للمتجر الذي يبدأ تنظيم ضماناته رقمياً',
    branchLabel: 'مناسب لفرع واحد',
    suggestedBranches: 1,
    features: [
      'بطاقة ضمان رقمية برمز QR',
      'رابط مشاركة آمن للضمان',
      'سجل ضمانات قابل للبحث',
      'مطالبات وصور ومستندات العميل',
    ],
  );

  static const growth = PlanPresentation(
    audience: 'لفريق يدير الضمانات والمتابعة يومياً',
    branchLabel: 'مناسب حتى 3 فروع',
    suggestedBranches: 3,
    features: [
      'كل مزايا بداية',
      'فريق بأدوار مستقلة',
      'الفروع والمخزون ونقطة البيع',
      'تقارير وتصدير CSV',
      'هوية المتجر والفروع',
    ],
    recommended: true,
  );

  static const scale = PlanPresentation(
    audience: 'لسلاسل الفروع والعمليات ذات الحجم الكبير',
    branchLabel: 'حتى 20 فرعاً',
    suggestedBranches: 20,
    features: [
      'كل مزايا نمو',
      'API بصلاحيات قابلة للتحديد',
      'Webhooks موقعة للمطالبات',
      'حصص أعلى للضمانات والتحليل',
      'سجل نشاط للمالك والمدير',
    ],
  );

  static const fallback = PlanPresentation(
    audience: 'خطة مخصصة لاحتياج المتجر',
    branchLabel: 'الفروع بحسب الخطة',
    suggestedBranches: null,
    features: [],
  );

  static PlanPresentation forPlanId(String planId) => switch (planId) {
    'free' => free,
    'starter' => starter,
    'growth' => growth,
    'scale' => scale,
    _ => fallback,
  };
}

class PlanInfo {
  const PlanInfo({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxMembers,
    required this.monthlyWarranties,
    this.monthlyAiImports = 0,
    this.monthlyAiClaimReviews = 0,
    this.maxBranches = 1,
    this.apiAccess = false,
    this.webhookAccess = false,
    this.customBranding = false,
  });

  final String id;
  final String name;
  final num monthlyPrice;
  final num yearlyPrice;
  final int maxMembers;
  final int monthlyWarranties;
  final int monthlyAiImports;
  final int monthlyAiClaimReviews;
  final int maxBranches;
  final bool apiAccess;
  final bool webhookAccess;
  final bool customBranding;

  PlanPresentation get presentation => PlanPresentation.forPlanId(id);
  String get audience => presentation.audience;
  String get branchLabel => presentation.branchLabel;
  int? get suggestedBranches => presentation.suggestedBranches;
  List<String> get features => [
    ...presentation.features,
    if (monthlyAiImports > 0)
      '$monthlyAiImports تحليل ملف منتجات بالذكاء الاصطناعي شهرياً',
    if (monthlyAiClaimReviews > 0)
      '$monthlyAiClaimReviews مراجعة ذكية للمطالبات شهرياً',
    if (customBranding) 'هوية وسياسة ضمان مخصصة للعميل',
    if (apiAccess) 'مفاتيح API تُعرض مرة واحدة فقط',
    if (webhookAccess) 'إشعارات Webhook مع توقيع وإعادة محاولة',
  ];
  bool get isRecommended => presentation.recommended;

  factory PlanInfo.fromJson(Map<String, dynamic> json) {
    return PlanInfo(
      id: json['id'] as String,
      name: json['name_ar'] as String,
      monthlyPrice: json['monthly_price'] as num? ?? 0,
      yearlyPrice: json['yearly_price'] as num? ?? 0,
      maxMembers: json['max_members'] as int? ?? 1,
      monthlyWarranties: json['monthly_warranties'] as int? ?? 0,
      monthlyAiImports: json['monthly_ai_imports'] as int? ?? 0,
      monthlyAiClaimReviews: json['monthly_ai_claim_reviews'] as int? ?? 0,
      maxBranches: json['max_branches'] as int? ?? 1,
      apiAccess: json['api_access'] as bool? ?? false,
      webhookAccess: json['webhook_access'] as bool? ?? false,
      customBranding: json['custom_branding'] as bool? ?? false,
    );
  }
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.id,
    required this.status,
    required this.plan,
    required this.trialEndsAt,
    required this.periodEndsAt,
    required this.usedWarranties,
    this.source = 'trial',
    this.billingProvider,
    this.storeProductId,
    this.originalTransactionId,
    this.billingCycle,
    this.autoRenews = false,
    this.lastVerifiedAt,
    this.hasStoreBillingLineage = false,
    this.storeBillingLineageVerifiedAt,
  });

  final String id;
  final String status;
  final PlanInfo plan;
  final DateTime? trialEndsAt;
  final DateTime? periodEndsAt;
  final int usedWarranties;
  final String source;
  final String? billingProvider;
  final String? storeProductId;
  final String? originalTransactionId;
  final String? billingCycle;
  final bool autoRenews;
  final DateTime? lastVerifiedAt;
  final bool hasStoreBillingLineage;
  final DateTime? storeBillingLineageVerifiedAt;

  bool get isUsable {
    final now = DateTime.now();
    if (status == 'trialing') {
      return trialEndsAt?.isAfter(now) ?? false;
    }
    if (status != 'active') return false;
    final end = periodEndsAt;
    if (isStoreSubscription) return end?.isAfter(now) ?? false;
    return end == null || end.isAfter(now);
  }

  bool get isAwaitingSubscription =>
      status == 'canceled' &&
      source == 'trial' &&
      trialEndsAt == null &&
      periodEndsAt == null;

  int get remainingWarranties => !isUsable
      ? 0
      : (plan.monthlyWarranties - usedWarranties).clamp(
          0,
          plan.monthlyWarranties,
        );
  int get warrantyGraceAllowance =>
      isFreeAccess ? 0 : (plan.monthlyWarranties / 10).ceil();
  int get remainingTrialDays {
    final end = trialEndsAt;
    if (end == null) return 0;
    final hours = end.difference(DateTime.now()).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  bool get isStoreSubscription => source == 'store';

  /// توجد معاملة متجر سابقة يمكن مصالحتها حتى إن كانت الخطة الفعالة مجانية.
  bool get canRefreshStoreBilling =>
      (isStoreSubscription && hasUnexpiredStorePeriod) ||
      hasStoreBillingLineage;

  /// وصول التطبيق المجاني ليس اشتراكاً في App Store أو Google Play.
  bool get isFreeAccess => source == 'free' && plan.id == 'free';

  SubscriptionInfo withUsedWarranties(int value) => SubscriptionInfo(
    id: id,
    status: status,
    plan: plan,
    trialEndsAt: trialEndsAt,
    periodEndsAt: periodEndsAt,
    usedWarranties: value,
    source: source,
    billingProvider: billingProvider,
    storeProductId: storeProductId,
    originalTransactionId: originalTransactionId,
    billingCycle: billingCycle,
    autoRenews: autoRenews,
    lastVerifiedAt: lastVerifiedAt,
    hasStoreBillingLineage: hasStoreBillingLineage,
    storeBillingLineageVerifiedAt: storeBillingLineageVerifiedAt,
  );

  bool get hasUnexpiredStorePeriod {
    if (!isStoreSubscription || (status != 'active' && status != 'past_due')) {
      return false;
    }
    final end = periodEndsAt;
    final verifiedAt = lastVerifiedAt;
    // لا تستخدم ساعة الهاتف لحسم إمكانية فتح مزود دفع ثانٍ. وقت التحقق
    // ونهاية الفترة كلاهما قادمان من الخادم؛ وعند نقص أحدهما نفشل مغلقين.
    if (end == null || verifiedAt == null) return true;
    return end.isAfter(verifiedAt);
  }
}
