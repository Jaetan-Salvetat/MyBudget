import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

/// Wraps what the model read from an older text than the one being typed.
///
/// The reading stays on screen — blanking it at every keystroke would make the
/// draft flicker — but it dims and stops answering : acting on it would record
/// or remember a category the current text never earned.
class QuickAddStale extends StatelessWidget {
  /// Faded enough to read as pending, legible enough to still be read.
  static const double opacity = 0.45;

  final bool stale;
  final Widget child;

  const QuickAddStale({required this.stale, required this.child, super.key});

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
