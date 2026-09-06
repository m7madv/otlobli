// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get appLanguage => 'ایپ کی زبان';

  @override
  String get followSystemLanguage => 'آلے کی زبان استعمال کریں';

  @override
  String get home => 'ہوم';

  @override
  String get history => 'ہسٹری';

  @override
  String get settings => 'ترتیبات';

  @override
  String get cancel => 'منسوخ';

  @override
  String get tryAgain => 'دوبارہ کوشش کریں';

  @override
  String get close => 'بند کریں';

  @override
  String get continueLabel => 'جاری رکھیں';

  @override
  String get signIn => 'سائن ان';

  @override
  String get signOut => 'سائن آؤٹ';

  @override
  String get delete => 'حذف کریں';

  @override
  String get copy => 'کاپی کریں';

  @override
  String get edit => 'ترمیم کریں';

  @override
  String get copied => 'کاپی ہو گیا';

  @override
  String get complete => 'مکمل';

  @override
  String get unavailable => 'دستیاب نہیں';

  @override
  String get replaceAudio => 'آڈیو بدلیں';

  @override
  String get removeAudio => 'آڈیو ہٹائیں';

  @override
  String get playAudio => 'آڈیو چلائیں';

  @override
  String get pauseAudio => 'آڈیو روکیں';

  @override
  String get audioWaveform => 'آڈیو کی لہر';

  @override
  String get audioWaveformLoading => 'آڈیو کی اصل لہر بن رہی ہے…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'آڈیو چل رہا ہے: $duration میں سے $elapsed';
  }

  @override
  String copySection(String title) {
    return '$title کاپی کریں';
  }

  @override
  String get screenUnavailable => 'یہ اسکرین دستیاب نہیں۔';

  @override
  String get goPro => 'Pro حاصل کریں';

  @override
  String get homeHeadline => 'صوتی پیغامات سے واضح اگلے قدم حاصل کریں';

  @override
  String get homeSupporting =>
      'WhatsApp سے شیئر کریں، آڈیو چنیں یا یہاں ریکارڈ کریں۔';

  @override
  String get shareFromWhatsApp => 'WhatsApp سے';

  @override
  String get shareFromWhatsAppSteps =>
      'صوتی پیغام دبا کر رکھیں، شیئر پر ٹیپ کریں، پھر VoiceBrief چنیں';

  @override
  String get chooseVoiceNote => 'صوتی پیغام چنیں';

  @override
  String get recordInstead => 'ابھی ریکارڈ کریں';

  @override
  String get recentBriefs => 'حالیہ خلاصے';

  @override
  String get viewAll => 'سب دیکھیں';

  @override
  String get noBriefsYet => 'ابھی کوئی خلاصہ نہیں';

  @override
  String get noBriefsMessage =>
      'پہلا خلاصہ بنانے کے لیے آڈیو چنیں یا ریکارڈ کریں۔';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return '$total مفت منٹوں میں سے $remaining باقی';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return '$total Pro منٹوں میں سے $remaining باقی';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return '$total منٹوں میں سے $remaining باقی';
  }

  @override
  String get authHeadline => 'ہر صوتی پیغام کو مفید بنائیں';

  @override
  String get authSupporting =>
      'اپنے منٹ محفوظ رکھنے اور محفوظ کردہ خلاصے اپنے اکاؤنٹ تک نجی رکھنے کے لیے سائن ان کریں۔';

  @override
  String get demoServicesActive =>
      'نمائشی خدمات فعال ہیں۔ کوئی بیرونی اکاؤنٹ یا معاوضے والی خدمت استعمال نہیں ہوتی۔';

  @override
  String get providerSignInTitle => 'تیز اور محفوظ سائن ان';

  @override
  String get providerSignInDescription =>
      'Apple یا Google چنیں۔ VoiceBrief آپ کے اکاؤنٹ کا پاس ورڈ کبھی نہیں دیکھتا۔';

  @override
  String get continueWithApple => 'Apple کے ساتھ جاری رکھیں';

  @override
  String get continueWithGoogle => 'Google کے ساتھ جاری رکھیں';

  @override
  String get byContinuingPrefix => 'جاری رکھ کر آپ اتفاق کرتے ہیں: ';

  @override
  String get terms => 'شرائط';

  @override
  String get andConjunction => ' اور ';

  @override
  String get privacyPolicy => 'رازداری کی پالیسی';

  @override
  String get errorIdentityProviderUnavailable =>
      'سائن ان کا یہ طریقہ دستیاب نہیں۔ دوسرا طریقہ آزمائیں۔';

  @override
  String get onboardingSignIn => 'سائن ان';

  @override
  String get onboardingTitleOne => 'آواز سے واضح معلومات';

  @override
  String get onboardingBodyOne =>
      'آڈیو شیئر کریں، چنیں یا ریکارڈ کریں۔ لفظی متن، خلاصہ، کام، تاریخیں اور مجوزہ جوابات حاصل کریں۔';

  @override
  String get onboardingTitleTwo => 'آپ کا آڈیو نجی رہتا ہے';

  @override
  String get onboardingBodyTwo =>
      'آڈیو محفوظ طریقے سے پراسیس ہو کر خودکار طور پر حذف ہو جاتا ہے۔ آپ طے کرتے ہیں کہ کون سا متن محفوظ کرنا ہے۔';

  @override
  String get getStarted => 'شروع کریں';

  @override
  String get recordAudio => 'آڈیو ریکارڈ کریں';

  @override
  String get discardRecordingTitle => 'ریکارڈنگ حذف کریں؟';

  @override
  String get discardRecordingMessage => 'موجودہ ریکارڈنگ حذف ہو جائے گی۔';

  @override
  String get discard => 'حذف کر دیں';

  @override
  String get recordingPaused => 'ریکارڈنگ رکی ہوئی ہے';

  @override
  String get recording => 'ریکارڈنگ جاری ہے';

  @override
  String get tapRecordReady => 'تیار ہوں تو ریکارڈ پر ٹیپ کریں';

  @override
  String get startRecording => 'ریکارڈنگ شروع کریں';

  @override
  String get resume => 'جاری رکھیں';

  @override
  String get pause => 'وقفہ';

  @override
  String get stop => 'روکیں';

  @override
  String get cancelRecording => 'ریکارڈنگ منسوخ کریں';

  @override
  String get microphoneJustInTime =>
      'مائیکروفون کی اجازت صرف ریکارڈ پر ٹیپ کرنے کے بعد مانگی جاتی ہے۔';

  @override
  String get recordingSaveFailed => 'ریکارڈنگ محفوظ نہیں ہو سکی۔';

  @override
  String get liveWaveformIdle => 'ریکارڈنگ شروع ہونے پر اصل لہر نظر آئے گی۔';

  @override
  String get liveWaveformStarting => 'مائیکروفون کی اصل سطح پڑھی جا رہی ہے…';

  @override
  String get liveWaveformActive => 'یہ لہر آپ کی آواز کے ساتھ حرکت کر رہی ہے۔';

  @override
  String get historyLocalOnly => 'صرف اس آلے پر محفوظ ہے';

  @override
  String get searchBriefs => 'خلاصے تلاش کریں';

  @override
  String get nothingSaved => 'ابھی کچھ محفوظ نہیں';

  @override
  String get nothingSavedMessage => 'کوئی نتیجہ محفوظ کریں تو یہاں نظر آئے گا۔';

  @override
  String get noMatchingBriefs => 'کوئی مماثل خلاصہ نہیں';

  @override
  String get noMatchingBriefsMessage =>
      'عنوان یا خلاصے کا کوئی دوسرا لفظ تلاش کریں۔';

  @override
  String get briefDeleted => 'خلاصہ حذف ہو گیا';

  @override
  String get undo => 'واپس لائیں';

  @override
  String get voiceNoteReady => 'صوتی پیغام تیار ہے';

  @override
  String get reviewAudio => 'آڈیو کا جائزہ لیں';

  @override
  String get createMyBrief => 'میرا خلاصہ بنائیں';

  @override
  String get secureAiProcessing =>
      'محفوظ AI پراسیسنگ · آخر میں عارضی آڈیو حذف ہو جاتا ہے';

  @override
  String get secureAiProcessingSemantics =>
      'آڈیو AI پراسیسنگ کے لیے محفوظ طریقے سے بھیجا جاتا ہے اور بعد میں عارضی اسٹوریج سے حذف کر دیا جاتا ہے۔';

  @override
  String get trimAudio => 'آڈیو تراشیں';

  @override
  String get trimAudioHelp =>
      'دونوں کنارے کھینچ کر حصہ چنیں۔ آگے بڑھنے سے پہلے اسے سن سکتے ہیں۔';

  @override
  String selectedAudioRange(String start, String end) {
    return 'منتخب حصہ: $start — $end';
  }

  @override
  String get useFullAudio => 'پورا آڈیو استعمال کریں';

  @override
  String get createBriefFromSelection => 'اس حصے کا خلاصہ بنائیں';

  @override
  String get trimmingAudio => 'آڈیو تراشا جا رہا ہے…';

  @override
  String get audioTrimmed => 'آڈیو تراش دیا گیا۔ صرف منتخب حصہ رکھا گیا ہے۔';

  @override
  String get sharedAudioImporting => 'شیئر کردہ صوتی پیغام تیار ہو رہا ہے…';

  @override
  String get customizeOutput => 'نتیجہ اپنی پسند کے مطابق بنائیں';

  @override
  String get defaultOutput =>
      'خلاصہ اور لفظ بہ لفظ متن خودکار طور پر شامل ہوتے ہیں';

  @override
  String get fullTranscript => 'لفظ بہ لفظ متن';

  @override
  String get fullTranscriptDescription =>
      'ریکارڈنگ میں کہی گئی ہر بات جوں کی توں، تاکہ آپ پڑھ، تلاش یا کاپی کر سکیں۔';

  @override
  String get summaryAndKeyPoints => 'خلاصہ اور اہم نکات';

  @override
  String get actionItemsAndDates => 'کام اور تاریخیں';

  @override
  String get suggestedReplies => 'مجوزہ جوابات';

  @override
  String get translateSummaryEnglish => 'خلاصے کا انگریزی میں ترجمہ کریں';

  @override
  String get sharedAudioReadySemantics =>
      'شیئر کردہ صوتی پیغام درآمد ہو کر تیار ہے۔';

  @override
  String get sharedAudioReady =>
      'صوتی پیغام درآمد ہو گیا۔ صرف ایک ٹیپ باقی ہے۔';

  @override
  String get creatingBrief => 'آپ کا خلاصہ بن رہا ہے';

  @override
  String get processingFallbackError =>
      'پراسیسنگ مکمل نہیں ہوئی۔ سرور کی محفوظ نقل حذف ہو گئی ہے اور آپ کی نجی مقامی نقل دوبارہ کوشش کے لیے تیار ہے۔';

  @override
  String get processingKeepOpen =>
      'محفوظ اپ لوڈ مکمل ہونے تک VoiceBrief کھلا رکھیں۔ وقت ریکارڈنگ کی لمبائی اور کنکشن پر منحصر ہے۔';

  @override
  String get preparingAudio => 'آڈیو تیار ہو رہا ہے';

  @override
  String get uploadingSecurely => 'محفوظ اپ لوڈ جاری ہے';

  @override
  String get transcribing => 'لفظی متن بن رہا ہے';

  @override
  String get creatingYourBrief => 'آپ کا خلاصہ بن رہا ہے';

  @override
  String get finalizing => 'آخری مرحلہ';

  @override
  String get brief => 'خلاصہ';

  @override
  String get briefUnavailable => 'یہ خلاصہ اب دستیاب نہیں۔';

  @override
  String get copyAll => 'سب کاپی کریں';

  @override
  String get shareResult => 'نتیجہ شیئر کریں';

  @override
  String get savedLocally => 'آلے پر محفوظ';

  @override
  String get notSaved => 'محفوظ نہیں';

  @override
  String get saved => 'محفوظ';

  @override
  String get saveResult => 'نتیجہ محفوظ کریں';

  @override
  String get deleteResult => 'نتیجہ حذف کریں';

  @override
  String get deleteBriefTitle => 'یہ خلاصہ حذف کریں؟';

  @override
  String get deleteBriefMessage => 'محفوظ کردہ متن اس آلے سے حذف ہو جائے گا۔';

  @override
  String get keyPoints => 'اہم نکات';

  @override
  String get actionItems => 'کام';

  @override
  String get importantDates => 'اہم تاریخیں';

  @override
  String get addToCalendar => 'کیلنڈر میں شامل کریں';

  @override
  String get setReminder => 'یاد دہانی لگائیں';

  @override
  String get reminderSet => 'VoiceBrief کا الارم لگا دیا گیا۔';

  @override
  String get reminderUnavailable =>
      'یاد دہانی نہیں لگ سکی۔ VoiceBrief کی اطلاعات فعال کر کے دوبارہ کوشش کریں۔';

  @override
  String get reminderMustBeFuture => 'یاد دہانی کے لیے مستقبل کا وقت چنیں۔';

  @override
  String get chooseAlarmTone => 'الارم کی آواز';

  @override
  String get chooseAlarmToneDescription =>
      'iPhone کی اصل آواز استعمال کریں یا اپنی آواز چنیں۔';

  @override
  String get previewTone => 'آواز سنیں';

  @override
  String get confirmAlarm => 'یہ آواز استعمال کریں';

  @override
  String get alarmsAndReminders => 'الارم اور یاد دہانیاں';

  @override
  String get voiceBriefAlarms => 'الارم';

  @override
  String get voiceBriefAlarmsDescription =>
      'اپنے مقرر کردہ الارم دیکھیں یا منسوخ کریں۔';

  @override
  String get noScheduledAlarms => 'کوئی آنے والا الارم نہیں';

  @override
  String get noScheduledAlarmsMessage =>
      'خلاصے کی کسی تاریخ سے الارم لگائیں تو یہاں نظر آئے گا۔';

  @override
  String get alarmsUnavailable => 'VoiceBrief کے الارم ابھی لوڈ نہیں ہو سکے۔';

  @override
  String get alarmScheduled => 'مقرر ہے';

  @override
  String alarmToneLabel(Object tone) {
    return 'آواز: $tone';
  }

  @override
  String get alarmSoundTitle => 'الارم کی آواز';

  @override
  String get systemAlarmSound => 'iPhone کی طے شدہ آواز';

  @override
  String get systemAlarmSoundDescription => 'سسٹم کی اصل آواز۔';

  @override
  String get customAlarmSound => 'اپنی آواز';

  @override
  String get changeAlarmSound => 'بدلیں';

  @override
  String get addCustomAlarmSound => 'اپنی آواز شامل کریں';

  @override
  String get importAudioSound => 'آڈیو فائل چنیں';

  @override
  String get importVideoSound => 'ویڈیو سے آواز نکالیں';

  @override
  String get soundLimitNotice =>
      'پہلے 29 سیکنڈ الارم کے موزوں فارمیٹ میں محفوظ ہوتے ہیں۔';

  @override
  String get preparingAlarmSound => 'آواز تیار ہو رہی ہے…';

  @override
  String get soundImportFailed =>
      'یہ فائل استعمال نہیں ہو سکی۔ آڈیو والی فائل چنیں۔';

  @override
  String get importedSoundReady => 'آواز تیار ہے۔';

  @override
  String get useThisSound => 'یہ آواز استعمال کریں';

  @override
  String get upcomingAlarms => 'آنے والے الارم';

  @override
  String get loadingAlarms => 'الارم لوڈ ہو رہے ہیں…';

  @override
  String get cancelAlarm => 'الارم منسوخ کریں';

  @override
  String get cancelAlarmTitle => 'یہ الارم منسوخ کریں؟';

  @override
  String cancelAlarmMessage(Object title) {
    return 'منسوخ ہونے کے بعد “$title” الارم نہیں بجے گا۔';
  }

  @override
  String get alarmCancelled => 'الارم منسوخ ہو گیا۔';

  @override
  String get alarmCancelFailed => 'الارم منسوخ نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get refresh => 'تازہ کریں';

  @override
  String reminderNotificationTitle(String title) {
    return 'یاد دہانی: $title';
  }

  @override
  String reminderNotificationBody(String phrase) {
    return 'VoiceBrief سے: “$phrase”';
  }

  @override
  String ownerLabel(String owner) {
    return 'ذمہ دار: $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'سنا گیا: “$phrase”';
  }

  @override
  String get needsConfirmation => 'تصدیق درکار ہے';

  @override
  String get taskDeadline => 'کام کی آخری تاریخ';

  @override
  String get shortTone => 'مختصر';

  @override
  String get friendlyTone => 'دوستانہ';

  @override
  String get professionalTone => 'پیشہ ورانہ';

  @override
  String get shortReply => 'مختصر جواب';

  @override
  String get friendlyReply => 'دوستانہ جواب';

  @override
  String get professionalReply => 'پیشہ ورانہ جواب';

  @override
  String get replyText => 'جواب کا متن';

  @override
  String get shareEditedReply => 'ترمیم شدہ جواب شیئر کریں';

  @override
  String get copyEditedReply => 'ترمیم شدہ جواب کاپی کریں';

  @override
  String confirmDatePhrase(String phrase) {
    return '“$phrase” کی تصدیق کریں';
  }

  @override
  String get confirmEventTime => 'تقریب کے وقت کی تصدیق کریں';

  @override
  String get openCalendarTitle => 'کیلنڈر کھولیں؟';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'VoiceBrief نے “$phrase” کو $date سمجھا ہے۔ محفوظ کرنے سے پہلے کیلنڈر آپ سے تصدیق مانگے گا۔';
  }

  @override
  String get openCalendar => 'کیلنڈر کھولیں';

  @override
  String calendarDescription(String phrase) {
    return 'VoiceBrief سے تصدیق کے بعد بنایا گیا: “$phrase”';
  }

  @override
  String get calendarOpened => 'کیلنڈر کا ایڈیٹر کھل گیا۔';

  @override
  String datesFound(int count) {
    return '$count تاریخیں ملیں · یاد دہانی لگائیں یا کیلنڈر میں شامل کریں';
  }

  @override
  String datesFoundSemantics(int count) {
    return '$count تاریخیں ملی ہیں۔ جائزہ لیں، پھر یاد دہانی لگائیں یا سسٹم کیلنڈر میں شامل کریں۔';
  }

  @override
  String get account => 'اکاؤنٹ';

  @override
  String get notSignedIn => 'سائن ان نہیں';

  @override
  String get verifiedAccount => 'تصدیق شدہ اکاؤنٹ';

  @override
  String get emailVerificationRequired => 'ای میل کی تصدیق درکار ہے';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'مفت پلان';

  @override
  String minutesRemaining(int count) {
    return '$count منٹ باقی';
  }

  @override
  String get restorePurchases => 'خریداریاں بحال کریں';

  @override
  String get purchasesRestored => 'خریداریاں بحال ہو گئیں۔';

  @override
  String get noPurchasesRestored => 'کوئی خریداری بحال نہیں ہوئی۔';

  @override
  String get manageSubscription => 'سبسکرپشن کا انتظام';

  @override
  String get appearance => 'ظاہری انداز';

  @override
  String get systemTheme => 'سسٹم';

  @override
  String get lightTheme => 'روشن';

  @override
  String get darkTheme => 'گہرا';

  @override
  String get privacyAndData => 'رازداری اور ڈیٹا';

  @override
  String get audioHandlingTitle => 'آڈیو عارضی ہے؛ متن محفوظ کرنا اختیاری';

  @override
  String get audioHandlingDescription =>
      'آڈیو لفظی متن بنانے کے لیے عارضی طور پر استعمال ہو کر خودکار طور پر حذف ہو جاتا ہے۔ صرف آپ کے محفوظ کردہ خلاصے اور متن ہسٹری میں رہتے ہیں۔';

  @override
  String get exportSavedText => 'محفوظ کردہ متن شیئر کریں';

  @override
  String get exportSubject => 'VoiceBrief برآمد';

  @override
  String get exportSavedTextDescription =>
      'خلاصوں، اہم نکات، کاموں، تاریخوں، جوابات اور لفظی متن کی TXT فائل بنا کر شیئر مینو کھولتا ہے۔ اس میں کبھی آڈیو شامل نہیں ہوتا۔';

  @override
  String get exportSavedTextFailed =>
      'شیئر کرنے کے لیے متن کی فائل نہیں بن سکی۔';

  @override
  String get noSavedTextOnDevice => 'اس آلے پر کوئی متن محفوظ نہیں۔';

  @override
  String get clearLocalHistory => 'محفوظ کردہ متن حذف کریں';

  @override
  String get clearSavedTextDescription =>
      'صرف اس آلے کے خلاصے اور لفظی متن حذف کرتا ہے۔ یہاں آڈیو ریکارڈنگ محفوظ نہیں ہوتی۔';

  @override
  String get clearHistoryTitle => 'محفوظ کردہ متن حذف کریں؟';

  @override
  String get clearHistoryMessage =>
      'اس آلے کے تمام خلاصے اور لفظی متن مستقل حذف ہو جائیں گے۔ آڈیو فائلیں پراسیسنگ کے بعد پہلے ہی حذف ہو جاتی ہیں۔';

  @override
  String get clearHistory => 'متن حذف کریں';

  @override
  String get savedTextCleared => 'محفوظ کردہ متن حذف ہو گیا۔';

  @override
  String get clearSavedTextFailed => 'متن حذف نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get termsOfService => 'استعمال کی شرائط';

  @override
  String get support => 'معاونت';

  @override
  String get contactSupport => 'معاونت سے رابطہ';

  @override
  String get appVersion => 'ایپ کا ورژن';

  @override
  String get deleteAccountTitle => 'اکاؤنٹ حذف کریں؟';

  @override
  String get deleteAccountMessage =>
      'اس سے سرور پر آپ کا اکاؤنٹ اور مقامی ہسٹری حذف ہو جائے گی۔ اسٹور کی سبسکرپشن تب تک جاری رہے گی جب تک آپ اسے اسٹور اکاؤنٹ میں منسوخ نہیں کرتے۔';

  @override
  String get deleteAccount => 'اکاؤنٹ حذف کریں';

  @override
  String get active => 'فعال';

  @override
  String get proHeadline => 'ہر صوتی پیغام سے قابلِ عمل خلاصہ حاصل کریں';

  @override
  String get accurateTranscripts => 'درست لفظی متن';

  @override
  String get instantSummaries => 'فوری خلاصے';

  @override
  String get threeReplyTones => 'بھیجنے کے لیے تیار تین انداز کے جواب';

  @override
  String get loadingStorePrices => 'اسٹور کی قیمتیں لوڈ ہو رہی ہیں…';

  @override
  String get subscriptionOptionsUnavailable =>
      'سبسکرپشن دستیاب نہیں۔ پروڈکشن میں متبادل قیمت نہیں دکھائی جاتی۔';

  @override
  String get yearly => 'سالانہ';

  @override
  String get monthly => 'ماہانہ';

  @override
  String get bestValue => 'بہترین قدر';

  @override
  String get proActive => 'Pro فعال ہے';

  @override
  String get subscriptionRenewalNotice =>
      'موجودہ مدت ختم ہونے سے کم از کم 24 گھنٹے پہلے منسوخ نہ کرنے پر سبسکرپشن خودکار طور پر تجدید ہوتی ہے۔ اسٹور اکاؤنٹ میں کسی بھی وقت انتظام یا منسوخی کریں۔';

  @override
  String get privacy => 'رازداری';

  @override
  String get proActivatedToast => 'VoiceBrief Pro فعال ہے۔';

  @override
  String get noActivePurchases => 'کوئی فعال خریداری نہیں ملی۔';

  @override
  String get errorNoInternet =>
      'آپ آف لائن لگ رہے ہیں۔ کنکشن چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String get errorAuthentication =>
      'سائن ان نہیں ہو سکا۔ معلومات چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String get errorProviderCanceled => 'سائن ان منسوخ ہو گیا۔';

  @override
  String get errorEmailVerification =>
      'ای میل میں تصدیقی لنک کھولیں، پھر VoiceBrief پر واپس آئیں۔';

  @override
  String get errorUnsupportedAudio => 'یہ آڈیو فارمیٹ معاون نہیں۔';

  @override
  String get errorFileTooLarge => 'آڈیو فائل موجودہ اپ لوڈ حد سے بڑی ہے۔';

  @override
  String get errorUnreadableAudio =>
      'یہ آڈیو پڑھا نہیں جا سکا۔ دوسری فائل آزمائیں۔';

  @override
  String get errorAudioEditing =>
      'اس آلے پر آڈیو تراشا نہیں جا سکا۔ اصل فائل تبدیل نہیں ہوئی۔';

  @override
  String get errorMicrophoneDenied =>
      'مائیکروفون کی اجازت صرف ریکارڈ کرنے کے لیے درکار ہے۔';

  @override
  String get errorUploadInterrupted =>
      'محفوظ اپ لوڈ رک گیا۔ آپ محفوظ طریقے سے دوبارہ کوشش کر سکتے ہیں۔';

  @override
  String get errorProcessingTimeout =>
      'پراسیسنگ میں بہت وقت لگا۔ آپ کے منٹ نہیں کاٹے گئے۔';

  @override
  String get errorTranscription =>
      'آڈیو کا لفظی متن نہیں بن سکا۔ کچھ دیر بعد دوبارہ کوشش کریں۔';

  @override
  String get errorInvalidResponse => 'نتیجہ نامکمل تھا اور محفوظ نہیں ہوا۔';

  @override
  String get errorQuotaExhausted => 'اس آڈیو کے لیے آپ کے منٹ کافی نہیں۔';

  @override
  String get errorSubscriptionUnavailable => 'سبسکرپشن ابھی دستیاب نہیں۔';

  @override
  String get errorSubscriptionSyncPending =>
      'خریداری کی تصدیق ہو گئی ہے اور Pro ابھی ہم وقت ہو رہا ہے۔ VoiceBrief کھلا رکھیں اور کچھ دیر بعد کوشش کریں۔';

  @override
  String get errorPurchaseCanceled => 'خریداری منسوخ ہو گئی۔';

  @override
  String get errorPurchaseFailed =>
      'خریداری مکمل نہیں ہوئی۔ VoiceBrief نے کوئی رقم نہیں کاٹی۔';

  @override
  String get errorRestoreFailed =>
      'خریداریاں بحال نہیں ہو سکیں۔ بعد میں کوشش کریں۔';

  @override
  String get errorServiceUnavailable =>
      'VoiceBrief عارضی طور پر دستیاب نہیں۔ کچھ دیر بعد کوشش کریں۔';

  @override
  String get errorShareHandoff =>
      'شیئر کردہ آڈیو محفوظ طریقے سے درآمد نہیں ہو سکا۔';

  @override
  String get errorConfiguration => 'اس سہولت کی پروڈکشن ترتیب ابھی باقی ہے۔';

  @override
  String get errorUnknown => 'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔';
}
