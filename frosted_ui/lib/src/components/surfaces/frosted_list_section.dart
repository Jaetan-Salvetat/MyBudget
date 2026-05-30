import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import 'frosted_divider.dart';

/// A grouped list container: a rounded `surfaceContainer` block that stacks
/// [FrostedListTile]s with hairline dividers between them.
///
/// Opaque M3 content surface. Per the M3 Expressive list spec the block uses
/// medium-large corners and clips its children so tile state layers stay
/// inside the rounded shape.
class FrostedListSection extends StatelessWidget {
  const FrostedListSection({
    required this.children,
    this.showDividers = true,
    this.dividerIndent = 72,
    super.key,
  });

  final List<Widget> children;

  /// Draw a divider between consecutive tiles.
  final bool showDividers;

  /// Left inset of the dividers, aligned past a tile's leading avatar by
  /// default (16 padding + 40 avatar + 16 gap).
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0 && showDividers) {
        rows.add(FrostedDivider(indent: dividerIndent));
      }
      rows.add(children[i]);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(FrostedRadius.lg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FrostedRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp1 + 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: rows,
          ),
        ),
      ),
    );
  }
}
