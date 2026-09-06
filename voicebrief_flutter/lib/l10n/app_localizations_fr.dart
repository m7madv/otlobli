// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get appLanguage => 'Langue de l’application';

  @override
  String get followSystemLanguage => 'Utiliser la langue de l’appareil';

  @override
  String get home => 'Accueil';

  @override
  String get history => 'Historique';

  @override
  String get settings => 'Réglages';

  @override
  String get cancel => 'Annuler';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get delete => 'Supprimer';

  @override
  String get copy => 'Copier';

  @override
  String get edit => 'Modifier';

  @override
  String get copied => 'Copié';

  @override
  String get complete => 'Terminé';

  @override
  String get unavailable => 'Indisponible';

  @override
  String get replaceAudio => 'Remplacer l’audio';

  @override
  String get removeAudio => 'Retirer l’audio';

  @override
  String get playAudio => 'Lire l’audio';

  @override
  String get pauseAudio => 'Mettre en pause';

  @override
  String get audioWaveform => 'Forme d’onde';

  @override
  String get audioWaveformLoading => 'Tracé de la forme d’onde réelle…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'Lecture : $elapsed sur $duration';
  }

  @override
  String copySection(String title) {
    return 'Copier $title';
  }

  @override
  String get screenUnavailable => 'Cet écran est indisponible.';

  @override
  String get goPro => 'Passer à Pro';

  @override
  String get homeHeadline =>
      'Transformez vos messages vocaux en actions claires';

  @override
  String get homeSupporting =>
      'Partagez depuis WhatsApp, choisissez un fichier audio ou enregistrez ici.';

  @override
  String get shareFromWhatsApp => 'Depuis WhatsApp';

  @override
  String get shareFromWhatsAppSteps =>
      'Maintenez le message vocal, touchez Partager, puis VoiceBrief';

  @override
  String get chooseVoiceNote => 'Choisir un message vocal';

  @override
  String get recordInstead => 'Enregistrer maintenant';

  @override
  String get recentBriefs => 'Résumés récents';

  @override
  String get viewAll => 'Tout voir';

  @override
  String get noBriefsYet => 'Aucun résumé pour le moment';

  @override
  String get noBriefsMessage =>
      'Choisissez ou enregistrez un audio pour créer votre premier résumé.';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return '$remaining minutes gratuites restantes sur $total';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return '$remaining minutes Pro restantes sur $total';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return '$remaining minutes restantes sur $total';
  }

  @override
  String get authHeadline => 'Rendez chaque message vocal utile';

  @override
  String get authSupporting =>
      'Connectez-vous pour protéger vos minutes et garder vos résumés privés dans votre compte.';

  @override
  String get demoServicesActive =>
      'Mode démo actif. Aucun compte externe ni service payant n’est utilisé.';

  @override
  String get providerSignInTitle => 'Connexion rapide et sécurisée';

  @override
  String get providerSignInDescription =>
      'Choisissez Apple ou Google. VoiceBrief ne voit jamais votre mot de passe.';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get byContinuingPrefix => 'En continuant, vous acceptez les ';

  @override
  String get terms => 'Conditions';

  @override
  String get andConjunction => ' et la ';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get errorIdentityProviderUnavailable =>
      'Ce mode de connexion est indisponible. Essayez-en un autre.';

  @override
  String get onboardingSignIn => 'Se connecter';

  @override
  String get onboardingTitleOne => 'De la voix à l’essentiel';

  @override
  String get onboardingBodyOne =>
      'Partagez, choisissez ou enregistrez un audio. Obtenez transcription, résumé, tâches, dates et suggestions de réponses.';

  @override
  String get onboardingTitleTwo => 'Votre audio reste privé';

  @override
  String get onboardingBodyTwo =>
      'L’audio est traité de façon sécurisée et supprimé automatiquement. Vous choisissez les textes à conserver.';

  @override
  String get getStarted => 'Commencer';

  @override
  String get recordAudio => 'Enregistrer un audio';

  @override
  String get discardRecordingTitle => 'Supprimer cet enregistrement ?';

  @override
  String get discardRecordingMessage =>
      'L’enregistrement actuel sera supprimé.';

  @override
  String get discard => 'Abandonner';

  @override
  String get recordingPaused => 'Enregistrement en pause';

  @override
  String get recording => 'Enregistrement';

  @override
  String get tapRecordReady => 'Touchez Enregistrer quand vous êtes prêt';

  @override
  String get startRecording => 'Démarrer l’enregistrement';

  @override
  String get resume => 'Reprendre';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Arrêter';

  @override
  String get cancelRecording => 'Annuler l’enregistrement';

  @override
  String get microphoneJustInTime =>
      'L’accès au microphone est demandé uniquement lorsque vous lancez l’enregistrement.';

  @override
  String get recordingSaveFailed =>
      'Impossible de sauvegarder l’enregistrement.';

  @override
  String get liveWaveformIdle =>
      'La forme d’onde réelle apparaît au début de l’enregistrement.';

  @override
  String get liveWaveformStarting => 'Lecture du niveau réel du microphone…';

  @override
  String get liveWaveformActive => 'Cette onde suit votre voix en direct.';

  @override
  String get historyLocalOnly => 'Enregistré localement sur cet appareil';

  @override
  String get searchBriefs => 'Rechercher des résumés';

  @override
  String get nothingSaved => 'Aucun texte enregistré';

  @override
  String get nothingSavedMessage =>
      'Enregistrez un résultat pour le retrouver ici.';

  @override
  String get noMatchingBriefs => 'Aucun résumé correspondant';

  @override
  String get noMatchingBriefsMessage =>
      'Essayez un autre mot du titre ou du résumé.';

  @override
  String get briefDeleted => 'Résumé supprimé';

  @override
  String get undo => 'Annuler';

  @override
  String get voiceNoteReady => 'Message vocal prêt';

  @override
  String get reviewAudio => 'Vérifier l’audio';

  @override
  String get createMyBrief => 'Créer mon résumé';

  @override
  String get secureAiProcessing =>
      'Traitement sécurisé par IA · audio temporaire supprimé après traitement';

  @override
  String get secureAiProcessingSemantics =>
      'L’audio est transmis de façon sécurisée à l’IA puis supprimé du stockage temporaire après traitement.';

  @override
  String get trimAudio => 'Découper l’audio';

  @override
  String get trimAudioHelp =>
      'Faites glisser les deux poignées pour sélectionner le passage. Vous pouvez l’écouter avant de continuer.';

  @override
  String selectedAudioRange(String start, String end) {
    return 'Passage sélectionné : $start — $end';
  }

  @override
  String get useFullAudio => 'Utiliser tout l’audio';

  @override
  String get createBriefFromSelection => 'Résumer ce passage';

  @override
  String get trimmingAudio => 'Découpage de l’audio…';

  @override
  String get audioTrimmed =>
      'Audio découpé. Seul le passage sélectionné a été conservé.';

  @override
  String get sharedAudioImporting => 'Préparation du message vocal partagé…';

  @override
  String get customizeOutput => 'Personnaliser le résultat';

  @override
  String get defaultOutput =>
      'Le résumé et la transcription intégrale sont inclus automatiquement';

  @override
  String get fullTranscript => 'Transcription intégrale';

  @override
  String get fullTranscriptDescription =>
      'Tout ce qui a été dit, conservé tel quel pour le relire, le rechercher ou le copier.';

  @override
  String get summaryAndKeyPoints => 'Résumé et points clés';

  @override
  String get actionItemsAndDates => 'Tâches et dates';

  @override
  String get suggestedReplies => 'Suggestions de réponses';

  @override
  String get translateSummaryEnglish => 'Traduire le résumé en anglais';

  @override
  String get sharedAudioReadySemantics =>
      'Message vocal partagé importé et prêt.';

  @override
  String get sharedAudioReady => 'Message vocal importé. Encore un geste.';

  @override
  String get creatingBrief => 'Création de votre résumé';

  @override
  String get processingFallbackError =>
      'Le traitement a échoué. La copie sécurisée du serveur a été supprimée et votre copie locale privée est prête pour un nouvel essai.';

  @override
  String get processingKeepOpen =>
      'Gardez VoiceBrief ouvert jusqu’à la fin de l’envoi sécurisé. La durée dépend de l’audio et de la connexion.';

  @override
  String get preparingAudio => 'Préparation de l’audio';

  @override
  String get uploadingSecurely => 'Envoi sécurisé';

  @override
  String get transcribing => 'Transcription';

  @override
  String get creatingYourBrief => 'Création de votre résumé';

  @override
  String get finalizing => 'Finalisation';

  @override
  String get brief => 'Résumé';

  @override
  String get briefUnavailable => 'Ce résumé n’est plus disponible.';

  @override
  String get copyAll => 'Tout copier';

  @override
  String get shareResult => 'Partager le résultat';

  @override
  String get savedLocally => 'Enregistré localement';

  @override
  String get notSaved => 'Non enregistré';

  @override
  String get saved => 'Enregistré';

  @override
  String get saveResult => 'Enregistrer le résultat';

  @override
  String get deleteResult => 'Supprimer le résultat';

  @override
  String get deleteBriefTitle => 'Supprimer ce résumé ?';

  @override
  String get deleteBriefMessage =>
      'Le texte enregistré sera supprimé de cet appareil.';

  @override
  String get keyPoints => 'Points clés';

  @override
  String get actionItems => 'Tâches';

  @override
  String get importantDates => 'Dates importantes';

  @override
  String get addToCalendar => 'Ajouter au calendrier';

  @override
  String get setReminder => 'Créer un rappel';

  @override
  String get reminderSet => 'Alarme VoiceBrief programmée.';

  @override
  String get reminderUnavailable =>
      'Impossible de créer le rappel. Activez les notifications de VoiceBrief et réessayez.';

  @override
  String get reminderMustBeFuture =>
      'Choisissez une heure future pour le rappel.';

  @override
  String get chooseAlarmTone => 'Son de l’alarme';

  @override
  String get chooseAlarmToneDescription =>
      'Utilisez le son d’origine de l’iPhone ou choisissez le vôtre.';

  @override
  String get previewTone => 'Écouter le son';

  @override
  String get confirmAlarm => 'Utiliser ce son';

  @override
  String get alarmsAndReminders => 'Alarmes et rappels';

  @override
  String get voiceBriefAlarms => 'Alarmes';

  @override
  String get voiceBriefAlarmsDescription =>
      'Consultez ou annulez vos alarmes programmées.';

  @override
  String get noScheduledAlarms => 'Aucune alarme à venir';

  @override
  String get noScheduledAlarmsMessage =>
      'Créez une alarme depuis une date d’un résumé pour la retrouver ici.';

  @override
  String get alarmsUnavailable =>
      'Impossible de charger les alarmes VoiceBrief.';

  @override
  String get alarmScheduled => 'Programmée';

  @override
  String alarmToneLabel(Object tone) {
    return 'Son : $tone';
  }

  @override
  String get alarmSoundTitle => 'Son de l’alarme';

  @override
  String get systemAlarmSound => 'Son par défaut de l’iPhone';

  @override
  String get systemAlarmSoundDescription => 'Le son d’origine du système.';

  @override
  String get customAlarmSound => 'Son personnalisé';

  @override
  String get changeAlarmSound => 'Changer';

  @override
  String get addCustomAlarmSound => 'Ajouter votre son';

  @override
  String get importAudioSound => 'Choisir un fichier audio';

  @override
  String get importVideoSound => 'Extraire le son d’une vidéo';

  @override
  String get soundLimitNotice =>
      'Les 29 premières secondes sont enregistrées dans un format adapté aux alarmes.';

  @override
  String get preparingAlarmSound => 'Préparation du son…';

  @override
  String get soundImportFailed =>
      'Impossible d’utiliser ce fichier. Choisissez un fichier contenant de l’audio.';

  @override
  String get importedSoundReady => 'Le son est prêt.';

  @override
  String get useThisSound => 'Utiliser ce son';

  @override
  String get upcomingAlarms => 'Alarmes à venir';

  @override
  String get loadingAlarms => 'Chargement des alarmes…';

  @override
  String get cancelAlarm => 'Annuler l’alarme';

  @override
  String get cancelAlarmTitle => 'Annuler cette alarme ?';

  @override
  String cancelAlarmMessage(Object title) {
    return 'L’alarme « $title » ne sonnera plus après son annulation.';
  }

  @override
  String get alarmCancelled => 'Alarme annulée.';

  @override
  String get alarmCancelFailed => 'Impossible d’annuler l’alarme. Réessayez.';

  @override
  String get refresh => 'Actualiser';

  @override
  String reminderNotificationTitle(String title) {
    return 'Rappel : $title';
  }

  @override
  String reminderNotificationBody(String phrase) {
    return 'Depuis VoiceBrief : « $phrase »';
  }

  @override
  String ownerLabel(String owner) {
    return 'Responsable : $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'Entendu : « $phrase »';
  }

  @override
  String get needsConfirmation => 'Confirmation requise';

  @override
  String get taskDeadline => 'Échéance';

  @override
  String get shortTone => 'Court';

  @override
  String get friendlyTone => 'Amical';

  @override
  String get professionalTone => 'Professionnel';

  @override
  String get shortReply => 'Réponse courte';

  @override
  String get friendlyReply => 'Réponse amicale';

  @override
  String get professionalReply => 'Réponse professionnelle';

  @override
  String get replyText => 'Texte de la réponse';

  @override
  String get shareEditedReply => 'Partager la réponse modifiée';

  @override
  String get copyEditedReply => 'Copier la réponse modifiée';

  @override
  String confirmDatePhrase(String phrase) {
    return 'Confirmer « $phrase »';
  }

  @override
  String get confirmEventTime => 'Confirmer l’heure';

  @override
  String get openCalendarTitle => 'Ouvrir le calendrier ?';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'VoiceBrief a interprété « $phrase » comme $date. Le calendrier vous demandera de confirmer avant l’enregistrement.';
  }

  @override
  String get openCalendar => 'Ouvrir le calendrier';

  @override
  String calendarDescription(String phrase) {
    return 'Créé depuis VoiceBrief après confirmation : « $phrase »';
  }

  @override
  String get calendarOpened => 'Éditeur du calendrier ouvert.';

  @override
  String datesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dates trouvées · créez des rappels ou ajoutez-les au calendrier',
      one: '1 date trouvée · créez un rappel ou ajoutez-la au calendrier',
    );
    return '$_temp0';
  }

  @override
  String datesFoundSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count dates trouvées. Vérifiez-les, puis créez des rappels ou ajoutez-les au calendrier du système.',
      one:
          '1 date trouvée. Vérifiez-la, puis créez un rappel ou ajoutez-la au calendrier du système.',
    );
    return '$_temp0';
  }

  @override
  String get account => 'Compte';

  @override
  String get notSignedIn => 'Non connecté';

  @override
  String get verifiedAccount => 'Compte vérifié';

  @override
  String get emailVerificationRequired =>
      'Vérification de l’adresse e-mail requise';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'Offre gratuite';

  @override
  String minutesRemaining(int count) {
    return '$count minutes restantes';
  }

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get purchasesRestored => 'Achats restaurés.';

  @override
  String get noPurchasesRestored => 'Aucun achat restauré.';

  @override
  String get manageSubscription => 'Gérer l’abonnement';

  @override
  String get appearance => 'Apparence';

  @override
  String get systemTheme => 'Système';

  @override
  String get lightTheme => 'Clair';

  @override
  String get darkTheme => 'Sombre';

  @override
  String get privacyAndData => 'Confidentialité et données';

  @override
  String get audioHandlingTitle =>
      'Audio temporaire ; enregistrement du texte facultatif';

  @override
  String get audioHandlingDescription =>
      'L’audio sert temporairement à la transcription, puis est supprimé automatiquement. Seuls les résumés et transcriptions que vous enregistrez restent dans l’historique.';

  @override
  String get exportSavedText => 'Partager les textes enregistrés';

  @override
  String get exportSubject => 'Export VoiceBrief';

  @override
  String get exportSavedTextDescription =>
      'Crée un fichier TXT avec résumés, points clés, tâches, dates, réponses et transcriptions, puis ouvre le menu de partage. Aucun audio n’est inclus.';

  @override
  String get exportSavedTextFailed =>
      'Impossible de créer le fichier texte à partager.';

  @override
  String get noSavedTextOnDevice => 'Aucun texte enregistré sur cet appareil.';

  @override
  String get clearLocalHistory => 'Supprimer les textes enregistrés';

  @override
  String get clearSavedTextDescription =>
      'Supprime les résumés et transcriptions de cet appareil uniquement. Aucun enregistrement audio n’y est conservé.';

  @override
  String get clearHistoryTitle => 'Supprimer les textes enregistrés ?';

  @override
  String get clearHistoryMessage =>
      'Tous les résumés et transcriptions de cet appareil seront définitivement supprimés. Les fichiers audio sont déjà supprimés après traitement.';

  @override
  String get clearHistory => 'Supprimer les textes';

  @override
  String get savedTextCleared => 'Textes enregistrés supprimés.';

  @override
  String get clearSavedTextFailed =>
      'Impossible de supprimer les textes. Réessayez.';

  @override
  String get termsOfService => 'Conditions d’utilisation';

  @override
  String get support => 'Assistance';

  @override
  String get contactSupport => 'Contacter l’assistance';

  @override
  String get appVersion => 'Version de l’application';

  @override
  String get deleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountMessage =>
      'Votre compte serveur et l’historique local seront supprimés. Les abonnements restent actifs jusqu’à leur résiliation dans votre compte de la boutique.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get active => 'Actif';

  @override
  String get proHeadline =>
      'Transformez chaque message vocal en résumé concret';

  @override
  String get accurateTranscripts => 'Transcriptions précises';

  @override
  String get instantSummaries => 'Résumés instantanés';

  @override
  String get threeReplyTones => 'Trois styles de réponses prêts à envoyer';

  @override
  String get loadingStorePrices => 'Chargement des tarifs…';

  @override
  String get subscriptionOptionsUnavailable =>
      'Les abonnements sont indisponibles. Aucun prix de remplacement n’est affiché en production.';

  @override
  String get yearly => 'Annuel';

  @override
  String get monthly => 'Mensuel';

  @override
  String get bestValue => 'MEILLEURE OFFRE';

  @override
  String get proActive => 'Pro est actif';

  @override
  String get subscriptionRenewalNotice =>
      'Les abonnements se renouvellent automatiquement sauf résiliation au moins 24 heures avant la fin de la période. Gérez-les ou résiliez-les dans votre compte de la boutique.';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get proActivatedToast => 'VoiceBrief Pro est actif.';

  @override
  String get noActivePurchases => 'Aucun achat actif trouvé.';

  @override
  String get errorNoInternet =>
      'Vous semblez hors ligne. Vérifiez votre connexion et réessayez.';

  @override
  String get errorAuthentication =>
      'Connexion impossible. Vérifiez vos informations et réessayez.';

  @override
  String get errorProviderCanceled => 'Connexion annulée.';

  @override
  String get errorEmailVerification =>
      'Ouvrez le lien de vérification reçu par e-mail, puis revenez dans VoiceBrief.';

  @override
  String get errorUnsupportedAudio =>
      'Ce format audio n’est pas pris en charge.';

  @override
  String get errorFileTooLarge =>
      'Ce fichier audio dépasse la limite d’envoi actuelle.';

  @override
  String get errorUnreadableAudio =>
      'Impossible de lire cet audio. Essayez un autre fichier.';

  @override
  String get errorAudioEditing =>
      'Impossible de découper cet audio sur cet appareil. L’original est inchangé.';

  @override
  String get errorMicrophoneDenied =>
      'Le microphone est nécessaire uniquement si vous choisissez d’enregistrer.';

  @override
  String get errorUploadInterrupted =>
      'L’envoi sécurisé a été interrompu. Vous pouvez réessayer sans risque.';

  @override
  String get errorProcessingTimeout =>
      'Le traitement a pris trop de temps. Vos minutes n’ont pas été déduites.';

  @override
  String get errorTranscription =>
      'Impossible de transcrire l’audio. Réessayez dans un instant.';

  @override
  String get errorInvalidResponse =>
      'Le résultat était incomplet et n’a pas été enregistré.';

  @override
  String get errorQuotaExhausted =>
      'Vos minutes sont insuffisantes pour traiter cet audio.';

  @override
  String get errorSubscriptionUnavailable =>
      'Les abonnements sont indisponibles pour le moment.';

  @override
  String get errorSubscriptionSyncPending =>
      'Votre achat est confirmé et Pro se synchronise. Gardez VoiceBrief ouvert et réessayez bientôt.';

  @override
  String get errorPurchaseCanceled => 'Achat annulé.';

  @override
  String get errorPurchaseFailed =>
      'L’achat n’a pas abouti. VoiceBrief ne vous a rien facturé.';

  @override
  String get errorRestoreFailed =>
      'Impossible de restaurer les achats. Réessayez plus tard.';

  @override
  String get errorServiceUnavailable =>
      'VoiceBrief est temporairement indisponible. Réessayez bientôt.';

  @override
  String get errorShareHandoff =>
      'Impossible d’importer l’audio partagé de façon sécurisée.';

  @override
  String get errorConfiguration =>
      'Cette fonctionnalité nécessite encore sa configuration de production.';

  @override
  String get errorUnknown => 'Un problème est survenu. Réessayez.';
}
