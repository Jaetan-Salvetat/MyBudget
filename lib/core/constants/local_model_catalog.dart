class LocalModelConfig {
  final String id;
  final String displayName;
  final String description;
  final String url;
  final String filename;
  final double sizeGb;
  final double requiredSpaceGb;
  final String version;

  const LocalModelConfig({
    required this.id,
    required this.displayName,
    required this.description,
    required this.url,
    required this.filename,
    required this.sizeGb,
    required this.requiredSpaceGb,
    required this.version,
  });

  String get taskGroup => 'model_$id';
}

abstract final class LocalModelCatalog {
  static const gemma4E2B = LocalModelConfig(
    id: 'gemma-4-e2b',
    displayName: 'Gemma 4 E2B',
    description: 'Léger · 2.6 Go',
    url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    filename: 'gemma-4-E2B-it.litertlm',
    sizeGb: 2.59,
    requiredSpaceGb: 3.0,
    version: '1.0.0',
  );

  static const gemma4E4B = LocalModelConfig(
    id: 'gemma-4-e4b',
    displayName: 'Gemma 4 E4B',
    description: 'Équilibré · 3.7 Go',
    url: 'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
    filename: 'gemma-4-E4B-it.litertlm',
    sizeGb: 3.66,
    requiredSpaceGb: 4.2,
    version: '1.0.0',
  );

  static const gemma3nE4B = LocalModelConfig(
    id: 'gemma-3n-e4b',
    displayName: 'Gemma 3n E4B',
    description: 'Rapide · 4.9 Go',
    url: 'https://huggingface.co/On-device/gemma-3n-E4B-it-litert-lm/resolve/main/gemma-3n-E4B-it-int4.litertlm',
    filename: 'gemma-3n-E4B-it-int4.litertlm',
    sizeGb: 4.92,
    requiredSpaceGb: 5.5,
    version: '1.0.0',
  );

  static const List<LocalModelConfig> models = [
    gemma3nE4B,
    gemma4E4B,
    gemma4E2B,
  ];

  static LocalModelConfig? getById(String id) {
    for (final model in models) {
      if (model.id == id) return model;
    }
    return null;
  }
}
