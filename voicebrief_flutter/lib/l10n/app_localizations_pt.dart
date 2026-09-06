// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get appLanguage => 'Idioma do aplicativo';

  @override
  String get followSystemLanguage => 'Usar idioma do dispositivo';

  @override
  String get home => 'Início';

  @override
  String get history => 'Histórico';

  @override
  String get settings => 'Configurações';

  @override
  String get cancel => 'Cancelar';

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get close => 'Fechar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get delete => 'Excluir';

  @override
  String get copy => 'Copiar';

  @override
  String get edit => 'Editar';

  @override
  String get copied => 'Copiado';

  @override
  String get complete => 'Concluído';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get replaceAudio => 'Substituir áudio';

  @override
  String get removeAudio => 'Remover áudio';

  @override
  String get playAudio => 'Reproduzir áudio';

  @override
  String get pauseAudio => 'Pausar áudio';

  @override
  String get audioWaveform => 'Forma de onda';

  @override
  String get audioWaveformLoading => 'Desenhando a onda real do áudio…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'Reprodução: $elapsed de $duration';
  }

  @override
  String copySection(String title) {
    return 'Copiar $title';
  }

  @override
  String get screenUnavailable => 'Esta tela está indisponível.';

  @override
  String get goPro => 'Assinar Pro';

  @override
  String get homeHeadline =>
      'Transforme mensagens de voz em próximos passos claros';

  @override
  String get homeSupporting =>
      'Compartilhe pelo WhatsApp, escolha um áudio ou grave aqui.';

  @override
  String get shareFromWhatsApp => 'Do WhatsApp';

  @override
  String get shareFromWhatsAppSteps =>
      'Segure a mensagem de voz, toque em Compartilhar e depois em VoiceBrief';

  @override
  String get chooseVoiceNote => 'Escolher mensagem de voz';

  @override
  String get recordInstead => 'Gravar agora';

  @override
  String get recentBriefs => 'Resumos recentes';

  @override
  String get viewAll => 'Ver todos';

  @override
  String get noBriefsYet => 'Ainda não há resumos';

  @override
  String get noBriefsMessage =>
      'Escolha ou grave um áudio para criar seu primeiro resumo.';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return 'Restam $remaining de $total minutos grátis';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return 'Restam $remaining de $total minutos Pro';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return 'Restam $remaining de $total minutos';
  }

  @override
  String get authHeadline => 'Aproveite cada mensagem de voz';

  @override
  String get authSupporting =>
      'Entre para proteger seus minutos e manter os resumos privados na sua conta.';

  @override
  String get demoServicesActive =>
      'Modo de demonstração ativo. Nenhuma conta externa ou serviço pago é usado.';

  @override
  String get providerSignInTitle => 'Acesso rápido e seguro';

  @override
  String get providerSignInDescription =>
      'Escolha Apple ou Google. O VoiceBrief nunca vê sua senha.';

  @override
  String get continueWithApple => 'Continuar com Apple';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get byContinuingPrefix => 'Ao continuar, você aceita os ';

  @override
  String get terms => 'Termos';

  @override
  String get andConjunction => ' e a ';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get errorIdentityProviderUnavailable =>
      'Esta forma de acesso está indisponível. Tente outra.';

  @override
  String get onboardingSignIn => 'Entrar';

  @override
  String get onboardingTitleOne => 'Da voz à clareza';

  @override
  String get onboardingBodyOne =>
      'Compartilhe, escolha ou grave um áudio. Receba transcrição, resumo, tarefas, datas e sugestões de respostas.';

  @override
  String get onboardingTitleTwo => 'Seu áudio continua privado';

  @override
  String get onboardingBodyTwo =>
      'O áudio é processado com segurança e excluído automaticamente. Você escolhe quais textos salvar.';

  @override
  String get getStarted => 'Começar';

  @override
  String get recordAudio => 'Gravar áudio';

  @override
  String get discardRecordingTitle => 'Descartar gravação?';

  @override
  String get discardRecordingMessage => 'A gravação atual será excluída.';

  @override
  String get discard => 'Descartar';

  @override
  String get recordingPaused => 'Gravação pausada';

  @override
  String get recording => 'Gravando';

  @override
  String get tapRecordReady => 'Toque em gravar quando estiver pronto';

  @override
  String get startRecording => 'Iniciar gravação';

  @override
  String get resume => 'Retomar';

  @override
  String get pause => 'Pausar';

  @override
  String get stop => 'Parar';

  @override
  String get cancelRecording => 'Cancelar gravação';

  @override
  String get microphoneJustInTime =>
      'O acesso ao microfone só é solicitado ao tocar em gravar.';

  @override
  String get recordingSaveFailed => 'Não foi possível salvar a gravação.';

  @override
  String get liveWaveformIdle => 'A onda real aparece ao iniciar a gravação.';

  @override
  String get liveWaveformStarting => 'Lendo o nível real do microfone…';

  @override
  String get liveWaveformActive => 'Esta onda acompanha sua voz ao vivo.';

  @override
  String get historyLocalOnly => 'Salvo localmente neste dispositivo';

  @override
  String get searchBriefs => 'Buscar resumos';

  @override
  String get nothingSaved => 'Nenhum texto salvo';

  @override
  String get nothingSavedMessage => 'Salve um resultado para vê-lo aqui.';

  @override
  String get noMatchingBriefs => 'Nenhum resumo encontrado';

  @override
  String get noMatchingBriefsMessage =>
      'Tente outra palavra do título ou resumo.';

  @override
  String get briefDeleted => 'Resumo excluído';

  @override
  String get undo => 'Desfazer';

  @override
  String get voiceNoteReady => 'Mensagem de voz pronta';

  @override
  String get reviewAudio => 'Revisar áudio';

  @override
  String get createMyBrief => 'Criar meu resumo';

  @override
  String get secureAiProcessing =>
      'Processamento seguro com IA · áudio temporário excluído após o processamento';

  @override
  String get secureAiProcessingSemantics =>
      'O áudio é enviado com segurança para processamento com IA e removido do armazenamento temporário ao terminar.';

  @override
  String get trimAudio => 'Recortar áudio';

  @override
  String get trimAudioHelp =>
      'Arraste as duas extremidades para escolher o trecho. Você pode ouvi-lo antes de continuar.';

  @override
  String selectedAudioRange(String start, String end) {
    return 'Trecho selecionado: $start — $end';
  }

  @override
  String get useFullAudio => 'Usar áudio completo';

  @override
  String get createBriefFromSelection => 'Resumir este trecho';

  @override
  String get trimmingAudio => 'Recortando áudio…';

  @override
  String get audioTrimmed =>
      'Áudio recortado. Apenas o trecho selecionado foi mantido.';

  @override
  String get sharedAudioImporting =>
      'Preparando a mensagem de voz compartilhada…';

  @override
  String get customizeOutput => 'Personalizar resultado';

  @override
  String get defaultOutput =>
      'O resumo e a transcrição literal são incluídos automaticamente';

  @override
  String get fullTranscript => 'Transcrição literal';

  @override
  String get fullTranscriptDescription =>
      'Tudo o que foi dito, mantido como foi falado, para revisar, buscar ou copiar.';

  @override
  String get summaryAndKeyPoints => 'Resumo e pontos principais';

  @override
  String get actionItemsAndDates => 'Tarefas e datas';

  @override
  String get suggestedReplies => 'Sugestões de respostas';

  @override
  String get translateSummaryEnglish => 'Traduzir resumo para inglês';

  @override
  String get sharedAudioReadySemantics =>
      'Mensagem de voz compartilhada importada e pronta.';

  @override
  String get sharedAudioReady => 'Mensagem importada. Falta só um toque.';

  @override
  String get creatingBrief => 'Criando seu resumo';

  @override
  String get processingFallbackError =>
      'Não foi possível concluir. A cópia segura no servidor foi excluída e sua cópia local privada está pronta para tentar novamente.';

  @override
  String get processingKeepOpen =>
      'Mantenha o VoiceBrief aberto até terminar o envio seguro. O tempo depende da duração do áudio e da conexão.';

  @override
  String get preparingAudio => 'Preparando áudio';

  @override
  String get uploadingSecurely => 'Enviando com segurança';

  @override
  String get transcribing => 'Transcrevendo';

  @override
  String get creatingYourBrief => 'Criando seu resumo';

  @override
  String get finalizing => 'Finalizando';

  @override
  String get brief => 'Resumo';

  @override
  String get briefUnavailable => 'Este resumo não está mais disponível.';

  @override
  String get copyAll => 'Copiar tudo';

  @override
  String get shareResult => 'Compartilhar resultado';

  @override
  String get savedLocally => 'Salvo localmente';

  @override
  String get notSaved => 'Não salvo';

  @override
  String get saved => 'Salvo';

  @override
  String get saveResult => 'Salvar resultado';

  @override
  String get deleteResult => 'Excluir resultado';

  @override
  String get deleteBriefTitle => 'Excluir este resumo?';

  @override
  String get deleteBriefMessage =>
      'O texto salvo será removido deste dispositivo.';

  @override
  String get keyPoints => 'Pontos principais';

  @override
  String get actionItems => 'Tarefas';

  @override
  String get importantDates => 'Datas importantes';

  @override
  String get addToCalendar => 'Adicionar ao calendário';

  @override
  String get setReminder => 'Definir lembrete';

  @override
  String get reminderSet => 'Alarme do VoiceBrief definido.';

  @override
  String get reminderUnavailable =>
      'Não foi possível definir o lembrete. Ative as notificações do VoiceBrief e tente novamente.';

  @override
  String get reminderMustBeFuture =>
      'Escolha um horário futuro para o lembrete.';

  @override
  String get chooseAlarmTone => 'Som do alarme';

  @override
  String get chooseAlarmToneDescription =>
      'Use o som original do iPhone ou escolha o seu.';

  @override
  String get previewTone => 'Ouvir som';

  @override
  String get confirmAlarm => 'Usar este som';

  @override
  String get alarmsAndReminders => 'Alarmes e lembretes';

  @override
  String get voiceBriefAlarms => 'Alarmes';

  @override
  String get voiceBriefAlarmsDescription =>
      'Veja ou cancele seus alarmes agendados.';

  @override
  String get noScheduledAlarms => 'Nenhum alarme próximo';

  @override
  String get noScheduledAlarmsMessage =>
      'Defina um alarme a partir de uma data de um resumo para vê-lo aqui.';

  @override
  String get alarmsUnavailable =>
      'Não foi possível carregar os alarmes do VoiceBrief.';

  @override
  String get alarmScheduled => 'Agendado';

  @override
  String alarmToneLabel(Object tone) {
    return 'Som: $tone';
  }

  @override
  String get alarmSoundTitle => 'Som do alarme';

  @override
  String get systemAlarmSound => 'Som padrão do iPhone';

  @override
  String get systemAlarmSoundDescription => 'O som original do sistema.';

  @override
  String get customAlarmSound => 'Som personalizado';

  @override
  String get changeAlarmSound => 'Alterar';

  @override
  String get addCustomAlarmSound => 'Adicionar seu som';

  @override
  String get importAudioSound => 'Escolher arquivo de áudio';

  @override
  String get importVideoSound => 'Extrair som de um vídeo';

  @override
  String get soundLimitNotice =>
      'Os primeiros 29 segundos são salvos em formato compatível com alarmes.';

  @override
  String get preparingAlarmSound => 'Preparando som…';

  @override
  String get soundImportFailed =>
      'Não foi possível usar este arquivo. Escolha um arquivo com áudio.';

  @override
  String get importedSoundReady => 'Som pronto.';

  @override
  String get useThisSound => 'Usar este som';

  @override
  String get upcomingAlarms => 'Próximos alarmes';

  @override
  String get loadingAlarms => 'Carregando alarmes…';

  @override
  String get cancelAlarm => 'Cancelar alarme';

  @override
  String get cancelAlarmTitle => 'Cancelar este alarme?';

  @override
  String cancelAlarmMessage(Object title) {
    return 'O alarme “$title” não tocará após ser cancelado.';
  }

  @override
  String get alarmCancelled => 'Alarme cancelado.';

  @override
  String get alarmCancelFailed =>
      'Não foi possível cancelar o alarme. Tente novamente.';

  @override
  String get refresh => 'Atualizar';

  @override
  String reminderNotificationTitle(String title) {
    return 'Lembrete: $title';
  }

  @override
  String reminderNotificationBody(String phrase) {
    return 'Do VoiceBrief: “$phrase”';
  }

  @override
  String ownerLabel(String owner) {
    return 'Responsável: $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'Ouvido: “$phrase”';
  }

  @override
  String get needsConfirmation => 'Requer confirmação';

  @override
  String get taskDeadline => 'Prazo da tarefa';

  @override
  String get shortTone => 'Curto';

  @override
  String get friendlyTone => 'Amigável';

  @override
  String get professionalTone => 'Profissional';

  @override
  String get shortReply => 'Resposta curta';

  @override
  String get friendlyReply => 'Resposta amigável';

  @override
  String get professionalReply => 'Resposta profissional';

  @override
  String get replyText => 'Texto da resposta';

  @override
  String get shareEditedReply => 'Compartilhar resposta editada';

  @override
  String get copyEditedReply => 'Copiar resposta editada';

  @override
  String confirmDatePhrase(String phrase) {
    return 'Confirmar “$phrase”';
  }

  @override
  String get confirmEventTime => 'Confirmar horário do evento';

  @override
  String get openCalendarTitle => 'Abrir calendário?';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'O VoiceBrief interpretou “$phrase” como $date. O calendário pedirá confirmação antes de salvar.';
  }

  @override
  String get openCalendar => 'Abrir calendário';

  @override
  String calendarDescription(String phrase) {
    return 'Criado pelo VoiceBrief após confirmar: “$phrase”';
  }

  @override
  String get calendarOpened => 'Editor do calendário aberto.';

  @override
  String datesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count datas encontradas · defina lembretes ou adicione ao calendário',
      one: '1 data encontrada · defina um lembrete ou adicione ao calendário',
    );
    return '$_temp0';
  }

  @override
  String datesFoundSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count datas encontradas. Revise e defina lembretes ou adicione ao calendário do sistema.',
      one:
          '1 data encontrada. Revise e defina um lembrete ou adicione ao calendário do sistema.',
    );
    return '$_temp0';
  }

  @override
  String get account => 'Conta';

  @override
  String get notSignedIn => 'Não conectado';

  @override
  String get verifiedAccount => 'Conta verificada';

  @override
  String get emailVerificationRequired => 'Verificação de e-mail necessária';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'Plano gratuito';

  @override
  String minutesRemaining(int count) {
    return '$count minutos restantes';
  }

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get purchasesRestored => 'Compras restauradas.';

  @override
  String get noPurchasesRestored => 'Nenhuma compra foi restaurada.';

  @override
  String get manageSubscription => 'Gerenciar assinatura';

  @override
  String get appearance => 'Aparência';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Escuro';

  @override
  String get privacyAndData => 'Privacidade e dados';

  @override
  String get audioHandlingTitle => 'Áudio temporário; salvar texto é opcional';

  @override
  String get audioHandlingDescription =>
      'O áudio é usado temporariamente na transcrição e excluído automaticamente. Só os resumos e transcrições que você salvar ficam no histórico.';

  @override
  String get exportSavedText => 'Compartilhar textos salvos';

  @override
  String get exportSubject => 'Exportação do VoiceBrief';

  @override
  String get exportSavedTextDescription =>
      'Cria um arquivo TXT com resumos, pontos principais, tarefas, datas, respostas e transcrições, e abre o compartilhamento. Nunca inclui áudio.';

  @override
  String get exportSavedTextFailed =>
      'Não foi possível criar o arquivo de texto para compartilhar.';

  @override
  String get noSavedTextOnDevice => 'Não há textos salvos neste dispositivo.';

  @override
  String get clearLocalHistory => 'Excluir textos salvos';

  @override
  String get clearSavedTextDescription =>
      'Exclui resumos e transcrições apenas deste dispositivo. Nenhuma gravação de áudio é guardada aqui.';

  @override
  String get clearHistoryTitle => 'Excluir textos salvos?';

  @override
  String get clearHistoryMessage =>
      'Todos os resumos e transcrições deste dispositivo serão excluídos permanentemente. Os áudios já são excluídos após o processamento.';

  @override
  String get clearHistory => 'Excluir textos';

  @override
  String get savedTextCleared => 'Textos salvos excluídos.';

  @override
  String get clearSavedTextFailed =>
      'Não foi possível excluir os textos. Tente novamente.';

  @override
  String get termsOfService => 'Termos de serviço';

  @override
  String get support => 'Suporte';

  @override
  String get contactSupport => 'Falar com o suporte';

  @override
  String get appVersion => 'Versão do aplicativo';

  @override
  String get deleteAccountTitle => 'Excluir conta?';

  @override
  String get deleteAccountMessage =>
      'Sua conta no servidor e o histórico local serão excluídos. As assinaturas continuam até você cancelá-las na conta da loja.';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get active => 'Ativo';

  @override
  String get proHeadline =>
      'Transforme cada mensagem de voz em um resumo com ações';

  @override
  String get accurateTranscripts => 'Transcrições precisas';

  @override
  String get instantSummaries => 'Resumos instantâneos';

  @override
  String get threeReplyTones => 'Três estilos de resposta prontos para enviar';

  @override
  String get loadingStorePrices => 'Carregando preços da loja…';

  @override
  String get subscriptionOptionsUnavailable =>
      'As assinaturas estão indisponíveis. Nenhum preço alternativo é exibido em produção.';

  @override
  String get yearly => 'Anual';

  @override
  String get monthly => 'Mensal';

  @override
  String get bestValue => 'MELHOR OPÇÃO';

  @override
  String get proActive => 'Pro está ativo';

  @override
  String get subscriptionRenewalNotice =>
      'As assinaturas se renovam automaticamente, salvo cancelamento pelo menos 24 horas antes do fim do período. Gerencie ou cancele a qualquer momento na sua conta da loja.';

  @override
  String get privacy => 'Privacidade';

  @override
  String get proActivatedToast => 'VoiceBrief Pro está ativo.';

  @override
  String get noActivePurchases => 'Nenhuma compra ativa encontrada.';

  @override
  String get errorNoInternet =>
      'Você parece estar sem internet. Verifique a conexão e tente novamente.';

  @override
  String get errorAuthentication =>
      'Não foi possível entrar. Verifique seus dados e tente novamente.';

  @override
  String get errorProviderCanceled => 'Login cancelado.';

  @override
  String get errorEmailVerification =>
      'Abra o link de verificação no seu e-mail e volte ao VoiceBrief.';

  @override
  String get errorUnsupportedAudio => 'Este formato de áudio não é compatível.';

  @override
  String get errorFileTooLarge => 'O áudio excede o limite atual de envio.';

  @override
  String get errorUnreadableAudio =>
      'Não foi possível ler este áudio. Tente outro arquivo.';

  @override
  String get errorAudioEditing =>
      'Não foi possível recortar neste dispositivo. O original não foi alterado.';

  @override
  String get errorMicrophoneDenied =>
      'O microfone só é necessário quando você escolhe gravar.';

  @override
  String get errorUploadInterrupted =>
      'O envio seguro foi interrompido. Você pode tentar novamente com segurança.';

  @override
  String get errorProcessingTimeout =>
      'O processamento demorou demais. Seus minutos não foram descontados.';

  @override
  String get errorTranscription =>
      'Não foi possível transcrever. Tente novamente em instantes.';

  @override
  String get errorInvalidResponse =>
      'O resultado estava incompleto e não foi salvo.';

  @override
  String get errorQuotaExhausted =>
      'Você não tem minutos suficientes para este áudio.';

  @override
  String get errorSubscriptionUnavailable =>
      'As assinaturas estão indisponíveis no momento.';

  @override
  String get errorSubscriptionSyncPending =>
      'Sua compra foi confirmada e Pro ainda está sincronizando. Mantenha o VoiceBrief aberto e tente novamente em breve.';

  @override
  String get errorPurchaseCanceled => 'Compra cancelada.';

  @override
  String get errorPurchaseFailed =>
      'A compra não foi concluída. O VoiceBrief não fez nenhuma cobrança.';

  @override
  String get errorRestoreFailed =>
      'Não foi possível restaurar as compras. Tente mais tarde.';

  @override
  String get errorServiceUnavailable =>
      'O VoiceBrief está temporariamente indisponível. Tente novamente em breve.';

  @override
  String get errorShareHandoff =>
      'Não foi possível importar o áudio compartilhado com segurança.';

  @override
  String get errorConfiguration =>
      'Esta função ainda precisa da configuração de produção.';

  @override
  String get errorUnknown => 'Algo deu errado. Tente novamente.';
}
