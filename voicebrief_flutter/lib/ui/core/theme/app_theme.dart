import 'package:flutter/material.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

abstract final class AppTheme {
  static const _signalBlue = Color(0xFF007AFF);
  static const _signalBlueDark = Color(0xFF0A84FF);

  static ThemeData light() => _build(Brightness.light, VoiceBriefPalette.light);

  static ThemeData dark() => _build(Brightness.dark, VoiceBriefPalette.dark);

  static ThemeData _build(Brightness brightness, VoiceBriefPalette palette) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final accent = isDark ? _signalBlueDark : _signalBlue;
    final error = isDark ? const Color(0xFFFF453A) : const Color(0xFFD70015);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: background,
      onSurface: palette.primaryText,
      surfaceContainerHighest: palette.surface,
      outline: palette.border,
      outlineVariant: palette.strongBorder,
    );

    final textTheme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w700,
        color: palette.primaryText,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        color: palette.primaryText,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w700,
        color: palette.primaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 22 / 17,
        fontWeight: FontWeight.w600,
        color: palette.primaryText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w400,
        color: palette.primaryText,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w500,
        color: palette.primaryText,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        height: 17 / 13,
        fontWeight: FontWeight.w400,
        color: palette.secondaryText,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: palette.secondaryText,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      dividerColor: palette.border,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: palette.primaryText,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: palette.secondaryText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: error),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? accent : palette.secondaryText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? accent : palette.secondaryText,
            size: 24,
          );
        }),
        elevation: 0,
        height: 68,
      ),
      extensions: [palette],
    );
  }
}
