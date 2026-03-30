import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'data/auth_service.dart';
import 'data/ai_service.dart';
import 'screens/welcome_screen.dart' as screens_welcome;
import 'utils/image_data.dart';
import 'widgets/ai_chat_bottom_sheet.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

// ═══════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  final String role;
  final String classId;
  const MainScreen({super.key, required this.role, required this.classId});

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
    FirestoreService.setClassId(widget.classId);
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

  DateTime _defaultHomeworkDeadline() {
    var date = DateTime.now().add(const Duration(days: 1));
    while (date.weekday == 6 || date.weekday == 7) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  Future<bool> _ensureCurrentClassScheduleLoaded() async {
    final classId = FirestoreService.classId;
    if (classId == null || classId.isEmpty) {
      return false;
    }
    return AuthService.loadClassData(classId);
  }

  String _buildScheduleSummaryForAI() {
    final buffer = StringBuffer();
    for (var dayIndex = 0; dayIndex < 6; dayIndex++) {
      final dayName = weekdaysFull[dayIndex];
      final lessons = weekSchedule[dayIndex] ?? const <Lesson>[];
      if (lessons.isEmpty) {
        buffer.writeln('$dayName: нет уроков.');
        continue;
      }

      final subjects = lessons
          .map((lesson) => '${lesson.subject} (${lesson.time})')
          .join(', ');
      buffer.writeln('$dayName: $subjects.');
    }
    return buffer.toString().trim();
  }

  DateTime? _parseAiDeadline(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) {
      return null;
    }

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String?>> _recognizeQuickHomework(String adminText) async {
    final loaded = await _ensureCurrentClassScheduleLoaded();
    if (!loaded) {
      return {'subject': null, 'deadline': null};
    }

    return AIService.recognizeQuickHomework(
      today: DateTime.now(),
      scheduleText: _buildScheduleSummaryForAI(),
      adminText: adminText,
    );
  }

  Future<void> _showAddHomeworkModal() async {
    final messenger = ScaffoldMessenger.of(context);
    String? selectedSubject;
    final taskController = TextEditingController();
    final quickCommandController = TextEditingController();
    final pickedImagePaths = <String>[];
    final speechToText = stt.SpeechToText();

    DateTime selectedDeadline = _defaultHomeworkDeadline();
    bool isUploading = false;
    bool isQuickMode = true;
    bool isListening = false;
    bool isRecognizingQuick = false;
    String? quickRecognitionMessage;
    final modalSurface = palette.surface2.withValues(alpha: 1);
    final fieldSurface = palette.surface3.withValues(alpha: 1);

    String normalizeSubjectKey(String value) {
      return value
          .trim()
          .toLowerCase()
          .replaceAll('\u0451', '\u0435')
          .replaceAll(RegExp(r'\s+'), ' ');
    }

    String? matchRecognizedSubject(String? value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }

      final normalizedValue = normalizeSubjectKey(value);
      for (final subject in allSubjects) {
        if (normalizeSubjectKey(subject) == normalizedValue) {
          return subject;
        }
      }
      for (final subject in allSubjects) {
        final normalizedSubject = normalizeSubjectKey(subject);
        if (normalizedSubject.contains(normalizedValue) ||
            normalizedValue.contains(normalizedSubject)) {
          return subject;
        }
      }
      return null;
    }

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
      if (!sheetContext.mounted) {
        return;
      }
      setModalState(() {
        for (final image in images) {
          if (!pickedImagePaths.contains(image.path)) {
            pickedImagePaths.add(image.path);
          }
        }
      });
    }

    Future<void> captureBoardPhoto(
      BuildContext sheetContext,
      StateSetter setModalState,
    ) async {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxSide,
        maxHeight: _pickedImageMaxSide,
      );
      if (image == null) {
        return;
      }
      if (!sheetContext.mounted) return;
      setModalState(() {
        pickedImagePaths
          ..clear()
          ..add(image.path);
      });
    }

    Future<void> toggleSpeechInput(
      BuildContext sheetContext,
      StateSetter setModalState,
    ) async {
      if (isListening) {
        await speechToText.stop();
        if (!sheetContext.mounted) return;
        setModalState(() {
          isListening = false;
        });
        return;
      }

      final available = await speechToText.initialize(
        onStatus: (status) {
          if (!sheetContext.mounted) return;
          if (status == 'done' || status == 'notListening') {
            setModalState(() {
              isListening = false;
            });
          }
        },
        onError: (_) {
          if (!sheetContext.mounted) return;
          setModalState(() {
            isListening = false;
          });
        },
      );

      if (!available) {
        if (sheetContext.mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Голосовой ввод сейчас недоступен на этом устройстве.',
              ),
            ),
          );
        }
        return;
      }

      if (!sheetContext.mounted) return;
      setModalState(() {
        isListening = true;
      });

      await speechToText.listen(
        localeId: 'ru_RU',
        listenOptions: stt.SpeechListenOptions(partialResults: true),
        onResult: (result) {
          quickCommandController.value = quickCommandController.value.copyWith(
            text: result.recognizedWords,
            selection:
                TextSelection.collapsed(offset: result.recognizedWords.length),
            composing: TextRange.empty,
          );

          if (result.finalResult && sheetContext.mounted) {
            setModalState(() {
              isListening = false;
            });
          }
        },
      );
    }

    Future<void> recognizeQuickHomework(
      BuildContext sheetContext,
      StateSetter setModalState,
    ) async {
      final quickText = quickCommandController.text.trim();
      if (quickText.isEmpty) {
        setModalState(() {
          quickRecognitionMessage =
              'Введите или продиктуйте текст для быстрого добавления.';
        });
        return;
      }

      if (isListening) {
        await speechToText.stop();
      }

      setModalState(() {
        isListening = false;
        isRecognizingQuick = true;
        quickRecognitionMessage = null;
      });

      final result = await _recognizeQuickHomework(quickText);
      if (!sheetContext.mounted) return;

      final recognizedSubject = matchRecognizedSubject(result['subject']);
      final recognizedDeadline = _parseAiDeadline(result['deadline']);

      setModalState(() {
        isRecognizingQuick = false;
        isQuickMode = false;
        selectedSubject = recognizedSubject;
        if (recognizedDeadline != null) {
          selectedDeadline = recognizedDeadline;
        }

        final recognizedTask = result['task']?.toString().trim();
        if (recognizedTask != null && recognizedTask.isNotEmpty) {
          taskController.text = recognizedTask;
        } else if (taskController.text.trim().isEmpty) {
          taskController.text = quickText;
        }

        quickRecognitionMessage =
            (recognizedSubject != null && recognizedDeadline != null)
                ? 'Поля заполнены автоматически. Проверьте и сохраните.'
                : 'Не всё удалось определить. Завершите заполнение вручную.';
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: Icon(Icons.close_rounded,
                                              color: palette.onSurface2,
                                              size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (isQuickMode) ...[
                            // Big camera button
                            SizedBox(
                              width: double.infinity,
                              height: 64, // Big accented button
                              child: ElevatedButton.icon(
                                onPressed: isUploading || isRecognizingQuick
                                    ? null
                                    : () async {
                                        await captureBoardPhoto(ctx, setModalState);
                                      },
                                icon: const Icon(Icons.photo_camera_rounded, size: 28),
                                label: const Text(
                                  '\u0421\u0444\u043e\u0442\u043e\u0433\u0440\u0430\u0444\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u0434\u043e\u0441\u043a\u0443',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Text field
                            TextField(
                              controller: quickCommandController,
                              minLines: 2,
                              maxLines: 4,
                              style: TextStyle(color: palette.onBg, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: '\u0423\u0442\u043e\u0447\u043d\u0438\u0442\u0435 \u0437\u0430\u0434\u0430\u043d\u0438\u0435', // "Уточните задание"
                                hintStyle: TextStyle(
                                  color: palette.onSurface3.withValues(alpha: 0.8),
                                ),
                                filled: true,
                                fillColor: fieldSurface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Material(
                                    color: isListening ? AppTheme.primary : palette.surface3,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      onPressed: isUploading || isRecognizingQuick
                                          ? null
                                          : () async {
                                              await toggleSpeechInput(ctx, setModalState);
                                            },
                                      icon: Icon(
                                        isListening
                                            ? Icons.stop_circle_rounded
                                            : Icons.mic_rounded,
                                        color: isListening ? Colors.white : palette.onSurface2,
                                      ),
                                    ),
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg), // softer corners
                                  borderSide: BorderSide(color: palette.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  borderSide: BorderSide(color: palette.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  borderSide: const BorderSide(color: AppTheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // "Распознать" button
                            SizedBox(
                              width: double.infinity,
                              height: 52, // Wide button
                              child: ElevatedButton.icon(
                                onPressed: isUploading || isRecognizingQuick
                                    ? null
                                    : () async {
                                        await recognizeQuickHomework(ctx, setModalState);
                                      },
                                icon: isRecognizingQuick
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome_rounded),
                                label: Text(
                                  isRecognizingQuick
                                      ? '\u0420\u0430\u0441\u043f\u043e\u0437\u043d\u0430\u0451\u043c...'
                                      : '\u0420\u0430\u0441\u043f\u043e\u0437\u043d\u0430\u0442\u044c',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDim, // brown color
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // "Добавить вручную" link
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  safeSetModalState(() {
                                    isQuickMode = false;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0432\u0440\u0443\u0447\u043d\u0443\u044e', // "Добавить вручную"
                                  style: TextStyle(
                                    color: palette.onSurface3,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          if (!isQuickMode) ...[
                            if (quickRecognitionMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: modalSurface,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  border: Border.all(color: palette.cardBorder),
                                ),
                                child: Text(
                                  quickRecognitionMessage!,
                                  style: TextStyle(
                                    color: palette.onBg,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
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

                                        final totalImageChars =
                                            embeddedImages.fold<int>(
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
                          ],
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
    await speechToText.stop();
    taskController.dispose();
    quickCommandController.dispose();
  }

  void _showAIChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIChatBottomSheet(),
    );
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
    if (!isAdmin) return null;

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
                physics: const NeverScrollableScrollPhysics(),
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
      floatingActionButton: _currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: isAdmin
                  ? PremiumGlowButton(
                      onPressed: _showAddHomeworkModal,
                      child: const Icon(
                        Icons.add_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    )
                  : AnimatedBuilder(
                      animation: aiChatController,
                      builder: (context, _) {
                        return PremiumGlowButton(
                          onPressed: _showAIChatModal,
                          isLoading: aiChatController.isBusy,
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
            )
          : null,
    );
  }
}

class PremiumGlowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isLoading;

  const PremiumGlowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  State<PremiumGlowButton> createState() => _PremiumGlowButtonState();
}

class _PremiumGlowButtonState extends State<PremiumGlowButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _syncLoadingAnimation();
  }

  @override
  void didUpdateWidget(covariant PremiumGlowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      _syncLoadingAnimation();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  void _syncLoadingAnimation() {
    if (widget.isLoading) {
      _loadingController.repeat();
      return;
    }
    _loadingController
      ..stop()
      ..value = 0;
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
              if (widget.isLoading) ...[
                RotationTransition(
                  turns: _loadingController,
                  child: SizedBox(
                    width: size * 1.38,
                    height: size * 1.38,
                    child: CustomPaint(
                      painter: _GlowButtonLoadingRingPainter(
                        primaryColor: glowColor.withValues(alpha: 0.95),
                        secondaryColor: Colors.white.withValues(alpha: 0.72),
                        strokeWidth: 2.6,
                        primarySweep: math.pi * 0.9,
                        secondarySweep: math.pi * 0.28,
                      ),
                    ),
                  ),
                ),
                RotationTransition(
                  turns: Tween<double>(begin: 0, end: -1).animate(
                    CurvedAnimation(
                      parent: _loadingController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: SizedBox(
                    width: size * 1.18,
                    height: size * 1.18,
                    child: CustomPaint(
                      painter: _GlowButtonLoadingRingPainter(
                        primaryColor: Colors.white.withValues(alpha: 0.46),
                        secondaryColor: glowColor.withValues(alpha: 0.62),
                        strokeWidth: 1.6,
                        primarySweep: math.pi * 0.42,
                        secondarySweep: math.pi * 0.18,
                      ),
                    ),
                  ),
                ),
              ],
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
                        alpha: _isPressed
                            ? 0.16
                            : widget.isLoading
                                ? 0.34
                                : 0.24,
                      ),
                      blurRadius: _isPressed
                          ? 10
                          : widget.isLoading
                              ? 24
                              : 18,
                      spreadRadius: _isPressed
                          ? 0.5
                          : widget.isLoading
                              ? 3
                              : 2,
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
                  opacity: _isPressed
                      ? 0.08
                      : widget.isLoading
                          ? 0.45
                          : 1,
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

class _GlowButtonLoadingRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;
  final double primarySweep;
  final double secondarySweep;

  const _GlowButtonLoadingRingPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
    required this.primarySweep,
    required this.secondarySweep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final primaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: <Color>[
          primaryColor.withValues(alpha: 0.08),
          primaryColor,
          primaryColor.withValues(alpha: 0.2),
        ],
        stops: const <double>[0, 0.55, 1],
      ).createShader(rect);

    final secondaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.82
      ..strokeCap = StrokeCap.round
      ..color = secondaryColor;

    canvas.drawArc(rect, -math.pi / 2, primarySweep, false, primaryPaint);
    canvas.drawArc(
      rect,
      math.pi * 0.72,
      secondarySweep,
      false,
      secondaryPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowButtonLoadingRingPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.primarySweep != primarySweep ||
        oldDelegate.secondarySweep != secondarySweep;
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
