import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';

/// iOS-style segmented control.
///
/// Each segment is equally sized. The selected segment slides between
/// positions with a spring-like ease.
class FrostedSegmentedControl extends StatelessWidget {
  const FrostedSegmentedControl({
    required this.segments,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<String> segments;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : segments.length * 96.0;
        final double segmentWidth = width / segments.length;

        return Container(
          width: width,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(FrostedRadius.md),
          ),
          child: SizedBox(
            height: 32,
            child: Stack(
              children: <Widget>[
                AnimatedPositioned(
                  duration: motion.duration,
                  curve: motion.curve,
                  left: segmentWidth * currentIndex - 3,
                  top: 0,
                  width: segmentWidth,
                  height: 32,
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(FrostedRadius.sm),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    for (int i = 0; i < segments.length; i++)
                      Expanded(
                        child: InteractiveSurface(
                          onTap: () => onTap(i),
                          semanticsLabel: segments[i],
                          semanticsSelected: i == currentIndex,
                          builder:
                              (BuildContext context, InteractionStates s) =>
                                  s.ink(
                                    borderRadius: BorderRadius.circular(
                                      FrostedRadius.sm,
                                    ),
                                    Center(
                                      child: Text(
                                        segments[i],
                                        style: FrostedTypeScale.labelMedium
                                            .copyWith(
                                              color: i == currentIndex
                                                  ? cs.onSurface
                                                  : cs.onSurfaceVariant,
                                              fontWeight: i == currentIndex
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
