import 'package:flutter/widgets.dart';

class FrostedGlassSuspension extends InheritedWidget {
  const FrostedGlassSuspension({
    required this.suspended,
    required super.child,
    super.key,
  });

  final bool suspended;

  static bool of(BuildContext context) {
    final FrostedGlassSuspension? scope = context
        .dependOnInheritedWidgetOfExactType<FrostedGlassSuspension>();
    return scope?.suspended ?? false;
  }

  @override
  bool updateShouldNotify(FrostedGlassSuspension oldWidget) =>
      oldWidget.suspended != suspended;
}
