import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/auth_service.dart';
import '../data/firestore_service.dart';
import '../data/schedule_data.dart';
import '../theme/app_theme.dart';
import '../utils/image_data.dart';
import '../widgets/network_photo.dart';

class AdminPanelScreen extends StatefulWidget {
  final VoidCallback onHomeworkChanged;

  const AdminPanelScreen({super.key, required this.onHomeworkChanged});

  @override
  State<AdminPanelScreen> createState() => AdminPanelScreenState();
}

class AdminPanelScreenState extends State<AdminPanelScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const int _pickedImageQuality = 55;
  static const double _pickedImageMaxSide = 1280;
  static const int _maxEmbeddedImageChars = 700000;

  final ImagePicker _imagePicker = ImagePicker();

  List<HomeworkItem> _customHomework = [];
  final Set<String> _deletingIds = <String>{};
  bool _isLoading = true;

  // Current tab: 0 = homework, 1 = settings
  int _tabIndex = 0;

  AppPalette get palette => AppTheme.colorsOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllHomework();
    });
  }

  Future<void> _loadAllHomework({
    bool forceRefresh = false,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    final list = await FirestoreService.getHomework(forceRefresh: forceRefresh);
    final todayStr = _todayString();
    final sortedHomework = list
        .where((hw) => hw.deadline.compareTo(todayStr) >= 0)
        .toList(growable: false)
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    if (!mounted) return;
    setState(() {
      _customHomework = sortedHomework;
      _deletingIds.removeWhere(
        (id) => !sortedHomework.any((item) => item.id == id),
      );
      _isLoading = false;
    });
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> reload({bool forceRefresh = false}) {
    return _loadAllHomework(forceRefresh: forceRefresh, showLoading: false);
  }

  Future<void> _deleteHomework(String itemId) async {
    if (_deletingIds.contains(itemId)) {
      return;
    }

    setState(() {
      _deletingIds.add(itemId);
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));

    final success = await FirestoreService.deleteHomework(itemId);
    if (!success) {
      if (mounted) {
        setState(() {
          _deletingIds.remove(itemId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка удаления')),
        );
      }
      return;
    }

    await _loadAllHomework();
    widget.onHomeworkChanged();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Задание удалено')),
    );
  }

  List<String> _homeworkImages(HomeworkItem hw) {
    if (hw.fullResolutionUrls != null && hw.fullResolutionUrls!.isNotEmpty) {
      return List<String>.from(hw.fullResolutionUrls!);
    }
    if (hw.imageUrls != null && hw.imageUrls!.isNotEmpty) {
      return List<String>.from(hw.imageUrls!);
    }
    if (hw.imageUrl != null && hw.imageUrl!.trim().isNotEmpty) {
      return <String>[hw.imageUrl!];
    }
    return <String>[];
  }

  Future<String?> _prepareEmbeddedImage(String path) async {
    try {
      final bytes = await loadImageBytes(path);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return encodeInlineImageData(
        bytes,
        mimeType: inferImageMimeType(path),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _editHomework(HomeworkItem hw) async {
    final controller = TextEditingController(text: hw.task);
    final editableImages = _homeworkImages(hw);

    final updatedHw = await showDialog<HomeworkItem>(
      context: context,
      builder: (ctx) {
        var isSaving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImages() async {
              final images = await _imagePicker.pickMultiImage(
                imageQuality: _pickedImageQuality,
                maxWidth: _pickedImageMaxSide,
                maxHeight: _pickedImageMaxSide,
              );
              if (images.isEmpty) {
                return;
              }

              final prepared = await Future.wait(
                images.map((image) => _prepareEmbeddedImage(image.path)),
              );
              if (!context.mounted) return;

              final newImages = prepared.whereType<String>().toList(growable: false);
              final totalChars = editableImages.fold<int>(
                    0,
                    (sum, item) => sum + item.length,
                  ) +
                  newImages.fold<int>(0, (sum, item) => sum + item.length);

              if (totalChars > _maxEmbeddedImageChars) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Слишком большие фото. Уменьшите количество или размер изображений.',
                    ),
                  ),
                );
                return;
              }

              setModalState(() {
                editableImages.addAll(newImages);
              });
            }

            return AlertDialog(
              backgroundColor: palette.surface2.withValues(alpha: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Редактировать задание',
                style: TextStyle(color: palette.onBg, fontSize: 18),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        maxLines: 4,
                        style: TextStyle(color: palette.onBg),
                        decoration: InputDecoration(
                          labelText: 'Текст задания',
                          labelStyle: TextStyle(color: palette.onSurface2),
                          filled: true,
                          fillColor: palette.surface3.withValues(alpha: 1),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            borderSide: BorderSide(color: palette.cardBorder),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Фото',
                            style: TextStyle(
                              color: palette.onBg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: isSaving ? null : pickImages,
                            icon: const Icon(Icons.add_photo_alternate_rounded),
                            label: const Text('Добавить'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (editableImages.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.surface3,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: palette.cardBorder),
                          ),
                          child: Text(
                            'Фото пока нет',
                            style: TextStyle(color: palette.onSurface2),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(editableImages.length, (index) {
                            final image = editableImages[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                  child: NetworkPhoto(
                                    url: image,
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    loading: Container(
                                      width: 110,
                                      height: 110,
                                      color: palette.surface3,
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    error: Container(
                                      width: 110,
                                      height: 110,
                                      color: palette.surface3,
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          color: palette.onSurface3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: isSaving
                                        ? null
                                        : () {
                                            setModalState(() {
                                              editableImages.removeAt(index);
                                            });
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Отмена',
                    style: TextStyle(color: palette.onSurface2),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newText = controller.text.trim();
                          if (newText.isEmpty) {
                            return;
                          }

                          setModalState(() {
                            isSaving = true;
                          });

                          Navigator.pop(
                            ctx,
                            HomeworkItem(
                              id: hw.id,
                              subject: hw.subject,
                              task: newText,
                              deadline: hw.deadline,
                              imageUrl: null,
                              imageUrls:
                                  editableImages.isEmpty ? null : editableImages,
                              fullResolutionUrls: null,
                              done: hw.done,
                              fromSchedule: hw.fromSchedule,
                            ),
                          );
                        },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (updatedHw == null) {
      return;
    }

    final success = await FirestoreService.updateHomework(updatedHw);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка сохранения задания')),
        );
      }
      return;
    }

    await _loadAllHomework();
    widget.onHomeworkChanged();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: IndexedStack(
            index: _tabIndex,
            children: [
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _buildList(_customHomework),
              _ClassSettingsTab(classId: FirestoreService.classId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<HomeworkItem> items) {
    if (items.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100, left: 20, right: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final hw = items[index];
        final isDeleting = _deletingIds.contains(hw.id);
        return AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          offset: isDeleting ? const Offset(1.1, 0) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isDeleting ? 0 : 1,
            child: _buildAdminCard(hw),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.4),
        border: Border(bottom: BorderSide(color: palette.cardBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 8),
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Админ-панель',
                style: TextStyle(
                  fontFamily: AppTheme.fontSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: palette.onBg,
                ),
              ),
              const Spacer(),
              if (_tabIndex == 0)
                Text(
                  'Всего: ${_customHomework.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.onSurface2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 10),
          // Tab selector
          Row(
            children: [
              _buildTabButton(0, Icons.assignment_rounded, 'Задания'),
              const SizedBox(width: 8),
              _buildTabButton(1, Icons.settings_rounded, 'Настройки'),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : palette.cardBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? AppTheme.primary : palette.onSurface3),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppTheme.primaryDim : palette.onSurface2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: palette.onSurface3.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет заданий',
            style: TextStyle(color: palette.onSurface3, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(HomeworkItem hw) {
    final images = _homeworkImages(hw);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border.all(color: palette.cardBorder),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    hw.subject,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDim,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  hw.deadline,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.onSurface2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...images.map((url) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: NetworkPhoto(
                      url: url,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loading: Container(
                        height: 150,
                        color: palette.surface3,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      error: Container(
                        height: 150,
                        color: palette.surface3,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: palette.onSurface3,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
            Text(
              hw.task,
              style: TextStyle(fontSize: 14, color: palette.onBg, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editHomework(hw),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Ред.', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteHomework(hw.id),
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Удалить', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Class Settings Tab — code, password, schedule editor
// ═══════════════════════════════════════════════════════════════════════
class _ClassSettingsTab extends StatefulWidget {
  final String? classId;
  const _ClassSettingsTab({required this.classId});

  @override
  State<_ClassSettingsTab> createState() => _ClassSettingsTabState();
}

class _ClassSettingsTabState extends State<_ClassSettingsTab> {
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
      times.add(found ?? (i < defaultLessonTimes.length ? defaultLessonTimes[i] : ''));
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
        content: Text(success
            ? 'Расписание сохранено'
            : 'Ошибка сохранения расписания'),
      ),
    );
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
            icon: Icon(Icons.copy_rounded,
                size: 18, color: palette.onSurface2),
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
            label: Text(_savingSchedule
                ? 'Сохранение...'
                : 'Сохранить расписание'),
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
    );
  }
}

class _DayEditor extends StatefulWidget {
  final int dayIdx;
  final List<Map<String, dynamic>> lessons;
  final List<String> subjects;
  final Future<void> Function(int, int) onPickTime;

  const _DayEditor({
    required this.dayIdx,
    required this.lessons,
    required this.subjects,
    required this.onPickTime,
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
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
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
                setState(() => lessons.add({
                      'subject': subjects.first,
                      'time': '',
                    }));
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Добавить урок',
                  style: TextStyle(fontSize: 12)),
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
