import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:voicebrief/app/app_state.dart';
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/core/utils/quota_math.dart';
import 'package:voicebrief/features/audio_import/data/audio_import_service.dart';
import 'package:voicebrief/features/audio_import/domain/audio_input.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/auth/domain/auth_user.dart';
import 'package:voicebrief/features/history/data/history_repository.dart';
import 'package:voicebrief/features/subscription/data/subscription_repository.dart';
import 'package:voicebrief/features/transcription/data/transcription_repository.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';
import 'package:voicebrief/features/transcription/domain/processing_options.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';

class AppController extends StateNotifier<AppState> {
  AppController({
    required AuthRepository authRepository,
    required SubscriptionRepository subscriptionRepository,
    required TranscriptionRepository transcriptionRepository,
    required HistoryRepository historyRepository,
    required AudioImportService audioImportService,
    required SharedAudioInbox sharedAudioInbox,
  }) : _auth = authRepository,
       _subscriptions = subscriptionRepository,
       _transcription = transcriptionRepository,
       _history = historyRepository,
       _audioImport = audioImportService,
       _sharedInbox = sharedAudioInbox,
       super(AppState(user: authRepository.currentUser)) {
    if (state.user != null) unawaited(_activateAccount(state.user!));
    _sharedAudioSubscription = _sharedInbox.received.listen(
      (payload) => unawaited(_importShared(payload)),
      onError: (Object error, StackTrace stackTrace) {
        state = state.copyWith(
          errorMessage: const AppFailure(AppFailureCode.shareHandoff).message,
        );
      },
    );
    _authStateSubscription = _auth.authStateChanges.listen(
      (user) {
        if (user == null || state.user?.id == user.id) return;
        if (state.authBusy) {
          _deferredAuthUser = user;
          return;
        }
        unawaited(_acceptAuthenticatedUser(user));
      },
      onError: (Object error, StackTrace stackTrace) {
        if (state.user == null) {
          state = state.copyWith(
            authBusy: false,
            errorMessage: const AppFailure(
              AppFailureCode.authentication,
            ).message,
          );
        }
      },
    );
    unawaited(takePendingSharedAudio());
  }

  final AuthRepository _auth;
  final SubscriptionRepository _subscriptions;
  final TranscriptionRepository _transcription;
  final HistoryRepository _history;
  final AudioImportService _audioImport;
  final SharedAudioInbox _sharedInbox;
  static const _uuid = Uuid();
  StreamSubscription<List<BriefResult>>? _historySubscription;
  StreamSubscription<SharedAudioPayload>? _sharedAudioSubscription;
  StreamSubscription<AuthUser?>? _authStateSubscription;
  AuthUser? _deferredAuthUser;
  String? _activeJobId;

  void setNavigationIndex(int index) =>
      state = state.copyWith(navigationIndex: index);

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void clearError() => state = state.copyWith(errorMessage: null);

  Future<bool> signInWithEmail(String email, String password) =>
      _authenticate(() => _auth.signInWithEmail(email, password));

  Future<bool> createAccount(String email, String password) =>
      _authenticate(() => _auth.createAccount(email, password));

  Future<bool> signInWithProvider(IdentityProvider provider) =>
      _authenticate(() => _auth.signInWithProvider(provider));

  Future<bool> _authenticate(Future<AuthUser?> Function() action) async {
    state = state.copyWith(authBusy: true, errorMessage: null);
    try {
      final returnedUser = await action();
      final user = returnedUser ?? _deferredAuthUser;
      _deferredAuthUser = null;
      if (user == null) {
        state = state.copyWith(authBusy: false);
        return false;
      }
      return _acceptAuthenticatedUser(user);
    } on AppFailure catch (failure) {
      state = state.copyWith(authBusy: false, errorMessage: failure.message);
      return false;
    } on Object {
      state = state.copyWith(
        authBusy: false,
        errorMessage: const AppFailure(AppFailureCode.authentication).message,
      );
      return false;
    }
  }

  Future<bool> _acceptAuthenticatedUser(AuthUser user) async {
    if (!user.emailVerified) {
      state = state.copyWith(
        user: null,
        authBusy: false,
        errorMessage: const AppFailure(
          AppFailureCode.emailVerificationRequired,
        ).message,
      );
      return false;
    }
    state = state.copyWith(user: user, authBusy: false, errorMessage: null);
    await _activateAccount(user);
    return true;
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(errorMessage: failure.message);
      return false;
    } on Object {
      state = state.copyWith(
        errorMessage: const AppFailure(
          AppFailureCode.serviceUnavailable,
        ).message,
      );
      return false;
    }
  }

  Future<void> _activateAccount(AuthUser user) async {
    final accountId = user.id;
    await _historySubscription?.cancel();
    _historySubscription = _history
        .watch(accountId)
        .listen(
          (items) => state = state.copyWith(history: items),
          onError: (_) => state = state.copyWith(
            errorMessage: const AppFailure(
              AppFailureCode.invalidResponse,
            ).message,
          ),
        );
    try {
      await _subscriptions.logIn(accountId);
      final subscription = await _subscriptions.load();
      state = state.copyWith(subscription: subscription);
    } on AppFailure catch (failure) {
      state = state.copyWith(errorMessage: failure.message);
    }
  }

  Future<void> signOut() async {
    final audio = state.selectedAudio;
    if (audio != null) await _audioImport.discard(audio);
    _activeJobId = null;
    await _subscriptions.logOut();
    await _auth.signOut();
    await _historySubscription?.cancel();
    state = const AppState();
  }

  Future<bool> deleteAccount() async {
    final accountId = state.user?.id;
    if (accountId == null) return false;
    try {
      await _auth.deleteAccount();
      await _history.clear(accountId);
      final audio = state.selectedAudio;
      if (audio != null) await _audioImport.discard(audio);
      _activeJobId = null;
      await _subscriptions.logOut();
      await _historySubscription?.cancel();
      state = const AppState();
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(errorMessage: failure.message);
      return false;
    } on Object {
      state = state.copyWith(
        errorMessage: const AppFailure(
          AppFailureCode.serviceUnavailable,
        ).message,
      );
      return false;
    }
  }

  Future<bool> pickAudio() async {
    clearError();
    try {
      final previous = state.selectedAudio;
      final input = await _audioImport.pick();
      if (input == null) return false;
      _activeJobId = null;
      state = state.copyWith(selectedAudio: input);
      if (previous != null && previous.path != input.path) {
        await _audioImport.discard(previous);
      }
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(errorMessage: failure.message);
      return false;
    } on Object {
      state = state.copyWith(
        errorMessage: const AppFailure(AppFailureCode.unreadableAudio).message,
      );
      return false;
    }
  }

  Future<bool> takePendingSharedAudio() async {
    try {
      final pending = await _sharedInbox.takePending();
      if (pending == null) return false;
      return _importShared(pending);
    } on MissingPluginException {
      return false;
    } on AppFailure catch (failure) {
      state = state.copyWith(errorMessage: failure.message);
      return false;
    } on Object {
      state = state.copyWith(
        errorMessage: const AppFailure(AppFailureCode.shareHandoff).message,
      );
      return false;
    }
  }

  Future<bool> _importShared(SharedAudioPayload pending) async {
    state = state.copyWith(audioImporting: true, errorMessage: null);
    var adopted = false;
    try {
      final previous = state.selectedAudio;
      final source = pending.source == 'iosShare'
          ? AudioSourceKind.iosShare
          : AudioSourceKind.androidShare;
      final input = await _audioImport.importOwnedPrivateFile(
        sourcePath: pending.path,
        displayName: pending.name,
        mimeType: pending.mime,
        source: source,
        knownSizeBytes: pending.sizeBytes,
        knownDurationSeconds: pending.durationSeconds,
      );
      adopted = true;
      _activeJobId = null;
      state = state.copyWith(selectedAudio: input, audioImporting: false);
      if (previous != null && previous.path != input.path) {
        await _audioImport.discard(previous);
      }
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(
        audioImporting: false,
        errorMessage: failure.message,
      );
      return false;
    } on Object {
      state = state.copyWith(
        audioImporting: false,
        errorMessage: const AppFailure(AppFailureCode.shareHandoff).message,
      );
      return false;
    } finally {
      if (!adopted) await _audioImport.discardSourcePath(pending.path);
    }
  }

  Future<void> selectRecording(String filePath, int durationSeconds) async {
    final previous = state.selectedAudio;
    final input = await _audioImport.importPrivateCopy(
      sourcePath: filePath,
      displayName: 'VoiceBrief recording.m4a',
      mimeType: 'audio/mp4',
      source: AudioSourceKind.recording,
    );
    _activeJobId = null;
    state = state.copyWith(
      selectedAudio: input.copyWith(durationSeconds: durationSeconds),
    );
    if (previous != null && previous.path != input.path) {
      await _audioImport.discard(previous);
    }
  }

  Future<void> discardAudio() async {
    final input = state.selectedAudio;
    _activeJobId = null;
    state = state.copyWith(selectedAudio: null);
    if (input != null) await _audioImport.discard(input);
  }

  Future<bool> trimSelectedAudio({
    required Duration start,
    required Duration end,
  }) async {
    final input = state.selectedAudio;
    if (input == null) return false;
    clearError();
    try {
      final trimmed = await _audioImport.trim(input, start: start, end: end);
      _activeJobId = null;
      state = state.copyWith(selectedAudio: trimmed);
      if (input.path != trimmed.path) await _audioImport.discard(input);
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(errorMessage: failure.message);
      return false;
    } on Object {
      state = state.copyWith(
        errorMessage: const AppFailure(AppFailureCode.audioEditing).message,
      );
      return false;
    }
  }

  void updateProcessingOptions(ProcessingOptions options) =>
      state = state.copyWith(processingOptions: options);

  Future<BriefResult?> createBrief() async {
    final audio = state.selectedAudio;
    if (audio == null) return null;
    final billedMinutes = billedMinutesForDuration(
      Duration(seconds: audio.durationSeconds),
    );
    if (billedMinutes > state.subscription.remainingMinutes) {
      state = state.copyWith(
        errorMessage: const AppFailure(AppFailureCode.quotaExhausted).message,
      );
      return null;
    }
    state = state.copyWith(
      processing: true,
      processingStep: ProcessingStep.preparing,
      errorMessage: null,
    );
    try {
      final result = await _transcription.createBrief(
        jobId: _activeJobId ??= _uuid.v4(),
        audio: audio,
        options: state.processingOptions.copyWith(transcript: true),
        onStage: (stage) {
          if (!mounted) return;
          state = state.copyWith(processingStep: _stepFor(stage));
        },
      );
      final subscription = state.subscription.copyWith(
        remainingMinutes: (state.subscription.remainingMinutes - billedMinutes)
            .clamp(0, state.subscription.totalMinutes)
            .toInt(),
      );
      state = state.copyWith(
        processing: false,
        activeResult: result,
        selectedAudio: null,
        subscription: subscription,
      );
      _activeJobId = null;
      await _audioImport.discard(audio);
      return result;
    } on AppFailure catch (failure) {
      state = state.copyWith(processing: false, errorMessage: failure.message);
      return null;
    } on Object {
      state = state.copyWith(
        processing: false,
        errorMessage: const AppFailure(AppFailureCode.transcription).message,
      );
      return null;
    }
  }

  ProcessingStep _stepFor(String stage) => switch (stage) {
    'uploading' => ProcessingStep.uploading,
    'transcribing' => ProcessingStep.transcribing,
    'creating' => ProcessingStep.creating,
    'finalizing' => ProcessingStep.finalizing,
    _ => ProcessingStep.preparing,
  };

  Future<void> saveActiveResult() async {
    final result = state.activeResult;
    final accountId = state.user?.id;
    if (result == null || accountId == null) return;
    await _history.save(accountId, result);
    state = state.copyWith(activeResult: result.copyWith(savedLocally: true));
  }

  Future<bool> deleteResult(String id) async {
    final accountId = state.user?.id;
    if (accountId == null) return false;
    final previousHistory = state.history;
    final previousActive = state.activeResult;
    state = state.copyWith(
      history: previousHistory
          .where((item) => item.id != id)
          .toList(growable: false),
      activeResult: previousActive?.id == id ? null : previousActive,
    );
    try {
      await _history.delete(accountId, id);
      return true;
    } on Object {
      if (state.user?.id == accountId) {
        state = state.copyWith(
          history: previousHistory,
          activeResult: previousActive,
          errorMessage: const AppFailure(AppFailureCode.unknown).message,
        );
      }
      return false;
    }
  }

  Future<void> restoreResult(BriefResult result) async {
    final accountId = state.user?.id;
    if (accountId == null) return;
    final restored = result.copyWith(savedLocally: true);
    final withoutDuplicate = state.history
        .where((item) => item.id != result.id)
        .toList(growable: false);
    state = state.copyWith(history: [restored, ...withoutDuplicate]);
    try {
      await _history.save(accountId, restored);
    } on Object {
      state = state.copyWith(
        history: state.history
            .where((item) => item.id != result.id)
            .toList(growable: false),
        errorMessage: const AppFailure(AppFailureCode.unknown).message,
      );
    }
  }

  Future<bool> clearHistory() async {
    final accountId = state.user?.id;
    if (accountId == null) return false;
    final previousHistory = state.history;
    state = state.copyWith(history: const []);
    try {
      await _history.clear(accountId);
      return true;
    } on Object {
      if (state.user?.id == accountId) {
        state = state.copyWith(
          history: previousHistory,
          errorMessage: const AppFailure(AppFailureCode.unknown).message,
        );
      }
      return false;
    }
  }

  void openResult(BriefResult result) =>
      state = state.copyWith(activeResult: result);

  Future<bool> purchase(String productId) async {
    try {
      final status = await _subscriptions.purchase(productId);
      state = state.copyWith(subscription: status);
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(errorMessage: failure.message);
      return false;
    }
  }

  Future<bool> refreshSubscription() async {
    try {
      final status = await _subscriptions.load();
      state = state.copyWith(subscription: status);
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(errorMessage: failure.message);
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final status = await _subscriptions.restore();
      state = state.copyWith(subscription: status);
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(errorMessage: failure.message);
      return false;
    }
  }

  @override
  void dispose() {
    unawaited(_historySubscription?.cancel());
    unawaited(_sharedAudioSubscription?.cancel());
    unawaited(_authStateSubscription?.cancel());
    super.dispose();
  }
}
