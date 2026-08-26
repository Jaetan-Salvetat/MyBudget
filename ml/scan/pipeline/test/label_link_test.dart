/// Le rattachement du libellé, décidé par le modèle de lien.
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

void main() {
  test('le libellé vient de la ligne à la distance prédite', () {
    final items = [
      ExtractedItem(name: 'EUR', amount: 16.99, discount: 0, lineIndex: 1),
    ];
    expect(
      relabel(items, lines, [0, 1, 0]).single.name,
      'PREM Litiere AGGLO 12KG',
    );
  });

  test('le libellé prédit prime sur celui des règles', () {
    final items = [
      ExtractedItem(
        name: '0,792 kg 2,65 EUR/kg',
        amount: 16.99,
        discount: 0,
        lineIndex: 1,
      ),
    ];
    expect(
      relabel(items, lines, [0, 1, 0]).single.name,
      'PREM Litiere AGGLO 12KG',
    );
  });

  test('une distance nulle laisse le libellé des règles', () {
    final items = [
      ExtractedItem(
        name: 'BAGUETTE 125G',
        amount: 16.99,
        discount: 0,
        lineIndex: 1,
      ),
    ];
    expect(relabel(items, lines, [0, 0, 0]).single.name, 'BAGUETTE 125G');
  });

  test('une ligne de libellé ne sert qu\'une fois', () {
    final twoPrices = [line('PAIN COMPLET'), line('2,50 EUR'), line('1,20 EUR')];
    final items = [
      ExtractedItem(name: 'EUR', amount: 2.50, discount: 0, lineIndex: 1),
      ExtractedItem(name: 'EUR', amount: 1.20, discount: 0, lineIndex: 2),
    ];
    final relabelled = relabel(items, twoPrices, [0, 1, 2]);
    expect(relabelled.first.name, 'PAIN COMPLET');
    expect(relabelled.last.name, 'EUR');
  });

  test('une ligne qui ne nomme rien n\'est pas rattachée', () {
    final noName = [line('*'), line('2,50 EUR')];
    final items = [
      ExtractedItem(name: 'EUR', amount: 2.50, discount: 0, lineIndex: 1),
    ];
    expect(relabel(items, noName, [0, 1]).single.name, 'EUR');
  });

  test('une distance qui sort du ticket ne change rien', () {
    final items = [
      ExtractedItem(name: 'EUR', amount: 16.99, discount: 0, lineIndex: 0),
    ];
    expect(relabel(items, lines, [2, 0, 0]).single.name, 'EUR');
  });

  test('un article sans ligne source est ignoré', () {
    final items = [ExtractedItem(name: 'EUR', amount: 16.99, discount: 0)];
    expect(relabel(items, lines, [0, 1, 0]).single.name, 'EUR');
  });

  test('sans prédiction rien ne bouge', () {
    final items = [
      ExtractedItem(name: 'EUR', amount: 16.99, discount: 0, lineIndex: 1),
    ];
    expect(relabel(items, lines, const []).single.name, 'EUR');
  });

  test('la fenêtre empile la ligne et les trois précédentes', () {
    final rows = [
      [1.0, 2.0],
      [3.0, 4.0],
      [5.0, 6.0],
    ];
    expect(windowFeatures(rows, 2, 1), [5.0, 6.0, 3.0, 4.0]);
    expect(windowFeatures(rows, 0, 1), [1.0, 2.0, 0.0, 0.0]);
  });
}
