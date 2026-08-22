import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';

/// Ce que sait faire un moteur d'ajout rapide : lire une saisie libre et en
/// sortir une transaction. Embarqué ou distant, le contrat est le même.
abstract interface class QuickAddEngine {
  Future<QuickAddClassification> classify(String input);
}
