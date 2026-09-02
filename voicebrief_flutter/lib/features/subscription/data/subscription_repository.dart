import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    hide SubscriptionOption;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';

abstract interface class SubscriptionRepository {
  Future<void> logIn(String accountId);
  Future<void> logOut();
  Future<SubscriptionStatus> load();
  Future<SubscriptionStatus> purchase(String productId);
  Future<SubscriptionStatus> restore();
}

typedef SubscriptionStatusLoader =
    Future<SubscriptionStatus> Function(SubscriptionStatus storeStatus);
typedef SubscriptionSyncWait = Future<void> Function(Duration duration);
typedef SubscriptionSyncRequest = Future<void> Function();

const subscriptionSyncRetryDelays = <Duration>[
  Duration.zero,
  Duration(milliseconds: 250),
  Duration(milliseconds: 500),
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 3),
  Duration(seconds: 4),
  Duration(seconds: 5),
];
const subscriptionSyncRequestRetryDelays = <Duration>[
  Duration.zero,
  Duration(seconds: 1),
  Duration(seconds: 3),
];
const maxSubscriptionSyncRequestAttempts = 3;

Future<void> _waitForSubscriptionSync(Duration duration) =>
    Future<void>.delayed(duration);

/// Reconciles RevenueCat with the server-owned entitlement and usage quota.
///
/// RevenueCat can confirm a purchase before its webhook transaction reaches
/// Supabase. A Pro result is therefore not exposed to the app until the server
/// has created the matching Pro usage period. The retries are bounded so a
/// delayed webhook cannot leave the purchase screen waiting indefinitely.
Future<SubscriptionStatus> synchronizeSubscriptionStatus({
  required SubscriptionStatus storeStatus,
  required SubscriptionStatusLoader loadServerStatus,
  List<Duration> retryDelays = subscriptionSyncRetryDelays,
  List<Duration> requestRetryDelays = subscriptionSyncRequestRetryDelays,
  SubscriptionSyncWait wait = _waitForSubscriptionSync,
  SubscriptionSyncRequest? requestServerSync,
}) async {
  var serverSyncUnavailable = false;
  if (requestServerSync != null) {
    if (requestRetryDelays.isEmpty) {
      throw const AppFailure(AppFailureCode.subscriptionSyncPending);
    }
    String? lastSyncDebugContext;
    serverSyncUnavailable = true;
    for (
      var attempt = 0;
      attempt < requestRetryDelays.length &&
          attempt < maxSubscriptionSyncRequestAttempts;
      attempt += 1
    ) {
      final delay = requestRetryDelays[attempt];
      if (delay > Duration.zero) await wait(delay);
      try {
        await requestServerSync();
        serverSyncUnavailable = false;
        break;
      } on AppFailure catch (failure) {
        if (failure.code != AppFailureCode.subscriptionUnavailable) rethrow;
        lastSyncDebugContext = failure.debugContext;
        if (failure.debugContext == '429') break;
      }
    }
    if (serverSyncUnavailable && storeStatus.tier == SubscriptionTier.pro) {
      throw AppFailure(
        AppFailureCode.subscriptionSyncPending,
        debugContext: lastSyncDebugContext,
      );
    }
  }

  if (storeStatus.tier != SubscriptionTier.pro) {
    final serverStatus = await loadServerStatus(storeStatus);
    if (serverSyncUnavailable && serverStatus.tier == SubscriptionTier.pro) {
      throw const AppFailure(AppFailureCode.subscriptionSyncPending);
    }
    return serverStatus;
  }
  if (retryDelays.isEmpty) {
    throw const AppFailure(AppFailureCode.subscriptionSyncPending);
  }

  String? lastDebugContext;
  for (final delay in retryDelays) {
    if (delay > Duration.zero) await wait(delay);
    try {
      final serverStatus = await loadServerStatus(storeStatus);
      if (serverStatus.tier == SubscriptionTier.pro) return serverStatus;
    } on AppFailure catch (failure) {
      if (failure.code != AppFailureCode.subscriptionUnavailable) rethrow;
      lastDebugContext = failure.debugContext;
    }
  }

  throw AppFailure(
    AppFailureCode.subscriptionSyncPending,
    debugContext: lastDebugContext,
  );
}

SubscriptionStatus subscriptionStatusFromServerSnapshot(
  SubscriptionStatus storeStatus,
  Object? response,
) {
  if (response is! Map) {
    throw const AppFailure(AppFailureCode.subscriptionUnavailable);
  }
  final snapshot = Map<String, dynamic>.from(response);
  final tier = switch (snapshot['tier']) {
    'pro' => SubscriptionTier.pro,
    'free' => SubscriptionTier.free,
    _ => null,
  };
  final total = (snapshot['quotaMinutes'] as num?)?.toInt();
  final used = (snapshot['usedMinutes'] as num?)?.toInt();
  final reserved = (snapshot['reservedMinutes'] as num?)?.toInt();
  final serverNow = DateTime.tryParse(snapshot['serverNow'] as String? ?? '');
  if (tier == null ||
      total == null ||
      used == null ||
      reserved == null ||
      serverNow == null ||
      total <= 0 ||
      used < 0 ||
      reserved < 0 ||
      used + reserved > total) {
    throw const AppFailure(AppFailureCode.subscriptionUnavailable);
  }
  return storeStatus.copyWith(
    tier: tier,
    remainingMinutes: total - used - reserved,
    totalMinutes: total,
  );
}

class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({this.pro = false});

  bool pro;

  static const _options = [
    SubscriptionOption(
      productId: ProductIds.annual,
      title: 'Yearly',
      localizedPrice: '229 QAR / year',
      localizedMonthlyEquivalent: '19.08 QAR / month',
      annual: true,
      packageIdentifier: 'annual-demo',
    ),
    SubscriptionOption(
      productId: ProductIds.monthly,
      title: 'Monthly',
      localizedPrice: '29 QAR / month',
      annual: false,
      packageIdentifier: 'monthly-demo',
    ),
  ];

  @override
  Future<void> logIn(String accountId) async {}

  @override
  Future<void> logOut() async => pro = false;

  @override
  Future<SubscriptionStatus> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _status;
  }

  @override
  Future<SubscriptionStatus> purchase(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    pro = true;
    return _status;
  }

  @override
  Future<SubscriptionStatus> restore() async => _status;

  SubscriptionStatus get _status => SubscriptionStatus(
    tier: pro ? SubscriptionTier.pro : SubscriptionTier.free,
    remainingMinutes: pro ? 300 : 10,
    totalMinutes: pro ? 300 : 10,
    options: _options,
    offeringsLoaded: true,
  );
}

class RevenueCatSubscriptionRepository implements SubscriptionRepository {
  RevenueCatSubscriptionRepository(this._client);

  final SupabaseClient _client;
  final Map<String, Package> _packages = {};

  @override
  Future<void> logIn(String accountId) async {
    await Purchases.logIn(accountId);
  }

  @override
  Future<void> logOut() => Purchases.logOut();

  @override
  Future<SubscriptionStatus> load() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering =
          offerings.getOffering(ProductIds.offering) ?? offerings.current;
      if (offering == null) {
        throw const AppFailure(AppFailureCode.subscriptionUnavailable);
      }
      _packages
        ..clear()
        ..addEntries(
          offering.availablePackages.map(
            (item) => MapEntry(item.storeProduct.identifier, item),
          ),
        );
      final customerInfo = await Purchases.getCustomerInfo();
      return await synchronizeSubscriptionStatus(
        storeStatus: _mapStatus(customerInfo, offering.availablePackages),
        loadServerStatus: _withServerUsage,
      );
    } on PlatformException catch (error) {
      throw AppFailure(
        AppFailureCode.subscriptionUnavailable,
        debugContext: error.code,
      );
    } on PostgrestException catch (error) {
      throw AppFailure(
        AppFailureCode.subscriptionUnavailable,
        debugContext: error.code,
      );
    }
  }

  @override
  Future<SubscriptionStatus> purchase(String productId) async {
    final package = _packages[productId];
    if (package == null) {
      throw const AppFailure(AppFailureCode.subscriptionUnavailable);
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return await synchronizeSubscriptionStatus(
        storeStatus: _mapStatus(result.customerInfo, _packages.values.toList()),
        loadServerStatus: _withServerUsage,
        requestServerSync: () => _requestServerSubscriptionSync(
          expectedPro: result.customerInfo.entitlements.active.containsKey(
            ProductIds.entitlement,
          ),
        ),
      );
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw const AppFailure(AppFailureCode.purchaseCanceled);
      }
      throw AppFailure(AppFailureCode.purchaseFailed, debugContext: code.name);
    } on PostgrestException catch (error) {
      throw AppFailure(
        AppFailureCode.subscriptionUnavailable,
        debugContext: error.code,
      );
    }
  }

  @override
  Future<SubscriptionStatus> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return await synchronizeSubscriptionStatus(
        storeStatus: _mapStatus(info, _packages.values.toList()),
        loadServerStatus: _withServerUsage,
        requestServerSync: () => _requestServerSubscriptionSync(
          expectedPro: info.entitlements.active.containsKey(
            ProductIds.entitlement,
          ),
        ),
      );
    } on PlatformException catch (error) {
      throw AppFailure(AppFailureCode.restoreFailed, debugContext: error.code);
    } on PostgrestException catch (error) {
      throw AppFailure(
        AppFailureCode.subscriptionUnavailable,
        debugContext: error.code,
      );
    }
  }

  SubscriptionStatus _mapStatus(
    CustomerInfo customerInfo,
    List<Package> packages,
  ) {
    final isPro = customerInfo.entitlements.active.containsKey(
      ProductIds.entitlement,
    );
    final options = packages
        .where(
          (item) =>
              item.storeProduct.identifier == ProductIds.monthly ||
              item.storeProduct.identifier == ProductIds.annual,
        )
        .map(
          (item) => SubscriptionOption(
            productId: item.storeProduct.identifier,
            title: item.storeProduct.identifier == ProductIds.annual
                ? 'Yearly'
                : 'Monthly',
            localizedPrice: item.storeProduct.priceString,
            annual: item.storeProduct.identifier == ProductIds.annual,
            packageIdentifier: item.identifier,
          ),
        )
        .toList(growable: false);
    return SubscriptionStatus(
      tier: isPro ? SubscriptionTier.pro : SubscriptionTier.free,
      remainingMinutes: isPro ? 300 : 10,
      totalMinutes: isPro ? 300 : 10,
      options: options,
      offeringsLoaded: true,
    );
  }

  Future<SubscriptionStatus> _withServerUsage(
    SubscriptionStatus storeStatus,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppFailure(AppFailureCode.authentication);
    try {
      final response = await _client.rpc('get_voicebrief_subscription_status');
      return subscriptionStatusFromServerSnapshot(storeStatus, response);
    } on PostgrestException catch (error) {
      throw AppFailure(
        AppFailureCode.subscriptionUnavailable,
        debugContext: error.code,
      );
    }
  }

  Future<void> _requestServerSubscriptionSync({
    required bool expectedPro,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'sync-subscription',
        body: {'expectedPro': expectedPro},
      );
      if (response.status != 200) {
        throw AppFailure(
          AppFailureCode.subscriptionUnavailable,
          debugContext: '${response.status}',
        );
      }
    } on FunctionException catch (error) {
      throw AppFailure(
        AppFailureCode.subscriptionUnavailable,
        debugContext: '${error.status}',
      );
    }
  }
}
