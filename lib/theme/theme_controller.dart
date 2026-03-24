import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeController {
  ThemeController._();

  static const String _themeKey = 'dnevnik_theme_mode';
  static final ValueNotifier<ThemeMode> notifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);
  static final ValueNotifier<bool> hydrated = ValueNotifier<bool>(false);

  static bool _initialized = false;
  static SharedPreferences? _prefs;

  static bool get isDark => notifier.value == ThemeMode.dark;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();
    final savedMode = _prefs!.getString(_themeKey);
    notifier.value = savedMode == 'light' ? ThemeMode.light : ThemeMode.dark;

    _applySystemOverlayStyle(notifier.value);
    notifier.addListener(() {
      _applySystemOverlayStyle(notifier.value);
    });
    hydrated.value = true;
  }

  static Future<void> setMode(ThemeMode mode) async {
    if (notifier.value == mode) {
      return;
    }

    notifier.value = mode;
    final modeStr = mode == ThemeMode.light ? 'light' : 'dark';

    if (_prefs != null) {
      unawaited(_prefs!.setString(_themeKey, modeStr));
      return;
    }

    // Fallback path if toggle happened before initialization completed.
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    unawaited(prefs.setString(_themeKey, modeStr));
  }

  static Future<void> toggle() {
    return setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  static void _applySystemOverlayStyle(ThemeMode mode) {
    final isDarkMode = mode == ThemeMode.dark;
    final palette = isDarkMode ? AppTheme.darkPalette : AppTheme.lightPalette;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: palette.surface,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
