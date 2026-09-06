import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';
import 'package:voicebrief/l10n/app_languages.dart';

abstract interface class AppPreferences {
  ThemeMode get themeMode;
  String? get languageCode;
  Future<void> setLanguageCode(String? code);

  SubscriptionStatus? subscriptionFor(String accountId);

  Future<void> setThemeMode(ThemeMode mode);

  Future<void> cacheSubscription(
    String accountId,
    SubscriptionStatus subscription,
  );

  Future<void> clearSubscription(String accountId);
}

class DeviceAppPreferences implements AppPreferences {
  DeviceAppPreferences(this._preferences);

  static const _themeKey = 'voicebrief.themeMode';
  static const _languageKey = 'voicebrief.languageCode';
  static const _subscriptionKey = 'voicebrief.subscriptionCache';

  final SharedPreferences _preferences;

  static Future<DeviceAppPreferences> load() async =>
      DeviceAppPreferences(await SharedPreferences.getInstance());

  @override
  String? get languageCode =>
      AppLanguages.validated(_preferences.getString(_languageKey));

  @override
  Future<void> setLanguageCode(String? code) async {
    final language = AppLanguages.validated(code);
    final saved = language == null
        ? await _preferences.remove(_languageKey)
        : await _preferences.setString(_languageKey, language);
    if (!saved) throw StateError('Language preference could not be saved');
  }

  @override
  ThemeMode get themeMode => switch (_preferences.getString(_themeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  @override
  SubscriptionStatus? subscriptionFor(String accountId) {
    final raw = _preferences.getString(_subscriptionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final payload = Map<String, Object?>.from(jsonDecode(raw) as Map);
      if (payload['accountId'] != accountId) return null;
      final tier = payload['tier'] == 'pro'
          ? SubscriptionTier.pro
          : SubscriptionTier.free;
      final remaining = (payload['remainingMinutes'] as num?)?.toInt();
      final total = (payload['totalMinutes'] as num?)?.toInt();
      if (remaining == null || total == null || remaining < 0 || total <= 0) {
        return null;
      }
      return SubscriptionStatus(
        tier: tier,
        remainingMinutes: remaining.clamp(0, total),
        totalMinutes: total,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) =>
      _preferences.setString(_themeKey, mode.name);

  @override
  Future<void> cacheSubscription(
    String accountId,
    SubscriptionStatus subscription,
  ) => _preferences.setString(
    _subscriptionKey,
    jsonEncode({
      'accountId': accountId,
      'tier': subscription.tier.name,
      'remainingMinutes': subscription.remainingMinutes,
      'totalMinutes': subscription.totalMinutes,
    }),
  );

  @override
  Future<void> clearSubscription(String accountId) async {
    final cached = subscriptionFor(accountId);
    if (cached != null) await _preferences.remove(_subscriptionKey);
  }
}

class MemoryAppPreferences implements AppPreferences {
  MemoryAppPreferences({
    ThemeMode themeMode = ThemeMode.system,
    String? languageCode,
    Map<String, SubscriptionStatus>? subscriptions,
  }) : _themeMode = themeMode,
       _languageCode = AppLanguages.validated(languageCode),
       _subscriptions = {...?subscriptions};

  ThemeMode _themeMode;
  String? _languageCode;

  @override
  String? get languageCode => _languageCode;

  @override
  Future<void> setLanguageCode(String? code) async =>
      _languageCode = AppLanguages.validated(code);
  final Map<String, SubscriptionStatus> _subscriptions;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  SubscriptionStatus? subscriptionFor(String accountId) =>
      _subscriptions[accountId];

  @override
  Future<void> setThemeMode(ThemeMode mode) async => _themeMode = mode;

  @override
  Future<void> cacheSubscription(
    String accountId,
    SubscriptionStatus subscription,
  ) async => _subscriptions[accountId] = subscription;

  @override
  Future<void> clearSubscription(String accountId) async {
    _subscriptions.remove(accountId);
  }
}
