import 'package:flutter/material.dart';

import '../theme/theme_controller.dart';

class ThemeSwitchButton extends StatelessWidget {
  final double size;
  final Color switchTrackColor;
  final Color switchActiveColor;
  final Color sunIconColor;
  final Color moonIconColor;

  const ThemeSwitchButton({
    super.key,
    this.size = 30,
    this.switchTrackColor = const Color(0xFF424242),
    this.switchActiveColor = const Color(0xFFDBDBDB),
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

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.notifier,
      builder: (context, mode, child) {
        final isLightMode = mode == ThemeMode.light;

        return Semantics(
          button: true,
          toggled: isLightMode,
          label: 'Переключить тему',
          child: GestureDetector(
            onTap: () {
              ThemeController.toggle();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: switchWidth,
              height: switchHeight,
              decoration: BoxDecoration(
                color: isLightMode ? switchActiveColor : switchTrackColor,
                borderRadius: BorderRadius.circular(switchHeight / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isLightMode ? 0.06 : 0.10),
                    blurRadius: isLightMode ? 3 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    top: inset,
                    left: isLightMode ? switchWidth - knobSize - inset : inset,
                    child: Container(
                      width: knobSize,
                      height: knobSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        isLightMode
                            ? Icons.wb_sunny_rounded
                            : Icons.nightlight_round,
                        color: isLightMode ? sunIconColor : moonIconColor,
                        size: knobIconSize,
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
}
