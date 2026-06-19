import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/schedule_data.dart';

class CalendarStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime today;
  final int selectedDayIndex;
  final ScrollController scrollController;
  final Function(int) onDaySelected;

  const CalendarStrip({
    super.key,
    required this.days,
    required this.today,
    required this.selectedDayIndex,
    required this.scrollController,
    required this.onDaySelected,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return SizedBox(
      height: 82,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final d = days[index];
          final isToday = _isSameDay(d, today);
          final isSelected = index == selectedDayIndex;
          final dayOfWeek = d.weekday - 1; // 0=Mon, 6=Sun
          final hasLessons = weekSchedule[dayOfWeek] != null &&
              weekSchedule[dayOfWeek]!.isNotEmpty;

          return GestureDetector(
            onTap: () => onDaySelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 56,
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : palette.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : palette.cardBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdaysShort[dayOfWeek],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.78)
                          : palette.onSurface3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontSerif,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : palette.onBg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasLessons)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.primaryDim.withValues(alpha: 0.5),
                      ),
                    )
                  else if (isToday && !isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
