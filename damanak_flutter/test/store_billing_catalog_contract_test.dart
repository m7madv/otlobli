import 'dart:io';

import 'package:damanak/models/store_billing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedApplePeriods = <String, String>{
    'com.damanak.subscription.starter.monthly': 'ONE_MONTH',
    'com.damanak.subscription.starter.yearly': 'ONE_YEAR',
    'com.damanak.subscription.growth.monthly': 'ONE_MONTH',
    'com.damanak.subscription.growth.yearly': 'ONE_YEAR',
    'com.damanak.subscription.scale.monthly': 'ONE_MONTH',
    'com.damanak.subscription.scale.yearly': 'ONE_YEAR',
  };
  const expectedGooglePeriods = <String, String>{
    'monthly': 'P1M',
    'yearly': 'P1Y',
  };

  test('تتطابق معرفات Apple وفتراتها بين Dart وسكربت المتجر وSQL', () {
    final script = File('scripts/app_store_setup.mjs').readAsStringSync();
    final migration = File(
      'supabase/migrations/20260824180000_damanak_store_billing.sql',
    ).readAsStringSync();

    final scriptProducts = _appleProductsAndPeriods(script);
    final sqlRows = _catalogRows(
      migration,
    ).where((row) => row.platform == 'app_store').toSet();
    final expectedRows = expectedApplePeriods.keys
        .map(
          (productId) => _CatalogRow(
            platform: 'app_store',
            productId: productId,
            basePlanId: '',
            planId: DamanakStoreCatalog.planIdFromProduct(productId)!,
            cycle: productId.endsWith('.monthly') ? 'monthly' : 'yearly',
          ),
        )
        .toSet();

    expect(
      DamanakStoreCatalog.appleProductIds,
      expectedApplePeriods.keys.toSet(),
    );
    expect(scriptProducts, expectedApplePeriods);
    expect(sqlRows, expectedRows);
    expect(
      script,
      contains("const BUNDLE_ID = '${DamanakStoreCatalog.packageName}'"),
    );
  });

  test('تتطابق معرفات Google وخططها الأساسية وفتراتها مع SQL', () {
    final script = File('scripts/google_play_setup.mjs').readAsStringSync();
    final migration = File(
      'supabase/migrations/20260824180000_damanak_store_billing.sql',
    ).readAsStringSync();

    final scriptProductIds = RegExp(
      r"productId:\s*'(com\.damanak\.subscription\.[^']+)'",
    ).allMatches(script).map((match) => match.group(1)!).toSet();
    final sqlRows = _catalogRows(
      migration,
    ).where((row) => row.platform == 'google_play').toSet();
    final expectedRows = <_CatalogRow>{
      for (final productId in DamanakStoreCatalog.googleProductIds)
        for (final basePlanId in expectedGooglePeriods.keys)
          _CatalogRow(
            platform: 'google_play',
            productId: productId,
            basePlanId: basePlanId,
            planId: DamanakStoreCatalog.planIdFromProduct(productId)!,
            cycle: basePlanId,
          ),
    };

    expect(scriptProductIds, DamanakStoreCatalog.googleProductIds);
    expect(_googleBasePlanPeriods(script), expectedGooglePeriods);
    expect(sqlRows, expectedRows);
    expect(
      script,
      contains("const PACKAGE_NAME = '${DamanakStoreCatalog.packageName}'"),
    );
  });
}

Map<String, String> _appleProductsAndPeriods(String script) {
  final matches = RegExp(
    r"productId:\s*'(com\.damanak\.subscription\.[^']+)'[\s\S]*?"
    r"subscriptionPeriod:\s*'(ONE_MONTH|ONE_YEAR)'",
  ).allMatches(script);
  return {for (final match in matches) match.group(1)!: match.group(2)!};
}

Map<String, String> _googleBasePlanPeriods(String script) {
  final matches = RegExp(
    r"basePlanId:\s*'(monthly|yearly)'[\s\S]*?"
    r"billingPeriodDuration:\s*'(P1M|P1Y)'",
  ).allMatches(script);
  return {for (final match in matches) match.group(1)!: match.group(2)!};
}

Set<_CatalogRow> _catalogRows(String migration) {
  final matches = RegExp(
    r"\('(app_store|google_play)',\s*'([^']+)',\s*'([^']*)',\s*"
    r"'([^']+)',\s*'(monthly|yearly)'\)",
  ).allMatches(migration);
  return {
    for (final match in matches)
      _CatalogRow(
        platform: match.group(1)!,
        productId: match.group(2)!,
        basePlanId: match.group(3)!,
        planId: match.group(4)!,
        cycle: match.group(5)!,
      ),
  };
}

class _CatalogRow {
  const _CatalogRow({
    required this.platform,
    required this.productId,
    required this.basePlanId,
    required this.planId,
    required this.cycle,
  });

  final String platform;
  final String productId;
  final String basePlanId;
  final String planId;
  final String cycle;

  @override
  bool operator ==(Object other) =>
      other is _CatalogRow &&
      platform == other.platform &&
      productId == other.productId &&
      basePlanId == other.basePlanId &&
      planId == other.planId &&
      cycle == other.cycle;

  @override
  int get hashCode =>
      Object.hash(platform, productId, basePlanId, planId, cycle);

  @override
  String toString() => '$platform:$productId:$basePlanId:$planId:$cycle';
}
