// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AudioInput _$AudioInputFromJson(Map<String, dynamic> json) => _AudioInput(
  path: json['path'] as String,
  displayName: json['displayName'] as String,
  mimeType: json['mimeType'] as String,
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  durationSeconds: (json['durationSeconds'] as num).toInt(),
  source: $enumDecode(_$AudioSourceKindEnumMap, json['source']),
);

Map<String, dynamic> _$AudioInputToJson(_AudioInput instance) =>
    <String, dynamic>{
      'path': instance.path,
      'displayName': instance.displayName,
      'mimeType': instance.mimeType,
      'sizeBytes': instance.sizeBytes,
      'durationSeconds': instance.durationSeconds,
      'source': _$AudioSourceKindEnumMap[instance.source]!,
    };

const _$AudioSourceKindEnumMap = {
  AudioSourceKind.picker: 'picker',
  AudioSourceKind.recording: 'recording',
  AudioSourceKind.androidShare: 'androidShare',
  AudioSourceKind.iosShare: 'iosShare',
};
