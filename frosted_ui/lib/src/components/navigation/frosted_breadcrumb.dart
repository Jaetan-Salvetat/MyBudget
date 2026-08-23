import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../actions/_interactive_surface.dart';

/// A standalone breadcrumb trail.
///
/// The last crumb is emphasized and not interactive. Others can be tapped if
/// [onTap] is provided.
class FrostedBreadcrumb extends StatelessWidget {
  const FrostedBreadcrumb({required this.crumbs, this.onTap, super.key});

  final List<String> crumbs;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (int i = 0; i < crumbs.length; i++) ...<Widget>[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedSpacing.sp1,
              ),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
          _Crumb(
            label: crumbs[i],
            active: i == crumbs.length - 1,
            onTap: onTap == null ? null : () => onTap!(i),
          ),
        ],
      ],
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle style = FrostedTypeScale.labelLarge.copyWith(
      color: active ? cs.onSurface : cs.onSurfaceVariant,
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
    );
    if (active || onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp1,
          vertical: 2,
        ),
        child: Text(label, style: style),
      );
    }
    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: label,
      builder: (BuildContext context, InteractionStates s) => s.ink(
        borderRadius: BorderRadius.circular(FrostedRadius.xs),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedSpacing.sp1,
            vertical: 2,
          ),
          child: Text(label, style: style),
        ),
      ),
    );
  }
}
