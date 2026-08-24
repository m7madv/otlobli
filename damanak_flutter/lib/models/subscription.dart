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
  int get remainingTrialDays {
    final end = trialEndsAt;
    if (end == null) return 0;
    final hours = end.difference(DateTime.now()).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  bool get isStoreSubscription => source == 'store';
}
