import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/app/router.dart';
import 'package:voicebrief/l10n/app_localizations.dart';
import 'package:voicebrief/ui/core/theme/app_theme.dart';

class VoiceBriefApp extends ConsumerWidget {
  const VoiceBriefApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(
      appControllerProvider.select((value) => value.themeMode),
    );
    return MaterialApp.router(
      title: AppIdentity.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (preferredLocales, supportedLocales) {
        final usesArabic = preferredLocales?.any(
          (locale) => locale.languageCode == 'ar',
        );
        return usesArabic == true ? const Locale('ar') : const Locale('en');
      },
    );
  }
}
