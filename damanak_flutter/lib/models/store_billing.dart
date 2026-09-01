enum StoreBillingPlatform { appStore, googlePlay, unavailable }

extension StoreBillingPlatformText on StoreBillingPlatform {
  String get value => switch (this) {
    StoreBillingPlatform.appStore => 'app_store',
    StoreBillingPlatform.googlePlay => 'google_play',
    StoreBillingPlatform.unavailable => 'unavailable',
  };

  String get label => switch (this) {
    StoreBillingPlatform.appStore => 'App Store',
    StoreBillingPlatform.googlePlay => 'Google Play',
    StoreBillingPlatform.unavailable => 'متجر التطبيقات',
  };

  static StoreBillingPlatform? fromValue(String? value) => switch (value) {
    'app_store' => StoreBillingPlatform.appStore,
    'google_play' => StoreBillingPlatform.googlePlay,
    _ => null,
  };
}

enum BillingCycle { monthly, yearly }

extension BillingCycleText on BillingCycle {
  String get value => name;
  String get label => this == BillingCycle.monthly ? 'شهري' : 'سنوي';
}

enum StoreBillingState {
  idle,
  loading,
  ready,
  unavailable,
  purchasing,
  restoring,
  pending,
}

enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

enum StoreSubscriptionTransitionKind {
  start,
  current,
  upgrade,
  downgrade,
  billingCycleChange,
}

abstract final class DamanakStoreCatalog {
  static const packageName = 'com.damanak.damanak';

  static const googleProductIds = <String>{
    'com.damanak.subscription.starter',
    'com.damanak.subscription.growth',
    'com.damanak.subscription.scale',
  };

  static const appleProductIds = <String>{
    'com.damanak.subscription.starter.monthly',
    'com.damanak.subscription.starter.yearly',
    'com.damanak.subscription.growth.monthly',
    'com.damanak.subscription.growth.yearly',
    'com.damanak.subscription.scale.monthly',
    'com.damanak.subscription.scale.yearly',
  };

  static String googleProductId(String planId) =>
      'com.damanak.subscription.$planId';

  static String appleProductId(String planId, BillingCycle cycle) =>
      'com.damanak.subscription.$planId.${cycle.value}';

  static String? planIdFromProduct(String productId) {
    if (!appleProductIds.contains(productId) &&
        !googleProductIds.contains(productId)) {
      return null;
    }
    const prefix = 'com.damanak.subscription.';
    final suffix = productId.substring(prefix.length);
    final planId = suffix.split('.').first;
    return const {'starter', 'growth', 'scale'}.contains(planId)
        ? planId
        : null;
  }

  static BillingCycle? cycleFromAppleProduct(String productId) {
    if (!appleProductIds.contains(productId)) return null;
    if (productId.endsWith('.monthly')) return BillingCycle.monthly;
    if (productId.endsWith('.yearly')) return BillingCycle.yearly;
    return null;
  }

  static BillingCycle? cycleFromGoogleBasePlan(String? basePlanId) =>
      switch (basePlanId) {
        'monthly' => BillingCycle.monthly,
        'yearly' => BillingCycle.yearly,
        _ => null,
      };

  static int planRank(String? planId) => switch (planId) {
    'starter' => 1,
    'growth' => 2,
    'scale' => 3,
    _ => 0,
  };

  static StoreSubscriptionTransitionKind subscriptionTransition({
    required bool hasActiveStoreSubscription,
    required String? currentPlanId,
    required String? currentBillingCycle,
    required String targetPlanId,
    required BillingCycle targetCycle,
  }) {
    final currentRank = planRank(currentPlanId);
    final targetRank = planRank(targetPlanId);
    if (!hasActiveStoreSubscription || currentRank == 0 || targetRank == 0) {
      return StoreSubscriptionTransitionKind.start;
    }
    if (currentPlanId == targetPlanId) {
      return currentBillingCycle == targetCycle.value
          ? StoreSubscriptionTransitionKind.current
          : StoreSubscriptionTransitionKind.billingCycleChange;
    }
    return targetRank > currentRank
        ? StoreSubscriptionTransitionKind.upgrade
        : StoreSubscriptionTransitionKind.downgrade;
  }

  static bool contains(StoreBillingPlatform platform, String productId) =>
      switch (platform) {
        StoreBillingPlatform.appStore => appleProductIds.contains(productId),
        StoreBillingPlatform.googlePlay => googleProductIds.contains(productId),
        StoreBillingPlatform.unavailable => false,
      };
}

class StoreProductOffer {
  const StoreProductOffer({
    required this.key,
    required this.planId,
    required this.cycle,
    required this.productId,
    required this.title,
    required this.description,
    required this.localizedPrice,
    required this.rawPrice,
    required this.currencyCode,
    this.basePlanId,
  });

  final String key;
  final String planId;
  final BillingCycle cycle;
  final String productId;
  final String? basePlanId;
  final String title;
  final String description;
  final String localizedPrice;
  final double rawPrice;
  final String currencyCode;
}

class StorePurchaseEvent {
  const StorePurchaseEvent({
    required this.key,
    required this.status,
    required this.platform,
    required this.productId,
    required this.verificationData,
    required this.verificationSource,
    required this.needsCompletion,
    this.purchaseId,
    this.transactionDate,
    this.errorCode,
    this.errorMessage,
    this.basePlanId,
    this.accountId,
    this.storeId,
    this.appAccountToken,
    this.pendingProductIds = const [],
  });

  final String key;
  final StorePurchaseStatus status;
  final StoreBillingPlatform platform;
  final String productId;
  final String? basePlanId;
  final String? purchaseId;
  final String? transactionDate;
  final String verificationData;
  final String verificationSource;
  final bool needsCompletion;
  final String? errorCode;
  final String? errorMessage;

  /// المعرّف المحلي الذي أعاده Google Play مع المعاملة، إن توفر.
  ///
  /// يبقى null على Apple؛ فالربط هناك يستخدم appAccountToken مستقلاً.
  final String? accountId;

  /// معرّف المتجر المحلي الذي أعاده Google Play في obfuscatedProfileId، إن توفر.
  final String? storeId;

  /// رمز StoreKit 2 الأصلي. يستخدم Build 24 وما بعده storeId، بينما قد تعيد
  /// معاملات Build 23 القديمة accountId. لا يجوز استنتاجه من جلسة التطبيق.
  final String? appAccountToken;

  /// المنتجات التي سيبدّل إليها Google لاحقاً عند استخدام الاستبدال المؤجل.
  /// تكون فارغة على Apple وفي المشتريات غير المؤجلة.
  final List<String> pendingProductIds;
}

class StorePurchaseReceipt {
  const StorePurchaseReceipt({
    required this.platform,
    required this.productId,
    required this.verificationData,
    required this.verificationSource,
    this.basePlanId,
    this.purchaseId,
    this.transactionDate,
    this.recoveryRequested = false,
  });

  final StoreBillingPlatform platform;
  final String productId;
  final String? basePlanId;
  final String? purchaseId;
  final String? transactionDate;
  final String verificationData;
  final String verificationSource;

  /// لا يُفعّل إلا من إجراء «استعادة المشتريات» الصريح.
  ///
  /// يسمح للخادم بتقييم ربط قديم بعد حذف الحساب من دون إضعاف التحقق الصارم
  /// للمعاملات الخلفية أو المتأخرة.
  final bool recoveryRequested;
}

class StoreProductLoadResult {
  const StoreProductLoadResult({
    required this.available,
    required this.platform,
    required this.offers,
    this.missingProductIds = const [],
    this.errorMessage,
  });

  final bool available;
  final StoreBillingPlatform platform;
  final List<StoreProductOffer> offers;
  final List<String> missingProductIds;
  final String? errorMessage;
}

class StoreRestoreResult {
  const StoreRestoreResult({
    required this.platform,
    this.restoredPurchases,
    this.pendingPurchases = 0,
    this.accountMismatchDetected = false,
  });

  final StoreBillingPlatform platform;

  /// عدد النتائج التي أعادها المتجر عندما يكون قابلاً للمعرفة مباشرة.
  ///
  /// يعيد Google Play عدداً نهائياً، بينما قد يرسل App Store النتائج لاحقاً
  /// على stream المعاملات؛ لذلك تكون القيمة null على Apple.
  final int? restoredPurchases;
  final int pendingPurchases;
  final bool accountMismatchDetected;
}
