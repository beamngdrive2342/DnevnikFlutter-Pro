import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/firestore_service.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/diary_screen.dart';
import '../screens/add_homework_modal.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/ai_chat_bottom_sheet.dart';
import '../widgets/premium_glow_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ═══════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  final String role;
  final String classId;
  const MainScreen({super.key, required this.role, required this.classId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isAIFabExpanded = false;
  final GlobalKey<DiaryScreenState> _diaryKey = GlobalKey<DiaryScreenState>();
  final GlobalKey<AdminPanelScreenState> _adminKey =
      GlobalKey<AdminPanelScreenState>();
  late final PageController _rootPageController;

  bool get isAdmin => widget.role == 'admin';
  AppPalette get palette => AppTheme.colorsOf(context);

  late final Widget _diaryScreen;
  Widget? _adminScreen;

  @override
  void initState() {
    super.initState();
    FirestoreService.setClassId(widget.classId);
    _diaryScreen = DiaryScreen(key: _diaryKey);
    _rootPageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _rootPageController.dispose();
    super.dispose();
  }

  Widget _buildAdminScreen() {
    return AdminPanelScreen(
      key: _adminKey,
      onHomeworkChanged: () {
        _diaryKey.currentState?.reloadHomework(forceRefresh: true);
      },
    );
  }

  Widget _buildRootPage(int index) {
    if (index == 0) {
      return _diaryScreen;
    }
    return _adminScreen ??= _buildAdminScreen();
  }

  void _handleNavigationTap(int index) {
    if (_currentIndex == index) {
      return;
    }

    if (isAdmin && index == 1 && _adminScreen == null) {
      setState(() {
        _adminScreen = _buildAdminScreen();
        _currentIndex = index;
      });
    } else {
      setState(() {
        _currentIndex = index;
      });
    }

    _rootPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _showAddHomeworkModal() {
    showAddHomeworkModal(
      parentContext: context,
      onHomeworkSaved: () async {
        await _diaryKey.currentState?.reloadHomework(forceRefresh: true);
        await _adminKey.currentState?.reload(forceRefresh: true);
      },
    );
  }

  void _showAIChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIChatBottomSheet(),
    );
  }

  Widget? _buildGlassyNavBar() {
    if (!isAdmin) return null;

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
          icon: Icon(LucideIcons.home), label: 'Главная'),
      const BottomNavigationBarItem(
          icon: Icon(LucideIcons.shieldAlert), label: 'Админ'),
    ];

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.surface.withValues(alpha: 0.96),
              palette.surface2.withValues(alpha: 0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: (ThemeController.isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            currentIndex: _currentIndex,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: palette.onSurface2,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            onTap: _handleNavigationTap,
            items: items,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: palette.bg,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.bg.withValues(alpha: 0.06),
                      palette.surface.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RepaintBoundary(
              child: PageView.builder(
                controller: _rootPageController,
                physics: const NeverScrollableScrollPhysics(),
                allowImplicitScrolling: true,
                onPageChanged: (index) {
                  if (_currentIndex == index) {
                    return;
                  }
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: isAdmin ? 2 : 1,
                itemBuilder: (context, index) {
                  return _buildRootPage(index);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassyNavBar(),
      floatingActionButton: _currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: isAdmin
                  ? SizedBox(
                      width: 80,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 240),
                            curve: _isAIFabExpanded ? Curves.easeOutBack : Curves.easeOutCubic,
                            bottom: _isAIFabExpanded ? 80.0 : 0.0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _isAIFabExpanded ? 1.0 : 0.0,
                              child: AnimatedBuilder(
                                animation: aiChatController,
                                builder: (context, _) {
                                  return IgnorePointer(
                                    ignoring: !_isAIFabExpanded,
                                    child: PremiumGlowButton(
                                      size: 48,
                                      onPressed: () {
                                        setState(() {
                                          _isAIFabExpanded = false;
                                        });
                                        _showAIChatModal();
                                      },
                                      isLoading: aiChatController.isBusy,
                                      child: const Icon(
                                        LucideIcons.sparkles,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: PremiumGlowButton(
                              onPressed: () {
                                if (_isAIFabExpanded) {
                                  setState(() {
                                    _isAIFabExpanded = false;
                                  });
                                } else {
                                  _showAddHomeworkModal();
                                }
                              },
                              onLongPress: () {
                                setState(() {
                                  _isAIFabExpanded = !_isAIFabExpanded;
                                });
                                HapticFeedback.mediumImpact();
                              },
                              child: AnimatedRotation(
                                duration: const Duration(milliseconds: 200),
                                turns: _isAIFabExpanded ? 0.125 : 0,
                                child: const Icon(
                                  LucideIcons.plus,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : AnimatedBuilder(
                      animation: aiChatController,
                      builder: (context, _) {
                        return PremiumGlowButton(
                          onPressed: _showAIChatModal,
                          isLoading: aiChatController.isBusy,
                          child: const Icon(
                            LucideIcons.sparkles,
                            size: 32,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
            )
          : null,
    );
  }
}
