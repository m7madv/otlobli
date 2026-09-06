// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get appLanguage => 'Idioma de la aplicación';

  @override
  String get followSystemLanguage => 'Usar el idioma del dispositivo';

  @override
  String get home => 'Inicio';

  @override
  String get history => 'Historial';

  @override
  String get settings => 'Ajustes';

  @override
  String get cancel => 'Cancelar';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get close => 'Cerrar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get delete => 'Eliminar';

  @override
  String get copy => 'Copiar';

  @override
  String get edit => 'Editar';

  @override
  String get copied => 'Copiado';

  @override
  String get complete => 'Completado';

  @override
  String get unavailable => 'No disponible';

  @override
  String get replaceAudio => 'Cambiar audio';

  @override
  String get removeAudio => 'Quitar audio';

  @override
  String get playAudio => 'Reproducir audio';

  @override
  String get pauseAudio => 'Pausar audio';

  @override
  String get audioWaveform => 'Forma de onda';

  @override
  String get audioWaveformLoading => 'Dibujando la onda real del audio…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'Reproducción: $elapsed de $duration';
  }

  @override
  String copySection(String title) {
    return 'Copiar $title';
  }

  @override
  String get screenUnavailable => 'Esta pantalla no está disponible.';

  @override
  String get goPro => 'Obtener Pro';

  @override
  String get homeHeadline => 'Convierte notas de voz en próximos pasos claros';

  @override
  String get homeSupporting =>
      'Comparte desde WhatsApp, elige un audio o graba aquí.';

  @override
  String get shareFromWhatsApp => 'Desde WhatsApp';

  @override
  String get shareFromWhatsAppSteps =>
      'Mantén pulsado el mensaje de voz, toca Compartir y luego VoiceBrief';

  @override
  String get chooseVoiceNote => 'Elegir una nota de voz';

  @override
  String get recordInstead => 'Grabar ahora';

  @override
  String get recentBriefs => 'Resúmenes recientes';

  @override
  String get viewAll => 'Ver todos';

  @override
  String get noBriefsYet => 'Aún no hay resúmenes';

  @override
  String get noBriefsMessage =>
      'Elige o graba un audio para crear tu primer resumen.';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return 'Quedan $remaining de $total minutos gratis';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return 'Quedan $remaining de $total minutos Pro';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return 'Quedan $remaining de $total minutos';
  }

  @override
  String get authHeadline => 'Aprovecha cada mensaje de voz';

  @override
  String get authSupporting =>
      'Inicia sesión para proteger tus minutos y mantener tus resúmenes privados en tu cuenta.';

  @override
  String get demoServicesActive =>
      'Modo de demostración activo. No se usan cuentas externas ni servicios de pago.';

  @override
  String get providerSignInTitle => 'Acceso rápido y seguro';

  @override
  String get providerSignInDescription =>
      'Elige Apple o Google. VoiceBrief nunca ve la contraseña de tu cuenta.';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get byContinuingPrefix => 'Al continuar, aceptas los ';

  @override
  String get terms => 'Términos';

  @override
  String get andConjunction => ' y la ';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get errorIdentityProviderUnavailable =>
      'Este método de acceso no está disponible. Prueba otro.';

  @override
  String get onboardingSignIn => 'Iniciar sesión';

  @override
  String get onboardingTitleOne => 'Transforma la voz en claridad';

  @override
  String get onboardingBodyOne =>
      'Comparte, elige o graba audio. Recibe la transcripción, el resumen, las tareas, las fechas y respuestas sugeridas.';

  @override
  String get onboardingTitleTwo => 'Tu audio sigue siendo privado';

  @override
  String get onboardingBodyTwo =>
      'El audio se procesa de forma segura y se elimina automáticamente. Tú eliges qué textos guardar.';

  @override
  String get getStarted => 'Empezar';

  @override
  String get recordAudio => 'Grabar audio';

  @override
  String get discardRecordingTitle => '¿Descartar la grabación?';

  @override
  String get discardRecordingMessage => 'Se eliminará la grabación actual.';

  @override
  String get discard => 'Descartar';

  @override
  String get recordingPaused => 'Grabación pausada';

  @override
  String get recording => 'Grabando';

  @override
  String get tapRecordReady => 'Pulsa grabar cuando estés listo';

  @override
  String get startRecording => 'Iniciar grabación';

  @override
  String get resume => 'Reanudar';

  @override
  String get pause => 'Pausar';

  @override
  String get stop => 'Detener';

  @override
  String get cancelRecording => 'Cancelar grabación';

  @override
  String get microphoneJustInTime =>
      'Solo se solicita acceso al micrófono cuando pulsas grabar.';

  @override
  String get recordingSaveFailed => 'No se pudo guardar la grabación.';

  @override
  String get liveWaveformIdle =>
      'La onda real aparece al iniciar la grabación.';

  @override
  String get liveWaveformStarting => 'Leyendo el nivel real del micrófono…';

  @override
  String get liveWaveformActive => 'Esta onda se mueve con tu voz en directo.';

  @override
  String get historyLocalOnly => 'Guardado localmente en este dispositivo';

  @override
  String get searchBriefs => 'Buscar resúmenes';

  @override
  String get nothingSaved => 'Aún no hay textos guardados';

  @override
  String get nothingSavedMessage =>
      'Guarda un resultado para que aparezca aquí.';

  @override
  String get noMatchingBriefs => 'No hay coincidencias';

  @override
  String get noMatchingBriefsMessage =>
      'Prueba otra palabra del título o resumen.';

  @override
  String get briefDeleted => 'Resumen eliminado';

  @override
  String get undo => 'Deshacer';

  @override
  String get voiceNoteReady => 'Nota de voz lista';

  @override
  String get reviewAudio => 'Revisar audio';

  @override
  String get createMyBrief => 'Crear mi resumen';

  @override
  String get secureAiProcessing =>
      'Procesamiento seguro con IA · el audio temporal se elimina al terminar';

  @override
  String get secureAiProcessingSemantics =>
      'El audio se envía de forma segura para procesarlo con IA y se elimina del almacenamiento temporal al terminar.';

  @override
  String get trimAudio => 'Recortar audio';

  @override
  String get trimAudioHelp =>
      'Arrastra ambos extremos para elegir el fragmento. Puedes escucharlo antes de continuar.';

  @override
  String selectedAudioRange(String start, String end) {
    return 'Fragmento seleccionado: $start — $end';
  }

  @override
  String get useFullAudio => 'Usar todo el audio';

  @override
  String get createBriefFromSelection => 'Resumir este fragmento';

  @override
  String get trimmingAudio => 'Recortando audio…';

  @override
  String get audioTrimmed =>
      'Audio recortado. Solo se conservó el fragmento seleccionado.';

  @override
  String get sharedAudioImporting => 'Preparando la nota de voz compartida…';

  @override
  String get customizeOutput => 'Personalizar el resultado';

  @override
  String get defaultOutput =>
      'El resumen y la transcripción literal se incluyen automáticamente';

  @override
  String get fullTranscript => 'Transcripción literal';

  @override
  String get fullTranscriptDescription =>
      'Todo lo dicho en la grabación, tal como se dijo, para revisarlo, buscarlo o copiarlo.';

  @override
  String get summaryAndKeyPoints => 'Resumen y puntos clave';

  @override
  String get actionItemsAndDates => 'Tareas y fechas';

  @override
  String get suggestedReplies => 'Respuestas sugeridas';

  @override
  String get translateSummaryEnglish => 'Traducir el resumen al inglés';

  @override
  String get sharedAudioReadySemantics =>
      'Nota de voz compartida importada y lista.';

  @override
  String get sharedAudioReady => 'Nota de voz importada. Solo queda un toque.';

  @override
  String get creatingBrief => 'Creando tu resumen';

  @override
  String get processingFallbackError =>
      'No se pudo completar el proceso. La copia segura del servidor se eliminó y tu copia local privada está lista para reintentar.';

  @override
  String get processingKeepOpen =>
      'Mantén VoiceBrief abierto hasta que termine la carga segura. El tiempo restante depende de la duración del audio y de la conexión.';

  @override
  String get preparingAudio => 'Preparando audio';

  @override
  String get uploadingSecurely => 'Subiendo de forma segura';

  @override
  String get transcribing => 'Transcribiendo';

  @override
  String get creatingYourBrief => 'Creando tu resumen';

  @override
  String get finalizing => 'Finalizando';

  @override
  String get brief => 'Resumen';

  @override
  String get briefUnavailable => 'Este resumen ya no está disponible.';

  @override
  String get copyAll => 'Copiar todo';

  @override
  String get shareResult => 'Compartir resultado';

  @override
  String get savedLocally => 'Guardado localmente';

  @override
  String get notSaved => 'Sin guardar';

  @override
  String get saved => 'Guardado';

  @override
  String get saveResult => 'Guardar resultado';

  @override
  String get deleteResult => 'Eliminar resultado';

  @override
  String get deleteBriefTitle => '¿Eliminar este resumen?';

  @override
  String get deleteBriefMessage =>
      'Se eliminará el texto guardado de este dispositivo.';

  @override
  String get keyPoints => 'Puntos clave';

  @override
  String get actionItems => 'Tareas';

  @override
  String get importantDates => 'Fechas importantes';

  @override
  String get addToCalendar => 'Añadir al calendario';

  @override
  String get setReminder => 'Programar recordatorio';

  @override
  String get reminderSet => 'Alarma de VoiceBrief programada.';

  @override
  String get reminderUnavailable =>
      'No se pudo programar el recordatorio. Activa las notificaciones de VoiceBrief e inténtalo de nuevo.';

  @override
  String get reminderMustBeFuture =>
      'Elige una hora futura para el recordatorio.';

  @override
  String get chooseAlarmTone => 'Sonido de alarma';

  @override
  String get chooseAlarmToneDescription =>
      'Usa el sonido original del iPhone o elige uno propio.';

  @override
  String get previewTone => 'Escuchar sonido';

  @override
  String get confirmAlarm => 'Usar este sonido';

  @override
  String get alarmsAndReminders => 'Alarmas y recordatorios';

  @override
  String get voiceBriefAlarms => 'Alarmas';

  @override
  String get voiceBriefAlarmsDescription =>
      'Consulta o cancela tus alarmas programadas.';

  @override
  String get noScheduledAlarms => 'No hay alarmas próximas';

  @override
  String get noScheduledAlarmsMessage =>
      'Programa una alarma desde una fecha de un resumen y aparecerá aquí.';

  @override
  String get alarmsUnavailable =>
      'No se pudieron cargar las alarmas de VoiceBrief.';

  @override
  String get alarmScheduled => 'Programada';

  @override
  String alarmToneLabel(Object tone) {
    return 'Sonido: $tone';
  }

  @override
  String get alarmSoundTitle => 'Sonido de alarma';

  @override
  String get systemAlarmSound => 'Sonido predeterminado del iPhone';

  @override
  String get systemAlarmSoundDescription => 'El sonido original del sistema.';

  @override
  String get customAlarmSound => 'Sonido personalizado';

  @override
  String get changeAlarmSound => 'Cambiar';

  @override
  String get addCustomAlarmSound => 'Añadir tu sonido';

  @override
  String get importAudioSound => 'Elegir un archivo de audio';

  @override
  String get importVideoSound => 'Extraer sonido de un vídeo';

  @override
  String get soundLimitNotice =>
      'Se guardan los primeros 29 segundos en un formato compatible con alarmas.';

  @override
  String get preparingAlarmSound => 'Preparando sonido…';

  @override
  String get soundImportFailed =>
      'No se pudo usar este archivo. Elige uno que contenga audio.';

  @override
  String get importedSoundReady => 'Sonido listo.';

  @override
  String get useThisSound => 'Usar este sonido';

  @override
  String get upcomingAlarms => 'Próximas alarmas';

  @override
  String get loadingAlarms => 'Cargando alarmas…';

  @override
  String get cancelAlarm => 'Cancelar alarma';

  @override
  String get cancelAlarmTitle => '¿Cancelar esta alarma?';

  @override
  String cancelAlarmMessage(Object title) {
    return 'La alarma «$title» no sonará una vez cancelada.';
  }

  @override
  String get alarmCancelled => 'Alarma cancelada.';

  @override
  String get alarmCancelFailed =>
      'No se pudo cancelar la alarma. Inténtalo de nuevo.';

  @override
  String get refresh => 'Actualizar';

  @override
  String reminderNotificationTitle(String title) {
    return 'Recordatorio: $title';
  }

  @override
  String reminderNotificationBody(String phrase) {
    return 'De VoiceBrief: «$phrase»';
  }

  @override
  String ownerLabel(String owner) {
    return 'Responsable: $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'Se escuchó: «$phrase»';
  }

  @override
  String get needsConfirmation => 'Requiere confirmación';

  @override
  String get taskDeadline => 'Fecha límite';

  @override
  String get shortTone => 'Breve';

  @override
  String get friendlyTone => 'Amable';

  @override
  String get professionalTone => 'Profesional';

  @override
  String get shortReply => 'Respuesta breve';

  @override
  String get friendlyReply => 'Respuesta amable';

  @override
  String get professionalReply => 'Respuesta profesional';

  @override
  String get replyText => 'Texto de la respuesta';

  @override
  String get shareEditedReply => 'Compartir respuesta editada';

  @override
  String get copyEditedReply => 'Copiar respuesta editada';

  @override
  String confirmDatePhrase(String phrase) {
    return 'Confirmar «$phrase»';
  }

  @override
  String get confirmEventTime => 'Confirmar hora del evento';

  @override
  String get openCalendarTitle => '¿Abrir el calendario?';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'VoiceBrief interpretó «$phrase» como $date. El calendario te pedirá confirmación antes de guardar.';
  }

  @override
  String get openCalendar => 'Abrir calendario';

  @override
  String calendarDescription(String phrase) {
    return 'Creado desde VoiceBrief tras confirmar: «$phrase»';
  }

  @override
  String get calendarOpened => 'Se abrió el editor del calendario.';

  @override
  String datesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fechas encontradas · programa recordatorios o añádelas al calendario',
      one:
          '1 fecha encontrada · programa un recordatorio o añádela al calendario',
    );
    return '$_temp0';
  }

  @override
  String datesFoundSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se encontraron $count fechas. Revísalas y programa recordatorios o añádelas al calendario del sistema.',
      one:
          'Se encontró 1 fecha. Revísala y programa un recordatorio o añádela al calendario del sistema.',
    );
    return '$_temp0';
  }

  @override
  String get account => 'Cuenta';

  @override
  String get notSignedIn => 'Sin sesión iniciada';

  @override
  String get verifiedAccount => 'Cuenta verificada';

  @override
  String get emailVerificationRequired => 'Se requiere verificar el correo';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'Plan gratuito';

  @override
  String minutesRemaining(int count) {
    return 'Quedan $count minutos';
  }

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get purchasesRestored => 'Compras restauradas.';

  @override
  String get noPurchasesRestored => 'No se restauró ninguna compra.';

  @override
  String get manageSubscription => 'Gestionar suscripción';

  @override
  String get appearance => 'Apariencia';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get privacyAndData => 'Privacidad y datos';

  @override
  String get audioHandlingTitle => 'Audio temporal; guardar texto es opcional';

  @override
  String get audioHandlingDescription =>
      'El audio se usa temporalmente para transcribirlo y se elimina automáticamente. Solo los resúmenes y transcripciones que decidas guardar quedan en el historial.';

  @override
  String get exportSavedText => 'Compartir textos guardados';

  @override
  String get exportSubject => 'Exportación de VoiceBrief';

  @override
  String get exportSavedTextDescription =>
      'Crea un archivo TXT con resúmenes, puntos clave, tareas, fechas, respuestas y transcripciones, y abre el menú para compartir. Nunca incluye audio.';

  @override
  String get exportSavedTextFailed =>
      'No se pudo crear el archivo de texto para compartirlo.';

  @override
  String get noSavedTextOnDevice =>
      'No hay textos guardados en este dispositivo.';

  @override
  String get clearLocalHistory => 'Eliminar textos guardados';

  @override
  String get clearSavedTextDescription =>
      'Elimina resúmenes y transcripciones solo de este dispositivo. Aquí no se guardan grabaciones de audio.';

  @override
  String get clearHistoryTitle => '¿Eliminar los textos guardados?';

  @override
  String get clearHistoryMessage =>
      'Se eliminarán permanentemente los resúmenes y transcripciones de este dispositivo. Los audios ya se eliminan después de procesarlos.';

  @override
  String get clearHistory => 'Eliminar textos';

  @override
  String get savedTextCleared => 'Textos guardados eliminados.';

  @override
  String get clearSavedTextFailed =>
      'No se pudieron eliminar los textos. Inténtalo de nuevo.';

  @override
  String get termsOfService => 'Condiciones del servicio';

  @override
  String get support => 'Ayuda';

  @override
  String get contactSupport => 'Contactar con soporte';

  @override
  String get appVersion => 'Versión de la aplicación';

  @override
  String get deleteAccountTitle => '¿Eliminar la cuenta?';

  @override
  String get deleteAccountMessage =>
      'Se eliminarán tu cuenta del servidor y el historial local. Las suscripciones continúan hasta que las canceles en tu cuenta de la tienda.';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get active => 'Activo';

  @override
  String get proHeadline =>
      'Convierte cada mensaje de voz en un resumen con acciones';

  @override
  String get accurateTranscripts => 'Transcripciones precisas';

  @override
  String get instantSummaries => 'Resúmenes al instante';

  @override
  String get threeReplyTones => 'Tres estilos de respuesta listos para enviar';

  @override
  String get loadingStorePrices => 'Cargando precios de la tienda…';

  @override
  String get subscriptionOptionsUnavailable =>
      'Las suscripciones no están disponibles. No se muestran precios alternativos en producción.';

  @override
  String get yearly => 'Anual';

  @override
  String get monthly => 'Mensual';

  @override
  String get bestValue => 'MEJOR OPCIÓN';

  @override
  String get proActive => 'Pro está activo';

  @override
  String get subscriptionRenewalNotice =>
      'Las suscripciones se renuevan automáticamente salvo que se cancelen al menos 24 horas antes del final del periodo. Puedes gestionarlas o cancelarlas en tu cuenta de la tienda.';

  @override
  String get privacy => 'Privacidad';

  @override
  String get proActivatedToast => 'VoiceBrief Pro está activo.';

  @override
  String get noActivePurchases => 'No se encontraron compras activas.';

  @override
  String get errorNoInternet =>
      'Parece que no tienes conexión. Compruébala e inténtalo de nuevo.';

  @override
  String get errorAuthentication =>
      'No pudimos iniciar tu sesión. Revisa tus datos e inténtalo de nuevo.';

  @override
  String get errorProviderCanceled => 'Inicio de sesión cancelado.';

  @override
  String get errorEmailVerification =>
      'Revisa tu correo y abre el enlace de verificación. Luego vuelve a VoiceBrief.';

  @override
  String get errorUnsupportedAudio => 'Este formato de audio no es compatible.';

  @override
  String get errorFileTooLarge =>
      'El archivo supera el límite actual de carga.';

  @override
  String get errorUnreadableAudio =>
      'No se pudo leer este audio. Prueba otro archivo.';

  @override
  String get errorAudioEditing =>
      'No se pudo recortar el audio en este dispositivo. El original no se ha modificado.';

  @override
  String get errorMicrophoneDenied =>
      'Solo necesitas acceso al micrófono si decides grabar.';

  @override
  String get errorUploadInterrupted =>
      'La carga segura se interrumpió. Puedes reintentar con seguridad.';

  @override
  String get errorProcessingTimeout =>
      'El proceso tardó demasiado. No se descontaron minutos.';

  @override
  String get errorTranscription =>
      'No se pudo transcribir el audio. Inténtalo de nuevo en unos instantes.';

  @override
  String get errorInvalidResponse =>
      'El resultado estaba incompleto y no se guardó.';

  @override
  String get errorQuotaExhausted =>
      'No tienes suficientes minutos para procesar este audio.';

  @override
  String get errorSubscriptionUnavailable =>
      'Las suscripciones no están disponibles ahora.';

  @override
  String get errorSubscriptionSyncPending =>
      'Tu compra está confirmada y Pro sigue sincronizándose. Mantén VoiceBrief abierto e inténtalo de nuevo en breve.';

  @override
  String get errorPurchaseCanceled => 'Compra cancelada.';

  @override
  String get errorPurchaseFailed =>
      'La compra no se completó. VoiceBrief no realizó ningún cobro.';

  @override
  String get errorRestoreFailed =>
      'No se pudieron restaurar las compras. Inténtalo más tarde.';

  @override
  String get errorServiceUnavailable =>
      'VoiceBrief no está disponible temporalmente. Inténtalo en breve.';

  @override
  String get errorShareHandoff =>
      'No se pudo importar el audio compartido de forma segura.';

  @override
  String get errorConfiguration =>
      'Esta función aún necesita su configuración de producción.';

  @override
  String get errorUnknown => 'Algo salió mal. Inténtalo de nuevo.';
}
