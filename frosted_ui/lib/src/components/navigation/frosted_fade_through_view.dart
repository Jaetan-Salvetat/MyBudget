import 'package:material_ui/material_ui.dart';

import '../../primitives/frosted_glass_suspension.dart';

/// Share of the swap the outgoing view spends fading out, from the Material
/// motion spec: it clears in the first 100ms, the incoming one fades in over
/// the remaining 200ms.
const double _kFadeOutFraction = 1 / 3;

/// Swaps between sibling top-level views with the Material fade-through, the
/// transition Android plays when a bottom bar moves between unrelated
/// destinations.
///
/// Views that are not on screen stay mounted, so each destination keeps its
/// scroll offset and state across a swap — the behaviour a native bottom bar
/// gives for free and a plain switcher throws away.
///
/// The two fades run one after the other rather than crossing: a tab change
/// reads as a swap, never as two screens briefly stacked on one another.
class FrostedFadeThroughView extends StatefulWidget {
  const FrostedFadeThroughView({
    required this.index,
    required this.children,
    super.key,
  });

  /// How long a swap takes, from the Material motion spec. A view being
  /// swapped in is off screen until the fade lands, so anything that needs it
  /// there — taking focus, raising the keyboard — has to wait this long.
  static const Duration transitionDuration = Duration(milliseconds: 300);

  /// Index of the view to show, into [children].
  final int index;

  /// The destinations, all kept alive whatever is on screen.
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

    // A change landing mid-flight must fade out whatever the last frame
    // actually painted, not the index the widget carried before.
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
