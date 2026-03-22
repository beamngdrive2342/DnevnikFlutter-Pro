import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../data/schedule_data.dart';
import '../data/firestore_service.dart';

class HomeworkScreen extends StatefulWidget {
  final VoidCallback onAddPressed;
  const HomeworkScreen({super.key, required this.onAddPressed});

  @override
  State<HomeworkScreen> createState() => HomeworkScreenState();
}

class HomeworkScreenState extends State<HomeworkScreen> {
  String _filter = 'pending'; // 'pending' | 'done'
  Map<String, bool> _doneState = {};
  List<HomeworkItem> _customHomework = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final doneJson = prefs.getString('dnevnik_done') ?? '{}';
    final list = await FirestoreService.getHomework();

    setState(() {
      _doneState = Map<String, bool>.from(jsonDecode(doneJson));
      _customHomework = list;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dnevnik_done', jsonEncode(_doneState));
  }

  Future<void> addHomework(HomeworkItem hw) async {
    final success = await FirestoreService.addHomework(hw);
    if (success) {
      setState(() {
        _customHomework.add(hw);
      });
    }
  }

  List<HomeworkItem> _getAllHomework() {
    final List<HomeworkItem> fromSchedule = [];
    for (var entry in weekSchedule.entries) {
      for (var lesson in entry.value) {
        if (lesson.hw.isNotEmpty) {
          final id = 'sch_${lesson.subject}_${lesson.time}';
          fromSchedule.add(HomeworkItem(
            id: id,
            subject: lesson.subject,
            task: lesson.hw,
            deadline: _getNextDeadline(),
            fromSchedule: true,
            done: _doneState[id] ?? false,
          ));
        }
      }
    }

    final merged = [...fromSchedule, ..._customHomework];
    final seen = <String>{};
    final deduped = merged.where((hw) {
      if (seen.contains(hw.id)) return false;
      seen.add(hw.id);
      return true;
    }).toList();

    if (_filter == 'done') {
      return deduped.where((hw) => _doneState[hw.id] == true).toList();
    }
    return deduped.where((hw) => _doneState[hw.id] != true).toList();
  }

  String _getNextDeadline() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
  }

  void _toggleDone(String id) {
    setState(() {
      _doneState[id] = !(_doneState[id] ?? false);
    });
    _saveData();
  }

  String _formatDeadline(String deadlineStr) {
    if (deadlineStr.isEmpty) return 'Срок не указан';
    try {
      final d = DateTime.parse(deadlineStr);
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      final dNormalized = DateTime(d.year, d.month, d.day);
      final diff = dNormalized.difference(todayNormalized).inDays;

      if (diff == 0) return 'Сегодня';
      if (diff == 1) return 'Завтра';
      if (diff < 0) return 'Просрочено (${diff.abs()} дн.)';
      return 'Через $diff дн. — ${d.day} ${monthsShort[d.month - 1]}';
    } catch (_) {
      return 'Срок не указан';
    }
  }

  bool _isUrgent(String deadlineStr) {
    if (deadlineStr.isEmpty) return false;
    try {
      final d = DateTime.parse(deadlineStr);
      final diff = d.difference(DateTime.now()).inDays;
      return diff <= 1;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        _buildTabs(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.bg.withValues(alpha: 0.4),
        border: const Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_rounded, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Домашние задания',
                  style: TextStyle(
                    fontFamily: AppTheme.fontSerif,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onBg,
                  )),
              Text('Все предметы',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  )),
            ],
          ),
          const Spacer(),
          Material(
            color: AppTheme.surface2,
            borderRadius: BorderRadius.circular(100),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(100),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.tune_rounded, color: AppTheme.onSurface2, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          _tab('Текущие', 'pending'),
          _tab('Выполненные', 'done'),
        ],
      ),
    );
  }

  Widget _tab(String label, String value) {
    final isActive = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isActive ? AppTheme.primaryDim : AppTheme.onSurface3,
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final items = _getAllHomework();
    if (items.isEmpty) {
      final isDone = _filter == 'done';
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDone ? Icons.task_alt_rounded : Icons.check_circle_rounded,
              size: 48,
              color: AppTheme.onSurface3.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isDone ? 'Выполненных заданий нет' : 'Все задания выполнены!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isDone
                  ? 'Завершённые задания появятся здесь.'
                  : 'Отличная работа, Иван!',
              style: const TextStyle(fontSize: 13, color: AppTheme.onSurface3),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final hw = items[index];
        final isDone = _doneState[hw.id] == true;
        final urgent = _isUrgent(hw.deadline);

        return AnimatedOpacity(
          opacity: isDone ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => _toggleDone(hw.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppTheme.primary : Colors.transparent,
                      border: Border.all(
                        color: isDone ? AppTheme.primary : AppTheme.onSurface3,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hw.subject,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onBg,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          )),
                      const SizedBox(height: 4),
                      Text(hw.task,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.onSurface2,
                            height: 1.45,
                          )),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 13,
                              color: urgent
                                  ? AppTheme.danger
                                  : AppTheme.onSurface3),
                          const SizedBox(width: 4),
                          Text(
                            _formatDeadline(hw.deadline),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: urgent
                                  ? AppTheme.danger
                                  : AppTheme.onSurface3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
