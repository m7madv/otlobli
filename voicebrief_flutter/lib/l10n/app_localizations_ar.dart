// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get home => 'الرئيسية';

  @override
  String get history => 'السجل';

  @override
  String get settings => 'الإعدادات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get tryAgain => 'حاول مجددًا';

  @override
  String get close => 'إغلاق';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get delete => 'حذف';

  @override
  String get copy => 'نسخ';

  @override
  String get edit => 'تعديل';

  @override
  String get copied => 'تم النسخ';

  @override
  String get complete => 'مكتمل';

  @override
  String get unavailable => 'غير متاح';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get replaceAudio => 'استبدال الصوت';

  @override
  String get removeAudio => 'إزالة الصوت';

  @override
  String get playAudio => 'تشغيل الصوت';

  @override
  String get pauseAudio => 'إيقاف الصوت مؤقتًا';

  @override
  String get audioWaveform => 'الموجة الصوتية';

  @override
  String get audioWaveformLoading => 'جارٍ رسم الموجة الحقيقية للصوت…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'تشغيل الصوت، $elapsed من $duration';
  }

  @override
  String copySection(String title) {
    return 'نسخ $title';
  }

  @override
  String get screenUnavailable => 'هذه الشاشة غير متاحة.';

  @override
  String get goPro => 'الترقية إلى Pro';

  @override
  String get homeHeadline => 'حوّل الرسائل الصوتية إلى خطوات واضحة';

  @override
  String get homeSupporting =>
      'شارك من واتساب، اختر ملفًا صوتيًا، أو سجّل من هنا.';

  @override
  String get shareFromWhatsApp => 'من واتساب';

  @override
  String get shareFromWhatsAppSteps =>
      'اضغط مطولًا على الرسالة، ثم مشاركة، ثم VoiceBrief';

  @override
  String get chooseVoiceNote => 'اختيار رسالة صوتية';

  @override
  String get recordInstead => 'تسجيل صوت جديد';

  @override
  String get recentBriefs => 'أحدث الملخصات';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get noBriefsYet => 'لا توجد ملخصات بعد';

  @override
  String get noBriefsMessage =>
      'اختر ملفًا صوتيًا أو سجّل صوتًا لإنشاء أول ملخص.';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return 'متبقي $remaining من أصل $total دقائق مجانية';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return 'متبقي $remaining من أصل $total دقائق Pro';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return 'متبقي $remaining من أصل $total دقائق';
  }

  @override
  String get authHeadline => 'استفد من كل رسالة صوتية';

  @override
  String get authSupporting =>
      'سجّل الدخول لحماية دقائقك وفصل الملخصات المحفوظة داخل حسابك.';

  @override
  String get demoServicesActive =>
      'خدمات العرض التجريبي مفعلة. لن يُستخدم حساب خارجي أو واجهة مدفوعة.';

  @override
  String get providerSignInTitle => 'تسجيل سريع وآمن';

  @override
  String get providerSignInDescription =>
      'اختر Apple أو Google. لا يرى VoiceBrief كلمة مرور حسابك.';

  @override
  String get continueWithApple => 'المتابعة باستخدام Apple';

  @override
  String get continueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get orUseEmail => 'أو استخدم البريد الإلكتروني';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get invalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا.';

  @override
  String get shortPassword => 'استخدم 8 أحرف على الأقل.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get alreadyHaveAccount => 'لديك حساب؟ سجّل الدخول';

  @override
  String get newToVoiceBrief => 'مستخدم جديد؟ أنشئ حسابًا';

  @override
  String get byContinuingPrefix => 'بالمتابعة، أنت توافق على ';

  @override
  String get terms => 'الشروط';

  @override
  String get andConjunction => ' و';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get passwordResetSent => 'أُرسلت رسالة إعادة تعيين كلمة المرور.';

  @override
  String get errorIdentityProviderUnavailable =>
      'طريقة تسجيل الدخول هذه غير متاحة الآن. جرّب طريقة أخرى.';

  @override
  String get onboardingSignIn => 'تسجيل الدخول';

  @override
  String get onboardingTitleOne => 'حوّل الصوت إلى وضوح';

  @override
  String get onboardingBodyOne =>
      'شارك رسالة صوتية أو اخترها أو سجّلها. يعيد VoiceBrief النص والملخص والمهام والمواعيد والردود المقترحة.';

  @override
  String get onboardingTitleTwo => 'صوتك يبقى خاصًا';

  @override
  String get onboardingBodyTwo =>
      'يُعالج الصوت بأمان ثم يُحذف تلقائيًا. أنت من يختار النتائج النصية التي تُحفظ.';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get recordAudio => 'تسجيل صوت';

  @override
  String get discardRecordingTitle => 'حذف التسجيل؟';

  @override
  String get discardRecordingMessage => 'سيُحذف التسجيل الحالي.';

  @override
  String get discard => 'حذف التسجيل';

  @override
  String get recordingPaused => 'التسجيل متوقف مؤقتًا';

  @override
  String get recording => 'جارٍ التسجيل';

  @override
  String get tapRecordReady => 'اضغط زر التسجيل عندما تكون جاهزًا';

  @override
  String get startRecording => 'بدء التسجيل';

  @override
  String get resume => 'استئناف';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get stop => 'إيقاف';

  @override
  String get cancelRecording => 'إلغاء التسجيل';

  @override
  String get microphoneJustInTime =>
      'سيُطلب إذن الميكروفون فقط عند الضغط على زر التسجيل.';

  @override
  String get recordingSaveFailed => 'تعذر حفظ التسجيل.';

  @override
  String get liveWaveformIdle => 'تظهر الموجة الحقيقية بعد بدء التسجيل.';

  @override
  String get liveWaveformStarting => 'جارٍ قراءة مستوى الميكروفون الحقيقي…';

  @override
  String get liveWaveformActive => 'هذه الموجة تتحرك حسب صوتك مباشرة.';

  @override
  String get historyLocalOnly => 'محفوظ محليًا على هذا الجهاز';

  @override
  String get searchBriefs => 'البحث في الملخصات';

  @override
  String get nothingSaved => 'لا يوجد شيء محفوظ بعد';

  @override
  String get nothingSavedMessage => 'احفظ النتيجة عندما تريد ظهورها هنا.';

  @override
  String get noMatchingBriefs => 'لا توجد نتائج مطابقة';

  @override
  String get noMatchingBriefsMessage =>
      'جرّب كلمة مختلفة من العنوان أو الملخص.';

  @override
  String get briefDeleted => 'تم حذف الملخص';

  @override
  String get undo => 'تراجع';

  @override
  String get voiceNoteReady => 'الرسالة الصوتية جاهزة';

  @override
  String get reviewAudio => 'مراجعة الصوت';

  @override
  String get createMyBrief => 'إنشاء الملخص';

  @override
  String get secureAiProcessing =>
      'معالجة آمنة بالذكاء الاصطناعي · يُحذف الصوت المؤقت بعد المعالجة';

  @override
  String get secureAiProcessingSemantics =>
      'سيُرسل الصوت بأمان للمعالجة بالذكاء الاصطناعي ثم يُحذف من التخزين المؤقت.';

  @override
  String get trimAudio => 'قص الصوت';

  @override
  String get trimAudioHelp =>
      'اسحب المقبضين لتحديد الجزء الذي تريد تلخيصه. يمكنك تشغيله قبل المتابعة.';

  @override
  String selectedAudioRange(String start, String end) {
    return 'الجزء المحدد: $start — $end';
  }

  @override
  String get useFullAudio => 'استخدام الصوت كاملًا';

  @override
  String get createBriefFromSelection => 'إنشاء ملخص لهذا الجزء';

  @override
  String get trimmingAudio => 'جارٍ قص الصوت…';

  @override
  String get audioTrimmed => 'تم قص الصوت وحُفظ الجزء المحدد فقط.';

  @override
  String get sharedAudioImporting => 'جارٍ تجهيز الرسالة الصوتية…';

  @override
  String get customizeOutput => 'تخصيص النتيجة';

  @override
  String get defaultOutput => 'الملخص والنص الحرفي جاهزان تلقائيًا';

  @override
  String get fullTranscript => 'النص الحرفي للتسجيل';

  @override
  String get fullTranscriptDescription =>
      'كل ما قيل في التسجيل كما هو، لتراجعه أو تبحث فيه أو تنسخه.';

  @override
  String get summaryAndKeyPoints => 'الملخص والنقاط الأساسية';

  @override
  String get actionItemsAndDates => 'المهام والمواعيد';

  @override
  String get suggestedReplies => 'الردود المقترحة';

  @override
  String get translateSummaryEnglish => 'ترجمة الملخص إلى الإنجليزية';

  @override
  String get sharedAudioReadySemantics =>
      'تم استيراد الرسالة الصوتية وأصبحت جاهزة.';

  @override
  String get sharedAudioReady => 'تم استيراد الرسالة الصوتية. بقيت ضغطة واحدة.';

  @override
  String get creatingBrief => 'جارٍ إنشاء الملخص';

  @override
  String get processingFallbackError =>
      'تعذر إكمال المعالجة. حُذفت نسخة الخادم الآمنة ونسختك المحلية الخاصة جاهزة للمحاولة مجددًا.';

  @override
  String get processingKeepOpen =>
      'أبقِ VoiceBrief مفتوحًا حتى ينتهي الرفع الآمن. قد يختلف الوقت حسب طول التسجيل وسرعة الاتصال.';

  @override
  String get preparingAudio => 'تجهيز الصوت';

  @override
  String get uploadingSecurely => 'رفع آمن';

  @override
  String get transcribing => 'تحويل الصوت إلى نص';

  @override
  String get creatingYourBrief => 'إنشاء الملخص';

  @override
  String get finalizing => 'اللمسات الأخيرة';

  @override
  String get brief => 'الملخص';

  @override
  String get briefUnavailable => 'هذا الملخص لم يعد متاحًا.';

  @override
  String get copyAll => 'نسخ الكل';

  @override
  String get shareResult => 'مشاركة النتيجة';

  @override
  String get savedLocally => 'محفوظ محليًا';

  @override
  String get notSaved => 'غير محفوظ';

  @override
  String get saved => 'محفوظ';

  @override
  String get saveResult => 'حفظ النتيجة';

  @override
  String get deleteResult => 'حذف النتيجة';

  @override
  String get deleteBriefTitle => 'حذف هذا الملخص؟';

  @override
  String get deleteBriefMessage => 'سيُحذف النص المحفوظ من هذا الجهاز.';

  @override
  String get keyPoints => 'النقاط الأساسية';

  @override
  String get actionItems => 'المهام';

  @override
  String get importantDates => 'المواعيد المهمة';

  @override
  String get addToCalendar => 'إضافة إلى التقويم';

  @override
  String ownerLabel(String owner) {
    return 'المسؤول: $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'المسموع: «$phrase»';
  }

  @override
  String get needsConfirmation => 'يحتاج إلى تأكيد';

  @override
  String get taskDeadline => 'موعد المهمة';

  @override
  String get shortTone => 'قصير';

  @override
  String get friendlyTone => 'ودّي';

  @override
  String get professionalTone => 'رسمي';

  @override
  String get shortReply => 'رد قصير';

  @override
  String get friendlyReply => 'رد ودّي';

  @override
  String get professionalReply => 'رد رسمي';

  @override
  String get replyText => 'نص الرد';

  @override
  String get shareEditedReply => 'مشاركة الرد المعدّل';

  @override
  String get copyEditedReply => 'نسخ الرد المعدّل';

  @override
  String confirmDatePhrase(String phrase) {
    return 'تأكيد «$phrase»';
  }

  @override
  String get confirmEventTime => 'تأكيد وقت الموعد';

  @override
  String get openCalendarTitle => 'فتح التقويم؟';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'فسّر VoiceBrief العبارة «$phrase» على أنها $date. سيطلب منك التقويم التأكيد قبل الحفظ.';
  }

  @override
  String get openCalendar => 'فتح التقويم';

  @override
  String calendarDescription(String phrase) {
    return 'أُنشئ من VoiceBrief بعد تأكيد: «$phrase»';
  }

  @override
  String get calendarOpened => 'تم فتح محرر التقويم.';

  @override
  String datesFound(int count) {
    return 'تم العثور على $count موعد · راجعه وأضفه إلى تقويمك';
  }

  @override
  String datesFoundSemantics(int count) {
    return 'تم العثور على $count موعد. راجعه قبل إضافته إلى تقويم النظام.';
  }

  @override
  String get account => 'الحساب';

  @override
  String get notSignedIn => 'لم يتم تسجيل الدخول';

  @override
  String get verifiedAccount => 'حساب موثّق';

  @override
  String get emailVerificationRequired => 'يلزم توثيق البريد الإلكتروني';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'الخطة المجانية';

  @override
  String minutesRemaining(int count) {
    return 'متبقي $count دقيقة';
  }

  @override
  String get restorePurchases => 'استعادة المشتريات';

  @override
  String get purchasesRestored => 'تمت استعادة المشتريات.';

  @override
  String get noPurchasesRestored => 'لم تُستعد أي مشتريات.';

  @override
  String get manageSubscription => 'إدارة الاشتراك';

  @override
  String get appearance => 'المظهر';

  @override
  String get systemTheme => 'النظام';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get darkTheme => 'داكن';

  @override
  String get privacyAndData => 'الخصوصية والبيانات';

  @override
  String get audioHandlingTitle => 'الصوت مؤقت، والنص اختياري';

  @override
  String get audioHandlingDescription =>
      'يُستخدم ملف الصوت مؤقتًا للتحويل ثم يُحذف تلقائيًا. لا يبقى في السجل إلا الملخص والنص عندما تضغط حفظ.';

  @override
  String get exportSavedText => 'مشاركة النصوص المحفوظة';

  @override
  String get exportSubject => 'تصدير VoiceBrief';

  @override
  String get exportSavedTextDescription =>
      'ينشئ ملف TXT من الملخص والنقاط والمهام والمواعيد والردود والنص الحرفي، ثم يفتح قائمة المشاركة. لا يتضمن أي صوت.';

  @override
  String get exportSavedTextFailed => 'تعذر إنشاء ملف النص للمشاركة.';

  @override
  String get noSavedTextOnDevice => 'لا توجد نصوص محفوظة على هذا الجهاز.';

  @override
  String get clearLocalHistory => 'حذف النصوص المحفوظة';

  @override
  String get clearSavedTextDescription =>
      'يحذف الملخصات والنصوص من هذا الجهاز فقط. لا توجد تسجيلات صوتية محفوظة هنا.';

  @override
  String get clearHistoryTitle => 'حذف النصوص المحفوظة؟';

  @override
  String get clearHistoryMessage =>
      'ستُحذف كل الملخصات والنصوص المحفوظة على هذا الجهاز نهائيًا. ملفات الصوت محذوفة أصلًا بعد المعالجة.';

  @override
  String get clearHistory => 'حذف النصوص';

  @override
  String get savedTextCleared => 'حُذفت النصوص المحفوظة.';

  @override
  String get clearSavedTextFailed => 'تعذر حذف النصوص المحفوظة. حاول مجددًا.';

  @override
  String get termsOfService => 'شروط الاستخدام';

  @override
  String get support => 'الدعم';

  @override
  String get contactSupport => 'التواصل مع الدعم';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get deleteAccountTitle => 'حذف الحساب؟';

  @override
  String get deleteAccountMessage =>
      'سيُحذف حساب الخادم والسجل المحلي. تستمر اشتراكات المتجر حتى تلغيها من حساب المتجر.';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get active => 'مفعّل';

  @override
  String get proHeadline => 'حوّل كل رسالة صوتية إلى ملخص قابل للتنفيذ';

  @override
  String get accurateTranscripts => 'نصوص دقيقة';

  @override
  String get instantSummaries => 'ملخصات فورية';

  @override
  String get threeReplyTones => 'ثلاث صيغ رد جاهزة للإرسال';

  @override
  String get loadingStorePrices => 'جارٍ تحميل أسعار المتجر…';

  @override
  String get subscriptionOptionsUnavailable =>
      'خيارات الاشتراك غير متاحة. لن يُعرض سعر بديل في نسخة الإنتاج.';

  @override
  String get yearly => 'سنوي';

  @override
  String get monthly => 'شهري';

  @override
  String get bestValue => 'أفضل قيمة · وفّر 34%';

  @override
  String get proActive => 'اشتراك Pro مفعّل';

  @override
  String get subscriptionRenewalNotice =>
      'تتجدد الاشتراكات تلقائيًا ما لم تُلغَ قبل نهاية الفترة الحالية بـ24 ساعة على الأقل. يمكنك الإدارة أو الإلغاء من حساب المتجر.';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get proActivatedToast => 'تم تفعيل VoiceBrief Pro.';

  @override
  String get noActivePurchases => 'لم يُعثر على مشتريات مفعلة.';

  @override
  String get errorNoInternet =>
      'يبدو أنك غير متصل. تحقق من الاتصال وحاول مجددًا.';

  @override
  String get errorAuthentication =>
      'تعذر تسجيل الدخول. تحقق من بياناتك وحاول مجددًا.';

  @override
  String get errorProviderCanceled => 'أُلغي تسجيل الدخول.';

  @override
  String get errorEmailVerification => 'وثّق بريدك الإلكتروني قبل المتابعة.';

  @override
  String get errorUnsupportedAudio => 'صيغة الصوت هذه غير مدعومة.';

  @override
  String get errorFileTooLarge => 'حجم ملف الصوت يتجاوز حد الرفع الحالي.';

  @override
  String get errorUnreadableAudio => 'تعذرت قراءة ملف الصوت. جرّب ملفًا آخر.';

  @override
  String get errorAudioEditing =>
      'تعذر قص هذا الصوت على جهازك. بقي الملف الأصلي دون تغيير.';

  @override
  String get errorMicrophoneDenied =>
      'يلزم إذن الميكروفون فقط عندما تختار التسجيل.';

  @override
  String get errorUploadInterrupted =>
      'توقف الرفع الآمن. يمكنك المحاولة مجددًا بأمان.';

  @override
  String get errorProcessingTimeout =>
      'استغرقت المعالجة وقتًا طويلًا. لم تُخصم دقائقك.';

  @override
  String get errorTranscription => 'تعذر تحويل الصوت إلى نص. حاول بعد قليل.';

  @override
  String get errorInvalidResponse => 'النتيجة غير مكتملة ولم تُحفظ.';

  @override
  String get errorQuotaExhausted => 'لا تملك دقائق معالجة كافية لهذا الصوت.';

  @override
  String get errorSubscriptionUnavailable => 'خيارات الاشتراك غير متاحة الآن.';

  @override
  String get errorPurchaseCanceled => 'أُلغيت عملية الشراء.';

  @override
  String get errorPurchaseFailed =>
      'لم تكتمل عملية الشراء ولم يخصم VoiceBrief أي مبلغ.';

  @override
  String get errorRestoreFailed => 'تعذرت استعادة المشتريات. حاول لاحقًا.';

  @override
  String get errorServiceUnavailable =>
      'VoiceBrief غير متاح مؤقتًا. حاول قريبًا.';

  @override
  String get errorShareHandoff => 'تعذر استيراد الصوت المشارك بأمان.';

  @override
  String get errorConfiguration => 'تحتاج هذه الميزة إلى إكمال إعداد الإنتاج.';

  @override
  String get errorUnknown => 'حدث خطأ ما. حاول مجددًا.';
}
