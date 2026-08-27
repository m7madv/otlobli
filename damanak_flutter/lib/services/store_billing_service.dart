import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/store_billing.dart';

typedef StoreProductQuery =
    Future<ProductDetailsResponse> Function(Set<String> productIds);

@visibleForTesting
Future<ProductDetailsResponse> queryAppleStoreProducts({
  required Set<String> productIds,
  required StoreProductQuery storeKit2Query,
  required StoreProductQuery storeKit1Query,
  required Duration timeout,
}) async {
  ProductDetailsResponse? emptyResponse;
  try {
    final response = await storeKit2Query(productIds).timeout(timeout);
    if (response.productDetails.isNotEmpty) return response;
    emptyResponse = response;
  } on TimeoutException {
    // StoreKit 2 can occasionally leave a product lookup unresolved. The
    // StoreKit 1 request below uses a separate native product-query path.
  } on PlatformException {
    // A native StoreKit 2 lookup failure can still be recovered by StoreKit 1.
  }

  try {
    final response = await storeKit1Query(productIds).timeout(timeout);
    if (response.productDetails.isNotEmpty) return response;
    final emptyResponses = <ProductDetailsResponse>[response];
    if (emptyResponse != null) emptyResponses.insert(0, emptyResponse);
    emptyResponse = _mergeProductResponses(
      productIds: productIds,
      responses: emptyResponses,
    );
  } on TimeoutException {
    if (emptyResponse == null) rethrow;
    return emptyResponse;
  } on PlatformException {
    if (emptyResponse == null) rethrow;
    return emptyResponse;
  }

  if (productIds.length < 2) return emptyResponse;

  // A few recent iOS/TestFlight combinations return an empty catalog for one
  // request containing all identifiers. Retry once using two bounded batches.
  // The two native requests run together, so this adds at most one timeout and
  // does not create polling or background work.
  final sortedIds = productIds.toList()..sort();
  final splitAt = (sortedIds.length / 2).ceil();
  final batches = [
    sortedIds.take(splitAt).toSet(),
    sortedIds.skip(splitAt).toSet(),
  ].where((batch) => batch.isNotEmpty);
  try {
    final responses = await Future.wait(
      batches.map(storeKit1Query),
    ).timeout(timeout);
    return _mergeProductResponses(
      productIds: productIds,
      responses: [emptyResponse, ...responses],
    );
  } on TimeoutException {
    return emptyResponse;
  } on PlatformException {
    return emptyResponse;
  }
}

ProductDetailsResponse _mergeProductResponses({
  required Set<String> productIds,
  required Iterable<ProductDetailsResponse> responses,
}) {
  final productsById = <String, ProductDetails>{};
  IAPError? firstError;
  for (final response in responses) {
    firstError ??= response.error;
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

  Future<StoreProductLoadResult> loadProducts();
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
  });
  Future<void> restorePurchases();
  Future<void> completePurchase(StorePurchaseEvent event);
  Future<bool> openSubscriptionManagement();
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
  Future<StoreProductLoadResult> loadProducts() async =>
      const StoreProductLoadResult(
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
  }) => throw StateError('STORE_UNAVAILABLE');

  @override
  Future<void> restorePurchases() => throw StateError('STORE_UNAVAILABLE');

  @override
  Future<void> completePurchase(StorePurchaseEvent event) async {}

  @override
  Future<bool> openSubscriptionManagement() async => false;

  @override
  Future<void> dispose() async {}
}

class PlatformStoreBillingService implements StoreBillingService {
  PlatformStoreBillingService({
    InAppPurchase? client,
    this.availabilityTimeout = const Duration(seconds: 6),
    this.productQueryTimeout = const Duration(seconds: 8),
  }) : _client = client ?? InAppPurchase.instance {
    _purchaseSubscription = _client.purchaseStream.listen(
      _forwardPurchases,
      onError: (Object error) {
        _updates.add([
          StorePurchaseEvent(
            key: 'stream-${DateTime.now().microsecondsSinceEpoch}',
            status: StorePurchaseStatus.error,
            platform: platform,
            productId: '',
            verificationData: '',
            verificationSource: '',
            needsCompletion: false,
            errorCode: 'purchase_stream',
            errorMessage: error.toString(),
          ),
        ]);
      },
    );
  }

  final InAppPurchase _client;
  final Duration availabilityTimeout;
  final Duration productQueryTimeout;
  final StreamController<List<StorePurchaseEvent>> _updates =
      StreamController<List<StorePurchaseEvent>>.broadcast();
  final Map<String, ProductDetails> _nativeProducts = {};
  final Map<String, PurchaseDetails> _nativePurchases = {};
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  GooglePlayPurchaseDetails? _oldGoogleSubscription;

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
  Future<StoreProductLoadResult> loadProducts() async {
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
      if (platform == StoreBillingPlatform.googlePlay) {
        await _loadOldGoogleSubscription();
      }

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

  Future<void> _loadOldGoogleSubscription() async {
    try {
      final addition = _client
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      final candidates = response.pastPurchases
          .whereType<GooglePlayPurchaseDetails>()
          .where(
            (item) =>
                DamanakStoreCatalog.googleProductIds.contains(item.productID),
          )
          .toList();
      candidates.sort(
        (a, b) => (b.transactionDate ?? '').compareTo(a.transactionDate ?? ''),
      );
      _oldGoogleSubscription = candidates.firstOrNull;
      if (candidates.isNotEmpty) _forwardPurchases(candidates);
    } catch (_) {
      _oldGoogleSubscription = null;
    }
  }

  @override
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
  }) async {
    final product = _nativeProducts[offer.key];
    if (product == null) throw StateError('STORE_PRODUCT_UNAVAILABLE');

    PurchaseParam param;
    if (product is GooglePlayProductDetails) {
      final old = _oldGoogleSubscription;
      param = GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: accountId,
        offerToken: product.offerToken,
        changeSubscriptionParam: old == null
            ? null
            : ChangeSubscriptionParam(
                oldPurchaseDetails: old,
                replacementMode: _replacementMode(old.productID, offer.planId),
              ),
      );
    } else {
      param = PurchaseParam(
        productDetails: product,
        applicationUserName: accountId,
      );
    }
    final launched = await _client.buyNonConsumable(purchaseParam: param);
    if (!launched) throw StateError('STORE_PURCHASE_NOT_LAUNCHED');
  }

  ReplacementMode _replacementMode(String oldProductId, String newPlanId) {
    final oldPlanId = DamanakStoreCatalog.planIdFromProduct(oldProductId);
    final oldRank = DamanakStoreCatalog.planRank(oldPlanId);
    final newRank = DamanakStoreCatalog.planRank(newPlanId);
    if (newRank > oldRank) return ReplacementMode.chargeProratedPrice;
    if (newRank < oldRank) return ReplacementMode.deferred;
    return ReplacementMode.chargeFullPrice;
  }

  void _forwardPurchases(List<PurchaseDetails> purchases) {
    final events = <StorePurchaseEvent>[];
    for (final purchase in purchases) {
      final key = [
        purchase.verificationData.source,
        purchase.purchaseID ?? purchase.productID,
        purchase.transactionDate ?? '',
      ].join(':');
      _nativePurchases[key] = purchase;
      if (purchase is GooglePlayPurchaseDetails &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        _oldGoogleSubscription = purchase;
      }
      events.add(
        StorePurchaseEvent(
          key: key,
          status: _status(purchase.status),
          platform: platform,
          productId: purchase.productID,
          basePlanId: _basePlanForPurchase(purchase.productID),
          purchaseId: purchase.purchaseID,
          transactionDate: purchase.transactionDate,
          verificationData: purchase.verificationData.serverVerificationData,
          verificationSource: purchase.verificationData.source,
          needsCompletion: purchase.pendingCompletePurchase,
          errorCode: purchase.error?.code,
          errorMessage: purchase.error?.message,
        ),
      );
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

  StorePurchaseStatus _status(PurchaseStatus status) => switch (status) {
    PurchaseStatus.pending => StorePurchaseStatus.pending,
    PurchaseStatus.purchased => StorePurchaseStatus.purchased,
    PurchaseStatus.restored => StorePurchaseStatus.restored,
    PurchaseStatus.canceled => StorePurchaseStatus.canceled,
    PurchaseStatus.error => StorePurchaseStatus.error,
  };

  @override
  Future<void> restorePurchases() => _client.restorePurchases();

  @override
  Future<void> completePurchase(StorePurchaseEvent event) async {
    final native = _nativePurchases.remove(event.key);
    if (native != null && native.pendingCompletePurchase) {
      await _client.completePurchase(native);
    }
  }

  @override
  Future<bool> openSubscriptionManagement() {
    final url = switch (platform) {
      StoreBillingPlatform.appStore => Uri.parse(
        'https://apps.apple.com/account/subscriptions',
      ),
      StoreBillingPlatform.googlePlay => Uri.parse(
        'https://play.google.com/store/account/subscriptions?package='
        '${DamanakStoreCatalog.packageName}',
      ),
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
