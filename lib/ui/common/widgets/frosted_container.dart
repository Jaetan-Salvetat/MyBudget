import 'dart:ui';
import 'package:material_ui/material_ui.dart';

class FrostedContainer extends StatelessWidget {
  const FrostedContainer({
    super.key,
    required this.child,
    this.blurStrength = 7,
    this.opacity = 0.7,
    this.borderRadius = BorderRadius.zero,
    this.padding,
    this.margin,
  });
  final Widget child;
  final double blurStrength;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: opacity),
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
