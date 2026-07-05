import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/schedule_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/scale_tap_wrapper.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DiaryTopBar extends ConsumerWidget {
  const DiaryTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.colorsOf(context);
    final className = ClassSchedule.className.trim().isNotEmpty
        ? ClassSchedule.className.trim()
        : 'Класс';
    final schoolName = ClassSchedule.schoolName.trim().isNotEmpty
        ? ClassSchedule.schoolName.trim()
        : 'Школа';

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(color: palette.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.bookOpen, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                className,
                style: TextStyle(
                  fontFamily: AppTheme.fontSerif,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.onBg,
                ),
              ),
              Text(
                schoolName,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Кнопка настроек — заменяет отдельные кнопки темы и логаута
          ScaleTapWrapper(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: palette.surface2.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.cardBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                LucideIcons.settings,
                color: palette.onSurface2,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
