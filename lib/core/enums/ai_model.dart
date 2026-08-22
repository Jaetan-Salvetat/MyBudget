import 'package:mybudget/core/enums/ai_provider.dart';

/// Les modèles qu'une clé personnelle peut adresser. Le choix est à
/// l'utilisateur : sa clé, sa facture, sa latence.
enum AiModel {
  flashLite35(
    id: 'gemini-3.5-flash-lite',
    provider: AiProvider.gemini,
    label: 'Gemini 3.5 Flash Lite',
    description: 'Le plus rapide et le moins cher. Suffit à l\'ajout rapide.',
  ),
  flash35(
    id: 'gemini-3.5-flash',
    provider: AiProvider.gemini,
    label: 'Gemini 3.5 Flash',
    description: 'Un cran au-dessus sur les saisies ambiguës.',
  ),
  flash36(
    id: 'gemini-3.6-flash',
    provider: AiProvider.gemini,
    label: 'Gemini 3.6 Flash',
    description: 'Génération précédente, équilibre vitesse et justesse.',
  ),
  flash37(
    id: 'gemini-3.7-flash',
    provider: AiProvider.gemini,
    label: 'Gemini 3.7 Flash',
    description: 'Le plus capable, et le plus lent des quatre.',
  );

  const AiModel({
    required this.id,
    required this.provider,
    required this.label,
    required this.description,
  });

  final String id;
  final AiProvider provider;
  final String label;
  final String description;

  /// Le moins cher et le plus rapide : l'ajout rapide passe avant la finesse,
  /// et c'est la clé de l'utilisateur qui paie.
  static const AiModel fallback = flashLite35;

  static List<AiModel> forProvider(AiProvider provider) {
    return values.where((model) => model.provider == provider).toList();
  }

  static AiModel defaultFor(AiProvider provider) {
    if (fallback.provider == provider) return fallback;
    return forProvider(provider).first;
  }

  static AiModel fromId(String? id) {
    for (final model in values) {
      if (model.id == id) return model;
    }
    return fallback;
  }
}
