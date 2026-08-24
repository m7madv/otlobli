import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:voicebrief/features/audio_import/domain/audio_input.dart';
import 'package:voicebrief/features/auth/domain/auth_user.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';
import 'package:voicebrief/features/transcription/domain/processing_options.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';

part 'app_state.freezed.dart';

@freezed
sealed class AppState with _$AppState {
  const factory AppState({
    AuthUser? user,
    @Default(false) bool authBusy,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(0) int navigationIndex,
    @Default(
      SubscriptionStatus(
        tier: SubscriptionTier.free,
        remainingMinutes: 10,
        totalMinutes: 10,
      ),
    )
    SubscriptionStatus subscription,
    @Default(false) bool audioImporting,
    AudioInput? selectedAudio,
    @Default(ProcessingOptions()) ProcessingOptions processingOptions,
    @Default(ProcessingStep.preparing) ProcessingStep processingStep,
    @Default(false) bool processing,
    BriefResult? activeResult,
    @Default([]) List<BriefResult> history,
    String? errorMessage,
  }) = _AppState;
}
