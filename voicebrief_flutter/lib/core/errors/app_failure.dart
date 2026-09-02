enum AppFailureCode {
  noInternet,
  authentication,
  providerCanceled,
  identityProviderUnavailable,
  emailVerificationRequired,
  unsupportedAudio,
  fileTooLarge,
  unreadableAudio,
  audioEditing,
  microphoneDenied,
  uploadInterrupted,
  processingTimeout,
  transcription,
  invalidResponse,
  quotaExhausted,
  subscriptionUnavailable,
  subscriptionSyncPending,
  purchaseCanceled,
  purchaseFailed,
  restoreFailed,
  serviceUnavailable,
  shareHandoff,
  configuration,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure(this.code, {this.debugContext});

  final AppFailureCode code;

  /// Diagnostic context that must never contain audio, transcript text, tokens,
  /// credentials, or other personal content.
  final String? debugContext;

  String get message => switch (code) {
    AppFailureCode.noInternet =>
      'You appear to be offline. Check your connection and try again.',
    AppFailureCode.authentication =>
      'We could not sign you in. Check your details and try again.',
    AppFailureCode.providerCanceled => 'Sign-in was canceled.',
    AppFailureCode.identityProviderUnavailable =>
      'This sign-in method is unavailable right now.',
    AppFailureCode.emailVerificationRequired =>
      'Check your email and open the verification link, then return to VoiceBrief.',
    AppFailureCode.unsupportedAudio => 'This audio format is not supported.',
    AppFailureCode.fileTooLarge =>
      'This audio file is larger than the current upload limit.',
    AppFailureCode.unreadableAudio =>
      'This audio file could not be read. Try another file.',
    AppFailureCode.audioEditing =>
      'This audio could not be trimmed on this device. Your original is unchanged.',
    AppFailureCode.microphoneDenied =>
      'Microphone access is needed only when you choose to record.',
    AppFailureCode.uploadInterrupted =>
      'The secure upload was interrupted. You can retry safely.',
    AppFailureCode.processingTimeout =>
      'Processing took too long. Your minutes were not charged.',
    AppFailureCode.transcription =>
      'The audio could not be transcribed. Try again in a moment.',
    AppFailureCode.invalidResponse =>
      'The result was incomplete and was not saved.',
    AppFailureCode.quotaExhausted =>
      'You do not have enough processing minutes for this audio.',
    AppFailureCode.subscriptionUnavailable =>
      'Subscription options are unavailable right now.',
    AppFailureCode.subscriptionSyncPending =>
      'Your purchase is confirmed and Pro is still syncing. Keep VoiceBrief open and try again shortly.',
    AppFailureCode.purchaseCanceled => 'The purchase was canceled.',
    AppFailureCode.purchaseFailed =>
      'The purchase did not complete. You were not charged by VoiceBrief.',
    AppFailureCode.restoreFailed =>
      'Purchases could not be restored. Try again later.',
    AppFailureCode.serviceUnavailable =>
      'VoiceBrief is temporarily unavailable. Try again shortly.',
    AppFailureCode.shareHandoff =>
      'The shared audio could not be imported safely.',
    AppFailureCode.configuration =>
      'This feature still needs its production configuration.',
    AppFailureCode.unknown => 'Something went wrong. Try again.',
  };

  @override
  String toString() => 'AppFailure(${code.name})';
}
