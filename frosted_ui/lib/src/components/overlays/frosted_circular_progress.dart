import 'package:material_ui/material_ui.dart';

/// A circular progress indicator on the primary color.
///
/// Pass [value] (0–1) for determinate; leave it null for an indeterminate
/// spinner. [size] sets the diameter.
class FrostedCircularProgress extends StatelessWidget {
  const FrostedCircularProgress({this.value, this.size = 40, super.key});

  final double? value;
  final double size;

  static const double _stroke = 4;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: _stroke,
        strokeCap: StrokeCap.round,
        color: cs.primary,
        backgroundColor: cs.surfaceContainerHighest,
      ),
    );
  }
}
