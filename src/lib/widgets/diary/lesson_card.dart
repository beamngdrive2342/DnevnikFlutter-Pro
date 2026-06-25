import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../data/schedule_data.dart';
import '../premium_card.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../network_photo.dart';

class LessonCard extends StatefulWidget {
  final Lesson lesson;
  final List<HomeworkItem> customHw;
  final Function(String) onImageTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.customHw,
    required this.onImageTap,
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

    return RepaintBoundary(
      child: PremiumCard(
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
                        const Row(
                          children: [
                            Icon(LucideIcons.clipboardList,
                                size: 14, color: AppTheme.primaryDim),
                            SizedBox(width: 6),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                if (ch.textbookNumbers.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      _showTextbookAnswers(context, ch.textbookNumbers, ch.subject);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryDim.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                        border: Border.all(color: AppTheme.primaryDim.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.bookOpen, size: 16, color: AppTheme.primaryDim),
                                          const SizedBox(width: 6),
                                          Text('Открыть ответы (${ch.textbookNumbers.join(", ")})', 
                                            style: const TextStyle(
                                              color: AppTheme.primaryDim,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            )
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if ((ch.imageUrls != null && ch.imageUrls!.isNotEmpty) || 
                                    (ch.imageUrl != null && ch.imageUrl!.isNotEmpty)) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 80,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      children: ((ch.imageUrls != null && ch.imageUrls!.isNotEmpty)
                                              ? List.generate(ch.imageUrls!.length, (i) {
                                                  return {
                                                    'display': (ch.fullResolutionUrls != null && ch.fullResolutionUrls!.length > i)
                                                        ? ch.fullResolutionUrls![i]
                                                        : ch.imageUrls![i],
                                                    'full': (ch.fullResolutionUrls != null && ch.fullResolutionUrls!.length > i)
                                                        ? ch.fullResolutionUrls![i]
                                                        : ch.imageUrls![i]
                                                  };
                                                })
                                              : [
                                                  {'display': ch.imageUrl!, 'full': ch.imageUrl!}
                                                ])
                                          .map((imageMap) {
                                        final displayUrl = imageMap['display']!;
                                        final fullUrl = imageMap['full']!;
                                        return GestureDetector(
                                          onTap: () => widget.onImageTap(fullUrl),
                                          child: Hero(
                                            tag: fullUrl,
                                            child: Container(
                                              width: 80,
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                                border: Border.all(color: AppTheme.primaryDim.withValues(alpha: 0.2)),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                                child: NetworkPhoto(
                                                  url: displayUrl,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ]
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

  static const _assetsBaseUrl =
      'https://raw.githubusercontent.com/beamngdrive2342/dnevnik-assets/main';

  void _showTextbookAnswers(BuildContext context, List<String> numbers, String subject) {
    // Determine folder based on subject
    final String folder;
    if (subject == 'Алгебра') {
      folder = 'Algebra';
    } else {
      folder = 'Geometry';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final palette = AppTheme.colorsOf(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: palette.onSurface3.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Ответы из учебника', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: palette.onBg)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: numbers.map((hwNum) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Номер $hwNum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: palette.onBg)),
                          const SizedBox(height: 8),
                          _NumberImages(
                            numStr: hwNum,
                            folder: folder,
                            baseUrl: _assetsBaseUrl,
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NumberImages extends StatefulWidget {
  final String numStr;
  final String folder;
  final String baseUrl;

  const _NumberImages({
    required this.numStr,
    required this.folder,
    required this.baseUrl,
  });

  @override
  State<_NumberImages> createState() => _NumberImagesState();
}

class _NumberImagesState extends State<_NumberImages> {
  int _imageCount = 1;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _checkImages();
  }

  Future<void> _checkImages() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'image_count_${widget.folder}_${widget.numStr}';
    
    // Быстрая загрузка из кэша, чтобы избежать долгих сетевых запросов при каждом открытии
    final cachedCount = prefs.getInt(cacheKey);
    if (cachedCount != null && cachedCount > 0) {
      if (mounted) {
        setState(() {
          _imageCount = cachedCount;
          _isLoadingCount = false;
        });
      }
      return;
    }

    int count = 1;

    try {
      // Check up to 5 image parts
      for (int i = 2; i <= 5; i++) {
        final url = '${widget.baseUrl}/${widget.folder}/${widget.numStr}_$i.png';
        final res = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          count = i;
        } else {
          break;
        }
      }
      await prefs.setInt(cacheKey, count);
    } catch (e) {
      // Offline fallback
      count = prefs.getInt(cacheKey) ?? 1;
    }
    
    if (mounted) {
      setState(() {
        _imageCount = count;
        _isLoadingCount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCount) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.colorsOf(context).surface3,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryDim,
            strokeWidth: 2,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(_imageCount, (index) {
        final imgNum = index + 1;
        final imageUrl = '${widget.baseUrl}/${widget.folder}/${widget.numStr}_$imgNum.png';
        return Padding(
          padding: EdgeInsets.only(bottom: index < _imageCount - 1 ? 16.0 : 0.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.colorsOf(context).surface3,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryDim,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.colorsOf(context).surface3,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Center(
                  child: Text('Ответ для номера ${widget.numStr} (часть $imgNum) не найден',
                    style: TextStyle(color: AppTheme.colorsOf(context).onSurface3)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
