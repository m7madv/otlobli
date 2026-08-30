import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voicebrief/app/app.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/core/security/safe_log.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  var appStarted = false;

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
    if (Platform.isIOS) {
      await _restoreIosShareSession(Supabase.instance.client);
      await _syncIosShareSession(
        config,
        Supabase.instance.client.auth.currentSession,
      );
      Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        unawaited(_syncIosShareSession(config, event.session));
        if (appStarted && event.session != null) {
          unawaited(_requestIosShareReadyNotifications());
        }
      });
    }
  }
  await configureRevenueCat(config);

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const VoiceBriefApp(),
    ),
  );
  appStarted = true;
  if (Platform.isIOS &&
      !config.useMocks &&
      config.hasSupabase &&
      Supabase.instance.client.auth.currentSession != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_requestIosShareReadyNotifications());
    });
  }
}

const _iosShareChannel = MethodChannel('voicebrief/share');

Future<void> _restoreIosShareSession(SupabaseClient client) async {
  try {
    final shared = await _iosShareChannel.invokeMapMethod<String, Object?>(
      'getShareSession',
    );
    final refreshToken = shared?['refreshToken'] as String?;
    if (refreshToken == null || refreshToken.isEmpty) return;
    if (client.auth.currentSession?.refreshToken == refreshToken) return;
    await client.auth.setSession(refreshToken);
  } on MissingPluginException {
    // The bridge is absent in unit tests and non-device builds.
  } on PlatformException {
    // Supabase can still restore its ordinary application-local session.
  } on AuthException {
    // A stale shared refresh token must not break normal application sign-in.
  }
}

Future<void> _syncIosShareSession(AppConfig config, Session? session) async {
  try {
    if (session == null) {
      await _iosShareChannel.invokeMethod<void>('syncShareSession');
      return;
    }
    await _iosShareChannel.invokeMethod<void>('syncShareSession', {
      'supabaseUrl': config.supabaseUrl,
      'anonKey': config.supabaseAnonKey,
      'accessToken': session.accessToken,
      'refreshToken': session.refreshToken,
      'userId': session.user.id,
      'expiresAt': session.expiresAt ?? 0,
    });
  } on MissingPluginException {
    // The iOS bridge is unavailable in unit tests and non-device builds.
  } on PlatformException {
    // Authentication remains usable even if the optional share sync fails.
  }
}

Future<void> _requestIosShareReadyNotifications() async {
  try {
    await _iosShareChannel.invokeMethod<bool>('requestShareReadyNotifications');
  } on MissingPluginException {
    // The bridge is absent in unit tests and non-device builds.
  } on PlatformException {
    // Sharing remains available if notification permission is unavailable.
  }
}
