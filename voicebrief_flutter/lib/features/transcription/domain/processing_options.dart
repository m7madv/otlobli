import 'package:freezed_annotation/freezed_annotation.dart';

part 'processing_options.freezed.dart';
part 'processing_options.g.dart';

@freezed
sealed class ProcessingOptions with _$ProcessingOptions {
  const factory ProcessingOptions({
    @Default(true) bool transcript,
    @Default(true) bool summary,
    @Default(true) bool actionItems,
    @Default(true) bool suggestedReplies,
    @Default(false) bool translation,
  }) = _ProcessingOptions;

  factory ProcessingOptions.fromJson(Map<String, Object?> json) =>
      _$ProcessingOptionsFromJson(json);
}
