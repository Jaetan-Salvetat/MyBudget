import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';

/// A status badge that can decorate a navigation item, an avatar, an icon
/// button, etc.
///
/// Two flavours are supported:
///   - [FrostedBadge.dot]: a small filled disc, used to signal *some* new
///     activity without a number.
///   - [FrostedBadge.count]: a pill with an integer count, capped at [max]
///     (overflow renders as `max+`).
sealed class FrostedBadge {
  const FrostedBadge({this.color});

  /// Override the badge background. Defaults to `Theme.colorScheme.error`.
  final Color? color;

  const factory FrostedBadge.dot({Color? color}) = _DotBadge;
  const factory FrostedBadge.count(int value, {int max, Color? color}) =
      _CountBadge;
}

class _DotBadge extends FrostedBadge {
  const _DotBadge({super.color});
}

class _CountBadge extends FrostedBadge {
  const _CountBadge(this.value, {this.max = 99, super.color});

  final int value;
  final int max;
}

/// Renders a [FrostedBadge] as a widget.
///
/// The badge sizes itself; wrap it in a [Stack] / [Positioned] to overlay it
/// on top of another widget.
class FrostedBadgeView extends StatelessWidget {
  const FrostedBadgeView({required this.badge, super.key});

  final FrostedBadge badge;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = badge.color ?? cs.error;
    final Color fg = cs.onError;

    switch (badge) {
      case _DotBadge():
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        );
      case _CountBadge(:final int value, :final int max):
        final String label = value > max ? '$max+' : '$value';
        return Container(
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedSpacing.sp1 + 1,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(FrostedRadius.full),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: FrostedTypeScale.labelSmall.copyWith(
              color: fg,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }
}
