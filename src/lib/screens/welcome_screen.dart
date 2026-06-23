import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/primary_scale_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  void _showLoginOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final palette = AppTheme.colorsOf(ctx);
        return Container(
          decoration: BoxDecoration(
            color: palette.bg.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: palette.cardBorder),
          ),
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.onSurface3.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryScaleButton(
                icon: LucideIcons.plusCircle,
                title: 'Создать класс',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/create');
                },
              ),
              const SizedBox(height: 16),
              PrimaryScaleButton(
                icon: LucideIcons.logIn,
                title: 'Войти в класс',
                isSecondary: true,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/join');
                },
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAdminLoginDialog(context);
                },
                child: Text(
                  'Войти как админ',
                  style: TextStyle(
                    color: palette.onSurface2,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _AdminLoginDialog(),
    );
  }

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
                    AppTheme.primary.withValues(alpha: 0.20),
                    AppTheme.primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
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
                  child: Icon(LucideIcons.graduationCap,
                      size: 44, color: AppTheme.primary),
                ),
                const SizedBox(height: 24),

                Text('Школьный Дневник', style: AppTextStyles.h1Serif(context)),
                const SizedBox(height: 8),
                Text(
                  'Расписание и задания\nдля вашего класса',
                  style: AppTextStyles.caption(context),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 4),

                // Swipe up gesture
                _SwipeUpToEnter(
                  onTriggered: () => _showLoginOptionsBottomSheet(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe Up Interaction
// ─────────────────────────────────────────────────────────────────────────────
class _SwipeUpToEnter extends StatefulWidget {
  final VoidCallback onTriggered;
  const _SwipeUpToEnter({required this.onTriggered});

  @override
  State<_SwipeUpToEnter> createState() => _SwipeUpToEnterState();
}

class _SwipeUpToEnterState extends State<_SwipeUpToEnter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _dragOffset = 0.0;
  final double _threshold = -60.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;
      if (_dragOffset > 0) _dragOffset = 0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset < _threshold) {
      widget.onTriggered();
    }
    setState(() {
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onTap: widget.onTriggered,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -6 * _pulseController.value),
                    child: child,
                  );
                },
                child: Icon(
                  LucideIcons.chevronUp,
                  color: palette.onSurface2,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'СВАЙПНИ ВВЕРХ',
                style: AppTextStyles.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
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
