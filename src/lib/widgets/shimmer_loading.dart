import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({
    super.key,
    required this.child,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final palette = AppTheme.colorsOf(context);
    _colorAnimation = ColorTween(
      begin: palette.surface2.withValues(alpha: 0.4),
      end: palette.surface3.withValues(alpha: 0.7),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                _colorAnimation.value ?? Colors.transparent,
                _colorAnimation.value?.withValues(alpha: 0.5) ?? Colors.transparent,
                _colorAnimation.value ?? Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBlock({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = AppTheme.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.surface, // base color, will be masked
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonLessonCard extends StatelessWidget {
  const SkeletonLessonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.cardBg, // using real card bg to make it look right
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBlock(width: 32, height: 32, borderRadius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBlock(width: 140, height: 20),
                  SizedBox(height: 8),
                  SkeletonBlock(width: 80, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
