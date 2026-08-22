import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';

/// A single row in a [FrostedMenuPanel].
///
/// Internal to the library — shared by the dropdown and the split button.
class FrostedMenuEntry {
  const FrostedMenuEntry({
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;
  final bool destructive;
}

/// The Frosted overlay panel: a glass card of [InteractiveSurface] rows that
/// springs into place. Render it inside a `MenuAnchor.menuChildren` (which
/// keeps Flutter's anchoring, keyboard and dismiss handling) — this widget
/// only owns the look and the open animation.
///
/// Internal to the library; not exported.
class FrostedMenuPanel extends StatelessWidget {
  const FrostedMenuPanel({
    required this.entries,
    this.width,
    this.maxHeight,
    this.borderRadius,
    super.key,
  });

  /// Gap between the anchor and the panel, fed to `MenuAnchor.alignmentOffset`.
  ///
  /// The panel is its own card, with its own corners. Flush against the field
  /// the two rounded rects meet corner to corner and pinch into one broken
  /// silhouette.
  static const double anchorGap = FrostedSpacing.sp2;
  static const Offset anchorOffset = Offset(0, anchorGap);

  final List<FrostedMenuEntry> entries;
  final double? width;

  /// Ceiling on the panel height. Past it the rows scroll.
  final double? maxHeight;

  /// Corner shape. Anchored menus flatten the edge they share with their
  /// field so the pair reads as one surface instead of two stacked cards.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    final Widget rows = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final FrostedMenuEntry entry in entries) _MenuRow(entry: entry),
      ],
    );

    final Widget panel = FrostedGlass(
      level: FrostedGlassLevel.regular,
      elevation: FrostedGlassElevation.none,
      borderRadius: borderRadius ?? BorderRadius.circular(FrostedRadius.md),
      child: maxHeight == null
          ? rows
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight!),
              child: SingleChildScrollView(primary: false, child: rows),
            ),
    );

    return TweenAnimationBuilder<double>(
      duration: motion.duration,
      curve: motion.curve,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double t, Widget? child) {
        // No Opacity: it isolates a layer and breaks the BackdropFilter
        // (the glass would stay transparent until the animation settles).
        return Transform.scale(
          scale: 0.92 + 0.08 * t,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: SizedBox(width: width, child: panel),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.entry});

  final FrostedMenuEntry entry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color base = entry.destructive
        ? cs.error
        : entry.selected
        ? cs.primary
        : cs.onSurface;

    return InteractiveSurface(
      onTap: entry.onTap,
      semanticsLabel: entry.label,
      semanticsSelected: entry.selected,
      builder: (BuildContext context, InteractionStates s) {
        final double overlay = s.pressed
            ? 0.12
            : s.focused
            ? 0.10
            : s.hovered
            ? 0.08
            : 0;
        return ColoredBox(
          color: overlay == 0
              ? Colors.transparent
              : base.withValues(alpha: overlay),
          child: s.ink(
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedSpacing.sp4,
                vertical: FrostedSpacing.sp3,
              ),
              child: Row(
                children: <Widget>[
                  if (entry.icon != null) ...<Widget>[
                    Icon(entry.icon, size: 20, color: base),
                    const SizedBox(width: FrostedSpacing.sp3),
                  ],
                  Expanded(
                    child: Text(
                      entry.label,
                      style: FrostedTypeScale.bodyLarge.copyWith(color: base),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.selected) ...<Widget>[
                    const SizedBox(width: FrostedSpacing.sp3),
                    Icon(Icons.check, size: 20, color: cs.primary),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
