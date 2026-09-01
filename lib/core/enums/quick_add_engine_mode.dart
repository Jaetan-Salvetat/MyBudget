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
