import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrimaryScaleButton extends StatefulWidget {
  final String title;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isSecondary;

  const PrimaryScaleButton({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.isSecondary = false,
  });

  @override
  State<PrimaryScaleButton> createState() => _PrimaryScaleButtonState();
}

class _PrimaryScaleButtonState extends State<PrimaryScaleButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: widget.isSecondary
                ? palette.cardBg.withValues(alpha: 0.6)
                : AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: widget.isSecondary
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 1)
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.1), width: 1),
            boxShadow: widget.isSecondary
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: widget.isSecondary ? palette.onBg : Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: AppTheme.fontSans,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.isSecondary ? palette.onBg : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
