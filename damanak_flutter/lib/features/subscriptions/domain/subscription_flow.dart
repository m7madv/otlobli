import '../../../../models/store_billing.dart';
import '../../../../models/subscription.dart';

/// The immutable tenant boundary for every subscription command and callback.
///
/// [epoch] must increase whenever the signed-in account or open store changes.
/// A value-equal scope is intentional: platform callbacks do not need to retain
/// the exact Dart object that created the operation.
class BillingScope {
  const BillingScope({
    required this.accountId,
    required this.storeId,
    required this.epoch,
  }) : assert(accountId != ''),
       assert(storeId != ''),
       assert(epoch >= 0);

  final String accountId;
  final String storeId;
  final int epoch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingScope &&
          other.accountId == accountId &&
          other.storeId == storeId &&
          other.epoch == epoch;

  @override
  int get hashCode => Object.hash(accountId, storeId, epoch);
}

enum CatalogStatus { idle, loading, ready, unavailable }

class CatalogSnapshot {
  CatalogSnapshot({
    required this.status,
    required this.platform,
    required List<StoreProductOffer> offers,
    this.message,
  }) : offers = List.unmodifiable(offers);

  const CatalogSnapshot.idle()
    : status = CatalogStatus.idle,
      platform = StoreBillingPlatform.unavailable,
      offers = const [],
      message = null;

  final CatalogStatus status;
  final StoreBillingPlatform platform;
  final List<StoreProductOffer> offers;
  final String? message;

  StoreProductOffer? offer(String planId, BillingCycle cycle) {
    for (final offer in offers) {
      if (offer.planId == planId && offer.cycle == cycle) return offer;
    }
    return null;
  }
}

enum BillingOperationKind {
  preflighting,
  awaitingStore,
  pending,
  verifying,
  provisioning,
  restoring,
  reconciling,
}

enum BillingOperationOrigin {
  purchase,
  explicitRestore,
  backgroundReconciliation,
}

class BillingOperation {
  const BillingOperation({
    required this.kind,
    required this.origin,
    required this.operationId,
    required this.scope,
    this.productId,
  }) : assert(operationId != '');

  final BillingOperationKind kind;
  final BillingOperationOrigin origin;
  final String operationId;
  final BillingScope scope;
  final String? productId;

  BillingOperation advance(BillingOperationKind nextKind) => BillingOperation(
    kind: nextKind,
    origin: origin,
    operationId: operationId,
    scope: scope,
    productId: productId,
  );
}

class SubscriptionFlowState {
  const SubscriptionFlowState({
    required this.scope,
    required this.entitlement,
    required this.catalog,
    required this.operation,
    required this.message,
    required this.revision,
  });

  const SubscriptionFlowState.initial()
    : scope = null,
      entitlement = null,
      catalog = const CatalogSnapshot.idle(),
      operation = null,
      message = null,
      revision = 0;

  final BillingScope? scope;
  final SubscriptionInfo? entitlement;
  final CatalogSnapshot catalog;
  final BillingOperation? operation;
  final String? message;
  final int revision;

  bool get attached => scope != null;
  bool get operationInProgress => operation != null;
}

/// A small synchronous state machine for subscription orchestration.
///
/// It owns no I/O. Callers perform platform and backend effects, then submit
/// their result with the original scope and request/operation token. Stale
/// callbacks return false and leave [state] and [SubscriptionFlowState.revision]
/// unchanged.
class SubscriptionFlowMachine {
  SubscriptionFlowState _state = const SubscriptionFlowState.initial();
  int _highestAttachedEpoch = -1;
  String? _catalogRequestId;
  BillingScope? _catalogRequestScope;

  SubscriptionFlowState get state => _state;

  bool attach({required BillingScope scope, SubscriptionInfo? entitlement}) {
    if (scope.epoch <= _highestAttachedEpoch) return false;
    _highestAttachedEpoch = scope.epoch;
    _catalogRequestId = null;
    _catalogRequestScope = null;
    _commit(
      scope: scope,
      entitlement: entitlement,
      catalog: const CatalogSnapshot.idle(),
      operation: null,
      message: null,
    );
    return true;
  }

  bool detach({required BillingScope scope}) {
    if (!_matchesScope(scope)) return false;
    _catalogRequestId = null;
    _catalogRequestScope = null;
    _commit(
      scope: null,
      entitlement: null,
      catalog: const CatalogSnapshot.idle(),
      operation: null,
      message: null,
    );
    return true;
  }

  bool updateEntitlement({
    required BillingScope scope,
    required SubscriptionInfo? entitlement,
    String? operationId,
  }) {
    if (!_matchesScope(scope)) return false;
    if (operationId != null && !_matchesOperation(scope, operationId)) {
      return false;
    }
    // A scope-only refresh must not overwrite the result of an active purchase
    // or restore. Effects belonging to that operation must provide its token.
    if (operationId == null && _state.operation != null) return false;
    _commit(
      scope: scope,
      entitlement: entitlement,
      catalog: _state.catalog,
      operation: _state.operation,
      message: _state.message,
    );
    return true;
  }

  bool beginCatalog({required BillingScope scope, required String requestId}) {
    if (!_matchesScope(scope) || requestId.trim().isEmpty) return false;
    _catalogRequestId = requestId;
    _catalogRequestScope = scope;
    _commit(
      scope: scope,
      entitlement: _state.entitlement,
      catalog: CatalogSnapshot(
        status: CatalogStatus.loading,
        platform: _state.catalog.platform,
        offers: const [],
      ),
      operation: _state.operation,
      message: _state.message,
    );
    return true;
  }

  bool completeCatalog({
    required BillingScope scope,
    required String requestId,
    required StoreBillingPlatform platform,
    required List<StoreProductOffer> offers,
    String? message,
  }) {
    if (!_matchesCatalogRequest(scope, requestId)) return false;
    final validOffers = offers
        .where((offer) => _offerMatchesPlatform(platform, offer))
        .toList(growable: false);
    final ready =
        platform != StoreBillingPlatform.unavailable && validOffers.isNotEmpty;
    _catalogRequestId = null;
    _catalogRequestScope = null;
    _commit(
      scope: scope,
      entitlement: _state.entitlement,
      catalog: CatalogSnapshot(
        status: ready ? CatalogStatus.ready : CatalogStatus.unavailable,
        platform: platform,
        offers: validOffers,
        message:
            message ?? (ready ? null : 'لم يُرجع متجر التطبيقات باقات صالحة.'),
      ),
      operation: _state.operation,
      message: _state.message,
    );
    return true;
  }

  bool failCatalog({
    required BillingScope scope,
    required String requestId,
    required StoreBillingPlatform platform,
    required String message,
  }) {
    if (!_matchesCatalogRequest(scope, requestId)) return false;
    _catalogRequestId = null;
    _catalogRequestScope = null;
    _commit(
      scope: scope,
      entitlement: _state.entitlement,
      catalog: CatalogSnapshot(
        status: CatalogStatus.unavailable,
        platform: platform,
        offers: const [],
        message: message,
      ),
      operation: _state.operation,
      message: _state.message,
    );
    return true;
  }

  bool beginOperation(BillingOperation operation) {
    if (!_matchesScope(operation.scope) || _state.operation != null) {
      return false;
    }
    if (operation.operationId.trim().isEmpty || !_validInitialKind(operation)) {
      return false;
    }
    if (operation.origin == BillingOperationOrigin.purchase) {
      final productId = operation.productId?.trim() ?? '';
      if (productId.isEmpty ||
          !DamanakStoreCatalog.contains(_state.catalog.platform, productId)) {
        return false;
      }
    }
    _commit(
      scope: operation.scope,
      entitlement: _state.entitlement,
      catalog: _state.catalog,
      operation: operation,
      message: null,
    );
    return true;
  }

  bool advanceOperation({
    required BillingScope scope,
    required String operationId,
    required BillingOperationKind kind,
  }) {
    if (!_matchesOperation(scope, operationId)) return false;
    final current = _state.operation!;
    if (!_canAdvance(current.kind, kind)) return false;
    _commit(
      scope: scope,
      entitlement: _state.entitlement,
      catalog: _state.catalog,
      operation: current.advance(kind),
      message: _state.message,
    );
    return true;
  }

  bool markPending({
    required BillingScope scope,
    required String operationId,
    String? message,
  }) {
    if (!_matchesOperation(scope, operationId)) return false;
    final current = _state.operation!;
    if (!_canAdvance(current.kind, BillingOperationKind.pending)) return false;
    _commit(
      scope: scope,
      entitlement: _state.entitlement,
      catalog: _state.catalog,
      operation: current.advance(BillingOperationKind.pending),
      message: message ?? _state.message,
    );
    return true;
  }

  bool finishOperation({
    required BillingScope scope,
    required String operationId,
    String? message,
  }) {
    if (!_matchesOperation(scope, operationId)) return false;
    _commit(
      scope: scope,
      entitlement: _state.entitlement,
      catalog: _state.catalog,
      operation: null,
      message: message,
    );
    return true;
  }

  bool setMessage({
    required BillingScope scope,
    required String? message,
    String? operationId,
  }) {
    if (!_matchesScope(scope)) return false;
    if (operationId != null && !_matchesOperation(scope, operationId)) {
      return false;
    }
    _commit(
      scope: scope,
      entitlement: _state.entitlement,
      catalog: _state.catalog,
      operation: _state.operation,
      message: message,
    );
    return true;
  }

  bool _matchesScope(BillingScope scope) => _state.scope == scope;

  bool _matchesCatalogRequest(BillingScope scope, String requestId) =>
      _matchesScope(scope) &&
      _catalogRequestScope == scope &&
      _catalogRequestId == requestId;

  bool _matchesOperation(BillingScope scope, String operationId) {
    final operation = _state.operation;
    return operation != null &&
        operation.scope == scope &&
        operation.operationId == operationId &&
        _matchesScope(scope);
  }

  void _commit({
    required BillingScope? scope,
    required SubscriptionInfo? entitlement,
    required CatalogSnapshot catalog,
    required BillingOperation? operation,
    required String? message,
  }) {
    _state = SubscriptionFlowState(
      scope: scope,
      entitlement: entitlement,
      catalog: catalog,
      operation: operation,
      message: message,
      revision: _state.revision + 1,
    );
  }
}

bool _validInitialKind(BillingOperation operation) =>
    switch (operation.origin) {
      BillingOperationOrigin.purchase =>
        operation.kind == BillingOperationKind.preflighting,
      BillingOperationOrigin.explicitRestore =>
        operation.kind == BillingOperationKind.restoring,
      BillingOperationOrigin.backgroundReconciliation =>
        operation.kind == BillingOperationKind.reconciling,
    };

bool _canAdvance(BillingOperationKind current, BillingOperationKind next) =>
    switch (current) {
      BillingOperationKind.preflighting =>
        next == BillingOperationKind.awaitingStore ||
            next == BillingOperationKind.pending ||
            next == BillingOperationKind.verifying,
      BillingOperationKind.awaitingStore =>
        next == BillingOperationKind.pending ||
            next == BillingOperationKind.verifying,
      BillingOperationKind.pending => next == BillingOperationKind.verifying,
      BillingOperationKind.verifying =>
        next == BillingOperationKind.provisioning,
      BillingOperationKind.restoring =>
        next == BillingOperationKind.pending ||
            next == BillingOperationKind.verifying,
      BillingOperationKind.reconciling =>
        next == BillingOperationKind.pending ||
            next == BillingOperationKind.verifying,
      BillingOperationKind.provisioning => false,
    };

bool _offerMatchesPlatform(
  StoreBillingPlatform platform,
  StoreProductOffer offer,
) {
  if (!DamanakStoreCatalog.contains(platform, offer.productId) ||
      DamanakStoreCatalog.planIdFromProduct(offer.productId) != offer.planId) {
    return false;
  }
  return switch (platform) {
    StoreBillingPlatform.appStore =>
      DamanakStoreCatalog.cycleFromAppleProduct(offer.productId) == offer.cycle,
    StoreBillingPlatform.googlePlay =>
      offer.basePlanId == null ||
          DamanakStoreCatalog.cycleFromGoogleBasePlan(offer.basePlanId) ==
              offer.cycle,
    StoreBillingPlatform.unavailable => false,
  };
}

enum SubscriptionDecisionKind { start, upgrade, cycleChange, blocked }

enum SubscriptionBlockReason {
  alreadyActive,
  downgrade,
  providerConflict,
  stateUnknown,
}

sealed class SubscriptionDecision {
  const SubscriptionDecision();

  SubscriptionDecisionKind get kind;
  bool get allowed => kind != SubscriptionDecisionKind.blocked;
  SubscriptionBlockReason? get blockedReason => null;
}

final class StartSubscriptionDecision extends SubscriptionDecision {
  const StartSubscriptionDecision();

  @override
  SubscriptionDecisionKind get kind => SubscriptionDecisionKind.start;
}

final class UpgradeSubscriptionDecision extends SubscriptionDecision {
  const UpgradeSubscriptionDecision();

  @override
  SubscriptionDecisionKind get kind => SubscriptionDecisionKind.upgrade;
}

final class ChangeBillingCycleDecision extends SubscriptionDecision {
  const ChangeBillingCycleDecision();

  @override
  SubscriptionDecisionKind get kind => SubscriptionDecisionKind.cycleChange;
}

final class BlockedSubscriptionDecision extends SubscriptionDecision {
  const BlockedSubscriptionDecision(this.reason);

  final SubscriptionBlockReason reason;

  @override
  SubscriptionDecisionKind get kind => SubscriptionDecisionKind.blocked;

  @override
  SubscriptionBlockReason get blockedReason => reason;
}

abstract final class SubscriptionPolicy {
  static SubscriptionDecision evaluate({
    required SubscriptionInfo? current,
    required StoreProductOffer target,
    required StoreBillingPlatform devicePlatform,
  }) {
    if (!_offerMatchesPlatform(devicePlatform, target)) {
      return const BlockedSubscriptionDecision(
        SubscriptionBlockReason.stateUnknown,
      );
    }
    if (current == null) return const StartSubscriptionDecision();

    if (!_knownSubscriptionSnapshot(current)) {
      return const BlockedSubscriptionDecision(
        SubscriptionBlockReason.stateUnknown,
      );
    }

    if (!current.isStoreSubscription) {
      return const StartSubscriptionDecision();
    }

    final currentProvider = StoreBillingPlatformText.fromValue(
      current.billingProvider,
    );
    final currentCycle = _cycleFromValue(current.billingCycle);
    final currentProductId = current.storeProductId?.trim() ?? '';
    if (currentProvider == null ||
        currentCycle == null ||
        currentProductId.isEmpty ||
        !_currentProductMatchesSnapshot(
          current,
          currentProvider,
          currentCycle,
          currentProductId,
        )) {
      return const BlockedSubscriptionDecision(
        SubscriptionBlockReason.stateUnknown,
      );
    }

    if (!current.hasUnexpiredStorePeriod) {
      return const StartSubscriptionDecision();
    }
    if (currentProvider != devicePlatform) {
      return const BlockedSubscriptionDecision(
        SubscriptionBlockReason.providerConflict,
      );
    }
    if (currentProvider == StoreBillingPlatform.appStore &&
        (current.originalTransactionId?.trim().isEmpty ?? true)) {
      return const BlockedSubscriptionDecision(
        SubscriptionBlockReason.stateUnknown,
      );
    }

    final currentRank = DamanakStoreCatalog.planRank(current.plan.id);
    final targetRank = DamanakStoreCatalog.planRank(target.planId);
    if (targetRank < currentRank) {
      return const BlockedSubscriptionDecision(
        SubscriptionBlockReason.downgrade,
      );
    }
    if (targetRank > currentRank) {
      return const UpgradeSubscriptionDecision();
    }
    if (currentCycle == target.cycle) {
      return const BlockedSubscriptionDecision(
        SubscriptionBlockReason.alreadyActive,
      );
    }
    return const ChangeBillingCycleDecision();
  }
}

bool storeSubscriptionVerificationIsFresh(
  SubscriptionInfo subscription, {
  required DateTime now,
  Duration maxAge = const Duration(minutes: 5),
  Duration allowedFutureSkew = const Duration(minutes: 2),
}) {
  if (!subscription.canRefreshStoreBilling) return false;
  final verifiedAt = subscription.isStoreSubscription
      ? subscription.lastVerifiedAt
      : subscription.storeBillingLineageVerifiedAt;
  if (verifiedAt == null) return false;
  final age = now.toUtc().difference(verifiedAt.toUtc());
  return age >= -allowedFutureSkew && age <= maxAge;
}

bool _knownSubscriptionSnapshot(SubscriptionInfo subscription) {
  const statuses = {'trialing', 'active', 'past_due', 'canceled'};
  const sources = {'free', 'trial', 'activation_code', 'manual', 'store'};
  if (!statuses.contains(subscription.status) ||
      !sources.contains(subscription.source)) {
    return false;
  }
  if (subscription.isFreeAccess) {
    return subscription.status == 'active' &&
        subscription.billingProvider == null &&
        subscription.storeProductId == null &&
        subscription.originalTransactionId == null &&
        subscription.billingCycle == null &&
        !subscription.autoRenews &&
        subscription.lastVerifiedAt == null &&
        subscription.trialEndsAt == null &&
        subscription.periodEndsAt == null;
  }
  if (DamanakStoreCatalog.planRank(subscription.plan.id) == 0) return false;
  if (!subscription.isStoreSubscription) {
    return subscription.billingProvider == null &&
        subscription.storeProductId == null &&
        subscription.billingCycle == null;
  }
  return true;
}

bool _currentProductMatchesSnapshot(
  SubscriptionInfo current,
  StoreBillingPlatform provider,
  BillingCycle cycle,
  String productId,
) {
  if (!DamanakStoreCatalog.contains(provider, productId) ||
      DamanakStoreCatalog.planIdFromProduct(productId) != current.plan.id) {
    return false;
  }
  if (provider == StoreBillingPlatform.appStore) {
    return DamanakStoreCatalog.cycleFromAppleProduct(productId) == cycle;
  }
  return true;
}

BillingCycle? _cycleFromValue(String? value) => switch (value) {
  'monthly' => BillingCycle.monthly,
  'yearly' => BillingCycle.yearly,
  _ => null,
};
