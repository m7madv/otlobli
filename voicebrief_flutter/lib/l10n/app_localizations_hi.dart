// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get appLanguage => 'ऐप की भाषा';

  @override
  String get followSystemLanguage => 'डिवाइस की भाषा इस्तेमाल करें';

  @override
  String get home => 'होम';

  @override
  String get history => 'इतिहास';

  @override
  String get settings => 'सेटिंग';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get close => 'बंद करें';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get signIn => 'साइन इन';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get delete => 'हटाएँ';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get edit => 'बदलें';

  @override
  String get copied => 'कॉपी हो गया';

  @override
  String get complete => 'पूरा हुआ';

  @override
  String get unavailable => 'उपलब्ध नहीं';

  @override
  String get replaceAudio => 'ऑडियो बदलें';

  @override
  String get removeAudio => 'ऑडियो हटाएँ';

  @override
  String get playAudio => 'ऑडियो चलाएँ';

  @override
  String get pauseAudio => 'ऑडियो रोकें';

  @override
  String get audioWaveform => 'ऑडियो तरंग';

  @override
  String get audioWaveformLoading => 'असली ऑडियो तरंग बन रही है…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'ऑडियो चल रहा है: $duration में से $elapsed';
  }

  @override
  String copySection(String title) {
    return '$title कॉपी करें';
  }

  @override
  String get screenUnavailable => 'यह स्क्रीन उपलब्ध नहीं है।';

  @override
  String get goPro => 'Pro लें';

  @override
  String get homeHeadline => 'वॉइस मैसेज से पाएँ स्पष्ट अगले कदम';

  @override
  String get homeSupporting =>
      'WhatsApp से साझा करें, ऑडियो चुनें या यहाँ रिकॉर्ड करें।';

  @override
  String get shareFromWhatsApp => 'WhatsApp से';

  @override
  String get shareFromWhatsAppSteps =>
      'वॉइस मैसेज दबाकर रखें, साझा करें पर टैप करें, फिर VoiceBrief चुनें';

  @override
  String get chooseVoiceNote => 'वॉइस मैसेज चुनें';

  @override
  String get recordInstead => 'अभी रिकॉर्ड करें';

  @override
  String get recentBriefs => 'हाल के सारांश';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get noBriefsYet => 'अभी कोई सारांश नहीं';

  @override
  String get noBriefsMessage =>
      'पहला सारांश बनाने के लिए ऑडियो चुनें या रिकॉर्ड करें।';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return '$total मुफ़्त मिनटों में से $remaining बाकी';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return '$total Pro मिनटों में से $remaining बाकी';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return '$total मिनटों में से $remaining बाकी';
  }

  @override
  String get authHeadline => 'हर वॉइस मैसेज को उपयोगी बनाएँ';

  @override
  String get authSupporting =>
      'अपने मिनट सुरक्षित रखने और सहेजे गए सारांश अपने खाते तक निजी रखने के लिए साइन इन करें।';

  @override
  String get demoServicesActive =>
      'डेमो सेवाएँ चालू हैं। बाहरी खाते या सशुल्क सेवाएँ इस्तेमाल नहीं होतीं।';

  @override
  String get providerSignInTitle => 'तेज़ और सुरक्षित साइन इन';

  @override
  String get providerSignInDescription =>
      'Apple या Google चुनें। VoiceBrief आपके खाते का पासवर्ड कभी नहीं देखता।';

  @override
  String get continueWithApple => 'Apple से जारी रखें';

  @override
  String get continueWithGoogle => 'Google से जारी रखें';

  @override
  String get byContinuingPrefix => 'आगे बढ़कर आप सहमति देते हैं: ';

  @override
  String get terms => 'शर्तें';

  @override
  String get andConjunction => ' और ';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get errorIdentityProviderUnavailable =>
      'यह साइन इन तरीका अभी उपलब्ध नहीं है। दूसरा तरीका आज़माएँ।';

  @override
  String get onboardingSignIn => 'साइन इन';

  @override
  String get onboardingTitleOne => 'आवाज़ से स्पष्ट जानकारी';

  @override
  String get onboardingBodyOne =>
      'ऑडियो साझा करें, चुनें या रिकॉर्ड करें। ट्रांसक्रिप्ट, सारांश, काम, तारीखें और जवाबों के सुझाव पाएँ।';

  @override
  String get onboardingTitleTwo => 'आपका ऑडियो निजी रहता है';

  @override
  String get onboardingBodyTwo =>
      'ऑडियो सुरक्षित ढंग से प्रोसेस होकर अपने आप हट जाता है। कौन-से टेक्स्ट सहेजने हैं, आप चुनते हैं।';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get recordAudio => 'ऑडियो रिकॉर्ड करें';

  @override
  String get discardRecordingTitle => 'रिकॉर्डिंग हटाएँ?';

  @override
  String get discardRecordingMessage => 'मौजूदा रिकॉर्डिंग हटा दी जाएगी।';

  @override
  String get discard => 'हटा दें';

  @override
  String get recordingPaused => 'रिकॉर्डिंग रुकी हुई है';

  @override
  String get recording => 'रिकॉर्डिंग चल रही है';

  @override
  String get tapRecordReady => 'तैयार होने पर रिकॉर्ड पर टैप करें';

  @override
  String get startRecording => 'रिकॉर्डिंग शुरू करें';

  @override
  String get resume => 'जारी रखें';

  @override
  String get pause => 'विराम दें';

  @override
  String get stop => 'रोकें';

  @override
  String get cancelRecording => 'रिकॉर्डिंग रद्द करें';

  @override
  String get microphoneJustInTime =>
      'माइक्रोफ़ोन की अनुमति केवल रिकॉर्ड पर टैप करने पर माँगी जाती है।';

  @override
  String get recordingSaveFailed => 'रिकॉर्डिंग सहेजी नहीं जा सकी।';

  @override
  String get liveWaveformIdle => 'रिकॉर्डिंग शुरू होने पर असली तरंग दिखेगी।';

  @override
  String get liveWaveformStarting => 'माइक्रोफ़ोन का असली स्तर पढ़ा जा रहा है…';

  @override
  String get liveWaveformActive => 'यह तरंग आपकी आवाज़ के साथ बदल रही है।';

  @override
  String get historyLocalOnly => 'केवल इस डिवाइस पर सहेजा गया';

  @override
  String get searchBriefs => 'सारांश खोजें';

  @override
  String get nothingSaved => 'अभी कुछ सहेजा नहीं गया';

  @override
  String get nothingSavedMessage => 'कोई नतीजा सहेजें, वह यहाँ दिखेगा।';

  @override
  String get noMatchingBriefs => 'मिलता-जुलता सारांश नहीं मिला';

  @override
  String get noMatchingBriefsMessage =>
      'शीर्षक या सारांश का कोई दूसरा शब्द खोजें।';

  @override
  String get briefDeleted => 'सारांश हटा दिया गया';

  @override
  String get undo => 'पहले जैसा करें';

  @override
  String get voiceNoteReady => 'वॉइस मैसेज तैयार है';

  @override
  String get reviewAudio => 'ऑडियो जाँचें';

  @override
  String get createMyBrief => 'मेरा सारांश बनाएँ';

  @override
  String get secureAiProcessing =>
      'सुरक्षित AI प्रोसेसिंग · पूरा होने पर अस्थायी ऑडियो हट जाता है';

  @override
  String get secureAiProcessingSemantics =>
      'ऑडियो AI प्रोसेसिंग के लिए सुरक्षित ढंग से भेजा जाता है और बाद में अस्थायी स्टोरेज से हट जाता है।';

  @override
  String get trimAudio => 'ऑडियो काटें';

  @override
  String get trimAudioHelp =>
      'दोनों किनारे खींचकर हिस्सा चुनें। आगे बढ़ने से पहले उसे सुन सकते हैं।';

  @override
  String selectedAudioRange(String start, String end) {
    return 'चुना गया हिस्सा: $start — $end';
  }

  @override
  String get useFullAudio => 'पूरा ऑडियो इस्तेमाल करें';

  @override
  String get createBriefFromSelection => 'इस हिस्से का सारांश बनाएँ';

  @override
  String get trimmingAudio => 'ऑडियो काटा जा रहा है…';

  @override
  String get audioTrimmed =>
      'ऑडियो काट दिया गया। केवल चुना हुआ हिस्सा रखा गया है।';

  @override
  String get sharedAudioImporting =>
      'साझा किया गया वॉइस मैसेज तैयार हो रहा है…';

  @override
  String get customizeOutput => 'नतीजा अपनी पसंद का बनाएँ';

  @override
  String get defaultOutput =>
      'सारांश और शब्दशः ट्रांसक्रिप्ट अपने आप शामिल होते हैं';

  @override
  String get fullTranscript => 'शब्दशः ट्रांसक्रिप्ट';

  @override
  String get fullTranscriptDescription =>
      'रिकॉर्डिंग में कही गई हर बात जस की तस, ताकि आप पढ़ सकें, खोज सकें या कॉपी कर सकें।';

  @override
  String get summaryAndKeyPoints => 'सारांश और मुख्य बातें';

  @override
  String get actionItemsAndDates => 'काम और तारीखें';

  @override
  String get suggestedReplies => 'जवाबों के सुझाव';

  @override
  String get translateSummaryEnglish => 'सारांश का अंग्रेज़ी में अनुवाद करें';

  @override
  String get sharedAudioReadySemantics =>
      'साझा किया गया वॉइस मैसेज आयात होकर तैयार है।';

  @override
  String get sharedAudioReady => 'वॉइस मैसेज आयात हो गया। बस एक टैप बाकी है।';

  @override
  String get creatingBrief => 'आपका सारांश बन रहा है';

  @override
  String get processingFallbackError =>
      'प्रोसेसिंग पूरी नहीं हुई। सर्वर की सुरक्षित कॉपी हटा दी गई है और आपकी निजी स्थानीय कॉपी दोबारा कोशिश के लिए तैयार है।';

  @override
  String get processingKeepOpen =>
      'सुरक्षित अपलोड पूरा होने तक VoiceBrief खुला रखें। समय रिकॉर्डिंग की लंबाई और कनेक्शन पर निर्भर करता है।';

  @override
  String get preparingAudio => 'ऑडियो तैयार हो रहा है';

  @override
  String get uploadingSecurely => 'सुरक्षित अपलोड हो रहा है';

  @override
  String get transcribing => 'ट्रांसक्रिप्ट बन रहा है';

  @override
  String get creatingYourBrief => 'आपका सारांश बन रहा है';

  @override
  String get finalizing => 'अंतिम चरण';

  @override
  String get brief => 'सारांश';

  @override
  String get briefUnavailable => 'यह सारांश अब उपलब्ध नहीं है।';

  @override
  String get copyAll => 'सब कॉपी करें';

  @override
  String get shareResult => 'नतीजा साझा करें';

  @override
  String get savedLocally => 'डिवाइस पर सहेजा गया';

  @override
  String get notSaved => 'सहेजा नहीं गया';

  @override
  String get saved => 'सहेजा गया';

  @override
  String get saveResult => 'नतीजा सहेजें';

  @override
  String get deleteResult => 'नतीजा हटाएँ';

  @override
  String get deleteBriefTitle => 'यह सारांश हटाएँ?';

  @override
  String get deleteBriefMessage => 'सहेजा गया टेक्स्ट इस डिवाइस से हट जाएगा।';

  @override
  String get keyPoints => 'मुख्य बातें';

  @override
  String get actionItems => 'काम';

  @override
  String get importantDates => 'ज़रूरी तारीखें';

  @override
  String get addToCalendar => 'कैलेंडर में जोड़ें';

  @override
  String get setReminder => 'रिमाइंडर लगाएँ';

  @override
  String get reminderSet => 'VoiceBrief अलार्म लगा दिया गया।';

  @override
  String get reminderUnavailable =>
      'रिमाइंडर नहीं लग सका। VoiceBrief सूचनाएँ चालू करके फिर कोशिश करें।';

  @override
  String get reminderMustBeFuture => 'रिमाइंडर के लिए भविष्य का समय चुनें।';

  @override
  String get chooseAlarmTone => 'अलार्म की आवाज़';

  @override
  String get chooseAlarmToneDescription =>
      'iPhone की मूल आवाज़ इस्तेमाल करें या अपनी आवाज़ चुनें।';

  @override
  String get previewTone => 'आवाज़ सुनें';

  @override
  String get confirmAlarm => 'यह आवाज़ इस्तेमाल करें';

  @override
  String get alarmsAndReminders => 'अलार्म और रिमाइंडर';

  @override
  String get voiceBriefAlarms => 'अलार्म';

  @override
  String get voiceBriefAlarmsDescription =>
      'तय किए गए अलार्म देखें या रद्द करें।';

  @override
  String get noScheduledAlarms => 'कोई आगामी अलार्म नहीं';

  @override
  String get noScheduledAlarmsMessage =>
      'सारांश की किसी तारीख से अलार्म लगाएँ, वह यहाँ दिखेगा।';

  @override
  String get alarmsUnavailable => 'VoiceBrief अलार्म अभी लोड नहीं हो सके।';

  @override
  String get alarmScheduled => 'तय किया गया';

  @override
  String alarmToneLabel(Object tone) {
    return 'आवाज़: $tone';
  }

  @override
  String get alarmSoundTitle => 'अलार्म की आवाज़';

  @override
  String get systemAlarmSound => 'iPhone की डिफ़ॉल्ट आवाज़';

  @override
  String get systemAlarmSoundDescription => 'सिस्टम की मूल आवाज़।';

  @override
  String get customAlarmSound => 'अपनी आवाज़';

  @override
  String get changeAlarmSound => 'बदलें';

  @override
  String get addCustomAlarmSound => 'अपनी आवाज़ जोड़ें';

  @override
  String get importAudioSound => 'ऑडियो फ़ाइल चुनें';

  @override
  String get importVideoSound => 'वीडियो से आवाज़ निकालें';

  @override
  String get soundLimitNotice =>
      'पहले 29 सेकंड अलार्म के अनुकूल फ़ॉर्मैट में सहेजे जाते हैं।';

  @override
  String get preparingAlarmSound => 'आवाज़ तैयार हो रही है…';

  @override
  String get soundImportFailed =>
      'यह फ़ाइल इस्तेमाल नहीं हो सकी। आवाज़ वाली फ़ाइल चुनें।';

  @override
  String get importedSoundReady => 'आवाज़ तैयार है।';

  @override
  String get useThisSound => 'यह आवाज़ इस्तेमाल करें';

  @override
  String get upcomingAlarms => 'आगामी अलार्म';

  @override
  String get loadingAlarms => 'अलार्म लोड हो रहे हैं…';

  @override
  String get cancelAlarm => 'अलार्म रद्द करें';

  @override
  String get cancelAlarmTitle => 'यह अलार्म रद्द करें?';

  @override
  String cancelAlarmMessage(Object title) {
    return 'रद्द करने के बाद “$title” अलार्म नहीं बजेगा।';
  }

  @override
  String get alarmCancelled => 'अलार्म रद्द कर दिया गया।';

  @override
  String get alarmCancelFailed => 'अलार्म रद्द नहीं हो सका। फिर कोशिश करें।';

  @override
  String get refresh => 'रीफ़्रेश करें';

  @override
  String reminderNotificationTitle(String title) {
    return 'रिमाइंडर: $title';
  }

  @override
  String reminderNotificationBody(String phrase) {
    return 'VoiceBrief से: “$phrase”';
  }

  @override
  String ownerLabel(String owner) {
    return 'ज़िम्मेदार: $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'सुना गया: “$phrase”';
  }

  @override
  String get needsConfirmation => 'पुष्टि चाहिए';

  @override
  String get taskDeadline => 'काम की अंतिम तारीख';

  @override
  String get shortTone => 'छोटा';

  @override
  String get friendlyTone => 'दोस्ताना';

  @override
  String get professionalTone => 'पेशेवर';

  @override
  String get shortReply => 'छोटा जवाब';

  @override
  String get friendlyReply => 'दोस्ताना जवाब';

  @override
  String get professionalReply => 'पेशेवर जवाब';

  @override
  String get replyText => 'जवाब का टेक्स्ट';

  @override
  String get shareEditedReply => 'बदला हुआ जवाब साझा करें';

  @override
  String get copyEditedReply => 'बदला हुआ जवाब कॉपी करें';

  @override
  String confirmDatePhrase(String phrase) {
    return '“$phrase” की पुष्टि करें';
  }

  @override
  String get confirmEventTime => 'कार्यक्रम के समय की पुष्टि करें';

  @override
  String get openCalendarTitle => 'कैलेंडर खोलें?';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'VoiceBrief ने “$phrase” का अर्थ $date समझा है। सहेजने से पहले कैलेंडर आपसे पुष्टि माँगेगा।';
  }

  @override
  String get openCalendar => 'कैलेंडर खोलें';

  @override
  String calendarDescription(String phrase) {
    return 'VoiceBrief से पुष्टि के बाद बनाया गया: “$phrase”';
  }

  @override
  String get calendarOpened => 'कैलेंडर संपादक खुल गया।';

  @override
  String datesFound(int count) {
    return '$count तारीखें मिलीं · रिमाइंडर लगाएँ या कैलेंडर में जोड़ें';
  }

  @override
  String datesFoundSemantics(int count) {
    return '$count तारीखें मिली हैं। जाँचें, फिर रिमाइंडर लगाएँ या सिस्टम कैलेंडर में जोड़ें।';
  }

  @override
  String get account => 'खाता';

  @override
  String get notSignedIn => 'साइन इन नहीं है';

  @override
  String get verifiedAccount => 'सत्यापित खाता';

  @override
  String get emailVerificationRequired => 'ईमेल सत्यापन ज़रूरी है';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'मुफ़्त प्लान';

  @override
  String minutesRemaining(int count) {
    return '$count मिनट बाकी';
  }

  @override
  String get restorePurchases => 'खरीदारी बहाल करें';

  @override
  String get purchasesRestored => 'खरीदारी बहाल हो गई।';

  @override
  String get noPurchasesRestored => 'कोई खरीदारी बहाल नहीं हुई।';

  @override
  String get manageSubscription => 'सदस्यता प्रबंधित करें';

  @override
  String get appearance => 'रूप';

  @override
  String get systemTheme => 'सिस्टम';

  @override
  String get lightTheme => 'हल्का';

  @override
  String get darkTheme => 'गहरा';

  @override
  String get privacyAndData => 'गोपनीयता और डेटा';

  @override
  String get audioHandlingTitle => 'ऑडियो अस्थायी है; टेक्स्ट सहेजना वैकल्पिक';

  @override
  String get audioHandlingDescription =>
      'ऑडियो ट्रांसक्रिप्ट बनाने के लिए अस्थायी रूप से इस्तेमाल होता है और अपने आप हट जाता है। केवल आपके चुने हुए सारांश और ट्रांसक्रिप्ट इतिहास में रहते हैं।';

  @override
  String get exportSavedText => 'सहेजा हुआ टेक्स्ट साझा करें';

  @override
  String get exportSubject => 'VoiceBrief निर्यात';

  @override
  String get exportSavedTextDescription =>
      'सारांश, मुख्य बातें, काम, तारीखें, जवाब और ट्रांसक्रिप्ट की TXT फ़ाइल बनाकर साझा करने का मेनू खोलता है। इसमें कभी ऑडियो नहीं होता।';

  @override
  String get exportSavedTextFailed =>
      'साझा करने के लिए टेक्स्ट फ़ाइल नहीं बन सकी।';

  @override
  String get noSavedTextOnDevice =>
      'इस डिवाइस पर कोई टेक्स्ट सहेजा नहीं गया है।';

  @override
  String get clearLocalHistory => 'सहेजा हुआ टेक्स्ट हटाएँ';

  @override
  String get clearSavedTextDescription =>
      'केवल इस डिवाइस के सारांश और ट्रांसक्रिप्ट हटते हैं। यहाँ ऑडियो रिकॉर्डिंग नहीं रखी जातीं।';

  @override
  String get clearHistoryTitle => 'सहेजा हुआ टेक्स्ट हटाएँ?';

  @override
  String get clearHistoryMessage =>
      'इस डिवाइस के सभी सारांश और ट्रांसक्रिप्ट हमेशा के लिए हट जाएँगे। ऑडियो फ़ाइलें प्रोसेसिंग के बाद पहले ही हट जाती हैं।';

  @override
  String get clearHistory => 'टेक्स्ट हटाएँ';

  @override
  String get savedTextCleared => 'सहेजा हुआ टेक्स्ट हट गया।';

  @override
  String get clearSavedTextFailed => 'टेक्स्ट नहीं हट सका। फिर कोशिश करें।';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get support => 'सहायता';

  @override
  String get contactSupport => 'सहायता से संपर्क करें';

  @override
  String get appVersion => 'ऐप का संस्करण';

  @override
  String get deleteAccountTitle => 'खाता हटाएँ?';

  @override
  String get deleteAccountMessage =>
      'इससे सर्वर पर आपका खाता और स्थानीय इतिहास हट जाएगा। स्टोर की सदस्यताएँ तब तक जारी रहेंगी जब तक आप उन्हें स्टोर खाते से रद्द नहीं करते।';

  @override
  String get deleteAccount => 'खाता हटाएँ';

  @override
  String get active => 'सक्रिय';

  @override
  String get proHeadline => 'हर वॉइस मैसेज से पाएँ काम आने वाला सारांश';

  @override
  String get accurateTranscripts => 'सटीक ट्रांसक्रिप्ट';

  @override
  String get instantSummaries => 'तुरंत सारांश';

  @override
  String get threeReplyTones => 'भेजने के लिए तैयार तीन तरह के जवाब';

  @override
  String get loadingStorePrices => 'स्टोर की कीमतें लोड हो रही हैं…';

  @override
  String get subscriptionOptionsUnavailable =>
      'सदस्यता विकल्प उपलब्ध नहीं हैं। प्रोडक्शन में वैकल्पिक कीमत नहीं दिखाई जाती।';

  @override
  String get yearly => 'सालाना';

  @override
  String get monthly => 'मासिक';

  @override
  String get bestValue => 'सबसे किफ़ायती';

  @override
  String get proActive => 'Pro सक्रिय है';

  @override
  String get subscriptionRenewalNotice =>
      'मौजूदा अवधि खत्म होने से कम से कम 24 घंटे पहले रद्द न करने पर सदस्यता अपने आप नवीनीकृत होती है। स्टोर खाते से कभी भी प्रबंधित या रद्द करें।';

  @override
  String get privacy => 'गोपनीयता';

  @override
  String get proActivatedToast => 'VoiceBrief Pro सक्रिय है।';

  @override
  String get noActivePurchases => 'कोई सक्रिय खरीदारी नहीं मिली।';

  @override
  String get errorNoInternet =>
      'आप ऑफ़लाइन लग रहे हैं। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get errorAuthentication =>
      'साइन इन नहीं हो सका। जानकारी जाँचें और फिर कोशिश करें।';

  @override
  String get errorProviderCanceled => 'साइन इन रद्द कर दिया गया।';

  @override
  String get errorEmailVerification =>
      'ईमेल का सत्यापन लिंक खोलें और फिर VoiceBrief पर लौटें।';

  @override
  String get errorUnsupportedAudio => 'यह ऑडियो फ़ॉर्मैट समर्थित नहीं है।';

  @override
  String get errorFileTooLarge => 'ऑडियो फ़ाइल मौजूदा अपलोड सीमा से बड़ी है।';

  @override
  String get errorUnreadableAudio =>
      'यह ऑडियो पढ़ा नहीं जा सका। दूसरी फ़ाइल आज़माएँ।';

  @override
  String get errorAudioEditing =>
      'इस डिवाइस पर ऑडियो नहीं काटा जा सका। मूल फ़ाइल नहीं बदली है।';

  @override
  String get errorMicrophoneDenied =>
      'माइक्रोफ़ोन की अनुमति केवल रिकॉर्ड करने पर चाहिए।';

  @override
  String get errorUploadInterrupted =>
      'सुरक्षित अपलोड रुक गया। आप सुरक्षित रूप से फिर कोशिश कर सकते हैं।';

  @override
  String get errorProcessingTimeout =>
      'प्रोसेसिंग में बहुत समय लगा। आपके मिनट नहीं काटे गए।';

  @override
  String get errorTranscription =>
      'ऑडियो का ट्रांसक्रिप्ट नहीं बन सका। थोड़ी देर में फिर कोशिश करें।';

  @override
  String get errorInvalidResponse => 'नतीजा अधूरा था और सहेजा नहीं गया।';

  @override
  String get errorQuotaExhausted =>
      'इस ऑडियो के लिए आपके पास पर्याप्त मिनट नहीं हैं।';

  @override
  String get errorSubscriptionUnavailable =>
      'सदस्यता विकल्प अभी उपलब्ध नहीं हैं।';

  @override
  String get errorSubscriptionSyncPending =>
      'खरीदारी की पुष्टि हो गई है और Pro सिंक हो रहा है। VoiceBrief खुला रखें और थोड़ी देर में फिर कोशिश करें।';

  @override
  String get errorPurchaseCanceled => 'खरीदारी रद्द कर दी गई।';

  @override
  String get errorPurchaseFailed =>
      'खरीदारी पूरी नहीं हुई। VoiceBrief ने कोई शुल्क नहीं लिया।';

  @override
  String get errorRestoreFailed =>
      'खरीदारी बहाल नहीं हो सकी। बाद में फिर कोशिश करें।';

  @override
  String get errorServiceUnavailable =>
      'VoiceBrief अभी उपलब्ध नहीं है। थोड़ी देर में फिर कोशिश करें।';

  @override
  String get errorShareHandoff =>
      'साझा ऑडियो सुरक्षित ढंग से आयात नहीं हो सका।';

  @override
  String get errorConfiguration =>
      'इस सुविधा का प्रोडक्शन कॉन्फ़िगरेशन अभी बाकी है।';

  @override
  String get errorUnknown => 'कुछ गलत हो गया। फिर कोशिश करें।';
}
