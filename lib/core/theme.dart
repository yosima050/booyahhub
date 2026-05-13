import 'package:flutter/material.dart';

class BooyahTheme {
  // ── Brand Colors ──
  static const Color bg        = Color(0xFF0A0A0A);
  static const Color surface   = Color(0xFF141414);
  static const Color card      = Color(0xFF1A1010);
  static const Color maroon    = Color(0xFF8B0000);
  static const Color maroonB   = Color(0xFFB22222);
  static const Color maroonL   = Color(0xFFCC3333);
  static const Color maroonGlow= Color(0xFFFF4444);
  static const Color maroonD   = Color(0xFF5C0000);
  static const Color gold      = Color(0xFFFFD700);
  static const Color goldD     = Color(0xFFB8860B);
  static const Color silver    = Color(0xFFC0C0C0);
  static const Color bronze    = Color(0xFFCD7F32);
  static const Color textPri   = Color(0xFFFFFFFF);
  static const Color textSec   = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFF888888);
  static const Color green     = Color(0xFF00C853);
  static const Color yellow    = Color(0xFFFFAB00);
  static const Color red       = Color(0xFFFF1744);

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: maroon,
      colorScheme: const ColorScheme.dark(
        primary: maroon,
        secondary: maroonB,
        surface: surface,
        error: red,
      ),
      fontFamily: 'Rajdhani',
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPri,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPri,
          letterSpacing: 2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: maroonB,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: maroon,
          foregroundColor: textPri,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: maroon.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: maroon.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: maroonB),
        ),
        labelStyle: const TextStyle(color: textMuted, fontSize: 12),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      ),
      cardTheme: CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: maroon.withOpacity(0.25)),
        ),
        elevation: 4,
        shadowColor: Colors.black54,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: maroon,
        labelStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: maroon.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      dividerColor: Colors.white.withOpacity(0.06),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w900, color: textPri),
        headlineMedium: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, color: textPri),
        titleLarge: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 18, color: textPri),
        titleMedium: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 15, color: textPri),
        bodyLarge: TextStyle(fontFamily: 'Rajdhani', fontSize: 14, color: textSec),
        bodyMedium: TextStyle(fontFamily: 'Rajdhani', fontSize: 12, color: textSec),
        labelSmall: TextStyle(fontFamily: 'Rajdhani', fontSize: 10, color: textMuted, letterSpacing: 1),
      ),
    );
  }
}
