import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_interactive_surface.dart';

const double _kBoxSize = 20;
const double _kBorderWidth = 2;

/// A square checkbox with rounded corners.
///
/// Supports the boolean states `true` (checked), `false` (unchecked) and,
/// when [tristate] is true, `null` (indeterminate — rendered as a horizontal
/// bar instead of a checkmark).
class FrostedCheckbox extends StatelessWidget {
  const FrostedCheckbox({
    required this.value,
    required this.onChanged,
    this.tristate = false,
    super.key,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    final bool enabled = onChanged != null;

    return InteractiveSurface(
      onTap: enabled ? _handleTap : null,
      semanticsButton: false,
      semanticsSelected: value == true,
      builder: (BuildContext context, InteractionStates s) {
        final bool isChecked = value == true;
        final bool isIndeterminate = value == null && tristate;
        final bool filled = isChecked || isIndeterminate;

        final Color fill = filled
            ? (enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.38))
            : Colors.transparent;
        final Color borderColor = enabled
            ? cs.outline
            : cs.onSurface.withValues(alpha: 0.38);
        final Color glyph = enabled ? cs.onPrimary : cs.surface;

        return s.ink(
          borderRadius: BorderRadius.circular(FrostedRadius.full),
          Padding(
            padding: const EdgeInsets.all(FrostedSpacing.sp3),
            child: AnimatedContainer(
              duration: motion.duration,
              curve: motion.curve,
              width: _kBoxSize,
              height: _kBoxSize,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(FrostedRadius.xs),
                border: filled
                    ? null
                    : Border.all(color: borderColor, width: _kBorderWidth),
              ),
              child: isIndeterminate
                  ? Center(child: Container(width: 12, height: 2, color: glyph))
                  : (isChecked
                        ? CustomPaint(painter: _CheckmarkPainter(color: glyph))
                        : const SizedBox.shrink()),
            ),
          ),
        );
      },
    );
  }

  void _handleTap() {
    if (tristate) {
      final bool? next = switch (value) {
        false => true,
        true => null,
        null => false,
      };
      onChanged!(next);
    } else {
      onChanged!(!(value ?? false));
    }
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.72)
      ..lineTo(size.width * 0.78, size.height * 0.32);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter old) => old.color != color;
}
