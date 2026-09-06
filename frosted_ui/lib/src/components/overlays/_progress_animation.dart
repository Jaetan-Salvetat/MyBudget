import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_progress_tokens.dart';

mixin ProgressAnimationStateMixin<T extends StatefulWidget>
    on State<T>, TickerProvider {
  late final AnimationController progressController = AnimationController(
    vsync: this,
    value: targetProgress ?? 0,
  );

  double? get targetProgress;

  double get animatedProgress => progressController.value;

  void animateToTargetProgress(double? previous) {
    final double? next = targetProgress;
    if (next == null || next == previous) return;

    progressController.animateWith(
      SpringSimulation(
        FrostedProgressTokens.progressSpring,
        previous == null ? 0 : progressController.value,
        next.clamp(0.0, 1.0),
        progressController.velocity,
        tolerance: FrostedProgressTokens.progressTolerance,
      ),
    );
  }
}
