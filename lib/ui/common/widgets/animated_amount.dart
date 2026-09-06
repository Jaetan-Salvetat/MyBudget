import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class AnimatedAmount extends StatefulWidget {
  const AnimatedAmount({
    required this.amount,
    required this.builder,
    super.key,
  });
  static const Duration duration = Duration(milliseconds: 650);
  static const double pulseScale = 1.045;

  final double amount;
  final Widget Function(BuildContext context, double value) builder;

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AnimatedAmount.duration,
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late double _from = widget.amount;
  late double _to = widget.amount;

  @override
  void didUpdateWidget(AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount == oldWidget.amount) return;

    _from = _displayedValue;
    _to = widget.amount;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  double get _displayedValue => _from + (_to - _from) * _curve.value;

  double get _pulse =>
      1 +
      (AnimatedAmount.pulseScale - 1) * math.sin(math.pi * _controller.value);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Transform.scale(
        scale: _pulse,
        child: widget.builder(context, _displayedValue),
      ),
    );
  }
}
