import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';
import 'frosted_list_tile.dart';

class FrostedExpansionTile extends StatefulWidget {
  const FrostedExpansionTile({
    required this.title,
    required this.child,
    this.leading,
    this.subtitle,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpansionChanged,
    this.position = FrostedTilePosition.single,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget child;
  final bool initiallyExpanded;

  final bool? expanded;

  final ValueChanged<bool>? onExpansionChanged;

  final FrostedTilePosition position;

  FrostedExpansionTile withPosition(FrostedTilePosition value) =>
      FrostedExpansionTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        initiallyExpanded: initiallyExpanded,
        expanded: expanded,
        onExpansionChanged: onExpansionChanged,
        position: value,
        key: key,
        child: child,
      );

  @override
  State<FrostedExpansionTile> createState() => _FrostedExpansionTileState();
}

class _FrostedExpansionTileState extends State<FrostedExpansionTile> {
  late bool _ownExpanded = widget.initiallyExpanded;

  bool get _expanded => widget.expanded ?? _ownExpanded;

  void _handleTap() {
    final bool next = !_expanded;
    if (widget.expanded == null) setState(() => _ownExpanded = next);
    widget.onExpansionChanged?.call(next);
  }

  static const double _outer = FrostedRadius.lg;
  static const double _inner = FrostedRadius.sm;
  static const double _headerHeight = 56;

  BorderRadius _shape(InteractionStates s, {required bool header}) {
    if (s.pressed && !_expanded) return BorderRadius.circular(_outer);

    final Radius outerR = const Radius.circular(_outer);
    final Radius innerR = const Radius.circular(_inner);
    final Radius topLeading;
    final Radius topTrailing;
    switch (widget.position) {
      case FrostedTilePosition.single:
      case FrostedTilePosition.first:
        topLeading = outerR;
        topTrailing = outerR;
        break;
      case FrostedTilePosition.middle:
      case FrostedTilePosition.last:
        topLeading = innerR;
        topTrailing = innerR;
        break;
    }
    final bool roundBottom =
        widget.position == FrostedTilePosition.single ||
        widget.position == FrostedTilePosition.last;
    final Radius bottom = roundBottom ? outerR : innerR;

    if (header) {
      return BorderRadius.only(
        topLeft: topLeading,
        topRight: topTrailing,
        bottomLeft: _expanded ? Radius.zero : bottom,
        bottomRight: _expanded ? Radius.zero : bottom,
      );
    }
    return BorderRadius.only(bottomLeft: bottom, bottomRight: bottom);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    final Widget header = InteractiveSurface(
      onTap: _handleTap,
      semanticsLabel: widget.title,
      semanticsSelected: _expanded,
      builder: (BuildContext context, InteractionStates s) {
        final double overlay = s.pressed
            ? 0.12
            : s.focused
            ? 0.10
            : s.hovered
            ? 0.08
            : 0;
        final Color fill = overlay == 0
            ? cs.surfaceContainer
            : Color.alphaBlend(
                cs.onSurface.withValues(alpha: overlay),
                cs.surfaceContainer,
              );

        return AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: _shape(s, header: true),
          ),
          child: s.ink(
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _headerHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FrostedSpacing.sp4,
                  vertical: FrostedSpacing.sp2,
                ),
                child: Row(
                  children: <Widget>[
                    if (widget.leading != null) ...<Widget>[
                      IconTheme.merge(
                        data: IconThemeData(
                          color: cs.onSurfaceVariant,
                          size: 24,
                        ),
                        child: widget.leading!,
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
                            widget.title,
                            style: FrostedTypeScale.bodyLarge.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.subtitle != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: FrostedTypeScale.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: FrostedSpacing.sp4),
                    AnimatedRotation(
                      duration: motion.duration,
                      curve: motion.curve,
                      turns: _expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 24,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final Widget body = DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: _shape(InteractionStates.inert, header: false),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FrostedSpacing.sp4,
          0,
          FrostedSpacing.sp4,
          FrostedSpacing.sp3,
        ),
        child: widget.child,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        header,
        AnimatedSize(
          duration: motion.duration,
          curve: motion.curve,
          alignment: Alignment.topCenter,
          child: _expanded ? body : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
