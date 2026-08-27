import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/features/audio_import/domain/audio_input.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';
import 'package:voicebrief/features/transcription/domain/processing_options.dart';

typedef ProcessingStageCallback = void Function(String stage);

abstract interface class TranscriptionRepository {
  Future<BriefResult> createBrief({
    required String jobId,
    required AudioInput audio,
    required ProcessingOptions options,
    ProcessingStageCallback? onStage,
  });
}

class FakeTranscriptionRepository implements TranscriptionRepository {
  @override
  Future<BriefResult> createBrief({
    required String jobId,
    required AudioInput audio,
    required ProcessingOptions options,
    ProcessingStageCallback? onStage,
  }) async {
    for (final stage in const [
      'preparing',
      'uploading',
      'transcribing',
      'creating',
      'finalizing',
    ]) {
      onStage?.call(stage);
      await Future<void>.delayed(const Duration(milliseconds: 420));
    }
    return BriefResult(
      id: jobId,
      detectedLanguage: 'en',
      title: 'Project launch follow-up',
      transcript:
          'Hi team, quick follow-up from today. Maya will send the final proposal before next Thursday. Please review the pricing notes and confirm the launch checklist. Let us meet Thursday after work if anything remains open.',
      summary:
          'The team agreed to finalize the proposal, review pricing, and confirm the launch checklist before the next meeting.',
      keyPoints: const [
        'The final proposal is due before next Thursday.',
        'Pricing notes need a final team review.',
        'The launch checklist must be confirmed before the follow-up.',
      ],
      actionItems: const [
        BriefActionItem(
          title: 'Send the final proposal',
          owner: 'Maya',
          originalDatePhrase: 'before next Thursday',
          confidence: 0.72,
        ),
        BriefActionItem(title: 'Review the pricing notes', confidence: 0.93),
      ],
      importantDates: const [
        BriefImportantDate(
          label: 'Follow-up meeting',
          originalPhrase: 'Thursday after work',
          confidence: 0.58,
          requiresConfirmation: true,
        ),
      ],
      suggestedReplies: const SuggestedReplies(
        short: 'Got it. I’ll review the pricing notes before Thursday.',
        friendly:
            'Sounds good! I’ll review the pricing notes and confirm everything before Thursday.',
        professional:
            'Thank you for the update. I will review the pricing notes and confirm the launch checklist before Thursday.',
      ),
      audioDurationSeconds: audio.durationSeconds,
      processedAt: DateTime.now().toUtc(),
    );
  }
}

class SupabaseTranscriptionRepository implements TranscriptionRepository {
  SupabaseTranscriptionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<BriefResult> createBrief({
    required String jobId,
    required AudioInput audio,
    required ProcessingOptions options,
    ProcessingStageCallback? onStage,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppFailure(AppFailureCode.authentication);
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      throw const AppFailure(AppFailureCode.noInternet);
    }
    final extension = path.extension(audio.displayName).toLowerCase();
    final storagePath = '${user.id}/$jobId/input$extension';
    onStage?.call('preparing');
    onStage?.call('uploading');
    try {
      await _client.storage
          .from('audio-temp')
          .upload(
            storagePath,
            File(audio.path),
            fileOptions: FileOptions(
              contentType: audio.mimeType,
              upsert: false,
            ),
          );
    } on StorageException {
      throw const AppFailure(AppFailureCode.uploadInterrupted);
    }
    onStage?.call('transcribing');
    try {
      final timeZoneOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      final deviceLanguage = PlatformDispatcher.instance.locale.languageCode
          .toLowerCase();
      final languageHint = deviceLanguage == 'ar' || deviceLanguage == 'en'
          ? deviceLanguage
          : null;
      final requestBody = <String, Object?>{
        'jobId': jobId,
        'storagePath': storagePath,
        'displayName': audio.displayName,
        'mimeType': audio.mimeType,
        'sizeBytes': audio.sizeBytes,
        'durationSeconds': audio.durationSeconds,
        'timeZoneOffsetMinutes': timeZoneOffsetMinutes,
        'options': options.toJson(),
      };
      if (languageHint != null) requestBody['languageHint'] = languageHint;
      final response = await _client.functions.invoke(
        'process-audio',
        body: requestBody,
      );
      if (response.status != 200 || response.data is! Map) {
        throw const AppFailure(AppFailureCode.invalidResponse);
      }
      onStage?.call('creating');
      final payload = Map<String, Object?>.from(response.data as Map);
      final resultPayload = payload['result'];
      if (resultPayload is! Map) {
        throw const AppFailure(AppFailureCode.invalidResponse);
      }
      final result = BriefResult.fromJson(
        Map<String, Object?>.from(resultPayload),
      );
      onStage?.call('finalizing');
      return result;
    } on FunctionException catch (error) {
      throw AppFailure(switch (error.status) {
        402 => AppFailureCode.quotaExhausted,
        408 || 504 => AppFailureCode.processingTimeout,
        500 || 502 || 503 => AppFailureCode.serviceUnavailable,
        _ => AppFailureCode.transcription,
      }, debugContext: '${error.status}');
    }
  }
}
