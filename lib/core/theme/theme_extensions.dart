import 'package:flutter/material.dart';

/// Brand & status theme extension matching the approved Master Prompt 2 design token system.
@immutable
class AppBrandTheme extends ThemeExtension<AppBrandTheme> {
  final Color brassPrimary;
  final Color brassSoft;
  final Color roleAccent;
  final Color statusApplied;
  final Color statusShortlisted;
  final Color statusRejected;
  final Color statusPending;
  final Color cardBorder;
  final Color surfaceAlt;
  final Color textMuted;

  const AppBrandTheme({
    required this.brassPrimary,
    required this.brassSoft,
    required this.roleAccent,
    required this.statusApplied,
    required this.statusShortlisted,
    required this.statusRejected,
    required this.statusPending,
    required this.cardBorder,
    required this.surfaceAlt,
    required this.textMuted,
  });

  @override
  AppBrandTheme copyWith({
    Color? brassPrimary,
    Color? brassSoft,
    Color? roleAccent,
    Color? statusApplied,
    Color? statusShortlisted,
    Color? statusRejected,
    Color? statusPending,
    Color? cardBorder,
    Color? surfaceAlt,
    Color? textMuted,
  }) {
    return AppBrandTheme(
      brassPrimary: brassPrimary ?? this.brassPrimary,
      brassSoft: brassSoft ?? this.brassSoft,
      roleAccent: roleAccent ?? this.roleAccent,
      statusApplied: statusApplied ?? this.statusApplied,
      statusShortlisted: statusShortlisted ?? this.statusShortlisted,
      statusRejected: statusRejected ?? this.statusRejected,
      statusPending: statusPending ?? this.statusPending,
      cardBorder: cardBorder ?? this.cardBorder,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppBrandTheme lerp(ThemeExtension<AppBrandTheme>? other, double t) {
    if (other is! AppBrandTheme) return this;
    return AppBrandTheme(
      brassPrimary: Color.lerp(brassPrimary, other.brassPrimary, t)!,
      brassSoft: Color.lerp(brassSoft, other.brassSoft, t)!,
      roleAccent: Color.lerp(roleAccent, other.roleAccent, t)!,
      statusApplied: Color.lerp(statusApplied, other.statusApplied, t)!,
      statusShortlisted: Color.lerp(statusShortlisted, other.statusShortlisted, t)!,
      statusRejected: Color.lerp(statusRejected, other.statusRejected, t)!,
      statusPending: Color.lerp(statusPending, other.statusPending, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}
