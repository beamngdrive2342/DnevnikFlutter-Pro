import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';
import '../theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'scale_tap_wrapper.dart';

class ThemeSwitchButton extends StatelessWidget {
  final double size;
  final Color sunIconColor;
  final Color moonIconColor;

  const ThemeSwitchButton({
    super.key,
    this.size = 30,
    this.sunIconColor = const Color(0xFFFF9100),
    this.moonIconColor = const Color(0xFF6B6B6B),
  });

  @override
  Widget build(BuildContext context) {
    final switchWidth = size * 1.8;
    final switchHeight = size;
    final knobSize = switchHeight * 0.8;
    final knobIconSize = knobSize * 0.6;
    final inset = (switchHeight - knobSize) / 2;
    final travel = switchWidth - knobSize - (inset * 2);
    final palette = AppTheme.colorsOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.notifier,
      builder: (context, mode, _) {
        final isLightMode = mode == ThemeMode.light;

        return Semantics(
          button: true,
          toggled: isLightMode,
          label: 'Переключить тему',
          child: RepaintBoundary(
            child: ScaleTapWrapper(
              onTap: ThemeController.toggle,
              child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: isLightMode ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Container(
                      width: switchWidth,
                      height: switchHeight,
                      decoration: BoxDecoration(
                        color: palette.surface3,
                        borderRadius: BorderRadius.circular(switchHeight / 2),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(inset),
                        child: Stack(
                          children: [
                            Transform.translate(
                              offset: Offset(travel * value, 0),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: knobSize,
                                  height: knobSize,
                                  child: Icon(
                                    isLightMode
                                        ? LucideIcons.sun
                                        : LucideIcons.moon,
                                    color: isLightMode
                                        ? sunIconColor
                                        : moonIconColor,
                                    size: knobIconSize,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ),
        );
      },
    );
  }
}
