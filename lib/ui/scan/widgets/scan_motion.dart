import 'package:material_ui/material_ui.dart';

class ScanMotion {
  const ScanMotion._();

  static const Duration settle = Duration(milliseconds: 460);
  static const Duration swap = Duration(milliseconds: 260);

  static const Curve curve = Curves.easeOutCubic;

  static const double rise = 0.35;
}

class ScanSettle extends StatelessWidget {
  final bool visible;
  final Widget child;

  const ScanSettle({required this.visible, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, ScanMotion.rise),
      duration: ScanMotion.settle,
      curve: ScanMotion.curve,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: ScanMotion.settle,
        curve: ScanMotion.curve,
        child: child,
      ),
    );
  }
}

class ScanSwap extends StatelessWidget {
  final Widget child;

  const ScanSwap({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: ScanMotion.swap,
      switchInCurve: ScanMotion.curve,
      switchOutCurve: ScanMotion.curve,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }
}
