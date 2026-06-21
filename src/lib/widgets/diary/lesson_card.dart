import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/schedule_data.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final List<HomeworkItem> customHw;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.customHw,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final hasAnyHw = lesson.hw.isNotEmpty || customHw.isNotEmpty;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: palette.cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            onTap: () {
              if (hasAnyHw) {
                onTap();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryLight,
                        ),
                        child: Center(
                          child: Text('${lesson.num}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDim,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(lesson.subject,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: palette.onBg,
                                        height: 1.2,
                                      )),
                                ),
                                if (hasAnyHw)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin:
                                        const EdgeInsets.only(left: 8, top: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryDim,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryDim
                                              .withValues(alpha: 0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(lesson.time,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: palette.onBg.withValues(alpha: 0.45),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasAnyHw) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDim.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                            color: AppTheme.primaryDim.withValues(alpha: 0.2)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 4,
                              color: AppTheme.primaryDim,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.assignment_rounded,
                                            size: 12,
                                            color: AppTheme.primaryDim),
                                        SizedBox(width: 6),
                                        Text('ЗАДАНО',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.0,
                                              color: AppTheme.primaryDim,
                                            )),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (lesson.hw.isNotEmpty)
                                      Text(lesson.hw,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: palette.onSurface,
                                            height: 1.5,
                                            fontWeight: FontWeight.w500,
                                          )),
                                    for (var ch in customHw)
                                      Padding(
                                        padding: EdgeInsets.only(
                                            top: (lesson.hw.isNotEmpty ||
                                                    customHw.indexOf(ch) > 0)
                                                ? 6
                                                : 0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('• ',
                                                style: TextStyle(
                                                    color: AppTheme.primaryDim,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                            Expanded(
                                                child: Text(ch.task,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color:
                                                            palette.onSurface,
                                                        height: 1.5,
                                                        fontWeight:
                                                            FontWeight.w500))),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
