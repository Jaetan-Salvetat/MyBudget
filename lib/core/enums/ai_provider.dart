/// Un service externe compatible OpenAI que l'utilisateur branche avec sa
/// propre clé. Le nom du fournisseur ne sort jamais de l'écran qui le liste.
enum AiProvider {
  gemini(
    id: 'gemini',
    label: 'Google Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    model: 'gemini-2.0-flash-lite',
    keyPattern: r'^AIza[0-9A-Za-z_-]{35}$',
    keyFormatHint: 'Une clé Google AI commence par AIza et fait 39 caractères.',
    keyPlaceholder: 'AIza…',
    consoleLabel: 'Google AI Studio',
    consoleUrl: 'https://aistudio.google.com/apikey',
  );

  const AiProvider({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.model,
    required this.keyPattern,
    required this.keyFormatHint,
    required this.keyPlaceholder,
    required this.consoleLabel,
    required this.consoleUrl,
  });

  final String id;
  final String label;
  final String baseUrl;
  final String model;
  final String keyPattern;
  final String keyFormatHint;
  final String keyPlaceholder;
  final String consoleLabel;
  final String consoleUrl;

  /// Préfixes des fournisseurs concurrents, du plus spécifique au plus large :
  /// une clé collée depuis le mauvais service est refusée sans appel réseau.
  static const Map<String, String> foreignKeyPrefixes = {
    'sk-ant-': 'Anthropic',
    'sk-proj-': 'OpenAI',
    'sk-': 'OpenAI',
    'gsk_': 'Groq',
    'hf_': 'Hugging Face',
    'r8_': 'Replicate',
    'xai-': 'xAI',
  };

  static const AiProvider fallback = gemini;

  bool matchesKeyFormat(String key) => RegExp(keyPattern).hasMatch(key);

  static AiProvider fromId(String? id) {
    for (final provider in values) {
      if (provider.id == id) return provider;
    }
    return fallback;
  }

  /// Le fournisseur d'où vient la clé quand ce n'est manifestement pas celui-ci.
  static String? foreignVendorOf(String key) {
    for (final entry in foreignKeyPrefixes.entries) {
      if (key.startsWith(entry.key)) return entry.value;
    }
    return null;
  }
}
