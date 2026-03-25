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
    final travel = switchWidth - knobSize - (inset * 2);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.notifier,
      builder: (context, mode, _) {
        final isLightMode = mode == ThemeMode.light;

        return Semantics(
          button: true,
          toggled: isLightMode,
          label: 'Переключить тему',
          child: RepaintBoundary(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const StadiumBorder(),
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
                        color: Color.lerp(
                          switchTrackColor,
                          switchActiveColor,
                          value,
                        ),
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
                                        ? Icons.wb_sunny_rounded
                                        : Icons.nightlight_round,
                                    color:
                                        isLightMode ? sunIconColor : moonIconColor,
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
          ),
        );
      },
    );
  }
}
