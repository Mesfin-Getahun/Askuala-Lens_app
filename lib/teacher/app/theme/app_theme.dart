import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const seedColor = Color(0xFF0F766E);
    const surfaceTint = Color(0xFFF4F7F5);
    const appFontFamily = 'Arial';

    return ThemeData(
      useMaterial3: true,
      fontFamily: appFontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ).copyWith(surface: Colors.white, surfaceContainerHighest: surfaceTint),
      scaffoldBackgroundColor: const Color(0xFFF3F6F8),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: appFontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
        titleLarge: TextStyle(
          fontFamily: appFontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
        titleMedium: TextStyle(
          fontFamily: appFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        bodyMedium: TextStyle(
          fontFamily: appFontFamily,
          fontSize: 14,
          color: Color(0xFF475569),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: seedColor,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
