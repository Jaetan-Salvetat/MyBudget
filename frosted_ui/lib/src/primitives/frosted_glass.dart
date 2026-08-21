import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundations/frosted_radius.dart';
import '../theme/frosted_glass_level_spec.dart';
import '../theme/frosted_glass_tokens.dart';
import '../theme/frosted_tokens.dart';
import 'frosted_glass_level.dart';

/// The Liquid Glass primitive used by every chrome surface (tab bar,
/// toolbar, sheet, modal shell).
///
/// The material is composed from three independent axes:
///
///   - [level]: how much matter the glass carries (blur + veil opacity).
///   - [tone]: which tint the veil uses ([FrostedGlassTone.auto] follows
///     the ambient theme brightness).
///   - [elevation]: how the glass sits in space (shadow strength).
///
/// Glass is for *chrome only*. Do not wrap scrollable content in it.
class FrostedGlass extends StatelessWidget {
  const FrostedGlass({
    super.key,
    this.child,
    this.borderRadius,
    this.padding,
    this.level = FrostedGlassLevel.regular,
    this.tone = FrostedGlassTone.auto,
    this.elevation = FrostedGlassElevation.floating,
    this.animation,
  });

  final Widget? child;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final FrostedGlassLevel level;
  final FrostedGlassTone tone;
  final FrostedGlassElevation elevation;

  /// Optional 0→1 driver that reveals the material progressively: blur, veil,
  /// border and shadow all scale with the animation value. When null the glass
  /// renders at full strength.
  ///
  /// Use it for reveal transitions (scrims, sheets, drawers) where wrapping the
  /// glass in [Opacity] would break the [BackdropFilter].
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? reveal = animation;
    if (reveal == null) return _buildGlass(context, 1);
    return AnimatedBuilder(
      animation: reveal,
      builder: (BuildContext context, _) =>
          _buildGlass(context, reveal.value.clamp(0, 1)),
    );
  }

  Widget _buildGlass(BuildContext context, double t) {
    final FrostedGlassTokens glass = context.frostedTokens.glass;
    final FrostedGlassLevelSpec spec = glass.specFor(level);
    final Brightness effective = _resolveBrightness(context);
    final bool isDark = effective == Brightness.dark;

    final double veilAlpha =
        (isDark ? spec.darkVeilOpacity : spec.lightVeilOpacity) * t;
    final Color veilColor =
        (isDark ? Colors.black : Colors.white).withValues(alpha: veilAlpha);
    final BorderSide base = isDark ? glass.darkBorder : glass.lightBorder;
    final BorderSide border = base.copyWith(
      color: base.color.withValues(alpha: base.color.a * t),
    );
    final List<BoxShadow>? shadow = switch (elevation) {
      FrostedGlassElevation.none => null,
      FrostedGlassElevation.floating => _scaleShadow(glass.floatingShadow, t),
      FrostedGlassElevation.lifted => _scaleShadow(glass.liftedShadow, t),
    };

    final BorderRadiusGeometry radius =
        borderRadius ?? BorderRadius.circular(FrostedRadius.xxl);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: BackdropFilter(
                filter: _saturatingBlur(
                  sigma: spec.blurSigma * t,
                  saturation: lerpDouble(1, glass.saturation, t)!,
                ),
                child: ColoredBox(color: veilColor),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.fromBorderSide(border),
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child ?? const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Brightness _resolveBrightness(BuildContext context) {
    switch (tone) {
      case FrostedGlassTone.auto:
        return Theme.of(context).brightness;
      case FrostedGlassTone.light:
        return Brightness.light;
      case FrostedGlassTone.dark:
        return Brightness.dark;
    }
  }
}

List<BoxShadow> _scaleShadow(List<BoxShadow> shadows, double t) {
  if (t >= 1) return shadows;
  return <BoxShadow>[
    for (final BoxShadow shadow in shadows)
      shadow.copyWith(color: shadow.color.withValues(alpha: shadow.color.a * t)),
  ];
}

ImageFilter _saturatingBlur({
  required double sigma,
  required double saturation,
}) {
  final ImageFilter blur = ImageFilter.blur(
    sigmaX: sigma,
    sigmaY: sigma,
    tileMode: TileMode.decal,
  );
  if (saturation == 1.0) return blur;
  final double s = saturation;
  final double r = 0.213 * (1 - s);
  final double g = 0.715 * (1 - s);
  final double b = 0.072 * (1 - s);
  final ColorFilter saturate = ColorFilter.matrix(<double>[
    r + s, g, b, 0, 0,
    r, g + s, b, 0, 0,
    r, g, b + s, 0, 0,
    0, 0, 0, 1, 0,
  ]);
  return ImageFilter.compose(outer: saturate, inner: blur);
}
