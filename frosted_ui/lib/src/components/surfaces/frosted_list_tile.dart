import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';

enum FrostedTilePosition { single, first, middle, last }

enum FrostedListTileVariant { filled, plain }

class FrostedListTile extends StatelessWidget {
  const FrostedListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.variant = FrostedListTileVariant.filled,
    this.position = FrostedTilePosition.single,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;
  final FrostedListTileVariant variant;
  final FrostedTilePosition position;

  FrostedListTile withPosition(FrostedTilePosition value) => FrostedListTile(
    title: title,
    subtitle: subtitle,
    leading: leading,
    trailing: trailing,
    selected: selected,
    onTap: onTap,
    variant: variant,
    position: value,
    key: key,
  );

  static const double _oneLineHeight = 56;
  static const double _twoLineHeight = 72;
  static const double _outer = FrostedRadius.lg;
  static const double _inner = FrostedRadius.sm;

  BorderRadius _shape(InteractionStates s) {
    if (s.pressed) return BorderRadius.circular(_outer);

    final Radius outerR = const Radius.circular(_outer);
    final Radius innerR = const Radius.circular(_inner);
    switch (position) {
      case FrostedTilePosition.single:
        return BorderRadius.circular(_outer);
      case FrostedTilePosition.first:
        return BorderRadius.vertical(top: outerR, bottom: innerR);
      case FrostedTilePosition.middle:
        return BorderRadius.all(innerR);
      case FrostedTilePosition.last:
        return BorderRadius.vertical(top: innerR, bottom: outerR);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool twoLine = subtitle != null;
    final double minHeight = twoLine ? _twoLineHeight : _oneLineHeight;
    final Color titleColor = selected ? cs.onSecondaryContainer : cs.onSurface;
    final Color subtitleColor = selected
        ? cs.onSecondaryContainer
        : cs.onSurfaceVariant;
    final Color base = selected
        ? cs.secondaryContainer
        : variant == FrostedListTileVariant.plain
        ? Colors.transparent
        : cs.surfaceContainer;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    Widget content(InteractionStates s) {
      final double overlay = s.pressed
          ? 0.12
          : s.focused
          ? 0.10
          : s.hovered
          ? 0.08
          : 0;
      final Color fill = overlay == 0
          ? base
          : Color.alphaBlend(cs.onSurface.withValues(alpha: overlay), base);

      return AnimatedContainer(
        duration: motion.duration,
        curve: motion.curve,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: fill, borderRadius: _shape(s)),
        child: s.ink(
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedSpacing.sp4,
                vertical: FrostedSpacing.sp2,
              ),
              child: Row(
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    IconTheme.merge(
                      data: IconThemeData(color: cs.onSurfaceVariant, size: 24),
                      child: leading!,
                    ),
                    const SizedBox(width: FrostedSpacing.sp4),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: FrostedTypeScale.bodyLarge.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (twoLine) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: FrostedTypeScale.bodySmall.copyWith(
                              color: subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: FrostedSpacing.sp4),
                    DefaultTextStyle.merge(
                      style: FrostedTypeScale.labelMedium.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      child: IconTheme.merge(
                        data: IconThemeData(
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                        child: trailing!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (onTap == null) {
      return content(InteractionStates.inert);
    }

    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: title,
      semanticsSelected: selected,
      builder: (BuildContext context, InteractionStates s) => content(s),
    );
  }
}
