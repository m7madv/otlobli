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
  pending,
}

enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

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
    const prefix = 'com.damanak.subscription.';
    if (!productId.startsWith(prefix)) return null;
    final suffix = productId.substring(prefix.length);
    final planId = suffix.split('.').first;
    return const {'starter', 'growth', 'scale'}.contains(planId)
        ? planId
        : null;
  }

  static BillingCycle? cycleFromAppleProduct(String productId) {
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
  });

  final StoreBillingPlatform platform;
  final String productId;
  final String? basePlanId;
  final String? purchaseId;
  final String? transactionDate;
  final String verificationData;
  final String verificationSource;
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
