import 'package:flutter/widgets.dart';
import 'package:voicebrief/l10n/app_localizations.dart';

extension VoiceBriefLocalizations on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String localizeFailure(String message) => switch (message) {
    'You appear to be offline. Check your connection and try again.' =>
      l10n.errorNoInternet,
    'We could not sign you in. Check your details and try again.' =>
      l10n.errorAuthentication,
    'Sign-in was canceled.' => l10n.errorProviderCanceled,
    'This sign-in method is unavailable right now.' =>
      l10n.errorIdentityProviderUnavailable,
    'Verify your email before continuing.' => l10n.errorEmailVerification,
    'This audio format is not supported.' => l10n.errorUnsupportedAudio,
    'This audio file is larger than the current upload limit.' =>
      l10n.errorFileTooLarge,
    'This audio file could not be read. Try another file.' =>
      l10n.errorUnreadableAudio,
    'This audio could not be trimmed on this device. Your original is unchanged.' =>
      l10n.errorAudioEditing,
    'Microphone access is needed only when you choose to record.' =>
      l10n.errorMicrophoneDenied,
    'The secure upload was interrupted. You can retry safely.' =>
      l10n.errorUploadInterrupted,
    'Processing took too long. Your minutes were not charged.' =>
      l10n.errorProcessingTimeout,
    'The audio could not be transcribed. Try again in a moment.' =>
      l10n.errorTranscription,
    'The result was incomplete and was not saved.' => l10n.errorInvalidResponse,
    'You do not have enough processing minutes for this audio.' =>
      l10n.errorQuotaExhausted,
    'Subscription options are unavailable right now.' =>
      l10n.errorSubscriptionUnavailable,
    'The purchase was canceled.' => l10n.errorPurchaseCanceled,
    'The purchase did not complete. You were not charged by VoiceBrief.' =>
      l10n.errorPurchaseFailed,
    'Purchases could not be restored. Try again later.' =>
      l10n.errorRestoreFailed,
    'VoiceBrief is temporarily unavailable. Try again shortly.' =>
      l10n.errorServiceUnavailable,
    'The shared audio could not be imported safely.' => l10n.errorShareHandoff,
    'This feature still needs its production configuration.' =>
      l10n.errorConfiguration,
    'Something went wrong. Try again.' => l10n.errorUnknown,
    _ => message,
  };
}
