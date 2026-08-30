import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';

class FrostedLinearProgress extends StatelessWidget {
  const FrostedLinearProgress({this.value, super.key});

  final double? value;

  static const double _thickness = 4;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: _thickness,
      child: LinearProgressIndicator(
        value: value,
        minHeight: _thickness,
        color: cs.primary,
        backgroundColor: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FrostedRadius.full),
      ),
    );
  }
}
