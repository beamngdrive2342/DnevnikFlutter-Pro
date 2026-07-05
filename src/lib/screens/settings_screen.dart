import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

import '../data/schedule_data.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../utils/image_data.dart';
import '../widgets/network_photo.dart';
import '../widgets/top_notification.dart';

// ═══════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ═══════════════════════════════════════════════════════════

/// URLs для юридических документов на GitHub Pages.
/// Замени на свой URL после включения GitHub Pages.
const _kPrivacyPolicyUrl =
    'https://beamngdrive2342.github.io/DnevnikFlutter-Pro/legal/privacy-policy.html';
const _kTermsUrl =
    'https://beamngdrive2342.github.io/DnevnikFlutter-Pro/legal/terms-of-service.html';
const _kSupportEmail = 'mailto:geminigravitivibe@gmail.com?subject=Школьный Дневник — Поддержка';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;
  bool _isDeleting = false;
  final _imagePicker = ImagePicker();

  AppPalette get palette => AppTheme.colorsOf(context);

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  Future<void> _editProfile() async {
    final profile = ref.read(profileProvider);
    final controller = TextEditingController(text: profile.name);
    String tempAvatar = profile.avatar;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              final image = await _imagePicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 50,
                maxWidth: 400,
                maxHeight: 400,
              );
              if (image == null) return;
              final bytes = await loadImageBytes(image.path);
              if (bytes != null) {
                final encoded = encodeInlineImageData(bytes, mimeType: inferImageMimeType(image.path));
                setModalState(() => tempAvatar = encoded);
              }
            }

            return AlertDialog(
              backgroundColor: palette.bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Профиль', style: TextStyle(color: palette.onBg, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: tempAvatar.isNotEmpty
                          ? NetworkPhoto(url: tempAvatar, width: 80, height: 80, fit: BoxFit.cover)
                          : const Icon(LucideIcons.camera, color: AppTheme.primary, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: TextStyle(color: palette.onBg),
                    decoration: InputDecoration(
                      labelText: 'Ваше имя',
                      labelStyle: TextStyle(color: palette.onSurface2),
                      filled: true,
                      fillColor: palette.surface3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        borderSide: BorderSide(color: palette.cardBorder),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Отмена', style: TextStyle(color: palette.onSurface2)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await ref.read(profileProvider.notifier).updateProfile(controller.text.trim(), tempAvatar);
    }
    controller.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────

  Future<void> _confirmLogout() async {
    final confirmed = await _showConfirmDialog(
      title: 'Выйти из аккаунта?',
      message: 'Данные класса останутся в Firestore. При следующем входе введи код класса.',
      confirmLabel: 'Выйти',
      confirmColor: AppTheme.warning,
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/welcome');
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final auth = ref.read(authProvider);
    final isAdmin = auth.role == 'admin';

    final confirmed = await _showConfirmDialog(
      title: 'Удалить аккаунт?',
      message: isAdmin
          ? '⚠️ Это невозможно отменить!\n\nБудут удалены:\n• Весь класс\n• Все домашние задания\n• Все участники\n• Твой аккаунт'
          : 'Будут удалены:\n• Твоя запись участника класса\n• Твой анонимный аккаунт\n\nДанные класса останутся.',
      confirmLabel: 'Удалить навсегда',
      confirmColor: AppTheme.danger,
      destructive: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final success = await ref.read(authProvider.notifier).deleteAccount();

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      context.go('/welcome');
    } else {
      showTopNotification(context, 'Ошибка удаления. Проверь соединение и попробуй снова.');
    }
  }

  Future<void> _clearCache() async {
    final auth = ref.read(authProvider);
    final classId = auth.classId ?? '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_homework_$classId');
    await prefs.remove('offline_class_$classId');
    if (mounted) {
      showTopNotification(context, 'Кэш очищен');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        showTopNotification(context, 'Не удалось открыть ссылку');
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: palette.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (destructive) ...[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.alertTriangle,
                        color: AppTheme.danger,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.onBg,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      color: palette.onSurface2,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: TextButton.styleFrom(
                            foregroundColor: palette.onSurface2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Отмена', textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: confirmColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(confirmLabel, textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isAdmin = auth.role == 'admin';
    // ClassSchedule uses static fields
    final classNameStr = ClassSchedule.className;
    final schoolNameStr = ClassSchedule.schoolName;

    return Scaffold(
      backgroundColor: palette.bg,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            left: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: _isDeleting
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppTheme.danger,
                                strokeWidth: 2,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Удаляем данные...',
                                style: TextStyle(
                                  color: palette.onSurface2,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: [
                            // ── Профиль ────────────────────────────────
                            _buildSectionHeader('Профиль'),
                            _buildAccountCard(
                              isAdmin: isAdmin,
                              className: classNameStr,
                              schoolName: schoolNameStr,
                            ),

                            // ── Внешний вид ─────────────────────────────
                            _buildSectionHeader('Внешний вид'),
                            _buildTileCard([
                              _buildThemeTile(),
                            ]),

                            // ── Данные ──────────────────────────────────
                            _buildSectionHeader('Данные'),
                            _buildTileCard([
                              _buildTile(
                                icon: LucideIcons.trash,
                                label: 'Очистить кэш',
                                subtitle: 'Расписание и ДЗ загрузятся заново',
                                iconColor: palette.onSurface2,
                                onTap: _clearCache,
                              ),
                            ]),

                            // ── О приложении ────────────────────────────
                            _buildSectionHeader('О приложении'),
                            _buildTileCard([
                              _buildTile(
                                icon: LucideIcons.shield,
                                label: 'Политика конфиденциальности',
                                iconColor: AppTheme.primary,
                                onTap: () => _openUrl(_kPrivacyPolicyUrl),
                                trailing: const Icon(
                                  LucideIcons.externalLink,
                                  size: 14,
                                ),
                              ),
                              _buildDivider(),
                              _buildTile(
                                icon: LucideIcons.fileText,
                                label: 'Условия использования',
                                iconColor: AppTheme.primary,
                                onTap: () => _openUrl(_kTermsUrl),
                                trailing: const Icon(
                                  LucideIcons.externalLink,
                                  size: 14,
                                ),
                              ),
                              _buildDivider(),
                              _buildTile(
                                icon: LucideIcons.mail,
                                label: 'Написать в поддержку',
                                iconColor: AppTheme.primary,
                                onTap: () => _openUrl(_kSupportEmail),
                                trailing: const Icon(
                                  LucideIcons.externalLink,
                                  size: 14,
                                ),
                              ),
                              _buildDivider(),
                              _buildTile(
                                icon: LucideIcons.info,
                                label: 'Лицензии',
                                iconColor: palette.onSurface3,
                                onTap: () => showLicensePage(
                                  context: context,
                                  applicationName: 'Школьный Дневник',
                                  applicationVersion:
                                      _packageInfo?.version ?? '1.0.0',
                                ),
                              ),
                            ]),

                            // ── Аккаунт ──────────────────────────────────
                            _buildSectionHeader('Аккаунт'),
                            _buildTileCard([
                              _buildTile(
                                icon: LucideIcons.logOut,
                                label: 'Выйти из аккаунта',
                                iconColor: AppTheme.warning,
                                onTap: _confirmLogout,
                              ),
                              _buildDivider(),
                              _buildTile(
                                icon: LucideIcons.trash2,
                                label: 'Удалить аккаунт и данные',
                                iconColor: AppTheme.danger,
                                labelColor: AppTheme.danger,
                                onTap: _confirmDeleteAccount,
                              ),
                            ]),

                            // ── Версия ──────────────────────────────────
                            const SizedBox(height: 24),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Школьный Дневник',
                                    style: TextStyle(
                                      color: palette.onSurface3,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _packageInfo != null
                                        ? 'Версия ${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                                        : 'Версия 1.0.0',
                                    style: TextStyle(
                                      color: palette.onSurface3,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: palette.onBg),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Text(
            'Настройки',
            style: TextStyle(
              color: palette.onBg,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: palette.onSurface3,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAccountCard({
    required bool isAdmin,
    required String className,
    required String schoolName,
  }) {
    final auth = ref.read(authProvider);
    final profile = ref.watch(profileProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: profile.avatar.isNotEmpty
                ? NetworkPhoto(url: profile.avatar, width: 48, height: 48, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      isAdmin ? '👑' : '📚',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isNotEmpty ? profile.name : (isAdmin ? 'Администратор' : 'Ученик'),
                  style: TextStyle(
                    color: palette.onBg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$className · $schoolName',
                  style: TextStyle(
                    color: palette.onSurface2,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isAdmin && auth.classId != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: auth.classId ?? ''));
                      showTopNotification(context, 'ID класса скопирован');
                    },
                    child: Text(
                      'ID: ${auth.classId}',
                      style: TextStyle(
                        color: palette.onSurface3,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _editProfile,
            icon: Icon(LucideIcons.pencil, color: palette.onSurface2, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTileCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? iconColor,
    Color? labelColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final iColor = iconColor ?? palette.onSurface;
    final lColor = labelColor ?? palette.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: AppTheme.primary.withValues(alpha: 0.08),
        highlightColor: AppTheme.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: lColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: palette.onSurface3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                IconTheme(
                  data: IconThemeData(color: palette.onSurface3, size: 16),
                  child: trailing,
                ),
              ] else ...[
                Icon(LucideIcons.chevronRight,
                    color: palette.onSurface3, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.notifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: palette.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDark ? LucideIcons.moon : LucideIcons.sun,
                  color: palette.onSurface,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isDark ? 'Тёмная тема' : 'Светлая тема',
                  style: TextStyle(
                    color: palette.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ThemeController.toggle();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.primary
                        : palette.surface3,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    alignment: isDark
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 0,
      color: palette.cardBorder,
    );
  }
}
