import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_service.dart';
import '../../data/firestore_service.dart';
import '../../data/schedule_data.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════
// Class Settings Tab — code, password, schedule editor
// ═══════════════════════════════════════════════════════════════════════
class ClassSettingsTab extends ConsumerStatefulWidget {
  final String? classId;
  const ClassSettingsTab({super.key, required this.classId});

  @override
  ConsumerState<ClassSettingsTab> createState() => ClassSettingsTabState();
}

class ClassSettingsTabState extends ConsumerState<ClassSettingsTab> {
  bool _loadingInfo = true;
  String _classCode = '';
  bool _showCode = false;

  // Schedule editor
  final Map<int, List<Map<String, String>>> _scheduleEditor = {};
  List<String> _subjects = [];
  bool _savingSchedule = false;
  bool _scheduleReady = false;

  static const List<String> _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];

  AppPalette get palette => AppTheme.colorsOf(context);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final classId = widget.classId;
    if (classId == null || classId.isEmpty) {
      setState(() => _loadingInfo = false);
      return;
    }

    final info = await AuthService.getClassInfo(classId);

    // Load current schedule from ClassSchedule singleton
    _subjects = List<String>.from(ClassSchedule.subjects);
    final currentSchedule = ClassSchedule.weekSchedule;
    for (var d = 0; d < 6; d++) {
      final dayLessons = currentSchedule[d] ?? [];
      _scheduleEditor[d] = dayLessons
          .map((l) => {
                'subject': l.subject,
                'time': l.time,
              })
          .toList();
    }

    if (!mounted) return;
    setState(() {
      _classCode = info?['code'] ?? '';
      _loadingInfo = false;
      _scheduleReady = true;
    });
  }

  Future<void> _saveSchedule() async {
    if (_savingSchedule) return;
    setState(() => _savingSchedule = true);

    final classId = widget.classId;
    if (classId == null || classId.isEmpty) {
      setState(() => _savingSchedule = false);
      return;
    }

    // Build schedule map for API
    final schedule = <int, List<Map<String, String>>>{};
    for (final entry in _scheduleEditor.entries) {
      schedule[entry.key] = entry.value
          .map((l) => {'subject': l['subject'] ?? '', 'room': ''})
          .toList();
    }

    // Build lesson times
    int maxLessons = 0;
    for (final dayLessons in _scheduleEditor.values) {
      if (dayLessons.length > maxLessons) maxLessons = dayLessons.length;
    }
    final times = <String>[];
    for (var i = 0; i < maxLessons; i++) {
      String? found;
      for (final dayLessons in _scheduleEditor.values) {
        if (i < dayLessons.length) {
          final t = dayLessons[i]['time'] ?? '';
          if (t.isNotEmpty) {
            found = t;
            break;
          }
        }
      }
      times.add(found ??
          (i < defaultLessonTimes.length ? defaultLessonTimes[i] : ''));
    }

    final success = await AuthService.updateClassSchedule(
      classId,
      subjects: _subjects,
      lessonTimes: times,
      schedule: schedule,
    );

    // Reload class data to update the singleton
    if (success) {
      await AuthService.loadClassData(classId);
    }

    if (!mounted) return;

    setState(() => _savingSchedule = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? 'Расписание сохранено' : 'Ошибка сохранения расписания'),
      ),
    );
  }

  void _addLessonForDay(int dayIdx, List<String> subjects) {
    if (subjects.isEmpty) {
      return;
    }

    setState(() {
      final lessons = _scheduleEditor[dayIdx] ??= <Map<String, String>>[];
      if (lessons.length >= 10) {
        return;
      }
      lessons.add({
        'subject': subjects.first,
        'time': '',
      });
    });
  }

  Future<void> _pickTimeForLesson(int dayIdx, int lessonIdx) async {
    final lessons = _scheduleEditor[dayIdx]!;
    final current = lessons[lessonIdx]['time'] ?? '';

    TimeOfDay startTime;
    if (current.contains(' - ')) {
      final parts = current.split(' - ')[0].split(':');
      startTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
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

  @override
  Widget build(BuildContext context) {
    if (_loadingInfo) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── Class info card ──
        _sectionTitle('Информация о классе'),
        const SizedBox(height: 8),
        _buildInfoCard(),
        const SizedBox(height: 24),

        // ── Schedule editor ──
        _sectionTitle('Расписание'),
        const SizedBox(height: 8),
        if (_scheduleReady) _buildScheduleEditor(),
        const SizedBox(height: 24),
        _buildDangerZoneCard(),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: TextStyle(
          fontFamily: AppTheme.fontSerif,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: palette.onBg,
        ));
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class name & school
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.school_rounded,
                    size: 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ClassSchedule.className,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: palette.onBg,
                        )),
                    Text(ClassSchedule.schoolName,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.onSurface2,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: palette.cardBorder, height: 1),
          const SizedBox(height: 16),

          // Class code
          _secretRow(
            icon: Icons.key_rounded,
            label: 'Код класса',
            value: _classCode,
            shown: _showCode,
            onToggle: () => setState(() => _showCode = !_showCode),
            onCopy: () {
              Clipboard.setData(ClipboardData(text: _classCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Код скопирован')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _secretRow({
    required IconData icon,
    required String label,
    required String value,
    required bool shown,
    required VoidCallback onToggle,
    VoidCallback? onCopy,
  }) {
    final displayValue = shown ? value : '••••••';

    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: palette.onSurface3,
                    letterSpacing: 0.5,
                  )),
              const SizedBox(height: 2),
              Text(displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.onBg,
                    fontFamily: shown ? AppTheme.fontSerif : null,
                    letterSpacing: shown ? 3 : 0,
                  )),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            shown ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 20,
            color: palette.onSurface2,
          ),
          visualDensity: VisualDensity.compact,
          onPressed: onToggle,
        ),
        if (onCopy != null)
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 18, color: palette.onSurface2),
            visualDensity: VisualDensity.compact,
            onPressed: onCopy,
          ),
      ],
    );
  }

  Widget _buildScheduleEditor() {
    final subjects = _subjects.toList()..sort();

    return Column(
      children: [
        // Day tabs
        Container(
          height: 460,
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: palette.cardBorder),
          ),
          child: DefaultTabController(
            length: 6,
            child: Column(
              children: [
                TabBar(
                  isScrollable: false,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: palette.onSurface3,
                  indicatorColor: AppTheme.primary,
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: _dayLabels.map((d) => Tab(text: d)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: List.generate(6, (dayIdx) {
                      return _buildDayEditorTab(dayIdx, subjects);
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Save button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _savingSchedule ? null : _saveSchedule,
            icon: _savingSchedule
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(
                _savingSchedule ? 'Сохранение...' : 'Сохранить расписание'),
          ),
        ),
      ],
    );
  }

  Widget _buildDayEditorTab(int dayIdx, List<String> subjects) {
    final lessons = _scheduleEditor[dayIdx] ??= [];
    return _DayEditor(
      dayIdx: dayIdx,
      lessons: lessons,
      subjects: subjects,
      onPickTime: _pickTimeForLesson,
      onAddLesson: () => _addLessonForDay(dayIdx, subjects),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0423\u0434\u0430\u043b\u0435\u043d\u0438\u0435 \u043a\u043b\u0430\u0441\u0441\u0430',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.onBg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\u042d\u0442\u043e \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0435 \u043d\u0430\u0432\u0441\u0435\u0433\u0434\u0430 \u0443\u0434\u0430\u043b\u0438\u0442 \u043a\u043b\u0430\u0441\u0441, \u043a\u043e\u0434 \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f \u0438 \u0432\u0441\u0435 \u0434\u043e\u043c\u0430\u0448\u043d\u0438\u0435 \u0437\u0430\u0434\u0430\u043d\u0438\u044f. \u0414\u043b\u044f \u043f\u043e\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0435\u043d\u0438\u044f \u043d\u0443\u0436\u0435\u043d \u043f\u0430\u0440\u043e\u043b\u044c \u0430\u0434\u043c\u0438\u043d\u0430.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: palette.onSurface2,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmDeleteClass,
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text(
                  '\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u043a\u043b\u0430\u0441\u0441'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteClass() async {
    final passwordController = TextEditingController();
    var isDeleting = false;
    String? errorText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleDelete() async {
              final password = passwordController.text;
              if (password.isEmpty) {
                setDialogState(() {
                  errorText =
                      '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043f\u0430\u0440\u043e\u043b\u044c \u0430\u0434\u043c\u0438\u043d\u0430';
                });
                return;
              }

              setDialogState(() {
                isDeleting = true;
                errorText = null;
              });

              final classId = widget.classId;
              if (classId == null || classId.isEmpty) {
                setDialogState(() {
                  isDeleting = false;
                  errorText =
                      '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u043f\u0440\u0435\u0434\u0435\u043b\u0438\u0442\u044c \u043a\u043b\u0430\u0441\u0441';
                });
                return;
              }

              final deleted = await AuthService.deleteClass(
                classId: classId,
                adminPassword: password,
              );

              if (!context.mounted) {
                return;
              }

              if (!deleted) {
                setDialogState(() {
                  isDeleting = false;
                  errorText =
                      '\u041d\u0435\u0432\u0435\u0440\u043d\u044b\u0439 \u043f\u0430\u0440\u043e\u043b\u044c \u0438\u043b\u0438 \u043e\u0448\u0438\u0431\u043a\u0430 \u0443\u0434\u0430\u043b\u0435\u043d\u0438\u044f';
                });
                return;
              }

              Navigator.of(dialogContext).pop(true);
            }

            return AlertDialog(
              backgroundColor: palette.surface2.withValues(alpha: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                '\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u043a\u043b\u0430\u0441\u0441',
                style: TextStyle(color: palette.onBg, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043f\u0430\u0440\u043e\u043b\u044c \u0430\u0434\u043c\u0438\u043d\u0430, \u0447\u0442\u043e\u0431\u044b \u043d\u0430\u0432\u0441\u0435\u0433\u0434\u0430 \u0443\u0434\u0430\u043b\u0438\u0442\u044c \u043a\u043b\u0430\u0441\u0441 \u0438 \u0432\u0441\u0435 \u0434\u0430\u043d\u043d\u044b\u0435.',
                    style: TextStyle(
                      color: palette.onSurface2,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    enabled: !isDeleting,
                    style: TextStyle(color: palette.onBg, fontSize: 14),
                    decoration: InputDecoration(
                      labelText:
                          '\u041f\u0430\u0440\u043e\u043b\u044c \u0430\u0434\u043c\u0438\u043d\u0430',
                      labelStyle: TextStyle(color: palette.onSurface2),
                      filled: true,
                      fillColor: palette.surface3.withValues(alpha: 1),
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
                    onSubmitted: (_) => handleDelete(),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    '\u041e\u0442\u043c\u0435\u043d\u0430',
                    style: TextStyle(color: palette.onSurface2),
                  ),
                ),
                ElevatedButton(
                  onPressed: isDeleting ? null : handleDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '\u0423\u0434\u0430\u043b\u0438\u0442\u044c'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    if (confirmed != true || !mounted) {
      return;
    }

    await ref.read(authProvider.notifier).logout();
    FirestoreService.clearClassId();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              '\u041a\u043b\u0430\u0441\u0441 \u0443\u0434\u0430\u043b\u0435\u043d')),
    );
  }
}

class _DayEditor extends StatefulWidget {
  final int dayIdx;
  final List<Map<String, dynamic>> lessons;
  final List<String> subjects;
  final Future<void> Function(int, int) onPickTime;
  final VoidCallback onAddLesson;

  const _DayEditor({
    required this.dayIdx,
    required this.lessons,
    required this.subjects,
    required this.onPickTime,
    required this.onAddLesson,
  });

  @override
  State<_DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<_DayEditor>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  AppPalette get palette => AppTheme.colorsOf(context);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lessons = widget.lessons;
    final subjects = widget.subjects;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: [
        ...List.generate(lessons.length, (i) {
          final lesson = lessons[i];
          final timeStr = lesson['time'] as String? ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Row(
              children: [
                // Lesson number
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryLight,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDim,
                        )),
                  ),
                ),
                const SizedBox(width: 6),
                // Subject dropdown
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: subjects.contains(lesson['subject'])
                          ? lesson['subject'] as String?
                          : (subjects.isNotEmpty ? subjects.first : null),
                      isExpanded: true,
                      dropdownColor: palette.surface2.withValues(alpha: 1),
                      style: TextStyle(color: palette.onBg, fontSize: 13),
                      items: subjects
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
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
                  onTap: () async {
                    await widget.onPickTime(widget.dayIdx, i);
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
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
                            size: 12,
                            color: timeStr.isNotEmpty
                                ? AppTheme.primary
                                : palette.onSurface3),
                        const SizedBox(width: 2),
                        Text(
                          timeStr.isNotEmpty ? timeStr : 'Время',
                          style: TextStyle(
                            fontSize: 10,
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
                // Remove
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      color: Colors.redAccent, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => lessons.removeAt(i));
                  },
                ),
              ],
            ),
          );
        }),
        // Add lesson
        if (lessons.length < 10 && subjects.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () {
                widget.onAddLesson();
                if (mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label:
                  const Text('Добавить урок', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
      ],
    );
  }
}
