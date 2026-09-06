import 'package:material_ui/material_ui.dart';

class JournalLanding extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 340);

  static const double travel = 24;

  static const Curve opening = Curves.easeOutCubic;

  static const Curve rising = Cubic(0.2, 1.26, 0.36, 1);

  static const double fadeSpan = 0.6;

  final Widget child;

  const JournalLanding({required this.child, super.key});

  @override
  State<JournalLanding> createState() => _JournalLandingState();
}

class _JournalLandingState extends State<JournalLanding>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: JournalLanding.duration,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;

    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = _controller.value;
        final risen = JournalLanding.rising.transform(progress);

        return Align(
          alignment: Alignment.topCenter,
          heightFactor: JournalLanding.opening.transform(progress),
          child: Opacity(
            opacity: (progress / JournalLanding.fadeSpan).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, JournalLanding.travel * (1 - risen)),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
