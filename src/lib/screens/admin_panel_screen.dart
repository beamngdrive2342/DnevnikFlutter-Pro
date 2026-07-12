import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_service.dart';
import '../data/schedule_data.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart';
import '../utils/image_data.dart';
import '../widgets/network_photo.dart';
import '../widgets/admin/admin_homework_card.dart';
import '../widgets/admin/class_settings_tab.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  final VoidCallback onHomeworkChanged;

  const AdminPanelScreen({super.key, required this.onHomeworkChanged});

  @override
  ConsumerState<AdminPanelScreen> createState() => AdminPanelScreenState();
}

class AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with AutomaticKeepAliveClientMixin<AdminPanelScreen> {
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
    final todayStr = todayString();
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

              final newImages =
                  prepared.whereType<String>().toList(growable: false);
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
                          children:
                              List.generate(editableImages.length, (index) {
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
                              imageUrls: editableImages.isEmpty
                                  ? null
                                  : editableImages,
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
              ClassSettingsTab(classId: FirestoreService.classId),
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
            child: AdminHomeworkCard(hw: hw, images: _homeworkImages(hw), onEdit: () => _editHomework(hw), onDelete: () => _deleteHomework(hw.id)),
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
              _buildTabButton(1, Icons.settings_rounded, 'Параметры класса'),
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

}

