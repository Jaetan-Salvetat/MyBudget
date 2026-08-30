import 'dart:async';

import 'package:material_ui/material_ui.dart';

class QuickAddLandingController extends ChangeNotifier {
  static const Duration figureDelay = Duration(milliseconds: 140);

  bool _holding = false;
  Timer? _opening;

  bool get holdsTheFigure => _holding;

  void arm() {
    _opening?.cancel();
    _opening = null;
    if (_holding) return;

    _holding = true;
    notifyListeners();
  }

  void land() {
    _opening?.cancel();
    _opening = Timer(figureDelay, release);
  }

  void release() {
    _opening?.cancel();
    _opening = null;
    if (!_holding) return;

    _holding = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _opening?.cancel();
    super.dispose();
  }
}

class QuickAddLanding extends InheritedNotifier<QuickAddLandingController> {
  const QuickAddLanding({
    required QuickAddLandingController super.notifier,
    required super.child,
    super.key,
  });

  static QuickAddLandingController? controllerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<QuickAddLanding>()?.notifier;
}
