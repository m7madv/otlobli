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
      return await _withServerUsage(
        _mapStatus(customerInfo, offering.availablePackages),
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
      return await _withServerUsage(
        _mapStatus(result.customerInfo, _packages.values.toList()),
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
      return await _withServerUsage(
        _mapStatus(info, _packages.values.toList()),
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
    final subscription = await _client
        .from('subscription_state')
        .select('entitlement')
        .eq('user_id', user.id)
        .maybeSingle();
    if (subscription == null) {
      throw const AppFailure(AppFailureCode.subscriptionUnavailable);
    }
    final periods = await _client
        .from('usage_periods')
        .select(
          'plan, starts_at, ends_at, quota_minutes, used_minutes, reserved_minutes',
        )
        .eq('user_id', user.id)
        .order('starts_at', ascending: false);
    final entitlement = subscription['entitlement'] == 'pro'
        ? SubscriptionTier.pro
        : SubscriptionTier.free;
    final expectedPlan = entitlement == SubscriptionTier.pro ? 'pro' : 'free';
    final now = DateTime.now().toUtc();
    Map<String, dynamic>? activePeriod;
    for (final period in periods) {
      if (period['plan'] != expectedPlan) continue;
      final startsAt = DateTime.tryParse(period['starts_at'] as String? ?? '');
      final endsAt = DateTime.tryParse(period['ends_at'] as String? ?? '');
      if (startsAt == null || startsAt.toUtc().isAfter(now)) continue;
      if (endsAt != null && !endsAt.toUtc().isAfter(now)) continue;
      activePeriod = period;
      break;
    }
    if (activePeriod == null) {
      throw const AppFailure(AppFailureCode.subscriptionUnavailable);
    }
    final total = (activePeriod['quota_minutes'] as num?)?.toInt();
    final used = (activePeriod['used_minutes'] as num?)?.toInt();
    final reserved = (activePeriod['reserved_minutes'] as num?)?.toInt();
    if (total == null || used == null || reserved == null || total <= 0) {
      throw const AppFailure(AppFailureCode.subscriptionUnavailable);
    }
    return storeStatus.copyWith(
      tier: entitlement,
      remainingMinutes: (total - used - reserved).clamp(0, total).toInt(),
      totalMinutes: total,
    );
  }
}
