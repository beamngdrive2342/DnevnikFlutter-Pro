import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_service.dart';
import '../data/schedule_data.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _pageController = PageController();
  int _step = 0;

  // Step 1 — Admin credentials
  final _emailC = TextEditingController();
  final _adminPassC = TextEditingController();
  final _adminPassConfirmC = TextEditingController();

  // Step 2 — Class info
  final _classNameC = TextEditingController();
  final _schoolNameC = TextEditingController();
  final _classPassC = TextEditingController();
  final _classPassConfirmC = TextEditingController();

  // Step 3 — Subjects
  late List<String> _availableSubjects;
  final Set<String> _selectedSubjects = {};
  final _customSubjectC = TextEditingController();

  // Step 4 — Schedule
  // day index → list of {subject, time} maps (in lesson order)
  final Map<int, List<Map<String, String>>> _daySchedules = {};

  bool _loading = false;
  String? _error;
  String? _generatedCode;
  String? _createdClassId;

  static const List<String> _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];

  AppPalette get palette => AppTheme.colorsOf(context);

  @override
  void initState() {
    super.initState();
    _availableSubjects = List<String>.from(defaultSubjects);
    _selectedSubjects.addAll(_availableSubjects);
    // Init empty schedules for Mon-Sat (0-5)
    for (var i = 0; i < 6; i++) {
      _daySchedules[i] = [];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailC.dispose();
    _adminPassC.dispose();
    _adminPassConfirmC.dispose();
    _classNameC.dispose();
    _schoolNameC.dispose();
    _classPassC.dispose();
    _classPassConfirmC.dispose();
    _customSubjectC.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    setState(() {
      _step = step;
      _error = null;
    });
  }

  void _next() {
    if (!_validate()) return;
    _goTo(_step + 1);
  }

  bool _validate() {
    switch (_step) {
      case 0:
        if (_emailC.text.trim().isEmpty) {
          setState(() => _error = 'Введите email');
          return false;
        }
        if (!_emailC.text.contains('@')) {
          setState(() => _error = 'Некорректный email');
          return false;
        }
        if (_adminPassC.text.length < 6) {
          setState(() => _error = 'Пароль минимум 6 символов');
          return false;
        }
        if (_adminPassC.text != _adminPassConfirmC.text) {
          setState(() => _error = 'Пароли не совпадают');
          return false;
        }
        return true;
      case 1:
        if (_classNameC.text.trim().isEmpty) {
          setState(() => _error = 'Введите название класса');
          return false;
        }
        if (_schoolNameC.text.trim().isEmpty) {
          setState(() => _error = 'Введите название школы');
          return false;
        }
        if (_classPassC.text.length < 4) {
          setState(() => _error = 'Пароль класса минимум 4 символа');
          return false;
        }
        if (_classPassC.text != _classPassConfirmC.text) {
          setState(() => _error = 'Пароли не совпадают');
          return false;
        }
        return true;
      case 2:
        if (_selectedSubjects.length < 2) {
          setState(() => _error = 'Выберите хотя бы 2 предмета');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _createClass() async {
    if (_loading) return;

    // Build schedule map
    final schedule = <int, List<Map<String, String>>>{};
    for (final entry in _daySchedules.entries) {
      schedule[entry.key] = entry.value
          .map((l) => {'subject': l['subject'] ?? '', 'room': ''})
          .toList();
    }

    // Build lesson times from the custom times set per lesson, or use defaults
    final customTimes = <String>[];
    // Collect all unique times across days to build the times list
    // For simplicity, use the maximum lesson count's times or defaults
    int maxLessons = 0;
    for (final dayLessons in _daySchedules.values) {
      if (dayLessons.length > maxLessons) maxLessons = dayLessons.length;
    }
    for (var i = 0; i < maxLessons; i++) {
      // Find first non-empty time for this slot
      String? found;
      for (final dayLessons in _daySchedules.values) {
        if (i < dayLessons.length) {
          final t = dayLessons[i]['time'] ?? '';
          if (t.isNotEmpty) {
            found = t;
            break;
          }
        }
      }
      customTimes.add(found ?? (i < defaultLessonTimes.length ? defaultLessonTimes[i] : ''));
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.createClass(
      adminEmail: _emailC.text.trim(),
      adminPassword: _adminPassC.text,
      className: _classNameC.text.trim(),
      schoolName: _schoolNameC.text.trim(),
      classPassword: _classPassC.text,
      subjects: _selectedSubjects.toList(),
      lessonTimes: customTimes.isNotEmpty ? customTimes : List<String>.from(defaultLessonTimes),
      schedule: schedule,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _error = 'Ошибка создания класса. Попробуйте ещё раз.';
      });
      return;
    }

    // Load schedule
    await AuthService.loadClassData(result['classId']!);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _generatedCode = result['code'];
      _createdClassId = result['classId'];
    });
    _goTo(4); // Success page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step > 0 && _step < 4
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: palette.onBg),
                onPressed: () => _goTo(_step - 1),
              )
            : _step == 4
                ? IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: palette.onBg),
                    onPressed: () {
                      // Go back to schedule step so user can review/edit
                      _goTo(3);
                    },
                  )
                : IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.onBg),
                    onPressed: () => Navigator.pop(context),
                  ),
        title: _step < 4
            ? Text(
                'Шаг ${_step + 1} из 4',
                style: TextStyle(
                    color: palette.onSurface2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              )
            : null,
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _step1AdminCreds(),
          _step2ClassInfo(),
          _step3Subjects(),
          _step4Schedule(),
          _step5Success(),
        ],
      ),
    );
  }

  // ── Step 1: Admin credentials ─────────────────────────────────────────

  Widget _step1AdminCreds() {
    return _stepScaffold(
      title: 'Аккаунт админа',
      subtitle: 'Данные для входа в панель управления',
      children: [
        _buildField(_emailC, 'Email', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildField(_adminPassC, 'Пароль', obscure: true),
        const SizedBox(height: 14),
        _buildField(_adminPassConfirmC, 'Повтор пароля', obscure: true),
      ],
      onNext: _next,
    );
  }

  // ── Step 2: Class info ────────────────────────────────────────────────

  Widget _step2ClassInfo() {
    return _stepScaffold(
      title: 'Информация о классе',
      subtitle: 'Название класса и пароль для учеников',
      children: [
        _buildField(_classNameC, 'Название класса (напр. 10А)'),
        const SizedBox(height: 14),
        _buildField(_schoolNameC, 'Школа (напр. Школа №42)'),
        const SizedBox(height: 14),
        _buildField(_classPassC, 'Пароль класса для учеников', obscure: true),
        const SizedBox(height: 14),
        _buildField(_classPassConfirmC, 'Повтор пароля класса', obscure: true),
      ],
      onNext: _next,
    );
  }

  // ── Step 3: Subjects ──────────────────────────────────────────────────

  Widget _step3Subjects() {
    final fieldBg = palette.surface3.withValues(alpha: 1);

    return _stepScaffold(
      title: 'Предметы',
      subtitle: 'Выберите предметы вашего класса',
      scrollable: true,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customSubjectC,
                style: TextStyle(color: palette.onBg, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Свой предмет...',
                  hintStyle: TextStyle(
                      color: palette.onSurface3.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: fieldBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final name = _customSubjectC.text.trim();
                if (name.isNotEmpty && !_availableSubjects.contains(name)) {
                  setState(() {
                    _availableSubjects.add(name);
                    _selectedSubjects.add(name);
                    _customSubjectC.clear();
                  });
                }
              },
              icon: const Icon(Icons.add_circle_rounded,
                  color: AppTheme.primary, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSubjects.map((subj) {
            final selected = _selectedSubjects.contains(subj);
            return FilterChip(
              label: Text(subj),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedSubjects.add(subj);
                  } else {
                    _selectedSubjects.remove(subj);
                  }
                });
              },
              selectedColor: AppTheme.primaryLight,
              checkmarkColor: AppTheme.primary,
              backgroundColor: palette.surface3,
              labelStyle: TextStyle(
                color: selected ? AppTheme.primaryDim : palette.onSurface2,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : palette.cardBorder,
              ),
            );
          }).toList(),
        ),
      ],
      onNext: _next,
    );
  }

  // ── Step 4: Schedule ──────────────────────────────────────────────────

  Widget _step4Schedule() {
    final subjects = _selectedSubjects.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text('Расписание',
                  style: TextStyle(
                    fontFamily: AppTheme.fontSerif,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: palette.onBg,
                  )),
              const SizedBox(height: 4),
              Text('Добавляйте уроки для каждого дня',
                  style: TextStyle(
                      fontSize: 13, color: palette.onSurface2)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: DefaultTabController(
            length: 6,
            child: Column(
              children: [
                TabBar(
                  isScrollable: false,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: palette.onSurface3,
                  indicatorColor: AppTheme.primary,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: _dayLabels.map((d) => Tab(text: d)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: List.generate(6, (dayIdx) {
                      return _buildDayEditor(dayIdx, subjects);
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _createClass,
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Создать класс'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayEditor(int dayIdx, List<String> subjects) {
    final lessons = _daySchedules[dayIdx] ??= [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      children: [
        ...List.generate(lessons.length, (i) {
          final lesson = lessons[i];
          final timeStr = lesson['time'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Row(
              children: [
                // Lesson number
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryLight,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDim,
                        )),
                  ),
                ),
                const SizedBox(width: 8),
                // Subject dropdown
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: subjects.contains(lesson['subject'])
                          ? lesson['subject']
                          : (subjects.isNotEmpty ? subjects.first : null),
                      isExpanded: true,
                      dropdownColor:
                          palette.surface2.withValues(alpha: 1),
                      style: TextStyle(
                          color: palette.onBg, fontSize: 13),
                      items: subjects
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => lessons[i]['subject'] = v);
                        }
                      },
                    ),
                  ),
                ),
                // Time button
                GestureDetector(
                  onTap: () => _pickTimeForLesson(dayIdx, i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: timeStr.isNotEmpty
                          ? AppTheme.primary.withValues(alpha: 0.08)
                          : palette.surface3,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: timeStr.isNotEmpty
                            ? AppTheme.primary.withValues(alpha: 0.25)
                            : palette.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14,
                            color: timeStr.isNotEmpty
                                ? AppTheme.primary
                                : palette.onSurface3),
                        const SizedBox(width: 3),
                        Text(
                          timeStr.isNotEmpty ? timeStr : 'Время',
                          style: TextStyle(
                            fontSize: 11,
                            color: timeStr.isNotEmpty
                                ? AppTheme.primaryDim
                                : palette.onSurface3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Remove button
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      color: Colors.redAccent, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => lessons.removeAt(i));
                  },
                ),
              ],
            ),
          );
        }),
        // Add lesson button
        if (lessons.length < 10 && subjects.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              setState(() => lessons.add({
                    'subject': subjects.first,
                    'time': '',
                  }));
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Добавить урок', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
        if (subjects.isEmpty)
          Text('Нет выбранных предметов',
              style: TextStyle(color: palette.onSurface3, fontSize: 13)),
      ],
    );
  }

  Future<void> _pickTimeForLesson(int dayIdx, int lessonIdx) async {
    final lessons = _daySchedules[dayIdx]!;
    final current = lessons[lessonIdx]['time'] ?? '';

    // Parse existing time or use default
    TimeOfDay startTime;
    if (current.contains(' - ')) {
      final parts = current.split(' - ')[0].split(':');
      startTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
      // Default: 9:00 + 55min * lessonIdx
      final totalMin = 9 * 60 + lessonIdx * 55;
      startTime = TimeOfDay(hour: totalMin ~/ 60, minute: totalMin % 60);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: startTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppTheme.primary,
                    surface: palette.surface2,
                    onSurface: palette.onBg,
                  ),
              dialogTheme: DialogThemeData(
                backgroundColor: palette.surface2,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked == null || !mounted) return;

    // End time = start + 45 min
    final endMinutes = picked.hour * 60 + picked.minute + 45;
    final endHour = endMinutes ~/ 60;
    final endMin = endMinutes % 60;

    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}'
        ' - '
        '${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';

    setState(() {
      lessons[lessonIdx]['time'] = timeStr;
    });
  }

  // ── Step 5: Success ───────────────────────────────────────────────────

  Widget _step5Success() {
    final code = _generatedCode ?? '------';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          Text('Класс создан!',
              style: TextStyle(
                fontFamily: AppTheme.fontSerif,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: palette.onBg,
              )),
          const SizedBox(height: 8),
          Text('Передайте этот код ученикам',
              style: TextStyle(
                  fontSize: 14, color: palette.onSurface2)),
          const SizedBox(height: 32),

          // Code display
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Код скопирован!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: palette.cardBg,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(code,
                      style: TextStyle(
                        fontFamily: AppTheme.fontSerif,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        color: palette.onBg,
                      )),
                  const SizedBox(width: 16),
                  Icon(Icons.copy_rounded,
                      color: palette.onSurface2, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Нажмите чтобы скопировать',
              style: TextStyle(
                  fontSize: 12, color: palette.onSurface3)),
          const SizedBox(height: 16),
          Text(
            'Пароль класса: ${_classPassC.text}',
            style: TextStyle(fontSize: 13, color: palette.onSurface2),
          ),
          const SizedBox(height: 16),

          // Back to schedule hint
          TextButton.icon(
            onPressed: () => _goTo(3),
            icon: Icon(Icons.edit_rounded, size: 16, color: palette.onSurface2),
            label: Text(
              'Вернуться к расписанию',
              style: TextStyle(fontSize: 13, color: palette.onSurface2),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final classId = _createdClassId ?? ClassSchedule.classId;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) =>
                        MainScreen(role: 'admin', classId: classId),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Начать работу'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────

  Widget _stepScaffold({
    required String title,
    required String subtitle,
    required List<Widget> children,
    required VoidCallback onNext,
    bool scrollable = false,
  }) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(title,
              style: TextStyle(
                fontFamily: AppTheme.fontSerif,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: palette.onBg,
              )),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(subtitle,
              style: TextStyle(fontSize: 13, color: palette.onSurface2),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 32),
        ...children,
        if (_error != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(_error!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text('Далее'),
          ),
        ),
      ],
    );

    if (scrollable) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: body,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: body,
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    final fieldBg = palette.surface3.withValues(alpha: 1);
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: TextStyle(color: palette.onBg, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.onSurface2, fontSize: 14),
        filled: true,
        fillColor: fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
