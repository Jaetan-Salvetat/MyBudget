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
  });

  final Widget? child;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final FrostedGlassLevel level;
  final FrostedGlassTone tone;
  final FrostedGlassElevation elevation;

  @override
  Widget build(BuildContext context) {
    final FrostedGlassTokens glass = context.frostedTokens.glass;
    final FrostedGlassLevelSpec spec = glass.specFor(level);
    final Brightness effective = _resolveBrightness(context);
    final bool isDark = effective == Brightness.dark;

    final Color veilColor = (isDark ? Colors.black : Colors.white).withValues(
      alpha: isDark ? spec.darkVeilOpacity : spec.lightVeilOpacity,
    );
    final BorderSide border = isDark ? glass.darkBorder : glass.lightBorder;
    final List<BoxShadow>? shadow = switch (elevation) {
      FrostedGlassElevation.none => null,
      FrostedGlassElevation.floating => glass.floatingShadow,
      FrostedGlassElevation.lifted => glass.liftedShadow,
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
                  sigma: spec.blurSigma,
                  saturation: glass.saturation,
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

ImageFilter _saturatingBlur({
  required double sigma,
  required double saturation,
}) {
  final ImageFilter blur = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
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
