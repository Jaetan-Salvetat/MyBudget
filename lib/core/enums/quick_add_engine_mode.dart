enum QuickAddEngineMode {
  geminiNano(
    id: 'geminiNano',
    label: 'Gemini Nano',
    isRecommended: true,
  ),
  onDevice(id: 'onDevice', label: 'Sur l\'appareil'),
  apiKey(id: 'apiKey', label: 'Clé personnelle');

  const QuickAddEngineMode({
    required this.id,
    required this.label,
    this.isRecommended = false,
  });

  final String id;
  final String label;
  final bool isRecommended;

  static const QuickAddEngineMode fallback = onDevice;

  static QuickAddEngineMode fromId(String? id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return fallback;
  }
}
