enum FeatureStage {
  experimental(id: 'experimental', label: 'Expérimental'),
  beta(id: 'beta', label: 'Bêta');

  const FeatureStage({required this.id, required this.label});

  final String id;
  final String label;

  static const FeatureStage fallback = experimental;

  static FeatureStage fromId(String? id) {
    for (final stage in values) {
      if (stage.id == id) return stage;
    }
    return fallback;
  }
}
