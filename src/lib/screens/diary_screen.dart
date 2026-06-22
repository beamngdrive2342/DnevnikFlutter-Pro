import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import '../theme/app_theme.dart';
import '../data/schedule_data.dart';
import '../data/firestore_service.dart';
import '../utils/image_data.dart';
import '../widgets/fast_page_scroll_physics.dart';
import '../widgets/network_photo.dart';
import '../widgets/top_notification.dart';
import '../widgets/diary/lesson_card.dart';
import '../widgets/diary/calendar_strip.dart';
import '../widgets/shimmer_loading.dart';
import 'diary/diary_top_bar.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => DiaryScreenState();
}

class DiaryScreenState extends State<DiaryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const Duration _imageDownloadTimeout = Duration(seconds: 15);
  AppPalette get palette => AppTheme.colorsOf(context);

  static const int _initialDayIndex = 3;
  late int _selectedDayIndex;
  late ScrollController _calendarScrollController;
  late PageController _pageController;
  late List<DateTime> _days;
  late DateTime _today;
  Map<String, List<HomeworkItem>> _homeworkLookup = {};
  bool _isLoadingHomework = true;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _days = List.generate(14, (i) => _today.add(Duration(days: i - 3)));
    _selectedDayIndex = _initialDayIndex;
    _calendarScrollController = ScrollController();
    _pageController = PageController(initialPage: _initialDayIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(_initialDayIndex);
      _loadCustomHomework();
    });
  }

  Future<void> _loadCustomHomework({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingHomework = true;
    });
    final list = await FirestoreService.getHomework(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _homeworkLookup = _buildHomeworkLookup(list);
      _isLoadingHomework = false;
    });
  }

  Future<void> reloadHomework({bool forceRefresh = false}) {
    return _loadCustomHomework(forceRefresh: forceRefresh);
  }

  Map<String, List<HomeworkItem>> _buildHomeworkLookup(
      List<HomeworkItem> homework) {
    final lookup = <String, List<HomeworkItem>>{};
    for (final item in homework) {
      final key = _buildHomeworkKey(item.deadline, item.subject);
      (lookup[key] ??= <HomeworkItem>[]).add(item);
    }
    return lookup;
  }

  String _buildHomeworkKey(String date, String subject) => '$date|$subject';

  void _scrollToIndex(int index) {
    if (!_calendarScrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (index * 62.0) - (screenWidth / 2) + 31.0;

    _calendarScrollController.animateTo(
      offset.clamp(0.0, _calendarScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        const DiaryTopBar(),
        const SizedBox(height: 12),
        CalendarStrip(
          days: _days,
          today: _today,
          selectedDayIndex: _selectedDayIndex,
          scrollController: _calendarScrollController,
          onDaySelected: (index) {
            setState(() => _selectedDayIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
            );
            _scrollToIndex(index);
          },
        ),
        // Native paged scrolling: smoother and less jank than manual drag+spring.
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const FastPageScrollPhysics(),
            allowImplicitScrolling: true,
            onPageChanged: (index) {
              setState(() => _selectedDayIndex = index);
              _scrollToIndex(index);
            },
            itemCount: _days.length,
            itemBuilder: (context, index) {
              return _buildLessonsSectionForDay(_days[index]);
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════ CALENDAR STRIP



  // ═══════════════════════════════════ LESSONS
  Widget _buildLessonsSectionForDay(DateTime date) {
    final dayOfWeek = date.weekday - 1;
    final lessons = weekSchedule[dayOfWeek] ?? [];
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final lessonHomework = _buildLessonHomeworkMap(dateStr, lessons);

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Расписание',
                style: TextStyle(
                  fontFamily: AppTheme.fontSerif,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: palette.onBg,
                )),
            Text(weekdaysFull[dayOfWeek],
                style: TextStyle(
                  fontSize: 12,
                  color: palette.onSurface2,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingHomework && lessons.isNotEmpty)
          ...List.generate(lessons.length, (i) => const SkeletonLessonCard())
        else if (lessons.isEmpty)
          _buildNoLessons()
        else
          ...lessons.asMap().entries.map((entry) {
            return LessonCard(
              lesson: entry.value,
              customHw: lessonHomework[entry.key] ?? const <HomeworkItem>[],
              onTap: () {
                _showLessonDetailsSheet(
                  context,
                  entry.value,
                  lessonHomework[entry.key] ?? const <HomeworkItem>[],
                );
              },
            );
          }),
      ],
    );
  }

  Map<int, List<HomeworkItem>> _buildLessonHomeworkMap(
    String dateStr,
    List<Lesson> lessons,
  ) {
    final assigned = <int, List<HomeworkItem>>{};
    final firstSubjectIndex = <String, int>{};

    for (var i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      firstSubjectIndex.putIfAbsent(lesson.subject, () => i);
    }

    for (final entry in firstSubjectIndex.entries) {
      final key = _buildHomeworkKey(dateStr, entry.key);
      final items = _homeworkLookup[key];
      if (items != null && items.isNotEmpty) {
        assigned[entry.value] = items;
      }
    }

    return assigned;
  }

  Widget _buildNoLessons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.weekend_rounded,
              size: 48, color: palette.onSurface3.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('В этот день уроков нет. Отдыхай!',
              style: TextStyle(fontSize: 14, color: palette.onSurface3)),
        ],
      ),
    );
  }



  // ignore: unused_element
  void _showLessonDetails(
      BuildContext context, Lesson lesson, List<HomeworkItem> customHw) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRect(
            child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: palette.bg.withValues(alpha: 0.85),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: palette.cardBorder),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.onSurface3.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.subject,
                          style: TextStyle(
                              fontFamily: AppTheme.fontSerif,
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: palette.onBg),
                        ),
                        const SizedBox(height: 32),
                        Text('Задание',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: palette.onBg)),
                        const SizedBox(height: 16),
                        if (lesson.hw.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: palette.surface2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: palette.cardBorder),
                            ),
                            child: Text(lesson.hw,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: palette.onBg,
                                    height: 1.5)),
                          ),
                        if (lesson.hw.isNotEmpty && customHw.isNotEmpty)
                          const SizedBox(height: 12),
                        ...customHw.map((hw) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(hw.task,
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: palette.onBg,
                                          height: 1.5)),
                                  if ((hw.imageUrls != null &&
                                          hw.imageUrls!.isNotEmpty) ||
                                      (hw.imageUrl != null &&
                                          hw.imageUrl!.trim().isNotEmpty)) ...[
                                    const SizedBox(height: 16),
                                    ...((hw.imageUrls != null &&
                                                hw.imageUrls!.isNotEmpty)
                                            ? List.generate(
                                                hw.imageUrls!.length, (i) {
                                                return {
                                                  'display': (hw.fullResolutionUrls !=
                                                              null &&
                                                          hw.fullResolutionUrls!
                                                                  .length >
                                                              i)
                                                      ? hw.fullResolutionUrls![
                                                          i]
                                                      : hw.imageUrls![i],
                                                  'full': (hw.fullResolutionUrls !=
                                                              null &&
                                                          hw.fullResolutionUrls!
                                                                  .length >
                                                              i)
                                                      ? hw.fullResolutionUrls![
                                                          i]
                                                      : hw.imageUrls![i]
                                                };
                                              })
                                            : [
                                                {
                                                  'display': hw.imageUrl!,
                                                  'full': hw.imageUrl!
                                                }
                                              ])
                                        .map((imageMap) {
                                      final displayUrl = imageMap['display']!;
                                      final fullUrl = imageMap['full']!;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              _openFullScreenImage(
                                                  context, fullUrl);
                                            },
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme.radiusSm),
                                              child: NetworkPhoto(
                                                url: displayUrl,
                                                width: double.infinity,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                loading: Container(
                                                  height: 120,
                                                  color: palette.surface3,
                                                  alignment: Alignment.center,
                                                  child: const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppTheme.primary,
                                                    ),
                                                  ),
                                                ),
                                                error: Container(
                                                  height: 120,
                                                  color: palette.surface3,
                                                  child: const Center(
                                                      child: Icon(
                                                          Icons
                                                              .broken_image_rounded,
                                                          color: AppTheme
                                                              .onSurface3)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  _saveImageToGallery(
                                                context,
                                                fullUrl,
                                              ),
                                              /*
                                                try {
                                                  final hasAccess =
                                                      await Gal.hasAccess();
                                                  if (!hasAccess) {
                                                    final request = await Gal
                                                        .requestAccess();
                                                    if (!request &&
                                                        context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Нет разрешения к галерее')),
                                                      );
                                                      return;
                                                    }
                                                  }

                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Сохраняем фото...'),
                                                          duration: Duration(
                                                              seconds: 1)),
                                                    );
                                                  }

                                                  List<int> bytes;
                                                  if (fullUrl
                                                      .startsWith('http')) {
                                                    final response = await http
                                                        .get(Uri.parse(fullUrl))
                                                        .timeout(
                                                            _imageDownloadTimeout);
                                                    if (response.statusCode ==
                                                        200) {
                                                      bytes =
                                                          response.bodyBytes;
                                                    } else {
                                                      throw Exception(
                                                          'Не удалось загрузить фото');
                                                    }
                                                  } else {
                                                    final f = File(fullUrl);
                                                    if (!f.existsSync()) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Файл не найден (кэш очищен)')),
                                                        );
                                                      }
                                                      return;
                                                    }
                                                    bytes =
                                                        await f.readAsBytes();
                                                  }

                                                  await Gal.putImageBytes(
                                                      Uint8List.fromList(
                                                          bytes));
                                                  if (context.mounted) {
                                                    _showTopNotification(
                                                        context,
                                                        'Фото успешно сохранено в галерею!');
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Ошибка при сохранении: $e')),
                                                    );
                                                  }
                                                }
                                              },
                                              */
                                              icon: const Icon(
                                                  Icons.download_rounded,
                                                  size: 16),
                                              label: const Text(
                                                  'Сохранить фото',
                                                  style:
                                                      TextStyle(fontSize: 13)),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppTheme.primary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 0),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      },
    );
  }

  void _showLessonDetailsSheet(
    BuildContext context,
    Lesson lesson,
    List<HomeworkItem> customHw,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(
                color: palette.bg.withValues(alpha: 0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: palette.cardBorder),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: palette.onSurface3.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    lesson.subject,
                    style: TextStyle(
                      fontFamily: AppTheme.fontSerif,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: palette.onBg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.time,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.onSurface2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lesson.hw.isNotEmpty) ...[
                            _buildDetailsSectionTitle('Задание из расписания'),
                            const SizedBox(height: 12),
                            _buildHomeworkTextCard(
                              lesson.hw,
                              backgroundColor: palette.surface2,
                              borderColor: palette.cardBorder,
                            ),
                            const SizedBox(height: 18),
                          ],
                          ...customHw.map((hw) {
                            final images = _homeworkImageMaps(hw);
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.24),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.assignment_rounded,
                                        size: 18,
                                        color: AppTheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Домашнее задание',
                                        style: TextStyle(
                                          color: palette.onBg,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _buildHomeworkTextCard(
                                    hw.task,
                                    backgroundColor:
                                        palette.surface.withValues(alpha: 0.55),
                                    borderColor: AppTheme.primary
                                        .withValues(alpha: 0.18),
                                  ),
                                  if (images.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    _buildDetailsSectionTitle('Фото'),
                                    const SizedBox(height: 10),
                                    ...images.map((imageMap) {
                                      final displayUrl = imageMap['display']!;
                                      final fullUrl = imageMap['full']!;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: _buildHomeworkImageCard(
                                          context,
                                          displayUrl: displayUrl,
                                          fullUrl: fullUrl,
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: palette.onSurface2,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildHomeworkTextCard(
    String text, {
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 15,
          color: palette.onBg,
          height: 1.55,
        ),
      ),
    );
  }

  List<Map<String, String>> _homeworkImageMaps(HomeworkItem hw) {
    if (hw.imageUrls != null && hw.imageUrls!.isNotEmpty) {
      return List.generate(hw.imageUrls!.length, (i) {
        final display = hw.imageUrls![i];
        final full =
            (hw.fullResolutionUrls != null && hw.fullResolutionUrls!.length > i)
                ? hw.fullResolutionUrls![i]
                : display;
        return <String, String>{'display': display, 'full': full};
      });
    }

    if (hw.imageUrl != null && hw.imageUrl!.trim().isNotEmpty) {
      return <Map<String, String>>[
        <String, String>{'display': hw.imageUrl!, 'full': hw.imageUrl!},
      ];
    }

    return const <Map<String, String>>[];
  }

  Widget _buildHomeworkImageCard(
    BuildContext context, {
    required String displayUrl,
    required String fullUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => _openFullScreenImage(context, fullUrl),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ColoredBox(
                  color: palette.surface3,
                  child: NetworkPhoto(
                    url: displayUrl,
                    fit: BoxFit.contain,
                    loading: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    error: Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: palette.onSurface3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _saveImageToGallery(context, fullUrl),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text(
                    'Сохранить фото',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _saveImageToGallery(BuildContext context, String source) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет разрешения к галерее')),
          );
          return;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сохраняем фото...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final bytes = await loadImageBytes(
        source,
        timeout: _imageDownloadTimeout,
      );
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Не удалось загрузить фото');
      }

      await Gal.putImageBytes(bytes);
      if (context.mounted) {
        showTopNotification(
          context,
          'Фото успешно сохранено в галерею!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении: $e')),
        );
      }
    }
  }

  void _openFullScreenImage(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (ctx, anim, secondAnim) {
          return FadeTransition(
            opacity: anim,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Center(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 8.0,
                        child: NetworkPhoto(
                          url: url,
                          fit: BoxFit.contain,
                          loading: const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          ),
                          error: Icon(
                            Icons.broken_image_rounded,
                            color: palette.onSurface3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(ctx).padding.top + 12,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}
