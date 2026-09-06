import 'dart:math';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../foundations/frosted_radius.dart';
import '../theme/frosted_glass_level_spec.dart';
import '../theme/frosted_glass_tokens.dart';
import '../theme/frosted_tokens.dart';
import 'frosted_glass_level.dart';
import 'frosted_glass_suspension.dart';

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

  final Set<FrostedGlassEdge> borderEdges;

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
    final Color veilColor = (isDark ? Colors.black : Colors.white).withValues(
      alpha: veilAlpha,
    );
    final bool detached = elevation != FrostedGlassElevation.none;
    final BorderSide base = switch ((isDark, detached)) {
      (true, true) => glass.darkDetachedBorder,
      (true, false) => glass.darkBorder,
      (false, true) => glass.lightDetachedBorder,
      (false, false) => glass.lightBorder,
    };
    final BorderSide border = base.copyWith(
      color: base.color.withValues(alpha: base.color.a * t),
    );
    final List<BoxShadow>? shadow = switch (elevation) {
      FrostedGlassElevation.none => null,
      FrostedGlassElevation.resting => _scaleShadow(glass.restingShadow, t),
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
              child: FrostedGlassSuspension.of(context)
                  ? ColoredBox(color: veilColor)
                  : _GlassBackdrop(
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
      bottom: borderEdges.contains(FrostedGlassEdge.bottom)
          ? side
          : BorderSide.none,
      left: borderEdges.contains(FrostedGlassEdge.left)
          ? side
          : BorderSide.none,
      right: borderEdges.contains(FrostedGlassEdge.right)
          ? side
          : BorderSide.none,
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
      shadow.copyWith(
        color: shadow.color.withValues(alpha: shadow.color.a * t),
      ),
  ];
}

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
    final Rect bounds = MatrixUtils.transformRect(
      getTransformTo(null),
      Offset.zero & size,
    );
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

const double _kSigmaToShortestSide = 3;

double _maxSigmaForBounds(Rect bounds) =>
    bounds.shortestSide / _kSigmaToShortestSide;

ColorFilter _saturate(double saturation) {
  final double s = saturation;
  final double r = 0.213 * (1 - s);
  final double g = 0.715 * (1 - s);
  final double b = 0.072 * (1 - s);
  return ColorFilter.matrix(<double>[
    r + s,
    g,
    b,
    0,
    0,
    r,
    g + s,
    b,
    0,
    0,
    r,
    g,
    b + s,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
}
