import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../data/schedule_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/theme_switch_button.dart';
import '../../widgets/scale_tap_wrapper.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DiaryTopBar extends ConsumerWidget {
  const DiaryTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.colorsOf(context);
    final className = ClassSchedule.className.trim().isNotEmpty
        ? ClassSchedule.className.trim()
        : '\u041A\u043B\u0430\u0441\u0441';
    final schoolName = ClassSchedule.schoolName.trim().isNotEmpty
        ? ClassSchedule.schoolName.trim()
        : '\u0428\u043A\u043E\u043B\u0430';

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
          Icon(LucideIcons.bookOpen,
              color: AppTheme.primary, size: 22),
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
          const ThemeSwitchButton(),
          const SizedBox(width: 12),
          ScaleTapWrapper(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: palette.surface2.withValues(alpha: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    '\u0412\u044B\u0439\u0442\u0438 \u0438\u0437 \u0430\u043A\u043A\u0430\u0443\u043D\u0442\u0430?',
                    style: TextStyle(color: palette.onBg, fontSize: 18),
                  ),
                  content: Text(
                    '\u0412\u044B \u0432\u0435\u0440\u043D\u0451\u0442\u0435\u0441\u044C \u043A \u0432\u044B\u0431\u043E\u0440\u0443 \u0440\u043E\u043B\u0438',
                    style: TextStyle(color: palette.onSurface2),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        '\u041E\u0442\u043C\u0435\u043D\u0430',
                        style: TextStyle(color: palette.onSurface2),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        '\u0412\u044B\u0439\u0442\u0438',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).logout();
              }
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 2),
              ),
              child: ClipOval(
                child: Container(
                  color: AppTheme.primary,
                  child: Center(
                    child: Icon(
                      LucideIcons.home,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
