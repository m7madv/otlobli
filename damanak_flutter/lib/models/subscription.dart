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

  static const starter = PlanPresentation(
    audience: 'للمتجر الذي يبدأ تنظيم ضماناته رقمياً',
    branchLabel: 'مناسب لفرع واحد',
    suggestedBranches: 1,
    features: [
      'بطاقة ضمان رقمية برمز QR',
      'رابط مشاركة آمن للضمان',
      'سجل ضمانات قابل للبحث',
      'طلبات صيانة أساسية',
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
    branchLabel: 'مناسب لفروع متعددة',
    suggestedBranches: null,
    features: [
      'كل مزايا نمو',
      'سجل نشاط للمالك والمدير',
      'الموردون وأوامر الشراء',
      'تحويل المخزون بين الفروع',
      'إدارة المرتجعات والصندوق',
    ],
  );

  static const fallback = PlanPresentation(
    audience: 'خطة مخصصة لاحتياج المتجر',
    branchLabel: 'الفروع بحسب الخطة',
    suggestedBranches: null,
    features: [],
  );

  static PlanPresentation forPlanId(String planId) => switch (planId) {
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
  });

  final String id;
  final String name;
  final num monthlyPrice;
  final num yearlyPrice;
  final int maxMembers;
  final int monthlyWarranties;

  PlanPresentation get presentation => PlanPresentation.forPlanId(id);
  String get audience => presentation.audience;
  String get branchLabel => presentation.branchLabel;
  int? get suggestedBranches => presentation.suggestedBranches;
  List<String> get features => presentation.features;
  bool get isRecommended => presentation.recommended;

  factory PlanInfo.fromJson(Map<String, dynamic> json) {
    return PlanInfo(
      id: json['id'] as String,
      name: json['name_ar'] as String,
      monthlyPrice: json['monthly_price'] as num? ?? 0,
      yearlyPrice: json['yearly_price'] as num? ?? 0,
      maxMembers: json['max_members'] as int? ?? 1,
      monthlyWarranties: json['monthly_warranties'] as int? ?? 0,
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
    this.billingCycle,
    this.autoRenews = false,
    this.lastVerifiedAt,
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
  final String? billingCycle;
  final bool autoRenews;
  final DateTime? lastVerifiedAt;

  bool get isUsable => status == 'trialing' || status == 'active';
  int get remainingWarranties => (plan.monthlyWarranties - usedWarranties)
      .clamp(0, plan.monthlyWarranties);
  int get warrantyGraceAllowance => (plan.monthlyWarranties / 10).ceil();
  int get remainingTrialDays {
    final end = trialEndsAt;
    if (end == null) return 0;
    final hours = end.difference(DateTime.now()).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  bool get isStoreSubscription => source == 'store';
}
