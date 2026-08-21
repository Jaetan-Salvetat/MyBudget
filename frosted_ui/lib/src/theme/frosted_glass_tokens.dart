import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../primitives/frosted_glass_level.dart';
import 'frosted_glass_level_spec.dart';

/// Liquid Glass material tokens.
///
/// Glass surfaces are reserved for *chrome* (tab bars, toolbars, sheets,
/// modals). Never apply glass to scrollable content.
///
/// The token values express the material itself (sigma, veil opacities,
/// borders, shadows, backdrop saturation) — never any seed-derived color.
@immutable
class FrostedGlassTokens {
  const FrostedGlassTokens({
    required this.ultraThin,
    required this.thin,
    required this.regular,
    required this.thick,
    required this.ultraThick,
    required this.lightBorder,
    required this.darkBorder,
    required this.saturation,
    required this.floatingShadow,
    required this.liftedShadow,
    required this.scrim,
  });

  factory FrostedGlassTokens.standard() {
    return const FrostedGlassTokens(
      ultraThin: FrostedGlassLevelSpec(
        blurSigma: 14,
        lightVeilOpacity: 0.15,
        darkVeilOpacity: 0.05,
      ),
      thin: FrostedGlassLevelSpec(
        blurSigma: 20,
        lightVeilOpacity: 0.25,
        darkVeilOpacity: 0.12,
      ),
      regular: FrostedGlassLevelSpec(
        blurSigma: 28,
        lightVeilOpacity: 0.35,
        darkVeilOpacity: 0.18,
      ),
      thick: FrostedGlassLevelSpec(
        blurSigma: 36,
        lightVeilOpacity: 0.55,
        darkVeilOpacity: 0.30,
      ),
      ultraThick: FrostedGlassLevelSpec(
        blurSigma: 44,
        lightVeilOpacity: 0.75,
        darkVeilOpacity: 0.50,
      ),
      lightBorder:
          BorderSide(color: Color(0x0D000000), width: 0.5),
      darkBorder:
          BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
      saturation: 1.4,
      floatingShadow: <BoxShadow>[
        BoxShadow(
          color: Color(0x1F000000),
          offset: Offset(0, 8),
          blurRadius: 40,
        ),
      ],
      liftedShadow: <BoxShadow>[
        BoxShadow(
          color: Color(0x3D000000),
          offset: Offset(0, 12),
          blurRadius: 60,
        ),
      ],
      scrim: Color(0x8C000000),
    );
  }

  final FrostedGlassLevelSpec ultraThin;
  final FrostedGlassLevelSpec thin;
  final FrostedGlassLevelSpec regular;
  final FrostedGlassLevelSpec thick;
  final FrostedGlassLevelSpec ultraThick;

  final BorderSide lightBorder;
  final BorderSide darkBorder;

  /// Backdrop saturation multiplier (1.0 = no boost).
  final double saturation;

  final List<BoxShadow> floatingShadow;
  final List<BoxShadow> liftedShadow;

  /// Scrim color used behind modal glass.
  final Color scrim;

  FrostedGlassLevelSpec specFor(FrostedGlassLevel level) {
    switch (level) {
      case FrostedGlassLevel.ultraThin:
        return ultraThin;
      case FrostedGlassLevel.thin:
        return thin;
      case FrostedGlassLevel.regular:
        return regular;
      case FrostedGlassLevel.thick:
        return thick;
      case FrostedGlassLevel.ultraThick:
        return ultraThick;
    }
  }

  FrostedGlassTokens copyWith({
    FrostedGlassLevelSpec? ultraThin,
    FrostedGlassLevelSpec? thin,
    FrostedGlassLevelSpec? regular,
    FrostedGlassLevelSpec? thick,
    FrostedGlassLevelSpec? ultraThick,
    BorderSide? lightBorder,
    BorderSide? darkBorder,
    double? saturation,
    List<BoxShadow>? floatingShadow,
    List<BoxShadow>? liftedShadow,
    Color? scrim,
  }) {
    return FrostedGlassTokens(
      ultraThin: ultraThin ?? this.ultraThin,
      thin: thin ?? this.thin,
      regular: regular ?? this.regular,
      thick: thick ?? this.thick,
      ultraThick: ultraThick ?? this.ultraThick,
      lightBorder: lightBorder ?? this.lightBorder,
      darkBorder: darkBorder ?? this.darkBorder,
      saturation: saturation ?? this.saturation,
      floatingShadow: floatingShadow ?? this.floatingShadow,
      liftedShadow: liftedShadow ?? this.liftedShadow,
      scrim: scrim ?? this.scrim,
    );
  }

  static FrostedGlassTokens lerp(
    FrostedGlassTokens a,
    FrostedGlassTokens b,
    double t,
  ) {
    return FrostedGlassTokens(
      ultraThin: FrostedGlassLevelSpec.lerp(a.ultraThin, b.ultraThin, t),
      thin: FrostedGlassLevelSpec.lerp(a.thin, b.thin, t),
      regular: FrostedGlassLevelSpec.lerp(a.regular, b.regular, t),
      thick: FrostedGlassLevelSpec.lerp(a.thick, b.thick, t),
      ultraThick: FrostedGlassLevelSpec.lerp(a.ultraThick, b.ultraThick, t),
      lightBorder: BorderSide.lerp(a.lightBorder, b.lightBorder, t),
      darkBorder: BorderSide.lerp(a.darkBorder, b.darkBorder, t),
      saturation: lerpDouble(a.saturation, b.saturation, t)!,
      floatingShadow:
          BoxShadow.lerpList(a.floatingShadow, b.floatingShadow, t)!,
      liftedShadow:
          BoxShadow.lerpList(a.liftedShadow, b.liftedShadow, t)!,
      scrim: Color.lerp(a.scrim, b.scrim, t)!,
    );
  }
}
