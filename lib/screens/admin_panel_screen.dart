import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/schedule_data.dart';
import '../data/firestore_service.dart';
import '../widgets/fast_page_scroll_physics.dart';
import '../widgets/network_photo.dart';
import '../widgets/theme_switch_button.dart';

class AdminPanelScreen extends StatefulWidget {
  final VoidCallback onHomeworkChanged;

  const AdminPanelScreen({super.key, required this.onHomeworkChanged});

  @override
  State<AdminPanelScreen> createState() => AdminPanelScreenState();
}

class AdminPanelScreenState extends State<AdminPanelScreen> {
  List<HomeworkItem> _customHomework = [];
  List<HomeworkItem> _activeHomework = [];
  List<HomeworkItem> _pastHomework = [];
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
    final sortedHomework = [...list]
      ..sort((a, b) => b.deadline.compareTo(a.deadline));
    final todayStr = _todayString();
    final activeHomework = <HomeworkItem>[];
    final pastHomework = <HomeworkItem>[];

    for (final hw in sortedHomework) {
      if (hw.deadline.compareTo(todayStr) >= 0) {
        activeHomework.add(hw);
      } else {
        pastHomework.add(hw);
      }
    }

    if (!mounted) return;
    setState(() {
      _customHomework = sortedHomework;
      _activeHomework = activeHomework;
      _pastHomework = pastHomework;
      _isLoading = false;
    });
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Public method so MainScreen can trigger a refresh
  Future<void> reload({bool forceRefresh = false}) {
    return _loadAllHomework(forceRefresh: forceRefresh, showLoading: false);
  }

  Future<void> _deleteHomework(String itemId) async {
    final success = await FirestoreService.deleteHomework(itemId);
    if (!success) {
      if (mounted) {
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

  Future<void> _editHomework(HomeworkItem hw) async {
    final controller = TextEditingController(text: hw.task);
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Редактировать задание',
            style: TextStyle(color: palette.onBg, fontSize: 18)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: palette.onBg),
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.surface3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              borderSide: BorderSide(color: palette.cardBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: palette.onSurface2)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newText != null && newText.trim().isNotEmpty && newText != hw.task) {
      final updatedHw = HomeworkItem(
        id: hw.id,
        subject: hw.subject,
        task: newText.trim(),
        deadline: hw.deadline,
        imageUrl: hw.imageUrl,
        imageUrls: hw.imageUrls,
        fullResolutionUrls: hw.fullResolutionUrls,
        done: hw.done,
        fromSchedule: hw.fromSchedule,
      );

      final success = await FirestoreService.updateHomework(updatedHw);
      if (success) {
        await _loadAllHomework();
        widget.onHomeworkChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildTopBar(),
          TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: palette.onSurface2,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: palette.cardBorder,
            tabs: const [Tab(text: 'Текущие'), Tab(text: 'Завершённые')],
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : TabBarView(
                    physics: const FastPageScrollPhysics(),
                    children: [
                      _buildList(_activeHomework, editable: true),
                      _buildList(_pastHomework, editable: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<HomeworkItem> items, {required bool editable}) {
    if (items.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100, left: 20, right: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildAdminCard(items[index], editable: editable);
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
          const Icon(Icons.admin_panel_settings_rounded,
              color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Text('Админ-панель',
              style: TextStyle(
                fontFamily: AppTheme.fontSerif,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: palette.onBg,
              )),
          const Spacer(),
          Text('Всего: ${_customHomework.length}',
              style: TextStyle(
                fontSize: 12,
                color: palette.onSurface2,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(width: 12),
          const ThemeSwitchButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: palette.onSurface3.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Нет заданий',
              style: TextStyle(color: palette.onSurface3, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAdminCard(HomeworkItem hw, {required bool editable}) {
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
                  child: Text(hw.subject,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDim)),
                ),
                const Spacer(),
                Text(hw.deadline,
                    style: TextStyle(
                        fontSize: 12,
                        color: palette.onSurface2,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if ((hw.imageUrls != null && hw.imageUrls!.isNotEmpty) ||
                (hw.imageUrl != null && hw.imageUrl!.trim().isNotEmpty)) ...[
              ...((hw.fullResolutionUrls != null &&
                          hw.fullResolutionUrls!.isNotEmpty)
                      ? hw.fullResolutionUrls!
                      : (hw.imageUrls != null && hw.imageUrls!.isNotEmpty)
                          ? hw.imageUrls!
                          : [hw.imageUrl!])
                  .map((url) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: url.startsWith('http')
                        ? NetworkPhoto(
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
                                  child: Icon(Icons.broken_image_rounded,
                                      color: palette.onSurface3)),
                            ),
                          )
                        : Image.file(
                            File(url),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 150,
                              color: palette.surface3,
                              child: Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: palette.onSurface3)),
                            ),
                          ),
                  ),
                );
              }),
            ],
            Text(hw.task,
                style:
                    TextStyle(fontSize: 14, color: palette.onBg, height: 1.4)),
            if (editable) ...[
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteHomework(hw.id),
                    icon: const Icon(Icons.delete_rounded, size: 16),
                    label:
                        const Text('Удалить', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
