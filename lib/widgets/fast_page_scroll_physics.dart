import 'package:flutter/material.dart';

class FastPageScrollPhysics extends PageScrollPhysics {
  const FastPageScrollPhysics({super.parent});

  @override
  FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get dragStartDistanceMotionThreshold => 20.0;

  @override
  double get minFlingDistance => 34.0;

  @override
  double get minFlingVelocity => 1150.0;

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.46,
        stiffness: 760.0,
        damping: 52.0,
      );
}
