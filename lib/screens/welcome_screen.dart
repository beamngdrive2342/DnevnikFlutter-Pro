import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import 'main_screen.dart';
import '../theme/app_theme.dart';
import 'create_class_screen.dart';
import 'join_class_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Scaffold(
      backgroundColor: palette.bg,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.1),
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
                    subtitle: 'Для администратора класса',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateClassScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Join class
                  _WelcomeButton(
                    icon: Icons.login_rounded,
                    title: 'Войти в класс',
                    subtitle: 'По коду от администратора',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const JoinClassScreen()),
                    ),
                  ),

                  const Spacer(),

                  // Admin login link
                  TextButton(
                    onPressed: () => _showAdminLoginDialog(context),
                    child: Text(
                      'Уже есть класс? Войти как админ',
                      style: TextStyle(color: palette.onSurface2, fontSize: 13),
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
  final String subtitle;
  final VoidCallback onTap;

  const _WelcomeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Material(
      color: palette.cardBg,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryLight,
                ),
                child: Icon(icon, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: palette.onBg,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.onSurface2,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.onSurface3),
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
class _AdminLoginDialog extends StatefulWidget {
  const _AdminLoginDialog();

  @override
  State<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<_AdminLoginDialog> {
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

    Navigator.of(context).pop(); // close dialog
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainScreen(role: 'admin', classId: classId),
      ),
      (route) => false,
    );
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
