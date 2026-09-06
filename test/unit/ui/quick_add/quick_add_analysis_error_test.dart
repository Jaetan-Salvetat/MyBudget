import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';

class _FailingEngine implements QuickAddEngine {
  const _FailingEngine(this.error);

  final Object error;

  @override
  Future<QuickAddClassification> classify(String input) async => throw error;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String?> errorAfterTyping(Object error) async {
    final container = ProviderContainer(
      overrides: [
        quickAddEngineProvider.overrideWith(
          (ref) async => _FailingEngine(error),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(quickAddProvider, (_, _) {});

    container.read(quickAddProvider.notifier).onInputChanged('café 3€');
    await Future<void>.delayed(
      QuickAddNotifier.analysisDebounce + const Duration(milliseconds: 100),
    );

    return container.read(quickAddProvider).analysisError;
  }

  group('QuickAddNotifier analyse en échec', () {
    test('une clé refusée le dit à l\'utilisateur', () async {
      expect(
        await errorAfterTyping(
          const AiRequestException(AiRequestFailure.invalidKey),
        ),
        AiRequestFailure.invalidKey.label,
      );
    });

    test('une coupure réseau le dit à l\'utilisateur', () async {
      expect(
        await errorAfterTyping(
          const AiRequestException(AiRequestFailure.offline),
        ),
        AiRequestFailure.offline.label,
      );
    });

    test('un moteur indisponible porte son propre message', () async {
      expect(
        await errorAfterTyping(
          const QuickAddEngineUnavailableException(
            message: 'Aucune clé API enregistrée',
          ),
        ),
        'Aucune clé API enregistrée',
      );
    });

    test('une panne sans cause connue garde le message générique', () async {
      expect(
        await errorAfterTyping(StateError('boum')),
        QuickAddNotifier.unreadInputMessage,
      );
    });
  });
}
