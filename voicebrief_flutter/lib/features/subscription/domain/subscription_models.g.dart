// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionOption _$SubscriptionOptionFromJson(Map<String, dynamic> json) =>
    _SubscriptionOption(
      productId: json['productId'] as String,
      title: json['title'] as String,
      localizedPrice: json['localizedPrice'] as String,
      annual: json['annual'] as bool,
      localizedMonthlyEquivalent: json['localizedMonthlyEquivalent'] as String?,
      packageIdentifier: json['packageIdentifier'] as String?,
    );

Map<String, dynamic> _$SubscriptionOptionToJson(_SubscriptionOption instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'title': instance.title,
      'localizedPrice': instance.localizedPrice,
      'annual': instance.annual,
      'localizedMonthlyEquivalent': instance.localizedMonthlyEquivalent,
      'packageIdentifier': instance.packageIdentifier,
    };

_SubscriptionStatus _$SubscriptionStatusFromJson(Map<String, dynamic> json) =>
    _SubscriptionStatus(
      tier: $enumDecode(_$SubscriptionTierEnumMap, json['tier']),
      remainingMinutes: (json['remainingMinutes'] as num).toInt(),
      totalMinutes: (json['totalMinutes'] as num).toInt(),
      options:
          (json['options'] as List<dynamic>?)
              ?.map(
                (e) => SubscriptionOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      offeringsLoaded: json['offeringsLoaded'] as bool? ?? false,
    );

Map<String, dynamic> _$SubscriptionStatusToJson(_SubscriptionStatus instance) =>
    <String, dynamic>{
      'tier': _$SubscriptionTierEnumMap[instance.tier]!,
      'remainingMinutes': instance.remainingMinutes,
      'totalMinutes': instance.totalMinutes,
      'options': instance.options.map((e) => e.toJson()).toList(),
      'offeringsLoaded': instance.offeringsLoaded,
    };

const _$SubscriptionTierEnumMap = {
  SubscriptionTier.free: 'free',
  SubscriptionTier.pro: 'pro',
};
