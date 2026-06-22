import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: palette.bg,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -150,
            left: -100,
            right: -100,
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.25),
                    AppTheme.primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.1, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppTheme.primary.withValues(alpha: 0.3),
                        AppTheme.primary.withValues(alpha: 0.08),
                      ]),
                    ),
                    child: const Icon(Icons.school_rounded,
                        size: 44, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 24),

                  Text('Школьный Дневник',
                      style: TextStyle(
                        fontFamily: AppTheme.fontSerif,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: palette.onBg,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Расписание и задания для вашего класса',
                    style: TextStyle(fontSize: 14, color: palette.onSurface2),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // Create class
                  _WelcomeButton(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Создать класс',
                    onTap: () => context.push('/create'),
                  ),
                  const SizedBox(height: 16),

                  // Join class
                  _WelcomeButton(
                    icon: Icons.login_rounded,
                    title: 'Войти в класс',
                    onTap: () => context.push('/join'),
                  ),

                  const Spacer(),

                  // Admin login link
                  TextButton(
                    onPressed: () => _showAdminLoginDialog(context),
                    child: Text(
                      'Войти как админ',
                      style: TextStyle(
                        color: palette.onSurface2,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _AdminLoginDialog(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome button card
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _WelcomeButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Material(
      color: palette.cardBg.withValues(alpha: 0.6), // Dark translucent
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: palette.onBg, size: 28),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: palette.onBg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 28), // Balance for centering text
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin login dialog
// ─────────────────────────────────────────────────────────────────────────────
class _AdminLoginDialog extends ConsumerStatefulWidget {
  const _AdminLoginDialog();

  @override
  ConsumerState<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends ConsumerState<_AdminLoginDialog> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final classId = await AuthService.loginAdmin(email, pass);

    if (!mounted) return;

    if (classId == null) {
      setState(() {
        _loading = false;
        _error = 'Неверный email или пароль';
      });
      return;
    }

    ref.read(authProvider.notifier).login(classId, 'admin');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bg = palette.surface2.withValues(alpha: 1);
    final fieldBg = palette.surface3.withValues(alpha: 1);

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Вход для админа',
          style: TextStyle(color: palette.onBg, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_emailC, 'Email', fieldBg, palette,
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(_passC, 'Пароль', fieldBg, palette,
              obscure: true, onSubmit: (_) => _submit()),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('Отмена', style: TextStyle(color: palette.onSurface2)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Войти'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    Color fillColor,
    AppPalette palette, {
    bool obscure = false,
    TextInputType? keyboard,
    ValueChanged<String>? onSubmit,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      onSubmitted: onSubmit,
      style: TextStyle(color: palette.onBg, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.onSurface2, fontSize: 14),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}
