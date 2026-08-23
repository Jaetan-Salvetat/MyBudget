import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_interactive_surface.dart';

const double _kTrackWidth = 52;
const double _kTrackHeight = 32;
const double _kThumbSize = 24;
const double _kPadding = 4;

/// An iOS-style on/off toggle.
class FrostedSwitch extends StatelessWidget {
  const FrostedSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    return InteractiveSurface(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      semanticsButton: false,
      semanticsLabel: value ? 'On' : 'Off',
      builder: (BuildContext context, InteractionStates s) {
        final Color trackColor = _trackColor(cs, s.enabled);
        final Color thumbColor = _thumbColor(cs, s.enabled);
        final BorderSide? border = _trackBorder(cs, s.enabled);

        return AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          width: _kTrackWidth,
          height: _kTrackHeight,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(FrostedRadius.full),
            border: border != null ? Border.fromBorderSide(border) : null,
          ),
          child: s.ink(
            borderRadius: BorderRadius.circular(FrostedRadius.full),
            Padding(
              padding: const EdgeInsets.all(_kPadding),
              child: AnimatedAlign(
                duration: motion.duration,
                curve: motion.curve,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: _kThumbSize,
                  height: _kThumbSize,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _trackColor(ColorScheme cs, bool enabled) {
    if (!enabled) {
      return value
          ? cs.primary.withValues(alpha: 0.38)
          : cs.surfaceContainerHigh;
    }
    return value ? cs.primary : cs.surfaceContainerHighest;
  }

  Color _thumbColor(ColorScheme cs, bool enabled) {
    if (!enabled) {
      return value ? cs.surface : cs.outline.withValues(alpha: 0.38);
    }
    return value ? cs.onPrimary : cs.outline;
  }

  BorderSide? _trackBorder(ColorScheme cs, bool enabled) {
    if (value) return null;
    final Color color = enabled
        ? cs.outline
        : cs.outline.withValues(alpha: 0.38);
    return BorderSide(color: color, width: 2);
  }
}
