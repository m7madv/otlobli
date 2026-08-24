import 'package:freezed_annotation/freezed_annotation.dart';

part 'brief_result.freezed.dart';
part 'brief_result.g.dart';

@freezed
sealed class BriefActionItem with _$BriefActionItem {
  const factory BriefActionItem({
    required String title,
    String? owner,
    String? dueDateIso,
    String? originalDatePhrase,
    @Default(0) double confidence,
  }) = _BriefActionItem;

  factory BriefActionItem.fromJson(Map<String, Object?> json) =>
      _$BriefActionItemFromJson(json);
}

@freezed
sealed class BriefImportantDate with _$BriefImportantDate {
  const factory BriefImportantDate({
    required String label,
    String? dateIso,
    required String originalPhrase,
    @Default(0) double confidence,
    @Default(true) bool requiresConfirmation,
  }) = _BriefImportantDate;

  factory BriefImportantDate.fromJson(Map<String, Object?> json) =>
      _$BriefImportantDateFromJson(json);
}

@freezed
sealed class SuggestedReplies with _$SuggestedReplies {
  const factory SuggestedReplies({
    required String short,
    required String friendly,
    required String professional,
  }) = _SuggestedReplies;

  factory SuggestedReplies.fromJson(Map<String, Object?> json) =>
      _$SuggestedRepliesFromJson(json);
}

@freezed
sealed class BriefResult with _$BriefResult {
  // Freezed forwards this constructor annotation to its generated class.
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory BriefResult({
    required String id,
    required String detectedLanguage,
    required String title,
    required String transcript,
    required String summary,
    required List<String> keyPoints,
    required List<BriefActionItem> actionItems,
    required List<BriefImportantDate> importantDates,
    required SuggestedReplies suggestedReplies,
    required int audioDurationSeconds,
    required DateTime processedAt,
    @Default(false) bool savedLocally,
  }) = _BriefResult;

  factory BriefResult.fromJson(Map<String, Object?> json) =>
      _$BriefResultFromJson(json);
}
