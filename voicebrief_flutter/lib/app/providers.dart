import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voicebrief/app/app_controller.dart';
import 'package:voicebrief/app/app_state.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/core/storage/app_database.dart';
import 'package:voicebrief/features/audio_import/data/audio_import_service.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/auth/data/native_identity_token_service.dart';
import 'package:voicebrief/features/history/data/history_repository.dart';
import 'package:voicebrief/features/recorder/data/recorder_service.dart';
import 'package:voicebrief/features/subscription/data/subscription_repository.dart';
import 'package:voicebrief/features/transcription/data/transcription_repository.dart';

final appConfigProvider = Provider<AppConfig>(
  (_) => AppConfig.fromEnvironment(),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => DriftHistoryRepository(ref.watch(appDatabaseProvider)),
);

final audioImportServiceProvider = Provider<AudioImportService>(
  (_) => AudioImportService(),
);
final sharedAudioInboxProvider = Provider<SharedAudioInbox>((ref) {
  final inbox = SharedAudioInbox();
  ref.onDispose(inbox.dispose);
  return inbox;
});
final recorderServiceProvider = Provider<RecorderService>((ref) {
  final service = RecorderService();
  ref.onDispose(service.dispose);
  return service;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMocks || !config.hasSupabase) {
    return FakeAuthRepository();
  }
  return SupabaseAuthRepository(
    Supabase.instance.client,
    NativeIdentityTokenService(config),
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final platformKey = Platform.isIOS
      ? config.revenueCatIosKey
      : config.revenueCatAndroidKey;
  if (config.useMocks || platformKey.isEmpty) {
    return FakeSubscriptionRepository();
  }
  return RevenueCatSubscriptionRepository();
});

final transcriptionRepositoryProvider = Provider<TranscriptionRepository>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  if (config.useMocks || !config.hasSupabase) {
    return FakeTranscriptionRepository();
  }
  return SupabaseTranscriptionRepository(Supabase.instance.client);
});

final appControllerProvider = StateNotifierProvider<AppController, AppState>((
  ref,
) {
  return AppController(
    authRepository: ref.watch(authRepositoryProvider),
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
    transcriptionRepository: ref.watch(transcriptionRepositoryProvider),
    historyRepository: ref.watch(historyRepositoryProvider),
    audioImportService: ref.watch(audioImportServiceProvider),
    sharedAudioInbox: ref.watch(sharedAudioInboxProvider),
  );
});

Future<void> configureRevenueCat(AppConfig config) async {
  if (config.useMocks) return;
  final key = Platform.isIOS
      ? config.revenueCatIosKey
      : config.revenueCatAndroidKey;
  if (key.isEmpty) return;
  await Purchases.setLogLevel(LogLevel.error);
  await Purchases.configure(PurchasesConfiguration(key));
}
