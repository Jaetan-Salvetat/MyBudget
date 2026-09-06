import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

class QuickAddStale extends StatelessWidget {
  const QuickAddStale({required this.stale, required this.child, super.key});
  static const double opacity = 0.45;

  final bool stale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.frostedTokens.motion.snappy;

    return IgnorePointer(
      ignoring: stale,
      child: AnimatedOpacity(
        duration: motion.duration,
        curve: motion.curve,
        opacity: stale ? opacity : 1,
        child: child,
      ),
    );
  }
}
