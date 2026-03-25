import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/diary_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'data/schedule_data.dart';
import 'data/firestore_service.dart';
import 'utils/image_data.dart';
import 'widgets/fast_page_scroll_physics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DnevnikApp());
  unawaited(_bootstrapRuntime());
}

Future<void> _bootstrapRuntime() async {
  await ThemeController.initialize();
  // Give the first navigation/render path time to stabilize before touching
  // vendor-specific display mode APIs.
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
              themeAnimationDuration: Duration.zero,
              themeAnimationCurve: Curves.linear,
              locale: const Locale('ru', 'RU'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ru', 'RU'),
              ],
              builder: (context, child) {
                return Stack(
                  children: [
                    child ?? const SizedBox.shrink(),
                    const _ThemeRevealOverlay(),
                  ],
                );
              },
              home: const RoleGate(),
            );
          },
        );
      },
    );
  }
}

// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
// ROLE GATE вЂ” simple PIN-code role selection on first launch
// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
class RoleGate extends StatefulWidget {
  const RoleGate({super.key});
  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  bool _isLoading = true;
  String? _role; // 'admin' or 'student'
  AppPalette get palette => AppTheme.colorsOf(context);

  // Admin PIN вЂ” can be changed by admin later
  static const String _adminPin = '1234';

  @override
  void initState() {
    super.initState();
    _loadRole();
    _scheduleStartupWarmup();
  }

  void _scheduleStartupWarmup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(FirestoreService.getHomework());
    });
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
      return Scaffold(
        backgroundColor: palette.bg,
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    if (_role != null) {
      return MainScreen(role: _role!);
    }
    return _buildRoleSelector();
  }

  Widget _buildRoleSelector() {
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded,
                  size: 64, color: AppTheme.primary),
              const SizedBox(height: 24),
              Text('Школьный дневник',
                  style: TextStyle(
                    fontFamily: AppTheme.fontSerif,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: palette.onBg,
                  )),
              const SizedBox(height: 8),
              Text('Выберите роль для входа',
                  style: TextStyle(
                    fontSize: 14,
                    color: palette.onSurface2,
                  )),
              const SizedBox(height: 48),
              // Student button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_rounded, size: 22),
                  label: const Text('Войти как ученик'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.surface3,
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
                  label: const Text('Войти как админ'),
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
    final isAuthorized = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _AdminPinDialog(expectedPin: _adminPin),
    );

    if (isAuthorized == true) {
      await _setRole('admin');
    }
  }
}

class _AdminPinDialog extends StatefulWidget {
  final String expectedPin;

  const _AdminPinDialog({required this.expectedPin});

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> {
  late final TextEditingController _pinController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pinController.text == widget.expectedPin) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorText = 'Неверный PIN';
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final dialogSurface = palette.surface2.withValues(alpha: 1);
    final fieldSurface = palette.surface3.withValues(alpha: 1);

    return AlertDialog(
      backgroundColor: dialogSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Введите PIN администратора',
        style: TextStyle(color: palette.onBg, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            autofocus: true,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
            style: TextStyle(
              color: palette.onBg,
              fontSize: 24,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              errorText: _errorText,
              filled: true,
              fillColor: fieldSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Отмена',
            style: TextStyle(color: palette.onSurface2),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Войти'),
        ),
      ],
    );
  }
}

class _ThemeRevealOverlay extends StatelessWidget {
  const _ThemeRevealOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<ThemeRevealTransition?>(
        valueListenable: ThemeController.reveal,
        builder: (context, transition, _) {
          if (transition == null) {
            return const SizedBox.shrink();
          }

          final targetPalette = transition.toMode == ThemeMode.dark
              ? AppTheme.darkPalette
              : AppTheme.lightPalette;

          return TweenAnimationBuilder<double>(
            key: ValueKey<int>(transition.token),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ThemeRevealPainter(
                  progress: value,
                  color: targetPalette.bg,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ThemeRevealPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ThemeRevealPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width - 28, 28);
    final maxRadius =
        math.sqrt((size.width * size.width) + (size.height * size.height));
    final radius = lerpDouble(0, maxRadius, progress) ?? 0;
    final paint = Paint()..color = color;
    canvas.drawCircle(origin, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ThemeRevealPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
// MAIN SCREEN
// в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
class MainScreen extends StatefulWidget {
  final String role;
  const MainScreen({super.key, required this.role});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const int _pickedImageQuality = 55;
  static const double _pickedImageMaxSide = 1280;
  static const int _maxEmbeddedImageChars = 700000;

  int _currentIndex = 0;
  final GlobalKey<DiaryScreenState> _diaryKey = GlobalKey<DiaryScreenState>();
  final GlobalKey<AdminPanelScreenState> _adminKey =
      GlobalKey<AdminPanelScreenState>();
  final ImagePicker _imagePicker = ImagePicker();
  late final PageController _rootPageController;

  bool get isAdmin => widget.role == 'admin';
  AppPalette get palette => AppTheme.colorsOf(context);

  Future<String?> _prepareEmbeddedImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) {
        return null;
      }
      return encodeInlineImageData(
        bytes,
        mimeType: inferImageMimeType(path),
      );
    } catch (e) {
      debugPrint('Image prepare error: $e');
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

  late final Widget _diaryScreen;
  Widget? _adminScreen;

  @override
  void initState() {
    super.initState();
    _diaryScreen = DiaryScreen(key: _diaryKey);
    _rootPageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _rootPageController.dispose();
    super.dispose();
  }

  Widget _buildAdminScreen() {
    return AdminPanelScreen(
      key: _adminKey,
      onHomeworkChanged: () {
        _diaryKey.currentState?.reloadHomework(forceRefresh: true);
      },
    );
  }

  Widget _buildRootPage(int index) {
    if (index == 0) {
      return _diaryScreen;
    }
    return _adminScreen ??= _buildAdminScreen();
  }

  void _handleNavigationTap(int index) {
    if (_currentIndex == index) {
      return;
    }

    if (isAdmin && index == 1 && _adminScreen == null) {
      setState(() {
        _adminScreen = _buildAdminScreen();
        _currentIndex = index;
      });
    } else {
      setState(() {
        _currentIndex = index;
      });
    }

    _rootPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showAddHomeworkModal() async {
    final messenger = ScaffoldMessenger.of(context);
    String? selectedSubject;
    final taskController = TextEditingController();
    final pickedImagePaths = <String>[];

    DateTime initDate = DateTime.now().add(const Duration(days: 1));
    while (initDate.weekday == 6 || initDate.weekday == 7) {
      initDate = initDate.add(const Duration(days: 1));
    }
    DateTime selectedDeadline = initDate;
    bool isUploading = false;
    final modalSurface = palette.surface2.withValues(alpha: 1);
    final fieldSurface = palette.surface3.withValues(alpha: 1);

    Future<void> pickImages(
      BuildContext sheetContext,
      StateSetter setModalState,
    ) async {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxSide,
        maxHeight: _pickedImageMaxSide,
      );
      if (images.isEmpty) {
        return;
      }
      if (!sheetContext.mounted) return;
      setModalState(() {
        for (final image in images) {
          if (!pickedImagePaths.contains(image.path)) {
            pickedImagePaths.add(image.path);
          }
        }
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void safeSetModalState(VoidCallback fn) {
              if (!ctx.mounted) return;
              setModalState(fn);
            }

            return PopScope(
              canPop: !isUploading,
              child: Container(
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 40),
                decoration: BoxDecoration(
                  color: modalSurface,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusXl)),
                  border: Border.all(color: palette.cardBorder),
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
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Добавить задание',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontSerif,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: palette.onBg,
                                  )),
                              Material(
                                color: palette.surface2,
                                borderRadius: BorderRadius.circular(100),
                                child: InkWell(
                                  onTap: isUploading
                                      ? null
                                      : () => Navigator.of(ctx).pop(),
                                  borderRadius: BorderRadius.circular(100),
                                  child: SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Icon(Icons.close_rounded,
                                        color: palette.onSurface2, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Subject
                          _formLabel('Предмет'),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: fieldSurface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSubject,
                                hint: Text('Выберите предмет',
                                    style: TextStyle(
                                        color: palette.onSurface3
                                            .withValues(alpha: 0.8),
                                        fontSize: 14)),
                                isExpanded: true,
                                dropdownColor: fieldSurface,
                                style: TextStyle(
                                    color: palette.onBg, fontSize: 14),
                                items: allSubjects
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) => safeSetModalState(
                                    () => selectedSubject = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Task
                          _formLabel('Задание'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: taskController,
                            maxLines: 4,
                            style: TextStyle(color: palette.onBg, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Опишите задание...',
                              hintStyle: TextStyle(
                                  color: palette.onSurface3
                                      .withValues(alpha: 0.8)),
                              filled: true,
                              fillColor: fieldSurface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                borderSide:
                                    BorderSide(color: palette.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                borderSide:
                                    BorderSide(color: palette.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                borderSide:
                                    const BorderSide(color: AppTheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Photo picker
                          _formLabel('Фото (необязательно)'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              await pickImages(ctx, setModalState);
                            },
                            child: Container(
                              width: double.infinity,
                              height: pickedImagePaths.isEmpty ? 50 : 170,
                              decoration: BoxDecoration(
                                color: fieldSurface,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: palette.cardBorder),
                              ),
                              child: pickedImagePaths.isEmpty
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.photo_library_rounded,
                                            color: palette.onSurface3
                                                .withValues(alpha: 0.8),
                                            size: 22),
                                        const SizedBox(width: 8),
                                        Text('Добавить фото',
                                            style: TextStyle(
                                                color: palette.onSurface3
                                                    .withValues(alpha: 0.8),
                                                fontSize: 14)),
                                      ],
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.all(8),
                                      itemCount: pickedImagePaths.length + 1,
                                      itemBuilder: (ctx, idx) {
                                        if (idx == pickedImagePaths.length) {
                                          return GestureDetector(
                                            onTap: () async {
                                              await pickImages(
                                                  ctx, setModalState);
                                            },
                                            child: Container(
                                              width: 120,
                                              margin: const EdgeInsets.only(
                                                  left: 8),
                                              decoration: BoxDecoration(
                                                color: modalSurface,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTheme.radiusSm),
                                                border: Border.all(
                                                    color: palette.cardBorder),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                    Icons.add_a_photo_rounded,
                                                    color: AppTheme.primaryDim),
                                              ),
                                            ),
                                          );
                                        }
                                        final path = pickedImagePaths[idx];
                                        return Container(
                                          width: 120,
                                          margin: EdgeInsets.only(
                                              right: idx ==
                                                      pickedImagePaths.length -
                                                          1
                                                  ? 0
                                                  : 8),
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppTheme.radiusSm),
                                                  child: Image.file(
                                                    File(path),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (ctx, err, stack) =>
                                                            Container(
                                                      color: palette.surface2,
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons
                                                            .broken_image_rounded,
                                                        color: Colors.white70,
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    safeSetModalState(() {
                                                      pickedImagePaths
                                                          .removeAt(idx);
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: const Icon(
                                                        Icons.close_rounded,
                                                        color: Colors.white,
                                                        size: 14),
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

                          // Deadline
                          _formLabel('Срок сдачи'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                locale: const Locale('ru', 'RU'),
                                initialDate: selectedDeadline,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                selectableDayPredicate: (DateTime val) =>
                                    val.weekday != 6 && val.weekday != 7,
                                builder: (context, child) {
                                  final pickerBaseTheme = Theme.of(context);
                                  return Theme(
                                    data: pickerBaseTheme.copyWith(
                                      colorScheme:
                                          pickerBaseTheme.colorScheme.copyWith(
                                        primary: AppTheme.primary,
                                        onPrimary: Colors.white,
                                        surface: palette.surface2,
                                        onSurface: palette.onBg,
                                      ),
                                      dialogTheme: DialogThemeData(
                                        backgroundColor: palette.surface2,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                safeSetModalState(
                                    () => selectedDeadline = picked);
                              }
                            },
                            child: Container(
                              height: 44,
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: fieldSurface,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: palette.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 18, color: palette.onSurface2),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${selectedDeadline.day}.${selectedDeadline.month.toString().padLeft(2, '0')}.${selectedDeadline.year}',
                                    style: TextStyle(
                                        color: palette.onBg, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      if (selectedSubject == null ||
                                          taskController.text.trim().isEmpty) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Заполните предмет и задание')),
                                        );
                                        return;
                                      }

                                      if (!_hasSubjectOnDate(
                                        selectedSubject!,
                                        selectedDeadline,
                                      )) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'В этот день этого предмета нет, выберите другой день или предмет.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      try {
                                        safeSetModalState(
                                            () => isUploading = true);

                                        final embeddedImages = <String>[];
                                        bool hasError = false;
                                        final uploadResults = await Future.wait(
                                          pickedImagePaths
                                              .map(_prepareEmbeddedImage),
                                        );
                                        for (final result in uploadResults) {
                                          if (result != null) {
                                            embeddedImages.add(result);
                                          } else {
                                            hasError = true;
                                          }
                                        }

                                        final totalImageChars = embeddedImages
                                            .fold<int>(
                                                0,
                                                (sum, item) =>
                                                    sum + item.length);
                                        if (totalImageChars >
                                            _maxEmbeddedImageChars) {
                                          safeSetModalState(
                                              () => isUploading = false);
                                          if (!context.mounted) return;
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Слишком большие фото. Уменьшите количество или выберите более лёгкие изображения.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        if (hasError) {
                                          safeSetModalState(
                                              () => isUploading = false);
                                          if (!context.mounted) return;
                                          messenger.showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Ошибка при подготовке фото. Попробуйте еще раз.')),
                                          );
                                          return;
                                        }

                                        final hw = HomeworkItem(
                                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                          subject: selectedSubject!,
                                          task: taskController.text.trim(),
                                          deadline:
                                              '${selectedDeadline.year}-${selectedDeadline.month.toString().padLeft(2, '0')}-${selectedDeadline.day.toString().padLeft(2, '0')}',
                                          imageUrl: null,
                                          imageUrls: embeddedImages.isNotEmpty
                                              ? embeddedImages
                                              : null,
                                          fullResolutionUrls: null,
                                          done: false,
                                          fromSchedule: false,
                                        );

                                        final success =
                                            await FirestoreService.addHomework(
                                                hw);

                                        if (!context.mounted) return;

                                        if (!success) {
                                          safeSetModalState(
                                              () => isUploading = false);
                                          messenger.showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Ошибка при сохранении в базу данных.')),
                                          );
                                          return;
                                        }

                                        if (!context.mounted) return;
                                        await _diaryKey.currentState
                                            ?.reloadHomework(
                                                forceRefresh: true);
                                        await _adminKey.currentState
                                            ?.reload(forceRefresh: true);
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        unawaited(
                                          _cleanupTemporaryPickerFiles(
                                              pickedImagePaths),
                                        );

                                        if (!context.mounted) return;
                                        _showTopNotification(
                                          context,
                                          'Задание на ${_formatDate(selectedDeadline)} успешно добавлено',
                                        );
                                      } catch (e, st) {
                                        debugPrint(
                                            'Save homework failed: $e\n$st');
                                        safeSetModalState(
                                            () => isUploading = false);
                                        if (!context.mounted) return;
                                        messenger.showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Произошла ошибка при сохранении задания. Попробуйте еще раз.')),
                                        );
                                      }
                                    },
                              child: isUploading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
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
          },
        );
      },
    );
    taskController.dispose();
  }

  Widget _formLabel(String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.onSurface2,
        ));
  }

  bool _hasSubjectOnDate(String subject, DateTime date) {
    final lessons = weekSchedule[date.weekday - 1] ?? const <Lesson>[];
    return lessons.any((lesson) => lesson.subject == subject);
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showTopNotification(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopNotification(
        message: message,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  Widget? _buildGlassyNavBar() {
    if (!isAdmin) return null; // BottomNavigationBar requires >= 2 items.

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
          icon: Icon(Icons.home_filled), label: 'Главная'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_rounded), label: 'Админ'),
    ];

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.surface.withValues(alpha: 0.96),
              palette.surface2.withValues(alpha: 0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: (ThemeController.isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            currentIndex: _currentIndex,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: palette.onSurface2,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            onTap: _handleNavigationTap,
            items: items,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: palette.bg,
      body: Stack(
        children: [
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
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.bg.withValues(alpha: 0.06),
                      palette.surface.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RepaintBoundary(
              child: PageView.builder(
                controller: _rootPageController,
                physics: isAdmin
                    ? const FastPageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                allowImplicitScrolling: true,
                onPageChanged: (index) {
                  if (_currentIndex == index) {
                    return;
                  }
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: isAdmin ? 2 : 1,
                itemBuilder: (context, index) {
                  return _buildRootPage(index);
                },
              ),
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

class _PremiumGlowButtonState extends State<PremiumGlowButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double size = 64.0;
    const Color glowColor = AppTheme.primary;

    return GestureDetector(
      onTapDown: (_) async {
        _setPressed(true);
        await HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _isPressed ? const Offset(0, 0.03) : Offset.zero,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: size * 1.2,
                height: size * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(
                        alpha: _isPressed ? 0.16 : 0.24,
                      ),
                      blurRadius: _isPressed ? 10 : 18,
                      spreadRadius: _isPressed ? 0.5 : 2,
                    ),
                  ],
                ),
              ),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: 0.85),
                      glowColor.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: size - 3,
                height: size - 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPressed
                      ? const Color(0xFF111111)
                      : const Color(0xFF000000),
                ),
                child: Center(child: widget.child),
              ),
              Positioned(
                top: 6,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: _isPressed ? 0.08 : 1,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopNotification extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _TopNotification({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
