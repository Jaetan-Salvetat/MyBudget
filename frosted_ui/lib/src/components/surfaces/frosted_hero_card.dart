import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';

/// A large emphasis card for the top of a screen: a `primaryContainer` block
/// with a soft corner halo, a display-scale [title], a [subtitle], and a row
/// of [actions].
///
/// Opaque M3 content surface. At most one per screen — it is the loudest
/// content element below the FAB.
class FrostedHeroCard extends StatelessWidget {
  const FrostedHeroCard({
    required this.title,
    this.subtitle,
    this.label,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? label;
  final List<Widget> actions;

  static const double _radius = FrostedRadius.xl - 6;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -40,
              bottom: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      cs.onPrimaryContainer.withValues(alpha: 0.10),
                      cs.onPrimaryContainer.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(FrostedSpacing.sp5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (label != null) ...<Widget>[
                    Text(
                      label!.toUpperCase(),
                      style: FrostedTypeScale.labelSmall.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: FrostedSpacing.sp2),
                  ],
                  Text(
                    title,
                    style: FrostedTypeScale.displaySmall.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: FrostedSpacing.sp2),
                    Text(
                      subtitle!,
                      style: FrostedTypeScale.bodyMedium.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                  if (actions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: FrostedSpacing.sp4),
                    Wrap(
                      spacing: FrostedSpacing.sp2,
                      runSpacing: FrostedSpacing.sp2,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
