// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brief_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BriefActionItem _$BriefActionItemFromJson(Map<String, dynamic> json) =>
    _BriefActionItem(
      title: json['title'] as String,
      owner: json['owner'] as String?,
      dueDateIso: json['dueDateIso'] as String?,
      originalDatePhrase: json['originalDatePhrase'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$BriefActionItemToJson(_BriefActionItem instance) =>
    <String, dynamic>{
      'title': instance.title,
      'owner': instance.owner,
      'dueDateIso': instance.dueDateIso,
      'originalDatePhrase': instance.originalDatePhrase,
      'confidence': instance.confidence,
    };

_BriefImportantDate _$BriefImportantDateFromJson(Map<String, dynamic> json) =>
    _BriefImportantDate(
      label: json['label'] as String,
      dateIso: json['dateIso'] as String?,
      originalPhrase: json['originalPhrase'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? true,
    );

Map<String, dynamic> _$BriefImportantDateToJson(_BriefImportantDate instance) =>
    <String, dynamic>{
      'label': instance.label,
      'dateIso': instance.dateIso,
      'originalPhrase': instance.originalPhrase,
      'confidence': instance.confidence,
      'requiresConfirmation': instance.requiresConfirmation,
    };

_SuggestedReplies _$SuggestedRepliesFromJson(Map<String, dynamic> json) =>
    _SuggestedReplies(
      short: json['short'] as String,
      friendly: json['friendly'] as String,
      professional: json['professional'] as String,
    );

Map<String, dynamic> _$SuggestedRepliesToJson(_SuggestedReplies instance) =>
    <String, dynamic>{
      'short': instance.short,
      'friendly': instance.friendly,
      'professional': instance.professional,
    };

_BriefResult _$BriefResultFromJson(Map<String, dynamic> json) => _BriefResult(
  id: json['id'] as String,
  detectedLanguage: json['detectedLanguage'] as String,
  title: json['title'] as String,
  transcript: json['transcript'] as String,
  summary: json['summary'] as String,
  keyPoints: (json['keyPoints'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  actionItems: (json['actionItems'] as List<dynamic>)
      .map((e) => BriefActionItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  importantDates: (json['importantDates'] as List<dynamic>)
      .map((e) => BriefImportantDate.fromJson(e as Map<String, dynamic>))
      .toList(),
  suggestedReplies: SuggestedReplies.fromJson(
    json['suggestedReplies'] as Map<String, dynamic>,
  ),
  audioDurationSeconds: (json['audioDurationSeconds'] as num).toInt(),
  processedAt: DateTime.parse(json['processedAt'] as String),
  savedLocally: json['savedLocally'] as bool? ?? false,
);

Map<String, dynamic> _$BriefResultToJson(_BriefResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'detectedLanguage': instance.detectedLanguage,
      'title': instance.title,
      'transcript': instance.transcript,
      'summary': instance.summary,
      'keyPoints': instance.keyPoints,
      'actionItems': instance.actionItems.map((e) => e.toJson()).toList(),
      'importantDates': instance.importantDates.map((e) => e.toJson()).toList(),
      'suggestedReplies': instance.suggestedReplies.toJson(),
      'audioDurationSeconds': instance.audioDurationSeconds,
      'processedAt': instance.processedAt.toIso8601String(),
      'savedLocally': instance.savedLocally,
    };
