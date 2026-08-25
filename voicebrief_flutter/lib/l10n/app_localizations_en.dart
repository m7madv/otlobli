// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get home => 'Home';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get tryAgain => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get continueLabel => 'Continue';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get edit => 'Edit';

  @override
  String get copied => 'Copied';

  @override
  String get complete => 'Complete';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get replaceAudio => 'Replace audio';

  @override
  String get removeAudio => 'Remove audio';

  @override
  String get playAudio => 'Play audio';

  @override
  String get pauseAudio => 'Pause audio';

  @override
  String get audioWaveform => 'Audio waveform';

  @override
  String get audioWaveformLoading => 'Drawing the real audio waveform…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'Audio playback, $elapsed of $duration';
  }

  @override
  String copySection(String title) {
    return 'Copy $title';
  }

  @override
  String get screenUnavailable => 'This screen is unavailable.';

  @override
  String get goPro => 'Go Pro';

  @override
  String get homeHeadline => 'Turn voice notes into clear next steps';

  @override
  String get homeSupporting =>
      'Share from WhatsApp, choose an audio file, or record here.';

  @override
  String get shareFromWhatsApp => 'From WhatsApp';

  @override
  String get shareFromWhatsAppSteps =>
      'Hold the voice message, then tap Share, then VoiceBrief';

  @override
  String get chooseVoiceNote => 'Choose a voice note';

  @override
  String get recordInstead => 'Record instead';

  @override
  String get recentBriefs => 'Recent briefs';

  @override
  String get viewAll => 'View all';

  @override
  String get noBriefsYet => 'No briefs yet';

  @override
  String get noBriefsMessage =>
      'Choose or record audio to create your first brief.';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return '$remaining of $total free minutes remaining';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return '$remaining of $total Pro minutes remaining';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return '$remaining of $total minutes remaining';
  }

  @override
  String get authHeadline => 'Make every voice message useful';

  @override
  String get authSupporting =>
      'Sign in to protect your minutes and keep saved briefs private to your account.';

  @override
  String get demoServicesActive =>
      'Demo services are active. No external account or paid API is used.';

  @override
  String get providerSignInTitle => 'Fast, secure sign-in';

  @override
  String get providerSignInDescription =>
      'Choose Apple or Google. VoiceBrief never sees your account password.';

  @override
  String get providerSignInOpened =>
      'Finish signing in on the open Google page. You will return to VoiceBrief automatically.';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orUseEmail => 'or use email';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get shortPassword => 'Use at least 8 characters.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get createAccount => 'Create account';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get newToVoiceBrief => 'New to VoiceBrief? Create account';

  @override
  String get byContinuingPrefix => 'By continuing, you agree to the ';

  @override
  String get terms => 'Terms';

  @override
  String get andConjunction => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get passwordResetSent => 'Password reset email sent.';

  @override
  String get errorIdentityProviderUnavailable =>
      'This sign-in method is unavailable right now. Try another method.';

  @override
  String get onboardingSignIn => 'Sign in';

  @override
  String get onboardingTitleOne => 'Turn voice into clarity';

  @override
  String get onboardingBodyOne =>
      'Share, choose, or record a voice note. VoiceBrief returns the transcript, summary, tasks, dates, and suggested replies.';

  @override
  String get onboardingTitleTwo => 'Your audio stays private';

  @override
  String get onboardingBodyTwo =>
      'Audio is processed securely and deleted automatically. You choose which text results to save.';

  @override
  String get getStarted => 'Get started';

  @override
  String get recordAudio => 'Record audio';

  @override
  String get discardRecordingTitle => 'Discard recording?';

  @override
  String get discardRecordingMessage =>
      'The current recording will be deleted.';

  @override
  String get discard => 'Discard';

  @override
  String get recordingPaused => 'Recording paused';

  @override
  String get recording => 'Recording';

  @override
  String get tapRecordReady => 'Tap record when you are ready';

  @override
  String get startRecording => 'Start recording';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get cancelRecording => 'Cancel recording';

  @override
  String get microphoneJustInTime =>
      'Microphone access is requested only when you tap record.';

  @override
  String get recordingSaveFailed => 'The recording could not be saved.';

  @override
  String get liveWaveformIdle =>
      'The real waveform appears after recording starts.';

  @override
  String get liveWaveformStarting => 'Reading the real microphone level…';

  @override
  String get liveWaveformActive =>
      'This waveform is moving with your live voice.';

  @override
  String get historyLocalOnly => 'Saved locally on this device';

  @override
  String get searchBriefs => 'Search briefs';

  @override
  String get nothingSaved => 'Nothing saved yet';

  @override
  String get nothingSavedMessage =>
      'Save a result when you want it to appear here.';

  @override
  String get noMatchingBriefs => 'No matching briefs';

  @override
  String get noMatchingBriefsMessage =>
      'Try a different title or summary word.';

  @override
  String get briefDeleted => 'Brief deleted';

  @override
  String get undo => 'Undo';

  @override
  String get voiceNoteReady => 'Voice note ready';

  @override
  String get reviewAudio => 'Review audio';

  @override
  String get createMyBrief => 'Create my brief';

  @override
  String get secureAiProcessing =>
      'Secure AI processing · temporary audio is deleted after processing';

  @override
  String get secureAiProcessingSemantics =>
      'Audio is sent securely for AI processing and removed from temporary storage after processing.';

  @override
  String get trimAudio => 'Trim audio';

  @override
  String get trimAudioHelp =>
      'Drag both handles to choose the part you want summarized. You can play it before continuing.';

  @override
  String selectedAudioRange(String start, String end) {
    return 'Selected part: $start — $end';
  }

  @override
  String get useFullAudio => 'Use full audio';

  @override
  String get createBriefFromSelection => 'Create brief from this part';

  @override
  String get trimmingAudio => 'Trimming audio…';

  @override
  String get audioTrimmed => 'Audio trimmed. Only the selected part was kept.';

  @override
  String get sharedAudioImporting => 'Preparing the shared voice note…';

  @override
  String get customizeOutput => 'Customize what I get';

  @override
  String get defaultOutput =>
      'The brief and word-for-word text are included automatically';

  @override
  String get fullTranscript => 'Word-for-word transcript';

  @override
  String get fullTranscriptDescription =>
      'Everything said in the recording, kept as spoken so you can review, search, or copy it.';

  @override
  String get summaryAndKeyPoints => 'Summary and key points';

  @override
  String get actionItemsAndDates => 'Action items and dates';

  @override
  String get suggestedReplies => 'Suggested replies';

  @override
  String get translateSummaryEnglish => 'Translate summary to English';

  @override
  String get sharedAudioReadySemantics =>
      'Shared voice note imported and ready.';

  @override
  String get sharedAudioReady => 'Shared voice note imported. One tap left.';

  @override
  String get creatingBrief => 'Creating your brief';

  @override
  String get processingFallbackError =>
      'Processing could not be completed. The secure server copy was deleted and your private local copy is ready to retry.';

  @override
  String get processingKeepOpen =>
      'Keep VoiceBrief open until the secure upload finishes. Remaining time can vary with the recording length and connection.';

  @override
  String get preparingAudio => 'Preparing audio';

  @override
  String get uploadingSecurely => 'Uploading securely';

  @override
  String get transcribing => 'Transcribing';

  @override
  String get creatingYourBrief => 'Creating your brief';

  @override
  String get finalizing => 'Finalizing';

  @override
  String get brief => 'Brief';

  @override
  String get briefUnavailable => 'This brief is no longer available.';

  @override
  String get copyAll => 'Copy all';

  @override
  String get shareResult => 'Share result';

  @override
  String get savedLocally => 'Saved locally';

  @override
  String get notSaved => 'Not saved';

  @override
  String get saved => 'Saved';

  @override
  String get saveResult => 'Save result';

  @override
  String get deleteResult => 'Delete result';

  @override
  String get deleteBriefTitle => 'Delete this brief?';

  @override
  String get deleteBriefMessage =>
      'Saved text will be removed from this device.';

  @override
  String get keyPoints => 'Key points';

  @override
  String get actionItems => 'Action items';

  @override
  String get importantDates => 'Important dates';

  @override
  String get addToCalendar => 'Add to calendar';

  @override
  String ownerLabel(String owner) {
    return 'Owner: $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'Heard: “$phrase”';
  }

  @override
  String get needsConfirmation => 'Needs confirmation';

  @override
  String get taskDeadline => 'Task deadline';

  @override
  String get shortTone => 'Short';

  @override
  String get friendlyTone => 'Friendly';

  @override
  String get professionalTone => 'Professional';

  @override
  String get shortReply => 'Short reply';

  @override
  String get friendlyReply => 'Friendly reply';

  @override
  String get professionalReply => 'Professional reply';

  @override
  String get replyText => 'Reply text';

  @override
  String get shareEditedReply => 'Share edited reply';

  @override
  String get copyEditedReply => 'Copy edited reply';

  @override
  String confirmDatePhrase(String phrase) {
    return 'Confirm “$phrase”';
  }

  @override
  String get confirmEventTime => 'Confirm event time';

  @override
  String get openCalendarTitle => 'Open calendar?';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'VoiceBrief interpreted “$phrase” as $date. Your calendar will ask you to confirm before saving.';
  }

  @override
  String get openCalendar => 'Open calendar';

  @override
  String calendarDescription(String phrase) {
    return 'Created from VoiceBrief after confirming: “$phrase”';
  }

  @override
  String get calendarOpened => 'Calendar editor opened.';

  @override
  String datesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dates found · review and add them to your calendar',
      one: '1 date found · review and add it to your calendar',
    );
    return '$_temp0';
  }

  @override
  String datesFoundSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dates were found. Review them before adding to the system calendar.',
      one: '1 date was found. Review it before adding to the system calendar.',
    );
    return '$_temp0';
  }

  @override
  String get account => 'Account';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get verifiedAccount => 'Verified account';

  @override
  String get emailVerificationRequired => 'Email verification required';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'Free plan';

  @override
  String minutesRemaining(int count) {
    return '$count minutes remaining';
  }

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get purchasesRestored => 'Purchases restored.';

  @override
  String get noPurchasesRestored => 'No purchases were restored.';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get privacyAndData => 'Privacy and data';

  @override
  String get audioHandlingTitle =>
      'Audio is temporary; saving text is optional';

  @override
  String get audioHandlingDescription =>
      'Audio is used temporarily for transcription, then deleted automatically. Only a brief and transcript you choose to save can remain in history.';

  @override
  String get exportSavedText => 'Share saved text';

  @override
  String get exportSubject => 'VoiceBrief export';

  @override
  String get exportSavedTextDescription =>
      'Creates a TXT file containing briefs, key points, tasks, dates, replies, and transcripts, then opens the share sheet. It never includes audio.';

  @override
  String get exportSavedTextFailed =>
      'The text file could not be created for sharing.';

  @override
  String get noSavedTextOnDevice => 'There is no saved text on this device.';

  @override
  String get clearLocalHistory => 'Delete saved text';

  @override
  String get clearSavedTextDescription =>
      'Deletes briefs and transcripts from this device only. No audio recordings are stored here.';

  @override
  String get clearHistoryTitle => 'Delete saved text?';

  @override
  String get clearHistoryMessage =>
      'All briefs and transcripts saved on this device will be permanently deleted. Audio files are already deleted after processing.';

  @override
  String get clearHistory => 'Delete text';

  @override
  String get savedTextCleared => 'Saved text deleted.';

  @override
  String get clearSavedTextFailed =>
      'Saved text could not be deleted. Try again.';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get support => 'Support';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get appVersion => 'App version';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountMessage =>
      'This deletes your server account and local history. Store subscriptions continue until you cancel them in your store account.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get active => 'Active';

  @override
  String get proHeadline => 'Turn every voice message into an actionable brief';

  @override
  String get accurateTranscripts => 'Accurate transcripts';

  @override
  String get instantSummaries => 'Instant summaries';

  @override
  String get threeReplyTones => 'Three ready-to-send reply tones';

  @override
  String get loadingStorePrices => 'Loading store prices…';

  @override
  String get subscriptionOptionsUnavailable =>
      'Subscription options are unavailable. No fallback price is shown in production.';

  @override
  String get yearly => 'Yearly';

  @override
  String get monthly => 'Monthly';

  @override
  String get bestValue => 'BEST VALUE · SAVE 34%';

  @override
  String get proActive => 'Pro is active';

  @override
  String get subscriptionRenewalNotice =>
      'Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel at any time in your store account.';

  @override
  String get privacy => 'Privacy';

  @override
  String get proActivatedToast => 'VoiceBrief Pro is active.';

  @override
  String get noActivePurchases => 'No active purchases found.';

  @override
  String get errorNoInternet =>
      'You appear to be offline. Check your connection and try again.';

  @override
  String get errorAuthentication =>
      'We could not sign you in. Check your details and try again.';

  @override
  String get errorProviderCanceled => 'Sign-in was canceled.';

  @override
  String get errorEmailVerification => 'Verify your email before continuing.';

  @override
  String get errorUnsupportedAudio => 'This audio format is not supported.';

  @override
  String get errorFileTooLarge =>
      'This audio file is larger than the current upload limit.';

  @override
  String get errorUnreadableAudio =>
      'This audio file could not be read. Try another file.';

  @override
  String get errorAudioEditing =>
      'This audio could not be trimmed on this device. Your original is unchanged.';

  @override
  String get errorMicrophoneDenied =>
      'Microphone access is needed only when you choose to record.';

  @override
  String get errorUploadInterrupted =>
      'The secure upload was interrupted. You can retry safely.';

  @override
  String get errorProcessingTimeout =>
      'Processing took too long. Your minutes were not charged.';

  @override
  String get errorTranscription =>
      'The audio could not be transcribed. Try again in a moment.';

  @override
  String get errorInvalidResponse =>
      'The result was incomplete and was not saved.';

  @override
  String get errorQuotaExhausted =>
      'You do not have enough processing minutes for this audio.';

  @override
  String get errorSubscriptionUnavailable =>
      'Subscription options are unavailable right now.';

  @override
  String get errorPurchaseCanceled => 'The purchase was canceled.';

  @override
  String get errorPurchaseFailed =>
      'The purchase did not complete. You were not charged by VoiceBrief.';

  @override
  String get errorRestoreFailed =>
      'Purchases could not be restored. Try again later.';

  @override
  String get errorServiceUnavailable =>
      'VoiceBrief is temporarily unavailable. Try again shortly.';

  @override
  String get errorShareHandoff =>
      'The shared audio could not be imported safely.';

  @override
  String get errorConfiguration =>
      'This feature still needs its production configuration.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';
}
