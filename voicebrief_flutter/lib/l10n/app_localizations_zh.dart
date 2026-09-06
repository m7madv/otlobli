// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get appLanguage => '应用语言';

  @override
  String get followSystemLanguage => '使用设备语言';

  @override
  String get home => '首页';

  @override
  String get history => '历史记录';

  @override
  String get settings => '设置';

  @override
  String get cancel => '取消';

  @override
  String get tryAgain => '重试';

  @override
  String get close => '关闭';

  @override
  String get continueLabel => '继续';

  @override
  String get signIn => '登录';

  @override
  String get signOut => '退出登录';

  @override
  String get delete => '删除';

  @override
  String get copy => '复制';

  @override
  String get edit => '编辑';

  @override
  String get copied => '已复制';

  @override
  String get complete => '完成';

  @override
  String get unavailable => '不可用';

  @override
  String get replaceAudio => '更换音频';

  @override
  String get removeAudio => '移除音频';

  @override
  String get playAudio => '播放音频';

  @override
  String get pauseAudio => '暂停音频';

  @override
  String get audioWaveform => '音频波形';

  @override
  String get audioWaveformLoading => '正在绘制真实音频波形…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return '音频播放：$elapsed，共 $duration';
  }

  @override
  String copySection(String title) {
    return '复制$title';
  }

  @override
  String get screenUnavailable => '此页面不可用。';

  @override
  String get goPro => '升级到 Pro';

  @override
  String get homeHeadline => '将语音消息化为清晰的行动';

  @override
  String get homeSupporting => '从 WhatsApp 分享、选择音频文件，或在此录音。';

  @override
  String get shareFromWhatsApp => '来自 WhatsApp';

  @override
  String get shareFromWhatsAppSteps => '长按语音消息，点按“分享”，然后选择 VoiceBrief';

  @override
  String get chooseVoiceNote => '选择语音消息';

  @override
  String get recordInstead => '直接录音';

  @override
  String get recentBriefs => '最近的摘要';

  @override
  String get viewAll => '查看全部';

  @override
  String get noBriefsYet => '暂无摘要';

  @override
  String get noBriefsMessage => '选择或录制音频，创建第一份摘要。';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return '免费分钟剩余 $remaining，共 $total';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return 'Pro 分钟剩余 $remaining，共 $total';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return '剩余 $remaining 分钟，共 $total 分钟';
  }

  @override
  String get authHeadline => '让每条语音消息更有价值';

  @override
  String get authSupporting => '登录以保护您的分钟额度，并让已保存的摘要仅对您的账户可见。';

  @override
  String get demoServicesActive => '演示服务已启用。不会使用外部账户或付费服务。';

  @override
  String get providerSignInTitle => '快速、安全地登录';

  @override
  String get providerSignInDescription =>
      '选择 Apple 或 Google。VoiceBrief 无法查看您的账户密码。';

  @override
  String get continueWithApple => '通过 Apple 继续';

  @override
  String get continueWithGoogle => '通过 Google 继续';

  @override
  String get byContinuingPrefix => '继续即表示您同意';

  @override
  String get terms => '条款';

  @override
  String get andConjunction => '及';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get errorIdentityProviderUnavailable => '此登录方式暂不可用，请尝试其他方式。';

  @override
  String get onboardingSignIn => '登录';

  @override
  String get onboardingTitleOne => '从语音到清晰要点';

  @override
  String get onboardingBodyOne => '分享、选择或录制音频，获取转写、摘要、任务、日期及回复建议。';

  @override
  String get onboardingTitleTwo => '您的音频保持私密';

  @override
  String get onboardingBodyTwo => '音频经过安全处理后会自动删除。您可以选择保存哪些文字结果。';

  @override
  String get getStarted => '开始使用';

  @override
  String get recordAudio => '录制音频';

  @override
  String get discardRecordingTitle => '放弃录音？';

  @override
  String get discardRecordingMessage => '当前录音将被删除。';

  @override
  String get discard => '放弃';

  @override
  String get recordingPaused => '录音已暂停';

  @override
  String get recording => '正在录音';

  @override
  String get tapRecordReady => '准备好后点按录音';

  @override
  String get startRecording => '开始录音';

  @override
  String get resume => '继续';

  @override
  String get pause => '暂停';

  @override
  String get stop => '停止';

  @override
  String get cancelRecording => '取消录音';

  @override
  String get microphoneJustInTime => '仅在点按录音时才会请求麦克风权限。';

  @override
  String get recordingSaveFailed => '无法保存录音。';

  @override
  String get liveWaveformIdle => '开始录音后会显示真实波形。';

  @override
  String get liveWaveformStarting => '正在读取实际麦克风音量…';

  @override
  String get liveWaveformActive => '此波形随您的实时声音变化。';

  @override
  String get historyLocalOnly => '仅保存在此设备';

  @override
  String get searchBriefs => '搜索摘要';

  @override
  String get nothingSaved => '暂无已保存内容';

  @override
  String get nothingSavedMessage => '保存结果后即可在此查看。';

  @override
  String get noMatchingBriefs => '没有匹配的摘要';

  @override
  String get noMatchingBriefsMessage => '请尝试其他标题或摘要关键词。';

  @override
  String get briefDeleted => '摘要已删除';

  @override
  String get undo => '撤销';

  @override
  String get voiceNoteReady => '语音消息已就绪';

  @override
  String get reviewAudio => '检查音频';

  @override
  String get createMyBrief => '生成我的摘要';

  @override
  String get secureAiProcessing => '安全的 AI 处理 · 处理后删除临时音频';

  @override
  String get secureAiProcessingSemantics => '音频将安全发送以供 AI 处理，并在处理后从临时存储中删除。';

  @override
  String get trimAudio => '裁剪音频';

  @override
  String get trimAudioHelp => '拖动两端选择要总结的片段。继续前可以试听。';

  @override
  String selectedAudioRange(String start, String end) {
    return '已选片段：$start — $end';
  }

  @override
  String get useFullAudio => '使用完整音频';

  @override
  String get createBriefFromSelection => '总结此片段';

  @override
  String get trimmingAudio => '正在裁剪音频…';

  @override
  String get audioTrimmed => '音频已裁剪，仅保留所选片段。';

  @override
  String get sharedAudioImporting => '正在准备分享的语音消息…';

  @override
  String get customizeOutput => '自定义输出内容';

  @override
  String get defaultOutput => '自动包含摘要和逐字转写';

  @override
  String get fullTranscript => '逐字转写';

  @override
  String get fullTranscriptDescription => '完整保留录音中的原话，方便查看、搜索或复制。';

  @override
  String get summaryAndKeyPoints => '摘要与要点';

  @override
  String get actionItemsAndDates => '任务与日期';

  @override
  String get suggestedReplies => '回复建议';

  @override
  String get translateSummaryEnglish => '将摘要翻译成英语';

  @override
  String get sharedAudioReadySemantics => '分享的语音消息已导入并就绪。';

  @override
  String get sharedAudioReady => '语音消息已导入，只需再点一下。';

  @override
  String get creatingBrief => '正在生成摘要';

  @override
  String get processingFallbackError => '处理未能完成。服务器上的安全副本已删除，您的私密本地副本可用于重试。';

  @override
  String get processingKeepOpen =>
      '请保持 VoiceBrief 打开，直到安全上传完成。所需时间取决于录音长度和网络连接。';

  @override
  String get preparingAudio => '正在准备音频';

  @override
  String get uploadingSecurely => '正在安全上传';

  @override
  String get transcribing => '正在转写';

  @override
  String get creatingYourBrief => '正在生成摘要';

  @override
  String get finalizing => '正在完成';

  @override
  String get brief => '摘要';

  @override
  String get briefUnavailable => '此摘要已不可用。';

  @override
  String get copyAll => '复制全部';

  @override
  String get shareResult => '分享结果';

  @override
  String get savedLocally => '已保存在本机';

  @override
  String get notSaved => '未保存';

  @override
  String get saved => '已保存';

  @override
  String get saveResult => '保存结果';

  @override
  String get deleteResult => '删除结果';

  @override
  String get deleteBriefTitle => '删除此摘要？';

  @override
  String get deleteBriefMessage => '已保存的文字将从此设备删除。';

  @override
  String get keyPoints => '要点';

  @override
  String get actionItems => '任务';

  @override
  String get importantDates => '重要日期';

  @override
  String get addToCalendar => '添加到日历';

  @override
  String get setReminder => '设置提醒';

  @override
  String get reminderSet => '已设置 VoiceBrief 闹钟。';

  @override
  String get reminderUnavailable => '无法设置提醒，请启用 VoiceBrief 通知后重试。';

  @override
  String get reminderMustBeFuture => '请选择未来的提醒时间。';

  @override
  String get chooseAlarmTone => '闹钟声音';

  @override
  String get chooseAlarmToneDescription => '使用 iPhone 原始铃声，或选择自己的声音。';

  @override
  String get previewTone => '试听铃声';

  @override
  String get confirmAlarm => '使用此声音';

  @override
  String get alarmsAndReminders => '闹钟与提醒';

  @override
  String get voiceBriefAlarms => '闹钟';

  @override
  String get voiceBriefAlarmsDescription => '查看或取消已安排的闹钟。';

  @override
  String get noScheduledAlarms => '暂无即将响起的闹钟';

  @override
  String get noScheduledAlarmsMessage => '从摘要中的日期设置闹钟后，它会显示在此处。';

  @override
  String get alarmsUnavailable => '暂时无法加载 VoiceBrief 闹钟。';

  @override
  String get alarmScheduled => '已安排';

  @override
  String alarmToneLabel(Object tone) {
    return '声音：$tone';
  }

  @override
  String get alarmSoundTitle => '闹钟声音';

  @override
  String get systemAlarmSound => 'iPhone 默认声音';

  @override
  String get systemAlarmSoundDescription => '系统提供的原始声音。';

  @override
  String get customAlarmSound => '自定义声音';

  @override
  String get changeAlarmSound => '更改';

  @override
  String get addCustomAlarmSound => '添加自己的声音';

  @override
  String get importAudioSound => '选择音频文件';

  @override
  String get importVideoSound => '从视频提取声音';

  @override
  String get soundLimitNotice => '将保存前 29 秒，并转换为适用于闹钟的格式。';

  @override
  String get preparingAlarmSound => '正在准备声音…';

  @override
  String get soundImportFailed => '无法使用此文件，请选择包含音频的文件。';

  @override
  String get importedSoundReady => '声音已就绪。';

  @override
  String get useThisSound => '使用此声音';

  @override
  String get upcomingAlarms => '即将响起的闹钟';

  @override
  String get loadingAlarms => '正在加载闹钟…';

  @override
  String get cancelAlarm => '取消闹钟';

  @override
  String get cancelAlarmTitle => '取消此闹钟？';

  @override
  String cancelAlarmMessage(Object title) {
    return '取消后，闹钟“$title”将不再响起。';
  }

  @override
  String get alarmCancelled => '闹钟已取消。';

  @override
  String get alarmCancelFailed => '无法取消闹钟，请重试。';

  @override
  String get refresh => '刷新';

  @override
  String reminderNotificationTitle(String title) {
    return '提醒：$title';
  }

  @override
  String reminderNotificationBody(String phrase) {
    return '来自 VoiceBrief：“$phrase”';
  }

  @override
  String ownerLabel(String owner) {
    return '负责人：$owner';
  }

  @override
  String heardLabel(String phrase) {
    return '原话：“$phrase”';
  }

  @override
  String get needsConfirmation => '需要确认';

  @override
  String get taskDeadline => '任务截止时间';

  @override
  String get shortTone => '简短';

  @override
  String get friendlyTone => '友好';

  @override
  String get professionalTone => '专业';

  @override
  String get shortReply => '简短回复';

  @override
  String get friendlyReply => '友好回复';

  @override
  String get professionalReply => '专业回复';

  @override
  String get replyText => '回复内容';

  @override
  String get shareEditedReply => '分享编辑后的回复';

  @override
  String get copyEditedReply => '复制编辑后的回复';

  @override
  String confirmDatePhrase(String phrase) {
    return '确认“$phrase”';
  }

  @override
  String get confirmEventTime => '确认事件时间';

  @override
  String get openCalendarTitle => '打开日历？';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'VoiceBrief 将“$phrase”理解为 $date。保存前，日历会请您确认。';
  }

  @override
  String get openCalendar => '打开日历';

  @override
  String calendarDescription(String phrase) {
    return '通过 VoiceBrief 创建，已确认：“$phrase”';
  }

  @override
  String get calendarOpened => '已打开日历编辑器。';

  @override
  String datesFound(int count) {
    return '找到 $count 个日期 · 设置提醒或添加到日历';
  }

  @override
  String datesFoundSemantics(int count) {
    return '找到 $count 个日期。请先检查，再设置提醒或添加到系统日历。';
  }

  @override
  String get account => '账户';

  @override
  String get notSignedIn => '未登录';

  @override
  String get verifiedAccount => '已验证账户';

  @override
  String get emailVerificationRequired => '需要验证邮箱';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => '免费方案';

  @override
  String minutesRemaining(int count) {
    return '剩余 $count 分钟';
  }

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get purchasesRestored => '购买已恢复。';

  @override
  String get noPurchasesRestored => '未恢复任何购买。';

  @override
  String get manageSubscription => '管理订阅';

  @override
  String get appearance => '外观';

  @override
  String get systemTheme => '跟随系统';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get privacyAndData => '隐私与数据';

  @override
  String get audioHandlingTitle => '音频临时处理；文字可选择保存';

  @override
  String get audioHandlingDescription =>
      '音频仅临时用于转写，随后自动删除。只有您选择保存的摘要和转写会留在历史记录中。';

  @override
  String get exportSavedText => '分享已保存文字';

  @override
  String get exportSubject => 'VoiceBrief 导出';

  @override
  String get exportSavedTextDescription =>
      '生成包含摘要、要点、任务、日期、回复和转写的 TXT 文件，并打开分享菜单。绝不包含音频。';

  @override
  String get exportSavedTextFailed => '无法创建用于分享的文字文件。';

  @override
  String get noSavedTextOnDevice => '此设备上没有已保存的文字。';

  @override
  String get clearLocalHistory => '删除已保存文字';

  @override
  String get clearSavedTextDescription => '仅删除此设备上的摘要和转写。此处不保存录音。';

  @override
  String get clearHistoryTitle => '删除已保存文字？';

  @override
  String get clearHistoryMessage => '此设备上的全部摘要和转写将被永久删除。音频文件已在处理后删除。';

  @override
  String get clearHistory => '删除文字';

  @override
  String get savedTextCleared => '已删除保存的文字。';

  @override
  String get clearSavedTextFailed => '无法删除文字，请重试。';

  @override
  String get termsOfService => '服务条款';

  @override
  String get support => '支持';

  @override
  String get contactSupport => '联系支持';

  @override
  String get appVersion => '应用版本';

  @override
  String get deleteAccountTitle => '删除账户？';

  @override
  String get deleteAccountMessage => '这将删除服务器账户和本地历史记录。商店订阅将继续，直到您在商店账户中取消。';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get active => '已启用';

  @override
  String get proHeadline => '将每条语音消息转为可执行的摘要';

  @override
  String get accurateTranscripts => '准确转写';

  @override
  String get instantSummaries => '即时摘要';

  @override
  String get threeReplyTones => '三种可直接发送的回复风格';

  @override
  String get loadingStorePrices => '正在加载商店价格…';

  @override
  String get subscriptionOptionsUnavailable => '订阅选项不可用。正式版本不会显示备用价格。';

  @override
  String get yearly => '按年';

  @override
  String get monthly => '按月';

  @override
  String get bestValue => '超值之选';

  @override
  String get proActive => 'Pro 已启用';

  @override
  String get subscriptionRenewalNotice =>
      '除非在当前周期结束至少 24 小时前取消，否则订阅将自动续订。您可随时在商店账户中管理或取消。';

  @override
  String get privacy => '隐私';

  @override
  String get proActivatedToast => 'VoiceBrief Pro 已启用。';

  @override
  String get noActivePurchases => '未找到有效购买。';

  @override
  String get errorNoInternet => '您似乎处于离线状态，请检查网络后重试。';

  @override
  String get errorAuthentication => '无法登录，请检查您的信息后重试。';

  @override
  String get errorProviderCanceled => '登录已取消。';

  @override
  String get errorEmailVerification => '请打开邮箱中的验证链接，然后返回 VoiceBrief。';

  @override
  String get errorUnsupportedAudio => '不支持此音频格式。';

  @override
  String get errorFileTooLarge => '此音频文件超出当前上传大小限制。';

  @override
  String get errorUnreadableAudio => '无法读取此音频，请尝试其他文件。';

  @override
  String get errorAudioEditing => '无法在此设备上裁剪此音频，原文件未更改。';

  @override
  String get errorMicrophoneDenied => '仅在选择录音时才需要麦克风权限。';

  @override
  String get errorUploadInterrupted => '安全上传已中断，您可以放心重试。';

  @override
  String get errorProcessingTimeout => '处理超时，未扣除您的分钟额度。';

  @override
  String get errorTranscription => '无法转写音频，请稍后重试。';

  @override
  String get errorInvalidResponse => '结果不完整，未予保存。';

  @override
  String get errorQuotaExhausted => '您的分钟额度不足以处理此音频。';

  @override
  String get errorSubscriptionUnavailable => '订阅选项暂不可用。';

  @override
  String get errorSubscriptionSyncPending =>
      '购买已确认，Pro 仍在同步中。请保持 VoiceBrief 打开，稍后重试。';

  @override
  String get errorPurchaseCanceled => '购买已取消。';

  @override
  String get errorPurchaseFailed => '购买未完成，VoiceBrief 未向您收费。';

  @override
  String get errorRestoreFailed => '无法恢复购买，请稍后重试。';

  @override
  String get errorServiceUnavailable => 'VoiceBrief 暂不可用，请稍后重试。';

  @override
  String get errorShareHandoff => '无法安全导入分享的音频。';

  @override
  String get errorConfiguration => '此功能仍需要完成正式环境配置。';

  @override
  String get errorUnknown => '出现问题，请重试。';
}
