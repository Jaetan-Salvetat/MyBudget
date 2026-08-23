import 'package:material_ui/material_ui.dart';

/// A 1px hairline separator on `outlineVariant`.
///
/// Use [indent] / [endIndent] to inset the line — e.g. to align it past a
/// list tile's leading element.
class FrostedDivider extends StatelessWidget {
  const FrostedDivider({
    this.axis = Axis.horizontal,
    this.indent = 0,
    this.endIndent = 0,
    super.key,
  });

  final Axis axis;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.outlineVariant;

    if (axis == Axis.horizontal) {
      return Padding(
        padding: EdgeInsets.only(left: indent, right: endIndent),
        child: SizedBox(height: 1, child: ColoredBox(color: color)),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: indent, bottom: endIndent),
      child: SizedBox(width: 1, child: ColoredBox(color: color)),
    );
  }
}
