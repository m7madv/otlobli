import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicebrief/app/app_controller.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/features/audio_import/data/audio_import_service.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/auth/domain/auth_user.dart';
import 'package:voicebrief/features/history/data/history_repository.dart';
import 'package:voicebrief/features/subscription/data/subscription_repository.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';
import 'package:voicebrief/features/transcription/data/transcription_repository.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';
import 'package:voicebrief/l10n/app_localizations.dart';
import 'package:voicebrief/ui/core/theme/app_theme.dart';

const testConfig = AppConfig(
  environment: 'test',
  useMocks: true,
  supabaseUrl: '',
  supabaseAnonKey: '',
  revenueCatIosKey: '',
  revenueCatAndroidKey: '',
  googleIosClientId: '',
  googleWebClientId: '',
  appleServiceId: '',
  appleRedirectUri: '',
);

BriefResult sampleResult({bool saved = false}) => BriefResult(
  id: '4a63937a-c449-4e42-96ec-33e33214bb04',
  detectedLanguage: 'en',
  title: 'Project launch follow-up',
  transcript: 'Maya will send the proposal before Thursday.',
  summary: 'The proposal is due before Thursday.',
  keyPoints: const ['The proposal is ready for final review.'],
  actionItems: const [
    BriefActionItem(
      title: 'Send the proposal',
      owner: 'Maya',
      dueDateIso: '2026-08-27T17:00:00+03:00',
      originalDatePhrase: 'before Thursday',
      confidence: 0.82,
    ),
  ],
  importantDates: const [
    BriefImportantDate(
      label: 'Proposal deadline',
      dateIso: '2026-08-27T17:00:00+03:00',
      originalPhrase: 'before Thursday',
      confidence: 0.61,
    ),
  ],
  suggestedReplies: const SuggestedReplies(
    short: 'Got it. I will review it before Thursday.',
    friendly: 'Sounds good! I will review it before Thursday.',
    professional: 'Thank you. I will review it before Thursday.',
  ),
  audioDurationSeconds: 84,
  processedAt: DateTime.utc(2026, 8, 24, 9, 30),
  savedLocally: saved,
);

class TestSharedAudioInbox extends SharedAudioInbox {
  TestSharedAudioInbox();

  @override
  Stream<SharedAudioPayload> get received => const Stream.empty();

  @override
  Future<SharedAudioPayload?> takePending() async => null;
}

AppController createTestController({
  bool pro = false,
  HistoryRepository? historyRepository,
}) {
  return AppController(
    authRepository: TestAuthRepository(),
    subscriptionRepository: TestSubscriptionRepository(pro: pro),
    transcriptionRepository: FakeTranscriptionRepository(),
    historyRepository: historyRepository ?? MemoryHistoryRepository(),
    audioImportService: const AudioImportService(),
    sharedAudioInbox: TestSharedAudioInbox(),
  );
}

class TestAuthRepository implements AuthRepository {
  AuthUser? _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<AuthUser> createAccount(String email, String password) =>
      signInWithEmail(email, password);

  @override
  Future<void> deleteAccount() async => _user = null;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    return _user = AuthUser(
      id: 'test-account',
      email: email,
      emailVerified: true,
    );
  }

  @override
  Future<AuthUser> signInWithProvider(IdentityProvider provider) =>
      signInWithEmail('${provider.name}@example.com', 'unused-password');

  @override
  Future<void> signOut() async => _user = null;
}

class TestSubscriptionRepository implements SubscriptionRepository {
  TestSubscriptionRepository({required this.pro});

  bool pro;

  SubscriptionStatus get _status => SubscriptionStatus(
    tier: pro ? SubscriptionTier.pro : SubscriptionTier.free,
    remainingMinutes: pro ? 300 : 10,
    totalMinutes: pro ? 300 : 10,
    options: const [
      SubscriptionOption(
        productId: ProductIds.annual,
        title: 'Yearly',
        localizedPrice: '229 QAR / year',
        annual: true,
        localizedMonthlyEquivalent: '19.08 QAR / month',
      ),
      SubscriptionOption(
        productId: ProductIds.monthly,
        title: 'Monthly',
        localizedPrice: '29 QAR / month',
        annual: false,
      ),
    ],
    offeringsLoaded: true,
  );

  @override
  Future<void> logIn(String accountId) async {}

  @override
  Future<void> logOut() async => pro = false;

  @override
  Future<SubscriptionStatus> load() async => _status;

  @override
  Future<SubscriptionStatus> purchase(String productId) async {
    pro = true;
    return _status;
  }

  @override
  Future<SubscriptionStatus> restore() async => _status;
}

Widget testApp({
  required AppController controller,
  required Widget home,
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) {
  controller.setThemeMode(themeMode);
  final testFontFamily = locale.languageCode == 'ar' ? 'Arial' : 'Roboto';
  final lightTheme = _fontTheme(AppTheme.light(), testFontFamily);
  final darkTheme = _fontTheme(AppTheme.dark(), testFontFamily);
  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith((_) => controller),
      appConfigProvider.overrideWithValue(testConfig),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

ThemeData _fontTheme(ThemeData base, String fontFamily) => base.copyWith(
  textTheme: base.textTheme.apply(fontFamily: fontFamily),
  primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
  appBarTheme: base.appBarTheme.copyWith(
    titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
      fontFamily: fontFamily,
    ),
  ),
);

Future<void> loadTestFonts() async {
  final loader = FontLoader('Roboto');
  for (final name in const [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    loader.addFont(
      File('test/fonts/$name').readAsBytes().then(
        (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
      ),
    );
  }
  await loader.load();

  final windowsDirectory = Platform.environment['WINDIR'];
  if (windowsDirectory != null) {
    final arabicFont = File('$windowsDirectory/Fonts/arial.ttf');
    if (arabicFont.existsSync()) {
      final arabicLoader = FontLoader('Arial')
        ..addFont(
          arabicFont.readAsBytes().then(
            (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
          ),
        );
      await arabicLoader.load();
    }
  }

  try {
    final bundledIconLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await bundledIconLoader.load();
    return;
  } on Object {
    // Older Flutter test bundles may not expose the app font through rootBundle.
  }

  var flutterCacheAncestor = File(Platform.resolvedExecutable).parent;
  File? materialIcons;
  for (var depth = 0; depth < 8; depth += 1) {
    final candidate = File(
      '${flutterCacheAncestor.path}'
      '/artifacts/material_fonts/materialicons-regular.otf',
    );
    if (candidate.existsSync()) {
      materialIcons = candidate;
      break;
    }
    flutterCacheAncestor = flutterCacheAncestor.parent;
  }
  if (materialIcons == null) {
    throw StateError('Flutter Material Icons font was not found.');
  }
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(
      materialIcons.readAsBytes().then(
        (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
      ),
    );
  await iconLoader.load();
}
