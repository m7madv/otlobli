import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF12263A);
  static const emerald = Color(0xFF12805C);
  static const emeraldDark = Color(0xFF0A6144);
  static const mint = Color(0xFFE6F5EF);
  static const gold = Color(0xFFE6A23C);
  static const paper = Color(0xFFF6F7F4);
  static const danger = Color(0xFFB44747);
  static const muted = Color(0xFF64717D);
  static const line = Color(0xFFDDE2DE);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.emerald,
    onPrimary: Colors.white,
    primaryContainer: AppColors.mint,
    onPrimaryContainer: AppColors.emeraldDark,
    secondary: AppColors.gold,
    onSecondary: AppColors.ink,
    error: AppColors.danger,
    surface: Colors.white,
    onSurface: AppColors.ink,
    outline: AppColors.line,
    shadow: Color(0x1A12263A),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1.15,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        height: 1.55,
        color: AppColors.ink,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: 1.45,
        color: AppColors.ink,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.emerald, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.mint,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.emeraldDark
              : AppColors.muted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          fontSize: 12,
        );
      }),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.mint,
      selectedIconTheme: IconThemeData(color: AppColors.emeraldDark),
      unselectedIconTheme: IconThemeData(color: AppColors.ink),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.emeraldDark,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppColors.muted,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerColor: AppColors.line,
  );
}
