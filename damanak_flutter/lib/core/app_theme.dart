import 'package:flutter/material.dart';

/// ألوان الهوية الثابتة فقط. أما ألوان الأسطح والنصوص فتؤخذ من
/// [ColorScheme] كي تتكيّف تلقائياً مع المظهر الفاتح والداكن.
abstract final class AppColors {
  static const accent = Color(0xFF087F5B);
  static const accentPressed = Color(0xFF056247);
  static const accentDark = Color(0xFF42D7A2);
  static const ivory = Color(0xFFF7F4EA);
  static const danger = Color(0xFFBA1A1A);

  // أسماء توافقية مؤقتة. جميعها تعود إلى لون العلامة الواحد كي لا تعود
  // الألوان الزخرفية السابقة إلى الواجهة أثناء نقل المكوّنات القديمة.
  static const jade = accent;
  static const jadeDark = accentPressed;
  static const emerald = accent;
  static const emeraldDark = accentPressed;
  static const amber = accent;
  static const blue = accent;
  static const gold = accent;

  // حياديات فاتحة للمكوّنات القديمة التي لم تُنقل بعد إلى ColorScheme.
  static const ink = Color(0xFF111412);
  static const inkSoft = Color(0xFF202522);
  static const muted = Color(0xFF626864);
  static const line = Color(0xFFE2E5E3);
  static const paper = Color(0xFFF2F4F3);
  static const sand = Color(0xFFF2F4F3);
  static const mint = Color(0xFFE8F3EF);
  static const dangerSoft = Color(0xFFFFEDEA);
}

extension DamanakThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
}

ThemeData buildAppTheme([Brightness brightness = Brightness.light]) {
  final isDark = brightness == Brightness.dark;
  final scheme = isDark
      ? const ColorScheme.dark(
          primary: AppColors.accentDark,
          onPrimary: Color(0xFF003828),
          primaryContainer: Color(0xFF174B3B),
          onPrimaryContainer: Color(0xFFB8F3DA),
          secondary: AppColors.accentDark,
          onSecondary: Color(0xFF003828),
          secondaryContainer: Color(0xFF174B3B),
          onSecondaryContainer: Color(0xFFB8F3DA),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          errorContainer: Color(0xFF93000A),
          onErrorContainer: Color(0xFFFFDAD6),
          surface: Color(0xFF1C1C1E),
          onSurface: Color(0xFFF4F7F5),
          onSurfaceVariant: Color(0xFFB8C0BC),
          outline: Color(0xFF747C78),
          outlineVariant: Color(0xFF3A403D),
          surfaceContainerLowest: Color(0xFF000000),
          surfaceContainerLow: Color(0xFF151716),
          surfaceContainer: Color(0xFF1C1F1D),
          surfaceContainerHigh: Color(0xFF252927),
          surfaceContainerHighest: Color(0xFF303532),
          shadow: Color(0x99000000),
        )
      : const ColorScheme.light(
          primary: AppColors.accent,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFE8F3EF),
          onPrimaryContainer: Color(0xFF064D38),
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFE8F3EF),
          onSecondaryContainer: Color(0xFF064D38),
          error: AppColors.danger,
          onError: Colors.white,
          errorContainer: AppColors.dangerSoft,
          onErrorContainer: Color(0xFF7A1010),
          surface: Colors.white,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.muted,
          outline: Color(0xFF7A817D),
          outlineVariant: AppColors.line,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xFFF8FAF9),
          surfaceContainer: AppColors.paper,
          surfaceContainerHigh: Color(0xFFECEFED),
          surfaceContainerHighest: Color(0xFFE3E7E5),
          shadow: Color(0x20111412),
        );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? scheme.surfaceContainerLowest
        : scheme.surfaceContainer,
    visualDensity: VisualDensity.standard,
  );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  final textTheme = base.textTheme.copyWith(
    displaySmall: base.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: scheme.onSurface,
      height: 1.08,
    ),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.35,
      color: scheme.onSurface,
      height: 1.15,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: scheme.onSurface,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(
      fontSize: 17,
      height: 1.42,
      color: scheme.onSurface,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.45,
      color: scheme.onSurface,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.45,
      color: scheme.onSurfaceVariant,
    ),
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: inputBorder(scheme.outlineVariant),
      enabledBorder: inputBorder(scheme.outlineVariant),
      focusedBorder: inputBorder(scheme.primary, 2),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error, 2),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      helperStyle: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
      errorStyle: TextStyle(color: scheme.error, height: 1.35),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        foregroundColor: scheme.onSurface,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 0,
      backgroundColor: scheme.surface.withValues(alpha: 0.96),
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          fontSize: 11,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    ),
    dividerColor: scheme.outlineVariant,
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primaryContainer,
    ),
  );
}
