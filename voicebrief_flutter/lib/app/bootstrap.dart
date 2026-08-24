import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voicebrief/app/app.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/core/security/safe_log.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();

  FlutterError.onError = (details) {
    SafeLog.event(
      'flutter_error',
      metadata: {'code': details.exception.runtimeType.toString()},
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    SafeLog.event(
      'platform_error',
      metadata: {'code': error.runtimeType.toString()},
    );
    return true;
  };

  if (!config.useMocks && config.hasSupabase) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  await configureRevenueCat(config);

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const VoiceBriefApp(),
    ),
  );
}
