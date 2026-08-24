// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProcessingOptions _$ProcessingOptionsFromJson(Map<String, dynamic> json) =>
    _ProcessingOptions(
      transcript: json['transcript'] as bool? ?? true,
      summary: json['summary'] as bool? ?? true,
      actionItems: json['actionItems'] as bool? ?? true,
      suggestedReplies: json['suggestedReplies'] as bool? ?? true,
      translation: json['translation'] as bool? ?? false,
    );

Map<String, dynamic> _$ProcessingOptionsToJson(_ProcessingOptions instance) =>
    <String, dynamic>{
      'transcript': instance.transcript,
      'summary': instance.summary,
      'actionItems': instance.actionItems,
      'suggestedReplies': instance.suggestedReplies,
      'translation': instance.translation,
    };
