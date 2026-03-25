import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeRevealTransition {
  final ThemeMode fromMode;
  final ThemeMode toMode;
  final int token;

  const ThemeRevealTransition({
    required this.fromMode,
    required this.toMode,
    required this.token,
  });
}

class ThemeController {
  ThemeController._();

  static const String _themeKey = 'dnevnik_theme_mode';
  static final ValueNotifier<ThemeMode> notifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);
  static final ValueNotifier<bool> hydrated = ValueNotifier<bool>(false);
  static final ValueNotifier<ThemeRevealTransition?> reveal =
      ValueNotifier<ThemeRevealTransition?>(null);

  static bool _initialized = false;
  static SharedPreferences? _prefs;
  static int _transitionToken = 0;

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

    final previousMode = notifier.value;
    final token = ++_transitionToken;
    reveal.value = ThemeRevealTransition(
      fromMode: previousMode,
      toMode: mode,
      token: token,
    );

    await Future<void>.delayed(const Duration(milliseconds: 170));
    if (_transitionToken != token) {
      return;
    }

    notifier.value = mode;
    final modeStr = mode == ThemeMode.light ? 'light' : 'dark';

    if (_prefs != null) {
      unawaited(_prefs!.setString(_themeKey, modeStr));
    } else {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      unawaited(prefs.setString(_themeKey, modeStr));
    }

    await Future<void>.delayed(const Duration(milliseconds: 230));
    if (_transitionToken == token) {
      reveal.value = null;
    }
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
