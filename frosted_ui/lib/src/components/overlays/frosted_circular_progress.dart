import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_easing.dart';
import '../../foundations/frosted_progress_tokens.dart';
import '_circular_progress_painter.dart';
import '_progress_animation.dart';

class FrostedCircularProgress extends StatefulWidget {
  const FrostedCircularProgress({
    this.value,
    this.size = FrostedProgressTokens.circularSize,
    this.thickness = FrostedProgressTokens.circularThickness,
    this.color,
    this.trackColor,
    super.key,
  });

  final double? value;
  final double size;
  final double thickness;
  final Color? color;
  final Color? trackColor;

  @override
  State<FrostedCircularProgress> createState() =>
      _FrostedCircularProgressState();
}

class _FrostedCircularProgressState extends State<FrostedCircularProgress>
    with
        TickerProviderStateMixin,
        ProgressAnimationStateMixin<FrostedCircularProgress> {
  static const int _cycleMs = 6000;
  static const int _stepMs = 300;
  static const int _holdMs = 1500;
  static const int _steps = 4;
  static const double _globalRotationDegrees = 1080;
  static const double _quarterDegrees = 90;
  static const double _degreesToRadians = math.pi / 180;
  static const Curve _rotationStepCurve = Curves.easeInOut;

  late final AnimationController _indeterminate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _cycleMs),
  );

  @override
  double? get targetProgress => widget.value;

  @override
  void initState() {
    super.initState();
    _syncIndeterminate();
  }

  @override
  void didUpdateWidget(FrostedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    animateToTargetProgress(oldWidget.value);
    _syncIndeterminate();
  }

  @override
  void dispose() {
    _indeterminate.dispose();
    progressController.dispose();
    super.dispose();
  }

  void _syncIndeterminate() {
    if (widget.value == null && !_indeterminate.isAnimating) {
      _indeterminate.repeat();
    } else if (widget.value != null && _indeterminate.isAnimating) {
      _indeterminate.stop();
      _indeterminate.value = 0;
    }
  }

  double get _sweep {
    if (widget.value != null) return animatedProgress;

    const double min = FrostedProgressTokens.circularIndeterminateMinSweep;
    const double max = FrostedProgressTokens.circularIndeterminateMaxSweep;
    final double time = _indeterminate.value * _cycleMs;
    const double half = _cycleMs / 2;
    return time <= half
        ? min + (max - min) * (time / half)
        : max -
              (max - min) *
                  FrostedEasing.standard.transform((time - half) / half);
  }

  double get _rotation {
    if (widget.value != null) return 0;

    final double global = _indeterminate.value * _globalRotationDegrees;
    final double additional = _additionalRotation(
      _indeterminate.value * _cycleMs,
    );
    return (global + additional) * _degreesToRadians;
  }

  double _additionalRotation(double timeMs) {
    for (int step = 0; step < _steps; step++) {
      final double start = _holdMs * step.toDouble();
      final double from = _quarterDegrees * step;
      if (timeMs <= start) return from;
      if (timeMs < start + _stepMs) {
        return from +
            _quarterDegrees *
                _rotationStepCurve.transform((timeMs - start) / _stepMs);
      }
    }
    return _quarterDegrees * _steps;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Semantics(
      value: widget.value == null
          ? null
          : '${(widget.value!.clamp(0.0, 1.0) * 100).round()}%',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            progressController,
            _indeterminate,
          ]),
          builder: (BuildContext context, Widget? child) => RepaintBoundary(
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: _sweep,
                thickness: widget.thickness,
                rotation: _rotation,
                color: widget.color ?? cs.primary,
                trackColor: widget.trackColor ?? cs.secondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
