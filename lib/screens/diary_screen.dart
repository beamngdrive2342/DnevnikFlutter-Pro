import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/physics.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../data/schedule_data.dart';
import '../data/firestore_service.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => DiaryScreenState();
}

class DiaryScreenState extends State<DiaryScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  late ScrollController _calendarScrollController;
  late PageController _pageController;
  late AnimationController _springController;
  late List<DateTime> _days;
  late DateTime _today;
  List<HomeworkItem> _customHomework = [];

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _days = List.generate(14, (i) => _today.add(Duration(days: i - 3)));
    _selectedDate = _today;
    _calendarScrollController = ScrollController();
    _pageController = PageController(initialPage: 3);

    _springController = AnimationController.unbounded(vsync: this);
    _springController.addListener(() {
      if (_pageController.hasClients) {
        _pageController.position.jumpTo(_springController.value);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(3);
    });
    _loadCustomHomework();
  }

  Future<void> _loadCustomHomework() async {
    final list = await FirestoreService.getHomework();
    if (!mounted) return;
    setState(() {
      _customHomework = list;
    });
  }

  void reloadHomework() {
    _loadCustomHomework();
  }

  void _scrollToIndex(int index) {
    if (!_calendarScrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (index * 62.0) - (screenWidth / 2) + 31.0;

    _calendarScrollController.animateTo(
      offset.clamp(0.0, _calendarScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    _pageController.dispose();
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context),
        const SizedBox(height: 12),
        _buildCalendarStrip(),
        // Swipable day content
        Expanded(
          child: GestureDetector(
            onHorizontalDragStart: (details) {
              _springController.stop();
            },
            onHorizontalDragUpdate: (details) {
              _pageController.position.jumpTo(
                _pageController.position.pixels - details.primaryDelta!,
              );
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0.0;
              final width = MediaQuery.of(context).size.width;
              final currentPixels = _pageController.position.pixels;

              int currentPage = (currentPixels / width).round();
              int targetPage = currentPage;

              if (velocity < -200 && targetPage < _days.length - 1) {
                targetPage++;
              } else if (velocity > 200 && targetPage > 0) {
                targetPage--;
              }
              targetPage = targetPage.clamp(0, _days.length - 1);

              final targetPixels = targetPage * width;

              final simulation = SpringSimulation(
                SpringDescription.withDampingRatio(
                  mass: 0.6,
                  stiffness: 280.0,
                  ratio: 0.85,
                ),
                currentPixels,
                targetPixels,
                -velocity,
              );

              _springController.animateWith(simulation);
            },
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _selectedDate = _days[index]);
                _scrollToIndex(index);
              },
              itemCount: _days.length,
              itemBuilder: (context, index) {
                return _buildLessonsSectionForDay(_days[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════ TOP BAR
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.bg.withValues(alpha: 0.4),
        border: const Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded,
              color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Школьный Дневник',
                  style: TextStyle(
                    fontFamily: AppTheme.fontSerif,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onBg,
                  )),
              Text('10А',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  )),
            ],
          ),
          const Spacer(),
          // Logout / Profile button
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF2E2218),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('Выйти из аккаунта?',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                  content: const Text('Вы вернётесь к выбору роли',
                      style: TextStyle(color: Colors.grey)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Отмена',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Выйти',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('dnevnik_role');
                if (!context.mounted) return;
                // Restart the app at RoleGate
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const _RoleGateRedirect()),
                  (route) => false,
                );
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
                  child: const Center(
                    child: Text('И',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════ CALENDAR STRIP
  Widget _buildCalendarStrip() {
    return SizedBox(
      height: 82,
      child: ListView.builder(
        controller: _calendarScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final d = _days[index];
          final isToday = _isSameDay(d, _today);
          final isSelected = _isSameDay(d, _selectedDate);
          final dayOfWeek = d.weekday - 1; // 0=Mon, 6=Sun
          final hasLessons = weekSchedule[dayOfWeek] != null &&
              weekSchedule[dayOfWeek]!.isNotEmpty;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = d);
              _springController.stop();

              final width = MediaQuery.of(context).size.width;
              final targetPixels = index * width;

              final simulation = SpringSimulation(
                SpringDescription.withDampingRatio(
                  mass: 0.6,
                  stiffness: 280.0,
                  ratio: 0.85,
                ),
                _pageController.position.pixels,
                targetPixels,
                0.0, // Initial velocity for tap is 0
              );

              _springController.animateWith(simulation);
              _scrollToIndex(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
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
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.onSurface3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontSerif,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.onBg,
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

  // ═══════════════════════════════════ LESSONS
  Widget _buildLessonsSectionForDay(DateTime date) {
    final dayOfWeek = date.weekday - 1;
    final lessons = weekSchedule[dayOfWeek] ?? [];
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Расписание',
                style: TextStyle(
                  fontFamily: AppTheme.fontSerif,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onBg,
                )),
            Text(weekdaysFull[dayOfWeek],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurface2,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
        const SizedBox(height: 16),
        if (lessons.isEmpty)
          _buildNoLessons()
        else
          ...lessons.map((lesson) {
            final additionalHw = _customHomework
                .where((hw) =>
                    hw.deadline == dateStr && hw.subject == lesson.subject)
                .toList();
            return _buildLessonCard(lesson, additionalHw);
          }),
      ],
    );
  }

  Widget _buildNoLessons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.weekend_rounded,
              size: 48, color: AppTheme.onSurface3.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text('В этот день уроков нет. Отдыхай!',
              style: TextStyle(fontSize: 14, color: AppTheme.onSurface3)),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Lesson lesson, List<HomeworkItem> customHw) {
    final hasAnyHw = lesson.hw.isNotEmpty || customHw.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () {
            if (hasAnyHw) {
              _showLessonDetails(context, lesson, customHw);
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
                          Text(lesson.subject,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onBg,
                                height: 1.2,
                              )),
                          const SizedBox(height: 3),
                          Text(lesson.time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onBg.withValues(alpha: 0.45),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ЗАДАНО',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppTheme.primaryDim,
                            )),
                        const SizedBox(height: 5),
                        if (lesson.hw.isNotEmpty)
                          Text(lesson.hw,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.onSurface,
                                height: 1.5,
                              )),
                        for (var ch in customHw)
                          Padding(
                            padding: EdgeInsets.only(
                                top: lesson.hw.isNotEmpty ? 6 : 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: AppTheme.primaryDim,
                                        fontSize: 13)),
                                Expanded(
                                    child: Text(ch.task,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.onSurface,
                                            height: 1.5))),
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
      ),
    );
  }

  void _showLessonDetails(
      BuildContext context, Lesson lesson, List<HomeworkItem> customHw) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: AppTheme.bg.withValues(alpha: 0.85),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppTheme.cardBorder),
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
                      color: AppTheme.onSurface3.withValues(alpha: 0.5),
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
                          style: const TextStyle(
                              fontFamily: AppTheme.fontSerif,
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onBg),
                        ),
                        const SizedBox(height: 32),
                        const Text('Задание',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onBg)),
                        const SizedBox(height: 16),
                        if (lesson.hw.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Text(lesson.hw,
                                style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.onBg,
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
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: AppTheme.onBg,
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
                                                  'display': hw.imageUrls![i],
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
                                              child: displayUrl
                                                      .startsWith('http')
                                                  ? Image.network(
                                                      displayUrl,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (ctx, err, stack) =>
                                                              Container(
                                                        height: 120,
                                                        color:
                                                            AppTheme.surface3,
                                                        child: const Center(
                                                            child: Icon(
                                                                Icons
                                                                    .broken_image_rounded,
                                                                color: AppTheme
                                                                    .onSurface3)),
                                                      ),
                                                    )
                                                  : Image.file(
                                                      File(displayUrl),
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (ctx, err, stack) =>
                                                              Container(
                                                        height: 120,
                                                        color:
                                                            AppTheme.surface3,
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
                                              onPressed: () async {
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
                                                    final response =
                                                        await http.get(
                                                            Uri.parse(fullUrl));
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
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
                        child: url.startsWith('http')
                            ? Image.network(url, fit: BoxFit.contain)
                            : Image.file(File(url), fit: BoxFit.contain),
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

  void _showTopNotification(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopNotification(
        message: message,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _TopNotification extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const _TopNotification({required this.message, required this.onDismiss});
  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Redirect widget used for logout — navigates back to RoleGate
class _RoleGateRedirect extends StatelessWidget {
  const _RoleGateRedirect();
  @override
  Widget build(BuildContext context) {
    // We directly build the MaterialApp again to reset navigation stack
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU')],
      home: const RoleGate(),
    );
  }
}
