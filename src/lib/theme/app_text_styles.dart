import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppTextStyles {
  // H1: Large, Serif, Elegant
  static TextStyle h1Serif(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return TextStyle(
      fontFamily: AppTheme.fontSerif,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: palette.onBg,
      height: 1.2,
    );
  }

  // H2: Section Titles, Sans-serif
  static TextStyle h2Sans(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return TextStyle(
      fontFamily: AppTheme.fontSans,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: palette.onBg,
      letterSpacing: -0.5,
    );
  }

  // Body: Regular text
  static TextStyle body(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return TextStyle(
      fontFamily: AppTheme.fontSans,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: palette.onBg,
    );
  }

  // Caption: Small secondary text
  static TextStyle caption(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return TextStyle(
      fontFamily: AppTheme.fontSans,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: palette.onSurface2,
    );
  }
}
