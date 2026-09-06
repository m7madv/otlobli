// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'VoiceBrief';

  @override
  String get appLanguage => 'Bahasa aplikasi';

  @override
  String get followSystemLanguage => 'Gunakan bahasa perangkat';

  @override
  String get home => 'Beranda';

  @override
  String get history => 'Riwayat';

  @override
  String get settings => 'Pengaturan';

  @override
  String get cancel => 'Batal';

  @override
  String get tryAgain => 'Coba lagi';

  @override
  String get close => 'Tutup';

  @override
  String get continueLabel => 'Lanjutkan';

  @override
  String get signIn => 'Masuk';

  @override
  String get signOut => 'Keluar';

  @override
  String get delete => 'Hapus';

  @override
  String get copy => 'Salin';

  @override
  String get edit => 'Edit';

  @override
  String get copied => 'Disalin';

  @override
  String get complete => 'Selesai';

  @override
  String get unavailable => 'Tidak tersedia';

  @override
  String get replaceAudio => 'Ganti audio';

  @override
  String get removeAudio => 'Hapus audio';

  @override
  String get playAudio => 'Putar audio';

  @override
  String get pauseAudio => 'Jeda audio';

  @override
  String get audioWaveform => 'Gelombang audio';

  @override
  String get audioWaveformLoading => 'Menggambar gelombang audio asli…';

  @override
  String audioPlayback(String elapsed, String duration) {
    return 'Pemutaran audio: $elapsed dari $duration';
  }

  @override
  String copySection(String title) {
    return 'Salin $title';
  }

  @override
  String get screenUnavailable => 'Layar ini tidak tersedia.';

  @override
  String get goPro => 'Beralih ke Pro';

  @override
  String get homeHeadline => 'Ubah pesan suara menjadi langkah yang jelas';

  @override
  String get homeSupporting =>
      'Bagikan dari WhatsApp, pilih file audio, atau rekam di sini.';

  @override
  String get shareFromWhatsApp => 'Dari WhatsApp';

  @override
  String get shareFromWhatsAppSteps =>
      'Tekan lama pesan suara, ketuk Bagikan, lalu VoiceBrief';

  @override
  String get chooseVoiceNote => 'Pilih pesan suara';

  @override
  String get recordInstead => 'Rekam sekarang';

  @override
  String get recentBriefs => 'Ringkasan terbaru';

  @override
  String get viewAll => 'Lihat semua';

  @override
  String get noBriefsYet => 'Belum ada ringkasan';

  @override
  String get noBriefsMessage =>
      'Pilih atau rekam audio untuk membuat ringkasan pertama.';

  @override
  String usageFreeMinutesRemaining(int remaining, int total) {
    return 'Sisa $remaining dari $total menit gratis';
  }

  @override
  String usageProMinutesRemaining(int remaining, int total) {
    return 'Sisa $remaining dari $total menit Pro';
  }

  @override
  String usageMinutesSemantics(int remaining, int total) {
    return 'Sisa $remaining dari $total menit';
  }

  @override
  String get authHeadline => 'Jadikan setiap pesan suara bermanfaat';

  @override
  String get authSupporting =>
      'Masuk untuk melindungi kuota menit dan menjaga privasi ringkasan di akun Anda.';

  @override
  String get demoServicesActive =>
      'Mode demo aktif. Tidak menggunakan akun eksternal atau layanan berbayar.';

  @override
  String get providerSignInTitle => 'Masuk cepat dan aman';

  @override
  String get providerSignInDescription =>
      'Pilih Apple atau Google. VoiceBrief tidak pernah melihat kata sandi akun Anda.';

  @override
  String get continueWithApple => 'Lanjutkan dengan Apple';

  @override
  String get continueWithGoogle => 'Lanjutkan dengan Google';

  @override
  String get byContinuingPrefix => 'Dengan melanjutkan, Anda menyetujui ';

  @override
  String get terms => 'Ketentuan';

  @override
  String get andConjunction => ' dan ';

  @override
  String get privacyPolicy => 'Kebijakan Privasi';

  @override
  String get errorIdentityProviderUnavailable =>
      'Metode masuk ini belum tersedia. Coba metode lain.';

  @override
  String get onboardingSignIn => 'Masuk';

  @override
  String get onboardingTitleOne => 'Dari suara menjadi kejelasan';

  @override
  String get onboardingBodyOne =>
      'Bagikan, pilih, atau rekam audio. Dapatkan transkrip, ringkasan, tugas, tanggal, dan saran balasan.';

  @override
  String get onboardingTitleTwo => 'Audio Anda tetap privat';

  @override
  String get onboardingBodyTwo =>
      'Audio diproses dengan aman dan dihapus otomatis. Anda memilih teks yang ingin disimpan.';

  @override
  String get getStarted => 'Mulai';

  @override
  String get recordAudio => 'Rekam audio';

  @override
  String get discardRecordingTitle => 'Buang rekaman?';

  @override
  String get discardRecordingMessage => 'Rekaman saat ini akan dihapus.';

  @override
  String get discard => 'Buang';

  @override
  String get recordingPaused => 'Rekaman dijeda';

  @override
  String get recording => 'Merekam';

  @override
  String get tapRecordReady => 'Ketuk rekam saat Anda siap';

  @override
  String get startRecording => 'Mulai merekam';

  @override
  String get resume => 'Lanjutkan';

  @override
  String get pause => 'Jeda';

  @override
  String get stop => 'Berhenti';

  @override
  String get cancelRecording => 'Batalkan rekaman';

  @override
  String get microphoneJustInTime =>
      'Akses mikrofon hanya diminta saat Anda mengetuk rekam.';

  @override
  String get recordingSaveFailed => 'Rekaman tidak dapat disimpan.';

  @override
  String get liveWaveformIdle =>
      'Gelombang asli muncul setelah perekaman dimulai.';

  @override
  String get liveWaveformStarting => 'Membaca tingkat mikrofon asli…';

  @override
  String get liveWaveformActive =>
      'Gelombang ini mengikuti suara Anda secara langsung.';

  @override
  String get historyLocalOnly => 'Disimpan lokal di perangkat ini';

  @override
  String get searchBriefs => 'Cari ringkasan';

  @override
  String get nothingSaved => 'Belum ada yang disimpan';

  @override
  String get nothingSavedMessage => 'Simpan hasil agar muncul di sini.';

  @override
  String get noMatchingBriefs => 'Tidak ada ringkasan yang cocok';

  @override
  String get noMatchingBriefsMessage =>
      'Coba kata lain dari judul atau ringkasan.';

  @override
  String get briefDeleted => 'Ringkasan dihapus';

  @override
  String get undo => 'Urungkan';

  @override
  String get voiceNoteReady => 'Pesan suara siap';

  @override
  String get reviewAudio => 'Tinjau audio';

  @override
  String get createMyBrief => 'Buat ringkasan saya';

  @override
  String get secureAiProcessing =>
      'Pemrosesan AI aman · audio sementara dihapus setelah diproses';

  @override
  String get secureAiProcessingSemantics =>
      'Audio dikirim dengan aman untuk diproses AI dan dihapus dari penyimpanan sementara setelah selesai.';

  @override
  String get trimAudio => 'Potong audio';

  @override
  String get trimAudioHelp =>
      'Geser kedua ujung untuk memilih bagian yang diringkas. Anda dapat memutarnya sebelum melanjutkan.';

  @override
  String selectedAudioRange(String start, String end) {
    return 'Bagian terpilih: $start — $end';
  }

  @override
  String get useFullAudio => 'Gunakan seluruh audio';

  @override
  String get createBriefFromSelection => 'Ringkas bagian ini';

  @override
  String get trimmingAudio => 'Memotong audio…';

  @override
  String get audioTrimmed =>
      'Audio dipotong. Hanya bagian terpilih yang disimpan.';

  @override
  String get sharedAudioImporting => 'Menyiapkan pesan suara yang dibagikan…';

  @override
  String get customizeOutput => 'Sesuaikan hasil';

  @override
  String get defaultOutput =>
      'Ringkasan dan transkrip kata demi kata disertakan otomatis';

  @override
  String get fullTranscript => 'Transkrip kata demi kata';

  @override
  String get fullTranscriptDescription =>
      'Semua yang diucapkan dalam rekaman, sesuai aslinya, untuk ditinjau, dicari, atau disalin.';

  @override
  String get summaryAndKeyPoints => 'Ringkasan dan poin utama';

  @override
  String get actionItemsAndDates => 'Tugas dan tanggal';

  @override
  String get suggestedReplies => 'Saran balasan';

  @override
  String get translateSummaryEnglish =>
      'Terjemahkan ringkasan ke bahasa Inggris';

  @override
  String get sharedAudioReadySemantics =>
      'Pesan suara yang dibagikan telah diimpor dan siap.';

  @override
  String get sharedAudioReady => 'Pesan suara diimpor. Tinggal satu ketukan.';

  @override
  String get creatingBrief => 'Membuat ringkasan Anda';

  @override
  String get processingFallbackError =>
      'Pemrosesan gagal. Salinan aman di server telah dihapus dan salinan lokal privat Anda siap dicoba lagi.';

  @override
  String get processingKeepOpen =>
      'Biarkan VoiceBrief terbuka hingga unggahan aman selesai. Waktu bergantung pada panjang rekaman dan koneksi.';

  @override
  String get preparingAudio => 'Menyiapkan audio';

  @override
  String get uploadingSecurely => 'Mengunggah dengan aman';

  @override
  String get transcribing => 'Mentranskripsikan';

  @override
  String get creatingYourBrief => 'Membuat ringkasan Anda';

  @override
  String get finalizing => 'Menyelesaikan';

  @override
  String get brief => 'Ringkasan';

  @override
  String get briefUnavailable => 'Ringkasan ini tidak lagi tersedia.';

  @override
  String get copyAll => 'Salin semua';

  @override
  String get shareResult => 'Bagikan hasil';

  @override
  String get savedLocally => 'Disimpan lokal';

  @override
  String get notSaved => 'Belum disimpan';

  @override
  String get saved => 'Disimpan';

  @override
  String get saveResult => 'Simpan hasil';

  @override
  String get deleteResult => 'Hapus hasil';

  @override
  String get deleteBriefTitle => 'Hapus ringkasan ini?';

  @override
  String get deleteBriefMessage =>
      'Teks tersimpan akan dihapus dari perangkat ini.';

  @override
  String get keyPoints => 'Poin utama';

  @override
  String get actionItems => 'Tugas';

  @override
  String get importantDates => 'Tanggal penting';

  @override
  String get addToCalendar => 'Tambahkan ke kalender';

  @override
  String get setReminder => 'Atur pengingat';

  @override
  String get reminderSet => 'Alarm VoiceBrief diatur.';

  @override
  String get reminderUnavailable =>
      'Pengingat tidak dapat diatur. Aktifkan notifikasi VoiceBrief dan coba lagi.';

  @override
  String get reminderMustBeFuture => 'Pilih waktu mendatang untuk pengingat.';

  @override
  String get chooseAlarmTone => 'Suara alarm';

  @override
  String get chooseAlarmToneDescription =>
      'Gunakan suara asli iPhone atau pilih suara Anda sendiri.';

  @override
  String get previewTone => 'Pratinjau suara';

  @override
  String get confirmAlarm => 'Gunakan suara ini';

  @override
  String get alarmsAndReminders => 'Alarm dan pengingat';

  @override
  String get voiceBriefAlarms => 'Alarm';

  @override
  String get voiceBriefAlarmsDescription =>
      'Lihat atau batalkan alarm terjadwal.';

  @override
  String get noScheduledAlarms => 'Tidak ada alarm mendatang';

  @override
  String get noScheduledAlarmsMessage =>
      'Atur alarm dari tanggal dalam ringkasan agar muncul di sini.';

  @override
  String get alarmsUnavailable => 'Alarm VoiceBrief belum dapat dimuat.';

  @override
  String get alarmScheduled => 'Terjadwal';

  @override
  String alarmToneLabel(Object tone) {
    return 'Suara: $tone';
  }

  @override
  String get alarmSoundTitle => 'Suara alarm';

  @override
  String get systemAlarmSound => 'Suara bawaan iPhone';

  @override
  String get systemAlarmSoundDescription => 'Suara asli dari sistem.';

  @override
  String get customAlarmSound => 'Suara khusus';

  @override
  String get changeAlarmSound => 'Ubah';

  @override
  String get addCustomAlarmSound => 'Tambahkan suara Anda';

  @override
  String get importAudioSound => 'Pilih file audio';

  @override
  String get importVideoSound => 'Ekstrak suara dari video';

  @override
  String get soundLimitNotice =>
      '29 detik pertama disimpan dalam format yang sesuai untuk alarm.';

  @override
  String get preparingAlarmSound => 'Menyiapkan suara…';

  @override
  String get soundImportFailed =>
      'File ini tidak dapat digunakan. Pilih file yang berisi audio.';

  @override
  String get importedSoundReady => 'Suara siap.';

  @override
  String get useThisSound => 'Gunakan suara ini';

  @override
  String get upcomingAlarms => 'Alarm mendatang';

  @override
  String get loadingAlarms => 'Memuat alarm…';

  @override
  String get cancelAlarm => 'Batalkan alarm';

  @override
  String get cancelAlarmTitle => 'Batalkan alarm ini?';

  @override
  String cancelAlarmMessage(Object title) {
    return 'Alarm “$title” tidak akan berbunyi setelah dibatalkan.';
  }

  @override
  String get alarmCancelled => 'Alarm dibatalkan.';

  @override
  String get alarmCancelFailed => 'Alarm tidak dapat dibatalkan. Coba lagi.';

  @override
  String get refresh => 'Muat ulang';

  @override
  String reminderNotificationTitle(String title) {
    return 'Pengingat: $title';
  }

  @override
  String reminderNotificationBody(String phrase) {
    return 'Dari VoiceBrief: “$phrase”';
  }

  @override
  String ownerLabel(String owner) {
    return 'Penanggung jawab: $owner';
  }

  @override
  String heardLabel(String phrase) {
    return 'Terdengar: “$phrase”';
  }

  @override
  String get needsConfirmation => 'Perlu konfirmasi';

  @override
  String get taskDeadline => 'Tenggat tugas';

  @override
  String get shortTone => 'Singkat';

  @override
  String get friendlyTone => 'Ramah';

  @override
  String get professionalTone => 'Profesional';

  @override
  String get shortReply => 'Balasan singkat';

  @override
  String get friendlyReply => 'Balasan ramah';

  @override
  String get professionalReply => 'Balasan profesional';

  @override
  String get replyText => 'Teks balasan';

  @override
  String get shareEditedReply => 'Bagikan balasan yang diedit';

  @override
  String get copyEditedReply => 'Salin balasan yang diedit';

  @override
  String confirmDatePhrase(String phrase) {
    return 'Konfirmasi “$phrase”';
  }

  @override
  String get confirmEventTime => 'Konfirmasi waktu acara';

  @override
  String get openCalendarTitle => 'Buka kalender?';

  @override
  String openCalendarMessage(String phrase, String date) {
    return 'VoiceBrief menafsirkan “$phrase” sebagai $date. Kalender akan meminta konfirmasi sebelum menyimpan.';
  }

  @override
  String get openCalendar => 'Buka kalender';

  @override
  String calendarDescription(String phrase) {
    return 'Dibuat dari VoiceBrief setelah mengonfirmasi: “$phrase”';
  }

  @override
  String get calendarOpened => 'Editor kalender dibuka.';

  @override
  String datesFound(int count) {
    return '$count tanggal ditemukan · atur pengingat atau tambahkan ke kalender';
  }

  @override
  String datesFoundSemantics(int count) {
    return '$count tanggal ditemukan. Tinjau, lalu atur pengingat atau tambahkan ke kalender sistem.';
  }

  @override
  String get account => 'Akun';

  @override
  String get notSignedIn => 'Belum masuk';

  @override
  String get verifiedAccount => 'Akun terverifikasi';

  @override
  String get emailVerificationRequired => 'Verifikasi email diperlukan';

  @override
  String get voiceBriefPro => 'VoiceBrief Pro';

  @override
  String get freePlan => 'Paket gratis';

  @override
  String minutesRemaining(int count) {
    return 'Sisa $count menit';
  }

  @override
  String get restorePurchases => 'Pulihkan pembelian';

  @override
  String get purchasesRestored => 'Pembelian dipulihkan.';

  @override
  String get noPurchasesRestored => 'Tidak ada pembelian yang dipulihkan.';

  @override
  String get manageSubscription => 'Kelola langganan';

  @override
  String get appearance => 'Tampilan';

  @override
  String get systemTheme => 'Sistem';

  @override
  String get lightTheme => 'Terang';

  @override
  String get darkTheme => 'Gelap';

  @override
  String get privacyAndData => 'Privasi dan data';

  @override
  String get audioHandlingTitle =>
      'Audio sementara; menyimpan teks bersifat opsional';

  @override
  String get audioHandlingDescription =>
      'Audio digunakan sementara untuk transkripsi lalu dihapus otomatis. Hanya ringkasan dan transkrip yang Anda pilih untuk disimpan yang tetap ada di riwayat.';

  @override
  String get exportSavedText => 'Bagikan teks tersimpan';

  @override
  String get exportSubject => 'Ekspor VoiceBrief';

  @override
  String get exportSavedTextDescription =>
      'Membuat file TXT berisi ringkasan, poin utama, tugas, tanggal, balasan, dan transkrip, lalu membuka menu berbagi. Tidak pernah menyertakan audio.';

  @override
  String get exportSavedTextFailed =>
      'File teks untuk dibagikan tidak dapat dibuat.';

  @override
  String get noSavedTextOnDevice =>
      'Tidak ada teks tersimpan di perangkat ini.';

  @override
  String get clearLocalHistory => 'Hapus teks tersimpan';

  @override
  String get clearSavedTextDescription =>
      'Menghapus ringkasan dan transkrip hanya dari perangkat ini. Tidak ada rekaman audio yang disimpan di sini.';

  @override
  String get clearHistoryTitle => 'Hapus teks tersimpan?';

  @override
  String get clearHistoryMessage =>
      'Semua ringkasan dan transkrip di perangkat ini akan dihapus permanen. File audio sudah dihapus setelah diproses.';

  @override
  String get clearHistory => 'Hapus teks';

  @override
  String get savedTextCleared => 'Teks tersimpan dihapus.';

  @override
  String get clearSavedTextFailed => 'Teks tidak dapat dihapus. Coba lagi.';

  @override
  String get termsOfService => 'Ketentuan layanan';

  @override
  String get support => 'Bantuan';

  @override
  String get contactSupport => 'Hubungi dukungan';

  @override
  String get appVersion => 'Versi aplikasi';

  @override
  String get deleteAccountTitle => 'Hapus akun?';

  @override
  String get deleteAccountMessage =>
      'Akun server dan riwayat lokal Anda akan dihapus. Langganan toko tetap berjalan hingga Anda membatalkannya di akun toko.';

  @override
  String get deleteAccount => 'Hapus akun';

  @override
  String get active => 'Aktif';

  @override
  String get proHeadline =>
      'Ubah setiap pesan suara menjadi ringkasan yang dapat ditindaklanjuti';

  @override
  String get accurateTranscripts => 'Transkrip akurat';

  @override
  String get instantSummaries => 'Ringkasan instan';

  @override
  String get threeReplyTones => 'Tiga gaya balasan siap kirim';

  @override
  String get loadingStorePrices => 'Memuat harga toko…';

  @override
  String get subscriptionOptionsUnavailable =>
      'Pilihan langganan tidak tersedia. Tidak ada harga pengganti yang ditampilkan dalam versi produksi.';

  @override
  String get yearly => 'Tahunan';

  @override
  String get monthly => 'Bulanan';

  @override
  String get bestValue => 'PALING HEMAT';

  @override
  String get proActive => 'Pro aktif';

  @override
  String get subscriptionRenewalNotice =>
      'Langganan diperpanjang otomatis kecuali dibatalkan setidaknya 24 jam sebelum periode berakhir. Kelola atau batalkan kapan saja di akun toko Anda.';

  @override
  String get privacy => 'Privasi';

  @override
  String get proActivatedToast => 'VoiceBrief Pro aktif.';

  @override
  String get noActivePurchases => 'Tidak ada pembelian aktif.';

  @override
  String get errorNoInternet =>
      'Anda tampaknya offline. Periksa koneksi dan coba lagi.';

  @override
  String get errorAuthentication =>
      'Tidak dapat masuk. Periksa data Anda dan coba lagi.';

  @override
  String get errorProviderCanceled => 'Proses masuk dibatalkan.';

  @override
  String get errorEmailVerification =>
      'Buka tautan verifikasi di email Anda, lalu kembali ke VoiceBrief.';

  @override
  String get errorUnsupportedAudio => 'Format audio ini tidak didukung.';

  @override
  String get errorFileTooLarge =>
      'File audio melebihi batas unggahan saat ini.';

  @override
  String get errorUnreadableAudio =>
      'Audio tidak dapat dibaca. Coba file lain.';

  @override
  String get errorAudioEditing =>
      'Audio tidak dapat dipotong di perangkat ini. File asli tidak berubah.';

  @override
  String get errorMicrophoneDenied =>
      'Akses mikrofon hanya diperlukan jika Anda memilih merekam.';

  @override
  String get errorUploadInterrupted =>
      'Unggahan aman terputus. Anda dapat mencoba lagi dengan aman.';

  @override
  String get errorProcessingTimeout =>
      'Pemrosesan terlalu lama. Menit Anda tidak dipotong.';

  @override
  String get errorTranscription =>
      'Audio tidak dapat ditranskripsikan. Coba lagi sebentar lagi.';

  @override
  String get errorInvalidResponse => 'Hasil tidak lengkap dan tidak disimpan.';

  @override
  String get errorQuotaExhausted =>
      'Menit pemrosesan Anda tidak cukup untuk audio ini.';

  @override
  String get errorSubscriptionUnavailable =>
      'Pilihan langganan belum tersedia.';

  @override
  String get errorSubscriptionSyncPending =>
      'Pembelian Anda dikonfirmasi dan Pro masih disinkronkan. Biarkan VoiceBrief terbuka dan coba lagi sebentar lagi.';

  @override
  String get errorPurchaseCanceled => 'Pembelian dibatalkan.';

  @override
  String get errorPurchaseFailed =>
      'Pembelian tidak selesai. VoiceBrief tidak menagih Anda.';

  @override
  String get errorRestoreFailed =>
      'Pembelian tidak dapat dipulihkan. Coba lagi nanti.';

  @override
  String get errorServiceUnavailable =>
      'VoiceBrief sementara tidak tersedia. Coba lagi sebentar lagi.';

  @override
  String get errorShareHandoff =>
      'Audio yang dibagikan tidak dapat diimpor dengan aman.';

  @override
  String get errorConfiguration =>
      'Fitur ini masih memerlukan konfigurasi produksi.';

  @override
  String get errorUnknown => 'Terjadi kesalahan. Coba lagi.';
}
