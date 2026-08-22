/// Le moteur qui lit la saisie de l'ajout rapide. Seul ce choix est persisté :
/// « clé saisie mais pas encore vérifiée » n'est pas un état durable.
enum QuickAddEngineMode {
  onDevice(id: 'onDevice', label: 'Sur l\'appareil'),
  apiKey(id: 'apiKey', label: 'Clé personnelle');

  const QuickAddEngineMode({required this.id, required this.label});

  final String id;
  final String label;

  static const QuickAddEngineMode fallback = onDevice;

  static QuickAddEngineMode fromId(String? id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return fallback;
  }
}
