import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_spacing.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_interactive_surface.dart';

const double _kCircleSize = 20;
const double _kBorderWidth = 2;
const double _kDotSize = 10;

/// A single-choice radio button, generic over the option type.
class FrostedRadio<T> extends StatelessWidget {
  const FrostedRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    super.key,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    final bool enabled = onChanged != null;

    return InteractiveSurface(
      onTap: enabled ? () => onChanged!(value) : null,
      semanticsButton: false,
      semanticsSelected: _selected,
      builder: (BuildContext context, InteractionStates s) {
        final Color ringColor = enabled
            ? (_selected ? cs.primary : cs.outline)
            : cs.onSurface.withValues(alpha: 0.38);
        final Color dotColor = enabled
            ? cs.primary
            : cs.onSurface.withValues(alpha: 0.38);

        return ClipOval(
          child: s.ink(
            Padding(
              padding: const EdgeInsets.all(FrostedSpacing.sp3),
              child: Container(
                width: _kCircleSize,
                height: _kCircleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: _kBorderWidth),
                ),
                child: Center(
                  child: AnimatedScale(
                    duration: motion.duration,
                    curve: motion.curve,
                    scale: _selected ? 1.0 : 0.0,
                    child: Container(
                      width: _kDotSize,
                      height: _kDotSize,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
