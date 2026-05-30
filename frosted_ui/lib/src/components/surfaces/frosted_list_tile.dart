import 'package:flutter/material.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../actions/_interactive_surface.dart';

/// A single row in a [FrostedListSection], following the M3 Expressive list
/// item spec (56 / 72 / 88dp heights, 16dp leading/trailing space, 10dp
/// vertical padding).
///
/// [leading] and [trailing] are arbitrary widgets — pass a [FrostedListAvatar]
/// for the rounded leading badge from the mockups.
class FrostedListTile extends StatelessWidget {
  const FrostedListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;

  static const double _oneLineHeight = 56;
  static const double _twoLineHeight = 72;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool twoLine = subtitle != null;
    final double minHeight = twoLine ? _twoLineHeight : _oneLineHeight;
    final Color titleColor = selected ? cs.onSecondaryContainer : cs.onSurface;
    final Color subtitleColor =
        selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    final Widget content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp4,
          vertical: 10,
        ),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
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
                      style: FrostedTypeScale.bodySmall
                          .copyWith(color: subtitleColor),
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
                style: FrostedTypeScale.labelMedium
                    .copyWith(color: cs.onSurfaceVariant),
                child: IconTheme.merge(
                  data: IconThemeData(color: cs.onSurfaceVariant, size: 20),
                  child: trailing!,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final Color background =
        selected ? cs.secondaryContainer : Colors.transparent;

    if (onTap == null) {
      return ColoredBox(color: background, child: content);
    }
    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: title,
      semanticsSelected: selected,
      builder: (BuildContext context, InteractionStates s) {
        final double overlay = s.pressed
            ? 0.12
            : s.focused
                ? 0.10
                : s.hovered
                    ? 0.08
                    : 0;
        final Color overlayColor = overlay == 0
            ? background
            : Color.alphaBlend(cs.onSurface.withValues(alpha: overlay), background);
        return ColoredBox(color: overlayColor, child: content);
      },
    );
  }
}
