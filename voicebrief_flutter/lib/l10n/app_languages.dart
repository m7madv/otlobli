import 'package:flutter/widgets.dart';

abstract final class AppLanguages {
  // Native names let users recover from selecting an unfamiliar language.
  static const names = <String, String>{
    'ar': 'العربية',
    'en': 'English',
    'zh': '简体中文',
    'hi': 'हिन्दी',
    'es': 'Español',
    'fr': 'Français',
    'bn': 'বাংলা',
    'pt': 'Português',
    'ru': 'Русский',
    'ur': 'اردو',
    'id': 'Bahasa Indonesia',
  };

  static String? validated(String? code) =>
      names.containsKey(code) ? code : null;

  static Locale resolve(List<Locale>? preferred, Iterable<Locale> supported) {
    for (final locale in preferred ?? const <Locale>[]) {
      // Do not advertise Simplified Chinese as a Traditional translation.
      if (locale.languageCode == 'zh' &&
          (locale.scriptCode == 'Hant' ||
              const ['TW', 'HK', 'MO'].contains(locale.countryCode))) {
        continue;
      }
      for (final candidate in supported) {
        if (candidate.languageCode == locale.languageCode) return candidate;
      }
    }
    return const Locale('en');
  }
}
