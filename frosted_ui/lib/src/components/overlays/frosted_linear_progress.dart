import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';

/// A linear progress indicator following the M3 Expressive spec: a 4dp track
/// with a rounded active bar, a 4dp gap before the remaining track, and a
/// stop dot at the end.
///
/// Pass [value] (0–1) for determinate; leave it null for an indeterminate
/// sweep.
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
