import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../data/schedule_data.dart';
import '../premium_card.dart';

class LessonCard extends StatefulWidget {
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
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final hasAnyHw = widget.lesson.hw.isNotEmpty || widget.customHw.isNotEmpty;

    return PremiumCard(
      padding: EdgeInsets.zero,
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.2),
                          AppTheme.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text('${widget.lesson.num}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontSans,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDim,
                          )),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.lesson.subject,
                                style: AppTextStyles.h2Sans(context).copyWith(fontSize: 17),
                              ),
                            ),
                            if (hasAnyHw)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryDim,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryDim.withValues(alpha: 0.6),
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.lesson.time,
                              style: AppTextStyles.caption(context),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: palette.onSurface3,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (_isExpanded && hasAnyHw) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDim.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                        color: AppTheme.primaryDim.withValues(alpha: 0.15)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_rounded,
                                  size: 14, color: AppTheme.primaryDim),
                              const SizedBox(width: 6),
                              Text('ДОМАШНЕЕ ЗАДАНИЕ',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontSans,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppTheme.primaryDim,
                                  )),
                            ],
                          ),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryDim.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.open_in_new_rounded,
                                  size: 16, color: AppTheme.primaryDim),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (widget.lesson.hw.isNotEmpty)
                        Text(widget.lesson.hw,
                            style: AppTextStyles.body(context).copyWith(fontSize: 14)),
                      for (var ch in widget.customHw)
                        Padding(
                          padding: EdgeInsets.only(
                              top: (widget.lesson.hw.isNotEmpty ||
                                      widget.customHw.indexOf(ch) > 0)
                                  ? 8
                                  : 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: AppTheme.primaryDim,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Expanded(
                                child: Text(ch.task,
                                    style: AppTextStyles.body(context).copyWith(fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
