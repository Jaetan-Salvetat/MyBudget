enum GeminiNanoPreference {
  fast(id: 'fast', label: 'Rapide'),
  full(id: 'full', label: 'Complet');

  const GeminiNanoPreference({required this.id, required this.label});

  final String id;
  final String label;

  static const GeminiNanoPreference quickAdd = fast;
  static const GeminiNanoPreference scan = full;

  static const GeminiNanoPreference fallback = fast;

  static GeminiNanoPreference fromId(String? id) {
    for (final preference in values) {
      if (preference.id == id) return preference;
    }
    return fallback;
  }
}
