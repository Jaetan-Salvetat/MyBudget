import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/scan/screens/scan_trace_report.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import '../../../helpers/receipt_line_factory.dart';

/// Un tagger parfait : chaque ligne reçoit le rôle qu'on lui donne.
RoleInference tagger(List<String> roles) =>
    (lines) => [
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

Future<String> reportOf(String total, {bool secondPass = false}) async {
  final outcome = await decideLocal(
    receipt(total),
    tagger(const ['item', 'item', 'total']),
    secondPass: secondPass ? () async => receipt(total) : null,
  );
  return scanTraceReport(outcome.trace);
}

void main() {
  test('sans lecture, le rapport le dit', () {
    expect(scanTraceReport(const []), contains('aucune lecture'));
  });

  test('chaque ligne porte le préfixe, pour être isolable d\'un log', () async {
    final report = await reportOf('5,00');
    expect(
      report.split('\n'),
      everyElement(predicate<String>((line) => line.startsWith(reportTag))),
    );
  });

  test('une somme prouvée annonce sa référence', () async {
    final report = await reportOf('5,00');
    expect(report, contains('somme prouvée'));
    expect(report, contains('référence 5.00'));
  });

  test('une somme non prouvée le dit sans inventer d\'hypothèse', () async {
    final report = await reportOf('9,00');
    expect(report, contains('somme NON prouvée'));
    expect(report, contains('aucune hypothèse'));
  });

  test('chaque lecture tentée a sa section', () async {
    final report = await reportOf('9,00', secondPass: true);
    expect(report, contains('=== passe1'));
    expect(report, contains('=== retry'));
    expect(report, contains('=== fusion'));
  });

  test('une ligne chiffrée porte ses candidats et son étiquette', () async {
    final report = await reportOf('5,00');
    expect(report, contains('candidats 2.00'));
    expect(report, contains('décodé article 2.00'));
    expect(report, contains('décodé total'));
  });

  test('une ligne sans montant n\'annonce ni candidat ni étiquette', () async {
    final outcome = await decideLocal(
      receiptLinesOf([
        [('MERCI', 0)],
        [('PAIN', 0), ('2,00', 20)],
        [('TOTAL', 0), ('2,00', 20)],
      ]),
      tagger(const ['noise', 'item', 'total']),
    );
    final merci = scanTraceReport(
      outcome.trace,
    ).split('\n').firstWhere((line) => line.contains('MERCI'));
    expect(merci, isNot(contains('candidats')));
  });

  test('le texte de la ligne est rendu tel quel, pour le rejouer', () async {
    final report = await reportOf('5,00');
    expect(report, contains('PAIN 2,00'));
    expect(report, contains('LAIT 3,00'));
  });

  group('mots exportés', () {
    Future<Map<String, dynamic>> wordsOf(String total) async {
      final outcome = await decideLocal(
        receipt(total),
        tagger(const ['item', 'item', 'total']),
        secondPass: () async => receipt(total),
      );
      return jsonDecode(scanTraceWords(outcome.trace)) as Map<String, dynamic>;
    }

    test('chaque lecture tentée porte ses mots', () async {
      final reads = (await wordsOf('9,00'))['reads'] as List;
      expect(
        [for (final read in reads) (read as Map)['source']],
        ['passe1', 'retry', 'fusion'],
      );
    });

    test('un mot porte sa boîte, de quoi rejouer le regroupement', () async {
      final reads = (await wordsOf('5,00'))['reads'] as List;
      final words = ((reads.first as Map)['words'] as List).cast<Map>();
      expect(words.first['text'], 'PAIN');
      expect((words.first['box'] as List), hasLength(4));
      expect(words.first['confidence'], isNotNull);
    });

    test(
      'tous les mots du ticket sont là, pas seulement les chiffrés',
      () async {
        final reads = (await wordsOf('5,00'))['reads'] as List;
        final words = ((reads.first as Map)['words'] as List).cast<Map>();
        expect(
          [for (final word in words) word['text']],
          ['PAIN', '2,00', 'LAIT', '3,00', 'TOTAL', '5,00'],
        );
      },
    );

    test('sans lecture, il n\'y a rien à rejouer', () {
      final payload = jsonDecode(scanTraceWords(const [])) as Map;
      expect(payload['reads'], isEmpty);
    });
  });
}
