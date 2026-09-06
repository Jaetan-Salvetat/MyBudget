import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';

const double _kPadding = 3;
const double _kHeight = 32;
const double _kFallbackSegmentWidth = 96;
const double _kTrackRadius = FrostedRadius.md;
const double _kSegmentRadius = _kTrackRadius - _kPadding;

class FrostedSegmentedControl extends StatelessWidget {
  const FrostedSegmentedControl({
    required this.segments,
    required this.currentIndex,
    required this.onTap,
    this.segmentWidth,
    super.key,
  });

  final List<String> segments;
  final int currentIndex;
  final ValueChanged<int> onTap;

  final double? segmentWidth;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double? width = segmentWidth == null
        ? null
        : segmentWidth! * segments.length;

    return Container(
      padding: const EdgeInsets.all(_kPadding),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(_kTrackRadius),
      ),
      child: SizedBox(
        height: _kHeight,
        width: width,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double trackWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : _kFallbackSegmentWidth * segments.length;

            return Stack(
              children: <Widget>[
                _SegmentRow(
                  count: segments.length,
                  builder: (int index) => _SegmentSurface(
                    label: segments[index],
                    selected: index == currentIndex,
                    onTap: () => onTap(index),
                  ),
                ),
                _Thumb(
                  left: trackWidth / segments.length * currentIndex,
                  width: trackWidth / segments.length,
                ),
                IgnorePointer(
                  child: _SegmentRow(
                    count: segments.length,
                    builder: (int index) => _SegmentLabel(
                      label: segments[index],
                      selected: index == currentIndex,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({required this.count, required this.builder});

  final int count;
  final Widget Function(int index) builder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < count; i++) Expanded(child: builder(i)),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.left, required this.width});

  final double left;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    return AnimatedPositioned(
      duration: motion.duration,
      curve: motion.curve,
      left: left,
      top: 0,
      bottom: 0,
      width: width,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(_kSegmentRadius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentSurface extends StatelessWidget {
  const _SegmentSurface({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: label,
      semanticsSelected: selected,
      builder: (BuildContext context, InteractionStates s) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_kSegmentRadius),
        ),
        child: s.ink(const SizedBox.expand()),
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;

    return Center(
      child: AnimatedDefaultTextStyle(
        duration: motion.duration,
        curve: motion.curve,
        style: FrostedTypeScale.labelMedium.copyWith(
          color: selected ? cs.onSurface : cs.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        child: Text(label),
      ),
    );
  }
}
