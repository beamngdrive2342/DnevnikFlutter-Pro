import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DnevnikApp());
  unawaited(_bootstrapRuntime());
}

Future<void> _bootstrapRuntime() async {
  await ThemeController.initialize();
  await Future<void>.delayed(const Duration(seconds: 5));
  unawaited(_configureDisplayMode());
}

Future<void> _configureDisplayMode() async {
  if (!Platform.isAndroid) {
    return;
  }
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    debugPrint('Display mode setup skipped: $e');
  }
}

class DnevnikApp extends StatelessWidget {
  const DnevnikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.hydrated,
      builder: (context, hydrated, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.notifier,
          builder: (context, themeMode, child) {
            return MaterialApp(
              title: 'Дневник',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              themeAnimationDuration: const Duration(milliseconds: 300),
              themeAnimationCurve: Curves.easeInOut,
              locale: const Locale('ru', 'RU'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ru', 'RU'),
              ],
              home: const AuthGate(),
            );
          },
        );
      },
    );
  }
}
