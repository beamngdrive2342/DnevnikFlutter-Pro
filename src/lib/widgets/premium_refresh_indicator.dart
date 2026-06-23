import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumRefreshControl extends StatelessWidget {
  final RefreshIndicatorMode refreshState;
  final double pulledExtent;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  const PremiumRefreshControl({
    super.key,
    required this.refreshState,
    required this.pulledExtent,
    required this.refreshTriggerPullDistance,
    required this.refreshIndicatorExtent,
  });

  @override
  Widget build(BuildContext context) {
    final double percentageComplete = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

    Widget indicator;

    if (refreshState == RefreshIndicatorMode.refresh || refreshState == RefreshIndicatorMode.armed) {
      indicator = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppTheme.primary,
        ),
      );
    } else if (refreshState == RefreshIndicatorMode.done) {
      indicator = const Icon(Icons.check_rounded, color: AppTheme.primary, size: 20);
    } else {
      // Dragging
      indicator = Transform.scale(
        scale: 0.5 + (percentageComplete * 0.5),
        child: Opacity(
          opacity: percentageComplete,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 2.5),
            ),
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      height: refreshIndicatorExtent,
      child: indicator,
    );
  }
}
