import 'maintenance_request.dart';

class ClaimAiUsage {
  const ClaimAiUsage({
    required this.provider,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.estimatedCostUsd,
    required this.monthlyUsed,
    required this.monthlyLimit,
  });

  final String provider;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final double? estimatedCostUsd;
  final int monthlyUsed;
  final int monthlyLimit;

  factory ClaimAiUsage.fromJson(Map<String, dynamic> json) => ClaimAiUsage(
    provider: json['provider'] as String? ?? '',
    model: json['model'] as String? ?? '',
    inputTokens: (json['inputTokens'] as num? ?? 0).toInt(),
    outputTokens: (json['outputTokens'] as num? ?? 0).toInt(),
    estimatedCostUsd: (json['estimatedCostUsd'] as num?)?.toDouble(),
    monthlyUsed: (json['monthlyUsed'] as num? ?? 0).toInt(),
    monthlyLimit: (json['monthlyLimit'] as num? ?? 0).toInt(),
  );
}

class ClaimAiReview {
  const ClaimAiReview({
    required this.id,
    required this.summary,
    required this.suggestedCategory,
    required this.suggestedPriority,
    required this.missingInformation,
    required this.signals,
    required this.confidence,
    required this.disclaimer,
    required this.includedAttachments,
    required this.usage,
  });

  final String id;
  final String summary;
  final ClaimCategory suggestedCategory;
  final ClaimPriority suggestedPriority;
  final List<String> missingInformation;
  final List<String> signals;
  final double confidence;
  final String disclaimer;
  final bool includedAttachments;
  final ClaimAiUsage usage;

  factory ClaimAiReview.fromJson(Map<String, dynamic> json) => ClaimAiReview(
    id: json['id'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    suggestedCategory: ClaimCategoryText.fromValue(json['suggestedCategory']),
    suggestedPriority: ClaimPriorityText.fromValue(json['suggestedPriority']),
    missingInformation: (json['missingInformation'] as List? ?? const [])
        .whereType<String>()
        .toList(),
    signals: (json['signals'] as List? ?? const [])
        .whereType<String>()
        .toList(),
    confidence: (json['confidence'] as num? ?? 0).toDouble(),
    disclaimer: json['disclaimer'] as String? ?? '',
    includedAttachments: json['includedAttachments'] as bool? ?? false,
    usage: ClaimAiUsage.fromJson(
      Map<String, dynamic>.from(json['usage'] as Map? ?? const {}),
    ),
  );
}
