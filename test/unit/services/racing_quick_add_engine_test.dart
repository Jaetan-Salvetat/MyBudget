import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_engine.dart';
import 'package:mybudget/core/services/quick_add/racing_quick_add_engine.dart';

class _StubEngine implements QuickAddEngine {
  _StubEngine({this.result, this.error, this.delay = Duration.zero});

  final QuickAddClassification? result;
  final Object? error;
  final Duration delay;

  int calls = 0;

  @override
  Future<QuickAddClassification> classify(String input) async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final failure = error;
    if (failure != null) throw failure;
    return result!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryTaxonomyService taxonomy;
  late QuickAddClassification localResult;
  late QuickAddClassification remoteResult;

  QuickAddClassification classificationFor(String name, String slug) {
    return QuickAddClassification(
      type: TransactionType.expense,
      category: taxonomy.resolve(slug)!,
      frequency: Frequency.oneTime,
      date: DateTime(2026, 8, 20),
      amount: 25,
      name: name,
      typeConfidence: 1,
      categoryConfidence: 1,
      recurrenceConfidence: 1,
      cleanedText: 'resto italien',
    );
  }

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  setUp(() {
    localResult = classificationFor('Local', 'restauration.restaurant');
    remoteResult = classificationFor('Distant', 'restauration.restaurant');
  });

  group('RacingQuickAddEngine', () {
    test('prefers the remote answer when it lands in time', () async {
      final local = _StubEngine(result: localResult);
      final engine = RacingQuickAddEngine(
        local: local,
        remote: _StubEngine(result: remoteResult),
      );

      final classification = await engine.classify('resto italien 25');

      expect(classification.name, 'Distant');
      expect(local.calls, 1, reason: 'le local part quand même');
    });

    test('falls back on the local answer when the remote fails', () async {
      final engine = RacingQuickAddEngine(
        local: _StubEngine(result: localResult),
        remote: _StubEngine(
          error: const AiRequestException(AiRequestFailure.serviceUnavailable),
        ),
      );

      expect((await engine.classify('resto italien 25')).name, 'Local');
    });

    test('falls back on the local answer when the remote is late', () async {
      final engine = RacingQuickAddEngine(
        local: _StubEngine(result: localResult),
        remote: _StubEngine(
          result: remoteResult,
          delay: const Duration(milliseconds: 80),
        ),
        timeout: const Duration(milliseconds: 10),
      );

      expect((await engine.classify('resto italien 25')).name, 'Local');
    });

    test('reports the failure that made it fall back', () async {
      AiRequestFailure? reported;
      final engine = RacingQuickAddEngine(
        local: _StubEngine(result: localResult),
        remote: _StubEngine(
          result: remoteResult,
          delay: const Duration(milliseconds: 80),
        ),
        timeout: const Duration(milliseconds: 10),
        onRemoteFailure: (failure) => reported = failure,
      );

      await engine.classify('resto italien 25');

      expect(reported, AiRequestFailure.timeout);
    });

    test('reports a success so the failure count can reset', () async {
      var succeeded = false;
      final engine = RacingQuickAddEngine(
        local: _StubEngine(result: localResult),
        remote: _StubEngine(result: remoteResult),
        onRemoteSuccess: () => succeeded = true,
      );

      await engine.classify('resto italien 25');

      expect(succeeded, isTrue);
    });

    test('surfaces the local error when both engines fail', () async {
      final engine = RacingQuickAddEngine(
        local: _StubEngine(error: StateError('modèle absent')),
        remote: _StubEngine(
          error: const AiRequestException(AiRequestFailure.offline),
        ),
      );

      expect(
        () => engine.classify('resto italien 25'),
        throwsA(isA<StateError>()),
      );
    });

    test('does not leak an unhandled error when the remote wins', () async {
      final errors = <Object>[];
      final engine = RacingQuickAddEngine(
        local: _StubEngine(error: StateError('modèle absent')),
        remote: _StubEngine(result: remoteResult),
      );

      await runZonedGuarded(() async {
        expect((await engine.classify('resto italien 25')).name, 'Distant');
        await Future<void>.delayed(Duration.zero);
      }, (error, _) => errors.add(error));

      expect(errors, isEmpty);
    });
  });
}
