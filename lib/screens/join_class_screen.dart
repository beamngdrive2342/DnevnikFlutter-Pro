import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_service.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _codeC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  String? _error;

  AppPalette get palette => AppTheme.colorsOf(context);

  @override
  void dispose() {
    _codeC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeC.text.trim();
    final pass = _passC.text;
    if (code.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }
    if (code.length < 6) {
      setState(() => _error = 'Код класса — 6 символов');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final classId = await AuthService.joinClass(code, pass);

    if (!mounted) return;

    if (classId == null) {
      setState(() {
        _loading = false;
        _error = 'Неверный код или пароль';
      });
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainScreen(role: 'student', classId: classId),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldBg = palette.surface3.withValues(alpha: 1);

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.onBg),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryLight,
                  ),
                  child: const Icon(Icons.login_rounded,
                      size: 32, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('Войти в класс',
                    style: TextStyle(
                      fontFamily: AppTheme.fontSerif,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: palette.onBg,
                    )),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Введите код и пароль от администратора',
                  style: TextStyle(fontSize: 13, color: palette.onSurface2),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Code field
              _label('Код класса'),
              const SizedBox(height: 6),
              TextField(
                controller: _codeC,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  UpperCaseFormatter(),
                ],
                style: TextStyle(
                  color: palette.onBg,
                  fontSize: 22,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • • • •',
                  hintStyle: TextStyle(
                      color: palette.onSurface3.withValues(alpha: 0.6),
                      letterSpacing: 6),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password field
              _label('Пароль класса'),
              const SizedBox(height: 6),
              TextField(
                controller: _passC,
                obscureText: true,
                onSubmitted: (_) => _submit(),
                style: TextStyle(color: palette.onBg, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Введите пароль',
                  hintStyle: TextStyle(
                      color: palette.onSurface3.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Войти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.onSurface2,
        ));
  }
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
