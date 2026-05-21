import 'package:flutter_litert_lm/flutter_litert_lm.dart';

class LitertEngineService {
  late LiteLmEngine _engine;

  static LitertEngineService? _instance;

  LitertEngineService._();

  static Future<LitertEngineService> getInstance(
    String modelPath,
    LiteLmBackend backend,
  ) async {
    if (_instance == null) {
      _instance = LitertEngineService._();
      await _instance!._init(modelPath, backend);
    }
    return _instance!;
  }

  Future<void> _init(String modelPath, LiteLmBackend backend) async {
    try {
      _engine = await LiteLmEngine.create(
        LiteLmEngineConfig(modelPath: modelPath, backend: backend),
      );
    } catch (e) {
      _instance = null;
      rethrow;
    }
  }

  LiteLmEngine get engine => _engine;

  bool get isInitialized => _instance != null;

  Future<void> dispose() async {
    await _engine.dispose();
    _instance = null;
  }

  static Future<void> resetInstance() async {
    if (_instance != null) {
      await _instance!.dispose();
    }
  }
}
