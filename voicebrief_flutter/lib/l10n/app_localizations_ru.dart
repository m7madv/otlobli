// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get appLanguage => 'Язык приложения';

  @override
  String get followSystemLanguage => 'Язык устройства';

  @override
  String get home => 'Главная';

  @override
  String get history => 'История';

  @override
  String get settings => 'Настройки';

  @override
  String get cancel => 'Отмена';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get close => 'Закрыть';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get signIn => 'Войти';

  @override
  String get signOut => 'Выйти';

  @override
  String get delete => 'Удалить';

  @override
  String get copy => 'Копировать';

  @override
  String get edit => 'Изменить';

  @override
  String get copied => 'Скопировано';

  @override
  String get complete => 'Готово';

  @override
  String get unavailable => 'Недоступно';

  @override
  String get replaceAudio => 'Заменить аудио';

  @override
  String get removeAudio => 'Убрать аудио';

  @override
  String get playAudio => 'Воспроизвести';

  @override
  String get pauseAudio => 'Приостановить';

  @override
  String get audioWaveform => 'Звуковая волна';

  @override
  String get audioWaveformLoading => 'Построение реальной звуковой волны…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'Воспроизведение: $elapsed из $duration';
  }

  @override
  String copySection(String title) {
    return 'Копировать: $title';
  }

  @override
  String get screenUnavailable => 'Этот экран недоступен.';

  @override
  String get goPro => 'Перейти на Pro';

  @override
  String get homeHeadline => 'Превратите голосовые сообщения в понятный план';

  @override
  String get homeSupporting =>
      'Поделитесь из WhatsApp, выберите аудиофайл или запишите здесь.';

  @override
  String get shareFromWhatsApp => 'Из WhatsApp';

  @override
  String get shareFromWhatsAppSteps =>
      'Удерживайте голосовое сообщение, нажмите «Поделиться», затем VoiceBrief';

  @override
  String get chooseVoiceNote => 'Выбрать голосовое сообщение';

  @override
  String get recordInstead => 'Записать сейчас';

  @override
  String get recentBriefs => 'Последние сводки';

  @override
  String get viewAll => 'Показать все';

  @override
  String get noBriefsYet => 'Сводок пока нет';

  @override
  String get noBriefsMessage =>
      'Выберите или запишите аудио, чтобы создать первую сводку.';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return 'Осталось $remaining из $total бесплатных минут';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return 'Осталось $remaining из $total минут Pro';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return 'Осталось $remaining из $total минут';
  }

  @override
  String get authHeadline => 'Польза в каждом голосовом сообщении';

  @override
  String get authSupporting =>
      'Войдите, чтобы защитить свои минуты и сохранить сводки доступными только в вашем аккаунте.';

  @override
  String get demoServicesActive =>
      'Включён деморежим. Внешние аккаунты и платные сервисы не используются.';

  @override
  String get providerSignInTitle => 'Быстрый и безопасный вход';

  @override
  String get providerSignInDescription =>
      'Выберите Apple или Google. VoiceBrief никогда не видит ваш пароль.';

  @override
  String get continueWithApple => 'Продолжить с Apple';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get byContinuingPrefix => 'Продолжая, вы принимаете ';

  @override
  String get terms => 'Условия';

  @override
  String get andConjunction => ' и ';

  @override
  String get privacyPolicy => 'Политику конфиденциальности';

  @override
  String get errorIdentityProviderUnavailable =>
      'Этот способ входа недоступен. Попробуйте другой.';

  @override
  String get onboardingSignIn => 'Войти';

  @override
  String get onboardingTitleOne => 'От голоса к ясности';

  @override
  String get onboardingBodyOne =>
      'Поделитесь, выберите или запишите аудио. Получите расшифровку, сводку, задачи, даты и варианты ответов.';

  @override
  String get onboardingTitleTwo => 'Ваше аудио остаётся личным';

  @override
  String get onboardingBodyTwo =>
      'Аудио безопасно обрабатывается и автоматически удаляется. Вы выбираете, какие тексты сохранить.';

  @override
  String get getStarted => 'Начать';

  @override
  String get recordAudio => 'Записать аудио';

  @override
  String get discardRecordingTitle => 'Удалить запись?';

  @override
  String get discardRecordingMessage => 'Текущая запись будет удалена.';

  @override
  String get discard => 'Удалить';

  @override
  String get recordingPaused => 'Запись приостановлена';

  @override
  String get recording => 'Идёт запись';

  @override
  String get tapRecordReady => 'Нажмите запись, когда будете готовы';

  @override
  String get startRecording => 'Начать запись';

  @override
  String get resume => 'Продолжить';

  @override
  String get pause => 'Пауза';

  @override
  String get stop => 'Стоп';

  @override
  String get cancelRecording => 'Отменить запись';

  @override
  String get microphoneJustInTime =>
      'Доступ к микрофону запрашивается только при начале записи.';

  @override
  String get recordingSaveFailed => 'Не удалось сохранить запись.';

  @override
  String get liveWaveformIdle =>
      'Реальная звуковая волна появится после начала записи.';

  @override
  String get liveWaveformStarting => 'Измерение уровня микрофона…';

  @override
  String get liveWaveformActive => 'Волна движется в такт вашему голосу.';

  @override
  String get historyLocalOnly => 'Сохранено только на этом устройстве';

  @override
  String get searchBriefs => 'Поиск сводок';

  @override
  String get nothingSaved => 'Пока ничего не сохранено';

  @override
  String get nothingSavedMessage =>
      'Сохраните результат, чтобы он появился здесь.';

  @override
  String get noMatchingBriefs => 'Совпадений нет';

  @override
  String get noMatchingBriefsMessage =>
      'Попробуйте другое слово из заголовка или сводки.';

  @override
  String get briefDeleted => 'Сводка удалена';

  @override
  String get undo => 'Отменить';

  @override
  String get voiceNoteReady => 'Голосовое сообщение готово';

  @override
  String get reviewAudio => 'Проверить аудио';

  @override
  String get createMyBrief => 'Создать сводку';

  @override
  String get secureAiProcessing =>
      'Безопасная обработка ИИ · временное аудио удаляется после обработки';

  @override
  String get secureAiProcessingSemantics =>
      'Аудио безопасно отправляется на обработку ИИ и затем удаляется из временного хранилища.';

  @override
  String get trimAudio => 'Обрезать аудио';

  @override
  String get trimAudioHelp =>
      'Перемещайте оба края, чтобы выбрать фрагмент. Его можно прослушать перед продолжением.';

  @override
  String selectedAudioRange(String start, String end) {
    return 'Выбранный фрагмент: $start — $end';
  }

  @override
  String get useFullAudio => 'Использовать всё аудио';

  @override
  String get createBriefFromSelection => 'Создать сводку фрагмента';

  @override
  String get trimmingAudio => 'Обрезка аудио…';

  @override
  String get audioTrimmed =>
      'Аудио обрезано. Сохранён только выбранный фрагмент.';

  @override
  String get sharedAudioImporting =>
      'Подготовка переданного голосового сообщения…';

  @override
  String get customizeOutput => 'Настроить результат';

  @override
  String get defaultOutput =>
      'Сводка и дословная расшифровка включаются автоматически';

  @override
  String get fullTranscript => 'Дословная расшифровка';

  @override
  String get fullTranscriptDescription =>
      'Всё сказанное в записи сохранено без пересказа, чтобы вы могли перечитать, найти или скопировать текст.';

  @override
  String get summaryAndKeyPoints => 'Сводка и ключевые мысли';

  @override
  String get actionItemsAndDates => 'Задачи и даты';

  @override
  String get suggestedReplies => 'Варианты ответов';

  @override
  String get translateSummaryEnglish => 'Перевести сводку на английский';

  @override
  String get sharedAudioReadySemantics =>
      'Переданное голосовое сообщение импортировано и готово.';

  @override
  String get sharedAudioReady =>
      'Сообщение импортировано. Осталось одно нажатие.';

  @override
  String get creatingBrief => 'Создание сводки';

  @override
  String get processingFallbackError =>
      'Обработка не завершена. Защищённая копия на сервере удалена, а ваша личная локальная копия готова к повторной попытке.';

  @override
  String get processingKeepOpen =>
      'Не закрывайте VoiceBrief до завершения безопасной загрузки. Время зависит от длины записи и соединения.';

  @override
  String get preparingAudio => 'Подготовка аудио';

  @override
  String get uploadingSecurely => 'Безопасная загрузка';

  @override
  String get transcribing => 'Расшифровка';

  @override
  String get creatingYourBrief => 'Создание сводки';

  @override
  String get finalizing => 'Завершение';

  @override
  String get brief => 'Сводка';

  @override
  String get briefUnavailable => 'Эта сводка больше недоступна.';

  @override
  String get copyAll => 'Копировать всё';

  @override
  String get shareResult => 'Поделиться результатом';

  @override
  String get savedLocally => 'Сохранено локально';

  @override
  String get notSaved => 'Не сохранено';

  @override
  String get saved => 'Сохранено';

  @override
  String get saveResult => 'Сохранить результат';

  @override
  String get deleteResult => 'Удалить результат';

  @override
  String get deleteBriefTitle => 'Удалить эту сводку?';

  @override
  String get deleteBriefMessage =>
      'Сохранённый текст будет удалён с этого устройства.';

  @override
  String get keyPoints => 'Ключевые мысли';

  @override
  String get actionItems => 'Задачи';

  @override
  String get importantDates => 'Важные даты';

  @override
  String get addToCalendar => 'Добавить в календарь';

  @override
  String get setReminder => 'Создать напоминание';

  @override
  String get reminderSet => 'Будильник VoiceBrief установлен.';

  @override
  String get reminderUnavailable =>
      'Не удалось создать напоминание. Включите уведомления VoiceBrief и повторите попытку.';

  @override
  String get reminderMustBeFuture => 'Выберите будущее время напоминания.';

  @override
  String get chooseAlarmTone => 'Звук будильника';

  @override
  String get chooseAlarmToneDescription =>
      'Используйте исходный звук iPhone или выберите свой.';

  @override
  String get previewTone => 'Прослушать';

  @override
  String get confirmAlarm => 'Использовать этот звук';

  @override
  String get alarmsAndReminders => 'Будильники и напоминания';

  @override
  String get voiceBriefAlarms => 'Будильники';

  @override
  String get voiceBriefAlarmsDescription =>
      'Просмотр и отмена запланированных будильников.';

  @override
  String get noScheduledAlarms => 'Нет предстоящих будильников';

  @override
  String get noScheduledAlarmsMessage =>
      'Создайте будильник из даты в сводке, и он появится здесь.';

  @override
  String get alarmsUnavailable => 'Не удалось загрузить будильники VoiceBrief.';

  @override
  String get alarmScheduled => 'Запланирован';

  @override
  String alarmToneLabel(Object tone) {
    return 'Звук: $tone';
  }

  @override
  String get alarmSoundTitle => 'Звук будильника';

  @override
  String get systemAlarmSound => 'Стандартный звук iPhone';

  @override
  String get systemAlarmSoundDescription => 'Исходный системный звук.';

  @override
  String get customAlarmSound => 'Свой звук';

  @override
  String get changeAlarmSound => 'Изменить';

  @override
  String get addCustomAlarmSound => 'Добавить свой звук';

  @override
  String get importAudioSound => 'Выбрать аудиофайл';

  @override
  String get importVideoSound => 'Извлечь звук из видео';

  @override
  String get soundLimitNotice =>
      'Первые 29 секунд сохраняются в формате для будильника.';

  @override
  String get preparingAlarmSound => 'Подготовка звука…';

  @override
  String get soundImportFailed =>
      'Не удалось использовать файл. Выберите файл со звуком.';

  @override
  String get importedSoundReady => 'Звук готов.';

  @override
  String get useThisSound => 'Использовать этот звук';

  @override
  String get upcomingAlarms => 'Предстоящие будильники';

  @override
  String get loadingAlarms => 'Загрузка будильников…';

  @override
  String get cancelAlarm => 'Отменить будильник';

  @override
  String get cancelAlarmTitle => 'Отменить этот будильник?';

  @override
  String cancelAlarmMessage(Object title) {
    return 'После отмены будильник «$title» не прозвучит.';
  }

  @override
  String get alarmCancelled => 'Будильник отменён.';

  @override
  String get alarmCancelFailed =>
      'Не удалось отменить будильник. Повторите попытку.';

  @override
  String get refresh => 'Обновить';

  @override
  String reminderNotificationTitle(String title) {
    return 'Напоминание: $title';
  }

  @override
  String reminderNotificationBody(String phrase) {
    return 'Из VoiceBrief: «$phrase»';
  }

  @override
  String ownerLabel(String owner) {
    return 'Ответственный: $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'Сказано: «$phrase»';
  }

  @override
  String get needsConfirmation => 'Нужно подтверждение';

  @override
  String get taskDeadline => 'Срок задачи';

  @override
  String get shortTone => 'Кратко';

  @override
  String get friendlyTone => 'Дружелюбно';

  @override
  String get professionalTone => 'Деловой стиль';

  @override
  String get shortReply => 'Краткий ответ';

  @override
  String get friendlyReply => 'Дружелюбный ответ';

  @override
  String get professionalReply => 'Деловой ответ';

  @override
  String get replyText => 'Текст ответа';

  @override
  String get shareEditedReply => 'Поделиться изменённым ответом';

  @override
  String get copyEditedReply => 'Копировать изменённый ответ';

  @override
  String confirmDatePhrase(String phrase) {
    return 'Подтвердить «$phrase»';
  }

  @override
  String get confirmEventTime => 'Подтвердить время события';

  @override
  String get openCalendarTitle => 'Открыть календарь?';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'VoiceBrief определил «$phrase» как $date. Календарь попросит подтвердить данные перед сохранением.';
  }

  @override
  String get openCalendar => 'Открыть календарь';

  @override
  String calendarDescription(String phrase) {
    return 'Создано в VoiceBrief после подтверждения: «$phrase»';
  }

  @override
  String get calendarOpened => 'Редактор календаря открыт.';

  @override
  String datesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Найдено дат: $count · создайте напоминания или добавьте в календарь',
      many:
          'Найдено $count дат · создайте напоминания или добавьте в календарь',
      few:
          'Найдены $count даты · создайте напоминания или добавьте в календарь',
      one:
          'Найдена $count дата · создайте напоминание или добавьте в календарь',
    );
    return '$_temp0';
  }

  @override
  String datesFoundSemantics(int count) {
    return 'Найдено дат: $count. Проверьте их, затем создайте напоминания или добавьте в системный календарь.';
  }

  @override
  String get account => 'Аккаунт';

  @override
  String get notSignedIn => 'Вход не выполнен';

  @override
  String get verifiedAccount => 'Аккаунт подтверждён';

  @override
  String get emailVerificationRequired => 'Требуется подтверждение почты';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'Бесплатный план';

  @override
  String minutesRemaining(int count) {
    return 'Осталось минут: $count';
  }

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get purchasesRestored => 'Покупки восстановлены.';

  @override
  String get noPurchasesRestored => 'Нет восстановленных покупок.';

  @override
  String get manageSubscription => 'Управление подпиской';

  @override
  String get appearance => 'Оформление';

  @override
  String get systemTheme => 'Системное';

  @override
  String get lightTheme => 'Светлое';

  @override
  String get darkTheme => 'Тёмное';

  @override
  String get privacyAndData => 'Конфиденциальность и данные';

  @override
  String get audioHandlingTitle =>
      'Аудио временное; сохранение текста по желанию';

  @override
  String get audioHandlingDescription =>
      'Аудио временно используется для расшифровки и автоматически удаляется. В истории остаются только сводки и расшифровки, которые вы сохраните.';

  @override
  String get exportSavedText => 'Поделиться сохранённым текстом';

  @override
  String get exportSubject => 'Экспорт VoiceBrief';

  @override
  String get exportSavedTextDescription =>
      'Создаёт TXT со сводками, ключевыми мыслями, задачами, датами, ответами и расшифровками и открывает меню отправки. Аудио не включается.';

  @override
  String get exportSavedTextFailed =>
      'Не удалось создать текстовый файл для отправки.';

  @override
  String get noSavedTextOnDevice =>
      'На этом устройстве нет сохранённого текста.';

  @override
  String get clearLocalHistory => 'Удалить сохранённый текст';

  @override
  String get clearSavedTextDescription =>
      'Удаляет сводки и расшифровки только с этого устройства. Аудиозаписи здесь не хранятся.';

  @override
  String get clearHistoryTitle => 'Удалить сохранённый текст?';

  @override
  String get clearHistoryMessage =>
      'Все сводки и расшифровки на этом устройстве будут удалены навсегда. Аудиофайлы уже удаляются после обработки.';

  @override
  String get clearHistory => 'Удалить текст';

  @override
  String get savedTextCleared => 'Сохранённый текст удалён.';

  @override
  String get clearSavedTextFailed =>
      'Не удалось удалить текст. Повторите попытку.';

  @override
  String get termsOfService => 'Условия использования';

  @override
  String get support => 'Поддержка';

  @override
  String get contactSupport => 'Связаться с поддержкой';

  @override
  String get appVersion => 'Версия приложения';

  @override
  String get deleteAccountTitle => 'Удалить аккаунт?';

  @override
  String get deleteAccountMessage =>
      'Будут удалены аккаунт на сервере и локальная история. Подписки останутся активны, пока вы не отмените их в аккаунте магазина.';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get active => 'Активно';

  @override
  String get proHeadline =>
      'Превратите каждое голосовое сообщение в сводку с действиями';

  @override
  String get accurateTranscripts => 'Точные расшифровки';

  @override
  String get instantSummaries => 'Мгновенные сводки';

  @override
  String get threeReplyTones => 'Три стиля готовых ответов';

  @override
  String get loadingStorePrices => 'Загрузка цен магазина…';

  @override
  String get subscriptionOptionsUnavailable =>
      'Подписки недоступны. В рабочей версии подставные цены не показываются.';

  @override
  String get yearly => 'Годовая';

  @override
  String get monthly => 'Месячная';

  @override
  String get bestValue => 'ВЫГОДНО';

  @override
  String get proActive => 'Pro активен';

  @override
  String get subscriptionRenewalNotice =>
      'Подписки продлеваются автоматически, если их не отменить минимум за 24 часа до конца периода. Управлять подписками и отменять их можно в аккаунте магазина.';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get proActivatedToast => 'VoiceBrief Pro активен.';

  @override
  String get noActivePurchases => 'Активные покупки не найдены.';

  @override
  String get errorNoInternet =>
      'Похоже, вы не в сети. Проверьте соединение и повторите попытку.';

  @override
  String get errorAuthentication =>
      'Не удалось войти. Проверьте данные и повторите попытку.';

  @override
  String get errorProviderCanceled => 'Вход отменён.';

  @override
  String get errorEmailVerification =>
      'Откройте ссылку подтверждения в письме, затем вернитесь в VoiceBrief.';

  @override
  String get errorUnsupportedAudio => 'Этот формат аудио не поддерживается.';

  @override
  String get errorFileTooLarge => 'Аудиофайл превышает текущий лимит загрузки.';

  @override
  String get errorUnreadableAudio =>
      'Не удалось прочитать аудио. Попробуйте другой файл.';

  @override
  String get errorAudioEditing =>
      'Не удалось обрезать аудио на этом устройстве. Оригинал не изменён.';

  @override
  String get errorMicrophoneDenied =>
      'Доступ к микрофону нужен только для записи.';

  @override
  String get errorUploadInterrupted =>
      'Безопасная загрузка прервана. Можно безопасно повторить попытку.';

  @override
  String get errorProcessingTimeout =>
      'Обработка заняла слишком много времени. Минуты не списаны.';

  @override
  String get errorTranscription =>
      'Не удалось расшифровать аудио. Повторите попытку чуть позже.';

  @override
  String get errorInvalidResponse => 'Результат неполный и не был сохранён.';

  @override
  String get errorQuotaExhausted =>
      'Недостаточно минут для обработки этого аудио.';

  @override
  String get errorSubscriptionUnavailable => 'Подписки сейчас недоступны.';

  @override
  String get errorSubscriptionSyncPending =>
      'Покупка подтверждена, Pro ещё синхронизируется. Не закрывайте VoiceBrief и повторите попытку чуть позже.';

  @override
  String get errorPurchaseCanceled => 'Покупка отменена.';

  @override
  String get errorPurchaseFailed =>
      'Покупка не завершена. VoiceBrief не списал деньги.';

  @override
  String get errorRestoreFailed =>
      'Не удалось восстановить покупки. Попробуйте позже.';

  @override
  String get errorServiceUnavailable =>
      'VoiceBrief временно недоступен. Попробуйте чуть позже.';

  @override
  String get errorShareHandoff =>
      'Не удалось безопасно импортировать переданное аудио.';

  @override
  String get errorConfiguration =>
      'Эта функция ещё требует настройки рабочего окружения.';

  @override
  String get errorUnknown => 'Произошла ошибка. Повторите попытку.';
}
