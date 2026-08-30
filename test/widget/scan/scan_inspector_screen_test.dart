import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:mybudget/ui/scan/screens/scan_inspector_screen.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import '../../helpers/receipt_line_factory.dart';

RoleInference tagger(List<String> roles) => (lines) => [
  for (final (index, _) in lines.indexed)
    [
      for (final name in roleNames)
        name == (index < roles.length ? roles[index] : 'noise') ? 1.0 : 0.0,
    ],
];

List<PhysicalLine> receipt(String total) => receiptLinesOf([
  [('PAIN', 0), ('2,00', 20)],
  [('LAIT', 0), ('3,00', 20)],
  [('TOTAL', 0), (total, 20)],
]);

Future<List<ReadTrace>> traceOfReceipt(String total) async {
  final outcome = await decideLocal(
    receipt(total),
    tagger(const ['item', 'item', 'total']),
    secondPass: () async => receipt(total),
  );
  return outcome.trace;
}

Future<void> pump(WidgetTester tester, List<ReadTrace> trace) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [scanTraceProvider.overrideWith(() => _StubTrace(trace))],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const ScanInspectorScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _StubTrace extends ScanTrace {
  _StubTrace(this._trace);

  final List<ReadTrace> _trace;

  @override
  List<ReadTrace> build() => _trace;
}

void main() {
  testWidgets('sans lecture, l\'inspecteur le dit', (tester) async {
    await pump(tester, const []);
    expect(find.text('Aucune lecture à inspecter'), findsOneWidget);
  });

  testWidgets('une lecture prouvée montre ses trois étages', (tester) async {
    await pump(tester, await traceOfReceipt('5,00'));

    expect(find.text('passe1'), findsOneWidget);
    expect(find.textContaining('somme prouvée'), findsOneWidget);
    expect(find.text('1 · OCR'), findsOneWidget);
    expect(find.text('2 · Tagger de rôles'), findsOneWidget);
    expect(find.text('3 · Décodeur'), findsOneWidget);
  });

  testWidgets('chaque lecture tentée a sa carte', (tester) async {
    await pump(tester, await traceOfReceipt('9,00'));

    expect(find.text('passe1'), findsOneWidget);
    expect(find.text('retry'), findsOneWidget);
    expect(find.text('fusion'), findsOneWidget);
    expect(find.textContaining('somme non prouvée'), findsNWidgets(3));
  });

  testWidgets('l\'étage OCR montre les lignes lues', (tester) async {
    await pump(tester, await traceOfReceipt('5,00'));
    await tester.tap(find.text('1 · OCR'));
    await tester.pumpAndSettle();

    expect(find.text('PAIN 2,00'), findsOneWidget);
    expect(find.text('LAIT 3,00'), findsOneWidget);
    expect(find.textContaining('2 mots'), findsNWidgets(3));
  });

  testWidgets('l\'étage des rôles montre le rôle retenu par ligne', (
    tester,
  ) async {
    await pump(tester, await traceOfReceipt('5,00'));
    await tester.tap(find.text('2 · Tagger de rôles'));
    await tester.pumpAndSettle();

    expect(find.text('item'), findsNWidgets(2));
    expect(find.text('total'), findsOneWidget);
  });

  testWidgets('l\'étage du décodeur montre candidats et étiquette', (
    tester,
  ) async {
    await pump(tester, await traceOfReceipt('5,00'));
    await tester.tap(find.text('3 · Décodeur'));
    await tester.pumpAndSettle();

    expect(find.text('article'), findsNWidgets(2));
    expect(find.textContaining('candidats 2.00 €'), findsOneWidget);
    expect(find.textContaining('lecture lâche autorisée'), findsNWidgets(3));
  });
}
