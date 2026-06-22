import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool animateTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppTheme.radiusLg,
    this.animateTap = true,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.animateTap) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.animateTap) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null && widget.animateTap) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: palette.cardBg.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.06), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: widget.animateTap
            ? ScaleTransition(scale: _scaleAnimation, child: content)
            : content,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: content,
    );
  }
}
