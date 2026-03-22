import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sahara Warm Minimalism — тёмная тема дневника
class AppTheme {
  // ─── Основные цвета ───
  static const Color primary      = Color(0xFFC2652A);
  static const Color primaryDim   = Color(0xFFE08850);
  static const Color primaryLight = Color(0x26C2652A); // 15% opacity

  static const Color bg           = Color(0xFF120E0B);
  static const Color surface      = Color(0xAA1C1610);
  static const Color surface2     = Color(0xAA251C14);
  static const Color surface3     = Color(0xAA2E2218);
  static const Color cardBg       = Color(0x88231A12);
  static const Color cardBorder   = Color(0x14D8D0C8); // 8% opacity

  static const Color onBg         = Color(0xFFF5EDE4);
  static const Color onSurface    = Color(0xFFE8DDD4);
  static const Color onSurface2   = Color(0xFFB0A090);
  static const Color onSurface3   = Color(0xFF6E5C4A);

  static const Color success      = Color(0xFF5A8E5C);
  static const Color warning      = Color(0xFFB07430);
  static const Color danger       = Color(0xFF8C3C3C);

  // ─── Скругления ───
  static const double radiusSm    = 8;
  static const double radiusMd    = 12;
  static const double radiusLg    = 16;
  static const double radiusXl    = 20;

  // ─── Тень ───
  static List<BoxShadow> get shadowSoft => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get shadowCard => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 2)),
  ];

  // ─── Шрифты ───
  static const String fontSerif = 'EB Garamond';
  static const String fontSans  = 'Manrope';

  // ─── ThemeData ───
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryDim,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: onBg,
    ),
    fontFamily: fontSans,
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primaryDim,
      unselectedItemColor: onSurface3,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0, // Apple flat design
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0, // Apple buttons are completely flat
        shadowColor: Colors.transparent,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), // Standard iOS corner radius
        ),
        textStyle: const TextStyle(
          fontFamily: fontSans,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(
          fontFamily: fontSans,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface3,
      contentTextStyle: const TextStyle(
        color: onBg,
        fontSize: 15, // iOS standard body size
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
