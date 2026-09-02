import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'VoiceBrief'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @replaceAudio.
  ///
  /// In en, this message translates to:
  /// **'Replace audio'**
  String get replaceAudio;

  /// No description provided for @removeAudio.
  ///
  /// In en, this message translates to:
  /// **'Remove audio'**
  String get removeAudio;

  /// No description provided for @playAudio.
  ///
  /// In en, this message translates to:
  /// **'Play audio'**
  String get playAudio;

  /// No description provided for @pauseAudio.
  ///
  /// In en, this message translates to:
  /// **'Pause audio'**
  String get pauseAudio;

  /// No description provided for @audioWaveform.
  ///
  /// In en, this message translates to:
  /// **'Audio waveform'**
  String get audioWaveform;

  /// No description provided for @audioWaveformLoading.
  ///
  /// In en, this message translates to:
  /// **'Drawing the real audio waveform…'**
  String get audioWaveformLoading;

  /// No description provided for @audioPlayback.
  ///
  /// In en, this message translates to:
  /// **'Audio playback, {elapsed} of {duration}'**
  String audioPlayback(String elapsed, String duration);

  /// No description provided for @copySection.
  ///
  /// In en, this message translates to:
  /// **'Copy {title}'**
  String copySection(String title);

  /// No description provided for @screenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This screen is unavailable.'**
  String get screenUnavailable;

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Turn voice notes into clear next steps'**
  String get homeHeadline;

  /// No description provided for @homeSupporting.
  ///
  /// In en, this message translates to:
  /// **'Share from WhatsApp, choose an audio file, or record here.'**
  String get homeSupporting;

  /// No description provided for @shareFromWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'From WhatsApp'**
  String get shareFromWhatsApp;

  /// No description provided for @shareFromWhatsAppSteps.
  ///
  /// In en, this message translates to:
  /// **'Hold the voice message, then tap Share, then VoiceBrief'**
  String get shareFromWhatsAppSteps;

  /// No description provided for @chooseVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Choose a voice note'**
  String get chooseVoiceNote;

  /// No description provided for @recordInstead.
  ///
  /// In en, this message translates to:
  /// **'Record instead'**
  String get recordInstead;

  /// No description provided for @recentBriefs.
  ///
  /// In en, this message translates to:
  /// **'Recent briefs'**
  String get recentBriefs;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noBriefsYet.
  ///
  /// In en, this message translates to:
  /// **'No briefs yet'**
  String get noBriefsYet;

  /// No description provided for @noBriefsMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose or record audio to create your first brief.'**
  String get noBriefsMessage;

  /// No description provided for @usageFreeMinutesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} free minutes remaining'**
  String usageFreeMinutesRemaining(int remaining, int total);

  /// No description provided for @usageProMinutesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} Pro minutes remaining'**
  String usageProMinutesRemaining(int remaining, int total);

  /// No description provided for @usageMinutesSemantics.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} minutes remaining'**
  String usageMinutesSemantics(int remaining, int total);

  /// No description provided for @authHeadline.
  ///
  /// In en, this message translates to:
  /// **'Make every voice message useful'**
  String get authHeadline;

  /// No description provided for @authSupporting.
  ///
  /// In en, this message translates to:
  /// **'Sign in to protect your minutes and keep saved briefs private to your account.'**
  String get authSupporting;

  /// No description provided for @demoServicesActive.
  ///
  /// In en, this message translates to:
  /// **'Demo services are active. No external account or paid API is used.'**
  String get demoServicesActive;

  /// No description provided for @providerSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast, secure sign-in'**
  String get providerSignInTitle;

  /// No description provided for @providerSignInDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose Apple or Google. VoiceBrief never sees your account password.'**
  String get providerSignInDescription;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @byContinuingPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to the '**
  String get byContinuingPrefix;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @andConjunction.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andConjunction;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @errorIdentityProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is unavailable right now. Try another method.'**
  String get errorIdentityProviderUnavailable;

  /// No description provided for @onboardingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get onboardingSignIn;

  /// No description provided for @onboardingTitleOne.
  ///
  /// In en, this message translates to:
  /// **'Turn voice into clarity'**
  String get onboardingTitleOne;

  /// No description provided for @onboardingBodyOne.
  ///
  /// In en, this message translates to:
  /// **'Share, choose, or record a voice note. VoiceBrief returns the transcript, summary, tasks, dates, and suggested replies.'**
  String get onboardingBodyOne;

  /// No description provided for @onboardingTitleTwo.
  ///
  /// In en, this message translates to:
  /// **'Your audio stays private'**
  String get onboardingTitleTwo;

  /// No description provided for @onboardingBodyTwo.
  ///
  /// In en, this message translates to:
  /// **'Audio is processed securely and deleted automatically. You choose which text results to save.'**
  String get onboardingBodyTwo;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @recordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get recordAudio;

  /// No description provided for @discardRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard recording?'**
  String get discardRecordingTitle;

  /// No description provided for @discardRecordingMessage.
  ///
  /// In en, this message translates to:
  /// **'The current recording will be deleted.'**
  String get discardRecordingMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @recordingPaused.
  ///
  /// In en, this message translates to:
  /// **'Recording paused'**
  String get recordingPaused;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @tapRecordReady.
  ///
  /// In en, this message translates to:
  /// **'Tap record when you are ready'**
  String get tapRecordReady;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get startRecording;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @cancelRecording.
  ///
  /// In en, this message translates to:
  /// **'Cancel recording'**
  String get cancelRecording;

  /// No description provided for @microphoneJustInTime.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is requested only when you tap record.'**
  String get microphoneJustInTime;

  /// No description provided for @recordingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The recording could not be saved.'**
  String get recordingSaveFailed;

  /// No description provided for @liveWaveformIdle.
  ///
  /// In en, this message translates to:
  /// **'The real waveform appears after recording starts.'**
  String get liveWaveformIdle;

  /// No description provided for @liveWaveformStarting.
  ///
  /// In en, this message translates to:
  /// **'Reading the real microphone level…'**
  String get liveWaveformStarting;

  /// No description provided for @liveWaveformActive.
  ///
  /// In en, this message translates to:
  /// **'This waveform is moving with your live voice.'**
  String get liveWaveformActive;

  /// No description provided for @historyLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Saved locally on this device'**
  String get historyLocalOnly;

  /// No description provided for @searchBriefs.
  ///
  /// In en, this message translates to:
  /// **'Search briefs'**
  String get searchBriefs;

  /// No description provided for @nothingSaved.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get nothingSaved;

  /// No description provided for @nothingSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Save a result when you want it to appear here.'**
  String get nothingSavedMessage;

  /// No description provided for @noMatchingBriefs.
  ///
  /// In en, this message translates to:
  /// **'No matching briefs'**
  String get noMatchingBriefs;

  /// No description provided for @noMatchingBriefsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different title or summary word.'**
  String get noMatchingBriefsMessage;

  /// No description provided for @briefDeleted.
  ///
  /// In en, this message translates to:
  /// **'Brief deleted'**
  String get briefDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @voiceNoteReady.
  ///
  /// In en, this message translates to:
  /// **'Voice note ready'**
  String get voiceNoteReady;

  /// No description provided for @reviewAudio.
  ///
  /// In en, this message translates to:
  /// **'Review audio'**
  String get reviewAudio;

  /// No description provided for @createMyBrief.
  ///
  /// In en, this message translates to:
  /// **'Create my brief'**
  String get createMyBrief;

  /// No description provided for @secureAiProcessing.
  ///
  /// In en, this message translates to:
  /// **'Secure AI processing · temporary audio is deleted after processing'**
  String get secureAiProcessing;

  /// No description provided for @secureAiProcessingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Audio is sent securely for AI processing and removed from temporary storage after processing.'**
  String get secureAiProcessingSemantics;

  /// No description provided for @trimAudio.
  ///
  /// In en, this message translates to:
  /// **'Trim audio'**
  String get trimAudio;

  /// No description provided for @trimAudioHelp.
  ///
  /// In en, this message translates to:
  /// **'Drag both handles to choose the part you want summarized. You can play it before continuing.'**
  String get trimAudioHelp;

  /// No description provided for @selectedAudioRange.
  ///
  /// In en, this message translates to:
  /// **'Selected part: {start} — {end}'**
  String selectedAudioRange(String start, String end);

  /// No description provided for @useFullAudio.
  ///
  /// In en, this message translates to:
  /// **'Use full audio'**
  String get useFullAudio;

  /// No description provided for @createBriefFromSelection.
  ///
  /// In en, this message translates to:
  /// **'Create brief from this part'**
  String get createBriefFromSelection;

  /// No description provided for @trimmingAudio.
  ///
  /// In en, this message translates to:
  /// **'Trimming audio…'**
  String get trimmingAudio;

  /// No description provided for @audioTrimmed.
  ///
  /// In en, this message translates to:
  /// **'Audio trimmed. Only the selected part was kept.'**
  String get audioTrimmed;

  /// No description provided for @sharedAudioImporting.
  ///
  /// In en, this message translates to:
  /// **'Preparing the shared voice note…'**
  String get sharedAudioImporting;

  /// No description provided for @customizeOutput.
  ///
  /// In en, this message translates to:
  /// **'Customize what I get'**
  String get customizeOutput;

  /// No description provided for @defaultOutput.
  ///
  /// In en, this message translates to:
  /// **'The brief and word-for-word text are included automatically'**
  String get defaultOutput;

  /// No description provided for @fullTranscript.
  ///
  /// In en, this message translates to:
  /// **'Word-for-word transcript'**
  String get fullTranscript;

  /// No description provided for @fullTranscriptDescription.
  ///
  /// In en, this message translates to:
  /// **'Everything said in the recording, kept as spoken so you can review, search, or copy it.'**
  String get fullTranscriptDescription;

  /// No description provided for @summaryAndKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'Summary and key points'**
  String get summaryAndKeyPoints;

  /// No description provided for @actionItemsAndDates.
  ///
  /// In en, this message translates to:
  /// **'Action items and dates'**
  String get actionItemsAndDates;

  /// No description provided for @suggestedReplies.
  ///
  /// In en, this message translates to:
  /// **'Suggested replies'**
  String get suggestedReplies;

  /// No description provided for @translateSummaryEnglish.
  ///
  /// In en, this message translates to:
  /// **'Translate summary to English'**
  String get translateSummaryEnglish;

  /// No description provided for @sharedAudioReadySemantics.
  ///
  /// In en, this message translates to:
  /// **'Shared voice note imported and ready.'**
  String get sharedAudioReadySemantics;

  /// No description provided for @sharedAudioReady.
  ///
  /// In en, this message translates to:
  /// **'Shared voice note imported. One tap left.'**
  String get sharedAudioReady;

  /// No description provided for @creatingBrief.
  ///
  /// In en, this message translates to:
  /// **'Creating your brief'**
  String get creatingBrief;

  /// No description provided for @processingFallbackError.
  ///
  /// In en, this message translates to:
  /// **'Processing could not be completed. The secure server copy was deleted and your private local copy is ready to retry.'**
  String get processingFallbackError;

  /// No description provided for @processingKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep VoiceBrief open until the secure upload finishes. Remaining time can vary with the recording length and connection.'**
  String get processingKeepOpen;

  /// No description provided for @preparingAudio.
  ///
  /// In en, this message translates to:
  /// **'Preparing audio'**
  String get preparingAudio;

  /// No description provided for @uploadingSecurely.
  ///
  /// In en, this message translates to:
  /// **'Uploading securely'**
  String get uploadingSecurely;

  /// No description provided for @transcribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing'**
  String get transcribing;

  /// No description provided for @creatingYourBrief.
  ///
  /// In en, this message translates to:
  /// **'Creating your brief'**
  String get creatingYourBrief;

  /// No description provided for @finalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing'**
  String get finalizing;

  /// No description provided for @brief.
  ///
  /// In en, this message translates to:
  /// **'Brief'**
  String get brief;

  /// No description provided for @briefUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This brief is no longer available.'**
  String get briefUnavailable;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get copyAll;

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share result'**
  String get shareResult;

  /// No description provided for @savedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally'**
  String get savedLocally;

  /// No description provided for @notSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get notSaved;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveResult.
  ///
  /// In en, this message translates to:
  /// **'Save result'**
  String get saveResult;

  /// No description provided for @deleteResult.
  ///
  /// In en, this message translates to:
  /// **'Delete result'**
  String get deleteResult;

  /// No description provided for @deleteBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this brief?'**
  String get deleteBriefTitle;

  /// No description provided for @deleteBriefMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved text will be removed from this device.'**
  String get deleteBriefMessage;

  /// No description provided for @keyPoints.
  ///
  /// In en, this message translates to:
  /// **'Key points'**
  String get keyPoints;

  /// No description provided for @actionItems.
  ///
  /// In en, this message translates to:
  /// **'Action items'**
  String get actionItems;

  /// No description provided for @importantDates.
  ///
  /// In en, this message translates to:
  /// **'Important dates'**
  String get importantDates;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendar;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get setReminder;

  /// No description provided for @reminderSet.
  ///
  /// In en, this message translates to:
  /// **'VoiceBrief alarm set.'**
  String get reminderSet;

  /// No description provided for @reminderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The reminder could not be set. Enable VoiceBrief notifications and try again.'**
  String get reminderUnavailable;

  /// No description provided for @reminderMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'Choose a future time for the reminder.'**
  String get reminderMustBeFuture;

  /// No description provided for @chooseAlarmTone.
  ///
  /// In en, this message translates to:
  /// **'Alarm sound'**
  String get chooseAlarmTone;

  /// No description provided for @chooseAlarmToneDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the original iPhone sound or choose your own.'**
  String get chooseAlarmToneDescription;

  /// No description provided for @previewTone.
  ///
  /// In en, this message translates to:
  /// **'Preview tone'**
  String get previewTone;

  /// No description provided for @confirmAlarm.
  ///
  /// In en, this message translates to:
  /// **'Use this sound'**
  String get confirmAlarm;

  /// No description provided for @alarmsAndReminders.
  ///
  /// In en, this message translates to:
  /// **'Alarms and reminders'**
  String get alarmsAndReminders;

  /// No description provided for @voiceBriefAlarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get voiceBriefAlarms;

  /// No description provided for @voiceBriefAlarmsDescription.
  ///
  /// In en, this message translates to:
  /// **'View or cancel your scheduled alarms.'**
  String get voiceBriefAlarmsDescription;

  /// No description provided for @noScheduledAlarms.
  ///
  /// In en, this message translates to:
  /// **'No upcoming alarms'**
  String get noScheduledAlarms;

  /// No description provided for @noScheduledAlarmsMessage.
  ///
  /// In en, this message translates to:
  /// **'Set an alarm from any date in a brief and it will appear here.'**
  String get noScheduledAlarmsMessage;

  /// No description provided for @alarmsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'VoiceBrief alarms could not be loaded right now.'**
  String get alarmsUnavailable;

  /// No description provided for @alarmScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get alarmScheduled;

  /// No description provided for @alarmToneLabel.
  ///
  /// In en, this message translates to:
  /// **'Tone: {tone}'**
  String alarmToneLabel(Object tone);

  /// No description provided for @alarmSoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarm sound'**
  String get alarmSoundTitle;

  /// No description provided for @systemAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Default iPhone sound'**
  String get systemAlarmSound;

  /// No description provided for @systemAlarmSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'The original sound provided by the system.'**
  String get systemAlarmSoundDescription;

  /// No description provided for @customAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Custom sound'**
  String get customAlarmSound;

  /// No description provided for @changeAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAlarmSound;

  /// No description provided for @addCustomAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Add your sound'**
  String get addCustomAlarmSound;

  /// No description provided for @importAudioSound.
  ///
  /// In en, this message translates to:
  /// **'Choose an audio file'**
  String get importAudioSound;

  /// No description provided for @importVideoSound.
  ///
  /// In en, this message translates to:
  /// **'Extract sound from a video'**
  String get importVideoSound;

  /// No description provided for @soundLimitNotice.
  ///
  /// In en, this message translates to:
  /// **'The first 29 seconds are saved in an alarm-ready format.'**
  String get soundLimitNotice;

  /// No description provided for @preparingAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Preparing sound…'**
  String get preparingAlarmSound;

  /// No description provided for @soundImportFailed.
  ///
  /// In en, this message translates to:
  /// **'This file could not be used. Choose a file that contains audio.'**
  String get soundImportFailed;

  /// No description provided for @importedSoundReady.
  ///
  /// In en, this message translates to:
  /// **'Sound is ready.'**
  String get importedSoundReady;

  /// No description provided for @useThisSound.
  ///
  /// In en, this message translates to:
  /// **'Use this sound'**
  String get useThisSound;

  /// No description provided for @upcomingAlarms.
  ///
  /// In en, this message translates to:
  /// **'Upcoming alarms'**
  String get upcomingAlarms;

  /// No description provided for @loadingAlarms.
  ///
  /// In en, this message translates to:
  /// **'Loading alarms…'**
  String get loadingAlarms;

  /// No description provided for @cancelAlarm.
  ///
  /// In en, this message translates to:
  /// **'Cancel alarm'**
  String get cancelAlarm;

  /// No description provided for @cancelAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this alarm?'**
  String get cancelAlarmTitle;

  /// No description provided for @cancelAlarmMessage.
  ///
  /// In en, this message translates to:
  /// **'The alarm “{title}” will not sound after it is canceled.'**
  String cancelAlarmMessage(Object title);

  /// No description provided for @alarmCancelled.
  ///
  /// In en, this message translates to:
  /// **'Alarm canceled.'**
  String get alarmCancelled;

  /// No description provided for @alarmCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'The alarm could not be canceled. Try again.'**
  String get alarmCancelFailed;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {title}'**
  String reminderNotificationTitle(String title);

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'From VoiceBrief: “{phrase}”'**
  String reminderNotificationBody(String phrase);

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner: {owner}'**
  String ownerLabel(String owner);

  /// No description provided for @heardLabel.
  ///
  /// In en, this message translates to:
  /// **'Heard: “{phrase}”'**
  String heardLabel(String phrase);

  /// No description provided for @needsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Needs confirmation'**
  String get needsConfirmation;

  /// No description provided for @taskDeadline.
  ///
  /// In en, this message translates to:
  /// **'Task deadline'**
  String get taskDeadline;

  /// No description provided for @shortTone.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get shortTone;

  /// No description provided for @friendlyTone.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get friendlyTone;

  /// No description provided for @professionalTone.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professionalTone;

  /// No description provided for @shortReply.
  ///
  /// In en, this message translates to:
  /// **'Short reply'**
  String get shortReply;

  /// No description provided for @friendlyReply.
  ///
  /// In en, this message translates to:
  /// **'Friendly reply'**
  String get friendlyReply;

  /// No description provided for @professionalReply.
  ///
  /// In en, this message translates to:
  /// **'Professional reply'**
  String get professionalReply;

  /// No description provided for @replyText.
  ///
  /// In en, this message translates to:
  /// **'Reply text'**
  String get replyText;

  /// No description provided for @shareEditedReply.
  ///
  /// In en, this message translates to:
  /// **'Share edited reply'**
  String get shareEditedReply;

  /// No description provided for @copyEditedReply.
  ///
  /// In en, this message translates to:
  /// **'Copy edited reply'**
  String get copyEditedReply;

  /// No description provided for @confirmDatePhrase.
  ///
  /// In en, this message translates to:
  /// **'Confirm “{phrase}”'**
  String confirmDatePhrase(String phrase);

  /// No description provided for @confirmEventTime.
  ///
  /// In en, this message translates to:
  /// **'Confirm event time'**
  String get confirmEventTime;

  /// No description provided for @openCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Open calendar?'**
  String get openCalendarTitle;

  /// No description provided for @openCalendarMessage.
  ///
  /// In en, this message translates to:
  /// **'VoiceBrief interpreted “{phrase}” as {date}. Your calendar will ask you to confirm before saving.'**
  String openCalendarMessage(String phrase, String date);

  /// No description provided for @openCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get openCalendar;

  /// No description provided for @calendarDescription.
  ///
  /// In en, this message translates to:
  /// **'Created from VoiceBrief after confirming: “{phrase}”'**
  String calendarDescription(String phrase);

  /// No description provided for @calendarOpened.
  ///
  /// In en, this message translates to:
  /// **'Calendar editor opened.'**
  String get calendarOpened;

  /// No description provided for @datesFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 date found · set a reminder or add it to your calendar} other{{count} dates found · set reminders or add them to your calendar}}'**
  String datesFound(int count);

  /// No description provided for @datesFoundSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 date was found. Review it, then set a reminder or add it to the system calendar.} other{{count} dates were found. Review them, then set reminders or add them to the system calendar.}}'**
  String datesFoundSemantics(int count);

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @verifiedAccount.
  ///
  /// In en, this message translates to:
  /// **'Verified account'**
  String get verifiedAccount;

  /// No description provided for @emailVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Email verification required'**
  String get emailVerificationRequired;

  /// No description provided for @voiceBriefPro.
  ///
  /// In en, this message translates to:
  /// **'VoiceBrief Pro'**
  String get voiceBriefPro;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get freePlan;

  /// No description provided for @minutesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes remaining'**
  String minutesRemaining(int count);

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get purchasesRestored;

  /// No description provided for @noPurchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'No purchases were restored.'**
  String get noPurchasesRestored;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @privacyAndData.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data'**
  String get privacyAndData;

  /// No description provided for @audioHandlingTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio is temporary; saving text is optional'**
  String get audioHandlingTitle;

  /// No description provided for @audioHandlingDescription.
  ///
  /// In en, this message translates to:
  /// **'Audio is used temporarily for transcription, then deleted automatically. Only a brief and transcript you choose to save can remain in history.'**
  String get audioHandlingDescription;

  /// No description provided for @exportSavedText.
  ///
  /// In en, this message translates to:
  /// **'Share saved text'**
  String get exportSavedText;

  /// No description provided for @exportSubject.
  ///
  /// In en, this message translates to:
  /// **'VoiceBrief export'**
  String get exportSubject;

  /// No description provided for @exportSavedTextDescription.
  ///
  /// In en, this message translates to:
  /// **'Creates a TXT file containing briefs, key points, tasks, dates, replies, and transcripts, then opens the share sheet. It never includes audio.'**
  String get exportSavedTextDescription;

  /// No description provided for @exportSavedTextFailed.
  ///
  /// In en, this message translates to:
  /// **'The text file could not be created for sharing.'**
  String get exportSavedTextFailed;

  /// No description provided for @noSavedTextOnDevice.
  ///
  /// In en, this message translates to:
  /// **'There is no saved text on this device.'**
  String get noSavedTextOnDevice;

  /// No description provided for @clearLocalHistory.
  ///
  /// In en, this message translates to:
  /// **'Delete saved text'**
  String get clearLocalHistory;

  /// No description provided for @clearSavedTextDescription.
  ///
  /// In en, this message translates to:
  /// **'Deletes briefs and transcripts from this device only. No audio recordings are stored here.'**
  String get clearSavedTextDescription;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete saved text?'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'All briefs and transcripts saved on this device will be permanently deleted. Audio files are already deleted after processing.'**
  String get clearHistoryMessage;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Delete text'**
  String get clearHistory;

  /// No description provided for @savedTextCleared.
  ///
  /// In en, this message translates to:
  /// **'Saved text deleted.'**
  String get savedTextCleared;

  /// No description provided for @clearSavedTextFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved text could not be deleted. Try again.'**
  String get clearSavedTextFailed;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This deletes your server account and local history. Store subscriptions continue until you cancel them in your store account.'**
  String get deleteAccountMessage;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @proHeadline.
  ///
  /// In en, this message translates to:
  /// **'Turn every voice message into an actionable brief'**
  String get proHeadline;

  /// No description provided for @accurateTranscripts.
  ///
  /// In en, this message translates to:
  /// **'Accurate transcripts'**
  String get accurateTranscripts;

  /// No description provided for @instantSummaries.
  ///
  /// In en, this message translates to:
  /// **'Instant summaries'**
  String get instantSummaries;

  /// No description provided for @threeReplyTones.
  ///
  /// In en, this message translates to:
  /// **'Three ready-to-send reply tones'**
  String get threeReplyTones;

  /// No description provided for @loadingStorePrices.
  ///
  /// In en, this message translates to:
  /// **'Loading store prices…'**
  String get loadingStorePrices;

  /// No description provided for @subscriptionOptionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription options are unavailable. No fallback price is shown in production.'**
  String get subscriptionOptionsUnavailable;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get bestValue;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'Pro is active'**
  String get proActive;

  /// No description provided for @subscriptionRenewalNotice.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel at any time in your store account.'**
  String get subscriptionRenewalNotice;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @proActivatedToast.
  ///
  /// In en, this message translates to:
  /// **'VoiceBrief Pro is active.'**
  String get proActivatedToast;

  /// No description provided for @noActivePurchases.
  ///
  /// In en, this message translates to:
  /// **'No active purchases found.'**
  String get noActivePurchases;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and try again.'**
  String get errorNoInternet;

  /// No description provided for @errorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you in. Check your details and try again.'**
  String get errorAuthentication;

  /// No description provided for @errorProviderCanceled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was canceled.'**
  String get errorProviderCanceled;

  /// No description provided for @errorEmailVerification.
  ///
  /// In en, this message translates to:
  /// **'Check your email and open the verification link, then return to VoiceBrief.'**
  String get errorEmailVerification;

  /// No description provided for @errorUnsupportedAudio.
  ///
  /// In en, this message translates to:
  /// **'This audio format is not supported.'**
  String get errorUnsupportedAudio;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This audio file is larger than the current upload limit.'**
  String get errorFileTooLarge;

  /// No description provided for @errorUnreadableAudio.
  ///
  /// In en, this message translates to:
  /// **'This audio file could not be read. Try another file.'**
  String get errorUnreadableAudio;

  /// No description provided for @errorAudioEditing.
  ///
  /// In en, this message translates to:
  /// **'This audio could not be trimmed on this device. Your original is unchanged.'**
  String get errorAudioEditing;

  /// No description provided for @errorMicrophoneDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is needed only when you choose to record.'**
  String get errorMicrophoneDenied;

  /// No description provided for @errorUploadInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The secure upload was interrupted. You can retry safely.'**
  String get errorUploadInterrupted;

  /// No description provided for @errorProcessingTimeout.
  ///
  /// In en, this message translates to:
  /// **'Processing took too long. Your minutes were not charged.'**
  String get errorProcessingTimeout;

  /// No description provided for @errorTranscription.
  ///
  /// In en, this message translates to:
  /// **'The audio could not be transcribed. Try again in a moment.'**
  String get errorTranscription;

  /// No description provided for @errorInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The result was incomplete and was not saved.'**
  String get errorInvalidResponse;

  /// No description provided for @errorQuotaExhausted.
  ///
  /// In en, this message translates to:
  /// **'You do not have enough processing minutes for this audio.'**
  String get errorQuotaExhausted;

  /// No description provided for @errorSubscriptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription options are unavailable right now.'**
  String get errorSubscriptionUnavailable;

  /// No description provided for @errorSubscriptionSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is confirmed and Pro is still syncing. Keep VoiceBrief open and try again shortly.'**
  String get errorSubscriptionSyncPending;

  /// No description provided for @errorPurchaseCanceled.
  ///
  /// In en, this message translates to:
  /// **'The purchase was canceled.'**
  String get errorPurchaseCanceled;

  /// No description provided for @errorPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase did not complete. You were not charged by VoiceBrief.'**
  String get errorPurchaseFailed;

  /// No description provided for @errorRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchases could not be restored. Try again later.'**
  String get errorRestoreFailed;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'VoiceBrief is temporarily unavailable. Try again shortly.'**
  String get errorServiceUnavailable;

  /// No description provided for @errorShareHandoff.
  ///
  /// In en, this message translates to:
  /// **'The shared audio could not be imported safely.'**
  String get errorShareHandoff;

  /// No description provided for @errorConfiguration.
  ///
  /// In en, this message translates to:
  /// **'This feature still needs its production configuration.'**
  String get errorConfiguration;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
