import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_shape.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_interactive_surface.dart';

enum _FabSize { small, regular, large, extended }

/// A Floating Action Button — the most expressive interactive element on
/// a screen.
///
/// [shape] picks the resting form, [FrostedShape.pill] by default since the
/// round form is the FAB's signature. A press morphs it into the other form
/// and back; each size carries its own [FrostedShape.rounded] radius so the
/// corner stays concentric with the container it sits in.
class FrostedFab extends StatelessWidget {
  const FrostedFab._({
    super.key,
    required this.icon,
    required _FabSize size,
    this.label,
    this.onPressed,
    this.tooltip,
    this.tonal = false,
    this.shape = FrostedShape.pill,
  }) : _size = size;

  factory FrostedFab.small({
    Key? key,
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    bool tonal = false,
    FrostedShape shape = FrostedShape.pill,
  }) => FrostedFab._(
    key: key,
    icon: icon,
    size: _FabSize.small,
    onPressed: onPressed,
    tooltip: tooltip,
    tonal: tonal,
    shape: shape,
  );

  factory FrostedFab.regular({
    Key? key,
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    bool tonal = false,
    FrostedShape shape = FrostedShape.pill,
  }) => FrostedFab._(
    key: key,
    icon: icon,
    size: _FabSize.regular,
    onPressed: onPressed,
    tooltip: tooltip,
    tonal: tonal,
    shape: shape,
  );

  factory FrostedFab.large({
    Key? key,
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    bool tonal = false,
    FrostedShape shape = FrostedShape.pill,
  }) => FrostedFab._(
    key: key,
    icon: icon,
    size: _FabSize.large,
    onPressed: onPressed,
    tooltip: tooltip,
    tonal: tonal,
    shape: shape,
  );

  factory FrostedFab.extended({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    String? tooltip,
    bool tonal = false,
    FrostedShape shape = FrostedShape.pill,
  }) => FrostedFab._(
    key: key,
    icon: icon,
    size: _FabSize.extended,
    label: label,
    onPressed: onPressed,
    tooltip: tooltip,
    tonal: tonal,
    shape: shape,
  );

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool tonal;

  /// The resting form. A press morphs it into [FrostedShape.opposite].
  final FrostedShape shape;

  final _FabSize _size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    final _FabMetrics m = _metricsFor(_size);

    BorderRadius resolveShape(InteractionStates s) => shape.resolve(
      m.box,
      pressed: s.pressed,
      roundedRadius: m.roundedRadius,
    );

    final Widget surface = InteractiveSurface(
      onTap: onPressed,
      semanticsLabel: tooltip ?? label,
      builder: (BuildContext context, InteractionStates s) {
        final Color bg = _resolveBg(cs, s);
        final Color fg = _resolveFg(cs, s);

        final Widget content = m.extended
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FrostedSpacing.sp4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, size: m.iconSize, color: fg),
                    const SizedBox(width: FrostedSpacing.sp2),
                    Text(
                      label!,
                      style: FrostedTypeScale.labelLarge.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Icon(icon, size: m.iconSize, color: fg),
              );

        return AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          height: m.height,
          width: m.extended ? null : m.height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: resolveShape(s),
            boxShadow: s.enabled
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: s.pressed ? 0.12 : 0.24,
                      ),
                      offset: const Offset(0, 6),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: content,
        );
      },
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: surface);
    }
    return surface;
  }

  Color _resolveBg(ColorScheme cs, InteractionStates s) {
    if (!s.enabled) return cs.onSurface.withValues(alpha: 0.12);
    final Color base = tonal ? cs.secondaryContainer : cs.primaryContainer;
    final Color overlay = tonal
        ? cs.onSecondaryContainer
        : cs.onPrimaryContainer;
    final double alpha = _overlayAlpha(s);
    if (alpha == 0) return base;
    return Color.alphaBlend(overlay.withValues(alpha: alpha), base);
  }

  Color _resolveFg(ColorScheme cs, InteractionStates s) {
    if (!s.enabled) return cs.onSurface.withValues(alpha: 0.38);
    return tonal ? cs.onSecondaryContainer : cs.onPrimaryContainer;
  }

  double _overlayAlpha(InteractionStates s) {
    if (s.pressed) return 0.12;
    if (s.focused) return 0.10;
    if (s.hovered) return 0.08;
    return 0;
  }

  _FabMetrics _metricsFor(_FabSize size) {
    switch (size) {
      case _FabSize.small:
        return const _FabMetrics(
          height: 40,
          iconSize: 20,
          roundedRadius: FrostedRadius.md,
        );
      case _FabSize.regular:
        return const _FabMetrics(
          height: 56,
          iconSize: 24,
          roundedRadius: FrostedRadius.lg,
        );
      case _FabSize.large:
        return const _FabMetrics(
          height: 96,
          iconSize: 36,
          roundedRadius: FrostedRadius.xxl,
        );
      case _FabSize.extended:
        return const _FabMetrics(
          height: 56,
          iconSize: 24,
          roundedRadius: FrostedRadius.lg,
          extended: true,
        );
    }
  }
}

class _FabMetrics {
  const _FabMetrics({
    required this.height,
    required this.iconSize,
    required this.roundedRadius,
    this.extended = false,
  });

  final double height;
  final double iconSize;
  final double roundedRadius;
  final bool extended;

  /// An extended fab grows with its label, so its shortest side — the one the
  /// pill radius is measured against — is always its height.
  Size get box =>
      extended ? Size(double.infinity, height) : Size(height, height);
}
