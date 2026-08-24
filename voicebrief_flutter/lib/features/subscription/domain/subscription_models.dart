import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_models.freezed.dart';
part 'subscription_models.g.dart';

enum SubscriptionTier { free, pro }

@freezed
sealed class SubscriptionOption with _$SubscriptionOption {
  const factory SubscriptionOption({
    required String productId,
    required String title,
    required String localizedPrice,
    required bool annual,
    String? localizedMonthlyEquivalent,
    String? packageIdentifier,
  }) = _SubscriptionOption;

  factory SubscriptionOption.fromJson(Map<String, Object?> json) =>
      _$SubscriptionOptionFromJson(json);
}

@freezed
sealed class SubscriptionStatus with _$SubscriptionStatus {
  // Freezed forwards this constructor annotation to its generated class.
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory SubscriptionStatus({
    required SubscriptionTier tier,
    required int remainingMinutes,
    required int totalMinutes,
    @Default([]) List<SubscriptionOption> options,
    @Default(false) bool offeringsLoaded,
  }) = _SubscriptionStatus;

  factory SubscriptionStatus.fromJson(Map<String, Object?> json) =>
      _$SubscriptionStatusFromJson(json);
}
