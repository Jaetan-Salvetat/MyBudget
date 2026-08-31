import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';

final class GeminiNanoUnavailableEngine implements QuickAddEngine {
  const GeminiNanoUnavailableEngine(this.failure);

  GeminiNanoUnavailableEngine.forStatus(GeminiNanoStatus status)
    : failure = status == GeminiNanoStatus.unavailable
          ? GeminiNanoFailure.unavailable
          : GeminiNanoFailure.notInstalled;

  final GeminiNanoFailure failure;

  @override
  Future<QuickAddClassification> classify(String input) =>
      Future<QuickAddClassification>.error(GeminiNanoException(failure));
}
