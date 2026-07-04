import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class PremiumGlowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final bool isLoading;
  final double size;

  const PremiumGlowButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    required this.child,
    this.isLoading = false,
    this.size = 64.0,
  });

  @override
  State<PremiumGlowButton> createState() => _PremiumGlowButtonState();
}

class _PremiumGlowButtonState extends State<PremiumGlowButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _syncLoadingAnimation();
  }

  @override
  void didUpdateWidget(covariant PremiumGlowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      _syncLoadingAnimation();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  void _syncLoadingAnimation() {
    if (widget.isLoading) {
      _loadingController.repeat();
      return;
    }
    _loadingController
      ..stop()
      ..value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    const Color glowColor = AppTheme.primary;

    return GestureDetector(
      onTapDown: (_) async {
        _setPressed(true);
        await HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress != null ? () {
        _setPressed(false);
        widget.onLongPress?.call();
      } : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _isPressed ? const Offset(0, 0.03) : Offset.zero,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isLoading) ...[
                RotationTransition(
                  turns: _loadingController,
                  child: SizedBox(
                    width: size * 1.38,
                    height: size * 1.38,
                    child: CustomPaint(
                      painter: _GlowButtonLoadingRingPainter(
                        primaryColor: glowColor.withValues(alpha: 0.95),
                        secondaryColor: Colors.white.withValues(alpha: 0.72),
                        strokeWidth: 2.6,
                        primarySweep: math.pi * 0.9,
                        secondarySweep: math.pi * 0.28,
                      ),
                    ),
                  ),
                ),
                RotationTransition(
                  turns: Tween<double>(begin: 0, end: -1).animate(
                    CurvedAnimation(
                      parent: _loadingController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: SizedBox(
                    width: size * 1.18,
                    height: size * 1.18,
                    child: CustomPaint(
                      painter: _GlowButtonLoadingRingPainter(
                        primaryColor: Colors.white.withValues(alpha: 0.46),
                        secondaryColor: glowColor.withValues(alpha: 0.62),
                        strokeWidth: 1.6,
                        primarySweep: math.pi * 0.42,
                        secondarySweep: math.pi * 0.18,
                      ),
                    ),
                  ),
                ),
              ],
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: size * 1.2,
                height: size * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(
                        alpha: _isPressed
                            ? 0.16
                            : widget.isLoading
                                ? 0.34
                                : 0.24,
                      ),
                      blurRadius: _isPressed
                          ? 10
                          : widget.isLoading
                              ? 24
                              : 18,
                      spreadRadius: _isPressed
                          ? 0.5
                          : widget.isLoading
                              ? 3
                              : 2,
                    ),
                  ],
                ),
              ),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: 0.85),
                      glowColor.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: size - 3,
                height: size - 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isPressed
                      ? const Color(0xFF111111)
                      : const Color(0xFF000000),
                ),
                child: Center(child: widget.child),
              ),
              Positioned(
                top: 6,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: _isPressed
                      ? 0.08
                      : widget.isLoading
                          ? 0.45
                          : 1,
                  child: Container(
                    width: size * 0.6,
                    height: size * 0.3,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(30)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowButtonLoadingRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;
  final double primarySweep;
  final double secondarySweep;

  const _GlowButtonLoadingRingPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
    required this.primarySweep,
    required this.secondarySweep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final primaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: <Color>[
          primaryColor.withValues(alpha: 0.08),
          primaryColor,
          primaryColor.withValues(alpha: 0.2),
        ],
        stops: const <double>[0, 0.55, 1],
      ).createShader(rect);

    final secondaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.82
      ..strokeCap = StrokeCap.round
      ..color = secondaryColor;

    canvas.drawArc(rect, -math.pi / 2, primarySweep, false, primaryPaint);
    canvas.drawArc(
      rect,
      math.pi * 0.72,
      secondarySweep,
      false,
      secondaryPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowButtonLoadingRingPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.primarySweep != primarySweep ||
        oldDelegate.secondarySweep != secondarySweep;
  }
}
