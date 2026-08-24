import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

ExtractedReceipt receipt(
  List<double> amounts,
  double? total, {
  double? payment,
}) {
  return ExtractedReceipt(
    store: null,
    date: null,
    total: total,
    subtotal: null,
    payment: payment,
    items: [
      for (final (index, amount) in amounts.indexed)
        ExtractedItem(name: 'ART$index', amount: amount, discount: 0.0),
    ],
  );
}

CloudReceipt cloud(List<(double, double)> items, double? total) {
  return CloudReceipt(
    items: [
      for (final (index, (amount, discount)) in items.indexed)
        ExtractedItem(name: 'CLOUD$index', amount: amount, discount: discount),
    ],
    total: total,
  );
}

List<(double, double)> amounts(FlowOutcome outcome) =>
    [for (final item in outcome.items) (item.amount, item.discount)];

const strict = FlowPolicy();

void main() {
  group('local stages', () {
    test('local checksum ok validates directly', () {
      final outcome = decide(receipt([2.0, 3.0], 5.0), null, null, strict);
      expect(outcome.stage, FlowStage.local);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
    });

    test('retry rescues failed first pass', () {
      final outcome = decide(
        receipt([2.0], 5.0),
        receipt([2.0, 3.0], 5.0),
        null,
        strict,
      );
      expect(outcome.stage, FlowStage.localRetry);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
    });

    test('local ok wins over everything', () {
      final outcome = decide(
        receipt([5.0], 5.0),
        receipt([1.0, 4.0], 5.0),
        cloud([(9.0, 0.0)], 9.0),
        strict,
      );
      expect(outcome.stage, FlowStage.local);
    });
  });

  group('cloud escalation', () {
    test('cloud accepted when sum matches cloud total', () {
      final outcome = decide(
        receipt([2.0], 5.0),
        null,
        cloud([(2.0, 0.0), (3.0, 0.0)], 5.0),
        strict,
      );
      expect(outcome.stage, FlowStage.cloud);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
      expect(outcome.total, 5.0);
    });

    test('cloud discounts count in checksum', () {
      final outcome = decide(
        receipt([2.0], 5.0),
        null,
        cloud([(3.0, 1.0), (3.0, 0.0)], 5.0),
        strict,
      );
      expect(outcome.stage, FlowStage.cloud);
    });

    test('cloud rejected when sum diverges', () {
      final outcome = decide(
        receipt([2.0], 5.0),
        null,
        cloud([(2.0, 0.0)], 5.0),
        strict,
      );
      expect(outcome.stage, FlowStage.confirm);
    });

    test('cloud rejected without total', () {
      final outcome = decide(
        receipt([2.0], 5.0),
        null,
        cloud([(2.0, 0.0)], null),
        strict,
      );
      expect(outcome.stage, FlowStage.confirm);
    });

    test('tolerance absorbs rounding gap', () {
      const policy = FlowPolicy(tolerance: 0.02);
      final outcome = decide(
        receipt([2.0], 5.0),
        null,
        cloud([(2.0, 0.0), (3.01, 0.0)], 5.0),
        policy,
      );
      expect(outcome.stage, FlowStage.cloud);
    });

    test('strict rejects rounding gap', () {
      final outcome = decide(
        receipt([2.0], 5.0),
        null,
        cloud([(2.0, 0.0), (3.01, 0.0)], 5.0),
        strict,
      );
      expect(outcome.stage, FlowStage.confirm);
    });
  });

  group('cross check', () {
    const policy = FlowPolicy(crossCheckLocalTotal: true);

    test('cloud rejected when totals disagree', () {
      final outcome = decide(
        receipt([2.0], 21.0),
        null,
        cloud([(20.0, 0.0)], 20.0),
        policy,
      );
      expect(outcome.stage, FlowStage.confirm);
    });

    test('cloud accepted when totals agree', () {
      final outcome = decide(
        receipt([2.0], 20.0),
        null,
        cloud([(20.0, 0.0)], 20.0),
        policy,
      );
      expect(outcome.stage, FlowStage.cloud);
    });

    test('cloud accepted when no local total', () {
      final outcome = decide(
        receipt([2.0], null),
        null,
        cloud([(20.0, 0.0)], 20.0),
        policy,
      );
      expect(outcome.stage, FlowStage.cloud);
    });

    test('retry total serves as reference', () {
      final outcome = decide(
        receipt([2.0], null),
        receipt([2.0], 21.0),
        cloud([(20.0, 0.0)], 20.0),
        policy,
      );
      expect(outcome.stage, FlowStage.confirm);
    });
  });

  group('confirm prefill', () {
    test('prefill cloud by default', () {
      final outcome = decide(
        receipt([2.0], 5.0),
        null,
        cloud([(9.0, 0.0)], 8.0),
        strict,
      );
      expect(outcome.stage, FlowStage.confirm);
      expect(amounts(outcome), [(9.0, 0.0)]);
    });

    test('prefill local when policy says so', () {
      const policy = FlowPolicy(confirmPrefill: ConfirmPrefill.local);
      final outcome = decide(
        receipt([2.0], 5.0),
        null,
        cloud([(9.0, 0.0)], 8.0),
        policy,
      );
      expect(amounts(outcome), [(2.0, 0.0)]);
    });

    test('prefill falls back to retry without cloud', () {
      final outcome = decide(
        receipt([2.0], 9.0),
        receipt([2.0, 3.0], 10.0),
        null,
        strict,
      );
      expect(outcome.stage, FlowStage.confirm);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
    });

    test('prefill falls back to local without retry', () {
      final outcome = decide(receipt([2.0], 9.0), null, null, strict);
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
        null,
        policy,
      );
      expect(outcome.stage, FlowStage.confirm);
    });

    test('retry with equal value still validates', () {
      final outcome = decide(
        receipt([2.0, 3.0], 6.0),
        receipt([2.0, 3.0], 5.0),
        null,
        policy,
      );
      expect(outcome.stage, FlowStage.localRetry);
    });

    test('retry gaining items still validates', () {
      final outcome = decide(
        receipt([2.0], 5.0),
        receipt([2.0, 3.0], 5.0),
        null,
        policy,
      );
      expect(outcome.stage, FlowStage.localRetry);
    });

    test('guard off keeps previous behaviour', () {
      final outcome = decide(
        receipt([7.05, 5.5, 9.9], 9.9),
        receipt([7.05, 5.5], 12.55),
        null,
        strict,
      );
      expect(outcome.stage, FlowStage.localRetry);
    });
  });
}
