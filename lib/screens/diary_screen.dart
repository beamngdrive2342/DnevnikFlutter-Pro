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
                _pageController.position.pixels - details.delta.dx,
              );
            },
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              final currentPixels = _pageController.position.pixels;
              final pageWidth = MediaQuery.of(context).size.width;

              int targetPage;
              if (velocity.abs() > 500) {
                targetPage = velocity > 0
                    ? (_pageController.page?.floor() ?? 0)
                    : (_pageController.page?.ceil() ?? 0);
              } else {
                targetPage = _pageController.page?.round() ?? 0;
              }

              targetPage = targetPage.clamp(0, _days.length - 1);
              final targetPixels = targetPage * pageWidth;

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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ДНЕВНИК',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: AppTheme.onBg,
                  )),
              Text('STUDENT PRO',
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
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
    return Container(
      height: 90,
      child: AnimatedBuilder(
          animation: Listenable.merge([_calendarScrollController, _pageController]),
          builder: (context, _) {
            double pageOffset = 0;
            if (_pageController.hasClients) {
              pageOffset = _pageController.page ?? 3.0;
            }

            return Stack(
              children: [
                // Selection highlight (Liquid drop effect)
                if (_calendarScrollController.hasClients)
                  _buildLiquidSelectionIndicator(pageOffset),

                ListView.builder(
                  controller: _calendarScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isSelected =
                        (pageOffset - index).abs() < 0.5;
                    final selectionFactor =
                        (1.0 - (pageOffset - index).abs()).clamp(0.0, 1.0);

                    final isToday = day.day == _today.day &&
                        day.month == _today.month &&
                        day.year == _today.year;

                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutQuart,
                        );
                      },
                      child: Container(
                        width: 62,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              weekdaysShort[day.weekday]!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.black
                                    : AppTheme.onSurface3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: isToday && !isSelected
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppTheme.primary, width: 1.5),
                                    )
                                  : null,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color: isSelected
                                      ? Colors.black
                                      : (isToday
                                          ? AppTheme.primary
                                          : AppTheme.onBg),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          }),
    );
  }

  Widget _buildLiquidSelectionIndicator(double pageOffset) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Each item is 62px, padding 16px.
    // Index center = 16 + index * 62 + 31
    final centerX = 16.0 + (pageOffset * 62.0) + 31.0;
    final scrollOffset = _calendarScrollController.offset;
    final indicatorX = centerX - scrollOffset;

    return Positioned(
      left: indicatorX - 25,
      top: 10,
      child: Container(
        width: 50,
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════ LESSONS
  Widget _buildLessonsSectionForDay(DateTime date) {
    final dateStr = '${date.day}.${date.month}.${date.year}';
    final dayOfWeek = date.weekday;
    final lessons = schedule[dayOfWeek] ?? [];

    return ListView(
      padding: const EdgeInsets.all(20),
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
                      margin: const EdgeInsets.only(top: 2), // Align circle with first line of text
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
                          const SizedBox(height: 4),
                          Text(lesson.time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onBg.withValues(alpha: 0.4),
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
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
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
                                  SelectionArea(
                                      child: Text(hw.task,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: AppTheme.onBg,
                                              height: 1.5))),
                                  if (hw.imageUrls != null &&
                                      hw.imageUrls!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 150,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: hw.imageUrls!.length,
                                        itemBuilder: (ctx, i) {
                                          final displayUrl = hw.imageUrls![i];
                                          final fullUrl = (hw.fullResolutionUrls != null && hw.fullResolutionUrls!.length > i)
                                              ? hw.fullResolutionUrls![i]
                                              : displayUrl;

                                          return GestureDetector(
                                            onTap: () => _openFullScreenImage(context, displayUrl, fullUrl),
                                            child: Container(
                                              width: 150,
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: displayUrl.startsWith('http')
                                                    ? Image.network(displayUrl, fit: BoxFit.cover)
                                                    : Image.file(File(displayUrl), fit: BoxFit.cover),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )),
                        const SizedBox(height: 40),
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

  void _openFullScreenImage(BuildContext context, String displayUrl, String fullUrl) {
    showGeneralPage(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: displayUrl,
                      child: displayUrl.startsWith('http')
                          ? Image.network(displayUrl, fit: BoxFit.contain)
                          : Image.file(File(displayUrl), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              // Download full quality button
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Скачать в полном качестве'),
                    onPressed: () async {
                      try {
                        // Show instant notification
                        _showInstantTopNotification(context, 'Начинаем загрузку...', Icons.cloud_download);
                        
                        Uint8List bytes;
                        if (fullUrl.startsWith('http')) {
                          final response = await http.get(Uri.parse(fullUrl));
                          bytes = response.bodyBytes;
                        } else {
                          bytes = await File(fullUrl).readAsBytes();
                        }
                        
                        await Gal.putImageBytes(bytes);
                        
                        if (context.mounted) {
                          _showInstantTopNotification(context, 'Фото сохранено в галерею!', Icons.check_circle_rounded);
                        }
                      } catch (e) {
                         if (context.mounted) {
                          _showInstantTopNotification(context, 'Ошибка при сохранении', Icons.error_outline_rounded);
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInstantTopNotification(BuildContext context, String message, IconData icon) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _InstantNotification(
        message: message,
        icon: icon,
        onFinished: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _InstantNotification extends StatefulWidget {
  final String message;
  final IconData icon;
  final VoidCallback onFinished;

  const _InstantNotification({
    required this.message,
    required this.icon,
    required this.onFinished,
  });

  @override
  State<_InstantNotification> createState() => _InstantNotificationState();
}

class _InstantNotificationState extends State<_InstantNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onFinished());
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
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2218).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Redirect helper for logout
class _RoleGateRedirect extends StatelessWidget {
  const _RoleGateRedirect();

  @override
  Widget build(BuildContext context) {
    // This assumes RoleGate is available in main.dart context
    // You might need to adjust based on where RoleGate is actually defined
    return const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
