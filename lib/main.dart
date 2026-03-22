import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'theme/app_theme.dart';
import 'screens/diary_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'data/schedule_data.dart';
import 'data/firestore_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const DnevnikApp());
}

class DnevnikApp extends StatelessWidget {
  const DnevnikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:
          'Р В Р’В Р Р†Р вЂљРЎСљР В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’ВµР В Р’В Р В РІР‚В Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚ВР В Р’В Р РЋРІР‚Сњ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      home: const RoleGate(),
    );
  }
}

// Р В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ў
// ROLE GATE Р В Р вЂ Р В РІР‚С™Р Р†Р вЂљРЎСљ simple PIN-code role selection on first launch
// Р В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ў
class RoleGate extends StatefulWidget {
  const RoleGate({super.key});
  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  bool _isLoading = true;
  String? _role; // 'admin' or 'student'

  // Admin PIN Р В Р вЂ Р В РІР‚С™Р Р†Р вЂљРЎСљ can be changed by admin later
  static const String _adminPin = '1234';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('dnevnik_role');
    if (!mounted) return;
    setState(() {
      _role = role;
      _isLoading = false;
    });
  }

  Future<void> _setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dnevnik_role', role);
    if (!mounted) return;
    setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    if (_role != null) {
      return MainScreen(role: _role!);
    }
    return _buildRoleSelector();
  }

  Widget _buildRoleSelector() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded,
                  size: 64, color: AppTheme.primary),
              const SizedBox(height: 24),
              const Text(
                  'Р В Р’В Р В Р С“Р В Р’В Р РЋРІР‚СњР В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ°Р В Р’В Р В РІР‚В¦Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р’В Р Р†РІР‚С›РІР‚вЂњ Р В Р’В Р Р†Р вЂљРЎСљР В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’ВµР В Р’В Р В РІР‚В Р В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚ВР В Р’В Р РЋРІР‚Сњ',
                  style: TextStyle(
                    fontFamily: AppTheme.fontSerif,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onBg,
                  )),
              const SizedBox(height: 8),
              const Text(
                  'Р В Р’В Р Р†Р вЂљРІвЂћСћР В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р’В Р вЂ™Р’В±Р В Р’В Р вЂ™Р’ВµР В Р Р‹Р В РІР‚С™Р В Р’В Р РЋРІР‚ВР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р вЂ™Р’Вµ Р В Р Р‹Р В РІР‚С™Р В Р’В Р РЋРІР‚СћР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р вЂ° Р В Р’В Р СћРІР‚ВР В Р’В Р вЂ™Р’В»Р В Р Р‹Р В Р РЏ Р В Р’В Р В РІР‚В Р В Р Р‹Р Р†Р вЂљР’В¦Р В Р’В Р РЋРІР‚СћР В Р’В Р СћРІР‚ВР В Р’В Р вЂ™Р’В°',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurface2,
                  )),
              const SizedBox(height: 48),
              // Student button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_rounded, size: 22),
                  label: const Text(
                      'Р В Р’В Р Р†Р вЂљРІвЂћСћР В Р’В Р РЋРІР‚СћР В Р’В Р Р†РІР‚С›РІР‚вЂњР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚В Р В Р’В Р РЋРІР‚СњР В Р’В Р вЂ™Р’В°Р В Р’В Р РЋРІР‚Сњ Р В Р Р‹Р РЋРІР‚СљР В Р Р‹Р Р†Р вЂљР Р‹Р В Р’В Р вЂ™Р’ВµР В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚ВР В Р’В Р РЋРІР‚Сњ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface3,
                    foregroundColor: AppTheme.primaryDim,
                  ),
                  onPressed: () => _setRole('student'),
                ),
              ),
              const SizedBox(height: 16),
              // Admin button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon:
                      const Icon(Icons.admin_panel_settings_rounded, size: 22),
                  label: const Text(
                      'Р В Р’В Р Р†Р вЂљРІвЂћСћР В Р’В Р РЋРІР‚СћР В Р’В Р Р†РІР‚С›РІР‚вЂњР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚В Р В Р’В Р РЋРІР‚СњР В Р’В Р вЂ™Р’В°Р В Р’В Р РЋРІР‚Сњ Р В Р’В Р вЂ™Р’В°Р В Р’В Р СћРІР‚ВР В Р’В Р РЋР’ВР В Р’В Р РЋРІР‚ВР В Р’В Р В РІР‚В¦'),
                  onPressed: () => _showAdminPinDialog(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAdminPinDialog() async {
    final pinController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2E2218),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
            'Р В Р’В Р Р†Р вЂљРІвЂћСћР В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’ВµР В Р’В Р СћРІР‚ВР В Р’В Р РЋРІР‚ВР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р вЂ™Р’Вµ PIN Р В Р’В Р вЂ™Р’В°Р В Р’В Р СћРІР‚ВР В Р’В Р РЋР’ВР В Р’В Р РЋРІР‚ВР В Р’В Р В РІР‚В¦Р В Р’В Р РЋРІР‚ВР В Р Р‹Р В РЎвЂњР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р Р‹Р В РІР‚С™Р В Р’В Р вЂ™Р’В°Р В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚СћР В Р Р‹Р В РІР‚С™Р В Р’В Р вЂ™Р’В°',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          style: const TextStyle(
              color: Colors.white, fontSize: 24, letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppTheme.surface3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.cardBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
                'Р В Р’В Р РЋРІР‚С”Р В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋР’ВР В Р’В Р вЂ™Р’ВµР В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’В°',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == _adminPin) {
                Navigator.pop(ctx);
                _setRole('admin');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Р В Р’В Р РЋРЎС™Р В Р’В Р вЂ™Р’ВµР В Р’В Р В РІР‚В Р В Р’В Р вЂ™Р’ВµР В Р Р‹Р В РІР‚С™Р В Р’В Р В РІР‚В¦Р В Р Р‹Р Р†Р вЂљРІвЂћвЂ“Р В Р’В Р Р†РІР‚С›РІР‚вЂњ PIN')),
                );
              }
            },
            child: const Text(
                'Р В Р’В Р Р†Р вЂљРІвЂћСћР В Р’В Р РЋРІР‚СћР В Р’В Р Р†РІР‚С›РІР‚вЂњР В Р Р‹Р Р†Р вЂљРЎв„ўР В Р’В Р РЋРІР‚В'),
          ),
        ],
      ),
    );
    pinController.dispose();
  }
}

// Р В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ў
// MAIN SCREEN
// Р В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ўР В Р вЂ Р Р†Р вЂљРЎС›Р РЋРІР‚в„ў
class MainScreen extends StatefulWidget {
  final String role;
  const MainScreen({super.key, required this.role});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const String _imageUploadUrl = 'https://freeimage.host/api/1/upload';
  static const String _imageUploadKey = '6d207e02198a847aa98d0a2a901485a5';
  static const Duration _uploadTimeout = Duration(seconds: 20);

  int _currentIndex = 0;
  final GlobalKey<DiaryScreenState> _diaryKey = GlobalKey<DiaryScreenState>();
  final GlobalKey<AdminPanelScreenState> _adminKey =
      GlobalKey<AdminPanelScreenState>();

  bool get isAdmin => widget.role == 'admin';

  Future<Map<String, String>?> _uploadImage(String path) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_imageUploadUrl));
      request.fields['key'] = _imageUploadKey;
      request.fields['action'] = 'upload';
      request.fields['format'] = 'json';
      request.files.add(await http.MultipartFile.fromPath('source', path));

      final response = await request.send().timeout(_uploadTimeout);
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final json = jsonDecode(respStr) as Map<String, dynamic>;
        if (json['image'] != null) {
          final fullUrl = json['image']['url'];
          return {'display': fullUrl.toString(), 'full': fullUrl.toString()};
        }
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
    return null;
  }

  Future<void> _cleanupTemporaryPickerFiles(Iterable<String> paths) async {
    try {
      final tempDirPath = (await getTemporaryDirectory()).path;
      final tempRoot = Directory(tempDirPath).absolute.path;

      for (final path in paths) {
        final absolutePath = File(path).absolute.path;
        if (!absolutePath.startsWith(tempRoot)) {
          continue;
        }

        final file = File(absolutePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Temp cleanup error: $e');
    }
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    if (isAdmin) {
      _screens = [
        DiaryScreen(key: _diaryKey),
        AdminPanelScreen(
          key: _adminKey,
          onHomeworkChanged: () {
            _diaryKey.currentState?.reloadHomework(forceRefresh: true);
          },
        ),
      ];
    } else {
      _screens = [
        DiaryScreen(key: _diaryKey),
      ];
    }
  }

  Future<void> _showAddHomeworkModal() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<_AddHomeworkResult>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHomeworkSheet(
        uploadImage: _uploadImage,
        cleanupTemporaryPickerFiles: _cleanupTemporaryPickerFiles,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    await _diaryKey.currentState?.reloadHomework(forceRefresh: true);
    await _adminKey.currentState?.reload(forceRefresh: true);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content:
            Text('Р—Р°РґР°РЅРёРµ РїРѕ ${result.subject} РґРѕР±Р°РІР»РµРЅРѕ'),
      ),
    );
  }

  Widget? _buildGlassyNavBar() {
    if (!isAdmin) return null; // BottomNavigationBar requires >= 2 items.

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label:
              'Р В Р’В Р Р†Р вЂљРЎС™Р В Р’В Р вЂ™Р’В»Р В Р’В Р вЂ™Р’В°Р В Р’В Р В РІР‚В Р В Р’В Р В РІР‚В¦Р В Р’В Р вЂ™Р’В°Р В Р Р‹Р В Р РЏ'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_rounded),
          label:
              'Р В Р’В Р РЋРІР‚в„ўР В Р’В Р СћРІР‚ВР В Р’В Р РЋР’ВР В Р’В Р РЋРІР‚ВР В Р’В Р В РІР‚В¦'),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              currentIndex: _currentIndex,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.onSurface2,
              showSelectedLabels: true,
              showUnselectedLabels: false,
              selectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              onTap: (i) => setState(() => _currentIndex = i),
              items: items,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                color: AppTheme.bg.withValues(alpha: 0.3),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassyNavBar(),
      floatingActionButton: isAdmin && _currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: PremiumGlowButton(
                onPressed: _showAddHomeworkModal,
                child: const Icon(Icons.add_rounded,
                    size: 32, color: Colors.white),
              ),
            )
          : null,
    );
  }
}

class _AddHomeworkResult {
  final String subject;

  const _AddHomeworkResult({required this.subject});
}

class _AddHomeworkSheet extends StatefulWidget {
  final Future<Map<String, String>?> Function(String path) uploadImage;
  final Future<void> Function(Iterable<String> paths)
      cleanupTemporaryPickerFiles;

  const _AddHomeworkSheet({
    required this.uploadImage,
    required this.cleanupTemporaryPickerFiles,
  });

  @override
  State<_AddHomeworkSheet> createState() => _AddHomeworkSheetState();
}

class _AddHomeworkSheetState extends State<_AddHomeworkSheet> {
  static const int _pickedImageQuality = 70;
  static const double _pickedImageMaxSide = 1920;

  final TextEditingController _taskController = TextEditingController();
  final List<String> _pickedImagePaths = <String>[];
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedSubject;
  late DateTime _selectedDeadline;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    var initDate = DateTime.now().add(const Duration(days: 1));
    while (initDate.weekday == 6 || initDate.weekday == 7) {
      initDate = initDate.add(const Duration(days: 1));
    }
    _selectedDeadline = initDate;
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      imageQuality: _pickedImageQuality,
      maxWidth: _pickedImageMaxSide,
      maxHeight: _pickedImageMaxSide,
    );
    if (!mounted || images.isEmpty) {
      return;
    }

    setState(() {
      for (final image in images) {
        if (!_pickedImagePaths.contains(image.path)) {
          _pickedImagePaths.add(image.path);
        }
      }
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_selectedSubject == null || _taskController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Заполните предмет и задание')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final displayUrls = <String>[];
    final fullUrls = <String>[];
    var hasError = false;

    final uploadResults = await Future.wait(
      _pickedImagePaths.map(widget.uploadImage),
    );
    if (!mounted) {
      return;
    }

    for (final result in uploadResults) {
      if (result != null) {
        displayUrls.add(result['display']!);
        fullUrls.add(result['full']!);
      } else {
        hasError = true;
      }
    }

    if (hasError) {
      setState(() => _isUploading = false);
      messenger.showSnackBar(
        const SnackBar(
          content:
              Text('Ошибка при загрузке фото в облако. Попробуйте ещё раз.'),
        ),
      );
      return;
    }

    final hw = HomeworkItem(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      subject: _selectedSubject!,
      task: _taskController.text.trim(),
      deadline:
          '${_selectedDeadline.year}-${_selectedDeadline.month.toString().padLeft(2, '0')}-${_selectedDeadline.day.toString().padLeft(2, '0')}',
      imageUrl: null,
      imageUrls: displayUrls.isNotEmpty ? displayUrls : null,
      fullResolutionUrls: fullUrls.isNotEmpty ? fullUrls : null,
      done: false,
      fromSchedule: false,
    );

    final success = await FirestoreService.addHomework(hw);
    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() => _isUploading = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ошибка при сохранении в базу данных.'),
        ),
      );
      return;
    }

    await widget.cleanupTemporaryPickerFiles(_pickedImagePaths);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(_AddHomeworkResult(subject: _selectedSubject!));
  }

  Widget _buildFormLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppTheme.onSurface2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF251C14),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Добавить задание',
                        style: TextStyle(
                          fontFamily: AppTheme.fontSerif,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onBg,
                        ),
                      ),
                      Material(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(100),
                        child: InkWell(
                          onTap: _isUploading
                              ? null
                              : () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(100),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.close_rounded,
                              color: AppTheme.onSurface2,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildFormLabel(
                      'Р В РЎСџР РЋР вЂљР В Р’ВµР В РўвЂР В РЎВР В Р’ВµР РЋРІР‚С™'),
                  const SizedBox(height: 6),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2218),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubject,
                        hint: Text(
                          'Выберите предмет',
                          style: TextStyle(
                            color: AppTheme.onSurface3.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2E2218),
                        style:
                            const TextStyle(color: AppTheme.onBg, fontSize: 14),
                        items: allSubjects
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedSubject = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFormLabel('Задание'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _taskController,
                    maxLines: 4,
                    style: const TextStyle(color: AppTheme.onBg, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Опишите задание...',
                      hintStyle: TextStyle(
                          color: AppTheme.onSurface3.withValues(alpha: 0.8)),
                      filled: true,
                      fillColor: const Color(0xFF2E2218),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFormLabel('Фото (необязательно)'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _isUploading ? null : _pickImages,
                    child: Container(
                      width: double.infinity,
                      height: _pickedImagePaths.isEmpty ? 50 : 170,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2218),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: _pickedImagePaths.isEmpty
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library_rounded,
                                  color: AppTheme.onSurface3
                                      .withValues(alpha: 0.8),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Добавить фото',
                                  style: TextStyle(
                                    color: AppTheme.onSurface3
                                        .withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.all(8),
                              itemCount: _pickedImagePaths.length + 1,
                              itemBuilder: (context, idx) {
                                if (idx == _pickedImagePaths.length) {
                                  return GestureDetector(
                                    onTap: _isUploading ? null : _pickImages,
                                    child: Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface2,
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSm),
                                        border: Border.all(
                                            color: AppTheme.cardBorder),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.add_a_photo_rounded,
                                          color: AppTheme.primaryDim,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final path = _pickedImagePaths[idx];
                                return Container(
                                  width: 120,
                                  margin: EdgeInsets.only(
                                    right: idx == _pickedImagePaths.length - 1
                                        ? 0
                                        : 8,
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusSm),
                                          child: Image.file(File(path),
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: _isUploading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _pickedImagePaths
                                                        .removeAt(idx);
                                                  });
                                                },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFormLabel('Срок сдачи'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _isUploading
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              locale: const Locale('ru', 'RU'),
                              initialDate: _selectedDeadline,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              selectableDayPredicate: (DateTime val) =>
                                  val.weekday != 6 && val.weekday != 7,
                              builder: (context, child) {
                                return Theme(
                                  data: AppTheme.darkTheme.copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppTheme.primary,
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF251C14),
                                      onSurface: AppTheme.onBg,
                                    ),
                                    dialogTheme: const DialogThemeData(
                                      backgroundColor: Color(0xFF251C14),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (!mounted || picked == null) {
                              return;
                            }
                            setState(() => _selectedDeadline = picked);
                          },
                    child: Container(
                      height: 44,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2218),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppTheme.onSurface2,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_selectedDeadline.day}.${_selectedDeadline.month.toString().padLeft(2, '0')}.${_selectedDeadline.year}',
                            style: const TextStyle(
                                color: AppTheme.onBg, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submit,
                      child: _isUploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Сохранить задание'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumGlowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const PremiumGlowButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  State<PremiumGlowButton> createState() => _PremiumGlowButtonState();
}

class _PremiumGlowButtonState extends State<PremiumGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 64.0;
    const Color glowColor = AppTheme.primary; // Orange glow to match theme

    return GestureDetector(
      onTap: widget.onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Atmosphere Glow (The soft light underneath)
          Container(
            width: size * 1.2,
            height: size * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // 2. Rotating Border Glow
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      glowColor.withValues(alpha: 0.8),
                      glowColor,
                      glowColor.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
                    transform:
                        GradientRotation(_controller.value * 2 * 3.14159),
                  ),
                ),
              );
            },
          ),

          // 3. Black Inner Body
          Container(
            width: size - 3,
            height: size - 3,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: Center(child: widget.child),
          ),

          // 4. Glass Reflection (Subtle top highlight)
          Positioned(
            top: 6,
            child: Container(
              width: size * 0.6,
              height: size * 0.3,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
