import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color cardBg;
  final Color cardBorder;
  final Color onBg;
  final Color onSurface;
  final Color onSurface2;
  final Color onSurface3;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.cardBg,
    required this.cardBorder,
    required this.onBg,
    required this.onSurface,
    required this.onSurface2,
    required this.onSurface3,
  });

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? cardBg,
    Color? cardBorder,
    Color? onBg,
    Color? onSurface,
    Color? onSurface2,
    Color? onSurface3,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      cardBg: cardBg ?? this.cardBg,
      cardBorder: cardBorder ?? this.cardBorder,
      onBg: onBg ?? this.onBg,
      onSurface: onSurface ?? this.onSurface,
      onSurface2: onSurface2 ?? this.onSurface2,
      onSurface3: onSurface3 ?? this.onSurface3,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surface2: Color.lerp(surface2, other.surface2, t) ?? surface2,
      surface3: Color.lerp(surface3, other.surface3, t) ?? surface3,
      cardBg: Color.lerp(cardBg, other.cardBg, t) ?? cardBg,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      onBg: Color.lerp(onBg, other.onBg, t) ?? onBg,
      onSurface: Color.lerp(onSurface, other.onSurface, t) ?? onSurface,
      onSurface2: Color.lerp(onSurface2, other.onSurface2, t) ?? onSurface2,
      onSurface3: Color.lerp(onSurface3, other.onSurface3, t) ?? onSurface3,
    );
  }
}

/// Sahara Warm Minimalism - school diary theme
class AppTheme {
  // --- Base colors ---
  static const Color primary = Color(0xFFC2652A);
  static const Color primaryDim = Color(0xFFE08850);
  static const Color primaryLight = Color(0x26C2652A); // 15% opacity

  // Legacy dark constants (used across old screens)
  static const Color bg = Color(0xFF120E0B);
  static const Color surface = Color(0xAA1C1610);
  static const Color surface2 = Color(0xAA251C14);
  static const Color surface3 = Color(0xAA2E2218);
  static const Color cardBg = Color(0x88231A12);
  static const Color cardBorder = Color(0x14D8D0C8); // 8% opacity

  static const Color onBg = Color(0xFFF5EDE4);
  static const Color onSurface = Color(0xFFE8DDD4);
  static const Color onSurface2 = Color(0xFFB0A090);
  static const Color onSurface3 = Color(0xFF6E5C4A);

  static const Color success = Color(0xFF5A8E5C);
  static const Color warning = Color(0xFFB07430);
  static const Color danger = Color(0xFF8C3C3C);

  static const AppPalette darkPalette = AppPalette(
    bg: bg,
    surface: surface,
    surface2: surface2,
    surface3: surface3,
    cardBg: cardBg,
    cardBorder: cardBorder,
    onBg: onBg,
    onSurface: onSurface,
    onSurface2: onSurface2,
    onSurface3: onSurface3,
  );

  static const AppPalette lightPalette = AppPalette(
    bg: Color(0xFFF8F5F1),
    surface: Color(0xFFF1ECE5),
    surface2: Color(0xFFE8DFD3),
    surface3: Color(0xFFDDD0C1),
    cardBg: Color(0xFFFFFFFF),
    cardBorder: Color(0x1F4E3D2E),
    onBg: Color(0xFF2D2218),
    onSurface: Color(0xFF3B2E22),
    onSurface2: Color(0xFF726150),
    onSurface3: Color(0xFFA08E7C),
  );

  // --- Radius ---
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // --- Shadow ---
  static List<BoxShadow> get shadowSoft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];
  static List<BoxShadow> get shadowCard => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  // --- Fonts ---
  static const String fontSerif = 'EB Garamond';
  static const String fontSans = 'Manrope';

  static AppPalette colorsOf(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? darkPalette;
  }

  // --- ThemeData ---
  static ThemeData get darkTheme => _buildTheme(
        palette: darkPalette,
        brightness: Brightness.dark,
        overlayStyle: SystemUiOverlayStyle.light,
      );

  static ThemeData get lightTheme => _buildTheme(
        palette: lightPalette,
        brightness: Brightness.light,
        overlayStyle: SystemUiOverlayStyle.dark,
      );

  static ThemeData _buildTheme({
    required AppPalette palette,
    required Brightness brightness,
    required SystemUiOverlayStyle overlayStyle,
  }) {
    final baseScheme = brightness == Brightness.dark
        ? const ColorScheme.dark()
        : const ColorScheme.light();

    final scheme = baseScheme.copyWith(
      primary: primary,
      secondary: primaryDim,
      surface: palette.surface,
      onSurface: palette.onBg,
      onPrimary: Colors.white,
      outline: palette.cardBorder,
    );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: palette.bg,
      primaryColor: primary,
      colorScheme: scheme,
      fontFamily: fontSans,
      extensions: <ThemeExtension<dynamic>>[
        palette,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bg,
        elevation: 0,
        systemOverlayStyle: overlayStyle,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: primaryDim,
        unselectedItemColor: palette.onSurface3,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
        backgroundColor: palette.surface3,
        contentTextStyle: TextStyle(
          color: palette.onBg,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
