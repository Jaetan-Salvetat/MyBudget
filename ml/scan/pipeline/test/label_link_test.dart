library;

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

PhysicalLine line(String text) => PhysicalLine(
  words: [
    for (final token in text.split(' '))
      Word(text: token, left: 0, top: 0, right: 10, bottom: 10, confidence: null),
  ],
);

final lines = [
  line('PREM Litiere AGGLO 12KG'),
  line('16,99 EUR'),
  line('2200017 CITIZEN'),
];

List<List<double>> certain(List<PhysicalLine> source) => [
  for (final line in source) [for (final _ in line.words) 0.9],
];

void main() {
  test('le libellé vient de la ligne à la distance prédite', () {
    final items = [
      ExtractedItem(name: 'EUR', amount: 16.99, discount: 0, lineIndex: 1),
    ];
    expect(
      relabel(items, lines, [0, 1, 0], certain(lines)).single.name,
      'PREM Litiere AGGLO 12KG',
    );
  });

  test('le libellé prédit prime sur celui de la ligne du prix', () {
    final items = [
      ExtractedItem(
        name: '0,792 kg 2,65 EUR/kg',
        amount: 16.99,
        discount: 0,
        lineIndex: 1,
      ),
    ];
    expect(
      relabel(items, lines, [0, 1, 0], certain(lines)).single.name,
      'PREM Litiere AGGLO 12KG',
    );
  });

  test('une distance nulle fait découper la ligne du prix', () {
    final source = [line('583877 DIAMOND TAPIS 29,95')];
    final items = [
      ExtractedItem(
        name: '583877 DIAMOND TAPIS 29,95',
        amount: 29.95,
        discount: 0,
        lineIndex: 0,
      ),
    ];
    expect(
      relabel(items, source, [0], [
        [0.1, 0.9, 0.9, 0.02],
      ]).single.name,
      'DIAMOND TAPIS',
    );
  });

  test('une ligne de libellé ne sert qu\'une fois', () {
    final twoPrices = [line('PAIN COMPLET'), line('2,50 EUR'), line('1,20 EUR')];
    final items = [
      ExtractedItem(name: 'EUR', amount: 2.50, discount: 0, lineIndex: 1),
      ExtractedItem(name: 'EUR', amount: 1.20, discount: 0, lineIndex: 2),
    ];
    final relabelled = relabel(items, twoPrices, [0, 1, 2], certain(twoPrices));
    expect(relabelled.first.name, 'PAIN COMPLET');
    expect(relabelled.last.name, 'EUR');
  });

  test('la ligne du prix appartient à son article', () {
    final source = [line('PAIN COMPLET 2,50'), line('BRIOCHE 1,20')];
    final items = [
      ExtractedItem(name: 'x', amount: 2.50, discount: 0, lineIndex: 0),
      ExtractedItem(name: 'x', amount: 1.20, discount: 0, lineIndex: 1),
    ];
    final relabelled = relabel(items, source, [0, 0], [
      [0.9, 0.9, 0.01],
      [0.9, 0.01],
    ]);
    expect(relabelled.first.name, 'PAIN COMPLET');
    expect(relabelled.last.name, 'BRIOCHE');
  });

  test('une ligne qui ne nomme rien n\'est pas rattachée', () {
    final noName = [line('*'), line('2,50 EUR')];
    final items = [
      ExtractedItem(name: 'EUR', amount: 2.50, discount: 0, lineIndex: 1),
    ];
    expect(relabel(items, noName, [0, 1], certain(noName)).single.name, 'EUR');
  });

  test('une distance qui sort du ticket ne change rien', () {
    final items = [
      ExtractedItem(name: 'EUR', amount: 16.99, discount: 0, lineIndex: 0),
    ];
    expect(relabel(items, lines, [2, 0, 0], certain(lines)).single.name, 'EUR');
  });

  test('un article sans ligne source est ignoré', () {
    final items = [ExtractedItem(name: 'EUR', amount: 16.99, discount: 0)];
    expect(relabel(items, lines, [0, 1, 0], certain(lines)).single.name, 'EUR');
  });

  test('sans prédiction rien ne bouge', () {
    final items = [
      ExtractedItem(name: 'EUR', amount: 16.99, discount: 0, lineIndex: 1),
    ];
    expect(relabel(items, lines, const [], certain(lines)).single.name, 'EUR');
  });
}
