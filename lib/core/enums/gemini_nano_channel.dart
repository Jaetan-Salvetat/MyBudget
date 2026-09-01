enum GeminiNanoChannel {
  stable(
    id: 'stable',
    label: 'Stable',
    description: 'Le modèle publié, celui de tout le monde.',
  ),
  preview(
    id: 'preview',
    label: 'Préversion',
    description:
        'Le prochain modèle, réservé aux appareils inscrits au programme '
        'de test AICore.',
  );

  const GeminiNanoChannel({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;

  static const GeminiNanoChannel fallback = stable;

  static GeminiNanoChannel fromId(String? id) {
    for (final channel in values) {
      if (channel.id == id) return channel;
    }
    return fallback;
  }
}
