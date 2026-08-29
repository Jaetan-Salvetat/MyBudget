import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Ce que la page fait d'une transaction qui vient d'être dite : le journal
/// lui ouvre un créneau, et la figure du mois attend cette ouverture pour
/// encaisser. Partie sur le tap, elle bougerait avant que la ligne existe, et
/// les deux n'auraient plus l'air d'avoir la même cause.
class QuickAddLandingController extends ChangeNotifier {
  /// Le temps que le créneau met à s'ouvrir. La figure part dessus.
  static const Duration figureDelay = Duration(milliseconds: 140);

  bool _holding = false;
  Timer? _opening;

  bool get holdsTheFigure => _holding;

  /// Le tap : l'écriture part, la figure ne doit plus bouger.
  void arm() {
    _opening?.cancel();
    _opening = null;
    if (_holding) return;

    _holding = true;
    notifyListeners();
  }

  /// La transaction est enregistrée : le journal lui ouvre sa place, la figure
  /// encaisse le temps que ce soit fait.
  void land() {
    _opening?.cancel();
    _opening = Timer(figureDelay, release);
  }

  /// La figure reprend ce que dit la base — le créneau est ouvert, ou il n'y a
  /// rien eu à enregistrer.
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

/// Donne l'atterrissage au champ qui l'amorce.
class QuickAddLanding extends InheritedNotifier<QuickAddLandingController> {
  const QuickAddLanding({
    required QuickAddLandingController super.notifier,
    required super.child,
    super.key,
  });

  static QuickAddLandingController? controllerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<QuickAddLanding>()?.notifier;
}
