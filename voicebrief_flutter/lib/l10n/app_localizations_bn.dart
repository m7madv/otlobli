// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get appLanguage => 'অ্যাপের ভাষা';

  @override
  String get followSystemLanguage => 'ডিভাইসের ভাষা ব্যবহার করুন';

  @override
  String get home => 'হোম';

  @override
  String get history => 'ইতিহাস';

  @override
  String get settings => 'সেটিংস';

  @override
  String get cancel => 'বাতিল';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get continueLabel => 'এগিয়ে যান';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get delete => 'মুছুন';

  @override
  String get copy => 'কপি করুন';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get copied => 'কপি হয়েছে';

  @override
  String get complete => 'সম্পন্ন';

  @override
  String get unavailable => 'উপলব্ধ নয়';

  @override
  String get replaceAudio => 'অডিও বদলান';

  @override
  String get removeAudio => 'অডিও সরান';

  @override
  String get playAudio => 'অডিও চালান';

  @override
  String get pauseAudio => 'অডিও থামান';

  @override
  String get audioWaveform => 'অডিও তরঙ্গ';

  @override
  String get audioWaveformLoading => 'আসল অডিও তরঙ্গ আঁকা হচ্ছে…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'অডিও চলছে: $duration এর মধ্যে $elapsed';
  }

  @override
  String copySection(String title) {
    return '$title কপি করুন';
  }

  @override
  String get screenUnavailable => 'এই পর্দাটি উপলব্ধ নয়।';

  @override
  String get goPro => 'Pro নিন';

  @override
  String get homeHeadline => 'ভয়েস মেসেজ থেকে স্পষ্ট পরবর্তী পদক্ষেপ';

  @override
  String get homeSupporting =>
      'WhatsApp থেকে শেয়ার করুন, অডিও বাছুন বা এখানে রেকর্ড করুন।';

  @override
  String get shareFromWhatsApp => 'WhatsApp থেকে';

  @override
  String get shareFromWhatsAppSteps =>
      'ভয়েস মেসেজ চেপে ধরে শেয়ার চাপুন, তারপর VoiceBrief বাছুন';

  @override
  String get chooseVoiceNote => 'ভয়েস মেসেজ বাছুন';

  @override
  String get recordInstead => 'এখন রেকর্ড করুন';

  @override
  String get recentBriefs => 'সাম্প্রতিক সারসংক্ষেপ';

  @override
  String get viewAll => 'সব দেখুন';

  @override
  String get noBriefsYet => 'এখনো সারসংক্ষেপ নেই';

  @override
  String get noBriefsMessage =>
      'প্রথম সারসংক্ষেপ তৈরি করতে অডিও বাছুন বা রেকর্ড করুন।';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return '$total ফ্রি মিনিটের মধ্যে $remaining বাকি';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return '$total Pro মিনিটের মধ্যে $remaining বাকি';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return '$total মিনিটের মধ্যে $remaining বাকি';
  }

  @override
  String get authHeadline => 'প্রতিটি ভয়েস মেসেজকে কাজে লাগান';

  @override
  String get authSupporting =>
      'মিনিট সুরক্ষিত রাখতে এবং সংরক্ষিত সারসংক্ষেপ আপনার অ্যাকাউন্টে ব্যক্তিগত রাখতে সাইন ইন করুন।';

  @override
  String get demoServicesActive =>
      'ডেমো পরিষেবা চালু। বাইরের অ্যাকাউন্ট বা অর্থপ্রদত্ত পরিষেবা ব্যবহৃত হচ্ছে না।';

  @override
  String get providerSignInTitle => 'দ্রুত ও নিরাপদ সাইন ইন';

  @override
  String get providerSignInDescription =>
      'Apple বা Google বাছুন। VoiceBrief কখনো আপনার পাসওয়ার্ড দেখে না।';

  @override
  String get continueWithApple => 'Apple দিয়ে চালিয়ে যান';

  @override
  String get continueWithGoogle => 'Google দিয়ে চালিয়ে যান';

  @override
  String get byContinuingPrefix => 'এগিয়ে গেলে আপনি সম্মত হচ্ছেন: ';

  @override
  String get terms => 'শর্তাবলি';

  @override
  String get andConjunction => ' এবং ';

  @override
  String get privacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get errorIdentityProviderUnavailable =>
      'এই সাইন ইন পদ্ধতি এখন উপলব্ধ নয়। অন্য পদ্ধতি চেষ্টা করুন।';

  @override
  String get onboardingSignIn => 'সাইন ইন';

  @override
  String get onboardingTitleOne => 'কণ্ঠ থেকে স্পষ্ট তথ্য';

  @override
  String get onboardingBodyOne =>
      'অডিও শেয়ার করুন, বাছুন বা রেকর্ড করুন। প্রতিলিপি, সারসংক্ষেপ, কাজ, তারিখ এবং উত্তরের পরামর্শ পান।';

  @override
  String get onboardingTitleTwo => 'আপনার অডিও ব্যক্তিগত থাকে';

  @override
  String get onboardingBodyTwo =>
      'অডিও নিরাপদে প্রক্রিয়াকরণের পর স্বয়ংক্রিয়ভাবে মুছে যায়। কোন লেখা রাখবেন, আপনি বাছেন।';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get recordAudio => 'অডিও রেকর্ড করুন';

  @override
  String get discardRecordingTitle => 'রেকর্ডিং মুছবেন?';

  @override
  String get discardRecordingMessage => 'বর্তমান রেকর্ডিং মুছে যাবে।';

  @override
  String get discard => 'বাদ দিন';

  @override
  String get recordingPaused => 'রেকর্ডিং স্থগিত';

  @override
  String get recording => 'রেকর্ড হচ্ছে';

  @override
  String get tapRecordReady => 'প্রস্তুত হলে রেকর্ড চাপুন';

  @override
  String get startRecording => 'রেকর্ডিং শুরু করুন';

  @override
  String get resume => 'চালিয়ে যান';

  @override
  String get pause => 'বিরতি';

  @override
  String get stop => 'থামান';

  @override
  String get cancelRecording => 'রেকর্ডিং বাতিল করুন';

  @override
  String get microphoneJustInTime =>
      'শুধু রেকর্ড চাপলেই মাইক্রোফোনের অনুমতি চাওয়া হয়।';

  @override
  String get recordingSaveFailed => 'রেকর্ডিং সংরক্ষণ করা যায়নি।';

  @override
  String get liveWaveformIdle => 'রেকর্ডিং শুরু হলে আসল তরঙ্গ দেখা যাবে।';

  @override
  String get liveWaveformStarting => 'মাইক্রোফোনের আসল মাত্রা পড়া হচ্ছে…';

  @override
  String get liveWaveformActive =>
      'এই তরঙ্গ আপনার কণ্ঠের সঙ্গে সরাসরি বদলাচ্ছে।';

  @override
  String get historyLocalOnly => 'শুধু এই ডিভাইসে সংরক্ষিত';

  @override
  String get searchBriefs => 'সারসংক্ষেপ খুঁজুন';

  @override
  String get nothingSaved => 'এখনো কিছু সংরক্ষিত নেই';

  @override
  String get nothingSavedMessage => 'কোনো ফলাফল সংরক্ষণ করলে এখানে দেখা যাবে।';

  @override
  String get noMatchingBriefs => 'মিলে যাওয়া সারসংক্ষেপ নেই';

  @override
  String get noMatchingBriefsMessage =>
      'শিরোনাম বা সারসংক্ষেপের অন্য শব্দ দিয়ে খুঁজুন।';

  @override
  String get briefDeleted => 'সারসংক্ষেপ মুছে গেছে';

  @override
  String get undo => 'ফিরিয়ে আনুন';

  @override
  String get voiceNoteReady => 'ভয়েস মেসেজ প্রস্তুত';

  @override
  String get reviewAudio => 'অডিও যাচাই করুন';

  @override
  String get createMyBrief => 'আমার সারসংক্ষেপ তৈরি করুন';

  @override
  String get secureAiProcessing =>
      'নিরাপদ AI প্রক্রিয়াকরণ · শেষে অস্থায়ী অডিও মুছে যায়';

  @override
  String get secureAiProcessingSemantics =>
      'AI প্রক্রিয়াকরণের জন্য অডিও নিরাপদে পাঠানো হয় এবং শেষে অস্থায়ী স্টোরেজ থেকে মুছে যায়।';

  @override
  String get trimAudio => 'অডিও কাটুন';

  @override
  String get trimAudioHelp =>
      'দুই প্রান্ত টেনে অংশ বাছুন। এগোনোর আগে শুনতে পারবেন।';

  @override
  String selectedAudioRange(String start, String end) {
    return 'নির্বাচিত অংশ: $start — $end';
  }

  @override
  String get useFullAudio => 'পুরো অডিও ব্যবহার করুন';

  @override
  String get createBriefFromSelection => 'এই অংশের সারসংক্ষেপ করুন';

  @override
  String get trimmingAudio => 'অডিও কাটা হচ্ছে…';

  @override
  String get audioTrimmed =>
      'অডিও কাটা হয়েছে। শুধু নির্বাচিত অংশ রাখা হয়েছে।';

  @override
  String get sharedAudioImporting => 'শেয়ার করা ভয়েস মেসেজ প্রস্তুত হচ্ছে…';

  @override
  String get customizeOutput => 'ফলাফল নিজের মতো সাজান';

  @override
  String get defaultOutput =>
      'সারসংক্ষেপ ও হুবহু প্রতিলিপি স্বয়ংক্রিয়ভাবে অন্তর্ভুক্ত থাকে';

  @override
  String get fullTranscript => 'হুবহু প্রতিলিপি';

  @override
  String get fullTranscriptDescription =>
      'রেকর্ডিংয়ে বলা সব কথা অবিকল রাখা হয়, যাতে পড়তে, খুঁজতে বা কপি করতে পারেন।';

  @override
  String get summaryAndKeyPoints => 'সারসংক্ষেপ ও মূল বিষয়';

  @override
  String get actionItemsAndDates => 'কাজ ও তারিখ';

  @override
  String get suggestedReplies => 'উত্তরের পরামর্শ';

  @override
  String get translateSummaryEnglish => 'সারসংক্ষেপ ইংরেজিতে অনুবাদ করুন';

  @override
  String get sharedAudioReadySemantics =>
      'শেয়ার করা ভয়েস মেসেজ আমদানি হয়েছে এবং প্রস্তুত।';

  @override
  String get sharedAudioReady => 'ভয়েস মেসেজ আমদানি হয়েছে। আর একবার চাপুন।';

  @override
  String get creatingBrief => 'আপনার সারসংক্ষেপ তৈরি হচ্ছে';

  @override
  String get processingFallbackError =>
      'প্রক্রিয়া সম্পন্ন হয়নি। সার্ভারের নিরাপদ কপি মুছে গেছে এবং আপনার ব্যক্তিগত স্থানীয় কপি আবার চেষ্টার জন্য প্রস্তুত।';

  @override
  String get processingKeepOpen =>
      'নিরাপদ আপলোড শেষ না হওয়া পর্যন্ত VoiceBrief খোলা রাখুন। সময় রেকর্ডিংয়ের দৈর্ঘ্য ও সংযোগের ওপর নির্ভর করে।';

  @override
  String get preparingAudio => 'অডিও প্রস্তুত হচ্ছে';

  @override
  String get uploadingSecurely => 'নিরাপদে আপলোড হচ্ছে';

  @override
  String get transcribing => 'প্রতিলিপি তৈরি হচ্ছে';

  @override
  String get creatingYourBrief => 'আপনার সারসংক্ষেপ তৈরি হচ্ছে';

  @override
  String get finalizing => 'শেষ করা হচ্ছে';

  @override
  String get brief => 'সারসংক্ষেপ';

  @override
  String get briefUnavailable => 'এই সারসংক্ষেপ আর উপলব্ধ নয়।';

  @override
  String get copyAll => 'সব কপি করুন';

  @override
  String get shareResult => 'ফলাফল শেয়ার করুন';

  @override
  String get savedLocally => 'ডিভাইসে সংরক্ষিত';

  @override
  String get notSaved => 'সংরক্ষিত নয়';

  @override
  String get saved => 'সংরক্ষিত';

  @override
  String get saveResult => 'ফলাফল সংরক্ষণ করুন';

  @override
  String get deleteResult => 'ফলাফল মুছুন';

  @override
  String get deleteBriefTitle => 'এই সারসংক্ষেপ মুছবেন?';

  @override
  String get deleteBriefMessage => 'সংরক্ষিত লেখা এই ডিভাইস থেকে মুছে যাবে।';

  @override
  String get keyPoints => 'মূল বিষয়';

  @override
  String get actionItems => 'কাজ';

  @override
  String get importantDates => 'গুরুত্বপূর্ণ তারিখ';

  @override
  String get addToCalendar => 'ক্যালেন্ডারে যোগ করুন';

  @override
  String get setReminder => 'রিমাইন্ডার দিন';

  @override
  String get reminderSet => 'VoiceBrief অ্যালার্ম সেট হয়েছে।';

  @override
  String get reminderUnavailable =>
      'রিমাইন্ডার সেট করা যায়নি। VoiceBrief বিজ্ঞপ্তি চালু করে আবার চেষ্টা করুন।';

  @override
  String get reminderMustBeFuture => 'রিমাইন্ডারের জন্য ভবিষ্যতের সময় বাছুন।';

  @override
  String get chooseAlarmTone => 'অ্যালার্মের শব্দ';

  @override
  String get chooseAlarmToneDescription =>
      'iPhone-এর মূল শব্দ ব্যবহার করুন বা নিজের শব্দ বাছুন।';

  @override
  String get previewTone => 'শব্দ শুনুন';

  @override
  String get confirmAlarm => 'এই শব্দ ব্যবহার করুন';

  @override
  String get alarmsAndReminders => 'অ্যালার্ম ও রিমাইন্ডার';

  @override
  String get voiceBriefAlarms => 'অ্যালার্ম';

  @override
  String get voiceBriefAlarmsDescription =>
      'নির্ধারিত অ্যালার্ম দেখুন বা বাতিল করুন।';

  @override
  String get noScheduledAlarms => 'আসন্ন অ্যালার্ম নেই';

  @override
  String get noScheduledAlarmsMessage =>
      'সারসংক্ষেপের কোনো তারিখ থেকে অ্যালার্ম সেট করলে এখানে দেখা যাবে।';

  @override
  String get alarmsUnavailable => 'VoiceBrief অ্যালার্ম এখন লোড করা যায়নি।';

  @override
  String get alarmScheduled => 'নির্ধারিত';

  @override
  String alarmToneLabel(Object tone) {
    return 'শব্দ: $tone';
  }

  @override
  String get alarmSoundTitle => 'অ্যালার্মের শব্দ';

  @override
  String get systemAlarmSound => 'iPhone-এর ডিফল্ট শব্দ';

  @override
  String get systemAlarmSoundDescription => 'সিস্টেমের মূল শব্দ।';

  @override
  String get customAlarmSound => 'নিজস্ব শব্দ';

  @override
  String get changeAlarmSound => 'বদলান';

  @override
  String get addCustomAlarmSound => 'নিজের শব্দ যোগ করুন';

  @override
  String get importAudioSound => 'অডিও ফাইল বাছুন';

  @override
  String get importVideoSound => 'ভিডিও থেকে শব্দ নিন';

  @override
  String get soundLimitNotice =>
      'প্রথম 29 সেকেন্ড অ্যালার্মের উপযোগী ফরম্যাটে সংরক্ষিত হয়।';

  @override
  String get preparingAlarmSound => 'শব্দ প্রস্তুত হচ্ছে…';

  @override
  String get soundImportFailed =>
      'এই ফাইল ব্যবহার করা যায়নি। অডিও আছে এমন ফাইল বাছুন।';

  @override
  String get importedSoundReady => 'শব্দ প্রস্তুত।';

  @override
  String get useThisSound => 'এই শব্দ ব্যবহার করুন';

  @override
  String get upcomingAlarms => 'আসন্ন অ্যালার্ম';

  @override
  String get loadingAlarms => 'অ্যালার্ম লোড হচ্ছে…';

  @override
  String get cancelAlarm => 'অ্যালার্ম বাতিল করুন';

  @override
  String get cancelAlarmTitle => 'এই অ্যালার্ম বাতিল করবেন?';

  @override
  String cancelAlarmMessage(Object title) {
    return 'বাতিল করার পর “$title” অ্যালার্ম আর বাজবে না।';
  }

  @override
  String get alarmCancelled => 'অ্যালার্ম বাতিল হয়েছে।';

  @override
  String get alarmCancelFailed =>
      'অ্যালার্ম বাতিল করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get refresh => 'রিফ্রেশ';

  @override
  String reminderNotificationTitle(String title) {
    return 'রিমাইন্ডার: $title';
  }

  @override
  String reminderNotificationBody(String phrase) {
    return 'VoiceBrief থেকে: “$phrase”';
  }

  @override
  String ownerLabel(String owner) {
    return 'দায়িত্বে: $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'শোনা গেছে: “$phrase”';
  }

  @override
  String get needsConfirmation => 'নিশ্চিত করা প্রয়োজন';

  @override
  String get taskDeadline => 'কাজের শেষ সময়';

  @override
  String get shortTone => 'সংক্ষিপ্ত';

  @override
  String get friendlyTone => 'বন্ধুত্বপূর্ণ';

  @override
  String get professionalTone => 'পেশাদার';

  @override
  String get shortReply => 'সংক্ষিপ্ত উত্তর';

  @override
  String get friendlyReply => 'বন্ধুত্বপূর্ণ উত্তর';

  @override
  String get professionalReply => 'পেশাদার উত্তর';

  @override
  String get replyText => 'উত্তরের লেখা';

  @override
  String get shareEditedReply => 'সম্পাদিত উত্তর শেয়ার করুন';

  @override
  String get copyEditedReply => 'সম্পাদিত উত্তর কপি করুন';

  @override
  String confirmDatePhrase(String phrase) {
    return '“$phrase” নিশ্চিত করুন';
  }

  @override
  String get confirmEventTime => 'অনুষ্ঠানের সময় নিশ্চিত করুন';

  @override
  String get openCalendarTitle => 'ক্যালেন্ডার খুলবেন?';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'VoiceBrief “$phrase” কথাটিকে $date হিসেবে বুঝেছে। সংরক্ষণের আগে ক্যালেন্ডার আপনার সম্মতি চাইবে।';
  }

  @override
  String get openCalendar => 'ক্যালেন্ডার খুলুন';

  @override
  String calendarDescription(String phrase) {
    return 'VoiceBrief থেকে নিশ্চিত করার পর তৈরি: “$phrase”';
  }

  @override
  String get calendarOpened => 'ক্যালেন্ডার সম্পাদক খোলা হয়েছে।';

  @override
  String datesFound(int count) {
    return '$countটি তারিখ পাওয়া গেছে · রিমাইন্ডার দিন বা ক্যালেন্ডারে যোগ করুন';
  }

  @override
  String datesFoundSemantics(int count) {
    return '$countটি তারিখ পাওয়া গেছে। যাচাই করে রিমাইন্ডার দিন বা সিস্টেম ক্যালেন্ডারে যোগ করুন।';
  }

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get notSignedIn => 'সাইন ইন করা নেই';

  @override
  String get verifiedAccount => 'যাচাইকৃত অ্যাকাউন্ট';

  @override
  String get emailVerificationRequired => 'ইমেইল যাচাই প্রয়োজন';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'ফ্রি প্ল্যান';

  @override
  String minutesRemaining(int count) {
    return '$count মিনিট বাকি';
  }

  @override
  String get restorePurchases => 'কেনাকাটা পুনরুদ্ধার করুন';

  @override
  String get purchasesRestored => 'কেনাকাটা পুনরুদ্ধার হয়েছে।';

  @override
  String get noPurchasesRestored => 'কোনো কেনাকাটা পুনরুদ্ধার হয়নি।';

  @override
  String get manageSubscription => 'সাবস্ক্রিপশন পরিচালনা করুন';

  @override
  String get appearance => 'চেহারা';

  @override
  String get systemTheme => 'সিস্টেম';

  @override
  String get lightTheme => 'হালকা';

  @override
  String get darkTheme => 'গাঢ়';

  @override
  String get privacyAndData => 'গোপনীয়তা ও ডেটা';

  @override
  String get audioHandlingTitle => 'অডিও অস্থায়ী; লেখা সংরক্ষণ ঐচ্ছিক';

  @override
  String get audioHandlingDescription =>
      'অডিও সাময়িকভাবে প্রতিলিপি তৈরিতে ব্যবহৃত হয়, তারপর নিজে থেকে মুছে যায়। শুধু আপনার সংরক্ষণ করা সারসংক্ষেপ ও প্রতিলিপি ইতিহাসে থাকে।';

  @override
  String get exportSavedText => 'সংরক্ষিত লেখা শেয়ার করুন';

  @override
  String get exportSubject => 'VoiceBrief রপ্তানি';

  @override
  String get exportSavedTextDescription =>
      'সারসংক্ষেপ, মূল বিষয়, কাজ, তারিখ, উত্তর ও প্রতিলিপি দিয়ে TXT ফাইল বানিয়ে শেয়ার মেনু খোলে। অডিও কখনো থাকে না।';

  @override
  String get exportSavedTextFailed =>
      'শেয়ারের জন্য টেক্সট ফাইল তৈরি করা যায়নি।';

  @override
  String get noSavedTextOnDevice => 'এই ডিভাইসে কোনো লেখা সংরক্ষিত নেই।';

  @override
  String get clearLocalHistory => 'সংরক্ষিত লেখা মুছুন';

  @override
  String get clearSavedTextDescription =>
      'শুধু এই ডিভাইসের সারসংক্ষেপ ও প্রতিলিপি মুছে দেয়। এখানে অডিও রেকর্ডিং রাখা হয় না।';

  @override
  String get clearHistoryTitle => 'সংরক্ষিত লেখা মুছবেন?';

  @override
  String get clearHistoryMessage =>
      'এই ডিভাইসের সব সারসংক্ষেপ ও প্রতিলিপি স্থায়ীভাবে মুছে যাবে। অডিও ফাইল প্রক্রিয়াকরণের পর আগেই মুছে যায়।';

  @override
  String get clearHistory => 'লেখা মুছুন';

  @override
  String get savedTextCleared => 'সংরক্ষিত লেখা মুছে গেছে।';

  @override
  String get clearSavedTextFailed => 'লেখা মোছা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get termsOfService => 'পরিষেবার শর্তাবলি';

  @override
  String get support => 'সহায়তা';

  @override
  String get contactSupport => 'সহায়তায় যোগাযোগ করুন';

  @override
  String get appVersion => 'অ্যাপ সংস্করণ';

  @override
  String get deleteAccountTitle => 'অ্যাকাউন্ট মুছবেন?';

  @override
  String get deleteAccountMessage =>
      'এতে সার্ভারের অ্যাকাউন্ট ও স্থানীয় ইতিহাস মুছে যাবে। স্টোর অ্যাকাউন্টে বাতিল না করা পর্যন্ত সাবস্ক্রিপশন চালু থাকবে।';

  @override
  String get deleteAccount => 'অ্যাকাউন্ট মুছুন';

  @override
  String get active => 'সক্রিয়';

  @override
  String get proHeadline => 'প্রতিটি ভয়েস মেসেজ থেকে কার্যকর সারসংক্ষেপ পান';

  @override
  String get accurateTranscripts => 'নির্ভুল প্রতিলিপি';

  @override
  String get instantSummaries => 'তাৎক্ষণিক সারসংক্ষেপ';

  @override
  String get threeReplyTones => 'পাঠানোর জন্য প্রস্তুত তিন ধরনের উত্তর';

  @override
  String get loadingStorePrices => 'স্টোরের দাম লোড হচ্ছে…';

  @override
  String get subscriptionOptionsUnavailable =>
      'সাবস্ক্রিপশন উপলব্ধ নয়। প্রোডাকশনে বিকল্প দাম দেখানো হয় না।';

  @override
  String get yearly => 'বার্ষিক';

  @override
  String get monthly => 'মাসিক';

  @override
  String get bestValue => 'সেরা সাশ্রয়';

  @override
  String get proActive => 'Pro সক্রিয়';

  @override
  String get subscriptionRenewalNotice =>
      'চলতি মেয়াদ শেষ হওয়ার অন্তত 24 ঘণ্টা আগে বাতিল না করলে সাবস্ক্রিপশন নিজে থেকে নবায়ন হয়। স্টোর অ্যাকাউন্টে যেকোনো সময় পরিচালনা বা বাতিল করুন।';

  @override
  String get privacy => 'গোপনীয়তা';

  @override
  String get proActivatedToast => 'VoiceBrief Pro সক্রিয়।';

  @override
  String get noActivePurchases => 'সক্রিয় কেনাকাটা পাওয়া যায়নি।';

  @override
  String get errorNoInternet =>
      'আপনি সম্ভবত অফলাইন। সংযোগ যাচাই করে আবার চেষ্টা করুন।';

  @override
  String get errorAuthentication =>
      'সাইন ইন করা যায়নি। তথ্য যাচাই করে আবার চেষ্টা করুন।';

  @override
  String get errorProviderCanceled => 'সাইন ইন বাতিল হয়েছে।';

  @override
  String get errorEmailVerification =>
      'ইমেইলের যাচাইকরণ লিংক খুলে VoiceBrief-এ ফিরে আসুন।';

  @override
  String get errorUnsupportedAudio => 'এই অডিও ফরম্যাট সমর্থিত নয়।';

  @override
  String get errorFileTooLarge => 'অডিও ফাইল বর্তমান আপলোড সীমার চেয়ে বড়।';

  @override
  String get errorUnreadableAudio =>
      'এই অডিও পড়া যায়নি। অন্য ফাইল চেষ্টা করুন।';

  @override
  String get errorAudioEditing =>
      'এই ডিভাইসে অডিও কাটা যায়নি। মূল ফাইল অপরিবর্তিত আছে।';

  @override
  String get errorMicrophoneDenied =>
      'শুধু রেকর্ড করতে চাইলে মাইক্রোফোনের অনুমতি লাগে।';

  @override
  String get errorUploadInterrupted =>
      'নিরাপদ আপলোড বাধাগ্রস্ত হয়েছে। নিরাপদে আবার চেষ্টা করতে পারেন।';

  @override
  String get errorProcessingTimeout =>
      'প্রক্রিয়াকরণে বেশি সময় লেগেছে। আপনার মিনিট কাটা হয়নি।';

  @override
  String get errorTranscription =>
      'অডিওর প্রতিলিপি তৈরি করা যায়নি। একটু পরে আবার চেষ্টা করুন।';

  @override
  String get errorInvalidResponse => 'ফলাফল অসম্পূর্ণ ছিল এবং সংরক্ষিত হয়নি।';

  @override
  String get errorQuotaExhausted => 'এই অডিওর জন্য পর্যাপ্ত মিনিট নেই।';

  @override
  String get errorSubscriptionUnavailable => 'সাবস্ক্রিপশন এখন উপলব্ধ নয়।';

  @override
  String get errorSubscriptionSyncPending =>
      'কেনাকাটা নিশ্চিত হয়েছে, Pro এখনো সিঙ্ক হচ্ছে। VoiceBrief খোলা রাখুন এবং একটু পরে আবার চেষ্টা করুন।';

  @override
  String get errorPurchaseCanceled => 'কেনাকাটা বাতিল হয়েছে।';

  @override
  String get errorPurchaseFailed =>
      'কেনাকাটা সম্পন্ন হয়নি। VoiceBrief কোনো টাকা কাটেনি।';

  @override
  String get errorRestoreFailed =>
      'কেনাকাটা পুনরুদ্ধার করা যায়নি। পরে আবার চেষ্টা করুন।';

  @override
  String get errorServiceUnavailable =>
      'VoiceBrief সাময়িকভাবে উপলব্ধ নয়। একটু পরে আবার চেষ্টা করুন।';

  @override
  String get errorShareHandoff => 'শেয়ার করা অডিও নিরাপদে আমদানি করা যায়নি।';

  @override
  String get errorConfiguration => 'এই সুবিধার প্রোডাকশন কনফিগারেশন এখনো বাকি।';

  @override
  String get errorUnknown => 'কিছু ভুল হয়েছে। আবার চেষ্টা করুন।';
}
