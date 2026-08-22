import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    this.borderEdges = FrostedGlassEdge.all,
    this.animation,
  });

  final Widget? child;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final FrostedGlassLevel level;
  final FrostedGlassTone tone;
  final FrostedGlassElevation elevation;

  /// Sides that carry the hairline border.
  ///
  /// Leave out any side that sits on a screen edge. Subsets other than
  /// [FrostedGlassEdge.all] or [FrostedGlassEdge.none] require a
  /// [BorderRadius.zero] radius.
  final Set<FrostedGlassEdge> borderEdges;

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

    assert(
      _hasUniformBorder || radius == BorderRadius.zero,
      'Leaving sides out of borderEdges requires BorderRadius.zero: Flutter '
      'cannot stroke a non-uniform border under a rounded radius.',
    );

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: _GlassBackdrop(
                sigma: spec.blurSigma * t,
                saturation: lerpDouble(1, glass.saturation, t)!,
                child: ColoredBox(color: veilColor),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: _buildBorder(border),
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

  bool get _hasUniformBorder =>
      borderEdges.length == FrostedGlassEdge.all.length || borderEdges.isEmpty;

  Border _buildBorder(BorderSide side) {
    if (_hasUniformBorder) {
      return Border.fromBorderSide(
        borderEdges.isEmpty ? BorderSide.none : side,
      );
    }
    return Border(
      top: borderEdges.contains(FrostedGlassEdge.top) ? side : BorderSide.none,
      bottom:
          borderEdges.contains(FrostedGlassEdge.bottom) ? side : BorderSide.none,
      left:
          borderEdges.contains(FrostedGlassEdge.left) ? side : BorderSide.none,
      right:
          borderEdges.contains(FrostedGlassEdge.right) ? side : BorderSide.none,
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

/// Blurs the backdrop, then desaturates it the way Apple's vibrancy does.
///
/// The blur is *bounded*: its kernel only samples pixels that sit inside the
/// glass bounds, so no surrounding colour bleeds in and no bright halo forms
/// along the edges.
///
/// Impeller's bounded blur degenerates once the sigma grows past roughly a
/// third of the bounded region: it collapses the backdrop into a flat fill
/// instead of blurring it, so the glass reads as opaque. Skia is unaffected,
/// which hides the problem in widget tests. The sigma is therefore capped
/// against the surface itself — see [_maxSigmaForBounds].
class _GlassBackdrop extends SingleChildRenderObjectWidget {
  const _GlassBackdrop({
    required this.sigma,
    required this.saturation,
    required Widget super.child,
  });

  final double sigma;
  final double saturation;

  @override
  _RenderGlassBackdrop createRenderObject(BuildContext context) {
    return _RenderGlassBackdrop(sigma: sigma, saturation: saturation);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGlassBackdrop renderObject,
  ) {
    renderObject
      ..sigma = sigma
      ..saturation = saturation;
  }
}

/// Paints the bounded backdrop blur behind its child.
///
/// The bounds a backdrop filter reads are expressed in the coordinate space of
/// the backdrop it samples — the root of the layer tree — not in the local
/// paint space the widget sits in. Any compositing layer in between (a repaint
/// boundary, a transform, the follower layer a [MenuAnchor] overlay hangs
/// from) resets the local offset to zero, which would aim the bounds at the
/// top-left of the screen and leave the filter reading nothing at all. The
/// rect is therefore resolved at paint time through [getTransformTo].
class _RenderGlassBackdrop extends RenderProxyBox {
  _RenderGlassBackdrop({required double sigma, required double saturation})
      : _sigma = sigma,
        _saturation = saturation;

  double _sigma;
  double get sigma => _sigma;
  set sigma(double value) {
    if (_sigma == value) return;
    _sigma = value;
    markNeedsPaint();
  }

  double _saturation;
  double get saturation => _saturation;
  set saturation(double value) {
    if (_saturation == value) return;
    _saturation = value;
    markNeedsPaint();
  }

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    assert(needsCompositing);
    final BackdropFilterLayer backdrop = layer ?? BackdropFilterLayer();
    backdrop.filter = _resolveFilter();
    layer = backdrop;
    context.pushLayer(backdrop, super.paint, offset);
  }

  ImageFilter _resolveFilter() {
    final Rect bounds =
        MatrixUtils.transformRect(getTransformTo(null), Offset.zero & size);
    final double effective = min(_sigma, _maxSigmaForBounds(bounds));
    final ImageFilter blur = ImageFilter.blur(
      sigmaX: effective,
      sigmaY: effective,
      tileMode: TileMode.clamp,
      bounds: bounds,
    );
    if (_saturation == 1) return blur;
    return ImageFilter.compose(outer: blur, inner: _saturate(_saturation));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('sigma', sigma));
    properties.add(DoubleProperty('saturation', saturation));
  }
}

/// Measured against Impeller: a bounded blur tracks Skia while the sigma stays
/// at or below a third of the shortest bounded span, and collapses beyond it.
const double _kSigmaToShortestSide = 3;

double _maxSigmaForBounds(Rect bounds) =>
    bounds.shortestSide / _kSigmaToShortestSide;

ColorFilter _saturate(double saturation) {
  final double s = saturation;
  final double r = 0.213 * (1 - s);
  final double g = 0.715 * (1 - s);
  final double b = 0.072 * (1 - s);
  return ColorFilter.matrix(<double>[
    r + s, g, b, 0, 0,
    r, g + s, b, 0, 0,
    r, g, b + s, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}
