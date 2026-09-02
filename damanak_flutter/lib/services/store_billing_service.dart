import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/store_billing.dart';

typedef StoreProductQuery =
    Future<ProductDetailsResponse> Function(Set<String> productIds);

typedef GoogleSubscriptionQuery = Future<PurchasesResultWrapper> Function();

typedef AppleSubscriptionEntitlementQuery =
    Future<List<AppleSubscriptionEntitlement>> Function();
typedef AppleUnfinishedTransactionQuery =
    Future<List<SK2Transaction>> Function();

typedef NativePurchaseCompletion =
    Future<void> Function(PurchaseDetails purchase);
typedef GooglePurchaseCompletion =
    Future<BillingResultWrapper> Function(GooglePlayPurchaseDetails purchase);

const _appleEntitlementChannel = MethodChannel(
  'com.damanak.damanak/storekit_entitlements',
);

@visibleForTesting
class AppleSubscriptionEntitlement {
  const AppleSubscriptionEntitlement({
    required this.productId,
    required this.originalTransactionId,
    this.appAccountToken,
  });

  final String productId;
  final String originalTransactionId;
  final String? appAccountToken;

  factory AppleSubscriptionEntitlement.fromChannelValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid StoreKit entitlement payload.');
    }
    final productId = value['productId'];
    if (productId is! String || productId.trim().isEmpty) {
      throw const FormatException('Missing StoreKit entitlement product.');
    }
    final originalTransactionId = value['originalTransactionId'];
    if (originalTransactionId is! String ||
        originalTransactionId.trim().isEmpty) {
      throw const FormatException(
        'Missing StoreKit original transaction identifier.',
      );
    }
    final token = value['appAccountToken'];
    if (token != null && token is! String) {
      throw const FormatException('Invalid StoreKit app account token.');
    }
    final normalizedToken = token is String ? token.trim() : null;
    return AppleSubscriptionEntitlement(
      productId: productId.trim(),
      originalTransactionId: originalTransactionId.trim(),
      appAccountToken: normalizedToken == null || normalizedToken.isEmpty
          ? null
          : normalizedToken,
    );
  }
}

Future<List<AppleSubscriptionEntitlement>>
queryAppleCurrentSubscriptionEntitlements() async {
  final values = await _appleEntitlementChannel.invokeListMethod<Object?>(
    'currentSubscriptionEntitlements',
  );
  if (values == null) {
    throw StateError('APPLE_SUBSCRIPTION_LOOKUP_FAILED');
  }
  return values
      .map(AppleSubscriptionEntitlement.fromChannelValue)
      .toList(growable: false);
}

@visibleForTesting
class AppleUnfinishedPurchaseBatch {
  const AppleUnfinishedPurchaseBatch({
    required this.purchases,
    required this.remainingPurchases,
  });

  final List<PurchaseDetails> purchases;
  final int remainingPurchases;
}

@visibleForTesting
Future<AppleUnfinishedPurchaseBatch> queryAppleUnfinishedStorePurchases({
  required AppleUnfinishedTransactionQuery queryTransactions,
  required Duration timeout,
  required String? expectedOriginalTransactionId,
  required Set<String> trustedAppAccountTokens,
  String? productId,
  int maxPurchases = 8,
  bool allowOrphanRecovery = false,
}) async {
  if (maxPurchases < 1) {
    throw ArgumentError.value(maxPurchases, 'maxPurchases');
  }
  late final List<SK2Transaction> transactions;
  try {
    transactions = await queryTransactions().timeout(timeout);
  } on TimeoutException {
    throw StateError('APPLE_SUBSCRIPTION_LOOKUP_TIMEOUT');
  } on StateError {
    rethrow;
  } on Object {
    throw StateError('APPLE_SUBSCRIPTION_LOOKUP_FAILED');
  }

  final requestedProductId = productId?.trim();
  final expectedOriginalId = expectedOriginalTransactionId?.trim() ?? '';
  final trustedTokens = trustedAppAccountTokens
      .map((token) => token.trim().toLowerCase())
      .where((token) => token.isNotEmpty)
      .toSet();
  final seenTransactionIds = <String>{};
  final eligibleByProduct = <String, List<SK2Transaction>>{};
  for (final transaction in transactions) {
    final transactionId = transaction.id.trim();
    final originalTransactionId = transaction.originalId.trim();
    final transactionProductId = transaction.productId.trim();
    final appAccountToken = transaction.appAccountToken?.trim().toLowerCase();
    final receipt = transaction.receiptData?.trim() ?? '';
    final hasRecoverableOrphanToken =
        expectedOriginalId.isEmpty &&
        allowOrphanRecovery &&
        appAccountToken != null &&
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(appAccountToken);
    final belongsToCurrentSubscription = expectedOriginalId.isNotEmpty
        ? originalTransactionId == expectedOriginalId
        : appAccountToken != null &&
              (trustedTokens.contains(appAccountToken) ||
                  hasRecoverableOrphanToken);
    if (!DamanakStoreCatalog.appleProductIds.contains(transactionProductId) ||
        (requestedProductId != null &&
            requestedProductId.isNotEmpty &&
            transactionProductId != requestedProductId) ||
        int.tryParse(transactionId) == null ||
        int.tryParse(originalTransactionId) == null ||
        receipt.isEmpty ||
        !belongsToCurrentSubscription ||
        !seenTransactionIds.add(transactionId)) {
      continue;
    }
    eligibleByProduct
        .putIfAbsent(transactionProductId, () => <SK2Transaction>[])
        .add(transaction);
  }

  for (final transactionsForProduct in eligibleByProduct.values) {
    transactionsForProduct.sort((left, right) {
      final leftDate = int.tryParse(left.purchaseDate) ?? 0;
      final rightDate = int.tryParse(right.purchaseDate) ?? 0;
      final dateOrder = rightDate.compareTo(leftDate);
      return dateOrder != 0 ? dateOrder : right.id.compareTo(left.id);
    });
  }

  // خذ معاملة واحدة من كل منتج في كل دورة. هذا يمنع تجديدات كثيرة لمنتج
  // واحد من حجب معاملة Scale السنوية العالقة، مع إبقاء الدفعة تحت حد الخادم.
  final selected = <SK2Transaction>[];
  final productOffsets = <String, int>{};
  var selectedInRound = true;
  while (selected.length < maxPurchases && selectedInRound) {
    selectedInRound = false;
    for (final product in DamanakStoreCatalog.appleProductIds) {
      final productTransactions = eligibleByProduct[product];
      final offset = productOffsets[product] ?? 0;
      if (productTransactions == null || offset >= productTransactions.length) {
        continue;
      }
      selected.add(productTransactions[offset]);
      productOffsets[product] = offset + 1;
      selectedInRound = true;
      if (selected.length == maxPurchases) break;
    }
  }

  final eligibleCount = eligibleByProduct.values.fold<int>(
    0,
    (count, values) => count + values.length,
  );
  final purchases = selected
      .map(
        (transaction) => SK2PurchaseDetails(
          productID: transaction.productId.trim(),
          purchaseID: transaction.id.trim(),
          verificationData: PurchaseVerificationData(
            localVerificationData: transaction.jsonRepresentation ?? '',
            serverVerificationData: transaction.receiptData ?? '',
            source: 'app_store',
          ),
          transactionDate: transaction.purchaseDate,
          status: PurchaseStatus.purchased,
          appAccountToken: transaction.appAccountToken,
        ),
      )
      .toList(growable: false);
  return AppleUnfinishedPurchaseBatch(
    purchases: purchases,
    remainingPurchases: eligibleCount - purchases.length,
  );
}

@visibleForTesting
Future<StoreRestoreResult> restoreAppleStorePurchases({
  required bool storeKit2Enabled,
  required AppleUnfinishedTransactionQuery queryUnfinishedTransactions,
  required Future<void> Function() restoreCurrentEntitlements,
  required void Function(List<PurchaseDetails> purchases) forwardPurchases,
  required Duration timeout,
  required String accountId,
  required String storeId,
  required String? currentOriginalTransactionId,
  required bool recoveryRequested,
}) async {
  var officialRestoreFailed = false;
  final officialRestore = () async {
    try {
      await restoreCurrentEntitlements().timeout(timeout);
    } on Object {
      officialRestoreFailed = true;
    }
  }();
  var unfinished = const AppleUnfinishedPurchaseBatch(
    purchases: <PurchaseDetails>[],
    remainingPurchases: 0,
  );
  var unfinishedLookupFailed = false;
  if (storeKit2Enabled) {
    try {
      unfinished = await queryAppleUnfinishedStorePurchases(
        queryTransactions: queryUnfinishedTransactions,
        timeout: timeout,
        expectedOriginalTransactionId: currentOriginalTransactionId,
        trustedAppAccountTokens: {accountId, storeId},
        allowOrphanRecovery: recoveryRequested,
      );
    } on Object {
      unfinishedLookupFailed = true;
    }
  }
  if (unfinished.purchases.isNotEmpty) {
    forwardPurchases(unfinished.purchases);
  }

  // Apple's supported restore must run even when the optional unfinished
  // lookup times out or fails; otherwise a repair path could break the normal
  // current-entitlements restore.
  await officialRestore;
  // StoreKit can enqueue valid current-entitlement callbacks and still return
  // an aggregate restore error for a different unverified item. The result is
  // therefore structured even without an unfinished batch so AppController
  // keeps the explicit-recovery session alive for those callbacks.
  return StoreRestoreResult(
    platform: StoreBillingPlatform.appStore,
    restoredPurchases: unfinished.purchases.isEmpty
        ? null
        : unfinished.purchases.length,
    remainingPurchases: unfinished.remainingPurchases,
    unfinishedLookupFailed: unfinishedLookupFailed,
    officialRestoreFailed: officialRestoreFailed,
  );
}

@visibleForTesting
Future<void> validateAppleSubscriptionOwnershipBeforePurchase({
  required String? currentPlanId,
  required String? currentProductId,
  required String? currentOriginalTransactionId,
  required AppleSubscriptionEntitlementQuery queryEntitlements,
  required Duration timeout,
}) async {
  // The server is authoritative for entitlement state, while StoreKit proves
  // that the Apple ID about to open the purchase sheet owns that exact chain.
  // Checking only appAccountToken is insufficient for legacy/recovered chains;
  // originalTransactionId is the stable link shared by StoreKit and the server.

  late final List<AppleSubscriptionEntitlement> entitlements;
  try {
    entitlements = await queryEntitlements().timeout(timeout);
  } on TimeoutException {
    throw StateError('APPLE_SUBSCRIPTION_LOOKUP_TIMEOUT');
  } on StateError {
    rethrow;
  } on Object {
    throw StateError('APPLE_SUBSCRIPTION_LOOKUP_FAILED');
  }

  final damanakEntitlements = entitlements
      .where(
        (entitlement) =>
            DamanakStoreCatalog.appleProductIds.contains(entitlement.productId),
      )
      .toList(growable: false);
  if (currentPlanId == null) {
    if (damanakEntitlements.isEmpty) return;
    throw StateError('APPLE_EXISTING_SUBSCRIPTION_RESTORE_REQUIRED');
  }

  final expectedProductId = currentProductId?.trim() ?? '';
  final expectedOriginalTransactionId =
      currentOriginalTransactionId?.trim() ?? '';
  if (expectedProductId.isEmpty || expectedOriginalTransactionId.isEmpty) {
    throw StateError('APPLE_SUBSCRIPTION_STATE_INVALID');
  }
  if (damanakEntitlements.length != 1) {
    throw StateError('APPLE_SUBSCRIPTION_ACCOUNT_MISMATCH');
  }
  final currentEntitlement = damanakEntitlements.single;
  if (currentEntitlement.originalTransactionId !=
      expectedOriginalTransactionId) {
    throw StateError('APPLE_SUBSCRIPTION_ACCOUNT_MISMATCH');
  }
  if (currentEntitlement.productId != expectedProductId) {
    throw StateError('APPLE_SUBSCRIPTION_STATE_CHANGED');
  }
}

@visibleForTesting
Future<void> completeGooglePlayPurchaseWithResultCheck({
  required GooglePlayPurchaseDetails purchase,
  required GooglePurchaseCompletion completePurchase,
}) async {
  final result = await completePurchase(purchase);
  if (result.responseCode != BillingResponse.ok) {
    throw StateError(
      'GOOGLE_ACKNOWLEDGEMENT_FAILED:${result.responseCode.name}',
    );
  }
}

@visibleForTesting
Future<void> completeTrackedNativePurchase({
  required Map<String, PurchaseDetails> purchases,
  required String eventKey,
  required NativePurchaseCompletion completePurchase,
}) async {
  final native = purchases[eventKey];
  if (native == null) return;
  if (native.pendingCompletePurchase) {
    await completePurchase(native);
  }
  if (identical(purchases[eventKey], native)) {
    purchases.remove(eventKey);
  }
}

@visibleForTesting
class GoogleSubscriptionSnapshot {
  const GoogleSubscriptionSnapshot({
    required this.purchased,
    required this.pending,
    required this.accountMismatchDetected,
  });

  final List<GooglePlayPurchaseDetails> purchased;
  final List<GooglePlayPurchaseDetails> pending;
  final bool accountMismatchDetected;

  GooglePlayPurchaseDetails? get latestPurchase => purchased.firstOrNull;

  int get pendingReplacementCount => purchased
      .where(
        (purchase) =>
            purchase.billingClientPurchase.pendingPurchaseUpdate != null,
      )
      .length;
}

@visibleForTesting
GoogleSubscriptionSnapshot selectGoogleSubscriptionPurchases({
  required PurchasesResultWrapper response,
  required String accountId,
  bool includeUnboundForRestore = false,
  bool recoveryRequested = false,
}) {
  // queryPurchases in in_app_purchase_android 0.5.0 force-fills the legacy
  // responseCode with OK. billingResult carries the actual BillingClient
  // outcome, so both fields must be successful before an empty list is trusted.
  final billingResponseCode = response.billingResult.responseCode;
  if (response.responseCode != BillingResponse.ok ||
      billingResponseCode != BillingResponse.ok) {
    final failureCode = billingResponseCode != BillingResponse.ok
        ? billingResponseCode
        : response.responseCode;
    throw StateError('GOOGLE_SUBSCRIPTION_LOOKUP_FAILED:${failureCode.name}');
  }

  final purchased = <GooglePlayPurchaseDetails>[];
  final pending = <GooglePlayPurchaseDetails>[];
  var accountMismatchDetected = false;
  for (final wrapper in response.purchasesList) {
    final catalogPurchases = GooglePlayPurchaseDetails.fromPurchase(wrapper)
        .where(
          (purchase) =>
              DamanakStoreCatalog.googleProductIds.contains(purchase.productID),
        );
    if (catalogPurchases.isEmpty) continue;

    final purchaseAccountId = wrapper.obfuscatedAccountId?.trim();
    final accountIsMissing =
        purchaseAccountId == null || purchaseAccountId.isEmpty;
    // Normal purchases remain strict. Restore may forward one legacy candidate
    // whose local account binding is absent; only the user's explicit recovery
    // action may forward a non-empty binding for a different local account.
    // The backend still verifies the signed Play token lineage authoritatively.
    if (purchaseAccountId != accountId) {
      accountMismatchDetected = true;
      if (!recoveryRequested &&
          !(includeUnboundForRestore && accountIsMissing)) {
        continue;
      }
    }
    for (final purchase in catalogPurchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          purchased.add(purchase);
        case PurchaseStatus.pending:
          pending.add(purchase);
        case PurchaseStatus.canceled:
        case PurchaseStatus.error:
          break;
      }
    }
  }

  int newestFirst(
    GooglePlayPurchaseDetails first,
    GooglePlayPurchaseDetails second,
  ) {
    final firstTime = int.tryParse(first.transactionDate ?? '') ?? 0;
    final secondTime = int.tryParse(second.transactionDate ?? '') ?? 0;
    return secondTime.compareTo(firstTime);
  }

  purchased.sort(newestFirst);
  pending.sort(newestFirst);
  return GoogleSubscriptionSnapshot(
    purchased: List.unmodifiable(purchased),
    pending: List.unmodifiable(pending),
    accountMismatchDetected: accountMismatchDetected,
  );
}

@visibleForTesting
List<GooglePlayPurchaseDetails> validatedGoogleSubscriptionsForRestore(
  GoogleSubscriptionSnapshot snapshot, {
  required String storeId,
  bool recoveryRequested = false,
}) {
  final candidates = [...snapshot.purchased, ...snapshot.pending];
  final matchingStore = candidates
      .where((purchase) {
        final purchaseStoreId = purchase
            .billingClientPurchase
            .obfuscatedProfileId
            ?.trim();
        return purchaseStoreId == storeId;
      })
      .toList(growable: false);
  if (matchingStore.length > 1) {
    throw StateError('GOOGLE_MULTIPLE_SUBSCRIPTIONS');
  }
  if (matchingStore.isNotEmpty) return List.unmodifiable(matchingStore);

  final recoveryCandidates = candidates
      .where((purchase) {
        final purchaseStoreId = purchase
            .billingClientPurchase
            .obfuscatedProfileId
            ?.trim();
        if (recoveryRequested) return purchaseStoreId != storeId;
        return purchaseStoreId == null || purchaseStoreId.isEmpty;
      })
      .toList(growable: false);
  if (recoveryCandidates.length > 1) {
    throw StateError('GOOGLE_MULTIPLE_SUBSCRIPTIONS');
  }
  return List.unmodifiable(recoveryCandidates);
}

@visibleForTesting
GooglePlayPurchaseDetails? validatedGoogleSubscriptionForPurchase({
  required GoogleSubscriptionSnapshot snapshot,
  required String storeId,
  required bool requireExistingSubscription,
}) {
  final candidates = [...snapshot.purchased, ...snapshot.pending];
  final hasUnboundLegacyStore = candidates.any((purchase) {
    final purchaseStoreId = purchase.billingClientPurchase.obfuscatedProfileId
        ?.trim();
    return purchaseStoreId == null || purchaseStoreId.isEmpty;
  });
  // An unbound legacy token can still be the backend's current receipt for this
  // store. Even when another candidate is explicitly store-bound, replacing it
  // without a token-level server preflight could mutate the wrong Play lineage.
  if (hasUnboundLegacyStore) {
    throw StateError('GOOGLE_SUBSCRIPTION_STORE_CONFLICT');
  }

  final matchingStore = candidates
      .where((purchase) {
        final purchaseStoreId = purchase
            .billingClientPurchase
            .obfuscatedProfileId
            ?.trim();
        return purchaseStoreId == storeId;
      })
      .toList(growable: false);
  if (matchingStore.length > 1) {
    throw StateError('GOOGLE_MULTIPLE_SUBSCRIPTIONS');
  }
  if (matchingStore.isNotEmpty) {
    final existing = matchingStore.single;
    if (existing.status == PurchaseStatus.pending ||
        existing.billingClientPurchase.pendingPurchaseUpdate != null) {
      throw StateError('GOOGLE_SUBSCRIPTION_PENDING');
    }
    // Play can know about an out-of-app purchase before the Damanak backend has
    // reconciled it. Never reinterpret that owned item as a fresh purchase or a
    // replacement based on a missing server cycle; explicit restore verifies it.
    if (!requireExistingSubscription) {
      throw StateError('GOOGLE_EXISTING_SUBSCRIPTION_RESTORE_REQUIRED');
    }
    return existing;
  }

  if (snapshot.accountMismatchDetected) {
    throw StateError('GOOGLE_SUBSCRIPTION_ACCOUNT_CONFLICT');
  }

  final hasDifferentStore = candidates.any((purchase) {
    final purchaseStoreId = purchase.billingClientPurchase.obfuscatedProfileId
        ?.trim();
    return purchaseStoreId != null &&
        purchaseStoreId.isNotEmpty &&
        purchaseStoreId != storeId;
  });
  // A token explicitly bound elsewhere must never become this store's old
  // purchase. If this store has no exact candidate, do not adopt another one.
  if (hasDifferentStore) {
    throw StateError('GOOGLE_SUBSCRIPTION_STORE_CONFLICT');
  }
  if (requireExistingSubscription) {
    throw StateError('GOOGLE_EXISTING_SUBSCRIPTION_NOT_FOUND');
  }
  return null;
}

@visibleForTesting
ReplacementMode googleSubscriptionReplacementMode({
  required String existingProductId,
  required BillingCycle? existingCycle,
  required StoreProductOffer replacement,
}) {
  final existingPlanId = DamanakStoreCatalog.planIdFromProduct(
    existingProductId,
  );
  final existingRank = DamanakStoreCatalog.planRank(existingPlanId);
  final replacementRank = DamanakStoreCatalog.planRank(replacement.planId);
  if (existingRank == 0 ||
      replacementRank == 0 ||
      !DamanakStoreCatalog.googleProductIds.contains(replacement.productId)) {
    throw StateError('GOOGLE_SUBSCRIPTION_TRANSITION_INVALID');
  }

  // Product policy is upgrade-only while a higher subscription is active.
  // Never open Google Play with a deferred lower entitlement.
  if (replacementRank < existingRank) {
    throw StateError('GOOGLE_SUBSCRIPTION_DOWNGRADE_NOT_ALLOWED');
  }

  if (existingCycle == null) {
    throw StateError('GOOGLE_EXISTING_CYCLE_UNKNOWN');
  }
  if (existingProductId == replacement.productId &&
      existingCycle == replacement.cycle) {
    throw StateError('GOOGLE_SUBSCRIPTION_ALREADY_ACTIVE');
  }

  if (existingCycle != replacement.cycle) {
    // A cross-tier cycle change must never grant a higher entitlement while
    // deferring its price until renewal. Start that upgrade at full price.
    // For a base-plan switch inside the same subscription, Google only permits
    // full-price or no-proration replacement modes.
    if (replacementRank > existingRank) {
      return ReplacementMode.chargeFullPrice;
    }
    return switch ((existingCycle, replacement.cycle)) {
      (BillingCycle.monthly, BillingCycle.yearly) =>
        ReplacementMode.chargeFullPrice,
      (BillingCycle.yearly, BillingCycle.monthly) =>
        ReplacementMode.withoutProration,
      _ => throw StateError('GOOGLE_SUBSCRIPTION_TRANSITION_INVALID'),
    };
  }
  if (replacementRank > existingRank) {
    return ReplacementMode.chargeProratedPrice;
  }
  throw StateError('GOOGLE_SUBSCRIPTION_TRANSITION_INVALID');
}

@visibleForTesting
StoreSubscriptionTransitionKind validateStoreSubscriptionPurchase({
  required String? currentPlanId,
  required BillingCycle? currentCycle,
  required StoreProductOffer offer,
}) {
  if (currentPlanId != null &&
      (DamanakStoreCatalog.planRank(currentPlanId) == 0 ||
          currentCycle == null)) {
    throw StateError('STORE_SUBSCRIPTION_STATE_INVALID');
  }
  final transition = DamanakStoreCatalog.subscriptionTransition(
    hasActiveStoreSubscription: currentPlanId != null,
    currentPlanId: currentPlanId,
    currentBillingCycle: currentCycle?.value,
    targetPlanId: offer.planId,
    targetCycle: offer.cycle,
  );
  if (!transition.canStartPurchase) {
    throw StateError(
      transition == StoreSubscriptionTransitionKind.current
          ? 'STORE_SUBSCRIPTION_ALREADY_ACTIVE'
          : 'STORE_SUBSCRIPTION_DOWNGRADE_NOT_ALLOWED',
    );
  }
  return transition;
}

@visibleForTesting
StorePurchaseStatus storePurchaseEventStatus(
  PurchaseDetails purchase, {
  required bool restoring,
}) {
  // Google keeps the current subscription in the purchased state while a
  // deferred replacement is waiting for renewal. pendingPurchaseUpdate
  // describes that future replacement, not a pending payment for the current
  // entitlement. Explicit restore must verify the currently owned token;
  // outside restore, keep the replacement pending until Play commits it.
  if (restoring && purchase.status == PurchaseStatus.purchased) {
    return StorePurchaseStatus.restored;
  }
  if (purchase is GooglePlayPurchaseDetails &&
      purchase.billingClientPurchase.pendingPurchaseUpdate != null) {
    return StorePurchaseStatus.pending;
  }
  return switch (purchase.status) {
    PurchaseStatus.pending => StorePurchaseStatus.pending,
    PurchaseStatus.purchased => StorePurchaseStatus.purchased,
    PurchaseStatus.restored => StorePurchaseStatus.restored,
    PurchaseStatus.canceled => StorePurchaseStatus.canceled,
    PurchaseStatus.error => StorePurchaseStatus.error,
  };
}

@visibleForTesting
String resolveStorePurchaseProductId({
  required String productId,
  required PurchaseStatus status,
  String? activeProductId,
}) {
  final normalizedProductId = productId.trim();
  if (normalizedProductId.isNotEmpty) return normalizedProductId;
  if (status != PurchaseStatus.canceled && status != PurchaseStatus.error) {
    return normalizedProductId;
  }
  return activeProductId?.trim() ?? normalizedProductId;
}

@visibleForTesting
StreamController<List<StorePurchaseEvent>>
createBufferedStorePurchaseController() =>
    StreamController<List<StorePurchaseEvent>>();

@visibleForTesting
Future<ProductDetailsResponse> queryAppleStoreProducts({
  required Set<String> productIds,
  required StoreProductQuery storeKit2Query,
  required StoreProductQuery storeKit1Query,
  required Duration timeout,
}) async {
  final stopwatch = Stopwatch()..start();
  final responses = <ProductDetailsResponse>[];
  PlatformException? platformError;

  Set<String> missingIds() {
    final found = responses
        .expand((response) => response.productDetails)
        .map((product) => product.id)
        .toSet();
    return productIds.difference(found);
  }

  Duration? remainingTimeout() {
    final remaining = timeout - stopwatch.elapsed;
    if (remaining <= Duration.zero) return null;
    return remaining;
  }

  Future<void> collect(
    StoreProductQuery query,
    Set<String> ids, {
    required Duration maximumTimeout,
  }) async {
    if (ids.isEmpty) return;
    final remaining = remainingTimeout();
    if (remaining == null) {
      return;
    }
    final boundedTimeout = remaining < maximumTimeout
        ? remaining
        : maximumTimeout;
    try {
      responses.add(await query(ids).timeout(boundedTimeout));
    } on TimeoutException {
      // Keep the single overall deadline and let the remaining fallback run.
    } on PlatformException catch (error) {
      platformError ??= error;
    }
  }

  // StoreKit 2 remains the primary source, but reserve half of the single
  // overall deadline for StoreKit 1. A tiny fallback window made valid catalog
  // responses lose a race against the timer on slower iPhones.
  final storeKit2Budget = Duration(microseconds: timeout.inMicroseconds ~/ 2);
  await collect(storeKit2Query, productIds, maximumTimeout: storeKit2Budget);
  var missing = missingIds();
  if (missing.isEmpty) {
    return _mergeProductResponses(productIds: productIds, responses: responses);
  }

  // Merge StoreKit 1 results only for identifiers StoreKit 2 omitted. A
  // partial StoreKit 2 response must not hide otherwise valid plans.
  await collect(storeKit1Query, missing, maximumTimeout: timeout);
  missing = missingIds();

  if (responses.isNotEmpty) {
    return _mergeProductResponses(productIds: productIds, responses: responses);
  }
  if (platformError != null) throw platformError!;
  throw TimeoutException('Apple product lookup timed out.');
}

ProductDetailsResponse _mergeProductResponses({
  required Set<String> productIds,
  required Iterable<ProductDetailsResponse> responses,
}) {
  final productsById = <String, ProductDetails>{};
  IAPError? firstError;
  for (final response in responses) {
    final responseIsExplicitEmptyCatalog =
        response.productDetails.isEmpty &&
        response.notFoundIDs.toSet().containsAll(productIds);
    if (!responseIsExplicitEmptyCatalog) {
      firstError ??= response.error;
    }
    for (final product in response.productDetails) {
      productsById[product.id] = product;
    }
  }
  final foundIds = productsById.keys.toSet();
  final missingIds = productIds.difference(foundIds).toList()..sort();
  return ProductDetailsResponse(
    productDetails: productsById.values.toList(growable: false),
    notFoundIDs: missingIds,
    error: productsById.isEmpty ? firstError : null,
  );
}

@visibleForTesting
ProductDetailsResponse googleSubscriptionProductResponse({
  required Set<String> productIds,
  required ProductDetailsResponseWrapper response,
}) {
  final products = response.productDetailsList
      .where((product) => product.productType == ProductType.subs)
      .expand(GooglePlayProductDetails.fromProductDetails)
      .toList(growable: false);
  final foundIds = products.map((product) => product.id).toSet();
  final unfetchedIds = response.unfetchedProductList
      .map((product) => product.productId)
      .toSet();
  final missingIds = {
    ...productIds.difference(foundIds),
    ...unfetchedIds,
  }.toList()..sort();
  final succeeded = response.responseCode == BillingResponse.ok;
  return ProductDetailsResponse(
    productDetails: products,
    notFoundIDs: missingIds,
    error: succeeded || products.isNotEmpty
        ? null
        : IAPError(
            source: 'google_play',
            code: response.responseCode.name,
            message:
                response.billingResult.debugMessage ??
                'تعذر جلب اشتراكات Google Play.',
            details: {
              'subResponseCode': response.billingResult.subResponseCode,
              'unfetchedProductIds': unfetchedIds.toList()..sort(),
            },
          ),
  );
}

Future<ProductDetailsResponse> _queryGoogleSubscriptionProducts({
  required Set<String> productIds,
  required Duration timeout,
}) async {
  final platform = InAppPurchasePlatform.instance;
  if (platform is! InAppPurchaseAndroidPlatform) {
    throw StateError('GOOGLE_PLAY_PLATFORM_UNAVAILABLE');
  }

  // The generic Flutter API queries every identifier as both an in-app item
  // and a subscription. With Play Billing 8, a failed in-app query can discard
  // the valid subscription response. Damanak only sells subscriptions, so ask
  // the already-connected Android billing client for that product type alone.
  // ignore: invalid_use_of_visible_for_testing_member
  final response = await platform.billingClientManager
      .runWithClient(
        (client) => client.queryProductDetails(
          productList: productIds
              .map(
                (productId) => ProductWrapper(
                  productId: productId,
                  productType: ProductType.subs,
                ),
              )
              .toList(growable: false),
        ),
      )
      .timeout(timeout);
  return googleSubscriptionProductResponse(
    productIds: productIds,
    response: response,
  );
}

const _gulfStorefrontCountryCodes = {
  'SA',
  'SAU',
  'AE',
  'ARE',
  'QA',
  'QAT',
  'KW',
  'KWT',
  'BH',
  'BHR',
  'OM',
  'OMN',
};

@visibleForTesting
String appleCatalogUnavailableMessage(String? storefrontCountryCode) {
  final countryCode = storefrontCountryCode?.trim().toUpperCase();
  if (countryCode != null &&
      countryCode.isNotEmpty &&
      !_gulfStorefrontCountryCodes.contains(countryCode)) {
    return 'متجر Apple المستخدم للمشتريات هو $countryCode، بينما خطط ضمانك '
        'متاحة في دول الخليج فقط. غيّر بلد حساب App Store إلى قطر ثم أعد المحاولة. '
        'رمز التشخيص: APPLE-STOREFRONT-$countryCode.';
  }
  if (countryCode == null || countryCode.isEmpty) {
    return 'لم يحدد App Store بلد حساب المشتريات، ولم يُرجع أي خطة. تحقق من '
        'تسجيل الدخول إلى الوسائط والمشتريات ثم أعد المحاولة. '
        'رمز التشخيص: APPLE-STOREFRONT-UNKNOWN.';
  }
  return 'اتصل التطبيق بمتجر Apple في $countryCode، لكن المتجر أعاد 0 من 6 '
      'خطط. تحقق من حساب الوسائط والمشتريات ثم أعد المحاولة. '
      'رمز التشخيص: APPLE-CATALOG-0-$countryCode.';
}

abstract interface class StoreBillingService {
  Stream<List<StorePurchaseEvent>> get purchaseUpdates;

  Future<StoreProductLoadResult> loadProducts({required String accountId});
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
    required String? currentPlanId,
    required String? currentProductId,
    required String? currentOriginalTransactionId,
    required BillingCycle? currentCycle,
    required bool requireExistingSubscription,
  });
  Future<StoreRestoreResult> restorePurchases({
    required String accountId,
    required String storeId,
    String? currentOriginalTransactionId,
    bool recoveryRequested = false,
  });
  Future<void> completePurchase(StorePurchaseEvent event);
  Future<bool> openSubscriptionManagement(
    StoreBillingPlatform provider, {
    String? productId,
  });
  Future<void> dispose();
}

Future<StoreBillingService> createStoreBillingService() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return const UnavailableStoreBillingService();
  }
  return PlatformStoreBillingService();
}

class UnavailableStoreBillingService implements StoreBillingService {
  const UnavailableStoreBillingService();

  @override
  Stream<List<StorePurchaseEvent>> get purchaseUpdates => const Stream.empty();

  @override
  Future<StoreProductLoadResult> loadProducts({
    required String accountId,
  }) async => const StoreProductLoadResult(
    available: false,
    platform: StoreBillingPlatform.unavailable,
    offers: [],
    errorMessage: 'تتوفر الاشتراكات داخل تطبيق Android أو iPhone فقط.',
  );

  @override
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
    required String? currentPlanId,
    required String? currentProductId,
    required String? currentOriginalTransactionId,
    required BillingCycle? currentCycle,
    required bool requireExistingSubscription,
  }) => throw StateError('STORE_UNAVAILABLE');

  @override
  Future<StoreRestoreResult> restorePurchases({
    required String accountId,
    required String storeId,
    String? currentOriginalTransactionId,
    bool recoveryRequested = false,
  }) => throw StateError('STORE_UNAVAILABLE');

  @override
  Future<void> completePurchase(StorePurchaseEvent event) async {}

  @override
  Future<bool> openSubscriptionManagement(
    StoreBillingPlatform provider, {
    String? productId,
  }) async => false;

  @override
  Future<void> dispose() async {}
}

class PlatformStoreBillingService implements StoreBillingService {
  PlatformStoreBillingService({
    InAppPurchase? client,
    GoogleSubscriptionQuery? googleSubscriptionQuery,
    GooglePurchaseCompletion? googlePurchaseCompletion,
    AppleSubscriptionEntitlementQuery? appleSubscriptionEntitlementQuery,
    AppleUnfinishedTransactionQuery? appleUnfinishedTransactionQuery,
    this.availabilityTimeout = const Duration(seconds: 6),
    this.productQueryTimeout = const Duration(seconds: 16),
    this.purchaseLookupTimeout = const Duration(seconds: 8),
  }) : _client = client ?? InAppPurchase.instance,
       _googleSubscriptionQueryOverride = googleSubscriptionQuery,
       _googlePurchaseCompletionOverride = googlePurchaseCompletion,
       _appleSubscriptionEntitlementQueryOverride =
           appleSubscriptionEntitlementQuery,
       _appleUnfinishedTransactionQueryOverride =
           appleUnfinishedTransactionQuery {
    _purchaseSubscription = _client.purchaseStream.listen(
      _forwardPurchases,
      onError: (Object error) {
        final launch = _activeLaunchIfFresh();
        _updates.add([
          StorePurchaseEvent(
            key: 'stream-${DateTime.now().microsecondsSinceEpoch}',
            status: StorePurchaseStatus.error,
            platform: platform,
            productId: launch?.productId ?? '',
            verificationData: '',
            verificationSource: '',
            needsCompletion: false,
            errorCode: 'purchase_stream',
            errorMessage: error.toString(),
            accountId: launch?.accountId,
            storeId: launch?.storeId,
          ),
        ]);
        _activeLaunch = null;
      },
    );
  }

  final InAppPurchase _client;
  final Duration availabilityTimeout;
  final Duration productQueryTimeout;
  final Duration purchaseLookupTimeout;
  final GoogleSubscriptionQuery? _googleSubscriptionQueryOverride;
  final GooglePurchaseCompletion? _googlePurchaseCompletionOverride;
  final AppleSubscriptionEntitlementQuery?
  _appleSubscriptionEntitlementQueryOverride;
  final AppleUnfinishedTransactionQuery?
  _appleUnfinishedTransactionQueryOverride;
  final StreamController<List<StorePurchaseEvent>> _updates =
      createBufferedStorePurchaseController();
  final Map<String, ProductDetails> _nativeProducts = {};
  final Map<String, PurchaseDetails> _nativePurchases = {};
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  bool _purchaseLaunchInProgress = false;
  _ActiveStorePurchaseLaunch? _activeLaunch;

  StoreBillingPlatform get platform {
    if (kIsWeb) return StoreBillingPlatform.unavailable;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => StoreBillingPlatform.googlePlay,
      TargetPlatform.iOS => StoreBillingPlatform.appStore,
      _ => StoreBillingPlatform.unavailable,
    };
  }

  @override
  Stream<List<StorePurchaseEvent>> get purchaseUpdates => _updates.stream;

  @override
  Future<StoreProductLoadResult> loadProducts({
    required String accountId,
  }) async {
    if (platform == StoreBillingPlatform.unavailable) {
      return const StoreProductLoadResult(
        available: false,
        platform: StoreBillingPlatform.unavailable,
        offers: [],
        errorMessage: 'تتوفر الاشتراكات داخل تطبيق Android أو iPhone فقط.',
      );
    }
    try {
      final available = await _client.isAvailable().timeout(
        availabilityTimeout,
      );
      if (!available) {
        return StoreProductLoadResult(
          available: false,
          platform: platform,
          offers: const [],
          errorMessage: 'تعذر الاتصال بـ${platform.label}.',
        );
      }

      final ids = platform == StoreBillingPlatform.googlePlay
          ? DamanakStoreCatalog.googleProductIds
          : DamanakStoreCatalog.appleProductIds;
      final appleCountryCode = platform == StoreBillingPlatform.appStore
          ? _appleStorefrontCountryCode()
          : Future<String?>.value();
      final response = platform == StoreBillingPlatform.appStore
          ? await queryAppleStoreProducts(
              productIds: ids,
              storeKit2Query: _client.queryProductDetails,
              storeKit1Query: _queryAppleProductsWithStoreKit1,
              timeout: productQueryTimeout,
            )
          : await _queryGoogleSubscriptionProducts(
              productIds: ids,
              timeout: productQueryTimeout,
            );
      final storefrontCountryCode = await appleCountryCode;

      _nativeProducts.clear();
      final offers = <StoreProductOffer>[];
      for (final product in response.productDetails) {
        final offer = _toOffer(product);
        if (offer == null) continue;
        final existing = offers.indexWhere((item) => item.key == offer.key);
        if (existing >= 0) {
          final current = offers[existing];
          if (offer.rawPrice < current.rawPrice) {
            offers[existing] = offer;
            _nativeProducts[offer.key] = product;
          }
        } else {
          offers.add(offer);
          _nativeProducts[offer.key] = product;
        }
      }
      offers.sort((a, b) {
        final plan = DamanakStoreCatalog.planRank(
          a.planId,
        ).compareTo(DamanakStoreCatalog.planRank(b.planId));
        return plan != 0 ? plan : a.cycle.index.compareTo(b.cycle.index);
      });
      return StoreProductLoadResult(
        available: response.error == null,
        platform: platform,
        offers: offers,
        missingProductIds: response.notFoundIDs,
        errorMessage: response.error != null
            ? 'تعذر جلب الأسعار من ${platform.label}. حاول مرة أخرى. '
                  'رمز المتجر: ${response.error!.code}.'
            : platform == StoreBillingPlatform.appStore && offers.isEmpty
            ? appleCatalogUnavailableMessage(storefrontCountryCode)
            : platform == StoreBillingPlatform.googlePlay && offers.isEmpty
            ? 'اتصل التطبيق بـGoogle Play، لكن المتجر لم يُرجع أي خطة. '
                  'رمز التشخيص: GOOGLE-CATALOG-'
                  '${response.productDetails.length}-'
                  '${response.notFoundIDs.length}.'
            : null,
      );
    } on TimeoutException {
      return StoreProductLoadResult(
        available: false,
        platform: platform,
        offers: const [],
        errorMessage:
            'استغرق ${platform.label} وقتاً طويلاً. تحقق من الاتصال ثم أعد المحاولة.',
      );
    } on PlatformException catch (error) {
      return StoreProductLoadResult(
        available: false,
        platform: platform,
        offers: const [],
        errorMessage:
            'تعذر جلب الأسعار من ${platform.label}. حاول مرة أخرى. '
            'رمز المتجر: ${error.code}.',
      );
    }
  }

  Future<String?> _appleStorefrontCountryCode() async {
    try {
      final countryCode = await _client.countryCode().timeout(
        const Duration(seconds: 4),
      );
      final normalized = countryCode.trim().toUpperCase();
      return normalized.isEmpty ? null : normalized;
    } on TimeoutException {
      return null;
    } on PlatformException {
      return null;
    } on UnimplementedError {
      return null;
    }
  }

  Future<ProductDetailsResponse> _queryAppleProductsWithStoreKit1(
    Set<String> productIds,
  ) async {
    try {
      final response = await SKRequestMaker().startProductRequest(
        productIds.toList(growable: false),
      );
      return ProductDetailsResponse(
        productDetails: response.products
            .map(AppStoreProductDetails.fromSKProduct)
            .toList(growable: false),
        notFoundIDs: response.invalidProductIdentifiers,
      );
    } on PlatformException catch (error) {
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: productIds.toList(growable: false),
        error: IAPError(
          source: 'app_store',
          code: error.code,
          message: error.message ?? 'تعذر جلب أسعار App Store.',
          details: error.details,
        ),
      );
    }
  }

  StoreProductOffer? _toOffer(ProductDetails product) {
    final planId = DamanakStoreCatalog.planIdFromProduct(product.id);
    if (planId == null) return null;

    BillingCycle? cycle;
    String? basePlanId;
    if (product is GooglePlayProductDetails) {
      final index = product.subscriptionIndex;
      final details = index == null
          ? null
          : product.productDetails.subscriptionOfferDetails?[index];
      if (details == null || details.offerId != null) return null;
      basePlanId = details.basePlanId;
      cycle = DamanakStoreCatalog.cycleFromGoogleBasePlan(basePlanId);
    } else {
      cycle = DamanakStoreCatalog.cycleFromAppleProduct(product.id);
    }
    if (cycle == null) return null;
    final key = '$planId:${cycle.value}';
    return StoreProductOffer(
      key: key,
      planId: planId,
      cycle: cycle,
      productId: product.id,
      basePlanId: basePlanId,
      title: product.title,
      description: product.description,
      localizedPrice: product.price,
      rawPrice: product.rawPrice,
      currencyCode: product.currencyCode,
    );
  }

  Future<PurchasesResultWrapper> _queryGoogleSubscriptions() async {
    final override = _googleSubscriptionQueryOverride;
    if (override != null) return override();

    final nativePlatform = InAppPurchasePlatform.instance;
    if (nativePlatform is! InAppPurchaseAndroidPlatform) {
      throw StateError('GOOGLE_PLAY_PLATFORM_UNAVAILABLE');
    }
    // Damanak has no one-time Play products. Querying only `subs` prevents an
    // unrelated in-app-product response from obscuring subscription state.
    // ignore: invalid_use_of_visible_for_testing_member
    return nativePlatform.billingClientManager.runWithClient(
      (client) => client.queryPurchases(ProductType.subs),
    );
  }

  Future<GoogleSubscriptionSnapshot> _queryGoogleSubscriptionSnapshot(
    String accountId, {
    bool includeUnboundForRestore = false,
    bool recoveryRequested = false,
  }) async {
    final response = await _queryGoogleSubscriptions();
    return selectGoogleSubscriptionPurchases(
      response: response,
      accountId: accountId,
      includeUnboundForRestore: includeUnboundForRestore,
      recoveryRequested: recoveryRequested,
    );
  }

  @override
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
    required String? currentPlanId,
    required String? currentProductId,
    required String? currentOriginalTransactionId,
    required BillingCycle? currentCycle,
    required bool requireExistingSubscription,
  }) async {
    validateStoreSubscriptionPurchase(
      currentPlanId: currentPlanId,
      currentCycle: currentCycle,
      offer: offer,
    );
    if (_purchaseLaunchInProgress) {
      throw StateError('STORE_PURCHASE_IN_PROGRESS');
    }
    final product = _nativeProducts[offer.key];
    if (product == null) throw StateError('STORE_PRODUCT_UNAVAILABLE');

    _ActiveStorePurchaseLaunch? launch;
    _purchaseLaunchInProgress = true;
    try {
      if (platform == StoreBillingPlatform.appStore) {
        await validateAppleSubscriptionOwnershipBeforePurchase(
          currentPlanId: currentPlanId,
          currentProductId: currentProductId,
          currentOriginalTransactionId: currentOriginalTransactionId,
          queryEntitlements:
              _appleSubscriptionEntitlementQueryOverride ??
              queryAppleCurrentSubscriptionEntitlements,
          timeout: purchaseLookupTimeout,
        );
      }

      launch = _ActiveStorePurchaseLaunch(
        productId: offer.productId,
        accountId: accountId,
        storeId: storeId,
        startedAt: DateTime.now(),
      );
      _activeLaunch = launch;
      if (product is GooglePlayProductDetails) {
        await _purchaseGoogleSubscription(
          product,
          offer: offer,
          accountId: accountId,
          storeId: storeId,
          currentCycle: currentCycle,
          requireExistingSubscription: requireExistingSubscription,
        );
        return;
      }

      final launched = await _client.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          // StoreKit 2 persists this UUID as appAccountToken. Binding it to the
          // store prevents a late transaction from being attached to another
          // workspace owned by the same account.
          applicationUserName: storeId,
        ),
      );
      if (!launched) throw StateError('STORE_PURCHASE_NOT_LAUNCHED');
    } catch (_) {
      if (launch != null && identical(_activeLaunch, launch)) {
        _activeLaunch = null;
      }
      rethrow;
    } finally {
      _purchaseLaunchInProgress = false;
    }
  }

  Future<void> _purchaseGoogleSubscription(
    GooglePlayProductDetails product, {
    required StoreProductOffer offer,
    required String accountId,
    required String storeId,
    required BillingCycle? currentCycle,
    required bool requireExistingSubscription,
  }) async {
    GoogleSubscriptionSnapshot snapshot;
    try {
      snapshot = await _queryGoogleSubscriptionSnapshot(
        accountId,
      ).timeout(purchaseLookupTimeout);
    } on TimeoutException {
      throw StateError('GOOGLE_SUBSCRIPTION_LOOKUP_TIMEOUT');
    } on StateError {
      rethrow;
    } on Object {
      throw StateError('GOOGLE_SUBSCRIPTION_LOOKUP_FAILED');
    }

    final existing = validatedGoogleSubscriptionForPurchase(
      snapshot: snapshot,
      storeId: storeId,
      requireExistingSubscription: requireExistingSubscription,
    );
    final replacementMode = existing == null
        ? null
        : googleSubscriptionReplacementMode(
            existingProductId: existing.productID,
            existingCycle: currentCycle,
            replacement: offer,
          );

    final nativePlatform = InAppPurchasePlatform.instance;
    if (nativePlatform is! InAppPurchaseAndroidPlatform) {
      throw StateError('GOOGLE_PLAY_PLATFORM_UNAVAILABLE');
    }
    // Use the native client so both local tenant identifiers reach Play. The
    // generic GooglePlayPurchaseParam exposes accountId but not profileId.
    // ignore: invalid_use_of_visible_for_testing_member
    final result = await nativePlatform.billingClientManager.runWithClient(
      (client) => client.launchBillingFlow(
        product: product.id,
        offerToken: product.offerToken,
        accountId: accountId,
        obfuscatedProfileId: storeId,
        oldProduct: existing?.productID,
        purchaseToken: existing?.verificationData.serverVerificationData,
        replacementMode: replacementMode,
      ),
    );
    if (result.responseCode != BillingResponse.ok) {
      throw StateError(
        'STORE_PURCHASE_NOT_LAUNCHED:${result.responseCode.name}',
      );
    }
  }

  void _forwardPurchases(
    List<PurchaseDetails> purchases, {
    bool restoring = false,
  }) {
    final events = <StorePurchaseEvent>[];
    for (final purchase in purchases) {
      final launch = _activeLaunchIfFresh();
      final isEmptyTerminal =
          purchase.productID.trim().isEmpty &&
          (purchase.status == PurchaseStatus.canceled ||
              purchase.status == PurchaseStatus.error);
      final productId = resolveStorePurchaseProductId(
        productId: purchase.productID,
        status: purchase.status,
        activeProductId: launch?.productId,
      );
      if (!DamanakStoreCatalog.contains(platform, productId)) {
        continue;
      }
      final key = [
        purchase.verificationData.source,
        purchase.purchaseID ?? productId,
        purchase.transactionDate ?? '',
      ].join(':');
      final trackedPurchase = _nativePurchases[key];
      // StoreKit 2 can deliver the same transaction twice during an explicit
      // restore: once from Transaction.currentEntitlements as `restored`
      // (pendingCompletePurchase=false), and once from Transaction.unfinished
      // as `purchased` (pendingCompletePurchase=true). Never let the restored
      // copy replace the unfinished copy, otherwise verification succeeds but
      // the native transaction is never finished and blocks this product.
      if (trackedPurchase == null ||
          purchase.pendingCompletePurchase ||
          !trackedPurchase.pendingCompletePurchase) {
        _nativePurchases[key] = purchase;
      }
      final googlePurchase = purchase is GooglePlayPurchaseDetails
          ? purchase.billingClientPurchase
          : null;
      final applePurchase = purchase is SK2PurchaseDetails ? purchase : null;
      final status = storePurchaseEventStatus(purchase, restoring: restoring);
      events.add(
        StorePurchaseEvent(
          key: key,
          status: status,
          platform: platform,
          productId: productId,
          basePlanId: _basePlanForPurchase(productId),
          purchaseId: purchase.purchaseID,
          transactionDate: purchase.transactionDate,
          verificationData: purchase.verificationData.serverVerificationData,
          verificationSource: purchase.verificationData.source,
          needsCompletion: purchase.pendingCompletePurchase,
          errorCode: purchase.error?.code,
          errorMessage: purchase.error?.message,
          accountId:
              _nonEmpty(googlePurchase?.obfuscatedAccountId) ??
              (isEmptyTerminal ? launch?.accountId : null),
          storeId:
              _nonEmpty(googlePurchase?.obfuscatedProfileId) ??
              (isEmptyTerminal ? launch?.storeId : null),
          appAccountToken: _nonEmpty(applePurchase?.appAccountToken),
          pendingProductIds:
              googlePurchase?.pendingPurchaseUpdate?.products
                  .where(DamanakStoreCatalog.googleProductIds.contains)
                  .toList(growable: false) ??
              const [],
        ),
      );
      if (launch != null &&
          status != StorePurchaseStatus.pending &&
          _eventBelongsToLaunch(
            launch,
            productId: productId,
            accountId: _nonEmpty(googlePurchase?.obfuscatedAccountId),
            storeId: _nonEmpty(googlePurchase?.obfuscatedProfileId),
            transactionDate: purchase.transactionDate,
            terminalFallback: isEmptyTerminal,
          )) {
        _activeLaunch = null;
      }
    }
    if (events.isNotEmpty) _updates.add(events);
  }

  String? _basePlanForPurchase(String productId) {
    final planId = DamanakStoreCatalog.planIdFromProduct(productId);
    if (planId == null) return null;
    final native = _nativeProducts.values
        .whereType<GooglePlayProductDetails>()
        .where((item) => item.id == productId)
        .firstOrNull;
    final index = native?.subscriptionIndex;
    return index == null
        ? null
        : native?.productDetails.subscriptionOfferDetails?[index].basePlanId;
  }

  String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  _ActiveStorePurchaseLaunch? _activeLaunchIfFresh() {
    final launch = _activeLaunch;
    if (launch == null) return null;
    if (DateTime.now().difference(launch.startedAt) <=
        const Duration(minutes: 5)) {
      return launch;
    }
    _activeLaunch = null;
    return null;
  }

  bool _eventBelongsToLaunch(
    _ActiveStorePurchaseLaunch launch, {
    required String productId,
    required String? accountId,
    required String? storeId,
    required String? transactionDate,
    required bool terminalFallback,
  }) {
    if (productId != launch.productId) return false;
    if (terminalFallback) return true;
    if (accountId != null && accountId != launch.accountId) return false;
    if (storeId != null && storeId != launch.storeId) return false;
    final timestamp = int.tryParse(transactionDate ?? '');
    if (timestamp == null) {
      return accountId == launch.accountId && storeId == launch.storeId;
    }
    final transactionAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return !transactionAt.isBefore(
      launch.startedAt.subtract(const Duration(minutes: 2)),
    );
  }

  @override
  Future<StoreRestoreResult> restorePurchases({
    required String accountId,
    required String storeId,
    String? currentOriginalTransactionId,
    bool recoveryRequested = false,
  }) async {
    if (platform == StoreBillingPlatform.googlePlay) {
      GoogleSubscriptionSnapshot snapshot;
      try {
        snapshot = await _queryGoogleSubscriptionSnapshot(
          accountId,
          includeUnboundForRestore: true,
          recoveryRequested: recoveryRequested,
        ).timeout(purchaseLookupTimeout);
      } on TimeoutException {
        throw StateError('GOOGLE_SUBSCRIPTION_LOOKUP_TIMEOUT');
      } on StateError {
        rethrow;
      } on Object {
        throw StateError('GOOGLE_SUBSCRIPTION_LOOKUP_FAILED');
      }

      final candidates = validatedGoogleSubscriptionsForRestore(
        snapshot,
        storeId: storeId,
        recoveryRequested: recoveryRequested,
      );
      _forwardPurchases(candidates, restoring: true);
      final statuses = candidates
          .map(
            (purchase) => storePurchaseEventStatus(purchase, restoring: true),
          )
          .toList(growable: false);
      return StoreRestoreResult(
        platform: StoreBillingPlatform.googlePlay,
        restoredPurchases: statuses
            .where((status) => status == StorePurchaseStatus.restored)
            .length,
        pendingPurchases: statuses
            .where((status) => status == StorePurchaseStatus.pending)
            .length,
        accountMismatchDetected: snapshot.accountMismatchDetected,
      );
    }
    if (platform == StoreBillingPlatform.appStore) {
      // StoreKit 2's restorePurchases enumerates currentEntitlements only. A
      // superseded transaction can remain in Transaction.unfinished and block
      // only its product forever with storekit_duplicate_product_object.
      // This repair is best-effort: a failure must never suppress Apple's
      // official current-entitlements restore that follows it.
      return restoreAppleStorePurchases(
        storeKit2Enabled: InAppPurchaseStoreKitPlatform.isStoreKit2Enabled,
        queryUnfinishedTransactions:
            _appleUnfinishedTransactionQueryOverride ??
            SK2Transaction.unfinishedTransactions,
        restoreCurrentEntitlements: () =>
            _client.restorePurchases(applicationUserName: accountId),
        forwardPurchases: (purchases) =>
            _forwardPurchases(purchases, restoring: true),
        timeout: purchaseLookupTimeout,
        accountId: accountId,
        storeId: storeId,
        currentOriginalTransactionId: currentOriginalTransactionId,
        recoveryRequested: recoveryRequested,
      );
    }
    throw StateError('STORE_UNAVAILABLE');
  }

  @override
  Future<void> completePurchase(StorePurchaseEvent event) async {
    // Server-side Google acknowledgement is best-effort after the entitlement
    // commits. Completing the same token locally is the device fallback and is
    // safe to retry. Keep the native purchase until completion succeeds so a
    // later delivery or explicit restore can retry it after a transient error.
    await completeTrackedNativePurchase(
      purchases: _nativePurchases,
      eventKey: event.key,
      completePurchase: _completeNativePurchase,
    );
  }

  Future<void> _completeNativePurchase(PurchaseDetails native) async {
    if (native is! GooglePlayPurchaseDetails) {
      await _client.completePurchase(native);
      return;
    }
    await completeGooglePlayPurchaseWithResultCheck(
      purchase: native,
      completePurchase:
          _googlePurchaseCompletionOverride ?? _completeGooglePurchaseOnDevice,
    );
  }

  Future<BillingResultWrapper> _completeGooglePurchaseOnDevice(
    GooglePlayPurchaseDetails purchase,
  ) {
    final nativePlatform = InAppPurchasePlatform.instance;
    if (nativePlatform is! InAppPurchaseAndroidPlatform) {
      throw StateError('GOOGLE_BILLING_PLATFORM_UNAVAILABLE');
    }
    return nativePlatform.completePurchase(purchase);
  }

  @override
  Future<bool> openSubscriptionManagement(
    StoreBillingPlatform provider, {
    String? productId,
  }) {
    final url = switch (provider) {
      StoreBillingPlatform.appStore => Uri.parse(
        'https://apps.apple.com/account/subscriptions',
      ),
      StoreBillingPlatform.googlePlay =>
        Uri.https('play.google.com', '/store/account/subscriptions', {
          'package': DamanakStoreCatalog.packageName,
          if (productId != null &&
              DamanakStoreCatalog.googleProductIds.contains(productId))
            'sku': productId,
        }),
      StoreBillingPlatform.unavailable => null,
    };
    if (url == null) return Future.value(false);
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Future<void> dispose() async {
    await _purchaseSubscription.cancel();
    await _updates.close();
  }
}

class _ActiveStorePurchaseLaunch {
  const _ActiveStorePurchaseLaunch({
    required this.productId,
    required this.accountId,
    required this.storeId,
    required this.startedAt,
  });

  final String productId;
  final String accountId;
  final String storeId;
  final DateTime startedAt;
}
