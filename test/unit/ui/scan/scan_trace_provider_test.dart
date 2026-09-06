import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import '../../../helpers/receipt_line_factory.dart';

RoleInference tagger(List<String> roles) =>
    (lines) => [
      for (final (index, _) in lines.indexed)
        [
          for (final name in roleNames)
            name == (index < roles.length ? roles[index] : 'noise') ? 1.0 : 0.0,
        ],
    ];

Future<List<ReadTrace>> someTrace() async {
  final outcome = await decideLocal(
    receiptLinesOf([
      [('PAIN', 0), ('2,00', 20)],
      [('TOTAL', 0), ('2,00', 20)],
    ]),
    tagger(const ['item', 'total']),
  );
  return outcome.trace;
}

void main() {
  test('la trace survit au scan qui l\'a produite', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(scanTraceProvider.notifier).record(await someTrace());
    await Future<void>.delayed(Duration.zero);

    expect(container.read(scanTraceProvider), hasLength(1));
  });

  test('un nouveau scan remplace la trace du précédent', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(scanTraceProvider.notifier).record(await someTrace());
    container.read(scanTraceProvider.notifier).record(const []);

    expect(container.read(scanTraceProvider), isEmpty);
  });
}
