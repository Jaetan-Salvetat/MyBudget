import 'package:flutter/widgets.dart';

/// Marks a subtree as being rasterized into a layer of its own — an opacity
/// fade, a snapshot, a shader mask.
///
/// A backdrop filter samples the layer it is composited into, so glass caught
/// inside such a layer would blur an empty buffer and collapse into a flat
/// slab of its own veil. [FrostedGlass] therefore suspends its blur for as
/// long as an ancestor announces the isolation, and takes it back the moment
/// the subtree paints straight onto the page again.
///
/// Wrap the rasterizing widget, not the glass: whoever creates the layer is
/// the one that knows it exists.
class FrostedGlassSuspension extends InheritedWidget {
  const FrostedGlassSuspension({
    required this.suspended,
    required super.child,
    super.key,
  });

  /// Whether the subtree currently paints into an isolated layer.
  final bool suspended;

  /// Whether glass built under [context] must hold back its backdrop.
  static bool of(BuildContext context) {
    final FrostedGlassSuspension? scope = context
        .dependOnInheritedWidgetOfExactType<FrostedGlassSuspension>();
    return scope?.suspended ?? false;
  }

  @override
  bool updateShouldNotify(FrostedGlassSuspension oldWidget) =>
      oldWidget.suspended != suspended;
}
