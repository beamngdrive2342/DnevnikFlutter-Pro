import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

class AdminPanelScreenState extends State<AdminPanelScreen> {
  static const int _pickedImageQuality = 55;
  static const double _pickedImageMaxSide = 1280;
  static const int _maxEmbeddedImageChars = 700000;

  final ImagePicker _imagePicker = ImagePicker();

  List<HomeworkItem> _customHomework = [];
  final Set<String> _deletingIds = <String>{};
  bool _isLoading = true;

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
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _buildList(_customHomework),
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
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.4),
        border: Border(bottom: BorderSide(color: palette.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
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
          Text(
            'Всего: ${_customHomework.length}',
            style: TextStyle(
              fontSize: 12,
              color: palette.onSurface2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
