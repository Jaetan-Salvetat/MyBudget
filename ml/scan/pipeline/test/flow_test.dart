import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

ExtractedReceipt receipt(List<double> amounts, double? total) {
  return ExtractedReceipt(
    store: null,
    date: null,
    total: total,
    subtotal: null,
    payment: null,
    items: [
      for (final (index, amount) in amounts.indexed)
        ExtractedItem(name: 'ART$index', amount: amount, discount: 0.0),
    ],
  );
}

List<(double, double)> amounts(FlowOutcome outcome) => [
  for (final item in outcome.items) (item.amount, item.discount),
];

const strict = FlowPolicy();

void main() {
  group('local stages', () {
    test('local checksum ok is verified', () {
      final outcome = decide(receipt([2.0, 3.0], 5.0), null, strict);
      expect(outcome.stage, FlowStage.local);
      expect(outcome.verified, isTrue);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
    });

    test('retry rescues failed first pass', () {
      final outcome = decide(
        receipt([2.0], 5.0),
        receipt([2.0, 3.0], 5.0),
        strict,
      );
      expect(outcome.stage, FlowStage.localRetry);
    });

    test('confirm prefills with retry when tried', () {
      final outcome = decide(
        receipt([2.0], 9.0),
        receipt([2.0, 3.0], 10.0),
        strict,
      );
      expect(outcome.stage, FlowStage.confirm);
      expect(outcome.verified, isFalse);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
    });

    test('confirm prefills with local without retry', () {
      final outcome = decide(receipt([2.0], 9.0), null, strict);
      expect(outcome.stage, FlowStage.confirm);
      expect(amounts(outcome), [(2.0, 0.0)]);
    });
  });

  group('retry value guard', () {
    const policy = FlowPolicy(retryMustNotLoseValue: true);

    test('retry losing value goes to confirm', () {
      final outcome = decide(
        receipt([7.05, 5.5, 9.9], 9.9),
        receipt([7.05, 5.5], 12.55),
        policy,
      );
      expect(outcome.stage, FlowStage.confirm);
    });

    test('retry with equal value still validates', () {
      final outcome = decide(
        receipt([2.0, 3.0], 6.0),
        receipt([2.0, 3.0], 5.0),
        policy,
      );
      expect(outcome.stage, FlowStage.localRetry);
    });

    test('guard off keeps previous behaviour', () {
      final outcome = decide(
        receipt([7.05, 5.5, 9.9], 9.9),
        receipt([7.05, 5.5], 12.55),
        strict,
      );
      expect(outcome.stage, FlowStage.localRetry);
    });
  });

  group('rescue', () {
    test('rescue is not consulted when rules verify', () {
      var called = false;
      decide(
        receipt([2.0], 2.0),
        null,
        strict,
        rescue: () {
          called = true;
          return null;
        },
      );
      expect(called, isFalse);
    });

    test('rescue outcome is used when rules fail', () {
      final outcome = decide(
        receipt([2.0], 9.0),
        null,
        strict,
        rescue: () => (FlowStage.localDp, receipt([2.0, 7.0], 9.0), const []),
      );
      expect(outcome.stage, FlowStage.localDp);
      expect(outcome.verified, isTrue);
      expect(amounts(outcome), [(2.0, 0.0), (7.0, 0.0)]);
    });

    test('rescue returning null falls through to confirm', () {
      final outcome = decide(
        receipt([2.0], 9.0),
        null,
        strict,
        rescue: () => null,
      );
      expect(outcome.stage, FlowStage.confirm);
    });
  });

  group('retry value guard', () {
    const guarded = FlowPolicy(retryMustNotLoseValue: true);

    test('retry losing a spurious item on the same total validates', () {
      final outcome = decide(
        receipt([5.0, 32.49, 137.11], 142.11),
        receipt([5.0, 137.11], 142.11),
        guarded,
      );
      expect(outcome.stage, FlowStage.localRetry);
    });

    test('retry losing value on a different total goes to confirm', () {
      final outcome = decide(
        receipt([7.05, 5.5, 9.9], 9.9),
        receipt([7.05, 5.5], 12.55),
        guarded,
      );
      expect(outcome.stage, FlowStage.confirm);
    });
  });

  group('verified total is displayed', () {
    test('payment verified receipt reports the payment as total', () {
      final local = ExtractedReceipt(
        store: null,
        date: null,
        total: 9.99,
        subtotal: null,
        payment: 5.0,
        items: [
          ExtractedItem(name: 'A', amount: 2.0, discount: 0.0),
          ExtractedItem(name: 'B', amount: 3.0, discount: 0.0),
        ],
        printedCount: 2,
      );
      final outcome = decide(local, null, strict);
      expect(outcome.stage, FlowStage.local);
      expect(outcome.total, 5.0);
    });

    test('confirm keeps the read total as prefill', () {
      final outcome = decide(receipt([2.0], 9.0), null, strict);
      expect(outcome.stage, FlowStage.confirm);
      expect(outcome.total, 9.0);
    });
  });

  group('stage names', () {
    test('fused stage serializes to the python name', () {
      expect(stageName(FlowStage.localFused), 'local_fused');
      expect(verifiedStages, contains(FlowStage.localFused));
    });
  });
}
