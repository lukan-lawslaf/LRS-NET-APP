import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colours ──────────────────────────────────────────────
  static const Color primary      = Color(0xFF0D47A1); // deep blue
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color accent       = Color(0xFF00E676); // neon green
  static const Color surface      = Color(0xFF121820);
  static const Color card         = Color(0xFF1A2332);
  static const Color cardBorder   = Color(0xFF263245);
  static const Color textPrimary  = Color(0xFFE8ECF1);
  static const Color textSecondary= Color(0xFF8A99AE);
  static const Color hikerBubble  = Color(0xFF1B3A4B);
  static const Color baseBubble   = Color(0xFF0D47A1);
  static const Color danger       = Color(0xFFEF5350);
  static const Color success      = Color(0xFF66BB6A);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: surface,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: textPrimary,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: accent,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      hintStyle: const TextStyle(color: textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
    ),
  );
}
