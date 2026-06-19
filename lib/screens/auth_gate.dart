import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════
// SPLASH SCREEN — displayed while checking session
// ═══════════════════════════════════════════════════════════
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).bg,
      body: const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }
}
