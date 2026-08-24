import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const page = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

abstract final class AppRadii {
  static const small = 8.0;
  static const control = 12.0;
  static const surface = 16.0;
}

abstract final class AppMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 220);
}

abstract final class AppBreakpoints {
  static const compact = 360.0;
  static const expanded = 700.0;
}

@immutable
class VoiceBriefPalette extends ThemeExtension<VoiceBriefPalette> {
  const VoiceBriefPalette({
    required this.primaryText,
    required this.secondaryText,
    required this.surface,
    required this.elevatedSurface,
    required this.border,
    required this.strongBorder,
    required this.accentPressed,
    required this.success,
    required this.warning,
  });

  final Color primaryText;
  final Color secondaryText;
  final Color surface;
  final Color elevatedSurface;
  final Color border;
  final Color strongBorder;
  final Color accentPressed;
  final Color success;
  final Color warning;

  static const light = VoiceBriefPalette(
    primaryText: Color(0xFF090909),
    secondaryText: Color(0xFF636366),
    surface: Color(0xFFF5F5F7),
    elevatedSurface: Color(0xFFFFFFFF),
    border: Color(0xFFE5E5EA),
    strongBorder: Color(0xFFD1D1D6),
    accentPressed: Color(0xFF0062CC),
    success: Color(0xFF248A3D),
    warning: Color(0xFFB25000),
  );

  static const dark = VoiceBriefPalette(
    primaryText: Color(0xFFF5F5F7),
    secondaryText: Color(0xFF98989D),
    surface: Color(0xFF0D0D0F),
    elevatedSurface: Color(0xFF1C1C1E),
    border: Color(0xFF2C2C2E),
    strongBorder: Color(0xFF3A3A3C),
    accentPressed: Color(0xFF409CFF),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
  );

  @override
  VoiceBriefPalette copyWith({
    Color? primaryText,
    Color? secondaryText,
    Color? surface,
    Color? elevatedSurface,
    Color? border,
    Color? strongBorder,
    Color? accentPressed,
    Color? success,
    Color? warning,
  }) {
    return VoiceBriefPalette(
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      surface: surface ?? this.surface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      border: border ?? this.border,
      strongBorder: strongBorder ?? this.strongBorder,
      accentPressed: accentPressed ?? this.accentPressed,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  VoiceBriefPalette lerp(ThemeExtension<VoiceBriefPalette>? other, double t) {
    if (other is! VoiceBriefPalette) return this;
    return VoiceBriefPalette(
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      strongBorder: Color.lerp(strongBorder, other.strongBorder, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension VoiceBriefTheme on BuildContext {
  VoiceBriefPalette get palette =>
      Theme.of(this).extension<VoiceBriefPalette>()!;
}
