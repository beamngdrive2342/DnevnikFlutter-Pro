import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/schedule_data.dart';
import '../data/firestore_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAllHomework();
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

  Future<void> _refreshFromPull() async {
    await _loadAllHomework(forceRefresh: true, showLoading: false);
    widget.onHomeworkChanged();
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Public method so MainScreen can trigger a refresh
  void reload() => _loadAllHomework();

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
        backgroundColor: const Color(0xFF2E2218),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Редактировать задание',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
          const TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.onSurface2,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: AppTheme.cardBorder,
            tabs: [Tab(text: 'Текущие'), Tab(text: 'Завершённые')],
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : TabBarView(
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
    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _refreshFromPull,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            const SizedBox(height: 180),
            _buildEmptyState(),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _refreshFromPull,
      child: ListView.builder(
        padding:
            const EdgeInsets.only(top: 16, bottom: 100, left: 20, right: 20),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildAdminCard(items[index], editable: editable);
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.bg.withValues(alpha: 0.4),
        border: const Border(
            bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings_rounded,
              color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          const Text('Админ-панель',
              style: TextStyle(
                fontFamily: AppTheme.fontSerif,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.onBg,
              )),
          const Spacer(),
          Text('Всего: ${_customHomework.length}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.onSurface2,
                fontWeight: FontWeight.w600,
              )),
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
              size: 64, color: AppTheme.onSurface3.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('Нет заданий',
              style: TextStyle(color: AppTheme.onSurface3, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAdminCard(HomeworkItem hw, {required bool editable}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.cardBorder),
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
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurface2,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if ((hw.imageUrls != null && hw.imageUrls!.isNotEmpty) ||
                (hw.imageUrl != null && hw.imageUrl!.trim().isNotEmpty)) ...[
              ...((hw.imageUrls != null && hw.imageUrls!.isNotEmpty)
                      ? hw.imageUrls!
                      : [hw.imageUrl!])
                  .map((url) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: url.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: url,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (ctx, value) => Container(
                              height: 150,
                              color: AppTheme.surface3,
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
                            errorWidget: (ctx, value, err) => Container(
                              height: 150,
                              color: AppTheme.surface3,
                              child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: AppTheme.onSurface3)),
                            ),
                          )
                        : Image.file(
                            File(url),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 150,
                              color: AppTheme.surface3,
                              child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: AppTheme.onSurface3)),
                            ),
                          ),
                  ),
                );
              }),
            ],
            Text(hw.task,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.onBg, height: 1.4)),
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
