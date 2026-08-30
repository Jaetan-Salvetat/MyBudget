import 'package:material_ui/material_ui.dart';

import '../../primitives/frosted_glass_suspension.dart';

const double _kFadeOutFraction = 1 / 3;

class FrostedFadeThroughView extends StatefulWidget {
  const FrostedFadeThroughView({
    required this.index,
    required this.children,
    super.key,
  });

  static const Duration transitionDuration = Duration(milliseconds: 300);

  final int index;

  final List<Widget> children;

  @override
  State<FrostedFadeThroughView> createState() => _FrostedFadeThroughViewState();
}

class _FrostedFadeThroughViewState extends State<FrostedFadeThroughView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FrostedFadeThroughView.transitionDuration,
    value: 1,
  );

  late final Animation<double> _opacity =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1, end: 0),
          weight: _kFadeOutFraction,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 1),
          weight: 1 - _kFadeOutFraction,
        ),
      ]).animate(_controller);

  late int _outgoingIndex = widget.index;

  @override
  void didUpdateWidget(FrostedFadeThroughView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;

    _outgoingIndex = _visibleIndexFor(oldWidget.index);

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _visibleIndexFor(int incoming) =>
      _controller.value < _kFadeOutFraction ? _outgoingIndex : incoming;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) => FadeTransition(
        opacity: _opacity,
        child: FrostedGlassSuspension(
          suspended: _controller.isAnimating,
          child: IndexedStack(
            index: _visibleIndexFor(widget.index),
            sizing: StackFit.expand,
            children: widget.children,
          ),
        ),
      ),
    );
  }
}
