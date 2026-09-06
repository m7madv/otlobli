import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show Intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'generated/app_localizations.dart';

part 'known_labels.dart';

/// App-wide display preference; never changes store currency or customer data.
class L10n extends ChangeNotifier {
  L10n._();
  static final instance = L10n._();
  static const preferenceKey = 'damanak.display_language';
  static const languageNames = <String, String>{
    'ar': 'العربية',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'pt': 'Português',
    'zh': '简体中文',
    'hi': 'हिन्दी',
    'ja': '日本語',
    'ru': 'Русский',
  };
  static const languageTitles = <String, String>{
    'ar': 'اللغة',
    'en': 'Language',
    'es': 'Idioma',
    'fr': 'Langue',
    'de': 'Sprache',
    'pt': 'Idioma',
    'zh': '语言',
    'hi': 'भाषा',
    'ja': '言語',
    'ru': 'Язык',
  };
  static const systemTitles = <String, String>{
    'ar': 'لغة الجهاز',
    'en': 'Device language',
    'es': 'Idioma del dispositivo',
    'fr': 'Langue de l’appareil',
    'de': 'Gerätesprache',
    'pt': 'Idioma do dispositivo',
    'zh': '设备语言',
    'hi': 'डिवाइस की भाषा',
    'ja': 'デバイスの言語',
    'ru': 'Язык устройства',
  };
  static Locale resolve(List<Locale> preferences) {
    for (final preference in preferences) {
      if (languageNames.containsKey(preference.languageCode)) {
        return Locale(preference.languageCode);
      }
    }
    return const Locale('en');
  }

  Locale _locale = const Locale('ar');
  String? _selection;
  Locale get locale => _locale;
  String? get selection => _selection;
  static final _localizedInstances = <String, AppLocalizations>{};
  static AppLocalizations get current => _localizedInstances.putIfAbsent(
    instance.locale.languageCode,
    () => lookupAppLocalizations(instance.locale),
  );
  static bool get isRtl => instance.locale.languageCode == 'ar';
  static String get languageTitle =>
      languageTitles[instance.locale.languageCode]!;
  static String get systemTitle => systemTitles[instance.locale.languageCode]!;
  static String knownLabel(String value) => _knownLabel(value);
  static void watch(BuildContext context) {
    Localizations.maybeLocaleOf(context);
  }

  Future<void> initialize() async {
    await initializeDateFormatting();
    try {
      final preferences = await SharedPreferences.getInstance();
      final selected = preferences.getString(preferenceKey);
      _selection = languageNames.containsKey(selected) ? selected : null;
    } catch (_) {
      _selection = null;
    }
    _applySelection();
  }

  Future<void> select(String? language) async {
    if (language != null && !languageNames.containsKey(language)) {
      throw ArgumentError.value(language, 'language');
    }
    _selection = language;
    _applySelection();
    final preferences = await SharedPreferences.getInstance();
    if (language == null) {
      await preferences.remove(preferenceKey);
    } else {
      await preferences.setString(preferenceKey, language);
    }
  }

  void deviceLocalesChanged() {
    if (_selection == null) _applySelection();
  }

  void _applySelection() {
    _locale = _selection == null
        ? resolve(ui.PlatformDispatcher.instance.locales)
        : Locale(_selection!);
    Intl.defaultLocale = _locale.languageCode;
    notifyListeners();
  }
}

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});
  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    return PopupMenuButton<String>(
      tooltip: L10n.languageTitle,
      initialValue: L10n.instance.selection ?? 'system',
      onSelected: (value) async {
        await L10n.instance.select(value == 'system' ? null : value);
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'system',
          checked: L10n.instance.selection == null,
          child: Text(L10n.systemTitle),
        ),
        for (final entry in L10n.languageNames.entries)
          CheckedPopupMenuItem(
            value: entry.key,
            checked: L10n.instance.selection == entry.key,
            child: Text(
              entry.value,
              textDirection: entry.key == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_outlined),
            const SizedBox(width: 8),
            Text(L10n.languageTitle),
          ],
        ),
      ),
    );
  }
}
