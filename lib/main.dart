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
      title: 'Дневник',
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

class RoleGate extends StatefulWidget {
  const RoleGate({super.key});
  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  bool _isLoading = true;
  String? _role;

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

  Future<void> _showAdminPinDialog() async {
    final pinController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2E2218),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Введите PIN администратора',
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
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == _adminPin) {
                Navigator.pop(ctx);
                _setRole('admin');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Неверный PIN')),
                );
              }
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
    pinController.dispose();
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
              const Text('Школьный Дневник',
                  style: TextStyle(
                    fontFamily: AppTheme.fontSerif,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onBg,
                  )),
              const SizedBox(height: 8),
              const Text('Выберите роль для входа',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurface2,
                  )),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_rounded, size: 22),
                  label: const Text('Войти как ученик'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface3,
                    foregroundColor: AppTheme.primaryDim,
                  ),
                  onPressed: () => _setRole('student'),
                ),
              ),
              const SizedBox(height: 16),
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
}

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
  static const int _pickedImageQuality = 70;
  static const double _pickedImageMaxSide = 1920;

  int _currentIndex = 0;
  final GlobalKey<DiaryScreenState> _diaryKey = GlobalKey<DiaryScreenState>();
  final GlobalKey<AdminPanelScreenState> _adminKey =
      GlobalKey<AdminPanelScreenState>();
  final ImagePicker _imagePicker = ImagePicker();

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
          final displayUrl = json['image']['medium']?['url'] ??
              json['image']['thumb']?['url'] ??
              fullUrl;

          return {'display': displayUrl.toString(), 'full': fullUrl.toString()};
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
        if (!absolutePath.startsWith(tempRoot)) continue;
        final file = File(absolutePath);
        if (await file.exists()) await file.delete();
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
          onHomeworkChanged: () => _diaryKey.currentState?.reloadHomework(),
        ),
      ];
    } else {
      _screens = [
        DiaryScreen(key: _diaryKey),
      ];
    }
  }

  Future<void> _showAddHomeworkModal() async {
    String? selectedSubject;
    final taskController = TextEditingController();
    final pickedImagePaths = <String>[];

    DateTime initDate = DateTime.now().add(const Duration(days: 1));
    while (initDate.weekday == 6 || initDate.weekday == 7) {
      initDate = initDate.add(const Duration(days: 1));
    }
    DateTime selectedDeadline = initDate;
    bool isUploading = false;

    Future<void> pickImages(StateSetter setModalState) async {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxSide,
        maxHeight: _pickedImageMaxSide,
      );
      if (images.isEmpty) return;
      setModalState(() {
        for (final image in images) {
          if (!pickedImagePaths.contains(image.path)) {
            pickedImagePaths.add(image.path);
          }
        }
      });
    }

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (modalCtx, setModalState) {
              final topPadding = MediaQuery.of(context).padding.top;
              return Container(
                margin: EdgeInsets.only(top: topPadding + 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF251C14),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusXl)),
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
                              const Text('Добавить задание',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontSerif,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onBg,
                                  )),
                              Material(
                                color: AppTheme.surface2,
                                borderRadius: BorderRadius.circular(100),
                                child: InkWell(
                                  onTap: () => Navigator.pop(ctx),
                                  borderRadius: BorderRadius.circular(100),
                                  child: const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Icon(Icons.close_rounded,
                                        color: AppTheme.onSurface2, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _formLabel('Предмет'),
                          const SizedBox(height: 6),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E2218),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSubject,
                                hint: Text('Выберите предмет',
                                    style: TextStyle(
                                        color: AppTheme.onSurface3
                                            .withValues(alpha: 0.8),
                                        fontSize: 14)),
                                isExpanded: true,
                                dropdownColor: const Color(0xFF2E2218),
                                style: const TextStyle(
                                    color: AppTheme.onBg, fontSize: 14),
                                items: allSubjects
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) =>
                                    setModalState(() => selectedSubject = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _formLabel('Задание'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: taskController,
                            maxLines: 4,
                            style: const TextStyle(
                                color: AppTheme.onBg, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Опишите задание...',
                              hintStyle: TextStyle(
                                  color: AppTheme.onSurface3
                                      .withValues(alpha: 0.8)),
                              filled: true,
                              fillColor: const Color(0xFF2E2218),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                borderSide: const BorderSide(
                                    color: AppTheme.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                borderSide: const BorderSide(
                                    color: AppTheme.cardBorder),
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
                          _formLabel('Фото (необязательно)'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              await pickImages(setModalState);
                            },
                            child: Container(
                              width: double.infinity,
                              height: pickedImagePaths.isEmpty ? 50 : 170,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E2218),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: pickedImagePaths.isEmpty
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.photo_library_rounded,
                                            color: AppTheme.onSurface3
                                                .withValues(alpha: 0.8),
                                            size: 22),
                                        const SizedBox(width: 8),
                                        Text('Добавить фото',
                                            style: TextStyle(
                                                color: AppTheme.onSurface3
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
                                              await pickImages(setModalState);
                                            },
                                            child: Container(
                                              width: 120,
                                              margin:
                                                  const EdgeInsets.only(left: 8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.surface2,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTheme.radiusSm),
                                                border: Border.all(
                                                    color: AppTheme.cardBorder),
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
                                                      pickedImagePaths.length - 1
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
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setModalState(() {
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
                          _formLabel('Срок сдачи'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                locale: const Locale('ru', 'RU'),
                                initialDate: selectedDeadline,
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
                                          backgroundColor: Color(0xFF251C14)),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() => selectedDeadline = picked);
                              }
                            },
                            child: Container(
                              height: 44,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E2218),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 18, color: AppTheme.onSurface2),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${selectedDeadline.day}.${selectedDeadline.month.toString().padLeft(2, '0')}.${selectedDeadline.year}',
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
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      if (selectedSubject == null ||
                                          taskController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Заполните предмет и задание')),
                                        );
                                        return;
                                      }

                                      setModalState(() => isUploading = true);

                                      final displayUrls = <String>[];
                                      final fullUrls = <String>[];
                                      bool hasError = false;
                                      final uploadResults = await Future.wait(
                                        pickedImagePaths.map(_uploadImage),
                                      );
                                      for (final result in uploadResults) {
                                        if (result != null) {
                                          displayUrls.add(result['display']!);
                                          fullUrls.add(result['full']!);
                                        } else {
                                          hasError = true;
                                        }
                                      }

                                      if (hasError) {
                                        setModalState(() => isUploading = false);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Ошибка при загрузке фото в облако. Попробуйте ещё раз.')),
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
                                        imageUrls: displayUrls.isNotEmpty
                                            ? displayUrls
                                            : null,
                                        fullResolutionUrls:
                                            fullUrls.isNotEmpty ? fullUrls : null,
                                        done: false,
                                        fromSchedule: false,
                                      );

                                      final success =
                                          await FirestoreService.addHomework(hw);

                                      if (!context.mounted) return;

                                      if (!success) {
                                        setModalState(() => isUploading = false);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Ошибка при сохранении в базу данных.')),
                                        );
                                        return;
                                      }

                                      await _cleanupTemporaryPickerFiles(
                                          pickedImagePaths);
                                      if (!context.mounted) return;
                                      _diaryKey.currentState?.reloadHomework();
                                      _adminKey.currentState?.reload();
                                      if (ctx.mounted) Navigator.pop(ctx);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Задание по $selectedSubject добавлено')),
                                      );
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
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('❌ Ошибка при открытии модалки задания: $e');
    } finally {
      taskController.dispose();
    }
  }

  Widget _formLabel(String text) {
    return Text(text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.onSurface2,
        ));
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
    const Color glowColor = AppTheme.primary;

    return GestureDetector(
      onTap: widget.onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
          Container(
            width: size - 3,
            height: size - 3,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: Center(child: widget.child),
          ),
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
