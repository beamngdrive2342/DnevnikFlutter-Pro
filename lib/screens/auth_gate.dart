import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/firestore_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'welcome_screen.dart' as screens_welcome;

// ═══════════════════════════════════════════════════════════
// AUTH GATE — check saved session
// ═══════════════════════════════════════════════════════════
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AppPalette get palette => AppTheme.colorsOf(context);

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final classId = await AuthService.getSavedClassId();
    final role = await AuthService.getSavedRole();

    if (classId != null && role != null) {
      FirestoreService.setClassId(classId);
      final restored = await AuthService.restoreSession();
      if (restored) {
        final loaded = await AuthService.loadClassData(classId);
        if (!mounted) return;
        if (loaded) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainScreen(role: role, classId: classId),
            ),
          );
          return;
        }
      }
      await AuthService.logout();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const screens_welcome.WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.bg,
      body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }
}
