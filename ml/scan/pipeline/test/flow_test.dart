import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Un tagger de rôles parfait : chaque ligne reçoit le rôle qu'on lui donne,
/// à probabilité 1. Le flow ne connaît que cette signature, donc sa politique
/// de lecture se teste sans embarquer de modèle.
RoleInference tagger(List<String> roles) => (lines) => [
  for (final (index, _) in lines.indexed)
    [
      for (final name in roleNames)
        name == (index < roles.length ? roles[index] : 'noise') ? 1.0 : 0.0,
    ],
];

const List<String> itemItemTotal = ['item', 'item', 'total'];

List<PhysicalLine> receipt(String first, String second, String total) =>
    receiptLines([
      [('PAIN', 0), (first, 20)],
      [('LAIT', 0), (second, 20)],
      [('TOTAL', 0), (total, 20)],
    ]);

List<(double, double)> amounts(LocalOutcome outcome) => [
  for (final item in outcome.items) (item.amount, item.discount),
];

void main() {
  group('la passe 1 suffit', () {
    test('une somme prouvée est vérifiée', () async {
      final outcome = await decideLocal(
        receipt('2,00', '3,00', '5,00'),
        tagger(itemItemTotal),
      );
      expect(outcome.source, ReadSource.pass1);
      expect(outcome.verified, isTrue);
      expect(outcome.total, 5.0);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
    });

    test('la seconde lecture n\'est pas demandée', () async {
      var asked = false;
      await decideLocal(
        receipt('2,00', '3,00', '5,00'),
        tagger(itemItemTotal),
        secondPass: () async {
          asked = true;
          return receipt('2,00', '3,00', '5,00');
        },
      );
      expect(asked, isFalse);
    });
  });

  group('escalade', () {
    test('le retry rattrape une passe 1 qui ne prouve rien', () async {
      final outcome = await decideLocal(
        receipt('2,00', '3,00', '9,00'),
        tagger(itemItemTotal),
        secondPass: () async => receipt('2,00', '3,00', '5,00'),
      );
      expect(outcome.source, ReadSource.retry);
      expect(outcome.verified, isTrue);
      expect(outcome.total, 5.0);
    });

    test('la fusion rattrape ce qu\'aucune passe ne prouve seule', () async {
      final outcome = await decideLocal(
        receipt('2,00', '3,OO', '5,00'),
        tagger(itemItemTotal),
        secondPass: () async => receipt('2,OO', '3,00', '5,00'),
      );
      expect(outcome.source, ReadSource.fused);
      expect(outcome.verified, isTrue);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
    });
  });

  group('rien ne prouve la somme', () {
    test('sans seconde lecture, la passe 1 pré-remplit la confirmation',
        () async {
      final outcome = await decideLocal(
        receipt('2,00', '3,00', '9,00'),
        tagger(itemItemTotal),
      );
      expect(outcome.source, ReadSource.confirm);
      expect(outcome.verified, isFalse);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
      expect(outcome.total, 9.0);
    });

    test('une seconde lecture impossible ne fait pas perdre la première',
        () async {
      final outcome = await decideLocal(
        receipt('2,00', '3,00', '9,00'),
        tagger(itemItemTotal),
        secondPass: () async => null,
      );
      expect(outcome.source, ReadSource.confirm);
      expect(amounts(outcome), [(2.0, 0.0), (3.0, 0.0)]);
    });

    test('la confirmation part de la dernière lecture', () async {
      final outcome = await decideLocal(
        receipt('2,00', '3,00', '9,00'),
        tagger(itemItemTotal),
        secondPass: () async => receipt('2,00', '4,00', '9,00'),
      );
      expect(outcome.source, ReadSource.confirm);
      expect(outcome.verified, isFalse);
    });
  });

  test('les rôles retenus sont ceux de la lecture retenue', () async {
    final outcome = await decideLocal(
      receipt('2,00', '3,00', '5,00'),
      tagger(itemItemTotal),
    );
    expect(outcome.lines.length, 3);
    expect(predictedRoles(outcome.roles), itemItemTotal);
  });

  test('les noms de lecture sont le contrat Python', () {
    expect(sourceName(ReadSource.pass1), 'passe1');
    expect(sourceName(ReadSource.retry), 'retry');
    expect(sourceName(ReadSource.fused), 'fusion');
    expect(sourceName(ReadSource.confirm), 'confirm');
  });
}
