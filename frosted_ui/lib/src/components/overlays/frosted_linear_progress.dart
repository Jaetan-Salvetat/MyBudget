import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_easing.dart';
import '../../foundations/frosted_progress_tokens.dart';
import '_linear_progress_painter.dart';
import '_progress_animation.dart';

class FrostedLinearProgress extends StatefulWidget {
  const FrostedLinearProgress({
    this.value,
    this.thickness = FrostedProgressTokens.linearThickness,
    this.color,
    this.trackColor,
    super.key,
  });

  final double? value;
  final double thickness;
  final Color? color;
  final Color? trackColor;

  @override
  State<FrostedLinearProgress> createState() => _FrostedLinearProgressState();
}

class _FrostedLinearProgressState extends State<FrostedLinearProgress>
    with
        TickerProviderStateMixin,
        ProgressAnimationStateMixin<FrostedLinearProgress> {
  static const int _cycleMs = 1750;
  static const _Keyframe _firstHead = _Keyframe(delay: 0, duration: 1000);
  static const _Keyframe _firstTail = _Keyframe(delay: 250, duration: 1000);
  static const _Keyframe _secondHead = _Keyframe(delay: 650, duration: 850);
  static const _Keyframe _secondTail = _Keyframe(delay: 900, duration: 850);

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
  void didUpdateWidget(FrostedLinearProgress oldWidget) {
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

  List<LinearProgressSegment> get _segments {
    if (widget.value != null) {
      return <LinearProgressSegment>[
        LinearProgressSegment(0, animatedProgress),
      ];
    }
    final double time = _indeterminate.value * _cycleMs;
    return <LinearProgressSegment>[
      LinearProgressSegment(_firstTail.at(time), _firstHead.at(time)),
      LinearProgressSegment(_secondTail.at(time), _secondHead.at(time)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Semantics(
      value: widget.value == null
          ? null
          : '${(widget.value!.clamp(0.0, 1.0) * 100).round()}%',
      child: SizedBox(
        width: double.infinity,
        height: widget.thickness,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            progressController,
            _indeterminate,
          ]),
          builder: (BuildContext context, Widget? child) => RepaintBoundary(
            child: CustomPaint(
              painter: LinearProgressPainter(
                segments: _segments,
                color: widget.color ?? cs.primary,
                trackColor: widget.trackColor ?? cs.secondaryContainer,
                showStopIndicator: widget.value != null,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _Keyframe {
  const _Keyframe({required this.delay, required this.duration});

  final int delay;
  final int duration;

  double at(double timeMs) {
    if (timeMs <= delay) return 0;
    if (timeMs >= delay + duration) return 1;
    return FrostedEasing.emphasizedAccelerate.transform(
      (timeMs - delay) / duration,
    );
  }
}
