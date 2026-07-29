import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_extensions.dart';

class AppTheme {
  AppTheme._();

  // ── Light Theme Tokens ──────────────────────────────────────────────────
  static final lightBrandTheme = AppBrandTheme(
    brassPrimary: const Color(0xA9752F),
    brassSoft: const Color(0xA9752F).withValues(alpha: 0.12),
    roleAccent: const Color(0xA9752F),
    statusApplied: const Color(0xA9752F),
    statusShortlisted: const Color(0xFF2F6B4F),
    statusRejected: const Color(0xFFB33F3A),
    statusPending: const Color(0xFF3E5C76),
    cardBorder: const Color(0xFFDADCE1),
    surfaceAlt: const Color(0xFFE9EAEC),
    textMuted: const Color(0xFF5B6472),
  );

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF14171C),
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF14171C),
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF14171C),
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF14171C),
      ),
      labelSmall: GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF5B6472),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xA9752F),
        onPrimary: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF14171C),
        surfaceContainerHighest: Color(0xFFE9EAEC),
        outline: Color(0xFFDADCE1),
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F2F4),
      textTheme: textTheme,
      extensions: [lightBrandTheme],
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: const Color(0xFF14171C),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF14171C),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE9EAEC),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF5B6472), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDADCE1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDADCE1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xA9752F), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB33F3A)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ── Dark Theme Tokens (Pure OLED #000000) ────────────────────────────────
  static final darkBrandTheme = AppBrandTheme(
    brassPrimary: const Color(0xFFC89446),
    brassSoft: const Color(0xFFC89446).withValues(alpha: 0.16),
    roleAccent: const Color(0xFFC89446),
    statusApplied: const Color(0xFFC89446),
    statusShortlisted: const Color(0xFF4C9172),
    statusRejected: const Color(0xFFD6635D),
    statusPending: const Color(0xFF6C8FB0),
    cardBorder: const Color(0xFF232428),
    surfaceAlt: const Color(0xFF1B1C20),
    textMuted: const Color(0xFF9AA3AF),
  );

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF2F1EC),
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: const Color(0xFFF2F1EC),
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF2F1EC),
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFF2F1EC),
      ),
      labelSmall: GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF9AA3AF),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFC89446),
        onPrimary: Color(0xFF0A0A0B),
        surface: Color(0xFF111214), // Lifted dark surface for cards
        onSurface: Color(0xFFF2F1EC),
        surfaceContainerHighest: Color(0xFF1B1C20),
        outline: Color(0xFF232428),
      ),
      scaffoldBackgroundColor: Colors.black, // Pure OLED Black per spec
      textTheme: textTheme,
      extensions: [darkBrandTheme],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFF2F1EC),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFF2F1EC),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B1C20),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF9AA3AF), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF232428)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF232428)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC89446), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD6635D)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
