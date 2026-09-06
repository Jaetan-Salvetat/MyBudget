import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';

sealed class FrostedBadge {
  const FrostedBadge({this.color});

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
