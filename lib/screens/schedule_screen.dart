import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/schedule_data.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late int _currentWeekDay;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday; // 1=Mon..7=Sun
    _currentWeekDay = today == 7 ? 1 : today;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        _buildWeekTabs(),
        Expanded(child: _buildScheduleGrid()),
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
      child: const Row(
        children: [
          Icon(Icons.calendar_today_rounded,
              color: AppTheme.primary, size: 22),
          SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Расписание',
                  style: TextStyle(
                    fontFamily: AppTheme.fontSerif,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onBg,
                  )),
              Text('Неделя',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTabs() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        itemCount: weekDaysNames.length,
        itemBuilder: (context, index) {
          final dayNum = index + 1; // 1=Mon..6=Sat
          final isActive = _currentWeekDay == dayNum;

          return GestureDetector(
            onTap: () => setState(() => _currentWeekDay = dayNum),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isActive ? AppTheme.primary : AppTheme.cardBorder,
                ),
              ),
              child: Center(
                child: Text(
                  weekDaysNames[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppTheme.onSurface2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleGrid() {
    final lessons = weekSchedule[_currentWeekDay - 1] ?? [];

    if (lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.weekend_rounded,
                size: 48,
                color: AppTheme.onSurface3.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('Выходной день',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface3)),
            const SizedBox(height: 4),
            const Text('Уроков нет. Время отдохнуть!',
                style: TextStyle(fontSize: 13, color: AppTheme.onSurface3)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final parts = lesson.time.split(' – ');
        final start = parts.isNotEmpty ? parts[0] : '';
        final end = parts.length > 1 ? parts[1] : '';
        final isLast = index == lessons.length - 1;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: AppTheme.cardBorder)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(start,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface2,
                        )),
                    Text(end,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.onSurface3,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Timeline line with dot
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 1,
                      height: 50,
                      color: AppTheme.cardBorder,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.subject,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onBg,
                        )),
                    const SizedBox(height: 3),
                    Text('${lesson.room} • ${lesson.topic}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurface2,
                        )),
                    if (lesson.hw.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text('ЗАДАНИЕ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppTheme.primaryDim,
                            )),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
